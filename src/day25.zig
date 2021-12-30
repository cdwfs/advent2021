const std = @import("std");
const util = @import("util.zig");

const data = @embedFile("../data/day25.txt");

const Input = struct {
    map: [140][140]u8 = undefined,
    dim_x: usize = 0,
    dim_y: usize = 0,

    pub fn init(input_text: []const u8, allocator: std.mem.Allocator) !@This() {
        _ = allocator;
        var self = Input{};
        errdefer self.deinit();

        var lines = std.mem.tokenize(u8, input_text, "\r\n");
        while (lines.next()) |line| : (self.dim_y += 1) {
            self.dim_x = line.len;
            std.mem.copy(u8, self.map[self.dim_y][0..], line);
        }

        return self;
    }
    pub fn deinit(self: @This()) void {
        _ = self;
    }
};

fn part1(input: Input) i64 {
    var mapA = input.map;
    var mapB = input.map;
    var step: i64 = 1;
    while (true) : (step += 1) {
        var moved: bool = false;
        // move >
        mapB = mapA;
        var y: usize = 0;
        while (y < input.dim_y) : (y += 1) {
            var x: usize = 0;
            while (x < input.dim_x) : (x += 1) {
                const x2 = @mod(x + 1, input.dim_x);
                if (mapA[y][x] == '>' and mapA[y][x2] == '.') {
                    mapB[y][x2] = '>';
                    mapB[y][x] = '.';
                    moved = true;
                }
            }
        }
        // move v
        mapA = mapB;
        y = 0;
        while (y < input.dim_y) : (y += 1) {
            const y2 = @mod(y + 1, input.dim_y);
            var x: usize = 0;
            while (x < input.dim_x) : (x += 1) {
                if (mapB[y][x] == 'v' and mapB[y2][x] == '.') {
                    mapA[y2][x] = 'v';
                    mapA[y][x] = '.';
                    moved = true;
                }
            }
        }
        if (!moved)
            return step;
    }
    unreachable;
}

const test_data =
    \\v...>>.vv>
    \\.vv>>.vv..
    \\>>.>v>...v
    \\>>v>>.>.v.
    \\v>v.vv.v..
    \\>.>>..v...
    \\.vv..>.>v.
    \\v.v..>>v.v
    \\....v..v.>
;
const part1_test_solution: ?i64 = 58;
const part1_solution: ?i64 = 378;

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

pub fn main() !void {
    try testPart1();
}

test "part1" {
    try testPart1();
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
