const Vapor = @import("vapor");
const std = @import("std");
const Row = Vapor.Row;
const ButtonCtx = Vapor.CtxButton;

var active_color: Vapor.Types.Color = .palette(.background);
var inactive_color: Vapor.Types.Color = .palette(.background);
var inactive_background: Vapor.Types.Color = .palette(.border_color_light);
var active_background: Vapor.Types.Color = .transparentizeHex(.palette(.tint), 0.7);

var border_radius: u8 = 4;
var duration: u32 = 100;

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
    const trans: f32 = if (switch_options.active) 20 else 0;
    Row()
        .width(.px(20))
        .height(.px(20))
        .layer(.dot(0.5, 6, .transparentizeHex(.black, 0.3)))
        .shadow(.{
            .top = 2,
            .blur = 2,
            .color = .transparentizeHex(.black, 0.1),
        })
        .border(.{
            .thickness = .none,
            .radius = .all(border_radius),
        })
        .background(.white)
        .inlineStyle(
            // \\transition: transform 0.4s cubic-bezier(0.85, 0.05, 0.18, 1.35);
            \\transform: translateX({d}px);
        , .{trans})
        .transition(.{
            .properties = &.{ .transform, .background_color },
            .duration = duration,
            .timing = .easeInCubic,
        })
        .children({});
}

fn toggle(switch_options: *SwitchOptions, callback: anytype, args: anytype) void {
    switch_options.active = !switch_options.active;
    @call(.auto, callback, args);
}

fn destroy(switch_options: *SwitchOptions) void {
    const hash = Vapor.utils.hashKey(switch_options.id);
    _ = switches.remove(hash);
}

fn Container() Vapor.Builder(.pure) {
    return Row()
        .width(.px(42))
        .border(.{
            .thickness = .none,
            .radius = .all(border_radius + 1),
        })
        .padding(.all(1))
        .layout(.center)
        .inlineStyle(
        \\background-image: linear-gradient(to bottom, #d5d5d5, #EDEDED);
        \\box-shadow: 0 1px 1px rgb(255 255 255 / .1);
    , .{});
}

pub fn render(aria_label: []const u8, on_change: anytype, args: anytype) void {
    const container = Container();
    const uuid = container.getUUID();
    const hash = Vapor.utils.hashKey(uuid);
    const switch_options = switches.get(hash) orelse blk: {
        const switch_options = Vapor.arena(.persist).create(SwitchOptions) catch unreachable;
        switch_options.* = .{ .id = uuid };
        switches.put(hash, switch_options) catch unreachable;
        break :blk switch_options;
    };

    const background_color = if (switch_options.active) active_background else inactive_background;
    Vapor.Static.HooksCtx(.destroy, destroy, .{switch_options})({
        container
            .children({
            ButtonCtx(toggle, .{ switch_options, on_change, args })
                .ariaLabel(aria_label)
                .width(.percent(100))
                .border(.{
                    .thickness = .none,
                    .radius = .all(border_radius),
                })
                .inlineStyle(
                    \\box-shadow: inset 0 0 .0625em .125em rgb(255 255 255 / .2), inset 0 .0625em .125em rgb(0 0 0 / .4);
                , .{})
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
