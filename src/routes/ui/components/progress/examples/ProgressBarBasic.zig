const Vapor = @import("vapor");
const ProgressBar = @import("opaque-ui").ProgressBar;

var bar: ProgressBar = undefined;

// In your init: make it once, with its size and colours.
pub fn init() void {
    bar = ProgressBar.init(Vapor.arena(.persist), .{
        .id = "upload", // names its elements; any unique word
        .width = 128,
        .height = 6,
        .color = .palette(.tint),
        .track_color = .transparentize(.palette(.text_color), 0.1),
    });
    bar.setProgress(0.34);
}

pub fn render() void {
    bar.render();
}
