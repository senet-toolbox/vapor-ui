const Vapor = @import("vapor");
const Checkbox = @import("opaque-ui").Checkbox;

var sound = false;

// create's callback gets the new state after your args.
fn toggle(on: bool) void {
    sound = on;
}

// Your own look: create returns the button, for you to style and fill.
pub fn render() void {
    Checkbox.create("sound-checkbox", toggle, .{})
        .ariaLabel("Sound")
        .background(if (sound) .palette(.danger) else .palette(.background))
        .children({
        Vapor.Icon(.soundwave)
            .font(16, 300, if (sound) .white else .palette(.text_color))
            .end();
    });
}
