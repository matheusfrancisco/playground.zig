//! By convention, main.zig is where your main function lives in the case that
//! you are building an executable. If you are making a library, the convention
//! is to delete this file and start with root.zig instead.

pub fn main() !void {
    // Prints to stderr (it's a shortcut based on `std.io.getStdErr()`)
    std.debug.print("All your {s} are belong to us.\n", .{"codebase"});

    // stdout is for the actual output of your application, for example if you
    // are implementing gzip, then only the compressed bytes should be sent to
    // stdout, not any debugging messages.
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    try stdout.print("Run `zig build test` to run the tests.\n", .{});

    // All printing functions take a comptime format string that can
    // contain placeholders for arguments to print. These placeholders
    // are called format specifiers and have the form:
    // `{[argument][specifier]:[fill][alignment][width].[precision]}`
    const float: f64 = 3.1415;
    try stdout.print("float: `{}` `{0d}`, `{0d:0<10.2}` `{0d:0^10.2}` `{0d:0>10.2}`  \n\n", .{float});

    // Integers can formatted as decimal, binary, hex, octal, ASCII, or Unicode.
    const int: u8 = 42;
    try stdout.print("int decimal: {} \n", .{int});
    try stdout.print("int binary: {b} \n", .{int});
    try stdout.print("int octal: {o} \n", .{int});
    try stdout.print("int hex: {x} \n", .{int});
    try stdout.print("int ASCII: {c} \n", .{int}); // max 8 bits
    try stdout.print("int Unicode: {u} \n\n", .{int}); // max 21 bits

    // Works for anything that can be sliced.
    const string = "Hello, world!";
    try stdout.print("string: `{s}` `{0s:_^20}` \n\n", .{string});

    const optional: ?u8 = 42;
    try stdout.print("optional: `{?}` `{?}` \n", .{ optional, @as(?u8, null) });
    // You can further format after the ?.
    try stdout.print("optional: `{?d:0>10}` \n\n", .{optional});

    const error_union: anyerror!u8 = error.WrongNumber;
    try stdout.print("error union: `{!}` `{!}` \n", .{ error_union, @as(anyerror!u8, 13) });
    // You can further format after the !.
    try stdout.print("error union: `{!d:0>10}` \n\n", .{@as(anyerror!u8, 13)});

    const ptr = &float;
    try stdout.print("pointer: `{}` `{0*}` `{}` \n", .{ ptr, ptr.* });

    const S = struct {
        a: bool = true,
        b: f16 = 3.1415,
    };
    const s = S{};
    try stdout.print("`s: {[a]}` `{[b]d:0>10.2}` \n\n", s);
    // Instead of
    try stdout.print("`s: {}` `{d:0>10.2}` \n\n", .{ s.a, s.b });

    // When you need to format a string to use within your program, you
    // can either print to a fixed buffer...
    var buf: [256]u8 = undefined;
    const str = try std.fmt.bufPrint(&buf, "`{[a]}` `{[b]d:0>10.2}` \n\n", s);
    try stdout.print("str: {s}", .{str});

    // ...or use an allocator.
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const str_alloc = try std.fmt.allocPrint(allocator, "`{[a]}` `{[b]d:0>10.2}` \n\n", s);
    defer allocator.free(str_alloc);
    try stdout.print("str_alloc: {s}", .{str_alloc});

    // To print a literal { or } you have to repeat it.
    try stdout.print("curly: {{s}} \n\n", .{});

    try bw.flush(); // don't forget to flush!

    // Same for debug and log output.
    std.debug.print("debug.print: {} \n\n", .{float});
    std.log.debug("{}", .{float});
    std.log.info("{}", .{float});
    std.log.warn("{}", .{float});
    std.log.err("{} \n", .{float});

    // `any` can print anything; great for debugging.
    std.debug.print("any: `{any}` `{any}` `{any}` \n", .{ s, string, float });

    try bw.flush(); // Don't forget to flush!
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // Try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}

test "use other module" {
    try std.testing.expectEqual(@as(i32, 150), lib.add(100, 50));
}

test "fuzz example" {
    const Context = struct {
        fn testOne(context: @This(), input: []const u8) anyerror!void {
            _ = context;
            // Try passing `--fuzz` to `zig build test` and see if it manages to fail this test case!
            try std.testing.expect(!std.mem.eql(u8, "canyoufindme", input));
        }
    };
    try std.testing.fuzz(Context{}, Context.testOne, .{});
}

const std = @import("std");

/// This imports the separate module containing `root.zig`. Take a look in `build.zig` for details.
const lib = @import("formatter_lib");
