const Vapor = @import("vapor");
const Stack = Vapor.Stack;
const Text = Vapor.Text;
const Color = Vapor.Types.Color;
const Carousel = @import("opaque-ui").Carousel;

const planets = [_][]const u8{ "Mercury", "Venus", "Earth", "Mars" };
const colors = [_]Color{ .hex("#a78bfa"), .hex("#f472b6"), .hex("#38bdf8"), .hex("#fb923c") };

/// One slide of the given size.
fn slide(index: usize, width: f32, height: f32) void {
    Stack()
        .width(.px(width))
        .height(.px(height))
        .background(colors[index % colors.len])
        .radius(.all(12))
        .inlineStyle("flex-shrink: 0;", .{})
        .layout(.center)
        .children({
        Text(planets[index]).font(22, 700, .white).end();
    });
}

/// Smaller slides: the viewport and stride follow the slide size.
pub fn compact() void {
    Carousel.render(.{ .id = "compact", .count = planets.len, .viewport_width = 320, .viewport_height = 200, .stride = 320 + 16 })
        .children({
        for (0..planets.len) |i| slide(i, 320, 200);
    });
}

/// Stops at the first and last slide instead of wrapping.
pub fn bounded() void {
    Carousel.render(.{ .id = "bounded", .count = planets.len, .viewport_width = 420, .viewport_height = 240, .stride = 420 + 16, .loop = false })
        .children({
        for (0..planets.len) |i| slide(i, 420, 240);
    });
}

/// No dots below.
pub fn arrowsOnly() void {
    Carousel.render(.{ .id = "arrows-only", .count = planets.len, .viewport_width = 420, .viewport_height = 240, .stride = 420 + 16, .show_dots = false })
        .children({
        for (0..planets.len) |i| slide(i, 420, 240);
    });
}

/// No arrows: swipe or use the dots.
pub fn dotsOnly() void {
    Carousel.render(.{ .id = "dots-only", .count = planets.len, .viewport_width = 420, .viewport_height = 240, .stride = 420 + 16, .show_arrows = false })
        .children({
        for (0..planets.len) |i| slide(i, 420, 240);
    });
}
