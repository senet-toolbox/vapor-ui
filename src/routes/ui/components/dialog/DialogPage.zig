// page.zig
const std = @import("std");
const Vapor = @import("vapor");
const Hero = @import("../../../../components/Hero.zig").Hero;
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
// Rendered and shown as code: what you read is what runs.
const BasicDialog = @import("examples/BasicDialog.zig");
const CustomDialog = @import("examples/CustomDialog.zig");

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

pub fn init() void {
    const allocator = Vapor.arena(.persist);

    hl_basic = SyntaxHighlighter.init(allocator);
    hl_basic.show_toolbar = true;
    hl_basic.parse(@embedFile("examples/BasicDialog.zig")) catch unreachable;

    hl_custom_render = SyntaxHighlighter.init(allocator);
    hl_custom_render.show_toolbar = true;
    hl_custom_render.parse(@embedFile("examples/CustomDialog.zig")) catch unreachable;

    // Initialize dialogs

    BasicDialog.init();
    CustomDialog.init();

    Vapor.Page(.{ .src = @src() }, render, null);
}

// ============================================================================
// UI HELPERS
// ============================================================================

fn sectionTitle(title: []const u8) void {
    Text(title).font(24, 600, Theme.text).fontFamily("IBM Plex Mono,monospace").margin(.{ .top = 48 }).end();
}

fn sectionDesc(desc: []const u8) void {
    Text(desc).font(14, 400, Theme.text_muted).fontFamily("IBM Plex Mono,monospace").margin(.{ .bottom = 16 }).end();
}

fn exampleLabel(label: []const u8) void {
    Text(label).font(14, 500, Theme.text_muted).fontFamily("IBM Plex Mono,monospace").margin(.{ .top = 24 }).end();
}

fn PreviewCard() Vapor.Builder(.pure) {
    return Stack()
        .background(.transparentize(.palette(.background), 0.5))
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
        .scroll(.scrollY())
        .size(.hw(.mobileDesktop(.fit, .px(512)), .mobileDesktopPercent(100, 100)))
        .border(.thin(.palette(.text_color)))
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
        Hero("dialog-ui", "Highly customizable, accessible command-palette style dialogs for search and selection.");

        // Content
        Stack()
            .width(.percent(50))
            .responsive(.mobile, .{ .size = .w(.percent(92)) })
            .height(.percent(100))
            .spacing(12)
            .padding(.{ .bottom = 120 })
            .children({

            // Basic
            exampleLabel("Basic Dialog");
            sectionDesc("A searchable dialog using default list item rendering.");
            PreviewCard().children({
                BasicDialog.render();
            });
            CodeBox(&hl_basic, "BasicDialog");

            // Custom
            exampleLabel("Custom Rendering");
            sectionDesc("Overriding the row component to create complex, multi-line result items.");
            PreviewCard().children({
                CustomDialog.render();
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
                .scroll(.scrollX())
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
                .scroll(.scrollX())
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
                .scroll(.scrollX())
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
