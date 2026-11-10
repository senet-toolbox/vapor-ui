const Vapor = @import("vapor");
const Stack = Vapor.Stack;
const CodeInput = @import("opaque-ui").CodeInput;

var invite: []const u8 = "";

pub fn render() void {
    Stack().layout(.center).spacing(16).children({
        CodeInput.render(&invite, .{ .label = "Invite code", .length = 4, .numeric = false });
        Vapor.TextFmt("{d} of 4", .{invite.len})
            .font(14, 400, .transparentize(.palette(.text_color), 0.6))
            .end();
    });
}
