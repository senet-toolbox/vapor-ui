// page.zig
const std = @import("std");
const Vapor = @import("vapor");
const Text = Vapor.Text;
const Row = Vapor.Row;
const Stack = Vapor.Stack;
const Opaque = @import("opaque-ui");
const Select = Opaque.Select;
const Vaporize = @import("vaporize");
const SyntaxHighlighter = Vaporize.SyntaxHighlighter;
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
var hl_with_icons: SyntaxHighlighter = undefined;
var hl_grouped: SyntaxHighlighter = undefined;
var hl_custom_trigger: SyntaxHighlighter = undefined;
var hl_detached: SyntaxHighlighter = undefined;

// ============================================================================
// SELECT INSTANCES
// ============================================================================

const Status = enum { pending, success, err };
var basic_select: Select(Status) = undefined;

const ScienceTools = enum { microscope, fire, screwdriver, toolbox };
var icons_select: Select(ScienceTools) = undefined;

const TimeZone = enum {
    est,
    cst,
    mst,
    pst,
    akst,
    hst,
    gmt,
    cet,
    eet,
    west,
    cat,
    eat,
    msk,
    ist,
    cst_china,
    jst,
    kst,
    wita,
    awst,
    acst,
    aest,
    nzst,
    fjt,
    art,
    bot,
    brt,
    clt,
    utc,
};
var grouped_select: Select(TimeZone) = undefined;

var custom_select: Select(usize) = undefined;

const NavItem = enum { dashboard, transactions, analytics, customers, settings };
var detached_select: Select(NavItem) = undefined;

// ============================================================================
// INIT
// ============================================================================

pub fn init() void {
    const allocator = Vapor.arena(.persist);

    // Initialize syntax highlighters
    hl_basic = SyntaxHighlighter.init(allocator);
    hl_basic.show_toolbar = true;
    hl_basic.parse(@embedFile("examples/BasicSelect.zig")) catch unreachable;

    hl_with_icons = SyntaxHighlighter.init(allocator);
    hl_basic.show_toolbar = true;
    hl_with_icons.parse(@embedFile("examples/WithIcons.zig")) catch unreachable;

    hl_grouped = SyntaxHighlighter.init(allocator);
    hl_basic.show_toolbar = true;
    hl_grouped.parse(@embedFile("examples/Grouped.zig")) catch unreachable;

    hl_custom_trigger = SyntaxHighlighter.init(allocator);
    hl_basic.show_toolbar = true;
    hl_custom_trigger.parse(@embedFile("examples/CustomTrigger.zig")) catch unreachable;

    hl_detached = SyntaxHighlighter.init(allocator);
    hl_basic.show_toolbar = true;
    hl_detached.parse(@embedFile("examples/Detached.zig")) catch unreachable;

    // Initialize select components
    basic_select = .fromItems(&.{
        .{ .value = Status.pending, .label = "Pending" },
        .{ .value = Status.success, .label = "Success" },
        .{ .value = Status.err, .label = "Error" },
    });

    icons_select = .fromItems(&.{
        .{ .value = ScienceTools.microscope, .label = "Microscope", .icon = .microscope },
        .{ .value = ScienceTools.fire, .label = "Fire", .icon = .fire },
        .{ .value = ScienceTools.screwdriver, .label = "Screwdriver", .icon = .screw_driver },
        .{ .value = ScienceTools.toolbox, .label = "Toolbox", .icon = .toolbox },
    });
    icons_select.trigger = "Science Tools";

    grouped_select = .init("Select Timezone", &.{
        Select(TimeZone).Group{ .title = "North America", .items = &.{
            .{ .value = TimeZone.est, .label = "Eastern Standard Time (EST)" },
            .{ .value = TimeZone.cst, .label = "Central Standard Time (CST)" },
            .{ .value = TimeZone.mst, .label = "Mountain Standard Time (MST)" },
            .{ .value = TimeZone.pst, .label = "Pacific Standard Time (PST)" },
            .{ .value = TimeZone.akst, .label = "Alaska Standard Time (AKST)" },
            .{ .value = TimeZone.hst, .label = "Hawaii Standard Time (HST)" },
        } },
        Select(TimeZone).Group{ .title = "Europe & Africa", .items = &.{
            .{ .value = TimeZone.gmt, .label = "Greenwich Mean Time (GMT)" },
            .{ .value = TimeZone.cet, .label = "Central European Time (CET)" },
            .{ .value = TimeZone.eet, .label = "Eastern European Time (EET)" },
            .{ .value = TimeZone.west, .label = "Western European Summer Time (WEST)" },
            .{ .value = TimeZone.cat, .label = "Central Africa Time (CAT)" },
            .{ .value = TimeZone.eat, .label = "East Africa Time (EAT)" },
        } },
        Select(TimeZone).Group{ .title = "Asia", .items = &.{
            .{ .value = TimeZone.msk, .label = "Moscow Time (MSK)" },
            .{ .value = TimeZone.ist, .label = "India Standard Time (IST)" },
            .{ .value = TimeZone.cst_china, .label = "China Standard Time (CST)" },
            .{ .value = TimeZone.jst, .label = "Japan Standard Time (JST)" },
            .{ .value = TimeZone.kst, .label = "Korea Standard Time (KST)" },
            .{ .value = TimeZone.wita, .label = "Indonesia Central Standard Time (WITA)" },
        } },
        Select(TimeZone).Group{ .title = "Australia & Pacific", .items = &.{
            .{ .value = TimeZone.awst, .label = "Australian Western Standard Time (AWST)" },
            .{ .value = TimeZone.acst, .label = "Australian Central Standard Time (ACST)" },
            .{ .value = TimeZone.aest, .label = "Australian Eastern Standard Time (AEST)" },
            .{ .value = TimeZone.nzst, .label = "New Zealand Standard Time (NZST)" },
            .{ .value = TimeZone.fjt, .label = "Fiji Time (FJT)" },
        } },
        Select(TimeZone).Group{ .title = "South America", .items = &.{
            .{ .value = TimeZone.art, .label = "Argentina Time (ART)" },
            .{ .value = TimeZone.bot, .label = "Bolivia Time (BOT)" },
            .{ .value = TimeZone.brt, .label = "Brasilia Time (BRT)" },
            .{ .value = TimeZone.clt, .label = "Chile Standard Time (CLT)" },
        } },
    });

    custom_select = .fromItems(&.{
        .{ .value = 0, .label = "Item 1" },
        .{ .value = 1, .label = "Item 2" },
        .{ .value = 2, .label = "Item 3" },
        .{ .value = 3, .label = "Item 4" },
        .{ .value = 4, .label = "Item 5" },
    });
    custom_select.trigger_component = CustomSelectBtn;
    custom_select.on_select = handleCustomSelect;

    detached_select = .fromItems(&.{
        .{ .value = NavItem.dashboard, .label = "Dashboard" },
        .{ .value = NavItem.transactions, .label = "Transactions" },
        .{ .value = NavItem.analytics, .label = "Analytics" },
        .{ .value = NavItem.customers, .label = "Customers" },
        .{ .value = NavItem.settings, .label = "Settings" },
    });
    detached_select.trigger_component = DetachedSelectBtn;
    detached_select.on_select = handleDetachedSelect;
    detached_select.is_detached = true;

    Vapor.Page(.{ .src = @src() }, render, null);
}

// ============================================================================
// HANDLERS
// ============================================================================

fn handleCustomSelect(_: *Select(usize), item: *Select(usize).Item) void {
    Vapor.alert("Selected: {s}", .{item.label});
}

fn handleDetachedSelect(_: *Select(NavItem), item: *Select(NavItem).Item) void {
    Vapor.alert("Selected: {s}", .{item.label});
}

// ============================================================================
// CUSTOM TRIGGER COMPONENTS
// ============================================================================

fn CustomSelectBtn(_: *Select(usize)) void {
    Row()
        .width(.percent(100))
        .layout(.center)
        .children({
        Row()
            .width(.px(24))
            .height(.px(24))
            .cursor(.pointer)
            .background(.palette(.background))
            .hover(.{
                .background = .palette(.tint),
                .text_color = .palette(.background),
            })
            .font(14, 300, .palette(.text_color))
            .duration(200)
            .border(.round(.transparent, .all(4)))
            .layout(.center)
            .children({
            Vapor.Icon(.three_dots)
                .font(16, 300, null)
                .end();
        });
    });
}

fn DetachedSelectBtn(_: *Select(NavItem)) void {
    Row()
        .padding(.tblr(8, 8, 10, 10))
        .layout(.x_between_center)
        .spacing(8)
        .width(.fit)
        .height(.fit)
        .border(.round(.palette(.border_color_light), .all(12)))
        .background(.palette(.tint))
        .duration(100)
        .shadow(Vapor.Types.NewShadow.init()
            .inset(0, -2, .transparentizeHex(.black, 0.3))
            .drop(0, 1, 3, .transparentizeHex(.black, 0.1)))
        .hover(.{
            .transform = .scaleDecimal(1.01),
            .new_shadow = Vapor.Types.NewShadow.init()
                .inset(0, -2, .transparentizeHex(.black, 0))
                .drop(0, 1, 3, .transparentizeHex(.black, 0)),
        })
        .children({
        Text("Open Menu →")
            .fontFamily("Montserrat")
            .font(16, 300, .palette(.background))
            .end();
    });
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
// RENDER
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
            Text("select-ui ⇒").style(&.{
                .visual = .font(12, 500, .hex("#6f6f6f")),
                .font_family = "IBM Plex Mono,monospace",
            }).end();
            Text("select-ui")
                .font(72, 700, .palette(.text_color))
                .end();
            Text("A collection of ready-to-use select components built on top of Vapor, copy and paste into your apps.")
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

            // ============================================================
            // BASIC
            // ============================================================
            exampleLabel("Basic");
            sectionDesc("A simple select with a flat list of items.");
            PreviewCard().children({
                basic_select.render();
            });
            CodeBox(&hl_basic, "BasicSelect");

            // ============================================================
            // WITH ICONS
            // ============================================================
            exampleLabel("With Icons");
            sectionDesc("Items can include icons for visual clarity.");
            PreviewCard().children({
                icons_select.render();
            });
            CodeBox(&hl_with_icons, "WithIcons");

            // ============================================================
            // GROUPED
            // ============================================================
            exampleLabel("Grouped");
            sectionDesc("Organize items into labeled groups using .init() with Group structs.");
            PreviewCard().children({
                grouped_select.render();
            });
            CodeBox(&hl_grouped, "Grouped");

            // ============================================================
            // CUSTOM TRIGGER
            // ============================================================
            exampleLabel("Custom Trigger");
            sectionDesc("Replace the default trigger button with a custom component.");
            PreviewCard().children({
                custom_select.render();
            });
            CodeBox(&hl_custom_trigger, "CustomTrigger");

            // ============================================================
            // DETACHED
            // ============================================================
            exampleLabel("Detached");
            sectionDesc("Render the trigger and dropdown separately for custom layouts.");
            PreviewCard().children({
                Stack().children({
                    detached_select.renderTrigger();
                });
                Stack()
                    .width(.percent(10))
                    .pos(.tr(.px(72), .px(12), .fixed))
                    .children({
                    detached_select.renderSelect();
                });
            });
            CodeBox(&hl_detached, "Detached");

            // ============================================================
            // API REFERENCE
            // ============================================================
            sectionTitle("API Reference");

            exampleLabel("Initialization");
            sectionDesc("Two ways to create a Select:");
            Row()
                .width(.percent(100))
                .padding(.all(16))
                .background(Theme.code_bg)
                .border(.round(Theme.border, .all(8)))
                .children({
                Text(
                    \\// Flat list
                    \\var select = Select(MyEnum).fromItems(&.{ ... });
                    \\
                    \\// Grouped list
                    \\var select = Select(MyEnum).init("Placeholder", &.{
                    \\    Select(MyEnum).Group{ .title = "Group", .items = &.{ ... } },
                    \\});
                )
                    .font(14, 400, .hex("#e4e4e7"))
                    .fontFamily("IBM Plex Mono,monospace")
                    .end();
            });

            exampleLabel("Item Structure");
            sectionDesc("Each item requires a value and label. Icon is optional.");
            Row()
                .width(.percent(100))
                .padding(.all(16))
                .background(Theme.code_bg)
                .border(.round(Theme.border, .all(8)))
                .children({
                Text(
                    \\.{ .value = MyEnum.option, .label = "Option Label", .icon = .icon_name }
                )
                    .font(14, 400, .hex("#e4e4e7"))
                    .fontFamily("IBM Plex Mono,monospace")
                    .end();
            });

            exampleLabel("Properties");
            sectionDesc("Configure behavior after initialization.");
            Row()
                .width(.percent(100))
                .padding(.all(16))
                .background(Theme.code_bg)
                .border(.round(Theme.border, .all(8)))
                .children({
                Text(
                    \\select.trigger = "Placeholder text";      // Custom placeholder
                    \\select.trigger_component = myFn;          // Custom trigger component
                    \\select.on_select = handleSelect;          // Selection callback
                )
                    .font(14, 400, .hex("#e4e4e7"))
                    .fontFamily("IBM Plex Mono,monospace")
                    .end();
            });

            exampleLabel("Render Methods");
            sectionDesc("Choose how to render the component.");
            Row()
                .width(.percent(100))
                .padding(.all(16))
                .background(Theme.code_bg)
                .border(.round(Theme.border, .all(8)))
                .children({
                Text(
                    \\select.render();          // Render trigger + dropdown together
                    \\select.renderTrigger();   // Render trigger only
                    \\select.renderSelect();    // Render dropdown only
                )
                    .font(14, 400, .hex("#e4e4e7"))
                    .fontFamily("IBM Plex Mono,monospace")
                    .end();
            });

            exampleLabel("Callback Signature");
            sectionDesc("The on_select callback receives the select instance and selected item.");
            Row()
                .width(.percent(100))
                .padding(.all(16))
                .background(Theme.code_bg)
                .border(.round(Theme.border, .all(8)))
                .children({
                Text(
                    \\fn handleSelect(sel: *Select(MyEnum), item: *Select(MyEnum).Item) void {
                    \\    // item.value - the enum value
                    \\    // item.label - the display string
                    \\    // item.icon  - optional icon
                    \\}
                )
                    .font(14, 400, .hex("#e4e4e7"))
                    .fontFamily("IBM Plex Mono,monospace")
                    .end();
            });
        });
    });
}

