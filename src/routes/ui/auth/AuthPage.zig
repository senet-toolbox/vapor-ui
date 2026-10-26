// page.zig
const Vapor = @import("vapor");
const Text = Vapor.Text;
const Row = Vapor.Row;
const Stack = Vapor.Stack;
const Login = @import("../../../components/templates/Login.zig");

// ============================================================================
// THEME
// ============================================================================

const Theme = struct {
    const text_muted = Vapor.Types.Color.hex("#71717a");
};

var login: Login = .{
    .login_title = "Login into Acorn",
    .login_subtitle = "Login into your Acorn account.",
    .create_account_title = "Create Acorn Account",
    .create_account_subtitle = "Create an Acorn account to login",
};

pub fn init() void {
    Vapor.Page(.{ .src = @src() }, render, null);
}

// ============================================================================
// UI HELPERS
// ============================================================================

fn sectionDesc(desc: []const u8) void {
    Text(desc)
        .font(14, 400, Theme.text_muted)
        .fontFamily("IBM Plex Mono,monospace")
        .margin(.{ .bottom = 16 })
        .end();
}

fn exampleLabel(label: []const u8) void {
    Text(label)
        .font(14, 500, Theme.text_muted)
        .fontFamily("IBM Plex Mono,monospace")
        .margin(.{ .top = 24 })
        .end();
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
            Text("auth-ui ⇒").style(&.{
                .visual = .font(12, 500, .hex("#6f6f6f")),
                .font_family = "IBM Plex Mono,monospace",
            }).end();
            Text("auth-ui")
                .font(72, 700, .palette(.text_color))
                .end();
            Text("Login and sign-up forms with validation and OAuth sign-in, ready to wire to your backend.")
                .font(16, 300, .palette(.text_color))
                .end();
        });

        // Content
        Stack()
            .width(.percent(50))
            .height(.percent(100))
            .spacing(12)
            .padding(.{ .bottom = 120 })
            .children({
            exampleLabel("Login & Create Account");
            sectionDesc("Two tabs share one card: login, and account creation with validated email and password. Google, GitHub and Apple buttons appear for the OAuth clients you configure in KeyStone.");
            login.render();
        });
    });
}
