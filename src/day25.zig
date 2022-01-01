const std = @import("std");
const print = std.debug.print;

// In this contrived example, we've got a Particle struct with a bunch of fields in it.
// Let's see how long it takes to normalize the velocity fields on a million particles.
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

fn testSimdSoa() !void {
    const ELEM_COUNT = 1024*1024;
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

    print("\n", .{});
    {
        var timer = try std.time.Timer.start();
        for (array1.items) |*p| {
            const inv_len: f32 = 1.0 / std.math.sqrt(p.vel.x * p.vel.x + p.vel.y * p.vel.y + p.vel.z * p.vel.z);
            p.vel = Vec3{ .x = p.vel.x * inv_len, .y = p.vel.y * inv_len, .z = p.vel.z * inv_len };
        }
        const duration_ms = @intToFloat(f64, timer.lap()) / 1000000.0;
        var sum = Vec3{};
        for (array1.items) |*p| {
            sum.x += p.vel.x;
            sum.y += p.vel.y;
            sum.z += p.vel.z;
        }
        print("test1 duration:{d:6.3}ms result:{d:15.6} {d:15.6} {d:15.6} [AoS]\n",
            .{duration_ms, sum.x, sum.y, sum.z});
    }
    {
        var timer = try std.time.Timer.start();
        for (array2.items(.vel)) |*v| {
            const inv_len: f32 = 1.0 / std.math.sqrt(v.x * v.x + v.y * v.y + v.z * v.z);
            v.* = Vec3{ .x = v.x * inv_len, .y = v.y * inv_len, .z = v.z * inv_len };
        }
        const duration_ms = @intToFloat(f64, timer.lap()) / 1000000.0;
        var sum = Vec3{};
        for (array2.items(.vel)) |*v| {
            sum.x += v.x;
            sum.y += v.y;
            sum.z += v.z;
        }
        print("test2 duration:{d:6.3}ms result:{d:15.6} {d:15.6} {d:15.6} [SoA]\n",
            .{duration_ms, sum.x, sum.y, sum.z});
    }
    {
        var timer = try std.time.Timer.start();
        const VEC_WIDTH = 8;
        var s = array3.slice();
        const xs = s.items(.x);
        const ys = s.items(.y);
        const zs = s.items(.z);
        const ones = @splat(VEC_WIDTH, @as(f32, 1.0));
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
            const inv_len = ones / @sqrt(x * x + y * y + z * z);
            x_slice.* = x * inv_len;
            y_slice.* = y * inv_len;
            z_slice.* = z * inv_len;
        }
        const duration_ms = @intToFloat(f64, timer.lap()) / 1000000.0;
        var sum = Vec3{};
        for (xs) |x| {
            sum.x += x;
        }
        for (ys) |y| {
            sum.y += y;
        }
        for (zs) |z| {
            sum.z += z;
        }
        print("test3 duration:{d:6.3}ms result:{d:15.6} {d:15.6} {d:15.6} [SoA + SIMD]\n",
            .{duration_ms, sum.x, sum.y, sum.z});
    }
}

pub fn main() !void {
    try testSimdSoa();
}

test "SIMD+SoA tests" {
    try testSimdSoa();
}
