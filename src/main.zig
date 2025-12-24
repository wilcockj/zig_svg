const std = @import("std");
const zig_svg_graph = @import("zig_svg_graph");

const SvgContainer = struct {
    file: std.fs.File,
    pub fn open(filename: []const u8) !SvgContainer {
        return .{
            .file = try std.fs.cwd().createFile(filename, .{ .read = true }),
        };
    }

    pub fn writeToSvgFile(self: SvgContainer, msg: []const u8) !void {
        try self.file.writeAll(msg);
    }

    pub fn genBasicSvgFileHeader(self: SvgContainer) !void {
        try self.writeToSvgFile("<svg version=\"1.1\" xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 100 100\">\n");
    }

    pub fn addBasicSvgSuffix(self: SvgContainer) !void {
        try self.writeToSvgFile("</svg>");
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
        var buffer = [_]u8{0} ** 256; // Buffer must be large enough

        // Formats into the stack-allocated buffer
        const written = try formatSvgCircle(circle, &buffer);
        try self.writeToSvgFile(written);
    }

    pub fn closeSvgFile(self: SvgContainer) !void {
        self.file.close();
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

pub fn main() !void {
    // Prints to stderr, ignoring potential errors.
    const rand = std.crypto.random;
    //std.debug.print("All your {s} are belong to us.\n", .{"codebase"});
    //try zig_svg_graph.bufferedPrint();
    {
        var svg_container = try SvgContainer.open("out.svg");
        defer svg_container.closeSvgFile() catch @panic("couldnt close svg file");
        try svg_container.genBasicSvgFileHeader();

        defer svg_container.addBasicSvgSuffix() catch @panic("Couldn't close svg");

        const color = [_]SvgColorType{ SvgColorType{ .named = "mediumorchid" }, SvgColorType{ .named = "midnightblue" }, SvgColorType{ .named = "navajowhite" } };

        for (0..300) |_| {
            const my_circle = SvgCircle{ .x = rand.int(u32) % 100, .y = rand.int(u32) % 100, .radius = rand.int(u32) % 5 + 1, .color = color[rand.int(u32) % color.len] };
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

test "fuzz example" {
    const Context = struct {
        fn testOne(context: @This(), input: []const u8) anyerror!void {
            _ = context;
            // Try passing `--fuzz` to `zig build test` and see if it manages to fail this test case!
            try std.testing.expect(!std.mem.eql(u8, "canyoufindme", input));
        }
    };
    try std.testing.fuzz(Context{}, Context.testOne, .{});
}
