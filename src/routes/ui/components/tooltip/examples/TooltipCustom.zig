const Vapor = @import("vapor");
const Text = Vapor.Text;
const Row = Vapor.Row;
const Stack = Vapor.Stack;
const Icon = Vapor.Icon;
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

fn TooltipContent(title: []const u8, label: []const u8, due: Vapor.DateTime) void {
    Row()
        .width(.px(280))
        .width(.px(280))
        .padding(.all(16))
        .border(.round(.palette(.border_color_light), .all(12)))
        .direction(.column)
        .spacing(12)
        .children({
        // Header with title and priority badge
        Row()
            .layout(.x_between_center)
            .children({
            Text(title)
                .font(14, 600, .palette(.text_color))
                .fontFamily("Montserrat")
                .width(.px(180))
                .ellipsis(.dot)
                .end();
            Row()
                .padding(.xy(8, 4))
                .children({
                Text(label)
                    .font(10, 500, .palette(.tint))
                    .fontFamily("Montserrat")
                    .end();
            });
        });

        // Divider
        Row()
            .width(.percent(100))
            .height(.px(1))
            .background(.palette(.border_color_light))
            .children({});

        // Details section
        Stack()
            .width(.percent(100))
            .spacing(8)
            .children({
            // Due date
            Row()
                .width(.percent(100))
                .layout(.x_between_center)
                .children({
                Row()
                    .layout(.left_center)
                    .spacing(6)
                    .children({
                    Icon(.calendar)
                        .font(12, 400, .palette(.text_color))
                        .end();
                    Text("Due date")
                        .font(12, 400, .palette(.text_color))
                        .fontFamily("Montserrat")
                        .end();
                });
                Text(due.formatDate(Vapor.arena(.frame)) catch "")
                    .font(12, 500, .palette(.text_color))
                    .fontFamily("Montserrat")
                    .end();
            });
        });
    });
}

pub fn render() void {
    Tooltip.create(.{ .background = .palette(.background), .stroke_color = .palette(.border_color_light) })
        .Trigger(TooltipTrigger, .{"Custom Tooltip with Custom Content"})
        .Component(TooltipContent, .{ "CUSTOM", "Priority", Vapor.DateTime.now() })
        .end();
}
