const std = @import("std");
const util = @import("util.zig");

const data = @embedFile("../data/day14.txt");

const Input = struct {
    template: []const u8 = undefined,
    rules: std.StringHashMap(u8) = undefined,

    pub fn init(input_text: []const u8, allocator: std.mem.Allocator) !@This() {
        _ = allocator;
        var input = Input{
            .rules = std.StringHashMap(u8).init(allocator),
        };
        errdefer input.deinit();
        try input.rules.ensureTotalCapacity(100);

        var lines = std.mem.tokenize(u8, input_text, "\r\n");
        input.template = lines.next().?;
        while (lines.next()) |rule| {
            input.rules.putAssumeCapacity(rule[0..2], rule[6]);
        }

        return input;
    }
    pub fn deinit(self: *@This()) void {
        self.rules.deinit();
    }
};

inline fn hashPair(pair: []const u8) u16 {
    return @as(u16, pair[0]) * 256 + @as(u16, pair[1]);
}
inline fn unhashPair(hash: u16) [2]u8 {
    return [2]u8{ @truncate(u8, hash >> 8), @truncate(u8, hash & 0xFF) };
}

fn buildPolymer(input: Input, step_count: usize) i64 {
    var step: usize = 0;
    var polymer = std.AutoHashMap(u16, i64).init(std.testing.allocator);
    polymer.ensureTotalCapacity(26 * 26) catch unreachable;
    {
        var i: usize = 0;
        while (i < input.template.len - 1) : (i += 1) {
            const pair = input.template[i .. i + 2];
            var result = polymer.getOrPut(hashPair(pair)) catch unreachable;
            if (!result.found_existing) {
                result.value_ptr.* = 0;
            }
            result.value_ptr.* += 1;
        }
    }

    while (step < step_count) : (step += 1) {
        var src = polymer;
        defer src.deinit();
        polymer = std.AutoHashMap(u16, i64).init(std.testing.allocator);
        polymer.ensureTotalCapacity(26 * 26) catch unreachable;
        var src_itor = src.iterator();
        while (src_itor.next()) |kv| {
            const pair_hash = kv.key_ptr.*;
            const pair = unhashPair(pair_hash);
            const count = kv.value_ptr.*;
            if (input.rules.get(pair[0..])) |middle| {
                // insert count copies of pair1
                const pair1 = [2]u8{ pair[0], middle };
                var result1 = polymer.getOrPut(hashPair(pair1[0..])) catch unreachable;
                if (!result1.found_existing) {
                    result1.value_ptr.* = 0;
                }
                result1.value_ptr.* += count;
                // insert count copies of pair2
                const pair2 = [2]u8{ middle, pair[1] };
                var result2 = polymer.getOrPut(hashPair(pair2[0..])) catch unreachable;
                if (!result2.found_existing) {
                    result2.value_ptr.* = 0;
                }
                result2.value_ptr.* += count;
            } else {
                // insert count copies of pair
                var result = polymer.getOrPut(pair_hash) catch unreachable;
                if (!result.found_existing) {
                    result.value_ptr.* = 0;
                }
                result.value_ptr.* += count;
            }
        }
    }

    var counts: [26]i64 = .{0} ** 26;
    {
        var itor = polymer.iterator();
        while (itor.next()) |kv| {
            const pair_hash = kv.key_ptr.*;
            const pair = unhashPair(pair_hash);
            const count = kv.value_ptr.*;
            counts[pair[1] - 'A'] += count;
        }
        // The first element never changes
        counts[input.template[0] - 'A'] += 1;
    }
    polymer.deinit();

    var min_count: i64 = std.math.maxInt(i64);
    var max_count: i64 = 0;
    for (counts) |count| {
        if (count == 0) {
            continue;
        }
        min_count = std.math.min(min_count, count);
        max_count = std.math.max(max_count, count);
    }

    return max_count - min_count;
}

fn part1(input: Input) i64 {
    return buildPolymer(input, 10);
}

fn part2(input: Input) i64 {
    return buildPolymer(input, 40);
}

const test_data =
    \\NNCB
    \\
    \\CH -> B
    \\HH -> N
    \\CB -> H
    \\NH -> C
    \\HB -> C
    \\HC -> B
    \\HN -> C
    \\NN -> C
    \\BH -> H
    \\NC -> B
    \\NB -> B
    \\BN -> B
    \\BB -> N
    \\BC -> B
    \\CC -> N
    \\CN -> C
;
const part1_test_solution: ?i64 = 1588;
const part1_solution: ?i64 = 3306;
const part2_test_solution: ?i64 = 2188189693529;
const part2_solution: ?i64 = 3760312702877;

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
