const Vapor = @import("vapor");
const Chart = @import("opaque-ui").Chart;

// A chart keeps its state between renders, so it lives in a global and is
// set up once, in your page's init.
var chart: Chart = undefined;

const sales = [_]Chart.Point{
    .{ .x = 1, .y = 90 },
    .{ .x = 2, .y = 70 },
    .{ .x = 3, .y = 45 },
    .{ .x = 4, .y = 65 },
    .{ .x = 5, .y = 120 },
    .{ .x = 6, .y = 110 },
};

pub fn init() void {
    chart = Chart.init(Vapor.arena(.persist), .{ .height = 400 });
    // .line, .line_smooth, .area, .area_smooth, .bar, .stacked_bar,
    // .scatter, .pie or .donut
    chart.addSeries(.line_smooth, "Sales", &sales, .{ .color = .palette(.tint) }) catch unreachable;
    chart.xAxis(.{ .label = "Month", .tick_count = 6 });
    chart.yAxis(.{ .label = "USD ($)", .tick_count = 5 });
    chart.legend(.{ .position = .top_right, .direction = .row });
    chart.build() catch unreachable;
}

pub fn render() void {
    // The chart fills its parent's width, at the height set above.
    chart.render();
}
