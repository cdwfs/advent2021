const std = @import("std");
const util = @import("util.zig");

const data = @embedFile("data/day13.txt");

const Coord2 = struct {
    x: usize,
    y: usize,
};
const Fold = struct {
    axis: u8,
    value: usize,
};
const Input = struct {
    dots: std.ArrayList(Coord2),
    folds: std.ArrayList(Fold),
    max_x: usize,
    max_y: usize,

    pub fn init(input_text: []const u8, allocator: std.mem.Allocator) !@This() {
        var input = Input{
            .dots = try std.ArrayList(Coord2).initCapacity(allocator, 800),
            .folds = try std.ArrayList(Fold).initCapacity(allocator, 16),
            .max_x = 0,
            .max_y = 0,
        };
        errdefer input.deinit();

        var lines = std.mem.tokenize(u8, input_text, "\r\n");
        while (lines.next()) |line| {
            if (line[0] != 'f') {
                var nums = std.mem.tokenize(u8, line, ",");
                const x = try parseInt(usize, nums.next().?, 10);
                const y = try parseInt(usize, nums.next().?, 10);
                input.max_x = std.math.max(input.max_x, x);
                input.max_y = std.math.max(input.max_y, y);
                //print("{d},{d}\n", .{x,y});
                try input.dots.append(Coord2{ .x = x, .y = y });
            } else {
                const axis = line[11];
                assert(axis == 'x' or axis == 'y');
                const value = try parseInt(usize, line[13..], 10);
                //print("fold at {c}={d}\n", .{axis,value});
                try input.folds.append(Fold{ .axis = axis, .value = value });
            }
        }

        return input;
    }
    pub fn deinit(self: @This()) void {
        self.dots.deinit();
        self.folds.deinit();
    }
};

fn processFold(cells: std.ArrayList(u8), fold: Fold, w: *usize, h: *usize, pitch: usize) void {
    if (fold.axis == 'y') {
        assert(fold.value < h.*);
        var tx: usize = 0;
        while (tx < w.*) : (tx += 1) {
            assert(cells.items[fold.value * w.* + tx] == '.');
        }
        var y: usize = fold.value + 1;
        while (y < h.*) : (y += 1) {
            var x: usize = 0;
            while (x < w.*) : (x += 1) {
                if (cells.items[y * pitch + x] == '#') {
                    const dy = y - fold.value;
                    const y2 = fold.value - dy;
                    cells.items[y2 * pitch + x] = '#';
                    cells.items[y * pitch + x] = '.';
                }
            }
        }
        h.* = fold.value;
    } else if (fold.axis == 'x') {
        assert(fold.value < w.*);
        var ty: usize = 0;
        while (ty < h.*) : (ty += 1) {
            assert(cells.items[ty * pitch + fold.value] == '.');
        }
        var y: usize = 0;
        while (y < h.*) : (y += 1) {
            var x: usize = fold.value + 1;
            while (x < w.*) : (x += 1) {
                if (cells.items[y * pitch + x] == '#') {
                    const dx = x - fold.value;
                    const x2 = fold.value - dx;
                    cells.items[y * pitch + x2] = '#';
                    cells.items[y * pitch + x] = '.';
                }
            }
        }
        w.* = fold.value;
    }
}

fn part1(input: Input) i64 {
    var w = input.max_x + 1;
    var h = input.max_y + 1;
    const pitch = w;
    var cells = std.ArrayList(u8).initCapacity(std.testing.allocator, pitch * h) catch unreachable;
    defer cells.deinit();
    cells.appendNTimesAssumeCapacity('.', cells.capacity);
    for (input.dots.items) |dot| {
        cells.items[dot.y * pitch + dot.x] = '#';
    }

    processFold(cells, input.folds.items[0], &w, &h, pitch);

    var dot_count: i64 = 0;
    var y: usize = 0;
    while (y < h) : (y += 1) {
        var x: usize = 0;
        while (x < w) : (x += 1) {
            if (cells.items[y * pitch + x] == '#') {
                dot_count += 1;
            }
        }
    }

    return dot_count;
}

fn part2(input: Input) i64 {
    var w = input.max_x + 1;
    var h = input.max_y + 1;
    const pitch = w;
    var cells = std.ArrayList(u8).initCapacity(std.testing.allocator, pitch * h) catch unreachable;
    defer cells.deinit();
    cells.appendNTimesAssumeCapacity('.', cells.capacity);
    for (input.dots.items) |dot| {
        cells.items[dot.y * pitch + dot.x] = '#';
    }

    for (input.folds.items) |fold| {
        processFold(cells, fold, &w, &h, pitch);
    }

    // This puzzle's output is a bitmap containing 8 characters of text.
    // Print the bitmap and then return a dummy value.
    var y: usize = 0;
    print("\n", .{});
    while (y < h) : (y += 1) {
        var x: usize = 0;
        while (x < w) : (x += 1) {
            print("{c}", .{cells.items[y * pitch + x]});
        }
        print("\n", .{});
    }

    return 23;
}

const test_data =
    \\6,10
    \\0,14
    \\9,10
    \\0,3
    \\10,4
    \\4,11
    \\6,0
    \\6,12
    \\4,1
    \\0,13
    \\10,12
    \\3,4
    \\3,0
    \\8,4
    \\1,10
    \\2,14
    \\8,10
    \\9,0
    \\
    \\fold along y=7
    \\fold along x=5
;
const part1_test_solution: ?i64 = 17;
const part1_solution: ?i64 = 664;
const part2_test_solution: ?i64 = null;
const part2_solution: ?i64 = 23;

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
