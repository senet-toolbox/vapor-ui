const Vapor = @import("vapor");
const std = @import("std");
const Opaque = @import("opaque-ui");
const Stack = Vapor.Stack;
const Center = Vapor.Center;
const Row = Vapor.Row;
const Text = Vapor.Text;
const TextField = Vapor.TextField;
const Label = Vapor.Label;
const TextFmt = Vapor.TextFmt;
const ButtonCtx = Vapor.Button;

const Theme = @import("theme");

const Item = Opaque.Item;
pub const Sortable = Opaque.Sortable;

const LoginComponent = @import("templates/Login.zig");

var login: LoginComponent = .{
    .login_title = "Login into Ryven",
    .login_subtitle = "Login into your Ryven account.",
    .create_account_title = "Create Ryven Account",
    .create_account_subtitle = "Create an Ryven account to login",
};

const Shadow = Vapor.Types.NewShadow;
const Color = Vapor.Types.Color;

pub const look_around = Vapor.Animation.init("look-around")
    .at(0).setAll(.{ .translateX = -1.5, .translateY = 0 })
    .at(16.6).setAll(.{ .translateX = -1.5, .translateY = 0 })
    .at(25).setAll(.{ .translateX = 1.5, .translateY = 0 })
    .at(41.6).setAll(.{ .translateX = 1.5, .translateY = 0 })
    .at(50).setAll(.{ .translateX = 0, .translateY = -1.5 })
    .at(66.6).setAll(.{ .translateX = 0, .translateY = -1.5 })
    .at(75).setAll(.{ .translateX = 0, .translateY = 0 })
    .at(91.6).setAll(.{ .translateX = 0, .translateY = 0 })
    .at(100).setAll(.{ .translateX = -1.5, .translateY = 0 })
    .easing(.easeInOut)
    .duration(2400)
    .infinite();

pub const text_glitch_chromatic = Vapor.Animation.init("text-glitch-chromatic")
    .duration(100)
    .iterations(3)
    .easing(.linear)

    // 0% - clean
    .at(0)
    .set(.translateX, 0)
    .set(.opacity, 1)
    .setShadow(.textShadow, Shadow.init()) // No shadow

    // 20% - RGB split left
    .at(20)
    .set(.translateX, -8)
    .set(.skewX, -10)
    .setShadow(.textShadow, Shadow.init()
        .drop(-4, 0, 0, .red) // Red left
        .drop(4, 0, 0, .cyan) // Cyan right
    )

    // 40% - RGB split right + flicker
    .at(40)
    .set(.translateX, 10)
    .set(.opacity, 0.6)
    .setShadow(.textShadow, Shadow.init()
        .drop(6, 2, 0, .green) // Green offset
        .drop(-6, -2, 0, .magenta) // Magenta opposite
    )

    // 60% - intense split
    .at(60)
    .set(.translateX, -6)
    .set(.translateY, -4)
    .set(.opacity, 1)
    .setShadow(.textShadow, Shadow.init()
        .drop(-8, 0, 2, .red) // Red offset
        .drop(8, 0, 2, .cyan))

    // 80% - settling
    .at(80)
    .set(.translateX, 3)
    .set(.skewX, -3)
    .setShadow(.textShadow, Shadow.init()
        .drop(-2, 0, 0, .red)
        .drop(2, 0, 0, .cyan))

    // 100% - clean
    .at(100)
    .set(.translateX, 0)
    .set(.translateY, 0)
    .set(.skewX, 0)
    .set(.opacity, 1)
    .setShadow(.textShadow, Shadow.init()); // Clear shadows

// After - using setAll + autoReset
pub const text_glitch: Vapor.Animation = Vapor.Animation.init("text-glitch")
    .duration(100)
    .iterations(3)
    .at(10).setAll(.{ .translateX = -8, .skewX = -12, .opacity = 0.9 })
    .at(25).setAll(.{ .translateX = 12, .translateY = -4, .skewX = 15, .opacity = 0 })
    .at(40).setAll(.{ .translateX = -6, .translateY = 6, .skewX = -8, .opacity = 1 })
    .at(55).setAll(.{ .translateX = 4, .translateY = -2, .opacity = 0.5 })
    .at(70).setAll(.{ .translateX = -10, .skewX = 10, .opacity = 0.8 })
    .at(85).setAll(.{ .translateX = 3, .translateY = 2, .skewX = -3, .opacity = 1 })
    .autoReset(); // Automatically adds 100% with all props reset

pub const glitch = Vapor.Animation.init("glitch")
    .duration(200)
    .at(25)
    .set(.translateX, -10)
    .setColor(.backgroundColor, .red)

    // 35% { transform: translate(10px); }
    .at(35)
    .set(.translateX, 10)
    .setColor(.backgroundColor, .green)
    .set(.scaleX, 1.1)

    // 59% { opacity: 0; }
    .at(59)
    .set(.opacity, 0)
    .setColor(.backgroundColor, .blue)

    // 60% { transform: translate(-10px); filter: blur(5px); }
    .at(60)
    .set(.opacity, 1) // Reset opacity from prev frame
    .set(.translateX, -10)
    .set(.blur, 5)
    .set(.scaleX, 0.7)

    // 100% { blur: (5px); }
    .at(100)
    .set(.blur, 5)
    .setColor(.backgroundColor, .yellow);

pub const blink = Vapor.Animation.init("blink")
    .duration(100)
    .infinite()
    .at(50)
    .set(.opacity, 0);

pub const fade_in = Vapor.Animation.init("opaque-fade-in")
    .prop(.opacity, 0, 1)
    .duration(150)
    .easing(.easeInOut)
    .fill(.forwards);

pub const fade_out = Vapor.Animation.init("opaque-fade-out")
    .prop(.opacity, 1, 0)
    .duration(150)
    .easing(.easeInOut)
    .fill(.forwards);

pub fn initAnimations() void {
    glitch.build();
    text_glitch.build();
    blink.build();
    fade_in.build();
    fade_out.build();
    text_glitch_chromatic.build();
    look_around.build();
}

pub fn new() void {}

pub const Table = Opaque.Table;
pub const Column = Opaque.Column;
pub const Action = Opaque.Action;

pub const Select = Opaque.Select;

pub const Accordion = Opaque.Accordion;

pub const Alert = Opaque.Alert;

pub const Sheet = Opaque.Sheet;

pub const Toast = Opaque.Toast;

pub const Chart = Opaque.Chart;

pub const StackTrace = Opaque.StackTrace;
pub const StackNode = Opaque.StackNode;

pub const Field = Opaque.Field;

pub const Tooltip = Opaque.Tooltip;

pub const ComboBox = Opaque.ComboBox;

pub const Button = Opaque.Button;

pub const ComboBoxDialog = Opaque.ComboBoxDialog;

pub const CommandPalette = Opaque.CommandPalette;

pub const Switch = Opaque.Switch;

pub const Group = Opaque.Group;

pub const Tabs = Opaque.Tabs;

pub const DatePicker = Opaque.DatePicker;

pub const ProgressCircle = Opaque.ProgressCircle;

pub const ProgressBar = Opaque.ProgressBar;

pub const SideBar = Opaque.SideBar;

pub const Slider = Opaque.Slider;

pub const TextArea = Opaque.TextArea;

pub const DynamicTable = Opaque.DynamicTable;
pub const DynamicRow = Opaque.DynamicRow;
pub const DataColumn = Opaque.DataColumn;
pub const ColumnType = Opaque.ColumnType;
pub const Value = Opaque.Value;
pub const Interval = Opaque.Interval;
pub const PopOver = Opaque.PopOver;
pub const StringSelect = Opaque.StringSelect;

const Status = enum {
    pending,
    success,
    err,
};

const Data = struct {
    id: usize,
    status: Status,
    email: []const u8,
    amount: i32,
};

var data = Vapor.persist.array(Data);

const columns = [_]Column(Data){
    Column(Data){ .title = "Status", .width = 100, .key = "status", .filter = true },
    Column(Data){ .title = "Email", .width = 100, .sort = .asc, .key = "email", .search = true },
    Column(Data){ .title = "Amount", .width = 100, .key = "amount" },
};

fn onSelect(item: *Data) void {
    std.log.info("You selected {s}", .{item.email});
}

fn onFilter(item: *Data) void {
    std.log.info("You filtered {s}", .{item.email});
}

fn handleDelete(item: *Data) void {
    std.log.info("You deleted {s}", .{item.email});
}

fn handleEdit(item: *Data) void {
    current_row = item;
    std.log.info("You edited {s}", .{item.email});
    status_select.default(Select(Status).Item{ .value = item.status, .label = @tagName(item.status) });
    sheet.open();
}

const MyTable = Table(
    Data,
    &columns,
    .{
        // .actions = &[_]Action(Data){
        //     .{ .label = "Delete", .on_action = handleDelete, .icon = .trash },
        //     .{ .label = "Edit", .on_action = handleEdit, .icon = .pencil },
        // },
        .default_style = .{ .background = .palette(.background), .text_color = .palette(.text), .border_color = .palette(.border_color_light) },
    },
);

var table: MyTable = undefined;
var current_row: *Data = undefined;

var text: []const u8 = "";
var password: []const u8 = "";
var file_text: []const u8 = "";
var card_number: []const u8 = "";

var status_select: Select(Status) = undefined;
var months_select: Select([]const u8) = undefined;
var years_select: Select(u32) = undefined;
var sheet: Sheet = undefined;
var chart: Chart = undefined;
var combobox: ComboBox(Status) = undefined;
var alert: Alert = undefined;
var combobox_dialog: ComboBoxDialog([]const u8) = undefined;
var accordion: Accordion = undefined;
var command_palette: CommandPalette = .{};
var date_picker: DatePicker = undefined;

const MonthItem = struct {
    value: []const u8,
    label: []const u8,
};
var months = [_]Select([]const u8).Item{
    .{ .value = "January", .label = "January" },
    .{ .value = "February", .label = "February" },
    .{ .value = "March", .label = "March" },
    .{ .value = "April", .label = "April" },
    .{ .value = "May", .label = "May" },
    .{ .value = "June", .label = "June" },
    .{ .value = "July", .label = "July" },
    .{ .value = "August", .label = "August" },
    .{ .value = "September", .label = "September" },
    .{ .value = "October", .label = "October" },
    .{ .value = "November", .label = "November" },
    .{ .value = "December", .label = "December" },
};

var years = [_]Select(u32).Item{
    .{ .value = 2022, .label = "2022" },
    .{ .value = 2023, .label = "2023" },
    .{ .value = 2024, .label = "2024" },
    .{ .value = 2025, .label = "2025" },
    .{ .value = 2026, .label = "2026" },
};

var items = [_]Accordion.AccordionItem{
    .{
        .title = "Product Information",
        .description =
        \\Our flagship product combines cutting-edge technology with sleek design.
        \\Built with premium materials, it offers unparalleled performance and reliability.
        \\Our flagship product combines cutting-edge technology with sleek design. Built with premium materials, it offers unparalleled performance and reliability.
        ,
        .trigger = AccordionTrigger,
        .content = AccordionContent,
    },
    .{ .title = "Title", .description =
    \\We stand behind our products with a comprehensive 30-day return policy. If you're not completely satisfied, simply return the item in its original condition.
    \\Our hassle-free return process includes free return shipping and full refunds processed within 48 hours of receiving the returned item.
    , .trigger = AccordionTrigger, .content = AccordionContent },
};

var status_options = [_]Select(Status).Item{
    .{ .value = Status.pending, .label = "Pending" },
    .{ .value = Status.success, .label = "Success" },
    .{ .value = Status.err, .label = "Error" },
};

fn AccordionTrigger(item: *Accordion.AccordionItem) void {
    Text(item.title)
        .fontFamily("Montserrat")
        .font(16, 300, .palette(.text_color)).end();
}

fn AccordionContent(item: *Accordion.AccordionItem) void {
    Text(item.description).font(16, 300, .palette(.text_color)).end();
}

fn onStatusSelect(_: *Select(Status), item: *Select(Status).Item) void {
    current_row.status = item.value;
}

fn sample(_: *Sheet) void {
    Stack()
        .width(.percent(100))
        .height(.percent(100))
        .layout(.top_center)
        .spacing(8)
        .children({
        Stack()
            .layout(.center)
            .children({
            TextFmt("{d}", .{2650})
                .layout(.center)
                .font(72, 700, .palette(.text_color))
                .fontFamily("Montserrat")
                .end();
            Text("Github Stars")
                .layout(.center)
                .font(14, 300, .palette(.text_color))
                .fontFamily("Montserrat")
                .end();
        });
    });
}

var combobox_options = [_]ComboBox(Status).Item{
    .{ .value = Status.pending, .label = "Pending" },
    .{ .value = Status.success, .label = "Success" },
    .{ .value = Status.err, .label = "Error" },
    .{ .value = Status.pending, .label = "Pending" },
    .{ .value = Status.err, .label = "Error" },
    .{ .value = Status.success, .label = "Success" },
    .{ .value = Status.err, .label = "Error" },
};
const MenuItem = Item([]const u8);

const menu_items = &.{
    MenuItem{ .label = "Item 1", .value = "1", .icon = Vapor.IconTokens.hash },
    MenuItem{ .label = "Item 2", .value = "2", .icon = Vapor.IconTokens.hash },
    MenuItem{ .label = "Item 3", .value = "3", .icon = Vapor.IconTokens.hash },
    MenuItem{ .label = "Item 4", .value = "4", .icon = Vapor.IconTokens.hash },
    MenuItem{ .label = "Item 5", .value = "5", .icon = Vapor.IconTokens.hash },
    MenuItem{ .label = "Item 6", .value = "6", .icon = Vapor.IconTokens.hash },
    MenuItem{ .label = "Item 7", .value = "7", .icon = Vapor.IconTokens.hash },
    MenuItem{ .label = "Item 8", .value = "8", .icon = Vapor.IconTokens.hash },
    MenuItem{ .label = "Item 9", .value = "9", .icon = Vapor.IconTokens.hash },
};

fn initTableData() void {
    data.appendSlice(&.{
        .{ .id = 0, .status = .pending, .email = "john@doe.com", .amount = 100 },
        .{ .id = 1, .status = .success, .email = "jane@doe.com", .amount = 200 },
        .{ .id = 2, .status = .err, .email = "john@doe.com", .amount = 300 },
        .{ .id = 3, .status = .pending, .email = "mary@doe.com", .amount = 400 },
        .{ .id = 4, .status = .success, .email = "vic@doe.com", .amount = 500 },
        .{ .id = 5, .status = .err, .email = "alicia@doe.com", .amount = 600 },
        .{ .id = 6, .status = .pending, .email = "nick@doe.com", .amount = 700 },
        .{ .id = 7, .status = .success, .email = "paxton@doe.com", .amount = 800 },
        .{ .id = 8, .status = .err, .email = "jaden@doe.com", .amount = 900 },
        .{ .id = 9, .status = .pending, .email = "sara@doe.com", .amount = 1000 },
        .{ .id = 10, .status = .success, .email = "marina@doe.com", .amount = 1100 },
        .{ .id = 11, .status = .err, .email = "gil@doe.com", .amount = 1200 },
        .{ .id = 12, .status = .pending, .email = "clara@doe.com", .amount = 1300 },
        .{ .id = 13, .status = .pending, .email = "mads@doe.com", .amount = 1400 },
        .{ .id = 14, .status = .success, .email = "jake@doe.com", .amount = 1500 },
        .{ .id = 15, .status = .err, .email = "james@doe.com", .amount = 1600 },
        .{ .id = 16, .status = .pending, .email = "jake@doe.com", .amount = 1700 },
        .{ .id = 17, .status = .success, .email = "james@doe.com", .amount = 1800 },
        .{ .id = 18, .status = .err, .email = "james@doe.com", .amount = 1900 },
        .{ .id = 19, .status = .pending, .email = "jake@doe.com", .amount = 2000 },
        .{ .id = 20, .status = .success, .email = "james@doe.com", .amount = 2100 },
        .{ .id = 21, .status = .err, .email = "james@doe.com", .amount = 2200 },
        .{ .id = 22, .status = .pending, .email = "jake@doe.com", .amount = 2300 },
        .{ .id = 23, .status = .success, .email = "james@doe.com", .amount = 2400 },
        .{ .id = 24, .status = .err, .email = "james@doe.com", .amount = 2500 },
        .{ .id = 25, .status = .pending, .email = "jake@doe.com", .amount = 2600 },
        .{ .id = 26, .status = .success, .email = "james@doe.com", .amount = 2700 },
        .{ .id = 27, .status = .err, .email = "james@doe.com", .amount = 2800 },
        .{ .id = 28, .status = .pending, .email = "jake@doe.com", .amount = 2900 },
        .{ .id = 29, .status = .success, .email = "james@doe.com", .amount = 3000 },
        .{ .id = 30, .status = .err, .email = "james@doe.com", .amount = 3100 },
        .{ .id = 31, .status = .pending, .email = "jake@doe.com", .amount = 3200 },
        .{ .id = 32, .status = .success, .email = "james@doe.com", .amount = 3300 },
        .{ .id = 33, .status = .err, .email = "james@doe.com", .amount = 3400 },
        .{ .id = 34, .status = .pending, .email = "jake@doe.com", .amount = 3500 },
        .{ .id = 35, .status = .success, .email = "james@doe.com", .amount = 3600 },
        .{ .id = 36, .status = .err, .email = "james@doe.com", .amount = 3700 },
        .{ .id = 37, .status = .pending, .email = "jake@doe.com", .amount = 3800 },
        .{ .id = 38, .status = .success, .email = "james@doe.com", .amount = 3900 },
        .{ .id = 39, .status = .err, .email = "james@doe.com", .amount = 4000 },
        .{ .id = 40, .status = .pending, .email = "jake@doe.com", .amount = 4100 },
        .{ .id = 41, .status = .success, .email = "james@doe.com", .amount = 4200 },
        .{ .id = 42, .status = .err, .email = "james@doe.com", .amount = 4300 },
        .{ .id = 42, .status = .err, .email = "james@doe.com", .amount = 4300 },
        .{ .id = 44, .status = .pending, .email = "jake@doe.com", .amount = 4500 },
        .{ .id = 45, .status = .success, .email = "james@doe.com", .amount = 4600 },
        .{ .id = 46, .status = .err, .email = "james@doe.com", .amount = 4700 },
        .{ .id = 47, .status = .pending, .email = "jake@doe.com", .amount = 4800 },
        .{ .id = 48, .status = .success, .email = "james@doe.com", .amount = 4900 },
        .{ .id = 49, .status = .err, .email = "james@doe.com", .amount = 5000 },
        .{ .id = 50, .status = .pending, .email = "jake@doe.com", .amount = 5100 },
        .{ .id = 51, .status = .success, .email = "james@doe.com", .amount = 5200 },
        .{ .id = 52, .status = .err, .email = "james@doe.com", .amount = 5300 },
        .{ .id = 53, .status = .pending, .email = "jake@doe.com", .amount = 5400 },
        .{ .id = 54, .status = .success, .email = "james@doe.com", .amount = 5500 },
        .{ .id = 55, .status = .err, .email = "james@doe.com", .amount = 5600 },
        .{ .id = 56, .status = .pending, .email = "jake@doe.com", .amount = 5700 },
        .{ .id = 57, .status = .success, .email = "james@doe.com", .amount = 5800 },
        .{ .id = 58, .status = .err, .email = "james@doe.com", .amount = 5900 },
        .{ .id = 59, .status = .pending, .email = "jake@doe.com", .amount = 6000 },
        .{ .id = 60, .status = .success, .email = "james@doe.com", .amount = 6100 },
        .{ .id = 61, .status = .err, .email = "james@doe.com", .amount = 6200 },
        .{ .id = 62, .status = .pending, .email = "jake@doe.com", .amount = 6300 },
        .{ .id = 63, .status = .success, .email = "james@doe.com", .amount = 6400 },
        .{ .id = 64, .status = .err, .email = "james@doe.com", .amount = 6500 },
        .{ .id = 65, .status = .pending, .email = "jake@doe.com", .amount = 6600 },
        .{ .id = 66, .status = .success, .email = "james@doe.com", .amount = 6700 },
        .{ .id = 67, .status = .err, .email = "james@doe.com", .amount = 6800 },
        .{ .id = 68, .status = .pending, .email = "jake@doe.com", .amount = 6900 }, // <-- add this
        .{ .id = 69, .status = .success, .email = "james@doe.com", .amount = 7000 },
        .{ .id = 70, .status = .err, .email = "james@doe.com", .amount = 7100 },
        .{ .id = 71, .status = .pending, .email = "jake@doe.com", .amount = 7200 },
        .{ .id = 72, .status = .success, .email = "james@doe.com", .amount = 7300 },
        .{ .id = 73, .status = .err, .email = "james@doe.com", .amount = 7400 },
        .{ .id = 74, .status = .pending, .email = "jake@doe.com", .amount = 7500 },
        .{ .id = 75, .status = .success, .email = "james@doe.com", .amount = 7600 },
        .{ .id = 76, .status = .err, .email = "james@doe.com", .amount = 7700 },
        .{ .id = 77, .status = .pending, .email = "jake@doe.com", .amount = 7800 },
        .{ .id = 78, .status = .success, .email = "james@doe.com", .amount = 7900 },
        .{ .id = 79, .status = .err, .email = "james@doe.com", .amount = 8000 },
        .{ .id = 80, .status = .pending, .email = "jake@doe.com", .amount = 8100 },
        .{ .id = 81, .status = .success, .email = "james@doe.com", .amount = 8200 },
        .{ .id = 82, .status = .err, .email = "james@doe.com", .amount = 8300 },
        .{ .id = 83, .status = .pending, .email = "jake@doe.com", .amount = 8400 },
        .{ .id = 84, .status = .success, .email = "james@doe.com", .amount = 8500 },
        .{ .id = 85, .status = .err, .email = "james@doe.com", .amount = 8600 },
        .{ .id = 86, .status = .pending, .email = "jake@doe.com", .amount = 8700 },
        .{ .id = 87, .status = .success, .email = "james@doe.com", .amount = 8800 },
        .{ .id = 88, .status = .err, .email = "james@doe.com", .amount = 8900 },
        .{ .id = 89, .status = .pending, .email = "jake@doe.com", .amount = 9000 },
        .{ .id = 90, .status = .success, .email = "james@doe.com", .amount = 9100 },
        .{ .id = 91, .status = .err, .email = "james@doe.com", .amount = 9200 },
    });
}

pub fn init() void {
    initTableData();
    table.init(data.items);
    table.on_select = onSelect;
    status_select = .fromItems(&status_options);
    status_select.on_select = onStatusSelect;
    chart = Chart.init(Vapor.arena(.persist), .{
        .height = 300 / 1,
        .width = 600 / 1,
        // .margin = .{ .top = 0, .bottom = 0, .left = 0, .right = 0 }, // Defaults
        .palette = .{ .colors = &.{ "#3b82f6", "#ef4444" } },
    });

    const sales = [_]Chart.Point{
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
    };

    const costs = [_]Chart.Point{
        .{ .x = 1, .y = 20 },
        .{ .x = 2, .y = 35 },
        .{ .x = 3, .y = 30 },
        .{ .x = 4, .y = 50 },
        .{ .x = 5, .y = 45 },
        .{ .x = 6, .y = 55 },
        .{ .x = 7, .y = 75 },
        .{ .x = 8, .y = 85 },
        .{ .x = 9, .y = 95 },
        .{ .x = 10, .y = 100 },
    };

    chart.addSeries(.bar, "Sales", &sales, .{ .color = .palette(.chart_bar_color) }) catch unreachable;
    chart.addSeries(.line_smooth, "Costs", &costs, .{ .color = .palette(.tint) }) catch unreachable;

    chart.xAxis(.{ .label = "Month", .tick_count = 6 });
    chart.yAxis(.{ .label = "USD ($)", .tick_count = 5 });
    chart.legend(.{ .position = .top_left });
    chart.build() catch unreachable;
    sheet = Sheet.init(.bottom);
    sheet.content = sample;
    alert = Alert.init(content);

    combobox = .fromItems(&combobox_options);
    combobox_dialog = .fromItems(menu_items);
    combobox_dialog.on_mount = openPalette;
    combobox_dialog.on_close = closePalette;
    command_palette.on_click = openSearch;
    months_select = .fromItems(&months);
    years_select = .fromItems(&years);
    accordion = Accordion.init(&items);

    date_picker.init();
}

fn openPalette() void {}

fn openSearch() void {
    combobox_dialog.clearAll();
    combobox_dialog.clearText();
    combobox_dialog.open();
}

fn closeSearch() void {
    combobox_dialog.close();
}

fn closePalette() void {
    command_palette.clicked = false;
}

var counter: usize = 0;
fn regenerate() void {
    if (counter % 2 == 0) {
        const costs = [_]Chart.Point{
            .{ .x = 1, .y = 80 },
            .{ .x = 2, .y = 20 },
            .{ .x = 3, .y = 25 },
            .{ .x = 4, .y = 40 },
            .{ .x = 5, .y = 55 },
            .{ .x = 6, .y = 25 },
            .{ .x = 7, .y = 30 },
            .{ .x = 8, .y = 20 },
            .{ .x = 9, .y = 45 },
            .{ .x = 10, .y = 15 },
        };

        const sales = [_]Chart.Point{
            .{ .x = 1, .y = 40 },
            .{ .x = 2, .y = 95 },
            .{ .x = 3, .y = 10 },
            .{ .x = 4, .y = 40 },
            .{ .x = 5, .y = 65 },
            .{ .x = 6, .y = 75 },
            .{ .x = 7, .y = 80 },
            .{ .x = 8, .y = 20 },
            .{ .x = 9, .y = 25 },
            .{ .x = 10, .y = 40 },
        };

        chart.updateSeries(&.{
            Chart.SeriesData{ .name = "Sales", .data = &sales },
            Chart.SeriesData{ .name = "Costs", .data = &costs },
        });
    } else {
        const sales = [_]Chart.Point{
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
        };

        const costs = [_]Chart.Point{
            .{ .x = 1, .y = 20 },
            .{ .x = 2, .y = 35 },
            .{ .x = 3, .y = 30 },
            .{ .x = 4, .y = 50 },
            .{ .x = 5, .y = 45 },
            .{ .x = 6, .y = 55 },
            .{ .x = 7, .y = 75 },
            .{ .x = 8, .y = 85 },
            .{ .x = 9, .y = 95 },
            .{ .x = 10, .y = 100 },
        };

        chart.updateSeries(&.{
            Chart.SeriesData{ .name = "Sales", .data = &sales },
            Chart.SeriesData{ .name = "Costs", .data = &costs },
        });
    }
    counter += 1;
}

fn content(_: *Alert) void {
    Row()
        .width(.percent(100))
        .spacing(16)
        .direction(.column)
        .children({
        Text("Are you sure?")
            .font(22, 700, .palette(.text_color))
            .fontFamily("Montserrat")
            .end();
        Text("This action cannot be undone. This will permanently delete your account and remove your data from our servers.")
            .font(14, 300, .palette(.text_color))
            .fontFamily("Montserrat")
            .end();

        Row()
            .width(.percent(100))
            .spacing(16)
            .layout(.right_center)
            .children({
            ButtonCtx(Alert.close, .{&alert})
                .ariaLabel("Close Alert")
                .cursor(.pointer)
                .hw(.px(42), .px(100))
                .background(.palette(.text_color))
                .border(.round(.palette(.text_color), .all(12)))
                .duration(100)
                .hoverScale()
                .children({
                Text("Cancel").fontFamily("Montserrat").font(14, null, .white).end();
            });
            ButtonCtx(Alert.close, .{&alert})
                .ariaLabel("Close Alert")
                .cursor(.pointer)
                .hw(.px(42), .px(100))
                .border(.round(.palette(.text_color), .all(12)))
                .duration(100)
                .hoverScale()
                .children({
                Text("Close").fontFamily("Montserrat").font(14, null, .black).end();
            });
        });
    });
}

fn addSuccessToast() void {
    Toast.info(.{ .title = "Success", .description = "This is a success toast" });
}

fn addErrorToast() void {
    Toast.err(.{ .title = "Error", .description = "This is an error toast" });
}

fn addWarningToast() void {
    Toast.warning(.{ .title = "Warning", .description = "This is a warning toast" });
}

fn addInfoToast() void {
    Toast.info(.{ .title = "Info", .description = "This is an info toast" });
}

var hovered: bool = false;

fn onHover(_: *Vapor.Event) void {
    hovered = true;
    std.log.info("Hovered", .{});
}

pub fn TabsView() void {
    const active = Tabs.create("sample tabs", &.{ "Auth", "Sign In", "Log in" })
        .render();

    switch (active) {
        0 => {
            // Auth
        },
        1 => {
            // Sign In
        },
        2 => {
            // Log in
        },
        else => {},
    }

    // Tabs.renderSample();
}

pub fn View() void {
    Vapor.Stack()
        .width(.percent(100))
        .children({
        // Two columns of examples on wide screens, one on phones.
        Vapor.Row()
            .width(.percent(100))
            .spacing(16)
            .padding(.all(32))
            .columns(2)
            .responsive(.mobile, .{ .direction = .column, .padding = .all(8) })
            .children({
            Vapor.Stack()
                .width(.expand)
                .spacing(16)
                .layer(.grid(14, 1, .palette(.grid_color)))
                .children({
                Vapor.Row()
                    .width(.percent(100))
                    .height(.fit)
                    .children({
                    table.render();
                });
                Row()
                    .direction(.row)
                    .padding(.all(16))
                    .layout(.top_center)
                    .width(.percent(100))
                    .spacing(16)
                    .responsive(.mobile, .{ .direction = .column, .padding = .all(0) })
                    .children({
                    date_picker.render();
                    Stack()
                        .width(.expand)
                        .children({
                        login.render(); // this is the broken line
                    });
                });
                Row()
                    .width(.percent(100))
                    .spacing(8)
                    .children({
                    Row()
                        .width(.percent(90))
                        .border(.round(.palette(.border_color_light), .all(12)))
                        .padding(.all(16))
                        .direction(.column)
                        .spacing(16)
                        .background(.palette(.background))
                        .children({
                        Stack().children({
                            Row()
                                .width(.percent(100))
                                .layout(.x_between_center)
                                .children({
                                Text("Billing Information")
                                    .font(18, 300, .palette(.text_color))
                                    .end();
                                Switch.render("file-switch", Vapor.alert, .{ "{s}", .{"Im a switch"} });
                            });
                            Text("Billing information is required to process your payment. Use the following information to complete your purchase.")
                                .font(12, 300, .palette(.text_color))
                                .end();
                        });
                        Row()
                            .width(.percent(100))
                            .layout(.x_between_center)
                            .children({
                            Button(std.log.info, .{ "{s}", .{"hello"} })
                                .ariaLabel("Print Hello")
                                .width(.px(36))
                                .height(.px(36))
                                .border(.round(.palette(.border_color_light), .all(99)))
                                .layout(.center)
                                .children({
                                Vapor.Icon(.plus)
                                    .font(24, 300, .palette(.text_color))
                                    .end();
                            });
                            Vapor.Stack()
                                .width(.percent(90))
                                .children({
                                Field.render(.{ .label = "Add File", .value = .{ .string = &file_text } });
                            });
                        });
                        Stack()
                            .width(.percent(100))
                            .spacing(8)
                            .children({
                            Text("Payment Method")
                                .font(18, 300, .palette(.text_color))
                                .end();
                            Field.render(.{ .label = "Card Number", .value = .{ .string = &card_number } });
                        });
                        Row()
                            .width(.percent(100))
                            .layout(.x_between_center)
                            .spacing(16)
                            .children({
                            Stack()
                                .width(.percent(60))
                                .spacing(4)
                                .children({
                                Text("Month")
                                    .font(16, 300, .palette(.text_color))
                                    .end();
                                months_select.render();
                            });
                            Stack()
                                .width(.percent(30))
                                .spacing(4)
                                .children({
                                Text("Year")
                                    .font(16, 300, .palette(.text_color))
                                    .end();
                                years_select.render();
                            });
                        });
                        Row()
                            .width(.percent(100))
                            .height(.fit)
                            .layout(.right_center)
                            .children({
                            Button(addSuccessToast, .{})
                                .ariaLabel("Success Toast")
                                .background(.transparentize(.palette(.tint), 0.7))
                                .border(.round(.palette(.tint), .all(12)))
                                .children({
                                Text("Success")
                                    .font(14, 300, .palette(.text_color))
                                    .fontFamily("IBM Plex Sans,monospace")
                                    .end();
                                Vapor.Icon(.send)
                                    .font(16, 700, .palette(.text_color))
                                    .end();
                            });
                        });
                    });
                    Vapor.Stack()
                        .width(.percent(8))
                        .layout(.top_center)
                        .padding(.vertical(8))
                        .border(.round(.palette(.border_color_light), .all(12)))
                        .background(.palette(.background))
                        .spacing(8)
                        .children({
                        Button(std.log.info, .{ "{s}", .{"hello"} })
                            .ariaLabel("Print Hello")
                            .width(.px(32))
                            .height(.px(32))
                            .border(.round(.palette(.border_color_light), .all(99)))
                            .layout(.center)
                            .hover(.{
                                .transform = .scaleDecimal(1.1),
                                .text_color = .palette(.tint),
                                .border = .round(.palette(.tint), .all(99)),
                            })
                            .children({
                            Vapor.Icon(.cloud)
                                .font(16, 300, null)
                                .end();
                        });
                        Button(std.log.info, .{ "{s}", .{"hello"} })
                            .ariaLabel("Print Hello")
                            .width(.px(32))
                            .height(.px(32))
                            .border(.round(.palette(.border_color_light), .all(99)))
                            .layout(.center)
                            .hover(.{
                                .transform = .scaleDecimal(1.1),
                                .text_color = .palette(.tint),
                                .border = .round(.palette(.tint), .all(99)),
                            })
                            .children({
                            Vapor.Icon(.motherboard)
                                .font(16, 300, null)
                                .end();
                        });
                        Button(std.log.info, .{ "{s}", .{"hello"} })
                            .ariaLabel("Print Hello")
                            .width(.px(32))
                            .height(.px(32))
                            .border(.round(.palette(.border_color_light), .all(99)))
                            .layout(.center)
                            .hover(.{
                                .transform = .scaleDecimal(1.1),
                                .text_color = .palette(.tint),
                                .border = .round(.palette(.tint), .all(99)),
                            })
                            .children({
                            Vapor.Icon(.github)
                                .font(16, 300, null)
                                .end();
                        });
                        Button(std.log.info, .{ "{s}", .{"hello"} })
                            .ariaLabel("Print Hello")
                            .width(.px(32))
                            .height(.px(32))
                            .border(.round(.palette(.border_color_light), .all(99)))
                            .layout(.center)
                            .hover(.{
                                .transform = .scaleDecimal(1.1),
                                .text_color = .palette(.tint),
                                .border = .round(.palette(.tint), .all(99)),
                            })
                            .children({
                            Vapor.Icon(.heart_balloon)
                                .font(16, 300, null)
                                .end();
                        });
                    });
                });
            });
            Vapor.Stack()
                .width(.expand)
                .spacing(16)
                .children({
                // chart.render();
                Row()
                    .width(.percent(100))
                    .height(.fit)
                    .layout(.right_center)
                    .children({
                    Button(regenerate, .{})
                        .ariaLabel("Regenerate Chart")
                        .hover(.{
                            .background = if (Theme.mode == .light) .yellow else .palette(.danger),
                            .animation = "glitch",
                        })
                        .border(.round(.palette(.text_color), .all(12)))
                        .onHover(onHover, .{})
                        .spacing(16)
                        .children({
                        Text("//")
                            .font(16, 300, .palette(.text_color))
                            .fontFamily("IBM Plex Sans,monospace")
                            .end();
                        Text("Re-generate")
                            .font(16, 300, .palette(.text_color))
                            .fontFamily("IBM Plex Sans,monospace")
                            .end();
                        Text("_ ↺")
                            .animation(if (hovered) "blink" else null)
                            .font(16, 300, .palette(.text_color))
                            .fontFamily("IBM Plex Sans,monospace")
                            .end();
                    });
                });
                Row()
                    .width(.expand)
                    .height(.px(72))
                    .layout(.center)
                    .spacing(16)
                    .children({
                    Button(Sheet.open, .{&sheet})
                        .ariaLabel("Open Sheet")
                        .width(.px(200))
                        .background(.transparentize(.palette(.tint), 0.7))
                        .border(.round(.palette(.tint), .all(12)))
                        .children({
                        Text("Open Drawer")
                            .font(16, 300, .palette(.text_color))
                            .fontFamily("IBM Plex Sans,monospace")
                            .end();
                        Vapor.Icon(.arrow_right)
                            .font(16, 700, .palette(.text_color))
                            .end();
                    });
                    combobox.render();
                });
                accordion.render();
                Row()
                    .width(.percent(100))
                    .height(.px(128))
                    .border(.round(.palette(.border_color_light), .all(12)))
                    .padding(.all(16))
                    .direction(.column)
                    .spacing(8)
                    .children({
                    Row()
                        .width(.percent(100))
                        .layout(.x_between_center)
                        .children({
                        Text("Enable Developer Mode")
                            .font(18, 300, .palette(.text_color))
                            .end();
                        Switch.render("test-switch", Vapor.alert, .{ "{s}", .{"Im a switch"} });
                    });
                    Text("Switch to developer mode to see developer tools, and debug your application.")
                        .font(12, 300, .palette(.text_color))
                        .end();
                });

                Row()
                    .width(.percent(100))
                    .height(.px(256))
                    .border(.round(.palette(.border_color_light), .all(12)))
                    .padding(.all(16))
                    .direction(.column)
                    .spacing(8)
                    .children({
                    Text("Bug Fixes")
                        .font(24, 300, .palette(.text_color))
                        .end();

                    Text("Record any bugs you find, and we will fix them ASAP!")
                        .font(14, 300, .palette(.text_color))
                        .end();

                    Vapor.TextArea()
                        .ariaLabel("Text Area")
                        .width(.percent(100))
                        .height(.percent(100))
                        .outline(.none, null)
                        .border(.solid(.{ .top = 1, .bottom = 3, .left = 1, .right = 1 }, .palette(.border_color_light), .all(6)))
                        .background(.palette(.background))
                        .padding(.all(8))
                        .font(16, 300, .palette(.text_color))
                        .fontFamily("IBM Plex Sans,monospace")
                        .resize(.none)
                        .end();

                    Row()
                        .width(.percent(100))
                        .height(.fit)
                        .layout(.right_center)
                        .children({
                        Button(addSuccessToast, .{})
                            .ariaLabel("Success Toast")
                            .hover(.{
                                .background = if (Theme.mode == .light) .yellow else .palette(.danger),
                                .animation = "glitch",
                            })
                            .border(.round(.palette(.text_color), .all(12)))
                            .onHover(onHover, .{})
                            .spacing(16)
                            .children({
                            Text("//")
                                .font(16, 300, .palette(.text_color))
                                .fontFamily("IBM Plex Sans,monospace")
                                .end();
                            Text("Glitch")
                                .font(16, 300, .palette(.text_color))
                                .fontFamily("IBM Plex Sans,monospace")
                                .end();
                            Text("_ ⇒")
                                .animation(if (hovered) "blink" else null)
                                .font(16, 300, .palette(.text_color))
                                .fontFamily("IBM Plex Sans,monospace")
                                .end();
                        });
                    });
                });
                Button(ComboBoxDialog([]const u8).open, .{&combobox_dialog})
                    .ariaLabel("Open ComboBox Dialog")
                    .children({
                    Text("Open Dialog")
                        .font(14, 300, .palette(.text_color))
                        .fontFamily("IBM Plex Sans,monospace")
                        .end();
                });

                Row()
                    .width(.percent(70))
                    // .height(.px(256))
                    .border(.round(.palette(.border_color_light), .all(12)))
                    .padding(.all(16))
                    .direction(.column)
                    .spacing(16)
                    .children({
                    Stack()
                        .width(.percent(100))
                        .layout(.top_left)
                        .spacing(8)
                        .children({
                        Text("Profile")
                            .font(18, 300, .palette(.text_color))
                            .end();
                        Text("Upload your profile picture")
                            .font(12, 300, .palette(.text_color))
                            .end();
                    });

                    Stack()
                        .layout(.center)
                        .width(.percent(100))
                        .children({
                        Row()
                            .pos(.relative)
                            .width(.px(256))
                            .height(.px(256))
                            .children({
                            if (file_upload.image_src.len > 0) {
                                Vapor.Image(.{ .src = file_upload.image_src })
                                    .pos(.absolute)
                                    .width(.px(256))
                                    .height(.px(256))
                                    // .newShadow(Vapor.Types.NewShadow.init()
                                    // .drop(0, 1, 3, .transparentizeHex(.black, 0.1)))
                                    .border(.round(.transparent, .all(12)))
                                    .outline(.none, null)
                                    .end();
                            }
                            Row()
                                .pos(.absolute)
                                .width(.px(256))
                                .height(.px(256))
                                .children({
                                file_upload.render();
                            });
                        });
                    });
                    Field.render(.{ .label = "Email", .value = .{ .string = &text }, .trans_label = true });
                    Field.render(.{ .label = "Password", .value = .{ .password = &password }, .trans_label = true });
                    // Slider.render(.{});
                });
            });
        });
        sheet.render();
        alert.render();
    });
}

var file_upload: Opaque.FileUpload = .{};

fn comboboxDialogOpen() void {
    combobox_dialog.open();
}
