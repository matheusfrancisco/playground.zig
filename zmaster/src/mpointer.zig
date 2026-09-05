const std = @import("std");

//make sure src.len is less than len or esle you wont get
// a null byte at the end of the return string!
extern fn copy(dst: [*]u8, src: [*]const u8, len: usize) [*:0]const u8;

pub fn main(_: std.process.Init) !void {
    var array = [_]u8{ 0, 1, 2 };
    var ptr: [*]u8 = &array;
    //type of
    std.debug.print("ptr: {x} type: {}\n", .{ @intFromPtr(ptr), @TypeOf(ptr) });
    ptr[0] = 9;
    std.debug.print("ptr[1]: {} = array[1] :{}\n", .{ ptr[1], array[1] });

    // pointer arithmetic (+ and -)
    // ptr += 1` moves by `@sizeOf(element type)` bytes behind the scenes
    // 1 byte for `u8`, 4 bytes for `u32`, etc.
    ptr += 1;
    std.debug.print("ptr: {any}\n", .{ptr});
    std.debug.print("ptr[1]: {} = array[1] :{}\n", .{ ptr[1], array[1] });
    ptr -= 1;
    std.debug.print("ptr[1]: {} = array[1] :{}\n", .{ ptr[1], array[1] });

    // many item poitners are similar and interoperable with c
    // pinters. A sentinel (0) terminated many item pointer is
    // interoperable with a C null terminated string.

    const msg = "Hello";
    var buf: [10]u8 = undefined;
    const result = copy(&buf, msg, msg.len);
    std.debug.print("result: {any}\n", .{result});
    std.debug.print("result: {s}\n", .{result});
}
