const Vapor = @import("vapor");
const Stack = Vapor.Stack;
const Text = Vapor.Text;
const Color = Vapor.Types.Color;
const Carousel = @import("opaque-ui").Carousel;

const Slide = struct { title: []const u8, color: Color };

const slides = [_]Slide{
    .{ .title = "Slide One", .color = .hex("#3b82f6") },
    .{ .title = "Slide Two", .color = .hex("#8b5cf6") },
    .{ .title = "Slide Three", .color = .hex("#ec4899") },
    .{ .title = "Slide Four", .color = .hex("#f97316") },
    .{ .title = "Slide Five", .color = .hex("#10b981") },
};

// Arrows, swipe and dots come from the carousel; you render the slides.
pub fn render() void {
    Carousel.render(.{
        .id = "hero", // required: keeps the index across renders
        .count = slides.len,
        .viewport_width = 480,
        .viewport_height = 280,
        .stride = 480 + 16, // slide width + gap
    }).children({
        for (slides) |slide| {
            Stack()
                .width(.px(480))
                .height(.px(280))
                .background(slide.color)
                .radius(.all(12))
                .inlineStyle("flex-shrink: 0;", .{})
                .layout(.center)
                .children({
                Text(slide.title).font(28, 700, .white).end();
            });
        }
    });
}
