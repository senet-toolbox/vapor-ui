const Vapor = @import("vapor");
const Row = Vapor.Row;
const Text = Vapor.Text;
const Stack = Vapor.Stack;
const Opaque = @import("opaque-ui");
const Tabs = Opaque.Tabs;
const Chart = Opaque.Chart;

var chart: Chart = undefined;
var requests_chart: Chart = undefined;
var pie_chart: Chart = undefined;
var area_chart: Chart = undefined;

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
    .{ .x = 25, .y = 35 },
    .{ .x = 25, .y = 40 },
    .{ .x = 25, .y = 15 },
    .{ .x = 25, .y = 10 },
};

// Define colors for each status code category
const gray = Vapor.Types.Color.hex("#212121"); // 1/2/3XX
const yellow = Vapor.Types.Color.hex("#FF8800"); // 4XX
const red = Vapor.Types.Color.hex("#FF2B00"); // 5XX

// Create data points with stacked segments
// Each point represents a time bucket
const data_requests = [_]Chart.Point{
    .{ .x = 1, .stack = &.{ .{ .value = 50, .color = gray }, .{ .value = 30, .color = gray }, .{ .value = 15, .color = yellow }, .{ .value = 20, .color = red } } },
    .{ .x = 2, .stack = &.{ .{ .value = 40, .color = gray }, .{ .value = 25, .color = gray }, .{ .value = 25, .color = yellow }, .{ .value = 30, .color = red } } },
    .{ .x = 3, .stack = &.{ .{ .value = 60, .color = gray }, .{ .value = 35, .color = gray }, .{ .value = 10, .color = yellow }, .{ .value = 20, .color = red } } },
    .{ .x = 4, .stack = &.{ .{ .value = 45, .color = gray }, .{ .value = 20, .color = gray }, .{ .value = 30, .color = yellow }, .{ .value = 40, .color = red } } },
    .{ .x = 5, .stack = &.{ .{ .value = 55, .color = gray }, .{ .value = 28, .color = gray }, .{ .value = 18, .color = yellow }, .{ .value = 25, .color = red } } },
    .{ .x = 6, .stack = &.{ .{ .value = 70, .color = gray }, .{ .value = 40, .color = gray }, .{ .value = 12, .color = yellow }, .{ .value = 15, .color = red } } },
    .{ .x = 7, .stack = &.{ .{ .value = 35, .color = gray }, .{ .value = 22, .color = gray }, .{ .value = 28, .color = yellow }, .{ .value = 35, .color = red } } },
    .{ .x = 8, .stack = &.{ .{ .value = 48, .color = gray }, .{ .value = 32, .color = gray }, .{ .value = 20, .color = yellow }, .{ .value = 22, .color = red } } },
    .{ .x = 9, .stack = &.{ .{ .value = 62, .color = gray }, .{ .value = 38, .color = gray }, .{ .value = 8, .color = yellow }, .{ .value = 12, .color = red } } },
    .{ .x = 10, .stack = &.{ .{ .value = 42, .color = gray }, .{ .value = 18, .color = gray }, .{ .value = 35, .color = yellow }, .{ .value = 45, .color = red } } },
    .{ .x = 11, .stack = &.{ .{ .value = 58, .color = gray }, .{ .value = 33, .color = gray }, .{ .value = 14, .color = yellow }, .{ .value = 18, .color = red } } },
    .{ .x = 12, .stack = &.{ .{ .value = 75, .color = gray }, .{ .value = 45, .color = gray }, .{ .value = 10, .color = yellow }, .{ .value = 10, .color = red } } },
    .{ .x = 13, .stack = &.{ .{ .value = 30, .color = gray }, .{ .value = 15, .color = gray }, .{ .value = 40, .color = yellow }, .{ .value = 50, .color = red } } },
    .{ .x = 14, .stack = &.{ .{ .value = 52, .color = gray }, .{ .value = 30, .color = gray }, .{ .value = 22, .color = yellow }, .{ .value = 28, .color = red } } },
    .{ .x = 15, .stack = &.{ .{ .value = 65, .color = gray }, .{ .value = 42, .color = gray }, .{ .value = 15, .color = yellow }, .{ .value = 16, .color = red } } },
    .{ .x = 16, .stack = &.{ .{ .value = 38, .color = gray }, .{ .value = 24, .color = gray }, .{ .value = 32, .color = yellow }, .{ .value = 38, .color = red } } },
    .{ .x = 17, .stack = &.{.{ .value = 120, .color = red }} },
    .{ .x = 18, .stack = &.{.{ .value = 140, .color = red }} },
    .{ .x = 19, .stack = &.{.{ .value = 90, .color = red }} },
    .{ .x = 20, .stack = &.{ .{ .value = 68, .color = gray }, .{ .value = 44, .color = gray }, .{ .value = 12, .color = yellow }, .{ .value = 14, .color = red } } },
    .{ .x = 21, .stack = &.{ .{ .value = 34, .color = gray }, .{ .value = 20, .color = gray }, .{ .value = 36, .color = yellow }, .{ .value = 42, .color = red } } },
    .{ .x = 22, .stack = &.{ .{ .value = 80, .color = gray }, .{ .value = 50, .color = gray }, .{ .value = 6, .color = yellow }, .{ .value = 6, .color = red } } },
    .{ .x = 23, .stack = &.{.{ .value = 60, .color = red }} },
    .{ .x = 24, .stack = &.{.{ .value = 74, .color = red }} },
    .{ .x = 25, .stack = &.{ .{ .value = 63, .color = gray }, .{ .value = 40, .color = gray } } },
    .{ .x = 26, .stack = &.{ .{ .value = 41, .color = gray }, .{ .value = 23, .color = gray }, .{ .value = 30, .color = yellow }, .{ .value = 36, .color = red } } },
    .{ .x = 27, .stack = &.{ .{ .value = 77, .color = gray }, .{ .value = 46, .color = gray }, .{ .value = 9, .color = yellow }, .{ .value = 11, .color = red } } },
    .{ .x = 28, .stack = &.{ .{ .value = 36, .color = gray }, .{ .value = 19, .color = gray }, .{ .value = 34, .color = yellow }, .{ .value = 44, .color = red } } },
    .{ .x = 29, .stack = &.{ .{ .value = 59, .color = gray }, .{ .value = 37, .color = gray }, .{ .value = 16, .color = yellow }, .{ .value = 19, .color = red } } },
    .{ .x = 30, .stack = &.{ .{ .value = 71, .color = gray }, .{ .value = 43, .color = gray }, .{ .value = 11, .color = yellow }, .{ .value = 13, .color = red } } },
    .{ .x = 31, .stack = &.{ .{ .value = 49, .color = gray }, .{ .value = 29, .color = gray } } },
    .{ .x = 32, .stack = &.{ .{ .value = 66, .color = gray }, .{ .value = 41, .color = gray } } },
    .{ .x = 33, .stack = &.{ .{ .value = 39, .color = gray }, .{ .value = 21, .color = gray } } },
    .{ .x = 34, .stack = &.{ .{ .value = 85, .color = gray }, .{ .value = 52, .color = gray } } },
    .{ .x = 35, .stack = &.{ .{ .value = 47, .color = gray }, .{ .value = 27, .color = gray } } },
    .{ .x = 36, .stack = &.{ .{ .value = 61, .color = gray }, .{ .value = 39, .color = gray } } },
    .{ .x = 37, .stack = &.{ .{ .value = 53, .color = gray }, .{ .value = 31, .color = gray } } },
    .{ .x = 38, .stack = &.{ .{ .value = 74, .color = gray }, .{ .value = 47, .color = gray } } },
    .{ .x = 39, .stack = &.{ .{ .value = 43, .color = gray }, .{ .value = 25, .color = gray } } },
    .{ .x = 40, .stack = &.{ .{ .value = 67, .color = gray }, .{ .value = 42, .color = gray } } },
    .{ .x = 41, .stack = &.{ .{ .value = 50, .color = gray }, .{ .value = 30, .color = gray } } },
    .{ .x = 42, .stack = &.{ .{ .value = 40, .color = gray }, .{ .value = 25, .color = gray } } },
    .{ .x = 43, .stack = &.{ .{ .value = 60, .color = gray }, .{ .value = 35, .color = gray }, .{ .value = 10, .color = yellow }, .{ .value = 20, .color = red } } },
    .{ .x = 44, .stack = &.{ .{ .value = 45, .color = gray }, .{ .value = 20, .color = gray }, .{ .value = 30, .color = yellow }, .{ .value = 40, .color = red } } },
    .{ .x = 45, .stack = &.{ .{ .value = 55, .color = gray }, .{ .value = 28, .color = gray }, .{ .value = 18, .color = yellow }, .{ .value = 25, .color = red } } },
    .{ .x = 46, .stack = &.{ .{ .value = 70, .color = gray }, .{ .value = 40, .color = gray }, .{ .value = 12, .color = yellow }, .{ .value = 15, .color = red } } },
    .{ .x = 47, .stack = &.{ .{ .value = 35, .color = gray }, .{ .value = 22, .color = gray }, .{ .value = 28, .color = yellow }, .{ .value = 35, .color = red } } },
    .{ .x = 48, .stack = &.{ .{ .value = 48, .color = gray }, .{ .value = 32, .color = gray }, .{ .value = 20, .color = yellow }, .{ .value = 22, .color = red } } },
    .{ .x = 49, .stack = &.{ .{ .value = 62, .color = gray }, .{ .value = 38, .color = gray }, .{ .value = 8, .color = yellow }, .{ .value = 12, .color = red } } },
    .{ .x = 50, .stack = &.{ .{ .value = 42, .color = gray }, .{ .value = 18, .color = gray }, .{ .value = 35, .color = yellow }, .{ .value = 45, .color = red } } },
    .{ .x = 51, .stack = &.{ .{ .value = 58, .color = gray }, .{ .value = 33, .color = gray }, .{ .value = 14, .color = yellow }, .{ .value = 18, .color = red } } },
    .{ .x = 52, .stack = &.{ .{ .value = 75, .color = gray }, .{ .value = 45, .color = gray }, .{ .value = 10, .color = yellow }, .{ .value = 10, .color = red } } },
    .{ .x = 53, .stack = &.{ .{ .value = 30, .color = gray }, .{ .value = 15, .color = gray }, .{ .value = 40, .color = yellow }, .{ .value = 50, .color = red } } },
    .{ .x = 54, .stack = &.{ .{ .value = 52, .color = gray }, .{ .value = 30, .color = gray }, .{ .value = 22, .color = yellow }, .{ .value = 28, .color = red } } },
    .{ .x = 55, .stack = &.{ .{ .value = 65, .color = gray }, .{ .value = 42, .color = gray }, .{ .value = 15, .color = yellow }, .{ .value = 16, .color = red } } },
    .{ .x = 56, .stack = &.{ .{ .value = 38, .color = gray }, .{ .value = 24, .color = gray }, .{ .value = 32, .color = yellow }, .{ .value = 38, .color = red } } },
    .{ .x = 57, .stack = &.{.{ .value = 115, .color = red }} },
    .{ .x = 58, .stack = &.{.{ .value = 135, .color = red }} },
    .{ .x = 59, .stack = &.{.{ .value = 85, .color = red }} },
    .{ .x = 60, .stack = &.{ .{ .value = 64, .color = gray }, .{ .value = 38, .color = gray }, .{ .value = 14, .color = yellow }, .{ .value = 16, .color = red } } },
    .{ .x = 61, .stack = &.{ .{ .value = 32, .color = gray }, .{ .value = 18, .color = gray }, .{ .value = 38, .color = yellow }, .{ .value = 44, .color = red } } },
    .{ .x = 62, .stack = &.{ .{ .value = 78, .color = gray }, .{ .value = 48, .color = gray }, .{ .value = 8, .color = yellow }, .{ .value = 8, .color = red } } },
    .{ .x = 63, .stack = &.{.{ .value = 55, .color = red }} },
    .{ .x = 64, .stack = &.{.{ .value = 68, .color = red }} },
    .{ .x = 65, .stack = &.{ .{ .value = 60, .color = gray }, .{ .value = 38, .color = gray } } },
    .{ .x = 66, .stack = &.{ .{ .value = 45, .color = gray }, .{ .value = 26, .color = gray } } },
    .{ .x = 67, .stack = &.{ .{ .value = 72, .color = gray }, .{ .value = 44, .color = gray } } },
    .{ .x = 68, .stack = &.{ .{ .value = 35, .color = gray }, .{ .value = 20, .color = gray } } },
    .{ .x = 69, .stack = &.{ .{ .value = 82, .color = gray }, .{ .value = 50, .color = gray } } },
    .{ .x = 70, .stack = &.{ .{ .value = 51, .color = gray }, .{ .value = 30, .color = gray }, .{ .value = 20, .color = yellow }, .{ .value = 25, .color = red } } },
    .{ .x = 71, .stack = &.{ .{ .value = 44, .color = gray }, .{ .value = 25, .color = gray }, .{ .value = 30, .color = yellow }, .{ .value = 35, .color = red } } },
    .{ .x = 72, .stack = &.{ .{ .value = 68, .color = gray }, .{ .value = 42, .color = gray } } },
    .{ .x = 73, .stack = &.{ .{ .value = 55, .color = gray }, .{ .value = 32, .color = gray } } },
    .{ .x = 74, .stack = &.{ .{ .value = 48, .color = gray }, .{ .value = 28, .color = gray } } },
    .{ .x = 75, .stack = &.{ .{ .value = 65, .color = gray }, .{ .value = 40, .color = gray }, .{ .value = 15, .color = yellow }, .{ .value = 18, .color = red } } },
    .{ .x = 76, .stack = &.{ .{ .value = 52, .color = gray }, .{ .value = 34, .color = gray }, .{ .value = 18, .color = yellow }, .{ .value = 22, .color = red } } },
    .{ .x = 77, .stack = &.{ .{ .value = 41, .color = gray }, .{ .value = 24, .color = gray }, .{ .value = 35, .color = yellow }, .{ .value = 40, .color = red } } },
    .{ .x = 78, .stack = &.{ .{ .value = 73, .color = gray }, .{ .value = 46, .color = gray }, .{ .value = 10, .color = yellow }, .{ .value = 12, .color = red } } },
    .{ .x = 79, .stack = &.{ .{ .value = 39, .color = gray }, .{ .value = 22, .color = gray }, .{ .value = 25, .color = yellow }, .{ .value = 30, .color = red } } },
    .{ .x = 80, .stack = &.{ .{ .value = 57, .color = gray }, .{ .value = 35, .color = gray }, .{ .value = 15, .color = yellow }, .{ .value = 18, .color = red } } },
    .{ .x = 81, .stack = &.{.{ .value = 125, .color = red }} },
    .{ .x = 82, .stack = &.{.{ .value = 155, .color = red }} },
    .{ .x = 83, .stack = &.{.{ .value = 110, .color = red }} },
    .{ .x = 84, .stack = &.{ .{ .value = 66, .color = gray }, .{ .value = 40, .color = gray } } },
    .{ .x = 85, .stack = &.{ .{ .value = 43, .color = gray }, .{ .value = 25, .color = gray } } },
    .{ .x = 86, .stack = &.{ .{ .value = 70, .color = gray }, .{ .value = 42, .color = gray } } },
    .{ .x = 87, .stack = &.{ .{ .value = 38, .color = gray }, .{ .value = 19, .color = gray } } },
    .{ .x = 88, .stack = &.{ .{ .value = 80, .color = gray }, .{ .value = 52, .color = gray } } },
    .{ .x = 89, .stack = &.{ .{ .value = 45, .color = gray }, .{ .value = 28, .color = gray } } },
    .{ .x = 90, .stack = &.{ .{ .value = 55, .color = gray }, .{ .value = 33, .color = gray } } },
    .{ .x = 91, .stack = &.{ .{ .value = 62, .color = gray }, .{ .value = 38, .color = gray }, .{ .value = 12, .color = yellow }, .{ .value = 14, .color = red } } },
    .{ .x = 92, .stack = &.{ .{ .value = 48, .color = gray }, .{ .value = 27, .color = gray }, .{ .value = 28, .color = yellow }, .{ .value = 35, .color = red } } },
    .{ .x = 93, .stack = &.{ .{ .value = 75, .color = gray }, .{ .value = 48, .color = gray }, .{ .value = 8, .color = yellow }, .{ .value = 10, .color = red } } },
    .{ .x = 94, .stack = &.{ .{ .value = 33, .color = gray }, .{ .value = 15, .color = gray }, .{ .value = 42, .color = yellow }, .{ .value = 55, .color = red } } },
    .{ .x = 95, .stack = &.{ .{ .value = 59, .color = gray }, .{ .value = 36, .color = gray }, .{ .value = 14, .color = yellow }, .{ .value = 18, .color = red } } },
    .{ .x = 96, .stack = &.{.{ .value = 95, .color = red }} },
    .{ .x = 97, .stack = &.{.{ .value = 80, .color = red }} },
    .{ .x = 98, .stack = &.{ .{ .value = 64, .color = gray }, .{ .value = 41, .color = gray } } },
    .{ .x = 99, .stack = &.{ .{ .value = 47, .color = gray }, .{ .value = 29, .color = gray } } },
    .{ .x = 100, .stack = &.{ .{ .value = 72, .color = gray }, .{ .value = 45, .color = gray }, .{ .value = 10, .color = yellow }, .{ .value = 12, .color = red } } },
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

    area_chart = Chart.init(Vapor.arena(.persist), .{
        .height = 400,
        .width = @intFromFloat(Vapor.lib.browser_width * 0.6),
        .palette = .{ .colors = &.{ "#3b82f6", "#ef4444", "#f59e0b", "#10b981" } },
    });

    area_chart.addSeries(.area, "Sales", &data, .{ .color = .palette(.tint) }) catch unreachable;
    area_chart.xAxis(.{ .label = "Month", .tick_count = 6 });
    area_chart.yAxis(.{ .label = "USD ($)", .tick_count = 5 });
    area_chart.legend(.{ .position = .top_right, .direction = .row });
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
        .border = .top(1, .hex("#000000")),
        .stroke = .hex("#000000"),
        .stroke_width = 0.5,
    }) catch unreachable;

    requests_chart.xAxis(.{ .label = "Time", .tick_count = 4 });
    requests_chart.yAxis(.{ .label = "Requests", .tick_count = 5 });
    requests_chart.legend(.{
        .position = .top_right,
        .direction = .row,
        .text_color = .palette(.text_color),
        .fields = &.{
            .{ .title = "3XX", .color = gray, .background = gray },
            .{ .title = "4XX", .color = yellow, .background = yellow },
            .{ .title = "5XX", .color = red, .background = red },
        },
    });

    requests_chart.build() catch unreachable;

    Vapor.Page(.{ .src = @src() }, render, null);
}

pub fn render() void {
    Row()
        .width(.percent(100))
        .height(.percent(100))
        .layout(.top_center)
        .direction(.column)
        .children({
        Vapor.Stack()
            .layout(.center)
            .height(.px(512))
            .width(.percent(100))
            .children({
            Text("charts-ui ⇒").style(&.{
                .visual = .font(12, 500, .hex("#6f6f6f")),
                .font_family = "IBM Plex Mono,monospace",
            }).end();
            Text("Charts-ui")
                .font(72, 700, .palette(.text_color))
                .end();
            Text("A collection of ready-to-use chart components built on top of Vapor. From basic charts to rich data displays, copy and paste into your apps.")
                .font(16, 300, .palette(.text_color))
                .end();
        });

        Stack()
            .spacing(24)
            .width(.percent(60))
            .children({
            const index = Tabs.NavBar("chart_tabs", &.{ "Line Charts", "Bar Charts", "Pie Charts", "Area Charts" });
            switch (index) {
                0 => {
                    Row()
                        .width(.percent(100))
                        .children({
                        chart.render();
                    });
                },
                1 => {
                    Row()
                        .width(.percent(100))
                        .children({
                        requests_chart.render();
                    });
                },
                2 => {
                    Row()
                        .width(.percent(100))
                        .children({});
                },
                3 => {
                    Row()
                        .width(.percent(100))
                        .children({
                        area_chart.render();
                    });
                },
                else => {},
            }
        });
    });
}
