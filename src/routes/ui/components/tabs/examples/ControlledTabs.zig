const Vapor = @import("vapor");
const Text = Vapor.Text;
const TextFmt = Vapor.TextFmt;
const Stack = Vapor.Stack;
const Tabs = @import("opaque-ui").Tabs;

// The selected tab lives in your state: `default` sets it on every render
// and `onClick` writes it back, so you can store it or change it yourself.
var selected: []const u8 = "Activity";

fn onTab(tabs: *Tabs) void {
    selected = tabs.active_tab orelse selected;
}

// ============================================================================
// MAIN RENDER
// ============================================================================

pub fn render() void {
    Stack().width(.percent(100)).spacing(16).children({
        _ = Tabs.create("controlled-tabs", &.{ "Overview", "Activity", "Settings" })
            .default(selected)
            .onClick(onTab)
            .render();
        TextFmt("Selected: {s}", .{selected})
            .font(14, 300, .palette(.text_color))
            .end();
    });
}
