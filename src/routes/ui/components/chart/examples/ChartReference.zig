const Vapor = @import("vapor");
const Chart = @import("opaque-ui").Chart;

// A reference line marks a value across the plot: a target, a limit, an
// average. Give it a `to` and it shades a band instead.
var chart: Chart = undefined;

const sales = [_]Chart.Point{
    .{ .x = 1, .y = 90 },
    .{ .x = 2, .y = 70 },
    .{ .x = 3, .y = 140 },
    .{ .x = 4, .y = 120 },
};

pub fn init() void {
    chart = Chart.init(Vapor.arena(.persist), .{ .height = 320 });
    chart.addSeries(.area, "Sales", &sales, .{}) catch unreachable;
    chart.xAxis(.{ .label = "Month" });
    chart.yAxis(.{ .label = "USD ($)" });
    chart.reference(.{ .value = 100, .label = "Target" }) catch unreachable;
    chart.reference(.{ .value = 130, .to = 150, .label = "Stretch", .color = .hex("#10b981") }) catch unreachable;
    // Standing at an x value
    chart.reference(.{ .axis = .x, .value = 3, .label = "Launch", .dashed = false }) catch unreachable;
    chart.build() catch unreachable;
}
