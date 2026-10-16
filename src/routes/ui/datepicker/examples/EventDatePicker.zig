const Vapor = @import("vapor");
const DateTime = Vapor.DateTime;
const DatePicker = @import("opaque-ui").DatePicker;

var event_picker: DatePicker = undefined;

pub fn init() void {
    // Instance 2: Event Driven (Your specific logic)
    event_picker.start_date = DateTime.fromMonth(8, 1991);
    event_picker.init();
    event_picker.on_date_select = onDateSelect;
    event_picker.on_year_select = onYearSelect;
    event_picker.on_month_select = onMonthSelect;
    event_picker.on_next_month = onNextMonth;
    event_picker.on_prev_month = onPrevMonth;

    Vapor.Page(.{ .src = @src() }, render, null);
}

// ============================================================================
// CALLBACKS
// ============================================================================

fn onDateSelect(_: *DatePicker, date: DateTime) void {
    const format = date.formatDate(Vapor.arena(.frame)) catch unreachable;
    Vapor.alert("Date selected: {s}", .{format});
}

fn onYearSelect(year: i32) void {
    Vapor.alert("Year selected: {d}", .{year});
}
fn onMonthSelect(month: i32) void {
    Vapor.alert("Month selected: {d}", .{month});
}
fn onNextMonth() void {
    Vapor.alert("Next Month", .{});
}
fn onPrevMonth() void {
    Vapor.alert("Prev Month", .{});
}

pub fn render() void {
    event_picker.render();
}
