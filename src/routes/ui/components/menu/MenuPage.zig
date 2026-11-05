const Vapor = @import("vapor");
const Hero = @import("../../../../components/Hero.zig").Hero;
const Row = Vapor.Row;
const SyntaxHighlighter = @import("vaporize").SyntaxHighlighter;
const CodeBox = @import("../CodeBox.zig").CodeBox;
const Docs = @import("../Docs.zig");
// Rendered and shown as code: what you read is what runs.
const BasicMenu = @import("examples/BasicMenu.zig");
const IconMenu = @import("examples/IconMenu.zig");

var hl_basic: SyntaxHighlighter = undefined;
var hl_icon: SyntaxHighlighter = undefined;
var hl_api: SyntaxHighlighter = undefined;

pub fn init() void {
    hl_basic = Docs.highlighter(@embedFile("examples/BasicMenu.zig"));
    hl_icon = Docs.highlighter(@embedFile("examples/IconMenu.zig"));
    hl_api = Docs.highlighter(
        \\const Menu = @import("opaque-ui").Menu;
        \\
        \\// Once, in init.
        \\pub fn init(label: []const u8, items: []const Item, on_select: ?*const fn (item: *const Item, index: usize) void) Menu
        \\
        \\// Every render: the standard button, or one you draw.
        \\pub fn render(menu: *Menu) void
        \\pub fn renderWith(menu: *Menu, comptime trigger_fn: anytype, args: anytype) void
        \\
        \\pub fn open(menu: *Menu) void
        \\pub fn close(menu: *Menu) void
        \\pub fn toggle(menu: *Menu) void
        \\pub fn isOpen(menu: *const Menu) bool
    );
    BasicMenu.init();
    IconMenu.init();

    Vapor.Page(.{ .src = @src() }, render, null);
}

const item_fields = [_]Docs.Field{
    .{ .name = "label", .type = "[]const u8", .desc = "The item's text, and what a typed letter jumps to." },
    .{ .name = "icon", .type = "?IconTokens", .default = "null", .desc = "Drawn before the label." },
    .{ .name = "shortcut", .type = "?[]const u8", .default = "null", .desc = "Shown at the right, such as a key it's also on. The menu doesn't bind the key." },
    .{ .name = "destructive", .type = "bool", .default = "false", .desc = "Coloured as a warning: delete, remove, sign out." },
    .{ .name = "disabled", .type = "bool", .default = "false", .desc = "Shown faded; it can't be picked, and the keys pass over it." },
    .{ .name = "separator_before", .type = "bool", .default = "false", .desc = "A line above it, to group the items." },
};

const fields = [_]Docs.Field{
    .{ .name = "label", .type = "[]const u8", .desc = "The standard button's text, and the name of the button and the menu for screen readers." },
    .{ .name = "on_select", .type = "?*const fn (item: *const Item, index: usize) void", .default = "null", .desc = "Called with the item picked and its place in items." },
    .{ .name = "placement", .type = "AnchorPlacement", .default = ".bottom", .desc = "Where the menu opens against its button: .bottom, .top, .bottom_left, .bottom_right and so on." },
    .{ .name = "background", .type = "Color", .default = ".palette(.background)", .desc = "Every menu's background; a Menu.background global, like the colours below." },
    .{ .name = "highlight", .type = "Color", .default = "tint at 15%", .desc = "The focused item's background." },
    .{ .name = "destructive_color", .type = "Color", .default = ".hex(\"#ef4444\")", .desc = "A destructive item's text and icon." },
};

const behaviours = [_]Docs.Field{
    .{ .name = "Opening", .desc = "A click, Enter or Space on the button opens it with the focus on the first item; Down opens it there too, Up at the last." },
    .{ .name = "Keyboard", .desc = "Up and Down move between items, wrapping round; Home and End go to the ends; a letter goes to the next item starting with it. Enter or Space picks." },
    .{ .name = "Pointer", .desc = "Moving over an item highlights it, as the keys do; a click picks it." },
    .{ .name = "Closing", .desc = "A pick, Escape, Tab or a click outside. The focus goes back to the button." },
    .{ .name = "Screen readers", .desc = "The button says it opens a menu and whether it's open. The menu has role=menu and its label, each item role=menuitem, and disabled ones aria-disabled." },
};

pub fn render() void {
    Row()
        .width(.percent(100))
        .layout(.top_center)
        .direction(.column)
        .children({
        Hero("menu-ui", "A dropdown menu of actions, opened from a button, by pointer or keyboard.");

        Docs.Content().children({
            Docs.exampleLabel("Basic Menu");
            Docs.sectionDesc("Icons, shortcuts, a disabled item and a destructive one after a separator. Open it and use the arrow keys.");
            Docs.PreviewCard().layout(.center).children({
                BasicMenu.render();
            });
            CodeBox(&hl_basic, "BasicMenu");

            Docs.exampleLabel("Icon Button");
            Docs.sectionDesc("Draw the button yourself with renderWith; its label still names it.");
            Docs.PreviewCard().layout(.center).children({
                IconMenu.render();
            });
            CodeBox(&hl_icon, "IconMenu");

            Docs.sectionTitle("Menu or Select?");
            Docs.sectionDesc("A menu does something: each item is an action, run once when picked, and the button keeps its own label. Edit, Duplicate, Delete.");
            Docs.sectionDesc("A select chooses a value: the choice stays, the button shows it, and a form reads it. A country, a sort order, a size. If the button should show what was picked, use a Select.");

            Docs.sectionTitle("API Reference");

            Docs.exampleLabel("Menu");
            Docs.sectionDesc("Set up once in init; render it every frame.");
            CodeBox(&hl_api, "Menu");

            Docs.exampleLabel("Item");
            Docs.ApiBox("Item", &item_fields);

            Docs.exampleLabel("Fields");
            Docs.ApiBox("Menu", &fields);

            Docs.exampleLabel("Behaviour");
            Docs.sectionDesc("What the menu does for you.");
            Docs.ApiBox("Behaviour", &behaviours);
        });
    });
}
