const Vapor = @import("vapor");
const Row = Vapor.Row;
const Stack = Vapor.Stack;
const Text = Vapor.Text;
const Opaque = @import("opaque-ui");
const Skeleton = Opaque.Skeleton;
const Avatar = Opaque.Avatar;
const Button = Opaque.Button;

var loading = false;

fn loaded() void {
    loading = false;
}

fn reload() void {
    loading = true;
    // Where you would fetch; here, the reply comes after a second.
    Vapor.timeout("skeleton-demo", 1000, loaded, .{});
}

pub fn render() void {
    Stack().width(.percent(100)).inlineStyle("max-width: 360px;", .{}).spacing(16).children({
        // Busy while it loads, so a screen reader waits for the content.
        Row()
            .attribute("aria-busy", if (loading) "true" else "false")
            .attribute("aria-live", "polite")
            .width(.percent(100))
            .spacing(12)
            .layout(.left_center)
            .children({
            if (loading) {
                Skeleton.circle(40);
                Stack().width(.grow).spacing(8).children({
                    Skeleton.render(.{ .width = .px(120), .height = 14 });
                    Skeleton.render(.{ .width = .px(200), .height = 12 });
                });
            } else {
                Avatar.render(.{ .name = "Sarah Chen" });
                Stack().spacing(4).children({
                    Text("Sarah Chen").font(14, 600, .palette(.text_color)).end();
                    Text("Shipped the new billing page").font(13, 400, .transparentize(.palette(.text_color), 0.6)).end();
                });
            }
        });
        Button(reload, .{}).children({
            Text(if (loading) "Loading…" else "Reload").font(14, 500, .palette(.text_color)).end();
        });
    });
}
