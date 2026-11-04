const Vapor = @import("vapor");
const Hero = @import("../../../../components/Hero.zig").Hero;
const Row = Vapor.Row;
const SyntaxHighlighter = @import("vaporize").SyntaxHighlighter;
const CodeBox = @import("../CodeBox.zig").CodeBox;
const Docs = @import("../Docs.zig");
// Rendered and shown as code: what you read is what runs.
const BasicAvatar = @import("examples/BasicAvatar.zig");
const AvatarGroup = @import("examples/AvatarGroup.zig");

var hl_basic: SyntaxHighlighter = undefined;
var hl_group: SyntaxHighlighter = undefined;
var hl_api: SyntaxHighlighter = undefined;

pub fn init() void {
    hl_basic = Docs.highlighter(@embedFile("examples/BasicAvatar.zig"));
    hl_group = Docs.highlighter(@embedFile("examples/AvatarGroup.zig"));
    hl_api = Docs.highlighter(
        \\const Avatar = @import("opaque-ui").Avatar;
        \\
        \\pub fn render(options: Options) void
        \\// Overlapping avatars, up to max, then "+N" for the rest.
        \\pub fn group(avatars: []const Options, max: usize) void
        \\
        \\// What render uses, for your own drawing.
        \\pub fn initials(name: []const u8, buf: *[8]u8) []const u8
        \\pub fn colorFor(name: []const u8) Color
    );
    Vapor.Page(.{ .src = @src() }, render, null);
}

const options = [_]Docs.Field{
    .{ .name = "name", .type = "[]const u8", .desc = "Who it is: what screen readers hear, and the initials when there's no photo." },
    .{ .name = "src", .type = "?[]const u8", .default = "null", .desc = "The photo's URL. It's drawn over the initials, so one that fails to load leaves them showing." },
    .{ .name = "size", .type = "f32", .default = "40", .desc = "Its width and height, in pixels. The initials and the dot scale with it." },
    .{ .name = "shape", .type = "Shape", .default = ".circle", .desc = ".circle, or .rounded for a square with soft corners." },
    .{ .name = "status", .type = "?Status", .default = "null", .desc = "A dot at the corner: .online, .away, .busy or .offline." },
    .{ .name = "background", .type = "?Color", .default = "null", .desc = "Behind the initials. Unset, a colour picked from the name, the same every time." },
};

const behaviours = [_]Docs.Field{
    .{ .name = "Initials", .desc = "The first letters of the first and last words of the name: Sarah Chen is SC." },
    .{ .name = "Colour", .desc = "Picked from the name out of Avatar.colors, mid tones that white text reads on." },
    .{ .name = "Groups", .desc = "Each avatar overlaps the last by a quarter, parted by a ring in the page colour." },
    .{ .name = "Screen readers", .desc = "Each is an image named by name, with its status after it: Emily Davis (online). A group is named by its count, and +N reads as N more." },
};

pub fn render() void {
    Row()
        .width(.percent(100))
        .layout(.top_center)
        .direction(.column)
        .children({
        Hero("avatar-ui", "A person's photo, or their initials when there's none; alone, or in a stacked group.");

        Docs.Content().children({
            Docs.exampleLabel("Avatars");
            Docs.sectionDesc("A photo, initials, a photo that won't load, status dots, a rounded square and sizes.");
            Docs.PreviewCard().layout(.center).children({
                BasicAvatar.render();
            });
            CodeBox(&hl_basic, "BasicAvatar");

            Docs.exampleLabel("Group");
            Docs.sectionDesc("A row that overlaps, with a count for those it leaves out.");
            Docs.PreviewCard().layout(.center).children({
                AvatarGroup.render();
            });
            CodeBox(&hl_group, "AvatarGroup");

            Docs.sectionTitle("API Reference");

            Docs.exampleLabel("Avatar");
            CodeBox(&hl_api, "Avatar");

            Docs.exampleLabel("Options");
            Docs.ApiBox("Options", &options);

            Docs.exampleLabel("Behaviour");
            Docs.sectionDesc("What the avatar does for you.");
            Docs.ApiBox("Behaviour", &behaviours);
        });
    });
}
