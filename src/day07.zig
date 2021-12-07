const std = @import("std");
const util = @import("util.zig");

const data = @embedFile("../data/day07.txt");

const Input = struct {
    positions: std.ArrayList(u11) = std.ArrayList(u11).init(std.testing.allocator),
    pub fn init() !@This() {
        var instance = Input{};
        try instance.positions.ensureTotalCapacity(2000);
        return instance;
    }
    pub fn deinit(self: @This()) void {
        self.positions.deinit();
    }
};

fn parseInput(input_text: []const u8) !Input {
    var input = try Input.init();
    errdefer input.deinit();

    var positions = std.mem.tokenize(u8, input_text, ",\r\n");
    while (positions.next()) |pos| {
        try input.positions.append(try parseInt(u11, pos, 10));
    }
    return input;
}

fn part1(input: Input) i64 {
    var crabs_at_pos: [2048]i64 = .{0} ** 2048;
    const total_crab_count: i64 = @intCast(i64, input.positions.items.len);
    for (input.positions.items) |pos| {
        crabs_at_pos[pos] += 1;
    }

    var crabs_left: i64 = 0;
    var crabs_right: i64 = total_crab_count;
    var min_balance: i64 = std.math.maxInt(i64);
    var pos_for_min_balance: usize = undefined;
    for (crabs_at_pos) |count, pos| {
        crabs_right -= count;
        const balance = std.math.absInt(crabs_left - crabs_right) catch unreachable;
        if (balance < min_balance) {
            min_balance = balance;
            pos_for_min_balance = pos;
        }
        crabs_left += count;
        if (crabs_right == 0) {
            break;
        }
    }

    crabs_right = 0;
    var fuel: i64 = 0;
    for (crabs_at_pos) |count, pos| {
        crabs_right -= count;
        const distance = std.math.absInt(@intCast(i64, pos) - @intCast(i64, pos_for_min_balance)) catch unreachable;
        fuel += crabs_at_pos[pos] * distance;
        if (crabs_right == 0) {
            break;
        }
    }
    return fuel;
}

fn part2(input: Input) i64 {
    var crabs_at_pos: [2048]i64 = .{0} ** 2048;
    const total_crab_count: i64 = @intCast(i64, input.positions.items.len);
    for (input.positions.items) |pos| {
        crabs_at_pos[pos] += 1;
    }

    // Just brute-force it!
    var min_fuel: i64 = std.math.maxInt(i64);
    var pos_for_min_fuel: usize = undefined;
    var target_pos: usize = 0;
    var crabs_remaining: i64 = total_crab_count;
    while (target_pos < crabs_at_pos.len) : (target_pos += 1) {
        var fuel: i64 = 0;
        for (crabs_at_pos) |count, pos| {
            const distance = std.math.absInt(@intCast(i64, pos) - @intCast(i64, target_pos)) catch unreachable;
            fuel += count * @divFloor(distance * (distance + 1), 2);
        }
        if (fuel < min_fuel) {
            min_fuel = fuel;
            pos_for_min_fuel = target_pos;
        }
        crabs_remaining -= crabs_at_pos[target_pos];
        if (crabs_remaining == 0) {
            break;
        }
    }
    return min_fuel;
}

const test_data = "16,1,2,0,4,2,7,1,2,14";
const part1_test_solution: ?i64 = 37;
const part1_solution: ?i64 = 348664;
const part2_test_solution: ?i64 = 168;
const part2_solution: ?i64 = 100220525;

// Just boilerplate below here, nothing to see

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
