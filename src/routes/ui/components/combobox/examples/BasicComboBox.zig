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
    // Starts with Pending ticked.
    combobox.default(.{ .value = Status.pending, .label = "Pending" });
}

pub fn render() void {
    combobox.render();
}
