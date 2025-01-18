const std = @import("std");

const InputError = error{EmptyInput};
const NumberError = error{ Overflow, InvalidCharacter };

const ParseError = InputError || NumberError;

fn parseNumber(s: []const u8) ParseError!u8 {
    if (s.len == 0) return error.EmptyInput;
    return try std.fmt.parseInt(u8, s, 10);
}

pub fn main() ParseError!void {
    const input = "234";
    var result = parseNumber(input);
    std.debug.print("type of {}\n", .{@TypeOf(result)});
    std.debug.print("result {!}\n", .{result});
    std.debug.print("\n", .{});
    result = parseNumber(input) catch 43;
    std.debug.print("result {!}\n", .{result});
    std.debug.print("\n", .{});

    result = parseNumber(input) catch |err|
        switch (err) {
        error.EmptyInput => blk: {
            std.debug.print("Empty input\n", .{});
            break :blk 34;
        },
        else => |e| {
            std.debug.print("Error: {}\n", .{err});
            return e;
        },
    };

    result = parseNumber("123") catch unreachable;
    result = parseNumber("123") catch |err| return err;
    result = try parseNumber("123");

    if (parseNumber("123")) |n| {
        std.debug.print("Success {}\n", .{n});
    } else |err| {
        std.debug.print("Failure {}\n", .{err});
    }
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
