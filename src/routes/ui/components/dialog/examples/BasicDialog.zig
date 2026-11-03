const std = @import("std");
const Vapor = @import("vapor");
const Text = Vapor.Text;
const Icon = Vapor.Icon;

const Opaque = @import("opaque-ui");
const ComboBoxDialog = Opaque.ComboBoxDialog;
const Button = Opaque.Button;
const Item = Opaque.Item;

const Status = enum { pending, success, err };

const Dialog = ComboBoxDialog(Status);
var basic_dialog: Dialog = undefined;
const basic_items = &.{
    Item(Status){ .value = .pending, .label = "Pending" },
    Item(Status){ .value = .success, .label = "Success" },
    Item(Status){ .value = .err, .label = "Error" },
};

var closed_count: usize = 0;

fn onClose() void {
    closed_count += 1;
}

pub fn init() void {
    basic_dialog = .fromItems(basic_items);
    // Names it for screen readers.
    basic_dialog.aria_label = "Pick a status";
    // Once per close: Escape, a pick, or a click outside.
    basic_dialog.on_close = onClose;
}

pub fn render() void {
    Button(Dialog.open, .{&basic_dialog})
        .ariaLabel("open basic dialog")
        .padding(.xy(12, 8))
        .background(.palette(.tint))
        .layout(.center)
        .children({
        Text("open basic dialog")
            .font(14, 300, .palette(.background))
            .fontFamily("Montserrat")
            .end();
        Icon(.arrow_right)
            .font(16, 500, .palette(.background))
            .end();
    });
    Text(Vapor.fmtln("Closed {d} time{s}", .{ closed_count, if (closed_count == 1) "" else "s" }))
        .font(14, 300, .palette(.text_color))
        .end();
    basic_dialog.render();
}
