const Vapor = @import("vapor");
const Row = Vapor.Row;
const Text = Vapor.Text;
const Marquee = @import("opaque-ui").Marquee;

const slides = [_]Marquee.MarqueeItem{
    .{ .title = "Slide One", .color = .hex("#3b82f6") },
    .{ .title = "Slide Two", .color = .hex("#8b5cf6") },
    .{ .title = "Slide Three", .color = .hex("#ec4899") },
};

// Pass children to render() to use any layout you like.
// `repeat` tiles your children to keep the lane full.
pub fn example() void {
    Marquee.render(.{
        .direction = .left,
        .speed_ms = 10000,
        .repeat = 2,
        .gap = 16,
    }).children({
        for (slides) |slide| {
            Row()
                .width(.px(220))
                .height(.px(64))
                .layout(.center)
                .spacing(6)
                .background(.palette(.background))
                .fontFamily("IBM Plex Mono,monospace")
                .border(.simple(.palette(.border_color_light)))
                .children({
                Text("// CUSTOM")
                    .fontSize(10)
                    .fontWeight(900)
                    .fontStyle(.italic)
                    .end();
                Text(slide.title)
                    .fontSize(10)
                    .fontColor(.transparentize(.palette(.text), 0.5))
                    .end();
            });
        }
    });
}
