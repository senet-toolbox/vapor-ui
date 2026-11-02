const Vapor = @import("vapor");
const Hero = @import("../../../../components/Hero.zig").Hero;
const Row = Vapor.Row;
const SyntaxHighlighter = @import("vaporize").SyntaxHighlighter;
const CodeBox = @import("../CodeBox.zig").CodeBox;
const Docs = @import("../Docs.zig");
// Rendered and shown as code: what you read is what runs.
const BasicSwitch = @import("examples/BasicSwitch.zig");

var hl_basic: SyntaxHighlighter = undefined;
var hl_api: SyntaxHighlighter = undefined;

pub fn init() void {
    hl_basic = Docs.highlighter(@embedFile("examples/BasicSwitch.zig"));
    hl_api = Docs.highlighter(
        \\const Switch = @import("opaque-ui").Switch;
        \\
        \\// Draws a switch. Calls on_change with args on each flip.
        \\pub fn render(aria_label: []const u8, on_change: anytype, args: anytype) void
        \\
        \\fn onChange() void { ... }
    );

    Vapor.Page(.{ .src = @src() }, render, null);
}

const params = [_]Docs.Field{
    .{ .name = "aria_label", .type = "[]const u8", .desc = "The switch's name for screen readers; it shows no text of its own, so put a label beside it." },
    .{ .name = "on_change", .type = "anytype", .desc = "The function to call on each flip." },
    .{ .name = "args", .type = "anytype", .desc = "A tuple of arguments for on_change; .{} for none." },
};

const behaviours = [_]Docs.Field{
    .{ .name = "State", .desc = "Each switch keeps whether it's on, starting off, and forgets it when it leaves the page." },
    .{ .name = "Keyboard", .desc = "It's a button: Tab reaches it, Enter or Space flips it." },
    .{ .name = "Screen readers", .desc = "It has role=switch and reports aria-checked." },
    .{ .name = "Animation", .desc = "The knob slides across in 100ms." },
};

pub fn render() void {
    Row()
        .width(.percent(100))
        .layout(.top_center)
        .direction(.column)
        .children({
        Hero("switch-ui", "A collection of ready-to-use switch components built on top of Vapor, copy and paste into your apps.");

        Docs.Content().children({
            Docs.exampleLabel("Basic Switch");
            Docs.sectionDesc("An on/off setting. The switch keeps its own state; your callback hears each flip.");
            Docs.PreviewCard().height(.px(160)).layout(.center).children({
                BasicSwitch.render();
            });
            CodeBox(&hl_basic, "BasicSwitch");

            Docs.sectionTitle("API Reference");

            Docs.exampleLabel("Switch");
            Docs.sectionDesc("One function draws it.");
            CodeBox(&hl_api, "Switch");

            Docs.exampleLabel("Parameters");
            Docs.sectionDesc("What render takes.");
            Docs.ApiBox("Parameters", &params);

            Docs.exampleLabel("Behaviour");
            Docs.sectionDesc("What the switch does for you.");
            Docs.ApiBox("Behaviour", &behaviours);
        });
    });
}
