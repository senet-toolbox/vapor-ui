const Vapor = @import("vapor");
const std = @import("std");
const Row = Vapor.Row;
const Button = Vapor.Button;
const Svg = Vapor.Svg;
const Text = Vapor.Text;

var active_color: Vapor.Types.Color = .palette(.background);
var inactive_color: Vapor.Types.Color = .palette(.background);
var inactive_background: Vapor.Types.Color = .palette(.border_color_light);
var active_background: Vapor.Types.Color = .transparentizeHex(.palette(.tint), 0.7);

var border_radius: u8 = 4;
var duration: u32 = 100;

var radios: std.AutoHashMap(u32, *CheckboxOptions) = undefined;

pub fn new() void {
    radios = std.AutoHashMap(u32, *CheckboxOptions).init(Vapor.arena(.persist));
}

const Checkbox = @This();

const CheckboxOptions = struct {
    id: []const u8,
    active: bool = false,
    erased_cb: Vapor.lib.ErasedCallback,
    // get_default_value: Vapor.lib.ErasedCallback,
};

fn toggle(switch_options: *CheckboxOptions, callback: anytype, args: anytype) void {
    switch_options.active = !switch_options.active;
    @call(.auto, callback, args);
}

fn toggleWithActive(switch_options: *CheckboxOptions, callback: anytype, args: anytype) void {
    switch_options.active = !switch_options.active;
    @call(.auto, callback, args ++ .{switch_options.active});
}

fn destroy(switch_options: *CheckboxOptions) void {
    const hash = Vapor.utils.hashKey(switch_options.id);
    _ = radios.remove(hash);
}

fn Container() Vapor.Builder(.pure) {
    return Vapor.Stack()
        .spacing(16);
}

pub fn RadioGroup(comptime T: type) type {
    return struct {
        id: []const u8,
        container: Vapor.Builder(.pure),
        switch_options: CheckboxOptions,
        default_value: ?T,
        erased_cb: Vapor.lib.ErasedCallback,

        pub fn children(self: *const RadioGroup, comptime items: anytype) void {
            self.container.children(items);
        }

        // pub fn selected(
        //     self: *const RadioGroup,
        // ) T {}
    };
}

fn selectItem(opts: *CheckboxOptions, value_hash: u32) void {
    _ = value_hash;
    // opts.selected_value = value_hash;
    opts.erased_cb.call();
}

pub fn Item(value: []const u8, text: []const u8) void {
    const current_node = Vapor.lib.getCurrentNode() orelse return;
    const group_hash = Vapor.utils.hashKey(current_node.uuid);
    const opts = radios.get(group_hash) orelse return;

    const value_hash = Vapor.utils.hashKey(value);
    // const is_selected = (opts.selected_value == value_hash);

    Button(selectItem, .{ opts, value_hash })
        .layout(.left_center)
        .children({
        Row()
            .width(.px(20))
            .height(.px(20))
            .background(.palette(.text))
            .radius(.all(99))
            // .border(.round(
            //     if (is_selected) .palette(.tint) else .palette(.border_color_light),
            //     .all(4),
            // ))
            .layout(.center)
            .children({
            // if (is_selected) {
            //     Row().width(.px(10)).height(.px(10))
            //         .background(.palette(.tint))
            //         .radius(.all(5)).end();
            // }
        });
        Text(text)
            .font(16, 300, .palette(.text_color))
            .end();
    });
}

pub fn Group(comptime T: type, default_value: T, on_change: anytype, args: anytype) Vapor.Builder(.pure) {
    _ = default_value;
    const container = Container();
    const uuid = container.getUUID();
    const hash = Vapor.utils.hashKey(uuid);

    const erased_cb = Vapor.lib.ErasedCallback.make(Vapor.frame.arena(), on_change, args) catch return container;

    _ = radios.get(hash) orelse blk: {
        const so = Vapor.arena(.persist).create(CheckboxOptions) catch unreachable;
        so.* = .{
            .id = uuid,
            .erased_cb = erased_cb,
            // .selected_value = Vapor.utils.hashKey(default_value),
        };
        radios.put(hash, so) catch unreachable;
        break :blk so;
    };

    return container;
}

pub fn create(uuid: []const u8, on_change: anytype, args: anytype) Vapor.Builder(.pure) {
    const hash = Vapor.utils.hashKey(uuid);
    const switch_options = radios.get(hash) orelse blk: {
        const switch_options = Vapor.arena(.persist).create(CheckboxOptions) catch unreachable;
        switch_options.* = .{ .id = uuid };
        radios.put(hash, switch_options) catch unreachable;
        break :blk switch_options;
    };

    const background_color = if (switch_options.active) active_background else inactive_background;
    var button: Vapor.Builder(.pure) = undefined;
    button = Button(toggleWithActive, .{ switch_options, on_change, args })
        .id(uuid)
        .onDestroy(destroy, .{switch_options})
        .width(.px(20))
        .height(.px(20))
        .cursor(.pointer)
        .duration(100)
        .center()
        .background(background_color)
        .radius(.all(4));
    return button;
}

// pub fn render(aria_label: []const u8, on_change: anytype, args: anytype) void {
//     const container = Container();
//     const uuid = container.getUUID();
//     const hash = Vapor.utils.hashKey(uuid);
//     const switch_options = radios.get(hash) orelse blk: {
//         const switch_options = Vapor.arena(.persist).create(CheckboxOptions) catch unreachable;
//         switch_options.* = .{ .id = uuid };
//         radios.put(hash, switch_options) catch unreachable;
//         break :blk switch_options;
//     };
//
//     const background_color = if (switch_options.active) active_background else inactive_background;
//     Vapor.Static.HooksCtx(.destroy, destroy, .{switch_options})({
//         container
//             .children({
//             Button(toggle, .{ switch_options, on_change, args })
//                 .ariaLabel(aria_label)
//                 .width(.px(20))
//                 .height(.px(20))
//                 .cursor(.pointer)
//                 .duration(100)
//                 .center()
//                 .background(background_color)
//                 .radius(.all(4))
//                 .children({
//                 Svg(.{ .override = true, .svg = checkbox_svg })
//                     .font(16, 300, if (switch_options.active) active_color else inactive_color)
//                     .end();
//             });
//         });
//     });
// }
