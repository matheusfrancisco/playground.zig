const std = @import("std");
const builtin = @import("builtin");

pub fn allocator() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    var n: usize = 0;
    if (builtin.target.os.tag == .windows) {
        n = 10;
    } else {
        n = 12;
    }
    const buffer = try allocator.alloc(u64, n);
    const slice = buffer[0..];
    _ = slice;
}
