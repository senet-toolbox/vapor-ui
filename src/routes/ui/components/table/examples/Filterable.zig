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
    .{ .title = "Status", .key = "status", .filter = true }, // Enum dropdown filter
    .{ .title = "Email", .key = "email", .search = true }, // Text search
    .{ .title = "Amount", .key = "amount" },
}, .{});

var table: MyTable = undefined;

var data: Vapor.Array(Transaction) = undefined;

pub fn init() void {
    data = Vapor.array(Transaction, .persist);
    sample(&data, 15);

    table.init(data.items);
}

pub fn render() void {
    // Click the funnel icon to filter by status enum values
    // Click the search icon to search email text
    Row()
        .width(.percent(100))
        .height(.fit)
        .children({
        table.render();
    });
}

/// `count` rows of made-up transactions.
fn sample(rows: *Vapor.Array(Transaction), count: usize) void {
    const statuses = [_]Status{ .pending, .paid, .declined };
    const emails = [_][]const u8{ "john@example.com", "jane@example.com", "alice@example.com", "bob@example.com", "mary@example.com" };
    for (0..count) |i| {
        rows.append(.{
            .id = i,
            .status = statuses[i % statuses.len],
            .email = emails[i % emails.len],
            .amount = @intCast((i + 1) * 100),
        }) catch unreachable;
    }
}
