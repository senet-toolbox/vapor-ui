const std = @import("std");
const Vapor = @import("vapor");
const Hero = @import("../../../../components/Hero.zig").Hero;
const Text = Vapor.Text;
const Row = Vapor.Row;
const Stack = Vapor.Stack;
const Icon = Vapor.Icon;
const Opaque = @import("opaque-ui");
const Button = Opaque.Button;
const CodeBox = @import("../CodeBox.zig").CodeBox;

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

pub fn init() void {
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

fn waiting() void {}

pub fn render() void {
    Row()
        .width(.percent(100))
        .layout(.top_center)
        .direction(.column)
        .children({
        Hero("button-ui", "A collection of ready-to-use button components built on top of Vapor. Copy and paste into your apps.");

        Stack()
            .width(.px(720))
            .responsive(.mobile, .{ .size = .w(.percent(92)) })
            .height(.percent(100))
            .spacing(12)
            .children({
            // Page Title
            Text("Button")
                .font(36, 700, Theme.text)
                .fontFamily("IBM Plex Mono,monospace")
                .end();

            Text("Displays a button or a component that looks like a button.")
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
                Button(std.log.info, .{ "Primary button clicked", .{} })
                    .background(.palette(.tint))
                    .children({
                    Text("Button")
                        .fontFamily("Montserrat")
                        .font(14, 500, .palette(.background)).end();
                });
            });

            // Secondary
            Text("Secondary")
                .font(14, 500, Theme.text_muted)
                .fontFamily("IBM Plex Mono,monospace")
                .end();
            Card().children({
                Button(std.log.info, .{ "Secondary button clicked", .{} })
                    .background(.transparent)
                    .border(.round(.palette(.border_color_light), .all(8)))
                    .children({
                    Text("Secondary")
                        .fontFamily("Montserrat")
                        .font(14, 500, .palette(.text_color)).end();
                });
            });

            // Outline
            Text("Outline")
                .font(14, 500, Theme.text_muted)
                .fontFamily("IBM Plex Mono,monospace")
                .end();
            Card().children({
                Button(std.log.info, .{ "Outline button clicked", .{} })
                    .background(.transparent)
                    .border(.round(.palette(.tint), .all(8)))
                    .children({
                    Text("Outline")
                        .fontFamily("Montserrat")
                        .font(14, 500, .palette(.tint)).end();
                });
            });

            // Ghost
            Text("Ghost")
                .font(14, 500, Theme.text_muted)
                .fontFamily("IBM Plex Mono,monospace")
                .end();
            Card().children({
                Button(std.log.info, .{ "Ghost button clicked", .{} })
                    .background(.transparent)
                    .children({
                    Text("Ghost")
                        .fontFamily("Montserrat")
                        .font(14, 500, .palette(.text_color)).end();
                });
            });

            // Destructive
            Text("Destructive")
                .font(14, 500, Theme.text_muted)
                .fontFamily("IBM Plex Mono,monospace")
                .end();
            Card().children({
                Button(std.log.info, .{ "Destructive button clicked", .{} })
                    .background(.hex("#ef4444"))
                    .children({
                    Text("Delete")
                        .fontFamily("Montserrat")
                        .font(14, 500, .white).end();
                });
            });

            // With Icon
            Text("With Icon")
                .font(14, 500, Theme.text_muted)
                .fontFamily("IBM Plex Mono,monospace")
                .end();
            Card().children({
                Button(std.log.info, .{ "Button with icon clicked", .{} })
                    .background(.palette(.tint))
                    .children({
                    Icon(.envelope)
                        .font(14, 500, .palette(.background))
                        .end();
                    Text("Login with Email")
                        .fontFamily("Montserrat")
                        .font(14, 500, .palette(.background)).end();
                });
            });

            // Icon Only
            Text("Icon")
                .font(14, 500, Theme.text_muted)
                .fontFamily("IBM Plex Mono,monospace")
                .end();
            Card().children({
                Button(std.log.info, .{ "Icon button clicked", .{} })
                    // An icon alone needs a name for screen readers.
                    .ariaLabel("Next")
                    .background(.transparent)
                    .border(.round(.palette(.border_color_light), .all(8)))
                    .children({
                    Icon(.chevron_right)
                        .font(16, 500, .palette(.text_color))
                        .end();
                });
            });

            // Loading
            Text("Loading")
                .font(14, 500, Theme.text_muted)
                .fontFamily("IBM Plex Mono,monospace")
                .end();
            Card().children({
                // While it waits, it does nothing and says so.
                Button(waiting, .{})
                    .a11y(Vapor.Accessibility.init().setDisabled(true).setBusy(true))
                    .cursor(.default)
                    .background(.palette(.tint))
                    .children({
                    Icon(.arrow_clockwise)
                        .font(14, 500, .palette(.background))
                        .end();
                    Text("Please wait")
                        .fontFamily("Montserrat")
                        .font(14, 500, .palette(.background)).end();
                });
            });

            // Installation Section
            section_title("Installation");
            section_description("Install the button component from your command line.");

            code_snippet("vapor add button");

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
