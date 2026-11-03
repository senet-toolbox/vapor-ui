const Vapor = @import("vapor");
const Hero = @import("../../../../components/Hero.zig").Hero;
const CodeBox = @import("../CodeBox.zig").CodeBox;
const Docs = @import("../Docs.zig");
const Row = Vapor.Row;
const Text = Vapor.Text;
const Stack = Vapor.Stack;
const Opaque = @import("opaque-ui");
const Tabs = Opaque.Tabs;
const Chart = Opaque.Chart;
const SyntaxHighlighter = @import("vaporize").SyntaxHighlighter;
const std = @import("std");

var chart: Chart = undefined;
var requests_chart: Chart = undefined;
var pie_chart: Chart = undefined;
var area_chart: Chart = undefined;

var hl_basic: SyntaxHighlighter = undefined;
var hl_pie: SyntaxHighlighter = undefined;
var hl_zoom: SyntaxHighlighter = undefined;
var hl_style: SyntaxHighlighter = undefined;
var hl_legend: SyntaxHighlighter = undefined;
var hl_format: SyntaxHighlighter = undefined;
var hl_reference: SyntaxHighlighter = undefined;
var hl_api: SyntaxHighlighter = undefined;

// The area chart's ticks and tooltip read in dollars.
fn dollars(value: f64, buf: []u8) []const u8 {
    return std.fmt.bufPrint(buf, "${d:.0}", .{value}) catch "";
}

const data = [_]Chart.Point{
    .{ .x = 1, .y = 90 },
    .{ .x = 2, .y = 70 },
    .{ .x = 3, .y = 45 },
    .{ .x = 4, .y = 50 },
    .{ .x = 5, .y = 65 },
    .{ .x = 6, .y = 55 },
    .{ .x = 7, .y = 75 },
    .{ .x = 8, .y = 85 },
    .{ .x = 9, .y = 95 },
    .{ .x = 10, .y = 100 },
    .{ .x = 11, .y = 110 },
    .{ .x = 12, .y = 120 },
    .{ .x = 13, .y = 80 },
    .{ .x = 14, .y = 70 },
    .{ .x = 15, .y = 120 },
    .{ .x = 16, .y = 110 },
    .{ .x = 17, .y = 150 },
    .{ .x = 20, .y = 70 },
    .{ .x = 21, .y = 120 },
    .{ .x = 22, .y = 110 },
    .{ .x = 23, .y = 190 },
    .{ .x = 24, .y = 120 },
    .{ .x = 25, .y = 110 },
    .{ .x = 26, .y = 30 },
    .{ .x = 27, .y = 160 },
    .{ .x = 28, .y = 140 },
};

const data_pie = [_]Chart.Point{
    .{ .x = 25, .y = 35, .label = "Direct" },
    .{ .x = 25, .y = 40, .label = "Search" },
    .{ .x = 25, .y = 15, .label = "Social" },
    .{ .x = 25, .y = 10, .label = "Email" },
};

// Define colors for each status code category
// Greys that show on a light page and a dark one.
const gray = Vapor.Types.Color.hex("#64748b"); // 1/2XX
const light_gray = Vapor.Types.Color.hex("#94a3b8"); // 3XX
const yellow = Vapor.Types.Color.hex("#FF8800"); // 4XX
const red = Vapor.Types.Color.hex("#FF2B00"); // 5XX

// Create data points with stacked segments
// Each point represents a time bucket
const data_requests = [_]Chart.Point{
    .{ .x = 1, .stack = &.{ .{ .value = 50, .color = gray }, .{ .value = 30, .color = light_gray }, .{ .value = 15, .color = yellow }, .{ .value = 20, .color = red } } },
    .{ .x = 2, .stack = &.{ .{ .value = 40, .color = gray }, .{ .value = 25, .color = light_gray }, .{ .value = 25, .color = yellow }, .{ .value = 30, .color = red } } },
    .{ .x = 3, .stack = &.{ .{ .value = 60, .color = gray }, .{ .value = 35, .color = light_gray }, .{ .value = 10, .color = yellow }, .{ .value = 20, .color = red } } },
    .{ .x = 4, .stack = &.{ .{ .value = 45, .color = gray }, .{ .value = 20, .color = light_gray }, .{ .value = 30, .color = yellow }, .{ .value = 40, .color = red } } },
    .{ .x = 5, .stack = &.{ .{ .value = 55, .color = gray }, .{ .value = 28, .color = light_gray }, .{ .value = 18, .color = yellow }, .{ .value = 25, .color = red } } },
    .{ .x = 6, .stack = &.{ .{ .value = 70, .color = gray }, .{ .value = 40, .color = light_gray }, .{ .value = 12, .color = yellow }, .{ .value = 15, .color = red } } },
    .{ .x = 7, .stack = &.{ .{ .value = 35, .color = gray }, .{ .value = 22, .color = light_gray }, .{ .value = 28, .color = yellow }, .{ .value = 35, .color = red } } },
    .{ .x = 8, .stack = &.{ .{ .value = 48, .color = gray }, .{ .value = 32, .color = light_gray }, .{ .value = 20, .color = yellow }, .{ .value = 22, .color = red } } },
    .{ .x = 9, .stack = &.{ .{ .value = 62, .color = gray }, .{ .value = 38, .color = light_gray }, .{ .value = 8, .color = yellow }, .{ .value = 12, .color = red } } },
    .{ .x = 10, .stack = &.{ .{ .value = 42, .color = gray }, .{ .value = 18, .color = light_gray }, .{ .value = 35, .color = yellow }, .{ .value = 45, .color = red } } },
    .{ .x = 11, .stack = &.{ .{ .value = 58, .color = gray }, .{ .value = 33, .color = light_gray }, .{ .value = 14, .color = yellow }, .{ .value = 18, .color = red } } },
    .{ .x = 12, .stack = &.{ .{ .value = 75, .color = gray }, .{ .value = 45, .color = light_gray }, .{ .value = 10, .color = yellow }, .{ .value = 10, .color = red } } },
    .{ .x = 13, .stack = &.{ .{ .value = 30, .color = gray }, .{ .value = 15, .color = light_gray }, .{ .value = 40, .color = yellow }, .{ .value = 50, .color = red } } },
    .{ .x = 14, .stack = &.{ .{ .value = 52, .color = gray }, .{ .value = 30, .color = light_gray }, .{ .value = 22, .color = yellow }, .{ .value = 28, .color = red } } },
    .{ .x = 15, .stack = &.{ .{ .value = 65, .color = gray }, .{ .value = 42, .color = light_gray }, .{ .value = 15, .color = yellow }, .{ .value = 16, .color = red } } },
    .{ .x = 16, .stack = &.{ .{ .value = 38, .color = gray }, .{ .value = 24, .color = light_gray }, .{ .value = 32, .color = yellow }, .{ .value = 38, .color = red } } },
    .{ .x = 17, .stack = &.{.{ .value = 120, .color = red }} },
    .{ .x = 18, .stack = &.{.{ .value = 140, .color = red }} },
    .{ .x = 19, .stack = &.{.{ .value = 90, .color = red }} },
    .{ .x = 20, .stack = &.{ .{ .value = 68, .color = gray }, .{ .value = 44, .color = light_gray }, .{ .value = 12, .color = yellow }, .{ .value = 14, .color = red } } },
    .{ .x = 21, .stack = &.{ .{ .value = 34, .color = gray }, .{ .value = 20, .color = light_gray }, .{ .value = 36, .color = yellow }, .{ .value = 42, .color = red } } },
    .{ .x = 22, .stack = &.{ .{ .value = 80, .color = gray }, .{ .value = 50, .color = light_gray }, .{ .value = 6, .color = yellow }, .{ .value = 6, .color = red } } },
    .{ .x = 23, .stack = &.{.{ .value = 60, .color = red }} },
    .{ .x = 24, .stack = &.{.{ .value = 74, .color = red }} },
    .{ .x = 25, .stack = &.{ .{ .value = 63, .color = gray }, .{ .value = 40, .color = light_gray } } },
    .{ .x = 26, .stack = &.{ .{ .value = 41, .color = gray }, .{ .value = 23, .color = light_gray }, .{ .value = 30, .color = yellow }, .{ .value = 36, .color = red } } },
    .{ .x = 27, .stack = &.{ .{ .value = 77, .color = gray }, .{ .value = 46, .color = light_gray }, .{ .value = 9, .color = yellow }, .{ .value = 11, .color = red } } },
    .{ .x = 28, .stack = &.{ .{ .value = 36, .color = gray }, .{ .value = 19, .color = light_gray }, .{ .value = 34, .color = yellow }, .{ .value = 44, .color = red } } },
    .{ .x = 29, .stack = &.{ .{ .value = 59, .color = gray }, .{ .value = 37, .color = light_gray }, .{ .value = 16, .color = yellow }, .{ .value = 19, .color = red } } },
    .{ .x = 30, .stack = &.{ .{ .value = 71, .color = gray }, .{ .value = 43, .color = light_gray }, .{ .value = 11, .color = yellow }, .{ .value = 13, .color = red } } },
    .{ .x = 31, .stack = &.{ .{ .value = 49, .color = gray }, .{ .value = 29, .color = light_gray } } },
    .{ .x = 32, .stack = &.{ .{ .value = 66, .color = gray }, .{ .value = 41, .color = light_gray } } },
    .{ .x = 33, .stack = &.{ .{ .value = 39, .color = gray }, .{ .value = 21, .color = light_gray } } },
    .{ .x = 34, .stack = &.{ .{ .value = 85, .color = gray }, .{ .value = 52, .color = light_gray } } },
    .{ .x = 35, .stack = &.{ .{ .value = 47, .color = gray }, .{ .value = 27, .color = light_gray } } },
    .{ .x = 36, .stack = &.{ .{ .value = 61, .color = gray }, .{ .value = 39, .color = light_gray } } },
    .{ .x = 37, .stack = &.{ .{ .value = 53, .color = gray }, .{ .value = 31, .color = light_gray } } },
    .{ .x = 38, .stack = &.{ .{ .value = 74, .color = gray }, .{ .value = 47, .color = light_gray } } },
    .{ .x = 39, .stack = &.{ .{ .value = 43, .color = gray }, .{ .value = 25, .color = light_gray } } },
    .{ .x = 40, .stack = &.{ .{ .value = 67, .color = gray }, .{ .value = 42, .color = light_gray } } },
    .{ .x = 41, .stack = &.{ .{ .value = 50, .color = gray }, .{ .value = 30, .color = light_gray } } },
    .{ .x = 42, .stack = &.{ .{ .value = 40, .color = gray }, .{ .value = 25, .color = light_gray } } },
    .{ .x = 43, .stack = &.{ .{ .value = 60, .color = gray }, .{ .value = 35, .color = light_gray }, .{ .value = 10, .color = yellow }, .{ .value = 20, .color = red } } },
    .{ .x = 44, .stack = &.{ .{ .value = 45, .color = gray }, .{ .value = 20, .color = light_gray }, .{ .value = 30, .color = yellow }, .{ .value = 40, .color = red } } },
    .{ .x = 45, .stack = &.{ .{ .value = 55, .color = gray }, .{ .value = 28, .color = light_gray }, .{ .value = 18, .color = yellow }, .{ .value = 25, .color = red } } },
    .{ .x = 46, .stack = &.{ .{ .value = 70, .color = gray }, .{ .value = 40, .color = light_gray }, .{ .value = 12, .color = yellow }, .{ .value = 15, .color = red } } },
    .{ .x = 47, .stack = &.{ .{ .value = 35, .color = gray }, .{ .value = 22, .color = light_gray }, .{ .value = 28, .color = yellow }, .{ .value = 35, .color = red } } },
    .{ .x = 48, .stack = &.{ .{ .value = 48, .color = gray }, .{ .value = 32, .color = light_gray }, .{ .value = 20, .color = yellow }, .{ .value = 22, .color = red } } },
    .{ .x = 49, .stack = &.{ .{ .value = 62, .color = gray }, .{ .value = 38, .color = light_gray }, .{ .value = 8, .color = yellow }, .{ .value = 12, .color = red } } },
    .{ .x = 50, .stack = &.{ .{ .value = 42, .color = gray }, .{ .value = 18, .color = light_gray }, .{ .value = 35, .color = yellow }, .{ .value = 45, .color = red } } },
    .{ .x = 51, .stack = &.{ .{ .value = 58, .color = gray }, .{ .value = 33, .color = light_gray }, .{ .value = 14, .color = yellow }, .{ .value = 18, .color = red } } },
    .{ .x = 52, .stack = &.{ .{ .value = 75, .color = gray }, .{ .value = 45, .color = light_gray }, .{ .value = 10, .color = yellow }, .{ .value = 10, .color = red } } },
    .{ .x = 53, .stack = &.{ .{ .value = 30, .color = gray }, .{ .value = 15, .color = light_gray }, .{ .value = 40, .color = yellow }, .{ .value = 50, .color = red } } },
    .{ .x = 54, .stack = &.{ .{ .value = 52, .color = gray }, .{ .value = 30, .color = light_gray }, .{ .value = 22, .color = yellow }, .{ .value = 28, .color = red } } },
    .{ .x = 55, .stack = &.{ .{ .value = 65, .color = gray }, .{ .value = 42, .color = light_gray }, .{ .value = 15, .color = yellow }, .{ .value = 16, .color = red } } },
    .{ .x = 56, .stack = &.{ .{ .value = 38, .color = gray }, .{ .value = 24, .color = light_gray }, .{ .value = 32, .color = yellow }, .{ .value = 38, .color = red } } },
    .{ .x = 57, .stack = &.{.{ .value = 115, .color = red }} },
    .{ .x = 58, .stack = &.{.{ .value = 135, .color = red }} },
    .{ .x = 59, .stack = &.{.{ .value = 85, .color = red }} },
    .{ .x = 60, .stack = &.{ .{ .value = 64, .color = gray }, .{ .value = 38, .color = light_gray }, .{ .value = 14, .color = yellow }, .{ .value = 16, .color = red } } },
    .{ .x = 61, .stack = &.{ .{ .value = 32, .color = gray }, .{ .value = 18, .color = light_gray }, .{ .value = 38, .color = yellow }, .{ .value = 44, .color = red } } },
    .{ .x = 62, .stack = &.{ .{ .value = 78, .color = gray }, .{ .value = 48, .color = light_gray }, .{ .value = 8, .color = yellow }, .{ .value = 8, .color = red } } },
    .{ .x = 63, .stack = &.{.{ .value = 55, .color = red }} },
    .{ .x = 64, .stack = &.{.{ .value = 68, .color = red }} },
    .{ .x = 65, .stack = &.{ .{ .value = 60, .color = gray }, .{ .value = 38, .color = light_gray } } },
    .{ .x = 66, .stack = &.{ .{ .value = 45, .color = gray }, .{ .value = 26, .color = light_gray } } },
    .{ .x = 67, .stack = &.{ .{ .value = 72, .color = gray }, .{ .value = 44, .color = light_gray } } },
    .{ .x = 68, .stack = &.{ .{ .value = 35, .color = gray }, .{ .value = 20, .color = light_gray } } },
    .{ .x = 69, .stack = &.{ .{ .value = 82, .color = gray }, .{ .value = 50, .color = light_gray } } },
    .{ .x = 70, .stack = &.{ .{ .value = 51, .color = gray }, .{ .value = 30, .color = light_gray }, .{ .value = 20, .color = yellow }, .{ .value = 25, .color = red } } },
    .{ .x = 71, .stack = &.{ .{ .value = 44, .color = gray }, .{ .value = 25, .color = light_gray }, .{ .value = 30, .color = yellow }, .{ .value = 35, .color = red } } },
    .{ .x = 72, .stack = &.{ .{ .value = 68, .color = gray }, .{ .value = 42, .color = light_gray } } },
    .{ .x = 73, .stack = &.{ .{ .value = 55, .color = gray }, .{ .value = 32, .color = light_gray } } },
    .{ .x = 74, .stack = &.{ .{ .value = 48, .color = gray }, .{ .value = 28, .color = light_gray } } },
    .{ .x = 75, .stack = &.{ .{ .value = 65, .color = gray }, .{ .value = 40, .color = light_gray }, .{ .value = 15, .color = yellow }, .{ .value = 18, .color = red } } },
    .{ .x = 76, .stack = &.{ .{ .value = 52, .color = gray }, .{ .value = 34, .color = light_gray }, .{ .value = 18, .color = yellow }, .{ .value = 22, .color = red } } },
    .{ .x = 77, .stack = &.{ .{ .value = 41, .color = gray }, .{ .value = 24, .color = light_gray }, .{ .value = 35, .color = yellow }, .{ .value = 40, .color = red } } },
    .{ .x = 78, .stack = &.{ .{ .value = 73, .color = gray }, .{ .value = 46, .color = light_gray }, .{ .value = 10, .color = yellow }, .{ .value = 12, .color = red } } },
    .{ .x = 79, .stack = &.{ .{ .value = 39, .color = gray }, .{ .value = 22, .color = light_gray }, .{ .value = 25, .color = yellow }, .{ .value = 30, .color = red } } },
    .{ .x = 80, .stack = &.{ .{ .value = 57, .color = gray }, .{ .value = 35, .color = light_gray }, .{ .value = 15, .color = yellow }, .{ .value = 18, .color = red } } },
    .{ .x = 81, .stack = &.{.{ .value = 125, .color = red }} },
    .{ .x = 82, .stack = &.{.{ .value = 155, .color = red }} },
    .{ .x = 83, .stack = &.{.{ .value = 110, .color = red }} },
    .{ .x = 84, .stack = &.{ .{ .value = 66, .color = gray }, .{ .value = 40, .color = light_gray } } },
    .{ .x = 85, .stack = &.{ .{ .value = 43, .color = gray }, .{ .value = 25, .color = light_gray } } },
    .{ .x = 86, .stack = &.{ .{ .value = 70, .color = gray }, .{ .value = 42, .color = light_gray } } },
    .{ .x = 87, .stack = &.{ .{ .value = 38, .color = gray }, .{ .value = 19, .color = light_gray } } },
    .{ .x = 88, .stack = &.{ .{ .value = 80, .color = gray }, .{ .value = 52, .color = light_gray } } },
    .{ .x = 89, .stack = &.{ .{ .value = 45, .color = gray }, .{ .value = 28, .color = light_gray } } },
    .{ .x = 90, .stack = &.{ .{ .value = 55, .color = gray }, .{ .value = 33, .color = light_gray } } },
    .{ .x = 91, .stack = &.{ .{ .value = 62, .color = gray }, .{ .value = 38, .color = light_gray }, .{ .value = 12, .color = yellow }, .{ .value = 14, .color = red } } },
    .{ .x = 92, .stack = &.{ .{ .value = 48, .color = gray }, .{ .value = 27, .color = light_gray }, .{ .value = 28, .color = yellow }, .{ .value = 35, .color = red } } },
    .{ .x = 93, .stack = &.{ .{ .value = 75, .color = gray }, .{ .value = 48, .color = light_gray }, .{ .value = 8, .color = yellow }, .{ .value = 10, .color = red } } },
    .{ .x = 94, .stack = &.{ .{ .value = 33, .color = gray }, .{ .value = 15, .color = light_gray }, .{ .value = 42, .color = yellow }, .{ .value = 55, .color = red } } },
    .{ .x = 95, .stack = &.{ .{ .value = 59, .color = gray }, .{ .value = 36, .color = light_gray }, .{ .value = 14, .color = yellow }, .{ .value = 18, .color = red } } },
    .{ .x = 96, .stack = &.{.{ .value = 95, .color = red }} },
    .{ .x = 97, .stack = &.{.{ .value = 80, .color = red }} },
    .{ .x = 98, .stack = &.{ .{ .value = 64, .color = gray }, .{ .value = 41, .color = light_gray } } },
    .{ .x = 99, .stack = &.{ .{ .value = 47, .color = gray }, .{ .value = 29, .color = light_gray } } },
    .{ .x = 100, .stack = &.{ .{ .value = 72, .color = gray }, .{ .value = 45, .color = light_gray }, .{ .value = 10, .color = yellow }, .{ .value = 12, .color = red } } },
};

pub fn init() void {
    chart = Chart.init(Vapor.arena(.persist), .{
        .height = 400,
        .width = @intFromFloat(Vapor.lib.browser_width * 0.6),
        .palette = .{ .colors = &.{ "#3b82f6", "#ef4444" } },
    });

    chart.addSeries(.line_smooth, "Sales", &data, .{ .color = .palette(.tint) }) catch unreachable;
    chart.xAxis(.{ .label = "Month", .tick_count = 6 });
    chart.yAxis(.{ .label = "USD ($)", .tick_count = 5 });
    chart.legend(.{ .position = .top_right, .direction = .row });
    chart.build() catch unreachable;

    pie_chart = Chart.init(Vapor.arena(.persist), .{
        .height = 400,
        .width = @intFromFloat(Vapor.lib.browser_width * 0.6),
        .palette = .{ .colors = &.{ "#3b82f6", "#8b5cf6", "#f59e0b", "#10b981" } },
    });
    pie_chart.addSeries(.pie, "Traffic", &data_pie, .{}) catch unreachable;
    pie_chart.legend(.{ .position = .top_right, .direction = .row });
    pie_chart.build() catch unreachable;

    area_chart = Chart.init(Vapor.arena(.persist), .{
        .height = 400,
        .width = @intFromFloat(Vapor.lib.browser_width * 0.6),
        .palette = .{ .colors = &.{ "#3b82f6", "#ef4444", "#f59e0b", "#10b981" } },
    });

    area_chart.addSeries(.area, "Sales", &data, .{ .color = .palette(.tint) }) catch unreachable;
    area_chart.xAxis(.{ .label = "Month", .tick_count = 6 });
    area_chart.yAxis(.{ .label = "USD ($)", .tick_count = 5, .formatter = dollars });
    area_chart.legend(.{ .position = .top_right, .direction = .row });
    area_chart.reference(.{ .value = 100, .label = "Target" }) catch unreachable;
    area_chart.build() catch unreachable;

    // Initialize chart
    requests_chart = Chart.init(Vapor.arena(.persist), .{
        .height = 400,
        .width = @intFromFloat(Vapor.lib.browser_width * 0.6),
        .palette = .{ .colors = &.{ "#6366f1", "#10b981", "#f59e0b" } },
    });

    requests_chart.addSeries(.stacked_bar, "1/2XX", &data_requests, .{
        .color = gray,
        .bar_radius = 0,
        .border = .top(1, .palette(.background)),
        .stroke = .palette(.background),
        .stroke_width = 0.5,
    }) catch unreachable;

    requests_chart.xAxis(.{ .label = "Time", .tick_count = 4 });
    requests_chart.yAxis(.{ .label = "Requests", .tick_count = 5 });
    requests_chart.legend(.{
        .position = .top_right,
        .direction = .row,
        .text_color = .palette(.text_color),
        .fields = &.{
            .{ .title = "3XX", .color = light_gray, .background = light_gray },
            .{ .title = "4XX", .color = yellow, .background = yellow },
            .{ .title = "5XX", .color = red, .background = red },
        },
    });

    requests_chart.build() catch unreachable;

    hl_basic = Docs.highlighter(@embedFile("examples/BasicChart.zig"));
    hl_pie = Docs.highlighter(@embedFile("examples/PieChart.zig"));
    hl_zoom = Docs.highlighter(@embedFile("examples/ChartZoom.zig"));
    hl_style = Docs.highlighter(@embedFile("examples/ChartStyle.zig"));
    hl_legend = Docs.highlighter(@embedFile("examples/ChartLegend.zig"));
    hl_format = Docs.highlighter(@embedFile("examples/ChartFormat.zig"));
    hl_reference = Docs.highlighter(@embedFile("examples/ChartReference.zig"));
    hl_api = Docs.highlighter(
        \\const Chart = @import("opaque-ui").Chart;
        \\
        \\pub fn init(allocator: std.mem.Allocator, config: Config) Chart
        \\pub fn addSeries(self: *Chart, series_type: SeriesType, name: []const u8, data: []const Point, options: SeriesOptions) !void
        \\pub fn xAxis(self: *Chart, config: AxisConfig) void
        \\pub fn yAxis(self: *Chart, config: AxisConfig) void
        \\pub fn legend(self: *Chart, config: LegendConfig) void
        \\pub fn reference(self: *Chart, ref: Reference) !void
        \\// Lays the chart out; call it once set up, and after changing it.
        \\pub fn build(self: *Chart) !void
        \\pub fn render(self: *Chart) void
        \\
        \\// New data for named series, drawn without a full rebuild.
        \\pub fn updateSeries(self: *Chart, series: []const SeriesData) void
        \\pub fn isShown(self: *const Chart, index: usize) bool
        \\pub fn setShown(self: *Chart, index: usize, shown: bool) void
        \\pub fn resetZoom(self: *Chart) void
        \\
        \\// Called with the ranges a zoom went to.
        \\onendselection: ?*const fn (x_min: f64, x_max: f64, y_min: f64, y_max: f64) void
    );

    Vapor.Page(.{ .src = @src() }, render, null);
}

const config_fields = [_]Docs.Field{
    .{ .name = "height", .type = "u32", .default = "400", .desc = "The plot's height in pixels. Its width follows its parent's." },
    .{ .name = "margin", .type = "Margin", .default = ".{ .top = 20, .right = 20, .bottom = 40, .left = 50 }", .desc = "Room around the plot for the axes' labels." },
    .{ .name = "palette", .type = "Palette", .default = "category10", .desc = "Colours for series, and a pie's slices, that set none of their own." },
    .{ .name = "zoom", .type = "ZoomMode", .default = ".x", .desc = "What a drag zooms: .x a stretch of x, the y axis fitted to it; .xy a box on both axes; .none nothing." },
    .{ .name = "animate", .type = "bool", .default = "true", .desc = "The chart fades in when it first shows; never for someone whose system asks for less motion." },
    .{ .name = "empty_text", .type = "[]const u8", .default = "\"No data\"", .desc = "Shown in place of the plot while no series has a point." },
    .{ .name = "tooltip_total", .type = "?bool", .default = "null", .desc = "A Total row in the tooltip. Unset, only stacked bars have one." },
    .{ .name = "show_line", .type = "bool", .default = "false", .desc = "A vertical line through the hovered x." },
    .{ .name = "background", .type = "?Color", .default = "null", .desc = "Fills the chart's box." },
};

const axis_fields = [_]Docs.Field{
    .{ .name = "label", .type = "?[]const u8", .default = "null", .desc = "The axis's name, beside it, and before the x value in the tooltip." },
    .{ .name = "tick_count", .type = "u32", .default = "5", .desc = "About how many ticks; they land on round numbers." },
    .{ .name = "formatter", .type = "?Formatter", .default = "null", .desc = "fn (value: f64, buf: []u8) []const u8. Writes tick labels, and for the y axis the tooltip's values. Unset, numbers get the decimals their ticks need, and an x with a point label shows the label." },
    .{ .name = "grid", .type = "bool", .default = "true", .desc = "Lines across the plot at the y axis's ticks." },
    .{ .name = "scale", .type = "ScaleConfig", .default = ".{}", .desc = "Linear or log, and a domain: .auto, .auto_zero, or .manual for fixed ends." },
    .{ .name = "color", .type = "Color", .default = ".palette(.text_color)", .desc = "The axis line's colour." },
};

const series_fields = [_]Docs.Field{
    .{ .name = "color", .type = "?Color", .default = "null", .desc = "The series' colour; unset, the palette's next." },
    .{ .name = "stroke_width", .type = "f32", .default = "2", .desc = "A line's thickness." },
    .{ .name = "show_dots", .type = "bool", .default = "true", .desc = "A dot on each point of a line or area. The hovered one grows." },
    .{ .name = "fill_opacity", .type = "f64", .default = "0.3", .desc = "How solid an area's fill is." },
    .{ .name = "bar_radius", .type = "f64", .default = "0", .desc = "Rounds a bar's corners." },
    .{ .name = "hovered_color", .type = "?Color", .default = "null", .desc = "A point's colour while hovered." },
    .{ .name = "inner_radius_ratio", .type = "f64", .default = "0", .desc = "A pie's hole, as a share of its radius; .donut uses 0.5 when this is unset." },
};

const legend_fields = [_]Docs.Field{
    .{ .name = "position", .type = "Position", .default = ".top_right", .desc = "Which corner it takes: .top_left, .top_right, .bottom_left or .bottom_right." },
    .{ .name = "direction", .type = "Direction", .default = ".row", .desc = ".row runs above or below the plot, .column down its side." },
    .{ .name = "fields", .type = "[]const LegendField", .default = "&.{}", .desc = "More items after the series'. On a stacked bar chart they name the segments after the first, and toggle them." },
    .{ .name = "text_color", .type = "?Color", .default = "null", .desc = "The items' text; unset, the theme's." },
};

const reference_fields = [_]Docs.Field{
    .{ .name = "axis", .type = "enum { x, y }", .default = ".y", .desc = ".y lies across the plot at a y value, .x stands at an x value." },
    .{ .name = "value", .type = "f64", .desc = "Where it is." },
    .{ .name = "to", .type = "?f64", .default = "null", .desc = "Set, it shades a band from value to here." },
    .{ .name = "label", .type = "?[]const u8", .default = "null", .desc = "Written at its end." },
    .{ .name = "color", .type = "?Color", .default = "null", .desc = "Unset, the theme's text colour." },
    .{ .name = "dashed", .type = "bool", .default = "true", .desc = "A dashed line, or a solid one." },
};

const behaviours = [_]Docs.Field{
    .{ .name = "Tooltip", .desc = "Over the plot it names the nearest x and lists each series' value there; on a pie, the slice's value and share. It hides over the margins, sits beside the point on the side with room, and never takes a click." },
    .{ .name = "Zoom", .desc = "Drag to zoom; double-click or Reset zoom to go back. Reset zoom sits outside the plot, so pointing at it hides the tooltip and pressing it starts no drag." },
    .{ .name = "Legend", .desc = "Buttons that hide and show their series, with aria-pressed, so a keyboard and a screen reader can use them too. The axes fit what is shown." },
    .{ .name = "Size", .desc = "Follows its parent's width as the page resizes." },
};

pub fn render() void {
    Row()
        .width(.percent(100))
        .height(.percent(100))
        .layout(.top_center)
        .direction(.column)
        .children({
        Hero("charts-ui", "A collection of ready-to-use chart components built on top of Vapor. From basic charts to rich data displays, copy and paste into your apps.");

        Stack()
            .spacing(24)
            .width(.percent(60))
            .responsive(.mobile, .{ .size = .w(.percent(92)) })
            .children({
            const index = Tabs.NavBar("chart_tabs", &.{ "Line Charts", "Bar Charts", "Pie Charts", "Area Charts" });
            // An id per tab, so one chart's elements are never reused for
            // another chart (which would not measure itself again).
            switch (index) {
                0 => {
                    Row()
                        .id("chart-panel-line")
                        .width(.percent(100))
                        .children({
                        chart.render();
                    });
                },
                1 => {
                    Row()
                        .id("chart-panel-bar")
                        .width(.percent(100))
                        .children({
                        requests_chart.render();
                    });
                },
                2 => {
                    Row()
                        .id("chart-panel-pie")
                        .width(.percent(100))
                        .children({
                        pie_chart.render();
                    });
                },
                3 => {
                    Row()
                        .id("chart-panel-area")
                        .width(.percent(100))
                        .children({
                        area_chart.render();
                    });
                },
                else => {},
            }
        });

        Stack()
            .spacing(12)
            .width(.percent(60))
            .responsive(.mobile, .{ .size = .w(.percent(92)) })
            .padding(.{ .bottom = 120 })
            .children({
            Docs.sectionTitle("Usage");
            Docs.sectionDesc("Set a chart up once in your page's init, then render it. It fills its parent's width. Hover it to read the values at a point.");
            CodeBox(&hl_basic, "BasicChart");

            Docs.sectionTitle("Pie and Donut Charts");
            Docs.sectionDesc("Give each slice a label: the legend and the pie name the slices by it.");
            CodeBox(&hl_pie, "PieChart");

            Docs.sectionTitle("Zooming");
            Docs.sectionDesc("Drag across a chart to zoom into that stretch; the y axis fits what is in it. Double-click, or press Reset zoom, to zoom back out. Try it on the charts above.");
            CodeBox(&hl_zoom, "ChartZoom");

            Docs.sectionTitle("Legend");
            Docs.sectionDesc("Click an item to hide its series and again to bring it back; point at one to fade the rest. Try it on the bar chart's 4XX.");
            CodeBox(&hl_legend, "ChartLegend");

            Docs.sectionTitle("Formatting values");
            Docs.sectionDesc("Write ticks and tooltip values your way, as dollars, percentages or dates. The area chart above shows dollars.");
            CodeBox(&hl_format, "ChartFormat");

            Docs.sectionTitle("Reference lines");
            Docs.sectionDesc("Mark a target, a limit or a range on the plot. The area chart above marks its target.");
            CodeBox(&hl_reference, "ChartReference");

            Docs.sectionTitle("Styling");
            Docs.sectionDesc("Labels, grid lines and legend text follow your theme in light and dark mode. Colours, fills, lines and dots are set per chart, axis or series.");
            CodeBox(&hl_style, "ChartStyle");

            Docs.sectionTitle("API Reference");

            Docs.exampleLabel("Chart");
            Docs.sectionDesc("Set up once in init, then rendered each frame. It keeps its zoom, legend and tooltip itself.");
            CodeBox(&hl_api, "Chart");

            Docs.exampleLabel("Config");
            Docs.sectionDesc("Passed to init.");
            Docs.ApiBox("Config", &config_fields);

            Docs.exampleLabel("AxisConfig");
            Docs.sectionDesc("Passed to xAxis and yAxis.");
            Docs.ApiBox("AxisConfig", &axis_fields);

            Docs.exampleLabel("SeriesOptions");
            Docs.sectionDesc("Passed to addSeries; the most used.");
            Docs.ApiBox("SeriesOptions", &series_fields);

            Docs.exampleLabel("LegendConfig");
            Docs.ApiBox("LegendConfig", &legend_fields);

            Docs.exampleLabel("Reference");
            Docs.sectionDesc("Passed to reference.");
            Docs.ApiBox("Reference", &reference_fields);

            Docs.exampleLabel("Behaviour");
            Docs.sectionDesc("What the chart does for you.");
            Docs.ApiBox("Behaviour", &behaviours);
        });
    });
}
