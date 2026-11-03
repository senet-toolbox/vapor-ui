const std = @import("std");
const Vapor = @import("vapor");
const Chart = @import("opaque-ui").Chart;

// A formatter writes a value the way it should read: on an axis's ticks,
// and for the y axis in the tooltip too. A point's label names its x on
// the axis and in the tooltip, in place of the number.
var chart: Chart = undefined;

const revenue = [_]Chart.Point{
    .{ .x = 1, .y = 1250, .label = "Jan" },
    .{ .x = 2, .y = 3400, .label = "Feb" },
    .{ .x = 3, .y = 2875.5, .label = "Mar" },
    .{ .x = 4, .y = 4100, .label = "Apr" },
};

// Writes into buf and returns what it wrote.
fn dollars(value: f64, buf: []u8) []const u8 {
    if (@abs(value) >= 1000) return std.fmt.bufPrint(buf, "${d:.1}k", .{value / 1000}) catch "";
    return std.fmt.bufPrint(buf, "${d:.0}", .{value}) catch "";
}

pub fn init() void {
    chart = Chart.init(Vapor.arena(.persist), .{ .height = 320 });
    chart.addSeries(.line, "Revenue", &revenue, .{}) catch unreachable;
    chart.xAxis(.{ .tick_count = 4 });
    chart.yAxis(.{ .label = "Revenue", .formatter = dollars });
    chart.build() catch unreachable;
}
