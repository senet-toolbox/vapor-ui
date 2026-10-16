const std = @import("std");
const Vapor = @import("vapor");
const Text = Vapor.Text;
const Row = Vapor.Row;
const Stack = Vapor.Stack;
const Opaque = @import("opaque-ui");
const Marquee = Opaque.Marquee;
const Vaporize = @import("vaporize");
const SyntaxHighlighter = Vaporize.SyntaxHighlighter;
const Page = Vapor.Page;
const CodeBox = @import("../CodeBox.zig").CodeBox;

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
// SYNTAX HIGHLIGHTERS
// ============================================================================

var hl_left: SyntaxHighlighter = undefined;
var hl_right: SyntaxHighlighter = undefined;
var hl_up: SyntaxHighlighter = undefined;
var hl_down: SyntaxHighlighter = undefined;

var hl_speed_slow: SyntaxHighlighter = undefined;
var hl_speed_normal: SyntaxHighlighter = undefined;
var hl_speed_fast: SyntaxHighlighter = undefined;
var hl_speed_blazing: SyntaxHighlighter = undefined;

var hl_custom: SyntaxHighlighter = undefined;
var hl_dual_lane: SyntaxHighlighter = undefined;

var hl_install: SyntaxHighlighter = undefined;
var hl_item_type: SyntaxHighlighter = undefined;
var hl_fields: SyntaxHighlighter = undefined;

// ============================================================================
// SLIDE DATA
// ============================================================================

const slides_h = [_]Marquee.MarqueeItem{
    .{ .title = "Slide One", .subtitle = "Scroll left", .color = .hex("#3b82f6") },
    .{ .title = "Slide Two", .subtitle = "Scroll left", .color = .hex("#8b5cf6") },
    .{ .title = "Slide Three", .subtitle = "Scroll left", .color = .hex("#ec4899") },
    .{ .title = "Slide Four", .subtitle = "Scroll left", .color = .hex("#f97316") },
    .{ .title = "Slide Five", .subtitle = "Scroll left", .color = .hex("#10b981") },
    .{ .title = "Slide Six", .subtitle = "Scroll left", .color = .hex("#f97316") },
    .{ .title = "Slide Seven", .subtitle = "Scroll left", .color = .hex("#10b981") },
};

const slides_r = [_]Marquee.MarqueeItem{
    .{ .title = "Slide One", .subtitle = "Scroll right", .color = .hex("#14b8a6") },
    .{ .title = "Slide Two", .subtitle = "Scroll right", .color = .hex("#f59e0b") },
    .{ .title = "Slide Three", .subtitle = "Scroll right", .color = .hex("#ef4444") },
    .{ .title = "Slide Four", .subtitle = "Scroll right", .color = .hex("#06b6d4") },
    .{ .title = "Slide Five", .subtitle = "Scroll right", .color = .hex("#84cc16") },
    .{ .title = "Slide Six", .subtitle = "Scroll right", .color = .hex("#f97316") },
    .{ .title = "Slide Seven", .subtitle = "Scroll right", .color = .hex("#10b981") },
};

const slides_v = [_]Marquee.MarqueeItem{
    .{ .title = "Card One", .subtitle = "Scroll up", .color = .hex("#ef4444") },
    .{ .title = "Card Two", .subtitle = "Scroll up", .color = .hex("#f59e0b") },
    .{ .title = "Card Three", .subtitle = "Scroll up", .color = .hex("#06b6d4") },
    .{ .title = "Card Four", .subtitle = "Scroll up", .color = .hex("#84cc16") },
    .{ .title = "Card Five", .subtitle = "Scroll up", .color = .hex("#a855f7") },
    .{ .title = "Card Six", .subtitle = "Scroll up", .color = .hex("#f97316") },
    .{ .title = "Card Seven", .subtitle = "Scroll up", .color = .hex("#10b981") },
};

const slides_d = [_]Marquee.MarqueeItem{
    .{ .title = "Card One", .subtitle = "Scroll down", .color = .hex("#6366f1") },
    .{ .title = "Card Two", .subtitle = "Scroll down", .color = .hex("#0ea5e9") },
    .{ .title = "Card Three", .subtitle = "Scroll down", .color = .hex("#d946ef") },
    .{ .title = "Card Four", .subtitle = "Scroll down", .color = .hex("#f43f5e") },
    .{ .title = "Card Five", .subtitle = "Scroll down", .color = .hex("#22c55e") },
    .{ .title = "Card Six", .subtitle = "Scroll down", .color = .hex("#f97316") },
    .{ .title = "Card Seven", .subtitle = "Scroll down", .color = .hex("#10b981") },
};

// ============================================================================
// INIT
// ============================================================================

pub fn init() void {
    const allocator = Vapor.arena(.persist);

    // Direction examples
    hl_left = SyntaxHighlighter.init(allocator);
    hl_left.show_toolbar = true;
    hl_left.scrolling_enabled = true;
    hl_left.parse(@embedFile("examples/MarqueeLeft.zig")) catch unreachable;

    hl_right = SyntaxHighlighter.init(allocator);
    hl_right.show_toolbar = true;
    hl_right.parse(@embedFile("examples/MarqueeRight.zig")) catch unreachable;

    hl_up = SyntaxHighlighter.init(allocator);
    hl_up.show_toolbar = true;
    hl_up.parse(@embedFile("examples/MarqueeUp.zig")) catch unreachable;

    hl_down = SyntaxHighlighter.init(allocator);
    hl_down.show_toolbar = true;
    hl_down.parse(@embedFile("examples/MarqueeDown.zig")) catch unreachable;

    // Speed examples
    hl_speed_slow = SyntaxHighlighter.init(allocator);
    hl_speed_slow.show_toolbar = true;
    hl_speed_slow.parse(@embedFile("examples/MarqueeSpeedSlow.zig")) catch unreachable;

    hl_speed_normal = SyntaxHighlighter.init(allocator);
    hl_speed_normal.show_toolbar = true;
    hl_speed_normal.parse(@embedFile("examples/MarqueeSpeedNormal.zig")) catch unreachable;

    // hl_speed_fast = SyntaxHighlighter.init(allocator);
    // hl_speed_fast.show_toolbar = true;
    // hl_speed_fast.parse(@embedFile("examples/MarqueeSpeedFast.zig")) catch unreachable;
    //
    // hl_speed_blazing = SyntaxHighlighter.init(allocator);
    // hl_speed_blazing.show_toolbar = true;
    // hl_speed_blazing.parse(@embedFile("examples/MarqueeSpeedBlazing.zig")) catch unreachable;

    // Composition examples
    hl_custom = SyntaxHighlighter.init(allocator);
    hl_custom.show_toolbar = true;
    hl_custom.parse(@embedFile("examples/MarqueeCustom.zig")) catch unreachable;

    hl_dual_lane = SyntaxHighlighter.init(allocator);
    hl_dual_lane.show_toolbar = true;
    hl_dual_lane.parse(@embedFile("examples/MarqueeDualLane.zig")) catch unreachable;

    // // Reference / install
    // hl_install = SyntaxHighlighter.init(allocator);
    // hl_install.show_toolbar = true;
    // hl_install.parse(@embedFile("examples/MarqueeInstall.zig")) catch unreachable;
    //
    // hl_item_type = SyntaxHighlighter.init(allocator);
    // hl_item_type.show_toolbar = true;
    // hl_item_type.parse(@embedFile("examples/MarqueeItemType.zig")) catch unreachable;
    //
    // hl_fields = SyntaxHighlighter.init(allocator);
    // hl_fields.show_toolbar = true;
    // hl_fields.parse(@embedFile("examples/MarqueeFields.zig")) catch unreachable;

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
        .layout(.center)
        .spacing(16);
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
            Text("marquee-ui ⇒").style(&.{
                .visual = .font(12, 500, .hex("#6f6f6f")),
                .font_family = "IBM Plex Mono,monospace",
            }).end();
            Text("marquee-ui")
                .font(72, 700, .palette(.text_color))
                .end();
            Text("Auto-scrolling marquee with left, right, up, and down motion. Configurable speed, gap, and item count.")
                .font(16, 300, .palette(.text_color))
                .end();
        });

        // Content
        Stack()
            .width(.px(800))
            .spacing(12)
            .padding(.bottom(120))
            .children({
            Text("Marquee")
                .font(36, 700, Theme.text)
                .fontFamily("IBM Plex Mono,monospace")
                .end();
            Text("Auto-motion marquee supporting all four scroll directions with variable speed input. Items loop seamlessly with zero layout shift.")
                .font(16, 400, Theme.text_muted)
                .fontFamily("IBM Plex Mono,monospace")
                .margin(.b(24))
                .end();

            // ================================================================
            // DIRECTION DEMOS
            // ================================================================

            sectionTitle("Directions");
            sectionDesc("Pick a direction with the .direction field. Horizontal marquees scroll left or right, vertical marquees scroll up or down.");

            exampleLabel("Left (default)");
            sectionDesc("Slides advance to the left continuously. This is the default behavior when no direction is specified.");
            PreviewCard().children({
                Marquee.render(.{
                    .direction = .left,
                    .speed_ms = 10000,
                }).children({
                    for (slides_h) |slide| {
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
            });
            CodeBox(&hl_left, "MarqueeLeft");

            exampleLabel("Right");
            sectionDesc("Slides advance to the right. Useful for paired lanes scrolling in opposite directions.");
            PreviewCard().children({
                Marquee.render(.{
                    .direction = .right,
                    .speed_ms = 10000,
                }).children({
                    for (slides_h) |slide| {
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
            });
            CodeBox(&hl_right, "MarqueeRight");

            exampleLabel("Up");
            sectionDesc("Slides scroll upward. Vertical marquees expect a fixed height on the container.");
            PreviewCard()
                .height(.px(512))
                .children({
                Marquee.render(.{
                    .speed_ms = 4000,
                    .direction = .up,
                }).children({
                    for (slides_v) |slide| {
                        Row()
                            .width(.px(220))
                            .height(.px(64))
                            .layout(.center)
                            .spacing(6)
                            .background(.palette(.background))
                            .fontFamily("IBM Plex Mono,monospace")
                            .border(.simple(.palette(.border_color_light)))
                            .children({
                            Text("// Up")
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
            });
            CodeBox(&hl_up, "MarqueeUp");

            exampleLabel("Down");
            sectionDesc("Slides scroll downward — handy for testimonial walls and column-stacked layouts.");
            PreviewCard()
                .height(.px(512))
                .children({
                Marquee.render(.{
                    .direction = .down,
                    .speed_ms = 4000,
                }).children({
                    for (slides_v) |slide| {
                        Row()
                            .width(.px(220))
                            .height(.px(64))
                            .layout(.center)
                            .spacing(6)
                            .background(.palette(.background))
                            .fontFamily("IBM Plex Mono,monospace")
                            .border(.simple(.palette(.border_color_light)))
                            .children({
                            Text("// Up")
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
            });
            CodeBox(&hl_down, "MarqueeDown");

            // ================================================================
            // DUAL LANE
            // ================================================================

            sectionTitle("Dual Lane");
            sectionDesc("Two marquees stacked in opposite directions create a layered, parallax-like feel — common in marketing pages and logo walls.");
            PreviewCard().children({
                Stack()
                    .width(.percent(100))
                    .direction(.column)
                    .spacing(12)
                    .children({
                    Marquee.render(.{
                        .direction = .right,
                        .speed_ms = 4000,
                    }).children({
                        for (slides_v) |slide| {
                            Row()
                                .width(.px(220))
                                .height(.px(64))
                                .layout(.center)
                                .spacing(6)
                                .background(slide.color)
                                .radius(.all(8))
                                .children({
                                Text("// Up")
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
                    Marquee.render(.{
                        .direction = .left,
                        .speed_ms = 4000,
                    }).children({
                        for (slides_r) |slide| {
                            Row()
                                .width(.px(220))
                                .height(.px(64))
                                .layout(.center)
                                .spacing(6)
                                .background(slide.color)
                                .radius(.all(8))
                                .children({
                                Text("// Up")
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
                });
            });
            CodeBox(&hl_dual_lane, "MarqueeDualLane");

            // ================================================================
            // INSTALLATION
            // ================================================================

            sectionTitle("Installation");
            sectionDesc("Marquee uses CSS keyframes that must be registered once at startup. Call Marquee.new() before mounting any pages.");
            Opaque.Copy("metal add vapor-ui opaque-marquee");
        });
    });
}

