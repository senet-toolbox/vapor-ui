const std = @import("std");
const Vapor = @import("vapor");
const Hero = @import("../../../../components/Hero.zig").Hero;
const Text = Vapor.Text;
const Row = Vapor.Row;
const Stack = Vapor.Stack;
const Opaque = @import("opaque-ui");
const Docs = @import("../Docs.zig");
const CodeBox = @import("../CodeBox.zig").CodeBox;
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
    hl_api = Docs.highlighter(
        \\const Field = @import("opaque-ui").Field;
        \\
        \\// Draws a labelled field bound to your variable.
        \\pub fn render(field: Field) void
        \\
        \\// The same, kept between renders, so callbacks can take arguments.
        \\pub fn create(field: Field) *Field
        \\pub fn onChange(field: *Field, callback: anytype, args: anytype) *Field
        \\
        \\var email: []const u8 = "";
        \\Field.render(.{ .label = "Email", .value = .{ .email = &email } });
    );
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
        Hero("field-ui", "A collection of ready-to-use field components built on top of Vapor, copy and paste into your apps.");

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

            Docs.sectionTitle("API Reference");

            Docs.exampleLabel("Field");
            Docs.sectionDesc("Render it every frame with a pointer to your variable.");
            CodeBox(&hl_api, "Field");

            Docs.exampleLabel("Fields");
            Docs.ApiBox("Field", &fields);

            Docs.exampleLabel("Behaviour");
            Docs.sectionDesc("What the field does for you.");
            Docs.ApiBox("Behaviour", &behaviours);
        });
    });
}

var hl_api: SyntaxHighlighter = undefined;

const fields = [_]Docs.Field{
    .{ .name = "label", .type = "?[]const u8", .default = "null", .desc = "Names the field. It sits inside until the field has focus or a value, then rises to the top edge." },
    .{ .name = "value", .type = "?Value", .default = "null", .desc = "A pointer to your variable, by kind: .string, .password, .email, .telephone, .credit_card, .number, .float, .bool or .date. It must stay put: a global, not a local." },
    .{ .name = "placeholder", .type = "?DefaultValue", .default = "null", .desc = "Shown while it's empty: .{ .string = \"you@example.com\" }, or .number." },
    .{ .name = "trans_label", .type = "bool", .default = "false", .desc = "Keeps the label at the top edge always." },
    .{ .name = "on_change", .type = "?*const fn (evt: *Vapor.Event) void", .default = "null", .desc = "Called as the value changes, after your variable is updated." },
    .{ .name = "on_enter", .type = "?*const fn (evt: *Vapor.Event) void", .default = "null", .desc = "Called when Enter is pressed in it." },
    .{ .name = "on_focus", .type = "?*const fn (evt: *Vapor.Event) void", .default = "null", .desc = "Called when it gains focus." },
    .{ .name = "on_blur", .type = "?*const fn (evt: *Vapor.Event) void", .default = "null", .desc = "Called when it loses focus." },
    .{ .name = "background", .type = "Color", .default = ".palette(.background)", .desc = "The field's background." },
    .{ .name = "text_color", .type = "Color", .default = ".palette(.text)", .desc = "The label's colour at rest." },
    .{ .name = "tint_color", .type = "Color", .default = ".palette(.tint)", .desc = "The label's colour while the field has focus." },
};

const behaviours = [_]Docs.Field{
    .{ .name = "Binding", .desc = "Typing writes straight into your variable; read it any time." },
    .{ .name = "Kinds", .desc = ".password hides what's typed; .credit_card and .telephone group the digits as they're typed; .number and .float take only numbers." },
    .{ .name = "Focus", .desc = "The border turns the tint colour and glows while it has focus." },
    .{ .name = "Screen readers", .desc = "The label is tied to the input, so it names it." },
};
