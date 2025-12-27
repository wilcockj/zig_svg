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
        try self.writeToSvgFile("</svg>");
    }

    pub fn startSvgGroup(self: SvgContainer) !void {
        try self.writeToSvgFile("<g>\n");
    }

    pub fn addSvgTitle(self: SvgContainer, title: []u8) !void {
        var svg_writer_buf = [_]u8{0} ** 256;
        const msg = try std.fmt.bufPrint(&svg_writer_buf, "<title>{s}</title>\n", .{title});
        try self.writeToSvgFile(msg);
    }

    pub fn endSvgGroup(self: SvgContainer) !void {
        try self.writeToSvgFile("</g>\n");
    }

    pub fn appendFillColor(color: SvgColorType, buf: []u8) ![]u8 {
        const written = switch (color) {
            .named => |name| try std.fmt.bufPrint(
                buf,
                " fill=\"{s}\"",
                .{name},
            ),
            .rgb => |rgb| try std.fmt.bufPrint(
                buf,
                " fill=\"rgb({d},{d},{d})\"",
                .{ rgb.r, rgb.g, rgb.b },
            ),
            .none => try std.fmt.bufPrint(
                buf,
                " />\n",
                .{},
            ),
        };
        return written;
    }

    pub fn appendStrokeColor(color: SvgColorType, buf: []u8) ![]u8 {
        const written = switch (color) {
            .named => |name| try std.fmt.bufPrint(
                buf,
                " stroke=\"{s}\"",
                .{name},
            ),
            .rgb => |rgb| try std.fmt.bufPrint(
                buf,
                " stroke=\"rgb({d},{d},{d})\"",
                .{ rgb.r, rgb.g, rgb.b },
            ),
            .none => try std.fmt.bufPrint(
                buf,
                " />\n",
                .{},
            ),
        };
        return written;
    }

    pub fn appendTagClose(buf: []u8) ![]u8 {
        const written = try std.fmt.bufPrint(
            buf,
            "/>\n",
            .{},
        );
        return written;
    }

    pub fn appendRectCornerRadius(rx: f32, ry: f32, buf: []u8) ![]u8 {
        const written = try std.fmt.bufPrint(
            buf,
            " rx=\"{d}\" ry=\"{d}\"",
            .{ rx, ry },
        );
        return written;
    }

    pub fn appendStroke(stroke_config: SvgStrokeConfig, buf: []u8) !usize {
        var written_len: usize = 0;
        const written = try appendStrokeColor(stroke_config.stroke_color, buf);
        written_len += written.len;
        const stroke_width_written = try std.fmt.bufPrint(
            buf[written_len..],
            " stroke-width=\"{d}\"",
            .{stroke_config.stroke_width},
        );
        return written_len + stroke_width_written.len;
    }

    pub fn formatSvgCircle(circle: SvgCircle, buf: []u8) ![]u8 {
        // Formats into the stack-allocated buffer
        var idx: usize = 0;
        const msg = try std.fmt.bufPrint(buf, "<circle cx=\"{d}\" cy=\"{d}\" r=\"{d}\"", .{ circle.x, circle.y, circle.radius });
        idx += msg.len;

        {
            const written = try appendFillColor(circle.color, buf[idx..]);
            idx += written.len;
        }

        if (circle.stroke_config.stroke_enabled) {
            idx += try appendStroke(circle.stroke_config, buf[idx..]);
        }

        {
            const written = try appendTagClose(buf[idx..]);
            idx += written.len;
        }
        return buf[0..idx];
    }

    pub fn addSvgCircle(self: SvgContainer, circle: SvgCircle) !void {
        // Formats into the stack-allocated buffer
        var svg_writer_buf = [_]u8{0} ** 256;
        const written = try formatSvgCircle(circle, &svg_writer_buf);
        try self.writeToSvgFile(written);
    }

    pub fn formatSvgRectangle(rect: SvgRect, buf: []u8) ![]u8 {
        // not implemented
        var idx: usize = 0;
        {
            const written = try std.fmt.bufPrint(buf, "<rect x=\"{d}\" y=\"{d}\" width=\"{d}\" height=\"{d}\"", .{ rect.x, rect.y, rect.width, rect.height });
            idx += written.len;
        }

        if (rect.round_rect) {
            const written = try appendRectCornerRadius(rect.rx, rect.ry, buf[idx..]);
            idx += written.len;
        }

        {
            const written = try appendFillColor(rect.color, buf[idx..]);
            idx += written.len;
        }

        if (rect.stroke_config.stroke_enabled) {
            idx += try appendStroke(rect.stroke_config, buf[idx..]);
        }

        {
            const written = try appendTagClose(buf[idx..]);
            idx += written.len;
        }
        return buf[0..idx];
    }

    pub fn addSvgRect(self: SvgContainer, rect: SvgRect) !void {
        // Formats into the stack-allocated buffer
        var svg_writer_buf = [_]u8{0} ** 256;
        const written = try formatSvgRectangle(rect, &svg_writer_buf);
        try self.writeToSvgFile(written);
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

const SvgCircle = struct {
    x: f32,
    y: f32,
    radius: f32,
    stroke_config: SvgStrokeConfig = SvgStrokeConfig{},
    color: SvgColorType,
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
        const num_points = 200;
        for (0..num_points) |i| {
            const rand_color = getRandomNamedSvgColor();
            const circle_size = 0.6;
            const my_y = std.math.sin(@as(f32, @floatFromInt(i)) / (4 * std.math.pi)) * 25 + 50;

            const stroke_width = 0.1;

            const stroke_config = SvgStrokeConfig{ .stroke_enabled = true, .stroke_dasharray = false, .stroke_width = stroke_width };
            const my_circle = SvgCircle{ .x = @as(f32, @floatFromInt(i)) / num_points * 100, .y = my_y, .radius = circle_size, .color = rand_color, .stroke_config = stroke_config };

            try svg_container.addSvgCircle(my_circle);
        }
    }

    // simple svg generation
}

test "svg circle named color test" {
    const color = SvgColorType{ .named = "mediumorchid" };
    const my_circle = SvgCircle{ .x = 100, .y = 100, .radius = 100, .color = color };
    var buf = [_]u8{0} ** 256;
    const msg = try SvgContainer.formatSvgCircle(my_circle, &buf);

    try std.testing.expectEqualStrings("<circle cx=\"100\" cy=\"100\" r=\"100\" fill=\"mediumorchid\"/>\n", msg);
}

test "svg circle rgb color test" {
    const color = SvgColorType{ .rgb = RgbSvgColor{ .r = 100, .g = 50, .b = 50 } };
    const my_circle = SvgCircle{ .x = 100, .y = 100, .radius = 100, .color = color };
    var buf = [_]u8{0} ** 256;
    const msg = try SvgContainer.formatSvgCircle(my_circle, &buf);

    try std.testing.expectEqualStrings("<circle cx=\"100\" cy=\"100\" r=\"100\" fill=\"rgb(100,50,50)\"/>\n", msg);
}
