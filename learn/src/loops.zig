const std = @import("std");

pub fn runner(src: []const u8) !void {
    var escape_count: usize = 0;
    var i: usize = 0;
    while (i < src.len) {
        // backslash is used as an escape character, thus we need to escape it...
        // with a backslash.
        if (src[i] == '\\') {
            i += 2;
            escape_count += 1;
        } else {
            i += 1;
        }
    }
    std.debug.print("escape count: {d}\n", .{escape_count});

    i = 0;
    escape_count = 0;
    //                    this will excute when the contition is false
    while (i < src.len) : (i += 1) {
        if (src[i] == '\\') {
            i += 1;
            escape_count += 1;
        }
    }
    std.debug.print("escape count: {d}\n", .{escape_count});
    loop();
}

fn loop() void {
    outer: for (1..10) |i| {
        for (i..10) |j| {
            if (i * j > (i + i + j + j)) continue :outer;
            std.debug.print("{d} + {d} >= {d} * {d}\n", .{ i + i, j + j, i, j });
        }
    }
}
