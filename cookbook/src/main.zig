const std = @import("std");
const print = std.debug.print;
const mmap = @import("mmapfile.zig").mmap;
const r = @import("readfile.zig");

pub fn main(init: std.process.Init) !void {
    try r.readf(init);
    try mmap(init);
}
