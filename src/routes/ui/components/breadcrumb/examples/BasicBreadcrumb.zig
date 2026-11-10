const Breadcrumb = @import("opaque-ui").Breadcrumb;

pub fn render() void {
    Breadcrumb.render(&.{
        .{ .label = "Home", .url = "/" },
        .{ .label = "Components", .url = "/ui/components" },
        .{ .label = "Breadcrumb" },
    }, .{});
}
