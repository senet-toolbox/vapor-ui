const Vapor = @import("vapor");
const Hero = @import("../../../../components/Hero.zig").Hero;
const Row = Vapor.Row;
const SyntaxHighlighter = @import("vaporize").SyntaxHighlighter;
const CodeBox = @import("../CodeBox.zig").CodeBox;
const Docs = @import("../Docs.zig");
// Rendered and shown as code: what you read is what runs.
const BasicSidebar = @import("examples/BasicSidebar.zig");

var hl_basic: SyntaxHighlighter = undefined;
var hl_api: SyntaxHighlighter = undefined;

pub fn init() void {
    hl_basic = Docs.highlighter(@embedFile("examples/BasicSidebar.zig"));
    hl_api = Docs.highlighter(
        \\const SideBar = @import("opaque-ui").SideBar;
        \\
        \\// Once, in your init: sets up the sidebar's animations.
        \\pub fn init() void
        \\// Draws it, filling its container.
        \\pub fn render(sidebar: *SideBar) void
        \\
        \\// The sidebar is a struct you fill in, kept in a global var.
        \\var sidebar: SideBar = .{ .title = "App", .groups = &groups };
    );
    BasicSidebar.init();

    Vapor.Page(.{ .src = @src() }, render, null);
}

const fields = [_]Docs.Field{
    .{ .name = "groups", .type = "?[]GroupItem", .default = "null", .desc = "The groups, top to bottom. A var: opening one writes into it." },
    .{ .name = "title", .type = "[]const u8", .default = "\"\"", .desc = "The sidebar's title." },
    .{ .name = "show_menu", .type = "bool", .default = "false", .desc = "Whether it's open, with labels; closed, it shows only icons. The menu button flips it." },
    .{ .name = "on_item_click", .type = "?*const fn (*const MenuItem) void", .default = "null", .desc = "Called with the item clicked, after it's marked current. Navigate or switch content here." },
    .{ .name = "on_group_click", .type = "?*const fn (*const GroupItem) void", .default = "null", .desc = "Called with the group clicked, after it opens or closes." },
    .{ .name = "current_path", .type = "?[]const u8", .default = "null", .desc = "The link of the current item. Set to the page's path when it appears, and to an item's link when clicked." },
};

const group_fields = [_]Docs.Field{
    .{ .name = "title", .type = "[]const u8", .desc = "The group's heading, which opens and closes it." },
    .{ .name = "icon", .type = "IconTokens", .desc = "Shown beside the heading, and alone when the sidebar is closed." },
    .{ .name = "items", .type = "[]const MenuItem", .desc = "The group's items." },
    .{ .name = "show", .type = "bool", .default = "false", .desc = "Whether the group starts open." },
};

const item_fields = [_]Docs.Field{
    .{ .name = "title", .type = "[]const u8", .desc = "The item's label." },
    .{ .name = "link", .type = "[]const u8", .desc = "The path it stands for. The item whose link is current_path is marked." },
    .{ .name = "icon", .type = "IconTokens", .desc = "Shown beside the label; any Vapor icon." },
};

const behaviours = [_]Docs.Field{
    .{ .name = "Clicking", .desc = "An item is marked current and on_item_click is called; the sidebar doesn't navigate by itself." },
    .{ .name = "Keyboard", .desc = "Headings and items are buttons: Tab reaches them, Enter or Space uses them. A closed group's items are skipped." },
    .{ .name = "Screen readers", .desc = "Headings and the menu button report aria-expanded; the current item reports aria-pressed. A closed group is hidden." },
};

pub fn render() void {
    Row()
        .width(.percent(100))
        .layout(.top_center)
        .direction(.column)
        .children({
        Hero("sidebar-ui", "A collapsible navigation sidebar with grouped menu items, icons, and customizable styling.");

        Docs.Content().children({
            Docs.exampleLabel("Basic Sidebar");
            Docs.sectionDesc("Groups of items that fold away, and a button that shrinks it to icons.");
            Docs.PreviewCard().height(.px(512)).children({
                BasicSidebar.render();
            });
            CodeBox(&hl_basic, "BasicSidebar");

            Docs.sectionTitle("API Reference");

            Docs.exampleLabel("SideBar");
            Docs.sectionDesc("Fill in a SideBar and render it where it goes.");
            CodeBox(&hl_api, "SideBar");

            Docs.exampleLabel("Fields");
            Docs.sectionDesc("Set them in the struct, or later.");
            Docs.ApiBox("SideBar", &fields);

            Docs.exampleLabel("GroupItem");
            Docs.sectionDesc("A heading and the items under it.");
            Docs.ApiBox("GroupItem", &group_fields);

            Docs.exampleLabel("MenuItem");
            Docs.sectionDesc("One entry.");
            Docs.ApiBox("MenuItem", &item_fields);

            Docs.exampleLabel("Behaviour");
            Docs.sectionDesc("What the sidebar does for you.");
            Docs.ApiBox("Behaviour", &behaviours);
        });
    });
}
