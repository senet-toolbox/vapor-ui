const CommandPalette = @import("opaque-ui").CommandPalette;

// The field people click, or reach with Ctrl+J (Cmd+J on a Mac).
var palette: CommandPalette = .{ .text = "Search...", .key_press = "j" };

pub fn render() void {
    palette.render();
}
