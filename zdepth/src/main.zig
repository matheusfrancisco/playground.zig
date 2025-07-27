const std = @import("std");
const _ = @import("hashmap.zig");
const e = @import("error.zig");

pub fn main() !void {
    try e.errors_test();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    var list = std.ArrayList(u8).init(gpa.allocator());
    defer list.deinit();

    for ("Hello, World") |i| {
        try list.append(i);
    }
    printList(list);

    try list.append('!');
    printList(list);
    _ = list.pop();
    printList(list);
    // use it like a writer if its an u8 list
    const writer = list.writer();
    _ = try writer.print(" Writing to an ArrayList: {} ", .{42});
    printList(list);

    while (list.pop()) |item| {
        std.debug.print("{c}", .{item});
    }
    std.debug.print("\n\n", .{});
    printList(list);

    try list.appendSlice("Appending a slice");
    printList(list);

    //ordered remove. returns removed item.
    //shifts items over o(n)
    _ = list.orderedRemove(5);
    printList(list);

    //swap remove. moves last item into new slot . O(1)
    _ = list.swapRemove(5);
    printList(list);

    // array list  arround a slice of items you can still work with the
    // slice directly
    list.items[3] = 'X';
    printList(list);

    // you can clear the list and obtain the item as an
    // owned slice which you must free
    const slice = try list.toOwnedSlice();
    defer gpa.allocator().free(slice);
    printList(list);

    // you can create a list and allocate the rquired capacity
    // all at once.
    list = try std.ArrayList(u8).initCapacity(gpa.allocator(), 12);
    for ("Hello") |byte| {
        list.appendAssumeCapacity(byte);
    }
    std.debug.print("len: {}, cap: {}\n", .{ list.items.len, list.capacity });
    printList(list);

    //
    const bytes = try gatherBytes(gpa.allocator(), "Hey there!");
    defer gpa.allocator().free(bytes);
    std.debug.print("bytes: {s}\n", .{bytes});
}

fn gatherBytes(allocator: std.mem.Allocator, slice: []const u8) ![]u8 {
    var list = try std.ArrayList(u8).initCapacity(allocator, slice.len);
    defer list.deinit();
    for (slice) |item| {
        list.appendAssumeCapacity(item);
    }
    return list.toOwnedSlice();
}

fn printList(list: std.ArrayList(u8)) void {
    for (list.items) |item| {
        std.debug.print("{c}", .{item});
    }
    std.debug.print("\n", .{});
}

test "main function" {
    try main();
    std.debug.print("Test passed.\n", .{});
}
