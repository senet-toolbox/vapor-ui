const Vapor = @import("vapor");
const Hero = @import("../../../../components/Hero.zig").Hero;
const Row = Vapor.Row;
const SyntaxHighlighter = @import("vaporize").SyntaxHighlighter;
const CodeBox = @import("../CodeBox.zig").CodeBox;
const Docs = @import("../Docs.zig");
// Rendered and shown as code: what you read is what runs.
const BasicSelect = @import("examples/BasicSelect.zig");
const WithIcons = @import("examples/WithIcons.zig");
const Grouped = @import("examples/Grouped.zig");
const CustomTrigger = @import("examples/CustomTrigger.zig");
const Detached = @import("examples/Detached.zig");

var hl_basic: SyntaxHighlighter = undefined;
var hl_with_icons: SyntaxHighlighter = undefined;
var hl_grouped: SyntaxHighlighter = undefined;
var hl_custom_trigger: SyntaxHighlighter = undefined;
var hl_detached: SyntaxHighlighter = undefined;
var hl_api: SyntaxHighlighter = undefined;

pub fn init() void {
    hl_basic = Docs.highlighter(@embedFile("examples/BasicSelect.zig"));
    hl_with_icons = Docs.highlighter(@embedFile("examples/WithIcons.zig"));
    hl_grouped = Docs.highlighter(@embedFile("examples/Grouped.zig"));
    hl_custom_trigger = Docs.highlighter(@embedFile("examples/CustomTrigger.zig"));
    hl_detached = Docs.highlighter(@embedFile("examples/Detached.zig"));
    hl_api = Docs.highlighter(
        \\const Select = @import("opaque-ui").Select;
        \\
        \\// A select of values of type T, e.g. an enum.
        \\pub fn Select(comptime T: type) type
        \\
        \\// A flat list; the trigger reads "Select" until one is picked.
        \\pub fn fromItems(items: []const Item) Self
        \\// Titled groups, with your placeholder.
        \\pub fn init(trigger: []const u8, groups: []const Group) Self
        \\
        \\// The trigger with the list under it.
        \\pub fn render(select: *Self) void
        \\// Or each on its own, anywhere; set is_detached first.
        \\pub fn renderTrigger(select: *Self) void
        \\pub fn renderSelect(select: *Self) void
        \\
        \\// Picks the item with that label, without calling on_select.
        \\pub fn default(select: *Self, item: Item) void
        \\pub fn selectedValue(select: *Self) ?T
        \\pub fn selectedItem(select: *Self) ?Item
        \\
        \\fn onSelect(select: *Select(T), item: *Select(T).Item) void { ... }
    );

    BasicSelect.init();
    WithIcons.init();
    Grouped.init();
    CustomTrigger.init();
    Detached.init();

    Vapor.Page(.{ .src = @src() }, render, null);
}

const item_fields = [_]Docs.Field{
    .{ .name = "value", .type = "T", .desc = "What selectedValue returns when it's picked." },
    .{ .name = "label", .type = "[]const u8", .desc = "Its text in the list, and in the trigger once picked." },
    .{ .name = "icon", .type = "?IconTokens", .default = "null", .desc = "An icon before the label." },
};

const group_fields = [_]Docs.Field{
    .{ .name = "title", .type = "?[]const u8", .default = "null", .desc = "A heading above the group's items." },
    .{ .name = "items", .type = "[]const Item", .desc = "The group's items." },
};

const fields = [_]Docs.Field{
    .{ .name = "on_select", .type = "?*const fn (*Self, *Item) void", .default = "null", .desc = "Called with the item clicked." },
    .{ .name = "trigger", .type = "[]const u8", .desc = "The trigger's text until something is picked." },
    .{ .name = "trigger_component", .type = "?*const fn (*Self) void", .default = "null", .desc = "Draws the trigger instead, inside the button that opens the list." },
    .{ .name = "trigger_label", .type = "?[]const u8", .default = "null", .desc = "Names the trigger for screen readers; needed when your trigger has no text, like an icon." },
    .{ .name = "is_detached", .type = "bool", .default = "false", .desc = "Set it when you render the trigger and the list apart." },
    .{ .name = "max_height", .type = "f32", .default = "256", .desc = "The list's height before it scrolls; 512 with more than 12 items." },
    .{ .name = "height", .type = "Sizing", .default = ".px(36)", .desc = "The trigger's height, and each item's." },
    .{ .name = "border", .type = "Border", .default = ".round(.transparentize(.black, 0.2), .all(12))", .desc = "The list's border." },
};

const behaviours = [_]Docs.Field{
    .{ .name = "Picking", .desc = "Click an item to pick it; click the picked item again to clear it." },
    .{ .name = "Closing", .desc = "Escape, or a click outside the list." },
    .{ .name = "Keyboard", .desc = "The trigger and items are buttons: Tab reaches them, Enter or Space uses them." },
    .{ .name = "Screen readers", .desc = "The trigger says it opens a listbox and whether it's open. The list has role=listbox; each item has role=option and reports aria-selected." },
};

pub fn render() void {
    Row()
        .width(.percent(100))
        .layout(.top_center)
        .direction(.column)
        .children({
        Hero("select-ui", "A collection of ready-to-use select components built on top of Vapor, copy and paste into your apps.");

        Docs.Content().children({
            Docs.exampleLabel("Basic Select");
            Docs.sectionDesc("A flat list of items.");
            Docs.PreviewCard().height(.px(160)).layout(.center).children({
                BasicSelect.render();
            });
            CodeBox(&hl_basic, "BasicSelect");

            Docs.exampleLabel("With Icons");
            Docs.sectionDesc("Items can show an icon beside their label.");
            Docs.PreviewCard().height(.px(160)).layout(.center).children({
                WithIcons.render();
            });
            CodeBox(&hl_with_icons, "WithIcons");

            Docs.exampleLabel("Grouped");
            Docs.sectionDesc("Items under titled groups, made with init.");
            Docs.PreviewCard().height(.px(160)).layout(.center).children({
                Grouped.render();
            });
            CodeBox(&hl_grouped, "Grouped");

            Docs.exampleLabel("Custom Trigger");
            Docs.sectionDesc("Your own trigger, here an icon, named for screen readers with trigger_label.");
            Docs.PreviewCard().height(.px(160)).layout(.center).children({
                CustomTrigger.render();
            });
            CodeBox(&hl_custom_trigger, "CustomTrigger");

            Docs.exampleLabel("Detached");
            Docs.sectionDesc("The trigger and the list rendered apart, each where you put it.");
            Docs.PreviewCard().height(.px(160)).layout(.center).children({
                Detached.render();
            });
            CodeBox(&hl_detached, "Detached");

            Docs.sectionTitle("API Reference");

            Docs.exampleLabel("Select");
            Docs.sectionDesc("Make one in your init from items or groups, and render it.");
            CodeBox(&hl_api, "Select");

            Docs.exampleLabel("Item");
            Docs.sectionDesc("One choice.");
            Docs.ApiBox("Item", &item_fields);

            Docs.exampleLabel("Group");
            Docs.sectionDesc("For init.");
            Docs.ApiBox("Group", &group_fields);

            Docs.exampleLabel("Fields");
            Docs.sectionDesc("Set them after init.");
            Docs.ApiBox("Select(T)", &fields);

            Docs.exampleLabel("Behaviour");
            Docs.sectionDesc("What the select does for you.");
            Docs.ApiBox("Behaviour", &behaviours);
        });
    });
}
