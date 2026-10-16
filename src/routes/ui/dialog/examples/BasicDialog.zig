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

pub fn init() void {
    basic_dialog = .fromItems(basic_items);
}

pub fn render() void {
    Button(Dialog.open, .{&basic_dialog})
        .ariaLabel("open basic dialog")
        .padding(.xy(12, 8))
        .background(.transparentizeHex(.palette(.tint), 0.7))
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
    basic_dialog.render();
}
