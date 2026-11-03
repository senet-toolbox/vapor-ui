const std = @import("std");
const Vapor = @import("vapor");
const Hero = @import("../../../../components/Hero.zig").Hero;
const CodeBox = @import("../CodeBox.zig").CodeBox;
const Docs = @import("../Docs.zig");
const Text = Vapor.Text;
const Row = Vapor.Row;
const Stack = Vapor.Stack;
const Opaque = @import("opaque-ui");
const Toast = Opaque.Toast;
const Vaporize = @import("vaporize");
const SyntaxHighlighter = Vaporize.SyntaxHighlighter;
const Icon = Vapor.Icon;
const Button = Opaque.Button;
const Item = Opaque.Item;

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
var hl_positions: SyntaxHighlighter = undefined;
var hl_types: SyntaxHighlighter = undefined;
var hl_style: SyntaxHighlighter = undefined;

// ============================================================================
// CURRENT POSITION STATE
// ============================================================================

var prev_position: Toast.StackPosition = .top_right;

pub fn init() void {
    hl_api = Docs.highlighter(
        \\const Toast = @import("opaque-ui").Toast;
        \\
        \\// Shows a toast of each type.
        \\pub fn success(options: Options) void
        \\pub fn err(options: Options) void
        \\pub fn warning(options: Options) void
        \\pub fn info(options: Options) void
        \\
        \\// Draws the stack, once, in your layout.
        \\pub fn renderStack() void
        \\pub fn renderStackAt(position: StackPosition) void
        \\
        \\Toast.success(.{ .title = "Saved", .description = "Your changes are live." });
    );
    hl_style = SyntaxHighlighter.init(Vapor.arena(.persist));
    hl_style.show_toolbar = true;
    hl_style.parse(@embedFile("examples/ToastStyle.zig")) catch unreachable;

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
        .padding(.all(24))
        .direction(.column)
        .layout(.center)
        .spacing(16);
}

fn ButtonRow() Vapor.Builder(.pure) {
    return Stack()
        .direction(.row)
        .layout(.center)
        .spacing(12)
        .wrap(.wrap);
}

fn render() void {
    Row()
        .width(.percent(100))
        .layout(.top_center)
        .direction(.column)
        .children({
        // Hero
        Hero("toast-ui", "Non-intrusive notifications that stack elegantly in any corner of the screen.");

        Stack()
            .width(.percent(50))
            .responsive(.mobile, .{ .size = .w(.percent(92)) })
            .height(.percent(100))
            .spacing(12)
            .padding(.{ .bottom = 120 })
            .children({
            sectionTitle("Toast Usage");
            sectionDesc("⚠️ Only call renderStack() once in your app, or layouts, Toasts are a global component.");

            // ================================================================
            // SECTION: Toast Types
            // ================================================================
            sectionTitle("Toast Types");
            sectionDesc("Four semantic toast types for different notification contexts.");

            // Success Toast
            exampleLabel("Success");
            sectionDesc("Confirm successful operations like saves, uploads, or completed actions.");
            PreviewCard().children({
                ButtonRow().children({
                    toastBtn("Save Successful", .success, "Document Saved", "Your changes have been saved successfully.");
                    toastBtn("Upload Complete", .success, "Upload Complete", "profile_photo.jpg has been uploaded.");
                    toastBtn("Payment Processed", .success, "Payment Received", "Transaction #4521 completed.");
                });
            });

            // Error Toast
            exampleLabel("Error");
            sectionDesc("Alert users to failures, validation errors, or critical issues requiring attention.");
            PreviewCard().children({
                ButtonRow().children({
                    toastBtn("Connection Failed", .err, "Connection Error", "Unable to reach the server. Please try again.");
                    toastBtn("Validation Error", .err, "Invalid Input", "Email address format is incorrect.");
                    toastBtn("Delete Failed", .err, "Delete Failed", "Insufficient permissions to remove this file.");
                });
            });

            // Warning Toast
            exampleLabel("Warning");
            sectionDesc("Caution users about potential issues or actions that may have consequences.");
            PreviewCard().children({
                ButtonRow().children({
                    toastBtn("Low Storage", .warning, "Storage Warning", "You have less than 100MB of storage remaining.");
                    toastBtn("Session Expiring", .warning, "Session Timeout", "Your session will expire in 5 minutes.");
                    toastBtn("Unsaved Changes", .warning, "Unsaved Work", "You have unsaved changes that may be lost.");
                });
            });

            // Info Toast
            exampleLabel("Info");
            sectionDesc("Provide helpful information, tips, or neutral status updates.");
            PreviewCard().children({
                ButtonRow().children({
                    toastBtn("New Features", .info, "What's New", "Check out the latest features in v2.0.");
                    toastBtn("Sync Started", .info, "Syncing", "Your files are being synchronized.");
                    toastBtn("Tip", .info, "Pro Tip", "Use keyboard shortcuts for faster navigation.");
                });
            });

            // ================================================================
            // SECTION: Stack Positions
            // ================================================================
            sectionTitle("Stack Positions");
            sectionDesc("Position your toast stack in any corner of the viewport.");

            // Top Right
            exampleLabel("Top Right (Default)");
            sectionDesc("The most common position for notifications. Toasts stack downward.");
            PreviewCard().children({
                ButtonRow().children({
                    positionBtn("Show Top Right", .top_right, .info, "Top Right", "Toasts appear in the top right corner.");
                });
            });

            // Top Left
            exampleLabel("Top Left");
            sectionDesc("Alternative top position. Ideal for RTL layouts or left-aligned interfaces.");
            PreviewCard().children({
                ButtonRow().children({
                    positionBtn("Show Top Left", .top_left, .success, "Top Left", "Toasts stack from the top left.");
                });
            });

            // Bottom Right
            exampleLabel("Bottom Right");
            sectionDesc("Toasts emerge from the bottom and stack upward. Great for chat-style apps.");
            PreviewCard().children({
                ButtonRow().children({
                    positionBtn("Show Bottom Right", .bottom_right, .warning, "Bottom Right", "Toasts rise from the bottom right.");
                });
            });

            // Bottom Left
            exampleLabel("Bottom Left");
            sectionDesc("Bottom left positioning with upward stacking. Pairs well with left-side navigation.");
            PreviewCard().children({
                ButtonRow().children({
                    positionBtn("Show Bottom Left", .bottom_left, .err, "Bottom Left", "Toasts stack upward from bottom left.");
                });
            });

            // ================================================================
            // SECTION: Stacking Behavior
            // ================================================================
            sectionTitle("Stacking Behavior");
            sectionDesc("Multiple toasts stack with smooth animations. Hover to expand and pause auto-dismiss.");

            PreviewCard().children({
                ButtonRow().children({
                    multiToastBtn("Trigger 3 Toasts");
                });
            });

            // ================================================================
            // SECTION: Styling
            // ================================================================
            sectionTitle("Styling");
            sectionDesc("Toasts follow your theme, light or dark. Change every toast, or one type, by setting these once.");
            CodeBox(&hl_style, "ToastStyle");

            Docs.sectionTitle("API Reference");

            Docs.exampleLabel("Toast");
            Docs.sectionDesc("Call one of these from anywhere; the stack in your layout shows it.");
            CodeBox(&hl_api, "Toast");

            Docs.exampleLabel("Options");
            Docs.ApiBox("Options", &options);

            Docs.exampleLabel("Settings");
            Docs.sectionDesc("Set once, before showing a toast. See Styling above.");
            Docs.ApiBox("Toast", &settings);

            Docs.exampleLabel("Behaviour");
            Docs.sectionDesc("What toasts do for you.");
            Docs.ApiBox("Behaviour", &behaviours);
        });
    });

    // The layout renders the one toast stack, at Toast.stack_position.
}

// ============================================================================
// BUTTON HELPERS
// ============================================================================

const ToastArg = struct {
    toast_type: Toast.ToastType,
    title: []const u8,
    description: []const u8,
};

fn toastBtn(label: []const u8, toast_type: Toast.ToastType, title: []const u8, description: []const u8) void {
    const ToastFn = struct {
        fn trigger(opts: ToastArg) void {
            if (Toast.stack_position != prev_position) {
                Toast.clearToasts();
                prev_position = Toast.stack_position;
            }
            switch (opts.toast_type) {
                .success => Toast.success(.{ .title = opts.title, .description = opts.description }),
                .err => Toast.err(.{ .title = opts.title, .description = opts.description }),
                .warning => Toast.warning(.{ .title = opts.title, .description = opts.description }),
                .info => Toast.info(.{ .title = opts.title, .description = opts.description }),
            }
        }
    };

    const bg_color = switch (toast_type) {
        .success => Vapor.Types.Color.hex("#00FF90"),
        .err => Vapor.Types.Color.hex("#DC0000"),
        .warning => Vapor.Types.Color.hex("#FF8000"),
        .info => Vapor.Types.Color.hex("#1E00FF"),
    };

    Button(ToastFn.trigger, .{ToastArg{ .toast_type = toast_type, .title = title, .description = description }})
        .padding(.xy(16, 10))
        .background(bg_color)
        .border(.round(bg_color, .all(12)))
        .children({
        Text(label).font(14, 500, .white)
            .fontFamily("Montserrat")
            .end();
    });
}

const PositionArg = struct {
    position: Toast.StackPosition,
    toast_type: Toast.ToastType,
    title: []const u8,
    description: []const u8,
};

fn positionBtn(label: []const u8, position: Toast.StackPosition, toast_type: Toast.ToastType, title: []const u8, description: []const u8) void {
    const PositionFn = struct {
        fn trigger(opts: PositionArg) void {
            Toast.stack_position = opts.position;
            if (Toast.stack_position != prev_position) {
                Toast.clearToasts();
                prev_position = Toast.stack_position;
            }
            switch (opts.toast_type) {
                .success => Toast.success(.{ .title = opts.title, .description = opts.description }),
                .err => Toast.err(.{ .title = opts.title, .description = opts.description }),
                .warning => Toast.warning(.{ .title = opts.title, .description = opts.description }),
                .info => Toast.info(.{ .title = opts.title, .description = opts.description }),
            }
        }
    };

    Button(PositionFn.trigger, .{PositionArg{ .position = position, .toast_type = toast_type, .title = title, .description = description }})
        .padding(.xy(16, 10))
        .background(.palette(.tint))
        .border(.round(.palette(.tint), .all(12)))
        .children({
        Text(label).font(14, 500, .white)
            .fontFamily("Montserrat")
            .end();
    });
}

fn positionSelectBtn(label: []const u8, position: Toast.StackPosition) void {
    const SelectFn = struct {
        fn select(pos: Toast.StackPosition) void {
            Toast.stack_position = pos;
        }
    };

    const is_active = Toast.stack_position == position;
    const bg = if (is_active) Vapor.Types.Color.palette(.tint) else Vapor.Types.Color.transparent;
    const text_color = if (is_active) Vapor.Types.Color.palette(.background) else Theme.text;
    const border_color = if (is_active) Vapor.Types.Color.palette(.tint) else Theme.border;

    Button(SelectFn.select, .{position})
        .padding(.xy(12, 8))
        .background(bg)
        .border(.round(border_color, .all(6)))
        .children({
        Text(label).font(12, 500, text_color).end();
    });
}

fn demoBtn(label: []const u8, toast_type: Toast.ToastType, title: []const u8, description: []const u8) void {
    const DemoFn = struct {
        fn trigger(opts: struct { toast_type: Toast.ToastType, title: []const u8, description: []const u8 }) void {
            switch (opts.toast_type) {
                .success => Toast.success(.{ .title = opts.title, .description = opts.description }),
                .err => Toast.err(.{ .title = opts.title, .description = opts.description }),
                .warning => Toast.warning(.{ .title = opts.title, .description = opts.description }),
                .info => Toast.info(.{ .title = opts.title, .description = opts.description }),
            }
        }
    };

    const bg_color = switch (toast_type) {
        .success => Vapor.Types.Color.hex("#22c55e"),
        .err => Vapor.Types.Color.hex("#ef4444"),
        .warning => Vapor.Types.Color.hex("#f59e0b"),
        .info => Vapor.Types.Color.hex("#3b82f6"),
    };

    Button(DemoFn.trigger, .{.{ .toast_type = toast_type, .title = title, .description = description }})
        .padding(.xy(14, 8))
        .background(.{ .color = bg_color })
        .border(.round(bg_color, .all(6)))
        .children({
        Text(label).font(13, 500, .white).end();
    });
}

fn multiToastBtn(label: []const u8) void {
    const MultiFn = struct {
        fn trigger(_: void) void {
            Toast.success(.{ .title = "First Toast", .description = "This one appears first." });
            Toast.info(.{ .title = "Second Toast", .description = "Stacking on top of the first." });
            Toast.warning(.{ .title = "Third Toast", .description = "Watch how they stack and scale." });
        }
    };

    Button(MultiFn.trigger, .{{}})
        .padding(.xy(16, 10))
        .background(.palette(.tint))
        .border(.round(.palette(.tint), .all(8)))
        .children({
        Text(label).font(14, 500, .palette(.background)).end();
    });
}

var hl_api: SyntaxHighlighter = undefined;

const options = [_]Docs.Field{
    .{ .name = "title", .type = "[]const u8", .desc = "The bold first line; up to 128 bytes." },
    .{ .name = "description", .type = "[]const u8", .desc = "The line under it; up to 256 bytes, cut short with an ellipsis if it's too long to fit." },
};

const settings = [_]Docs.Field{
    .{ .name = "stack_position", .type = "StackPosition", .default = ".top_right", .desc = "Which corner the stack sits in: .top_right, .top_left, .bottom_right or .bottom_left." },
    .{ .name = "stack_margin", .type = "f32", .default = "24", .desc = "Pixels between the stack and the edges of the window." },
    .{ .name = "background", .type = "Color", .default = ".palette(.background)", .desc = "Every toast's background." },
    .{ .name = "text_color", .type = "Color", .default = ".palette(.text)", .desc = "Every toast's text." },
    .{ .name = "border_color", .type = "Color", .default = ".palette(.border_color_light)", .desc = "Every toast's border." },
    .{ .name = "border_radius", .type = "BorderRadius", .default = ".all(16)", .desc = "Every toast's corners." },
    .{ .name = "success_background", .type = "?Color", .default = "null", .desc = "One type's background; likewise err_, warning_ and info_. Unset, it takes background." },
    .{ .name = "success_text_color", .type = "?Color", .default = "null", .desc = "One type's text; likewise for the other types." },
    .{ .name = "success_icon_color", .type = "Color", .default = ".hex(\"#22c55e\")", .desc = "One type's icon, which tells the types apart; likewise for the others." },
    .{ .name = "success_blur", .type = "u8", .default = "0", .desc = "Blurs the page behind a see-through toast of that type; likewise for the others." },
};

const behaviours = [_]Docs.Field{
    .{ .name = "Stacking", .desc = "Newest in front. Only the front toast shows its text until the stack is hovered, when it spreads out." },
    .{ .name = "Closing", .desc = "On its own after 3 seconds, or by its close button. Hovering the stack holds them." },
    .{ .name = "Screen readers", .desc = "An error is an alert, read out at once; the others are status messages, read out when the reader is free. The close button is named Dismiss notification." },
    .{ .name = "Animation", .desc = "Slides in from its side of the window and back out." },
};
