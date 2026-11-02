const std = @import("std");
const Vapor = @import("vapor");
const Row = Vapor.Row;
const Text = Vapor.Text;
const Icon = Vapor.Icon;
const Button = @import("opaque-ui").Button;

fn clicked(name: []const u8) void {
    std.log.info("{s} clicked", .{name});
}

pub fn render() void {
    Row().layout(.center).wrap(.wrap).spacing(12).children({
        // An icon beside the text: both go in its children.
        Button(clicked, .{"Login with Email"})
            .background(.palette(.tint))
            .children({
            Icon(.envelope)
                .font(14, 500, .palette(.background))
                .end();
            Text("Login with Email")
                .fontFamily("Montserrat")
                .font(14, 500, .palette(.background))
                .end();
        });

        // An icon alone needs a name for screen readers.
        Button(clicked, .{"Next"})
            .ariaLabel("Next")
            .background(.transparent)
            .border(.round(.palette(.border_color_light), .all(8)))
            .children({
            Icon(.chevron_right)
                .font(16, 500, .palette(.text_color))
                .end();
        });
    });
}
