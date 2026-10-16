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
    .{ .title = "Status", .key = "status", .sort = .asc },
    .{ .title = "Email", .key = "email", .sort = .asc },
    .{ .title = "Amount", .key = "amount", .sort = .desc },
}, .{});

var table: MyTable = undefined;

var data: Vapor.Array(Transaction) = undefined;

pub fn init() void {
    data = Vapor.array(Transaction, .persist);
    data.appendSlice(&.{
        .{ .id = 0, .status = .pending, .email = "john@example.com", .amount = 100 },
        .{ .id = 1, .status = .paid, .email = "jane@example.com", .amount = 200 },
        .{ .id = 2, .status = .declined, .email = "alice@example.com", .amount = 300 },
    }) catch unreachable;

    table.init(data.items);
}

pub fn render() void {
    // Click sort icons to toggle between ascending/descending
    // Supports strings, enums, and numeric types
    Row()
        .width(.percent(100))
        .height(.fit)
        .children({
        table.render();
    });
}
