const Vapor = @import("vapor");
const Text = Vapor.Text;
const Row = Vapor.Row;
const Stack = Vapor.Stack;
const Opaque = @import("opaque-ui");
const Alert = Opaque.Alert;
const Icon = Vapor.Icon;
const Button = Opaque.Button;

var alert: Alert = undefined;
var answer: []const u8 = "none yet";

pub fn init() void {
    // Initialize Alert with the content callback
    alert = .init(alertContent);
    // Names it for screen readers.
    alert.label = "Delete account";
    // Escape, or a click outside.
    alert.on_close = onDismiss;
}

fn onDismiss() void {
    answer = "dismissed";
}

fn cancel() void {
    answer = "cancelled";
    alert.close();
}

fn proceed() void {
    answer = "continued";
    alert.close();
}

pub fn render() void {
    Button(Alert.open, .{&alert})
        // Focus comes back here when the alert closes.
        .ref(&alert.trigger)
        .ariaLabel("open alert")
        .padding(.xy(12, 8))
        .background(.palette(.tint))
        .layout(.center)
        .children({
        Text("Trigger Confirmation").font(14, 300, .palette(.background)).fontFamily("Montserrat").end();
        Icon(.arrow_right).font(16, 500, .palette(.background)).end();
    });
    Text(Vapor.fmtln("Answer: {s}", .{answer}))
        .font(14, 300, .palette(.text_color))
        .end();
    alert.render();
}

fn alertContent(_: *Alert) void {
    Stack()
        .width(.percent(100))
        .spacing(8)
        .children({
        Text("Delete your account?")
            .font(18, 600, .palette(.text_color))
            .fontFamily("Montserrat")
            .end();

        Text("This can't be undone. Your account and everything in it will be deleted from our servers.")
            .font(14, 400, .hex("#71717a"))
            .fontFamily("Montserrat")
            .inlineStyle("line-height: 1.5;", .{})
            .end();
    });

    Row()
        .width(.percent(100))
        .margin(.{ .top = 24 })
        .spacing(8)
        .layout(.right_center)
        .children({
        Button(cancel, .{})
            .cursor(.pointer)
            .padding(.xy(16, 9))
            .background(.transparent)
            .border(.round(.palette(.border_color_light), .all(8)))
            .hoverBackground(.palette(.highlight_color))
            .children({
            Text("Cancel").fontFamily("Montserrat").font(14, 500, .palette(.text_color)).end();
        });

        // The destructive action, in the warning colour.
        Button(proceed, .{})
            .cursor(.pointer)
            .padding(.xy(16, 9))
            .background(.hex("#dc2626"))
            .border(.round(.hex("#dc2626"), .all(8)))
            .hoverBackground(.hex("#b91c1c"))
            .children({
            Text("Delete account").fontFamily("Montserrat").font(14, 500, .white).end();
        });
    });
}
