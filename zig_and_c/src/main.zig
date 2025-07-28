const c = @cImport({
    @cDefine("_NO_CRT_STDIO_INLINE", "1");
    @cInclude("stdio.h");
    @cInclude("math.h");
});

const user = @cImport({
    @cInclude("src/user.h");
});

fn set_user_id(u: *user.User, id: u32) void {
    u.id = id;
}

const std = @import("std");
pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    const x: f64 = 3.0;
    const y: f64 = c.sin(x);
    const z: f64 = c.cos(x);
    const result: f64 = y + z;

    // Print the result using C's printf
    _ = c.printf("sin(%.2f) + cos(%.2f) = %.2f\n", x, x, result);

    const file = c.fopen("foo.txt", "rb");
    if (file == null) {
        @panic("Could not open file!");
    }
    if (c.fclose(file) != 0) {
        return error.CouldNotCloseFileDescriptor;
    }
    const k = c.powf(15.68, 2.32);
    try stdout.print("{d}\n", .{k});
    //The “need-conversion” scenario
    const path: []const u8 = "foo.txt";
    const c_path: [*c]const u8 = @ptrCast(path);
    _ = c.fopen(c_path, "rb");
    //
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var new_user: user.User = undefined;
    new_user.id = 1;
    var user_name = try allocator.alloc(u8, 8);
    defer allocator.free(user_name);
    @memcpy(user_name[0..(user_name.len - 1)], "matheus");
    user_name[user_name.len - 1] = 0;
    new_user.name = user_name.ptr;

    std.debug.print("User ID: {d}, Name: {s}\n", .{ new_user.id, new_user.name });

    set_user_id(&new_user, 2);
    std.debug.print("User ID: {d}, Name: {s}\n", .{ new_user.id, new_user.name });
}
