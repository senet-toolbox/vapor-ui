const std = @import("std");
const Vapor = @import("vapor");
const Static = Vapor.Static;
const Types = Vapor.Types;
const Signal = Vapor.Signal;
const Kit = Vapor.Kit;
const println = Vapor.println;
const logo = @embedFile("logo.svg");
const Binded = Vapor.Binded;
const Row = Vapor.Row;
const Text = Static.Text;
const Link = Static.Link;
const Image = Static.Image;
const Svg = Static.Svg;
const Button = Static.Button;
const Center = Static.Center;
const Icon = Vapor.Icon;
const Nav = @import("VaporUINav.zig");
const MenuItem = @import("VaporUINav.zig").MenuItem;
const goto = @import("VaporUINav.zig").goto;

var current_route: usize = 0;

fn gotoNextRoute() void {
    current_route += 1;
    const route = Nav.menu_items[current_route].value;
    goto(route);
}

fn gotoPrevRoute() void {
    if (current_route == 0) return;
    current_route -= 1;
    const route = Nav.menu_items[current_route].value;
    goto(route);
}

fn getPrevPath() ?MenuItem {
    if (current_route < 1) return null;
    return Nav.menu_items[current_route - 1];
}

fn getNextPathItem() ?MenuItem {
    if (current_route >= Nav.menu_items.len - 1) return null;
    return Nav.menu_items[current_route + 1];
}

fn setCurrentRoute(path: []const u8) void {
    for (Nav.menu_items, 0..) |route, i| {
        if (std.mem.eql(u8, path, route.value)) {
            current_route = i;
        }
    }
}

var hovered_item: ?MenuItem = null;
fn onHover(item: MenuItem, _: *Vapor.Event) void {
    hovered_item = item;
}

fn onLeave(_: *Vapor.Event) void {
    hovered_item = null;
}

pub fn render() void {
    const path = Vapor.Kit.getWindowPath() orelse "/";
    setCurrentRoute(path);
    Row().style(&.{
        .size = .w(.percent(100)),
        .layout = .{ .x = .end, .y = .center },
        .child_gap = 32,
    }).children({ 
        if (getPrevPath()) |item| {
            Button(gotoPrevRoute)
                .class("prev-btn")
                .size(.hw(.px(128), .percent(50)))
                .border(.simple(.palette(.border_color_light)))
                .background(.transparent)
                .cursor(.pointer)
                .padding(.all(12))
                .direction(.column)
                .layout(.{ .x = .start, .y = .even })
                .duration(100)
                .hover(.{
                    .border = .{ .color = .palette(.tint), .thickness = .all(1) },
                    .text_color = .palette(.tint),
                })
                .children({
                Icon(.arrow_left)
                    .class("btn-icon")
                    .fontSize(18)
                    .height(.px(32))
                    .font(18, null, .palette(.text_color))
                    .width(.px(32))
                    .inheritHover(&.{ .border, .text_color })
                    .layout(.center)
                    .border(.{
                        .color = .palette(.border_color_light),
                        .thickness = .all(1),
                    })
                    .end();
                Center().style(&.{
                    .child_gap = 12,
                }).children({ 
                    Text(item.label)
                        .baseStyle(&.{
                            .visual = .{
                                .font_size = 18,
                                .text_color = .palette(.text_color),
                            },
                        })
                        .fontFamily("IBM Plex Sans,monospace")
                        .end();
                });
            });
        }
        if (getNextPathItem()) |item| {
            Button(gotoNextRoute)
                .class("next-btn")
                .size(.hw(.px(128), .percent(50)))
                .border(.simple(.palette(.border_color_light)))
                .background(.transparent)
                .cursor(.pointer)
                .padding(.all(12))
                .direction(.column)
                .layout(.{ .x = .end, .y = .even })
                .duration(100)
                .hover(.{
                    .border = .{ .color = .palette(.tint), .thickness = .all(1) },
                    .text_color = .palette(.tint),
                })
                .children({
                Icon(.arrow_right)
                    .class("btn-icon")
                    .font(18, null, .palette(.text_color))
                    .height(.px(32))
                    .width(.px(32))
                    .inheritHover(&.{ .border, .text_color })
                    .layout(.center)
                    .border(.{
                        .color = .palette(.border_color_light),
                        .thickness = .all(1),
                    })
                    .end();
                Center().style(&.{
                    .child_gap = 12,
                }).children({ 
                    Text(item.label)
                        .baseStyle(&.{
                            .visual = .{
                                .font_size = 18,
                                .text_color = .palette(.text_color),
                            },
                        })
                        .fontFamily("IBM Plex Sans,monospace")
                        .end();
                });
            });
        }
    });
}
