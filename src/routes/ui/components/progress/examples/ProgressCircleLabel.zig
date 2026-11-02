const Vapor = @import("vapor");
const Text = Vapor.Text;
const Opaque = @import("opaque-ui");
const ProgressCircle = Opaque.ProgressCircle;
const Button = Opaque.Button;

var circle: ProgressCircle = undefined;

pub fn init() void {
    circle = ProgressCircle.init(Vapor.arena(.persist), .{
        .id = "goal",
        .size = 120,
        .stroke_width = 10,
        .track_color = .palette(.highlight_color),
        .color = .palette(.text_color),
        .show_label = true, // the percentage, in the middle
        .label_font_size = 12,
        .label_color = .palette(.text_color),
    });
    circle.setProgress(0.9);
}

// updateProgress moves the ring and its label, without a rerender.
fn toggle() void {
    circle.updateProgress(if (circle.progress != 0.3) 0.3 else 0.8);
}

pub fn render() void {
    Vapor.Row().layout(.center).spacing(16).children({
        Button(toggle, .{})
            .padding(.xy(12, 8))
            .background(.palette(.tint))
            .children({
            Text("Toggle Progress")
                .font(14, 300, .palette(.background))
                .end();
        });
        circle.render();
    });
}
