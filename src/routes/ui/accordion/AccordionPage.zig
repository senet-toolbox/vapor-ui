// page.zig
const std = @import("std");
const Vapor = @import("vapor");
const Text = Vapor.Text;
const Row = Vapor.Row;
const Stack = Vapor.Stack;
const Opaque = @import("opaque-ui");
const Accordion = Opaque.Accordion;
const Vaporize = @import("vaporize");
const SyntaxHighlighter = Vaporize.SyntaxHighlighter;
const Icon = Vapor.Icon;
const Button = Opaque.Button;
const CodeBox = @import("../CodeBox.zig").CodeBox;
// The page shows these files' code and renders them, so the code you read
// is the code that runs.
const BasicAccordion = @import("examples/BasicAccordion.zig");
const CustomAccordion = @import("examples/CustomAccordion.zig");

// ============================================================================
// THEME
// ============================================================================

const Theme = struct {
    const text = Vapor.Types.Color.palette(.text_color);
    const text_muted = Vapor.Types.Color.hex("#71717a");
    const border = Vapor.Types.Color.palette(.border_color_light);
    const code_bg = Vapor.Types.Color.hex("#1a1a1a");
    const warning = Vapor.Types.Color.hex("#F5590B");
};

// ============================================================================
// SYNTAX HIGHLIGHTERS
// ============================================================================

var hl_basic: SyntaxHighlighter = undefined;
var hl_custom_render: SyntaxHighlighter = undefined;
var hl_api: SyntaxHighlighter = undefined;

pub fn init() void {
    const allocator = Vapor.arena(.persist);

    // Initialize syntax highlighters
    hl_basic = SyntaxHighlighter.init(allocator);
    hl_basic.show_toolbar = true;
    hl_basic.parse(@embedFile("examples/BasicAccordion.zig")) catch unreachable;

    hl_custom_render = SyntaxHighlighter.init(allocator);
    hl_custom_render.show_toolbar = true;
    hl_custom_render.parse(@embedFile("examples/CustomAccordion.zig")) catch unreachable;

    Vapor.Page(.{ .src = @src() }, render, null);
}

// ============================================================================
// UI HELPERS
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
        .padding(.all(24))
        .direction(.column)
        .spacing(16);
}

// ============================================================================
// MAIN RENDER
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
            Text("accordion-ui ⇒").style(&.{
                .visual = .font(12, 500, .hex("#6f6f6f")),
                .font_family = "IBM Plex Mono,monospace",
            }).end();
            Text("accordion-ui")
                .font(72, 700, .palette(.text_color))
                .end();
            Text("Highly customizable, accessible collapsible sections for organizing content.")
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

            // Basic
            exampleLabel("Basic Accordion");
            sectionDesc("Standard list of collapsible items using default typography.");
            PreviewCard().children({
                BasicAccordion.render();
            });
            CodeBox(&hl_basic, "BasicAccordion");

            // Custom
            exampleLabel("Custom Rendering");
            sectionDesc("Using function pointers to override how headers and content panels are rendered.");
            PreviewCard().children({
                CustomAccordion.render();
            });
            CodeBox(&hl_custom_render, "CustomAccordion");

            // API Reference
            sectionTitle("API Reference");

            exampleLabel("Item Structure");
            sectionDesc("Define the data and render functions for each panel.");
            Row()
                .width(.percent(100))
                .padding(.all(16))
                .background(Theme.code_bg)
                .border(.round(Theme.border, .all(8)))
                .children({
                Text(
                    \\.{
                    \\  .title = "Label",
                    \\  .description = "Extended text content...",
                    \\  .trigger = MyHeaderFn,
                    \\  .content = MyBodyFn
                    \\}
                )
                    .font(14, 400, .hex("#e4e4e7"))
                    .fontFamily("IBM Plex Mono,monospace")
                    .end();
            });

            exampleLabel("Initialization");
            sectionDesc("Pass a slice of AccordionItem structs to the init method.");
            Row()
                .width(.percent(100))
                .padding(.all(16))
                .background(Theme.code_bg)
                .border(.round(Theme.border, .all(8)))
                .children({
                Text("var accordion = Accordion.init(&.{ item1, item2 });")
                    .font(14, 400, .hex("#e4e4e7"))
                    .fontFamily("IBM Plex Mono,monospace")
                    .end();
            });

            exampleLabel("Render Functions");
            sectionDesc("Your custom functions receive a pointer to the current item.");
            Row()
                .width(.percent(100))
                .padding(.all(16))
                .background(Theme.code_bg)
                .border(.round(Theme.border, .all(8)))
                .children({
                Text("fn MyTrigger(item: *Accordion.AccordionItem) void { ... }")
                    .font(14, 400, .hex("#e4e4e7"))
                    .fontFamily("IBM Plex Mono,monospace")
                    .end();
            });
        });
    });
}
