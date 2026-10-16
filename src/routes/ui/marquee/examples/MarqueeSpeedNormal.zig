const Vapor = @import("vapor");
const Row = Vapor.Row;
const Text = Vapor.Text;
const Marquee = @import("opaque-ui").Marquee;

// Standard pace — what most marquees should feel like.
pub fn example(items: []const Marquee.MarqueeItem) void {
    Marquee.render(.{
        .direction = .left,
        .speed_ms = 10000,
    }).children({
        for (items) |slide| {
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
