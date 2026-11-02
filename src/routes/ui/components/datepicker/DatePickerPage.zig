const Vapor = @import("vapor");
const Hero = @import("../../../../components/Hero.zig").Hero;
const Row = Vapor.Row;
const SyntaxHighlighter = @import("vaporize").SyntaxHighlighter;
const CodeBox = @import("../CodeBox.zig").CodeBox;
const Docs = @import("../Docs.zig");
// Rendered and shown as code: what you read is what runs.
const BasicDatePicker = @import("examples/BasicDatePicker.zig");
const EventDatePicker = @import("examples/EventDatePicker.zig");

var hl_basic: SyntaxHighlighter = undefined;
var hl_events: SyntaxHighlighter = undefined;
var hl_api: SyntaxHighlighter = undefined;

pub fn init() void {
    hl_basic = Docs.highlighter(@embedFile("examples/BasicDatePicker.zig"));
    hl_events = Docs.highlighter(@embedFile("examples/EventDatePicker.zig"));
    hl_api = Docs.highlighter(
        \\const DatePicker = @import("opaque-ui").DatePicker;
        \\
        \\// Fills in the calendar, starting on start_date's month (or
        \\// today's). It resets every other field: set them after.
        \\pub fn init(date_picker: *DatePicker) void
        \\pub fn render(date_picker: *DatePicker) void
        \\
        \\// A global var, set up in your init.
        \\var picker: DatePicker = undefined;
        \\
        \\pub fn init() void {
        \\    picker.init();
        \\    picker.on_date_select = onDate;
        \\}
        \\
        \\fn onDate(picker: *DatePicker, date: Vapor.DateTime) void { ... }
    );

    BasicDatePicker.init();
    EventDatePicker.init();

    Vapor.Page(.{ .src = @src() }, render, null);
}

const fields = [_]Docs.Field{
    .{ .name = "start_date", .type = "?DateTime", .default = "null", .desc = "The month it opens on and the day it starts picked; today when null. Set it before init." },
    .{ .name = "on_date_select", .type = "?*const fn (*DatePicker, DateTime) void", .default = "null", .desc = "Called with the day clicked." },
    .{ .name = "on_month_select", .type = "?*const fn (month: i32) void", .default = "null", .desc = "Called with the month picked from its menu." },
    .{ .name = "on_year_select", .type = "?*const fn (year: i32) void", .default = "null", .desc = "Called with the year picked from its menu, 1925 to 2035." },
    .{ .name = "on_next_month", .type = "?*const fn () void", .default = "null", .desc = "Called after the next-month arrow." },
    .{ .name = "on_prev_month", .type = "?*const fn () void", .default = "null", .desc = "Called after the previous-month arrow." },
    .{ .name = "tint", .type = "Color", .default = ".palette(.tint)", .desc = "The picked day's background, and a faint wash on today." },
    .{ .name = "text_color", .type = "Color", .default = ".palette(.text)", .desc = "The numbers of this month's days; other months' are grey." },
    .{ .name = "background", .type = "Color", .default = ".palette(.background)", .desc = "The calendar's background." },
};

const behaviours = [_]Docs.Field{
    .{ .name = "Paging", .desc = "The arrows move a month; the month and year menus jump." },
    .{ .name = "Keyboard", .desc = "Days, arrows and menus are buttons: Tab reaches them, Enter or Space uses them." },
    .{ .name = "Screen readers", .desc = "Each day is named by its date, like August 14, 1991, and the picked one reports aria-pressed. The arrows are named Previous Month and Next Month." },
};

fn render() void {
    Row()
        .width(.percent(100))
        .layout(.top_center)
        .direction(.column)
        .children({
        Hero("datepicker-ui", "Accessible calendar components for precise date and time selection.");

        Docs.Content().children({
            Docs.exampleLabel("Basic DatePicker");
            Docs.sectionDesc("A calendar on this month. Click a day to pick it.");
            Docs.PreviewCard().layout(.center).children({
                BasicDatePicker.render();
            });
            CodeBox(&hl_basic, "BasicDatePicker");

            Docs.exampleLabel("Event-Driven Selection");
            Docs.sectionDesc("Opens on a given month, and calls back on each pick and page.");
            Docs.PreviewCard().layout(.center).children({
                EventDatePicker.render();
            });
            CodeBox(&hl_events, "EventDatePicker");

            Docs.sectionTitle("API Reference");

            Docs.exampleLabel("DatePicker");
            Docs.sectionDesc("A struct you init once and render.");
            CodeBox(&hl_api, "DatePicker");

            Docs.exampleLabel("Fields");
            Docs.sectionDesc("Set them after init, except start_date.");
            Docs.ApiBox("DatePicker", &fields);

            Docs.exampleLabel("Behaviour");
            Docs.sectionDesc("What the date picker does for you.");
            Docs.ApiBox("Behaviour", &behaviours);
        });
    });
}
