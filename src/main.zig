const std = @import("std");
const Vapor = @import("vapor");
const Opaque = @import("opaque-ui");
const Animation = Vapor.Animation;

const initView = @import("components/View.zig").init;
const newView = @import("components/View.zig").new;
const Theme = @import("theme");
const VaporUI = @import("routes/vapor-ui/Page.zig");

// Initialize Vapor
pub export fn init() void {
    Vapor.init(.{});
    Animation.new();
    Opaque.new();
    Opaque.initAnimations();
    Opaque.OverlayManager.init();
    initView();

    Vapor.setGlobalStyleVariables(.{ // Adds 11kb
        .themes = &.{
            Vapor.ThemeDefinition{ .name = "light", .theme = Theme.Light, .default = true },
            Vapor.ThemeDefinition{ .name = "dark", .theme = Theme.Dark },
        },
    });

    VaporUI.init();
}

pub const std_options = std.Options{
    // Debug logs stay in development; visitors' consoles get warnings only.
    .log_level = if (@import("builtin").mode == .Debug) .debug else .warn,
    .logFn = Vapor.lib.log,
};
