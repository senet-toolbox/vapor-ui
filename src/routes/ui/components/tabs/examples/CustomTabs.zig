const Vapor = @import("vapor");
const Text = Vapor.Text;
const Stack = Vapor.Stack;
const Row = Vapor.Row;
const Tabs = @import("opaque-ui").Tabs;

// ============================================================================
// MAIN RENDER
// ============================================================================

pub fn render() void {
    Stack().width(.percent(100)).spacing(16).children({
        // Trigger keeps the tab behaviour (selection, arrow keys, roles) and
        // lets you draw each tab yourself.
        const index = Tabs.create("custom-tabs", &.{ "Daily", "Weekly", "Monthly" })
            .Trigger(TabTrigger);
        const totals = [_][]const u8{ "128 visits today", "904 visits this week", "3,812 visits this month" };
        Text(totals[index])
            .font(14, 300, .palette(.text_color))
            .end();
    });
}

fn TabTrigger(_: *Tabs, name: []const u8, active: bool) void {
    Row()
        .padding(.xy(4, 6))
        .border(if (active) .bottom(2, .palette(.text_color)) else .bottom(2, .transparent))
        .children({
        Text(name)
            .fontFamily("IBM Plex Mono,monospace")
            .font(14, if (active) 600 else 300, .palette(.text_color))
            .end();
    });
}
