const Vapor = @import("vapor");
const Stack = Vapor.Stack;
const TextFmt = Vapor.TextFmt;
const Radio = @import("opaque-ui").Radio;

var density: []const u8 = "default";

fn onDensity(value: []const u8) void {
    density = value;
}

pub fn render() void {
    Stack().spacing(16).children({
        Radio.Group("Density", "default", onDensity, .{}).children({
            Radio.Item("default", "Default");
            Radio.Item("comfortable", "Comfortable");
            Radio.Item("compact", "Compact");
        });
        TextFmt("Density: {s}", .{density})
            .font(14, 300, .palette(.text_color))
            .end();
    });
}
