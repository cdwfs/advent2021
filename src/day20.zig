const std = @import("std");
const util = @import("util.zig");

const data = @embedFile("../data/day20.txt");

const Input = struct {
    enhancement: [512]u8 = undefined,
    image: [100][100]u8 = undefined,
    dim: usize,

    pub fn init(input_text: []const u8, allocator: std.mem.Allocator) !@This() {
        _ = allocator;
        var self = Input{ .dim = 0 };
        errdefer self.deinit();

        var lines = std.mem.tokenize(u8, input_text, "\r\n");
        const first_line = lines.next().?;
        assert(first_line.len == 512);
        std.mem.copy(u8, self.enhancement[0..], first_line);
        var y: usize = 0;
        while (lines.next()) |line| : (y += 1) {
            if (y == 0) {
                self.dim = line.len;
            } else {
                assert(line.len == self.dim);
            }
            std.mem.copy(u8, self.image[y][0..], line);
        }

        return self;
    }
    pub fn deinit(self: @This()) void {
        _ = self;
    }
};

const Coord2 = struct {
    x: i64,
    y: i64,
};

const PixelMap = struct {
    pixels: std.AutoHashMap(Coord2, bool),
    enhancement: [512]u8 = undefined,
    min: Coord2,
    max: Coord2,
    pub fn init(input: Input, allocator: std.mem.Allocator) !@This() {
        var self = PixelMap{
            .pixels = std.AutoHashMap(Coord2, bool).init(allocator),
            .min = Coord2{ .x = 0, .y = 0 },
            .max = Coord2{ .x = @intCast(i64, input.dim), .y = @intCast(i64, input.dim) },
        };
        std.mem.copy(u8, self.enhancement[0..], input.enhancement[0..]);
        try self.pixels.ensureTotalCapacity(1000 * 1000);
        var y: usize = 0;
        while (y < input.dim) : (y += 1) {
            var x: usize = 0;
            while (x < input.dim) : (x += 1) {
                if (input.image[y][x] == '#') {
                    try self.pixels.putNoClobber(Coord2{ .x = @intCast(i64, x), .y = @intCast(i64, y) }, true);
                }
            }
        }
        return self;
    }
    pub fn deinit(self: *@This()) void {
        self.pixels.deinit();
    }

    const OFFSETS = [9]Coord2{
        Coord2{ .x = -1, .y = -1 },
        Coord2{ .x = 0, .y = -1 },
        Coord2{ .x = 1, .y = -1 },
        Coord2{ .x = -1, .y = 0 },
        Coord2{ .x = 0, .y = 0 },
        Coord2{ .x = 1, .y = 0 },
        Coord2{ .x = -1, .y = 1 },
        Coord2{ .x = 0, .y = 1 },
        Coord2{ .x = 1, .y = 1 },
    };
    pub fn enhance2(self: *@This()) !void {
        var tmp_pixels = std.AutoHashMap(Coord2, bool).init(self.pixels.allocator);
        defer tmp_pixels.deinit();
        try tmp_pixels.ensureTotalCapacity(2 * self.pixels.count());
        // ping
        var y: i64 = self.min.y - 3;
        while (y <= self.max.y + 3) : (y += 1) {
            var x: i64 = self.min.x - 3;
            while (x <= self.max.x + 3) : (x += 1) {
                const c = Coord2{ .x = x, .y = y };
                var idx: u9 = 0;
                for (OFFSETS) |offset| {
                    idx *= 2;
                    const p = Coord2{ .x = c.x + offset.x, .y = c.y + offset.y };
                    idx += if (self.pixels.contains(p)) @as(u9, 1) else @as(u9, 0);
                }
                if (self.enhancement[idx] == '#') {
                    try tmp_pixels.putNoClobber(c, true);
                }
            }
        }
        // pong
        self.pixels.clearRetainingCapacity();
        try self.pixels.ensureTotalCapacity(2 * tmp_pixels.count());
        var new_min = Coord2{ .x = std.math.maxInt(i64), .y = std.math.maxInt(i64) };
        var new_max = Coord2{ .x = std.math.minInt(i64), .y = std.math.minInt(i64) };
        y = self.min.y - 2;
        while (y <= self.max.y + 1) : (y += 1) {
            var x: i64 = self.min.x - 2;
            while (x <= self.max.x + 1) : (x += 1) {
                const c = Coord2{ .x = x, .y = y };
                var idx: u9 = 0;
                for (OFFSETS) |offset| {
                    idx *= 2;
                    const p = Coord2{ .x = c.x + offset.x, .y = c.y + offset.y };
                    idx += if (tmp_pixels.contains(p)) @as(u9, 1) else @as(u9, 0);
                }
                if (self.enhancement[idx] == '#') {
                    try self.pixels.putNoClobber(c, true);
                    new_min.x = std.math.min(new_min.x, c.x);
                    new_min.y = std.math.min(new_min.y, c.y);
                    new_max.x = std.math.max(new_max.x, c.x + 1);
                    new_max.y = std.math.max(new_max.y, c.y + 1);
                }
            }
        }
        self.min = new_min;
        self.max = new_max;
    }
};

fn part1(input: Input) i64 {
    var pixel_map = PixelMap.init(input, std.testing.allocator) catch unreachable;
    defer pixel_map.deinit();
    pixel_map.enhance2() catch unreachable;
    var count: i64 = 0;
    var py: i64 = pixel_map.min.y;
    while (py < pixel_map.max.y) : (py += 1) {
        var px: i64 = pixel_map.min.x;
        while (px < pixel_map.max.x) : (px += 1) {
            const c = Coord2{ .x = px, .y = py };
            if (pixel_map.pixels.contains(c)) {
                count += 1;
            }
        }
    }
    return count;
}

fn part2(input: Input) i64 {
    var pixel_map = PixelMap.init(input, std.testing.allocator) catch unreachable;
    defer pixel_map.deinit();

    var i: i64 = 0;
    while (i < 25) : (i += 1) {
        print("{d} ", .{i + 1});
        pixel_map.enhance2() catch unreachable;
    }
    print("\n", .{});

    var count: i64 = 0;
    var py: i64 = pixel_map.min.y;
    while (py < pixel_map.max.y) : (py += 1) {
        var px: i64 = pixel_map.min.x;
        while (px < pixel_map.max.x) : (px += 1) {
            const c = Coord2{ .x = px, .y = py };
            if (pixel_map.pixels.contains(c)) {
                count += 1;
            }
        }
    }
    return count;
}

const test_data =
    \\..#.#..#####.#.#.#.###.##.....###.##.#..###.####..#####..#....#..#..##..###..######.###...####..#..#####..##..#.#####...##.#.#..#.##..#.#......#.###.######.###.####...#.##.##..#..#..#####.....#.#....###..#.##......#.....#..#..#..##..#...##.######.####.####.#.#...#.......#..#.#.#...####.##.#......#..#...##.#.##..#...##.#.##..###.#......#.#.......#.#.#.####.###.##...#.....####.#..#..#.##.#....##..#.####....##...##..#...#......#.#.......#.......##..####..#...#.#.#...##..#.#..###..#####........#..####......#..#
    \\
    \\#..#.
    \\#....
    \\##..#
    \\..#..
    \\..###
;
const part1_test_solution: ?i64 = 35;
const part1_solution: ?i64 = 5573;
const part2_test_solution: ?i64 = 3351;
const part2_solution: ?i64 = 20097; // 20582 is too high

// Just boilerplate below here, nothing to see

fn testPart1() !void {
    var test_input = try Input.init(test_data, std.testing.allocator);
    defer test_input.deinit();
    if (part1_test_solution) |solution| {
        try std.testing.expectEqual(solution, part1(test_input));
    }

    var timer = try std.time.Timer.start();
    var input = try Input.init(data, std.testing.allocator);
    defer input.deinit();
    if (part1_solution) |solution| {
        try std.testing.expectEqual(solution, part1(input));
        print("part1 took {d:9.3}ms\n", .{@intToFloat(f64, timer.lap()) / 1000000.0});
    }
}

fn testPart2() !void {
    var test_input = try Input.init(test_data, std.testing.allocator);
    defer test_input.deinit();
    if (part2_test_solution) |solution| {
        try std.testing.expectEqual(solution, part2(test_input));
    }

    var timer = try std.time.Timer.start();
    var input = try Input.init(data, std.testing.allocator);
    defer input.deinit();
    if (part2_solution) |solution| {
        try std.testing.expectEqual(solution, part2(input));
        print("part2 took {d:9.3}ms\n", .{@intToFloat(f64, timer.lap()) / 1000000.0});
    }
}

pub fn main() !void {
    try testPart1();
    try testPart2();
}

test "part1" {
    try testPart1();
}

test "part2" {
    try testPart2();
}

// Useful stdlib functions
const tokenize = std.mem.tokenize;
const split = std.mem.split;
const parseInt = std.fmt.parseInt;
const min = std.math.min;
const max = std.math.max;
const print = std.debug.print;
const expect = std.testing.expect;
const assert = std.debug.assert;
