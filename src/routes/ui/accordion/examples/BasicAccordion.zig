const Vapor = @import("vapor");
const Text = Vapor.Text;
const Accordion = @import("opaque-ui").Accordion;

// ============================================================================
// MAIN RENDER
// ============================================================================

var items = [_]Accordion.AccordionItem{
    .{
        .title = "Product Information",
        .description =
        \\Our flagship product combines cutting-edge technology with 
        \\sleek design. Built with premium materials, it offers 
        \\unparalleled performance and reliability.
        ,
        .trigger = AccordionTrigger,
        .content = AccordionContent,
    },
    .{
        .title = "Return Policy",
        .description =
        \\We stand behind our products with a 30-day return policy. 
        \\If you're not satisfied, simply return the item in its 
        \\original condition for a full refund.
        ,
        .trigger = AccordionTrigger,
        .content = AccordionContent,
    },
};

pub fn render() void {
    var basic_accordion = Accordion.init(&items);
    basic_accordion.render();
}

fn AccordionTrigger(item: *Accordion.AccordionItem) void {
    Text(item.title)
        .fontFamily("Montserrat")
        .font(16, 500, .palette(.text_color))
        .end();
}

fn AccordionContent(item: *Accordion.AccordionItem) void {
    Text(item.description)
        .font(14, 300, .palette(.text_color))
        .end();
}
