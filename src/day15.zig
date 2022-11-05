const std = @import("std");
const util = @import("util.zig");

const data = @embedFile("data/day15.txt");

const Input = struct {
    risks: [100][100]i64 = undefined,
    dim: usize = undefined,
    allocator: std.mem.Allocator = undefined,

    pub fn init(input_text: []const u8, allocator: std.mem.Allocator) !@This() {
        var input = Input{};
        errdefer input.deinit();

        var lines = std.mem.tokenize(u8, input_text, "\r\n");
        var y: usize = 0;
        while (lines.next()) |line| : (y += 1) {
            for (line) |c, x| {
                input.risks[y][x] = c - '0';
            }
        }
        input.dim = y;
        input.allocator = allocator;

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
const UNVISITED: i64 = std.math.maxInt(i64);
fn updateCandidate(input: Input, lowest: *[100][100]i64, candidates: *std.ArrayList(Coord2), x: usize, y: usize, val: i64) void {
    if (x >= input.dim or y >= input.dim) {
        return; // out of bounds
    }
    if (lowest.*[y][x] == UNVISITED) {
        candidates.appendAssumeCapacity(Coord2{ .x = x, .y = y });
    }
    lowest.*[y][x] = std.math.min(lowest.*[y][x], val + input.risks[y][x]);
}
fn part1(input: Input) i64 {
    var lowest: [100][100]i64 = undefined;
    for (lowest) |*row| {
        for (row) |*v| {
            v.* = UNVISITED;
        }
    }
    var candidates = std.ArrayList(Coord2).initCapacity(input.allocator, 100 * 100) catch unreachable;
    defer candidates.deinit();

    candidates.appendAssumeCapacity(Coord2{ .x = input.dim - 1, .y = input.dim - 1 });
    lowest[input.dim - 1][input.dim - 1] = input.risks[input.dim - 1][input.dim - 1];
    var visit_count: usize = 0;
    while (candidates.items.len > 0) {
        visit_count += 1;
        var min_risk: i64 = UNVISITED;
        var min_risk_index: usize = 0;
        // when picking the next candidate to explore:
        // for Dijkstra, just pick the one with the lowest total cost.
        // For A*, add a conservative heuristic of the remaining cost (e.g. Manhattan distance).
        for (candidates.items) |c, i| {
            const h: i64 = @intCast(i64, c.y + c.x);
            const r = lowest[c.y][c.x] + h;
            if (r < min_risk) {
                min_risk = r;
                min_risk_index = i;
            }
        }
        const c = candidates.swapRemove(min_risk_index);
        if (c.x == 0 and c.y == 0) {
            print("visited {d} nodes out of {d}\n", .{ visit_count, input.dim * input.dim });
            return lowest[0][0] - input.risks[0][0]; // starting location not counted
        }
        const r = lowest[c.y][c.x];
        updateCandidate(input, &lowest, &candidates, c.x -% 1, c.y, r);
        updateCandidate(input, &lowest, &candidates, c.x + 1, c.y, r);
        updateCandidate(input, &lowest, &candidates, c.x, c.y -% 1, r);
        updateCandidate(input, &lowest, &candidates, c.x, c.y + 1, r);
    }
    unreachable;
}

fn tiledRisk(input: Input, x: usize, y: usize) i64 {
    const tile_x = @divFloor(x, input.dim);
    const tile_y = @divFloor(y, input.dim);
    const cell_x = x % input.dim;
    const cell_y = y % input.dim;
    const risk_offset = tile_x + tile_y;
    const r = input.risks[cell_y][cell_x] + @intCast(i64, risk_offset);
    return if (r <= 9) r else @mod(r + 1, 10);
}
fn updateCandidate2(input: Input, lowest: *[500][500]i64, candidates: *std.ArrayList(Coord2), x: usize, y: usize, val: i64) void {
    const scale_dim = 5 * input.dim;
    if (x >= scale_dim or y >= scale_dim) {
        return; // out of bounds
    }
    if (lowest.*[y][x] == UNVISITED) {
        candidates.appendAssumeCapacity(Coord2{ .x = x, .y = y });
    }
    lowest.*[y][x] = std.math.min(lowest.*[y][x], val + tiledRisk(input, x, y));
}
fn part2(input: Input) i64 {
    var lowest: [500][500]i64 = undefined;
    for (lowest) |*row| {
        for (row) |*v| {
            v.* = UNVISITED;
        }
    }
    var candidates = std.ArrayList(Coord2).initCapacity(input.allocator, 500 * 500) catch unreachable;
    defer candidates.deinit();

    const scale_dim = 5 * input.dim;
    candidates.appendAssumeCapacity(Coord2{ .x = scale_dim - 1, .y = scale_dim - 1 });
    lowest[scale_dim - 1][scale_dim - 1] = tiledRisk(input, scale_dim - 1, scale_dim - 1);
    var visit_count: usize = 0;
    while (candidates.items.len > 0) {
        visit_count += 1;
        var min_risk: i64 = UNVISITED;
        var min_risk_index: usize = 0;
        // when picking the next candidate to explore:
        // for Dijkstra, just pick the one with the lowest total cost.
        // For A*, add a conservative heuristic of the remaining cost (e.g. Manhattan distance).
        // In this case it doesn't really make a huge difference in the visit count, and adding
        // the heuristic doubles the running time (???), so I've left it commented out.
        for (candidates.items) |c, i| {
            const r = lowest[c.y][c.x];// + @intCast(i64, c.y + c.x);
            if (r < min_risk) {
                min_risk = r;
                min_risk_index = i;
            }
        }
        const c = candidates.swapRemove(min_risk_index);
        if (c.x == 0 and c.y == 0) {
            print("visited {d} nodes out of {d}\n", .{ visit_count, scale_dim * scale_dim });
            return lowest[0][0] - input.risks[0][0]; // starting location not counted
        }
        const r = lowest[c.y][c.x];
        updateCandidate2(input, &lowest, &candidates, c.x -% 1, c.y, r);
        updateCandidate2(input, &lowest, &candidates, c.x + 1, c.y, r);
        updateCandidate2(input, &lowest, &candidates, c.x, c.y -% 1, r);
        updateCandidate2(input, &lowest, &candidates, c.x, c.y + 1, r);
    }
    unreachable;
}

const test_data =
    \\1163751742
    \\1381373672
    \\2136511328
    \\3694931569
    \\7463417111
    \\1319128137
    \\1359912421
    \\3125421639
    \\1293138521
    \\2311944581
;
const part1_test_solution: ?i64 = 40;
const part1_solution: ?i64 = 741;
const part2_test_solution: ?i64 = 315;
const part2_solution: ?i64 = 2976;

// Just boilerplate below here, nothing to see

fn testPart1(allocator: std.mem.Allocator) !void {
    var test_input = try Input.init(test_data, allocator);
    defer test_input.deinit();
    if (part1_test_solution) |solution| {
        try std.testing.expectEqual(solution, part1(test_input));
    }

    var timer = try std.time.Timer.start();
    var input = try Input.init(data, allocator);
    defer input.deinit();
    if (part1_solution) |solution| {
        try std.testing.expectEqual(solution, part1(input));
        print("part1 took {d:9.3}ms\n", .{@intToFloat(f64, timer.lap()) / 1000000.0});
    }
}

fn testPart2(allocator: std.mem.Allocator) !void {
    var test_input = try Input.init(test_data, allocator);
    defer test_input.deinit();
    if (part2_test_solution) |solution| {
        try std.testing.expectEqual(solution, part2(test_input));
    }

    var timer = try std.time.Timer.start();
    var input = try Input.init(data, allocator);
    defer input.deinit();
    if (part2_solution) |solution| {
        try std.testing.expectEqual(solution, part2(input));
        print("part2 took {d:9.3}ms\n", .{@intToFloat(f64, timer.lap()) / 1000000.0});
    }
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    try testPart1(allocator);
    try testPart2(allocator);
}

test "part1" {
    try testPart1(std.testing.allocator);
}

test "part2" {
    try testPart2(std.testing.allocator);
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
