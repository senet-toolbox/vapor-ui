const Vapor = @import("vapor");
const Row = Vapor.Row;
const Stack = Vapor.Stack;
const Skeleton = @import("opaque-ui").Skeleton;

pub fn render() void {
    Stack().width(.percent(100)).inlineStyle("max-width: 360px;", .{}).spacing(16).children({
        Skeleton.render(.{ .height = 160, .radius = 12 });
        Row().width(.percent(100)).spacing(12).layout(.left_center).children({
            Skeleton.circle(40);
            Stack().width(.grow).spacing(8).children({
                Skeleton.render(.{ .width = .px(140), .height = 14 });
                Skeleton.text(2);
            });
        });
    });
}
