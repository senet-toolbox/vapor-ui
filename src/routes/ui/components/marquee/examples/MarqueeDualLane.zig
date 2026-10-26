const Vapor = @import("vapor");
const Row = Vapor.Row;
const Stack = Vapor.Stack;
const Text = Vapor.Text;
const Marquee = @import("opaque-ui").Marquee;

const slides_a = [_]Marquee.MarqueeItem{
    .{ .title = "Lane A — One", .color = .hex("#3b82f6") },
    .{ .title = "Lane A — Two", .color = .hex("#8b5cf6") },
    .{ .title = "Lane A — Three", .color = .hex("#ec4899") },
};

const slides_b = [_]Marquee.MarqueeItem{
    .{ .title = "Lane B — One", .color = .hex("#14b8a6") },
    .{ .title = "Lane B — Two", .color = .hex("#f59e0b") },
    .{ .title = "Lane B — Three", .color = .hex("#ef4444") },
};

fn lane(slides: []const Marquee.MarqueeItem) void {
    for (slides) |slide| {
        Row()
            .width(.px(220))
            .height(.px(64))
            .layout(.center)
            .background(slide.color)
            .radius(.all(8))
            .children({
            Text(slide.title).fontSize(10).end();
        });
    }
}

// Two marquees in opposing directions produce a parallax effect.
pub fn example() void {
    Stack()
        .width(.percent(100))
        .spacing(12)
        .children({
        Marquee.render(.{ .direction = .left, .speed_ms = 8000 }).children({
            lane(&slides_a);
        });
        Marquee.render(.{ .direction = .right, .speed_ms = 8000 }).children({
            lane(&slides_b);
        });
    });
}
