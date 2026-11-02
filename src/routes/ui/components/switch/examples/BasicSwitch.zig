const Vapor = @import("vapor");
const Row = Vapor.Row;
const Text = Vapor.Text;
const Switch = @import("opaque-ui").Switch;

var airplane = false;

fn toggle() void {
    airplane = !airplane;
}

// The switch keeps its own on/off; your callback hears each flip.
pub fn render() void {
    Row().layout(.left_center).spacing(12).children({
        // The label names it for screen readers.
        Switch.render("Airplane mode", toggle, .{});
        Text(if (airplane) "Airplane mode: on" else "Airplane mode: off")
            .font(14, 400, .palette(.text_color))
            .end();
    });
}
