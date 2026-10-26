const std = @import("std");
const Vapor = @import("vapor");
const Hero = @import("../../../../components/Hero.zig").Hero;
const Text = Vapor.Text;
const Row = Vapor.Row;
const Stack = Vapor.Stack;
const Icon = Vapor.Icon;
const Opaque = @import("opaque-ui");
const Button = Opaque.Button;
const CommandPalette = Opaque.CommandPalette;

// ============================================================================
// THEME
// ============================================================================

const Theme = struct {
    const bg = Vapor.Types.Color.palette(.background);
    const text = Vapor.Types.Color.palette(.text_color);
    const text_muted = Vapor.Types.Color.hex("#71717a");
    const border = Vapor.Types.Color.palette(.border_color_light);
    const code_bg = Vapor.Types.Color.hex("#1a1a1a");
};

// ============================================================================
// CODE SNIPPET COMPONENT
// ============================================================================

fn code_snippet(code: []const u8) void {
    Row()
        .width(.percent(100))
        .padding(.all(16))
        .background(Theme.code_bg)
        .scroll(.scrollX())
        .border(.round(Theme.border, .all(8)))
        .children({
        Text(code)
            .font(14, 400, .hex("#e4e4e7"))
            .fontFamily("IBM Plex Mono,monospace")
            .end();
    });
}

fn section_title(title: []const u8) void {
    Text(title)
        .font(24, 600, Theme.text)
        .fontFamily("IBM Plex Mono,monospace")
        .margin(.{ .top = 32 })
        .end();
}

fn section_description(desc: []const u8) void {
    Text(desc)
        .font(14, 400, Theme.text_muted)
        .fontFamily("IBM Plex Mono,monospace")
        .margin(.{ .bottom = 16 })
        .end();
}

// ============================================================================
// MAIN RENDER
// ============================================================================

var command_palette: CommandPalette = .{ .text = "Search..." };
var open_dialog: CommandPalette = .{ .text = "Open Dialog..." };
pub fn init() void {
    command_palette.key_press = "j";
    open_dialog.key_press = "i";
    Vapor.Page(.{ .src = @src() }, render, null);
}

fn Card() Vapor.Builder(.pure) {
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

pub fn render() void {
    Row()
        .width(.percent(100))
        .layout(.top_center)
        .direction(.column)
        .children({
        Hero("command-palette-ui", "A collection of ready-to-use command-palette components built on top of Vapor. Copy and paste into your apps.");

        Stack()
            .width(.px(720))
            .responsive(.mobile, .{ .size = .w(.percent(92)) })
            .height(.percent(100))
            .spacing(12)
            .children({
            // Page Title
            Text("Command Palette")
                .font(36, 700, Theme.text)
                .fontFamily("IBM Plex Mono,monospace")
                .end();

            Text("Displays a command-palette or a component that looks like a command-palette.")
                .font(16, 400, Theme.text_muted)
                .fontFamily("IBM Plex Mono,monospace")
                .margin(.{ .bottom = 24 })
                .end();

            // Preview Section

            // Primary
            Text("Primary")
                .font(14, 500, Theme.text_muted)
                .fontFamily("IBM Plex Mono,monospace")
                .end();
            Card().children({
                command_palette.render();
            });

            // Secondary
            Text("Secondary")
                .font(14, 500, Theme.text_muted)
                .fontFamily("IBM Plex Mono,monospace")
                .end();
            Card().children({
                open_dialog.render();
            });

            // Installation Section
            section_title("Installation");
            section_description("Install the command-palette component from your command line.");

            code_snippet("vapor add command-palette");

            // Usage Section
            section_title("Usage");
            section_description("Import and use the Button component in your code.");

            code_snippet("const Button = @import(\"opaque-ui\").Button;");

            // Examples Section
            section_title("Examples");

            // Primary Button
            Text("Primary")
                .font(18, 500, Theme.text)
                .fontFamily("IBM Plex Mono,monospace")
                .margin(.{ .top = 16 })
                .end();

            code_snippet(
                \\Button(handleClick, .{})
                \\    .background(.palette(.tint))
                \\    .children({
                \\        Text("Primary").end();
                \\    });
            );

            // Secondary Button
            Text("Secondary")
                .font(18, 500, Theme.text)
                .fontFamily("IBM Plex Mono,monospace")
                .margin(.{ .top = 16 })
                .end();

            code_snippet(
                \\Button(handleClick, .{})
                \\    .background(.transparent)
                \\    .border(.round(.palette(.border_color_light), .all(8)))
                \\    .children({
                \\        Text("Secondary").end();
                \\    });
            );

            // With Icon
            Text("With Icon")
                .font(18, 500, Theme.text)
                .fontFamily("IBM Plex Mono,monospace")
                .margin(.{ .top = 16 })
                .end();

            code_snippet(
                \\Button(handleClick, .{})
                \\    .children({
                \\        Icon(.arrow_right).end();
                \\        Text("Continue").end();
                \\    });
            );

            // API Reference Section
            section_title("API Reference");
            section_description("The Button component accepts the following properties.");

            code_snippet(
                \\// Handler and arguments
                \\Button(handler_fn, .{ arg1, arg2 })
                \\
                \\// Styling
                \\.background(.palette(.tint))
                \\.border(.round(.palette(.border_color_light), .all(8)))
                \\.padding(.xy(16, 10))
                \\.layout(.center)
                \\.spacing(8)
            );
        });
    });
}
