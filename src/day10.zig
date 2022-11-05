const std = @import("std");
const util = @import("util.zig");

const data = @embedFile("data/day10.txt");

const Input = struct {
    lines: std.ArrayList([]const u8),

    pub fn init(input_text: []const u8, allocator: std.mem.Allocator) !@This() {
        _ = allocator;
        var input = Input{
            .lines = std.ArrayList([]const u8).initCapacity(allocator, 110) catch unreachable,
        };
        errdefer input.deinit();

        var lines = std.mem.tokenize(u8, input_text, "\r\n");
        while (lines.next()) |line| {
            input.lines.append(line) catch unreachable;
        }

        return input;
    }
    pub fn deinit(self: @This()) void {
        self.lines.deinit();
    }
};

fn part1(input: Input) i64 {
    var openers = std.ArrayList(u8).initCapacity(std.testing.allocator, input.lines.items[0].len) catch unreachable;
    defer openers.deinit();
    var score: i64 = 0;
    for (input.lines.items) |line, i| {
        openers.shrinkRetainingCapacity(0);
        for (line) |c| {
            if (c == '[' or c == '(' or c == '{' or c == '<') {
                openers.append(c) catch unreachable;
            } else if (c == ']' or c == ')' or c == '}' or c == '>') {
                assert(openers.items.len > 0);
                const o = openers.pop();
                if ((o == '[' and c != ']') or
                    (o == '(' and c != ')') or
                    (o == '{' and c != '}') or
                    (o == '<' and c != '>'))
                {
                    _ = i;
                    //print("Line {d} is corrupt: Opened with {c} but closed with {c} instead\n", .{i, o, c});
                    if (c == ']') {
                        score += 57;
                    } else if (c == ')') {
                        score += 3;
                    } else if (c == '}') {
                        score += 1197;
                    } else if (c == '>') {
                        score += 25137;
                    } else {
                        unreachable;
                    }
                    continue;
                }
            }
        }
    }
    return score;
}

fn part2(input: Input) i64 {
    var openers = std.ArrayList(u8).initCapacity(std.testing.allocator, input.lines.items[0].len) catch unreachable;
    defer openers.deinit();
    var scores = std.ArrayList(i64).initCapacity(std.testing.allocator, input.lines.items.len) catch unreachable;
    defer scores.deinit();
    outer: for (input.lines.items) |line, i| {
        var score: i64 = 0;
        openers.shrinkRetainingCapacity(0);
        for (line) |c| {
            if (c == '(' or c == '[' or c == '{' or c == '<') {
                openers.append(c) catch unreachable;
            } else if (c == ')' or c == ']' or c == '}' or c == '>') {
                assert(openers.items.len > 0);
                const o = openers.pop();
                if ((o == '(' and c != ')') or
                    (o == '[' and c != ']') or
                    (o == '{' and c != '}') or
                    (o == '<' and c != '>'))
                {
                    //print("Line {d} is corrupt: Opened with {c} but closed with {c} instead\n", .{i, o, c});
                    continue :outer;
                }
            }
        }
        if (openers.items.len > 0) {
            _ = i;
            //print("Line {d} is incomplete: closing sequence is ", .{i});
            while (openers.items.len > 0) {
                const o = openers.pop();
                if (o == '(') {
                    //print(")", .{});
                    score = (score * 5) + 1;
                } else if (o == '[') {
                    //print("]", .{});
                    score = (score * 5) + 2;
                } else if (o == '{') {
                    //print("}}", .{});
                    score = (score * 5) + 3;
                } else if (o == '<') {
                    //print(">", .{});
                    score = (score * 5) + 4;
                } else {
                    unreachable;
                }
            }
        }
        //print(" for a score of {d}\n", .{score});
        scores.append(score) catch unreachable;
    }
    std.sort.sort(i64, scores.items, {}, comptime std.sort.asc(i64));
    return scores.items[@divFloor(scores.items.len, 2)];
}

const test_data =
    \\[({(<(())[]>[[{[]{<()<>>
    \\[(()[<>])]({[<{<<[]>>(
    \\{([(<{}[<>[]}>{[]{[(<()>
    \\(((({<>}<{<{<>}{[]{[]{}
    \\[[<[([]))<([[{}[[()]]]
    \\[{[{({}]{}}([{[{{{}}([]
    \\{<[[]]>}<{[{[{[]{()[[[]
    \\[<(<(<(<{}))><([]([]()
    \\<{([([[(<>()){}]>(<<{{
    \\<{([{{}}[<[[[<>{}]]]>[]]
;
const part1_test_solution: ?i64 = 26397;
const part1_solution: ?i64 = 392367;
const part2_test_solution: ?i64 = 288957;
const part2_solution: ?i64 = 2192104158;

// Just boilerplate below here, nothing to see

fn testPart1() !void {
    var test_input = try Input.init(test_data, std.testing.allocator);
    defer test_input.deinit();
    if (part1_test_solution) |solution| {
        try std.testing.expectEqual(solution, part1(test_input));
    }

    var input = try Input.init(data, std.testing.allocator);
    defer input.deinit();
    if (part1_solution) |solution| {
        try std.testing.expectEqual(solution, part1(input));
    }
}

fn testPart2() !void {
    var test_input = try Input.init(test_data, std.testing.allocator);
    defer test_input.deinit();
    if (part2_test_solution) |solution| {
        try std.testing.expectEqual(solution, part2(test_input));
    }

    var input = try Input.init(data, std.testing.allocator);
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
