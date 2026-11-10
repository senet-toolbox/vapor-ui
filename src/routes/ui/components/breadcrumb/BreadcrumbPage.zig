const Vapor = @import("vapor");
const Hero = @import("../../../../components/Hero.zig").Hero;
const Row = Vapor.Row;
const SyntaxHighlighter = @import("vaporize").SyntaxHighlighter;
const CodeBox = @import("../CodeBox.zig").CodeBox;
const Docs = @import("../Docs.zig");
// Rendered and shown as code: what you read is what runs.
const BasicBreadcrumb = @import("examples/BasicBreadcrumb.zig");
const IconBreadcrumb = @import("examples/IconBreadcrumb.zig");

var hl_BasicBreadcrumb: SyntaxHighlighter = undefined;
var hl_IconBreadcrumb: SyntaxHighlighter = undefined;
var hl_api: SyntaxHighlighter = undefined;

pub fn init() void {
    hl_BasicBreadcrumb = Docs.highlighter(@embedFile("examples/BasicBreadcrumb.zig"));
    hl_IconBreadcrumb = Docs.highlighter(@embedFile("examples/IconBreadcrumb.zig"));
    hl_api = Docs.highlighter(
        \\const Breadcrumb = @import("opaque-ui").Breadcrumb;
        \\
        \\pub fn render(crumbs: []const Crumb, options: Options) void
    );
    Vapor.Page(.{ .src = @src() }, render, null);
}

const crumb = [_]Docs.Field{
    .{ .name = "label", .type = "[]const u8", .desc = "What the crumb reads." },
    .{ .name = "url", .type = "?[]const u8", .default = "null", .desc = "Where it goes. The last crumb, the page you are on, needs none." },
    .{ .name = "icon", .type = "?IconTokens", .default = "null", .desc = "Drawn before the label." },
};

const options = [_]Docs.Field{
    .{ .name = "label", .type = "[]const u8", .default = "\"Breadcrumb\"", .desc = "Names the trail for screen readers." },
    .{ .name = "separator", .type = "Separator", .default = ".chevron", .desc = ".chevron or .slash, between crumbs." },
};

const settings = [_]Docs.Field{
    .{ .name = "muted_color", .type = "Color", .desc = "The links and separators." },
    .{ .name = "current_color", .type = "Color", .desc = "The page you are on, and a link under the pointer." },
    .{ .name = "font_size", .type = "u8", .default = "14", .desc = "In pixels." },
};

const behaviours = [_]Docs.Field{
    .{ .name = "Current page", .desc = "The last crumb is text, not a link, marked aria-current=page." },
    .{ .name = "Screen readers", .desc = "A navigation landmark named by label; the separators are hidden from them." },
    .{ .name = "Narrow screens", .desc = "A trail too long for its row wraps onto the next." },
};

pub fn render() void {
    Row()
        .width(.percent(100))
        .layout(.top_center)
        .direction(.column)
        .children({
        Hero("breadcrumb-ui", "Where a page sits: a link to each page above it, then the page itself.");

        Docs.Content().children({
            Docs.exampleLabel("Basic");
            Docs.sectionDesc("The pages above this one, then this one.");
            Docs.PreviewCard().layout(.center).children({
                BasicBreadcrumb.render();
            });
            CodeBox(&hl_BasicBreadcrumb, "BasicBreadcrumb");

            Docs.exampleLabel("Icons and slashes");
            Docs.sectionDesc("An icon before a label, a slash between crumbs; a long trail wraps.");
            Docs.PreviewCard().layout(.center).children({
                IconBreadcrumb.render();
            });
            CodeBox(&hl_IconBreadcrumb, "IconBreadcrumb");

            Docs.sectionTitle("API Reference");

            Docs.exampleLabel("Breadcrumb");
            CodeBox(&hl_api, "Breadcrumb");

            Docs.exampleLabel("Crumb");
            Docs.ApiBox("Crumb", &crumb);

            Docs.exampleLabel("Options");
            Docs.ApiBox("Options", &options);

            Docs.exampleLabel("Settings");
            Docs.sectionDesc("Breadcrumb globals; set them once.");
            Docs.ApiBox("Breadcrumb", &settings);

            Docs.exampleLabel("Behaviour");
            Docs.sectionDesc("What breadcrumb does for you.");
            Docs.ApiBox("Behaviour", &behaviours);
        });
    });
}
