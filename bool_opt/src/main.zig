const std = @import("std");

pub fn main() !void {
    const t: bool = true;
    const f: bool = false;

    std.debug.print("t: {}, f: {}\n", .{ t, f });

    var maybe_byte: ?u8 = null;
    var maybe: ?bool = null;
    std.debug.print("maybe: {?},maybe_byte: {?}\n", .{ maybe_byte, maybe });

    maybe = true;
    maybe_byte = 3;
    std.debug.print("maybe: {?},maybe_byte: {?}\n", .{ maybe_byte, maybe });

    if (t) {
        std.debug.print("t is true\n", .{});
    } else if (f) {
        std.debug.print("f is true\n", .{});
    } else {
        std.debug.print("t and f are false\n", .{});
    }
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
