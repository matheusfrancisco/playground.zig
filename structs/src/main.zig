const std = @import("std");
const Point = @import("point.zig").Point;
//const Point = struct {
//    x: f32,
//    y: f32 = 0,
//
//    //namespace function
//    fn new(x: f32, y: f32) Point {
//        return .{ .x = x, .y = y };
//    }
//
//    // Method
//    fn distance(self: Point, other: Point) f32 {
//        const diffx = self.x - other.x;
//        const diffy = self.y - other.y;
//        return @sqrt(diffx * diffx + diffy * diffy);
//    }
//};

const Namespace = struct {
    const pi: f64 = 3.14159265358979323846;
    var count: usize = 0;
};

pub fn main() !void {
    const a_point: Point(f32) = .{ .x = 1.0, .y = 2.0 };
    const b_point = Point(f32).new(3.0, 4.0);

    std.debug.print("Distance: {d:.2}\n", .{a_point.distance(b_point)});

    std.debug.print("distance: {d:.1} \n", .{Point(f32).distance(a_point, b_point)});

    // a namespaces
    std.debug.print("size of point: {}\n", .{@sizeOf(Point(f32))});
    std.debug.print("size of namespace: {}\n", .{@sizeOf(Namespace)});

    var c_point = Point(f32).new(5.0, 6.0);

    setYBasedOnX(&c_point.x, 23.0);
    std.debug.print("c_point.y: {d:.1}\n", .{c_point.y});

    // take the adress of a struct
    const cptr = &c_point;
    //we can access the fields of the struct using the pointer
    std.debug.print("cptr.y: {d:.1}, cptr.*.y: {d:.1}\n", .{ cptr.y, cptr.*.y });
}

// struct field order is determined by the compiler
fn setYBasedOnX(x: *f32, y: f32) void {
    const point: *Point(f32) = @fieldParentPtr("x", x);
    point.y = y;
}
