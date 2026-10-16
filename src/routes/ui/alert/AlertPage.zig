const std = @import("std");
const Vapor = @import("vapor");
const Text = Vapor.Text;
const Row = Vapor.Row;
const Stack = Vapor.Stack;
const Opaque = @import("opaque-ui");
const Alert = Opaque.Alert;
const Vaporize = @import("vaporize");
const SyntaxHighlighter = Vaporize.SyntaxHighlighter;
const Icon = Vapor.Icon;
const Button = Opaque.Button;
const Page = Vapor.Page;
const CodeBox = @import("../CodeBox.zig").CodeBox;
// Rendered and shown as code: what you read is what runs.
const AlertExample = @import("examples/AlertExample.zig");

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

var hl_alert: SyntaxHighlighter = undefined;

// ============================================================================
// ALERT INSTANCE
// ============================================================================

pub fn init() void {
    const allocator = Vapor.arena(.persist);

    // Initialize syntax highlighter
    hl_alert = SyntaxHighlighter.init(allocator);
    hl_alert.show_toolbar = true;
    hl_alert.parse(@embedFile("examples/AlertExample.zig")) catch unreachable;

    // Initialize Alert with the content callback
    AlertExample.init();

    Page(.{ .src = @src() }, render, null);
}

// ============================================================================
// UI HELPERS
// ============================================================================

fn sectionDesc(desc: []const u8) void {
    Text(desc).font(14, 400, Theme.text_muted).fontFamily("IBM Plex Mono,monospace").margin(.{ .bottom = 16 }).end();
}

fn exampleLabel(label: []const u8) void {
    Text(label).font(14, 500, Theme.text_muted).fontFamily("IBM Plex Mono,monospace").margin(.{ .top = 24 }).end();
}

fn PreviewCard() Vapor.Builder(.pure) {
    return Stack()
        .background(.transparentize(.palette(.background), 0.5))
        .border(.round(.palette(.border_color_light), .all(12)))
        .width(.percent(100))
        .height(.px(200))
        .padding(.all(24))
        .direction(.column)
        .layout(.center)
        .spacing(16);
}

// ============================================================================
// RENDER
// ============================================================================

fn render() void {
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
            Text("alert-ui ⇒").style(&.{
                .visual = .font(12, 500, .hex("#6f6f6f")),
                .font_family = "IBM Plex Mono,monospace",
            }).end();
            Text("alert-ui")
                .font(72, 700, .palette(.text_color))
                .end();
            Text("Modal interrupts used for confirmations, warnings, and critical information.")
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
            exampleLabel("Standard Alert");
            sectionDesc("A centered modal overlay that requires user interaction to dismiss.");

            PreviewCard().children({
                AlertExample.render();
            });

            CodeBox(&hl_alert, "Alert");

            // API Reference
            Text("API Reference").font(24, 600, Theme.text).fontFamily("IBM Plex Mono,monospace").margin(.{ .top = 48 }).end();

            exampleLabel("Initialization");
            sectionDesc("Alerts are initialized with a function pointer that defines the internal layout.");
            Row()
                .width(.percent(100))
                .padding(.all(16))
                .background(Theme.code_bg)
                .border(.round(Theme.border, .all(8)))
                .children({
                Text("alert = Alert.init(myContentFn);")
                    .font(14, 400, .hex("#e4e4e7"))
                    .fontFamily("IBM Plex Mono,monospace")
                    .end();
            });
        });
    });
}
