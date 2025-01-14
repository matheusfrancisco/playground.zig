const std = @import("std");
const u = @import("models/user.zig");

pub fn main() !void {
    const user = u.User{ .power = 9001, .name = "Goku" };
    const user2 = u.User.init("Vegeta", 9000);

    std.debug.print("{s}'s power is  {d} \n", .{
        user.name,
        user.power,
    });
    std.debug.print("{s}'s power is  {d} \n", .{
        user2.name,
        user2.power,
    });
    const a = [5]i32{ 1, 2, 3, 4, 5 };

    // we already saw this .{...} syntax with structs
    // it works with arrays too
    const b: [5]i32 = .{ 1, 2, 3, 4, 5 };

    // use _ to let the compiler infer the length
    const c = [_]i32{ 1, 2, 3, 4, 5 };

    std.debug.print("{d} \n", .{a});
    std.debug.print("{d} \n", .{b});
    std.debug.print("{d} \n", .{c});
    //I'd love to be able to tell you that b is a slice with a length of 3 and a pointer to a. But because we "sliced" our array using values that are known at compile time, i.e. 1 and 4, our length, 3, is also known at compile time. Zig figures all this out and thus b isn't a slice, but rather a pointer to an array of integers with a length of 3. Specifically, its type is *const [3]i32. So this demonstration of a slice is foiled by Zig's cleverness.

    const k = a[1..4];
    std.debug.print("{d} \n", .{k});

    var a1 = [_]i32{ 1, 2, 3, 4, 5 };
    var end: usize = 4;
    end += 1;
    // the line bellow will not compile  because const are not mutable
    // we have to use var instead, but using var is will not make this code compile
    // because slice is a length and a pointer to part of an array.
    // an slice type is alwys derived from what it is slicing.
    // if we want mutate be need to change a to var
    //const b1 = a1[1..end];
    var b1 = a1[1..end];
    b1[0] = 42;
    std.debug.print("{any}", .{@TypeOf(b)});

    //strings
    // zig strings are sequence (i.e array or slices) of byte (u8)
    // strings should only contains uft-8 encoded characters
    // is not enforced and there is really no difference between a  []const u8 that represents
    // ascii or uft-8
    //
    //string literals those you see n the source "Goku" have a compile time known lenght.
    //the compiler knows that "Goku" has length of 4.
    // the type of "Goku" is []const u8
    //
    //
    //string literals are null terminated. that is to say they alwys have \0 aaat the end
    //null terminated strings are important when interacting with c. in memory, goku would
    //look like this: {'G', 'o', 'k', 'u', '\0'}
    //yo might think you can overwrite the null terminator, but you can't. zig will not let you
    //goku has the type: *const[4:0]u8 pointer to an null terminated array of 4 bytes
    //the syntax is more generic: [LENGTH:SENTINEL] where "SENTINEL

    // an array of 3 booleans with false as the sentinel value
    const ab = [3:false]bool{ false, true, false };

    // This line is more advanced, and is not going to get explained!
    std.debug.print("{any}\n", .{std.mem.asBytes(&ab).*});
}

fn add(a: i64, b: i64) i64 {
    // there is no function overloading in zig
    // a += b; will not work
    return a + b;
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
