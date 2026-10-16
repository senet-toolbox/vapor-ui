// page.zig
const std = @import("std");
const Vapor = @import("vapor");
const Text = Vapor.Text;
const Row = Vapor.Row;
const Stack = Vapor.Stack;
const Opaque = @import("opaque-ui");
const Select = Opaque.Select;
const Vaporize = @import("vaporize");
const SyntaxHighlighter = Vaporize.SyntaxHighlighter;
const Slider = Opaque.Slider;
const CodeBox = @import("../CodeBox.zig").CodeBox;

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
var hl_custom_switch: SyntaxHighlighter = undefined;
var hl_grouped: SyntaxHighlighter = undefined;
var hl_detached: SyntaxHighlighter = undefined;

// ============================================================================
// SELECT INSTANCES
// ============================================================================

// ============================================================================
// INIT
// ============================================================================

pub fn init() void {
    const allocator = Vapor.arena(.persist);

    // Initialize syntax highlighters
    hl_basic = SyntaxHighlighter.init(allocator);
    hl_basic.show_toolbar = true;
    hl_basic.parse("Slider.render(\"test-switch\", switchToggle, .{})") catch unreachable;

    Vapor.Page(.{ .src = @src() }, render, null);
}

// ============================================================================
// HANDLERS
// ============================================================================

// ============================================================================
// CUSTOM TRIGGER COMPONENTS
// ============================================================================

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

fn switchToggle() void {
    Vapor.alert("Slider Toggled", .{});
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
            Text("switch-ui ⇒").style(&.{
                .visual = .font(12, 500, .hex("#6f6f6f")),
                .font_family = "IBM Plex Mono,monospace",
            }).end();
            Text("switch-ui")
                .font(72, 700, .palette(.text_color))
                .end();
            Text("A collection of ready-to-use switch components built on top of Vapor, copy and paste into your apps.")
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
            sectionDesc("A simple switch with a Title and Content.");
            PreviewCard().children({
                Row()
                    .width(.percent(70))
                    .direction(.column)
                    .children({
                    Slider.render(.{});
                });
            });
            CodeBox(&hl_basic, "BasicSlider");

            // ============================================================
            // API REFERENCE
            // ============================================================
            sectionTitle("API Reference");

            exampleLabel("Initialization");
            sectionDesc("Two ways to create a Select:");
            Row()
                .width(.percent(100))
                .padding(.all(16))
                .background(Theme.code_bg)
                .border(.round(Theme.border, .all(8)))
                .children({
                Text(
                    \\// Flat list
                    \\var switch = Select(MyEnum).fromItems(&.{ ... });
                    \\
                    \\// Grouped list
                    \\var switch = Select(MyEnum).init("Placeholder", &.{
                    \\    Select(MyEnum).Group{ .title = "Group", .items = &.{ ... } },
                    \\});
                )
                    .font(14, 400, .hex("#e4e4e7"))
                    .fontFamily("IBM Plex Mono,monospace")
                    .end();
            });

            exampleLabel("Item Structure");
            sectionDesc("Each item requires a value and label. Icon is optional.");
            Row()
                .width(.percent(100))
                .padding(.all(16))
                .background(Theme.code_bg)
                .border(.round(Theme.border, .all(8)))
                .children({
                Text(
                    \\.{ .value = MyEnum.option, .label = "Option Label", .icon = .icon_name }
                )
                    .font(14, 400, .hex("#e4e4e7"))
                    .fontFamily("IBM Plex Mono,monospace")
                    .end();
            });

            exampleLabel("Properties");
            sectionDesc("Configure behavior after initialization.");
            Row()
                .width(.percent(100))
                .padding(.all(16))
                .background(Theme.code_bg)
                .border(.round(Theme.border, .all(8)))
                .children({
                Text(
                    \\switch.trigger = "Placeholder text";      // Custom placeholder
                    \\switch.trigger_component = myFn;          // Custom trigger component
                    \\switch.on_switch = handleSelect;          // Selection callback
                )
                    .font(14, 400, .hex("#e4e4e7"))
                    .fontFamily("IBM Plex Mono,monospace")
                    .end();
            });

            exampleLabel("Render Methods");
            sectionDesc("Choose how to render the component.");
            Row()
                .width(.percent(100))
                .padding(.all(16))
                .background(Theme.code_bg)
                .border(.round(Theme.border, .all(8)))
                .children({
                Text(
                    \\switch.render();          // Render trigger + dropdown together
                    \\switch.renderTrigger();   // Render trigger only
                    \\switch.renderSelect();    // Render dropdown only
                )
                    .font(14, 400, .hex("#e4e4e7"))
                    .fontFamily("IBM Plex Mono,monospace")
                    .end();
            });

            exampleLabel("Callback Signature");
            sectionDesc("The on_switch callback receives the switch instance and switched item.");
            Row()
                .width(.percent(100))
                .padding(.all(16))
                .background(Theme.code_bg)
                .border(.round(Theme.border, .all(8)))
                .children({
                Text(
                    \\fn handleSelect(sel: *Select(MyEnum), item: *Select(MyEnum).Item) void {
                    \\    // item.value - the enum value
                    \\    // item.label - the display string
                    \\    // item.icon  - optional icon
                    \\}
                )
                    .font(14, 400, .hex("#e4e4e7"))
                    .fontFamily("IBM Plex Mono,monospace")
                    .end();
            });
        });
    });
}
