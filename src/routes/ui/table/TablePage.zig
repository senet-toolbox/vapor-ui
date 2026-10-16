// table_page.zig
const std = @import("std");
const Vapor = @import("vapor");
const Text = Vapor.Text;
const Row = Vapor.Row;
const Stack = Vapor.Stack;
const Opaque = @import("opaque-ui");
const Table = Opaque.Table;
const Vaporize = @import("vaporize");
const SyntaxHighlighter = Vaporize.SyntaxHighlighter;
const CodeBox = @import("../CodeBox.zig").CodeBox;

// ============================================================================
// THEME
// ============================================================================

const Theme = struct {
    const text = Vapor.Types.Color.palette(.text_color);
    const text_muted = Vapor.Types.Color.hex("#71717a");
    const border = Vapor.Types.Color.palette(.border_color_light);
    const code_bg = Vapor.Types.Color.hex("#1a1a1a");
};

// ============================================================================
// SYNTAX HIGHLIGHTERS
// ============================================================================

var hl_basic: SyntaxHighlighter = undefined;
var hl_with_actions: SyntaxHighlighter = undefined;
var hl_filterable: SyntaxHighlighter = undefined;
var hl_sortable: SyntaxHighlighter = undefined;
var hl_virtual: SyntaxHighlighter = undefined;

// ============================================================================
// DATA TYPES
// ============================================================================

const Status = enum { pending, success, err };

const Transaction = struct {
    id: usize,
    status: Status,
    email: []const u8,
    amount: u32,
};

const User = struct {
    id: usize,
    name: []const u8,
    role: Role,
    department: []const u8,
};

const Role = enum { admin, editor, viewer };

// ============================================================================
// TABLE INSTANCES
// ============================================================================

const BasicTable = Table(Transaction, &.{
    .{ .title = "Status", .key = "status" },
    .{ .title = "Email", .key = "email" },
    .{ .title = "Amount", .key = "amount" },
}, .{});
var basic_table: BasicTable = undefined;

const ActionsTable = Table(Transaction, &.{
    .{ .title = "Status", .key = "status" },
    .{ .title = "Email", .key = "email" },
    .{ .title = "Amount", .key = "amount" },
}, .{
    .actions = &.{
        .{ .label = "View", .icon = .eye },
        .{ .label = "Edit", .icon = .pencil },
        .{ .label = "Delete", .icon = .trash },
    },
});
var actions_table: ActionsTable = undefined;

const FilterableTable = Table(Transaction, &.{
    .{ .title = "Status", .key = "status", .filter = true },
    .{ .title = "Email", .key = "email", .search = true },
    .{ .title = "Amount", .key = "amount" },
}, .{});
var filterable_table: FilterableTable = undefined;

const SortableTable = Table(Transaction, &.{
    .{ .title = "Status", .key = "status", .sort = .asc },
    .{ .title = "Email", .key = "email", .sort = .asc },
    .{ .title = "Amount", .key = "amount", .sort = .desc },
}, .{});
var sortable_table: SortableTable = undefined;

const VirtualTable = Table(Transaction, &.{
    .{ .title = "Status", .key = "status" },
    .{ .title = "Email", .key = "email" },
    .{ .title = "Amount", .key = "amount" },
}, .{});
var virtual_table: VirtualTable = undefined;

// ============================================================================
// SAMPLE DATA
// ============================================================================

var basic_data: Vapor.Array(Transaction) = undefined;
var actions_data: Vapor.Array(Transaction) = undefined;
var filterable_data: Vapor.Array(Transaction) = undefined;
var sortable_data: Vapor.Array(Transaction) = undefined;
var virtual_data: Vapor.Array(Transaction) = undefined;

fn generateSampleData(arr: *Vapor.Array(Transaction), count: usize) void {
    const statuses = [_]Status{ .pending, .success, .err };
    const emails = [_][]const u8{
        "john@example.com",
        "jane@example.com",
        "alice@example.com",
        "bob@example.com",
        "mary@example.com",
    };

    for (0..count) |i| {
        arr.append(.{
            .id = i,
            .status = statuses[i % 3],
            .email = emails[i % 5],
            .amount = @intCast((i + 1) * 100),
        }) catch unreachable;
    }
}

// ============================================================================
// INIT
// ============================================================================

pub fn init() void {
    const allocator = Vapor.arena(.persist);

    // Initialize syntax highlighters
    hl_basic = SyntaxHighlighter.init(allocator);
    hl_basic.show_toolbar = true;
    hl_basic.parse(@embedFile("examples/BasicTable.zig")) catch unreachable;

    hl_with_actions = SyntaxHighlighter.init(allocator);
    hl_with_actions.show_toolbar = true;
    hl_with_actions.parse(@embedFile("examples/WithActions.zig")) catch unreachable;

    hl_filterable = SyntaxHighlighter.init(allocator);
    hl_filterable.show_toolbar = true;
    hl_filterable.parse(@embedFile("examples/Filterable.zig")) catch unreachable;

    hl_sortable = SyntaxHighlighter.init(allocator);
    hl_sortable.show_toolbar = true;
    hl_sortable.parse(@embedFile("examples/Sortable.zig")) catch unreachable;

    hl_virtual = SyntaxHighlighter.init(allocator);
    hl_virtual.show_toolbar = true;
    hl_virtual.parse(@embedFile("examples/Virtual.zig")) catch unreachable;

    // Initialize data arrays
    basic_data = Vapor.array(Transaction, .persist);
    actions_data = Vapor.array(Transaction, .persist);
    filterable_data = Vapor.array(Transaction, .persist);
    sortable_data = Vapor.array(Transaction, .persist);
    virtual_data = Vapor.array(Transaction, .persist);

    // Generate sample data
    generateSampleData(&basic_data, 5);
    generateSampleData(&actions_data, 5);
    generateSampleData(&filterable_data, 15);
    generateSampleData(&sortable_data, 10);
    generateSampleData(&virtual_data, 100);

    // Initialize tables
    basic_table.init(basic_data.items);

    actions_table.init(actions_data.items);

    filterable_table.init(filterable_data.items);

    sortable_table.init(sortable_data.items);

    virtual_table.init(virtual_data.items);
    virtual_table.display_mode = .virtual;

    Vapor.Page(.{ .src = @src() }, render, null);
}

// ============================================================================
// HANDLERS
// ============================================================================

fn handleSelect(item: *Transaction) void {
    Vapor.alert("Selected: {s} - ${d}", .{ item.email, item.amount });
}

fn handleView(item: *Transaction) void {
    Vapor.alert("Viewing: {s}", .{item.email});
}

fn handleEdit(item: *Transaction) void {
    Vapor.alert("Editing: {s}", .{item.email});
}

fn handleDelete(item: *Transaction) void {
    Vapor.alert("Deleting: {s}", .{item.email});
}

// ============================================================================
// UI COMPONENTS
// ============================================================================

fn sectionTitle(title: []const u8) void {
    Text(title)
        .font(24, 600, Theme.text)
        .fontFamily("IBM Plex Mono,monospace")
        .margin(.t(48))
        .end();
}

fn sectionDesc(desc: []const u8) void {
    Text(desc)
        .font(14, 400, Theme.text_muted)
        .fontFamily("IBM Plex Mono,monospace")
        .margin(.b(16))
        .end();
}

fn exampleLabel(label: []const u8) void {
    Text(label)
        .font(14, 500, Theme.text_muted)
        .fontFamily("IBM Plex Mono,monospace")
        .margin(.t(24))
        .end();
}

fn PreviewCard() Vapor.Builder(.pure) {
    return Stack()
        .background(.transparentizeHex(.palette(.background), 0.5))
        .border(.round(.palette(.border_color_light), .all(12)))
        .width(.percent(100))
        .height(.px(400))
        .padding(.all(24))
        .direction(.column)
        .layout(.top_center)
        .scroll(.scroll_y());
}

// ============================================================================
// RENDER
// ============================================================================

pub fn render() void {
    Row()
        .width(.percent(100))
        .layout(.top_center)
        .direction(.column)
        .children({

        // Hero
        Vapor.Stack()
            .layout(.center)
            .height(.px(512))
            .width(.percent(100))
            .children({
            Text("table-ui ⇒").style(&.{
                .visual = .font(12, 500, .hex("#6f6f6f")),
                .font_family = "IBM Plex Mono,monospace",
            }).end();
            Text("table-ui")
                .font(72, 700, .palette(.text_color))
                .end();
            Text("A powerful, feature-rich data table component built on top of Vapor with sorting, filtering, pagination, and row actions.")
                .font(16, 300, .palette(.text_color))
                .end();
        });

        // Content
        Stack()
            .width(.percent(50))
            .height(.percent(100))
            .spacing(12)
            .padding(.bottom(120))
            .children({

            // ============================================================
            // BASIC
            // ============================================================
            exampleLabel("Basic");
            sectionDesc("A simple table with columns and data. Each row requires an 'id' field.");
            PreviewCard().children({
                basic_table.render();
            });
            CodeBox(&hl_basic, "BasicTable");

            // ============================================================
            // WITH ACTIONS
            // ============================================================
            exampleLabel("With Actions");
            sectionDesc("Add row-level actions with icons using the config.actions parameter.");
            PreviewCard().children({
                actions_table.render();
            });
            CodeBox(&hl_with_actions, "WithActions");

            // ============================================================
            // FILTERABLE
            // ============================================================
            exampleLabel("Filterable");
            sectionDesc("Enable text search and enum filtering on columns with .search and .filter.");
            PreviewCard().children({
                filterable_table.render();
            });
            CodeBox(&hl_filterable, "Filterable");

            // ============================================================
            // SORTABLE
            // ============================================================
            exampleLabel("Sortable");
            sectionDesc("Add sorting to columns with .sort = .asc or .sort = .desc.");
            PreviewCard().children({
                sortable_table.render();
            });
            CodeBox(&hl_sortable, "Sortable");

            // ============================================================
            // VIRTUAL SCROLLING
            // ============================================================
            exampleLabel("Virtual Scrolling");
            sectionDesc("For large datasets, use display_mode = .virtual for performant rendering.");
            PreviewCard().children({
                virtual_table.render();
            });
            CodeBox(&hl_virtual, "Virtual");

            // ============================================================
            // API REFERENCE
            // ============================================================
            sectionTitle("API Reference");

            exampleLabel("Table Definition");
            sectionDesc("Define a table type with your data struct, columns, and optional config:");
            Row()
                .width(.percent(100))
                .padding(.all(16))
                .background(Theme.code_bg)
                .border(.round(Theme.border, .all(8)))
                .children({
                Text(
                    \\const MyTable = Table(
                    \\    DataType,           // Must have 'id' field
                    \\    &.{ ... },          // Column definitions
                    \\    .{ .actions = ... } // Optional config
                    \\);
                    \\var table: MyTable = undefined;
                )
                    .font(14, 400, .hex("#e4e4e7"))
                    .fontFamily("IBM Plex Mono,monospace")
                    .end();
            });

            exampleLabel("Data Structure");
            sectionDesc("Your data type must include an 'id' field for row identification:");
            Row()
                .width(.percent(100))
                .padding(.all(16))
                .background(Theme.code_bg)
                .border(.round(Theme.border, .all(8)))
                .children({
                Text(
                    \\const Transaction = struct {
                    \\    id: usize,           // Required
                    \\    status: Status,      // Enum fields support filtering
                    \\    email: []const u8,   // String fields support search
                    \\    amount: u32,         // Numeric fields support sorting
                    \\};
                )
                    .font(14, 400, .hex("#e4e4e7"))
                    .fontFamily("IBM Plex Mono,monospace")
                    .end();
            });

            exampleLabel("Column Options");
            sectionDesc("Configure each column with these properties:");
            Row()
                .width(.percent(100))
                .padding(.all(16))
                .background(Theme.code_bg)
                .border(.round(Theme.border, .all(8)))
                .children({
                Text(
                    \\.{
                    \\    .title = "Column Title",    // Display name
                    \\    .key = "field_name",        // Struct field to display
                    \\    .width = 0,                 // Column width (0 = auto)
                    \\    .alignment = .left,         // .left, .center, .right
                    \\    .sort = .asc,               // .none, .asc, .desc
                    \\    .search = true,             // Enable text search
                    \\    .filter = true,             // Enable enum filtering
                    \\    .render = customRenderFn,   // Custom cell renderer
                    \\}
                )
                    .font(14, 400, .hex("#e4e4e7"))
                    .fontFamily("IBM Plex Mono,monospace")
                    .end();
            });

            exampleLabel("Action Config");
            sectionDesc("Add row actions with labels, icons, and callbacks:");
            Row()
                .width(.percent(100))
                .padding(.all(16))
                .background(Theme.code_bg)
                .border(.round(Theme.border, .all(8)))
                .children({
                Text(
                    \\.{
                    \\    .actions = &.{
                    \\        .{ .label = "View", .icon = .eye, .on_action = viewFn },
                    \\        .{ .label = "Edit", .icon = .pencil, .on_action = editFn },
                    \\        .{ .label = "Delete", .icon = .trash, .on_action = deleteFn },
                    \\    },
                    \\}
                )
                    .font(14, 400, .hex("#e4e4e7"))
                    .fontFamily("IBM Plex Mono,monospace")
                    .end();
            });

            exampleLabel("Initialization");
            sectionDesc("Initialize the table with your data slice:");
            Row()
                .width(.percent(100))
                .padding(.all(16))
                .background(Theme.code_bg)
                .border(.round(Theme.border, .all(8)))
                .children({
                Text(
                    \\table.init(data.items);           // Pass data slice
                    \\table.on_select = handleSelect;   // Row selection callback
                    \\table.on_select_all = handleAll;  // Select all callback
                    \\table.per_page = 10;              // Items per page
                    \\table.file_name = "export";       // Download filename
                )
                    .font(14, 400, .hex("#e4e4e7"))
                    .fontFamily("IBM Plex Mono,monospace")
                    .end();
            });

            exampleLabel("Display Modes");
            sectionDesc("Choose how to render large datasets:");
            Row()
                .width(.percent(100))
                .padding(.all(16))
                .background(Theme.code_bg)
                .border(.round(Theme.border, .all(8)))
                .children({
                Text(
                    \\table.display_mode = .paginated;  // Default, with page controls
                    \\table.display_mode = .virtual;    // Virtualized scrolling
                    \\table.display_mode = .all;        // Render all rows (small datasets)
                )
                    .font(14, 400, .hex("#e4e4e7"))
                    .fontFamily("IBM Plex Mono,monospace")
                    .end();
            });

            exampleLabel("Methods");
            sectionDesc("Available methods on the table instance:");
            Row()
                .width(.percent(100))
                .padding(.all(16))
                .background(Theme.code_bg)
                .border(.round(Theme.border, .all(8)))
                .children({
                Text(
                    \\table.init(data);      // Initialize with data
                    \\table.render();        // Render the table
                    \\table.refresh();       // Refresh after data changes
                )
                    .font(14, 400, .hex("#e4e4e7"))
                    .fontFamily("IBM Plex Mono,monospace")
                    .end();
            });

            exampleLabel("Callback Signatures");
            sectionDesc("Event handler function signatures:");
            Row()
                .width(.percent(100))
                .padding(.all(16))
                .background(Theme.code_bg)
                .border(.round(Theme.border, .all(8)))
                .children({
                Text(
                    \\// Row selection callback
                    \\fn onSelect(item: *Transaction) void {
                    \\    // Access item.id, item.status, item.email, etc.
                    \\}
                    \\
                    \\// Action callback
                    \\fn onAction(item: *Transaction) void {
                    \\    // Handle the action for this row
                    \\}
                    \\
                    \\// Select all callback
                    \\fn onSelectAll() void {
                    \\    // Handle select all toggle
                    \\}
                )
                    .font(14, 400, .hex("#e4e4e7"))
                    .fontFamily("IBM Plex Mono,monospace")
                    .end();
            });

            exampleLabel("Features");
            sectionDesc("Built-in functionality:");
            Row()
                .width(.percent(100))
                .padding(.all(16))
                .background(Theme.code_bg)
                .border(.round(Theme.border, .all(8)))
                .children({
                Text(
                    \\• Row selection with checkboxes
                    \\• Select all / deselect all
                    \\• Column sorting (strings, enums, numbers)
                    \\• Text search on string columns
                    \\• Enum filtering with dropdown
                    \\• Pagination with configurable page size
                    \\• Virtual scrolling for large datasets
                    \\• JSON export of selected rows
                    \\• Row actions with custom handlers
                    \\• Horizontal scrolling for many columns
                )
                    .font(14, 400, .hex("#e4e4e7"))
                    .fontFamily("IBM Plex Mono,monospace")
                    .end();
            });
        });
    });
}
