const std = @import("std");

pub fn main() !void {
    const t: bool = true;
    const f: bool = false;

    std.debug.print("t: {}, f: {}\n", .{ t, f });
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
