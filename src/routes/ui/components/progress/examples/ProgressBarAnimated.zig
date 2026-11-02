const Vapor = @import("vapor");
const Text = Vapor.Text;
const Opaque = @import("opaque-ui");
const ProgressBar = Opaque.ProgressBar;
const Button = Opaque.Button;

var bar: ProgressBar = undefined;

pub fn init() void {
    bar = ProgressBar.init(Vapor.arena(.persist), .{
        .id = "download",
        .width = 256,
        .height = 16,
        .color = .palette(.danger),
        .track_color = .transparentize(.palette(.text_color), 0.1),
        .show_label = true,
        .label_position = .above,
        .label_color = .palette(.text_color),
    });
}

// Every 60ms, a step closer; at 100% it stops.
fn step() void {
    if (bar.progress >= 1) {
        Vapor.lib.cancelTimeout("download-progress");
        return;
    }
    bar.updateProgress(bar.progress + 0.01);
}

fn start() void {
    // Run it again from the start once it has finished.
    if (bar.progress >= 1) bar.updateProgress(0);
    Vapor.lib.loopInterval("download-progress", 60, step, .{});
}

pub fn render() void {
    Button(start, .{})
        .border(.round(.palette(.border_color_light), .all(4)))
        .padding(.xy(12, 8))
        .background(.palette(.background))
        .children({
        Text("Start Animation")
            .font(14, 300, .palette(.text_color))
            .end();
    });
    bar.render();
}
