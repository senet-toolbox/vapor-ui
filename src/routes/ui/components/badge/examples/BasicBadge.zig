const Vapor = @import("vapor");
const Row = Vapor.Row;
const Badge = @import("opaque-ui").Badge;

pub fn render() void {
    Row().spacing(10).layout(.center).wrap(.wrap).children({
        Badge.render(.{ .text = "Draft" });
        Badge.render(.{ .text = "New", .tone = .tint });
        Badge.render(.{ .text = "Active", .tone = .success, .dot = true });
        Badge.render(.{ .text = "Pending", .tone = .warning, .dot = true });
        Badge.render(.{ .text = "Failed", .tone = .danger, .icon = .x_lg });
        Badge.render(.{ .text = "v3.8.0", .tone = .outline });
    });
}
