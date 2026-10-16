const std = @import("std");
const Vapor = @import("vapor");
const Text = Vapor.Text;
const Row = Vapor.Row;
const ButtonCtx = Vapor.CtxButton;
const Icon = Vapor.Icon;
const Stack = Vapor.Stack;
const IconTokens = Vapor.IconTokens;
const OverlayManager = @import("OverlayManager.zig");

var background: Vapor.Types.Color = .palette(.background);

const CommandPalette = @This();
text: []const u8 = "",
key_press: []const u8 = "k",
on_click: ?*const fn () void = null,
on_escape: ?*const fn () void = null,
clicked: bool = false,

fn mount(command_palette: *CommandPalette) void {
    // OverlayManager.register(.keydown, clickEvent, command_palette);
    _ = Vapor.addGlobalListenerCtx(.keydown, clickEvent, .{command_palette});
}

pub fn clickEvent(command_palette: *CommandPalette, evt: *Vapor.Event) void {
    const key = evt.key();
    if (std.mem.eql(u8, command_palette.key_press, key) and evt.metaKey()) {
        command_palette.clicked = !command_palette.clicked;
        if (command_palette.on_click) |callback| {
            @call(.auto, callback, .{});
        }
    }

    if (std.mem.eql(u8, "Escape", key)) {
        command_palette.clicked = false;
        if (command_palette.on_escape) |callback| {
            @call(.auto, callback, .{});
        }
    }
}

pub fn toggle(command_palette: *CommandPalette) void {
    command_palette.clicked = !command_palette.clicked;
    if (command_palette.on_click) |callback| {
        @call(.auto, callback, .{});
    }
}

pub fn render(command_palette: *CommandPalette) void {
    const trans: f32 = if (command_palette.clicked) -70 else 0;
    const scale: f32 = if (command_palette.clicked) 0.9 else 1;
    const left: f32 = if (command_palette.clicked) 42 else 36;
    const text_color: Vapor.Types.Color = if (command_palette.clicked) .palette(.border_color) else .transparentizeHex(.palette(.text_color), 0.5);
    Stack()
        .width(.percent(100))
        .children({
        Vapor.Static.HooksCtx(.mounted, mount, .{command_palette})({
            ButtonCtx(toggle, .{command_palette})
                .background(background)
                .width(.percent(100))
                .cursor(.pointer)
                .duration(100)
                .hover(.{ .border = .round(.palette(.border_color), .all(12)) })
                .shadow(.{ .top = 2, .blur = 2, .color = .transparentizeHex(.black, 0.1) })
                .border(.round(.palette(.border_color_light), .all(12)))
                .children({
                ButtonCtx(toggle, .{command_palette})
                    .pos(.relative)
                    .width(.percent(100))
                    .padding(.tblr(10, 10, 12, 12))
                    .width(.percent(100))
                    .spacing(8)
                    .layout(.x_between_center)
                    .border(.{
                        .thickness = .none,
                        .radius = .all(11),
                    })
                    .children({
                    Vapor.Svg(.{ .svg = IconTokens.lucide_search.svg.? })
                        .width(.px(16))
                        .height(.px(16))
                        .stroke(.palette(.text_color))
                        .end();
                    Text(if (command_palette.text.len > 0) command_palette.text else "Search")
                        .pos(.{ .left = .px(left), .type = .absolute })
                        .transition(.{
                            .properties = &.{ .transform, .scale, .left },
                            .duration = 100,
                            .timing = .easeInOut,
                        })
                        .inlineStyle("transform: translateY({d}%) scale({d});", .{ trans, scale })
                        .padding(.horizontal(2))
                        .background(background)
                        .fontFamily("Montserrat")
                        .font(16, 300, text_color)
                        .end();
                    Row()
                        .spacing(4)
                        .layout(.right_center)
                        .width(.grow)
                        .children({
                        Icon(.command)
                            .font(12, 300, .palette(.text_color))
                            .end();
                        Text(Vapor.utils.firstLetterToUpper(command_palette.key_press, .frame))
                            .font(12, 300, .palette(.text_color))
                            .end();
                    });
                });
            });
        });
    });
}
