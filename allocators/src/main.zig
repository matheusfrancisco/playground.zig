const std = @import("std");

// return the concatenation of a and b as newly alloacted bytes.
// caller must free returned bytes with allocator
fn catAlloc(allocator: std.mem.Allocator, a: []const u8, b: []const u8) ![]u8 {
    // try to allocate enough space returns a []T on success
    const bytes = try allocator.alloc(u8, a.len + b.len);
    // copy the bytes.
    std.mem.copyForwards(u8, bytes, a);
    std.mem.copyForwards(u8, bytes[a.len..], b);
    // return the allocated slices.
    return bytes;
}

test "fba bytes" {
    // our inputs.
    const hello = "Hello";
    const world = "world";

    // if we know the required memory size in advance, we can create
    var buf: [12]u8 = undefined;
    // and then use that buffer as the backing store for a FixedBufferAllocator.
    var fba = std.heap.FixedBufferAllocator.init(&buf);
    const allocator = fba.allocator();

    const result = try catAlloc(allocator, hello, world);
    defer allocator.free(result);

    try std.testing.expectEqualStrings(hello ++ world, result);
}

// Returns slice with elements of the type of item and length n.
// Caller must free returned slice with allocator.
fn sliceOfAlloc(allocator: std.mem.Allocator, item: anytype, n: usize) ![]@TypeOf(item) {
    const slice = try allocator.alloc(@TypeOf(item), n);
    for (slice) |*e| e.* = item;
    return slice;
}

test "slice of" {
    const Foo = struct {
        a: u8 = 34,
        b: []const u8 = "hello world",
    };

    // inputs
    const foo = Foo{};
    const n = 2;
    // calculate the size of the items in bytes using @sizeOf.
    var buf: [n * @sizeOf(Foo)]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buf);
    const allocator = fba.allocator();

    const result = try sliceOfAlloc(allocator, foo, n);
    defer allocator.free(result);
    try std.testing.expectEqualSlices(Foo, &[_]Foo{ foo, foo }, result);
}

pub fn main() !void {}
