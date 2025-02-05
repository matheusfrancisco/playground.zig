const std = @import("std");
const testing = std.testing;

pub fn main() !void {}

fn locals() u8 {
    // all of these are local variables
    // are gone once the function returns
    // they live on the function's stack frame
    const a: u8 = 0;
    const b: u8 = 1;
    const result: u8 = a + b;
    // here copy of result is returned,
    // original result is gone
    return result;
}

fn badIdea() *u8 {
    // x lives on the stack.
    var x: u8 = 0;
    // invalid pointer once the function returns
    // and its stack frame is destroyed
    return &x;
}

fn badIdea2() *u8 {
    const array: [5]u8 = .{ 0, 1, 2, 3, 4 };
    // slices are pointers to the first element
    const s = array[0..2];
    //once the function returns, the array is gone
    //with the array gone the slice is invalid
    return s;
}

// caller must free return bytes
fn goodIdea(allocator: std.mem.Allocator) std.mem.Allocator.Error![]u8 {
    const array: [5]u8 = .{ 0, 1, 2, 3, 4 };
    // s is a []u8 with length 5and a pointer to bytes
    // on the heap.
    const s = try allocator.alloc(u8, 5);
    std.mem.copyForwards(s, &array, 5);
    //this is ok since s points to bytes allocated on the
    //heap and thus outlives the function s stack frame
    return s;
}

const Foo = struct {
    s: []u8,

    fn init(allocator: std.mem.Allocator, s: []const u8) !*Foo {
        // create allocates space on the heap for a single value.
        // it returns a pointer to the allocated space
        const foo_ptr = try allocator.create(Foo);
        errdefer allocator.destroy(foo_ptr);
        // alloc allocates space on the heap for a slice of bytes
        // it return a slice
        foo_ptr.s = try allocator.alloc(u8, s.len);
        std.mem.copyForwards(u8, foo_ptr.s, s);
        return foo_ptr;
    }

    // when a type needs to clean up resources, its convention to
    // to do it in a deinit method
    fn deinit(self: *Foo, allocator: std.mem.Allocator) void {
        allocator.free(self.s);
        // destroy frees the space allocated for the Foo
        allocator.destroy(self);
    }
};

test "Foo" {
    const alloc = std.testing.allocator;
    const foo = try Foo.init(alloc, "hello");
    defer foo.deinit(alloc);

    try testing.expectEqualStrings("hello", foo.s);
}

// tke an output variable
// return number of bytes with written
fn catOutVarLen(a: []const u8, b: []const u8, out: []u8) usize {
    std.debug.assert(out.len >= a.len + b.len);
    std.mem.copyForwards(u8, out, a);
    std.mem.copyForwards(u8, out[a.len..], b);
    return a.len + b.len;
}

test "catOutVarLen" {
    const hello: []const u8 = "hello";
    const world: []const u8 = "world";

    // our output buffer
    var buf: [128]u8 = undefined;
    // write to buffer, get the length
    const len = catOutVarLen(hello, world, &buf);
    try testing.expectEqual(hello.len + world.len, len);
    try testing.expectEqualStrings(hello ++ world, buf[0..len]);
}

fn catOutVarSlice(a: []const u8, b: []const u8, out: []u8) []u8 {
    std.mem.copyForwards(u8, out, a);
    std.mem.copyForwards(u8, out[a.len..], b);
    return out[0 .. a.len + b.len];
}

test "catOutVarSlice" {
    const hello: []const u8 = "hello";
    const world: []const u8 = "world";

    // our output buffer
    var buf: [128]u8 = undefined;
    // write to buffer, get the slice
    const slice = catOutVarSlice(hello, world, &buf);

    try testing.expectEqualStrings(hello ++ world, slice);
}

fn callAloc(allocator: std.mem.Allocator, a: []const u8, b: []const u8) ![]u8 {
    const bytes = try allocator.alloc(u8, a.len + b.len);
    errdefer allocator.free(bytes);

    std.mem.copyForwards(u8, bytes, a);

    // this may fail and you will leak memory
    // try mayFail();

    std.mem.copyForwards(u8, bytes[a.len..], b);
    return bytes;
}

test "callAloc" {
    const hello: []const u8 = "hello";
    const world: []const u8 = "world";
    const alloc = std.testing.allocator;
    const slice = try callAloc(alloc, hello, world);
    try std.testing.expectEqualStrings(hello ++ world, slice);
    defer alloc.free(slice);
}

fn mayFail() !void {
    return error.Boom;
}
