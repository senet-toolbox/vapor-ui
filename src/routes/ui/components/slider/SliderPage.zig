const Vapor = @import("vapor");
const Hero = @import("../../../../components/Hero.zig").Hero;
const Row = Vapor.Row;
const SyntaxHighlighter = @import("vaporize").SyntaxHighlighter;
const CodeBox = @import("../CodeBox.zig").CodeBox;
const Docs = @import("../Docs.zig");
// Rendered and shown as code: what you read is what runs.
const BasicSlider = @import("examples/BasicSlider.zig");

var hl_basic: SyntaxHighlighter = undefined;
var hl_api: SyntaxHighlighter = undefined;

pub fn init() void {
    hl_basic = Docs.highlighter(@embedFile("examples/BasicSlider.zig"));
    hl_api = Docs.highlighter(
        \\const Slider = @import("opaque-ui").Slider;
        \\
        \\// Draws a slider as wide as its container.
        \\pub fn render(options: Slider) void
        \\
        \\fn onChange(value: f32) void { ... }
    );

    Vapor.Page(.{ .src = @src() }, render, null);
}

const options = [_]Docs.Field{
    .{ .name = "min", .type = "f32", .default = "0", .desc = "The value at the left end." },
    .{ .name = "max", .type = "f32", .default = "100", .desc = "The value at the right end." },
    .{ .name = "value", .type = "f32", .default = "0", .desc = "Where it starts. After the first render the slider keeps its own value." },
    .{ .name = "step", .type = "f32", .default = "1", .desc = "Values snap to min plus a multiple of it. With 0 the value is free, and keys move a hundredth of the range." },
    .{ .name = "label", .type = "[]const u8", .default = "\"Slider\"", .desc = "Names it for screen readers." },
    .{ .name = "on_change", .type = "?*const fn (value: f32) void", .default = "null", .desc = "Called with the new value whenever it changes." },
};

const behaviours = [_]Docs.Field{
    .{ .name = "Pointer", .desc = "Press anywhere on the track to jump there, and drag to slide." },
    .{ .name = "Keyboard", .desc = "Tab to the handle. Arrow keys move one step, Page Up and Down ten, Home and End to min and max." },
    .{ .name = "Screen readers", .desc = "The handle has role=slider, its label, and reports its value, min and max." },
};

pub fn render() void {
    Row()
        .width(.percent(100))
        .layout(.top_center)
        .direction(.column)
        .children({
        Hero("slider-ui", "A slider for picking a number in a range, by pointer or keyboard.");

        Docs.Content().children({
            Docs.exampleLabel("Basic Slider");
            Docs.sectionDesc("Drag the handle, press the track, or focus it and use the arrow keys.");
            Docs.PreviewCard().layout(.center).children({
                Row().width(.percent(70)).direction(.column).children({
                    BasicSlider.render();
                });
            });
            CodeBox(&hl_basic, "BasicSlider");

            Docs.sectionTitle("API Reference");

            Docs.exampleLabel("Slider");
            Docs.sectionDesc("One function draws it, from its options.");
            CodeBox(&hl_api, "Slider");

            Docs.exampleLabel("Options");
            Docs.sectionDesc("Passed to render, each time; the slider keeps only its value.");
            Docs.ApiBox("Slider", &options);

            Docs.exampleLabel("Behaviour");
            Docs.sectionDesc("What the slider does for you.");
            Docs.ApiBox("Behaviour", &behaviours);
        });
    });
}
