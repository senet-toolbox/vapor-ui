const Vaporize = @import("vaporize");
const SyntaxHighlighter = Vaporize.SyntaxHighlighter;
const Vapor = @import("vapor");
const Row = Vapor.Row;
const Text = Vapor.Text;
const Center = Vapor.Center;
const Stack = Vapor.Stack;
const std = @import("std");

pub fn CodeBox(code: *SyntaxHighlighter, title: []const u8) void {
    Stack().width(.percent(100))
        .height(.percent(100))
        .background(.palette(.border_color_light))
        .radius(.all(18))
        .padding(.xy(8, 8))
        .children({
        Stack().width(.percent(100))
            .height(.percent(100))
            .background(.hex("#111110"))
            .radius(.all(10))
            .padding(.xy(8, 16))
            .children({
            if (Vapor.isDesktop()) {
                Row()
                    .width(.percent(100))
                    .height(.percent(6))
                    .padding(.horizontal(24))
                    .children({
                    Row()
                        .padding(.all(8))
                        .width(.fit)
                        .layout(.center)
                        .height(.percent(100))
                        .border(.bottom(1, .white))
                        .children({
                        Text(title)
                            .fontStyle(.italic)
                            .fontFamily("Geist Mono, monospace")
                            .font(14, 300, .white).end();
                    });
                });
            }
            Center().width(.percent(100))
                .height(.expand)
                .scroll(.scroll_y())
                .border(.round(.hex("#383735"), .all(6)))
                .background(.hex("#282828"))
                .children({
                code.render() catch unreachable;
            });
        });
    });
}
