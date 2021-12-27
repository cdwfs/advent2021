const std = @import("std");
const util = @import("util.zig");

const data = @embedFile("../data/day12.txt");

const Input = struct {
    nodes: std.StringHashMap(std.ArrayList([]const u8)),
    node_masks: std.StringHashMap(u25),
    allocator: std.mem.Allocator,

    pub fn init(input_text: []const u8, allocator: std.mem.Allocator) !@This() {
        var input = Input{
            .nodes = std.StringHashMap(std.ArrayList([]const u8)).init(allocator),
            .node_masks = std.StringHashMap(u25).init(allocator),
            .allocator = allocator,
        };
        errdefer input.deinit();
        try input.nodes.ensureTotalCapacity(25);
        try input.node_masks.ensureTotalCapacity(25);

        var lines = std.mem.tokenize(u8, input_text, "\r\n");
        var node_count: u5 = 0;
        while (lines.next()) |line| {
            var kv = std.mem.tokenize(u8, line, "-");
            const node1 = kv.next().?;
            const node2 = kv.next().?;
            if (input.nodes.getOrPut(node1)) |result| {
                if (!result.found_existing) {
                    result.value_ptr.* = try std.ArrayList([]const u8).initCapacity(input.allocator, 25);
                    try input.node_masks.put(node1, @as(u25, 1) << node_count);
                    node_count += 1;
                }
                try result.value_ptr.append(node2);
            } else |_| {
                print("GetOrPut error\n", .{});
            }
            // TODO: do it again
            if (input.nodes.getOrPut(node2)) |result| {
                if (!result.found_existing) {
                    result.value_ptr.* = try std.ArrayList([]const u8).initCapacity(input.allocator, 25);
                    try input.node_masks.put(node2, @as(u25, 1) << node_count);
                    node_count += 1;
                }
                try result.value_ptr.append(node1);
            } else |_| {
                print("GetOrPut error\n", .{});
            }
        }

        return input;
    }
    pub fn deinit(self: *@This()) void {
        var itor = self.nodes.valueIterator();
        while (itor.next()) |val| {
            val.deinit();
        }
        self.nodes.deinit();
        self.node_masks.deinit();
    }
};

fn numPathsToEnd(input: Input, node: []const u8, visited: u25, can_visit_twice: bool) i64 {
    if (std.mem.eql(u8, node, "end")) {
        return 1;
    }
    var new_visited = visited;
    var new_can_visit_twice = can_visit_twice;
    if (std.ascii.isLower(node[0])) {
        const mask = input.node_masks.get(node).?;
        assert(mask != 0);
        if ((new_visited & mask) != 0) {
            // we've already been here. Can we visit twice?
            if (!new_can_visit_twice or std.mem.eql(u8, node, "start")) {
                return 0; // can't visit this node twice
            }
            new_can_visit_twice = false; // no more double-visits on this path
        }
        new_visited |= mask; // mark node as visited
    }
    var sum: i64 = 0;
    const neighbors = input.nodes.get(node).?;
    for (neighbors.items) |neighbor| {
        sum += numPathsToEnd(input, neighbor, new_visited, new_can_visit_twice);
    }
    return sum;
}

fn part1(input: Input) i64 {
    return numPathsToEnd(input, "start", 0, false);
}

fn part2(input: Input) i64 {
    return numPathsToEnd(input, "start", 0, true);
}

const test_data =
    \\start-A
    \\start-b
    \\A-c
    \\A-b
    \\b-d
    \\A-end
    \\b-end
;
const part1_test_solution: ?i64 = 10;
const part1_solution: ?i64 = 4720;
const part2_test_solution: ?i64 = 36;
const part2_solution: ?i64 = 147848;

const test_data2 =
    \\dc-end
    \\HN-start
    \\start-kj
    \\dc-start
    \\dc-HN
    \\LN-dc
    \\HN-end
    \\kj-sa
    \\kj-HN
    \\kj-dc
;

const test_data3 =
    \\fs-end
    \\he-DX
    \\fs-he
    \\start-DX
    \\pj-DX
    \\end-zg
    \\zg-sl
    \\zg-pj
    \\pj-he
    \\RW-he
    \\fs-DX
    \\pj-RW
    \\zg-RW
    \\start-pj
    \\he-WI
    \\zg-he
    \\pj-fs
    \\start-RW
;

// Just boilerplate below here, nothing to see

fn testPart1() !void {
    var test_input = try Input.init(test_data, std.testing.allocator);
    defer test_input.deinit();
    if (part1_test_solution) |solution| {
        try std.testing.expectEqual(solution, part1(test_input));
    }

    var test_input2 = try Input.init(test_data2, std.testing.allocator);
    defer test_input2.deinit();
    try std.testing.expectEqual(@as(i64, 19), part1(test_input2));

    var test_input3 = try Input.init(test_data3, std.testing.allocator);
    defer test_input3.deinit();
    try std.testing.expectEqual(@as(i64, 226), part1(test_input3));

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

    var test_input2 = try Input.init(test_data2, std.testing.allocator);
    defer test_input2.deinit();
    try std.testing.expectEqual(@as(i64, 103), part2(test_input2));

    var test_input3 = try Input.init(test_data3, std.testing.allocator);
    defer test_input3.deinit();
    try std.testing.expectEqual(@as(i64, 3509), part2(test_input3));

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
