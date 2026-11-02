const Vapor = @import("vapor");
const Text = Vapor.Text;
const Icon = Vapor.Icon;
const Button = @import("opaque-ui").Button;

fn waiting() void {}

// While it waits, it does nothing and says so.
pub fn render() void {
    Button(waiting, .{})
        .a11y(Vapor.Accessibility.init().setDisabled(true).setBusy(true))
        .cursor(.default)
        .background(.palette(.tint))
        .children({
        Icon(.arrow_clockwise)
            .font(14, 500, .palette(.background))
            .end();
        Text("Please wait")
            .fontFamily("Montserrat")
            .font(14, 500, .palette(.background))
            .end();
    });
}
