const Marquee = @import("opaque-ui").Marquee;

const cards = [_]Marquee.MarqueeItem{
    .{ .title = "Card One", .subtitle = "Scroll up", .color = .hex("#ef4444") },
    .{ .title = "Card Two", .subtitle = "Scroll up", .color = .hex("#f59e0b") },
    .{ .title = "Card Three", .subtitle = "Scroll up", .color = .hex("#06b6d4") },
};

pub fn example() void {
    Marquee.render(.{
        .items = &cards,
        .direction = .up,
        .speed_ms = 10000,
    }).children({
        for (cards) |slide| {
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

