const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;
const Str = []const u8;

const util = @import("util.zig");
const gpa = util.gpa;

const data = @embedFile("../data/day02.txt");

const MoveDir = enum {
    Forward,
    Down,
    Up,
};
const Move = struct {
    dir: MoveDir,
    distance: i64,
};

fn parseInput(inputText: []const u8) std.ArrayList(Move) {
    var list = std.ArrayList(Move).init(std.testing.allocator);
    var lines = tokenize(u8, inputText, "\r\n");
    while (lines.next()) |line| {
        var tokens = tokenize(u8, line, " ");
        const dir_str = tokens.next().?;
        const dir = switch (dir_str[0]) {
            'f' => MoveDir.Forward,
            'd' => MoveDir.Down,
            'u' => MoveDir.Up,
            else => unreachable,
        };
        const dist = parseInt(i64, tokens.next().?, 10) catch unreachable;
        list.append(Move{ .dir = dir, .distance = dist }) catch unreachable;
    }
    return list;
}

fn finalProductXY(input: std.ArrayList(Move)) i64 {
    var horizontal: i64 = 0;
    var depth: i64 = 0;
    for (input.items) |move| {
        switch (move.dir) {
            MoveDir.Forward => {
                horizontal += move.distance;
            },
            MoveDir.Down => {
                depth += move.distance;
            },
            MoveDir.Up => {
                depth -= move.distance;
            },
        }
    }
    return horizontal * depth;
}

fn finalProductXYWithAim(input: std.ArrayList(Move)) i64 {
    var horizontal: i64 = 0;
    var depth: i64 = 0;
    var aim: i64 = 0;
    for (input.items) |move| {
        switch (move.dir) {
            MoveDir.Forward => {
                horizontal += move.distance;
                depth += aim * move.distance;
            },
            MoveDir.Down => {
                aim += move.distance;
            },
            MoveDir.Up => {
                aim -= move.distance;
            },
        }
    }
    return horizontal * depth;
}

pub fn main() !void {}

const test_data =
    \\forward 5
    \\down 5
    \\forward 8
    \\up 3
    \\down 8
    \\forward 2
;

test "part1" {
    const test_input = parseInput(test_data);
    defer test_input.deinit();
    const result = finalProductXY(test_input);
    try std.testing.expectEqual(@as(i64, 150), result);

    const input = parseInput(data);
    defer input.deinit();
    try std.testing.expectEqual(@as(i64, 1804520), finalProductXY(input));
}

test "part2" {
    const test_input = parseInput(test_data);
    defer test_input.deinit();
    try std.testing.expectEqual(@as(i64, 900), finalProductXYWithAim(test_input));

    const input = parseInput(data);
    defer input.deinit();
    try std.testing.expectEqual(@as(i64, 1971095320), finalProductXYWithAim(input));
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
