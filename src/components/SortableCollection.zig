// ============================================================================
// SortableCollection.zig — Generic sortable collection with drag-and-drop
// ============================================================================
//
// CRITICAL DESIGN NOTES
// =====================
//
// 1. POSITIONAL SLOTS: Vapor UUIDs are position-based. Slots (Binded refs)
//    are pinned to DOM positions and NEVER reorder with items.
//
// 2. PERSIST-ARENA RECTS: Cached bounding rects must survive across render
//    cycles (frame arena gets freed). We allocate from persist arena and
//    free/reallocate on each cacheRects() call.
//
// 3. SAFE FRACTIONAL INDEXING: After reorders, position keys on items may
//    not be in sorted order. FractionalIndex.between() handles this by
//    falling back to generateAfter() when before >= after.
//
// 4. TRANSFER API: transferTo() moves an item between collections
//    programmatically (e.g. from button clicks). It removes from source,
//    appends to destination, and fires the on_transfer callback on
//    the destination collection.

const std = @import("std");
const Vapor = @import("vapor");
pub const DragContext = @import("DragContext.zig");
const FractionalIndex = @import("FractionalIndex.zig");

// ============================================================================
// Event Types
// ============================================================================

pub fn ReorderEvent(comptime T: type) type {
    return struct {
        item: *T,
        from_index: usize,
        to_index: usize,
        position: []const u8,
        rollback_fn: ?*const fn () void = null,

        pub fn rollback(self: @This()) void {
            if (self.rollback_fn) |f| f();
        }
    };
}

pub fn TransferEvent(comptime T: type) type {
    return struct {
        item: *T,
        from_collection: []const u8,
        to_collection: []const u8,
        from_index: usize,
        to_index: usize,
        position: []const u8,
        rollback_fn: ?*const fn () void = null,

        pub fn rollback(self: @This()) void {
            if (self.rollback_fn) |f| f();
        }
    };
}

// ============================================================================
// Configuration
// ============================================================================

pub fn CollectionConfig(comptime T: type) type {
    return struct {
        id_field: []const u8 = "id",
        direction: DragContext.Direction = .vertical,
        on_reorder: ?*const fn (ReorderEvent(T)) void = null,
        on_transfer: ?*const fn (TransferEvent(T)) void = null,
        gap_size: f32 = 8,
        animate_gap: bool = true,
        allow_drag_out: bool = true,
        allow_drop_in: bool = true,
        accepts: ?*const fn (item: *const T) bool = null,
        handle_class: ?[]const u8 = null,
        show_drag_overlay: bool = true,
        drag_overlay_render: ?*const fn (item: *T, delta_x: f32, delta_y: f32) void = null,
        gap_render: ?*const fn (dir: DragContext.Direction) void = null,
    };
}

// ============================================================================
// Per-position tracking (pinned to DOM positions, never reorders)
// ============================================================================

fn ItemSlot(comptime T: type) type {
    _ = T;
    return struct {
        binded: Vapor.Binded = .{},
    };
}

// ============================================================================
// Collection
// ============================================================================

pub fn Collection(comptime T: type, comptime config: CollectionConfig(T)) type {
    return struct {
        const Self = @This();

        items: Vapor.Array(T) = undefined,
        slots: Vapor.Array(ItemSlot(T)) = undefined,
        drag_ctx: ?*DragContext = null,
        handle: DragContext.CollectionHandle = .{},
        container_binded: Vapor.Binded = .{},
        stable_id: []const u8 = "",
        /// Optional human-readable name for this collection, used as
        /// from_collection / to_collection in TransferEvent. If empty,
        /// stable_id (the auto-generated UUID) is used instead.
        display_name: []const u8 = "",
        gap_index: ?usize = null,
        initialized: bool = false,

        /// Optional runtime filter. When set, only items for which this
        /// function returns `true` are rendered. Filtered-out items remain
        /// in the collection's data but are hidden from the UI and excluded
        /// from drag hit-testing rects. Set via `setFilter()`, clear with
        /// `clearFilter()`.
        filter_fn: ?*const fn (*const T) bool = null,

        /// Persist-allocated rect cache. Freed and reallocated on each
        /// cacheRects() call so it survives across render cycles.
        cached_rects: ?[]DragContext.CachedRect = null,

        // ====================================================================
        // Initialization
        // ====================================================================

        /// Initialize with a shared drag context and seed items.
        /// `name` is an optional human-readable identifier used in transfer
        /// events (e.g. "backlog", "todo"). Pass `null` to use the
        /// auto-generated stable_id.
        pub fn initNamed(self: *Self, drag_ctx: *DragContext, name: ?[]const u8, initial_items: []const T) void {
            self.items = Vapor.array(T, .persist);
            self.slots = Vapor.array(ItemSlot(T), .persist);
            self.drag_ctx = drag_ctx;
            self.initialized = true;

            if (name) |n| {
                const name_alloc = Vapor.arena(.persist).alloc(u8, n.len) catch unreachable;
                @memcpy(name_alloc, n);
                self.display_name = name_alloc;
            }

            for (initial_items) |item| {
                self.items.append(item) catch unreachable;
                self.slots.append(.{}) catch unreachable;
            }

            self.handle = .{
                .ptr = @ptrCast(self),
                .direction = config.direction,
                .item_count = self.items.items.len,
                .cache_rects_fn = cacheRectsErased,
                .set_gap_fn = setGapErased,
                .get_position_key_fn = getPositionKeyErased,
                .remove_item_fn = removeItemErased,
                .insert_item_fn = insertItemErased,
                .finalize_reorder_fn = finalizeReorderErased,
                .get_item_ptr_fn = getItemPtrErased,
                .cache_container_rect_fn = cacheContainerRectErased,
                .fire_transfer_fn = fireTransferErased,
                .get_display_name_fn = getDisplayNameErased,
            };
        }

        /// Initialize with a shared drag context and seed items (unnamed).
        /// The collection's stable_id will be used as its identifier.
        pub fn init(self: *Self, drag_ctx: *DragContext, initial_items: []const T) void {
            self.initNamed(drag_ctx, null, initial_items);
        }

        // ====================================================================
        // Display Name
        // ====================================================================

        /// Returns the human-readable name for this collection. Falls back
        /// to stable_id if no display_name was set.
        pub fn getDisplayName(self: *const Self) []const u8 {
            if (self.display_name.len > 0) return self.display_name;
            return self.stable_id;
        }

        // ====================================================================
        // Item Management
        // ====================================================================

        pub fn append(self: *Self, item: T) !void {
            try self.items.append(item);
            self.ensureSlots(self.items.items.len);
            self.handle.item_count = self.items.items.len;
        }

        pub fn remove(self: *Self, index: usize) T {
            const item = self.items.orderedRemove(index);
            self.handle.item_count = self.items.items.len;
            return item;
        }

        /// Remove an item by pointer. Searches for the item whose address
        /// matches `item_ptr` within the items slice. Returns the removed
        /// item or null if not found.
        pub fn removeByPtr(self: *Self, item_ptr: *const T) ?T {
            const index = self.indexOfPtr(item_ptr) orelse return null;
            return self.remove(index);
        }

        pub fn insertAt(self: *Self, index: usize, item: T) void {
            self.items.insert(index, item) catch unreachable;
            self.ensureSlots(self.items.items.len);
            self.handle.item_count = self.items.items.len;
        }

        pub fn count(self: *const Self) usize {
            return self.items.items.len;
        }

        pub fn getItems(self: *const Self) []T {
            return self.items.items;
        }

        /// Find the index of an item by pointer identity. Compares the
        /// address of `item_ptr` against each element in the items slice.
        pub fn indexOfPtr(self: *const Self, item_ptr: *const T) ?usize {
            const items = self.items.items;
            for (items, 0..) |*item, i| {
                if (item == item_ptr) return i;
            }
            return null;
        }

        /// Find the index of an item by its id field value.
        pub fn indexOfId(self: *const Self, id: anytype) ?usize {
            const items = self.items.items;
            for (items, 0..) |*item, i| {
                if (@field(item, config.id_field) == id) return i;
            }
            return null;
        }

        fn ensureSlots(self: *Self, n: usize) void {
            while (self.slots.items.len < n) {
                self.slots.append(.{}) catch unreachable;
            }
        }

        // ====================================================================
        // Filtering
        // ====================================================================

        /// Set a runtime filter function. Only items for which `f` returns
        /// true will be rendered and participate in drag hit-testing.
        /// The filter does NOT remove items from the collection — it only
        /// controls visibility.
        pub fn setFilter(self: *Self, f: *const fn (*const T) bool) void {
            self.filter_fn = f;
        }

        /// Remove any active filter — all items will be rendered.
        pub fn clearFilter(self: *Self) void {
            self.filter_fn = null;
        }

        /// Returns true if the item at the given index passes the current
        /// filter (or if no filter is set).
        fn passesFilter(self: *const Self, item: *const T) bool {
            if (self.filter_fn) |f| return f(item);
            return true;
        }

        /// Count only items that pass the current filter.
        pub fn visibleCount(self: *const Self) usize {
            if (self.filter_fn == null) return self.items.items.len;
            var n: usize = 0;
            for (self.items.items) |*item| {
                if (self.passesFilter(item)) n += 1;
            }
            return n;
        }

        // ====================================================================
        // Cross-collection Transfer (programmatic)
        // ====================================================================

        /// Transfer an item from this collection to another collection.
        /// The item is identified by pointer. It is removed from `self`
        /// and appended to `dest`. Fires the on_transfer callback on the
        /// destination collection.
        ///
        /// Usage (e.g. from a "move right" button handler):
        ///   from_col.transferTo(&to_col, task);
        pub fn transferTo(self: *Self, dest: *Self, item_ptr: *T) void {
            self.transferToAt(dest, item_ptr, dest.count());
        }

        /// Transfer an item to a specific index in the destination collection.
        pub fn transferToAt(self: *Self, dest: *Self, item_ptr: *T, dest_index: usize) void {
            const from_index = self.indexOfPtr(item_ptr) orelse return;
            const item_copy = item_ptr.*;

            // Remove from source first (we have a copy)
            _ = self.remove(from_index);

            // Clamp dest_index to destination length
            const clamped_index = @min(dest_index, dest.count());

            // Insert into destination
            dest.insertAt(clamped_index, item_copy);

            // Compute a position key for the new location
            var key_buf: [64]u8 = undefined;
            const position_key = dest.getPositionKey(clamped_index, &key_buf);
            const persisted_key = Vapor.arena(.persist).alloc(u8, position_key.len) catch unreachable;
            @memcpy(persisted_key, position_key);

            // Update position field if present
            if (@hasField(T, "position")) {
                @field(&dest.items.items[clamped_index], "position") = persisted_key;
            }

            // Fire transfer callback
            if (config.on_transfer) |callback| {
                callback(.{
                    .item = &dest.items.items[clamped_index],
                    .from_collection = self.getDisplayName(),
                    .to_collection = dest.getDisplayName(),
                    .from_index = from_index,
                    .to_index = clamped_index,
                    .position = persisted_key,
                    .rollback_fn = null,
                });
            }
        }

        // ====================================================================
        // Fractional Index Key Generation
        // ====================================================================

        fn getPositionKey(self: *Self, index: usize, buf: []u8) []const u8 {
            const items = self.items.items;

            const before: ?[]const u8 = if (index > 0)
                getItemPosition(&items[index - 1])
            else
                null;

            const after: ?[]const u8 = if (index < items.len)
                getItemPosition(&items[index])
            else
                null;

            return FractionalIndex.between(before, after, buf);
        }

        fn getItemPosition(item: *const T) ?[]const u8 {
            if (@hasField(T, "position")) {
                return @field(item, "position");
            }
            return null;
        }

        // ====================================================================
        // Rect Caching (persist arena — survives across renders)
        // ====================================================================

        fn cacheRects(self: *Self) void {
            const item_count = self.items.items.len;
            self.ensureSlots(item_count);

            const rects = Vapor.arena(.persist).alloc(
                DragContext.CachedRect,
                item_count,
            ) catch unreachable;

            for (0..item_count) |i| {
                const slot = &self.slots.items[i];
                if (slot.binded.getBoundingClientRect()) |bounds| {
                    rects[i] = .{
                        .rect = .{
                            .top = bounds.top,
                            .left = bounds.left,
                            .right = bounds.right,
                            .bottom = bounds.bottom,
                            .width = bounds.width,
                            .height = bounds.height,
                        },
                        .item_index = i,
                    };
                } else {
                    rects[i] = .{ .item_index = i };
                }
            }

            self.cached_rects = rects;
            self.handle.item_rects = rects;
            self.handle.item_count = item_count;
        }

        fn cacheContainerRect(self: *Self) ?DragContext.Rect {
            if (self.container_binded.getBoundingClientRect()) |bounds| {
                return .{
                    .top = bounds.top,
                    .left = bounds.left,
                    .right = bounds.right,
                    .bottom = bounds.bottom,
                    .width = bounds.width,
                    .height = bounds.height,
                };
            }
            return null;
        }

        // ====================================================================
        // Gap Management
        // ====================================================================

        fn setGap(self: *Self, index: ?usize) void {
            self.gap_index = index;
        }

        // ====================================================================
        // Reorder
        // ====================================================================

        fn finalizeReorder(self: *Self, from: usize, to: usize) void {
            if (from == to) {
                self.gap_index = null;
                return;
            }

            // Translate visual gap index → item-array destination
            const dest = if (to > from) to - 1 else to;

            if (dest == from) {
                self.gap_index = null;
                return;
            }

            // Compute position key BEFORE moving
            var key_buf: [64]u8 = undefined;
            const position_key = self.getPositionKey(dest, &key_buf);

            const persisted_key = Vapor.arena(.persist).alloc(u8, position_key.len) catch unreachable;
            @memcpy(persisted_key, position_key);

            // Reorder ONLY the items array. Slots stay pinned.
            const item = self.items.orderedRemove(from);
            self.items.insert(dest, item) catch unreachable;

            if (@hasField(T, "position")) {
                @field(&self.items.items[dest], "position") = persisted_key;
            }

            if (config.on_reorder) |callback| {
                callback(.{
                    .item = &self.items.items[dest],
                    .from_index = from,
                    .to_index = dest,
                    .position = persisted_key,
                    .rollback_fn = null,
                });
            }

            self.gap_index = null;
        }

        // ====================================================================
        // Fire Transfer Event (called by DragContext on cross-collection drop)
        // ====================================================================

        fn fireTransfer(
            self: *Self,
            item_ptr: *T,
            from_collection_name: []const u8,
            from_index: usize,
            to_index: usize,
        ) void {
            // Compute position key for the inserted item
            var key_buf: [64]u8 = undefined;
            const position_key = self.getPositionKey(to_index, &key_buf);
            const persisted_key = Vapor.arena(.persist).alloc(u8, position_key.len) catch unreachable;
            @memcpy(persisted_key, position_key);

            // Update position field
            if (@hasField(T, "position")) {
                @field(item_ptr, "position") = persisted_key;
            }

            if (config.on_transfer) |callback| {
                callback(.{
                    .item = item_ptr,
                    .from_collection = from_collection_name,
                    .to_collection = self.getDisplayName(),
                    .from_index = from_index,
                    .to_index = to_index,
                    .position = persisted_key,
                    .rollback_fn = null,
                });
            }
        }

        // ====================================================================
        // Type-erased vtable
        // ====================================================================

        fn cacheRectsErased(ptr: *anyopaque) void {
            const self: *Self = @ptrCast(@alignCast(ptr));
            self.cacheRects();
        }

        fn cacheContainerRectErased(ptr: *anyopaque) ?DragContext.Rect {
            const self: *Self = @ptrCast(@alignCast(ptr));
            return self.cacheContainerRect();
        }

        fn setGapErased(ptr: *anyopaque, index: ?usize) void {
            const self: *Self = @ptrCast(@alignCast(ptr));
            self.setGap(index);
        }

        fn getPositionKeyErased(ptr: *anyopaque, index: usize, buf: []u8) []const u8 {
            const self: *Self = @ptrCast(@alignCast(ptr));
            return self.getPositionKey(index, buf);
        }

        fn removeItemErased(ptr: *anyopaque, index: usize) void {
            const self: *Self = @ptrCast(@alignCast(ptr));
            _ = self.remove(index);
        }

        fn insertItemErased(ptr: *anyopaque, index: usize, item_ptr: *anyopaque) void {
            const self: *Self = @ptrCast(@alignCast(ptr));
            const item: *T = @ptrCast(@alignCast(item_ptr));
            self.insertAt(index, item.*);
        }

        fn finalizeReorderErased(ptr: *anyopaque, from: usize, to: usize) void {
            const self: *Self = @ptrCast(@alignCast(ptr));
            self.finalizeReorder(from, to);
        }

        fn getItemPtrErased(ptr: *anyopaque, index: usize) ?*anyopaque {
            const self: *Self = @ptrCast(@alignCast(ptr));
            if (index >= self.items.items.len) return null;
            return @ptrCast(&self.items.items[index]);
        }

        fn fireTransferErased(
            ptr: *anyopaque,
            item_ptr: *anyopaque,
            from_collection_name: []const u8,
            from_index: usize,
            to_index: usize,
        ) void {
            const self: *Self = @ptrCast(@alignCast(ptr));
            const typed_item: *T = @ptrCast(@alignCast(item_ptr));
            self.fireTransfer(typed_item, from_collection_name, from_index, to_index);
        }

        fn getDisplayNameErased(ptr: *anyopaque) []const u8 {
            const self: *Self = @ptrCast(@alignCast(ptr));
            return self.getDisplayName();
        }

        // ====================================================================
        // Drag Handlers
        // ====================================================================

        fn handleItemPointerDown(self: *Self, index: usize, evt: *Vapor.Event) void {
            const ctx = self.drag_ctx orelse return;
            evt.preventDefault();

            const px = evt.clientX();
            const py = evt.clientY();

            var initial_rect: ?DragContext.Rect = null;
            self.ensureSlots(index + 1);
            if (self.slots.items[index].binded.getBoundingClientRect()) |bounds| {
                initial_rect = .{
                    .top = bounds.top,
                    .left = bounds.left,
                    .right = bounds.right,
                    .bottom = bounds.bottom,
                    .width = bounds.width,
                    .height = bounds.height,
                };
            }

            ctx.startDrag(
                self.stable_id,
                index,
                @ptrCast(&self.items.items[index]),
                px,
                py,
                initial_rect,
            );
        }

        // ====================================================================
        // Rendering
        // ====================================================================

        pub fn surface(self: *Self) Surface {
            const container = Vapor.Row();
            const uuid = container.getUUID();

            if (self.stable_id.len == 0) {
                // If a display_name was provided, use it as stable_id too
                // so that DragContext registers the collection under that name.
                if (self.display_name.len > 0) {
                    self.stable_id = self.display_name;
                } else {
                    const id_alloc = Vapor.arena(.persist).alloc(u8, uuid.len) catch unreachable;
                    @memcpy(id_alloc, uuid);
                    self.stable_id = id_alloc;
                }

                if (self.drag_ctx) |ctx| {
                    ctx.registerCollection(self.stable_id, &self.handle);
                }
            }

            return .{ .collection = self, .container = container };
        }

        pub const Surface = struct {
            collection: *Self,
            container: Vapor.Builder(.pure),

            pub fn width(s: Surface, w: anytype) Surface {
                return .{ .collection = s.collection, .container = s.container.width(w) };
            }
            pub fn height(s: Surface, h: anytype) Surface {
                return .{ .collection = s.collection, .container = s.container.height(h) };
            }
            pub fn background(s: Surface, bg: anytype) Surface {
                return .{ .collection = s.collection, .container = s.container.background(bg) };
            }
            pub fn padding(s: Surface, p: anytype) Surface {
                return .{ .collection = s.collection, .container = s.container.padding(p) };
            }
            pub fn spacing(s: Surface, sp: anytype) Surface {
                return .{ .collection = s.collection, .container = s.container.spacing(sp) };
            }
            pub fn border(s: Surface, b: anytype) Surface {
                return .{ .collection = s.collection, .container = s.container.border(b) };
            }
            pub fn layout(s: Surface, l: anytype) Surface {
                return .{ .collection = s.collection, .container = s.container.layout(l) };
            }
            pub fn direction(s: Surface, d: anytype) Surface {
                return .{ .collection = s.collection, .container = s.container.direction(d) };
            }
            pub fn scroll(s: Surface, sc: anytype) Surface {
                return .{ .collection = s.collection, .container = s.container.scroll(sc) };
            }
            pub fn pos(s: Surface, p: anytype) Surface {
                return .{ .collection = s.collection, .container = s.container.pos(p) };
            }
            pub fn shadow(s: Surface, sh: anytype) Surface {
                return .{ .collection = s.collection, .container = s.container.shadow(sh) };
            }

            pub fn render(
                s: Surface,
                comptime render_fn: fn (*T, usize, DragContext.ItemState) void,
            ) void {
                const self = s.collection;
                const ctx = self.drag_ctx;
                const is_dragging_from_here = if (ctx) |c| c.isDraggingFrom(self.stable_id) else false;
                const drag_source_index = if (ctx) |c| c.getDragSourceIndex() else null;

                const dir: Vapor.Types.Direction = if (config.direction == .vertical)
                    .column
                else
                    .row;

                s.container
                    .ref(&self.container_binded)
                    .direction(dir)
                    .children({
                    const items = self.items.items;
                    self.ensureSlots(items.len);

                    var visible_count: usize = 0;

                    for (items, 0..) |*item, i| {
                        // Skip items that don't pass the filter.
                        // The item is still being dragged even if filtered,
                        // so always show the currently-dragging item.
                        const is_this_item_dragging = is_dragging_from_here and
                            (drag_source_index orelse std.math.maxInt(usize)) == i;

                        if (!is_this_item_dragging and !self.passesFilter(item)) {
                            continue;
                        }

                        visible_count += 1;
                        const slot = &self.slots.items[i];

                        // Gap before this item
                        if (self.gap_index) |gap| {
                            if (gap == i) {
                                renderGap(config.direction);
                            }
                        }

                        const state = DragContext.ItemState{
                            .is_dragging = is_this_item_dragging,
                            .is_placeholder = is_this_item_dragging,
                            .is_over = false,
                            .index = i,
                        };

                        // Wrapper with positional binded ref
                        Vapor.Row()
                            .ref(&slot.binded)
                            .onEventCtx(.pointerdown, handlePointerDownDispatch, .{ self, i })
                            .cursor(if (is_this_item_dragging) .grabbing else .grab)
                            .opacity(if (is_this_item_dragging) 0.3 else 1.0)
                            .children({
                            render_fn(item, i, state);
                        });
                    }

                    // Gap at end
                    if (self.gap_index) |gap| {
                        if (gap >= items.len) {
                            renderGap(config.direction);
                        }
                    }

                    // Empty drop target (no visible items and no gap)
                    if (visible_count == 0 and self.gap_index == null) {
                        Vapor.Row()
                            .width(if (config.direction == .horizontal) .px(2) else .percent(100))
                            .height(if (config.direction == .vertical) .px(2) else .percent(100))
                            .children({});
                    }
                });

                // Default drag overlay
                if (config.show_drag_overlay) {
                    if (ctx) |c| {
                        const overlay = c.getOverlayState();
                        if (overlay.is_active and c.isDraggingFrom(self.stable_id)) {
                            if (overlay.initial_rect) |rect| {
                                const overlay_x = rect.left + overlay.delta_x;
                                const overlay_y = rect.top + overlay.delta_y;

                                if (config.drag_overlay_render) |custom_render| {
                                    if (overlay.item_ptr) |ptr| {
                                        const typed_item: *T = @ptrCast(@alignCast(ptr));
                                        custom_render(typed_item, overlay.delta_x, overlay.delta_y);
                                    } else {
                                        Vapor.Null();
                                    }
                                } else {
                                    if (overlay.item_ptr) |ptr| {
                                        const typed_item: *T = @ptrCast(@alignCast(ptr));
                                        const drag_idx = drag_source_index orelse 0;

                                        Vapor.Row()
                                            .pos(.tl(.px(overlay_y), .px(overlay_x), .fixed))
                                            .width(.px(rect.width))
                                            .zIndex(9999)
                                            .cursor(.grabbing)
                                            .opacity(0.9)
                                            .shadow(.{
                                                .color = .transparentize(.black, 0.15),
                                                .blur = 16,
                                                .top = 4,
                                                .spread = 2,
                                            })
                                            .border(.round(.palette(.tint), .all(8)))
                                            .background(.palette(.background))
                                            .children({
                                            render_fn(typed_item, drag_idx, .{
                                                .is_dragging = true,
                                                .is_placeholder = false,
                                                .is_over = false,
                                                .index = drag_idx,
                                            });
                                        });
                                    } else {
                                        Vapor.Null();
                                    }
                                }
                            } else {
                                Vapor.Null();
                            }
                        } else {
                            Vapor.Null();
                        }
                    } else {
                        Vapor.Null();
                    }
                }
            }
        };

        fn handlePointerDownDispatch(self: *Self, index: usize, evt: *Vapor.Event) void {
            self.handleItemPointerDown(index, evt);
        }

        fn renderGap(comptime dir: DragContext.Direction) void {
            if (config.gap_render) |f| {
                f(dir);
                return;
            }
            Vapor.Row()
                .width(if (dir == .horizontal) .px(60) else .percent(100))
                .height(if (dir == .vertical) .px(60) else .percent(100))
                .background(.transparentize(.palette(.tint), 0.1))
                .border(.round(.transparentize(.palette(.tint), 0.3), .all(8)))
                .duration(150)
                .children({});
        }
    };
}
