const std = @import("std");
const util = @import("util.zig");

const data = @embedFile("../data/day17.txt");

const Input = struct {
    x_min: i64,
    x_max: i64,
    y_min: i64,
    y_max: i64,

    pub fn init(input_text: []const u8, allocator: std.mem.Allocator) !@This() {
        _ = allocator;

        var nums = std.mem.tokenize(u8, input_text[15..], "., y=\r\n");
        var input = Input{
            .x_min = try parseInt(i64, nums.next().?, 10),
            .x_max = try parseInt(i64, nums.next().?, 10),
            .y_min = try parseInt(i64, nums.next().?, 10),
            .y_max = try parseInt(i64, nums.next().?, 10),
        };
        errdefer input.deinit();

        return input;
    }
    pub fn deinit(self: @This()) void {
        _ = self;
    }
};

fn hitsTargetArea(input: Input, x_vel: i64, y_vel: i64, y_max: ?*i64) bool {
    var x: i64 = 0;
    var y: i64 = 0;
    var y_highest: i64 = 0;
    var xv: i64 = x_vel;
    var yv: i64 = y_vel;
    while (x <= input.x_max and y >= input.y_min) {
        x += xv;
        y += yv;
        y_highest = std.math.max(y_highest, y);
        xv = if (xv > 0) xv - 1 else if (xv < 0) xv + 1 else 0;
        yv -= 1;
        if (x >= input.x_min and x <= input.x_max and y >= input.y_min and y <= input.y_max) {
            if (y_max != null) {
                y_max.?.* = y_highest;
            }
            return true;
        }
    }
    return false;
}

fn triangleNumFloor(n: i64) i64 {
    assert(n >= 1);
    var sum: i64 = 0;
    var tri: i64 = 0;
    while (sum < n) {
        tri += 1;
        sum += tri;
    }
    return tri;
}

fn part1(input: Input) i64 {
    const x_vel: i64 = triangleNumFloor(input.x_min);
    const y_vel: i64 = -input.y_min - 1;
    var y_max: i64 = undefined;
    assert(hitsTargetArea(input, x_vel, y_vel, &y_max));
    return y_max;
}

fn part2(input: Input) i64 {
    const xv_min: i64 = triangleNumFloor(input.x_min);
    const xv_max: i64 = input.x_max + 1;
    const yv_min: i64 = input.y_min - 1;
    const yv_max: i64 = -input.y_min - 1;
    var hit_count: i64 = 0;
    var yv = yv_min;
    while (yv <= yv_max) : (yv += 1) {
        var xv = xv_min;
        while (xv <= xv_max) : (xv += 1) {
            if (hitsTargetArea(input, xv, yv, null)) {
                hit_count += 1;
            }
        }
    }
    return hit_count;
}

const test_data =
    \\target area: x=20..30, y=-10..-5
;
const part1_test_solution: ?i64 = 45;
const part1_solution: ?i64 = 2850;
const part2_test_solution: ?i64 = 112;
const part2_solution: ?i64 = 1117;

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
