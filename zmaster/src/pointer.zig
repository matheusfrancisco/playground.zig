const std = @import("std");

pub fn p() !void {
    var array = [_]u8{ 1, 2, 3, 4, 5 };
    // a pointer to a mutable array
    const ptr = &array;
    std.debug.print("\nstype of ptr: {}\n", .{@TypeOf(ptr)});

    //normal dereference syntex
    ptr.*[0] = 9;
    std.debug.print("ptr: {x} = {any}\n", .{ @intFromPtr(ptr), ptr.* });

    // convenient indexing syntax
    ptr[1] = 10;
    std.debug.print("ptr[1]: {x} = {any}\n", .{ @intFromPtr(ptr), ptr.* });

    // single item pointer to array element;
    const item_ptr = &array[0];
    item_ptr.* = 11;

    //type of item_ptr
    std.debug.print("\ntype of item_ptr: {}\n", .{@TypeOf(item_ptr)});
    std.debug.print("item_ptr.*: {} , ptr[0]: {}, array[0]: {}\n", .{ item_ptr.*, ptr[0], array[0] });

    // the addresses are the same, but the types differ.
    std.debug.print("item_ptr: {} , ptr: {*}, &array: {*}\n", .{ item_ptr, ptr, &array });

    // a string literal
    const hello = "Héllo";
    std.debug.print("\ntype of hello: {}\n", .{@TypeOf(hello)});
    std.debug.print("hello[0] = {0} {0c}\n", .{hello[0]});
    std.debug.print("hello.*[0]: {0} {0c}\n", .{hello.*[0]});
    std.debug.print("hello[1]: {0} {0c}\n", .{hello[1]});
}
