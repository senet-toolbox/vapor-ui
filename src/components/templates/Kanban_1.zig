// ============================================================================
// Kanban Board — Advanced UI with Sortable Drag-and-Drop
// ============================================================================
//
// Refactored to a struct-level component so multiple boards can coexist with
// independent state. Truly shared resources (animations, theme, static option
// data, the type aliases) remain at module scope.

const std = @import("std");
const Vapor = @import("vapor");
const Text = Vapor.Text;
const Row = Vapor.Row;
const Stack = Vapor.Stack;
const Center = Vapor.Center;
const Icon = Vapor.Icon;
const TextFmt = Vapor.TextFmt;
const TextField = Vapor.TextField;
const Animation = Vapor.Animation;
const Opaque = @import("opaque-ui");
const Button = Opaque.Button;
const Alert = Opaque.Alert;
const DateTime = Vapor.DateTime;
const ProgressCircle = Opaque.ProgressCircle;
const ProgressBar = Opaque.ProgressBar;
const Sortable = Opaque.Sortable;

// ============================================================================
// TYPE ALIASES
// ============================================================================

pub const Select = Opaque.Select;
pub const Toast = Opaque.Toast;
pub const Sheet = Opaque.Sheet;
const Field = Opaque.TextField;
pub const Tooltip = Opaque.Tooltip;
pub const Switch = Opaque.Switch;
pub const Group = Opaque.Group;

// ============================================================================
// DATA TYPES
// ============================================================================

pub const TaskPriority = enum {
    low,
    medium,
    high,
    urgent,

    pub fn color(self: TaskPriority) Vapor.Types.Color {
        return switch (self) {
            .low => .hex("#1E00FF"),
            .medium => .hex("#FFD900"),
            .high => .hex("#C300FF"),
            .urgent => .palette(.danger),
        };
    }

    pub fn label(self: TaskPriority) []const u8 {
        return switch (self) {
            .low => "Low",
            .medium => "Medium",
            .high => "High",
            .urgent => "Urgent",
        };
    }

    pub fn icon(self: TaskPriority) Vapor.IconTokens {
        return switch (self) {
            .low => .flag,
            .medium => .flag_fill,
            .high => .exclamation_circle,
            .urgent => .exclamation_triangle_fill,
        };
    }
};

pub const TaskStatus = enum {
    backlog,
    todo,
    in_progress,
    review,
    done,

    pub fn label(self: TaskStatus) []const u8 {
        return switch (self) {
            .backlog => "Backlog",
            .todo => "To Do",
            .in_progress => "In Progress",
            .review => "Review",
            .done => "Done",
        };
    }

    pub fn color(self: TaskStatus) Vapor.Types.Color {
        return switch (self) {
            .backlog => .hex("#6b7280"),
            .todo => .hex("#3b82f6"),
            .in_progress => .hex("#8b5cf6"),
            .review => .hex("#f59e0b"),
            .done => .hex("#10b981"),
        };
    }

    pub fn icon(self: TaskStatus) Vapor.IconTokens {
        return switch (self) {
            .backlog => .inbox,
            .todo => .circle,
            .in_progress => .play_circle,
            .review => .eye,
            .done => .check_circle_fill,
        };
    }
};

pub const Task = struct {
    id: usize,
    title: []const u8,
    description: []const u8,
    status: TaskStatus,
    priority: TaskPriority,
    assignee: ?[]const u8,
    tags: []const []const u8,
    due_date: ?Vapor.DateTime,
    created_at: []const u8,
    progress: ?ProgressCircle = null,
    percent: f64 = 0,
    position: []const u8 = "n", // fractional index key for sortable ordering
};

// ============================================================================
// THEME (shared — no reason to duplicate per instance)
// ============================================================================

const Theme = struct {
    const bg_base = Vapor.Types.Color.palette(.background);
    const bg_card = Vapor.Types.Color.palette(.background);
    const bg_elevated = Vapor.Types.Color.palette(.background);
    const bg_hover = Vapor.Types.Color.hex("#3f3f46");
    const border = Vapor.Types.Color.hex("#27272a");
    const border_light = Vapor.Types.Color.hex("#3f3f46");
    const text = Vapor.Types.Color.palette(.text_color);
    const text_secondary = Vapor.Types.Color.hex("#a1a1aa");
    const text_muted = Vapor.Types.Color.hex("#71717a");
    const accent = Vapor.Types.Color.hex("#6366f1");
    const accent_hover = Vapor.Types.Color.hex("#818cf8");
    const success = Vapor.Types.Color.hex("#10b981");
    const warning = Vapor.Types.Color.hex("#F5590B");
    const err = Vapor.Types.Color.palette(.danger);
    const gradient_start = Vapor.Types.Color.hex("#6366f1");
    const gradient_end = Vapor.Types.Color.hex("#8b5cf6");
};

// ============================================================================
// SHARED ANIMATIONS — built once via Kanban.initShared(), reused by all boards
// ============================================================================

const pulse_glow = Animation.init("kanban-pulse-glow")
    .prop(.opacity, 1, 0.5)
    .duration(2000)
    .dir(.alternate)
    .infinite();

const slide_up = Animation.init("kanban-slide-up")
    .prop(.translateY, 20, 0)
    .prop(.opacity, 0, 1)
    .duration(300)
    .easing(.easeOut)
    .fill(.forwards);

const fade_scale = Animation.init("kanban-fade-scale")
    .prop(.scale, 0.95, 1)
    .prop(.opacity, 0, 1)
    .duration(200)
    .easing(.easeOut)
    .fill(.forwards);

const card_enter = Animation.init("kanban-card-enter")
    .prop(.translateY, 10, 0)
    .prop(.opacity, 0, 1)
    .duration(200)
    .easing(.easeOut)
    .fill(.forwards);

const modal_enter = Animation.init("kanban-modal-enter")
    .prop(.scale, 0.95, 1)
    .prop(.opacity, 0, 1)
    .duration(200)
    .easing(.easeOutBack)
    .fill(.forwards);

// ============================================================================
// SHARED STATIC OPTION DATA
// ============================================================================
//
// Select.Item arrays describe the list of choices. The chosen *value* is
// stored on the Kanban instance via on_select; the option list itself never
// mutates, so it's fine (and cheap) to share.

var priority_options = [_]Select(TaskPriority).Item{
    .{ .value = .low, .label = "Low" },
    .{ .value = .medium, .label = "Medium" },
    .{ .value = .high, .label = "High" },
    .{ .value = .urgent, .label = "Urgent" },
};

var status_options = [_]Select(TaskStatus).Item{
    .{ .value = .backlog, .label = "Backlog" },
    .{ .value = .todo, .label = "To Do" },
    .{ .value = .in_progress, .label = "In Progress" },
    .{ .value = .review, .label = "Review" },
    .{ .value = .done, .label = "Done" },
};

// Shared RNG for seeding mock progress values; not state that any
// individual board reads back from, so global is fine.
var rand = std.Random.DefaultPrng.init(0);

// ============================================================================
// KANBAN STRUCT
// ============================================================================

const ColumnId = enum { backlog, todo, review, in_progress, done };
const Ctx = Sortable.DragContext(ColumnId);

pub const Kanban = struct {
    // ------------------------------------------------------------------------
    // Sortable collection type — parameterized on the *outer* Kanban so its
    // callbacks can recover the instance from the collection pointer via
    // @fieldParentPtr. Defining this inside the struct keeps the per-instance
    // dispatch self-contained.
    // ------------------------------------------------------------------------
    pub const TaskCollection = Sortable.Collection(Task, ColumnId, .{
        .id_field = "id",
        .direction = .vertical,
        .on_reorder = onReorderCb,
        // .on_transfer = onTransferCb,
        .show_drag_overlay = false,
        .gap_render = gapRender,
        .no_items_render = noItemsRender,
        .height = 156,
        .gap_height = 16,
    });

    // ------------------------------------------------------------------------
    // Per-instance state
    // ------------------------------------------------------------------------

    // Drag context shared across this board's columns (NOT across boards).
    drag_ctx: Ctx = .{},

    // One sortable collection per kanban column.
    backlog_col: TaskCollection = undefined,
    todo_col: TaskCollection = undefined,
    in_progress_col: TaskCollection = undefined,
    review_col: TaskCollection = undefined,
    done_col: TaskCollection = undefined,

    next_task_id: usize = 100,
    show_completed: bool = true,
    search_query: []const u8 = "",
    filter_priority: ?TaskPriority = null,
    selected_task: ?*const Task = null,

    // New task form state
    new_task_title: []const u8 = "",
    new_task_description: []const u8 = "",
    new_task_priority: TaskPriority = .medium,
    new_task_status: TaskStatus = .todo,

    // Component instances
    detail_sheet: Sheet = undefined,
    priority_filter: Select(TaskPriority) = undefined,
    status_select: Select(TaskStatus) = undefined,
    alert: Alert = undefined,

    bar: ProgressBar = undefined,
    progress_bar_tooltip: ProgressBar = undefined,

    total_completed: f64 = 0.34,

    // ========================================================================
    // SHARED INITIALIZATION
    // ========================================================================
    //
    // Call this exactly once per process, before instantiating any Kanban.
    // It builds the shared animations and bootstraps the Sortable subsystem.
    // ========================================================================

    pub fn initShared() void {
        pulse_glow.build();
        slide_up.build();
        fade_scale.build();
        card_enter.build();
        modal_enter.build();
        Sortable.new();
    }

    // ========================================================================
    // INSTANCE INITIALIZATION
    // ========================================================================

    pub fn init(self: *Kanban) void {
        self.* = .{};

        self.drag_ctx.init();

        // Seed each column. Names ("backlog", "todo", ...) are used in
        // var backlog_task = Vapor.persist.array(Task);

        // for (20..120) |i| {
        //     const task = makeTask(i, "Database schema review", "Review and optimize current database schema", .backlog, .medium, null, &.{ "backend", "database" }, null, "Jan 10", "f");
        //     backlog_task.append(task);
        // }
        //
        // self.backlog_col.init(&self.drag_ctx, .backlog, backlog_task.items);
        self.backlog_col.init(&self.drag_ctx, .backlog, &.{
            makeTask(5, "Database schema review", "Review and optimize current database schema", .backlog, .medium, null, &.{ "backend", "database" }, null, "Jan 10", "f"),
            makeTask(8, "Performance audit", "Run Lighthouse and optimize critical metrics", .backlog, .low, null, &.{"performance"}, null, "Jan 12", "n"),
        });
        self.backlog_col.onTransfer(onTransferCb, .{self});

        self.todo_col.init(&self.drag_ctx, .todo, &.{
            makeTask(4, "API documentation", "Document all REST endpoints with examples", .todo, .low, "Alex", &.{ "docs", "api" }, DateTime.fromDayMonthYear(21, 1, 2026), "Jan 20", "d"),
            makeTask(6, "Mobile responsive layout", "Ensure all pages work on mobile devices", .todo, .high, "Sarah", &.{ "frontend", "mobile" }, DateTime.fromDayMonthYear(12, 8, 2026), "Jan 7", "h"),
            makeTask(9, "Notification system", "Build real-time notification infrastructure", .todo, .high, "Alex", &.{ "backend", "realtime" }, DateTime.fromDayMonthYear(3, 6, 2026), "Jan 10", "l"),
        });
        self.todo_col.onTransfer(onTransferCb, .{self});

        self.in_progress_col.init(&self.drag_ctx, .in_progress, &.{
            makeTask(2, "User authentication flow", "Implement login, signup, and password reset", .in_progress, .urgent, "Mike", &.{ "backend", "security" }, DateTime.fromDayMonthYear(13, 1, 2026), "Jan 8", "f"),
            makeTask(7, "Unit test coverage", "Increase test coverage to 80%", .in_progress, .medium, "Mike", &.{ "testing", "quality" }, DateTime.fromDayMonthYear(17, 4, 2026), "Jan 11", "n"),
        });
        self.in_progress_col.onTransfer(onTransferCb, .{self});

        self.review_col.init(&self.drag_ctx, .review, &.{
            makeTask(3, "Dashboard wireframes", "Create low-fidelity wireframes for main dashboard", .review, .medium, "Sarah", &.{"design"}, DateTime.fromDayMonthYear(8, 1, 2026), "Jan 6", "f"),
            makeTask(10, "Settings page", "User preferences and account settings UI", .review, .medium, "Sarah", &.{ "frontend", "ui" }, DateTime.fromDayMonthYear(28, 4, 2026), "Jan 8", "n"),
        });
        self.review_col.onTransfer(onTransferCb, .{self});

        self.done_col.init(&self.drag_ctx, .done, &.{
            makeTask(1, "Design system setup", "Create color tokens, typography scale, and spacing system", .done, .high, "Sarah", &.{ "design", "foundation" }, DateTime.fromDayMonthYear(1, 1, 2026), "Jan 5", "n"),
        });
        self.done_col.onTransfer(onTransferCb, .{self});

        // Selects — share the static option arrays.
        self.priority_filter = .fromItems(&priority_options);
        self.priority_filter.trigger = "Priority";
        self.priority_filter.on_select = setFilterPriorityCb;

        self.status_select = .fromItems(&status_options);
        self.status_select.trigger = "Status";

        self.detail_sheet = Sheet.init(.right);
        self.detail_sheet.content = renderDetailSheetContentCb;
        self.alert = .init(renderAddModalCb);

        self.bar = ProgressBar.init(Vapor.persist.arena(), .{
            .width = 128,
            .height = 6,
            .color = .palette(.tint),
            .background = .transparentize(.palette(.text_color), 0.1),
        });
        self.bar.setProgress(self.doneProgress());

        self.progress_bar_tooltip = ProgressBar.init(Vapor.persist.arena(), .{
            .width = 128,
            .height = 6,
            .color = .palette(.tint),
            .background = .transparentize(.palette(.text_color), 0.1),
        });
        self.progress_bar_tooltip.setProgress(0);
    }

    // ========================================================================
    // CALLBACK BRIDGES
    // ========================================================================
    //
    // The Sortable / Select / Sheet / Alert APIs take plain function pointers
    // with fixed signatures. They give us a pointer to the embedded component
    // (or, for Sortable, to the collection / drag context). We recover the
    // owning Kanban via @fieldParentPtr and dispatch to a method.
    // ========================================================================

    fn onReorderCb(event: Sortable.ReorderEvent(Task)) void {
        // Both endpoints of a reorder live within the same collection, so the
        // collection pointer (and thus the Kanban) is unambiguous. The event
        // currently doesn't carry the *Kanban directly, but onReorder is a
        // pure log/persist hook — no instance state is touched.
        std.log.info("Reorder: '{s}' from {d} to {d}, position key: {s}\n", .{
            event.item.title,
            event.from_index,
            event.to_index,
            event.position,
        });
    }

    fn onTransferCb(self: *Kanban, event: Sortable.TransferEvent(Task, ColumnId)) void {

        // Update the moved task's status to match its new column.
        const new_status: TaskStatus = switch (event.to_collection) {
            .backlog => .backlog,
            .todo => .todo,
            .in_progress => .in_progress,
            .review => .review,
            .done => .done,
        };
        event.item.status = new_status;

        std.log.info("Transfer: '{s}' from {any} to {any} at index {d}, position key: {s}\n", .{
            event.item.title,
            event.from_collection,
            event.to_collection,
            event.to_index,
            event.position,
        });

        Toast.info(.{
            .title = "Task Moved",
            .description = new_status.label(),
        });

        const done_progress = self.doneProgress();
        self.bar.updateProgress(done_progress);
    }

    fn setFilterPriorityCb(sel: *Select(TaskPriority), item: *Select(TaskPriority).Item) void {
        const self: *Kanban = Vapor.parentPtr(Kanban, "priority_filter", sel);
        if (self.filter_priority == item.value) {
            self.filter_priority = null;
        } else {
            self.filter_priority = item.value;
        }
        self.applyFilters(); // <-- add this
    }

    fn renderAddModalCb(a: *Alert) void {
        const self: *Kanban = Vapor.parentPtr(Kanban, "alert", a);
        self.renderAddModal();
    }

    fn renderDetailSheetContentCb(s: *Sheet) void {
        const self: *Kanban = Vapor.parentPtr(Kanban, "detail_sheet", s);
        self.renderDetailSheetContent();
    }

    // ========================================================================
    // EVENT HANDLERS (instance methods — passed to Vapor.Button via .{ self, ... })
    // ========================================================================

    pub fn openAddModal(self: *Kanban) void {
        self.new_task_title = "";
        self.new_task_description = "";
        self.new_task_priority = .medium;
        self.new_task_status = .todo;
        self.alert.open();
    }

    pub fn closeAddModal(self: *Kanban) void {
        self.alert.close();
    }

    pub fn addTask(self: *Kanban) void {
        if (self.new_task_title.len == 0) return;

        const task = makeTask(
            self.next_task_id,
            Vapor.persist.dupe(self.new_task_title),
            Vapor.persist.dupe(self.new_task_description),
            self.new_task_status,
            self.new_task_priority,
            null,
            &.{},
            null,
            "Today",
            "z",
        );

        const col = self.collectionForStatus(self.new_task_status);
        col.append(task) catch return;

        self.next_task_id += 1;
        self.closeAddModal();
        Toast.success(.{ .title = "Task Created", .description = "New task has been added to the board" });
    }

    pub fn deleteTaskFromCollection(self: *Kanban, task: *Task) void {
        const col = self.collectionForStatus(task.status);
        const t = col.removeByPtr(task) orelse return;
        Toast.warning(.{ .title = Vapor.frame.fmt("Deleted {s}", .{t.title}), .description = "This action cannot be undone" });
    }

    pub fn handleViewTask(self: *Kanban, task: *Task) void {
        self.selected_task = task;
        self.detail_sheet.open();
    }

    pub fn closeDetailSheet(self: *Kanban) void {
        self.detail_sheet.close();
        self.selected_task = null;
    }

    pub fn toggleCompleted(self: *Kanban) void {
        self.show_completed = !self.show_completed;
        if (self.show_completed) {
            Toast.info(.{ .title = "Showing Completed", .description = "Done tasks are now visible" });
        } else {
            Toast.info(.{ .title = "Hiding Completed", .description = "Done tasks are now hidden" });
        }
    }

    pub fn handleExport(_: *Kanban) void {
        Toast.info(.{ .title = "Exporting Data", .description = "Your board data will be ready shortly" });
    }

    pub fn handleRefresh(_: *Kanban) void {
        Toast.success(.{ .title = "Board Refreshed", .description = "All tasks are up to date" });
    }

    pub fn addTaskToColumn(self: *Kanban, status: TaskStatus) void {
        self.new_task_status = status;
        self.openAddModal();
    }

    pub fn selectPriority(self: *Kanban, priority: TaskPriority) void {
        self.new_task_priority = priority;
    }

    pub fn selectStatus(self: *Kanban, status: TaskStatus) void {
        self.new_task_status = status;
    }

    pub fn moveTaskLeft(self: *Kanban, task: *Task) void {
        const old_status = task.status;
        const new_status: TaskStatus = switch (old_status) {
            .backlog => .backlog,
            .todo => .backlog,
            .in_progress => .todo,
            .review => .in_progress,
            .done => .review,
        };
        if (old_status != new_status) {
            task.status = new_status;
            const from_col = self.collectionForStatus(old_status);
            const to_col = self.collectionForStatus(new_status);
            from_col.transferTo(to_col, task);
        }
    }

    pub fn moveTaskRight(self: *Kanban, task: *Task) void {
        const old_status = task.status;
        const new_status: TaskStatus = switch (old_status) {
            .backlog => .todo,
            .todo => .in_progress,
            .in_progress => .review,
            .review => .done,
            .done => .done,
        };
        if (old_status != new_status) {
            task.status = new_status;
            const from_col = self.collectionForStatus(old_status);
            const to_col = self.collectionForStatus(new_status);
            from_col.transferTo(to_col, task);
        }
    }

    fn canMoveLeft(status: TaskStatus) bool {
        return status != .backlog;
    }

    fn canMoveRight(status: TaskStatus) bool {
        return status != .done;
    }

    // ========================================================================
    // HELPERS
    // ========================================================================

    pub fn totalTaskCount(self: *Kanban) usize {
        return self.backlog_col.count() +
            self.todo_col.count() +
            self.in_progress_col.count() +
            self.review_col.count() +
            self.done_col.count();
    }

    pub fn doneProgress(self: *Kanban) f32 {
        const done_collection = self.collectionForStatus(.done);
        const done_count = done_collection.count();
        const total_count = self.totalTaskCount();
        const result = @as(f32, @floatFromInt(done_count)) / @as(f32, @floatFromInt(total_count));
        return result;
    }

    fn matchesFilter(self: *Kanban, task: *const Task) bool {
        if (self.filter_priority) |priority| {
            if (task.priority != priority) return false;
        }
        if (self.search_query.len > 0) {
            const title_lower = Vapor.frame.toLowerCase(task.title);
            const query_lower = Vapor.frame.toLowerCase(self.search_query);
            if (std.mem.indexOf(u8, title_lower, query_lower) == null) return false;
        }

        return true;
    }

    fn collectionForStatus(self: *Kanban, status: TaskStatus) *TaskCollection {
        return switch (status) {
            .backlog => &self.backlog_col,
            .todo => &self.todo_col,
            .in_progress => &self.in_progress_col,
            .review => &self.review_col,
            .done => &self.done_col,
        };
    }

    // ========================================================================
    // RENDERING
    // ========================================================================

    pub fn render(self: *Kanban) void {
        Row()
            .width(.percent(100))
            .height(.percent(100))
            .background(Theme.bg_base)
            .layout(.top_left)
            .children({

            // Main content area
            Stack()
                .width(.percent(100))
                .height(.percent(100))
                .children({
                self.renderHeader();
                self.renderBoard();
            });

            // Floating drag preview during an active drag
            self.drag_ctx.dragLayerTyped(Task, renderDragOverlay);

            // Overlays
            self.detail_sheet.render();
            self.alert.render();
        });
    }

    // --- Navigation -------------------------------------------------------
    //
    // Kept as an instance method even though most of it is static, because
    // the stat counts on the right depend on this instance.
    pub fn renderNavigation(self: *Kanban) void {
        Stack()
            .width(.px(240))
            .height(.percent(100))
            .padding(.all(20))
            .spacing(24)
            .children({
            // Logo
            Row()
                .layout(.left_center)
                .spacing(12)
                .children({
                Row()
                    .width(.px(40))
                    .height(.px(40))
                    .background(.black)
                    .border(.round(.black, .all(8)))
                    .layout(.center)
                    .children({
                    Icon(.kanban)
                        .font(20, 700, .white)
                        .end();
                });
                Stack()
                    .spacing(0)
                    .children({
                    Text("Kanban")
                        .font(20, 700, Theme.text)
                        .fontFamily("Montserrat")
                        .end();
                    Text("Board")
                        .font(11, 500, Theme.text_muted)
                        .fontFamily("Montserrat")
                        .end();
                });
            });

            // Navigation
            Stack()
                .width(.percent(100))
                .spacing(4)
                .children({
                Text("VIEWS")
                    .font(10, 600, Theme.text_muted)
                    .fontFamily("Montserrat")
                    .margin(.{ .bottom = 8 })
                    .end();

                renderNavButton("Board", .kanban, true);
                renderNavButton("List", .list_ul, false);
                renderNavButton("Calendar", .calendar, false);
                renderNavButton("Timeline", .bar_chart_line, false);
            });

            // Stats
            Stack()
                .width(.percent(100))
                .spacing(4)
                .children({
                Text("STATISTICS")
                    .font(10, 600, Theme.text_muted)
                    .fontFamily("Montserrat")
                    .margin(.{ .bottom = 8 })
                    .end();

                renderStatRow("Total Tasks", self.totalTaskCount());
                renderStatRow("In Progress", self.in_progress_col.count());
                renderStatRow("Completed", self.done_col.count());
            });

            Row().height(.grow).children({});

            // User profile
            Row()
                .width(.percent(100))
                .padding(.all(8))
                .layout(.left_center)
                .spacing(12)
                .children({
                Stack()
                    .spacing(0)
                    .width(.grow)
                    .children({
                    Text("Vic Rokx")
                        .font(14, 500, Theme.text)
                        .fontFamily("Montserrat")
                        .end();
                    Text("Project Manager")
                        .font(12, 400, Theme.text_muted)
                        .fontFamily("Montserrat")
                        .end();
                });
                Icon(.chevron_expand)
                    .font(14, 400, Theme.text_muted)
                    .end();
            });
        });
    }

    fn applyFilters(self: *Kanban) void {
        if (self.filter_priority != null or self.search_query.len > 0) {
            self.drag_ctx.setFilter(Task, filterTrampoline, .{self});
        } else {
            self.drag_ctx.clearFilter();
        }
    }

    fn filter(self: *Kanban) void {
        self.applyFilters();
    }

    // --- Header -----------------------------------------------------------
    fn renderHeader(self: *Kanban) void {
        Row()
            .width(.percent(100))
            .padding(.xy(28, 16))
            .responsive(.mobile, .{ .padding = .xy(8, 12) })
            .background(Theme.bg_base)
            .layout(.x_between_center)
            .wrap(.wrap)
            .spacing(12)
            .children({
            // Title
            Stack()
                .spacing(4)
                .layout(.left_center)
                .children({
                Text("Kanban Board")
                    .font(24, 700, Theme.text)
                    .fontFamily("Montserrat")
                    .end();
            });

            // Controls
            Row()
                .layout(.right_center)
                .wrap(.wrap)
                .spacing(12)
                .children({
                // Search
                Row()
                    .width(.px(200))
                    .layout(.left_center)
                    .spacing(8)
                    .children({
                    Field(.{ .label = "Search...", .value = .{ .string = &self.search_query } })
                        .onChange(filter, .{self})
                        .render();
                });

                // Priority filter
                Row()
                    .width(.px(140))
                    .children({
                    self.priority_filter.renderPos(.bottom);
                });

                // Toggle completed
                Button(toggleCompleted, .{self})
                    .padding(.xy(14, 9))
                    .children({
                    if (self.show_completed) {
                        Row()
                            .width(.px(8))
                            .height(.px(8))
                            .background(.palette(.tint))
                            .border(.round(.palette(.tint), .all(99)))
                            .animation("kanban-pulse-glow")
                            .children({});
                    }
                    Text(if (self.show_completed) "Hide Done" else "Show Done")
                        .font(13, 500, if (self.show_completed) .palette(.tint) else Theme.text_secondary)
                        .fontFamily("Montserrat")
                        .end();
                });

                Button(handleExport, .{self})
                    .padding(.xy(14, 9))
                    .children({
                    Text("Export")
                        .font(13, 500, .palette(.text_color))
                        .fontFamily("Montserrat")
                        .end();
                    Icon(.download)
                        .font(14, 400, .palette(.text_color))
                        .end();
                });

                Button(handleRefresh, .{self})
                    .ariaLabel("Refresh")
                    .width(.px(40))
                    .height(.px(40))
                    .layout(.center)
                    .pointer()
                    .children({
                    Icon(.arrow_clockwise)
                        .inheritHover(&.{.text_color})
                        .font(18, 700, .palette(.text_color))
                        .end();
                });

                Button(openAddModal, .{self})
                    .padding(.xy(14, 9))
                    .background(.palette(.tint))
                    .children({
                    Icon(.plus)
                        .font(14, 600, .palette(.background))
                        .end();
                    Text("Add Task")
                        .font(13, 500, .palette(.background))
                        .fontFamily("Montserrat")
                        .end();
                });
            });
        });

        // Progress strip below header
        Row()
            .width(.percent(100))
            .padding(.horizontal(28))
            .responsive(.mobile, .{ .padding = .horizontal(8) })
            .layout(.left_center)
            .spacing(16)
            .children({
            Row()
                .spacing(8)
                .padding(.xy(16, 6))
                .border(.round(.palette(.border_color_light), .all(6)))
                .layout(.left_center)
                .children({
                Text("Board Progress").font(14, 300, Theme.text).end();
                self.bar.render();
                TextFmt("{d:.1}%", .{self.doneProgress() * 100})
                    .font(14, 300, Theme.text)
                    .fontFamily("Montserrat")
                    .end();
            });
        });
    }

    // --- Board ------------------------------------------------------------
    fn renderBoard(self: *Kanban) void {
        // The columns share the width down to 220px each; narrower than
        // that, the board scrolls sideways.
        Row()
            .width(.percent(100))
            .height(.fit)
            .padding(.all(28))
            .responsive(.mobile, .{ .padding = .all(8) })
            .layout(.top_left)
            .spacing(20)
            .scroll(.scrollX())
            .children({
            for (std.enums.values(TaskStatus)) |status| {
                if (status == .done and !self.show_completed) continue;
                self.renderColumn(status, self.collectionForStatus(status));
            }
        });
    }

    fn filterTrampoline(self: *Kanban, task: *const Task) bool {
        return self.matchesFilter(task);
    }

    fn renderColumn(self: *Kanban, status: TaskStatus, collection: *TaskCollection) void {
        const visible = collection.visibleCount();

        Row()
            .width(.expand)
            .inlineStyle("min-width: 220px;", .{})
            .direction(.column)
            .border(.round(.palette(.border_color_light), .all(20)))
            .padding(.all(8))
            .spacing(12)
            .children({
            // Column header
            Row()
                .layout(.x_between_center)
                .children({
                Row()
                    .layout(.left_center)
                    .spacing(10)
                    .children({
                    Row()
                        .padding(.xy(8, 4))
                        .children({
                        TextFmt("{d}", .{visible})
                            .font(14, 300, null)
                            .end();
                    });
                    Text(status.label())
                        .font(16, 300, Theme.text)
                        .fontFamily("Montserrat")
                        .end();
                });

                Vapor.Button(addTaskToColumn, .{ self, status })
                    .ariaLabel("Add task")
                    .layout(.center)
                    .duration(100)
                    .textColor(Theme.text_muted)
                    .pointer()
                    .hover(.{ .text_color = .palette(.highlight_color) })
                    .children({
                    Icon(.plus)
                        .fontSize(22)
                        .end();
                });
            });

            var surface = collection.surface();
            surface.container = surface.container
                .width(.percent(100))
                .height(.grow)
                .spacing(10)
                .scroll(.scrollY());
            surface.render(renderTaskCardTrampoline, .{self});
        });
    }

    // --- Per-card render --------------------------------------------------
    fn renderTaskCard(self: *Kanban, task: *Task, state: Sortable.ItemState) void {
        Row()
            .layout(.y_between)
            .inlineStyle("user-select: none;", .{})
            .width(.percent(100))
            .padding(.{ .top = 14 })
            .animationEnter("kanban-card-enter")
            .border(.round(
                if (state.is_dragging) .transparentize(.palette(.tint), 0.3) else .palette(.border_color_light),
                .all(20),
            ))
            .opacity(if (state.is_placeholder) 0.3 else 1.0)
            .background(if (state.is_dragging) .transparent else Theme.bg_card)
            .direction(.column)
            .pointer()
            .duration(100)
            .hover(.{
                .shadow = Vapor.Types.NewShadow.init().drop(0, 2, 8, .transparentize(.black, 0.05)),
            })
            .children({
            Stack()
                .width(.percent(100))
                .spacing(10)
                .children({
                // Title and priority
                Row()
                    .padding(.horizontal(14))
                    .layout(.x_between_center)
                    .children({
                    Text(task.title)
                        .ellipsis(.dot)
                        .font(14, 500, Theme.text)
                        .fontFamily("Montserrat")
                        .width(.percent(70))
                        .end();
                    Row()
                        .padding(.xy(6, 3))
                        .children({
                        Text(task.priority.label())
                            .font(10, 300, task.priority.color())
                            .fontFamily("Montserrat")
                            .end();
                    });
                });

                // Description
                if (task.description.len > 0) {
                    Text(task.description)
                        .padding(.horizontal(14))
                        .font(12, 400, Theme.text_secondary)
                        .ellipsis(.dot)
                        .fontFamily("Montserrat")
                        .end();
                }

                // Due date
                if (task.due_date) |due| {
                    Row()
                        .padding(.horizontal(14))
                        .layout(.left_center)
                        .spacing(4)
                        .children({
                        Icon(.calendar)
                            .font(11, 400, Theme.text_muted)
                            .end();
                        Text(due.formatDate(Vapor.frame.arena()) catch "")
                            .font(11, 400, Theme.text_muted)
                            .fontFamily("Montserrat")
                            .end();
                    });
                }
            });
            // Footer
            Row()
                .width(.percent(100))
                .layout(.x_between_center)
                .padding(.xy(10, 4))
                .border(.top(1, .palette(.border_color_light)))
                .children({
                Row()
                    .layout(.left_center)
                    .spacing(12)
                    .width(.px(36))
                    .height(.px(36))
                    .children({
                    if (task.assignee) |assignee| {
                        Tooltip.create(.{
                            .background = .palette(.background),
                            .stroke_color = .palette(.border_color_light),
                        })
                            .Trigger(tooltipTriggerTrampoline, .{assignee})
                            .Component(tooltipContentTrampoline, .{ self, task })
                            .end();
                    }
                });

                // Actions
                Row()
                    .layout(.right_center)
                    .spacing(4)
                    .children({
                    // Progress
                    Row()
                        .height(.px(24))
                        .layout(.center)
                        .background(.transparent)
                        .pointer()
                        .textColor(Theme.text_muted)
                        .spacing(8)
                        .children({
                        TextFmt("{d}%", .{task.percent})
                            .fontFamily("Montserrat")
                            .font(12, 400, null)
                            .end();
                        if (task.progress) |*progress| {
                            progress.render();
                        }
                    });

                    // View
                    Vapor.Button(handleViewTask, .{ self, task })
                        .ariaLabel("View task")
                        .width(.px(24))
                        .height(.px(24))
                        .layout(.center)
                        .background(.transparent)
                        .pointer()
                        .textColor(Theme.text_muted)
                        .hover(.{ .text_color = .palette(.highlight_color) })
                        .children({
                        Icon(.eye)
                            .font(12, 400, null)
                            .end();
                    });

                    // Move left
                    if (canMoveLeft(task.status)) {
                        Vapor.Button(moveTaskLeft, .{ self, task })
                            .ariaLabel("Move task left")
                            .width(.px(24))
                            .height(.px(24))
                            .layout(.center)
                            .background(.transparent)
                            .pointer()
                            .textColor(Theme.text_muted)
                            .hover(.{ .text_color = .palette(.highlight_color) })
                            .children({
                            Icon(.chevron_left)
                                .font(12, 400, null)
                                .end();
                        });
                    }

                    // Move right
                    if (canMoveRight(task.status)) {
                        Vapor.Button(moveTaskRight, .{ self, task })
                            .ariaLabel("Move task right")
                            .width(.px(24))
                            .height(.px(24))
                            .layout(.center)
                            .background(.transparent)
                            .pointer()
                            .textColor(Theme.text_muted)
                            .hover(.{ .text_color = .palette(.highlight_color) })
                            .children({
                            Icon(.chevron_right)
                                .font(12, 400, null)
                                .end();
                        });
                    }

                    // Delete
                    Vapor.Button(deleteTaskFromCollection, .{ self, task })
                        .ariaLabel("Delete task")
                        .width(.px(24))
                        .height(.px(24))
                        .layout(.center)
                        .background(.transparent)
                        .pointer()
                        .textColor(Theme.text_muted)
                        .hover(.{ .text_color = .palette(.danger) })
                        .children({
                        Icon(.trash)
                            .font(14, 400, null)
                            .end();
                    });
                });
            });
        });
    }

    // --- Tooltip ----------------------------------------------------------
    fn tooltipContent(self: *Kanban, task: *Task) void {
        self.progress_bar_tooltip.setProgress(task.percent / 100.0);
        Row()
            .width(.px(280))
            .padding(.all(16))
            .background(Theme.bg_card)
            .border(.round(.palette(.border_color_light), .all(12)))
            .direction(.column)
            .spacing(12)
            .animationEnter("kanban-fade-scale")
            .children({
            Row()
                .layout(.x_between_center)
                .children({
                Text(task.title)
                    .font(14, 600, Theme.text)
                    .fontFamily("Montserrat")
                    .width(.px(180))
                    .ellipsis(.dot)
                    .end();
                Row()
                    .padding(.xy(8, 4))
                    .background(.transparentize(task.priority.color(), 0.2))
                    .border(.round(task.priority.color(), .all(6)))
                    .children({
                    Text(task.priority.label())
                        .font(10, 500, task.priority.color())
                        .fontFamily("Montserrat")
                        .end();
                });
            });

            Row()
                .width(.percent(100))
                .height(.px(1))
                .background(.palette(.border_color_light))
                .children({});

            Stack()
                .width(.percent(100))
                .spacing(8)
                .children({
                if (task.due_date) |due| {
                    Row()
                        .width(.percent(100))
                        .layout(.x_between_center)
                        .children({
                        Row()
                            .layout(.left_center)
                            .spacing(6)
                            .children({
                            Icon(.calendar)
                                .font(12, 400, Theme.text_muted)
                                .end();
                            Text("Due date")
                                .font(12, 400, Theme.text_muted)
                                .fontFamily("Montserrat")
                                .end();
                        });
                        Text(due.formatDate(Vapor.frame.arena()) catch "")
                            .font(12, 500, Theme.text)
                            .fontFamily("Montserrat")
                            .end();
                    });
                }

                Row()
                    .width(.percent(100))
                    .layout(.x_between_center)
                    .children({
                    Row()
                        .layout(.left_center)
                        .spacing(6)
                        .children({
                        Icon(.clock)
                            .font(12, 400, Theme.text_muted)
                            .end();
                        Text("Created")
                            .font(12, 400, Theme.text_muted)
                            .fontFamily("Montserrat")
                            .end();
                    });
                    Text(task.created_at)
                        .font(12, 500, Theme.text)
                        .fontFamily("Montserrat")
                        .end();
                });

                if (task.assignee) |assignee| {
                    Row()
                        .width(.percent(100))
                        .layout(.x_between_center)
                        .children({
                        Text("Assignee")
                            .font(12, 400, Theme.text_muted)
                            .fontFamily("Montserrat")
                            .end();
                        Text(assignee)
                            .font(12, 500, Theme.text)
                            .fontFamily("Montserrat")
                            .end();
                    });
                }
            });

            Row()
                .width(.percent(100))
                .padding(.all(10))
                .border(.round(.palette(.border_color_light), .all(8)))
                .layout(.x_between_center)
                .children({
                Text("Progress")
                    .font(12, 400, Theme.text_muted)
                    .fontFamily("Montserrat")
                    .end();
                Row()
                    .layout(.right_center)
                    .spacing(10)
                    .children({
                    self.progress_bar_tooltip.render();
                    TextFmt("{d}%", .{task.percent})
                        .font(12, 600, Theme.text)
                        .fontFamily("Montserrat")
                        .end();
                });
            });
        });
    }

    // --- Add modal --------------------------------------------------------
    fn renderAddModal(self: *Kanban) void {
        Row()
            .width(.px(480))
            .padding(.all(24))
            .direction(.column)
            .spacing(20)
            .animationEnter("kanban-modal-enter")
            .children({
            // Header
            Row()
                .layout(.x_between_center)
                .children({
                Text("Add New Task")
                    .font(20, 700, Theme.text)
                    .fontFamily("Montserrat")
                    .end();
                Vapor.Button(closeAddModal, .{self})
                    .ariaLabel("Close")
                    .width(.px(36))
                    .height(.px(36))
                    .layout(.center)
                    .pointer()
                    .children({
                    Icon(.x_lg)
                        .font(16, 400, Theme.text_secondary)
                        .end();
                });
            });

            // Form
            Stack()
                .spacing(16)
                .children({
                // Title
                Stack()
                    .spacing(6)
                    .children({
                    Text("Title")
                        .font(13, 500, Theme.text_secondary)
                        .fontFamily("Montserrat")
                        .end();
                    Row()
                        .width(.percent(100))
                        .layout(.left_center)
                        .children({
                        Field(.{ .label = "Title", .value = .{ .string = &self.new_task_title } }).render();
                    });
                });

                // Description
                Stack()
                    .spacing(6)
                    .children({
                    Text("Description")
                        .font(13, 500, Theme.text_secondary)
                        .fontFamily("Montserrat")
                        .end();
                    Row()
                        .width(.percent(100))
                        .height(.px(100))
                        .children({
                        Vapor.TextArea()
                            .background(.palette(.background))
                            .bind(&self.new_task_description)
                            .ariaLabel("Text Area")
                            .width(.percent(100))
                            .height(.percent(100))
                            .outline(.none, null)
                            .border(.solid(.{ .top = 1, .bottom = 3, .left = 1, .right = 1 }, .palette(.border_color_light), .all(6)))
                            .padding(.all(8))
                            .font(16, 300, .palette(.text_color))
                            .fontFamily("IBM Plex Sans,monospace")
                            .resize(.none)
                            .end();
                    });
                });

                // Priority selector
                Stack()
                    .spacing(6)
                    .children({
                    Text("Priority")
                        .font(13, 500, Theme.text_secondary)
                        .fontFamily("Montserrat")
                        .end();
                    Row()
                        .layout(.left_center)
                        .spacing(8)
                        .children({
                        for (std.enums.values(TaskPriority)) |priority| {
                            const is_selected = self.new_task_priority == priority;
                            CheckRow(selectPriority, .{ self, priority })
                                .border(.round(if (is_selected) priority.color() else .palette(.border_color_light), .all(6)))
                                .layout(.center)
                                .pointer()
                                .children({
                                Row()
                                    .width(.px(14))
                                    .height(.px(14))
                                    .background(if (is_selected) priority.color() else .transparent)
                                    .border(.round(.transparent, .all(4)))
                                    .hoverScale()
                                    .layout(.center)
                                    .children({});
                            });
                            Text(priority.label())
                                .font(12, 500, if (is_selected) priority.color() else Theme.text_secondary)
                                .fontFamily("Montserrat")
                                .end();
                        }
                    });
                });

                // Status selector
                Stack()
                    .spacing(6)
                    .children({
                    Text("Status")
                        .font(13, 500, Theme.text_secondary)
                        .fontFamily("Montserrat")
                        .end();
                    Row()
                        .layout(.left_center)
                        .spacing(8)
                        .wrap(.wrap)
                        .children({
                        for (std.enums.values(TaskStatus)) |status| {
                            const is_selected = self.new_task_status == status;
                            CheckRow(selectStatus, .{ self, status })
                                .border(.round(if (is_selected) status.color() else .palette(.border_color_light), .all(6)))
                                .layout(.center)
                                .pointer()
                                .children({
                                Row()
                                    .width(.px(14))
                                    .height(.px(14))
                                    .background(if (is_selected) status.color() else .transparent)
                                    .border(.round(.transparent, .all(4)))
                                    .hoverScale()
                                    .layout(.center)
                                    .children({});
                            });
                            Text(status.label())
                                .font(12, 500, if (is_selected) status.color() else Theme.text_secondary)
                                .fontFamily("Montserrat")
                                .end();
                        }
                    });
                });
            });

            // Actions
            Row()
                .layout(.right_center)
                .spacing(12)
                .margin(.{ .top = 8 })
                .children({
                Button(closeAddModal, .{self})
                    .background(.palette(.text_color))
                    .children({
                    Text("Cancel")
                        .font(14, 300, .palette(.background))
                        .fontFamily("Montserrat")
                        .end();
                });
                Button(addTask, .{self})
                    .background(.palette(.tint))
                    .children({
                    Icon(.plus)
                        .font(14, 600, .palette(.background))
                        .end();
                    Text("Add Task")
                        .font(14, 300, .palette(.background))
                        .fontFamily("Montserrat")
                        .end();
                });
            });
        });
    }

    // --- Detail sheet -----------------------------------------------------
    fn renderDetailSheetContent(self: *Kanban) void {
        if (self.selected_task) |task| {
            Stack()
                .width(.percent(100))
                .height(.percent(100))
                .padding(.all(24))
                .spacing(24)
                .children({
                Row()
                    .layout(.x_between_center)
                    .children({
                    Text("Task Details")
                        .font(20, 700, Theme.text)
                        .fontFamily("Montserrat")
                        .end();
                    Button(closeDetailSheet, .{self})
                        .ariaLabel("Close details")
                        .width(.px(36))
                        .height(.px(36))
                        .layout(.center)
                        .pointer()
                        .children({
                        Icon(.x_lg)
                            .font(16, 400, Theme.text_secondary)
                            .end();
                    });
                });

                Row()
                    .width(.percent(100))
                    .padding(.all(20))
                    .direction(.column)
                    .spacing(12)
                    .layout(.center)
                    .children({
                    Text(task.title)
                        .font(24, 700, Theme.text)
                        .fontFamily("Montserrat")
                        .end();
                    Row()
                        .layout(.center)
                        .spacing(8)
                        .children({
                        Row()
                            .padding(.xy(10, 6))
                            .background(.transparentize(task.status.color(), 0.2))
                            .border(.round(task.status.color(), .all(6)))
                            .children({
                            Text(task.status.label())
                                .font(12, 600, task.status.color())
                                .fontFamily("Montserrat")
                                .end();
                        });
                        Row()
                            .padding(.xy(10, 6))
                            .background(.transparentize(task.priority.color(), 0.2))
                            .border(.round(task.priority.color(), .all(6)))
                            .children({
                            Text(task.priority.label())
                                .font(12, 600, task.priority.color())
                                .fontFamily("Montserrat")
                                .end();
                        });
                    });
                });

                if (task.description.len > 0) {
                    Stack()
                        .width(.percent(100))
                        .spacing(8)
                        .children({
                        Text("Description")
                            .font(12, 500, Theme.text_muted)
                            .fontFamily("Montserrat")
                            .end();
                        Text(task.description)
                            .font(14, 400, Theme.text_secondary)
                            .fontFamily("Montserrat")
                            .end();
                    });
                }

                Stack()
                    .width(.percent(100))
                    .spacing(16)
                    .children({
                    if (task.assignee) |assignee| {
                        renderDetailRow("Assignee", assignee);
                    }
                    if (task.due_date) |due| {
                        renderDetailRow("Due Date", due.formatDate(Vapor.frame.arena()) catch "");
                    }
                    renderDetailRow("Created", task.created_at);
                    renderDetailRowFmt("Task ID", "TASK-{d}", .{task.id});
                });

                if (task.tags.len > 0) {
                    Stack()
                        .width(.percent(100))
                        .spacing(8)
                        .children({
                        Text("Tags")
                            .font(12, 500, Theme.text_muted)
                            .fontFamily("Montserrat")
                            .end();
                        Row()
                            .layout(.left_center)
                            .spacing(8)
                            .wrap(.wrap)
                            .children({
                            for (task.tags) |tag| {
                                Row()
                                    .padding(.xy(10, 6))
                                    .background(.palette(.highlight_color))
                                    .border(.round(.palette(.border_color_light), .all(6)))
                                    .children({
                                    Text(tag)
                                        .font(12, 500, Theme.text_secondary)
                                        .fontFamily("Montserrat")
                                        .end();
                                });
                            }
                        });
                    });
                }

                Row()
                    .width(.percent(100))
                    .layout(.left_center)
                    .spacing(12)
                    .children({
                    Button(closeDetailSheet, .{self})
                        .padding(.xy(12, 8))
                        .background(Theme.warning)
                        .border(.round(Theme.warning, .all(12)))
                        .pointer()
                        .layout(.center)
                        .spacing(8)
                        .children({
                        Icon(.pencil)
                            .font(16, 400, Theme.bg_base)
                            .end();
                        Text("Edit Task")
                            .font(14, 500, Theme.bg_base)
                            .fontFamily("Montserrat")
                            .end();
                    });
                    Button(closeDetailSheet, .{self})
                        .padding(.xy(12, 8))
                        .background(Theme.bg_elevated)
                        .border(.round(.palette(.border_color_light), .all(12)))
                        .pointer()
                        .layout(.center)
                        .spacing(8)
                        .children({
                        Icon(.link)
                            .font(16, 400, Theme.text_secondary)
                            .end();
                        Text("Copy Link")
                            .font(14, 500, Theme.text_secondary)
                            .fontFamily("Montserrat")
                            .end();
                    });
                });
            });
        }
    }
};

// ============================================================================
// SHARED FREE FUNCTIONS (no per-instance state)
// ============================================================================

fn createProgressCircle() ProgressCircle {
    return ProgressCircle.init(Vapor.persist.arena(), .{
        .size = 16,
        .stroke_width = 2,
        .track_color = .palette(.highlight_color),
        .color = .palette(.text_color),
        .clockwise = false,
        .show_label = false,
    });
}

fn makeTask(
    id: usize,
    title: []const u8,
    description: []const u8,
    status: TaskStatus,
    priority: TaskPriority,
    assignee: ?[]const u8,
    tags: []const []const u8,
    due_date: ?Vapor.DateTime,
    created_at: []const u8,
    position: []const u8,
) Task {
    var progress_circle = createProgressCircle();
    const rand_value: f64 = @floatFromInt(rand.random().intRangeAtMost(u32, 0, 100));
    progress_circle.setProgress(rand_value / 100);
    return Task{
        .id = id,
        .title = title,
        .description = description,
        .status = status,
        .priority = priority,
        .assignee = assignee,
        .tags = tags,
        .due_date = due_date,
        .created_at = created_at,
        .progress = progress_circle,
        .percent = rand_value,
        .position = position,
    };
}

fn renderNavButton(label_text: []const u8, nav_icon: Vapor.IconTokens, is_active: bool) void {
    Row()
        .width(.percent(100))
        .padding(.xy(14, 4))
        .background(if (is_active) .transparentize(.palette(.tint), 0.1) else .transparent)
        .border(.right(1, if (is_active) .palette(.tint) else .transparent))
        .layer(if (is_active) .dot(0.5, 6, .transparentize(.palette(.tint), 0.3)) else null)
        .layout(.left_center)
        .spacing(12)
        .pointer()
        .duration(150)
        .hover(.{
            .background = if (is_active) .transparentize(.palette(.tint), 0.1) else .palette(.highlight_color),
        })
        .children({
        Row()
            .width(.px(32))
            .height(.px(32))
            .layout(.center)
            .children({
            Icon(nav_icon)
                .font(16, 400, if (is_active) .palette(.tint) else Theme.text_secondary)
                .end();
        });
        Text(label_text)
            .font(14, if (is_active) @as(u32, 500) else @as(u32, 400), if (is_active) .palette(.tint) else Theme.text_secondary)
            .fontFamily("Montserrat")
            .end();
    });
}

fn renderStatRow(label_text: []const u8, count: usize) void {
    Row()
        .width(.percent(100))
        .padding(.xy(14, 8))
        .layout(.x_between_center)
        .children({
        Text(label_text)
            .font(13, 400, Theme.text_secondary)
            .fontFamily("Montserrat")
            .end();
        TextFmt("{d}", .{count})
            .font(13, 600, Theme.text)
            .fontFamily("Montserrat")
            .end();
    });
}

fn renderDetailRow(label_text: []const u8, value: []const u8) void {
    Row()
        .width(.percent(100))
        .layout(.x_between_center)
        .padding(.vertical(12))
        .border(.bottom(1, .palette(.border_color_light)))
        .children({
        Text(label_text)
            .font(14, 400, Theme.text_muted)
            .fontFamily("Montserrat")
            .end();
        Text(value)
            .font(14, 500, Theme.text)
            .fontFamily("Montserrat")
            .end();
    });
}

fn renderDetailRowFmt(label_text: []const u8, comptime fmt: []const u8, args: anytype) void {
    Row()
        .width(.percent(100))
        .layout(.x_between_center)
        .padding(.vertical(12))
        .border(.bottom(1, .palette(.border_color_light)))
        .children({
        Text(label_text)
            .font(14, 400, Theme.text_muted)
            .fontFamily("Montserrat")
            .end();
        TextFmt(fmt, args)
            .font(14, 500, Theme.text)
            .fontFamily("Montserrat")
            .end();
    });
}

fn CheckRow(func: anytype, args: anytype) Vapor.Builder(.pure) {
    return Vapor.Button(func, args)
        .ariaLabel("Table Row Checkbox")
        .width(.px(20))
        .height(.px(20))
        .cursor(.pointer)
        .duration(100)
        .hoverScale();
}

fn noItemsRender(collection_count: usize, dir: Sortable.Direction) void {
    _ = dir;
    Center()
        .height(.px(100))
        .children({
        Stack()
            .layout(.center)
            .spacing(8)
            .children({
            Icon(.inbox)
                .font(24, 400, Theme.text_muted)
                .end();
            Text(if (collection_count > 0) "No matching tasks" else "No tasks")
                .font(13, 400, Theme.text_muted)
                .fontFamily("Montserrat")
                .end();
        });
    });
}

fn gapRender(dir: Sortable.Direction) void {
    Vapor.Row()
        .width(if (dir == .horizontal) .px(16) else .percent(100))
        .height(if (dir == .vertical) .px(16) else .percent(100))
        .background(.transparentize(.palette(.tint), 0.1))
        .border(.round(.transparentize(.palette(.tint), 0.3), .all(8)))
        .duration(150)
        .children({});
}

fn renderDragOverlay(task: ?*Task, delta_x: f32, delta_y: f32) void {
    if (task) |t| {
        Row()
            .src(@src())
            .pos(.tl(.px(delta_y), .px(delta_x), .fixed))
            .zIndex(9999)
            .width(.px(280))
            .padding(.all(14))
            .background(.palette(.background))
            .radius(.all(12))
            .shadow(Vapor.Types.NewShadow.init().dropSpread(0, 0, 12, 2, .transparentize(.palette(.tint), 0.10)))
            .direction(.column)
            .spacing(8)
            .children({
            Row()
                .layout(.x_between_center)
                .children({
                Text(t.title)
                    .font(13, 600, Theme.text)
                    .fontFamily("Montserrat")
                    .width(.px(180))
                    .ellipsis(.dot)
                    .end();
                Row()
                    .padding(.xy(6, 3))
                    .background(.transparentize(t.priority.color(), 0.2))
                    .border(.round(t.priority.color(), .all(4)))
                    .children({
                    Text(t.priority.label())
                        .font(10, 500, t.priority.color())
                        .fontFamily("Montserrat")
                        .end();
                });
            });

            if (t.description.len > 0) {
                Text(t.description)
                    .font(11, 400, Theme.text_secondary)
                    .fontFamily("Montserrat")
                    .end();
            }

            Row()
                .padding(.xy(8, 4))
                .background(.transparentize(t.status.color(), 0.15))
                .border(.round(t.status.color(), .all(6)))
                .children({
                Text(t.status.label())
                    .font(10, 500, t.status.color())
                    .fontFamily("Montserrat")
                    .end();
            });
        });
    }
}

fn renderTaskCardTrampoline(kanban: *Kanban, task: *Task, index: usize, state: Sortable.ItemState) void {
    _ = index;
    kanban.renderTaskCard(task, state);
}

fn tooltipTriggerTrampoline(_: []const u8) void {
    Vapor.Image(.{ .src = "/assets/me.webp" })
        .width(.px(28))
        .height(.px(28))
        .radius(.all(999))
        .end();
}

fn tooltipContentTrampoline(self: *Kanban, task: *Task) void {
    self.tooltipContent(task);
}
