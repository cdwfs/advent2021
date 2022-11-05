const std = @import("std");
const util = @import("util.zig");

const data = @embedFile("data/day09.txt");

const Input = struct {
    heightmap: [100][100]u8 = undefined,
    dim_x: usize = undefined,
    dim_y: usize = undefined,

    pub fn init(input_text: []const u8, allocator: std.mem.Allocator) !@This() {
        _ = allocator;
        var input = Input{};
        errdefer input.deinit();

        var lines = std.mem.tokenize(u8, input_text, "\r\n");
        var y: usize = 0;
        while (lines.next()) |line| : (y += 1) {
            input.dim_x = line.len;
            for (line) |c, x| {
                input.heightmap[y][x] = c - '0';
            }
        }
        input.dim_y = y;

        return input;
    }
    pub fn deinit(self: @This()) void {
        _ = self;
    }

    pub fn cell(self: @This(), x: isize, y: isize) ?u8 {
        if (x < 0 or x >= self.dim_x or y < 0 or y >= self.dim_y) {
            return null;
        }
        return self.heightmap[@intCast(usize, y)][@intCast(usize, x)];
    }
};

const Vec2 = struct {
    x: isize,
    y: isize,
};

const offsets = [_]Vec2{
    Vec2{ .x = -1, .y = 0 },
    Vec2{ .x = 1, .y = 0 },
    Vec2{ .x = 0, .y = -1 },
    Vec2{ .x = 0, .y = 1 },
};

fn part1(input: Input) i64 {
    var risk: i64 = 0;
    var y: isize = 0;
    while (y < input.dim_y) : (y += 1) {
        var x: isize = 0;
        xloop: while (x < input.dim_x) : (x += 1) {
            const c: u8 = input.cell(x, y).?;
            for (offsets) |offset| {
                const neighbor: ?u8 = input.cell(x + offset.x, y + offset.y);
                if (neighbor) |n| {
                    if (n <= c) {
                        continue :xloop;
                    }
                }
            }
            risk += c + 1;
        }
    }
    return risk;
}

fn part2(input_original: Input) i64 {
    var input = input_original;
    var basin_sizes = std.ArrayList(i64).init(std.testing.allocator);
    defer basin_sizes.deinit();
    var y: isize = 0;
    var to_visit = std.ArrayList(Vec2).initCapacity(std.testing.allocator, input.dim_x * input.dim_y) catch unreachable;
    defer to_visit.deinit();
    while (y < input.dim_y) : (y += 1) {
        var x: isize = 0;
        xloop: while (x < input.dim_x) : (x += 1) {
            const c: u8 = input.cell(x, y).?;
            if (c == 9) {
                continue :xloop;
            }
            // flood-fill from here. To mark a cell as visited, change it to a 9.
            var basin_size: i64 = 0;
            assert(to_visit.items.len == 0);
            to_visit.append(Vec2{ .x = x, .y = y }) catch unreachable;
            while (to_visit.items.len > 0) {
                const v = to_visit.pop();
                if (input.cell(v.x, v.y)) |height| {
                    if (height < 9) {
                        input.heightmap[@intCast(usize, v.y)][@intCast(usize, v.x)] = 9;
                        basin_size += 1;
                        for (offsets) |offset| {
                            to_visit.append(Vec2{ .x = v.x + offset.x, .y = v.y + offset.y }) catch unreachable;
                        }
                    }
                }
            }
            basin_sizes.append(basin_size) catch unreachable;
        }
    }
    // sort basin sizes to pick the three largest
    assert(basin_sizes.items.len >= 3);
    std.sort.sort(i64, basin_sizes.items, {}, comptime std.sort.desc(i64));
    return basin_sizes.items[0] * basin_sizes.items[1] * basin_sizes.items[2];
}

const test_data =
    \\2199943210
    \\3987894921
    \\9856789892
    \\8767896789
    \\9899965678
;
const part1_test_solution: ?i64 = 15;
const part1_solution: ?i64 = 524;
const part2_test_solution: ?i64 = 1134;
const part2_solution: ?i64 = 1235430;

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
