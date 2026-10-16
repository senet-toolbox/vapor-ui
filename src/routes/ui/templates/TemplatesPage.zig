const Templates = @import("../../../components/templates/Dashboard.zig");
const Kanban = @import("../../../components/templates/Kanban_1.zig").Kanban;
const Chat = @import("../../../components/templates/Chat.zig");
const ApiClient = @import("../../../components/templates/ApiClient.zig");
const std = @import("std");
const Vapor = @import("vapor");
const Text = Vapor.Text;
const Row = Vapor.Row;
const Stack = Vapor.Stack;
const Opaque = @import("opaque-ui");
const Vaporize = @import("vaporize");
const SyntaxHighlighter = Vaporize.SyntaxHighlighter;
const Ecommerce = @import("../../../components/templates/Ecommerce.zig");

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

var text: []const u8 = "";
var email: []const u8 = "";
var password: []const u8 = "";
var phonenumber: []const u8 = "";
var cardnumber: []const u8 = "";

// ============================================================================
// INIT
// ============================================================================

var board: Kanban = undefined;
pub fn init() void {
    board.init();
    Vapor.Page(.{ .src = @src() }, render, null);
}

// ============================================================================
// UI COMPONENTS
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
        .margin(.t(128))
        .font(14, 500, Theme.text_muted)
        .fontFamily("IBM Plex Mono,monospace")
        .end();
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
// TEXT FIELD INSTANCES
// ============================================================================

pub inline fn Code() fn (void) void {
    const elem_decl = Vapor.ElementDecl{
        .state_type = .static,
        .elem_type = .Code,
    };
    _ = Vapor.LifeCycle.open(elem_decl);
    Vapor.LifeCycle.configure(elem_decl);
    return Vapor.LifeCycle.close;
}

fn render() void {
    Vapor.Stack()
        .width(.percent(100))
        .height(.percent(100))
        .layout(.top_center)
        .children({
        // Hero
        Vapor.Stack()
            .layout(.center)
            .height(.px(512))
            .width(.percent(100))
            .children({
            Text("templates-ui ⇒").style(&.{
                .visual = .font(12, 500, .hex("#6f6f6f")),
                .font_family = "IBM Plex Mono,monospace",
            }).end();
            Text("templates-ui")
                .font(72, 700, .palette(.text_color))
                .end();
            Text("A collection of ready-to-use templates components built on top of Vapor, copy and paste into your apps.")
                .font(16, 300, .palette(.text_color))
                .end();
        });

        // Content
        Stack()
            .width(.percent(90))
            .height(.percent(100))
            .spacing(12)
            .padding(.bottom(120))
            .children({
            exampleLabel("Template Ecommerce");
            sectionDesc("A simple ecommerce template with cart, login, and checkout.");
            Ecommerce.renderHome();

            // ============================================================
            // BASIC
            // ============================================================
            exampleLabel("DND Kanban");
            sectionDesc("Drag and Drop Kanban Board with Sortable Collections filtering, search, and creation modals.");
            board.render();
            // CodeBlock(&hl_basic);

            // ============================================================
            // BASIC
            // ============================================================
            exampleLabel("Fullstack Dashboard");
            sectionDesc("Dashboard with charts, tables, filtering, search, and sidebar.");
            Templates.render();

            exampleLabel("Chat App");
            sectionDesc("Chat App with working websockets, chat history, and typing indicators.");
            Chat.render();

            exampleLabel("API Client");
            sectionDesc("A single-file REST API client component with: Method selector (GET/POST/PUT/DELETE/PATCH), URL input field, Request body editor (JSON) with syntax highlighting, and headers editor (key/value pairs).");
            ApiClient.render();
        });
    });
}
