const Vapor = @import("vapor");
const Row = Vapor.Row;
const Text = Vapor.Text;
const Marquee = @import("opaque-ui").Marquee;

const cards = [_]Marquee.MarqueeItem{
    .{ .title = "Card One", .subtitle = "Scroll down", .color = .hex("#14b8a6") },
    .{ .title = "Card Two", .subtitle = "Scroll down", .color = .hex("#f59e0b") },
    .{ .title = "Card Three", .subtitle = "Scroll down", .color = .hex("#ef4444") },
};

// Vertical marquees need a fixed height on their container.
pub fn example() void {
    Marquee.render(.{
        .direction = .down,
        .speed_ms = 10000,
    }).children({
        for (cards) |card| {
            Row()
                .width(.px(220))
                .height(.px(64))
                .layout(.center)
                .spacing(6)
                .background(.palette(.background))
                .fontFamily("IBM Plex Mono,monospace")
                .border(.thin(.palette(.border_color_light)))
                .children({
                Text(card.title)
                    .fontSize(10)
                    .textColor(.transparentize(.palette(.text), 0.5))
                    .end();
            });
        }
    });
}
