const std = @import("std");
const util = @import("util.zig");

const data = @embedFile("../data/day04.txt");

const BingoBoard = struct {
    mask: u25 = 0,
    is_winner: bool = false,
    cells: [5][5]u8 = undefined,
};

const BoardLoc = struct {
    board: usize,
    row: u5,
    col: u5,
};
const NumLocsMap = struct {
    map: std.AutoHashMap(u8, std.ArrayList(BoardLoc)) = undefined,

    pub fn init(allocator: *std.mem.Allocator) @This() {
        var map = std.AutoHashMap(u8, std.ArrayList(BoardLoc)).init(allocator);
        return @This(){
            .map = map,
        };
    }

    pub fn deinit(self: *@This()) void {
        var itor = self.map.valueIterator();
        while (itor.next()) |val| {
            val.deinit();
        }
        self.map.deinit();
        self.* = undefined;
    }

    pub fn add(self: *@This(), num: u8, loc: BoardLoc) void {
        if (self.map.getOrPut(num)) |result| {
            if (!result.found_existing) {
                result.value_ptr.* = std.ArrayList(BoardLoc).init(self.map.allocator);
            }
            result.value_ptr.append(loc) catch unreachable;
        } else |err| {
            print("getOrPut error: {}\n", .{err});
        }
    }

    pub fn get(self: @This(), num: u8) ?std.ArrayList(BoardLoc) {
        return self.map.get(num);
    }
};

test "AutoHashMap" {
    var map = NumLocsMap.init(std.testing.allocator);
    defer map.deinit();

    map.add(17, BoardLoc{ .board = 1, .row = 2, .col = 3 });
    map.add(17, BoardLoc{ .board = 4, .row = 5, .col = 6 });
    map.add(23, BoardLoc{ .board = 7, .row = 8, .col = 9 });

    try expect(map.map.count() == 2);
    const locs17 = map.get(17);
    try expect(locs17 != null);
    try expect(locs17.?.items.len == 2);
    try expect(locs17.?.items[1].col == 6);
    const locs23 = map.get(23);
    try expect(locs23 != null);
    try expect(locs23.?.items.len == 1);
    try expect(locs23.?.items[0].col == 9);
    try expect(map.get(42) == null);
}

const win_masks = [10]u25{
    0b00000_00000_00000_00000_11111,
    0b00000_00000_00000_11111_00000,
    0b00000_00000_11111_00000_00000,
    0b00000_11111_00000_00000_00000,
    0b11111_00000_00000_00000_00000,
    0b00001_00001_00001_00001_00001,
    0b00010_00010_00010_00010_00010,
    0b00100_00100_00100_00100_00100,
    0b01000_01000_01000_01000_01000,
    0b10000_10000_10000_10000_10000,
};

const Input = struct {
    numbers: []const u8,
    boards: std.ArrayList(BingoBoard) = std.ArrayList(BingoBoard).init(std.testing.allocator),
    board_locs: NumLocsMap = NumLocsMap.init(std.testing.allocator),

    pub fn deinit(self: *@This()) void {
        self.boards.deinit();
        self.board_locs.deinit();
        self.* = undefined;
    }
};

fn parseInput(input_text: []const u8) Input {
    var lines = std.mem.split(u8, input_text, "\n");

    // First line is a list of comma-separated numbers
    var input = Input{
        .numbers = std.mem.trimRight(u8, lines.next().?, "\r"),
    };
    // TODO: why can't this go in NumLocsMap.init()?
    input.board_locs.map.ensureTotalCapacity(100) catch unreachable;

    // Each board is six lines: a blank line, then five rows of five cells each
    while (lines.next()) |_| {
        var board = BingoBoard{};
        var row: u5 = 0;
        while (row < 5) : (row += 1) {
            var row_cells = std.mem.trimRight(u8, lines.next().?, "\r");
            var col: u5 = 0;
            while (col < 5) : (col += 1) {
                const cell = std.mem.trim(u8, row_cells[3 * col .. 3 * col + 2], " ");
                const n = parseInt(u8, cell, 10) catch unreachable;
                board.cells[row][col] = n;
                input.board_locs.add(n, BoardLoc{ .board = input.boards.items.len, .row = row, .col = col });
            }
        }
        input.boards.append(board) catch unreachable;
    }
    return input;
}

fn boardValue(board: BingoBoard, num: u8) i64 {
    var sum: i64 = 0;
    var bit: u5 = 0;
    while (bit < 25) : (bit += 1) {
        if (board.mask & @as(u25, 1) << bit == 0) {
            const row = bit / 5;
            const col = bit % 5;
            sum += board.cells[row][col];
        }
    }
    return sum * num;
}

fn part1(input: Input) i64 {
    var nums = std.mem.tokenize(u8, input.numbers, ",");
    while (nums.next()) |token| {
        const num = parseInt(u8, token, 10) catch unreachable;
        if (input.board_locs.get(num)) |locs| {
            for (locs.items) |loc| {
                const board = &input.boards.items[loc.board];
                assert(board.cells[loc.row][loc.col] == num);
                const bit: u5 = @intCast(u5, loc.row) * 5 + @intCast(u5, loc.col);
                board.mask |= @as(u25, 1) << bit;
                for (win_masks) |win_mask| {
                    if (board.mask & win_mask == win_mask) {
                        return boardValue(board.*, num);
                    }
                }
            }
        }
    }
    unreachable;
}

fn part2(input: Input) i64 {
    var nums = std.mem.tokenize(u8, input.numbers, ",");
    var num_boards_left: usize = input.boards.items.len;
    while (nums.next()) |token| {
        const num = parseInt(u8, token, 10) catch unreachable;
        if (input.board_locs.get(num)) |locs| {
            for (locs.items) |loc| {
                const board = &input.boards.items[loc.board];
                assert(board.cells[loc.row][loc.col] == num);
                if (board.is_winner) {
                    continue;
                }
                const bit: u5 = @intCast(u5, loc.row) * 5 + @intCast(u5, loc.col);
                board.mask |= @as(u25, 1) << bit;
                for (win_masks) |win_mask| {
                    if (board.mask & win_mask == win_mask) {
                        board.is_winner = true;
                        num_boards_left -= 1;
                        if (num_boards_left == 0) {
                            return boardValue(board.*, num);
                        }
                        break;
                    }
                }
            }
        }
    }
    unreachable;
}

fn testPart1() !void {
    var test_input = parseInput(test_data);
    defer test_input.deinit();
    try std.testing.expectEqual(@as(i64, 4512), part1(test_input));

    var input = parseInput(data);
    defer input.deinit();
    try std.testing.expectEqual(@as(i64, 64084), part1(input));
}

fn testPart2() !void {
    var test_input = parseInput(test_data);
    defer test_input.deinit();
    try std.testing.expectEqual(@as(i64, 1924), part2(test_input));

    var input = parseInput(data);
    defer input.deinit();
    try std.testing.expectEqual(@as(i64, 12833), part2(input));
}

pub fn main() !void {
    try testPart1();
    try testPart2();
}

const test_data =
    \\7,4,9,5,11,17,23,2,0,14,21,24,10,16,13,6,15,25,12,22,18,20,8,19,3,26,1
    \\
    \\22 13 17 11  0
    \\ 8  2 23  4 24
    \\21  9 14 16  7
    \\ 6 10  3 18  5
    \\ 1 12 20 15 19
    \\
    \\ 3 15  0  2 22
    \\ 9 18 13 17  5
    \\19  8  7 25 23
    \\20 11 10 24  4
    \\14 21 16 12  6
    \\
    \\14 21 17 24  4
    \\10 16 15  9 19
    \\18  8 23 26 20
    \\22 11 13  6  5
    \\ 2  0 12  3  7
;

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
