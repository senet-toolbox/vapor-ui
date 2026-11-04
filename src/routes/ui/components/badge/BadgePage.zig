const Vapor = @import("vapor");
const Hero = @import("../../../../components/Hero.zig").Hero;
const Row = Vapor.Row;
const SyntaxHighlighter = @import("vaporize").SyntaxHighlighter;
const CodeBox = @import("../CodeBox.zig").CodeBox;
const Docs = @import("../Docs.zig");
// Rendered and shown as code: what you read is what runs.
const BasicBadge = @import("examples/BasicBadge.zig");
const BadgeCount = @import("examples/BadgeCount.zig");

var hl_basic: SyntaxHighlighter = undefined;
var hl_count: SyntaxHighlighter = undefined;
var hl_api: SyntaxHighlighter = undefined;

pub fn init() void {
    hl_basic = Docs.highlighter(@embedFile("examples/BasicBadge.zig"));
    hl_count = Docs.highlighter(@embedFile("examples/BadgeCount.zig"));
    hl_api = Docs.highlighter(
        \\const Badge = @import("opaque-ui").Badge;
        \\
        \\pub fn render(options: Options) void
        \\// A number: "99+" past Badge.max_count. what says what it counts.
        \\pub fn count(n: usize, what: []const u8) void
    );
    Vapor.Page(.{ .src = @src() }, render, null);
}

const options = [_]Docs.Field{
    .{ .name = "text", .type = "[]const u8", .desc = "What it says. It stays on one line." },
    .{ .name = "tone", .type = "Tone", .default = ".neutral", .desc = ".neutral, .tint, .success, .warning, .danger, or .outline for a border and no fill." },
    .{ .name = "icon", .type = "?IconTokens", .default = "null", .desc = "Drawn before the text, in the tone's colour." },
    .{ .name = "dot", .type = "bool", .default = "false", .desc = "A dot before the text, in the tone's colour." },
};

const settings = [_]Docs.Field{
    .{ .name = "success_color", .type = "Color", .default = ".hex(\"#16a34a\")", .desc = "The .success tone; likewise warning_color and danger_color." },
    .{ .name = "max_count", .type = "usize", .default = "99", .desc = "The largest count shown in full." },
};

const behaviours = [_]Docs.Field{
    .{ .name = "Tones", .desc = "Each is its colour on a faint wash of it, readable in light and dark." },
    .{ .name = "Counts", .desc = "A tinted pill at least as wide as it is tall; past max_count it reads 99+." },
    .{ .name = "Screen readers", .desc = "A badge is its text. A count is a status named in full, 150 alerts, not 99+." },
};

pub fn render() void {
    Row()
        .width(.percent(100))
        .layout(.top_center)
        .direction(.column)
        .children({
        Hero("badge-ui", "Small labels for a status, a tag or a count.");

        Docs.Content().children({
            Docs.exampleLabel("Tones");
            Docs.sectionDesc("Neutral, tint, success, warning, danger and outline, with a dot or an icon.");
            Docs.PreviewCard().layout(.center).children({
                BasicBadge.render();
            });
            CodeBox(&hl_basic, "BasicBadge");

            Docs.exampleLabel("Counts");
            Docs.sectionDesc("A number beside what it counts; large ones are cut to 99+.");
            Docs.PreviewCard().layout(.center).children({
                BadgeCount.render();
            });
            CodeBox(&hl_count, "BadgeCount");

            Docs.sectionTitle("API Reference");

            Docs.exampleLabel("Badge");
            CodeBox(&hl_api, "Badge");

            Docs.exampleLabel("Options");
            Docs.ApiBox("Options", &options);

            Docs.exampleLabel("Settings");
            Docs.sectionDesc("Badge globals; set them once.");
            Docs.ApiBox("Badge", &settings);

            Docs.exampleLabel("Behaviour");
            Docs.sectionDesc("What badges do for you.");
            Docs.ApiBox("Behaviour", &behaviours);
        });
    });
}
