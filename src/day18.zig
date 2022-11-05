const std = @import("std");
const util = @import("util.zig");

const data = @embedFile("data/day18.txt");
const TreeNodeLeaf = struct {
    value: i64,
};
const TreeNodeBranch = struct {
    left: *TreeNode,
    right: *TreeNode,
};
const TreeNodeType = enum {
    leaf,
    branch,
};
const TreeNodePayload = union(TreeNodeType) {
    leaf: TreeNodeLeaf,
    branch: TreeNodeBranch,
};
const TreeNode = struct {
    parent: ?*TreeNode,
    payload: TreeNodePayload,
};
fn buildTree(line: []const u8, pos: *usize, parent: ?*TreeNode, allocator: std.mem.Allocator) anyerror!*TreeNode {
    var node = try allocator.create(TreeNode);
    switch (line[pos.*]) {
        '[' => {
            pos.* += 1; // skip [
            const left = try buildTree(line, pos, node, allocator);
            assert(line[pos.*] == ',');
            pos.* += 1; // skip ,
            const right = try buildTree(line, pos, node, allocator);
            assert(line[pos.*] == ']');
            pos.* += 1; // skip ]
            node.* = TreeNode{ .parent = parent, .payload = TreeNodePayload{ .branch = TreeNodeBranch{
                .left = left,
                .right = right,
            } } };
        },
        '0', '1', '2', '3', '4', '5', '6', '7', '8', '9' => {
            var nums = std.mem.tokenize(u8, line[pos.*..], ",]");
            const num_str = nums.next().?;
            const num = try parseInt(u8, num_str, 10);
            node.* = TreeNode{ .parent = parent, .payload = TreeNodePayload{ .leaf = TreeNodeLeaf{
                .value = num,
            } } };
            pos.* += num_str.len;
        },
        else => unreachable,
    }
    return node;
}

fn freeTree(tree: *TreeNode, allocator: std.mem.Allocator) void {
    switch (tree.payload) {
        .branch => |branch| {
            freeTree(branch.left, allocator);
            freeTree(branch.right, allocator);
        },
        else => {},
    }
    allocator.destroy(tree);
}

fn writeTree(tree: *TreeNode, writer: *std.ArrayList(u8).Writer) anyerror!void {
    switch (tree.payload) {
        .branch => |branch| {
            try writer.print("[", .{});
            try writeTree(branch.left, writer);
            try writer.print(",", .{});
            try writeTree(branch.right, writer);
            try writer.print("]", .{});
        },
        .leaf => |leaf| {
            try writer.print("{d}", .{leaf.value});
        },
    }
}

fn printTree(tree: *TreeNode, allocator: std.mem.Allocator) !void {
    var tree_str = std.ArrayList(u8).init(allocator);
    defer tree_str.deinit();
    var writer = tree_str.writer();
    try writeTree(tree, &writer);
    print("{s}\n", .{tree_str.items[0..]});
}

fn reduceExplode(tree: *TreeNode, depth: usize, allocator: std.mem.Allocator) anyerror!bool {
    switch (tree.payload) {
        .branch => |*branch| {
            if (depth >= 4) {
                // explode
                assert(@as(TreeNodeType, branch.left.payload) == .leaf);
                assert(@as(TreeNodeType, branch.right.payload) == .leaf);
                // add left leaf's value to first leaf node to the left, if possible
                const left_value = branch.left.payload.leaf.value;
                var left_dest = tree;
                while (left_dest.parent != null) : (left_dest = left_dest.parent.?) {
                    if (left_dest.parent.?.payload.branch.left != left_dest) {
                        // There is definitely a number in here somewhere;
                        left_dest = left_dest.parent.?.payload.branch.left;
                        while (@as(TreeNodeType, left_dest.payload) != .leaf) {
                            left_dest = left_dest.payload.branch.right;
                        }
                        left_dest.payload.leaf.value += left_value;
                        break;
                    }
                }
                // add right leaf's value to first leaf node to the right, if possible
                const right_value = branch.right.payload.leaf.value;
                var right_dest = tree;
                while (right_dest.parent != null) : (right_dest = right_dest.parent.?) {
                    if (right_dest.parent.?.payload.branch.right != right_dest) {
                        // There is definitely a number in here somewhere;
                        right_dest = right_dest.parent.?.payload.branch.right;
                        while (@as(TreeNodeType, right_dest.payload) != .leaf) {
                            right_dest = right_dest.payload.branch.left;
                        }
                        right_dest.payload.leaf.value += right_value;
                        break;
                    }
                }
                // replace exploded branch node with a leaf node with value=0
                allocator.destroy(branch.left);
                allocator.destroy(branch.right);
                tree.payload = TreeNodePayload{ .leaf = TreeNodeLeaf{ .value = 0 } };
                //print("EXPLODE: pair [{d},{d}]\n", .{left_value, right_value});
                return true;
            } else {
                return (try reduceExplode(branch.left, depth + 1, allocator)) or (try reduceExplode(branch.right, depth + 1, allocator));
            }
        },
        .leaf => {}, // leafs do not explode
    }
    return false;
}
fn reduceSplit(tree: *TreeNode, allocator: std.mem.Allocator) anyerror!bool {
    switch (tree.payload) {
        .branch => |*branch| {
            return (try reduceSplit(branch.left, allocator)) or (try reduceSplit(branch.right, allocator));
        },
        .leaf => |*leaf| {
            if (leaf.value >= 10) {
                // split
                //print("SPLIT: {d}\n", .{leaf.value});
                var left = try allocator.create(TreeNode);
                const left_value = @divFloor(leaf.value, 2);
                left.* = TreeNode{ .parent = tree, .payload = TreeNodePayload{ .leaf = TreeNodeLeaf{ .value = left_value } } };
                var right = try allocator.create(TreeNode);
                const right_value = @divFloor(leaf.value + 1, 2);
                right.* = TreeNode{ .parent = tree, .payload = TreeNodePayload{ .leaf = TreeNodeLeaf{ .value = right_value } } };
                tree.payload = TreeNodePayload{ .branch = TreeNodeBranch{
                    .left = left,
                    .right = right,
                } };
                return true;
            }
        },
    }
    return false;
}

fn addTrees(left: *TreeNode, right: *TreeNode, allocator: std.mem.Allocator) !*TreeNode {
    var result = try allocator.create(TreeNode);
    result.* = TreeNode{ .parent = null, .payload = TreeNodePayload{ .branch = TreeNodeBranch{
        .left = left,
        .right = right,
    } } };
    left.parent = result;
    right.parent = result;
    while (true) {
        //print("Reducing ", .{});
        //try printTree(result, allocator);
        const had_explode = try reduceExplode(result, 0, allocator);
        if (!had_explode) {
            const had_split = try reduceSplit(result, allocator);
            if (!had_split) {
                break;
            }
        }
    }
    return result;
}

fn magnitude(tree: *TreeNode) i64 {
    return switch (tree.payload) {
        .branch => |branch| (3 * magnitude(branch.left)) + (2 * magnitude(branch.right)),
        .leaf => |leaf| leaf.value,
    };
}

const Input = struct {
    lines: std.BoundedArray([]const u8, 100) = undefined,
    allocator: std.mem.Allocator,

    pub fn init(input_text: []const u8, allocator: std.mem.Allocator) !@This() {
        _ = allocator;
        var input = Input{
            .lines = try std.BoundedArray([]const u8, 100).init(0),
            .allocator = allocator,
        };
        errdefer input.deinit();

        var lines = std.mem.tokenize(u8, input_text, "\r\n");
        while (lines.next()) |line| {
            try input.lines.append(line);
        }

        return input;
    }
    pub fn deinit(self: @This()) void {
        _ = self;
    }
};

fn part1(input: Input) i64 {
    var sum: *TreeNode = undefined;
    defer freeTree(sum, input.allocator);
    for (input.lines.constSlice()) |line, i| {
        var line_pos: usize = 0;
        var tree = buildTree(line, &line_pos, null, input.allocator) catch unreachable;
        assert(line_pos == line.len);
        if (i == 0) {
            sum = tree;
        } else {
            sum = addTrees(sum, tree, input.allocator) catch unreachable;
        }
    }

    return magnitude(sum);
}

fn part2(input: Input) i64 {
    var largest_magnitude: i64 = 0;
    for (input.lines.constSlice()) |s1| {
        for (input.lines.constSlice()) |s2| {
            var s1_pos: usize = 0;
            var tree1 = buildTree(s1, &s1_pos, null, input.allocator) catch unreachable;
            var s2_pos: usize = 0;
            var tree2 = buildTree(s2, &s2_pos, null, input.allocator) catch unreachable;
            var sum: *TreeNode = undefined;
            defer freeTree(sum, input.allocator);
            sum = addTrees(tree1, tree2, input.allocator) catch unreachable;
            const mag = magnitude(sum);
            largest_magnitude = std.math.max(mag, largest_magnitude);
        }
    }
    return largest_magnitude;
}

const test_data =
    \\[[[0,[5,8]],[[1,7],[9,6]]],[[4,[1,2]],[[1,4],2]]]
    \\[[[5,[2,8]],4],[5,[[9,9],0]]]
    \\[6,[[[6,2],[5,6]],[[7,6],[4,7]]]]
    \\[[[6,[0,7]],[0,9]],[4,[9,[9,0]]]]
    \\[[[7,[6,4]],[3,[1,3]]],[[[5,5],1],9]]
    \\[[6,[[7,3],[3,2]]],[[[3,8],[5,7]],4]]
    \\[[[[5,4],[7,7]],8],[[8,3],8]]
    \\[[9,3],[[9,9],[6,[4,9]]]]
    \\[[2,[[7,7],7]],[[5,8],[[9,3],[0,2]]]]
    \\[[[[5,2],5],[8,[3,7]]],[[5,[7,5]],[4,4]]]
;
const part1_test_solution: ?i64 = 4140;
const part1_solution: ?i64 = 4365;
const part2_test_solution: ?i64 = 3993;
const part2_solution: ?i64 = 4490;

// Just boilerplate below here, nothing to see
fn treesAreEqual(expected: *TreeNode, actual: *TreeNode, allocator: std.mem.Allocator) !void {
    var result1 = std.ArrayList(u8).init(allocator);
    defer result1.deinit();
    var result1_writer = result1.writer();
    try writeTree(expected, &result1_writer);

    var result2 = std.ArrayList(u8).init(allocator);
    defer result2.deinit();
    var result2_writer = result2.writer();
    try writeTree(actual, &result2_writer);

    try std.testing.expectEqualStrings(result1.items[0..], result2.items[0..]);
}
fn testBuildTree(s: []const u8, allocator: std.mem.Allocator) !*TreeNode {
    var pos: usize = 0;
    var tree = try buildTree(s, &pos, null, allocator);
    errdefer freeTree(tree, allocator);
    try std.testing.expectEqual(s.len, pos);
    var result = try std.ArrayList(u8).initCapacity(allocator, s.len);
    defer result.deinit();
    var result_writer = result.writer();
    try writeTree(tree, &result_writer);
    try std.testing.expectEqualStrings(s, result.items[0..]);
    return tree;
}
fn testMagnitude(s: []const u8, expected: i64, allocator: std.mem.Allocator) !void {
    var tree = try testBuildTree(s, allocator);
    defer freeTree(tree, allocator);
    try std.testing.expectEqual(expected, magnitude(tree));
}
fn testAddition(s1: []const u8, s2: []const u8, expected_sum: []const u8, allocator: std.mem.Allocator) !void {
    var tree1 = try testBuildTree(s1, allocator);
    var tree2 = try testBuildTree(s2, allocator);
    var actual = try addTrees(tree1, tree2, allocator);
    defer freeTree(actual, allocator);
    var expected = try testBuildTree(expected_sum, allocator);
    defer freeTree(expected, allocator);
    try treesAreEqual(expected, actual, allocator);
}
fn testPart1() !void {
    // Test magnitude
    try testMagnitude("[9,1]", 29, std.testing.allocator);
    try testMagnitude("[[9,1],[1,9]]", 129, std.testing.allocator);
    try testMagnitude("[[1,2],[[3,4],5]]", 143, std.testing.allocator);
    try testMagnitude("[[[[0,7],4],[[7,8],[6,0]]],[8,1]]", 1384, std.testing.allocator);
    try testMagnitude("[[[[1,1],[2,2]],[3,3]],[4,4]]", 445, std.testing.allocator);
    try testMagnitude("[[[[3,0],[5,3]],[4,4]],[5,5]]", 791, std.testing.allocator);
    try testMagnitude("[[[[5,0],[7,4]],[5,5]],[6,6]]", 1137, std.testing.allocator);
    try testMagnitude("[[[[8,7],[7,7]],[[8,6],[7,7]]],[[[0,7],[6,6]],[8,7]]]", 3488, std.testing.allocator);
    // test addition
    try testAddition("[[[[4,3],4],4],[7,[[8,4],9]]]", "[1,1]", "[[[[0,7],4],[[7,8],[6,0]]],[8,1]]", std.testing.allocator);
    const longer_input =
        \\[[[0,[4,5]],[0,0]],[[[4,5],[2,6]],[9,5]]]
        \\[7,[[[3,7],[4,3]],[[6,3],[8,8]]]]
        \\[[2,[[0,8],[3,4]]],[[[6,7],1],[7,[1,6]]]]
        \\[[[[2,4],7],[6,[0,5]]],[[[6,8],[2,8]],[[2,1],[4,5]]]]
        \\[7,[5,[[3,8],[1,4]]]]
        \\[[2,[2,2]],[8,[8,1]]]
        \\[2,9]
        \\[1,[[[9,3],9],[[9,0],[0,7]]]]
        \\[[[5,[7,4]],7],1]
        \\[[[[4,2],2],6],[8,7]]
    ;
    {
        var lines = std.mem.tokenize(u8, longer_input, "\r\n");
        var sum: ?*TreeNode = null;
        defer freeTree(sum.?, std.testing.allocator);
        while (lines.next()) |line| {
            var line_pos: usize = 0;
            var tree = buildTree(line, &line_pos, null, std.testing.allocator) catch unreachable;
            assert(line_pos == line.len);
            if (sum == null) {
                //print("  ", .{});
                //try printTree(tree, std.testing.allocator);
                sum = tree;
            } else {
                //print("+ ", .{});
                //try printTree(tree, std.testing.allocator);
                sum = addTrees(sum.?, tree, std.testing.allocator) catch unreachable;
                //print("= ", .{});
                //try printTree(sum.?, std.testing.allocator);
            }
        }
    }

    if (part1_test_solution) |solution| {
        var test_input = try Input.init(test_data, std.testing.allocator);
        defer test_input.deinit();
        try std.testing.expectEqual(solution, part1(test_input));
    }

    if (part1_solution) |solution| {
        var timer = try std.time.Timer.start();
        var input = try Input.init(data, std.testing.allocator);
        defer input.deinit();
        try std.testing.expectEqual(solution, part1(input));
        print("part1 took {d:9.3}ms\n", .{@intToFloat(f64, timer.lap()) / 1000000.0});
    }
}

fn testPart2() !void {
    if (part2_test_solution) |solution| {
        var test_input = try Input.init(test_data, std.testing.allocator);
        defer test_input.deinit();
        try std.testing.expectEqual(solution, part2(test_input));
    }

    if (part2_solution) |solution| {
        var timer = try std.time.Timer.start();
        var input = try Input.init(data, std.testing.allocator);
        defer input.deinit();
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
