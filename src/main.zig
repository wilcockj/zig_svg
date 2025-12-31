const std = @import("std");
const zig_svg_graph = @import("zig_svg_graph");

const cssColorKeywords = [_][]const u8{
    "aliceblue",            "antiquewhite",    "aqua",              "aquamarine",       "azure",           "beige",         "bisque",
    "black",                "blanchedalmond",  "blue",              "blueviolet",       "brown",           "burlywood",     "cadetblue",
    "chartreuse",           "chocolate",       "coral",             "cornflowerblue",   "cornsilk",        "crimson",       "cyan",
    "darkblue",             "darkcyan",        "darkgoldenrod",     "darkgray",         "darkgreen",       "darkgrey",      "darkkhaki",
    "darkmagenta",          "darkolivegreen",  "darkorange",        "darkorchid",       "darkred",         "darksalmon",    "darkseagreen",
    "darkslateblue",        "darkslategray",   "darkslategrey",     "darkturquoise",    "darkviolet",      "deeppink",      "deepskyblue",
    "dimgray",              "dimgrey",         "dodgerblue",        "firebrick",        "floralwhite",     "forestgreen",   "fuchsia",
    "gainsboro",            "ghostwhite",      "gold",              "goldenrod",        "gray",            "green",         "greenyellow",
    "grey",                 "honeydew",        "hotpink",           "indianred",        "indigo",          "ivory",         "khaki",
    "lavender",             "lavenderblush",   "lawngreen",         "lemonchiffon",     "lightblue",       "lightcoral",    "lightcyan",
    "lightgoldenrodyellow", "lightgray",       "lightgreen",        "lightgrey",        "lightpink",       "lightsalmon",   "lightseagreen",
    "lightskyblue",         "lightslategray",  "lightslategrey",    "lightsteelblue",   "lightyellow",     "lime",          "limegreen",
    "linen",                "magenta",         "maroon",            "mediumaquamarine", "mediumblue",      "mediumorchid",  "mediumpurple",
    "mediumseagreen",       "mediumslateblue", "mediumspringgreen", "mediumturquoise",  "mediumvioletred", "midnightblue",  "mintcream",
    "mistyrose",            "moccasin",        "navajowhite",       "navy",             "oldlace",         "olive",         "olivedrab",
    "orange",               "orangered",       "orchid",            "palegoldenrod",    "palegreen",       "paleturquoise", "palevioletred",
    "papayawhip",           "peachpuff",       "peru",              "pink",             "plum",            "powderblue",    "purple",
    "red",                  "rosybrown",       "royalblue",         "saddlebrown",      "salmon",          "sandybrown",    "seagreen",
    "seashell",             "sienna",          "silver",            "skyblue",          "slateblue",       "slategray",     "slategrey",
    "snow",                 "springgreen",     "steelblue",         "tan",              "teal",            "thistle",       "tomato",
    "turquoise",            "violet",          "wheat",             "white",            "whitesmoke",      "yellow",        "yellowgreen",
};

pub fn pickRandomNamedColor() []const u8 {
    return cssColorKeywords[std.crypto.random.int(u32) % cssColorKeywords.len];
}

pub fn getRandomNamedSvgColor() SvgColorType {
    return SvgColorType{ .named = cssColorKeywords[std.crypto.random.int(u32) % cssColorKeywords.len] };
}

const SvgContainer = struct {
    writer: *std.Io.Writer,

    pub fn open(writer: *std.Io.Writer) !SvgContainer {
        var new_container = SvgContainer{ .writer = writer };
        try new_container.genBasicSvgFileHeader();
        return new_container;
    }

    pub fn writeToSvgFile(self: SvgContainer, msg: []const u8) !void {
        try self.writer.writeAll(msg);
    }

    fn genBasicSvgFileHeader(self: SvgContainer) !void {
        try self.writeToSvgFile("<svg version=\"1.1\" xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 100 100\" preserveAspectRatio=\"xMinYMin\">\n");
    }

    pub fn addBasicSvgSuffix(self: SvgContainer) !void {
        try self.writeToSvgFile("</svg>\n");
    }

    pub fn startSvgGroup(self: SvgContainer) !void {
        try self.writeToSvgFile("<g>\n");
    }

    pub fn addSvgTitle(self: SvgContainer, title: []u8) !void {
        var buffer: [1024]u8 = undefined;
        var fba = std.heap.FixedBufferAllocator.init(buffer[0..]);
        const allocator = fba.allocator();

        var list: std.ArrayList(u8) = .empty;
        list.ensureTotalCapacity(allocator, buffer.size / 2);
        defer list.deinit(allocator);
        var static_writer = list.writer(allocator);
        try static_writer.print("<title>{s}</title>\n", .{title});
        self.writeToSvgFile(try list.toOwnedSlice(allocator));
    }

    pub fn endSvgGroup(self: SvgContainer) !void {
        try self.writeToSvgFile("</g>\n");
    }

    pub fn appendFillColor(color: SvgColorType, my_writer: anytype) !void {
        switch (color) {
            .named => |name| try my_writer.print(
                " fill=\"{s}\"",
                .{name},
            ),
            .rgb => |rgb| try my_writer.print(
                " fill=\"rgb({d},{d},{d})\"",
                .{ rgb.r, rgb.g, rgb.b },
            ),
            .none => try my_writer.print(
                " />\n",
                .{},
            ),
        }
    }

    pub fn appendStrokeColor(color: SvgColorType, my_writer: anytype) !void {
        switch (color) {
            .named => |name| try my_writer.print(
                " stroke=\"{s}\"",
                .{name},
            ),
            .rgb => |rgb| try my_writer.print(
                " stroke=\"rgb({d},{d},{d})\"",
                .{ rgb.r, rgb.g, rgb.b },
            ),
            .none => try my_writer.print(
                " />\n",
                .{},
            ),
        }
    }

    pub fn appendTagClose(my_writer: anytype) !void {
        try my_writer.print(
            "/>\n",
            .{},
        );
    }

    pub fn appendRectCornerRadius(rx: f32, ry: f32, my_writer: anytype) !void {
        try my_writer.print(
            " rx=\"{d}\" ry=\"{d}\"",
            .{ rx, ry },
        );
    }

    pub fn appendStroke(stroke_config: SvgStrokeConfig, my_writer: anytype) !void {
        try appendStrokeColor(stroke_config.stroke_color, my_writer);
        try my_writer.print(
            " stroke-width=\"{d}\"",
            .{stroke_config.stroke_width},
        );
    }

    pub fn formatSvgAnimate(animate: SvgAnimateConfig, my_writer: anytype) !void {
        try my_writer.print("<animate attributeName=\"{s}\" values=\"{s}\" dur=\"{d}s\" repeatCount=\"{s}\"/>\n", .{ animate.attribute_name, animate.values, animate.duration, animate.repeat_count });
    }

    pub fn formatSvgCircle(circle: SvgCircle, my_writer: anytype) !void {
        // Formats into the stack-allocated buffer
        try my_writer.print("<circle cx=\"{d}\" cy=\"{d}\" r=\"{d}\"", .{ circle.x, circle.y, circle.radius });

        try appendFillColor(circle.color, my_writer);

        if (circle.stroke_config.stroke_enabled) {
            try appendStroke(circle.stroke_config, my_writer);
        }

        if (!circle.animate_config.enabled) {
            try appendTagClose(my_writer);
        } else {
            // Close the opening tag and add animation element
            try my_writer.print(">\n", .{});

            try formatSvgAnimate(circle.animate_config, my_writer);

            try my_writer.print("</circle>\n", .{});
        }
    }

    pub fn addSvgCircle(self: SvgContainer, circle: SvgCircle) !void {
        // Formats into the stack-allocated buffer
        var buffer: [1024]u8 = undefined;
        var fba = std.heap.FixedBufferAllocator.init(buffer[0..]);
        const allocator = fba.allocator();

        var list: std.ArrayList(u8) = .empty;
        defer list.deinit(allocator);
        try list.ensureTotalCapacity(allocator, buffer.len / 2);
        var static_writer = list.writer(allocator);

        try formatSvgCircle(circle, &static_writer);
        try self.writeToSvgFile(try list.toOwnedSlice(allocator));
    }

    pub fn formatSvgRectangle(rect: SvgRect, my_writer: anytype) !void {
        // not implemented
        try my_writer.print("<rect x=\"{d}\" y=\"{d}\" width=\"{d}\" height=\"{d}\"", .{ rect.x, rect.y, rect.width, rect.height });

        if (rect.round_rect) {
            try appendRectCornerRadius(rect.rx, rect.ry, my_writer);
        }

        try appendFillColor(rect.color, my_writer);

        if (rect.stroke_config.stroke_enabled) {
            try appendStroke(rect.stroke_config, my_writer);
        }

        try appendTagClose(my_writer);
    }

    pub fn addSvgRect(self: SvgContainer, rect: SvgRect) !void {
        // Formats into the stack-allocated buffer
        var buffer: [512]u8 = undefined;
        var fba = std.heap.FixedBufferAllocator.init(buffer[0..]);
        const allocator = fba.allocator();

        var list: std.ArrayList(u8) = .empty;
        defer list.deinit(allocator);
        var static_writer = list.writer(allocator);

        try formatSvgRectangle(rect, &static_writer);
        try self.writeToSvgFile(try list.toOwnedSlice(allocator));
    }

    pub fn closeSvgFile(self: SvgContainer) !void {
        try self.writer.flush();
    }
};

const SvgColorTypeTag = enum {
    named,
    rgb,
    none,
};

const RgbSvgColor = struct { r: u8, g: u8, b: u8 };

const SvgColorType = union(SvgColorTypeTag) {
    named: []const u8,
    rgb: RgbSvgColor,
    none,
};

const SvgAnimateConfig = struct {
    enabled: bool = false,
    attribute_name: []const u8 = "cy",
    values: []const u8 = "", // Semicolon-separated values
    duration: f32 = 2.0,
    repeat_count: []const u8 = "indefinite",
};

const SvgCircle = struct {
    x: f32,
    y: f32,
    radius: f32,
    stroke_config: SvgStrokeConfig = SvgStrokeConfig{},
    color: SvgColorType,
    animate_config: SvgAnimateConfig = SvgAnimateConfig{},
};

const SvgStrokeConfig = struct {
    stroke_enabled: bool = false,
    stroke_color: SvgColorType = SvgColorType{ .named = "black" },
    stroke_width: f32 = 0.0,
    stroke_opacity: f32 = 1.0,
    stroke_dasharray: bool = false,
};

const SvgRect = struct {
    x: f32,
    y: f32,
    rx: f32,
    ry: f32,
    width: f32,
    height: f32,
    color: SvgColorType,
    stroke_config: SvgStrokeConfig = SvgStrokeConfig{},
    round_rect: bool = false,

    pub fn buildSvgRect(x: f32, y: f32, width: f32, height: f32, color: SvgColorType) SvgRect {
        const my_rect = SvgRect{ .x = x, .y = y, .rx = 0, .ry = 0, .width = width, .height = height, .color = color };
        return my_rect;
    }

    pub fn buildSvgRoundRect(x: f32, y: f32, rx: f32, ry: f32, width: f32, height: f32, color: SvgColorType) SvgRect {
        const my_rect = SvgRect{ .x = x, .y = y, .rx = rx, .ry = ry, .width = width, .height = height, .color = color, .round_rect = true };
        return my_rect;
    }
};

pub fn main() !void {
    const rand = std.crypto.random;
    {
        var stdout_buffer: [5096]u8 = undefined;
        var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
        const stdout = &stdout_writer.interface;

        var svg_container = try SvgContainer.open(stdout);
        defer svg_container.closeSvgFile() catch @panic("couldnt close svg file");

        defer svg_container.addBasicSvgSuffix() catch @panic("Couldn't close svg");

        for (0..0) |_| {
            const my_color = getRandomNamedSvgColor();

            const my_circle = SvgCircle{ .x = rand.int(u32) % 100, .y = rand.int(u32) % 100, .radius = rand.int(u32) % 5 + 1, .color = my_color };
            try svg_container.startSvgGroup();
            try svg_container.addSvgCircle(my_circle);
            var buf = [_]u8{0} ** 256;
            switch (my_circle.color) {
                SvgColorType.named => |name| {
                    const msg = try std.fmt.bufPrint(&buf, ".x = {d}, .y = {d}, .r = {d}, .c={s}", .{ my_circle.x, my_circle.y, my_circle.radius, name });
                    try svg_container.addSvgTitle(msg);
                },
                else => {},
            }
            try svg_container.endSvgGroup();
        }

        // try graphing
        const square = SvgRect.buildSvgRect(0, 0, 100, 100, SvgColorType{ .named = "azure" });
        try svg_container.addSvgRect(square);
        const num_points = 1000;
        for (0..num_points) |i| {
            const rand_color = getRandomNamedSvgColor();
            const circle_size = 0.6;
            const x_pos = @as(f32, @floatFromInt(i)) / num_points * 100;

            const phase = @as(f32, @floatFromInt(i)) / (4 * std.math.pi);
            const amplitude = 25.0;
            const center_y = 50.0;

            // For a traveling wave, advance the phase by a small amount (one wavelength shift)
            // This makes the wave pattern appear to move
            const phase_shift = 2.0 * std.math.pi; // One complete wavelength travels past

            var values_buf = [_]u8{0} ** 64;
            const values = try std.fmt.bufPrint(&values_buf, "{d:.2};{d:.2};{d:.2};{d:.2};{d:.2}", .{
                std.math.sin(phase) * amplitude + center_y,
                std.math.sin(phase + phase_shift * 0.25) * amplitude + center_y,
                std.math.sin(phase + phase_shift * 0.5) * amplitude + center_y,
                std.math.sin(phase + phase_shift * 0.75) * amplitude + center_y,
                std.math.sin(phase + phase_shift) * amplitude + center_y,
            });

            const animate_config = SvgAnimateConfig{
                .enabled = true,
                .attribute_name = "cy",
                .values = values,
                .duration = 6.0,
                .repeat_count = "indefinite",
            };

            const stroke_width = 0.1;
            const stroke_config = SvgStrokeConfig{ .stroke_enabled = true, .stroke_dasharray = false, .stroke_width = stroke_width };

            const my_circle = SvgCircle{
                .x = x_pos,
                .y = std.math.sin(phase) * amplitude + center_y,
                .radius = circle_size,
                .color = rand_color,
                .stroke_config = stroke_config,
                .animate_config = animate_config,
            };

            try svg_container.addSvgCircle(my_circle);
        }
    }

    // simple svg generation
}

test "svg circle named color test" {
    const color = SvgColorType{ .named = "mediumorchid" };
    const my_circle = SvgCircle{ .x = 100, .y = 100, .radius = 100, .color = color };

    var buffer: [512]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(buffer[0..]);
    const allocator = fba.allocator();

    var list: std.ArrayList(u8) = .empty;
    defer list.deinit(allocator);
    var static_writer = list.writer(allocator);
    try SvgContainer.formatSvgCircle(my_circle, &static_writer);

    try std.testing.expectEqualStrings("<circle cx=\"100\" cy=\"100\" r=\"100\" fill=\"mediumorchid\"/>\n", try list.toOwnedSlice(allocator));
}

test "svg circle rgb color test" {
    const color = SvgColorType{ .rgb = RgbSvgColor{ .r = 100, .g = 50, .b = 50 } };
    const my_circle = SvgCircle{ .x = 100, .y = 100, .radius = 100, .color = color };

    var buffer: [512]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(buffer[0..]);
    const allocator = fba.allocator();

    var list: std.ArrayList(u8) = .empty;
    defer list.deinit(allocator);
    var static_writer = list.writer(allocator);
    try SvgContainer.formatSvgCircle(my_circle, &static_writer);

    try std.testing.expectEqualStrings("<circle cx=\"100\" cy=\"100\" r=\"100\" fill=\"rgb(100,50,50)\"/>\n", try list.toOwnedSlice(allocator));
}
