const Marquee = @import("opaque-ui").Marquee;

const slides = [_]Marquee.MarqueeItem{
    .{ .title = "Slide One", .subtitle = "Scroll right", .color = .hex("#14b8a6") },
    .{ .title = "Slide Two", .subtitle = "Scroll right", .color = .hex("#f59e0b") },
    .{ .title = "Slide Three", .subtitle = "Scroll right", .color = .hex("#ef4444") },
};

pub fn example() void {
    Marquee.render(.{
        .items = &slides,
        .direction = .down,
        .speed_ms = 10000,
    });
}
