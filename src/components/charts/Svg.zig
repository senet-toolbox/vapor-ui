const std = @import("std");
const Vapor = @import("vapor");
const Writer = Vapor.Writer;

pub const Svg = struct {
    buffer: std.array_list.Managed(u8),

    pub fn init(allocator: std.mem.Allocator) Svg {
        return .{
            .buffer = std.array_list.Managed(u8).init(allocator),
        };
    }

    pub fn initCapacity(allocator: std.mem.Allocator, capacity: usize) !Svg {
        return .{
            .buffer = try std.array_list.Managed(u8).initCapacity(allocator, capacity),
        };
    }

    pub fn deinit(self: *Svg) void {
        self.buffer.deinit();
    }

    pub fn writer(self: *Svg) std.array_list.Managed(u8).Writer {
        return self.buffer.writer();
    }

    pub fn toOwnedSlice(self: *Svg) ![]u8 {
        return self.buffer.toOwnedSlice();
    }

    // ============ SVG Elements ============

    pub fn openSvg(self: *Svg, width: u32, height: u32) !void {
        try self.writer().print(
            \\<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {d} {d}">
            \\
        , .{ width, height });
    }

    pub fn closeSvg(self: *Svg) !void {
        try self.writer().writeAll("</svg>\n");
    }

    pub fn openGroup(self: *Svg, class: ?[]const u8, transform: ?[]const u8) !void {
        const w = self.writer();
        try w.writeAll("<g");
        if (class) |c| try w.print(" class=\"{s}\"", .{c});
        if (transform) |t| try w.print(" transform=\"{s}\"", .{t});
        try w.writeAll(">\n");
    }

    pub fn closeGroup(self: *Svg) !void {
        try self.writer().writeAll("</g>\n");
    }

    pub fn convertColor(color: Vapor.Types.Color) []const u8 {
        var w: Writer = undefined;
        var buffer: [4096]u8 = undefined;
        w.init(&buffer);
        color.toCss(&w) catch unreachable;
        return w.buffer[0..w.pos];
    }

    pub fn line(self: *Svg, x1: f64, y1: f64, x2: f64, y2: f64, opts: LineOpts) !void {
        const w = self.writer();
        try w.print("<line id=\"{s}\" x1=\"{d:.2}\" y1=\"{d:.2}\" x2=\"{d:.2}\" y2=\"{d:.2}\"", .{ opts.id, x1, y1, x2, y2 });
        if (opts.class) |c| try w.print(" class=\"{s}\"", .{c});
        if (opts.stroke) |s| try w.print(" stroke=\"{s}\"", .{convertColor(s)});
        if (opts.stroke_width) |sw| try w.print(" stroke-width=\"{d}\"", .{sw});
        try w.writeAll("/>\n");
    }

    pub fn rect(self: *Svg, x: f64, y: f64, width: f64, height: f64, opts: RectOpts) !void {
        const w = self.writer();
        try w.print("<rect id=\"{s}\" x=\"{d:.2}\" y=\"{d:.2}\" width=\"{d:.2}\" height=\"{d:.2}\"", .{ opts.id, x, y, width, height });
        if (opts.class) |c| try w.print(" class=\"{s}\"", .{c});
        if (opts.fill) |f| try w.print(" fill=\"{s}\"", .{convertColor(f)});
        if (opts.stroke) |s| try w.print(" stroke=\"{s}\"", .{convertColor(s)});
        if (opts.stroke_width) |sw| try w.print(" stroke-width=\"{d:.2}\"", .{sw});
        if (opts.rx) |r| try w.print(" rx=\"{d:.2}\"", .{r});
        if (opts.opacity) |o| try w.print(" opacity=\"{d:.2}\"", .{o});
        try w.writeAll("/>\n");
    }

    pub fn circle(self: *Svg, cx: f64, cy: f64, r: f64, opts: CircleOpts) !void {
        const w = self.writer();
        try w.print("<circle id=\"{s}\" cx=\"{d:.2}\" cy=\"{d:.2}\" r=\"{d:.2}\"", .{ opts.id, cx, cy, r });
        if (opts.class) |c| try w.print(" class=\"{s}\"", .{c});
        if (opts.fill) |f| try w.print(" fill=\"{s}\"", .{convertColor(f)});
        if (opts.stroke) |s| try w.print(" stroke=\"{s}\"", .{convertColor(s)});
        try w.writeAll("/>\n");
    }

    pub fn path(self: *Svg, d: []const u8, opts: PathOpts) !void {
        const w = self.writer();
        try w.print("<path id=\"{s}\" d=\"{s}\"", .{ opts.id, d });
        if (opts.class) |c| try w.print(" class=\"{s}\"", .{c});
        if (opts.fill) |f| try w.print(" fill=\"{s}\"", .{convertColor(f)});
        if (opts.stroke) |s| try w.print(" stroke=\"{s}\"", .{convertColor(s)});
        if (opts.stroke_width) |sw| try w.print(" stroke-width=\"{d}\"", .{sw});
        try w.writeAll("/>\n");
    }

    pub fn text(self: *Svg, x: f64, y: f64, content: []const u8, opts: TextOpts) !void {
        const w = self.writer();
        try w.print("<text id=\"{s}\" x=\"{d:.2}\" y=\"{d:.2}\"", .{ opts.id, x, y });
        if (opts.class) |c| try w.print(" class=\"{s}\"", .{c});
        if (opts.anchor) |a| try w.print(" text-anchor=\"{s}\"", .{@tagName(a)});
        if (opts.dominant_baseline) |db| try w.print(" dominant-baseline=\"{s}\"", .{@tagName(db)});
        if (opts.font_size) |fs| try w.print(" font-size=\"{d}\"", .{fs});
        if (opts.fill) |f| try w.print(" fill=\"{s}\"", .{convertColor(f)});
        if (opts.transform) |t| try w.print(" transform=\"{s}\"", .{t});
        try w.print(">{s}</text>\n", .{content});
    }

    pub fn style(self: *Svg, css: []const u8) !void {
        try self.writer().print("<style>{s}</style>\n", .{css});
    }

    // ============ Option Types ============

    pub const LineOpts = struct {
        id: []const u8 = "",
        class: ?[]const u8 = null,
        stroke: ?Vapor.Types.Color = null,
        stroke_width: ?f32 = null,
    };

    pub const RectOpts = struct {
        id: []const u8 = "",
        class: ?[]const u8 = null,
        fill: ?Vapor.Types.Color = null,
        stroke: ?Vapor.Types.Color = null,
        rx: ?f64 = null,
        border: ?Vapor.Types.BorderGrouped = null,
        stroke_width: ?f32 = null,
        opacity: ?f64 = null,
    };

    pub const CircleOpts = struct {
        id: []const u8 = "",
        class: ?[]const u8 = null,
        fill: ?Vapor.Types.Color = null,
        stroke: ?Vapor.Types.Color = null,
    };

    pub const PathOpts = struct {
        id: []const u8 = "",
        class: ?[]const u8 = null,
        fill: ?Vapor.Types.Color = null,
        stroke: ?Vapor.Types.Color = null,
        stroke_width: ?f32 = null,
    };

    pub const TextOpts = struct {
        id: []const u8 = "",
        class: ?[]const u8 = null,
        anchor: ?TextAnchor = null,
        dominant_baseline: ?DominantBaseline = null,
        font_size: ?u32 = null,
        fill: ?Vapor.Types.Color = null,
        transform: ?[]const u8 = null,
    };

    pub const TextAnchor = enum { start, middle, end };
    pub const DominantBaseline = enum { auto, middle, hanging };
};
