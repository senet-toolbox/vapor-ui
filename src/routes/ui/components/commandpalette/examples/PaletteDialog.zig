const Vapor = @import("vapor");
const Stack = Vapor.Stack;
const TextFmt = Vapor.TextFmt;
const Opaque = @import("opaque-ui");
const CommandPalette = Opaque.CommandPalette;
const ComboBoxDialog = Opaque.ComboBoxDialog;
const Item = Opaque.Item;

const Dialog = ComboBoxDialog([]const u8);

// Ctrl+I (Cmd+I on a Mac) or a click opens a dialog of pages.
var palette: CommandPalette = .{
    .text = "Open Dialog...",
    .key_press = "i",
    .on_click = toggle,
};
var dialog: Dialog = undefined;
var opened: []const u8 = "nothing yet";

pub fn init() void {
    dialog = .fromItems(&.{
        Item([]const u8){ .value = "/dashboard", .label = "Dashboard" },
        Item([]const u8){ .value = "/settings", .label = "Settings" },
        Item([]const u8){ .value = "/billing", .label = "Billing" },
    });
    dialog.on_select = pick;
    dialog.on_close = closed;
}

// The palette flips its state, then calls this.
fn toggle() void {
    if (palette.clicked) dialog.open() else dialog.close();
}

fn pick(item: *Item([]const u8)) void {
    opened = item.label;
    dialog.close();
}

// However the dialog closes, the field goes back to rest.
fn closed() void {
    palette.clicked = false;
}

pub fn render() void {
    Stack().width(.percent(100)).spacing(12).children({
        palette.render();
        TextFmt("Opened: {s}", .{opened})
            .font(14, 300, .palette(.text_color))
            .end();
    });
    dialog.render();
}
