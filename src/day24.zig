const std = @import("std");
const util = @import("util.zig");

const data = @embedFile("../data/day24.txt");

const Reg = enum(u2) {
    W = 0,
    X = 1,
    Y = 2,
    Z = 3,
};
const Arg = enum(i64) {
    RW = 100,
    RX = 101,
    RY = 102,
    RZ = 103,
    _,
};
const Opcode = enum(u3) {
    inp = 0,
    add = 1,
    mul = 2,
    div = 3,
    mod = 4,
    eql = 5,
};
const Instruction = struct {
    op: Opcode,
    reg: Reg,
    arg: Arg,
};

const Input = struct {
    instructions: std.BoundedArray(Instruction, 256),

    pub fn init(input_text: []const u8) !@This() {
        var self = Input{
            .instructions = try std.BoundedArray(Instruction, 256).init(0),
        };

        var lines = std.mem.tokenize(u8, input_text, "\r\n");
        while (lines.next()) |line| {
            var tokens = std.mem.tokenize(u8, line, " ");
            const op = tokens.next().?;
            const reg = tokens.next().?;
            const a = tokens.next();
            self.instructions.appendAssumeCapacity(Instruction{
                .op = switch (op[1]) {
                    'n' => .inp,
                    'd' => .add,
                    'u' => .mul,
                    'i' => .div,
                    'o' => .mod,
                    'q' => .eql,
                    else => unreachable,
                },
                .reg = switch (reg[0]) {
                    'w' => .W,
                    'x' => .X,
                    'y' => .Y,
                    'z' => .Z,
                    else => unreachable, // arg1 must be a register
                },
                .arg = if (op[1] == 'n') @intToEnum(Arg, 0) else switch (a.?[0]) {
                    'w' => .RW,
                    'x' => .RX,
                    'y' => .RY,
                    'z' => .RZ,
                    else => @intToEnum(Arg, try parseInt(i64, a.?, 10)),
                },
            });
        }
        return self;
    }
};

fn argValue(regs: [4]i64, arg: Arg) i64 {
    return switch (arg) {
        .RW => regs[@enumToInt(Reg.W)],
        .RX => regs[@enumToInt(Reg.X)],
        .RY => regs[@enumToInt(Reg.Y)],
        .RZ => regs[@enumToInt(Reg.Z)],
        else => @enumToInt(arg),
    };
}

fn run(instructions: std.BoundedArray(Instruction, 256), input: []const u8) [4]i64 {
    var regs: [4]i64 = .{0} ** 4;
    var next_input: usize = 0;
    for (instructions.constSlice()) |inst| {
        const r = &regs[@enumToInt(inst.reg)];
        const b = argValue(regs, inst.arg);
        switch (inst.op) {
            .inp => {
                assert(next_input < input.len);
                const in = @intCast(i64, input[next_input] - '0');
                assert(in >= 1 and in <= 9);
                next_input += 1;
                r.* = in;
            },
            .add => {
                r.* += b;
            },
            .mul => {
                r.* *= b;
            },
            .div => {
                assert(b != 0);
                r.* = @divTrunc(r.*, b);
            },
            .mod => {
                assert(r.* >= 0);
                assert(b > 0);
                r.* = @rem(r.*, b);
            },
            .eql => {
                r.* = if (r.* == b) 1 else 0;
            },
        }
    }
    return regs;
}

fn part1(input: Input) i64 {
    // z /= 26, maybe?
    // if (z%26)+K != in[i]
    //   z *= 26
    //   z += in[i] + N
    //  0: D= 1 K= 10 N=13
    //  1: D= 1 K= 13 N=10
    //  2: D= 1 K= 13 N= 3
    //  3: D=26 K=-11 N= 1
    //  4: D= 1 K= 11 N= 9
    //  5: D=26 K= -4 N= 3
    //  6: D= 1 K= 12 N= 5
    //  7: D= 1 K= 12 N= 1
    //  8: D= 1 K= 15 N= 0
    //  9: D=26 K= -2 N=13
    // 10: D=26 K= -5 N= 7
    // 11: D=26 K=-11 N=15
    // 12: D=26 K=-13 N=12
    // 13: D=26 K=-10 N= 8

    //                      89
    //                    7   A
    //                   6      B
    //                4 5
    //              23
    //            1              C
    //           0                D

    //           01 234 567 89A BCD
    var m: i64 = 69_914_999_975_369;
    var s: [15]u8 = undefined;
    const len = std.fmt.formatIntBuf(s[0..], m, 10, .lower, std.fmt.FormatOptions{});
    assert(len == 14);
    for (s) |digit| {
        assert(digit != '0');
    }
    const regs = run(input.instructions, s[0..]);
    return regs[@enumToInt(Reg.Z)];
}

fn part2(input: Input) i64 {
    //           01 234 567 89A BCD
    var m: i64 = 14_911_675_311_114;
    var s: [15]u8 = undefined;
    const len = std.fmt.formatIntBuf(s[0..], m, 10, .lower, std.fmt.FormatOptions{});
    assert(len == 14);
    for (s) |digit| {
        assert(digit != '0');
    }
    const regs = run(input.instructions, s[0..]);
    return regs[@enumToInt(Reg.Z)];
}

const part1_solution: ?i64 = 0;
const part2_test_solution: ?i64 = null;
const part2_solution: ?i64 = 0;

// Just boilerplate below here, nothing to see

fn testPart1() !void {
    var regs: [4]i64 = undefined;

    const test_data1 =
        \\inp x
        \\mul x -1
    ;
    var test_input1 = try Input.init(test_data1);
    regs = run(test_input1.instructions, "7");
    try std.testing.expectEqual(@as(i64, -7), regs[@enumToInt(Reg.X)]);

    const test_data2 =
        \\inp z
        \\inp x
        \\mul z 3
        \\eql z x
    ;
    var test_input2 = try Input.init(test_data2);
    regs = run(test_input2.instructions, "26");
    try std.testing.expectEqual(@as(i64, 1), regs[@enumToInt(Reg.Z)]);
    regs = run(test_input2.instructions, "27");
    try std.testing.expectEqual(@as(i64, 0), regs[@enumToInt(Reg.Z)]);

    const test_data3 =
        \\inp w
        \\add z w
        \\mod z 2
        \\div w 2
        \\add y w
        \\mod y 2
        \\div w 2
        \\add x w
        \\mod x 2
        \\div w 2
        \\mod w 2
    ;
    var test_input3 = try Input.init(test_data3);
    regs = run(test_input3.instructions, "9");
    try std.testing.expectEqual(@as(i64, 1), regs[@enumToInt(Reg.W)]);
    try std.testing.expectEqual(@as(i64, 0), regs[@enumToInt(Reg.X)]);
    try std.testing.expectEqual(@as(i64, 0), regs[@enumToInt(Reg.Y)]);
    try std.testing.expectEqual(@as(i64, 1), regs[@enumToInt(Reg.Z)]);

    var timer = try std.time.Timer.start();
    var input = try Input.init(data);
    if (part1_solution) |solution| {
        try std.testing.expectEqual(solution, part1(input));
        print("part1 took {d:9.3}ms\n", .{@intToFloat(f64, timer.lap()) / 1000000.0});
    }
}

fn testPart2() !void {
    var timer = try std.time.Timer.start();
    var input = try Input.init(data);
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
