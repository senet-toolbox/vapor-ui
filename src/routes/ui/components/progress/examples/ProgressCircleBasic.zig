const Vapor = @import("vapor");
const ProgressCircle = @import("opaque-ui").ProgressCircle;

var circle: ProgressCircle = undefined;

pub fn init() void {
    circle = ProgressCircle.init(Vapor.arena(.persist), .{
        .id = "storage",
        .size = 120,
        .stroke_width = 10,
        .track_color = .palette(.highlight_color),
        .color = .palette(.text_color),
        .clockwise = false,
        .show_label = false,
    });
    circle.setProgress(0.75);
}

pub fn render() void {
    circle.render();
}
