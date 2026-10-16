const Vapor = @import("vapor");
const Row = Vapor.Row;
const Stack = Vapor.Stack;
const Text = Vapor.Text;
const Icon = Vapor.Icon;
const Accordion = @import("opaque-ui").Accordion;

var items = [_]Accordion.AccordionItem{
    .{
        .title = "Security Settings",
        .description = "Manage your two-factor authentication and password recovery options.",
        .trigger = CustomTrigger,
        .content = CustomContentAccount,
    },
    .{
        .title = "Notification Preferences",
        .description = "Choose which alerts you want to receive via email and push notifications.",
        .trigger = CustomTrigger,
        .content = CustomContentEmail,
    },
};

pub fn render() void {
    var custom_accordion = Accordion.init(&items);
    custom_accordion.render();
}

fn CustomTrigger(item: *Accordion.AccordionItem) void {
    Stack()
        .direction(.row)
        .spacing(12)
        .layout(.left_center)
        .children({
        // Dynamic Icon based on title
        Icon(.settings)
            .font(18, 300, .palette(.tint))
            .end();

        Text(item.title)
            .fontFamily("Montserrat")
            .font(16, 600, .palette(.text_color))
            .end();
    });
}

fn CustomContentAccount(item: *Accordion.AccordionItem) void {
    Stack()
        .width(.percent(100))
        .spacing(16)
        .children({
        Text("Configure your account settings.")
            .font(16, 300, .palette(.text_color))
            .end();
        Text(item.description)
            .font(16, 400, .palette(.text_color))
            .end();
        Button(Vapor.alert, .{ "{s}", .{"Opening Settings..."} })
            .padding(.xy(12, 8))
            .ariaLabel("Alert Opening Settings")
            .background(.palette(.tint))
            .children({
            Text("Open Account Settings")
                .font(14, 300, .palette(.background))
                .fontFamily("Montserrat")
                .end();
        });
    });
}

fn CustomContentEmail(item: *Accordion.AccordionItem) void {
    Stack()
        .width(.percent(100))
        .spacing(16)
        .children({
        Text("Configure your communication settings.")
            .font(16, 300, .palette(.text_color))
            .end();
        Text(item.description)
            .font(16, 400, .palette(.text_color))
            .end();
        Row()
            .width(.percent(100))
            .layout(.right_center)
            .spacing(16)
            .children({
            Button(Vapor.alert, .{ "{s}", .{"Opening Settings..."} })
                .padding(.xy(12, 8))
                .ariaLabel("Email Opening Settings")
                .background(.palette(.tint))
                .children({
                Text("Email Settings")
                    .font(14, 300, .palette(.background))
                    .fontFamily("Montserrat")
                    .end();
            });
            Button(Vapor.alert, .{ "{s}", .{"Opening Settings..."} })
                .padding(.xy(12, 8))
                .ariaLabel("Notification Opening Settings")
                .background(.palette(.text_color))
                .children({
                Text("Notification Settings")
                    .font(14, 300, .palette(.background))
                    .fontFamily("Montserrat")
                    .end();
            });
        });
    });
}
