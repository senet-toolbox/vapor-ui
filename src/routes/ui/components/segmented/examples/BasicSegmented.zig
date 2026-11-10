const Vapor = @import("vapor");
const Stack = Vapor.Stack;
const Segmented = @import("opaque-ui").Segmented;

const periods = [_][]const u8{ "Day", "Week", "Month", "Year" };
var period: usize = 1;

pub fn render() void {
    Stack().layout(.center).spacing(16).children({
        Segmented.render(&period, &periods, .{ .label = "Period" });
        Vapor.TextFmt("Showing this {s}", .{periods[period]})
            .font(14, 400, .transparentize(.palette(.text_color), 0.6))
            .end();
    });
}
