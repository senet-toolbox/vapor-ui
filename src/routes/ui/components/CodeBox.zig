const Vaporize = @import("vaporize");
const SyntaxHighlighter = Vaporize.SyntaxHighlighter;
const Vapor = @import("vapor");
const Row = Vapor.Row;
const Text = Vapor.Text;
const Stack = Vapor.Stack;
const std = @import("std");

/// A code example in a frame, under a tab with its file name. It is as tall
/// as its code: a percentage height would take the parent's, wherever the
/// parent has one.
pub fn CodeBox(code: *SyntaxHighlighter, title: []const u8) void {
    Stack().width(.percent(100))
        .background(.palette(.border_color_light))
        .radius(.all(18))
        .padding(.xy(8, 8))
        .children({
        Stack().width(.percent(100))
            .background(.hex("#111110"))
            .radius(.all(10))
            .padding(.xy(8, 16))
            .children({
            {
                // The file tab; phones go straight to the code.
                Row()
                    .width(.percent(100))
                    .padding(.horizontal(24))
                    .hideOn(.mobile)
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
                            .font(14, 300, .white).end();
                    });
                });
            }
            // The highlighter scrolls long lines itself, inside this box,
            // instead of widening the page.
            Stack().width(.percent(100))
                .height(.expand)
                .border(.round(.hex("#383735"), .all(6)))
                .background(.hex("#282828"))
                .children({
                code.render() catch unreachable;
            });
        });
    });
}
