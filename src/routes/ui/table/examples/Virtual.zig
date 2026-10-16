const Opaque = @import("opaque-ui");
const Vapor = @import("vapor");
const Row = Vapor.Row;
const Table = Opaque.Table;

const Status = enum { pending, paid, declined };

const Transaction = struct {
    id: usize,
    status: Status,
    email: []const u8,
    amount: i32,
};

const MyTable = Table(Transaction, &.{
    .{ .title = "Status", .key = "status" },
    .{ .title = "Email", .key = "email" },
    .{ .title = "Amount", .key = "amount" },
}, .{});

var table: MyTable = undefined;

pub fn init() void {
    // Generate large dataset (100+ rows)
    var data = Vapor.array(Transaction, .persist);
    for (0..100) |i| {
        data.append(.{
            .id = i,
            .status = if (i % 3 == 0) .pending else if (i % 3 == 1) .success else .err,
            .email = "user@example.com",
            .amount = @intCast((i + 1) * 100),
        }) catch unreachable;
    }

    table.init(data.items);
    table.display_mode = .virtual; // Enable virtualized rendering
    table.visible_row_count = 20; // Rows visible in viewport
}

pub fn render() void {
    Row()
        .width(.percent(100))
        .height(.px(600))
        .children({
        table.render();
    });
}
