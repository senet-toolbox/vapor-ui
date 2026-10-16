const Vapor = @import("vapor");
const Opaque = @import("opaque-ui");
const ComboBox = Opaque.ComboBox;

const Status = enum {
    pending,
    success,
    err,
};

var combobox: ComboBox(Status) = undefined;
pub fn init() void {
    combobox = .fromItems(&.{
        .{ .value = Status.pending, .label = "Pending" },
        .{ .value = Status.success, .label = "Success" },
        .{ .value = Status.err, .label = "Error" },
    });
    combobox.trigger = "Status";

    Vapor.Page(.{ .src = @src() }, render, null);
}

fn render() void {
    combobox.render();
}
