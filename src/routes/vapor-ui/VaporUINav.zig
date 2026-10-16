const std = @import("std");
const Vapor = @import("vapor");
const println = Vapor.println;
const Kit = Vapor.Kit;
const Text = Vapor.Text;
const Row = Vapor.Row;
const Link = Vapor.Link;
const Stack = Vapor.Stack;
const Image = Vapor.Image;
const Svg = Vapor.Svg;
const Center = Vapor.Center;
const Icon = Vapor.Icon;
const List = Vapor.List;
const ListItem = Vapor.ListItem;
const RedirectLink = Vapor.RedirectLink;
const Button = Vapor.Button;
const Theme = @import("theme");
const Graphic = Vapor.Graphic;
const Opaque = @import("opaque-ui");
const OverlayManager = Opaque.OverlayManager;
const Item = Opaque.Item;

const CommandPalette = Opaque.CommandPalette;
const ComboBoxDialog = Opaque.ComboBoxDialog;

pub const MenuItem = Item([]const u8);

var command_palette: CommandPalette = .{};
pub var combobox_dialog: ComboBoxDialog([]const u8) = undefined;

pub var menu_items = [_]MenuItem{
    MenuItem{ .value = "/ui/accordion", .label = "Accordion", .icon = .arrow_right, .link = "/ui/accordion" },
    MenuItem{ .value = "/ui/alert", .label = "Alert", .icon = .arrow_right, .link = "/ui/alert" },
    MenuItem{ .value = "/ui/button", .label = "Button", .icon = .arrow_right, .link = "/ui/button" },
    MenuItem{ .value = "/ui/carousel", .label = "Carousel", .icon = .arrow_right, .link = "/ui/carousel" },
    MenuItem{ .value = "/ui/chart", .label = "Chart", .icon = .arrow_right, .link = "/ui/chart" },
    MenuItem{ .value = "/ui/combobox", .label = "Combobox", .icon = .arrow_right, .link = "/ui/combobox" },
    MenuItem{ .value = "/ui/commandpalette", .label = "CommandPalette", .icon = .arrow_right, .link = "/ui/commandpalette" },
    MenuItem{ .value = "/ui/datepicker", .label = "DatePicker", .icon = .arrow_right, .link = "/ui/datepicker" },
    MenuItem{ .value = "/ui/dialog", .label = "Dialog", .icon = .arrow_right, .link = "/ui/dialog" },
    MenuItem{ .value = "/ui/drawer", .label = "Drawer", .icon = .arrow_right, .link = "/ui/drawer" },
    MenuItem{ .value = "/ui/marquee", .label = "Marquee", .icon = .arrow_right, .link = "/ui/marquee" },
    // MenuItem{ .value = "/ui/group", .label = "Group", .icon = .arrow_right, .link = "/ui/group" },
    MenuItem{ .value = "/ui/select", .label = "Select", .icon = .arrow_right, .link = "/ui/select" },
    MenuItem{ .value = "/ui/sidebar", .label = "Sidebar", .icon = .arrow_right, .link = "/ui/sidebar" },
    MenuItem{ .value = "/ui/slider", .label = "Slider", .icon = .arrow_right, .link = "/ui/slider" },
    MenuItem{ .value = "/ui/switch", .label = "Switch", .icon = .arrow_right, .link = "/ui/switch" },
    MenuItem{ .value = "/ui/table", .label = "Table", .icon = .arrow_right, .link = "/ui/table" },
    MenuItem{ .value = "/ui/tabs", .label = "Tabs", .icon = .arrow_right, .link = "/ui/tabs" },
    MenuItem{ .value = "/ui/textfield", .label = "TextField", .icon = .arrow_right, .link = "/ui/textfield" },
    MenuItem{ .value = "/ui/toasts", .label = "Toasts", .icon = .arrow_right, .link = "/ui/toasts" },
    MenuItem{ .value = "/ui/tooltip", .label = "Tooltip", .icon = .arrow_right, .link = "/ui/tooltip" },
    MenuItem{ .value = "/ui/progress", .label = "Progress Bar/Circle", .icon = .arrow_right, .link = "/ui/progress" },
};

var nav: Vapor.Binded = .{};

pub fn init() void {
    combobox_dialog = .fromItems(&menu_items);
    combobox_dialog.on_select = onSelect;
    combobox_dialog.on_close = closePalette;
    command_palette.on_click = openSearch;
    command_palette.on_escape = closeSearch;
    // OverlayManager.register(.keydown, navigateByNum, &nav);
}

fn navigateByNum(_: *Vapor.Binded, _: *Vapor.Event) void {
    // evt.preventDefault();
    Vapor.print("navigateByNum", .{});
    // const key = evt.key();
    // if (std.mem.eql(u8, key, "0")) {
    //     navigate("/vapor-ui");
    // } else if (std.mem.eql(u8, key, "1")) {
    //     navigate("/ui/commandpalette");
    // } else if (std.mem.eql(u8, key, "2")) {
    //     navigate("/templates");
    // } else if (std.mem.eql(u8, key, "3")) {
    //     navigate("/authentication");
    // } else if (std.mem.eql(u8, key, "4")) {
    //     navigate("/payment");
    // }
    //
    // if (std.mem.eql(u8, key, "x") and evt.metaKey()) {
    //     Theme.toggleTheme();
    // }
}

fn onSelect(item: *ComboBoxDialog([]const u8).ItemT) void {
    const path = item.value;
    goto(path);
    combobox_dialog.close();
}

fn openSearch() void {
    combobox_dialog.clearAll();
    combobox_dialog.clearText();
    combobox_dialog.open();
}

fn closeSearch() void {
    combobox_dialog.close();
}

fn closePalette() void {
    command_palette.clicked = false;
}

var last_time: i64 = 0;
pub fn throttle() bool {
    const current_time = std.time.milliTimestamp();
    if (current_time - last_time < 60) {
        return true;
    }
    last_time = current_time;
    return false;
}

var menu: bool = false;
fn openMenu() void {
    // if (!throttle()) {
    menu = !menu;
    //     Vapor.cycle();
    // }
}
const Url = struct {
    url: []const u8,
    title: []const u8,
};
const urls: [4]Url = .{
    // .{
    //     .url = "/vapor-ui/docs",
    //     .title = "[0] = Docs",
    // },
    .{
        .url = "/ui/components",
        .title = "[1] = Components",
    },
    .{
        .url = "/ui/templates",
        .title = "[2] = Templates",
    },
    .{
        .url = "/ui/auth",
        .title = "[3] = Authentication",
    },
    .{
        .url = "/ui/payment",
        .title = "[4] = Payments",
    },
};

inline fn routes() void {
    // const current_path = Kit.getWindowPath();
    for (urls) |url| {
        ListItem().style(&Styles.item).children({
            Link(.{ .url = url.url, .aria_label = url.title }).style(&.{
                .visual = .{ .text_decoration = .none },
            }).children({
                Text(url.title).style(&.{ .visual = .font(16, 300, .palette(.text_color)), .font_family = "IBM Plex Mono,monospace" }).end();
            });
        });
    }
}

const Self = @This();

fn switchTheme(opt: []const u8) void {
    println("Switch Theme! {s}", .{opt});
    // if (opt[0] == 'D') {
    //     Vapor.Theme.switchTheme(.dark);
    //     return;
    // }
    // Vapor.Theme.switchTheme(.light);
    return;
}

// pub fn init() void {
//     // Search.init();
//     OverlayManager.register(.keydown, clickEvent, &local_binded);
// }

pub fn closeAll(evt: *Vapor.Event) void {
    evt.preventDefault();
}

pub fn setDefault() void {}

fn openDialog() void {
    // Search.toggle();
}

fn navigate(url: []const u8) void {
    Kit.navigate(url);
    menu = !menu;
    // Vapor.cycle();
}

pub fn setAttribute(id: []const u8, key: []const u8, value: []const u8) void {
    if (!Vapor.lib.isWasi) return;
    Vapor.Wasm.setAttributeWasm(id.ptr, id.len, key.ptr, key.len, value.ptr, value.len);
}

pub fn toggleTheme() void {
    Theme.toggleTheme();

    switch (Theme.mode) {
        .dark => {
            setAttribute("starDisc", "transform", "translate(22, -13)");
            setAttribute("gearDisc", "transform", "translate(-22, 13)");
        },
        .light => {
            // OFF - return to original
            setAttribute("gearDisc", "transform", "translate(0, 0)");
            setAttribute("starDisc", "transform", "translate(0, 0)");
        },
    }

    // Vapor.cycle();
}

var local_binded: []const u8 = "";

pub fn clickEvent(_: *[]const u8, evt: *Vapor.Event) void {
    const key = evt.key();
    if (std.mem.eql(u8, key, "k") and evt.metaKey()) {
        openDialog();
    }
}

pub fn goto(url: []const u8) void {
    Vapor.Kit.navigate(url);
    Vapor.Kit.scrollTo(0, 0);
    const uuid = Vapor.fmtln("menu-{s}", .{url});
    Vapor.scrollIntoView(uuid, .{ .block = .start });
}

var mounted: bool = false;
var current_menu_item: ?MenuItem = null;
fn mount() void {
    mounted = true;
    Vapor.Kit.scrollTo(0, 0);
    // this runs after the vaporize is mounter
    const current_path = Vapor.Kit.getWindowPath() orelse "/vapor-ui";
    current_menu_item = null;
    for (menu_items) |item| {
        if (std.mem.eql(u8, current_path, item.value)) {
            current_menu_item = item;
            break;
        }
    }

    switch (Theme.mode) {
        .dark => {
            setAttribute("starDisc", "transform", "translate(22, -13)");
            setAttribute("gearDisc", "transform", "translate(-22, 13)");
        },
        .light => {
            // OFF - return to original
            setAttribute("gearDisc", "transform", "translate(0, 0)");
            setAttribute("starDisc", "transform", "translate(0, 0)");
        },
    }

    if (current_menu_item == null) return;
    const uuid = Vapor.fmtln("menu-{s}", .{current_menu_item.?.value});
    Vapor.scrollIntoView(uuid, .{ .block = .start });
    Vapor.onPopState(handlePopState);
}

fn handlePopState() void {
    const current_path = Vapor.Kit.getWindowPath() orelse "/vapor-ui";
    Vapor.Kit.scrollTo(0, 0);
    const uuid = Vapor.fmtln("menu-{s}", .{current_path});
    Vapor.scrollIntoView(uuid, .{ .block = .start });
}

const theme_svg = @embedFile("nightswitch.svg");

pub fn render() void {
    const current_path = Vapor.Kit.getWindowPath() orelse "/vapor-ui";
    Vapor.onMount(mount, .{});
    if (Vapor.isDesktop()) {
        Row().id("nav").style(&.{
            .position = .nav,
            .size = .hw(.px(60), .grow),
            .layout = .x_between_center,
            .padding = .horizontal(50),
            .visual = .{ .blur = 2 },
        }).children({
            Row().style(&.{
                .size = .{ .height = .px(50) },
                .direction = .row,
                .layout = .left_center,
                .child_gap = 10,
            }).children({
                Button(goto, .{"/"})
                    .ariaLabel("navigate home page of tether")
                    // Link(.{ .url = "/", .aria_label = "home page of tether" })
                    .style(&.{
                        .visual = .{ .text_decoration = .none },
                    }).children({
                    Center().style(&.{
                        .size = .{ .width = .px(84) },
                        .margin = .{ .right = 30 },
                        .transition = .{ .duration = 100 },
                        .interactive = .{ .hover = .{ .transform = .scale() } },
                        .visual = .{ .text_color = .palette(.text_color) },
                    }).children({
                        Graphic(.{ .src = "/assets/vapor_ui.svg" }).style(&.{
                            .size = .{ .width = .percent(100), .height = .percent(100) },
                            .visual = .{ .fill = .black, .stroke = .black },
                            .transition = .{ .duration = 100 },
                            .interactive = .{ .hover = .{
                                .fill = .palette(.tint),
                                .stroke = .palette(.tint),
                            } },
                        }).end();
                    });
                });
                List().style(&.{
                    .child_gap = 32,
                    .layout = .center,
                    .size = .hw(.percent(100), .percent(100)),
                }).children({
                    routes();
                });
            });

            Center().style(&.{
                .child_gap = 8,
                .size = .w(.percent(30)),
            }).children({
                Row()
                    .width(.percent(70))
                    .margin(.r(12))
                    .children({
                    command_palette.render();
                });
                RedirectLink(.{ .url = "https://github.com/vic-Rokx/vapor", .aria_label = "redirect link to tether github repo" })
                    .class("nav-item")
                    .size(.hw_px(36, 36))
                    .layout(.center)
                    .background(.transparentizeHex(.black, 0.8))
                    .border(.round(.black, .all(8)))
                    .pointer()
                    .hover(.{
                        .background = .yellow,
                        .text_color = .black,
                    })
                    .children({
                    Icon(.github)
                        .class("nav-item-icon")
                        .inheritHover(&.{.text_color})
                        .font(18, 700, .white)
                        .end();
                });
                RedirectLink(.{ .url = "https://github.com/vic-Rokx/vapor", .aria_label = "redirect link to discord" })
                    .class("nav-item")
                    .size(.hw_px(36, 36))
                    .layout(.center)
                    .background(.transparentizeHex(.black, 0.8))
                    .border(.round(.black, .all(8)))
                    .pointer()
                    .hover(.{
                        .background = .yellow,
                        .text_color = .black,
                    })
                    .children({
                    Icon(.discord)
                        .class("nav-item-icon")
                        .inheritHover(&.{.text_color})
                        .font(18, 700, .white)
                        .end();
                });

                Button(toggleTheme, .{})
                    .ariaLabel("toggle theme")
                    // .class("nav-item")
                    // .size(.hw_px(36, 36))
                    .layout(.center)
                    // .background(.transparentizeHex(.black, 0.8))
                    // .border(.round(.black, .all(8)))
                    .pointer()
                    .hover(.{
                        // .background = .yellow,
                        // .text_color = .black,
                    })
                    .children({
                    Vapor.Svg(.{ .override = true, .svg = theme_svg })
                        .size(.hw_px(56, 56))
                        // .class("nav-item-icon")
                        .inheritHover(&.{.text_color})
                        .font(18, 700, .white)
                        .end();
                    // Icon(.cloud_moon)
                    //     .class("nav-item-icon")
                    //     .inheritHover(&.{.text_color})
                    //     .font(18, 700, .white)
                    //     .end();
                });
            });
        });
        if (!std.mem.eql(u8, current_path, "/") and !std.mem.eql(u8, current_path, "/ui/components") and !std.mem.eql(u8, current_path, "/ui/templates")) {
            Row().style(&.{
                .position = .{ .type = .fixed, .top = .px(60), .left = .percent(2), .z_index = 999 },
                .size = .hw(.percent(100), .mobile_desktop_percent(100, 14)),
            }).children({
                List().style(&.{
                    .list_style = .none,
                    .direction = .column,
                    .padding = .tblr(16, 64, 8, 8),
                    .child_gap = 12,
                    .size = .hw(.percent(95), .percent(100)),
                    .scroll = .scroll_y(),
                    .show_scrollbar = false,
                    .layout = .{},
                }).children({
                    for (menu_items) |item| {
                        const uuid = Vapor.fmtln("menu-{s}", .{item.value});
                        const active = std.mem.eql(u8, current_path, item.value);
                        // const inline_style = if (active)
                        //     \\background:
                        //     \\linear-gradient(rgba(var(--background)), rgba(var(--background))) padding-box,
                        //     \\linear-gradient(to top right, rgba(var(--tint)), rgba(var(--background)) 20%, rgba(var(--background)) 80%, rgba(var(--tint))) border-box;
                        // else
                        //     "";
                        ListItem()
                            .id(uuid)
                            .border(.sharp(.all(1), .transparent))
                            // .inlineStyle("{s}", .{inline_style})
                            .background(if (active) .transparentizeHex(.palette(.tint), 0.1) else .transparent)
                            .size(.hw(.fit, .percent(100)))
                            .hoverBackground(if (active) .transparentizeHex(.palette(.tint), 0.1) else .palette(.highlight_color))
                            .border(.r(1, if (active) .palette(.tint) else .transparent))
                            .layer(if (active) .dot(0.5, 6, .transparentizeHex(.palette(.tint), 0.3)) else null)
                            .children({
                            Link(.{ .url = item.value, .aria_label = Vapor.fmtln("navigate to {s}", .{item.value}) })
                                .ariaLabel(Vapor.fmtln("navigate to {s}", .{item.value}))
                                .style(&.{
                                    .visual = .{
                                        .text_decoration = .none,
                                        .cursor = .pointer,
                                        .background = .transparent,
                                    },
                                    .size = .w(.percent(100)),
                                    .layout = .left_center,
                                    .child_gap = 12,
                                    .padding = .tblr(10, 10, 8, 8),
                                })
                                .children({
                                // Icon(item.icon).style(&.{
                                //     // .visual = .{ .text_color = if (std.mem.eql(u8, current_path, item.value)) .palette(.tint) else .palette(.text_color) },
                                // });
                                Text(item.label).style(&.{
                                    .visual = .{
                                        .text_color = if (std.mem.eql(u8, current_path, item.value)) .palette(.tint) else .palette(.text_color),
                                        .font_size = 14,
                                    },
                                    .font_family = "Montserrat",
                                }).end();
                            });
                        });
                    }
                });
            });
        }
    } else {
        Row().style(&.{
            .layout = .x_between_center,
            .child_gap = 8,
            .padding = .horizontal(16),
            .position = .{ .type = .fixed, .top = .px(0), .left = .percent(0), .right = .percent(0), .z_index = 999 },
            .size = .hw(.px(80), .percent(100)),
            .visual = .{
                .background = .palette(.background),
            },
        }).children({
            Row().style(&.{ .layout = .left_center }).children({
                Link(.{ .url = "/", .aria_label = "home page of tether" }).style(&.{
                    .visual = .{ .text_decoration = .none },
                    .size = .h(.px(48)),
                    .layout = .center,
                }).children({
                    Image(.{ .src = "/assets/circlelogo.webp", .alt = "tether logo" }).style(&.{
                        .size = .w(.px(48)),
                    }).end();
                });
            });
            Row().style(&.{ .layout = .right_center }).children({
                Button(openMenu, .{})
                    .ariaLabel("open menu")
                    .style(&.{
                        .size = .hw(.px(36), .px(48)),
                        .visual = .bg(.palette(.background)),
                    }).children({
                    Icon(.search).style(&.{
                        .visual = .{ .font_size = 24, .text_color = .palette(.icon_color) },
                        .interactive = .{ .hover = .{ .text_color = .palette(.tint) } },
                    }).end();
                });

                Button(toggleTheme, .{})
                    .ariaLabel("toggle theme")
                    .style(&.{
                        .visual = .{ .cursor = .pointer, .background = .palette(.background) },
                        .size = .hw(.px(36), .px(48)),
                    }).children({
                    Icon(.cloud_moon).style(&.{
                        .visual = .{ .font_size = 24, .text_color = .palette(.icon_color) },
                    }).end();
                });

                Button(openMenu, .{}).style(&.{
                    .size = .hw(.px(36), .px(48)),
                    .visual = .bg(.palette(.background)),
                }).children({
                    if (menu) {
                        Icon(.x_lg).style(&.{
                            .id = "close-menu",
                            .visual = .{ .font_size = 24, .text_color = .palette(.icon_color) },
                        }).end();
                    } else {
                        Icon(.list).style(&.{
                            .id = "open-menu",
                            .visual = .{ .font_size = 24, .text_color = .palette(.icon_color) },
                        }).end();
                    }
                });
            });
        });
    }
}

const Styles = struct {
    pub const item = Vapor.Style{
        .list_style = .none,
        .size = .{ .width = .auto, .height = .px(30) },
        .layout = .{ .y = .center, .x = .start },
        .visual = .{ .border = .bottom(1, .transparent) },
        .interactive = .{
            .hover = .{
                .border = .bottom(1, .palette(.text_color)),
            },
        },
    };
};
