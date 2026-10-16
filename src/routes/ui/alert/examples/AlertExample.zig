const Vapor = @import("vapor");
const Text = Vapor.Text;
const Row = Vapor.Row;
const Stack = Vapor.Stack;
const Opaque = @import("opaque-ui");
const Alert = Opaque.Alert;
const Icon = Vapor.Icon;
const Button = Opaque.Button;

var alert: Alert = undefined;

pub fn init() void {
    // Initialize Alert with the content callback
    alert = .init(alertContent);
}

pub fn render() void {
    Button(Alert.open, .{&alert})
        .ariaLabel("open alert")
        .padding(.xy(12, 8))
        .background(.palette(.tint))
        .layout(.center)
        .children({
        Text("Trigger Confirmation").font(14, 300, .palette(.background)).fontFamily("Montserrat").end();
        Icon(.arrow_right).font(16, 500, .palette(.background)).end();
    });
    alert.render();
}

fn alertContent(_: *Alert) void {
    Row()
        .width(.percent(100))
        .spacing(16)
        .direction(.column)
        .children({
        Text("Are you sure?")
            .font(22, 700, .palette(.text_color))
            .fontFamily("Montserrat")
            .end();

        Text("This action cannot be undone. This will permanently delete your account and remove your data from our servers.")
            .font(14, 300, .palette(.text_color))
            .fontFamily("Montserrat")
            .end();

        Row()
            .width(.percent(100))
            .spacing(12)
            .layout(.right_center)
            .children({
            // Cancel Button
            Button(Alert.close, .{&alert})
                .cursor(.pointer)
                .padding(.xy(20, 10))
                .background(.palette(.text_color))
                .border(.round(.palette(.text_color), .all(8)))
                .hoverScale()
                .children({
                Text("Cancel").fontFamily("Montserrat").font(14, 600, .palette(.background)).end();
            });

            // Action Button
            Button(Alert.close, .{&alert})
                .cursor(.pointer)
                .padding(.xy(20, 10))
                .border(.round(.palette(.text_color), .all(8)))
                .hoverScale()
                .children({
                Text("Continue").fontFamily("Montserrat").font(14, 600, .palette(.text_color)).end();
            });
        });
    });
}
