//! The banner at the top of a showcase page: a small label, the page's name
//! and a line on what it shows. Shorter, with a smaller title, on phones.

const Vapor = @import("vapor");
const Text = Vapor.Text;
const TextFmt = Vapor.TextFmt;
const Stack = Vapor.Stack;

pub fn Hero(name: []const u8, description: []const u8) void {
    Stack()
        .layout(.center)
        .height(.px(512))
        .width(.percent(100))
        .padding(.horizontal(16))
        .responsive(.mobile, .{ .size = .h(.px(240)) })
        .children({
        TextFmt("{s} ⇒", .{name}).style(&.{
            .visual = .font(12, 500, .hex("#6f6f6f")),
            .font_family = "IBM Plex Mono,monospace",
        }).end();
        Text(name)
            .font(72, 700, .palette(.text_color))
            .responsive(.mobile, .{ .visual = .{ .font_size = 40 } })
            .end();
        Text(description)
            .font(16, 300, .palette(.text_color))
            .responsive(.mobile, .{ .visual = .{ .font_size = 14 } })
            .end();
    });
}
