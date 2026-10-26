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
    page("button", "Button"),
    page("carousel", "Carousel"),
    page("chart", "Chart"),
    page("checkbox", "Checkbox"),
    page("combobox", "Combobox"),
    page("commandpalette", "CommandPalette"),
    page("datepicker", "DatePicker"),
    page("dialog", "Dialog"),
    page("drawer", "Drawer"),
    page("marquee", "Marquee"),
    page("radio", "Radio"),
    page("select", "Select"),
    page("sidebar", "Sidebar"),
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
/// itself, so it goes without the sidebar.
fn layout(render_page: *const fn () void) void {
    if (!std.mem.eql(u8, Vapor.currentPath(), base_path)) Sidebar();
    render_page();
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
    if (!Vapor.isDesktop()) return;
    const current_path = Vapor.currentPath();
    Row().id("components-sidebar").style(&.{
        .position = .{ .type = .fixed, .top = .px(60), .left = .percent(2), .z_index = 999 },
        .size = .hw(.percent(100), .mobileDesktopPercent(100, 14)),
    }).children({
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
