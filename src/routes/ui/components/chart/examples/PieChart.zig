const Vapor = @import("vapor");
const Chart = @import("opaque-ui").Chart;

var pie: Chart = undefined;

// Each slice's label names it in the legend and beside the pie.
const traffic = [_]Chart.Point{
    .{ .x = 0, .y = 35, .label = "Direct" },
    .{ .x = 0, .y = 40, .label = "Search" },
    .{ .x = 0, .y = 15, .label = "Social" },
    .{ .x = 0, .y = 10, .label = "Email" },
};

pub fn init() void {
    pie = Chart.init(Vapor.arena(.persist), .{
        .height = 400,
        // The slices take these colours in turn.
        .palette = .{ .colors = &.{ "#3b82f6", "#8b5cf6", "#f59e0b", "#10b981" } },
    });
    // .donut for a ring instead
    pie.addSeries(.pie, "Traffic", &traffic, .{}) catch unreachable;
    pie.legend(.{ .position = .top_right, .direction = .row });
    pie.build() catch unreachable;
}

pub fn render() void {
    pie.render();
}
