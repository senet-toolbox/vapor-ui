// page.zig
const std = @import("std");
const Vapor = @import("vapor");
const Text = Vapor.Text;
const Row = Vapor.Row;
const Stack = Vapor.Stack;
const Vaporize = @import("vaporize");
const SyntaxHighlighter = Vaporize.SyntaxHighlighter;
const CodeBox = @import("../CodeBox.zig").CodeBox;
// The page shows these files' code and renders them, so the code you read
// is the code that runs.
const BasicTabs = @import("examples/BasicTabs.zig");
const ControlledTabs = @import("examples/ControlledTabs.zig");
const CustomTabs = @import("examples/CustomTabs.zig");

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
var hl_controlled: SyntaxHighlighter = undefined;
var hl_custom: SyntaxHighlighter = undefined;

pub fn init() void {
    const allocator = Vapor.arena(.persist);

    hl_basic = SyntaxHighlighter.init(allocator);
    hl_basic.show_toolbar = true;
    hl_basic.parse(@embedFile("examples/BasicTabs.zig")) catch unreachable;

    hl_controlled = SyntaxHighlighter.init(allocator);
    hl_controlled.show_toolbar = true;
    hl_controlled.parse(@embedFile("examples/ControlledTabs.zig")) catch unreachable;

    hl_custom = SyntaxHighlighter.init(allocator);
    hl_custom.show_toolbar = true;
    hl_custom.parse(@embedFile("examples/CustomTabs.zig")) catch unreachable;

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

fn CodeLine(code: []const u8) void {
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
            Text("tabs-ui ⇒").style(&.{
                .visual = .font(12, 500, .hex("#6f6f6f")),
                .font_family = "IBM Plex Mono,monospace",
            }).end();
            Text("tabs-ui")
                .font(72, 700, .palette(.text_color))
                .end();
            Text("Accessible tabs that switch between panels, with arrow-key navigation and your own tab styles.")
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
            exampleLabel("Basic Tabs");
            sectionDesc("NavBar draws the tabs and returns the selected index; switch on it to show a panel.");
            PreviewCard().children({
                BasicTabs.render();
            });
            CodeBox(&hl_basic, "BasicTabs");

            // Controlled
            exampleLabel("Controlled Tabs");
            sectionDesc("Keep the selected tab in your own state with default and onClick, e.g. to remember it.");
            PreviewCard().children({
                ControlledTabs.render();
            });
            CodeBox(&hl_controlled, "ControlledTabs");

            // Custom
            exampleLabel("Custom Triggers");
            sectionDesc("Trigger keeps selection, keyboard and roles, and calls your function to draw each tab.");
            PreviewCard().children({
                CustomTabs.render();
            });
            CodeBox(&hl_custom, "CustomTabs");

            // API Reference
            sectionTitle("API Reference");

            exampleLabel("NavBar");
            sectionDesc("The tabs keep their state under the tag, so the selection survives rerenders.");
            CodeLine("const index = Tabs.NavBar(\"tag\", &.{ \"One\", \"Two\" });");

            exampleLabel("create");
            sectionDesc("Returns the Tabs for the tag, to configure before rendering.");
            CodeLine("const index = Tabs.create(\"tag\", names).default(selected).onClick(onTab).render();");

            exampleLabel("Trigger");
            sectionDesc("Renders each tab with your function; active is true for the selected one.");
            CodeLine("fn TabTrigger(tabs: *Tabs, name: []const u8, active: bool) void { ... }");

            exampleLabel("Keyboard");
            sectionDesc("Left and Right move between tabs, Home and End jump to the first and last.");
        });
    });
}
