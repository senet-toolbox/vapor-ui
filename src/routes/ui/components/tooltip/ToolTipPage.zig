// page.zig
const std = @import("std");
const Vapor = @import("vapor");
const Hero = @import("../../../../components/Hero.zig").Hero;
const Text = Vapor.Text;
const Row = Vapor.Row;
const Stack = Vapor.Stack;
const Opaque = @import("opaque-ui");
const Select = Opaque.Select;
const Vaporize = @import("vaporize");
const SyntaxHighlighter = Vaporize.SyntaxHighlighter;
const Tooltip = Opaque.Tooltip;
const Icon = Vapor.Icon;
const CodeBox = @import("../CodeBox.zig").CodeBox;
// Rendered and shown as code: what you read is what runs.
const TooltipCustomTrigger = @import("examples/TooltipCustomTrigger.zig");
const TooltipCustom = @import("examples/TooltipCustom.zig");

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
var hl_custom_tooltip: SyntaxHighlighter = undefined;
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
    hl_basic.parse("Tooltip.simple(\"Hover Me\",\"This is a tooltip\")") catch unreachable;

    hl_custom_tooltip = SyntaxHighlighter.init(allocator);
    hl_custom_tooltip.show_toolbar = true;
    hl_custom_tooltip.parse(@embedFile("examples/TooltipCustomTrigger.zig")) catch unreachable;

    hl_grouped = SyntaxHighlighter.init(allocator);
    hl_grouped.show_toolbar = true;
    hl_grouped.parse(@embedFile("examples/TooltipCustom.zig")) catch unreachable;

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
// RENDER
// ============================================================================

pub fn render() void {
    Row()
        .width(.percent(100))
        .layout(.top_center)
        .direction(.column)
        .children({

        // Hero
        Hero("tooltip-ui", "A collection of ready-to-use tooltip components built on top of Vapor, copy and paste into your apps.");

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
            sectionDesc("A simple tooltip with a Title and Content.");
            PreviewCard().children({
                Tooltip.simple("Hover Me", "This is a tooltip");
            });
            CodeBox(&hl_basic, "BasicTooltip");

            // ============================================================
            // WITH ICONS
            // ============================================================
            exampleLabel("With a Custom Trigger");
            sectionDesc("Tooltips can be triggered by a custom component.");
            PreviewCard().children({
                TooltipCustomTrigger.render();
            });
            CodeBox(&hl_custom_tooltip, "TooltipTrigger");

            // ============================================================
            // GROUPED
            // ============================================================
            exampleLabel("Custom Content and Custom Trigger");
            sectionDesc("A Tooltip can have custom content and a custom trigger.");
            PreviewCard().children({
                TooltipCustom.render();
            });
            CodeBox(&hl_grouped, "TooltipContent");

            // ============================================================
            // API REFERENCE
            // ============================================================
            sectionTitle("API Reference");

            exampleLabel("Setup");
            sectionDesc("Render the tooltip layer once, in your layout; every tooltip shows there.");
            apiSnippet(
                \\Opaque.TooltipLayer();
            );

            exampleLabel("Tooltip.simple");
            sectionDesc("A text trigger with a text tooltip above it.");
            apiSnippet(
                \\Tooltip.simple(trigger_text, tooltip_text);
                \\Tooltip.simpleWithPosition(trigger_text, tooltip_text, .bottom);
            );

            exampleLabel("Tooltip.create");
            sectionDesc("Your own trigger, and optionally your own content.");
            apiSnippet(
                \\Tooltip.create(.{ .content = "Text", .position = .top })
                \\    .Trigger(myTrigger, .{args})
                \\    .Component(myContent, .{args}) // optional
                \\    .end();
            );

            exampleLabel("Behaviour");
            sectionDesc("Shows after a short hover or on keyboard focus; hides on leave, blur or Escape. The popup has role=tooltip.");
        });
    });
}

fn apiSnippet(code: []const u8) void {
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
            .whiteSpace(.pre)
            .end();
    });
}
