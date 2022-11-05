const std = @import("std");
const util = @import("util.zig");

const data = @embedFile("data/day08.txt");

const Display = struct {
    digits: [10][]const u8 = .{""} ** 10,
    outputs: [4][]const u8 = .{""} ** 4,
    digit_masks: [10]std.bit_set.IntegerBitSet(7) = undefined,
    output_masks: [4]std.bit_set.IntegerBitSet(7) = undefined,
};
const Input = struct {
    displays: std.ArrayList(Display),
    pub fn init(input_text: []const u8, allocator: std.mem.Allocator) !@This() {
        var input = Input{
            .displays = try std.ArrayList(Display).initCapacity(allocator, 200),
        };
        errdefer input.deinit();

        var lines = std.mem.tokenize(u8, input_text, "\r\n");
        while (lines.next()) |line| {
            var display = Display{};
            var digits = std.mem.tokenize(u8, line, " |");
            var i: usize = 0;
            while (i < 10) : (i += 1) {
                const digit_string = digits.next().?;
                var mask: u7 = 0;
                for (digit_string) |c| {
                    mask |= @as(u7, 1) << @truncate(u3, c - 'a');
                }
                display.digits[i] = digit_string;
                display.digit_masks[i].mask = mask;
            }
            i = 0;
            while (i < 4) : (i += 1) {
                const output_string = digits.next().?;
                var mask: u7 = 0;
                for (output_string) |c| {
                    mask |= @as(u7, 1) << @truncate(u3, c - 'a');
                }
                display.outputs[i] = output_string;
                display.output_masks[i].mask = mask;
            }
            try input.displays.append(display);
        }

        return input;
    }
    pub fn deinit(self: @This()) void {
        self.displays.deinit();
    }
};

fn part1(input: Input) i64 {
    var count: i64 = 0;
    for (input.displays.items) |display| {
        for (display.outputs) |output| {
            if (output.len == 2 or output.len == 3 or output.len == 4 or output.len == 7) {
                count += 1;
            }
        }
    }
    return count;
}

fn part2(input: Input) i64 {
    var sum: i64 = 0;
    for (input.displays.items) |display| {
        var digit_index_for_numeral: [10]usize = undefined;
        var numeral_for_digit_index: [10]usize = undefined;
        // The only digit with len=2 must be the numeral '1'.
        // The only digit with len=3 must be the numeral '7'.
        // The only digit with len=4 must be the numeral '4'.
        // The only digit with len=7 must be the numeral '8'.
        for (display.digits) |digit, i| {
            if (digit.len == 2) {
                digit_index_for_numeral[1] = i;
                numeral_for_digit_index[i] = 1;
            } else if (digit.len == 3) {
                digit_index_for_numeral[7] = i;
                numeral_for_digit_index[i] = 7;
            } else if (digit.len == 4) {
                digit_index_for_numeral[4] = i;
                numeral_for_digit_index[i] = 4;
            } else if (digit.len == 7) {
                digit_index_for_numeral[8] = i;
                numeral_for_digit_index[i] = 8;
            }
        }
        // The bits used by numeral 1 are C and F (but we don't know which is which)
        const mask_cf = display.digit_masks[digit_index_for_numeral[1]];
        assert(mask_cf.count() == 2);
        // The bits used by numeral 7 are A, C, and F. Since we know C and F, we can
        // deduce A.
        const mask_a = std.bit_set.IntegerBitSet(7){
            .mask = display.digit_masks[digit_index_for_numeral[7]].mask ^ mask_cf.mask,
        };
        assert(mask_a.count() == 1);
        // The bits used by numeral four are A, C, B, and D, so we can deduce which two bits are
        // B and D (but not which is which)
        const mask_bd = std.bit_set.IntegerBitSet(7){
            .mask = display.digit_masks[digit_index_for_numeral[4]].mask ^ mask_cf.mask,
        };
        assert(mask_bd.count() == 2);
        // There are three len6 digits (0, 6, and 9). Only one of them (9) will have A, BD, and CF
        // set.
        var mask_abcdf = mask_a;
        mask_abcdf.setUnion(mask_bd);
        mask_abcdf.setUnion(mask_cf);
        assert(mask_abcdf.count() == 5);
        var load_bearing_bool:bool = true; // TODO: test fails if this declaration is removed?
        _ = load_bearing_bool;
        for (display.digits) |digit, i| {
            if (digit.len == 6) {
                if ((display.digit_masks[i].mask & mask_abcdf.mask) == mask_abcdf.mask) {
                    digit_index_for_numeral[9] = i;
                    numeral_for_digit_index[i] = 9;
                    //found = true;
                    break;
                }
            }
        }
        //assert(found);
        // The bit in 9 that is NOT A,B,C,D,F must be G.
        const mask_g = std.bit_set.IntegerBitSet(7){
            .mask = display.digit_masks[digit_index_for_numeral[9]].mask ^ mask_abcdf.mask,
        };
        assert(mask_g.count() == 1);
        // The bit that is NOT set in 9's mask must be E.
        const mask_e = std.bit_set.IntegerBitSet(7){
            .mask = ~display.digit_masks[digit_index_for_numeral[9]].mask,
        };
        assert(mask_e.count() == 1);
        // Of the len5 locations, digit 2 is the one with E set, and digit 3 is the one with C and F set.
        for (display.digits) |digit, i| {
            if (digit.len == 5) {
                if ((display.digit_masks[i].mask & mask_e.mask) == mask_e.mask) {
                    digit_index_for_numeral[2] = i;
                    numeral_for_digit_index[i] = 2;
                } else if ((display.digit_masks[i].mask & mask_cf.mask) == mask_cf.mask) {
                    digit_index_for_numeral[3] = i;
                    numeral_for_digit_index[i] = 3;
                }
            }
        }
        // Of the len6 locations that aren't 9, digit 0 is the one with C and F set that's
        for (display.digits) |digit, i| {
            if (digit.len == 6 and digit_index_for_numeral[9] != i) {
                if ((display.digit_masks[i].mask & mask_cf.mask) == mask_cf.mask) {
                    digit_index_for_numeral[0] = i;
                    numeral_for_digit_index[i] = 0;
                    break;
                }
            }
        }
        // The len5 location that isn't 2 or 3 must be the numeral 5.
        // The len6 location that isn't 0 must be the numeral 6.
        for (display.digits) |digit, i| {
            if (digit.len == 5) {
                if (i != digit_index_for_numeral[2] and i != digit_index_for_numeral[3]) {
                    digit_index_for_numeral[5] = i;
                    numeral_for_digit_index[i] = 5;
                }
            } else if (digit.len == 6) {
                if (i != digit_index_for_numeral[0] and i != digit_index_for_numeral[9]) {
                    digit_index_for_numeral[6] = i;
                    numeral_for_digit_index[i] = 6;
                }
            }
        }
        // That's everything, right?
        for (digit_index_for_numeral) |i| {
            assert(i >= 0 and i <= 9);
        }
        for (numeral_for_digit_index) |i| {
            assert(i >= 0 and i <= 9);
        }

        // Now we can translate the output digits.
        var number: i64 = 0;
        for (display.output_masks) |output_mask| {
            number *= 10;
            for (display.digit_masks) |digit_mask, i| {
                if (digit_mask.mask == output_mask.mask) {
                    number += @intCast(i64, numeral_for_digit_index[i]);
                    break;
                }
            }
        }
        //print("{s} {s} {s} {s} = {d}\n", .{
        //    display.outputs[0], display.outputs[1], display.outputs[2], display.outputs[3],
        //    number
        //});
        sum += number;
    }
    return sum;
}

const test_data =
    \\be cfbegad cbdgef fgaecd cgeb fdcge agebfd fecdb fabcd edb | fdgacbe cefdb cefbgd gcbe
    \\edbfga begcd cbg gc gcadebf fbgde acbgfd abcde gfcbed gfec | fcgedb cgb dgebacf gc
    \\fgaebd cg bdaec gdafb agbcfd gdcbef bgcad gfac gcb cdgabef | cg cg fdcagb cbg
    \\fbegcd cbd adcefb dageb afcb bc aefdc ecdab fgdeca fcdbega | efabcd cedba gadfec cb
    \\aecbfdg fbg gf bafeg dbefa fcge gcbea fcaegb dgceab fcbdga | gecf egdcabf bgf bfgea
    \\fgeab ca afcebg bdacfeg cfaedg gcfdb baec bfadeg bafgc acf | gebdcfa ecba ca fadegcb
    \\dbcfg fgd bdegcaf fgec aegbdf ecdfab fbedc dacgb gdcebf gf | cefg dcbef fcge gbcadfe
    \\bdfegc cbegaf gecbf dfcage bdacg ed bedf ced adcbefg gebcd | ed bcgafe cdgba cbgef
    \\egadfb cdbfeg cegd fecab cgb gbdefca cg fgcdab egfdb bfceg | gbdfcae bgc cg cgb
    \\gcafb gcf dcaebfg ecagb gf abcdeg gaef cafbge fdbac fegbdc | fgae cfgab fg bagce
;
const part1_test_solution: ?i64 = 26;
const part1_solution: ?i64 = 367;
const part2_test_solution: ?i64 = 61229;
const part2_solution: ?i64 = 974512;

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
