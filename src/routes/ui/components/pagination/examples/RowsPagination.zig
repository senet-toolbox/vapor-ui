const Vapor = @import("vapor");
const Stack = Vapor.Stack;
const Pagination = @import("opaque-ui").Pagination;

const rows = 1000;
const per_page = 20;

var page: usize = 9;
var fetches: usize = 0;

/// Where you would fetch the page's rows.
fn fetch(new_page: usize) void {
    _ = new_page;
    fetches += 1;
}

pub fn render() void {
    Stack().layout(.center).spacing(16).children({
        Pagination.render(&page, rows / per_page, .{ .on_change = fetch });
        Vapor.TextFmt("Rows {d}–{d} of {d}, fetched {d} times", .{ page * per_page + 1, (page + 1) * per_page, rows, fetches })
            .font(14, 400, .transparentize(.palette(.text_color), 0.6))
            .end();
    });
}
