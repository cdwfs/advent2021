const std = @import("std");
const util = @import("util.zig");

const data = @embedFile("../data/day23.txt");

const Input = struct {
    stack1: [2]u8,
    stack2: [2]u8,
    stack3: [2]u8,
    stack4: [2]u8,

    pub fn init(input_text: []const u8, allocator: std.mem.Allocator) !@This() {
        _ = allocator;

        var lines = std.mem.tokenize(u8, input_text, "\r\n");
        _ = lines.next();
        _ = lines.next();
        const row1 = lines.next().?;
        const row2 = lines.next().?;

        var input = Input{
            .stack1 = [2]u8{ row2[3], row1[3] },
            .stack2 = [2]u8{ row2[5], row1[5] },
            .stack3 = [2]u8{ row2[7], row1[7] },
            .stack4 = [2]u8{ row2[9], row1[9] },
        };
        errdefer input.deinit();

        return input;
    }
    pub fn deinit(self: @This()) void {
        _ = self;
    }
};

fn energy(pod: u8) i64 {
    const POD_ENERGIES = [4]i64{ 1, 10, 100, 1000 };
    return POD_ENERGIES[pod - 'A'];
}
fn goal(pod: u8) i8 {
    const POD_GOALS = [4]i8{ 2, 4, 6, 8 };
    return POD_GOALS[pod - 'A'];
}
// 0123456789A
//#############
//#...........#
//###A#B#C#D###
const LEFT_FROM = [11][]const usize{
    &.{}, // 0
    &.{0}, // 1
    &.{ 1, 0 }, // 2
    &.{ 1, 0 }, // 3
    &.{ 3, 1, 0 }, // 4
    &.{ 3, 1, 0 }, // 5
    &.{ 5, 3, 1, 0 }, // 6
    &.{ 5, 3, 1, 0 }, // 7
    &.{ 7, 5, 3, 1, 0 }, // 8
    &.{ 7, 5, 3, 1, 0 }, // 9
    &.{ 9, 7, 5, 3, 1, 0 }, // 10
};
const RIGHT_FROM = [11][]const usize{
    &.{ 1, 3, 5, 7, 9, 10 }, // 0
    &.{ 3, 5, 7, 9, 10 }, // 1
    &.{ 3, 5, 7, 9, 10 }, // 2
    &.{ 5, 7, 9, 10 }, // 3
    &.{ 5, 7, 9, 10 }, // 4
    &.{ 7, 9, 10 }, // 5
    &.{ 7, 9, 10 }, // 6
    &.{ 9, 10 }, // 7
    &.{ 9, 10 }, // 8
    &.{10}, // 9
    &.{}, // 10
};

const PodStack = struct {
    array: std.BoundedArray(u8, 4) = undefined,
    x: i8 = undefined,
    num_to_sink: u8 = undefined,

    pub fn init(pods: []const u8, x: i8) @This() {
        var self = PodStack{
            .array = std.BoundedArray(u8, 4).init(0) catch unreachable,
            .x = x,
            .num_to_sink = @truncate(u8, pods.len),
        };
        for (pods) |pod| {
            self.array.appendAssumeCapacity(pod);
        }
        const sink_pod: u8 = 'A' + @intCast(u8, @divFloor(x - 2, 2));
        while (!self.empty() and self.array.buffer[0] == sink_pod) {
            _ = self.array.orderedRemove(0);
            self.num_to_sink -= 1;
        }
        return self;
    }
    pub fn empty(self: @This()) bool {
        return (self.array.len == 0);
    }
    pub fn top(self: @This()) ?u8 {
        if (self.empty())
            return null;
        const top_index = self.array.len - 1;
        const top_elem = self.array.buffer[top_index];
        return top_elem;
    }
    pub fn pop(self: *@This()) ?u8 {
        return self.array.popOrNull();
    }
    pub fn cost(self: @This()) i64 {
        var total: i64 = 0;
        for (self.array.constSlice()) |pod| {
            const gx = goal(pod);
            const e = energy(pod);
            total += if (gx == self.x) e * 2 else e * @intCast(i64, std.math.absInt(self.x - gx) catch unreachable);
        }
        return total;
    }
};

const Move = struct {
    pod: u8,
    x0: i8,
    x1: i8,
    pub fn cost(self: @This()) i64 {
        return energy(self.pod) * @intCast(i64, std.math.absInt(self.x1 - self.x0) catch unreachable);
    }
};

const MapState = struct {
    stacks: [4]PodStack = undefined,
    hallway: [11]u8 = .{'.'} ** 11,
    moves: std.BoundedArray(Move, 32) = undefined,
    cost: i64 = 0,
    fixed_cost: i64 = 0,
    pub fn init(stack1: []const u8, stack2: []const u8, stack3: []const u8, stack4: []const u8) @This() {
        var self = MapState{
            .stacks = [4]PodStack{
                PodStack.init(stack1, 2),
                PodStack.init(stack2, 4),
                PodStack.init(stack3, 6),
                PodStack.init(stack4, 8),
            },
            .moves = std.BoundedArray(Move, 32).init(0) catch unreachable,
        };
        // compute fixed cost: moving pods into & out of hallways.
        var countA: i64 = 0;
        var countB: i64 = 0;
        var countC: i64 = 0;
        var countD: i64 = 0;
        var moveA: i64 = 0;
        var moveB: i64 = 0;
        var moveC: i64 = 0;
        var moveD: i64 = 0;
        for (self.stacks) |stack| {
            const L = stack.array.len;
            for (stack.array.constSlice()) |pod, i| {
                if (pod == 'A') {
                    countA += 1;
                    moveA += @intCast(i64, L - i) + countA;
                } else if (pod == 'B') {
                    countB += 1;
                    moveB += @intCast(i64, L - i) + countB;
                } else if (pod == 'C') {
                    countC += 1;
                    moveC += @intCast(i64, L - i) + countC;
                } else if (pod == 'D') {
                    countD += 1;
                    moveD += @intCast(i64, L - i) + countD;
                }
            }
        }
        self.fixed_cost = (moveA * energy('A')) + (moveB * energy('B')) + (moveC * energy('C')) + (moveD * energy('D'));
        return self;
    }
    pub fn done(self: @This()) bool {
        return (self.stacks[0].num_to_sink == 0 and self.stacks[1].num_to_sink == 0 and self.stacks[2].num_to_sink == 0 and self.stacks[3].num_to_sink == 0);
    }
    // conservative estimate of the cost to complete the map from this state
    pub fn costEstimate(self: @This()) i64 {
        var total: i64 = 0;
        for (self.stacks) |stack| {
            total += stack.cost();
        }
        for (self.hallway) |pod, x| {
            if (pod == '.') {
                continue;
            } else {
                const gx = goal(pod);
                const sx = @intCast(i8, x);
                const e = energy(pod);
                total += e * @intCast(i64, std.math.absInt(sx - gx) catch unreachable);
            }
        }
        return total;
    }
    pub fn applyMove(self: *@This(), move: Move) void {
        if (move.x0 == 2 or move.x0 == 4 or move.x0 == 6 or move.x0 == 8) {
            // moving a pod from a stack into the hallway
            const si = @intCast(usize, @divFloor(move.x0 - 2, 2));
            assert(self.stacks[si].top().? == move.pod); // is this pod actually at the top of this stack?
            const hx = @intCast(usize, move.x1);
            assert(self.hallway[hx] == '.'); // is the destination in the hallway empty?
            _ = self.stacks[si].pop();
            self.hallway[hx] = move.pod;
        } else if (move.x1 == 2 or move.x1 == 4 or move.x1 == 6 or move.x1 == 8) {
            // moving a pod from the hallway into its sink
            const si: usize = move.pod - 'A';
            assert(si == @intCast(usize, @divFloor(move.x1 - 2, 2))); // is this the correct sink for this pod?
            assert(self.stacks[si].empty()); // is the sink an empty stack?
            assert(self.stacks[si].num_to_sink > 0); // does it still have room to sink things?
            const hx = @intCast(usize, move.x0);
            assert(self.hallway[hx] == move.pod); // is the pod we're moving actually in its source pos?
            self.stacks[si].num_to_sink -= 1;
            self.hallway[hx] = '.';
        } else {
            unreachable;
        }
        self.moves.appendAssumeCapacity(move);
        self.cost += move.cost();
    }
};

fn solveMap(state: MapState, lowest_cost: *i64) void {
    if (state.cost + state.costEstimate() >= lowest_cost.*) {
        return; // no point in pursuing this path
    }
    if (state.done()) {
        if (state.cost < lowest_cost.*) {
            lowest_cost.* = state.cost;
            //print("New shortest solution:\n", .{});
            //for (state.moves.constSlice()) |move| {
            //    if (move.x0 == 2 or move.x0 == 4 or move.x0 == 6 or move.x0 == 8) {
            //        print("Move {c} from stack {d} to hall {d}\n", .{ move.pod, move.x0, move.x1 });
            //    } else {
            //        print("Move {c} from hall {d} to sink {d}\n", .{ move.pod, move.x0, move.x1 });
            //    }
            //}
        }
        return;
    }
    // hallway moves first; it's always best to move things out of the hallway if possible.
    hallway_loop: for (state.hallway) |pod, i| {
        if (pod == '.' or !state.stacks[pod - 'A'].empty()) {
            continue;
        }
        var px = @intCast(i8, i);
        var gx = goal(pod);
        const x0 = @intCast(usize, if (gx < px) gx else px + 1);
        const x1 = @intCast(usize, if (gx < px) px else gx + 1);
        for (state.hallway[x0..x1]) |c| {
            if (c != '.') {
                continue :hallway_loop;
            }
        }
        // pod can move to its goal
        var new_state = state;
        new_state.applyMove(Move{ .pod = pod, .x0 = px, .x1 = gx });
        solveMap(new_state, lowest_cost);
    }
    // move things out of the stacks
    for (state.stacks) |stack| {
        if (stack.empty()) {
            continue;
        }
        const p = stack.top().?;
        const px: i8 = stack.x;
        // TODO: could be more clever here, prioritizing closer moves in either direction rather than a
        // depth-first search in one direction and the other.
        for (LEFT_FROM[@intCast(usize, px)]) |hx| {
            if (state.hallway[hx] != '.') {
                break; // this & further cells in this direction are blocked, can't move here.
            }
            // pod can move here
            //print("Move: {c},{d},{d} [from stack]\n", .{ pod, px, hx });
            var new_state = state;
            new_state.applyMove(Move{ .pod = p, .x0 = px, .x1 = @intCast(i8, hx) });
            solveMap(new_state, lowest_cost);
        }
        for (RIGHT_FROM[@intCast(usize, px)]) |hx| {
            if (state.hallway[hx] != '.') {
                break; // this & further cells in this direction are blocked, can't move here.
            }
            // pod can move here
            //print("Move: {c},{d},{d} [from stack]\n", .{ pod, px, hx });
            var new_state = state;
            new_state.applyMove(Move{ .pod = p, .x0 = px, .x1 = @intCast(i8, hx) });
            solveMap(new_state, lowest_cost);
        }
    }
}

fn sanityCheck() !i64 {
    var lowest_cost: i64 = std.math.maxInt(i64);
    var state = MapState.init("AB", "DC", "CB", "AD");

    solveMap(state, &lowest_cost);

    const fixed_cost = 3 * energy('A') + 5 * energy('B') + 2 * energy('C') + 6 * energy('D');
    return lowest_cost + fixed_cost;
}

fn part1(input: Input) i64 {
    var state = MapState.init(input.stack1[0..], input.stack2[0..], input.stack3[0..], input.stack4[0..]);
    var lowest_cost: i64 = std.math.maxInt(i64);
    solveMap(state, &lowest_cost);
    assert(lowest_cost < std.math.maxInt(i64));
    const fixed_cost = state.fixed_cost;
    return lowest_cost + fixed_cost;
}

fn part2(input: Input) i64 {
    const stack1 = [4]u8{ input.stack1[0], 'D', 'D', input.stack1[1] };
    const stack2 = [4]u8{ input.stack2[0], 'B', 'C', input.stack2[1] };
    const stack3 = [4]u8{ input.stack3[0], 'A', 'B', input.stack3[1] };
    const stack4 = [4]u8{ input.stack4[0], 'C', 'A', input.stack4[1] };
    var state = MapState.init(stack1[0..], stack2[0..], stack3[0..], stack4[0..]);
    var lowest_cost: i64 = std.math.maxInt(i64);
    solveMap(state, &lowest_cost);
    assert(lowest_cost < std.math.maxInt(i64));
    const fixed_cost = state.fixed_cost;
    return lowest_cost + fixed_cost;
}

const test_data =
    \\#############
    \\#...........#
    \\###B#C#B#D###
    \\  #A#D#C#A#
    \\  #########
;
const part1_test_solution: ?i64 = 12521;
const part1_solution: ?i64 = 11332;
const part2_test_solution: ?i64 = 44169;
const part2_solution: ?i64 = 49936;

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
