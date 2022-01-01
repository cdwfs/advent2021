const std = @import("std");
const util = @import("util.zig");

const data = @embedFile("../data/day25.txt");

const Input = struct {
    map: [140][140]u8 = undefined,
    dim_x: usize = 0,
    dim_y: usize = 0,

    pub fn init(input_text: []const u8, allocator: std.mem.Allocator) !@This() {
        _ = allocator;
        var self = Input{};
        errdefer self.deinit();

        var lines = std.mem.tokenize(u8, input_text, "\r\n");
        while (lines.next()) |line| : (self.dim_y += 1) {
            self.dim_x = line.len;
            std.mem.copy(u8, self.map[self.dim_y][0..], line);
        }

        return self;
    }
    pub fn deinit(self: @This()) void {
        _ = self;
    }
};

fn part1(input: Input) i64 {
    var mapA = input.map;
    var mapB = input.map;
    var step: i64 = 1;
    while (true) : (step += 1) {
        var moved: bool = false;
        // move >
        mapB = mapA;
        var y: usize = 0;
        while (y < input.dim_y) : (y += 1) {
            var x: usize = 0;
            while (x < input.dim_x) : (x += 1) {
                const x2 = @mod(x + 1, input.dim_x);
                if (mapA[y][x] == '>' and mapA[y][x2] == '.') {
                    mapB[y][x2] = '>';
                    mapB[y][x] = '.';
                    moved = true;
                }
            }
        }
        // move v
        mapA = mapB;
        y = 0;
        while (y < input.dim_y) : (y += 1) {
            const y2 = @mod(y + 1, input.dim_y);
            var x: usize = 0;
            while (x < input.dim_x) : (x += 1) {
                if (mapB[y][x] == 'v' and mapB[y2][x] == '.') {
                    mapA[y2][x] = 'v';
                    mapA[y][x] = '.';
                    moved = true;
                }
            }
        }
        if (!moved)
            return step;
    }
    unreachable;
}

const Vec3 = struct {
    x: f32 = 0,
    y: f32 = 0,
    z: f32 = 0,
};
const Particle = struct {
    pos: Vec3,
    vel: Vec3,
    color: Vec3,
    lifetime: f32,
    fn initRandom(rng: std.rand.Random) @This() {
        return @This(){
            .pos = Vec3{ .x = rng.float(f32), .y = rng.float(f32), .z = rng.float(f32) },
            .vel = Vec3{ .x = rng.float(f32), .y = rng.float(f32), .z = rng.float(f32) },
            .color = Vec3{ .x = rng.float(f32), .y = rng.float(f32), .z = rng.float(f32) },
            .lifetime = rng.float(f32),
        };
    }
};

fn testPart2() !void {
    const ELEM_COUNT = 1024 * 1024;
    var array1 = try std.ArrayList(Particle).initCapacity(std.testing.allocator, ELEM_COUNT);
    defer array1.deinit();
    var array2 = std.MultiArrayList(Particle){};
    defer array2.deinit(std.testing.allocator);
    try array2.ensureTotalCapacity(std.testing.allocator, ELEM_COUNT);
    var array3 = std.MultiArrayList(Vec3){};
    defer array3.deinit(std.testing.allocator);
    try array3.ensureTotalCapacity(std.testing.allocator, ELEM_COUNT);

    var i: usize = 0;
    var rng = std.rand.DefaultPrng.init(0).random();
    while (i < ELEM_COUNT) : (i += 1) {
        const p = Particle.initRandom(rng);
        array1.appendAssumeCapacity(p);
        array2.appendAssumeCapacity(p);
        array3.appendAssumeCapacity(p.vel);
    }

    {
        var timer = try std.time.Timer.start();
        for (array1.items) |*p| {
            const inv_len: f32 = 1.0 / std.math.sqrt(p.vel.x * p.vel.x + p.vel.y * p.vel.y + p.vel.z * p.vel.z);
            p.vel = Vec3{ .x = p.vel.x * inv_len, .y = p.vel.y * inv_len, .z = p.vel.z * inv_len };
        }
        print("particle ArrayList took {d:9.3}ms\n", .{@intToFloat(f64, timer.lap()) / 1000000.0});
    }
    {
        var timer = try std.time.Timer.start();
        for (array2.items(.vel)) |*v| {
            const inv_len: f32 = 1.0 / std.math.sqrt(v.x * v.x + v.y * v.y + v.z * v.z);
            v.* = Vec3{ .x = v.x * inv_len, .y = v.y * inv_len, .z = v.z * inv_len };
        }
        print("particle MultiArrayList took {d:9.3}ms\n", .{@intToFloat(f64, timer.lap()) / 1000000.0});
    }
    {
        var timer = try std.time.Timer.start();
        const VEC_WIDTH = 8;
        var s = array3.slice();
        const xs = s.items(.x);
        const ys = s.items(.x);
        const zs = s.items(.x);
        const ones = @splat(VEC_WIDTH,@as(f32,1.0));
        var iv: usize = 0;
        while (iv < array3.len) : (iv += VEC_WIDTH) {
            // Workaround to get a comptime-sized slice from a runtime offset
            const x_slice = xs[iv..][0..VEC_WIDTH];
            const y_slice = ys[iv..][0..VEC_WIDTH];
            const z_slice = zs[iv..][0..VEC_WIDTH];
            var x: std.meta.Vector(VEC_WIDTH, f32) = x_slice.*;
            var y: std.meta.Vector(VEC_WIDTH, f32) = y_slice.*;
            var z: std.meta.Vector(VEC_WIDTH, f32) = z_slice.*;
            // std.math.sqrt() isn't implemented for Vectors yet, but @sqrt() is
            x_slice.* = ones / @sqrt(x * x + y * y + z * z);
        }
        print("particle MultiArrayList w/SIMD took {d:9.3}ms\n", .{@intToFloat(f64, timer.lap()) / 1000000.0});
    }
}

const test_data =
    \\v...>>.vv>
    \\.vv>>.vv..
    \\>>.>v>...v
    \\>>v>>.>.v.
    \\v>v.vv.v..
    \\>.>>..v...
    \\.vv..>.>v.
    \\v.v..>>v.v
    \\....v..v.>
;
const part1_test_solution: ?i64 = 58;
const part1_solution: ?i64 = 378;

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
