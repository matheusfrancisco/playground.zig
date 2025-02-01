const std = @import("std");

const stdout = std.io.getStdOut().writer();
pub fn main() !void {
    try stdout.print("Run `zig build test` to run the tests.\n", .{});

    const num: u8 = 100;

    const ns = [4]u8{ 1, 2, 3, 4 };
    const ls = [_]u8{ 1, 2, 3, 4 };

    std.debug.print("ns: {d}\n", .{ns});
    //this will repeats the array
    const a = ns ** 2;
    std.debug.print("a: {d}\n", .{a});

    _ = ls;

    try stdout.print("num: {d}\n", .{num});
    try stdout.print("{d}\n", .{ns[2]});

    const ar = [4]u8{ 1, 2, 3, 4 };
    const sl = ar[0..3];
    const sl1 = ar[0..ar.len];
    _ = sl;

    const sl2 = ar[0..];
    std.debug.print("*% result: {d}\n", .{sl1});
    std.debug.print("*% result: {d}\n", .{sl2});
    //the array can be comptime
    const x = 5;
    var aa = [x]u8{ 1, 2, 3, 4, 5 };
    aa[0] = 38;
    std.debug.print("aa: {d}\n", .{aa});
    const a2: [2][2]u8 = [_][2]u8{
        .{ 1, 2 },
        .{ 3, 4 },
    };
    std.debug.print("a2: {d}\n", .{a2});
    std.debug.print("a2[1][1]: {d}\n", .{a2[1][1]});

    const a8: [2:0]u8 = [2:0]u8{ 1, 2 };
    std.debug.print("a8: {d}\n", .{
        a8,
    });

    // blocks and scopes  are created in zig a pair of curly braces
    var y: i32 = 123;
    const xk = add_one: {
        y += 1;
        break :add_one y;
    };

    if (xk == 123 and y == 124) {
        try stdout.print("hey\n", .{});
    }
}

pub fn strings() !void {
    // strings
    const bytes = [_]u8{ 0x48, 0x65, 0x6C, 0x6C, 0x6F };
    try stdout.print("{s}\n", .{bytes});
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
