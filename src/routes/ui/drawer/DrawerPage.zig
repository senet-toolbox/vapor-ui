const std = @import("std");
const Vapor = @import("vapor");
const Text = Vapor.Text;
const TextFmt = Vapor.TextFmt;
const Row = Vapor.Row;
const Stack = Vapor.Stack;
const Opaque = @import("opaque-ui");
const Drawer = Opaque.Sheet;
const Vaporize = @import("vaporize");
const SyntaxHighlighter = Vaporize.SyntaxHighlighter;
const Icon = Vapor.Icon;
const Button = Opaque.Button;
const CodeBox = @import("../CodeBox.zig").CodeBox;

// ============================================================================
// THEME & MOCK DATA
// ============================================================================

const Theme = struct {
    const text = Vapor.Types.Color.palette(.text_color);
    const text_secondary = Vapor.Types.Color.hex("#a1a1aa");
    const text_muted = Vapor.Types.Color.hex("#71717a");
    const border = Vapor.Types.Color.palette(.border_color_light);
    const bg_elevated = Vapor.Types.Color.palette(.background);
    const warning = Vapor.Types.Color.hex("#ef4444");
    const success = Vapor.Types.Color.hex("#22c55e");
};

const Status = enum {
    success,
    pending,
    fn label(self: Status) []const u8 {
        return @tagName(self);
    }
    fn color(self: Status) Vapor.Types.Color {
        return if (self == .success) Theme.success else Theme.text_muted;
    }
};

const Transaction = struct {
    id: u32,
    amount: u32,
    customer: []const u8,
    email: []const u8,
    date: []const u8,
    method: []const u8,
    status: Status,
};

var selected_transaction: ?Transaction = .{
    .id = 8842,
    .amount = 125,
    .customer = "John Carmack",
    .email = "js@quakeisthebest.org",
    .date = "Jan 15, 2026",
    .method = "Visa •••• 4242",
    .status = .success,
};

// ============================================================================
// DRAWER INSTANCES
// ============================================================================

var bottom_drawer: Drawer = undefined;
var right_drawer: Drawer = undefined;
var left_drawer: Drawer = undefined;
var top_drawer: Drawer = undefined;

var hl_basic: SyntaxHighlighter = undefined;

pub fn init() void {
    const allocator = Vapor.arena(.persist);

    hl_basic = SyntaxHighlighter.init(allocator);
    hl_basic.parse(@embedFile("examples/BasicDrawer.zig")) catch unreachable;
    hl_basic.show_toolbar = true;

    bottom_drawer = .init(.bottom);
    bottom_drawer.content = renderBasicContent;

    right_drawer = .init(.right);
    right_drawer.content = renderDetailSheetContent;

    left_drawer = .init(.left);
    left_drawer.content = renderBasicContent;

    top_drawer = .init(.top);
    top_drawer.content = renderBasicContent;

    Vapor.Page(.{ .src = @src() }, render, null);
}

// ============================================================================
// CONTENT RENDERERS
// ============================================================================

fn renderBasicContent(_: *Drawer) void {
    Stack()
        .width(.percent(100))
        .padding(.all(24))
        .children({
        Text("Simple Drawer Content")
            .font(18, 600, Theme.text)
            .end();
        Text("This is a basic placeholder for drawer content.")
            .font(14, 400, Theme.text_muted)
            .end();
    });
}

fn renderDetailSheetContent(_: *Drawer) void {
    if (selected_transaction) |txn| {
        Stack()
            .width(.percent(100))
            .height(.percent(100))
            .padding(.all(24))
            .spacing(24)
            .direction(.column)
            .children({
            // Header
            Row()
                .width(.percent(100))
                .layout(.x_between_center)
                .children({
                Text("Transaction Details")
                    .font(20, 700, Theme.text)
                    .fontFamily("IBM Plex Mono,monospace")
                    .end();
                Button(Drawer.close, .{&right_drawer})
                    .width(.px(36))
                    .height(.px(36))
                    .layout(.center)
                    .pointer()
                    .children({
                    Icon(.x_lg).font(16, 400, Theme.text_secondary).end();
                });
            });

            // Amount Section
            Row()
                .width(.percent(100))
                .padding(.all(20))
                .direction(.column)
                .spacing(8)
                .layout(.center)
                .background(.transparentizeHex(Theme.text, 0.05))
                .border(.round(Theme.border, .all(12)))
                .children({
                Text("Total Amount").font(12, 500, Theme.text_muted).end();
                TextFmt("${d}.00", .{txn.amount})
                    .font(36, 700, Theme.text)
                    .fontFamily("IBM Plex Mono,monospace")
                    .end();
                Text(txn.status.label())
                    .font(12, 600, txn.status.color())
                    .end();
            });

            // Detail Rows
            Stack().width(.percent(100)).spacing(16).children({
                renderDetailRow("Customer", txn.customer);
                renderDetailRow("Email", txn.email);
                renderDetailRow("Date", txn.date);
                renderDetailRow("Method", txn.method);
            });

            // Actions
            Row()
                .width(.percent(100))
                .layout(.left_center)
                .spacing(12)
                // .margin(.t(.auto)) // Push to bottom
                .children({
                Button(Drawer.close, .{&right_drawer})
                    .padding(.xy(16, 10))
                    .background(.hex("#ef4444"))
                    .border(.round(.hex("#ef4444"), .all(8)))
                    .children({
                    Text("Refund").font(14, 600, .white).end();
                });
            });
        });
    }
}

fn renderDetailRow(label: []const u8, value: []const u8) void {
    Row()
        .width(.percent(100))
        .layout(.x_between_center)
        .children({
        Text(label).font(14, 400, Theme.text_muted).end();
        Text(value).font(14, 500, Theme.text).end();
    });
}

// ============================================================================
// UI HELPERS
// ============================================================================

fn sectionDesc(desc: []const u8) void {
    Text(desc).font(14, 400, Theme.text_muted).fontFamily("IBM Plex Mono,monospace").margin(.b(16)).end();
}

fn exampleLabel(label: []const u8) void {
    Text(label).font(14, 500, Theme.text_muted).fontFamily("IBM Plex Mono,monospace").margin(.t(24)).end();
}

fn CodeBlock(highlighter: *SyntaxHighlighter) void {
    Row()
        .scroll(.scroll_y())
        .size(.hw(.mobile_desktop(.fit, .px(400)), .mobile_desktop_percent(100, 100)))
        .border(.simple(.palette(.text_color)))
        .children({
        highlighter.render() catch unreachable;
    });
}

fn PreviewCard() Vapor.Builder(.pure) {
    return Stack()
        .background(.transparentizeHex(.palette(.background), 0.5))
        .border(.round(.palette(.border_color_light), .all(12)))
        .width(.percent(100))
        .padding(.all(24))
        .direction(.column)
        .layout(.center)
        .spacing(16);
}

// ============================================================================
// MAIN PAGE RENDER
// ============================================================================

fn render() void {
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
            Text("drawer-ui ⇒").style(&.{
                .visual = .font(12, 500, .hex("#6f6f6f")),
                .font_family = "IBM Plex Mono,monospace",
            }).end();
            Text("drawer-ui")
                .font(72, 700, .palette(.text_color))
                .end();
            Text("Slide-out surfaces for secondary content and complex workflows.")
                .font(16, 300, .palette(.text_color))
                .end();
        });

        Stack()
            .width(.percent(50))
            .height(.percent(100))
            .spacing(12)
            .padding(.bottom(120))
            .children({

            // Basic
            exampleLabel("Open Bottom Drawer");
            sectionDesc("Open a drawer from any Button or Click event.");
            PreviewCard().children({
                posBtn("Open Bottom", &bottom_drawer);
            });
            CodeBox(&hl_basic, "BasicDrawer");

            // EXAMPLE 1: BASIC

            // EXAMPLE 2: Open Drawer Right
            exampleLabel("Open Right Drawer");
            sectionDesc("Open a drawer from any Button or Click event.");
            PreviewCard().children({
                posBtn("Open Right (Details)", &right_drawer);
            });

            // EXAMPLE 3: Open Drawer Left
            exampleLabel("Open Left Drawer");
            sectionDesc("Open a drawer from any Button or Click event.");
            PreviewCard().children({
                posBtn("Open Left", &left_drawer);
            });

            // EXAMPLE 4: Open Drawer Top
            exampleLabel("Open Top Drawer");
            sectionDesc("Open a drawer from any Button or Click event.");
            PreviewCard().children({
                posBtn("Open Top", &top_drawer);
            });
        });
    });

    bottom_drawer.render();
    right_drawer.render();
    left_drawer.render();
    top_drawer.render();
}

fn posBtn(label: []const u8, drawer: *Drawer) void {
    Button(Drawer.open, .{drawer})
        .padding(.xy(16, 10))
        .background(.palette(.tint))
        .border(.round(.palette(.tint), .all(8)))
        .children({
        Text(label).font(14, 500, .palette(.background)).end();
    });
}

