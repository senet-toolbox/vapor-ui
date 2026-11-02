const std = @import("std");
const Vapor = @import("vapor");
const Hero = @import("../../../../components/Hero.zig").Hero;
const Text = Vapor.Text;
const Row = Vapor.Row;
const Stack = Vapor.Stack;
const Opaque = @import("opaque-ui");
const Accordion = Opaque.Accordion;
const Vaporize = @import("vaporize");
const SyntaxHighlighter = Vaporize.SyntaxHighlighter;
const Icon = Vapor.Icon;
const Button = Opaque.Button;
const CodeBox = @import("../CodeBox.zig").CodeBox;
const Docs = @import("../Docs.zig");
// The page shows these files' code and renders them, so the code you read
// is the code that runs.
const BasicAccordion = @import("examples/BasicAccordion.zig");
const CustomAccordion = @import("examples/CustomAccordion.zig");

// ============================================================================
// SYNTAX HIGHLIGHTERS
// ============================================================================

var hl_basic: SyntaxHighlighter = undefined;
var hl_custom_render: SyntaxHighlighter = undefined;
var hl_api: SyntaxHighlighter = undefined;

pub fn init() void {
    hl_basic = Docs.highlighter(@embedFile("examples/BasicAccordion.zig"));
    hl_custom_render = Docs.highlighter(@embedFile("examples/CustomAccordion.zig"));
    hl_api = Docs.highlighter(
        \\const Accordion = @import("opaque-ui").Accordion;
        \\
        \\// Keeps the items, which keep whether each is open.
        \\pub fn init(items: []AccordionItem) Accordion
        \\// Draws every item, top to bottom.
        \\pub fn render(accordion: *Accordion) void
        \\
        \\// The items are a global var: each toggle writes into its item,
        \\// so they must outlive the render, and can't be const.
        \\var items = [_]Accordion.AccordionItem{
        \\    .{
        \\        .title = "Shipping",
        \\        .description = "Free over $50.",
        \\        .trigger = Header,
        \\        .content = Panel,
        \\    },
        \\};
        \\
        \\// Your page's render function.
        \\pub fn render() void {
        \\    var accordion = Accordion.init(&items);
        \\    accordion.render();
        \\}
    );

    Vapor.Page(.{ .src = @src() }, render, null);
}

const item_fields = [_]Docs.Field{
    .{ .name = "title", .type = "[]const u8", .desc = "The item's name, for your trigger function to draw. The accordion doesn't draw it." },
    .{ .name = "description", .type = "[]const u8", .desc = "The item's text, for your content function to draw." },
    .{ .name = "is_open", .type = "bool", .default = "false", .desc = "Whether the panel is open. Set it to start open; the accordion flips it on each click." },
    .{ .name = "trigger", .type = "?*const fn (*AccordionItem) void", .default = "null", .desc = "Draws the header, inside the button that toggles the item. The chevron is added after it." },
    .{ .name = "content", .type = "?*const fn (*AccordionItem) void", .default = "null", .desc = "Draws the panel. Any content, of any height; buttons in it work as usual." },
};

const behaviours = [_]Docs.Field{
    .{ .name = "Opening", .desc = "Each item opens and closes on its own; any number can be open at once." },
    .{ .name = "Keyboard", .desc = "Each header is a button: Tab reaches it, Enter or Space toggles it." },
    .{ .name = "Screen readers", .desc = "The header reports aria-expanded. A closed panel is hidden from screen readers and the tab order." },
    .{ .name = "Animation", .desc = "A panel grows to its content's height, whatever it is, in 150ms; the header stays still." },
};

// ============================================================================
// MAIN RENDER
// ============================================================================

pub fn render() void {
    Row()
        .width(.percent(100))
        .layout(.top_center)
        .direction(.column)
        .children({
        Hero("accordion-ui", "Highly customizable, accessible collapsible sections for organizing content.");

        Docs.Content().children({
            Docs.exampleLabel("Basic Accordion");
            Docs.sectionDesc("Each item has a title and some text. Two small functions of yours draw its header and its panel.");
            Docs.PreviewCard().children({
                BasicAccordion.render();
            });
            CodeBox(&hl_basic, "BasicAccordion");

            Docs.exampleLabel("Custom Rendering");
            Docs.sectionDesc("Headers and panels are whatever your functions draw: here an icon in each header, and buttons in each panel.");
            Docs.PreviewCard().children({
                CustomAccordion.render();
            });
            CodeBox(&hl_custom_render, "CustomAccordion");

            Docs.sectionTitle("API Reference");

            Docs.exampleLabel("Accordion");
            Docs.sectionDesc("Make one from your items and render it where the accordion goes.");
            CodeBox(&hl_api, "Accordion");

            Docs.exampleLabel("AccordionItem");
            Docs.sectionDesc("One per section.");
            Docs.ApiBox("AccordionItem", &item_fields);

            Docs.exampleLabel("Behaviour");
            Docs.sectionDesc("What the accordion does for you.");
            Docs.ApiBox("Behaviour", &behaviours);
        });
    });
}
