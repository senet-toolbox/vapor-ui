const Vapor = @import("vapor");
const Hero = @import("../../../../components/Hero.zig").Hero;
const Row = Vapor.Row;
const SyntaxHighlighter = @import("vaporize").SyntaxHighlighter;
const CodeBox = @import("../CodeBox.zig").CodeBox;
const Docs = @import("../Docs.zig");
// Rendered and shown as code: what you read is what runs.
const BasicSegmented = @import("examples/BasicSegmented.zig");
const FullWidthSegmented = @import("examples/FullWidthSegmented.zig");

var hl_BasicSegmented: SyntaxHighlighter = undefined;
var hl_FullWidthSegmented: SyntaxHighlighter = undefined;
var hl_api: SyntaxHighlighter = undefined;

pub fn init() void {
    hl_BasicSegmented = Docs.highlighter(@embedFile("examples/BasicSegmented.zig"));
    hl_FullWidthSegmented = Docs.highlighter(@embedFile("examples/FullWidthSegmented.zig"));
    hl_api = Docs.highlighter(
        \\const Segmented = @import("opaque-ui").Segmented;
        \\
        \\// chosen counts from 0; it must outlive the render.
        \\pub fn render(chosen: *usize, labels: []const []const u8, options: Options) void
    );
    Vapor.Page(.{ .src = @src() }, render, null);
}

const options = [_]Docs.Field{
    .{ .name = "label", .type = "[]const u8", .desc = "Names the group for screen readers." },
    .{ .name = "on_change", .type = "?*const fn (usize) void", .default = "null", .desc = "Called with the option chosen, counted from 0." },
    .{ .name = "full_width", .type = "bool", .default = "false", .desc = "Stretches across its container, the options sharing the width." },
};

const settings = [_]Docs.Field{
    .{ .name = "track_color", .type = "Color", .desc = "The track behind the options." },
    .{ .name = "chosen_color", .type = "Color", .desc = "The chosen option's fill." },
    .{ .name = "muted_color", .type = "Color", .desc = "The other options' text; under the pointer, text_color." },
};

const behaviours = [_]Docs.Field{
    .{ .name = "Keyboard", .desc = "One Tab stop, on the chosen option; the arrow keys move the choice and wrap round, Home and End go to the ends." },
    .{ .name = "Screen readers", .desc = "A radio group named by label, each option a radio that reads checked or not." },
    .{ .name = "Or Tabs?", .desc = "Segmented changes a setting; for a choice that shows another panel, use Tabs." },
};

pub fn render() void {
    Row()
        .width(.percent(100))
        .layout(.top_center)
        .direction(.column)
        .children({
        Hero("segmented-ui", "A row of options, one of them chosen: a view, a period, a mode.");

        Docs.Content().children({
            Docs.exampleLabel("Basic");
            Docs.sectionDesc("Four periods; the arrow keys move the choice.");
            Docs.PreviewCard().layout(.center).children({
                BasicSegmented.render();
            });
            CodeBox(&hl_BasicSegmented, "BasicSegmented");

            Docs.exampleLabel("Full width");
            Docs.sectionDesc("Stretched across its container, with on_change.");
            Docs.PreviewCard().layout(.center).children({
                FullWidthSegmented.render();
            });
            CodeBox(&hl_FullWidthSegmented, "FullWidthSegmented");

            Docs.sectionTitle("API Reference");

            Docs.exampleLabel("Segmented");
            CodeBox(&hl_api, "Segmented");

            Docs.exampleLabel("Options");
            Docs.ApiBox("Options", &options);

            Docs.exampleLabel("Settings");
            Docs.sectionDesc("Segmented globals; set them once.");
            Docs.ApiBox("Segmented", &settings);

            Docs.exampleLabel("Behaviour");
            Docs.sectionDesc("What a segmented control does for you.");
            Docs.ApiBox("Behaviour", &behaviours);
        });
    });
}
