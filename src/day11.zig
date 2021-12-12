const std = @import("std");
const util = @import("util.zig");

const data = @embedFile("../data/day11.txt");

const Input = struct {
    energy: [10][10]u8 = undefined,

    pub fn init(input_text: []const u8, allocator: std.mem.Allocator) !@This() {
        _ = allocator;
        var input = Input{};
        errdefer input.deinit();

        var lines = std.mem.tokenize(u8, input_text, "\r\n");

        var y: usize = 0;
        while (lines.next()) |line| : (y += 1) {
            for (line) |c, x| {
                input.energy[y][x] = c - '0';
            }
        }

        return input;
    }

    pub fn deinit(self: @This()) void {
        _ = self;
    }
};

const Coord2 = struct {
    x: usize,
    y: usize,
};
const Offset = struct {
    x: isize,
    y: isize,
};
pub fn flash(energy: *[10][10]u8, coord: Coord2, flashers: *std.ArrayList(Coord2), flashed: *std.StaticBitSet(100)) void {
    assert(coord.x < 10 and coord.y < 10);
    // TODO: Why don't I need any .* operators below?
    const offsets = [8]Offset{
        Offset{ .x = -1, .y = -1 },
        Offset{ .x = 0, .y = -1 },
        Offset{ .x = 1, .y = -1 },
        Offset{ .x = -1, .y = 0 },
        Offset{ .x = 1, .y = 0 },
        Offset{ .x = -1, .y = 1 },
        Offset{ .x = 0, .y = 1 },
        Offset{ .x = 1, .y = 1 },
    };
    for (offsets) |offset| {
        const cx: isize = @intCast(isize, coord.x) + offset.x;
        const cy: isize = @intCast(isize, coord.y) + offset.y;
        if (cx < 0 or cx >= 10 or cy < 0 or cy >= 10) {
            continue; // out of bounds
        }
        const c = Coord2{ .x = @intCast(usize, cx), .y = @intCast(usize, cy) };
        if (flashed.isSet(10 * c.y + c.x)) {
            continue; // already flashed this step
        }
        energy[c.y][c.x] += 1;
        if (energy[c.y][c.x] > 9) {
            flashers.append(Coord2{ .x = c.x, .y = c.y }) catch unreachable;
            flashed.set(10 * c.y + c.x);
        }
    }
}

fn part1(input: Input) i64 {
    var energy = input.energy;
    var flashers = std.ArrayList(Coord2).initCapacity(std.testing.allocator, 10 * 10) catch unreachable;
    defer flashers.deinit();
    var step: usize = 0;
    var flash_count: i64 = 0;
    while (step < 100) : (step += 1) {
        assert(flashers.items.len == 0);
        var flashed = std.StaticBitSet(100).initEmpty();
        // increase energy of all cells & track any that flash
        for (energy) |*row, y| {
            for (row) |*e, x| {
                e.* += 1;
                if (e.* > 9) {
                    flashers.append(Coord2{ .x = x, .y = y }) catch unreachable;
                    assert(!flashed.isSet(10 * y + x));
                    flashed.set(10 * y + x);
                }
            }
        }
        // process flashes
        while (flashers.items.len > 0) {
            const center = flashers.pop();
            flash(&energy, center, &flashers, &flashed);
        }
        // Anything that flashed this step gets its energy reset to zero
        for (energy) |*row, y| {
            for (row) |*e, x| {
                if (flashed.isSet(10 * y + x)) {
                    assert(e.* > 9);
                    e.* = 0;
                    flash_count += 1;
                } else {
                    assert(e.* <= 9);
                }
            }
        }
    }

    return flash_count;
}

fn part2(input: Input) i64 {
    var energy = input.energy; // TODO: is this a copy?
    var flashers = std.ArrayList(Coord2).initCapacity(std.testing.allocator, 10 * 10) catch unreachable;
    defer flashers.deinit();
    var step: i64 = 0;
    while (true) : (step += 1) {
        assert(flashers.items.len == 0);
        var flashed = std.StaticBitSet(100).initEmpty();
        // increase energy of all cells & track any that flash
        for (energy) |*row, y| {
            for (row) |*e, x| {
                assert(e.* <= 9);
                e.* += 1;
                if (e.* > 9) {
                    flashers.append(Coord2{ .x = x, .y = y }) catch unreachable;
                    assert(!flashed.isSet(10 * y + x));
                    flashed.set(10 * y + x);
                }
            }
        }
        // process flashes
        while (flashers.items.len > 0) {
            const center = flashers.pop();
            flash(&energy, center, &flashers, &flashed);
        }
        // Anything that flashed this step gets its energy reset to zero
        var flash_count: i64 = 0;
        for (energy) |*row, y| {
            for (row) |*e, x| {
                if (flashed.isSet(10 * y + x)) {
                    assert(e.* > 9);
                    e.* = 0;
                    flash_count += 1;
                } else {
                    assert(e.* <= 9);
                }
            }
        }
        if (flash_count == 100)
            return step + 1;
    }
    unreachable;
}

const test_data =
    \\5483143223
    \\2745854711
    \\5264556173
    \\6141336146
    \\6357385478
    \\4167524645
    \\2176841721
    \\6882881134
    \\4846848554
    \\5283751526
;
const part1_test_solution: ?i64 = 1656;
const part1_solution: ?i64 = 1673;
const part2_test_solution: ?i64 = 195;
const part2_solution: ?i64 = 279;

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
