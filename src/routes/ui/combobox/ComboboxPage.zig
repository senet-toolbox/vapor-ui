const std = @import("std");
const Vapor = @import("vapor");
const Text = Vapor.Text;
const Row = Vapor.Row;
const Stack = Vapor.Stack;
const Icon = Vapor.Icon;
const Opaque = @import("opaque-ui");
const Button = Opaque.Button;
const ComboBox = Opaque.ComboBox;
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
        .margin(.t(32))
        .end();
}

fn section_description(desc: []const u8) void {
    Text(desc)
        .font(14, 400, Theme.text_muted)
        .fontFamily("IBM Plex Mono,monospace")
        .margin(.b(16))
        .end();
}

// ============================================================================
// MAIN RENDER
// ============================================================================

const Status = enum {
    pending,
    success,
    err,
};

var combobox: ComboBox(Status) = undefined;
var hl_basic: SyntaxHighlighter = undefined;
pub fn init() void {
    const allocator = Vapor.arena(.persist);

    // Initialize syntax highlighters
    hl_basic = SyntaxHighlighter.init(allocator);
    hl_basic.show_toolbar = true;
    hl_basic.show_cpy_btn = true;
    hl_basic.parse(@embedFile("examples/BasicComboBox.zig")) catch unreachable;

    combobox = .fromItems(&.{
        .{ .value = Status.pending, .label = "Pending" },
        .{ .value = Status.success, .label = "Success" },
        .{ .value = Status.err, .label = "Error" },
    });
    combobox.trigger = "Status";

    Vapor.Page(.{ .src = @src() }, render, null);
}

fn Card() Vapor.Builder(.pure) {
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
            Text("combobox-ui ⇒").style(&.{
                .visual = .font(12, 500, .hex("#6f6f6f")),
                .font_family = "IBM Plex Mono,monospace",
            }).end();
            Text("combobox-ui")
                .font(72, 700, .palette(.text_color))
                .end();
            Text("A collection of ready-to-use combobox components built on top of Vapor, copy and paste into your apps.")
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
            sectionDesc("A simple combobox with the default string type.");
            PreviewCard().children({
                combobox.render();
            });
            CodeBox(&hl_basic, "BasicComboBox");

            // ============================================================
            // BASIC
            // ============================================================
            exampleLabel("Email and Password");
            sectionDesc("A Email and Password combobox with specific combobox types.");
            PreviewCard().children({});

            // Field.render(.{ .label = "Password", .value = .{ .password = &password }, .trans_label = true });
            // Field.render(.{ .label = "Phone Number", .value = .{ .number = &phonenumber }, .trans_label = true });
            // Field.render(.{ .label = "Card Number", .value = .{ .number = &cardnumber }, .trans_label = true });
            // Field.render(.{ .label = "Card Number", .value = .{ .number = &cardnumber }, .trans_label = true });
        });
    });
}
