// examples/Grouped.zig
const Vapor = @import("vapor");
const Opaque = @import("opaque-ui");
const Select = Opaque.Select;

const TimeZone = enum {
    // North America
    est,
    cst,
    mst,
    pst,
    akst,
    hst,
    // Europe & Africa
    gmt,
    cet,
    eet,
    west,
    cat,
    eat,
    // Asia
    msk,
    ist,
    cst_china,
    jst,
    kst,
    wita,
    // Australia & Pacific
    awst,
    acst,
    aest,
    nzst,
    fjt,
    // South America
    art,
    bot,
    brt,
    clt,
    // Universal
    utc,
};

var select: Select(TimeZone) = undefined;

pub fn init() void {
    select = .init("Select Timezone", &.{
        Select(TimeZone).Group{ .title = "North America", .items = &.{
            .{ .value = TimeZone.est, .label = "Eastern Standard Time (EST)" },
            .{ .value = TimeZone.cst, .label = "Central Standard Time (CST)" },
            .{ .value = TimeZone.mst, .label = "Mountain Standard Time (MST)" },
            .{ .value = TimeZone.pst, .label = "Pacific Standard Time (PST)" },
            .{ .value = TimeZone.akst, .label = "Alaska Standard Time (AKST)" },
            .{ .value = TimeZone.hst, .label = "Hawaii Standard Time (HST)" },
        } },
        Select(TimeZone).Group{ .title = "Europe & Africa", .items = &.{
            .{ .value = TimeZone.gmt, .label = "Greenwich Mean Time (GMT)" },
            .{ .value = TimeZone.cet, .label = "Central European Time (CET)" },
            .{ .value = TimeZone.eet, .label = "Eastern European Time (EET)" },
            .{ .value = TimeZone.west, .label = "Western European Summer Time (WEST)" },
            .{ .value = TimeZone.cat, .label = "Central Africa Time (CAT)" },
            .{ .value = TimeZone.eat, .label = "East Africa Time (EAT)" },
        } },
        Select(TimeZone).Group{ .title = "Asia", .items = &.{
            .{ .value = TimeZone.msk, .label = "Moscow Time (MSK)" },
            .{ .value = TimeZone.ist, .label = "India Standard Time (IST)" },
            .{ .value = TimeZone.cst_china, .label = "China Standard Time (CST)" },
            .{ .value = TimeZone.jst, .label = "Japan Standard Time (JST)" },
            .{ .value = TimeZone.kst, .label = "Korea Standard Time (KST)" },
            .{ .value = TimeZone.wita, .label = "Indonesia Central Standard Time (WITA)" },
        } },
        Select(TimeZone).Group{ .title = "Australia & Pacific", .items = &.{
            .{ .value = TimeZone.awst, .label = "Australian Western Standard Time (AWST)" },
            .{ .value = TimeZone.acst, .label = "Australian Central Standard Time (ACST)" },
            .{ .value = TimeZone.aest, .label = "Australian Eastern Standard Time (AEST)" },
            .{ .value = TimeZone.nzst, .label = "New Zealand Standard Time (NZST)" },
            .{ .value = TimeZone.fjt, .label = "Fiji Time (FJT)" },
        } },
        Select(TimeZone).Group{ .title = "South America", .items = &.{
            .{ .value = TimeZone.art, .label = "Argentina Time (ART)" },
            .{ .value = TimeZone.bot, .label = "Bolivia Time (BOT)" },
            .{ .value = TimeZone.brt, .label = "Brasilia Time (BRT)" },
            .{ .value = TimeZone.clt, .label = "Chile Standard Time (CLT)" },
        } },
    });
}

pub fn render() void {
    select.render();
}
