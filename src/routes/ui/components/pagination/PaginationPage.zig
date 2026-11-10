const Vapor = @import("vapor");
const Hero = @import("../../../../components/Hero.zig").Hero;
const Row = Vapor.Row;
const SyntaxHighlighter = @import("vaporize").SyntaxHighlighter;
const CodeBox = @import("../CodeBox.zig").CodeBox;
const Docs = @import("../Docs.zig");
// Rendered and shown as code: what you read is what runs.
const BasicPagination = @import("examples/BasicPagination.zig");
const RowsPagination = @import("examples/RowsPagination.zig");

var hl_BasicPagination: SyntaxHighlighter = undefined;
var hl_RowsPagination: SyntaxHighlighter = undefined;
var hl_api: SyntaxHighlighter = undefined;

pub fn init() void {
    hl_BasicPagination = Docs.highlighter(@embedFile("examples/BasicPagination.zig"));
    hl_RowsPagination = Docs.highlighter(@embedFile("examples/RowsPagination.zig"));
    hl_api = Docs.highlighter(
        \\const Pagination = @import("opaque-ui").Pagination;
        \\
        \\// page counts from 0; count is how many pages there are.
        \\pub fn render(page: *usize, count: usize, options: Options) void
        \\
        \\// The row it draws, for your own: pages and gaps.
        \\pub fn slots(page: usize, count: usize, siblings: usize, buf: []Slot) []const Slot
    );
    Vapor.Page(.{ .src = @src() }, render, null);
}

const options = [_]Docs.Field{
    .{ .name = "label", .type = "[]const u8", .default = "\"Pagination\"", .desc = "Names the pages for screen readers." },
    .{ .name = "siblings", .type = "usize", .default = "1", .desc = "Pages shown on each side of the current one." },
    .{ .name = "on_change", .type = "?*const fn (usize) void", .default = "null", .desc = "Called with the new page, counted from 0." },
};

const settings = [_]Docs.Field{
    .{ .name = "current_background", .type = "Color", .desc = "The current page's fill; its number is current_text." },
    .{ .name = "hover_background", .type = "Color", .desc = "A page under the pointer." },
    .{ .name = "size", .type = "f32", .default = "32", .desc = "A button's width and height, in pixels; at 32, the row fits a 375px phone." },
};

const behaviours = [_]Docs.Field{
    .{ .name = "Steady width", .desc = "Past 2 x siblings + 5 pages, the row always has that many slots, so it never shifts as you move." },
    .{ .name = "Ends", .desc = "The previous and next arrows are dimmed and marked disabled at the first and last pages." },
    .{ .name = "Screen readers", .desc = "A navigation landmark; each button reads Page 4, and the current one is aria-current=page." },
};

pub fn render() void {
    Row()
        .width(.percent(100))
        .layout(.top_center)
        .direction(.column)
        .children({
        Hero("pagination-ui", "Page numbers for a long list, with previous and next.");

        Docs.Content().children({
            Docs.exampleLabel("Basic");
            Docs.sectionDesc("Twelve pages: the first and last, and those beside the current one.");
            Docs.PreviewCard().layout(.center).children({
                BasicPagination.render();
            });
            CodeBox(&hl_BasicPagination, "BasicPagination");

            Docs.exampleLabel("Fetching a page");
            Docs.sectionDesc("Fifty pages, and on_change where you would fetch the rows.");
            Docs.PreviewCard().layout(.center).children({
                RowsPagination.render();
            });
            CodeBox(&hl_RowsPagination, "RowsPagination");

            Docs.sectionTitle("API Reference");

            Docs.exampleLabel("Pagination");
            CodeBox(&hl_api, "Pagination");

            Docs.exampleLabel("Options");
            Docs.ApiBox("Options", &options);

            Docs.exampleLabel("Settings");
            Docs.sectionDesc("Pagination globals; set them once.");
            Docs.ApiBox("Pagination", &settings);

            Docs.exampleLabel("Behaviour");
            Docs.sectionDesc("What pagination does for you.");
            Docs.ApiBox("Behaviour", &behaviours);
        });
    });
}
