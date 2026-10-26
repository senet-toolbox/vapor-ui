const Vapor = @import("vapor");
const Text = Vapor.Text;
const Stack = Vapor.Stack;
const Tabs = @import("opaque-ui").Tabs;

// ============================================================================
// MAIN RENDER
// ============================================================================

pub fn render() void {
    Stack().width(.percent(100)).spacing(16).children({
        // NavBar draws the tabs and returns the index of the selected one.
        const index = Tabs.NavBar("basic-tabs", &.{ "Account", "Password", "Notifications" });
        switch (index) {
            0 => Panel("Change your name, email and avatar."),
            1 => Panel("Update your password. You will be signed out of other devices."),
            2 => Panel("Choose which emails and push notifications you receive."),
            else => {},
        }
    });
}

fn Panel(body: []const u8) void {
    Text(body)
        .font(14, 300, .palette(.text_color))
        .end();
}
