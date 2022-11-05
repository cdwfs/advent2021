const std = @import("std");
const util = @import("util.zig");

const data = @embedFile("data/day21.txt");

const Input = struct {
    start1: u16,
    start2: u16,

    pub fn init(input_text: []const u8, allocator: std.mem.Allocator) !@This() {
        _ = allocator;
        var lines = std.mem.tokenize(u8, input_text, "\r\n");
        const line1 = lines.next().?;
        const line2 = lines.next().?;
        var input = Input{
            .start1 = try parseInt(u16, line1[28..], 10),
            .start2 = try parseInt(u16, line2[28..], 10),
        };
        return input;
    }
    pub fn deinit(self: @This()) void {
        _ = self;
    }
};

fn part1(input: Input) i64 {
    var pos1: u16 = input.start1;
    var pos2: u16 = input.start2;
    var score1: i64 = 0;
    var score2: i64 = 0;
    var die: u16 = 0;
    var roll_count: i64 = 0;
    while (score1 < 1000 and score2 < 1000) {
        // player 1 turn
        die = if (die == 100) @as(u16, 1) else die + 1;
        const roll1a = die;
        die = if (die == 100) @as(u16, 1) else die + 1;
        const roll1b = die;
        die = if (die == 100) @as(u16, 1) else die + 1;
        const roll1c = die;
        roll_count += 3;
        pos1 = ((pos1 - 1 + roll1a + roll1b + roll1c) % 10) + 1;
        score1 += pos1;
        //print("Player 1 rolls {d}+{d}+{d} and moves to {d} for a total score of {d}\n",
        //    .{roll1a, roll1b, roll1c, pos1, score1});
        if (score1 >= 1000) {
            return roll_count * score2;
        }
        // player 2 turn
        die = if (die == 100) @as(u16, 1) else die + 1;
        const roll2a = die;
        die = if (die == 100) @as(u16, 1) else die + 1;
        const roll2b = die;
        die = if (die == 100) @as(u16, 1) else die + 1;
        const roll2c = die;
        roll_count += 3;
        pos2 = ((pos2 - 1 + roll2a + roll2b + roll2c) % 10) + 1;
        score2 += pos2;
        //print("Player 2 rolls {d}+{d}+{d} and moves to {d} for a total score of {d}\n",
        //    .{roll2a, roll2b, roll2c, pos2, score2});
        if (score2 >= 1000) {
            return roll_count * score1;
        }
    }
    unreachable;
}

const GameState = struct {
    pos1: u16,
    pos2: u16,
    score1: i64,
    score2: i64,
    universes: i64,
};

const DiracRoll = struct {
    move: u16,
    count: i64,
};
const DIRAC_ROLLS = [7]DiracRoll{
    DiracRoll{ .move = 3, .count = 1 },
    DiracRoll{ .move = 4, .count = 3 },
    DiracRoll{ .move = 5, .count = 6 },
    DiracRoll{ .move = 6, .count = 7 },
    DiracRoll{ .move = 7, .count = 6 },
    DiracRoll{ .move = 8, .count = 3 },
    DiracRoll{ .move = 9, .count = 1 },
};
fn simulateRound(state: GameState, turn: u32, wins1: *i64, wins2: *i64) void {
    if (turn == 1) {
        for (DIRAC_ROLLS) |roll| {
            const new_pos1 = ((state.pos1 - 1 + roll.move) % 10) + 1;
            const new_score1 = state.score1 + new_pos1;
            const new_universes = state.universes * roll.count;
            if (new_score1 >= 21) {
                wins1.* += new_universes;
                continue;
            }
            var new_state = GameState{
                .pos1 = new_pos1,
                .pos2 = state.pos2,
                .score1 = new_score1,
                .score2 = state.score2,
                .universes = new_universes,
            };
            simulateRound(new_state, 2, wins1, wins2);
        }
    } else if (turn == 2) {
        for (DIRAC_ROLLS) |roll| {
            const new_pos2 = ((state.pos2 - 1 + roll.move) % 10) + 1;
            const new_score2 = state.score2 + new_pos2;
            const new_universes = state.universes * roll.count;
            if (new_score2 >= 21) {
                wins2.* += new_universes;
                continue;
            }
            var new_state = GameState{
                .pos1 = state.pos1,
                .pos2 = new_pos2,
                .score1 = state.score1,
                .score2 = new_score2,
                .universes = new_universes,
            };
            simulateRound(new_state, 1, wins1, wins2);
        }
    }
}

fn part2(input: Input) i64 {
    const state = GameState{ .pos1 = input.start1, .pos2 = input.start2, .score1 = 0, .score2 = 0, .universes = 1 };
    var wins1: i64 = 0;
    var wins2: i64 = 0;
    simulateRound(state, 1, &wins1, &wins2);
    return std.math.max(wins1, wins2);
}

const test_data =
    \\Player 1 starting position: 4
    \\Player 2 starting position: 8
;
const part1_test_solution: ?i64 = 739785;
const part1_solution: ?i64 = 675024;
const part2_test_solution: ?i64 = 444356092776315;
const part2_solution: ?i64 = 570239341223618;

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
