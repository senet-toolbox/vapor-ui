//! Compile-only gate for the examples the pages show as code (`zig build
//! check`): each is a module of its own, and the pages only @embedFile them,
//! so nothing else makes the compiler look at them. A new example goes in
//! `examples` too.

const std = @import("std");

pub const examples = .{
    @import("routes/ui/components/accordion/examples/BasicAccordion.zig"),
    @import("routes/ui/components/accordion/examples/CustomAccordion.zig"),
    @import("routes/ui/components/alert/examples/AlertExample.zig"),
    @import("routes/ui/components/carousel/examples/BasicCarousel.zig"),
    @import("routes/ui/components/carousel/examples/CarouselOptions.zig"),
    @import("routes/ui/components/combobox/examples/BasicComboBox.zig"),
    @import("routes/ui/components/datepicker/examples/BasicDatePicker.zig"),
    @import("routes/ui/components/datepicker/examples/EventDatePicker.zig"),
    @import("routes/ui/components/dialog/examples/BasicDialog.zig"),
    @import("routes/ui/components/dialog/examples/CustomDialog.zig"),
    @import("routes/ui/components/drawer/examples/BasicDrawer.zig"),
    @import("routes/ui/components/marquee/examples/MarqueeCustom.zig"),
    @import("routes/ui/components/marquee/examples/MarqueeDown.zig"),
    @import("routes/ui/components/marquee/examples/MarqueeDualLane.zig"),
    @import("routes/ui/components/marquee/examples/MarqueeLeft.zig"),
    @import("routes/ui/components/marquee/examples/MarqueeRight.zig"),
    @import("routes/ui/components/marquee/examples/MarqueeSpeedNormal.zig"),
    @import("routes/ui/components/marquee/examples/MarqueeSpeedSlow.zig"),
    @import("routes/ui/components/marquee/examples/MarqueeUp.zig"),
    @import("routes/ui/components/radio/examples/BasicRadio.zig"),
    @import("routes/ui/components/select/examples/BasicSelect.zig"),
    @import("routes/ui/components/select/examples/CustomTrigger.zig"),
    @import("routes/ui/components/select/examples/Detached.zig"),
    @import("routes/ui/components/select/examples/Grouped.zig"),
    @import("routes/ui/components/select/examples/WithIcons.zig"),
    @import("routes/ui/components/slider/examples/BasicSlider.zig"),
    @import("routes/ui/components/table/examples/BasicTable.zig"),
    @import("routes/ui/components/table/examples/Filterable.zig"),
    @import("routes/ui/components/table/examples/Sortable.zig"),
    @import("routes/ui/components/table/examples/Virtual.zig"),
    @import("routes/ui/components/table/examples/WithActions.zig"),
    @import("routes/ui/components/tabs/examples/BasicTabs.zig"),
    @import("routes/ui/components/tabs/examples/ControlledTabs.zig"),
    @import("routes/ui/components/tabs/examples/CustomTabs.zig"),
    @import("routes/ui/components/tooltip/examples/TooltipCustom.zig"),
    @import("routes/ui/components/tooltip/examples/TooltipCustomTrigger.zig"),
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
