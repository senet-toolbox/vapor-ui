const std = @import("std");
const Vapor = @import("vapor");
const Row = Vapor.Row;
const Text = Vapor.Text;
const Svg = @import("svg.zig").Svg;
const LinearScale = @import("scales/linear.zig").LinearScale;
const BandScale = @import("scales/band.zig").BandScale;
const path_util = @import("util/path.zig");
const color_util = @import("util/color.zig");
const ScaleConfig = @import("scales/scale.zig").ScaleConfig;
const Scale = @import("scales/scale.zig").Scale;
const LogScale = @import("scales/log.zig").LogScale;
const Writer = Vapor.Writer;

pub const ElementId = struct {
    series_index: u16,
    point_index: ?u16 = null,
    element_type: ElementType,

    pub const ElementType = enum(u8) {
        line_path,
        area_path,
        dot,
        bar,
        legend,
        background,
    };

    pub fn toString(self: ElementId, buf: []u8) ![]u8 {
        if (self.point_index) |point_index| {
            return std.fmt.bufPrint(buf, "chart-{d}-{d}-{s}", .{
                self.series_index,
                point_index,
                @tagName(self.element_type),
            });
        }
        return std.fmt.bufPrint(buf, "chart-{d}-{s}", .{
            self.series_index,
            @tagName(self.element_type),
        });
    }
};

// Track rendered state for diffing
pub const RenderedElement = struct {
    id: ElementId,
    // Store the attributes that can change
    attrs: union(enum) {
        circle: struct { cx: f64, cy: f64, r: f64, fill: ?Vapor.Types.Color = null },
        rect: struct { x: f64, y: f64, width: f64, height: f64, fill: ?Vapor.Types.Color = null },
        path: struct {
            d: []const u8,
            stroke: ?Vapor.Types.Color = null,
            stroke_width: ?f32 = null,
            fill: ?Vapor.Types.Color = null,
        },
    },
};

const TooltipLegend = struct {
    title: []const u8 = "",
    color: Vapor.Types.Color = .hex("#000000"),
    background: Vapor.Types.Color = .hex("#ffffff"),
    value: []const u8 = "",
};

pub const Tooltip = struct {
    top: f32 = 0,
    left: f32 = 0,
    binded: Vapor.Binded = .{},
    hide: bool = false,
    x_label: []const u8 = "",
    y_label: []const u8 = "",
    value: []TooltipLegend = &.{},
};

const Bounds = struct {
    offset_x: f32 = 0,
    offset_y: f32 = 0,
    x: f32 = 0,
    y: f32 = 0,
    width: f32 = 0,
    height: f32 = 0,
};

pub const Chart = struct {
    allocator: std.mem.Allocator,
    config: Config,
    series: std.array_list.Managed(Series),
    x_axis_config: ?AxisConfig = null,
    y_axis_config: ?AxisConfig = null,
    legend_config: ?LegendConfig = null,
    current_chart_svg: ?[]const u8 = null,
    container: Vapor.Binded = .{},

    old_x: f64 = 0,
    old_y: f64 = 0,

    // NEW: Track what we've rendered
    rendered_elements: std.array_list.Managed(RenderedElement),
    old_rendered_elements: std.array_list.Managed(RenderedElement),

    // NEW: Platform abstraction
    platform: Platform,
    tooltip: ?Tooltip = null,

    bounds: Bounds = .{},

    x_scale: ?Scale = null,
    y_scale: ?Scale = null,
    has_data: bool = false,

    pub const HoveredPoint = struct {
        series_index: usize,
        point_index: usize,
        data_x: f64,
        data_y: f64,
        screen_x: f32,
        screen_y: f32,
        series_name: []const u8,
        series_color: Vapor.Types.Color,
    };

    pub const HoverResult = struct {
        points: []HoveredPoint,
        screen_x: f32, // For drawing vertical crosshair
    };

    pub const Platform = union(enum) {
        browser: BrowserPlatform,
        // Future: native: NativePlatform,
    };

    pub const BrowserPlatform = struct {
        pub fn setAttribute(_: BrowserPlatform, id: []const u8, key: []const u8, value: []const u8) void {
            Vapor.Wasm.setAttributeWasm(id.ptr, id.len, key.ptr, key.len, value.ptr, value.len);
        }
    };

    // ============ Types ============

    pub const Config = struct {
        width: u32 = 600,
        height: u32 = 400,
        margin: Margin = .{},
        background: ?Vapor.Types.Color = null,
        palette: color_util.Palette = color_util.palettes.category10,
    };

    pub const Margin = struct {
        top: u32 = 20,
        right: u32 = 20,
        bottom: u32 = 40,
        left: u32 = 50,
    };

    pub const SeriesType = enum {
        line,
        line_smooth,
        bar,
        area,
        area_smooth,
        scatter,
    };

    pub const Series = struct {
        type: SeriesType,
        name: []const u8,
        data: []const Point,
        options: SeriesOptions,
    };

    pub const Point = struct {
        x: f64,
        y: f64,
        label: ?[]const u8 = null,
    };

    pub const SeriesOptions = struct {
        color: ?Vapor.Types.Color = null,
        stroke_width: f32 = 2,
        show_dots: bool = true,
        dot_radius: u32 = 4,
        fill_opacity: f64 = 0.3,
        bar_radius: f64 = 0,
    };

    pub const AxisConfig = struct {
        label: ?[]const u8 = null,
        tick_count: u32 = 5,
        format: ?[]const u8 = null,
        grid: bool = true,
        scale: ScaleConfig = .{}, // ADD THIS
    };

    pub const LegendConfig = struct {
        position: Position = .top_right,
        pub const Position = enum { top_left, top_right, bottom_left, bottom_right };
    };

    // ============ Lifecycle ============

    pub fn init(allocator: std.mem.Allocator, config: Config) Chart {
        return .{
            .allocator = allocator,
            .config = config,
            .series = std.array_list.Managed(Series).init(allocator),
            .rendered_elements = std.array_list.Managed(RenderedElement).init(allocator),
            .old_rendered_elements = std.array_list.Managed(RenderedElement).init(allocator),
            .platform = Platform.browser,
            .tooltip = Tooltip{},
            .bounds = calculateBounds(config),
        };
    }

    pub fn deinit(self: *Chart) void {
        self.series.deinit();
    }

    fn calculateBounds(config: Config) Bounds {
        var bounds = Bounds{};

        bounds.x = @floatFromInt(config.margin.left);
        bounds.y = @floatFromInt(config.margin.top);
        bounds.width = @floatFromInt(config.width - config.margin.left - config.margin.right);
        bounds.height = @floatFromInt(config.height - config.margin.top - config.margin.bottom);
        return bounds;
    }

    // ============ Builder Methods ============

    pub fn addSeries(
        self: *Chart,
        series_type: SeriesType,
        name: []const u8,
        data: []const Point,
        options: SeriesOptions,
    ) !void {
        try self.series.append(.{
            .type = series_type,
            .name = name,
            .data = data,
            .options = options,
        });
    }

    pub const SeriesData = struct {
        name: []const u8,
        data: []const Point,
    };

    pub fn updateSeries(self: *Chart, series: []const SeriesData) void {
        const old_svg = self.current_chart_svg;
        const items = self.rendered_elements.toOwnedSlice() catch unreachable;
        self.old_rendered_elements.appendSlice(items) catch unreachable;
        self.rendered_elements.clearRetainingCapacity();

        for (series) |new_s| {
            for (self.series.items) |*s| {
                if (std.mem.eql(u8, s.name, new_s.name)) {
                    s.data = new_s.data;
                }
            }
        }

        self.build() catch unreachable;

        if (self.old_rendered_elements.items.len != self.rendered_elements.items.len) {
            return;
        }

        self.current_chart_svg = old_svg;
        self.update() catch unreachable;
    }

    pub fn updateFullSeries(self: *Chart, series: []const Series) void {
        const old_svg = self.current_chart_svg;
        const items = self.rendered_elements.toOwnedSlice() catch unreachable;
        self.old_rendered_elements.appendSlice(items) catch unreachable;
        self.rendered_elements.clearRetainingCapacity();

        for (series) |new_s| {
            for (self.series.items) |*s| {
                if (std.mem.eql(u8, s.name, new_s.name)) {
                    s.data = new_s.data;
                    s.options = new_s.options;
                }
            }
        }

        self.build() catch unreachable;

        if (self.old_rendered_elements.items.len != self.rendered_elements.items.len) {
            return;
        }

        self.current_chart_svg = old_svg;
        self.update() catch unreachable;
    }

    // Called after data changes
    pub fn update(self: *Chart) !void {
        // 1. Calculate new positions (reuse your existing scale logic)
        const new_elements = self.rendered_elements;

        // 2. Diff against rendered_elements
        for (new_elements.items, 0..) |new_el, i| {
            // Element exists - update only changed attributes
            if (i < self.old_rendered_elements.items.len - 1) {
                const old_el = self.old_rendered_elements.items[i];
                try self.emitAttributeUpdates(old_el, new_el);
            }
        }
        self.old_rendered_elements.clearRetainingCapacity();
    }

    fn emitAttributeUpdates(self: *Chart, old: RenderedElement, new: RenderedElement) !void {
        var id_buf: [64]u8 = undefined;
        const id = try new.id.toString(&id_buf);

        switch (new.attrs) {
            .circle => |c| {
                const old_c = old.attrs.circle;
                if (c.cx != old_c.cx) {
                    var buf: [32]u8 = undefined;
                    const val = try std.fmt.bufPrint(&buf, "{d:.2}", .{c.cx});
                    self.platform.browser.setAttribute(id, "cx", val);
                }
                if (c.cy != old_c.cy) {
                    var buf: [32]u8 = undefined;
                    const val = try std.fmt.bufPrint(&buf, "{d:.2}", .{c.cy});
                    self.platform.browser.setAttribute(id, "cy", val);
                }
                if (c.r != old_c.r) {
                    var buf: [32]u8 = undefined;
                    const val = try std.fmt.bufPrint(&buf, "{d:.2}", .{c.r});
                    self.platform.browser.setAttribute(id, "r", val);
                }
                // if (c.fill) |f| if (old.attrs.circle.fill) |old_f| {
                //     if (!std.mem.eql(u8, f, old_f)) {
                //         self.platform.browser.setAttribute(id, "fill", f);
                //     }
                // };
            },
            .path => |p| {
                self.platform.browser.setAttribute(id, "d", p.d);
                self.allocator.free(old.attrs.path.d);
                if (p.stroke) |s| {
                    self.platform.browser.setAttribute(id, "stroke", Svg.convertColor(s));
                }
                if (p.stroke_width) |sw| {
                    var buf: [32]u8 = undefined;
                    const val = try std.fmt.bufPrint(&buf, "{d:.2}", .{sw});
                    self.platform.browser.setAttribute(id, "stroke-width", val);
                }
                if (p.fill) |f| {
                    self.platform.browser.setAttribute(id, "fill", Svg.convertColor(f));
                }
            },
            .rect => |r| {
                const old_r = old.attrs.rect;
                if (r.x != old_r.x) {
                    var buf: [32]u8 = undefined;
                    const val = try std.fmt.bufPrint(&buf, "{d:.2}", .{r.x});
                    self.platform.browser.setAttribute(id, "x", val);
                }
                if (r.y != old_r.y) {
                    var buf: [32]u8 = undefined;
                    const val = try std.fmt.bufPrint(&buf, "{d:.2}", .{r.y});
                    self.platform.browser.setAttribute(id, "y", val);
                }
                if (r.width != old_r.width) {
                    var buf: [32]u8 = undefined;
                    const val = try std.fmt.bufPrint(&buf, "{d:.2}", .{r.width});
                    self.platform.browser.setAttribute(id, "width", val);
                }
                if (r.height != old_r.height) {
                    var buf: [32]u8 = undefined;
                    const val = try std.fmt.bufPrint(&buf, "{d:.2}", .{r.height});
                    self.platform.browser.setAttribute(id, "height", val);
                }
                if (r.fill) |f| {
                    self.platform.browser.setAttribute(id, "fill", Svg.convertColor(f));
                }
            },
        }
    }

    pub fn xAxis(self: *Chart, config: AxisConfig) void {
        if (self.tooltip) |*tooltip| {
            tooltip.x_label = config.label orelse "";
        }
        self.x_axis_config = config;
    }

    pub fn yAxis(self: *Chart, config: AxisConfig) void {
        if (self.tooltip) |*tooltip| {
            tooltip.y_label = config.label orelse "";
        }
        self.y_axis_config = config;
    }

    pub fn legend(self: *Chart, config: LegendConfig) void {
        self.legend_config = config;
    }

    // ============ Building ============
    pub fn build(self: *Chart) !void {
        if (self.series.items.len == 0) return;
        self.has_data = true;
        var svg = try Svg.initCapacity(self.allocator, 8192);
        errdefer svg.deinit();

        const m = self.config.margin;
        const chart_width: f64 = @floatFromInt(self.config.width - m.left - m.right);
        const chart_height: f64 = @floatFromInt(self.config.height - m.top - m.bottom);

        // Check if we have bar charts (need different x scaling)
        var has_bars = false;
        var max_points_in_series: usize = 0;
        for (self.series.items) |s| {
            if (s.type == .bar) {
                has_bars = true;
            }
            max_points_in_series = @max(max_points_in_series, s.data.len);
        }

        // Calculate scales from all series data
        var all_x = std.array_list.Managed(f64).init(self.allocator);
        defer all_x.deinit();
        var all_y = std.array_list.Managed(f64).init(self.allocator);
        defer all_y.deinit();

        for (self.series.items) |s| {
            for (s.data) |p| {
                try all_x.append(p.x);
                try all_y.append(p.y);
            }
        }

        // ============ X SCALE ============
        const x_config = if (self.x_axis_config) |c| c.scale else ScaleConfig{};

        const x_scale: Scale = blk: {
            var domain: [2]f64 = switch (x_config.domain) {
                .auto => .{ findMin(all_x.items), findMax(all_x.items) },
                .auto_zero => .{ @min(0, findMin(all_x.items)), findMax(all_x.items) },
                .manual => |d| d,
            };

            // For bar charts, expand domain so bars don't overflow
            if (has_bars and max_points_in_series > 1) {
                const span = domain[1] - domain[0];
                const step = span / @as(f64, @floatFromInt(max_points_in_series - 1));
                domain[0] -= step * 0.5;
                domain[1] += step * 0.5;
            }

            // X scale: domain -> { 0, chart_width }
            switch (x_config.type) {
                .linear => {
                    var s = LinearScale.init(domain, .{ 0, chart_width });
                    // Don't apply nice/padding to x for bar charts - messes up alignment
                    if (!has_bars) {
                        if (x_config.nice) s = s.niced();
                        if (x_config.padding > 0) s = s.padded(x_config.padding);
                    }
                    break :blk .{ .linear = s };
                },
                .log => {
                    break :blk .{ .log = LogScale.init(domain, .{ 0, chart_width }) };
                },
                .sqrt => {
                    break :blk .{ .linear = LinearScale.init(domain, .{ 0, chart_width }) };
                },
            }
        };

        // ============ Y SCALE ============
        const y_config = if (self.y_axis_config) |c| c.scale else ScaleConfig{};

        const y_scale: Scale = blk: {
            var domain: [2]f64 = switch (y_config.domain) {
                .auto => .{ findMin(all_y.items), findMax(all_y.items) },
                .auto_zero => .{ @min(0, findMin(all_y.items)), findMax(all_y.items) },
                .manual => |d| d,
            };

            // For bar charts, always include 0
            if (has_bars) {
                domain[0] = @min(0, domain[0]);
            }

            // Y scale: domain -> { chart_height, 0 } (inverted because SVG y goes down)
            switch (y_config.type) {
                .linear => {
                    var s = LinearScale.init(domain, .{ chart_height, 0 });
                    if (y_config.nice) s = s.niced();
                    if (y_config.padding > 0) s = s.padded(y_config.padding);
                    break :blk .{ .linear = s };
                },
                .log => {
                    break :blk .{ .log = LogScale.init(domain, .{ chart_height, 0 }) };
                },
                .sqrt => {
                    break :blk .{ .linear = LinearScale.init(domain, .{ chart_height, 0 }) };
                },
            }
        };

        for (self.series.items) |s| {
            for (s.data) |p| {
                try all_x.append(p.x);
                try all_y.append(p.y);
            }
        }

        // SVG Header
        try svg.openSvg(self.config.width, self.config.height);

        // Styles
        try svg.style(
            \\.axis { stroke: #333; stroke-width: 1; }
            \\.axis-label { font-size: 12px; fill: #333; }
            \\.grid { stroke: #e5e5e5; stroke-width: 1; }
            \\.tick-label { font-size: 10px; fill: #666; }
            \\.legend-text { font-size: 11px; fill: #333; }
            \\.series-line { fill: none; stroke-linecap: round; stroke-linejoin: round; transition: stroke 200ms ease-in-out, stroke-width 200ms ease-in-out, fill 200ms ease-in-out, cy 200ms ease-in-out, cx 200ms ease-in-out, d 200ms ease-in-out; }
            \\.series-area { stroke: none; }
            \\.series-dot { stroke: white; stroke-width: 1.5; transition: stroke 200ms ease-in-out, stroke-width 200ms ease-in-out, fill 200ms ease-in-out, cy 200ms ease-in-out, cx 200ms ease-in-out, d 200ms ease-in-out;  }
            \\.series-bar { transition: stroke 200ms ease-in-out, stroke-width 200ms ease-in-out, fill 200ms ease-in-out, y 200ms ease-in-out, x 200ms ease-in-out, height 200ms ease-in-out, width 200ms ease-in-out; }
        );

        // Background
        if (self.config.background) |bg| {
            try svg.rect(0, 0, @floatFromInt(self.config.width), @floatFromInt(self.config.height), .{
                .id = "chart-background",
                .fill = bg,
            });
        }

        try self.rendered_elements.append(.{
            .id = .{ .element_type = .background, .series_index = 0 },
            .attrs = .{ .rect = .{
                .x = 0,
                .y = 0,
                .width = @floatFromInt(self.config.width),
                .height = @floatFromInt(self.config.height),
                .fill = self.config.background,
            } },
        });

        // Chart area group
        var transform_buf: [64]u8 = undefined;
        const transform = try std.fmt.bufPrint(&transform_buf, "translate({d},{d})", .{ m.left, m.top });
        try svg.openGroup("chart-area", transform);

        // Grid
        if (self.y_axis_config) |axis| {
            if (axis.grid) {
                try self.renderGrid(&svg, y_scale, chart_width, chart_height);
            }
        }

        // Render each series
        for (self.series.items, 0..) |s, i| {
            const series_color = s.options.color orelse Vapor.Types.Color.hex(self.config.palette.get(i));
            try self.renderSeries(&svg, s, i, x_scale, y_scale, series_color);
        }

        // Axes
        if (self.x_axis_config) |_| {
            try self.renderAxes(&svg, x_scale, y_scale, chart_width, chart_height);
        }

        try svg.closeGroup();

        // Legend
        if (self.legend_config) |_| {
            try self.renderLegend(&svg);
        }

        try svg.closeSvg();

        self.x_scale = x_scale;
        self.y_scale = y_scale;

        if (self.tooltip) |*tooltip| {
            tooltip.value = self.allocator.alloc(TooltipLegend, self.series.items.len) catch unreachable;
            for (self.series.items, 0..) |s, i| {
                tooltip.value[i].title = s.name;
                tooltip.value[i].color = s.options.color orelse Vapor.Types.Color.hex(self.config.palette.get(i));
                tooltip.value[i].value = "";
                tooltip.value[i].background = s.options.color orelse Vapor.Types.Color.hex(self.config.palette.get(i));
            }
        }

        self.current_chart_svg = try svg.toOwnedSlice();
    }

    fn renderGrid(self: *Chart, svg: *Svg, y_scale: Scale, width: f64, _: f64) !void {
        const tick_count = if (self.y_axis_config) |c| c.tick_count else 5;
        const ticks = try y_scale.ticks(tick_count, self.allocator);
        defer self.allocator.free(ticks);

        for (ticks) |tick| {
            const y = y_scale.scale(tick);
            var id_buf: [64]u8 = undefined;
            const id = try std.fmt.bufPrint(&id_buf, "chart-grid-{d}", .{tick});
            try svg.line(0, y, width, y, .{ .id = id, .class = "grid" });
        }
    }

    fn renderSeries(self: *Chart, svg: *Svg, s: Series, series_index: usize, x_scale: Scale, y_scale: Scale, series_color: Vapor.Types.Color) !void {
        switch (s.type) {
            .line => try self.renderLine(svg, s, series_index, x_scale, y_scale, series_color, false),
            .line_smooth => try self.renderLine(svg, s, series_index, x_scale, y_scale, series_color, true),
            .area => try self.renderArea(svg, s, series_index, x_scale, y_scale, series_color, false),
            .area_smooth => try self.renderArea(svg, s, series_index, x_scale, y_scale, series_color, true),
            .bar => try self.renderBars(svg, s, series_index, x_scale, y_scale, series_color),
            .scatter => try self.renderScatter(svg, s, series_index, x_scale, y_scale, series_color),
        }
    }

    fn renderLine(self: *Chart, svg: *Svg, s: Series, series_index: usize, x_scale: Scale, y_scale: Scale, series_color: Vapor.Types.Color, smooth: bool) !void {
        if (s.data.len == 0) return;

        // Build points array
        var points = try self.allocator.alloc([2]f64, s.data.len);
        defer self.allocator.free(points);

        for (s.data, 0..) |p, i| {
            points[i] = .{ x_scale.scale(p.x), y_scale.scale(p.y) };
        }

        // Generate path
        const path_d = if (smooth)
            try path_util.smoothLine(self.allocator, points, 1.0)
        else
            try self.straightLine(points);
        // defer self.allocator.free(path_d);

        var path_id_buf: [64]u8 = undefined;
        const path_id = try std.fmt.bufPrint(&path_id_buf, "chart-{d}-line_path", .{series_index});
        try svg.path(path_d, .{
            .id = path_id,
            .class = "series-line",
            .stroke = series_color,
            .stroke_width = s.options.stroke_width,
        });

        // Track for future updates
        try self.rendered_elements.append(.{
            .id = .{ .series_index = @intCast(series_index), .element_type = .line_path },
            .attrs = .{ .path = .{ .d = path_d, .stroke = series_color, .stroke_width = s.options.stroke_width } },
        });

        // Dots
        if (s.options.show_dots) {
            for (points, 0..) |pt, point_index| {
                const x = pt[0];
                const y = pt[1];

                var id_buf: [64]u8 = undefined;
                const id = try std.fmt.bufPrint(&id_buf, "chart-{d}-{d}-dot", .{ series_index, point_index });

                try svg.circle(pt[0], pt[1], @floatFromInt(s.options.dot_radius), .{
                    .id = id,
                    .class = "series-dot",
                    .fill = series_color,
                });
                // Track for future updates
                try self.rendered_elements.append(.{
                    .id = .{ .series_index = @intCast(series_index), .point_index = @intCast(point_index), .element_type = .dot },
                    .attrs = .{ .circle = .{ .cx = x, .cy = y, .r = @floatFromInt(s.options.dot_radius), .fill = series_color } },
                });
            }
        }
    }

    fn renderArea(self: *Chart, svg: *Svg, s: Series, series_index: usize, x_scale: Scale, y_scale: Scale, series_color: Vapor.Types.Color, smooth: bool) !void {
        if (s.data.len == 0) return;

        var points = try self.allocator.alloc([2]f64, s.data.len);
        defer self.allocator.free(points);

        for (s.data, 0..) |p, i| {
            points[i] = .{ x_scale.scale(p.x), y_scale.scale(p.y) };
        }

        const baseline = y_scale.scale(y_scale.domainMin());

        // Build area path
        var path = path_util.PathBuilder.init(self.allocator);
        defer path.deinit();

        // Line part
        const line_d = if (smooth)
            try path_util.smoothLine(self.allocator, points, 1.0)
        else
            try self.straightLine(points);
        defer self.allocator.free(line_d);

        try path.buffer.appendSlice(line_d);
        try path.lineTo(points[points.len - 1][0], baseline);
        try path.lineTo(points[0][0], baseline);
        try path.closePath();

        // Render with opacity

        const fill_with_opacity = series_color;

        var path_id_buf: [64]u8 = undefined;
        const path_id = try std.fmt.bufPrint(&path_id_buf, "chart-{d}-area_path", .{series_index});
        const path_d = path.slice();
        try svg.path(path_d, .{
            .id = path_id,
            .class = "series-area",
            .fill = fill_with_opacity,
        });

        // Track for future updates
        try self.rendered_elements.append(.{
            .id = .{ .series_index = @intCast(series_index), .element_type = .area_path },
            .attrs = .{ .path = .{ .d = path_d, .fill = fill_with_opacity } },
        });

        // Also render the line on top
        try self.renderLine(svg, s, series_index, x_scale, y_scale, series_color, smooth);
    }

    fn renderBars(self: *Chart, svg: *Svg, s: Series, series_index: usize, x_scale: Scale, y_scale: Scale, series_color: Vapor.Types.Color) !void {
        if (s.data.len == 0) return;

        // Count how many bar series we have
        var bar_series_count: usize = 0;
        var bar_series_index: usize = 0;
        for (self.series.items, 0..) |item, i| {
            if (item.type == .bar) {
                if (i == series_index) bar_series_index = bar_series_count;
                bar_series_count += 1;
            }
        }

        const n_points: f64 = @floatFromInt(s.data.len);
        const n_series: f64 = @floatFromInt(bar_series_count);

        // Calculate bar dimensions
        const total_width = x_scale.rangeMax() - x_scale.rangeMin();
        const group_width = (total_width / n_points) * 0.9; // 70% of available space per group
        const bar_width = group_width / n_series;

        const baseline = y_scale.scale(@max(0, y_scale.domainMin()));

        for (s.data, 0..) |p, point_index| {
            const center_x = x_scale.scale(p.x);
            // Position bar within group: start from left edge of group, offset by series index
            const group_start = center_x - (group_width / 2);
            const x = group_start + (@as(f64, @floatFromInt(bar_series_index)) * bar_width);

            const y = y_scale.scale(p.y);
            const height = @abs(baseline - y);

            // Add small gap between bars (use 95% of bar width)
            const actual_bar_width = bar_width * 0.95;

            var id_buf: [64]u8 = undefined;
            const id = try std.fmt.bufPrint(&id_buf, "chart-{d}-{d}-bar", .{ series_index, point_index });
            try svg.rect(x, @min(y, baseline), actual_bar_width, height, .{
                .id = id,
                .fill = series_color,
                .rx = s.options.bar_radius,
                .class = "series-bar",
            });

            try self.rendered_elements.append(.{
                .id = .{ .series_index = @intCast(series_index), .point_index = @intCast(point_index), .element_type = .bar },
                .attrs = .{ .rect = .{ .x = x, .y = @min(y, baseline), .width = actual_bar_width, .height = height, .fill = series_color } },
            });
        }
    }
    fn renderScatter(self: *Chart, svg: *Svg, s: Series, series_index: usize, x_scale: Scale, y_scale: Scale, series_color: Vapor.Types.Color) !void {
        for (s.data, 0..) |p, point_index| {
            const x = x_scale.scale(p.x);
            const y = y_scale.scale(p.y);

            var id_buf: [64]u8 = undefined;
            const id = try std.fmt.bufPrint(&id_buf, "chart-{d}-{d}-dot", .{ series_index, point_index });

            try svg.circle(x, y, @floatFromInt(s.options.dot_radius), .{
                .id = id, // Add id field to CircleOpts
                .class = "series-dot",
                .fill = series_color,
            });

            // Track for future updates
            try self.rendered_elements.append(.{
                .id = .{ .series_index = @intCast(series_index), .point_index = @intCast(point_index), .element_type = .dot },
                .attrs = .{ .circle = .{ .cx = x, .cy = y, .r = @floatFromInt(s.options.dot_radius), .fill = series_color } },
            });
        }
    }

    fn renderAxes(self: *Chart, svg: *Svg, x_scale: Scale, y_scale: Scale, width: f64, height: f64) !void {
        // X axis line
        try svg.line(0, height, width, height, .{ .class = "axis", .id = "chart-axis-x" });

        // Y axis line
        try svg.line(0, 0, 0, height, .{ .class = "axis", .id = "chart-axis-y" });

        // X axis ticks
        const x_tick_count: usize = if (self.x_axis_config) |c| c.tick_count else 5;
        const x_ticks = try x_scale.ticks(x_tick_count, self.allocator);
        defer self.allocator.free(x_ticks);

        for (x_ticks) |tick| {
            const x = x_scale.scale(tick);
            var id_buf: [64]u8 = undefined;
            const id = try std.fmt.bufPrint(&id_buf, "chart-axis-x-{d}", .{tick});
            try svg.line(x, height, x, height + 5, .{ .class = "axis", .id = id });

            var label_buf: [32]u8 = undefined;
            const label = try std.fmt.bufPrint(&label_buf, "{d:.0}", .{tick});
            var id_buf_text: [64]u8 = undefined;
            const id_text = try std.fmt.bufPrint(&id_buf_text, "chart-axis-x-{d}-text-label", .{tick});
            try svg.text(x, height + 18, label, .{ .class = "tick-label", .anchor = .middle, .id = id_text });
        }

        // Y axis ticks
        const y_tick_count: usize = if (self.y_axis_config) |c| c.tick_count else 5;
        const y_ticks = try y_scale.ticks(y_tick_count, self.allocator);
        defer self.allocator.free(y_ticks);

        for (y_ticks) |tick| {
            const y = y_scale.scale(tick);
            var id_buf: [64]u8 = undefined;
            const id = try std.fmt.bufPrint(&id_buf, "chart-axis-y-{d}", .{tick});
            try svg.line(-5, y, 0, y, .{ .class = "axis", .id = id });

            var label_buf: [32]u8 = undefined;
            const label = try std.fmt.bufPrint(&label_buf, "{d:.0}", .{tick});
            var id_buf_text: [64]u8 = undefined;
            const id_text = try std.fmt.bufPrint(&id_buf_text, "chart-axis-y-{d}-text-label", .{tick});
            try svg.text(-10, y, label, .{ .class = "tick-label", .anchor = .end, .dominant_baseline = .middle, .id = id_text });
        }

        // Axis labels
        if (self.x_axis_config) |cfg| {
            if (cfg.label) |label| {
                try svg.text(width / 2, height + 35, label, .{
                    .class = "axis-label",
                    .anchor = .middle,
                });
            }
        }

        if (self.y_axis_config) |cfg| {
            if (cfg.label) |label| {
                var transform_buf: [128]u8 = undefined;
                const t = try std.fmt.bufPrint(&transform_buf, "rotate(-90) translate({d:.2}, {d})", .{ -height / 2, -35 });
                try svg.text(0, 0, label, .{
                    .class = "axis-label",
                    .anchor = .middle,
                    .transform = t,
                });
            }
        }
    }

    fn renderLegend(self: *Chart, svg: *Svg) !void {
        const cfg = self.legend_config orelse return;
        const m = self.config.margin;

        const x: f64 = switch (cfg.position) {
            .top_left, .bottom_left => @floatFromInt(m.left + 10),
            .top_right, .bottom_right => @floatFromInt(self.config.width - m.right - 100),
        };
        const y: f64 = switch (cfg.position) {
            .top_left, .top_right => @floatFromInt(m.top + 0),
            .bottom_left, .bottom_right => @floatFromInt(self.config.height - m.bottom - 20),
        };

        for (self.series.items, 0..) |s, i| {
            const series_color = s.options.color orelse Vapor.Types.Color.hex(self.config.palette.get(i));
            const offset_y = y + @as(f64, @floatFromInt(i)) * 18;

            // Color box
            var id_buf: [64]u8 = undefined;
            const id = try std.fmt.bufPrint(&id_buf, "chart-legend-{d}", .{i});
            try svg.rect(x, offset_y - 6, 12, 12, .{ .fill = series_color, .rx = 2, .id = id });

            try self.rendered_elements.append(.{
                .id = .{ .series_index = @intCast(i), .element_type = .legend },
                .attrs = .{ .rect = .{ .x = x, .y = offset_y - 6, .width = 12, .height = 12 } },
            });

            // Label
            try svg.text(x + 18, offset_y + 3, s.name, .{ .class = "legend-text" });
        }
    }

    fn straightLine(self: *Chart, points: [][2]f64) ![]u8 {
        var path = path_util.PathBuilder.init(self.allocator);
        defer path.deinit();

        if (points.len == 0) return try self.allocator.dupe(u8, "");

        try path.moveTo(points[0][0], points[0][1]);
        for (points[1..]) |pt| {
            try path.lineTo(pt[0], pt[1]);
        }

        return path.toOwnedSlice();
    }

    pub fn updateTooltip(self: *Chart, event: *Vapor.Event) void {
        if (Vapor.Kit.throttle(16)) return;
        if (self.tooltip) |*tooltip| {
            const x = event.pageX() - self.bounds.offset_x;
            const y = event.pageY() - self.bounds.offset_y;

            tooltip.left = x;
            tooltip.top = y;

            // Check if OUTSIDE the chart area
            const min_x = self.bounds.x;
            const max_x = self.bounds.x + self.bounds.width;
            const min_y = self.bounds.y;
            const max_y = self.bounds.y + self.bounds.height;

            const is_outside = (x < min_x or x > max_x or y < min_y or y > max_y);

            if (is_outside and !tooltip.hide) {
                // Was visible, now outside - hide it
                tooltip.binded.mutateStyleString("display", "none");
                tooltip.hide = true;
                return;
            } else if (!is_outside and tooltip.hide) {
                // Was hidden, now inside - show it
                tooltip.binded.mutateStyleString("display", "block");
                tooltip.hide = false;
            }

            // Vapor.cycle();

            if (self.findNearestX(@floatCast(x), y)) |result| {
                defer self.allocator.free(result.points);

                if (self.old_x != result.points[0].screen_x) {
                    for (result.points, 0..) |pt, i| {
                        const val = Vapor.fmtln("{d}", .{pt.data_y});
                        tooltip.value[i].value = val;
                    }
                    Vapor.cycle();
                }
                _ = tooltip.binded.translate3d(.{ .x = result.points[0].screen_x, .y = tooltip.top });

                self.old_x = result.points[0].screen_x;
            } else {
                // Outside chart or no data
                if (!tooltip.hide) {
                    tooltip.binded.mutateStyleString("display", "none");
                    tooltip.hide = true;
                }
            }
        }
    }

    pub fn findNearestX(self: *Chart, mouse_x: f64, _: f64) ?HoverResult {
        const x_scale = self.x_scale orelse return null;
        const y_scale = self.y_scale orelse return null;

        const m = self.config.margin;

        // Convert mouse position to chart-local coordinates
        const chart_x = mouse_x - @as(f64, @floatFromInt(m.left));

        // Invert X scale: screen coordinate → data value
        const data_x = x_scale.invert(chart_x);

        // Find the closest X value across all series
        var closest_x: ?f64 = null;
        var closest_dist: f64 = std.math.floatMax(f64);

        for (self.series.items) |s| {
            for (s.data) |p| {
                const dist = @abs(p.x - data_x);
                if (dist < closest_dist) {
                    closest_dist = dist;
                    closest_x = p.x;
                }
            }
        }

        const target_x = closest_x orelse return null;

        // Collect all points at this X value
        var points = std.array_list.Managed(HoveredPoint).init(self.allocator);
        defer points.deinit();

        for (self.series.items, 0..) |s, series_idx| {
            for (s.data, 0..) |p, point_idx| {
                // Use small epsilon for float comparison
                if (@abs(p.x - target_x) < 0.0001) {
                    const screen_x = x_scale.scale(p.x);
                    const screen_y = y_scale.scale(p.y);
                    const color = s.options.color orelse Vapor.Types.Color.hex(self.config.palette.get(series_idx));

                    points.append(.{
                        .series_index = series_idx,
                        .point_index = point_idx,
                        .data_x = p.x,
                        .data_y = p.y,
                        .screen_x = @as(f32, @floatCast(screen_x)) + @as(f32, @floatFromInt(m.left)),
                        .screen_y = @as(f32, @floatCast(screen_y)) + @as(f32, @floatFromInt(m.top)),
                        .series_name = s.name,
                        .series_color = color,
                    }) catch continue;
                }
            }
        }

        if (points.items.len == 0) return null;

        // Return owned slice
        const result_points = self.allocator.dupe(HoveredPoint, points.items) catch return null;

        return .{
            .points = result_points,
            .screen_x = @as(f32, @floatCast(x_scale.scale(target_x))) + @as(f32, @floatFromInt(m.left)),
        };
    }

    fn mount(self: *Chart) void {
        const offsets = self.container.getOffsets() orelse return;
        self.bounds.offset_x = offsets.offset_left;
        self.bounds.offset_y = offsets.offset_top;
        if (self.tooltip) |*tooltip| {
            tooltip.binded.mutateStyleString("display", "none");
        }
    }

    pub fn render(self: *Chart) void {
        if (!self.has_data) return;
        Row()
            .width(.px(@floatFromInt(self.config.width)))
            .height(.px(@floatFromInt(self.config.height)))
            .children({
            Vapor.Static.HooksCtx(.mounted, mount, .{self})({
                Row()
                    .ref(&self.container)
                    .pos(.relative)
                    .width(.percent(100))
                    .height(.percent(100))
                    .onEventCtx(.pointermove, updateTooltip, self)
                    .children({
                    if (self.tooltip) |*tooltip| {
                        Row()
                            .ref(&tooltip.binded)
                            .duration(100)
                            .transition(.{
                                .properties = &.{.transform},
                                .duration = 100,
                                .timing = .ease,
                            })
                            .pos(.absolute)
                            .width(.px(140))
                            .padding(.tblr(4, 4, 8, 8))
                            .layout(.top_left)
                            .direction(.column)
                            .background(.palette(.background))
                            .border(.round(.hex("#e5e5e5"), .all(6)))
                            .shadow(.glow(4, .transparentizeHex(.hex("#616161"), 0.1)))
                            .children({
                            Text(tooltip.x_label).font(14, 300, .palette(.text_color)).end();
                            for (tooltip.value) |lg| {
                                Row()
                                    .layout(.left_center)
                                    .spacing(4)
                                    .children({
                                    Row().width(.px(12)).height(.px(12))
                                        .border(.round(lg.color, .all(2)))
                                        .background(.{ .color = lg.background })
                                        .children({});
                                    Text(lg.value).font(12, 300, .palette(.text_color)).end();
                                });
                            }
                        });
                    }
                    if (self.current_chart_svg) |svg| {
                        Vapor.Svg(.{ .svg = svg, .override = true })
                            .end();
                    } else {
                        Vapor.printErr("No chart SVG generated", .{});
                    }
                });
            });
        });
    }
};

fn findMin(data: []const f64) f64 {
    if (data.len == 0) return 0;
    var min = data[0];
    for (data) |v| min = @min(min, v);
    return min;
}

fn findMax(data: []const f64) f64 {
    if (data.len == 0) return 1;
    var max = data[0];
    for (data) |v| max = @max(max, v);
    return max;
}

pub fn generate() ![]const u8 {
    const allocator = Vapor.arena(.persist);
    var chart = Chart.init(allocator, .{
        .width = 700,
        .height = 400,
        .margin = .{ .top = 30, .right = 30, .bottom = 50, .left = 60 },
        .palette = .{ .colors = &.{ "#3b82f6", "#ef4444" } },
    });
    defer chart.deinit();

    const sales = [_]Chart.Point{
        .{ .x = 1, .y = 30 },
        .{ .x = 2, .y = 50 },
        .{ .x = 3, .y = 45 },
        .{ .x = 4, .y = 80 },
        .{ .x = 5, .y = 65 },
        .{ .x = 6, .y = 95 },
    };

    const costs = [_]Chart.Point{
        .{ .x = 1, .y = 20 },
        .{ .x = 2, .y = 35 },
        .{ .x = 3, .y = 30 },
        .{ .x = 4, .y = 50 },
        .{ .x = 5, .y = 45 },
        .{ .x = 6, .y = 55 },
    };

    try chart.addSeries(.line_smooth, "Sales", &sales, .{ .color = "#000000" });
    try chart.addSeries(.line_smooth, "Costs", &costs, .{ .color = "#002BFF" });

    chart.xAxis(.{ .label = "Month", .tick_count = 6 });
    chart.yAxis(.{ .label = "USD ($)", .tick_count = 5 });
    chart.legend(.{ .position = .top_right });

    const svg = try chart.render();
    return svg;
    // defer allocator.free(svg);
}

pub fn generate2() ![]const u8 {
    const allocator = Vapor.arena(.persist);
    var chart = Chart.init(allocator, .{
        .width = 700,
        .height = 400,
        .margin = .{ .top = 30, .right = 30, .bottom = 50, .left = 60 },
        .palette = .{ .colors = &.{ "#3b82f6", "#ef4444" } },
    });
    defer chart.deinit();

    const costs = [_]Chart.Point{
        .{ .x = 1, .y = 80 },
        .{ .x = 2, .y = 20 },
        .{ .x = 3, .y = 25 },
        .{ .x = 4, .y = 40 },
        .{ .x = 5, .y = 55 },
        .{ .x = 6, .y = 25 },
    };

    const sales = [_]Chart.Point{
        .{ .x = 1, .y = 40 },
        .{ .x = 2, .y = 95 },
        .{ .x = 3, .y = 10 },
        .{ .x = 4, .y = 40 },
        .{ .x = 5, .y = 65 },
        .{ .x = 6, .y = 75 },
    };

    try chart.addSeries(.line_smooth, "Sales", &sales, .{ .color = "#000000" });
    try chart.addSeries(.line_smooth, "Costs", &costs, .{ .color = "#002BFF" });

    chart.xAxis(.{ .label = "Month", .tick_count = 6 });
    chart.yAxis(.{ .label = "USD ($)", .tick_count = 5 });
    chart.legend(.{ .position = .top_right });

    const svg = try chart.render();
    return svg;
    // defer allocator.free(svg);
}
