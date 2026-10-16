const Vapor = @import("vapor");
const DateTime = Vapor.DateTime;
const DatePicker = @import("opaque-ui").DatePicker;

var basic_picker: DatePicker = undefined;

pub fn init() void {
    basic_picker.init();
    Vapor.Page(.{ .src = @src() }, render, null);
}

pub fn render() void {
    basic_picker.render();
}
