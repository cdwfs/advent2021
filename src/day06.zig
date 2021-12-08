const std = @import("std");
const util = @import("util.zig");

const data = @embedFile("../data/day06.txt");

const Input = struct {
    fish_ages: std.ArrayList(u8) = std.ArrayList(u8).init(std.testing.allocator),
    pub fn deinit(self: @This()) void {
        self.fish_ages.deinit();
    }
};

fn parseInput(input_text: []const u8) !Input {
    var input = Input{};
    errdefer input.deinit();

    var ages = std.mem.tokenize(u8, input_text, ",\r\n");
    while (ages.next()) |age| {
        try input.fish_ages.append(try parseInt(u8, age, 10));
    }
    return input;
}

fn simulateFish(input: Input, day_count: usize) i64 {
    var fish_at_age: [9]i64 = .{0} ** 9;
    for (input.fish_ages.items) |age| {
        fish_at_age[age] += 1;
    }
    var day: usize = 0;
    while (day < day_count) : (day += 1) {
        const parent_count = fish_at_age[0];
        std.mem.rotate(i64, fish_at_age[0..], 1);
        fish_at_age[8] = parent_count;
        fish_at_age[6] += parent_count;
    }

    var sum: i64 = 0;
    for (fish_at_age) |fish_count| {
        sum += fish_count;
    }
    return sum;
}

fn part1(input: Input) i64 {
    return simulateFish(input, 80);
}

fn part2(input: Input) i64 {
    return simulateFish(input, 256);
}

const test_data = "3,4,3,1,2";
const part1_test_solution: ?i64 = 5934;
const part1_solution: ?i64 = 388739;
const part2_test_solution: ?i64 = 26984457539;
const part2_solution: ?i64 = 1741362314973;

fn testPart1() !void {
    var test_input = try parseInput(test_data);
    defer test_input.deinit();
    if (part1_test_solution) |solution| {
        try std.testing.expectEqual(solution, part1(test_input));
    }

    var input = try parseInput(data);
    defer input.deinit();
    if (part1_solution) |solution| {
        try std.testing.expectEqual(solution, part1(input));
    }
}

fn testPart2() !void {
    var test_input = try parseInput(test_data);
    defer test_input.deinit();
    if (part2_test_solution) |solution| {
        try std.testing.expectEqual(solution, part2(test_input));
    }

    var input = try parseInput(data);
    defer input.deinit();
    if (part2_solution) |solution| {
        try std.testing.expectEqual(solution, part2(input));
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
