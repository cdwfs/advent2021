const std = @import("std");
const util = @import("util.zig");

const data = @embedFile("../data/day05.txt");

const Point2 = struct {
    x:i16,
    y:i16,
};
const VentMap = struct {
    map: std.AutoHashMap(Point2, u32) = undefined,

    pub fn init(allocator: *std.mem.Allocator) @This() {
        var map = std.AutoHashMap(Point2, u32).init(allocator);
        return @This(){
            .map = map,
        };
    }

    pub fn deinit(self: *@This()) void {
        self.map.deinit();
        self.* = undefined;
    }

    pub fn add(self: *@This(), point:Point2) void {
        if (self.map.getOrPut(point)) |result| {
            if (!result.found_existing) {
                result.value_ptr.* = 0;
            }
            result.value_ptr.* += 1;
        } else |err| {
            print("getOrPut error: {}\n", .{err});
        }
    }
};

const VentLine = struct {
    x1:i16,
    y1:i16,
    x2:i16,
    y2:i16,
};
const Input = struct {
    lines: std.ArrayList(VentLine) = std.ArrayList(VentLine).init(std.testing.allocator),
    pub fn deinit(self:@This()) void {
        self.lines.deinit();
    }
};

fn parseInput(input_text: []const u8) Input {
    var input = Input{};
    var lines = std.mem.tokenize(u8, input_text, "\r\n");
    while(lines.next()) |line| {
        var endpoints = std.mem.tokenize(u8, line, ",- >");
        input.lines.append(VentLine{
            .x1 = parseInt(i16, endpoints.next().?, 10) catch unreachable,
            .y1 = parseInt(i16, endpoints.next().?, 10) catch unreachable,
            .x2 = parseInt(i16, endpoints.next().?, 10) catch unreachable,
            .y2 = parseInt(i16, endpoints.next().?, 10) catch unreachable,
        }) catch unreachable;
    }
    return input;
}

fn part1(input: Input) i64 {
    var map = VentMap.init(std.testing.allocator);
    defer map.deinit();

    for(input.lines.items) |line| {
        //print("line from {d},{d} to {d},{d}\n", .{line.x1, line.y1, line.x2, line.y2});
        if (line.x1 == line.x2) {
            const y_min = min(line.y1, line.y2);
            const y_max = max(line.y1, line.y2);
            var y = y_min;
            while(y <= y_max) : (y += 1) {
                //print(" point at {d},{d}\n", .{line.x1, y});
                map.add(Point2{.x = line.x1, .y = y});
            }
        } else if (line.y1 == line.y2) {
            const x_min = min(line.x1, line.x2);
            const x_max = max(line.x1, line.x2);
            var x = x_min;
            while(x <= x_max) : (x += 1) {
                //print(" point at {d},{d}\n", .{x, line.y1});
                map.add(Point2{.x = x, .y = line.y1});
            }
        }
    }

    var values = map.map.valueIterator();
    var count:i64 = 0;
    while(values.next()) |val| {
        if (val.* > 1) {
            count += 1;
        }
    }
    return count;
}

fn part2(input: Input) i64 {
    var map = VentMap.init(std.testing.allocator);
    defer map.deinit();

    for(input.lines.items) |line| {
        //print("line from {d},{d} to {d},{d}\n", .{line.x1, line.y1, line.x2, line.y2});
        var x = line.x1;
        var y = line.y1;
        var dx:i16 = 0;
        if (line.x2 > line.x1) {
            dx = 1;
        } else if (line.x2 < line.x1) {
            dx = -1;
        }
        var dy:i16 = 0;
        if (line.y2 > line.y1) {
            dy = 1;
        } else if (line.y2 < line.y1) {
            dy = -1;
        }
        while(x != line.x2 or y != line.y2)  : ({x += dx; y += dy;}) {
            //print(" point at {d},{d}\n", .{x, y});
            map.add(Point2{.x = x, .y = y});
        }
        //print(" point at {d},{d}\n", .{line.x2, line.y2});
        map.add(Point2{.x = line.x2, .y = line.y2});
    }

    var values = map.map.valueIterator();
    var count:i64 = 0;
    while(values.next()) |val| {
        if (val.* > 1) {
            count += 1;
        }
    }
    return count;
}

fn testPart1() !void {
    var test_input = parseInput(test_data);
    defer test_input.deinit();
    try std.testing.expectEqual(@as(i64, 5), part1(test_input));

    var input = parseInput(data);
    defer input.deinit();
    try std.testing.expectEqual(@as(i64, 6225), part1(input));
}

fn testPart2() !void {
    var test_input = parseInput(test_data);
    defer test_input.deinit();
    try std.testing.expectEqual(@as(i64, 12), part2(test_input));

    var input = parseInput(data);
    defer input.deinit();
    try std.testing.expectEqual(@as(i64, 12833), part2(input));
}

pub fn main() !void {
    try testPart1();
    try testPart2();
}

const test_data =
    \\0,9 -> 5,9
    \\8,0 -> 0,8
    \\9,4 -> 3,4
    \\2,2 -> 2,1
    \\7,0 -> 7,4
    \\6,4 -> 2,0
    \\0,9 -> 2,9
    \\3,4 -> 1,4
    \\0,0 -> 8,8
    \\5,5 -> 8,2
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
