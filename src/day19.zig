const std = @import("std");
const util = @import("util.zig");

const data = @embedFile("../data/day19.txt");

const Point3 = struct {
    x: i64,
    y: i64,
    z: i64,
};

const Input = struct {
    scanners: std.BoundedArray(std.BoundedArray(Point3, 27), 39) = undefined,

    pub fn init(input_text: []const u8, allocator: std.mem.Allocator) !@This() {
        _ = allocator;
        var input = Input{
            .scanners = try std.BoundedArray(std.BoundedArray(Point3, 27), 39).init(0),
        };
        errdefer input.deinit();

        var lines = std.mem.tokenize(u8, input_text, "\r\n");
        var scanner_index: usize = 0;
        while (lines.next()) |line| {
            if (line[3] == ' ') {
                // new scanner
                scanner_index = input.scanners.len;
                try input.scanners.append(try std.BoundedArray(Point3, 27).init(0));
            } else {
                // beacon within current scanner
                var coords = std.mem.tokenize(u8, line, ",");
                const x: i64 = try parseInt(i64, coords.next().?, 10);
                const y: i64 = try parseInt(i64, coords.next().?, 10);
                const z: i64 = try parseInt(i64, coords.next().?, 10);
                try input.scanners.buffer[scanner_index].append(Point3{ .x = x, .y = y, .z = z });
            }
        }

        return input;
    }
    pub fn deinit(self: @This()) void {
        _ = self;
    }
};

const transforms = [24][9]i32{
    [9]i32{ 1, 0, 0, 0, 1, 0, 0, 0, 1 },
    [9]i32{ 0, 0, 1, 0, 1, 0, -1, 0, 0 },
    [9]i32{ 0, 0, 1, 0, -1, 0, 1, 0, 0 },
    [9]i32{ 0, 0, 1, 1, 0, 0, 0, 1, 0 },
    [9]i32{ 0, 0, 1, -1, 0, 0, 0, -1, 0 },
    [9]i32{ 0, 0, -1, 0, 1, 0, 1, 0, 0 },
    [9]i32{ 0, 0, -1, 0, -1, 0, -1, 0, 0 },
    [9]i32{ 0, 0, -1, 1, 0, 0, 0, -1, 0 },
    [9]i32{ 0, 0, -1, -1, 0, 0, 0, 1, 0 },
    [9]i32{ 0, 1, 0, 0, 0, 1, 1, 0, 0 },
    [9]i32{ 0, 1, 0, 0, 0, -1, -1, 0, 0 },
    [9]i32{ 0, 1, 0, 1, 0, 0, 0, 0, -1 },
    [9]i32{ 0, 1, 0, -1, 0, 0, 0, 0, 1 },
    [9]i32{ 0, -1, 0, 0, 0, 1, -1, 0, 0 },
    [9]i32{ 0, -1, 0, 0, 0, -1, 1, 0, 0 },
    [9]i32{ 0, -1, 0, 1, 0, 0, 0, 0, 1 },
    [9]i32{ 0, -1, 0, -1, 0, 0, 0, 0, -1 },
    [9]i32{ 1, 0, 0, 0, 0, 1, 0, -1, 0 },
    [9]i32{ 1, 0, 0, 0, 0, -1, 0, 1, 0 },
    [9]i32{ 1, 0, 0, 0, -1, 0, 0, 0, -1 },
    [9]i32{ -1, 0, 0, 0, 0, 1, 0, 1, 0 },
    [9]i32{ -1, 0, 0, 0, 0, -1, 0, -1, 0 },
    [9]i32{ -1, 0, 0, 0, 1, 0, 0, 0, -1 },
    [9]i32{ -1, 0, 0, 0, -1, 0, 0, 0, 1 },
};
const IDENTITY_TRANSFORM: usize = 0;

fn transformPoints(points: []const Point3, out_points: []Point3, xform_index: usize) void {
    const mat = transforms[xform_index];
    for (points) |point, i| {
        out_points[i] = Point3{
            .x = mat[0] * point.x + mat[1] * point.y + mat[2] * point.z,
            .y = mat[3] * point.x + mat[4] * point.y + mat[5] * point.z,
            .z = mat[6] * point.x + mat[7] * point.y + mat[8] * point.z,
        };
    }
}

test "transformPoints" {
    const transform_test_data =
        \\--- scanner 0 ---
        \\-1,-1,1
        \\-2,-2,2
        \\-3,-3,3
        \\-2,-3,1
        \\5,6,-4
        \\8,0,7
        \\
        \\--- scanner 0 ---
        \\1,-1,1
        \\2,-2,2
        \\3,-3,3
        \\2,-1,3
        \\-5,4,-6
        \\-8,-7,0
        \\
        \\--- scanner 0 ---
        \\-1,-1,-1
        \\-2,-2,-2
        \\-3,-3,-3
        \\-1,-3,-2
        \\4,6,5
        \\-7,0,8
        \\
        \\--- scanner 0 ---
        \\1,1,-1
        \\2,2,-2
        \\3,3,-3
        \\1,3,-2
        \\-4,-6,5
        \\7,0,8
        \\
        \\--- scanner 0 ---
        \\1,1,1
        \\2,2,2
        \\3,3,3
        \\3,1,2
        \\-6,-4,-5
        \\0,7,-8
    ;
    var test_input = try Input.init(transform_test_data, std.testing.allocator);
    defer test_input.deinit();
    // populate set with beacons from scanner 0
    var all_beacons = std.AutoHashMap(Point3, bool).init(std.testing.allocator);
    defer all_beacons.deinit();
    try all_beacons.ensureTotalCapacity(6);
    for (test_input.scanners.buffer[0].constSlice()) |beacon_pos| {
        all_beacons.putAssumeCapacityNoClobber(beacon_pos, true);
    }
    // make sure remaining scanners all rotate to the existing beacons
    var transformed_points: [6]Point3 = .{undefined} ** 6;
    for (test_input.scanners.constSlice()) |scanner| {
        var found_xform_for_match = false;
        for (transforms) |_, xform_index| {
            transformPoints(scanner.constSlice(), transformed_points[0..], xform_index);
            //print("with transform {d:2}, beacon 5 transforms to {d:2},{d:2},{d:2}\n", .{ xform_index, transformed_points[5].x, transformed_points[5].y, transformed_points[5].z });
            var found_all_beacons = true;
            for (transformed_points) |pt| {
                if (!all_beacons.contains(pt)) {
                    found_all_beacons = false;
                    break;
                }
            }
            if (found_all_beacons) {
                found_xform_for_match = true;
                break;
            }
        }
        try expect(found_xform_for_match);
    }
}

const TransformedScannerData = struct {
    beacons: std.BoundedArray(Point3, 27),
    offsets: std.AutoHashMap(Point3, Point3),
    allocator: std.mem.Allocator,
    pub fn init(points: std.BoundedArray(Point3, 27), xform_index: usize, allocator: std.mem.Allocator) !@This() {
        var self = TransformedScannerData{
            .beacons = try std.BoundedArray(Point3, 27).init(points.len),
            .offsets = std.AutoHashMap(Point3, Point3).init(allocator),
            .allocator = allocator,
        };
        transformPoints(points.constSlice(), self.beacons.slice(), xform_index);
        const offset_count = @truncate(u32, (self.beacons.len * (self.beacons.len - 1)) / 2);
        try self.offsets.ensureTotalCapacity(offset_count);
        for (self.beacons.constSlice()) |p1, i| {
            var j: usize = i + 1;
            while (j < self.beacons.len) : (j += 1) {
                const p2 = self.beacons.buffer[j];
                const offset = Point3{ .x = p2.x - p1.x, .y = p2.y - p1.y, .z = p2.z - p1.z };
                self.offsets.putAssumeCapacity(offset, p1);
            }
        }
        return self;
    }
    pub fn deinit(self: *@This()) void {
        self.offsets.deinit();
    }
};
const Scanner = struct {
    transformed: std.BoundedArray(TransformedScannerData, 24),
    id: usize,
    pub fn init(id: usize, points: std.BoundedArray(Point3, 27), allocator: std.mem.Allocator) !@This() {
        var self = Scanner{
            .transformed = try std.BoundedArray(TransformedScannerData, 24).init(0),
            .id = id,
        };
        for (transforms) |_, xform_index| {
            self.transformed.appendAssumeCapacity(try TransformedScannerData.init(points, xform_index, allocator));
        }
        return self;
    }
    pub fn deinit(self: *@This()) void {
        for (self.transformed.slice()) |*t| {
            t.deinit();
        }
    }
};

const KnownSpace = struct {
    beacons: std.ArrayList(Point3),
    beacon_map: std.AutoHashMap(Point3, bool),
    offsets_map: std.AutoHashMap(Point3, Point3),
    scanner_positions: std.ArrayList(Point3),

    pub fn init(allocator: std.mem.Allocator) !@This() {
        var self = KnownSpace{
            .beacons = try std.ArrayList(Point3).initCapacity(allocator, 40 * 30),
            .beacon_map = std.AutoHashMap(Point3, bool).init(allocator),
            .offsets_map = std.AutoHashMap(Point3, Point3).init(allocator),
            .scanner_positions = try std.ArrayList(Point3).initCapacity(allocator, 40),
        };
        try self.beacon_map.ensureTotalCapacity(@truncate(u32, self.beacons.capacity));
        return self;
    }
    pub fn deinit(self: *@This()) void {
        self.beacons.deinit();
        self.beacon_map.deinit();
        self.offsets_map.deinit();
        self.scanner_positions.deinit();
    }

    pub fn pointWithOffset(self: @This(), offset: Point3) ?Point3 {
        return self.offsets_map.get(offset);
    }

    pub fn numMatches(self: @This(), scanner_points: std.BoundedArray(Point3, 27), relative_scanner_offset: Point3) usize {
        var count: usize = 0;
        for (scanner_points.constSlice()) |p| {
            const shifted = Point3{ .x = p.x + relative_scanner_offset.x, .y = p.y + relative_scanner_offset.y, .z = p.z + relative_scanner_offset.z };
            if (self.beacon_map.contains(shifted)) {
                count += 1;
            }
        }
        return count;
    }

    pub fn addScanner(self: *@This(), scanners: *std.BoundedArray(Scanner, 39), scanner_index: usize, xform_index: usize, relative_scanner_offset: Point3) !void {
        // Add beacons
        for (scanners.buffer[scanner_index].transformed.buffer[xform_index].beacons.constSlice()) |beacon| {
            const b = Point3{ .x = beacon.x + relative_scanner_offset.x, .y = beacon.y + relative_scanner_offset.y, .z = beacon.z + relative_scanner_offset.z };
            if (!self.beacon_map.contains(b)) {
                //print("Adding {d:4},{d:4},{d:4} to known space from scanner {d}\n", .{ b.x, b.y, b.z, scanners.buffer[scanner_index].id });
                self.beacons.appendAssumeCapacity(b);
                self.beacon_map.putAssumeCapacity(b, true);
            } else {
                //print("Skipping {d:4},{d:4},{d:4} to known space from scanner {d} (already known)\n", .{ b.x, b.y, b.z, scanners.buffer[scanner_index].id });
            }
        }
        //print("Known space now contains {d} beacons\n", .{self.beacons.items.len});
        // Recalculate offsets between known beacons
        self.offsets_map.clearRetainingCapacity();
        const offset_count = @truncate(u32, (self.beacons.items.len * (self.beacons.items.len - 1)) / 2);
        try self.offsets_map.ensureTotalCapacity(offset_count);
        for (self.beacons.items) |p1, i| {
            var j: usize = i + 1;
            while (j < self.beacons.items.len) : (j += 1) {
                const p2 = self.beacons.items[j];
                const offset = Point3{ .x = p2.x - p1.x, .y = p2.y - p1.y, .z = p2.z - p1.z };
                self.offsets_map.putAssumeCapacity(offset, p1);
            }
        }
        // Add scanner position
        self.scanner_positions.appendAssumeCapacity(relative_scanner_offset);
        // remove scanner
        var s = scanners.swapRemove(scanner_index);
        s.deinit();
    }
};

fn mapKnownSpace(input: Input) !KnownSpace {
    var scanners = try std.BoundedArray(Scanner, 39).init(0);
    for (input.scanners.constSlice()) |beacons, id| {
        scanners.appendAssumeCapacity(try Scanner.init(id, beacons, std.testing.allocator));
    }
    var known_space = try KnownSpace.init(std.testing.allocator);
    errdefer known_space.deinit();

    // Add scanner 0 to known space
    try known_space.addScanner(&scanners, 0, IDENTITY_TRANSFORM, Point3{ .x = 0, .y = 0, .z = 0 });

    while (scanners.len > 0) {
        scanner_loop: for (scanners.constSlice()) |scanner, scanner_index| {
            for (scanner.transformed.constSlice()) |transformed, xform_index| {
                var offset_itor = transformed.offsets.keyIterator();
                while (offset_itor.next()) |offset| {
                    if (known_space.pointWithOffset(offset.*)) |kp| {
                        const sp = transformed.offsets.get(offset.*).?;
                        const relative_scanner_pos = Point3{ .x = kp.x - sp.x, .y = kp.y - sp.y, .z = kp.z - sp.z };
                        // possible match; shift transformed.beacons to overlap at this
                        // point and check for matches
                        const matches = known_space.numMatches(transformed.beacons, relative_scanner_pos);
                        if (matches >= 12) {
                            //print("found overlap: scanner {d} transform {d} matches {d} beacons at {d:5},{d:5},{d:5}\n",
                            //    .{ scanner.id, xform_index, matches, relative_scanner_pos.x, relative_scanner_pos.y, relative_scanner_pos.z});
                            known_space.addScanner(&scanners, scanner_index, xform_index, relative_scanner_pos) catch unreachable;
                            break :scanner_loop;
                        }
                    }
                }
            }
        }
    }
    // clean up remaining scanners (though there shouldn't be any!)
    for (scanners.slice()) |*scanner| {
        scanner.deinit();
    }
    return known_space;
}

fn part1(input: Input) i64 {
    var known_space = mapKnownSpace(input) catch unreachable;
    defer known_space.deinit();
    return @intCast(i64, known_space.beacons.items.len);
}

fn part2(input: Input) i64 {
    var known_space = mapKnownSpace(input) catch unreachable;
    defer known_space.deinit();
    var max_distance: i64 = 0;
    for (known_space.scanner_positions.items) |p1, i| {
        var j = i + 1;
        while (j < known_space.scanner_positions.items.len) : (j += 1) {
            const p2 = known_space.scanner_positions.items[j];
            var d = std.math.absInt(p2.x - p1.x) catch unreachable;
            d += std.math.absInt(p2.y - p1.y) catch unreachable;
            d += std.math.absInt(p2.z - p1.z) catch unreachable;
            max_distance = std.math.max(max_distance, d);
        }
    }
    return @intCast(i64, max_distance);
}

const test_data =
    \\--- scanner 0 ---
    \\404,-588,-901
    \\528,-643,409
    \\-838,591,734
    \\390,-675,-793
    \\-537,-823,-458
    \\-485,-357,347
    \\-345,-311,381
    \\-661,-816,-575
    \\-876,649,763
    \\-618,-824,-621
    \\553,345,-567
    \\474,580,667
    \\-447,-329,318
    \\-584,868,-557
    \\544,-627,-890
    \\564,392,-477
    \\455,729,728
    \\-892,524,684
    \\-689,845,-530
    \\423,-701,434
    \\7,-33,-71
    \\630,319,-379
    \\443,580,662
    \\-789,900,-551
    \\459,-707,401
    \\
    \\--- scanner 1 ---
    \\686,422,578
    \\605,423,415
    \\515,917,-361
    \\-336,658,858
    \\95,138,22
    \\-476,619,847
    \\-340,-569,-846
    \\567,-361,727
    \\-460,603,-452
    \\669,-402,600
    \\729,430,532
    \\-500,-761,534
    \\-322,571,750
    \\-466,-666,-811
    \\-429,-592,574
    \\-355,545,-477
    \\703,-491,-529
    \\-328,-685,520
    \\413,935,-424
    \\-391,539,-444
    \\586,-435,557
    \\-364,-763,-893
    \\807,-499,-711
    \\755,-354,-619
    \\553,889,-390
    \\
    \\--- scanner 2 ---
    \\649,640,665
    \\682,-795,504
    \\-784,533,-524
    \\-644,584,-595
    \\-588,-843,648
    \\-30,6,44
    \\-674,560,763
    \\500,723,-460
    \\609,671,-379
    \\-555,-800,653
    \\-675,-892,-343
    \\697,-426,-610
    \\578,704,681
    \\493,664,-388
    \\-671,-858,530
    \\-667,343,800
    \\571,-461,-707
    \\-138,-166,112
    \\-889,563,-600
    \\646,-828,498
    \\640,759,510
    \\-630,509,768
    \\-681,-892,-333
    \\673,-379,-804
    \\-742,-814,-386
    \\577,-820,562
    \\
    \\--- scanner 3 ---
    \\-589,542,597
    \\605,-692,669
    \\-500,565,-823
    \\-660,373,557
    \\-458,-679,-417
    \\-488,449,543
    \\-626,468,-788
    \\338,-750,-386
    \\528,-832,-391
    \\562,-778,733
    \\-938,-730,414
    \\543,643,-506
    \\-524,371,-870
    \\407,773,750
    \\-104,29,83
    \\378,-903,-323
    \\-778,-728,485
    \\426,699,580
    \\-438,-605,-362
    \\-469,-447,-387
    \\509,732,623
    \\647,635,-688
    \\-868,-804,481
    \\614,-800,639
    \\595,780,-596
    \\
    \\--- scanner 4 ---
    \\727,592,562
    \\-293,-554,779
    \\441,611,-461
    \\-714,465,-776
    \\-743,427,-804
    \\-660,-479,-426
    \\832,-632,460
    \\927,-485,-438
    \\408,393,-506
    \\466,436,-512
    \\110,16,151
    \\-258,-428,682
    \\-393,719,612
    \\-211,-452,876
    \\808,-476,-593
    \\-575,615,604
    \\-485,667,467
    \\-680,325,-822
    \\-627,-443,-432
    \\872,-547,-609
    \\833,512,582
    \\807,604,487
    \\839,-516,451
    \\891,-625,532
    \\-652,-548,-490
    \\30,-46,-14
;
const part1_test_solution: ?i64 = 79;
const part1_solution: ?i64 = 467;
const part2_test_solution: ?i64 = 3621;
const part2_solution: ?i64 = 12226;

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
