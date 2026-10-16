// ============================================================================
// Todo List — A simple, clean example showing draft-vs-list separation
// ============================================================================
//
// Key ideas:
//   - `draft_*` fields are framework-owned scratch space the TextField binds to
//   - On commit, draft contents are duped into the persist arena and appended
//     to the todos list — this gives each todo a stable, owned buffer
//   - Editing an existing todo binds the field directly to that row's slice,
//     so edits flow live without a separate "save" step
//   - Per-instance state lives on the struct so multiple lists can coexist

const std = @import("std");
const Vapor = @import("vapor");
const Text = Vapor.Text;
const Row = Vapor.Row;
const Stack = Vapor.Stack;
const Center = Vapor.Center;
const Icon = Vapor.Icon;
const TextFmt = Vapor.TextFmt;
const Animation = Vapor.Animation;
const Opaque = @import("opaque-ui");
const Button = Opaque.Button;
const Field = Opaque.TextField;
const Toast = Opaque.Toast;

// ============================================================================
// THEME
// ============================================================================

const Theme = struct {
    const bg_base = Vapor.Types.Color.palette(.background);
    const bg_card = Vapor.Types.Color.palette(.background);
    const border = Vapor.Types.Color.palette(.border_color_light);
    const text = Vapor.Types.Color.palette(.text_color);
    const text_muted = Vapor.Types.Color.hex("#71717a");
    const accent = Vapor.Types.Color.palette(.tint);
    const success = Vapor.Types.Color.hex("#10b981");
    const danger = Vapor.Types.Color.palette(.danger);
};

// ============================================================================
// ANIMATIONS
// ============================================================================

const item_enter = Animation.init("todo-item-enter")
    .prop(.translateY, 8, 0)
    .prop(.opacity, 0, 1)
    .duration(180)
    .easing(.easeOut)
    .fill(.forwards);

// ============================================================================
// DATA
// ============================================================================

pub const TodoItem = struct {
    id: usize,
    text: []const u8,
    completed: bool = false,
};

const Filter = enum {
    all,
    active,
    completed,

    pub fn label(self: Filter) []const u8 {
        return switch (self) {
            .all => "All",
            .active => "Active",
            .completed => "Completed",
        };
    }
};

// ============================================================================
// TODO LIST COMPONENT
// ============================================================================

pub const TodoList = struct {
    // --- Persistent list of todos -------------------------------------------
    todos: Vapor.ArrayArena(TodoItem) = Vapor.persist.array(TodoItem),
    next_id: usize = 1,

    // --- Draft state for the "add" field ------------------------------------
    // This is the framework-owned scratch buffer the input binds to. On
    // commit, we dupe into the persist arena and clear this back to "".
    draft_text: []const u8 = "",

    // --- Edit state ---------------------------------------------------------
    // When non-null, the input row is hidden and the matching row renders an
    // inline editor bound directly to that todo's `text` slice.
    editing_id: ?usize = null,

    // --- Filter -------------------------------------------------------------
    filter: Filter = .all,

    // ========================================================================
    // SHARED INIT (call once before any instance)
    // ========================================================================

    pub fn initShared() void {
        item_enter.build();
    }

    // ========================================================================
    // INSTANCE INIT
    // ========================================================================

    pub fn init(self: *TodoList) void {
        self.* = .{};

        // Seed with a couple of examples
        self.appendOwned("Buy groceries", false);
        self.appendOwned("Read Zig docs", true);
        self.appendOwned("Ship the framework", false);
    }

    /// Append a todo whose text is already owned by the persist arena
    /// (string literals qualify since they live in .rodata).
    fn appendOwned(self: *TodoList, text: []const u8, completed: bool) void {
        self.todos.append(.{
            .id = self.next_id,
            .text = text,
            .completed = completed,
        });
        self.next_id += 1;
    }

    // ========================================================================
    // EVENT HANDLERS
    // ========================================================================

    pub fn addTodo(self: *TodoList) void {
        // Trim and validate
        const trimmed = std.mem.trim(u8, self.draft_text, " \t\n\r");
        if (trimmed.len == 0) return;

        // Dupe into the persist arena so the todo owns its own stable buffer
        const owned = Vapor.persist.dupe(trimmed);

        self.todos.append(.{
            .id = self.next_id,
            .text = owned,
            .completed = false,
        });
        self.next_id += 1;

        // Clear the draft — framework will re-seed the bound field with ""
        self.draft_text = "";

        Toast.success(.{ .title = "Added", .description = owned });
    }

    pub fn toggleCompleted(self: *TodoList, item: *TodoItem) void {
        _ = self;
        item.completed = !item.completed;
    }

    pub fn deleteTodo(self: *TodoList, item: *TodoItem) void {
        // If we're editing this one, exit edit mode first
        if (self.editing_id == item.id) self.editing_id = null;

        for (self.todos.items, 0..) |*t, i| {
            if (t.id == item.id) {
                _ = self.todos.orderedRemove(i);
                Toast.warning(.{ .title = "Deleted", .description = "Item removed" });
                return;
            }
        }
    }

    pub fn beginEdit(self: *TodoList, item: *TodoItem) void {
        self.editing_id = item.id;
    }

    pub fn finishEdit(self: *TodoList) void {
        // The TextField was bound directly to the todo's `text` slice, so
        // the value is already updated. We just leave edit mode and let the
        // framework's draft system handle keeping that buffer alive.
        self.editing_id = null;
    }

    pub fn setFilter(self: *TodoList, f: Filter) void {
        self.filter = f;
    }

    pub fn clearCompleted(self: *TodoList) void {
        var i: usize = 0;
        var removed: usize = 0;
        while (i < self.todos.items.len) {
            if (self.todos.items[i].completed) {
                _ = self.todos.orderedRemove(i);
                removed += 1;
            } else {
                i += 1;
            }
        }
        if (removed > 0) {
            Toast.info(.{ .title = "Cleared", .description = "Completed items removed" });
        }
    }

    // ========================================================================
    // HELPERS
    // ========================================================================

    fn isVisible(self: *TodoList, item: *const TodoItem) bool {
        return switch (self.filter) {
            .all => true,
            .active => !item.completed,
            .completed => item.completed,
        };
    }

    fn activeCount(self: *TodoList) usize {
        var n: usize = 0;
        for (self.todos.items) |t| if (!t.completed) {
            n += 1;
        };
        return n;
    }

    fn completedCount(self: *TodoList) usize {
        var n: usize = 0;
        for (self.todos.items) |t| if (t.completed) {
            n += 1;
        };
        return n;
    }

    // ========================================================================
    // RENDERING
    // ========================================================================

    pub fn render(self: *TodoList) void {
        Center()
            .width(.percent(100))
            .height(.percent(100))
            .background(Theme.bg_base)
            .children({
            Stack()
                .width(.px(560))
                .padding(.all(24))
                .spacing(20)
                .children({
                self.renderHeader();
                self.renderInput();
                self.renderFilters();
                self.renderList();
                self.renderFooter();
            });
        });
    }

    fn renderHeader(self: *TodoList) void {
        Row()
            .width(.percent(100))
            .layout(.x_between_center)
            .children({
            Stack().spacing(2).children({
                Text("Todos")
                    .font(28, 700, Theme.text)
                    .fontFamily("Montserrat")
                    .end();
                TextFmt("{d} active, {d} done", .{ self.activeCount(), self.completedCount() })
                    .font(13, 400, Theme.text_muted)
                    .fontFamily("Montserrat")
                    .end();
            });

            Icon(.check_circle_fill)
                .font(28, 400, Theme.accent)
                .end();
        });
    }

    fn renderInput(self: *TodoList) void {
        Row()
            .width(.percent(100))
            .spacing(8)
            .layout(.left_center)
            .children({
            Row().width(.grow).children({
                Vapor.TextField(.string)
                    .width(.percent(100))
                    .border(.round(Theme.border, .all(6)))
                    .padding(.all(4))
                    .bind(&self.draft_text)
                    .end();
            });

            Button(addTodo, .{self})
                .padding(.xy(16, 10))
                .background(Theme.accent)
                .children({
                Icon(.plus)
                    .font(14, 600, .palette(.background))
                    .end();
                Text("Add")
                    .font(13, 500, .palette(.background))
                    .fontFamily("Montserrat")
                    .end();
            });
        });
    }

    fn renderFilters(self: *TodoList) void {
        Row()
            .width(.percent(100))
            .layout(.left_center)
            .spacing(6)
            .children({
            for (std.enums.values(Filter)) |f| {
                const is_active = self.filter == f;
                Button(setFilter, .{ self, f })
                    .padding(.xy(12, 6))
                    .background(if (is_active) .transparentize(Theme.accent, 0.15) else .transparent)
                    .border(.round(
                        if (is_active) Theme.accent else Theme.border,
                        .all(6),
                    ))
                    .children({
                    Text(f.label())
                        .font(12, 500, if (is_active) Theme.accent else Theme.text_muted)
                        .fontFamily("Montserrat")
                        .end();
                });
            }
        });
    }

    fn renderList(self: *TodoList) void {
        Stack()
            .width(.percent(100))
            .spacing(6)
            .children({
            var visible: usize = 0;
            for (self.todos.items) |*item| {
                if (!self.isVisible(item)) continue;
                visible += 1;
                self.renderItem(item);
            }

            if (visible == 0) {
                self.renderEmpty();
            }
        });
    }

    fn renderItem(self: *TodoList, item: *TodoItem) void {
        const is_editing = (self.editing_id == item.id);

        Row()
            .width(.percent(100))
            .padding(.xy(12, 10))
            .spacing(10)
            .layout(.left_center)
            .border(.round(Theme.border, .all(10)))
            .background(Theme.bg_card)
            .animationEnter("todo-item-enter")
            .children({
            // Checkbox
            Button(toggleCompleted, .{ self, item })
                .width(.px(22))
                .height(.px(22))
                .layout(.center)
                .border(.round(
                    if (item.completed) Theme.success else Theme.border,
                    .all(99),
                ))
                .background(if (item.completed) Theme.success else .transparent)
                .children({
                if (item.completed) {
                    Icon(.check)
                        .font(12, 700, .palette(.background))
                        .end();
                }
            });

            // Text — either label or inline editor
            Row().width(.grow).children({
                if (is_editing) {
                    // Bind directly to the todo's text slice. The framework
                    // table keys on the field's UUID, so edits flow live
                    // and the buffer is owned by the framework. When we
                    // exit edit mode, the slice still points at the
                    // (now framework-owned) updated buffer.
                    Vapor.TextField(.string)
                        .width(.percent(100))
                        .border(.round(Theme.border, .all(6)))
                        .padding(.all(4))
                        .bind(&item.text)
                        .end();
                } else {
                    Button(beginEdit, .{ self, item })
                        .width(.percent(100))
                        .padding(.xy(4, 2))
                        .background(.transparent)
                        .layout(.left_center)
                        .pointer()
                        .children({
                        Text(item.text)
                            .font(14, 400, if (item.completed) Theme.text_muted else Theme.text)
                            .fontFamily("Montserrat")
                            .ellipsis(.dot)
                            .end();
                    });
                }
            });

            // Action buttons
            if (is_editing) {
                Button(finishEdit, .{self})
                    .width(.px(28))
                    .height(.px(28))
                    .layout(.center)
                    .background(.transparent)
                    .pointer()
                    .hover(.{ .text_color = Theme.success })
                    .children({
                    Icon(.check)
                        .font(14, 400, Theme.text_muted)
                        .end();
                });
            }

            Button(deleteTodo, .{ self, item })
                .width(.px(28))
                .height(.px(28))
                .layout(.center)
                .background(.transparent)
                .pointer()
                .hover(.{ .text_color = Theme.danger })
                .children({
                Icon(.trash)
                    .font(13, 400, Theme.text_muted)
                    .end();
            });
        });
    }

    fn renderEmpty(self: *TodoList) void {
        const message = switch (self.filter) {
            .all => "Nothing yet — add your first todo above",
            .active => "No active todos — nice work",
            .completed => "Nothing completed yet",
        };

        Center()
            .width(.percent(100))
            .padding(.vertical(32))
            .children({
            Stack().layout(.center).spacing(8).children({
                Icon(.inbox)
                    .font(28, 400, Theme.text_muted)
                    .end();
                Text(message)
                    .font(13, 400, Theme.text_muted)
                    .fontFamily("Montserrat")
                    .end();
            });
        });
    }

    fn renderFooter(self: *TodoList) void {
        if (self.completedCount() == 0) return;

        Row()
            .width(.percent(100))
            .layout(.right_center)
            .children({
            Button(clearCompleted, .{self})
                .padding(.xy(10, 6))
                .background(.transparent)
                .pointer()
                .hover(.{ .text_color = Theme.danger })
                .children({
                Text("Clear completed")
                    .font(12, 500, Theme.text_muted)
                    .fontFamily("Montserrat")
                    .end();
            });
        });
    }
};
