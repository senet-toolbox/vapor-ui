const Vapor = @import("vapor");
const Stack = Vapor.Stack;
const TextFmt = Vapor.TextFmt;
const Slider = @import("opaque-ui").Slider;

var volume: f32 = 40;

fn setVolume(value: f32) void {
    volume = value;
}

pub fn render() void {
    Stack().width(.percent(100)).spacing(16).children({
        Slider.render(.{ .label = "Volume", .value = 40, .step = 5, .on_change = setVolume });
        TextFmt("Volume: {d}", .{volume})
            .font(14, 300, .palette(.text_color))
            .end();
    });
}
