// examples/WithIcons.zig
const Vapor = @import("vapor");
const Opaque = @import("opaque-ui");
const Select = Opaque.Select;

const ScienceTools = enum {
    microscope,
    fire,
    screwdriver,
    toolbox,
};

var select: Select(ScienceTools) = undefined;

pub fn init() void {
    select = .fromItems(&.{
        .{ .value = ScienceTools.microscope, .label = "Microscope", .icon = .microscope },
        .{ .value = ScienceTools.fire, .label = "Fire", .icon = .fire },
        .{ .value = ScienceTools.screwdriver, .label = "Screwdriver", .icon = .screw_driver },
        .{ .value = ScienceTools.toolbox, .label = "Toolbox", .icon = .toolbox },
    });
    select.trigger = "Science Tools";
}

pub fn render() void {
    select.render();
}
