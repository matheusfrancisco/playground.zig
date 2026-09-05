const std = @import("std");

const Slice = struct {
    ptr: [*]const u8,
    len: usize,
};

fn display4(items: []const u8) void {
    for (0..items.len) |i| std.debug.print("items[{}]: {d}\n", .{ i, items[i] });
}
fn display3(items: Slice) void {
    for (0..items.len) |i| std.debug.print("items[{}]: {d}\n", .{ i, items.ptr[i] });
}
fn display2(items: [*]const u8, len: usize) void {
    for (0..len) |i| std.debug.print("items[{}]: {d}\n", .{ i, items[i] });
}
fn display(items: [3]u8) void {
    for (0..items.len) |i| std.debug.print("items[{}]: {d}\n", .{ i, items[i] });
}
pub fn main(_: std.process.Init) !void {
    const array = [_]u8{ 1, 2, 3, 4 };
    //display(array);
    //display2(&array, array.len);
    display3(.{ .ptr = &array, .len = array.len });
    std.debug.print("---------------------\n", .{});
    display4(&array);

    std.debug.print("---------------------\n", .{});
    const array2 = [_]u8{ 1, 2, 3, 4, 5 };
    display4(&array2);

    const slice: []const u8 = &array2; // coerce
    display4(slice);
    const slice2: []const u8 = array[0..2]; // coerce
    std.debug.print("---------------------\n", .{});
    display4(slice2);
    const slice3 = array[0..2]; // coerce
    //type
    std.debug.print("type of the slice: {}", .{@TypeOf(slice3)});
    //var start: usize = 0;
    //var len: usize = 4;
    //var slice4 = array[start ..][0..len] //

    const array4 = [_]u8{ 0, 1, 2, 3, 4, 0 };
    const s_slice: [:0]const u8 = array4[0 .. array4.len - 1 :0]; // coerc
    // type

    std.debug.print("type of the s_slice: {}", .{@TypeOf(s_slice)});
}
