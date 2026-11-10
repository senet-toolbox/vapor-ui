const Vapor = @import("vapor");
const Stack = Vapor.Stack;
const Segmented = @import("opaque-ui").Segmented;

var view: usize = 0;
var changes: usize = 0;

fn changed(index: usize) void {
    _ = index;
    changes += 1;
}

pub fn render() void {
    Stack().width(.percent(100)).inlineStyle("max-width: 420px;", .{}).spacing(16).layout(.center).children({
        Segmented.render(&view, &.{ "List", "Board", "Calendar" }, .{
            .label = "View",
            .full_width = true,
            .on_change = changed,
        });
        Vapor.TextFmt("Changed {d} times", .{changes})
            .font(14, 400, .transparentize(.palette(.text_color), 0.6))
            .end();
    });
}
