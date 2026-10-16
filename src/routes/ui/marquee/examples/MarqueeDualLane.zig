const Vapor = @import("vapor");
const Stack = Vapor.Stack;
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

// Two marquees in opposing directions produce a parallax effect.
pub fn example() void {
    Stack()
        .direction(.column)
        .spacing(12)
        .children({
        Marquee.render(.{
            .items = &slides_a,
            .direction = .left,
            .speed_ms = 8000,
        });
        Marquee.render(.{
            .items = &slides_b,
            .direction = .right,
            .speed_ms = 8000,
        });
    });
}

