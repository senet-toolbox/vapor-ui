const Vapor = @import("vapor");
const Hero = @import("../../../../components/Hero.zig").Hero;
const Row = Vapor.Row;
const SyntaxHighlighter = @import("vaporize").SyntaxHighlighter;
const CodeBox = @import("../CodeBox.zig").CodeBox;
const Docs = @import("../Docs.zig");
// Rendered and shown as code: what you read is what runs.
const BasicTable = @import("examples/BasicTable.zig");
const WithActions = @import("examples/WithActions.zig");
const Filterable = @import("examples/Filterable.zig");
const Sortable = @import("examples/Sortable.zig");
const Virtual = @import("examples/Virtual.zig");

var hl_basic: SyntaxHighlighter = undefined;
var hl_with_actions: SyntaxHighlighter = undefined;
var hl_filterable: SyntaxHighlighter = undefined;
var hl_sortable: SyntaxHighlighter = undefined;
var hl_virtual: SyntaxHighlighter = undefined;
var hl_api: SyntaxHighlighter = undefined;

pub fn init() void {
    hl_basic = Docs.highlighter(@embedFile("examples/BasicTable.zig"));
    hl_with_actions = Docs.highlighter(@embedFile("examples/WithActions.zig"));
    hl_filterable = Docs.highlighter(@embedFile("examples/Filterable.zig"));
    hl_sortable = Docs.highlighter(@embedFile("examples/Sortable.zig"));
    hl_virtual = Docs.highlighter(@embedFile("examples/Virtual.zig"));
    hl_api = Docs.highlighter(
        \\const Opaque = @import("opaque-ui");
        \\const Table = Opaque.Table;
        \\
        \\// A table type for rows of T, a struct with an id field.
        \\pub fn Table(
        \\    comptime T: type,
        \\    comptime columns: []const Column(T),
        \\    config: struct {
        \\        actions: ?[]const Action(T) = null,
        \\        default_style: TableStyle = .{},
        \\    },
        \\) type
        \\
        \\// Takes the rows; call it once, in your init.
        \\pub fn init(table: *Self, data: []T) void
        \\pub fn render(table: *Self) void
        \\// Applies the search and filters again after you change the rows.
        \\pub fn refresh(table: *Self) void
        \\// Removes the row with that id; false if there's none.
        \\pub fn delete(table: *Self, id: IdType) bool
    );

    BasicTable.init();
    WithActions.init();
    Filterable.init();
    Sortable.init();
    Virtual.init();

    Vapor.Page(.{ .src = @src() }, render, null);
}

const column_fields = [_]Docs.Field{
    .{ .name = "title", .type = "[]const u8", .desc = "The column's heading." },
    .{ .name = "key", .type = "[]const u8", .desc = "The field of T it shows." },
    .{ .name = "width", .type = "?f32", .default = "null", .desc = "In px; null uses the style's column_width." },
    .{ .name = "alignment", .type = "?Align", .default = ".none", .desc = ".left, .center or .right." },
    .{ .name = "sort", .type = "?Sort", .default = "null", .desc = "Adds a sort button to the heading; .asc or .desc is the first click's direction, and each click flips it." },
    .{ .name = "search", .type = "bool", .default = "false", .desc = "Adds a search button: shows only the rows that match what you type." },
    .{ .name = "filter", .type = "bool", .default = "false", .desc = "For an enum field: adds a filter to show only the values you pick." },
    .{ .name = "render", .type = "?*const fn (*T) void", .default = "null", .desc = "Draws the cell yourself." },
};

const action_fields = [_]Docs.Field{
    .{ .name = "label", .type = "[]const u8", .desc = "The action's name in the row's menu." },
    .{ .name = "icon", .type = "?IconTokens", .default = "null", .desc = "Shown beside the label." },
    .{ .name = "on_action", .type = "?*const fn (item: *T) void", .default = "null", .desc = "Called with the row it was picked on." },
};

const table_fields = [_]Docs.Field{
    .{ .name = "display_mode", .type = "DisplayMode", .default = ".paginated", .desc = ".paginated in pages, .virtual draws only the rows in view, for thousands, .all draws every row." },
    .{ .name = "per_page", .type = "usize", .default = "10", .desc = "Rows per page when paginated." },
    .{ .name = "on_select", .type = "?*const fn (item: *T) void", .default = "null", .desc = "Called with a row when its checkbox is clicked." },
    .{ .name = "on_select_all", .type = "?*const fn () void", .default = "null", .desc = "Called when the heading's checkbox is clicked." },
    .{ .name = "file_name", .type = "[]const u8", .default = "\"content\"", .desc = "Names the table for screen readers." },
    .{ .name = "style", .type = "TableStyle", .default = "config.default_style", .desc = "Fonts, colours, borders and sizes; set after init for a themed variant." },
};

const behaviours = [_]Docs.Field{
    .{ .name = "Selecting", .desc = "A checkbox on each row, and one in the heading for every row." },
    .{ .name = "Pages", .desc = "Previous and next buttons below a paginated table; the page number is announced as it changes." },
    .{ .name = "Wide tables", .desc = "Scroll sideways inside their box, not the page." },
    .{ .name = "Screen readers", .desc = "The table has role=grid; the row checkboxes are named Select row, the sort and search buttons after their column." },
};

pub fn render() void {
    Row()
        .width(.percent(100))
        .layout(.top_center)
        .direction(.column)
        .children({
        Hero("table-ui", "A powerful, feature-rich data table component built on top of Vapor with sorting, filtering, pagination, and row actions.");

        Docs.Content().children({
            Docs.exampleLabel("Basic Table");
            Docs.sectionDesc("Columns name the fields of your row struct, which needs an id field.");
            TableCard().children({
                BasicTable.render();
            });
            CodeBox(&hl_basic, "BasicTable");

            Docs.exampleLabel("With Actions");
            Docs.sectionDesc("A menu on each row, with the actions you list in config.actions.");
            TableCard().children({
                WithActions.render();
            });
            CodeBox(&hl_with_actions, "WithActions");

            Docs.exampleLabel("Filterable");
            Docs.sectionDesc("Search a text column with .search, and pick enum values with .filter.");
            TableCard().children({
                Filterable.render();
            });
            CodeBox(&hl_filterable, "Filterable");

            Docs.exampleLabel("Sortable");
            Docs.sectionDesc("A sort button on each column with .sort.");
            TableCard().children({
                Sortable.render();
            });
            CodeBox(&hl_sortable, "Sortable");

            Docs.exampleLabel("Virtual Scrolling");
            Docs.sectionDesc("For thousands of rows, display_mode = .virtual draws only those in view.");
            TableCard().children({
                Virtual.render();
            });
            CodeBox(&hl_virtual, "Virtual");

            Docs.sectionTitle("API Reference");

            Docs.exampleLabel("Table");
            Docs.sectionDesc("Make a table type from your row struct and its columns, then a var of it.");
            CodeBox(&hl_api, "Table");

            Docs.exampleLabel("Column");
            Docs.sectionDesc("One per column, in order.");
            Docs.ApiBox("Column(T)", &column_fields);

            Docs.exampleLabel("Action");
            Docs.sectionDesc("One per entry in a row's menu.");
            Docs.ApiBox("Action(T)", &action_fields);

            Docs.exampleLabel("Fields");
            Docs.sectionDesc("Set them after init.");
            Docs.ApiBox("Table", &table_fields);

            Docs.exampleLabel("Behaviour");
            Docs.sectionDesc("What the table does for you.");
            Docs.ApiBox("Behaviour", &behaviours);
        });
    });
}

/// A preview card that scrolls a tall table inside it.
fn TableCard() Vapor.Builder(.pure) {
    return Docs.PreviewCard()
        .height(.px(400))
        .layout(.top_center)
        .scroll(.scrollY());
}
