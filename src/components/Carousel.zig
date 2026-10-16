// ============================================================================
// Carousel.zig — click + swipe carousel component
// ============================================================================
//
// A classic discrete carousel:
//   - Prev / next arrow buttons advance one slide at a time.
//   - Pointer/touch drag (swipe) follows the finger and snaps to the
//     nearest slide on release once a threshold is crossed.
//   - Optional dot indicators jump directly to a given slide.
//
// Two APIs mirror Marquee:
//
//   1) Standalone — default item rendering:
//        Carousel.render(.{ .id = "hero", .items = &items });
//
//   2) Chainable — custom per-item component:
//        _ = Carousel.create(.{ .id = "hero", .items = &items })
//            .Component(myItemFn, .{ arg1, arg2 });
//
// IMPORTANT: a stable `id` is required for state lookup so that the carousel
// remembers its current index across renders.

const std = @import("std");
const Vapor = @import("vapor");
const Row = Vapor.Row;
const Stack = Vapor.Stack;
const Text = Vapor.Text;
const Button = Vapor.Button;
const Draggable = Vapor.Draggable;

// ============================================================================
// Types
// ============================================================================

pub const CarouselItem = struct {
    title: []const u8,
    subtitle: []const u8 = "",
    color: Vapor.Types.Color = .palette(.tint),
};

pub const Options = struct {
    /// Stable id for state lookup. Required for proper state persistence.
    id: []const u8 = "",
    items: []const CarouselItem,
    /// Width of each slide in pixels.
    item_width: f32 = 480,
    /// Height of each slide in pixels.
    item_height: f32 = 280,
    /// Gap between slides in pixels.
    gap: f32 = 16,
    /// Whether to wrap around when navigating past the ends.
    loop: bool = true,
    /// Show prev / next arrow buttons.
    show_arrows: bool = true,
    /// Show dot indicators below the carousel.
    show_dots: bool = true,
    /// Minimum drag distance (px) required to advance one slide on release.
    swipe_threshold: f32 = 60,
    /// Transition duration in ms when snapping to a slide.
    transition_ms: u32 = 350,
};

// ============================================================================
// State
// ============================================================================

var carousels: std.AutoHashMap(usize, *Carousel) = undefined;

pub fn new() void {
    carousels = std.AutoHashMap(usize, *Carousel).init(Vapor.arena(.persist));
}

// ============================================================================
// Carousel struct
// ============================================================================

const Carousel = @This();

options: Options,
index: usize = 0,
drag_offset: f32 = 0,
is_dragging: bool = false,
draggable: Draggable,
track: *Vapor.Binded,
stable_id: usize = 0,
default: bool = true,
container: Vapor.Builder(.pure),

// ============================================================================
// Internal: transform helpers
// ============================================================================

fn stride(c: *const Carousel) f32 {
    return c.options.item_width + c.options.gap;
}

fn currentOffset(c: *const Carousel) f32 {
    const idx_f: f32 = @floatFromInt(c.index);
    return -(idx_f * stride(c)) + c.drag_offset;
}

fn applyTransform(c: *Carousel, animate: bool) void {
    const transition_str = if (animate)
        Vapor.fmtln("transform {d}ms cubic-bezier(0.22, 1, 0.36, 1)", .{c.options.transition_ms})
    else
        "none";
    c.track.mutateStyleString("transition", transition_str);
    c.track.mutateStyleString(
        "transform",
        Vapor.fmtln("translate3d({d}px, 0, 0)", .{currentOffset(c)}),
    );
}

// ============================================================================
// Drag handlers
// ============================================================================

fn onDragStart(d: *Draggable, _: *Vapor.Event) void {
    const c: *Carousel = @alignCast(@fieldParentPtr("draggable", d));
    c.is_dragging = true;
    c.drag_offset = 0;
    applyTransform(c, false);
}

fn onDrag(d: *Draggable, _: *Vapor.Event) void {
    const c: *Carousel = @alignCast(@fieldParentPtr("draggable", d));
    c.drag_offset = d.delta_x;
    applyTransform(c, false);
}

fn onDragEnd(d: *Draggable, _: *Vapor.Event) void {
    const c: *Carousel = @alignCast(@fieldParentPtr("draggable", d));
    c.is_dragging = false;

    const dx = d.delta_x;
    const last_idx = c.options.items.len - 1;

    if (dx <= -c.options.swipe_threshold) {
        if (c.index < last_idx) {
            c.index += 1;
        } else if (c.options.loop) {
            c.index = 0;
        }
    } else if (dx >= c.options.swipe_threshold) {
        if (c.index > 0) {
            c.index -= 1;
        } else if (c.options.loop) {
            c.index = last_idx;
        }
    }

    c.drag_offset = 0;
    d.delta_x = 0;
    d.delta_y = 0;
    d.current_x = 0;
    d.current_y = 0;
    d.x = 0;
    d.y = 0;
    applyTransform(c, true);
    Vapor.cycle();
}

// ============================================================================
// Click handlers
// ============================================================================

fn goPrev(c: *Carousel) void {
    const last_idx = c.options.items.len - 1;
    if (c.index > 0) {
        c.index -= 1;
    } else if (c.options.loop) {
        c.index = last_idx;
    }
    applyTransform(c, true);
}

fn goNext(c: *Carousel) void {
    const last_idx = c.options.items.len - 1;
    if (c.index < last_idx) {
        c.index += 1;
    } else if (c.options.loop) {
        c.index = 0;
    }
    applyTransform(c, true);
}

const DotCtx = struct { c: *Carousel, idx: usize };

fn goTo(ctx: *DotCtx) void {
    ctx.c.index = ctx.idx;
    applyTransform(ctx.c, true);
}

// ============================================================================
// State lookup / construction
// ============================================================================

fn getOrCreate(options: Options, container: Vapor.Builder(.pure)) *Carousel {
    const uuid = container.getUUID();
    const hash = Vapor.utils.hashKey(uuid);
    const stable_id = if (options.id.len > 0) Vapor.utils.hashKey(options.id) else hash;

    const carousel = carousels.get(stable_id) orelse blk: {
        const c = Vapor.arena(.persist).create(Carousel) catch unreachable;
        const tb = Vapor.arena(.persist).create(Vapor.Binded) catch unreachable;
        tb.* = .{};
        c.* = .{
            .options = options,
            .index = 0,
            .drag_offset = 0,
            .is_dragging = false,
            .draggable = .{
                .on_drag_start = onDragStart,
                .on_drag = onDrag,
                .on_drag_end = onDragEnd,
                .config = .{ .axis = .x },
            },
            .track = tb,
            .stable_id = stable_id,
            .default = true,
            .container = container,
        };
        carousels.put(stable_id, c) catch unreachable;
        break :blk c;
    };
    carousel.options = options;
    carousel.default = true;
    carousel.container = container;
    // Clamp index in case items list shrank between renders.
    if (options.items.len == 0) {
        carousel.index = 0;
    } else if (carousel.index >= options.items.len) {
        carousel.index = options.items.len - 1;
    }
    return carousel;
}

// ============================================================================
// Public API: render() — standalone usage with default item renderer
// ============================================================================

pub fn render(options: Options) void {
    const container = Stack();
    const carousel = getOrCreate(options, container);
    renderCarousel(carousel, null);
}

// ============================================================================
// Public API: create() + Component() / end() — chainable with custom renderers
// ============================================================================

pub fn create(options: Options) *Carousel {
    const container = Stack();
    return getOrCreate(options, container);
}

/// Render the carousel with a custom per-item component.
///
/// `component(item, item_width, item_height, ...args)` is invoked once per
/// slide so callers can render any UI they want for each item.
pub fn Component(carousel: *Carousel, comptime component: anytype, args: anytype) void {
    carousel.default = false;
    renderCarouselCustom(carousel, component, args);
}

/// Finalize the carousel with the default item renderer. Only renders when
/// Component() was not called.
pub fn end(carousel: *Carousel) void {
    if (!carousel.default) return;
    renderCarousel(carousel, null);
}

// ============================================================================
// Internal: rendering
// ============================================================================

fn renderCarousel(c: *Carousel, _: ?*const fn () void) void {
    const opts = c.options;
    const initial_offset = currentOffset(c);

    c.container
        .width(.px(opts.item_width))
        .direction(.column)
        .spacing(12)
        .children({

        // Viewport: clips overflow + hosts the swipe gesture.
        Row()
            .width(.px(opts.item_width))
            .height(.px(opts.item_height))
            .scroll(.none())
            .pos(.relative)
            .createDraggable(&c.draggable)
            .inlineStyle("touch-action: pan-y; cursor: grab; user-select: none; overflow: hidden;", .{})
            .children({

            // Track: holds all slides in a row, translated by index.
            Row()
                .ref(c.track)
                .spacing(@as(u8, @intFromFloat(opts.gap)))
                .inlineStyle(
                    "transform: translate3d({d}px, 0, 0); transition: transform {d}ms cubic-bezier(0.22, 1, 0.36, 1); will-change: transform;",
                    .{ initial_offset, opts.transition_ms },
                )
                .children({
                for (opts.items) |item| {
                    renderItem(item, opts.item_width, opts.item_height);
                }
            });

            if (opts.show_arrows and opts.items.len > 1) {
                renderArrows(c);
            }
        });

        if (opts.show_dots and opts.items.len > 1) {
            renderDots(c);
        }
    });
}

fn renderCarouselCustom(c: *Carousel, comptime component: anytype, args: anytype) void {
    const opts = c.options;
    const initial_offset = currentOffset(c);

    c.container
        .width(.px(opts.item_width))
        .direction(.column)
        .spacing(12)
        .children({
        Row()
            .width(.px(opts.item_width))
            .height(.px(opts.item_height))
            .scroll(.none())
            .pos(.relative)
            .createDraggable(&c.draggable)
            .inlineStyle("touch-action: pan-y; cursor: grab; user-select: none; overflow: hidden;", .{})
            .children({
            Row()
                .ref(c.track)
                .spacing(@as(u8, @intFromFloat(opts.gap)))
                .inlineStyle(
                    "transform: translate3d({d}px, 0, 0); transition: transform {d}ms cubic-bezier(0.22, 1, 0.36, 1); will-change: transform;",
                    .{ initial_offset, opts.transition_ms },
                )
                .children({
                for (opts.items) |item| {
                    @call(.auto, component, .{ item, opts.item_width, opts.item_height } ++ args);
                }
            });

            if (opts.show_arrows and opts.items.len > 1) {
                renderArrows(c);
            }
        });

        if (opts.show_dots and opts.items.len > 1) {
            renderDots(c);
        }
    });
}

fn renderArrows(c: *Carousel) void {
    Row()
        .pos(.absolute)
        .inlineStyle(
            "top: 50%; left: 0; right: 0; transform: translateY(-50%); pointer-events: none; padding: 0 12px; display: flex; justify-content: space-between; align-items: center;",
            .{},
        )
        .children({
        Button(goPrev, .{c})
            .ariaLabel("previous slide")
            .inlineStyle("pointer-events: auto;", .{})
            .width(.px(40))
            .height(.px(40))
            .layout(.center)
            .background(.transparentizeHex(.black, 0.4))
            .border(.round(.transparent, .all(99)))
            .pointer()
            .children({
            Text("‹")
                .font(24, 700, .white)
                .fontFamily("IBM Plex Sans,monospace")
                .end();
        });
        Button(goNext, .{c})
            .ariaLabel("next slide")
            .inlineStyle("pointer-events: auto;", .{})
            .width(.px(40))
            .height(.px(40))
            .layout(.center)
            .background(.transparentizeHex(.black, 0.4))
            .border(.round(.transparent, .all(99)))
            .pointer()
            .children({
            Text("›")
                .font(24, 700, .white)
                .fontFamily("IBM Plex Sans,monospace")
                .end();
        });
    });
}

fn renderDots(c: *Carousel) void {
    Row()
        .width(.percent(100))
        .layout(.center)
        .spacing(8)
        .children({
        for (c.options.items, 0..) |_, i| {
            const ctx = Vapor.arena(.frame).create(DotCtx) catch unreachable;
            ctx.* = .{ .c = c, .idx = i };
            const active = (i == c.index);
            Button(goTo, .{ctx})
                .ariaLabel("dot")
                .width(.px(if (active) 24 else 8))
                .height(.px(8))
                .background(if (active) .palette(.tint) else .palette(.border_color_light))
                .border(.round(.transparent, .all(99)))
                .pointer()
                .children({});
        }
    });
}

fn renderItem(item: CarouselItem, width: f32, height: f32) void {
    Stack()
        .width(.px(width))
        .height(.px(height))
        .direction(.column)
        .layout(.center)
        .spacing(8)
        .background(item.color)
        .border(.round(item.color, .all(12)))
        .inlineStyle("flex-shrink: 0;", .{})
        .children({
        Text(item.title)
            .font(28, 700, .white)
            .fontFamily("Montserrat")
            .end();
        if (item.subtitle.len > 0) {
            Text(item.subtitle)
                .font(14, 300, .white)
                .fontFamily("Montserrat")
                .end();
        }
    });
}
