//! The component pages: their list (the sidebar, the components index and the
//! search all read it) and the layout that puts the sidebar beside every page
//! under /ui/components.

const std = @import("std");
const Vapor = @import("vapor");
const Text = Vapor.Text;
const Row = Vapor.Row;
const Link = Vapor.Link;
const List = Vapor.List;
const ListItem = Vapor.ListItem;
const Opaque = @import("opaque-ui");

pub const MenuItem = Opaque.Item([]const u8);

pub const base_path = "/ui/components";

fn page(comptime slug: []const u8, comptime label: []const u8) MenuItem {
    const path = base_path ++ "/" ++ slug;
    return .{ .value = path, .label = label, .icon = .arrow_right, .link = path };
}

/// Every component page, in sidebar order. A new page goes here and in
/// `routes/vapor-ui/Page.zig`.
pub var items = [_]MenuItem{
    page("accordion", "Accordion"),
    page("alert", "Alert"),
    page("avatar", "Avatar"),
    page("badge", "Badge"),
    page("breadcrumb", "Breadcrumb"),
    page("button", "Button"),
    page("carousel", "Carousel"),
    page("chart", "Chart"),
    page("checkbox", "Checkbox"),
    page("codeinput", "CodeInput"),
    page("combobox", "Combobox"),
    page("commandpalette", "CommandPalette"),
    page("datepicker", "DatePicker"),
    page("dialog", "Dialog"),
    page("drawer", "Drawer"),
    page("marquee", "Marquee"),
    page("menu", "Menu"),
    page("pagination", "Pagination"),
    page("radio", "Radio"),
    page("segmented", "Segmented"),
    page("select", "Select"),
    page("sidebar", "Sidebar"),
    page("skeleton", "Skeleton"),
    page("slider", "Slider"),
    page("switch", "Switch"),
    page("table", "Table"),
    page("tabs", "Tabs"),
    page("textfield", "TextField"),
    page("toasts", "Toasts"),
    page("tooltip", "Tooltip"),
    page("progress", "Progress Bar/Circle"),
};

pub fn init() void {
    Vapor.lib.registerLayout(base_path, layout, .{}) catch unreachable;
}

/// Wraps every page under /ui/components. The index lists the components
/// itself, so it goes without the sidebar and the page links.
fn layout(render_page: *const fn () void) void {
    const on_index = std.mem.eql(u8, Vapor.currentPath(), base_path);
    if (!on_index) Sidebar();
    render_page();
    if (!on_index) PageLinks();
}

/// The place of the page at `path` in `items`.
fn indexOf(path: []const u8) ?usize {
    for (items, 0..) |item, i| {
        if (std.mem.eql(u8, path, item.value)) return i;
    }
    return null;
}

const Side = enum { previous, next };

/// Links to the pages before and after this one, in sidebar order, at the
/// foot of the page.
fn PageLinks() void {
    const index = indexOf(Vapor.currentPath()) orelse return;
    Row()
        .width(.percent(100))
        .layout(.center)
        .padding(.{ .bottom = 120 })
        .children({
        Row()
            .a11y(Vapor.Accessibility.init().setRole(.navigation).setLabel("Previous and next component"))
            .width(.percent(50))
            .responsive(.mobile, .{ .size = .w(.percent(92)) })
            .layout(.x_between_center)
            .spacing(16)
            .children({
            if (index > 0) PageLink(.previous, items[index - 1]) else Spacer();
            if (index + 1 < items.len) PageLink(.next, items[index + 1]) else Spacer();
        });
    });
}

/// Holds the other side's place, so a lone link stays on its own side.
fn Spacer() void {
    Row().width(.percent(48)).children({});
}

fn PageLink(side: Side, item: MenuItem) void {
    const previous = side == .previous;
    Link(.{
        .url = item.value,
        .aria_label = Vapor.fmtln("{s}: {s}", .{ if (previous) "Previous" else "Next", item.label }),
    })
        .width(.percent(48))
        .direction(.column)
        .layout(if (previous) .{ .x = .start, .y = .center } else .{ .x = .end, .y = .center })
        .spacing(8)
        .padding(.xy(20, 18))
        .border(.round(.palette(.border_color_light), .all(12)))
        .textDecoration(.none)
        .textColor(.palette(.text_color))
        .duration(120)
        .hover(.{
            .border = .round(.palette(.tint), .all(12)),
            .text_color = .palette(.tint),
        })
        .children({
        Text(if (previous) "← Previous" else "Next →")
            .font(13, 400, .hex("#71717a"))
            .fontFamily("IBM Plex Mono,monospace")
            .end();
        // The link's colour, so it turns with the border on hover.
        Text(item.label)
            .font(18, 500, null)
            .fontFamily("Montserrat")
            .end();
    });
}

/// The sidebar entry's element id for `path`.
fn itemId(path: []const u8) []const u8 {
    return Vapor.fmtln("menu-{s}", .{path});
}

/// Scrolls the sidebar so the entry for `path` is in view.
pub fn reveal(path: []const u8) void {
    Vapor.scrollIntoView(itemId(path), .{ .block = .start });
}

fn mount() void {
    reveal(Vapor.currentPath());
    Vapor.onPopState(onPopState);
}

fn onPopState() void {
    Vapor.scrollTo(0, 0);
    reveal(Vapor.currentPath());
}

fn Sidebar() void {
    const current_path = Vapor.currentPath();
    // Phones reach these pages from the menu instead.
    Row().id("components-sidebar").style(&.{
        .position = .{ .type = .fixed, .top = .px(60), .left = .percent(2), .z_index = 999 },
        .size = .hw(.percent(100), .mobileDesktopPercent(100, 14)),
    }).hideOn(.mobile).children({
        Vapor.onMount(mount, .{});
        List().style(&.{
            .list_style = .none,
            .direction = .column,
            .padding = .{ .top = 16, .bottom = 64, .left = 8, .right = 8 },
            .child_gap = 12,
            .size = .hw(.percent(95), .percent(100)),
            .scroll = .scrollY(),
            .show_scrollbar = false,
            .layout = .{},
        }).children({
            for (items) |item| {
                const active = std.mem.eql(u8, current_path, item.value);
                ListItem()
                    .id(itemId(item.value))
                    .border(.sharp(.all(1), .transparent))
                    .background(if (active) .transparentize(.palette(.tint), 0.1) else .transparent)
                    .size(.hw(.fit, .percent(100)))
                    .hoverBackground(if (active) .transparentize(.palette(.tint), 0.1) else .palette(.highlight_color))
                    .border(.right(1, if (active) .palette(.tint) else .transparent))
                    .layer(if (active) .dot(0.5, 6, .transparentize(.palette(.tint), 0.3)) else null)
                    .children({
                    Link(.{ .url = item.value, .aria_label = Vapor.fmtln("navigate to {s}", .{item.value}) })
                        .style(&.{
                            .visual = .{
                                .text_decoration = .none,
                                .cursor = .pointer,
                                .background = .transparent,
                            },
                            .size = .w(.percent(100)),
                            .layout = .left_center,
                            .child_gap = 12,
                            .padding = .xy(8, 10),
                        })
                        .children({
                        Text(item.label).style(&.{
                            .visual = .{
                                .text_color = if (active) .palette(.tint) else .palette(.text_color),
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
