// ============================================================================
// Kanban Board — Advanced UI with Sortable Drag-and-Drop
// ============================================================================
//
// Styling converted from Vapor chained style methods to inlineStyle("...", .{})
// with Tailwind CSS utility classes.

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

    pub fn icon(self: TaskPriority) Vapor.IconType {
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

    pub fn icon(self: TaskStatus) Vapor.IconType {
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
    position: []const u8 = "n",
};

// ============================================================================
// SHARED ANIMATIONS
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

var rand = std.Random.DefaultPrng.init(0);

// ============================================================================
// KANBAN STRUCT
// ============================================================================

const ColumnId = enum { backlog, todo, review, in_progress, done };
const Ctx = Sortable.DragContext(ColumnId);

pub const Kanban = struct {
    pub const TaskCollection = Sortable.Collection(Task, ColumnId, .{
        .id_field = "id",
        .direction = .vertical,
        .on_reorder = onReorderCb,
        .on_transfer = onTransferCb,
        .show_drag_overlay = false,
        .gap_render = gapRender,
    });

    drag_ctx: Ctx = .{},

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

    new_task_title: []const u8 = "",
    new_task_description: []const u8 = "",
    new_task_priority: TaskPriority = .medium,
    new_task_status: TaskStatus = .todo,

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

        self.backlog_col.init(&self.drag_ctx, .backlog, &.{
            makeTask(5, "Database schema review", "Review and optimize current database schema", .backlog, .medium, null, &.{ "backend", "database" }, null, "Jan 10", "f"),
            makeTask(8, "Performance audit", "Run Lighthouse and optimize critical metrics", .backlog, .low, null, &.{"performance"}, null, "Jan 12", "n"),
        });

        self.todo_col.init(&self.drag_ctx, .todo, &.{
            makeTask(4, "API documentation", "Document all REST endpoints with examples", .todo, .low, "Alex", &.{ "docs", "api" }, DateTime.fromDayMonthYear(21, 1, 2026), "Jan 20", "d"),
            makeTask(6, "Mobile responsive layout", "Ensure all pages work on mobile devices", .todo, .high, "Sarah", &.{ "frontend", "mobile" }, DateTime.fromDayMonthYear(12, 8, 2026), "Jan 7", "h"),
            makeTask(9, "Notification system", "Build real-time notification infrastructure", .todo, .high, "Alex", &.{ "backend", "realtime" }, DateTime.fromDayMonthYear(3, 6, 2026), "Jan 10", "l"),
        });

        self.in_progress_col.init(&self.drag_ctx, .in_progress, &.{
            makeTask(2, "User authentication flow", "Implement login, signup, and password reset", .in_progress, .urgent, "Mike", &.{ "backend", "security" }, DateTime.fromDayMonthYear(13, 1, 2026), "Jan 8", "f"),
            makeTask(7, "Unit test coverage", "Increase test coverage to 80%", .in_progress, .medium, "Mike", &.{ "testing", "quality" }, DateTime.fromDayMonthYear(17, 4, 2026), "Jan 11", "n"),
        });

        self.review_col.init(&self.drag_ctx, .review, &.{
            makeTask(3, "Dashboard wireframes", "Create low-fidelity wireframes for main dashboard", .review, .medium, "Sarah", &.{"design"}, DateTime.fromDayMonthYear(8, 1, 2026), "Jan 6", "f"),
            makeTask(10, "Settings page", "User preferences and account settings UI", .review, .medium, "Sarah", &.{ "frontend", "ui" }, DateTime.fromDayMonthYear(28, 4, 2026), "Jan 8", "n"),
        });

        self.done_col.init(&self.drag_ctx, .done, &.{
            makeTask(1, "Design system setup", "Create color tokens, typography scale, and spacing system", .done, .high, "Sarah", &.{ "design", "foundation" }, DateTime.fromDayMonthYear(1, 1, 2026), "Jan 5", "n"),
        });

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
        self.bar.setProgress(self.total_completed);

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

    fn onReorderCb(event: Sortable.ReorderEvent(Task)) void {
        std.log.info("Reorder: '{s}' from {d} to {d}, position key: {s}\n", .{
            event.item.title,
            event.from_index,
            event.to_index,
            event.position,
        });
    }

    fn onTransferCb(event: Sortable.TransferEvent(Task, ColumnId)) void {
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
    }

    fn setFilterPriorityCb(sel: *Select(TaskPriority), item: *Select(TaskPriority).Item) void {
        const self: *Kanban = Vapor.parentPtr(Kanban, "priority_filter", sel);
        if (self.filter_priority == item.value) {
            self.filter_priority = null;
        } else {
            self.filter_priority = item.value;
        }
        self.applyFilters();
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
    // EVENT HANDLERS
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
        _ = col.removeByPtr(task);
        Toast.warning(.{ .title = "Task Deleted", .description = "This action cannot be undone" });
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
            .class("w-full h-full bg-background flex items-start justify-start")
            .children({
            Stack()
                .class("w-full h-full flex flex-col")
                .children({
                self.renderHeader();
                self.renderBoard();
            });

            self.drag_ctx.dragLayerTyped(Task, renderDragOverlay);

            self.detail_sheet.render();
            self.alert.render();
        });
    }

    // --- Navigation -------------------------------------------------------

    pub fn renderNavigation(self: *Kanban) void {
        Stack()
            .class("w-60 h-full p-5 flex flex-col gap-6")
            .children({
            // Logo
            Row()
                .class("flex items-center gap-3")
                .children({
                Row()
                    .class("w-10 h-10 bg-black rounded-lg flex items-center justify-center")
                    .children({
                    Icon(.kanban)
                        .class("text-xl font-bold text-white")
                        .end();
                });
                Stack()
                    .class("flex flex-col gap-0")
                    .children({
                    Text("Kanban")
                        .class("text-xl font-bold font-[Montserrat] text-foreground")
                        .end();
                    Text("Board")
                        .class("text-[11px] font-medium font-[Montserrat] text-zinc-500")
                        .end();
                });
            });

            // Navigation
            Stack()
                .class("w-full flex flex-col gap-1")
                .children({
                Text("VIEWS")
                    .class("text-[10px] font-semibold font-[Montserrat] text-zinc-500 mb-2")
                    .end();

                renderNavButton("Board", .kanban, true);
                renderNavButton("List", .list_ul, false);
                renderNavButton("Calendar", .calendar, false);
                renderNavButton("Timeline", .bar_chart_line, false);
            });

            // Stats
            Stack()
                .class("w-full flex flex-col gap-1")
                .children({
                Text("STATISTICS")
                    .class("text-[10px] font-semibold font-[Montserrat] text-zinc-500 mb-2")
                    .end();

                renderStatRow("Total Tasks", self.totalTaskCount());
                renderStatRow("In Progress", self.in_progress_col.count());
                renderStatRow("Completed", self.done_col.count());
            });

            Row()
                .class("flex-grow")
                .children({});

            // User profile
            Row()
                .class("w-full p-2 flex items-center gap-3")
                .children({
                Stack()
                    .class("flex flex-col gap-0 flex-grow")
                    .children({
                    Text("Vic Rokx")
                        .class("text-sm font-medium font-[Montserrat] text-foreground")
                        .end();
                    Text("Project Manager")
                        .class("text-xs font-normal font-[Montserrat] text-zinc-500")
                        .end();
                });
                Icon(.chevron_expand)
                    .class("text-sm text-zinc-500")
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
            .class("w-full h-[72px] px-7 bg-background flex items-center justify-between")
            .children({
            // Title
            Stack()
                .class("flex flex-col gap-1 items-start")
                .children({
                Text("Kanban Board")
                    .class("text-2xl font-bold font-[Montserrat] text-foreground")
                    .end();
            });

            // Controls
            Row()
                .class("flex items-center justify-end gap-3")
                .children({
                // Search
                Row()
                    .class("w-[200px] flex items-center gap-2")
                    .children({
                    Field(.{ .label = "Search...", .value = .{ .string = &self.search_query } })
                        .onChange(filter, .{self})
                        .render();
                });

                // Priority filter
                Row()
                    .class("w-[140px]")
                    .children({
                    self.priority_filter.renderPos(.bottom);
                });

                // Toggle completed
                Button(toggleCompleted, .{self})
                    .class("px-[14px] py-[9px] flex items-center gap-2")
                    .children({
                    if (self.show_completed) {
                        Row()
                            .class("w-2 h-2 bg-tint rounded-full animate-[kanban-pulse-glow]")
                            .children({});
                    }
                    Text(if (self.show_completed) "Hide Done" else "Show Done")
                        .class(
                            if (self.show_completed)
                                "text-[13px] font-medium font-[Montserrat] text-tint"
                            else
                                "text-[13px] font-medium font-[Montserrat] text-zinc-400",
                        )
                        .end();
                });

                Button(handleExport, .{self})
                    .class("px-[14px] py-[9px] flex items-center gap-2")
                    .children({
                    Text("Export")
                        .class("text-[13px] font-medium font-[Montserrat] text-foreground")
                        .end();
                    Icon(.download)
                        .class("text-sm text-foreground")
                        .end();
                });

                Button(handleRefresh, .{self})
                    .class("w-10 h-10 flex items-center justify-center cursor-pointer")
                    .children({
                    Icon(.arrow_clockwise)
                        .class("text-lg font-bold text-foreground hover:text-foreground/70 transition-colors")
                        .end();
                });

                Button(openAddModal, .{self})
                    .class("px-[14px] py-[9px] bg-tint flex items-center gap-2")
                    .children({
                    Icon(.plus)
                        .class("text-sm font-semibold text-background")
                        .end();
                    Text("Add Task")
                        .class("text-[13px] font-medium font-[Montserrat] text-background")
                        .end();
                });
            });
        });

        // Progress strip below header
        Row()
            .class("w-full px-7 flex items-center gap-4")
            .children({
            Row()
                .class("flex items-center gap-2 px-4 py-1.5 border border-border rounded-md")
                .children({
                Text("Board Progress")
                    .class("text-sm font-light text-foreground")
                    .end();
                self.bar.render();
                TextFmt("{d}%", .{self.total_completed * 100})
                    .class("text-sm font-light font-[Montserrat] text-foreground")
                    .end();
            });
        });
    }

    // --- Board ------------------------------------------------------------

    fn renderBoard(self: *Kanban) void {
        Row()
            .class("h-fit p-7 flex items-start gap-5 overflow-x-auto")
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
            .class("w-[19%] flex flex-col border border-border rounded-[20px] p-2 gap-3")
            .children({
            // Column header
            Row()
                .class("flex items-center justify-between")
                .children({
                Row()
                    .class("flex items-center gap-2.5")
                    .children({
                    Row()
                        .class("px-2 py-1 flex items-center justify-center")
                        .children({
                        TextFmt("{d}", .{visible})
                            .class("text-sm font-light")
                            .end();
                    });
                    Text(status.label())
                        .class("text-base font-light font-[Montserrat] text-foreground")
                        .end();
                });

                Vapor.Button(addTaskToColumn, .{ self, status })
                    .class("flex items-center justify-center cursor-pointer text-zinc-500 hover:text-foreground transition-colors duration-100")
                    .children({
                    Icon(.plus)
                        .class("text-[22px]")
                        .end();
                });
            });

            var surface = collection.surface();
            surface.container = surface.container
                .class("w-full h-full flex flex-col gap-2.5 overflow-y-auto");
            surface.render(renderTaskCardTrampoline, .{self});

            if (visible == 0) {
                Center()
                    .class("h-[100px] flex items-center justify-center")
                    .children({
                    Stack()
                        .class("flex flex-col items-center gap-2")
                        .children({
                        Icon(.inbox)
                            .class("text-2xl text-zinc-500")
                            .end();
                        Text(if (collection.count() > 0) "No matching tasks" else "No tasks")
                            .class("text-[13px] font-normal font-[Montserrat] text-zinc-500")
                            .end();
                    });
                });
            }
        });
    }

    // --- Per-card render --------------------------------------------------

    fn renderTaskCard(self: *Kanban, task: *Task, state: Sortable.ItemState) void {
        Row()
            .class(
                "w-full pt-3.5 flex flex-col gap-2.5 rounded-[20px] cursor-pointer " ++
                    "transition-shadow duration-100 hover:shadow-md animate-[kanban-card-enter]",
            )
            .class(
                if (state.is_dragging)
                    "border border-tint/30 bg-transparent opacity-100"
                else if (state.is_placeholder)
                    "border border-border bg-background opacity-30"
                else
                    "border border-border bg-background opacity-100",
            )
            .children({
            // Title and priority
            Row()
                .class("px-3.5 flex items-center justify-between")
                .children({
                Text(task.title)
                    .class("text-sm font-medium font-[Montserrat] text-foreground truncate w-[70%]")
                    .end();
                Row()
                    .class("px-1.5 py-0.5")
                    .children({
                    Text(task.priority.label())
                        .class("text-[10px] font-light font-[Montserrat]")
                        .end();
                });
            });

            // Description
            if (task.description.len > 0) {
                Text(task.description)
                    .class("px-3.5 text-xs font-normal font-[Montserrat] text-zinc-400")
                    .end();
            }

            // Due date
            if (task.due_date) |due| {
                Row()
                    .class("px-3.5 flex items-center gap-1")
                    .children({
                    Icon(.calendar)
                        .class("text-[11px] text-zinc-500")
                        .end();
                    Text(due.formatDate(Vapor.frame.arena()) catch "")
                        .class("text-[11px] font-normal font-[Montserrat] text-zinc-500")
                        .end();
                });
            }

            // Footer
            Row()
                .class("w-full flex items-center justify-between px-2.5 py-1 border-t border-border")
                .children({
                Row()
                    .class("flex items-center gap-3 w-9 h-9")
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
                    .class("flex items-center justify-end gap-1")
                    .children({
                    // Progress
                    Row()
                        .class("h-6 flex items-center justify-center bg-transparent cursor-pointer gap-2")
                        .children({
                    TextFmt("{d}%", .{task.percent})
                            .class("font-[Montserrat] text-xs font-normal")
                            .end();
                        if (task.progress) |*progress| {
                            progress.render();
                        }
                    });

                    // View
                    Vapor.Button(handleViewTask, .{ self, task })
                        .class("w-6 h-6 flex items-center justify-center bg-transparent cursor-pointer text-zinc-500 hover:text-foreground transition-colors")
                        .children({
                        Icon(.eye)
                            .class("text-xs")
                            .end();
                    });

                    // Move left
                    if (canMoveLeft(task.status)) {
                        Vapor.Button(moveTaskLeft, .{ self, task })
                            .class("w-6 h-6 flex items-center justify-center bg-transparent cursor-pointer text-zinc-500 hover:text-foreground transition-colors")
                            .children({
                            Icon(.chevron_left)
                                .class("text-xs")
                                .end();
                        });
                    }

                    // Move right
                    if (canMoveRight(task.status)) {
                        Vapor.Button(moveTaskRight, .{ self, task })
                            .class("w-6 h-6 flex items-center justify-center bg-transparent cursor-pointer text-zinc-500 hover:text-tint transition-colors")
                            .children({
                            Icon(.chevron_right)
                                .class("text-xs")
                                .end();
                        });
                    }

                    // Delete
                    Vapor.Button(deleteTaskFromCollection, .{ self, task })
                        .class("w-6 h-6 flex items-center justify-center bg-transparent cursor-pointer text-zinc-500 hover:text-red-500 transition-colors")
                        .children({
                        Icon(.trash)
                            .class("text-sm")
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
            .class("w-[280px] p-4 bg-background border border-border rounded-xl flex flex-col gap-3 animate-[kanban-fade-scale]")
            .children({
            Row()
                .class("flex items-center justify-between")
                .children({
                Text(task.title)
                    .class("text-sm font-semibold font-[Montserrat] text-foreground w-[180px] truncate")
                    .end();
                Row()
                    .class("px-2 py-1 rounded-md border")
                    .children({
                    Text(task.priority.label())
                        .class("text-[10px] font-medium font-[Montserrat]")
                        .end();
                });
            });

            Row()
                .class("w-full h-px bg-border")
                .children({});

            Stack()
                .class("w-full flex flex-col gap-2")
                .children({
                if (task.due_date) |due| {
                    Row()
                        .class("w-full flex items-center justify-between")
                        .children({
                        Row()
                            .class("flex items-center gap-1.5")
                            .children({
                            Icon(.calendar)
                                .class("text-xs text-zinc-500")
                                .end();
                            Text("Due date")
                                .class("text-xs font-normal font-[Montserrat] text-zinc-500")
                                .end();
                        });
                        Text(due.formatDate(Vapor.frame.arena()) catch "")
                            .class("text-xs font-medium font-[Montserrat] text-foreground")
                            .end();
                    });
                }

                Row()
                    .class("w-full flex items-center justify-between")
                    .children({
                    Row()
                        .class("flex items-center gap-1.5")
                        .children({
                        Icon(.clock)
                            .class("text-xs text-zinc-500")
                            .end();
                        Text("Created")
                            .class("text-xs font-normal font-[Montserrat] text-zinc-500")
                            .end();
                    });
                    Text(task.created_at)
                        .class("text-xs font-medium font-[Montserrat] text-foreground")
                        .end();
                });

                if (task.assignee) |assignee| {
                    Row()
                        .class("w-full flex items-center justify-between")
                        .children({
                        Text("Assignee")
                            .class("text-xs font-normal font-[Montserrat] text-zinc-500")
                            .end();
                        Text(assignee)
                            .class("text-xs font-medium font-[Montserrat] text-foreground")
                            .end();
                    });
                }
            });

            Row()
                .class("w-full p-2.5 border border-border rounded-lg flex items-center justify-between")
                .children({
                Text("Progress")
                    .class("text-xs font-normal font-[Montserrat] text-zinc-500")
                    .end();
                Row()
                    .class("flex items-center justify-end gap-2.5")
                    .children({
                    self.progress_bar_tooltip.render();
                    TextFmt("{d}%", .{task.percent})
                        .class("text-xs font-semibold font-[Montserrat] text-foreground")
                        .end();
                });
            });
        });
    }

    // --- Add modal --------------------------------------------------------

    fn renderAddModal(self: *Kanban) void {
        Row()
            .class("w-[480px] p-6 flex flex-col gap-5 animate-[kanban-modal-enter]")
            .children({
            // Header
            Row()
                .class("flex items-center justify-between")
                .children({
                Text("Add New Task")
                    .class("text-xl font-bold font-[Montserrat] text-foreground")
                    .end();
                Vapor.Button(closeAddModal, .{self})
                    .class("w-9 h-9 flex items-center justify-center cursor-pointer")
                    .children({
                    Icon(.x_lg)
                        .class("text-base text-zinc-400")
                        .end();
                });
            });

            // Form
            Stack()
                .class("flex flex-col gap-4")
                .children({
                // Title
                Stack()
                    .class("flex flex-col gap-1.5")
                    .children({
                    Text("Title")
                        .class("text-[13px] font-medium font-[Montserrat] text-zinc-400")
                        .end();
                    Row()
                        .class("w-full flex items-center")
                        .children({
                        Field(.{ .label = "Title", .value = .{ .string = &self.new_task_title } }).render();
                    });
                });

                // Description
                Stack()
                    .class("flex flex-col gap-1.5")
                    .children({
                    Text("Description")
                        .class("text-[13px] font-medium font-[Montserrat] text-zinc-400")
                        .end();
                    Row()
                        .class("w-full h-[100px]")
                        .children({
                        Vapor.TextArea()
                            .class(
                                "w-full h-full bg-background border border-border rounded-md p-2 " ++
                                    "text-base font-light text-foreground font-['IBM_Plex_Sans',monospace] " ++
                                    "outline-none resize-none",
                            )
                            .bind(&self.new_task_description)
                            .ariaLabel("Text Area")
                            .end();
                    });
                });

                // Priority selector
                Stack()
                    .class("flex flex-col gap-1.5")
                    .children({
                    Text("Priority")
                        .class("text-[13px] font-medium font-[Montserrat] text-zinc-400")
                        .end();
                    Row()
                        .class("flex items-center gap-2")
                        .children({
                        for (std.enums.values(TaskPriority)) |priority| {
                            const is_selected = self.new_task_priority == priority;
                            CheckRow(selectPriority, .{ self, priority })
                                .class(
                                    if (is_selected)
                                        "border rounded-md flex items-center justify-center cursor-pointer"
                                    else
                                        "border border-border rounded-md flex items-center justify-center cursor-pointer",
                                )
                                .children({
                                Row()
                                    .class(
                                        if (is_selected)
                                            "w-3.5 h-3.5 rounded border-transparent flex items-center justify-center transition-transform hover:scale-110"
                                        else
                                            "w-3.5 h-3.5 bg-transparent rounded border-transparent flex items-center justify-center transition-transform hover:scale-110",
                                    )
                                    .children({});
                            });
                            Text(priority.label())
                                .class(
                                    if (is_selected)
                                        "text-xs font-medium font-[Montserrat]"
                                    else
                                        "text-xs font-medium font-[Montserrat] text-zinc-400",
                                )
                                .end();
                        }
                    });
                });

                // Status selector
                Stack()
                    .class("flex flex-col gap-1.5")
                    .children({
                    Text("Status")
                        .class("text-[13px] font-medium font-[Montserrat] text-zinc-400")
                        .end();
                    Row()
                        .class("flex items-center gap-2 flex-wrap")
                        .children({
                        for (std.enums.values(TaskStatus)) |status| {
                            const is_selected = self.new_task_status == status;
                            CheckRow(selectStatus, .{ self, status })
                                .class(
                                    if (is_selected)
                                        "border rounded-md flex items-center justify-center cursor-pointer"
                                    else
                                        "border border-border rounded-md flex items-center justify-center cursor-pointer",
                                )
                                .children({
                                Row()
                                    .class(
                                        if (is_selected)
                                            "w-3.5 h-3.5 rounded border-transparent flex items-center justify-center transition-transform hover:scale-110"
                                        else
                                            "w-3.5 h-3.5 bg-transparent rounded border-transparent flex items-center justify-center transition-transform hover:scale-110",
                                    )
                                    .children({});
                            });
                            Text(status.label())
                                .class(
                                    if (is_selected)
                                        "text-xs font-medium font-[Montserrat]"
                                    else
                                        "text-xs font-medium font-[Montserrat] text-zinc-400",
                                )
                                .end();
                        }
                    });
                });
            });

            // Actions
            Row()
                .class("flex items-center justify-end gap-3 mt-2")
                .children({
                Button(closeAddModal, .{self})
                    .class("px-3.5 py-2 bg-foreground flex items-center gap-2")
                    .children({
                    Text("Cancel")
                        .class("text-sm font-light font-[Montserrat] text-background")
                        .end();
                });
                Button(addTask, .{self})
                    .class("px-3.5 py-2 bg-tint flex items-center gap-2")
                    .children({
                    Icon(.plus)
                        .class("text-sm font-semibold text-background")
                        .end();
                    Text("Add Task")
                        .class("text-sm font-light font-[Montserrat] text-background")
                        .end();
                });
            });
        });
    }

    // --- Detail sheet -----------------------------------------------------

    fn renderDetailSheetContent(self: *Kanban) void {
        if (self.selected_task) |task| {
            Stack()
                .class("w-full h-full p-6 flex flex-col gap-6")
                .children({
                Row()
                    .class("flex items-center justify-between")
                    .children({
                    Text("Task Details")
                        .class("text-xl font-bold font-[Montserrat] text-foreground")
                        .end();
                    Button(closeDetailSheet, .{self})
                        .class("w-9 h-9 flex items-center justify-center cursor-pointer")
                        .children({
                        Icon(.x_lg)
                            .class("text-base text-zinc-400")
                            .end();
                    });
                });

                Row()
                    .class("w-full p-5 flex flex-col items-center gap-3")
                    .children({
                    Text(task.title)
                        .class("text-2xl font-bold font-[Montserrat] text-foreground")
                        .end();
                    Row()
                        .class("flex items-center gap-2")
                        .children({
                        Row()
                            .class("px-2.5 py-1.5 rounded-md border")
                            .children({
                            Text(task.status.label())
                                .class("text-xs font-semibold font-[Montserrat]")
                                .end();
                        });
                        Row()
                            .class("px-2.5 py-1.5 rounded-md border")
                            .children({
                            Text(task.priority.label())
                                .class("text-xs font-semibold font-[Montserrat]")
                                .end();
                        });
                    });
                });

                if (task.description.len > 0) {
                    Stack()
                        .class("w-full flex flex-col gap-2")
                        .children({
                        Text("Description")
                            .class("text-xs font-medium font-[Montserrat] text-zinc-500")
                            .end();
                        Text(task.description)
                            .class("text-sm font-normal font-[Montserrat] text-zinc-400")
                            .end();
                    });
                }

                Stack()
                    .class("w-full flex flex-col gap-4")
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
                        .class("w-full flex flex-col gap-2")
                        .children({
                        Text("Tags")
                            .class("text-xs font-medium font-[Montserrat] text-zinc-500")
                            .end();
                        Row()
                            .class("flex items-center gap-2 flex-wrap")
                            .children({
                            for (task.tags) |tag| {
                                Row()
                                    .class("px-2.5 py-1.5 bg-zinc-800 border border-border rounded-md")
                                    .children({
                                    Text(tag)
                                        .class("text-xs font-medium font-[Montserrat] text-zinc-400")
                                        .end();
                                });
                            }
                        });
                    });
                }

                Row()
                    .class("w-full flex items-center gap-3")
                    .children({
                    Button(closeDetailSheet, .{self})
                        .class("px-3 py-2 bg-[#F5590B] border border-[#F5590B] rounded-xl cursor-pointer flex items-center gap-2")
                        .children({
                        Icon(.pencil)
                            .class("text-base text-background")
                            .end();
                        Text("Edit Task")
                            .class("text-sm font-medium font-[Montserrat] text-background")
                            .end();
                    });
                    Button(closeDetailSheet, .{self})
                        .class("px-3 py-2 bg-background border border-border rounded-xl cursor-pointer flex items-center gap-2")
                        .children({
                        Icon(.link)
                            .class("text-base text-zinc-400")
                            .end();
                        Text("Copy Link")
                            .class("text-sm font-medium font-[Montserrat] text-zinc-400")
                            .end();
                    });
                });
            });
        }
    }
};

// ============================================================================
// SHARED FREE FUNCTIONS
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

fn renderNavButton(label_text: []const u8, nav_icon: Vapor.IconType, is_active: bool) void {
    Row()
        .class(
            if (is_active)
                "w-full px-3.5 py-1 flex items-center gap-3 cursor-pointer bg-tint/10 border-r-2 border-tint transition-colors duration-150"
            else
                "w-full px-3.5 py-1 flex items-center gap-3 cursor-pointer bg-transparent hover:bg-zinc-800 transition-colors duration-150",
        )
        .children({
        Row()
            .class("w-8 h-8 flex items-center justify-center")
            .children({
            Icon(nav_icon)
                .class(
                    if (is_active)
                        "text-base text-tint"
                    else
                        "text-base text-zinc-400",
                )
                .end();
        });
        Text(label_text)
            .class(
                if (is_active)
                    "text-sm font-medium font-[Montserrat] text-tint"
                else
                    "text-sm font-normal font-[Montserrat] text-zinc-400",
            )
            .end();
    });
}

fn renderStatRow(label_text: []const u8, count: usize) void {
    Row()
        .class("w-full px-3.5 py-2 flex items-center justify-between")
        .children({
        Text(label_text)
            .class("text-[13px] font-normal font-[Montserrat] text-zinc-400")
            .end();
        TextFmt("{d}", .{count})
            .class("text-[13px] font-semibold font-[Montserrat] text-foreground")
            .end();
    });
}

fn renderDetailRow(label_text: []const u8, value: []const u8) void {
    Row()
        .class("w-full flex items-center justify-between py-3 border-b border-border")
        .children({
        Text(label_text)
            .class("text-sm font-normal font-[Montserrat] text-zinc-500")
            .end();
        Text(value)
            .class("text-sm font-medium font-[Montserrat] text-foreground")
            .end();
    });
}

fn renderDetailRowFmt(label_text: []const u8, comptime fmt: []const u8, args: anytype) void {
    Row()
        .class("w-full flex items-center justify-between py-3 border-b border-border")
        .children({
        Text(label_text)
            .class("text-sm font-normal font-[Montserrat] text-zinc-500")
            .end();
        TextFmt(fmt, args)
            .class("text-sm font-medium font-[Montserrat] text-foreground")
            .end();
    });
}

fn CheckRow(func: anytype, args: anytype) Vapor.Builder(.pure) {
    return Vapor.Button(func, args)
        .ariaLabel("Table Row Checkbox")
        .class("w-5 h-5 cursor-pointer transition-transform duration-100 hover:scale-110");
}

fn gapRender(dir: Sortable.Direction) void {
    Vapor.Row()
        .class(
            if (dir == .horizontal)
                "w-4 h-full bg-tint/10 border border-tint/30 rounded-lg transition-all duration-150"
            else
                "w-full h-4 bg-tint/10 border border-tint/30 rounded-lg transition-all duration-150",
        )
        .children({});
}

fn renderDragOverlay(task: ?*Task, delta_x: f32, delta_y: f32) void {
    if (task) |t| {
        Row()
            .class("fixed z-[9999] w-[280px] p-3.5 bg-background rounded-xl flex flex-col gap-2 shadow-[0_0_12px_2px_rgba(99,102,241,0.10)]")
            .inlineStyle("top-[{d}px] left-[{d}px]", .{ delta_y, delta_x })
            .children({
            Row()
                .class("flex items-center justify-between")
                .children({
                Text(t.title)
                    .class("text-[13px] font-semibold font-[Montserrat] text-foreground w-[180px] truncate")
                    .end();
                Row()
                    .class("px-1.5 py-0.5 rounded border")
                    .children({
                    Text(t.priority.label())
                        .class("text-[10px] font-medium font-[Montserrat]")
                        .end();
                });
            });

            if (t.description.len > 0) {
                Text(t.description)
                    .class("text-[11px] font-normal font-[Montserrat] text-zinc-400")
                    .end();
            }

            Row()
                .class("px-2 py-1 rounded-md border")
                .children({
                Text(t.status.label())
                    .class("text-[10px] font-medium font-[Montserrat]")
                    .end();
            });
        });
    } else {
        Vapor.Null();
    }
}

fn renderTaskCardTrampoline(kanban: *Kanban, task: *Task, index: usize, state: Sortable.ItemState) void {
    _ = index;
    kanban.renderTaskCard(task, state);
}

fn tooltipTriggerTrampoline(_: []const u8) void {
    Vapor.Image(.{ .src = "/assets/me.webp" })
        .class("w-7 h-7 rounded-full object-cover")
        .end();
}

fn tooltipContentTrampoline(self: *Kanban, task: *Task) void {
    self.tooltipContent(task);
}
