// page.zig
const std = @import("std");
const Vapor = @import("vapor");
const Text = Vapor.Text;
const Row = Vapor.Row;
const Stack = Vapor.Stack;
const Vaporize = @import("vaporize");
const SyntaxHighlighter = Vaporize.SyntaxHighlighter;
const BasicRadio = @import("examples/BasicRadio.zig");

// ============================================================================
// THEME
// ============================================================================

const Theme = struct {
    const text = Vapor.Types.Color.palette(.text_color);
    const text_muted = Vapor.Types.Color.hex("#71717a");
    const border = Vapor.Types.Color.palette(.border_color_light);
    const code_bg = Vapor.Types.Color.hex("#1a1a1a");
};

var hl_basic: SyntaxHighlighter = undefined;

pub fn init() void {
    hl_basic = SyntaxHighlighter.init(Vapor.arena(.persist));
    hl_basic.show_toolbar = true;
    hl_basic.parse(@embedFile("examples/BasicRadio.zig")) catch unreachable;

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

fn checkboxToggle() void {
    Vapor.alert("Checkbox Toggled", .{});
}

var custom: bool = false;
fn customCheckboxToggle(active: bool) void {
    custom = active;
}

// ============================================================================
// RENDER
// ============================================================================

fn codeSnippet(code: []const u8) void {
    Row()
        .width(.percent(100))
        .padding(.all(16))
        .background(Theme.code_bg)
        .border(.round(Theme.border, .all(8)))
        .children({
        Text(code)
            .font(14, 400, .hex("#e4e4e7"))
            .fontFamily("IBM Plex Mono,monospace")
            .whiteSpace(.pre)
            .end();
    });
}

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
            Text("radio-ui ⇒").style(&.{
                .visual = .font(12, 500, .hex("#6f6f6f")),
                .font_family = "IBM Plex Mono,monospace",
            }).end();
            Text("radio-ui")
                .font(72, 700, .palette(.text_color))
                .end();
            Text("Radio buttons for picking one option out of a group, with keyboard and screen reader support.")
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
            exampleLabel("Basic");
            sectionDesc("A group starts on its default value and reports each change.");
            PreviewCard().height(.fit).children({
                BasicRadio.render();
            });
            CodeBlock(&hl_basic);

            sectionTitle("API Reference");

            exampleLabel("Radio.Group");
            sectionDesc("Groups the items; the name labels the group for screen readers.");
            codeSnippet(
                \\Radio.Group(name: []const u8, default_value: []const u8, on_change, args)
            );

            exampleLabel("Radio.Item");
            sectionDesc("One choice. Call it inside the group's children.");
            codeSnippet(
                \\Radio.Item(value: []const u8, label: []const u8)
            );

            exampleLabel("Callback Signature");
            sectionDesc("Called with the group's args followed by the chosen value, only when the choice changes.");
            codeSnippet(
                \\fn onChange(value: []const u8) void { ... }
            );
        });
    });
}
