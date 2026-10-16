// page.zig
const std = @import("std");
const Vapor = @import("vapor");
const Text = Vapor.Text;
const Row = Vapor.Row;
const Stack = Vapor.Stack;
const Opaque = @import("opaque-ui");
const ComboBoxDialog = Opaque.ComboBoxDialog;
const Vaporize = @import("vaporize");
const SyntaxHighlighter = Vaporize.SyntaxHighlighter;
const Icon = Vapor.Icon;
const Button = Opaque.Button;
const Item = Opaque.Item;
const CodeBox = @import("../CodeBox.zig").CodeBox;

// ============================================================================
// THEME
// ============================================================================

const Theme = struct {
    const text = Vapor.Types.Color.palette(.text_color);
    const text_muted = Vapor.Types.Color.hex("#71717a");
    const border = Vapor.Types.Color.palette(.border_color_light);
    const code_bg = Vapor.Types.Color.hex("#1a1a1a");
};

// ============================================================================
// SYNTAX HIGHLIGHTERS
// ============================================================================

var hl_basic: SyntaxHighlighter = undefined;
var hl_custom_render: SyntaxHighlighter = undefined;

// ============================================================================
// DIALOG INSTANCES
// ============================================================================

const Status = enum { pending, success, err };

var basic_dialog: ComboBoxDialog(Status) = undefined;
var basic_items = [_]Item(Status){
    .{ .value = .pending, .label = "Pending" },
    .{ .value = .success, .label = "Success" },
    .{ .value = .err, .label = "Error" },
};

const ComponentType = enum { Basic, Comptime, Complex };
const CustomDialog = ComboBoxDialog(ComponentType);
var custom_dialog: CustomDialog = undefined;

const custom_items = &.{
    Item(ComponentType){
        .value = .Basic,
        .label = "Basic",
        .icon = .hash,
        .link = "/ui/button",
        .description = "A basic dialog with a button",
    },
    Item(ComponentType){
        .value = .Comptime,
        .label = "Comptime",
        .icon = .hash,
        .link = "/ui/table",
        .description = "A dialog with a table",
    },
    Item(ComponentType){
        .value = .Complex,
        .label = "Complex",
        .icon = .hash,
        .link = "/ui/chart",
        .description = "A dialog with a chart",
    },
};

// ============================================================================
// CUSTOM ROW RENDERER
// ============================================================================

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

// ============================================================================
// INIT
// ============================================================================

pub fn init() void {
    const allocator = Vapor.arena(.persist);

    hl_basic = SyntaxHighlighter.init(allocator);
    hl_basic.show_toolbar = true;
    hl_basic.parse(@embedFile("examples/BasicDialog.zig")) catch unreachable;

    hl_custom_render = SyntaxHighlighter.init(allocator);
    hl_custom_render.show_toolbar = true;
    hl_custom_render.parse(@embedFile("examples/CustomDialog.zig")) catch unreachable;

    // Initialize dialogs
    basic_dialog = .fromItems(&basic_items);

    custom_dialog = .fromItems(custom_items);
    custom_dialog.row_component = custom_row;

    Vapor.Page(.{ .src = @src() }, render, null);
}

// ============================================================================
// UI HELPERS
// ============================================================================

fn sectionTitle(title: []const u8) void {
    Text(title).font(24, 600, Theme.text).fontFamily("IBM Plex Mono,monospace").margin(.t(48)).end();
}

fn sectionDesc(desc: []const u8) void {
    Text(desc).font(14, 400, Theme.text_muted).fontFamily("IBM Plex Mono,monospace").margin(.b(16)).end();
}

fn exampleLabel(label: []const u8) void {
    Text(label).font(14, 500, Theme.text_muted).fontFamily("IBM Plex Mono,monospace").margin(.t(24)).end();
}

fn PreviewCard() Vapor.Builder(.pure) {
    return Stack()
        .background(.transparentizeHex(.palette(.background), 0.5))
        .border(.round(.palette(.border_color_light), .all(12)))
        .width(.percent(100))
        .height(.px(160))
        .padding(.all(24))
        .direction(.column)
        .layout(.center)
        .spacing(16);
}

fn CodeBlock(highlighter: *SyntaxHighlighter) void {
    Row()
        .scroll(.scroll_y())
        .size(.hw(.mobile_desktop(.fit, .px(512)), .mobile_desktop_percent(100, 100)))
        .border(.simple(.palette(.text_color)))
        .children({
        highlighter.render() catch unreachable;
    });
}

// ============================================================================
// RENDER
// ============================================================================

pub fn render() void {
    Row()
        .width(.percent(100))
        .layout(.top_center)
        .direction(.column)
        .children({

        // Hero
        Vapor.Stack()
            .layout(.center)
            .height(.px(512))
            .width(.percent(100))
            .children({
            Text("dialog-ui ⇒").style(&.{
                .visual = .font(12, 500, .hex("#6f6f6f")),
                .font_family = "IBM Plex Mono,monospace",
            }).end();
            Text("dialog-ui")
                .font(72, 700, .palette(.text_color))
                .end();
            Text("Highly customizable, accessible command-palette style dialogs for search and selection.")
                .font(16, 300, .palette(.text_color))
                .end();
        });

        // Content
        Stack()
            .width(.percent(50))
            .height(.percent(100))
            .spacing(12)
            .padding(.bottom(120))
            .children({

            // Basic
            exampleLabel("Basic Dialog");
            sectionDesc("A searchable dialog using default list item rendering.");
            PreviewCard().children({
                Button(ComboBoxDialog(Status).open, .{&basic_dialog})
                    .ariaLabel("open basic dialog")
                    .padding(.xy(12, 8))
                    .background(.palette(.tint))
                    .layout(.center)
                    .children({
                    Text("open basic dialog").font(14, 300, .palette(.background)).fontFamily("Montserrat").end();
                    Icon(.arrow_right).font(16, 500, .palette(.background)).end();
                });
                basic_dialog.render();
            });
            CodeBox(&hl_basic, "BasicDialog");

            // Custom
            exampleLabel("Custom Rendering");
            sectionDesc("Overriding the row component to create complex, multi-line result items.");
            PreviewCard().children({
                Button(CustomDialog.open, .{&custom_dialog})
                    .ariaLabel("open custom dialog")
                    .padding(.xy(12, 8))
                    .background(.palette(.tint))
                    .layout(.center)
                    .children({
                    Text("open custom dialog").font(14, 300, .palette(.background)).fontFamily("Montserrat").end();
                    Icon(.arrow_right).font(16, 500, .palette(.background)).end();
                });
                custom_dialog.render();
            });
            CodeBox(&hl_custom_render, "CustomDialog");

            // API Reference
            sectionTitle("API Reference");

            exampleLabel("Generic Item Structure");
            sectionDesc("Item(T) is a global type used across the framework for data consistency.");
            Row()
                .width(.percent(100))
                .padding(.all(16))
                .background(Theme.code_bg)
                .border(.round(Theme.border, .all(8)))
                .children({
                Text(
                    \\Item(T) {
                    \\  value: T,
                    \\  label: []const u8,
                    \\  icon: ?IconTokens,
                    \\  description: ?[]const u8,
                    \\  link: ?[]const u8,
                    \\  is_selected: bool,
                    \\}
                )
                    .font(14, 400, .hex("#e4e4e7"))
                    .fontFamily("IBM Plex Mono,monospace")
                    .end();
            });

            exampleLabel("Custom Row Callback");
            sectionDesc("Provide a custom function to render rows. Receives the dialog and the item pointer.");
            Row()
                .width(.percent(100))
                .padding(.all(16))
                .background(Theme.code_bg)
                .border(.round(Theme.border, .all(8)))
                .children({
                Text("dialog.row_component = myCustomRowFn;")
                    .font(14, 400, .hex("#e4e4e7"))
                    .fontFamily("IBM Plex Mono,monospace")
                    .end();
            });

            exampleLabel("Static Methods");
            sectionDesc("Use .open to trigger the dialog from any Button or Click event.");
            Row()
                .width(.percent(100))
                .padding(.all(16))
                .background(Theme.code_bg)
                .border(.round(Theme.border, .all(8)))
                .children({
                Text("Button(ComboBoxDialog(T).open, .{&my_dialog})")
                    .font(14, 400, .hex("#e4e4e7"))
                    .fontFamily("IBM Plex Mono,monospace")
                    .end();
            });
        });
    });
}
