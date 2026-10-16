const Marquee = @import("opaque-ui").Marquee;

// Slow, ambient motion — calming background pace.
pub fn example(items: []const Marquee.MarqueeItem) void {
    Marquee.render(.{
        .items = items,
        .direction = .left,
        .speed_ms = 20000,
    }).children({
        for (items) |slide| {
            Row()
                .width(.px(220))
                .height(.px(64))
                .layout(.center)
                .spacing(6)
                .background(.palette(.background))
                .fontFamily("IBM Plex Mono,monospace")
                .border(.simple(.palette(.border_color_light)))
                .children({
                Text(slide.title)
                    .fontSize(10)
                    .fontColor(.transparentize(.palette(.text), 0.5))
                    .end();
            });
        }
    });
}

