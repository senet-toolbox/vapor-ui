//! The pieces a component page is made of, in the site's one style: section
//! titles and descriptions, preview cards, and ApiBox, the API reference's
//! counterpart to CodeBox, framed the same way.

const Vapor = @import("vapor");
const SyntaxHighlighter = @import("vaporize").SyntaxHighlighter;
const Row = Vapor.Row;
const Stack = Vapor.Stack;
const Text = Vapor.Text;

const muted = Vapor.Types.Color.hex("#71717a");

// CodeBox's colours and fonts, so an ApiBox sits beside one as a pair.
const frame_panel = Vapor.Types.Color.hex("#111110");
const well = Vapor.Types.Color.hex("#282828");
const well_line = Vapor.Types.Color.hex("#383735");
const code_font = "DM Mono, monospace";
const name_color = Vapor.Types.Color.hex("#EAEAEA");
const type_color = Vapor.Types.Color.hex("#82AAFF"); // the highlighter's keyword colour
const default_color = Vapor.Types.Color.hex("#8A8A8A");
const desc_color = Vapor.Types.Color.hex("#B4B4B4");

/// A highlighter for a CodeBox, parsed once, kept for the page's life.
pub fn highlighter(source: []const u8) SyntaxHighlighter {
    var hl = SyntaxHighlighter.init(Vapor.arena(.persist));
    hl.show_toolbar = true;
    hl.parse(source) catch unreachable;
    return hl;
}

/// The page's column, below the hero.
pub fn Content() Vapor.Builder(.pure) {
    return Stack()
        .width(.percent(50))
        .responsive(.mobile, .{ .size = .w(.percent(92)) })
        .spacing(12)
        // The links to the next and previous pages follow, then the foot.
        .padding(.{ .bottom = 64 });
}

pub fn sectionTitle(title: []const u8) void {
    Text(title)
        .font(24, 600, .palette(.text_color))
        .fontFamily("IBM Plex Mono,monospace")
        .margin(.{ .top = 48 })
        .end();
}

pub fn sectionDesc(desc: []const u8) void {
    Text(desc)
        .font(14, 400, muted)
        .fontFamily("IBM Plex Mono,monospace")
        .margin(.{ .bottom = 16 })
        .end();
}

pub fn exampleLabel(label: []const u8) void {
    Text(label)
        .font(14, 500, muted)
        .fontFamily("IBM Plex Mono,monospace")
        .margin(.{ .top = 24 })
        .end();
}

pub fn PreviewCard() Vapor.Builder(.pure) {
    return Stack()
        .background(.transparentize(.palette(.background), 0.5))
        .border(.round(.palette(.border_color_light), .all(12)))
        .width(.percent(100))
        .padding(.all(24))
        .direction(.column)
        .spacing(16);
}

/// One entry of an ApiBox: a field, an option or a behaviour.
pub const Field = struct {
    name: []const u8,
    /// Its Zig type; none for a behaviour.
    type: ?[]const u8 = null,
    /// Its default value, as written in code.
    default: ?[]const u8 = null,
    desc: []const u8,
};

/// A type's fields (or a component's behaviours), framed like a CodeBox:
/// the same frame, file tab and code well, with one row per field. Rows
/// wrap rather than scroll, so a phone shows them whole.
pub fn ApiBox(title: []const u8, fields: []const Field) void {
    Stack()
        .width(.percent(100))
        .background(.palette(.border_color_light))
        .radius(.all(18))
        .padding(.xy(8, 8))
        .children({
        Stack()
            .width(.percent(100))
            .background(frame_panel)
            .radius(.all(10))
            .padding(.xy(8, 16))
            .children({
            // The tab, as on a CodeBox; kept on phones, where it names the type.
            Row()
                .width(.percent(100))
                .padding(.horizontal(24))
                .responsive(.mobile, .{ .padding = .horizontal(8) })
                .children({
                Row()
                    .padding(.all(8))
                    .width(.fit)
                    .layout(.center)
                    .border(.bottom(1, .white))
                    .children({
                    Text(title)
                        .fontStyle(.italic)
                        .fontFamily("Geist Mono, monospace")
                        .font(14, 300, .white)
                        .end();
                });
            });
            Stack()
                .width(.percent(100))
                .border(.round(well_line, .all(6)))
                .background(well)
                .children({
                for (fields, 0..) |field, i| {
                    Stack()
                        .width(.percent(100))
                        .padding(.xy(16, 14))
                        .spacing(6)
                        .border(if (i + 1 < fields.len) .bottom(1, well_line) else .bottom(0, well_line))
                        .children({
                        Row()
                            .width(.percent(100))
                            .layout(.left_center)
                            .wrap(.wrap)
                            .spacing(8)
                            .children({
                            Text(field.name)
                                .fontFamily(code_font)
                                .font(13, 500, name_color)
                                .end();
                            if (field.type) |t| {
                                Text(t)
                                    .fontFamily(code_font)
                                    .font(13, 400, type_color)
                                    .end();
                            }
                            if (field.default) |d| {
                                Text(Vapor.fmtln("= {s}", .{d}))
                                    .fontFamily(code_font)
                                    .font(13, 400, default_color)
                                    .end();
                            }
                        });
                        Text(field.desc)
                            .fontFamily("IBM Plex Mono,monospace")
                            .font(13, 400, desc_color)
                            .end();
                    });
                }
            });
        });
    });
}
