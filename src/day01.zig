const std = @import("std");
const Allocator = std.mem.Allocator;
const assert = std.debug.assert;
const expect = std.testing.expect;
const print = std.debug.print;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;
const Str = []const u8;

const util = @import("util.zig");
const gpa = util.gpa;

const data = @embedFile("../data/day01.txt");

fn parseInput(inputText:[]const u8) std.ArrayList(u32) {
    var list = std.ArrayList(u32).init(std.testing.allocator);
    var nums = std.mem.tokenize(u8, inputText, "\r\n");
    while(nums.next()) |numStr| {
        const num = std.fmt.parseInt(u32, numStr, 10) catch unreachable;
        list.append(num) catch unreachable;
    }
    return list;
}

fn countIncreases(inputList:std.ArrayList(u32), windowSize:u32) u32 {
    var increaseCount:u32 = 0;
    var i:usize = 0;
    var prevSum:u32 = 0;
    while(i < windowSize) : (i += 1) {
        prevSum += inputList.items[i];
    }
    i = windowSize;
    while(i < inputList.items.len) : (i += 1) {
        const sum = prevSum - inputList.items[i-windowSize] + inputList.items[i];
        if (sum > prevSum)
            increaseCount += 1;
        prevSum = sum;
    }
    return increaseCount;
}

pub fn main() !void {
    const inputList = parseInput(data);
    defer inputList.deinit();

    const part1 = countIncreases(inputList, 1);
    try expect(part1 == 1451);
    print("Part 1: {d}\n", .{part1});

    const part2 = countIncreases(inputList, 3);
    try expect(part1 == 1395);
    print("Part 2: {d}\n", .{part2});
}

const testData = 
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
    const testList = parseInput(testData);
    defer testList.deinit();
    const increases = countIncreases(testList, 1);
    try expect(increases == 7);
}

test "part2" {
    const testList = parseInput(testData);
    defer testList.deinit();
    const increases = countIncreases(testList, 3);
    try expect(increases == 5);
}
