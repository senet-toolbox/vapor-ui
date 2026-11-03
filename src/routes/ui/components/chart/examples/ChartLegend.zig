const Vapor = @import("vapor");
const Chart = @import("opaque-ui").Chart;

// Click a legend item to hide its series, and again to bring it back; the
// axes fit what is left. Pointing at an item fades the others.
var chart: Chart = undefined;

const desktop = [_]Chart.Point{
    .{ .x = 1, .y = 186 },
    .{ .x = 2, .y = 305 },
    .{ .x = 3, .y = 237 },
    .{ .x = 4, .y = 73 },
};

const mobile = [_]Chart.Point{
    .{ .x = 1, .y = 80 },
    .{ .x = 2, .y = 200 },
    .{ .x = 3, .y = 120 },
    .{ .x = 4, .y = 190 },
};

pub fn init() void {
    chart = Chart.init(Vapor.arena(.persist), .{ .height = 320 });
    chart.addSeries(.bar, "Desktop", &desktop, .{}) catch unreachable;
    chart.addSeries(.bar, "Mobile", &mobile, .{}) catch unreachable;
    chart.xAxis(.{ .label = "Month" });
    chart.yAxis(.{ .label = "Visitors" });
    // .row runs along the top or bottom, .column down the side.
    chart.legend(.{ .position = .top_right, .direction = .row });
    chart.build() catch unreachable;
}

// The same from your own code. Items count from 0, in legend order.
pub fn showMobileOnly() void {
    chart.setShown(0, false);
    chart.setShown(1, true);
}
