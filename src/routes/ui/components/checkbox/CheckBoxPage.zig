const Vapor = @import("vapor");
const Hero = @import("../../../../components/Hero.zig").Hero;
const Row = Vapor.Row;
const SyntaxHighlighter = @import("vaporize").SyntaxHighlighter;
const CodeBox = @import("../CodeBox.zig").CodeBox;
const Docs = @import("../Docs.zig");
// Rendered and shown as code: what you read is what runs.
const BasicCheckbox = @import("examples/BasicCheckbox.zig");
const CustomCheckbox = @import("examples/CustomCheckbox.zig");

var hl_basic: SyntaxHighlighter = undefined;
var hl_custom: SyntaxHighlighter = undefined;
var hl_api: SyntaxHighlighter = undefined;

pub fn init() void {
    hl_basic = Docs.highlighter(@embedFile("examples/BasicCheckbox.zig"));
    hl_custom = Docs.highlighter(@embedFile("examples/CustomCheckbox.zig"));
    hl_api = Docs.highlighter(
        \\const Checkbox = @import("opaque-ui").Checkbox;
        \\
        \\// A ready-made checkbox. Calls on_change with args on each click.
        \\pub fn render(aria_label: []const u8, on_change: anytype, args: anytype) void
        \\
        \\// Your own look: returns the button, to style and fill. Calls
        \\// on_change with args, then the new state.
        \\pub fn create(id: []const u8, on_change: anytype, args: anytype) Vapor.Builder(.pure)
        \\
        \\fn onChange(checked: bool) void { ... }
    );

    Vapor.Page(.{ .src = @src() }, render, null);
}

const params = [_]Docs.Field{
    .{ .name = "aria_label", .type = "[]const u8", .desc = "render only. The checkbox's name for screen readers; it shows no text of its own, so put a label beside it." },
    .{ .name = "id", .type = "[]const u8", .desc = "create only. A unique id; the checkbox keeps its state under it. Name it yourself with .ariaLabel." },
    .{ .name = "on_change", .type = "anytype", .desc = "The function to call on each click." },
    .{ .name = "args", .type = "anytype", .desc = "A tuple of arguments for on_change. create adds the new state after them." },
};

const behaviours = [_]Docs.Field{
    .{ .name = "State", .desc = "Each checkbox keeps whether it's checked, starting unchecked, and forgets it when it leaves the page." },
    .{ .name = "Keyboard", .desc = "It's a button: Tab reaches it, Enter or Space toggles it." },
    .{ .name = "Screen readers", .desc = "Both have role=checkbox and report aria-checked." },
};

pub fn render() void {
    Row()
        .width(.percent(100))
        .layout(.top_center)
        .direction(.column)
        .children({
        Hero("checkbox-ui", "A collection of ready-to-use checkbox components built on top of Vapor, copy and paste into your apps.");

        Docs.Content().children({
            Docs.exampleLabel("Basic Checkbox");
            Docs.sectionDesc("A ready-made checkbox. It keeps its own state; your callback hears each click.");
            Docs.PreviewCard().height(.px(160)).layout(.center).children({
                BasicCheckbox.render();
            });
            CodeBox(&hl_basic, "BasicCheckbox");

            Docs.exampleLabel("Custom Checkbox");
            Docs.sectionDesc("Any look you like: here an icon that turns red when checked.");
            Docs.PreviewCard().height(.px(160)).layout(.center).children({
                CustomCheckbox.render();
            });
            CodeBox(&hl_custom, "CustomCheckbox");

            Docs.sectionTitle("API Reference");

            Docs.exampleLabel("Checkbox");
            Docs.sectionDesc("render draws a ready-made one; create returns one for you to style.");
            CodeBox(&hl_api, "Checkbox");

            Docs.exampleLabel("Parameters");
            Docs.sectionDesc("What render and create take.");
            Docs.ApiBox("Parameters", &params);

            Docs.exampleLabel("Behaviour");
            Docs.sectionDesc("What the checkbox does for you.");
            Docs.ApiBox("Behaviour", &behaviours);
        });
    });
}
