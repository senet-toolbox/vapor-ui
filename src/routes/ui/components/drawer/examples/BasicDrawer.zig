const Vapor = @import("vapor");
const Text = Vapor.Text;
const Stack = Vapor.Stack;
const Icon = Vapor.Icon;
const Opaque = @import("opaque-ui");
const Drawer = Opaque.Sheet;
const Button = Opaque.Button;

var drawer: Drawer = undefined;

pub fn init() void {
    drawer = .init(.bottom);
    drawer.label = "Example drawer";
    drawer.content = content;
}

fn content(_: *Drawer) void {
    Stack()
        .width(.percent(100))
        .padding(.all(24))
        .children({
        Text("Simple Drawer Content")
            .font(18, 600, .palette(.text_color))
            .end();
        Text("This is a basic placeholder for drawer content.")
            .font(14, 400, .hex("#71717a"))
            .end();
    });
}

pub fn render() void {
    Button(Drawer.open, .{&drawer})
        .padding(.xy(16, 10))
        .background(.palette(.tint))
        .layout(.center)
        .spacing(8)
        .children({
        Text("Open Bottom").font(14, 500, .palette(.background)).end();
        Icon(.arrow_right).font(16, 500, .palette(.background)).end();
    });
    drawer.render();
}
