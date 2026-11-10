const Vapor = @import("vapor");
const Hero = @import("../../../../components/Hero.zig").Hero;
const Row = Vapor.Row;
const SyntaxHighlighter = @import("vaporize").SyntaxHighlighter;
const CodeBox = @import("../CodeBox.zig").CodeBox;
const Docs = @import("../Docs.zig");
// Rendered and shown as code: what you read is what runs.
const CardSkeleton = @import("examples/CardSkeleton.zig");
const LoadingSkeleton = @import("examples/LoadingSkeleton.zig");

var hl_CardSkeleton: SyntaxHighlighter = undefined;
var hl_LoadingSkeleton: SyntaxHighlighter = undefined;
var hl_api: SyntaxHighlighter = undefined;

pub fn init() void {
    hl_CardSkeleton = Docs.highlighter(@embedFile("examples/CardSkeleton.zig"));
    hl_LoadingSkeleton = Docs.highlighter(@embedFile("examples/LoadingSkeleton.zig"));
    hl_api = Docs.highlighter(
        \\const Skeleton = @import("opaque-ui").Skeleton;
        \\
        \\pub fn render(options: Options) void
        \\// lines of text, the last one shorter.
        \\pub fn text(lines: usize) void
        \\// An avatar, diameter pixels across.
        \\pub fn circle(diameter: f32) void
    );
    Vapor.Page(.{ .src = @src() }, render, null);
}

const options = [_]Docs.Field{
    .{ .name = "width", .type = "Sizing", .default = ".percent(100)", .desc = "Its width." },
    .{ .name = "height", .type = "f32", .default = "16", .desc = "In pixels." },
    .{ .name = "radius", .type = "u16", .default = "6", .desc = "Corner radius, in pixels." },
};

const settings = [_]Docs.Field{
    .{ .name = "color", .type = "Color", .default = ".transparentize(.palette(.text_color), 0.12)", .desc = "Its fill: a faint wash of the text colour, for both themes." },
};

const behaviours = [_]Docs.Field{
    .{ .name = "Pulse", .desc = "It fades in and out, and holds still when the system asks for less motion." },
    .{ .name = "Screen readers", .desc = "They skip it. Mark the region that loads aria-busy, as the second example does." },
    .{ .name = "Startup", .desc = "Opaque.new() registers the pulse; call Skeleton.new() instead if you do not call that." },
};

pub fn render() void {
    Row()
        .width(.percent(100))
        .layout(.top_center)
        .direction(.column)
        .children({
        Hero("skeleton-ui", "Shapes where content will be while it loads.");

        Docs.Content().children({
            Docs.exampleLabel("Shapes");
            Docs.sectionDesc("A block, a circle and lines of text, in the layout the content will have.");
            Docs.PreviewCard().layout(.center).children({
                CardSkeleton.render();
            });
            CodeBox(&hl_CardSkeleton, "CardSkeleton");

            Docs.exampleLabel("While it loads");
            Docs.sectionDesc("Reload to see the skeleton stand in for a second.");
            Docs.PreviewCard().layout(.center).children({
                LoadingSkeleton.render();
            });
            CodeBox(&hl_LoadingSkeleton, "LoadingSkeleton");

            Docs.sectionTitle("API Reference");

            Docs.exampleLabel("Skeleton");
            CodeBox(&hl_api, "Skeleton");

            Docs.exampleLabel("Options");
            Docs.ApiBox("Options", &options);

            Docs.exampleLabel("Settings");
            Docs.sectionDesc("Skeleton globals; set them once.");
            Docs.ApiBox("Skeleton", &settings);

            Docs.exampleLabel("Behaviour");
            Docs.sectionDesc("What skeleton does for you.");
            Docs.ApiBox("Behaviour", &behaviours);
        });
    });
}
