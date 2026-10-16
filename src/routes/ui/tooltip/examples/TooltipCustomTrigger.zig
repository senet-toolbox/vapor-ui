const Vapor = @import("vapor");
const Text = Vapor.Text;
const Row = Vapor.Row;
const Opaque = @import("opaque-ui");
const Tooltip = Opaque.Tooltip;

fn TooltipTrigger(title: []const u8) void {
    Row()
        .width(.fit)
        .padding(.xy(12, 8))
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
        Text(title)
            .font(14, 300, null)
            .end();
    });
}

fn render() void {
    Tooltip.create(.{ .content = "This is a custom trigger tooltip" })
        .Trigger(TooltipTrigger, .{"Custom Tooltip"})
        .end();
}
