const Vapor = @import("vapor");
const Hero = @import("../../../../components/Hero.zig").Hero;
const Row = Vapor.Row;
const SyntaxHighlighter = @import("vaporize").SyntaxHighlighter;
const CodeBox = @import("../CodeBox.zig").CodeBox;
const Docs = @import("../Docs.zig");
// Rendered and shown as code: what you read is what runs.
const BasicCommandPalette = @import("examples/BasicCommandPalette.zig");
const PaletteDialog = @import("examples/PaletteDialog.zig");

var hl_basic: SyntaxHighlighter = undefined;
var hl_dialog: SyntaxHighlighter = undefined;
var hl_api: SyntaxHighlighter = undefined;

pub fn init() void {
    hl_basic = Docs.highlighter(@embedFile("examples/BasicCommandPalette.zig"));
    hl_dialog = Docs.highlighter(@embedFile("examples/PaletteDialog.zig"));
    hl_api = Docs.highlighter(
        \\const CommandPalette = @import("opaque-ui").CommandPalette;
        \\
        \\// Draws the field. While it's on the page, its shortcut works.
        \\pub fn render(palette: *CommandPalette) void
        \\// Opens or closes it, as a click or the shortcut does.
        \\pub fn toggle(palette: *CommandPalette) void
        \\
        \\// A struct you fill in, kept in a global var.
        \\var palette: CommandPalette = .{ .text = "Search...", .on_click = onOpen };
    );
    PaletteDialog.init();

    Vapor.Page(.{ .src = @src() }, render, null);
}

const fields = [_]Docs.Field{
    .{ .name = "text", .type = "[]const u8", .default = "\"\"", .desc = "The field's placeholder; \"Search\" when empty. It floats up while open." },
    .{ .name = "key_press", .type = "[]const u8", .default = "\"k\"", .desc = "The shortcut's key, pressed with Ctrl, or Cmd on a Mac. Shown in the field." },
    .{ .name = "on_click", .type = "?*const fn () void", .default = "null", .desc = "Called after each click or shortcut, once clicked has flipped. Open or close what the palette is for here." },
    .{ .name = "on_escape", .type = "?*const fn () void", .default = "null", .desc = "Called when Escape closes it." },
    .{ .name = "clicked", .type = "bool", .default = "false", .desc = "Whether it's open. Set it false when what you opened closes." },
};

const behaviours = [_]Docs.Field{
    .{ .name = "Shortcut", .desc = "Ctrl or Cmd with key_press opens and closes it from anywhere on the page; Escape closes it." },
    .{ .name = "Keyboard", .desc = "The field is a button: Tab reaches it, Enter or Space opens it." },
    .{ .name = "Leaving", .desc = "The shortcut stops listening when the field leaves the page." },
};

pub fn render() void {
    Row()
        .width(.percent(100))
        .layout(.top_center)
        .direction(.column)
        .children({
        Hero("command-palette-ui", "A search field with a keyboard shortcut, for opening your app's command menu.");

        Docs.Content().children({
            Docs.exampleLabel("Basic Command Palette");
            Docs.sectionDesc("The field, with its shortcut. Press Ctrl+J, or Cmd+J on a Mac, then Escape.");
            Docs.PreviewCard().height(.px(160)).layout(.center).children({
                BasicCommandPalette.render();
            });
            CodeBox(&hl_basic, "BasicCommandPalette");

            Docs.exampleLabel("Opening a Dialog");
            Docs.sectionDesc("What opens is yours: here a searchable dialog of pages, with Ctrl+I or Cmd+I.");
            Docs.PreviewCard().height(.px(160)).layout(.center).children({
                PaletteDialog.render();
            });
            CodeBox(&hl_dialog, "PaletteDialog");

            Docs.sectionTitle("API Reference");

            Docs.exampleLabel("CommandPalette");
            Docs.sectionDesc("Fill one in and render it where the field goes.");
            CodeBox(&hl_api, "CommandPalette");

            Docs.exampleLabel("Fields");
            Docs.sectionDesc("Set them in the struct, or later.");
            Docs.ApiBox("CommandPalette", &fields);

            Docs.exampleLabel("Behaviour");
            Docs.sectionDesc("What the command palette does for you.");
            Docs.ApiBox("Behaviour", &behaviours);
        });
    });
}
