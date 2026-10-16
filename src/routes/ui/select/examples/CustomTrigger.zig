// examples/CustomTrigger.zig
const Vapor = @import("vapor");
const Opaque = @import("opaque-ui");
const Select = Opaque.Select;
const Row = Vapor.Row;

var select: Select(usize) = undefined;

pub fn init() void {
    select = .fromItems(&.{
        .{ .value = 0, .label = "Item 1" },
        .{ .value = 1, .label = "Item 2" },
        .{ .value = 2, .label = "Item 3" },
        .{ .value = 3, .label = "Item 4" },
        .{ .value = 4, .label = "Item 5" },
    });
    select.trigger_component = triggerButton;
    select.on_select = handleSelect;
}

fn handleSelect(_: *Select(usize), item: *Select(usize).Item) void {
    Vapor.alert("Selected: {s}", .{item.label});
}

fn triggerButton(_: *Select(usize)) void {
    Row()
        .width(.px(24))
        .height(.px(24))
        .cursor(.pointer)
        .background(.palette(.background))
        .hover(.{
            .background = .palette(.tint),
            .text_color = .palette(.background),
        })
        .duration(200)
        .border(.round(.transparent, .all(4)))
        .layout(.center)
        .children({
        Vapor.Icon(.three_dots)
            .font(16, 300, null)
            .end();
    });
}

pub fn render() void {
    select.render();
}
