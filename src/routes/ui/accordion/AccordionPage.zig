// page.zig
const std = @import("std");
const Vapor = @import("vapor");
const Text = Vapor.Text;
const Row = Vapor.Row;
const Stack = Vapor.Stack;
const Opaque = @import("opaque-ui");
const Accordion = Opaque.Accordion;
const Vaporize = @import("vaporize");
const SyntaxHighlighter = Vaporize.SyntaxHighlighter;
const Icon = Vapor.Icon;
const Button = Opaque.Button;
const CodeBox = @import("../CodeBox.zig").CodeBox;

// ============================================================================
// THEME
// ============================================================================

const Theme = struct {
    const text = Vapor.Types.Color.palette(.text_color);
    const text_muted = Vapor.Types.Color.hex("#71717a");
    const border = Vapor.Types.Color.palette(.border_color_light);
    const code_bg = Vapor.Types.Color.hex("#1a1a1a");
    const warning = Vapor.Types.Color.hex("#F5590B");
};

// ============================================================================
// SYNTAX HIGHLIGHTERS
// ============================================================================

var hl_basic: SyntaxHighlighter = undefined;
var hl_custom_render: SyntaxHighlighter = undefined;
var hl_api: SyntaxHighlighter = undefined;

// ============================================================================
// ACCORDION INSTANCES
// ============================================================================

var basic_accordion: Accordion = undefined;
var custom_accordion: Accordion = undefined;

// ============================================================================
// INIT
// ============================================================================

var basic_items = [_]Accordion.AccordionItem{
    .{
        .title = "Product Information",
        .description = "Our flagship product combines cutting-edge technology with sleek design.",
        .trigger = DefaultTrigger,
        .content = DefaultContent,
    },
    .{
        .title = "Return Policy",
        .description = "We stand behind our products with a comprehensive 30-day return policy.",
        .trigger = DefaultTrigger,
        .content = DefaultContent,
    },
};

var custom_items = [_]Accordion.AccordionItem{
    .{
        .title = "Security Settings",
        .description = "Manage your two-factor authentication and password recovery options.",
        .trigger = CustomTrigger,
        .content = CustomContentAccount,
    },
    .{
        .title = "Notification Preferences",
        .description = "Choose which alerts you want to receive via email and push notifications.",
        .trigger = CustomTrigger,
        .content = CustomContentEmail,
    },
};

pub fn init() void {
    const allocator = Vapor.arena(.persist);

    // Initialize syntax highlighters
    hl_basic = SyntaxHighlighter.init(allocator);
    hl_basic.show_toolbar = true;
    hl_basic.parse(@embedFile("examples/BasicAccordion.zig")) catch unreachable;

    hl_custom_render = SyntaxHighlighter.init(allocator);
    hl_custom_render.show_toolbar = true;
    hl_custom_render.parse(@embedFile("examples/CustomAccordion.zig")) catch unreachable;

    // Initialize basic accordion
    basic_accordion = .init(&basic_items);

    // Initialize custom accordion with specific components
    custom_accordion = .init(&custom_items);

    Vapor.Page(.{ .src = @src() }, render, null);
}

// ============================================================================
// COMPONENT RENDERS
// ============================================================================

fn DefaultTrigger(item: *Accordion.AccordionItem) void {
    Text(item.title)
        .fontFamily("Montserrat")
        .font(16, 500, Theme.text)
        .end();
}

fn DefaultContent(item: *Accordion.AccordionItem) void {
    Text(item.description)
        .font(14, 300, Theme.text_muted)
        .end();
}

fn CustomTrigger(item: *Accordion.AccordionItem) void {
    Row()
        .direction(.row)
        .spacing(12)
        .layout(.left_center)
        .children({
        // Dynamic Icon based on title
        Icon(.sliders2_vertical)
            .font(18, 300, .palette(.text_color))
            .end();

        Text(item.title)
            .fontFamily("Montserrat")
            .font(16, 600, .palette(.text_color))
            .end();
    });
}

fn CustomContentAccount(item: *Accordion.AccordionItem) void {
    Stack()
        .width(.percent(100))
        .spacing(16)
        .children({
        Text("Configure your account settings.")
            .font(16, 300, .palette(.text_color))
            .end();
        Text(item.description)
            .font(16, 400, .palette(.text_color))
            .end();
        Button(Vapor.alert, .{ "{s}", .{"Opening Settings..."} })
            .padding(.xy(12, 8))
            .ariaLabel("Alert Opening Settings")
            .background(.palette(.tint))
            .children({
            Text("Open Account Settings")
                .font(14, 300, .palette(.background))
                .fontFamily("Montserrat")
                .end();
        });
    });
}

fn CustomContentEmail(item: *Accordion.AccordionItem) void {
    Stack()
        .width(.percent(100))
        .spacing(16)
        .children({
        Text("Configure your communication settings.")
            .font(16, 300, .palette(.text_color))
            .end();
        Text(item.description)
            .font(16, 400, .palette(.text_color))
            .end();
        Row()
            .width(.percent(100))
            .layout(.right_center)
            .spacing(16)
            .children({
            Button(Vapor.alert, .{ "{s}", .{"Opening Settings..."} })
                .padding(.xy(12, 8))
                .ariaLabel("Email Opening Settings")
                .background(.palette(.tint))
                .children({
                Text("Email Settings")
                    .font(14, 300, .palette(.background))
                    .fontFamily("Montserrat")
                    .end();
            });
            Button(Vapor.alert, .{ "{s}", .{"Opening Settings..."} })
                .padding(.xy(12, 8))
                .ariaLabel("Notification Opening Settings")
                .background(.palette(.text_color))
                .children({
                Text("Notification Settings")
                    .font(14, 300, .palette(.background))
                    .fontFamily("Montserrat")
                    .end();
            });
        });
    });
}

// ============================================================================
// UI HELPERS
// ============================================================================

fn sectionTitle(title: []const u8) void {
    Text(title)
        .font(24, 600, Theme.text)
        .fontFamily("IBM Plex Mono,monospace")
        .margin(.t(48))
        .end();
}

fn sectionDesc(desc: []const u8) void {
    Text(desc)
        .font(14, 400, Theme.text_muted)
        .fontFamily("IBM Plex Mono,monospace")
        .margin(.b(16))
        .end();
}

fn exampleLabel(label: []const u8) void {
    Text(label)
        .font(14, 500, Theme.text_muted)
        .fontFamily("IBM Plex Mono,monospace")
        .margin(.t(24))
        .end();
}

fn PreviewCard() Vapor.Builder(.pure) {
    return Stack()
        .background(.transparentizeHex(.palette(.background), 0.5))
        .border(.round(.palette(.border_color_light), .all(12)))
        .width(.percent(100))
        .padding(.all(24))
        .direction(.column)
        .spacing(16);
}

// ============================================================================
// MAIN RENDER
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
            Text("accordion-ui ⇒").style(&.{
                .visual = .font(12, 500, .hex("#6f6f6f")),
                .font_family = "IBM Plex Mono,monospace",
            }).end();
            Text("accordion-ui")
                .font(72, 700, .palette(.text_color))
                .end();
            Text("Highly customizable, accessible collapsible sections for organizing content.")
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
            exampleLabel("Basic Accordion");
            sectionDesc("Standard list of collapsible items using default typography.");
            PreviewCard().children({
                basic_accordion.render();
            });
            CodeBox(&hl_basic, "BasicAccordion");

            // Custom
            exampleLabel("Custom Rendering");
            sectionDesc("Using function pointers to override how headers and content panels are rendered.");
            PreviewCard().children({
                custom_accordion.render();
            });
            CodeBox(&hl_custom_render, "CustomAccordion");

            // API Reference
            sectionTitle("API Reference");

            exampleLabel("Item Structure");
            sectionDesc("Define the data and render functions for each panel.");
            Row()
                .width(.percent(100))
                .padding(.all(16))
                .background(Theme.code_bg)
                .border(.round(Theme.border, .all(8)))
                .children({
                Text(
                    \\.{
                    \\  .title = "Label",
                    \\  .description = "Extended text content...",
                    \\  .trigger = MyHeaderFn,
                    \\  .content = MyBodyFn
                    \\}
                )
                    .font(14, 400, .hex("#e4e4e7"))
                    .fontFamily("IBM Plex Mono,monospace")
                    .end();
            });

            exampleLabel("Initialization");
            sectionDesc("Pass a slice of AccordionItem structs to the init method.");
            Row()
                .width(.percent(100))
                .padding(.all(16))
                .background(Theme.code_bg)
                .border(.round(Theme.border, .all(8)))
                .children({
                Text("var accordion = Accordion.init(&.{ item1, item2 });")
                    .font(14, 400, .hex("#e4e4e7"))
                    .fontFamily("IBM Plex Mono,monospace")
                    .end();
            });

            exampleLabel("Render Functions");
            sectionDesc("Your custom functions receive a pointer to the current item.");
            Row()
                .width(.percent(100))
                .padding(.all(16))
                .background(Theme.code_bg)
                .border(.round(Theme.border, .all(8)))
                .children({
                Text("fn MyTrigger(item: *Accordion.AccordionItem) void { ... }")
                    .font(14, 400, .hex("#e4e4e7"))
                    .fontFamily("IBM Plex Mono,monospace")
                    .end();
            });
        });
    });
}
