const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;
const Str = []const u8;

const util = @import("util.zig");
const gpa = util.gpa;

const data = @embedFile("data/day01.txt");

fn parseInput(input_text: []const u8) std.ArrayList(u64) {
    var list = std.ArrayList(u64).init(std.testing.allocator);
    var lines = tokenize(u8, input_text, "\r\n");
    while (lines.next()) |line| {
        const num = parseInt(u64, line, 10) catch unreachable;
        list.append(num) catch unreachable;
    }
    return list;
}

fn countIncreases(input: std.ArrayList(u64), window_size: u64) u64 {
    var count: u64 = 0;
    var i: usize = 0;
    var prev_sum: u64 = 0;
    while (i < window_size) : (i += 1) {
        prev_sum += input.items[i];
    }
    i = window_size;
    while (i < input.items.len) : (i += 1) {
        const sum = prev_sum - input.items[i - window_size] + input.items[i];
        if (sum > prev_sum)
            count += 1;
        prev_sum = sum;
    }
    return count;
}

pub fn main() !void {}

const test_data =
    \\199
    \\200
    \\208
    \\210
    \\200
    \\207
    \\240
    \\269
    \\260
    \\263
;

test "part1" {
    const test_input = parseInput(test_data);
    defer test_input.deinit();
    try std.testing.expectEqual(@as(u64, 7), countIncreases(test_input, 1));

    const input = parseInput(data);
    defer input.deinit();
    try std.testing.expectEqual(@as(u64, 1451), countIncreases(input, 1));
}

test "part2" {
    const test_input = parseInput(test_data);
    defer test_input.deinit();
    try std.testing.expectEqual(@as(u64, 5), countIncreases(test_input, 3));

    const input = parseInput(data);
    defer input.deinit();
    try std.testing.expectEqual(@as(u64, 1395), countIncreases(input, 3));
}

// Useful stdlib functions
const tokenize = std.mem.tokenize;
const split = std.mem.split;
const indexOf = std.mem.indexOfScalar;
const indexOfAny = std.mem.indexOfAny;
const indexOfStr = std.mem.indexOfPosLinear;
const lastIndexOf = std.mem.lastIndexOfScalar;
const lastIndexOfAny = std.mem.lastIndexOfAny;
const lastIndexOfStr = std.mem.lastIndexOfLinear;
const trim = std.mem.trim;
const sliceMin = std.mem.min;
const sliceMax = std.mem.max;

const parseInt = std.fmt.parseInt;
const parseFloat = std.fmt.parseFloat;

const min = std.math.min;
const min3 = std.math.min3;
const max = std.math.max;
const max3 = std.math.max3;

const print = std.debug.print;
const assert = std.debug.assert;

const sort = std.sort.sort;
const asc = std.sort.asc;
const desc = std.sort.desc;
