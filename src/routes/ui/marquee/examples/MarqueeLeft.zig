const Vapor = @import("vapor");
const Row = Vapor.Row;
const Text = Vapor.Text;
const Marquee = @import("opaque-ui").Marquee;

const slides = [_]Marquee.MarqueeItem{
    .{ .title = "Slide One", .subtitle = "Scroll left", .color = .hex("#3b82f6") },
    .{ .title = "Slide Two", .subtitle = "Scroll left", .color = .hex("#8b5cf6") },
    .{ .title = "Slide Three", .subtitle = "Scroll left", .color = .hex("#ec4899") },
};

pub fn example() void {
    Marquee.render(.{ .items = &slides, .direction = .left, .speed_ms = 10000 }).children({
        for (slides) |slide| {
            Row().width(.px(220)).height(.px(64))
                .layout(.center).spacing(6)
                .background(.palette(.background)).fontFamily("IBM Plex Mono,monospace")
                .border(.simple(.palette(.border_color_light)))
                .children({
                Text(slide.title).fontSize(10).fontColor(.transparentize(.palette(.text), 0.5)).end();
            });
        }
    });
}
