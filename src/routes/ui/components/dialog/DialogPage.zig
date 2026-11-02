const Vapor = @import("vapor");
const Hero = @import("../../../../components/Hero.zig").Hero;
const Row = Vapor.Row;
const SyntaxHighlighter = @import("vaporize").SyntaxHighlighter;
const CodeBox = @import("../CodeBox.zig").CodeBox;
const Docs = @import("../Docs.zig");
// Rendered and shown as code: what you read is what runs.
const BasicDialog = @import("examples/BasicDialog.zig");
const CustomDialog = @import("examples/CustomDialog.zig");

var hl_basic: SyntaxHighlighter = undefined;
var hl_custom: SyntaxHighlighter = undefined;
var hl_api: SyntaxHighlighter = undefined;

pub fn init() void {
    hl_basic = Docs.highlighter(@embedFile("examples/BasicDialog.zig"));
    hl_custom = Docs.highlighter(@embedFile("examples/CustomDialog.zig"));
    hl_api = Docs.highlighter(
        \\const Opaque = @import("opaque-ui");
        \\const ComboBoxDialog = Opaque.ComboBoxDialog;
        \\const Item = Opaque.Item;
        \\
        \\// A dialog of items whose value is of type T.
        \\pub fn ComboBoxDialog(comptime T: type) type
        \\
        \\// A flat list, or titled groups.
        \\pub fn fromItems(items: []const Item(T)) Self
        \\pub fn init(trigger: []const u8, groups: []const Group) Self
        \\
        \\// Draws the dialog while it's open, and nothing while it's closed.
        \\pub fn render(dialog: *Self) void
        \\pub fn open(dialog: *Self) void
        \\pub fn close(dialog: *Self) void
        \\
        \\// Any button can open it.
        \\Button(ComboBoxDialog(T).open, .{&dialog})
    );

    BasicDialog.init();
    CustomDialog.init();

    Vapor.Page(.{ .src = @src() }, render, null);
}

const item_fields = [_]Docs.Field{
    .{ .name = "value", .type = "T", .desc = "What the item stands for." },
    .{ .name = "label", .type = "[]const u8", .desc = "Its text, and what the search matches, ignoring case." },
    .{ .name = "icon", .type = "?IconTokens", .default = "null", .desc = "For your row_component to draw." },
    .{ .name = "description", .type = "?[]const u8", .default = "null", .desc = "For your row_component to draw." },
    .{ .name = "link", .type = "?[]const u8", .default = "null", .desc = "For your row_component or on_select to use." },
    .{ .name = "is_selected", .type = "bool", .default = "false", .desc = "Whether it's picked. Picking it again unpicks it." },
};

const fields = [_]Docs.Field{
    .{ .name = "on_select", .type = "?*const fn (item: *Item(T)) void", .default = "null", .desc = "Called with the item picked or unpicked." },
    .{ .name = "on_close", .type = "?*const fn () void", .default = "null", .desc = "Called when the dialog closes." },
    .{ .name = "row_component", .type = "?*const fn (*Self, *Item(T)) void", .default = "null", .desc = "Draws each row yourself; the dialog keeps the highlight, clicks and keys." },
};

const behaviours = [_]Docs.Field{
    .{ .name = "Searching", .desc = "The search box has focus when it opens; typing shows only the items whose label contains it." },
    .{ .name = "Keyboard", .desc = "Up and Down move the highlight, Enter picks the highlighted item, Tab picks it and closes, Escape closes." },
    .{ .name = "Closing", .desc = "Escape, Tab, or a click outside." },
    .{ .name = "Screen readers", .desc = "The box has role=dialog; the search is a combobox that points at the highlighted option, and the count of results is announced." },
};

pub fn render() void {
    Row()
        .width(.percent(100))
        .layout(.top_center)
        .direction(.column)
        .children({
        Hero("dialog-ui", "Highly customizable, accessible command-palette style dialogs for search and selection.");

        Docs.Content().children({
            Docs.exampleLabel("Basic Dialog");
            Docs.sectionDesc("A searchable list of items, drawn the standard way.");
            Docs.PreviewCard().height(.px(160)).layout(.center).children({
                BasicDialog.render();
            });
            CodeBox(&hl_basic, "BasicDialog");

            Docs.exampleLabel("Custom Rendering");
            Docs.sectionDesc("Your own row_component, here with an icon and a second line per item.");
            Docs.PreviewCard().height(.px(160)).layout(.center).children({
                CustomDialog.render();
            });
            CodeBox(&hl_custom, "CustomDialog");

            Docs.sectionTitle("API Reference");

            Docs.exampleLabel("ComboBoxDialog");
            Docs.sectionDesc("Make one in your init from your items, and render it where its button is.");
            CodeBox(&hl_api, "ComboBoxDialog");

            Docs.exampleLabel("Item");
            Docs.sectionDesc("Opaque.Item(T): one entry, also used by other opaque-ui lists.");
            Docs.ApiBox("Item(T)", &item_fields);

            Docs.exampleLabel("Fields");
            Docs.sectionDesc("Set them after init.");
            Docs.ApiBox("ComboBoxDialog(T)", &fields);

            Docs.exampleLabel("Behaviour");
            Docs.sectionDesc("What the dialog does for you.");
            Docs.ApiBox("Behaviour", &behaviours);
        });
    });
}
