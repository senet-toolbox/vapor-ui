const Vapor = @import("vapor");
const Hero = @import("../../../../components/Hero.zig").Hero;
const Row = Vapor.Row;
const SyntaxHighlighter = @import("vaporize").SyntaxHighlighter;
const CodeBox = @import("../CodeBox.zig").CodeBox;
const Docs = @import("../Docs.zig");
// Rendered and shown as code: what you read is what runs.
const AlertExample = @import("examples/AlertExample.zig");

var hl_alert: SyntaxHighlighter = undefined;
var hl_api: SyntaxHighlighter = undefined;

pub fn init() void {
    hl_alert = Docs.highlighter(@embedFile("examples/AlertExample.zig"));
    hl_api = Docs.highlighter(
        \\const Alert = @import("opaque-ui").Alert;
        \\
        \\// A closed alert whose box your function draws.
        \\pub fn init(content: ?*const fn (*Alert) void) Alert
        \\// Draws the alert while it's open, and nothing while it's closed.
        \\pub fn render(alert: *Alert) void
        \\pub fn open(alert: *Alert) void
        \\pub fn close(alert: *Alert) void
        \\
        \\// A global var: open and close change it, so it must outlive
        \\// the render.
        \\var alert: Alert = undefined;
        \\
        \\// Any button can open it.
        \\Button(Alert.open, .{&alert})
    );
    AlertExample.init();

    Vapor.Page(.{ .src = @src() }, render, null);
}

const alert_fields = [_]Docs.Field{
    .{ .name = "content", .type = "?*const fn (*Alert) void", .default = "null", .desc = "Draws what's in the box: text, buttons, anything. Your buttons call close to dismiss it." },
    .{ .name = "closed", .type = "bool", .default = "true", .desc = "Whether the alert is hidden. open and close set it." },
    .{ .name = "background", .type = "Color", .default = ".palette(.background)", .desc = "The box's background." },
    .{ .name = "border", .type = "Border", .default = ".round(.hex(\"#e4e4e4\"), .all(12))", .desc = "The box's border and corners." },
    .{ .name = "on_enter", .type = "?*const fn (*Alert) void", .default = "null", .desc = "Called when Enter is pressed while the alert is open. The alert stays open; close it here if the action should." },
    .{ .name = "on_close", .type = "?*const fn () void", .default = "null", .desc = "Called when Escape closes the alert." },
};

const behaviours = [_]Docs.Field{
    .{ .name = "Closing", .desc = "Escape, a click outside the box, or your call to close." },
    .{ .name = "Keyboard", .desc = "While open, Escape closes it and Enter calls on_enter." },
    .{ .name = "Backdrop", .desc = "The page behind is blurred and can't be clicked; the box sits in the middle." },
    .{ .name = "Animation", .desc = "Fades and grows in, and fades and shrinks out, in 200ms." },
};

fn render() void {
    Row()
        .width(.percent(100))
        .layout(.top_center)
        .direction(.column)
        .children({
        Hero("alert-ui", "Modal interrupts used for confirmations, warnings, and critical information.");

        Docs.Content().children({
            Docs.exampleLabel("Confirmation");
            Docs.sectionDesc("A box in front of the page that waits for an answer. Your function draws what's in it.");
            Docs.PreviewCard().height(.px(200)).layout(.center).children({
                AlertExample.render();
            });
            CodeBox(&hl_alert, "Alert");

            Docs.sectionTitle("API Reference");

            Docs.exampleLabel("Alert");
            Docs.sectionDesc("Make one in your init, and render it where its button is.");
            CodeBox(&hl_api, "Alert");

            Docs.exampleLabel("Fields");
            Docs.sectionDesc("Set them after init to change how it looks and what it does.");
            Docs.ApiBox("Alert", &alert_fields);

            Docs.exampleLabel("Behaviour");
            Docs.sectionDesc("What the alert does for you.");
            Docs.ApiBox("Behaviour", &behaviours);
        });
    });
}
