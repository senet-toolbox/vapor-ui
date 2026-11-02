const Vapor = @import("vapor");
const Hero = @import("../../../../components/Hero.zig").Hero;
const Row = Vapor.Row;
const SyntaxHighlighter = @import("vaporize").SyntaxHighlighter;
const CodeBox = @import("../CodeBox.zig").CodeBox;
const Docs = @import("../Docs.zig");
// Rendered and shown as code: what you read is what runs.
const BasicTooltip = @import("examples/BasicTooltip.zig");
const TooltipCustom = @import("examples/TooltipCustom.zig");
const TooltipCustomTrigger = @import("examples/TooltipCustomTrigger.zig");

var hl_basic: SyntaxHighlighter = undefined;
var hl_custom_trigger: SyntaxHighlighter = undefined;
var hl_custom: SyntaxHighlighter = undefined;
var hl_api: SyntaxHighlighter = undefined;

pub fn init() void {
    hl_basic = Docs.highlighter(@embedFile("examples/BasicTooltip.zig"));
    hl_custom_trigger = Docs.highlighter(@embedFile("examples/TooltipCustomTrigger.zig"));
    hl_custom = Docs.highlighter(@embedFile("examples/TooltipCustom.zig"));
    hl_api = Docs.highlighter(
        \\const Opaque = @import("opaque-ui");
        \\const Tooltip = Opaque.Tooltip;
        \\
        \\// Once, in your layout: every tooltip shows in this layer.
        \\Opaque.TooltipLayer();
        \\
        \\// A text trigger with a text tooltip, above it or where you say.
        \\pub fn simple(title: []const u8, content: []const u8) void
        \\pub fn simpleWithPosition(title: []const u8, content: []const u8, position: AnchorPlacement) void
        \\
        \\// Your own trigger, and optionally your own content.
        \\pub fn create(options: Options) *Tooltip
        \\pub fn Trigger(tooltip: *Tooltip, trigger: anytype, args: anytype) *Tooltip
        \\pub fn Component(tooltip: *Tooltip, component: anytype, args: anytype) *Tooltip
        \\pub fn end(tooltip: *Tooltip) void
        \\
        \\Tooltip.create(.{ .content = "Saved" })
        \\    .Trigger(SaveIcon, .{})
        \\    .end();
    );

    Vapor.Page(.{ .src = @src() }, render, null);
}

const options = [_]Docs.Field{
    .{ .name = "content", .type = "[]const u8", .default = "\"\"", .desc = "The tooltip's text, when Component doesn't draw it." },
    .{ .name = "position", .type = "AnchorPlacement", .default = ".top", .desc = "Which side of the trigger it shows on: .top, .bottom, .left or .right." },
    .{ .name = "background", .type = "Color", .default = ".black", .desc = "The popup's background." },
    .{ .name = "stroke_color", .type = "Color", .default = ".black", .desc = "The outline of the arrow pointing at the trigger." },
    .{ .name = "border", .type = "Border", .default = ".round(.transparent, .all(6))", .desc = "The popup's border and corners." },
    .{ .name = "id", .type = "[]const u8", .default = "\"\"", .desc = "Names the trigger for the popup to anchor to. Made for you when empty." },
};

const behaviours = [_]Docs.Field{
    .{ .name = "Showing", .desc = "After half a second's hover, or as soon as the trigger has keyboard focus." },
    .{ .name = "Hiding", .desc = "Shortly after the pointer leaves or focus moves on, or at once on Escape." },
    .{ .name = "Placement", .desc = "Beside the trigger, never over it, with an arrow pointing at it." },
    .{ .name = "Screen readers", .desc = "The popup has role=tooltip." },
};

pub fn render() void {
    Row()
        .width(.percent(100))
        .layout(.top_center)
        .direction(.column)
        .children({
        Hero("tooltip-ui", "A collection of ready-to-use tooltip components built on top of Vapor, copy and paste into your apps.");

        Docs.Content().children({
            Docs.exampleLabel("Basic Tooltip");
            Docs.sectionDesc("Text to hover or focus, and a short line that explains it.");
            Docs.PreviewCard().height(.px(160)).layout(.center).children({
                BasicTooltip.render();
            });
            CodeBox(&hl_basic, "BasicTooltip");

            Docs.exampleLabel("Custom Trigger");
            Docs.sectionDesc("Any component can be the trigger; your function draws it.");
            Docs.PreviewCard().height(.px(160)).layout(.center).children({
                TooltipCustomTrigger.render();
            });
            CodeBox(&hl_custom_trigger, "TooltipCustomTrigger");

            Docs.exampleLabel("Custom Content");
            Docs.sectionDesc("The popup can hold any component too, with its own colours.");
            Docs.PreviewCard().height(.px(160)).layout(.center).children({
                TooltipCustom.render();
            });
            CodeBox(&hl_custom, "TooltipCustom");

            Docs.sectionTitle("API Reference");

            Docs.exampleLabel("Tooltip");
            Docs.sectionDesc("simple for text; create, Trigger and Component for your own.");
            CodeBox(&hl_api, "Tooltip");

            Docs.exampleLabel("Options");
            Docs.sectionDesc("Passed to create. Set once: the tooltip keeps the first render's.");
            Docs.ApiBox("Options", &options);

            Docs.exampleLabel("Behaviour");
            Docs.sectionDesc("What the tooltip does for you.");
            Docs.ApiBox("Behaviour", &behaviours);
        });
    });
}
