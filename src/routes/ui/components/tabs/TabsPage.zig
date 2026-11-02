const Vapor = @import("vapor");
const Hero = @import("../../../../components/Hero.zig").Hero;
const Row = Vapor.Row;
const SyntaxHighlighter = @import("vaporize").SyntaxHighlighter;
const CodeBox = @import("../CodeBox.zig").CodeBox;
const Docs = @import("../Docs.zig");
// Rendered and shown as code: what you read is what runs.
const BasicTabs = @import("examples/BasicTabs.zig");
const ControlledTabs = @import("examples/ControlledTabs.zig");
const CustomTabs = @import("examples/CustomTabs.zig");

var hl_basic: SyntaxHighlighter = undefined;
var hl_controlled: SyntaxHighlighter = undefined;
var hl_custom: SyntaxHighlighter = undefined;
var hl_api: SyntaxHighlighter = undefined;

pub fn init() void {
    hl_basic = Docs.highlighter(@embedFile("examples/BasicTabs.zig"));
    hl_controlled = Docs.highlighter(@embedFile("examples/ControlledTabs.zig"));
    hl_custom = Docs.highlighter(@embedFile("examples/CustomTabs.zig"));
    hl_api = Docs.highlighter(
        \\const Tabs = @import("opaque-ui").Tabs;
        \\
        \\// Draws the tabs and returns the selected index. The tabs are
        \\// kept under tag, so the selection survives rerenders.
        \\pub fn NavBar(tag: []const u8, names: []const []const u8) usize
        \\
        \\// The same, configured first.
        \\pub fn create(tag: []const u8, names: []const []const u8) *Tabs
        \\// Selects the named tab, on every render it's called.
        \\pub fn default(tabs: *Tabs, name: ?[]const u8) *Tabs
        \\// Called after a tab is clicked or picked by key.
        \\pub fn onClick(tabs: *Tabs, callback: *const fn (*Tabs) void) *Tabs
        \\// Draws the standard tabs; returns the selected index.
        \\pub fn render(tabs: *Tabs) usize
        \\// Draws each tab with your function; returns the selected index.
        \\pub fn Trigger(tabs: *Tabs, trigger_fn: *const fn (*Tabs, []const u8, bool) void) usize
        \\
        \\// Selects a tab from outside, by tag and index.
        \\pub fn switchToTab(tag: []const u8, index: usize) void
    );

    Vapor.Page(.{ .src = @src() }, render, null);
}

const fields = [_]Docs.Field{
    .{ .name = "tag", .type = "[]const u8", .desc = "The name the tabs are kept under. One per set of tabs." },
    .{ .name = "names", .type = "[]const []const u8", .desc = "The tabs, in order. Each name is also its label." },
    .{ .name = "active_tab", .type = "?[]const u8", .default = "null", .desc = "The selected tab's name; null means the first. Read it in onClick." },
    .{ .name = "selected_index", .type = "usize", .default = "0", .desc = "The selected tab's index, as of the last render." },
};

const behaviours = [_]Docs.Field{
    .{ .name = "Keyboard", .desc = "Tab reaches the selected tab. Left and Right move to the next one, Home and End to the first and last, selecting it and taking focus with it." },
    .{ .name = "Screen readers", .desc = "The row has role=tablist; each tab has role=tab and reports aria-selected." },
    .{ .name = "Narrow screens", .desc = "Tabs that don't fit scroll sideways rather than widen the page." },
    .{ .name = "Panels", .desc = "Yours to draw: switch on the returned index." },
};

pub fn render() void {
    Row()
        .width(.percent(100))
        .layout(.top_center)
        .direction(.column)
        .children({
        Hero("tabs-ui", "Accessible tabs that switch between panels, with arrow-key navigation and your own tab styles.");

        Docs.Content().children({
            Docs.exampleLabel("Basic Tabs");
            Docs.sectionDesc("NavBar draws the tabs and returns the selected index; switch on it to show a panel.");
            Docs.PreviewCard().children({
                BasicTabs.render();
            });
            CodeBox(&hl_basic, "BasicTabs");

            Docs.exampleLabel("Controlled Tabs");
            Docs.sectionDesc("Keep the selected tab in your own state with default and onClick, e.g. to remember it.");
            Docs.PreviewCard().children({
                ControlledTabs.render();
            });
            CodeBox(&hl_controlled, "ControlledTabs");

            Docs.exampleLabel("Custom Triggers");
            Docs.sectionDesc("Trigger keeps selection, keyboard and roles, and calls your function to draw each tab.");
            Docs.PreviewCard().children({
                CustomTabs.render();
            });
            CodeBox(&hl_custom, "CustomTabs");

            Docs.sectionTitle("API Reference");

            Docs.exampleLabel("Tabs");
            Docs.sectionDesc("NavBar for the standard tabs; create, then render or Trigger, to configure them.");
            CodeBox(&hl_api, "Tabs");

            Docs.exampleLabel("Fields");
            Docs.sectionDesc("What onClick's *Tabs holds.");
            Docs.ApiBox("Tabs", &fields);

            Docs.exampleLabel("Behaviour");
            Docs.sectionDesc("What the tabs do for you.");
            Docs.ApiBox("Behaviour", &behaviours);
        });
    });
}
