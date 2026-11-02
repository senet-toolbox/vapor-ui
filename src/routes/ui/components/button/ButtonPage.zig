const Vapor = @import("vapor");
const Hero = @import("../../../../components/Hero.zig").Hero;
const Row = Vapor.Row;
const SyntaxHighlighter = @import("vaporize").SyntaxHighlighter;
const CodeBox = @import("../CodeBox.zig").CodeBox;
const Docs = @import("../Docs.zig");
// Rendered and shown as code: what you read is what runs.
const ButtonVariants = @import("examples/ButtonVariants.zig");
const ButtonIcons = @import("examples/ButtonIcons.zig");
const ButtonLoading = @import("examples/ButtonLoading.zig");

var hl_variants: SyntaxHighlighter = undefined;
var hl_icons: SyntaxHighlighter = undefined;
var hl_loading: SyntaxHighlighter = undefined;
var hl_api: SyntaxHighlighter = undefined;

pub fn init() void {
    hl_variants = Docs.highlighter(@embedFile("examples/ButtonVariants.zig"));
    hl_icons = Docs.highlighter(@embedFile("examples/ButtonIcons.zig"));
    hl_loading = Docs.highlighter(@embedFile("examples/ButtonLoading.zig"));
    hl_api = Docs.highlighter(
        \\const Button = @import("opaque-ui").Button;
        \\
        \\// A Vapor.Button with opaque-ui's look. Clicking it calls
        \\// func with args, as @call(func, args) would.
        \\pub fn Button(func: anytype, args: anytype) Vapor.Builder(.pure)
        \\
        \\// The rest is Vapor's builder: any call changes the look,
        \\// and children draw what's inside.
        \\Button(save, .{&draft})
        \\    .background(.palette(.tint))
        \\    .children({
        \\        Text("Save").end();
        \\    });
    );

    Vapor.Page(.{ .src = @src() }, render, null);
}

const defaults = [_]Docs.Field{
    .{ .name = "background", .default = ".transparentize(.hex(\"#F5F5F5\"), 0.2)", .desc = "A light wash that works on either theme." },
    .{ .name = "border", .default = ".round(.palette(.border_color_light), .all(12))", .desc = "A thin line, in the theme's border colour." },
    .{ .name = "padding", .default = ".xy(10, 8)", .desc = "Room around the content." },
    .{ .name = "layout", .default = ".x_between_center", .desc = "Children in a row, centred vertically, 8px apart." },
    .{ .name = "width, height", .default = ".fit", .desc = "As big as its content." },
    .{ .name = "shadow", .desc = "A faint inset edge and a drop shadow, which go away on hover." },
    .{ .name = "hover", .desc = "Darkens 5% and grows 1%, over 100ms." },
};

const behaviours = [_]Docs.Field{
    .{ .name = "Keyboard", .desc = "It's a real button: Tab reaches it, Enter or Space clicks it." },
    .{ .name = "Screen readers", .desc = "Its text names it. A button with only an icon needs .ariaLabel." },
    .{ .name = "Busy", .desc = "Mark it disabled and busy with .a11y, and give it a handler that does nothing, as Loading does." },
};

pub fn render() void {
    Row()
        .width(.percent(100))
        .layout(.top_center)
        .direction(.column)
        .children({
        Hero("button-ui", "A collection of ready-to-use button components built on top of Vapor. Copy and paste into your apps.");

        Docs.Content().children({
            Docs.exampleLabel("Variants");
            Docs.sectionDesc("One button, styled for each kind of action.");
            Docs.PreviewCard().layout(.center).children({
                ButtonVariants.render();
            });
            CodeBox(&hl_variants, "ButtonVariants");

            Docs.exampleLabel("With Icon");
            Docs.sectionDesc("Icons go in the children, beside the text or on their own.");
            Docs.PreviewCard().layout(.center).children({
                ButtonIcons.render();
            });
            CodeBox(&hl_icons, "ButtonIcons");

            Docs.exampleLabel("Loading");
            Docs.sectionDesc("While a button waits on its work, it can't be clicked, and screen readers hear that it's busy.");
            Docs.PreviewCard().layout(.center).children({
                ButtonLoading.render();
            });
            CodeBox(&hl_loading, "ButtonLoading");

            Docs.sectionTitle("API Reference");

            Docs.exampleLabel("Button");
            Docs.sectionDesc("Takes the function to call and its arguments, and returns a builder.");
            CodeBox(&hl_api, "Button");

            Docs.exampleLabel("Defaults");
            Docs.sectionDesc("The look it starts with. Each one is a builder call you can make again to change it.");
            Docs.ApiBox("Defaults", &defaults);

            Docs.exampleLabel("Behaviour");
            Docs.sectionDesc("What the button does for you.");
            Docs.ApiBox("Behaviour", &behaviours);
        });
    });
}
