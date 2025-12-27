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

const SvgContainer = struct {
    writer: *std.Io.Writer,
    var svg_writer_buf = [_]u8{0} ** 256;

    pub fn open(writer: *std.Io.Writer) !SvgContainer {
        var new_container = SvgContainer{ .writer = writer };
        try new_container.genBasicSvgFileHeader();
        return new_container;
    }

    pub fn writeToSvgFile(self: SvgContainer, msg: []const u8) !void {
        try self.writer.writeAll(msg);
    }

    fn genBasicSvgFileHeader(self: SvgContainer) !void {
        try self.writeToSvgFile("<svg version=\"1.1\" xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 100 100\" preserveAspectRatio=\"true\">\n");
    }

    pub fn addBasicSvgSuffix(self: SvgContainer) !void {
        try self.writeToSvgFile("</svg>");
    }

    pub fn startSvgGroup(self: SvgContainer) !void {
        try self.writeToSvgFile("<g>\n");
    }

    pub fn addSvgTitle(self: SvgContainer, title: []u8) !void {
        const msg = try std.fmt.bufPrint(&svg_writer_buf, "<title>{s}</title>\n", .{title});
        try self.writeToSvgFile(msg);
    }

    pub fn endSvgGroup(self: SvgContainer) !void {
        try self.writeToSvgFile("</g>\n");
    }

    pub fn formatSvgCircle(circle: SvgCircle, buf: []u8) ![]u8 {
        // Formats into the stack-allocated buffer
        const msg = switch (circle.color) {
            SvgColorTypeTag.named => |name| try std.fmt.bufPrint(buf, "<circle cx=\"{d}\" cy=\"{d}\" r=\"{d}\" fill=\"{s}\"/>\n", .{ circle.x, circle.y, circle.radius, name }),
            SvgColorTypeTag.rgb => |rgb| try std.fmt.bufPrint(buf, "<circle cx=\"{d}\" cy=\"{d}\" r=\"{d}\" fill=\"rgb({d},{d},{d})\"/>\n", .{ circle.x, circle.y, circle.radius, rgb.r, rgb.g, rgb.b }),
            SvgColorTypeTag.none => |_| {
                unreachable;
            },
        };
        return msg;
    }

    pub fn addSvgCircle(self: SvgContainer, circle: SvgCircle) !void {
        // Formats into the stack-allocated buffer
        const written = try formatSvgCircle(circle, &svg_writer_buf);
        try self.writeToSvgFile(written);
    }

    pub fn formatSvgRectangle(rect: SvgRect, buf: []u8) ![]u8 {
        // not implemented
        _ = rect;
        _ = buf;
        //const msg = switch (rect.color) {
        //    SvgColorTypeTag.named => |name| unreachable,
        //    SvgColorTypeTag.rgb => |rgb| unreachable,
        //    SvgColorTypeTag.none => |_| {
        //        unreachable;
        //    },
        //};
        //return msg;
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
    x: u32,
    y: u32,
    radius: u32,
    color: SvgColorType,
};

const SvgRect = struct {
    x: u32,
    y: u32,
    width: u32,
    height: u32,
    color: SvgColorType,
};

pub fn main() !void {
    // Prints to stderr, ignoring potential errors.
    const rand = std.crypto.random;
    //std.debug.print("All your {s} are belong to us.\n", .{"codebase"});
    //try zig_svg_graph.bufferedPrint();
    {
        var stdout_buffer: [5096]u8 = undefined;
        var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
        const stdout = &stdout_writer.interface;
        var svg_container = try SvgContainer.open(stdout);
        defer svg_container.closeSvgFile() catch @panic("couldnt close svg file");

        defer svg_container.addBasicSvgSuffix() catch @panic("Couldn't close svg");

        for (0..3000) |_| {
            const rand_color = pickRandomNamedColor();
            const my_color = SvgColorType{ .named = rand_color };

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
