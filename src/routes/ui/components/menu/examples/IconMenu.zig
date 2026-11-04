const Vapor = @import("vapor");
const Icon = Vapor.Icon;
const Menu = @import("opaque-ui").Menu;

const items = [_]Menu.Item{
    .{ .label = "Profile", .icon = .person },
    .{ .label = "Settings", .icon = .gear },
    .{ .label = "Sign out", .destructive = true, .separator_before = true },
};

var menu: Menu = undefined;

pub fn init() void {
    // The label names the icon-only button for screen readers.
    menu = Menu.init("Account menu", &items, null);
    // Opens below, towards the left.
    menu.placement = .bottom_left;
}

fn dots() void {
    Icon(.three_dots).font(16, 400, .palette(.text_color)).end();
}

pub fn render() void {
    menu.renderWith(dots, .{});
}
