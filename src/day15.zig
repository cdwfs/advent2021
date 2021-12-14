const std = @import("std");
const util = @import("util.zig");

const data = @embedFile("../data/day15.txt");

const Input = struct {
    heightmap: [100][100]u8 = undefined,

    pub fn init(input_text: []const u8, allocator: std.mem.Allocator) !@This() {
        _ = allocator;
        var input = Input{};
        errdefer input.deinit();

        var lines = std.mem.tokenize(u8, input_text, "\r\n");
        while (lines.next()) |line| : (y += 1) {}
        input.dim_y = y;

        return input;
    }
    pub fn deinit(self: @This()) void {
        _ = self;
    }
};

fn part1(input: Input) i64 {
    _ = input;
    return 17;
}

fn part2(input: Input) i64 {
    _ = input;
    return 23;
}

const test_data =
    \\2199943210
    \\3987894921
    \\9856789892
    \\8767896789
    \\9899965678
;
const part1_test_solution: ?i64 = 0;
const part1_solution: ?i64 = null;
const part2_test_solution: ?i64 = null;
const part2_solution: ?i64 = null;

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
        print("part1 took {:15}ns\n", .{timer.lap()});
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
        print("part2 took {:15}ns\n", .{timer.lap()});
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
