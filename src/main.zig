const std = @import("std");
const zig_svg_graph = @import("zig_svg_graph");

pub fn seekEndOfFile(file: std.fs.File) !void {
    const stat = try file.stat();
    try file.seekTo(stat.size); // Position the cursor at the end
}

const SvgContainer = struct {
    filename: []const u8,

    pub fn genBasicSvgFileHeader(self: SvgContainer) !void {
        const file = try std.fs.cwd().createFile(
            self.filename,
            .{ .read = true },
        );
        defer file.close();

        try file.writeAll("<svg version=\"1.1\" xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 100 100\">\n");
    }

    pub fn addBasicSvgSuffix(self: SvgContainer) !void {
        const file = try std.fs.cwd().openFile(self.filename, .{ .mode = .read_write });
        defer file.close();
        try seekEndOfFile(file);
        try file.writeAll("</svg>");
    }

    pub fn addSvgCircle(self: SvgContainer, circle: SvgCircle) !void {
        const file = try std.fs.cwd().openFile(self.filename, .{ .mode = .read_write });
        defer file.close();
        try seekEndOfFile(file);

        var buffer: [1024]u8 = undefined; // Buffer must be large enough

        var msg: ?[]u8 = null;
        // Formats into the stack-allocated buffer
        switch (circle.color) {
            SvgColorTypeTag.named => {
                msg = try std.fmt.bufPrint(&buffer, "<circle xmlns=\"http://www.w3.org/2000/svg\" cx=\"{d}\" cy=\"{d}\" r=\"{d}\" fill=\"{s}\">\n", .{ circle.x, circle.y, circle.radius, circle.color.named });
            },
            SvgColorTypeTag.rgb => {
                msg = try std.fmt.bufPrint(&buffer, "<circle xmlns=\"http://www.w3.org/2000/svg\" cx=\"{d}\" cy=\"{d}\" r=\"{d}\" fill=\"rgb({d}{d}{d})\">\n", .{ circle.x, circle.y, circle.radius, circle.color.rgb.r, circle.color.rgb.g, circle.color.rgb.b });
            },
        }
        if (msg) |message| {
            try file.writeAll(message);
        }
    }

    pub fn closeSvgCircle(self: SvgContainer) !void {
        const file = try std.fs.cwd().openFile(self.filename, .{ .mode = .read_write });
        defer file.close();
        try seekEndOfFile(file);
        try file.writeAll("</circle>\n");
    }
};

const SvgColorTypeTag = enum {
    named,
    rgb,
};

const RgbSvgColor = struct { r: u8, g: u8, b: u8 };

const SvgColorType = union(SvgColorTypeTag) {
    named: []const u8,
    rgb: RgbSvgColor,
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
        const svg_container = SvgContainer{ .filename = "out.svg" };
        try svg_container.genBasicSvgFileHeader();

        defer svg_container.addBasicSvgSuffix() catch @panic("Couldn't close svg");

        const color = SvgColorType{ .named = "mediumorchid" };
        for (0..300) |_| {
            const my_circle = SvgCircle{ .x = rand.int(u32) % 100, .y = rand.int(u32) % 100, .radius = rand.int(u32) % 5 + 1, .color = color };
            try svg_container.addSvgCircle(my_circle);
            defer svg_container.closeSvgCircle() catch @panic("Couldn't close svg circle");
        }
    }

    // simple svg generation
}

test "simple test" {
    const gpa = std.testing.allocator;
    var list: std.ArrayList(i32) = .empty;
    defer list.deinit(gpa); // Try commenting this out and see if zig detects the memory leak!
    try list.append(gpa, 42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
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
