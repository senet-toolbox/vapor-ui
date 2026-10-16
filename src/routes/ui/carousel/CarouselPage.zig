const std = @import("std");
const Vapor = @import("vapor");
const Text = Vapor.Text;
const Row = Vapor.Row;
const Stack = Vapor.Stack;
const Opaque = @import("opaque-ui");
const Carousel = Opaque.Carousel;

// ============================================================================
// THEME
// ============================================================================

const Theme = struct {
    const text = Vapor.Types.Color.palette(.text_color);
    const text_muted = Vapor.Types.Color.hex("#71717a");
    const border = Vapor.Types.Color.palette(.border_color_light);
    const code_bg = Vapor.Types.Color.hex("#1a1a1a");
};


const CarouselItem = struct {
    title: []const u8,
    subtitle: []const u8 = "",
    color: Vapor.Types.Color = .palette(.tint),
};


// ============================================================================
// SLIDE DATA
// ============================================================================

const slides_basic = [_]CarouselItem{
    .{ .title = "Slide One", .subtitle = "Click ‹ ›  or swipe", .color = .hex("#3b82f6") },
    .{ .title = "Slide Two", .subtitle = "Click ‹ ›  or swipe", .color = .hex("#8b5cf6") },
    .{ .title = "Slide Three", .subtitle = "Click ‹ ›  or swipe", .color = .hex("#ec4899") },
    .{ .title = "Slide Four", .subtitle = "Click ‹ ›  or swipe", .color = .hex("#f97316") },
    .{ .title = "Slide Five", .subtitle = "Click ‹ ›  or swipe", .color = .hex("#10b981") },
};

const slides_compact = [_]CarouselItem{
    .{ .title = "Mercury", .color = .hex("#a78bfa") },
    .{ .title = "Venus", .color = .hex("#f472b6") },
    .{ .title = "Earth", .color = .hex("#34d399") },
    .{ .title = "Mars", .color = .hex("#f87171") },
    .{ .title = "Jupiter", .color = .hex("#fbbf24") },
    .{ .title = "Saturn", .color = .hex("#fcd34d") },
};

const slides_no_loop = [_]CarouselItem{
    .{ .title = "Step 1", .subtitle = "Onboarding", .color = .hex("#06b6d4") },
    .{ .title = "Step 2", .subtitle = "Profile", .color = .hex("#10b981") },
    .{ .title = "Step 3", .subtitle = "Preferences", .color = .hex("#84cc16") },
    .{ .title = "Step 4", .subtitle = "Done", .color = .hex("#22c55e") },
};

// ============================================================================
// INIT
// ============================================================================

pub fn init() void {
    Vapor.Page(.{ .src = @src() }, render, null);
}

// ============================================================================
// UI HELPERS
// ============================================================================

fn sectionTitle(title: []const u8) void {
    Text(title)
        .font(24, 600, Theme.text)
        .fontFamily("IBM Plex Mono,monospace")
        .margin(.t(48))
        .end();
}

fn sectionDesc(desc: []const u8) void {
    Text(desc)
        .font(14, 400, Theme.text_muted)
        .fontFamily("IBM Plex Mono,monospace")
        .margin(.b(16))
        .end();
}

fn exampleLabel(label: []const u8) void {
    Text(label)
        .font(14, 500, Theme.text_muted)
        .fontFamily("IBM Plex Mono,monospace")
        .margin(.t(24))
        .end();
}

fn PreviewCard() Vapor.Builder(.pure) {
    return Stack()
        .background(.transparentizeHex(.palette(.background), 0.5))
        .border(.round(.palette(.border_color_light), .all(12)))
        .width(.percent(100))
        .padding(.all(32))
        .direction(.column)
        .layout(.center)
        .spacing(16);
}

fn customBadgeTile(item: CarouselItem, width: f32, height: f32) void {
    Stack()
        .width(.px(width))
        .height(.px(height))
        .layout(.center)
        .direction(.column)
        .spacing(8)
        .background(.palette(.background))
        .border(.round(.palette(.border_color_light), .all(12)))
        .inlineStyle("flex-shrink: 0;", .{})
        .children({
        Text("// CUSTOM")
            .fontSize(12)
            .fontWeight(900)
            .fontStyle(.italic)
            .fontFamily("IBM Plex Mono,monospace")
            .end();
        Text(item.title)
            .font(20, 600, .palette(.text_color))
            .fontFamily("IBM Plex Mono,monospace")
            .end();
    });
}

fn codeSnippet(code: []const u8) void {
    Row()
        .width(.percent(100))
        .padding(.all(16))
        .background(Theme.code_bg)
        .border(.round(Theme.border, .all(8)))
        .children({
        Text(code)
            .font(13, 400, .hex("#e4e4e7"))
            .fontFamily("IBM Plex Mono,monospace")
            .end();
    });
}

// ============================================================================
// RENDER
// ============================================================================

pub fn render() void {
    Row()
        .width(.percent(100))
        .layout(.top_center)
        .direction(.column)
        .children({

        // Hero
        Vapor.Stack()
            .layout(.center)
            .height(.px(512))
            .width(.percent(100))
            .children({
            Text("carousel-ui ⇒").style(&.{
                .visual = .font(12, 500, .hex("#6f6f6f")),
                .font_family = "IBM Plex Mono,monospace",
            }).end();
            Text("carousel-ui")
                .font(72, 700, .palette(.text_color))
                .end();
            Text("Click + swipe carousel. Prev / next arrows, dot indicators, drag to swipe.")
                .font(16, 300, .palette(.text_color))
                .end();
        });

        // Content
        Stack()
            .width(.px(800))
            .spacing(12)
            .padding(.bottom(120))
            .children({
            Text("Carousel")
                .font(36, 700, Theme.text)
                .fontFamily("IBM Plex Mono,monospace")
                .end();
            Text("Discrete slide carousel. Navigate with arrow buttons, dot indicators, or by swiping.")
                .font(16, 400, Theme.text_muted)
                .fontFamily("IBM Plex Mono,monospace")
                .margin(.b(24))
                .end();

            // ================================================================
            // BASIC
            // ================================================================

            sectionTitle("Basic");
            sectionDesc("Click the arrows, drag to swipe, or click a dot to jump.");
            PreviewCard().children({
                Carousel.render(.{
                    .id = "hero",
                    .count = slides_basic.len,
                    .viewport_width = 480,
                    .viewport_height = 280,
                    .stride = 480 + 16,
                }).children({
                    for (slides_basic) |slide| {
                        Stack()
                            .width(.px(480))
                            .height(.px(280))
                            .background(slide.color)
                            .border(.round(slide.color, .all(12)))
                            .inlineStyle("flex-shrink: 0;", .{})
                            .layout(.center)
                            .children({
                            Text(slide.title).font(28, 700, .white).end();
                        });
                    }
                });

                // Carousel.render(.{
                //     .id = "carousel-basic",
                //     .items = &slides_basic,
                //     .item_width = 480,
                //     .item_height = 280,
                // });
            });

            // ================================================================
            // COMPACT
            // ================================================================

            sectionTitle("Compact");
            sectionDesc("Smaller slides — same swipe + click behavior.");
            PreviewCard().children({
                // Carousel.render(.{
                //     .id = "carousel-compact",
                //     .items = &slides_compact,
                //     .item_width = 320,
                //     .item_height = 200,
                // });
            });

            // ================================================================
            // NO LOOP
            // ================================================================

            sectionTitle("Bounded (no loop)");
            sectionDesc("Stops at the first and last slide instead of wrapping.");
            PreviewCard().children({
                // Carousel.render(.{
                //     .id = "carousel-noloop",
                //     .items = &slides_no_loop,
                //     .item_width = 420,
                //     .item_height = 240,
                //     .loop = false,
                // });
            });

            // ================================================================
            // ARROWS-ONLY (no dots)
            // ================================================================

            sectionTitle("Arrows only");
            sectionDesc("Hide the dot indicators below.");
            PreviewCard().children({
                // Carousel.render(.{
                //     .id = "carousel-arrows-only",
                //     .items = &slides_basic,
                //     .item_width = 480,
                //     .item_height = 240,
                //     .show_dots = false,
                // });
            });

            // ================================================================
            // DOTS-ONLY (no arrows)
            // ================================================================

            sectionTitle("Dots only");
            sectionDesc("Hide arrow buttons — rely on swipes + dot indicators.");
            PreviewCard().children({
                // Carousel.render(.{
                //     .id = "carousel-dots-only",
                //     .items = &slides_basic,
                //     .item_width = 480,
                //     .item_height = 240,
                //     .show_arrows = false,
                // });
            });

            // ================================================================
            // CUSTOM ITEM RENDERER
            // ================================================================

            sectionTitle("Custom Item Renderer");
            sectionDesc("Use create() + Component() to render slides with your own component.");
            PreviewCard().children({
                // Carousel.create(.{
                //     .id = "carousel-custom",
                //     .items = &slides_compact,
                //     .item_width = 360,
                //     .item_height = 220,
                // })
                //     .Component(customBadgeTile, .{});
            });

            // ================================================================
            // CODE USAGE
            // ================================================================

            sectionTitle("Installation");
            codeSnippet(
                \\// In main.zig — initialize state map once at startup
                \\const Carousel = @import("components/Carousel.zig");
                \\Carousel.new();
            );

            sectionTitle("Usage");
            codeSnippet(
                \\const Carousel = @import("components/Carousel.zig");
                \\
                \\const items = [_]CarouselItem{
                \\    .{ .title = "Slide 1", .subtitle = "desc", .color = .hex("#3b82f6") },
                \\    .{ .title = "Slide 2", .subtitle = "desc", .color = .hex("#8b5cf6") },
                \\    // ...
                \\};
                \\
                \\// Click + swipe carousel
                \\Carousel.render(.{
                \\    .id = "my-carousel",   // required for state persistence
                \\    .items = &items,
                \\    .item_width = 480,
                \\    .item_height = 280,
                \\});
            );

            sectionTitle("API Reference");
            exampleLabel("CarouselItem");
            codeSnippet(
                \\pub const CarouselItem = struct {
                \\    title: []const u8,
                \\    subtitle: []const u8 = "",       // optional label below title
                \\    color: Color = .palette(.tint),  // background color of slide
                \\};
            );

            exampleLabel("Custom item renderer via create() + Component()");
            codeSnippet(
                \\fn mySlide(item: CarouselItem, w: f32, h: f32) void {
                \\    Stack()
                \\        .width(.px(w))
                \\        .height(.px(h))
                \\        .background(item.color)
                \\        .children({
                \\        Text(item.title).end();
                \\    });
                \\}
                \\
                \\_ = Carousel.create(.{
                \\    .id = "custom",
                \\    .items = &items,
                \\}).Component(mySlide, .{});
            );

            exampleLabel("Carousel fields");
            codeSnippet(
                \\id: []const u8 = "",         // stable id — required for state
                \\items: []const CarouselItem, // slide data
                \\item_width: f32 = 480,       // slide width  (px)
                \\item_height: f32 = 280,      // slide height (px)
                \\gap: f32 = 16,               // gap between slides (px)
                \\loop: bool = true,           // wrap around at the ends
                \\show_arrows: bool = true,    // prev / next buttons
                \\show_dots: bool = true,      // dot indicators
                \\swipe_threshold: f32 = 60,   // px drag needed to advance
                \\transition_ms: u32 = 350,    // snap animation duration
            );
        });
    });
}
