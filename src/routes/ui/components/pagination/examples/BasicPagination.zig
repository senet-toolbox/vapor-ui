const Vapor = @import("vapor");
const Stack = Vapor.Stack;
const Pagination = @import("opaque-ui").Pagination;

var page: usize = 0;

pub fn render() void {
    Stack().layout(.center).spacing(16).children({
        Pagination.render(&page, 12, .{});
        Vapor.TextFmt("Showing page {d} of 12", .{page + 1})
            .font(14, 400, .transparentize(.palette(.text_color), 0.6))
            .end();
    });
}
