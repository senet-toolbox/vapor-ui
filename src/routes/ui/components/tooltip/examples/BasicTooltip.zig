const Tooltip = @import("opaque-ui").Tooltip;

// Text to hover, and the text it explains.
pub fn render() void {
    Tooltip.simple("Hover Me", "This is a tooltip");
}
