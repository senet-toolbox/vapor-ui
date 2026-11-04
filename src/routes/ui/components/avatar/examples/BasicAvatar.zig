const Vapor = @import("vapor");
const Row = Vapor.Row;
const Avatar = @import("opaque-ui").Avatar;

pub fn render() void {
    Row().spacing(16).layout(.center).wrap(.wrap).children({
        // A photo
        Avatar.render(.{ .name = "John Lennon", .src = "/assets/lenon.webp", .size = 48 });
        // No photo: initials, on a colour picked from the name
        Avatar.render(.{ .name = "Sarah Chen", .size = 48 });
        // A photo that won't load leaves the initials
        Avatar.render(.{ .name = "Mike Johnson", .src = "/assets/missing.webp", .size = 48 });
        // A status dot, and a rounded square
        Avatar.render(.{ .name = "Emily Davis", .size = 48, .status = .online });
        Avatar.render(.{ .name = "Alex Kim", .size = 48, .status = .busy, .shape = .rounded });
        // Sizes
        Avatar.render(.{ .name = "Small One", .size = 24 });
        Avatar.render(.{ .name = "Large One", .size = 64 });
    });
}
