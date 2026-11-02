const Vapor = @import("vapor");
const Chart = @import("opaque-ui").Chart;

// Labels, grid lines and legend text follow your theme in light and dark
// mode. Everything else is set per chart, per axis or per series.
var chart: Chart = undefined;

const visits = [_]Chart.Point{
    .{ .x = 1, .y = 30 },
    .{ .x = 2, .y = 55 },
    .{ .x = 3, .y = 42 },
    .{ .x = 4, .y = 80 },
};

pub fn init() void {
    chart = Chart.init(Vapor.arena(.persist), .{
        .height = 320,
        // Series without a colour of their own take these in turn.
        .palette = .{ .colors = &.{ "#6366f1", "#10b981" } },
    });
    chart.addSeries(.area_smooth, "Visits", &visits, .{
        .fill_opacity = 0.15,
        .stroke_width = 3,
        .show_dots = false,
    }) catch unreachable;
    chart.xAxis(.{ .label = "Week", .grid = false, .color = .palette(.border_color_light) });
    chart.yAxis(.{ .label = "Visits", .grid = true });
    chart.legend(.{ .position = .top_left, .text_color = .palette(.tint) });
    chart.build() catch unreachable;
}
