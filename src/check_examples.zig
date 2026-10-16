//! Compile-only gate for the examples the pages show as code (`zig build
//! check`): each is a module of its own, and the pages only @embedFile them,
//! so nothing else makes the compiler look at them. A new example goes in
//! `examples` too.

const std = @import("std");

pub const examples = .{
    @import("routes/ui/accordion/examples/BasicAccordion.zig"),
    @import("routes/ui/accordion/examples/CustomAccordion.zig"),
    @import("routes/ui/alert/examples/AlertExample.zig"),
    @import("routes/ui/carousel/examples/BasicCarousel.zig"),
    @import("routes/ui/carousel/examples/CarouselOptions.zig"),
    @import("routes/ui/combobox/examples/BasicComboBox.zig"),
    @import("routes/ui/datepicker/examples/BasicDatePicker.zig"),
    @import("routes/ui/datepicker/examples/EventDatePicker.zig"),
    @import("routes/ui/dialog/examples/BasicDialog.zig"),
    @import("routes/ui/dialog/examples/CustomDialog.zig"),
    @import("routes/ui/drawer/examples/BasicDrawer.zig"),
    @import("routes/ui/marquee/examples/MarqueeCustom.zig"),
    @import("routes/ui/marquee/examples/MarqueeDown.zig"),
    @import("routes/ui/marquee/examples/MarqueeDualLane.zig"),
    @import("routes/ui/marquee/examples/MarqueeLeft.zig"),
    @import("routes/ui/marquee/examples/MarqueeRight.zig"),
    @import("routes/ui/marquee/examples/MarqueeSpeedNormal.zig"),
    @import("routes/ui/marquee/examples/MarqueeSpeedSlow.zig"),
    @import("routes/ui/marquee/examples/MarqueeUp.zig"),
    @import("routes/ui/radio/examples/BasicRadio.zig"),
    @import("routes/ui/select/examples/BasicSelect.zig"),
    @import("routes/ui/select/examples/CustomTrigger.zig"),
    @import("routes/ui/select/examples/Detached.zig"),
    @import("routes/ui/select/examples/Grouped.zig"),
    @import("routes/ui/select/examples/WithIcons.zig"),
    @import("routes/ui/slider/examples/BasicSlider.zig"),
    @import("routes/ui/table/examples/BasicTable.zig"),
    @import("routes/ui/table/examples/Filterable.zig"),
    @import("routes/ui/table/examples/Sortable.zig"),
    @import("routes/ui/table/examples/Virtual.zig"),
    @import("routes/ui/table/examples/WithActions.zig"),
    @import("routes/ui/tooltip/examples/TooltipCustom.zig"),
    @import("routes/ui/tooltip/examples/TooltipCustomTrigger.zig"),
};

/// Takes a reference to every public declaration of `T`.
fn refAll(comptime T: type) void {
    inline for (comptime std.meta.declarations(T)) |decl| {
        _ = &@field(T, decl.name);
    }
}

export fn __vapor_ui_check_examples() void {
    inline for (examples) |Example| refAll(Example);
}
