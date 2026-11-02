const std = @import("std");
const Vapor = @import("vapor");
const Row = Vapor.Row;
const Text = Vapor.Text;
const Button = @import("opaque-ui").Button;

fn clicked(name: []const u8) void {
    std.log.info("{s} clicked", .{name});
}

// One look per job; each is the same Button with a few calls changed.
pub fn render() void {
    Row().layout(.center).wrap(.wrap).spacing(12).children({
        // Primary: the one main action.
        Button(clicked, .{"Primary"})
            .background(.palette(.tint))
            .children({
            Text("Button")
                .fontFamily("Montserrat")
                .font(14, 500, .palette(.background))
                .end();
        });

        // Secondary: no fill, a quiet border.
        Button(clicked, .{"Secondary"})
            .background(.transparent)
            .border(.round(.palette(.border_color_light), .all(8)))
            .children({
            Text("Secondary")
                .fontFamily("Montserrat")
                .font(14, 500, .palette(.text_color))
                .end();
        });

        // Outline: the border in the tint.
        Button(clicked, .{"Outline"})
            .background(.transparent)
            .border(.round(.palette(.tint), .all(8)))
            .children({
            Text("Outline")
                .fontFamily("Montserrat")
                .font(14, 500, .palette(.tint))
                .end();
        });

        // Ghost: just the text, until hovered.
        Button(clicked, .{"Ghost"})
            .background(.transparent)
            .children({
            Text("Ghost")
                .fontFamily("Montserrat")
                .font(14, 500, .palette(.text_color))
                .end();
        });

        // Destructive: for actions that can't be undone.
        Button(clicked, .{"Delete"})
            .background(.hex("#ef4444"))
            .children({
            Text("Delete")
                .fontFamily("Montserrat")
                .font(14, 500, .white)
                .end();
        });
    });
}
