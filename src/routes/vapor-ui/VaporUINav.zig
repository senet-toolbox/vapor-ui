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

const CommandPalette = Opaque.CommandPalette;
const ComboBoxDialog = Opaque.ComboBoxDialog;

const ComponentsNav = @import("../ui/components/ComponentsNav.zig");

var command_palette: CommandPalette = .{};
pub var combobox_dialog: ComboBoxDialog([]const u8) = undefined;

var nav: Vapor.Element = .{};

pub fn init() void {
    combobox_dialog = .fromItems(&ComponentsNav.items);
    combobox_dialog.on_select = onSelect;
    combobox_dialog.on_close = closePalette;
    command_palette.on_click = openSearch;
    command_palette.on_escape = closeSearch;
    // OverlayManager.register(.keydown, navigateByNum, &nav);
}

fn navigateByNum(_: *Vapor.Element, _: *Vapor.Event) void {
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
    Vapor.navigate(url);
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
    Vapor.navigate(url);
    Vapor.scrollTo(0, 0);
    ComponentsNav.reveal(url);
}

fn mount() void {
    Vapor.scrollTo(0, 0);
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
}

const theme_svg = @embedFile("nightswitch.svg");

pub fn render() void {
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
                    .margin(.{ .right = 12 })
                    .children({
                    command_palette.render();
                });
                RedirectLink(.{ .url = "https://github.com/senet-toolbox/vapor-ui", .aria_label = "redirect link to vapor-ui repo" })
                    .class("nav-item")
                    .size(.hwPx(36, 36))
                    .layout(.center)
                    .background(.transparentize(.black, 0.8))
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
                Button(toggleTheme, .{})
                    .ariaLabel("toggle theme")
                    .layout(.center)
                    .pointer()
                    .children({
                    Vapor.Svg(.{ .override = true, .svg = theme_svg })
                        .size(.hwPx(56, 56))
                        .inheritHover(&.{.text_color})
                        .font(18, 700, .white)
                        .end();
                });
            });
        });
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
                Button(openSearch, .{})
                    .ariaLabel("search components")
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

                Button(openMenu, .{})
                    .ariaLabel(if (menu) "close menu" else "open menu")
                    .style(&.{
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
        if (menu) MobileMenu();
    }
}

fn closeMenu(_: *Vapor.Event) void {
    menu = false;
}

/// The phone menu: the site's sections and every component page, under the
/// top bar. Choosing one closes it.
fn MobileMenu() void {
    const current_path = Vapor.currentPath();
    Stack().id("mobile-menu").style(&.{
        .position = .{ .type = .fixed, .top = .px(80), .left = .percent(0), .right = .percent(0), .bottom = .px(0), .z_index = 998 },
        .padding = .{ .top = 8, .bottom = 48, .left = 16, .right = 16 },
        .scroll = .scrollY(),
        .visual = .{ .background = .palette(.background) },
    }).children({
        MenuSection("Pages");
        for (urls) |url| MenuLink(url.url, url.title[6..], current_path);
        MenuSection("Components");
        for (ComponentsNav.items) |item| MenuLink(item.value, item.label, current_path);
    });
}

fn MenuSection(title: []const u8) void {
    Text(title)
        .font(12, 500, .hex("#71717a"))
        .fontFamily("IBM Plex Mono,monospace")
        .margin(.{ .top = 16, .bottom = 4 })
        .end();
}

fn MenuLink(url: []const u8, label: []const u8, current_path: []const u8) void {
    const active = std.mem.eql(u8, current_path, url);
    Link(.{ .url = url, .aria_label = label })
        .onEvent(.click, closeMenu, .{})
        .width(.percent(100))
        .padding(.xy(4, 12))
        .textDecoration(.none)
        .children({
        Text(label)
            .font(16, if (active) 600 else 400, if (active) .palette(.tint) else .palette(.text_color))
            .end();
    });
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
