const Breadcrumb = @import("opaque-ui").Breadcrumb;

pub fn render() void {
    Breadcrumb.render(&.{
        .{ .label = "Home", .url = "/", .icon = .home },
        .{ .label = "Templates", .url = "/ui/templates" },
        .{ .label = "Components", .url = "/ui/components" },
        .{ .label = "Navigation", .url = "/ui/components/breadcrumb" },
        .{ .label = "Breadcrumb" },
    }, .{ .separator = .slash });
}
