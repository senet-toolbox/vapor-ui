const Vapor = @import("vapor");
const TextFmt = Vapor.TextFmt;
const Row = Vapor.Row;
const Menu = @import("opaque-ui").Menu;

const items = [_]Menu.Item{
    .{ .label = "Edit", .icon = .pencil, .shortcut = "E" },
    .{ .label = "Duplicate", .icon = .copy, .shortcut = "D" },
    .{ .label = "Archive", .disabled = true },
    // A line above it groups it apart.
    .{ .label = "Delete", .icon = .trash, .destructive = true, .separator_before = true },
};

var menu: Menu = undefined;
var picked: []const u8 = "nothing yet";

fn onPick(item: *const Menu.Item, _: usize) void {
    picked = item.label;
}

pub fn init() void {
    menu = Menu.init("Actions", &items, onPick);
}

pub fn render() void {
    // Side by side: the menu opens below, over what's under the button.
    Row().spacing(16).layout(.center).children({
        menu.render();
        TextFmt("Picked: {s}", .{picked})
            .font(14, 300, .palette(.text_color))
            .end();
    });
}
