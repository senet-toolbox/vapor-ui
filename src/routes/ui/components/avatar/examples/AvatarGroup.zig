const Avatar = @import("opaque-ui").Avatar;

const team = [_]Avatar.Options{
    .{ .name = "Sarah Chen" },
    .{ .name = "Mike Johnson" },
    .{ .name = "Emily Davis" },
    .{ .name = "Alex Kim" },
    .{ .name = "Priya Patel" },
    .{ .name = "Tom Berg" },
};

pub fn render() void {
    // Four shown, then "+2" for the rest.
    Avatar.group(&team, 4);
}
