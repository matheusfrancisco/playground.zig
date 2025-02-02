const std = @import("std");

fn Point(comptime T: type) type {
    return struct {
        x: T,
        y: T = 0,

        const Self = @This();

        pub fn new(x: T, y: T) Self {
            return .{ .x = x, .y = y };
        }

        // Method.
        pub fn distance(self: Self, other: Self) f64 {
            //const diffx = self.x - other.x;
            //const diffy = self.y - other.y;
            const diffx: f64 = switch (@typeInfo(T)) {
                .Int => @floatFromInt(other.x - self.x),
                .Float => other.x - self.x,
                else => @compileError("Unsupported type"),
            };
            const diffy: f64 = switch (@typeInfo(T)) {
                .Int => @floatFromInt(other.y - self.y),
                .Float => other.y - self.y,
                else => @compileError("Unsupported type"),
            };
            // sqrt only work for floating types
            return @sqrt(diffx * diffx + diffy * diffy);
        }
    };
}

pub fn main() !void {
    const P = Point(u32);
    const a_point = P.new(1.0, 2.0);
    const b_point = P.new(3.0, 4.0);

    std.debug.print("Distance: {d:.1}\n", .{a_point.distance(b_point)});

    // comptime expression evaluation
    const condition = false;
    // condition is comptime known,so it is evaluated at comptime.
    if (condition) {
        @compileError("What?");
    }

    //
    // inline for setup.
    const nums = [_]i32{ 2, 4, 6 };
    var sum: usize = 0;

    // an inline for is unrolled
    inline for (nums) |num| {
        // a non inline for cant deal with types.
        const T = switch (num) {
            2 => f32,
            4 => i8,
            6 => bool,
            else => unreachable,
        };

        sum += typeNameLength(T);
    }
    std.debug.print("for sum: {}\n\n", .{sum});

    //inline while setup
    sum = 0;
    // we need a comptime var for the inline while given it is a comptime context
    comptime var i = 0;
    inline while (i < 3) : (i += 1) {
        const T = switch (i) {
            0 => f32,
            1 => i8,
            2 => bool,
            else => unreachable,
        };

        sum += typeNameLength(T);
    }

    std.debug.print("isOptFor A: {}\n", .{isOptFor(A, 1)});
    std.debug.print("isOptSwitch A: {}\n", .{isOptSwitch(A, 1)});
    std.debug.print("isOptSwitch B: {}\n", .{isOptSwitch(B, 22)});

    const a: U = .{ .a = .{ .a = 1, .b = null } };
    const b: U = .{ .b = .{ .a = 1, .b = 2 } };

    std.debug.print("U hasImpl a: {}\n", .{a.hasImpl()});
    std.debug.print("U hasImpl b: {}\n", .{b.hasImpl()});

    std.debug.print("runtime fib(7): {}\n", .{fib(7)});

    const ct_fib = comptime blk: {
        break :blk fib(7);
    };

    std.debug.print("\n", .{});
    std.debug.print("comptime fib(7): {}\n", .{ct_fib});
}

// struct with optional field and impl  decl
const A = struct {
    a: u8,
    b: ?u8,
    fn impl() void {}
};

const B = struct {
    a: u8,
    b: u8,
};

fn typeNameLength(T: type) usize {
    return @typeName(T).len;
}

// Using an inline for
fn isOptFor(comptime T: type, field_index: usize) bool {
    const fields = @typeInfo(T).Struct.fields;

    inline for (fields, 0..) |field, i| {
        if (field_index == i and @typeInfo(field.type) == .Optional) return true;
    }

    return false;
}

// Using a switch with inline prong
fn isOptSwitch(comptime T: type, field_index: usize) bool {
    const fields = @typeInfo(T).Struct.fields;

    return switch (field_index) {
        inline 0...fields.len - 1 => |idx| @typeInfo(fields[idx].type) == .Optional,
        else => false,
    };
}

const U = union(enum) {
    a: A,
    b: B,

    fn hasImpl(self: U) bool {
        return switch (self) {
            inline else => |s| @hasDecl(@TypeOf(s), "impl"),
        };
    }
};

fn fib(n: usize) usize {
    if (n < 2) return n;

    var a: usize = 0;
    var b: usize = 1;
    var i: usize = 0;

    while (i < n) : (i += 1) {
        const tmp = a;
        a = b;
        b = tmp + b;
    }

    return a;
}
