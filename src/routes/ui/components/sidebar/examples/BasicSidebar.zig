const Vapor = @import("vapor");
const Row = Vapor.Row;
const TextFmt = Vapor.TextFmt;
const SideBar = @import("opaque-ui").SideBar;
const GroupItem = SideBar.GroupItem;
const MenuItem = SideBar.MenuItem;

// A global var: opening a group writes into it.
var groups = [_]GroupItem{
    .{ .title = "Overview", .icon = .grid_3x3, .show = true, .items = &.{
        .{ .title = "Dashboard", .link = "/dashboard", .icon = .house },
        .{ .title = "Activity", .link = "/activity", .icon = .activity },
    } },
    .{ .title = "Projects", .icon = .folder, .show = true, .items = &.{
        .{ .title = "Routes", .link = "/routes", .icon = .diagram_3 },
        .{ .title = "Treehouse", .link = "/treehouse", .icon = .tree },
    } },
    .{ .title = "Data", .icon = .database, .show = true, .items = &.{
        .{ .title = "Database", .link = "/database", .icon = .database },
        .{ .title = "Sql Editor", .link = "/sql-editor", .icon = .code_slash },
    } },
};

var sidebar: SideBar = .{
    .title = "Vapor UI",
    .groups = &groups,
    .show_menu = true,
    .on_item_click = onItem,
};

var showing: []const u8 = "Dashboard";

fn onItem(item: *const MenuItem) void {
    showing = item.title;
}

// In your init: sets up its animations.
pub fn init() void {
    SideBar.init();
}

pub fn render() void {
    Row().width(.percent(100)).height(.percent(100)).children({
        Row().width(.percent(50)).height(.percent(100)).children({
            sidebar.render();
        });
        // Your page, beside it.
        Row().width(.expand).layout(.center).children({
            TextFmt("Showing {s}", .{showing})
                .font(18, 400, .palette(.text_color))
                .end();
        });
    });
}
