const Vapor = @import("vapor");
const Hero = @import("../../../../components/Hero.zig").Hero;
const Row = Vapor.Row;
const SyntaxHighlighter = @import("vaporize").SyntaxHighlighter;
const CodeBox = @import("../CodeBox.zig").CodeBox;
const Docs = @import("../Docs.zig");
// Rendered and shown as code: what you read is what runs.
const BasicCodeInput = @import("examples/BasicCodeInput.zig");
const LetterCodeInput = @import("examples/LetterCodeInput.zig");

var hl_BasicCodeInput: SyntaxHighlighter = undefined;
var hl_LetterCodeInput: SyntaxHighlighter = undefined;
var hl_api: SyntaxHighlighter = undefined;

pub fn init() void {
    hl_BasicCodeInput = Docs.highlighter(@embedFile("examples/BasicCodeInput.zig"));
    hl_LetterCodeInput = Docs.highlighter(@embedFile("examples/LetterCodeInput.zig"));
    hl_api = Docs.highlighter(
        \\const CodeInput = @import("opaque-ui").CodeInput;
        \\
        \\// code must outlive the render: a module-level var.
        \\pub fn render(code: *[]const u8, options: Options) void
        \\
        \\// What it keeps of a typed or pasted code.
        \\pub fn clean(code: []const u8, numeric: bool, length: usize, buf: []u8) []const u8
    );
    Vapor.Page(.{ .src = @src() }, render, null);
}

const options = [_]Docs.Field{
    .{ .name = "label", .type = "[]const u8", .default = "\"Verification code\"", .desc = "Names the field for screen readers." },
    .{ .name = "length", .type = "u8", .default = "6", .desc = "How many characters the code has." },
    .{ .name = "numeric", .type = "bool", .default = "true", .desc = "Digits only, on a phone's number pad; false takes letters and digits." },
    .{ .name = "on_complete", .type = "?*const fn ([]const u8) void", .default = "null", .desc = "Called with the code once every box is filled." },
};

const settings = [_]Docs.Field{
    .{ .name = "border_color", .type = "Color", .desc = "The boxes' borders; the box the next character goes in takes text_color." },
    .{ .name = "box_size", .type = "f32", .default = "44", .desc = "A box's width, in pixels; its height is 8 more." },
};

const behaviours = [_]Docs.Field{
    .{ .name = "One field", .desc = "A single field lies over the boxes, so pasting, Backspace and a phone filling the code from a text message all just work." },
    .{ .name = "Cleaning", .desc = "A pasted 123 456 becomes 123456; anything past length, or not a digit when numeric, is dropped." },
    .{ .name = "Screen readers", .desc = "One field named by label; the boxes are hidden from them." },
};

pub fn render() void {
    Row()
        .width(.percent(100))
        .layout(.top_center)
        .direction(.column)
        .children({
        Hero("codeinput-ui", "A one-time code, one character in each box.");

        Docs.Content().children({
            Docs.exampleLabel("Basic");
            Docs.sectionDesc("Six digits, on a phone's number pad; on_complete runs once all are in.");
            Docs.PreviewCard().layout(.center).children({
                BasicCodeInput.render();
            });
            CodeBox(&hl_BasicCodeInput, "BasicCodeInput");

            Docs.exampleLabel("Letters and digits");
            Docs.sectionDesc("Four characters, numeric = false.");
            Docs.PreviewCard().layout(.center).children({
                LetterCodeInput.render();
            });
            CodeBox(&hl_LetterCodeInput, "LetterCodeInput");

            Docs.sectionTitle("API Reference");

            Docs.exampleLabel("CodeInput");
            CodeBox(&hl_api, "CodeInput");

            Docs.exampleLabel("Options");
            Docs.ApiBox("Options", &options);

            Docs.exampleLabel("Settings");
            Docs.sectionDesc("CodeInput globals; set them once.");
            Docs.ApiBox("CodeInput", &settings);

            Docs.exampleLabel("Behaviour");
            Docs.sectionDesc("What the code input does for you.");
            Docs.ApiBox("Behaviour", &behaviours);
        });
    });
}
