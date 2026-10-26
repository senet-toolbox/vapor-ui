const std = @import("std");
const Vapor = @import("vapor");
const Hero = @import("../../../../components/Hero.zig").Hero;
const Text = Vapor.Text;
const Row = Vapor.Row;
const Stack = Vapor.Stack;
const Opaque = @import("opaque-ui");
const Carousel = Opaque.Carousel;
// Rendered and shown as code: what you read is what runs.
const BasicCarousel = @import("examples/BasicCarousel.zig");
const CarouselOptions = @import("examples/CarouselOptions.zig");

// ============================================================================
// THEME
// ============================================================================

const Theme = struct {
    const text = Vapor.Types.Color.palette(.text_color);
    const text_muted = Vapor.Types.Color.hex("#71717a");
    const border = Vapor.Types.Color.palette(.border_color_light);
    const code_bg = Vapor.Types.Color.hex("#1a1a1a");
};

// ============================================================================
// SLIDE DATA
// ============================================================================

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
        .margin(.{ .top = 48 })
        .end();
}

fn sectionDesc(desc: []const u8) void {
    Text(desc)
        .font(14, 400, Theme.text_muted)
        .fontFamily("IBM Plex Mono,monospace")
        .margin(.{ .bottom = 16 })
        .end();
}

fn exampleLabel(label: []const u8) void {
    Text(label)
        .font(14, 500, Theme.text_muted)
        .fontFamily("IBM Plex Mono,monospace")
        .margin(.{ .top = 24 })
        .end();
}

fn PreviewCard() Vapor.Builder(.pure) {
    return Stack()
        .background(.transparentize(.palette(.background), 0.5))
        .border(.round(.palette(.border_color_light), .all(12)))
        .width(.percent(100))
        .padding(.all(32))
        .direction(.column)
        .layout(.center)
        .spacing(16);
}

fn codeSnippet(code: []const u8) void {
    Row()
        .width(.percent(100))
        .padding(.all(16))
        .background(Theme.code_bg)
        .scroll(.scrollX())
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
        Hero("carousel-ui", "Click + swipe carousel. Prev / next arrows, dot indicators, drag to swipe.");

        // Content
        Stack()
            .width(.px(800))
            .responsive(.mobile, .{ .size = .w(.percent(92)) })
            .spacing(12)
            .padding(.{ .bottom = 120 })
            .children({
            Text("Carousel")
                .font(36, 700, Theme.text)
                .fontFamily("IBM Plex Mono,monospace")
                .end();
            Text("Discrete slide carousel. Navigate with arrow buttons, dot indicators, or by swiping.")
                .font(16, 400, Theme.text_muted)
                .fontFamily("IBM Plex Mono,monospace")
                .margin(.{ .bottom = 24 })
                .end();

            // ================================================================
            // BASIC
            // ================================================================

            sectionTitle("Basic");
            sectionDesc("Click the arrows, drag to swipe, or click a dot to jump.");
            PreviewCard().children({
                BasicCarousel.render();
            });

            // ================================================================
            // COMPACT
            // ================================================================

            sectionTitle("Compact");
            sectionDesc("Smaller slides — same swipe + click behavior.");
            PreviewCard().children({
                CarouselOptions.compact();
            });

            // ================================================================
            // NO LOOP
            // ================================================================

            sectionTitle("Bounded (no loop)");
            sectionDesc("Stops at the first and last slide instead of wrapping.");
            PreviewCard().children({
                CarouselOptions.bounded();
            });

            // ================================================================
            // ARROWS-ONLY (no dots)
            // ================================================================

            sectionTitle("Arrows only");
            sectionDesc("Hide the dot indicators below.");
            PreviewCard().children({
                CarouselOptions.arrowsOnly();
            });

            // ================================================================
            // DOTS-ONLY (no arrows)
            // ================================================================

            sectionTitle("Dots only");
            sectionDesc("Hide arrow buttons — rely on swipes + dot indicators.");
            PreviewCard().children({
                CarouselOptions.dotsOnly();
            });

            // ================================================================
            // CODE USAGE
            // ================================================================

            sectionTitle("Installation");
            codeSnippet(
                \\// In your init: sets up the state of every opaque-ui component
                \\const Opaque = @import("opaque-ui");
                \\Opaque.new();
            );

            sectionTitle("Usage");
            codeSnippet(@embedFile("examples/BasicCarousel.zig"));

            sectionTitle("Options");
            sectionDesc("The variants above: size, looping, arrows and dots.");
            codeSnippet(@embedFile("examples/CarouselOptions.zig"));

            sectionTitle("API Reference");
            exampleLabel("Carousel.render options");
            codeSnippet(
                \\id: []const u8,              // stable id — required for state
                \\count: usize,                // number of slides you render
                \\viewport_width: f32 = 480,   // visible width (px)
                \\viewport_height: f32 = 280,  // visible height (px)
                \\stride: f32 = 496,           // slide width + gap (px)
                \\loop: bool = true,           // wrap around at the ends
                \\show_arrows: bool = true,    // prev / next buttons
                \\show_dots: bool = true,      // dot indicators
                \\swipe_threshold: f32 = 60,   // px drag needed to advance
                \\transition_ms: u32 = 350,    // snap animation duration
            );
        });
    });
}
