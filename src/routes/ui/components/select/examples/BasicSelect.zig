// examples/BasicSelect.zig
const Vapor = @import("vapor");
const Opaque = @import("opaque-ui");
const Select = Opaque.Select;

const Status = enum {
    pending,
    success,
    err,
};

var select: Select(Status) = undefined;

pub fn init() void {
    select = .fromItems(&.{
        .{ .value = Status.pending, .label = "Pending" },
        .{ .value = Status.success, .label = "Success" },
        .{ .value = Status.err, .label = "Error" },
    });
}

pub fn render() void {
    select.render();
}
