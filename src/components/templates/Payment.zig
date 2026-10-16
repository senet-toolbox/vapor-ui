const std = @import("std");
const Vapor = @import("vapor");
const Text = Vapor.Text;
const Row = Vapor.Row;
const Center = Vapor.Center;
const Stack = Vapor.Stack;
const Button = Vapor.Button;

const PricingCards = @This();

pub const Tier = enum {
    free,
    pro,
    premium,
};

pub const PricingPlan = struct {
    tier: Tier,
    name: []const u8,
    price: []const u8,
    period: []const u8,
    description: []const u8,
    features: []const []const u8,
    cta_text: []const u8,
    highlighted: bool = false,
};

var hovered_tier: ?Tier = null;

const plans = [_]PricingPlan{
    .{
        .tier = .free,
        .name = "Free",
        .price = "$0",
        .period = "/month",
        .description = "Perfect for testing and experimentation",
        .features = &.{
            "1 Project",
            "Full Senet Integration",
            "Community support",
            "Basic analytics",
            "Database Interface",
            "Postman like API",
            "API access (100 req/day)",
        },
        .cta_text = "Get Started",
        .highlighted = false,
    },
    .{
        .tier = .pro,
        .name = "Pro",
        .price = "$29",
        .period = "/month",
        .description = "For professionals and growing teams",
        .features = &.{
            "Unlimited projects",
            "Full Senet Integration",
            "100GB storage",
            "Priority support",
            "Advanced analytics",
            "Advanced Feature Set",
            "API access (unlimited)",
            "Team collaboration",
        },
        .cta_text = "Start Free Trial",
        .highlighted = true,
    },
    .{
        .tier = .premium,
        .name = "Premium",
        .price = "79",
        .period = "/month",
        .description = "For large organizations with custom needs",
        .features = &.{
            "Everything in Pro",
            "Unlimited storage",
            "24/7 dedicated support",
            "Audit logs",
            "On-premise option",
            "Deployment options",
            "Team collaboration",
            "Full Feature Set",
        },
        .cta_text = "Go Premium",
        .highlighted = false,
    },
};

fn onHoverTier(tier: Tier, _: *Vapor.Event) void {
    hovered_tier = tier;
}

fn onLeaveTier(_: *Vapor.Event) void {
    hovered_tier = null;
}

fn onSelectPlan(tier: Tier) void {
    std.log.info("Selected plan: {s}", .{@tagName(tier)});
}

fn PricingCard(plan: *const PricingPlan) void {
    // const is_hovered = hovered_tier != null and hovered_tier.? == plan.tier;
    const is_highlighted = plan.highlighted;

    const text_color: Vapor.Types.Color = if (is_highlighted) .palette(.background) else .palette(.text);

    Stack()
        .pos(.relative)
        .width(.expand)
        .height(.fit)
        .padding(.all(16))
        .spacing(12)
        .layout(.top_left)
        .background(if (is_highlighted)
            .transparentize(.palette(.tint), 0.6)
        else
            .transparentize(.palette(.background), 0.5))
        .border(.sharp(
            .all(1),
            if (is_highlighted) .palette(.tint) else .palette(.border_color_light),
        ))
        .duration(200)
        .hover(.{
            .transform = .translate(0, -8, .px),
            .border = .round(if (is_highlighted) .palette(.tint) else .palette(.border_color_light), .all(16)),
            .new_shadow = Vapor.Types.NewShadow.init()
                .inset(0, -2, .transparentize(.black, 0.3))
                .drop(0, 1, 3, .transparentize(.black, 0.1)),
        })
        .onEvent(.pointerenter, onHoverTier, .{plan.tier})
        .onLeave(onLeaveTier, .{})
        .children({
        // Badge for highlighted plan
        if (is_highlighted) {
            Row()
                .width(.percent(100))
                .layout(.center)
                .children({
                Row()
                    .pos(.{ .top = .px(-16), .type = .absolute })
                    .height(.px(32))
                    .width(.percent(40))
                    .layout(.center)
                    .background(.palette(.tint))
                    .border(.thin(.palette(.tint)))
                    .children({
                    Text("Most Popular")
                        .font(16, 200, .palette(.background))
                        .fontFamily("IBM Plex Sans,monospace")
                        .end();
                });
            });
        }

        // Plan name
        Text(plan.name)
            .font(24, 700, text_color)
            .end();

        // Price
        Row()
            .layout(.bottom_left)
            .spacing(4)
            .children({
            Text(plan.price)
                .font(48, 700, text_color)
                .end();
            if (plan.period.len > 0) {
                Text(plan.period)
                    .font(16, 300, text_color)
                    .fontFamily("IBM Plex Sans,monospace")
                    .end();
            }
        });

        // Description
        Text(plan.description)
            .font(14, 300, text_color)
            .fontFamily("IBM Plex Sans,monospace")
            .end();

        // Divider
        Row()
            .width(.percent(100))
            .height(.px(1))
            .background(.palette(.border_color_light))
            .children({});

        // Features list
        Stack()
            .width(.percent(100))
            .spacing(6)
            .children({
            for (plan.features) |feature| {
                Row()
                    .width(.percent(100))
                    .layout(.left_center)
                    .spacing(10)
                    .children({
                    Vapor.Icon(.check)
                        .font(16, 700, if (is_highlighted) .palette(.tint) else .palette(.text))
                        .end();
                    Text(feature)
                        .font(14, 300, text_color)
                        .fontFamily("IBM Plex Sans,monospace")
                        .end();
                });
            }
        });

        // CTA Button
        Row()
            .width(.percent(100))
            .padding(.{ .top = 16 })
            .layout(.center)
            .children({
            Button(onSelectPlan, .{plan.tier})
                .shadow(Vapor.Types.Shadow.init().dropSpread(0, 2, 4, 2, .transparentize(.black, 0.1)))
                .size(.hw(.px(42), .percent(80)))
                .layout(.center)
                .background(if (is_highlighted)
                    .palette(.tint)
                else
                    .transparent)
                // .border(.simple(if (is_highlighted) .palette(.tint) else .palette(.text)))
                .radius(.all(99))
                .pointer()
                .duration(150)
                .hover(.{
                    // .background = if (is_highlighted) .transparentizeHex(.palette(.tint), 0.2) else .palette(.text),
                    // .text = .palette(.background),
                    .transform = .scaleDecimal(1.02),
                })
                .font(16, 500, text_color)
                .children({
                Text(plan.cta_text)
                    .font(16, 300, null)
                    .end();
            });
        });
    });
}

pub fn render() void {
    Stack()
        .width(.percent(100))
        .layout(.center)
        .spacing(32)
        .padding(.all(48))
        .fontFamily("Montserrat, sans-serif")
        .children({
        // Header section
        Stack()
            .layout(.center)
            .spacing(12)
            .children({
            Text("Ryven Pricing")
                .font(42, 700, .palette(.text))
                .end();
            Text("Replace Sentry, Supabase, Postman, and more with Ryven. Choose the plan that fits your needs. Upgrade or downgrade at any time.")
                .font(16, 300, .palette(.text))
                .fontFamily("IBM Plex Sans,monospace")
                .end();
        });

        // Pricing cards row
        Row()
            .width(.percent(90))
            .layout(.center)
            .spacing(24)
            .columns(3)
            .children({
            for (&plans) |*plan| {
                PricingCard(plan);
            }
        });

        // Footer note
        Stack()
            .layout(.center)
            .spacing(8)
            .children({
            Text("Free plan includes 14-day free trial · No credit card required")
                .font(14, 300, .palette(.text))
                .fontFamily("IBM Plex Sans,monospace")
                .end();
            Row()
                .layout(.center)
                .spacing(16)
                .children({
                Vapor.Button(std.log.info, .{ "Ryven Pricing clicked", .{} })
                    .children({
                    Text("See what people are saying →")
                        .font(14, 500, .palette(.tint))
                        .fontFamily("IBM Plex Sans,monospace")
                        .end();
                });
            });
        });
    });
}

pub fn init() void {
    // Initialize any required state
}
