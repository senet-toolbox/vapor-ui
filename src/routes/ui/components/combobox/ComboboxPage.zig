const std = @import("std");
const Vapor = @import("vapor");
const Hero = @import("../../../../components/Hero.zig").Hero;
const Text = Vapor.Text;
const Row = Vapor.Row;
const Stack = Vapor.Stack;
const Icon = Vapor.Icon;
const Opaque = @import("opaque-ui");
const Button = Opaque.Button;
const ComboBox = Opaque.ComboBox;
// Rendered and shown as code: what you read is what runs.
const BasicComboBox = @import("examples/BasicComboBox.zig");
const Vaporize = @import("vaporize");
const SyntaxHighlighter = Vaporize.SyntaxHighlighter;
const CodeBox = @import("../CodeBox.zig").CodeBox;
const Docs = @import("../Docs.zig");

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
        .scroll(.scrollX())
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
        .margin(.{ .top = 32 })
        .end();
}

fn section_description(desc: []const u8) void {
    Text(desc)
        .font(14, 400, Theme.text_muted)
        .fontFamily("IBM Plex Mono,monospace")
        .margin(.{ .bottom = 16 })
        .end();
}

// ============================================================================
// MAIN RENDER
// ============================================================================

var hl_basic: SyntaxHighlighter = undefined;
pub fn init() void {
    hl_api = Docs.highlighter(
        \\const ComboBox = @import("opaque-ui").ComboBox;
        \\
        \\// One list of options, or titled groups of them.
        \\pub fn fromItems(items: []const Item) ComboBox(T)
        \\pub fn init(trigger: []const u8, groups: []const Group) ComboBox(T)
        \\
        \\// Draws the trigger, and the list while it's open.
        \\pub fn render(combobox: *ComboBox(T)) void
        \\pub fn toggle(combobox: *ComboBox(T)) void
        \\pub fn close(combobox: *ComboBox(T)) void
        \\
        \\// A group: an optional title over its items.
        \\pub const Group = struct { title: ?[]const u8 = null, items: []Item };
    );
    const allocator = Vapor.arena(.persist);

    // Initialize syntax highlighters
    hl_basic = SyntaxHighlighter.init(allocator);
    hl_basic.show_toolbar = true;
    hl_basic.show_cpy_btn = true;
    hl_basic.parse(@embedFile("examples/BasicComboBox.zig")) catch unreachable;

    BasicComboBox.init();

    Vapor.Page(.{ .src = @src() }, render, null);
}

fn Card() Vapor.Builder(.pure) {
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
        Hero("combobox-ui", "A collection of ready-to-use combobox components built on top of Vapor, copy and paste into your apps.");

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
            sectionDesc("Pick any number of options; type to filter them.");
            PreviewCard().children({
                BasicComboBox.render();
            });
            CodeBox(&hl_basic, "BasicComboBox");

            Docs.sectionTitle("API Reference");

            Docs.exampleLabel("ComboBox(T)");
            Docs.sectionDesc("T is what each option stands for: an enum, an id, a struct.");
            CodeBox(&hl_api, "ComboBox");

            Docs.exampleLabel("Item");
            Docs.ApiBox("Item", &item_fields);

            Docs.exampleLabel("Fields");
            Docs.sectionDesc("Set after fromItems or init.");
            Docs.ApiBox("ComboBox(T)", &fields);

            Docs.exampleLabel("Behaviour");
            Docs.sectionDesc("What the combobox does for you.");
            Docs.ApiBox("Behaviour", &behaviours);
        });
    });
}

var hl_api: SyntaxHighlighter = undefined;

const item_fields = [_]Docs.Field{
    .{ .name = "value", .type = "T", .desc = "What the option stands for; on_select gets the item." },
    .{ .name = "label", .type = "[]const u8", .desc = "Its text, and what the search matches the start of, ignoring case." },
    .{ .name = "icon", .type = "?IconTokens", .default = "null", .desc = "Drawn before the label." },
    .{ .name = "is_selected", .type = "bool", .default = "false", .desc = "Whether it's ticked. Set it to start ticked; clicks flip it." },
};

const fields = [_]Docs.Field{
    .{ .name = "trigger", .type = "[]const u8", .default = "\"Search\"", .desc = "The trigger's text while nothing is ticked, and the list's name for screen readers. fromItems sets \"Search\"; init takes it." },
    .{ .name = "on_select", .type = "?*const fn (item: *Item) void", .default = "null", .desc = "Called with an option each time it's ticked or unticked." },
    .{ .name = "trigger_component", .type = "?*const fn (self: *Self) void", .default = "null", .desc = "Draws the trigger yourself, in place of the standard one." },
};

const behaviours = [_]Docs.Field{
    .{ .name = "Choosing", .desc = "A click ticks an option and another unticks it; any number can be ticked. The trigger then lists their labels." },
    .{ .name = "Searching", .desc = "Opening it puts the focus in its search box. Typing shows only the options whose label starts with what was typed; the cross clears it." },
    .{ .name = "Closing", .desc = "Escape, a click outside, or the trigger again." },
    .{ .name = "Keyboard", .desc = "Tab moves through the options; Enter or Space ticks one." },
    .{ .name = "Screen readers", .desc = "The trigger says it opens a listbox and whether it's open. The list is a listbox where several can be chosen, named by trigger; each option reports aria-selected." },
};
