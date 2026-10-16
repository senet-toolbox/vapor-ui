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
const CodeBox = @import("../CodeBox.zig").CodeBox;
// Rendered and shown as code: what you read is what runs.
const BasicSelect = @import("examples/BasicSelect.zig");
const WithIcons = @import("examples/WithIcons.zig");
const Grouped = @import("examples/Grouped.zig");
const CustomTrigger = @import("examples/CustomTrigger.zig");
const Detached = @import("examples/Detached.zig");

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
var hl_with_icons: SyntaxHighlighter = undefined;
var hl_grouped: SyntaxHighlighter = undefined;
var hl_custom_trigger: SyntaxHighlighter = undefined;
var hl_detached: SyntaxHighlighter = undefined;

// ============================================================================
// INIT
// ============================================================================

pub fn init() void {
    const allocator = Vapor.arena(.persist);

    // Initialize syntax highlighters
    hl_basic = SyntaxHighlighter.init(allocator);
    hl_basic.show_toolbar = true;
    hl_basic.parse(@embedFile("examples/BasicSelect.zig")) catch unreachable;

    hl_with_icons = SyntaxHighlighter.init(allocator);
    hl_basic.show_toolbar = true;
    hl_with_icons.parse(@embedFile("examples/WithIcons.zig")) catch unreachable;

    hl_grouped = SyntaxHighlighter.init(allocator);
    hl_basic.show_toolbar = true;
    hl_grouped.parse(@embedFile("examples/Grouped.zig")) catch unreachable;

    hl_custom_trigger = SyntaxHighlighter.init(allocator);
    hl_basic.show_toolbar = true;
    hl_custom_trigger.parse(@embedFile("examples/CustomTrigger.zig")) catch unreachable;

    hl_detached = SyntaxHighlighter.init(allocator);
    hl_basic.show_toolbar = true;
    hl_detached.parse(@embedFile("examples/Detached.zig")) catch unreachable;

    BasicSelect.init();
    WithIcons.init();
    Grouped.init();
    CustomTrigger.init();
    Detached.init();

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
        .size(.hw(.mobileDesktop(.fit, .px(512)), .mobileDesktopPercent(100, 100)))
        .border(.thin(.palette(.text_color)))
        .children({
        highlighter.render() catch unreachable;
    });
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
            Text("select-ui ⇒").style(&.{
                .visual = .font(12, 500, .hex("#6f6f6f")),
                .font_family = "IBM Plex Mono,monospace",
            }).end();
            Text("select-ui")
                .font(72, 700, .palette(.text_color))
                .end();
            Text("A collection of ready-to-use select components built on top of Vapor, copy and paste into your apps.")
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
            sectionDesc("A simple select with a flat list of items.");
            PreviewCard().children({
                BasicSelect.render();
            });
            CodeBox(&hl_basic, "BasicSelect");

            // ============================================================
            // WITH ICONS
            // ============================================================
            exampleLabel("With Icons");
            sectionDesc("Items can include icons for visual clarity.");
            PreviewCard().children({
                WithIcons.render();
            });
            CodeBox(&hl_with_icons, "WithIcons");

            // ============================================================
            // GROUPED
            // ============================================================
            exampleLabel("Grouped");
            sectionDesc("Organize items into labeled groups using .init() with Group structs.");
            PreviewCard().children({
                Grouped.render();
            });
            CodeBox(&hl_grouped, "Grouped");

            // ============================================================
            // CUSTOM TRIGGER
            // ============================================================
            exampleLabel("Custom Trigger");
            sectionDesc("Replace the default trigger button with a custom component.");
            PreviewCard().children({
                CustomTrigger.render();
            });
            CodeBox(&hl_custom_trigger, "CustomTrigger");

            // ============================================================
            // DETACHED
            // ============================================================
            exampleLabel("Detached");
            sectionDesc("Render the trigger and dropdown separately for custom layouts.");
            PreviewCard().children({
                Detached.render();
            });
            CodeBox(&hl_detached, "Detached");

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
                    \\var select = Select(MyEnum).fromItems(&.{ ... });
                    \\
                    \\// Grouped list
                    \\var select = Select(MyEnum).init("Placeholder", &.{
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
                    \\select.trigger = "Placeholder text";      // Custom placeholder
                    \\select.trigger_component = myFn;          // Custom trigger component
                    \\select.on_select = handleSelect;          // Selection callback
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
                    \\select.render();          // Render trigger + dropdown together
                    \\select.renderTrigger();   // Render trigger only
                    \\select.renderSelect();    // Render dropdown only
                )
                    .font(14, 400, .hex("#e4e4e7"))
                    .fontFamily("IBM Plex Mono,monospace")
                    .end();
            });

            exampleLabel("Callback Signature");
            sectionDesc("The on_select callback receives the select instance and selected item.");
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
