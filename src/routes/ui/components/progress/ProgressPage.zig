const Vapor = @import("vapor");
const Hero = @import("../../../../components/Hero.zig").Hero;
const Row = Vapor.Row;
const SyntaxHighlighter = @import("vaporize").SyntaxHighlighter;
const CodeBox = @import("../CodeBox.zig").CodeBox;
const Docs = @import("../Docs.zig");
// Rendered and shown as code: what you read is what runs.
const ProgressBarBasic = @import("examples/ProgressBarBasic.zig");
const ProgressCircleBasic = @import("examples/ProgressCircleBasic.zig");
const ProgressBarAnimated = @import("examples/ProgressBarAnimated.zig");
const ProgressCircleLabel = @import("examples/ProgressCircleLabel.zig");

var hl_bar: SyntaxHighlighter = undefined;
var hl_circle: SyntaxHighlighter = undefined;
var hl_bar_animated: SyntaxHighlighter = undefined;
var hl_circle_label: SyntaxHighlighter = undefined;
var hl_api: SyntaxHighlighter = undefined;

pub fn init() void {
    hl_bar = Docs.highlighter(@embedFile("examples/ProgressBarBasic.zig"));
    hl_circle = Docs.highlighter(@embedFile("examples/ProgressCircleBasic.zig"));
    hl_bar_animated = Docs.highlighter(@embedFile("examples/ProgressBarAnimated.zig"));
    hl_circle_label = Docs.highlighter(@embedFile("examples/ProgressCircleLabel.zig"));
    hl_api = Docs.highlighter(
        \\const Opaque = @import("opaque-ui");
        \\const ProgressBar = Opaque.ProgressBar;
        \\const ProgressCircle = Opaque.ProgressCircle;
        \\
        \\// Both have the same methods.
        \\pub fn init(allocator: std.mem.Allocator, config: Config) ProgressBar
        \\// Sets the value, 0 to 1, before the next render.
        \\pub fn setProgress(self: *ProgressBar, value: f64) void
        \\// Moves it to the value now, animated, without a rerender.
        \\pub fn updateProgress(self: *ProgressBar, value: f64) void
        \\// setProgress, from 0 to 100.
        \\pub fn setPercent(self: *ProgressBar, percent: f64) void
        \\pub fn render(self: *ProgressBar) void
        \\
        \\// The value, 0 to 1.
        \\progress: f64
    );
    ProgressBarBasic.init();
    ProgressCircleBasic.init();
    ProgressBarAnimated.init();
    ProgressCircleLabel.init();

    Vapor.Page(.{ .src = @src() }, render, null);
}

const bar_config = [_]Docs.Field{
    .{ .name = "id", .type = "?[]const u8", .default = "null", .desc = "Names its elements. Without it they're numbered in creation order, so create your bars in the same order everywhere." },
    .{ .name = "width", .type = "u32", .default = "200", .desc = "In px." },
    .{ .name = "height", .type = "u32", .default = "20", .desc = "In px." },
    .{ .name = "color", .type = "Color", .default = ".hex(\"#3b82f6\")", .desc = "The filled part." },
    .{ .name = "track_color", .type = "Color", .default = ".hex(\"#e5e7eb\")", .desc = "The unfilled part." },
    .{ .name = "border_radius", .type = "?f32", .default = "null", .desc = "The corners; null rounds the ends fully." },
    .{ .name = "show_label", .type = "bool", .default = "false", .desc = "Shows the percentage." },
    .{ .name = "label_position", .type = "LabelPosition", .default = ".inside", .desc = ".inside, .above, .below or .right of the bar." },
    .{ .name = "label_font_size", .type = "u32", .default = "12", .desc = "In px." },
    .{ .name = "label_color", .type = "?Color", .default = "null", .desc = "The label's colour." },
    .{ .name = "animated", .type = "bool", .default = "true", .desc = "Slides to each new value." },
    .{ .name = "direction", .type = "Direction", .default = ".ltr", .desc = "Fills from the left, or with .rtl from the right." },
    .{ .name = "striped", .type = "bool", .default = "false", .desc = "Diagonal stripes on the fill, in stripe_color (white unless set)." },
};

const circle_config = [_]Docs.Field{
    .{ .name = "id", .type = "?[]const u8", .default = "null", .desc = "As for the bar." },
    .{ .name = "size", .type = "u32", .default = "120", .desc = "The diameter, in px." },
    .{ .name = "stroke_width", .type = "f32", .default = "10", .desc = "The ring's thickness, in px." },
    .{ .name = "color", .type = "?Color", .default = ".hex(\"#3b82f6\")", .desc = "The filled part of the ring. linearGradient and radialGradient replace it with a gradient." },
    .{ .name = "track_color", .type = "Color", .default = ".hex(\"#e5e7eb\")", .desc = "The unfilled part." },
    .{ .name = "rounded_caps", .type = "bool", .default = "true", .desc = "Rounds the ends of the filled part." },
    .{ .name = "show_label", .type = "bool", .default = "true", .desc = "Shows the percentage in the middle." },
    .{ .name = "label_font_size", .type = "u32", .default = "24", .desc = "In px." },
    .{ .name = "label_color", .type = "?Color", .default = "null", .desc = "The label's colour." },
    .{ .name = "clockwise", .type = "bool", .default = "true", .desc = "Which way it fills." },
    .{ .name = "start_angle", .type = "f64", .default = "-90", .desc = "Where it starts, in degrees; -90 is the top." },
};

const behaviours = [_]Docs.Field{
    .{ .name = "Screen readers", .desc = "Both have role=progressbar, named Progress, and report their value from 0 to 100, also after updateProgress." },
    .{ .name = "Animation", .desc = "updateProgress glides to the new value in 300ms." },
    .{ .name = "Over time", .desc = "Call updateProgress from a Vapor.lib.loopInterval, as Animated Progress Bar does." },
};

pub fn render() void {
    Row()
        .width(.percent(100))
        .layout(.top_center)
        .direction(.column)
        .children({
        Hero("progress-ui", "A collection of ready-to-use progress components built on top of Vapor, copy and paste into your apps.");

        Docs.Content().children({
            Docs.exampleLabel("Progress Bar");
            Docs.sectionDesc("A horizontal bar, any size and colours.");
            Docs.PreviewCard().height(.px(160)).layout(.center).children({
                ProgressBarBasic.render();
            });
            CodeBox(&hl_bar, "ProgressBarBasic");

            Docs.exampleLabel("Progress Circle");
            Docs.sectionDesc("A ring, any size and thickness.");
            Docs.PreviewCard().height(.px(200)).layout(.center).children({
                ProgressCircleBasic.render();
            });
            CodeBox(&hl_circle, "ProgressCircleBasic");

            Docs.exampleLabel("Animated Progress Bar");
            Docs.sectionDesc("updateProgress, called on an interval, runs the bar up to 100%.");
            Docs.PreviewCard().height(.px(200)).layout(.center).children({
                ProgressBarAnimated.render();
            });
            CodeBox(&hl_bar_animated, "ProgressBarAnimated");

            Docs.exampleLabel("Progress Circle with Label");
            Docs.sectionDesc("The percentage in the middle, kept up to date.");
            Docs.PreviewCard().height(.px(200)).layout(.center).children({
                ProgressCircleLabel.render();
            });
            CodeBox(&hl_circle_label, "ProgressCircleLabel");

            Docs.sectionTitle("API Reference");

            Docs.exampleLabel("ProgressBar and ProgressCircle");
            Docs.sectionDesc("Make one in your init, set its value, and render it.");
            CodeBox(&hl_api, "Progress");

            Docs.exampleLabel("ProgressBar.Config");
            Docs.sectionDesc("Passed to init.");
            Docs.ApiBox("ProgressBar.Config", &bar_config);

            Docs.exampleLabel("ProgressCircle.Config");
            Docs.sectionDesc("Passed to init.");
            Docs.ApiBox("ProgressCircle.Config", &circle_config);

            Docs.exampleLabel("Behaviour");
            Docs.sectionDesc("What both do for you.");
            Docs.ApiBox("Behaviour", &behaviours);
        });
    });
}
