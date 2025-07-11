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

const Allocator = std.mem.Allocator;
fn some_memory_leak(allocator: Allocator) !void {
    const buffer = try allocator.alloc(u32, 10);
    _ = buffer;
    // Return without freeing the
    // allocated memory
}

test "memory leak" {
    const allocator = std.testing.allocator;
    try some_memory_leak(allocator);
}

const expectError = std.testing.expectError;
fn alloc_error(allocator: Allocator) !void {
    var ibuffer = try allocator.alloc(u8, 100);
    defer allocator.free(ibuffer);
    ibuffer[0] = 2;
}

test "testing error" {
    var buffer: [10]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();
    try expectError(error.OutOfMemory, alloc_error(allocator));
}
