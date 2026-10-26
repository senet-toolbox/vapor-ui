// page.zig
const Vapor = @import("vapor");
const Hero = @import("../../../components/Hero.zig").Hero;
const Text = Vapor.Text;
const Row = Vapor.Row;
const Stack = Vapor.Stack;
const Pricing = @import("../../../components/templates/Payment.zig");

// ============================================================================
// THEME
// ============================================================================

const Theme = struct {
    const text_muted = Vapor.Types.Color.hex("#71717a");
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
        Hero("payment-ui", "Pricing and plan selection templates to drop into your product.");

        // Content
        Stack()
            .width(.percent(70))
            .responsive(.mobile, .{ .size = .w(.percent(92)) })
            .height(.percent(100))
            .spacing(12)
            .padding(.{ .bottom = 120 })
            .children({
            exampleLabel("Pricing Cards");
            sectionDesc("Three plans side by side with a highlighted tier, feature lists and a hover lift.");
            Pricing.render();
        });
    });
}
