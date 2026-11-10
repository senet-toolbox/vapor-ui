const Vapor = @import("vapor");
const Stack = Vapor.Stack;
const Text = Vapor.Text;
const CodeInput = @import("opaque-ui").CodeInput;

var code: []const u8 = "";
var verified = false;

fn verify(entered: []const u8) void {
    // Where you would send it to your server.
    verified = entered.len == 6;
}

pub fn render() void {
    Stack().layout(.center).spacing(16).children({
        CodeInput.render(&code, .{ .label = "Verification code", .on_complete = verify });
        Text(if (verified and code.len == 6) "Code entered" else "Enter the 6-digit code we sent you")
            .font(14, 400, .transparentize(.palette(.text_color), 0.6))
            .end();
    });
}
