const Vapor = @import("vapor");
const Hero = @import("../../../../components/Hero.zig").Hero;
const Row = Vapor.Row;
const SyntaxHighlighter = @import("vaporize").SyntaxHighlighter;
const CodeBox = @import("../CodeBox.zig").CodeBox;
const Docs = @import("../Docs.zig");
// Rendered and shown as code: what you read is what runs.
const BasicRadio = @import("examples/BasicRadio.zig");

var hl_basic: SyntaxHighlighter = undefined;
var hl_api: SyntaxHighlighter = undefined;

pub fn init() void {
    hl_basic = Docs.highlighter(@embedFile("examples/BasicRadio.zig"));
    hl_api = Docs.highlighter(
        \\const Radio = @import("opaque-ui").Radio;
        \\
        \\// Holds the items and which one is chosen. Calls on_change with
        \\// args, then the chosen value, only when the choice changes.
        \\pub fn Group(name: []const u8, default_value: []const u8, comptime on_change: anytype, args: anytype) Vapor.Builder(.pure)
        \\// One choice. Call it inside the group's children.
        \\pub fn Item(value: []const u8, label: []const u8) void
        \\
        \\fn onChange(value: []const u8) void { ... }
        \\
        \\// The colours of every radio; set them once, in your init.
        \\pub var ring_color: Color = .palette(.border_color_light);
        \\pub var checked_color: Color = .palette(.tint);
    );

    Vapor.Page(.{ .src = @src() }, render, null);
}

const group_params = [_]Docs.Field{
    .{ .name = "name", .type = "[]const u8", .desc = "Names the group for screen readers." },
    .{ .name = "default_value", .type = "[]const u8", .desc = "The value chosen at first. on_change isn't called for it." },
    .{ .name = "on_change", .type = "comptime anytype", .desc = "Called with args and then the chosen value." },
    .{ .name = "args", .type = "anytype", .desc = "A tuple of arguments for on_change; .{} for none." },
};

const item_params = [_]Docs.Field{
    .{ .name = "value", .type = "[]const u8", .desc = "What on_change receives when this item is chosen. Unique within the group." },
    .{ .name = "label", .type = "[]const u8", .desc = "The text beside the circle; clicking it chooses the item too." },
};

const behaviours = [_]Docs.Field{
    .{ .name = "Choosing", .desc = "One item at a time. Clicking the chosen one again does nothing." },
    .{ .name = "State", .desc = "The group keeps its choice across renders, and forgets it when it leaves the page." },
    .{ .name = "Keyboard", .desc = "Tab stops once, on the chosen item. The arrow keys move the choice and the focus to the next or previous item, wrapping round." },
    .{ .name = "Screen readers", .desc = "The group has role=radiogroup and its name; each item has role=radio and reports aria-checked." },
};

pub fn render() void {
    Row()
        .width(.percent(100))
        .layout(.top_center)
        .direction(.column)
        .children({
        Hero("radio-ui", "Radio buttons for picking one option out of a group, with keyboard and screen reader support.");

        Docs.Content().children({
            Docs.exampleLabel("Basic Radio");
            Docs.sectionDesc("A group starts on its default value and reports each change.");
            Docs.PreviewCard().children({
                BasicRadio.render();
            });
            CodeBox(&hl_basic, "BasicRadio");

            Docs.sectionTitle("API Reference");

            Docs.exampleLabel("Radio");
            Docs.sectionDesc("A Group, with an Item per choice in its children.");
            CodeBox(&hl_api, "Radio");

            Docs.exampleLabel("Group");
            Docs.sectionDesc("What Group takes.");
            Docs.ApiBox("Group", &group_params);

            Docs.exampleLabel("Item");
            Docs.sectionDesc("What Item takes.");
            Docs.ApiBox("Item", &item_params);

            Docs.exampleLabel("Behaviour");
            Docs.sectionDesc("What the radio group does for you.");
            Docs.ApiBox("Behaviour", &behaviours);
        });
    });
}
