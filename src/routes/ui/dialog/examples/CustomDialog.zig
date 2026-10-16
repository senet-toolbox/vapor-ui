const std = @import("std");
const Vapor = @import("vapor");
const Text = Vapor.Text;
const Icon = Vapor.Icon;
const Row = Vapor.Row;

const Opaque = @import("opaque-ui");
const ComboBoxDialog = Opaque.ComboBoxDialog;
const Button = Opaque.Button;
const Item = Opaque.Item;

const ComponentType = enum { Basic, Comptime, Complex };
const CustomDialog = ComboBoxDialog(ComponentType);
var custom_dialog: CustomDialog = undefined;
const custom_items = &.{
    Item(ComponentType){
        .value = .Basic,
        .label = "Basic",
        .icon = Vapor.IconTokens.hash,
        .link = "/ui/button",
        .description = "A basic dialog with a button",
    },
    Item(ComponentType){
        .value = .Comptime,
        .label = "Comptime",
        .icon = Vapor.IconTokens.hash,
        .link = "/ui/table",
        .description = "A dialog with a table",
    },
    Item(ComponentType){
        .value = .Complex,
        .label = "Complex",
        .icon = Vapor.IconTokens.hash,
        .link = "/ui/chart",
        .description = "A dialog with a chart",
    },
};

fn custom_row(combobox: *CustomDialog, item: *Item(ComponentType)) void {
    const background_color: Vapor.Types.Color = if (item.is_selected) blk: {
        break :blk .transparentizeHex(.palette(.tint), 0.3);
    } else blk: {
        break :blk .palette(.background);
    };

    const selected_border_color: Vapor.Types.Color = if (combobox.hovered_item == item) blk: {
        break :blk .transparentizeHex(.palette(.tint), 0.2);
    } else blk: {
        break :blk .transparent;
    };
    Vapor.CtxButton(CustomDialog.selectItem, .{ combobox, item })
        .direction(.column)
        .width(.percent(100))
        // .height(.px(44))
        .background(background_color)
        .layout(.left_center)
        .padding(.tblr(6, 6, 6, 24))
        .border(.sharp(.all(1), selected_border_color))
        .children({
        Row()
            .width(.percent(100))
            .layout(.left_center)
            .spacing(8)
            .children({
            Text(item.label)
                .fontFamily("Montserrat")
                .font(18, 700, .transparentizeHex(.palette(.text_color), 0.7))
                .end();
        });
        Vapor.Link(.{ .url = item.link.?, .aria_label = item.label })
            .layout(.left_center)
            .pointer()
            .spacing(4)
            .children({
            if (item.icon) |icon| {
                Icon(icon)
                    .font(14, 300, .transparentizeHex(.palette(.text_color), 0.7))
                    .end();
            }
            Text(item.label)
                .font(14, 300, .palette(.text_color))
                .fontFamily("Montserrat")
                .end();
        });
        Text(item.description orelse "")
            .font(12, 300, .palette(.text_color))
            .fontFamily("Montserrat")
            .end();
    });
}

pub fn init() void {
    custom_dialog = .fromItems(custom_items);
    custom_dialog.row_component = custom_row;
}

pub fn render() void {
    Button(CustomDialog.open, .{&custom_dialog})
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
    custom_dialog.render();
}
