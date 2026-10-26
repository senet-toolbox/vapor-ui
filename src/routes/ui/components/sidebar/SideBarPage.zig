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
const SideBar = Opaque.SideBar;
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
var hl_groups: SyntaxHighlighter = undefined;
var hl_menu_items: SyntaxHighlighter = undefined;
var hl_render: SyntaxHighlighter = undefined;

// ============================================================================
// SIDEBAR INSTANCE
// ============================================================================

var sidebar: SideBar = .{
    .groups = &groups,
    .title = "Vapor UI",
    .show_menu = true,
};

const GroupItem = SideBar.GroupItem;
const MenuItem = SideBar.MenuItem;

var groups = [_]GroupItem{
    GroupItem{
        .title = "Dashboard",
        .items = menu_items[0..2],
        .show = true,
        .icon = .grid_3x3,
    },
    GroupItem{
        .title = "Projects",
        .items = menu_items[2..4],
        .show = true,
        .icon = .folder,
    },
    GroupItem{
        .title = "Routes",
        .items = menu_items[4..6],
        .show = true,
        .icon = .diagram_3,
    },
};

const menu_items: []const MenuItem = &.{
    MenuItem{
        .title = "Dashboard",
        .link = "/nightwatch/dashboard",
        .icon = .house,
    },
    MenuItem{
        .title = "Projects",
        .link = "/nightwatch/projects",
        .icon = .folder,
    },
    MenuItem{
        .title = "Routes",
        .link = "/nightwatch/routes",
        .icon = .diagram_3,
    },
    MenuItem{
        .title = "Treehouse",
        .link = "/nightwatch/treehouse",
        .icon = .tree,
    },
    MenuItem{
        .title = "Database",
        .link = "/nightwatch/database",
        .icon = .database,
    },
    MenuItem{
        .title = "Activity",
        .link = "/nightwatch/activity",
        .icon = .activity,
    },
    MenuItem{
        .title = "Memory",
        .link = "/nightwatch/memory",
        .icon = .memory,
    },
    MenuItem{
        .title = "Logs",
        .link = "/nightwatch/logs",
        .icon = .lightbulb,
    },
    MenuItem{
        .title = "Sql Editor",
        .link = "/nightwatch/sql-editor",
        .icon = .code_slash,
    },
};

// ============================================================================
// INIT
// ============================================================================

pub fn init() void {
    const allocator = Vapor.arena(.persist);
    SideBar.init();

    // Initialize syntax highlighters
    hl_basic = SyntaxHighlighter.init(allocator);
    hl_basic.show_toolbar = true;
    hl_basic.parse(
        \\var sidebar: SideBar = .{
        \\    .groups = &groups,
        \\    .title = "Vapor UI",
        \\    .show_menu = true,
        \\};
        \\
        \\sidebar.render();
    ) catch unreachable;

    hl_groups = SyntaxHighlighter.init(allocator);
    hl_groups.show_toolbar = true;
    hl_groups.parse(
        \\const GroupItem = SideBar.GroupItem;
        \\
        \\var groups = [_]GroupItem{
        \\    GroupItem{
        \\        .title = "Dashboard",
        \\        .items = menu_items[0..2],
        \\        .show = true,
        \\        .icon = .grid_3x3,
        \\    },
        \\    GroupItem{
        \\        .title = "Projects",
        \\        .items = menu_items[2..4],
        \\        .show = true,
        \\        .icon = .folder,
        \\    },
        \\};
    ) catch unreachable;

    hl_menu_items = SyntaxHighlighter.init(allocator);
    hl_menu_items.show_toolbar = true;
    hl_menu_items.parse(
        \\const MenuItem = SideBar.MenuItem;
        \\
        \\const menu_items: []const MenuItem = &.{
        \\    MenuItem{
        \\        .title = "Dashboard",
        \\        .link = "/dashboard",
        \\        .icon = .house,
        \\    },
        \\    MenuItem{
        \\        .title = "Projects",
        \\        .link = "/projects",
        \\        .icon = .folder,
        \\    },
        \\};
    ) catch unreachable;

    hl_render = SyntaxHighlighter.init(allocator);
    hl_render.show_toolbar = true;
    hl_render.parse(
        \\pub fn render() void {
        \\    Row()
        \\        .direction(.row)
        \\        .children({
        \\        sidebar.render();
        \\        // Your main content here
        \\    });
        \\}
    ) catch unreachable;

    Vapor.Page(.{ .src = @src() }, render, null);
}

// ============================================================================
// UI COMPONENTS
// ============================================================================

fn sectionTitle(title: []const u8) void {
    Text(title)
        .font(24, 600, Theme.text)
        .fontFamily("IBM Plex Mono,monospace")
        .margin(.{ .top = 48 })
        .end();
}

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

fn PreviewCard() Vapor.Builder(.pure) {
    return Row()
        .background(.transparentize(.palette(.background), 0.5))
        .border(.round(.palette(.border_color_light), .all(12)))
        .width(.percent(100))
        .height(.px(512))
        .padding(.all(24))
        .direction(.column)
        .layout(.center)
        .spacing(16);
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
            Text("sidebar-ui ⇒").style(&.{
                .visual = .font(12, 500, .hex("#6f6f6f")),
                .font_family = "IBM Plex Mono,monospace",
            }).end();
            Text("sidebar")
                .font(72, 700, .palette(.text_color))
                .end();
            Text("A collapsible navigation sidebar with grouped menu items, icons, and customizable styling.")
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

            // ============================================================
            // BASIC
            // ============================================================
            exampleLabel("Basic");
            sectionDesc("A sidebar with grouped navigation items and collapsible sections.");
            PreviewCard()
                .direction(.row)
                .children({
                Vapor.Row()
                    .width(.percent(50))
                    .height(.percent(100))
                    .children({
                    sidebar.render();
                });
                Row()
                    .width(.expand)
                    .layout(.center)
                    .children({
                    Text("Content Over Here").fontFamily("Montserrat").font(18, null, null).end();
                });
            });
            CodeBox(&hl_basic, "BasicSidebar");

            // ============================================================
            // API REFERENCE
            // ============================================================
            sectionTitle("API Reference");

            exampleLabel("Initialization");
            sectionDesc("Create a SideBar with groups, title, and menu visibility.");
            Row()
                .width(.percent(100))
                .padding(.all(16))
                .background(Theme.code_bg)
                .border(.round(Theme.border, .all(8)))
                .children({
                Text(
                    \\var sidebar: SideBar = .{
                    \\    .groups = &groups,     // Array of GroupItem
                    \\    .title = "My App",     // Sidebar header title
                    \\    .show_menu = true,     // Toggle menu visibility
                    \\};
                )
                    .font(14, 400, .hex("#e4e4e7"))
                    .fontFamily("IBM Plex Mono,monospace")
                    .end();
            });

            exampleLabel("GroupItem Structure");
            sectionDesc("Each group contains a title, menu items, visibility state, and an optional icon.");
            CodeBox(&hl_groups, "GroupItem");

            exampleLabel("MenuItem Structure");
            sectionDesc("Each menu item requires a title, link, and optional icon.");
            CodeBox(&hl_menu_items, "MenuItem");

            exampleLabel("Properties");
            sectionDesc("Configure the sidebar after initialization.");
            Row()
                .width(.percent(100))
                .padding(.all(16))
                .background(Theme.code_bg)
                .border(.round(Theme.border, .all(8)))
                .children({
                Text(
                    \\sidebar.title = "App Name";        // Header title
                    \\sidebar.show_menu = true;          // Show/hide menu
                    \\sidebar.groups = &my_groups;       // Set navigation groups
                )
                    .font(14, 400, .hex("#e4e4e7"))
                    .fontFamily("IBM Plex Mono,monospace")
                    .end();
            });

            exampleLabel("Render");
            sectionDesc("Call render() to display the sidebar alongside your content.");
            CodeBox(&hl_render, "Sidebar.render()");

            exampleLabel("Available Icons");
            sectionDesc("Use any icon from the Vapor icon set.");
            Row()
                .width(.percent(100))
                .padding(.all(16))
                .background(Theme.code_bg)
                .border(.round(Theme.border, .all(8)))
                .children({
                Text(
                    \\.icon = .house       // Home icon
                    \\.icon = .folder      // Folder icon
                    \\.icon = .database    // Database icon
                    \\.icon = .activity    // Activity graph icon
                    \\.icon = .grid_3x3    // Grid icon
                    \\.icon = .diagram_3   // Diagram/routes icon
                    \\.icon = .tree        // Tree structure icon
                    \\.icon = .code_slash  // Code editor icon
                )
                    .font(14, 400, .hex("#e4e4e7"))
                    .fontFamily("IBM Plex Mono,monospace")
                    .end();
            });
        });
    });
}
