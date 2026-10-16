const std = @import("std");
const Vapor = @import("vapor");
const Text = Vapor.Text;
const Row = Vapor.Row;
const Stack = Vapor.Stack;
const Opaque = @import("opaque-ui");
const Field = Opaque.Field;
const Vaporize = @import("vaporize");
const SyntaxHighlighter = Vaporize.SyntaxHighlighter;

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

var hl_basic: SyntaxHighlighter = undefined;
var hl_custom_render: SyntaxHighlighter = undefined;

var text: []const u8 = "";
var email: []const u8 = "";
var password: []const u8 = "";
var phonenumber: []const u8 = "";
var cardnumber: []const u8 = "";

// ============================================================================
// INIT
// ============================================================================

pub fn init() void {
    Vapor.Page(.{ .src = @src() }, render, null);
}

// ============================================================================
// UI COMPONENTS
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
        .height(.px(160))
        .padding(.all(24))
        .direction(.column)
        .layout(.center)
        .spacing(16);
}

fn CodeBlock(highlighter: *SyntaxHighlighter) void {
    Row()
        .scroll(.scroll_y())
        .size(.hw(.mobile_desktop(.fit, .px(512)), .mobile_desktop_percent(100, 100)))
        .border(.simple(.palette(.text_color)))
        .children({
        highlighter.render() catch unreachable;
    });
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
        Vapor.Stack()
            .layout(.center)
            .height(.px(512))
            .width(.percent(100))
            .children({
            Text("field-ui ⇒").style(&.{
                .visual = .font(12, 500, .hex("#6f6f6f")),
                .font_family = "IBM Plex Mono,monospace",
            }).end();
            Text("field-ui")
                .font(72, 700, .palette(.text_color))
                .end();
            Text("A collection of ready-to-use field components built on top of Vapor, copy and paste into your apps.")
                .font(16, 300, .palette(.text_color))
                .end();
        });

        // Content
        Stack()
            .width(.percent(50))
            .height(.percent(100))
            .spacing(12)
            .padding(.bottom(120))
            .children({

            // ============================================================
            // BASIC
            // ============================================================
            exampleLabel("Basic");
            sectionDesc("A simple field with the default string type.");
            PreviewCard().children({
                Field.render(.{ .label = "Default", .value = .{ .string = &text } });
            });
            // CodeBlock(&hl_basic);

            // ============================================================
            // BASIC
            // ============================================================
            exampleLabel("Email and Password");
            sectionDesc("A Email and Password field with specific field types.");
            PreviewCard().children({
                Field.render(.{ .label = "Email", .value = .{ .email = &email } });
                Field.render(.{ .label = "Password", .value = .{ .password = &password } });
            });

            // Field.render(.{ .label = "Password", .value = .{ .password = &password }, .trans_label = true });
            // Field.render(.{ .label = "Phone Number", .value = .{ .number = &phonenumber }, .trans_label = true });
            // Field.render(.{ .label = "Card Number", .value = .{ .number = &cardnumber }, .trans_label = true });
            // Field.render(.{ .label = "Card Number", .value = .{ .number = &cardnumber }, .trans_label = true });
        });
    });
}
