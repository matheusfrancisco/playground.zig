const std = @import("std");
const testing = std.testing;

fn add(a: i32, b: i32) i32 {
    return a + b;
}

fn sub(a: i32, b: i32) i32 {
    return a - b;
}

pub fn main() !void {}

test "basic sub functionality" {
    try testing.expectEqual(sub(2, 1), 1);
    try testing.expect(sub(2, 1) == 1);
}

test "basic add functionality" {
    try testing.expectEqual(add(1, 2), 3);
    try testing.expect(add(1, 2) == 3);
}

const Foo = struct {
    a: bool,
    b: u8,
    c: []const usize,
    d: []const u8,

    fn new(flag: bool) Foo {
        return if (flag)
            .{ .a = true, .b = 0, .c = &[_]usize{ 1, 2, 3 }, .d = "Hello" }
        else
            .{
                .a = false,
                .b = 0,
                .c = &[_]usize{ 1, 2, 3 },
                .d = "Bye",
            };
    }

    //you can have test inside struct
    test "inside foo" {
        try testing.expect(true);
    }
};

test "new Foo: true" {
    const foo = Foo.new(true);
    try testing.expect(foo.a);

    try testing.expectEqual(foo.b, 0);
    try testing.expectEqual(foo.c.len, 3);
    try testing.expectEqual(@as(u8, 0), foo.b);

    try testing.expectEqualSlices(usize, &[_]usize{ 1, 2, 3 }, foo.c);
    try testing.expectEqualStrings("Hello", foo.d);
}

const Error = error{Boom};

fn harmless() Error!void {
    return error.Boom;
}

test "harmless" {
    try testing.expectError(error.Boom, harmless());
}
