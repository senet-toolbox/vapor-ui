const Vapor = @import("vapor");
const Row = Vapor.Row;
const Text = Vapor.Text;
const Badge = @import("opaque-ui").Badge;

pub fn render() void {
    Row().spacing(24).layout(.center).children({
        Row().spacing(8).layout(.center).children({
            Text("Inbox").font(14, 400, .palette(.text_color)).end();
            Badge.count(3, "unread messages");
        });
        Row().spacing(8).layout(.center).children({
            Text("Alerts").font(14, 400, .palette(.text_color)).end();
            // Past 99 it reads 99+; screen readers hear 150.
            Badge.count(150, "alerts");
        });
    });
}
