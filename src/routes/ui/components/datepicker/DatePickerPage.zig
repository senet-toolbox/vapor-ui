const std = @import("std");
const Vapor = @import("vapor");
const Hero = @import("../../../../components/Hero.zig").Hero;
const Text = Vapor.Text;
const Row = Vapor.Row;
const Stack = Vapor.Stack;
const Opaque = @import("opaque-ui");
const Vaporize = @import("vaporize");
const SyntaxHighlighter = Vaporize.SyntaxHighlighter;
const Icon = Vapor.Icon;
const Button = Opaque.Button;
const DatePicker = Opaque.DatePicker;
// Rendered and shown as code: what you read is what runs.
const BasicDatePicker = @import("examples/BasicDatePicker.zig");
const EventDatePicker = @import("examples/EventDatePicker.zig");
const DateTime = Vapor.DateTime;
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
var hl_events: SyntaxHighlighter = undefined;

pub fn init() void {
    const allocator = Vapor.arena(.persist);

    // Highlighters
    hl_basic = SyntaxHighlighter.init(allocator);
    hl_basic.parse(@embedFile("examples/BasicDatePicker.zig")) catch unreachable;

    hl_events = SyntaxHighlighter.init(allocator);
    hl_events.parse(@embedFile("examples/EventDatePicker.zig")) catch unreachable;

    BasicDatePicker.init();
    EventDatePicker.init();

    Vapor.Page(.{ .src = @src() }, render, null);
}

// ============================================================================
// UI HELPERS
// ============================================================================

fn sectionDesc(desc: []const u8) void {
    Text(desc).font(14, 400, Theme.text_muted).fontFamily("IBM Plex Mono,monospace").margin(.{ .bottom = 8 }).end();
}

fn exampleLabel(label: []const u8) void {
    Text(label).font(14, 500, Theme.text_muted).fontFamily("IBM Plex Mono,monospace").margin(.{ .top = 8 }).end();
}

fn CodeBlock(highlighter: *SyntaxHighlighter) void {
    Row().scroll(.scrollY()).size(.hw(.fit, .percent(100))).border(.thin(Theme.border)).children({
        highlighter.render() catch unreachable;
    });
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

// ============================================================================
// RENDER
// ============================================================================

const items: []const []const u8 = &.{ ".on_date_select = fn(DateTime) void", ".on_year_select = fn(i32) void", ".on_month_select = fn(i32) void", ".on_next_month = fn() void", ".on_prev_month = fn() void" };
fn render() void {
    Row()
        .width(.percent(100))
        .layout(.top_center)
        .direction(.column)
        .children({

        // Hero
        Hero("datepicker-ui", "Accessible calendar components for precise date and time selection.");

        // Content
        Stack()
            .width(.percent(50))
            .responsive(.mobile, .{ .size = .w(.percent(92)) })
            .spacing(32)
            .padding(.{ .bottom = 120 })
            .children({

            // EXAMPLE 1: BASIC
            Row().direction(.column)
                .spacing(16)
                .children({
                exampleLabel("Basic DatePicker");
                sectionDesc("Default calendar view with no external dependencies or callbacks.");

                PreviewCard().children({
                    BasicDatePicker.render();
                });
                CodeBox(&hl_basic, "Basic DatePicker");
            });

            // EXAMPLE 2: EVENT DRIVEN
            Row().direction(.column)
                .spacing(16)
                .children({
                exampleLabel("Event-Driven Selection");
                sectionDesc("Hook into specific lifecycle events like year changes or month navigation.");

                PreviewCard().children({
                    EventDatePicker.render();
                });
                CodeBox(&hl_events, "Event-Driven Selection");
            });

            // API REFERENCE
            Text("API Reference").font(24, 600, Theme.text).fontFamily("IBM Plex Mono,monospace").margin(.{ .top = 48 }).end();

            exampleLabel("Event Callbacks");
            sectionDesc("DatePicker exposes optional function pointers for fine-grained control.");
            Vapor.List()
                .width(.percent(100))
                .padding(.xy(32, 0))
                .spacing(8)
                .listStyle(.upper_roman)
                .children({
                for (items[0..]) |item| {
                    Vapor.ListItem()
                        .children({
                        Text(item)
                            .fontSize(14)
                            .fontFamily("IBM Plex Mono,monospace")
                            .end();
                    });
                }
            });
        });
    });
}
