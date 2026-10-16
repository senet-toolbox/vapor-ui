const Vapor = @import("vapor");
const Row = Vapor.Row;
const Text = Vapor.Text;
const Marquee = @import("opaque-ui").Marquee;

const slides = [_]Marquee.MarqueeItem{
    .{ .title = "Slide One", .subtitle = "Scroll right", .color = .hex("#14b8a6") },
    .{ .title = "Slide Two", .subtitle = "Scroll right", .color = .hex("#f59e0b") },
    .{ .title = "Slide Three", .subtitle = "Scroll right", .color = .hex("#ef4444") },
};

pub fn example() void {
    Marquee.render(.{
        .direction = .right,
        .speed_ms = 10000,
    }).children({
        for (slides) |slide| {
            Row()
                .width(.px(220))
                .height(.px(64))
                .layout(.center)
                .spacing(6)
                .background(.palette(.background))
                .fontFamily("IBM Plex Mono,monospace")
                .border(.thin(.palette(.border_color_light)))
                .children({
                Text(slide.title)
                    .fontSize(10)
                    .textColor(.transparentize(.palette(.text), 0.5))
                    .end();
            });
        }
    });
}
