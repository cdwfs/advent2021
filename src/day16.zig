const std = @import("std");
const util = @import("util.zig");

const data = @embedFile("data/day16.txt");

const Input = struct {
    bits: std.DynamicBitSet = undefined,

    pub fn init(input_text: []const u8, allocator: std.mem.Allocator) !@This() {
        var input = Input{};
        errdefer input.deinit();

        var lines = std.mem.tokenize(u8, input_text, "\r\n");
        while (lines.next()) |line| {
            input.bits = try std.DynamicBitSet.initEmpty(allocator, line.len * 4);
            var i: usize = 0;
            while (i < line.len) : (i += 1) {
                const hexit: u4 = try parseInt(u4, line[i .. i + 1], 16);
                if ((hexit & 0b1000) != 0) input.bits.set(i * 4 + 0);
                if ((hexit & 0b0100) != 0) input.bits.set(i * 4 + 1);
                if ((hexit & 0b0010) != 0) input.bits.set(i * 4 + 2);
                if ((hexit & 0b0001) != 0) input.bits.set(i * 4 + 3);
            }
        }

        return input;
    }
    pub fn deinit(self: *@This()) void {
        self.bits.deinit();
    }
};

const PacketType = enum(u3) {
    OpSum = 0,
    OpProduct = 1,
    OpMin = 2,
    OpMax = 3,
    Literal = 4,
    OpGreaterThan = 5,
    OpLessThan = 6,
    OpEqualTo = 7,
};

fn readBits(comptime T: type, start_bit: *usize, bits: std.DynamicBitSet) !T {
    const int_type = switch (@typeInfo(T)) {
        .Int => T,
        .Enum => |info| info.tag_type,
        else => @compileError("expected enum or union type, found '" ++ @typeName(T) ++ "'"),
    };
    const bit_count = @typeInfo(int_type).Int.bits;
    var i: usize = start_bit.*;
    const end_bit = i + bit_count;
    if (end_bit > bits.capacity()) {
        return error.OutOfRange;
    }
    start_bit.* += bit_count;
    // Special case for reading a single bit
    if (bit_count == 1) {
        return @as(int_type, if (bits.isSet(i)) 1 else 0);
    }
    var result_as_int: int_type = 0;
    while (i < end_bit) : (i += 1) {
        result_as_int = (result_as_int << 1) | @as(int_type, if (bits.isSet(i)) 1 else 0);
    }
    var result = switch (@typeInfo(T)) {
        .Int => result_as_int,
        .Enum => @intToEnum(T, result_as_int),
        else => @compileError("expected enum or union type, found '" ++ @typeName(T) ++ "'"),
    };
    return result;
}

fn initPrefixSum(op: PacketType) i64 {
    return switch (op) {
        .OpSum => 0,
        .OpProduct => 1,
        .OpMin => std.math.maxInt(i64),
        .OpMax => std.math.minInt(i64),
        .OpGreaterThan => -1,
        .OpLessThan => -1,
        .OpEqualTo => -1,
        else => unreachable,
    };
}

fn applyPrefixSum(op: PacketType, sum: *i64, val: i64) void {
    sum.* = switch (op) {
        .OpSum => sum.* + val,
        .OpProduct => sum.* * val,
        .OpMin => std.math.min(sum.*, val),
        .OpMax => std.math.max(sum.*, val),
        .OpGreaterThan => if (sum.* == -1) val else if (sum.* > val) @as(i64, 1) else @as(i64, 0),
        .OpLessThan => if (sum.* == -1) val else if (sum.* < val) @as(i64, 1) else @as(i64, 0),
        .OpEqualTo => if (sum.* == -1) val else if (sum.* == val) @as(i64, 1) else @as(i64, 0),
        else => unreachable,
    };
}

fn processPacket(bits: std.DynamicBitSet, next_bit: *usize, version_sum: *i64) anyerror!i64 {
    const version = try readBits(u3, next_bit, bits);
    version_sum.* += version;
    const type_id = try readBits(PacketType, next_bit, bits);
    switch (type_id) {
        .Literal => {
            var value: i64 = 0;
            const continue_mask: u5 = 0b10000;
            while (true) {
                const literal_block = try readBits(u5, next_bit, bits);
                value <<= 4;
                value |= @as(i64, literal_block & ~continue_mask);
                if ((literal_block & continue_mask) == 0) {
                    //print("{d} ", .{value});
                    return value;
                }
            }
        },
        else => {
            var sum: i64 = initPrefixSum(type_id);
            const length_type_id = try readBits(u1, next_bit, bits);
            //print("{s}(", .{@tagName(type_id)});
            if (length_type_id == 0) {
                const bit_count = try readBits(u15, next_bit, bits);
                const end_bit = next_bit.* + bit_count;
                while (next_bit.* < end_bit) {
                    applyPrefixSum(type_id, &sum, try processPacket(bits, next_bit, version_sum));
                }
            } else {
                const packet_count: usize = try readBits(u11, next_bit, bits);
                var packet: usize = 0;
                while (packet < packet_count) : (packet += 1) {
                    applyPrefixSum(type_id, &sum, try processPacket(bits, next_bit, version_sum));
                }
            }
            //print(")", .{});
            return sum;
        },
    }
}

fn part1(input: Input) i64 {
    var next_bit: usize = 0;
    var version_sum: i64 = 0;
    _ = processPacket(input.bits, &next_bit, &version_sum) catch unreachable;
    return version_sum;
}

fn part2(input: Input) i64 {
    var next_bit: usize = 0;
    var version_sum: i64 = 0;
    return processPacket(input.bits, &next_bit, &version_sum) catch unreachable;
}

const test_data =
    \\D2FE28
;
const part1_test_solution: ?i64 = 6;
const part1_solution: ?i64 = 847;
const part2_test_solution: ?i64 = 2021;
const part2_solution: ?i64 = 333794664059;

// Just boilerplate below here, nothing to see

fn testPart1() !void {
    var test_input = try Input.init(test_data, std.testing.allocator);
    defer test_input.deinit();
    if (part1_test_solution) |solution| {
        try std.testing.expectEqual(solution, part1(test_input));
    }

    var test_input2 = try Input.init("8A004A801A8002F478", std.testing.allocator);
    defer test_input2.deinit();
    try std.testing.expectEqual(@as(i64, 16), part1(test_input2));

    var test_input3 = try Input.init("620080001611562C8802118E34", std.testing.allocator);
    defer test_input3.deinit();
    try std.testing.expectEqual(@as(i64, 12), part1(test_input3));

    var test_input4 = try Input.init("C0015000016115A2E0802F182340", std.testing.allocator);
    defer test_input4.deinit();
    try std.testing.expectEqual(@as(i64, 23), part1(test_input4));

    var test_input5 = try Input.init("A0016C880162017C3686B18A3D4780", std.testing.allocator);
    defer test_input5.deinit();
    try std.testing.expectEqual(@as(i64, 31), part1(test_input5));

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

    var test_input2 = try Input.init("C200B40A82", std.testing.allocator);
    defer test_input2.deinit();
    try std.testing.expectEqual(@as(i64, 3), part2(test_input2));

    var test_input3 = try Input.init("04005AC33890", std.testing.allocator);
    defer test_input3.deinit();
    try std.testing.expectEqual(@as(i64, 54), part2(test_input3));

    var test_input4 = try Input.init("880086C3E88112", std.testing.allocator);
    defer test_input4.deinit();
    try std.testing.expectEqual(@as(i64, 7), part2(test_input4));

    var test_input5 = try Input.init("CE00C43D881120", std.testing.allocator);
    defer test_input5.deinit();
    try std.testing.expectEqual(@as(i64, 9), part2(test_input5));

    var test_input6 = try Input.init("D8005AC2A8F0", std.testing.allocator);
    defer test_input6.deinit();
    try std.testing.expectEqual(@as(i64, 1), part2(test_input6));

    var test_input7 = try Input.init("F600BC2D8F", std.testing.allocator);
    defer test_input7.deinit();
    try std.testing.expectEqual(@as(i64, 0), part2(test_input7));

    var test_input8 = try Input.init("9C005AC2F8F0", std.testing.allocator);
    defer test_input8.deinit();
    try std.testing.expectEqual(@as(i64, 0), part2(test_input8));

    var test_input9 = try Input.init("9C0141080250320F1802104A08", std.testing.allocator);
    defer test_input9.deinit();
    try std.testing.expectEqual(@as(i64, 1), part2(test_input9));

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
