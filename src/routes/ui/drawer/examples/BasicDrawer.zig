const std = @import("std");
const Vapor = @import("vapor");
const Text = Vapor.Text;
const TextFmt = Vapor.TextFmt;
const Row = Vapor.Row;
const Stack = Vapor.Stack;
const Opaque = @import("opaque-ui");
const Drawer = Opaque.Sheet;
const Vaporize = @import("vaporize");
const SyntaxHighlighter = Vaporize.SyntaxHighlighter;
const Icon = Vapor.Icon;
const Button = Opaque.Button;

var bottom_drawer: Drawer = undefined;
var right_drawer: Drawer = undefined;
var left_drawer: Drawer = undefined;
var top_drawer: Drawer = undefined;

var hl_basic: SyntaxHighlighter = undefined;

pub fn init() void {
    bottom_drawer = .init(.bottom);
    bottom_drawer.content = renderBasicContent;
}

fn renderBasicContent(_: *Drawer) void {
    Stack()
        .width(.percent(100))
        .padding(.all(24))
        .children({
        Text("Simple Drawer Content")
            .font(18, 600, .black)
            .end();
        Text("This is a basic placeholder for drawer content.")
            .font(14, 400, .gray)
            .end();
    });
}

fn render() void {
    Button(Drawer.open, .{&bottom_drawer})
        .ariaLabel("open drawer")
        .padding(.xy(12, 8))
        .background(.palette(.tint))
        .layout(.center)
        .children({
        Text("Open Drawer").font(14, 300, .palette(.background)).fontFamily("Montserrat").end();
        Icon(.arrow_right).font(16, 500, .palette(.background)).end();
    });
    bottom_drawer.render();
}
