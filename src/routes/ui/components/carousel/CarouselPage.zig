const Vapor = @import("vapor");
const Hero = @import("../../../../components/Hero.zig").Hero;
const Row = Vapor.Row;
const SyntaxHighlighter = @import("vaporize").SyntaxHighlighter;
const CodeBox = @import("../CodeBox.zig").CodeBox;
const Docs = @import("../Docs.zig");
// Rendered and shown as code: what you read is what runs.
const BasicCarousel = @import("examples/BasicCarousel.zig");
const CarouselOptions = @import("examples/CarouselOptions.zig");

var hl_basic: SyntaxHighlighter = undefined;
var hl_options: SyntaxHighlighter = undefined;
var hl_api: SyntaxHighlighter = undefined;

pub fn init() void {
    hl_basic = Docs.highlighter(@embedFile("examples/BasicCarousel.zig"));
    hl_options = Docs.highlighter(@embedFile("examples/CarouselOptions.zig"));
    hl_api = Docs.highlighter(
        \\const Carousel = @import("opaque-ui").Carousel;
        \\
        \\// Opens the carousel; your slides go in its children.
        \\pub fn render(options: Options) *Carousel
        \\// Closes it, adding the arrows and dots after your slides.
        \\pub fn children(self: *Carousel, _: void) void
        \\
        \\// Call Opaque.new() once in your app's init: it sets up
        \\// the state every opaque-ui component keeps.
        \\@import("opaque-ui").new();
    );

    Vapor.Page(.{ .src = @src() }, render, null);
}

const options = [_]Docs.Field{
    .{ .name = "id", .type = "[]const u8", .desc = "Required. Names the carousel, so it keeps its slide across renders. One per carousel." },
    .{ .name = "count", .type = "usize", .desc = "Required. How many slides you render, for the dots and the ends." },
    .{ .name = "viewport_width", .type = "f32", .default = "480", .desc = "The width shown, in px. Never wider than its container: on a narrow screen the slide is cropped." },
    .{ .name = "viewport_height", .type = "f32", .default = "280", .desc = "The height shown, in px." },
    .{ .name = "stride", .type = "f32", .default = "496", .desc = "From one slide's start to the next: slide width plus gap. Render your slides that wide." },
    .{ .name = "loop", .type = "bool", .default = "true", .desc = "Wrap from the last slide to the first, and back." },
    .{ .name = "show_arrows", .type = "bool", .default = "true", .desc = "Previous and next buttons over the slides." },
    .{ .name = "show_dots", .type = "bool", .default = "true", .desc = "A dot per slide below, to jump to it." },
    .{ .name = "swipe_threshold", .type = "f32", .default = "60", .desc = "How far, in px, a drag must go to change slide." },
    .{ .name = "transition_ms", .type = "u32", .default = "350", .desc = "How long the slide takes to settle." },
};

const behaviours = [_]Docs.Field{
    .{ .name = "Swiping", .desc = "Drag with a mouse or finger and the slides follow. Past swipe_threshold it moves one slide on release; a shorter drag springs back. Vertical swipes still scroll the page." },
    .{ .name = "Keyboard", .desc = "The arrows and dots are buttons: Tab reaches them, Enter or Space uses them." },
    .{ .name = "Screen readers", .desc = "The arrows are named Previous slide and Next slide, the dots Go to slide 1, 2…" },
    .{ .name = "One slide", .desc = "With a single slide there are no arrows or dots." },
};

pub fn render() void {
    Row()
        .width(.percent(100))
        .layout(.top_center)
        .direction(.column)
        .children({
        Hero("carousel-ui", "Click + swipe carousel. Prev / next arrows, dot indicators, drag to swipe.");

        Docs.Content().children({
            Docs.exampleLabel("Basic Carousel");
            Docs.sectionDesc("Click the arrows, drag to swipe, or click a dot to jump. You draw the slides; the carousel moves them.");
            Docs.PreviewCard().layout(.center).children({
                BasicCarousel.render();
            });
            CodeBox(&hl_basic, "BasicCarousel");

            Docs.exampleLabel("Compact");
            Docs.sectionDesc("Smaller slides: the viewport and stride follow the slide size.");
            Docs.PreviewCard().layout(.center).children({
                CarouselOptions.compact();
            });

            Docs.exampleLabel("Bounded");
            Docs.sectionDesc("Stops at the first and last slide instead of wrapping.");
            Docs.PreviewCard().layout(.center).children({
                CarouselOptions.bounded();
            });

            Docs.exampleLabel("Arrows Only");
            Docs.sectionDesc("No dots below.");
            Docs.PreviewCard().layout(.center).children({
                CarouselOptions.arrowsOnly();
            });

            Docs.exampleLabel("Dots Only");
            Docs.sectionDesc("No arrows: swipe, or use the dots.");
            Docs.PreviewCard().layout(.center).children({
                CarouselOptions.dotsOnly();
            });
            CodeBox(&hl_options, "CarouselOptions");

            Docs.sectionTitle("API Reference");

            Docs.exampleLabel("Carousel");
            Docs.sectionDesc("render takes the options and opens the carousel; your slides go in its children.");
            CodeBox(&hl_api, "Carousel");

            Docs.exampleLabel("Options");
            Docs.sectionDesc("Passed to render, each time; the carousel keeps only which slide it's on.");
            Docs.ApiBox("Options", &options);

            Docs.exampleLabel("Behaviour");
            Docs.sectionDesc("What the carousel does for you.");
            Docs.ApiBox("Behaviour", &behaviours);
        });
    });
}
