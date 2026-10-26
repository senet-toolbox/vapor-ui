const std = @import("std");
const Vapor = @import("vapor");
const Hero = @import("../../../../components/Hero.zig").Hero;
const Text = Vapor.Text;
const Row = Vapor.Row;
const Stack = Vapor.Stack;
const Icon = Vapor.Icon;
const Opaque = @import("opaque-ui");
const Button = Opaque.Button;
const ComboBox = Opaque.ComboBox;
// Rendered and shown as code: what you read is what runs.
const BasicComboBox = @import("examples/BasicComboBox.zig");
const Vaporize = @import("vaporize");
const SyntaxHighlighter = Vaporize.SyntaxHighlighter;
const CodeBox = @import("../CodeBox.zig").CodeBox;

// ============================================================================
// THEME
// ============================================================================

const Theme = struct {
    const bg = Vapor.Types.Color.palette(.background);
    const text = Vapor.Types.Color.palette(.text_color);
    const text_muted = Vapor.Types.Color.hex("#71717a");
    const border = Vapor.Types.Color.palette(.border_color_light);
    const code_bg = Vapor.Types.Color.hex("#1a1a1a");
};

// ============================================================================
// CODE SNIPPET COMPONENT
// ============================================================================

fn code_snippet(code: []const u8) void {
    Row()
        .width(.percent(100))
        .padding(.all(16))
        .background(Theme.code_bg)
        .scroll(.scrollX())
        .border(.round(Theme.border, .all(8)))
        .children({
        Text(code)
            .font(14, 400, .hex("#e4e4e7"))
            .fontFamily("IBM Plex Mono,monospace")
            .end();
    });
}

fn section_title(title: []const u8) void {
    Text(title)
        .font(24, 600, Theme.text)
        .fontFamily("IBM Plex Mono,monospace")
        .margin(.{ .top = 32 })
        .end();
}

fn section_description(desc: []const u8) void {
    Text(desc)
        .font(14, 400, Theme.text_muted)
        .fontFamily("IBM Plex Mono,monospace")
        .margin(.{ .bottom = 16 })
        .end();
}

// ============================================================================
// MAIN RENDER
// ============================================================================

var hl_basic: SyntaxHighlighter = undefined;
pub fn init() void {
    const allocator = Vapor.arena(.persist);

    // Initialize syntax highlighters
    hl_basic = SyntaxHighlighter.init(allocator);
    hl_basic.show_toolbar = true;
    hl_basic.show_cpy_btn = true;
    hl_basic.parse(@embedFile("examples/BasicComboBox.zig")) catch unreachable;

    BasicComboBox.init();

    Vapor.Page(.{ .src = @src() }, render, null);
}

fn Card() Vapor.Builder(.pure) {
    return Stack()
        .background(.transparentize(.palette(.background), 0.5))
        .border(.round(.palette(.border_color_light), .all(12)))
        .width(.percent(100))
        .height(.px(160))
        .padding(.all(24))
        .direction(.column)
        .layout(.center)
        .spacing(16);
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
    return Stack()
        .background(.transparentize(.palette(.background), 0.5))
        .border(.round(.palette(.border_color_light), .all(12)))
        .width(.percent(100))
        .height(.px(160))
        .padding(.all(24))
        .direction(.column)
        .layout(.center)
        .spacing(16);
}

// ============================================================================
// TEXT FIELD INSTANCES
// ============================================================================

fn render() void {
    Row()
        .width(.percent(100))
        .layout(.top_center)
        .direction(.column)
        .children({

        // Hero
        Hero("combobox-ui", "A collection of ready-to-use combobox components built on top of Vapor, copy and paste into your apps.");

        // Content
        Stack()
            .width(.percent(50))
            .responsive(.mobile, .{ .size = .w(.percent(92)) })
            .height(.percent(100))
            .spacing(12)
            .padding(.{ .bottom = 120 })
            .children({

            // ============================================================
            // BASIC
            // ============================================================
            exampleLabel("Basic");
            sectionDesc("Pick any number of options; type to filter them.");
            PreviewCard().children({
                BasicComboBox.render();
            });
            CodeBox(&hl_basic, "BasicComboBox");
        });
    });
}
