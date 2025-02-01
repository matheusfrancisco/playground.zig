const std = @import("std");

pub fn main() !void {
    // string literal is a const pointer to a sentinel terminated array
    // the sentinel is 0 also known as null character in c.
    const hello = "Hello, World!";
    std.debug.print("type of {s}: {}", .{ hello, @TypeOf(hello) });

    std.debug.print("\n", .{});

    // a slice of bytes; either const []const u8 or not []u8
    printString("hello, world\n");

    // zig has a miknimal set of escapes
    std.debug.print("escapes \t \" \' \x65 \u{e9} \n \r", .{});

    std.debug.print("\n", .{});

    //indexing into a string produces individual bytes.
    std.debug.print("hello[2]= {}, {0c}, {0u} \n", .{hello[0]});
    var hello_acute: []const u8 = "hello\u{e9}";
    std.debug.print("hello_acute: {s}, len {} \n", .{ hello_acute, hello_acute.len });
    hello_acute = "he\xe9llo";
    std.debug.print("hello_acute: {s}, len {} \n", .{ hello_acute, hello_acute.len });

    const multiline =
        \\ this is a multiline string
        \\ string in zig. this \n
        \\ will note be processed
        \\ as a new line.
    ;

    std.debug.print("multiline: {s}, len {} \n", .{ multiline, multiline.len });
}

fn printString(s: []const u8) void {
    std.debug.print("{s}", .{s});
    // iterate over the slice
    //for (s) |c| {
    //    std.debug.print("{c}", .{c});
    //}
}
