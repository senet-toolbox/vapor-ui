// page.zig
const std = @import("std");
const Vapor = @import("vapor");
const Text = Vapor.Text;
const Row = Vapor.Row;
const Stack = Vapor.Stack;
const Opaque = @import("opaque-ui");
const Select = Opaque.Select;
const Vaporize = @import("vaporize");
const SyntaxHighlighter = Vaporize.SyntaxHighlighter;
const Switch = Opaque.Switch;
const ProgressBar = Opaque.ProgressBar;
const ProgressCircle = Opaque.ProgressCircle;
const Button = Opaque.Button;
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

var hl_bar_basic: SyntaxHighlighter = undefined;
var hl_circle_basic: SyntaxHighlighter = undefined;
var hl_bar_animated: SyntaxHighlighter = undefined;
var hl_circle_label: SyntaxHighlighter = undefined;

// ============================================================================
// INIT
// ============================================================================

var bar: ProgressBar = undefined;
var circle: ProgressCircle = undefined;

var bar_with_label: ProgressBar = undefined;
var circle_with_label: ProgressCircle = undefined;

pub fn init() void {
    const allocator = Vapor.arena(.persist);

    // Initialize syntax highlighters
    hl_bar_basic = SyntaxHighlighter.init(allocator);
    hl_bar_basic.show_toolbar = true;
    hl_bar_basic.parse(
        \\bar = ProgressBar.init(allocator, .{
        \\    .width = 128,
        \\    .height = 6,
        \\    .color = .palette(.tint),
        \\    .background = .transparentize(.palette(.text_color), 0.1),
        \\});
        \\bar.setProgress(0.34);
        \\bar.render();
    ) catch unreachable;

    hl_circle_basic = SyntaxHighlighter.init(allocator);
    hl_circle_basic.show_toolbar = true;
    hl_circle_basic.parse(
        \\circle = ProgressCircle.init(allocator, .{
        \\    .size = 120,
        \\    .stroke_width = 10,
        \\    .track_color = .palette(.highlight_color),
        \\    .color = .palette(.text_color),
        \\    .clockwise = false,
        \\    .show_label = false,
        \\});
        \\circle.setProgress(0.75);
        \\circle.render();
    ) catch unreachable;

    hl_bar_animated = SyntaxHighlighter.init(allocator);
    hl_bar_animated.show_toolbar = true;
    hl_bar_animated.parse(
        \\bar_with_label = ProgressBar.init(allocator, .{
        \\    .width = 256,
        \\    .height = 16,
        \\    .color = .palette(.danger),
        \\    .background = .transparentize(.palette(.text_color), 0.1),
        \\});
        \\bar_with_label.setProgress(0.0);
        \\
        \\// Animate progress with interval
        \\Vapor.lib.loopInterval("progress-bar-toggle", 60, progressBarToggle, .{});
        \\
        \\fn progressBarToggle() void {
        \\    if (bar_with_label.progress == 1) {
        \\        Vapor.lib.cancelTimeout("progress-bar-toggle");
        \\        return;
        \\    }
        \\    bar_with_label.updateProgress(bar_with_label.progress + 0.01);
        \\}
    ) catch unreachable;

    hl_circle_label = SyntaxHighlighter.init(allocator);
    hl_circle_label.show_toolbar = true;
    hl_circle_label.parse(
        \\circle_with_label = ProgressCircle.init(allocator, .{
        \\    .size = 120,
        \\    .stroke_width = 10,
        \\    .track_color = .palette(.highlight_color),
        \\    .color = .palette(.text_color),
        \\    .clockwise = true,
        \\    .show_label = true,
        \\    .label_font_size = 12,
        \\    .label_color = .palette(.text_color),
        \\});
        \\circle_with_label.setProgress(0.9);
        \\
        \\// Toggle between values
        \\fn progressCircleToggle() void {
        \\    if (circle_with_label.progress != 0.3) {
        \\        circle_with_label.updateProgress(0.3);
        \\    } else {
        \\        circle_with_label.updateProgress(0.8);
        \\    }
        \\}
    ) catch unreachable;

    circle = ProgressCircle.init(Vapor.arena(.persist), .{
        .size = 120,
        .stroke_width = 10,
        .track_color = .palette(.highlight_color),
        .color = .palette(.text_color),
        .clockwise = false,
        .show_label = false,
    });
    circle.setProgress(0.75); // 75%

    bar = ProgressBar.init(Vapor.arena(.persist), .{
        .width = 128,
        .height = 6,
        .color = .palette(.tint),
        .background = .transparentize(.palette(.text_color), 0.1),
    });
    bar.setProgress(0.34);

    circle_with_label = ProgressCircle.init(Vapor.arena(.persist), .{
        .size = 120,
        .stroke_width = 10,
        .track_color = .palette(.highlight_color),
        .color = .palette(.text_color),
        .clockwise = true,
        .show_label = true,
        .label_font_size = 12,
        .label_color = .palette(.text_color),
    });
    circle_with_label.setProgress(0.9); // 75%

    bar_with_label = ProgressBar.init(Vapor.arena(.persist), .{
        .width = 256,
        .height = 16,
        .color = .palette(.danger),
        .background = .transparentize(.palette(.text_color), 0.1),
        .show_label = true,
        .label_font_size = 12,
        .label_position = .above,
        .label_color = .palette(.text_color),
    });
    bar_with_label.setProgress(0.0);

    Vapor.Page(.{ .src = @src() }, render, null);
}

// ============================================================================
// UI COMPONENTS
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
    return Row()
        .background(.transparentize(.palette(.background), 0.5))
        .border(.round(.palette(.border_color_light), .all(12)))
        .width(.percent(100))
        .height(.px(160))
        .padding(.all(24))
        .direction(.column)
        .layout(.center)
        .spacing(16);
}

fn CodeBlock(highlighter: *SyntaxHighlighter) void {
    Row()
        .scroll(.scrollY())
        .inlineStyle("max-height: 512px;", .{})
        .size(.w(.percent(100)))
        .border(.thin(.palette(.text_color)))
        .children({
        highlighter.render() catch unreachable;
    });
}

fn startAnimation() void {
    // Run it again from the start once it has finished.
    if (bar_with_label.progress >= 1) bar_with_label.updateProgress(0);
    Vapor.lib.loopInterval("progress-bar-toggle", 60, progressBarToggle, .{});
}

fn progressBarToggle() void {
    if (bar_with_label.progress == 1) {
        Vapor.lib.cancelTimeout("progress-bar-toggle");
        return;
    }
    bar_with_label.updateProgress(bar_with_label.progress + 0.01);
}

fn progressCircleToggle() void {
    if (circle_with_label.progress != 0.3) {
        circle_with_label.updateProgress(0.3);
    } else {
        circle_with_label.updateProgress(0.8);
    }
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
            Text("progress-ui ⇒").style(&.{
                .visual = .font(12, 500, .hex("#6f6f6f")),
                .font_family = "IBM Plex Mono,monospace",
            }).end();
            Text("progress-ui")
                .font(72, 700, .palette(.text_color))
                .end();
            Text("A collection of ready-to-use progress components built on top of Vapor, copy and paste into your apps.")
                .font(16, 300, .palette(.text_color))
                .end();
        });

        // Content
        Stack()
            .width(.percent(50))
            .height(.percent(100))
            .spacing(12)
            .padding(.{ .bottom = 120 })
            .children({

            // ============================================================
            // PROGRESS BAR BASIC
            // ============================================================
            exampleLabel("Progress Bar");
            sectionDesc("A horizontal progress bar with customizable width, height, and colors.");
            PreviewCard().children({
                bar.render();
            });
            CodeBox(&hl_bar_basic, "ProgressBar");

            // ============================================================
            // PROGRESS CIRCLE BASIC
            // ============================================================
            exampleLabel("Progress Circle");
            sectionDesc("A circular progress indicator with configurable size and stroke width.");
            PreviewCard().children({
                circle.render();
            });
            CodeBox(&hl_circle_basic, "ProgressCircle");

            // ============================================================
            // ANIMATED PROGRESS BAR
            // ============================================================
            exampleLabel("Animated Progress Bar");
            sectionDesc("A progress bar with animated updates using interval-based progression.");
            PreviewCard().children({
                Button(startAnimation, .{})
                    .border(.round(.palette(.border_color_light), .all(4)))
                    .padding(.xy(12, 8))
                    .background(.palette(.background))
                    .children({
                    Text("Start Animation")
                        .font(14, 300, .palette(.text_color))
                        .fontFamily("IBM Plex Mono,monospace")
                        .end();
                });
                bar_with_label.render();
            });
            CodeBox(&hl_bar_animated, "ProgressBar Animation");

            // ============================================================
            // PROGRESS CIRCLE WITH LABEL
            // ============================================================
            exampleLabel("Progress Circle with Label");
            sectionDesc("A circular progress indicator displaying the percentage value.");
            PreviewCard()
                .direction(.row)
                .spacing(16)
                .children({
                Button(progressCircleToggle, .{})
                    .padding(.xy(12, 8))
                    .background(.palette(.tint))
                    .children({
                    Text("Toggle Progress")
                        .font(14, 300, .palette(.background))
                        .fontFamily("IBM Plex Mono,monospace")
                        .end();
                });
                circle_with_label.render();
            });
            CodeBox(&hl_circle_label, "ProgressCircle Label");

            // ============================================================
            // API REFERENCE
            // ============================================================
            sectionTitle("API Reference");

            exampleLabel("ProgressBar Initialization");
            sectionDesc("Create a progress bar with custom dimensions and colors.");
            Row()
                .width(.percent(100))
                .padding(.all(16))
                .background(Theme.code_bg)
                .border(.round(Theme.border, .all(8)))
                .children({
                Text(
                    \\var bar = ProgressBar.init(allocator, .{
                    \\    .width = 128,        // Width in pixels
                    \\    .height = 6,         // Height in pixels
                    \\    .color = .palette(.tint),              // Fill color
                    \\    .background = .transparentize(...),    // Track color
                    \\});
                )
                    .font(14, 400, .hex("#e4e4e7"))
                    .fontFamily("IBM Plex Mono,monospace")
                    .end();
            });

            exampleLabel("ProgressCircle Initialization");
            sectionDesc("Create a circular progress indicator with configurable options.");
            Row()
                .width(.percent(100))
                .padding(.all(16))
                .background(Theme.code_bg)
                .border(.round(Theme.border, .all(8)))
                .children({
                Text(
                    \\var circle = ProgressCircle.init(allocator, .{
                    \\    .size = 120,                           // Diameter in pixels
                    \\    .stroke_width = 10,                    // Ring thickness
                    \\    .track_color = .palette(.highlight_color),
                    \\    .color = .palette(.text_color),        // Progress color
                    \\    .clockwise = true,                     // Direction
                    \\    .show_label = true,                    // Show percentage
                    \\    .label_font_size = 12,                 // Label size
                    \\    .label_color = .palette(.text_color),
                    \\});
                )
                    .font(14, 400, .hex("#e4e4e7"))
                    .fontFamily("IBM Plex Mono,monospace")
                    .end();
            });

            exampleLabel("Setting Progress");
            sectionDesc("Set or update the progress value (0.0 to 1.0).");
            Row()
                .width(.percent(100))
                .padding(.all(16))
                .background(Theme.code_bg)
                .border(.round(Theme.border, .all(8)))
                .children({
                Text(
                    \\// Set initial progress (no animation)
                    \\bar.setProgress(0.5);       // 50%
                    \\circle.setProgress(0.75);   // 75%
                    \\
                    \\// Update progress (with animation)
                    \\bar.updateProgress(0.8);    // Animate to 80%
                    \\circle.updateProgress(0.9); // Animate to 90%
                )
                    .font(14, 400, .hex("#e4e4e7"))
                    .fontFamily("IBM Plex Mono,monospace")
                    .end();
            });

            exampleLabel("Render Methods");
            sectionDesc("Render the progress component.");
            Row()
                .width(.percent(100))
                .padding(.all(16))
                .background(Theme.code_bg)
                .border(.round(Theme.border, .all(8)))
                .children({
                Text(
                    \\bar.render();      // Render the progress bar
                    \\circle.render();   // Render the progress circle
                )
                    .font(14, 400, .hex("#e4e4e7"))
                    .fontFamily("IBM Plex Mono,monospace")
                    .end();
            });

            exampleLabel("Animation with Intervals");
            sectionDesc("Create smooth progress animations using Vapor intervals.");
            Row()
                .width(.percent(100))
                .padding(.all(16))
                .background(Theme.code_bg)
                .border(.round(Theme.border, .all(8)))
                .children({
                Text(
                    \\// Start animation loop (60ms interval)
                    \\Vapor.lib.loopInterval("my-progress", 60, updateFn, .{});
                    \\
                    \\fn updateFn() void {
                    \\    if (bar.progress >= 1.0) {
                    \\        Vapor.lib.cancelTimeout("my-progress");
                    \\        return;
                    \\    }
                    \\    bar.updateProgress(bar.progress + 0.01);
                    \\}
                )
                    .font(14, 400, .hex("#e4e4e7"))
                    .fontFamily("IBM Plex Mono,monospace")
                    .end();
            });
        });
    });
}
