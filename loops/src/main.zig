const std = @import("std");

pub fn main() !void {
    var array = [_]u8{ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9 };

    for (array) |element| {
        std.debug.print("{d}\n", .{element});
    }

    array[0] = 42;
    for (array[0..3]) |element| {
        std.debug.print("{d}\n", .{element});
    }

    for (array, 0..) |element, i| {
        std.debug.print("{}: {d}\n", .{ i, element });
    }

    for (array[0..2], array[1..3], array[2..4]) |a, b, c| {
        std.debug.print("{d} {d} {d}\n", .{ a, b, c });
    }

    var sum: usize = 0;
    for (array) |element| {
        if (element == 5) {
            break;
        }
        if (element == 3) {
            continue;
        }
        sum += element;
    }
    std.debug.print("sum: {}\n", .{sum});

    sum = 0;
    outer: for (0..10) |i| {
        for (0..10) |j| {
            if (i == 5) {
                break :outer;
            }
            sum += j;
        }
    }
    std.debug.print("sum: {}\n", .{sum});

    // you can obtain a pointer to the item to modify it
    // the object just not be const and you  must use a pointer to it
    // remember a slice is also a pointer type.
    for (&array) |*e| {
        e.* *= 2;
        std.debug.print("{d}\n", .{e.*});
    }
    std.debug.print("{d}\n", .{array});

    var i: usize = 10;
    while (i > 2) {
        std.debug.print("{d}\n", .{i});
        i -= 1;
    }

    // continue expression
    i = 10;
    while (i > 0) : (i -= 1) {
        i -= 1;
        std.debug.print("{d}\n", .{i});
    }
    std.debug.print("{d}\n", .{i});
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
