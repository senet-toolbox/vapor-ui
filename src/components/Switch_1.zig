const Vapor = @import("vapor");
const std = @import("std");
const Row = Vapor.Row;
const ButtonCtx = Vapor.CtxButton;

var active_color: Vapor.Types.Color = .palette(.background);
var inactive_color: Vapor.Types.Color = .palette(.background);
var inactive_background: Vapor.Types.Color = .palette(.background);
var active_background: Vapor.Types.Color = .palette(.tint);
var border_radius: u8 = 4;
var duration: u32 = 300;

var switches: std.AutoHashMap(u32, *SwitchOptions) = undefined;

pub fn new() void {
    switches = std.AutoHashMap(u32, *SwitchOptions).init(Vapor.arena(.persist));
}

const Switch = @This();

const SwitchOptions = struct {
    id: []const u8,
    active: bool = false,
};

fn Circle(switch_options: *SwitchOptions) void {
    // const current_color = if (switch_options.active) active_color else inactive_color;
    const trans: f32 = if (switch_options.active) 28 else 0;
    Row()
        .width(.px(20))
        .height(.px(20))
        .border(.{
            .thickness = .none,
            .radius = .all(border_radius),
        })
        .background(.white)
        .inlineStyle(
            // \\border-radius: .3125em;
            // \\width: 1.375em;
            // \\height: 1.375em;
            // \\background-color: #e8e8e8;
            \\transform: translateX({d}px);
            \\box-shadow: inset 0 -.0625em .0625em .125em rgb(0 0 0 / .05),
            \\inset 0 -.125em .0625em rgb(0 0 0 / .1), 
            \\inset 0 .1875em .0625em rgb(255 255 255 / .2),
            \\0 .125em .125em rgb(0 0 0 / .2);
        , .{trans})
        .transition(.{
            .properties = &.{ .transform, .background_color },
            .duration = duration,
            .timing = .easeInOut,
        })
        .children({});
}

fn toggle(switch_options: *SwitchOptions) void {
    switch_options.active = !switch_options.active;
}

fn destroy(switch_options: *SwitchOptions) void {
    const hash = Vapor.utils.hashKey(switch_options.id);
    _ = switches.remove(hash);
}

pub fn render(id: []const u8) void {
    const hash = Vapor.utils.hashKey(id);
    const switch_options = switches.get(hash) orelse blk: {
        const switch_options = Vapor.arena(.persist).create(SwitchOptions) catch unreachable;
        switch_options.* = .{ .id = id };
        switches.put(hash, switch_options) catch unreachable;
        break :blk switch_options;
    };

    const background_color = if (switch_options.active) active_background else inactive_background;
    Vapor.Static.HooksCtx(.destroy, destroy, .{switch_options})({
        Row()
            .width(.px(48))
            .border(.{
                .thickness = .none,
                .radius = .all(border_radius + 2),
            })
            .padding(.all(2))
            .layout(.center)
            .width(.fit)
            .inlineStyle(
                // \\border-radius: .5em;
                // \\padding: .125em;
                \\background-image: linear-gradient(to bottom, #d5d5d5, #e8e8e8);
                \\box-shadow: 0 1px 1px rgb(255 255 255 / .1);
            , .{})
            .children({
            ButtonCtx(toggle, .{switch_options})
                .width(.px(48))
                .inlineStyle(
                    // \\border-radius: .375em;
                    \\background-color: #e8e8e8;
                    \\box-shadow: inset 0 0 .0625em .125em rgb(255 255 255 / .2), inset 0 .0625em .125em rgb(0 0 0 / .4);
                , .{})
                .border(.{
                    .thickness = .none,
                    .radius = .all(border_radius),
                })
                .cursor(.pointer)
                .transition(.{
                    .properties = &.{.background_color},
                    .duration = duration,
                    .timing = .easeInOut,
                })
                .background(background_color)
                .children({
                Circle(switch_options);
            });
        });
    });
}
