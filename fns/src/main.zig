const std = @import("std");

fn add(a: u8, b: u8) u8 {
    return a +| b;
}

fn printU8(n: u8) void {
    std.debug.print("{}", .{n});
}

fn oops() noreturn {
    @panic("oops");
}

fn never() void {
    @compileError("this function should never be called");
}

//pub function can be imported from another namespace
pub fn sub(a: u8, b: u8) u8 {
    return a -| b;
}

//an extern funtion is linked in from an object file
extern "c" fn atan2(y: f64, x: f64) f64;

// an export function is made available for use in the generated object file
export fn mul(a: u8, b: u8) u8 {
    return a * b;
}

//you can force inlining of a function but usually the compiler will do this for you
inline fn answer() u8 {
    return 42;
}

pub fn main() !void {
    const s = add(1, 2);
    std.debug.print("{}", .{s});
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
