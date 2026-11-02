const Vapor = @import("vapor");
const DateTime = Vapor.DateTime;
const DatePicker = @import("opaque-ui").DatePicker;

var basic_picker: DatePicker = undefined;

// Opens on this month, with today marked.
pub fn init() void {
    basic_picker.init();
}

pub fn render() void {
    basic_picker.render();
}
