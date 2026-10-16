const Vapor = @import("vapor");
const Row = Vapor.Row;
const Text = Vapor.Text;

pub fn render() void {
    Row()
        .width(.percent(100))
        .height(.percent(100))
        .direction(.column)
        .layout(.top_center)
        .children({
        Text("Profile").font(72, 700, .palette(.text_color)).end();
    });
}
