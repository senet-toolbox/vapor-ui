const Vapor = @import("vapor");
const Row = Vapor.Row;
const Text = Vapor.Text;
const Checkbox = @import("opaque-ui").Checkbox;

var subscribed = false;

fn toggle() void {
    subscribed = !subscribed;
}

// The checkbox keeps its own checked state; your callback hears each click.
pub fn render() void {
    Row().layout(.left_center).spacing(12).children({
        // The label names it for screen readers.
        Checkbox.render("Email me updates", toggle, .{});
        Text(if (subscribed) "Emails: on" else "Emails: off")
            .font(14, 400, .palette(.text_color))
            .end();
    });
}
