const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;
const Str = []const u8;

const util = @import("util.zig");
const gpa = util.gpa;

const data = @embedFile("../data/day03.txt");

fn parseInput(input_text: []const u8) std.ArrayList([]const u8) {
    var list = std.ArrayList([]const u8).init(std.testing.allocator);
    var lines = tokenize(u8, input_text, "\r\n");
    while (lines.next()) |line| {
        list.append(line) catch unreachable;
    }
    return list;
}

fn bitDeltaAtPosition(input:std.ArrayList([]const u8), skip:?std.ArrayList(bool), bit_index:usize) i64 {
    var delta:i64 = 0;
    for (input.items) |bits,i| {
        if (skip == null or !skip.?.items[i])
            delta = if (bits[bit_index] == '0') delta-1 else delta+1;
    }
    return delta;
}

fn part1(input:std.ArrayList([]const u8)) i64 {
    var gamma_rate:i64 = 0;
    var epsilon_rate:i64 = 0;
    var i:usize = 0;

    const bit_count = input.items[0].len;
    while(i < bit_count) : (i += 1) {
        const delta = bitDeltaAtPosition(input, null, i);
        gamma_rate *= 2;
        gamma_rate += if (delta > 0) @as(i64, 1) else @as(i64, 0);
        epsilon_rate *= 2;
        epsilon_rate += if (delta > 0) @as(i64, 0) else @as(i64, 1);
    }

    return gamma_rate * epsilon_rate;
}

fn part2(input:std.ArrayList([]const u8)) i64 {
    var i:usize = 0;

    var skip = std.ArrayList(bool).init(std.testing.allocator);
    skip.ensureTotalCapacity(input.items.len) catch unreachable;
    defer skip.deinit();
    while(i < input.items.len) : (i += 1) {
        skip.append(false) catch unreachable;
    }

    const bit_count = input.items[0].len;

    var winner:usize = input.items.len;
    var candidates_remaining = input.items.len;
    i=0;
    var oxygen_rating = while(i < bit_count) : (i += 1) {
        const delta = bitDeltaAtPosition(input, skip, i);
        const target:u8 = if (delta >= 0) '1' else '0';
        for(input.items) |bits,j| {
            if (skip.items[j]) {
                continue;
            }
            if (bits[i] != target) {
                skip.items[j] = true;
                candidates_remaining -= 1;
                continue;
            }
            winner = j;
        }
        if (candidates_remaining == 1) {
            break parseInt(i64, input.items[winner], 2) catch unreachable;
        }
    } else -1;

    winner = input.items.len;
    candidates_remaining = input.items.len;
    std.mem.set(bool, skip.items, false);
    i=0;
    var co2_rating = while(i < bit_count) : (i += 1) {
        const delta = bitDeltaAtPosition(input, skip, i);
        const target:u8 = if (delta >= 0) '0' else '1'; // flip target for CO2 scrubber
        for(input.items) |bits,j| {
            if (skip.items[j]) {
                continue;
            }
            if (bits[i] != target) {
                skip.items[j] = true;
                candidates_remaining -= 1;
                continue;
            }
            winner = j;
        }
        if (candidates_remaining == 1) {
            break parseInt(i64, input.items[winner], 2) catch unreachable;
        }
    } else -1;

    return oxygen_rating * co2_rating;
}


pub fn main() !void {}

const test_data =
    \\00100
    \\11110
    \\10110
    \\10111
    \\10101
    \\01111
    \\00111
    \\11100
    \\10000
    \\11001
    \\00010
    \\01010
;

test "part1" {
    const test_input = parseInput(test_data);
    defer test_input.deinit();
    try std.testing.expectEqual(@as(i64, 198), part1(test_input));

    const input = parseInput(data);
    defer input.deinit();
    try std.testing.expectEqual(@as(i64, 4001724), part1(input));
}

test "part2" {
    const test_input = parseInput(test_data);
    defer test_input.deinit();
    try std.testing.expectEqual(@as(i64, 230), part2(test_input));

    const input = parseInput(data);
    defer input.deinit();
    try std.testing.expectEqual(@as(i64, 587895), part2(input));
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
