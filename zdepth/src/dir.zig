const std = @import("std");

pub fn main() !void {
    const cwd = std.fs.cwd();
    const dir = try cwd.openDir("./src", .{ .iterate = true });
    var iter = dir.iterate();

    std.debug.print("Listing files in current directory:\n {any}", .{dir});
    while (try iter.next()) |entry| {
        // Print the name of each entry in the directory
        std.debug.print("{s}\n", .{entry.name});
    }
    // make dir
    try cwd.createDir("new_dir", .{});
    try cwd.makePath("new_dir/sub_dir", .{});
    try cwd.deleteDir("new_dir");
}
