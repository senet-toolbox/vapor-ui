// page.zig
const std = @import("std");
const Vapor = @import("vapor");
const Text = Vapor.Text;
const Row = Vapor.Row;
const Stack = Vapor.Stack;
const Opaque = @import("opaque-ui");
const Checkbox = @import("opaque-ui").Checkbox;
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
var hl_custom_checkbox: SyntaxHighlighter = undefined;
var hl_grouped: SyntaxHighlighter = undefined;
var hl_detached: SyntaxHighlighter = undefined;

// ============================================================================
// INIT
// ============================================================================

pub fn init() void {
    const allocator = Vapor.arena(.persist);

    // Initialize syntax highlighters
    hl_basic = SyntaxHighlighter.init(allocator);
    hl_basic.show_toolbar = true;
    hl_basic.parse("Checkbox.render(\"test-checkbox\", checkboxToggle, .{})") catch unreachable;

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
            Text("checkbox-ui ⇒").style(&.{
                .visual = .font(12, 500, .hex("#6f6f6f")),
                .font_family = "IBM Plex Mono,monospace",
            }).end();
            Text("checkbox-ui")
                .font(72, 700, .palette(.text_color))
                .end();
            Text("A collection of ready-to-use checkbox components built on top of Vapor, copy and paste into your apps.")
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
            // BASIC
            // ============================================================
            exampleLabel("Basic");
            sectionDesc("A simple checkbox with a Title and Content.");
            PreviewCard().children({
                Checkbox.render("test-checkbox", checkboxToggle, .{});
            });
            CodeBlock(&hl_basic);

            exampleLabel("Custom");
            sectionDesc("A custom checkbox with a Title and Content.");
            PreviewCard().children({
                Checkbox.create("custom-v1-checkbox", customCheckboxToggle, .{})
                    .ariaLabel("Sound")
                    .background(if (custom) .palette(.danger) else .palette(.background))
                    .children({
                    Vapor.Icon(.soundwave)
                        .font(16, 300, if (custom) .white else .palette(.text_color))
                        .end();
                });
            });
            CodeBlock(&hl_basic);

            // ============================================================
            // API REFERENCE
            // ============================================================
            sectionTitle("API Reference");

            exampleLabel("Checkbox.render");
            sectionDesc("A ready-made checkbox; each one keeps its own checked state.");
            apiSnippet(
                \\Checkbox.render(aria_label: []const u8, on_change, args)
            );

            exampleLabel("Checkbox.create");
            sectionDesc("Your own look: a button builder you style and fill. The callback also gets the new state.");
            apiSnippet(
                \\Checkbox.create(id: []const u8, on_change, args)
                \\    .ariaLabel("Sound")
                \\    .children({ ... });
                \\
                \\fn onChange(active: bool) void { ... }
            );

            exampleLabel("Accessibility");
            sectionDesc("Both have role=checkbox and report aria-checked.");
        });
    });
}

fn apiSnippet(code: []const u8) void {
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
