const std = @import("std");
const Vapor = @import("vapor");
const Chart = @import("opaque-ui").Chart;

// Drag a box over a chart to zoom into it. Double-click the chart, or press
// the Reset zoom button it shows, to zoom back out.
var chart: Chart = undefined;

const sales = [_]Chart.Point{
    .{ .x = 1, .y = 90 },
    .{ .x = 2, .y = 70 },
    .{ .x = 3, .y = 45 },
    .{ .x = 4, .y = 65 },
};

// Called with the ranges the chart zoomed to.
fn onZoom(x_min: f64, x_max: f64, y_min: f64, y_max: f64) void {
    std.log.info("x {d:.1} to {d:.1}, y {d:.1} to {d:.1}", .{ x_min, x_max, y_min, y_max });
}

pub fn init() void {
    chart = Chart.init(Vapor.arena(.persist), .{ .height = 400 });
    chart.addSeries(.line, "Sales", &sales, .{}) catch unreachable;
    chart.xAxis(.{ .label = "Month" });
    chart.yAxis(.{ .label = "USD ($)" });
    chart.onendselection = onZoom;
    // Or turn zooming off:
    // chart.zoom_enabled = false;
    chart.build() catch unreachable;
}

// Zooms back out from your own code, say from a button.
pub fn showAll() void {
    chart.resetZoom();
}
