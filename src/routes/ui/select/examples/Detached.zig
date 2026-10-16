// examples/Detached.zig
const Vapor = @import("vapor");
const Opaque = @import("opaque-ui");
const Select = Opaque.Select;
const Row = Vapor.Row;
const Text = Vapor.Text;
const Stack = Vapor.Stack;

const NavItem = enum {
    dashboard,
    transactions,
    analytics,
    customers,
    settings,
};

var select: Select(NavItem) = undefined;

pub fn init() void {
    select = .fromItems(&.{
        .{ .value = NavItem.dashboard, .label = "Dashboard" },
        .{ .value = NavItem.transactions, .label = "Transactions" },
        .{ .value = NavItem.analytics, .label = "Analytics" },
        .{ .value = NavItem.customers, .label = "Customers" },
        .{ .value = NavItem.settings, .label = "Settings" },
    });
    select.trigger_component = triggerButton;
    select.on_select = handleSelect;
    select.is_detached = true;
}

fn handleSelect(_: *Select(NavItem), item: *Select(NavItem).Item) void {
    Vapor.alert("Selected: {s}", .{item.label});
}

fn triggerButton(_: *Select(NavItem)) void {
    Row()
        .padding(.tblr(8, 8, 10, 10))
        .layout(.x_between_center)
        .spacing(8)
        .width(.fit)
        .height(.fit)
        .border(.round(.palette(.border_color_light), .all(12)))
        .background(.palette(.tint))
        .duration(100)
        .newShadow(Vapor.Types.NewShadow.init()
            .inset(0, -2, .transparentizeHex(.black, 0.3))
            .drop(0, 1, 3, .transparentizeHex(.black, 0.1)))
        .hover(.{
            .transform = .scaleDecimal(1.01),
            .new_shadow = Vapor.Types.NewShadow.init()
                .inset(0, -2, .transparentizeHex(.black, 0))
                .drop(0, 1, 3, .transparentizeHex(.black, 0)),
        })
        .children({
        Text("Open Menu →")
            .fontFamily("Montserrat")
            .font(16, 300, .palette(.background))
            .end();
    });
}

pub fn render() void {
    // Render trigger and dropdown separately
    Stack().children({
        select.renderTrigger();
    });
    Stack()
        .width(.percent(10))
        .pos(.tr(.px(72), .px(12), .fixed))
        .children({
        select.renderSelect();
    });
}
