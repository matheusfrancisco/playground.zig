const std = @import("std");
//const List = @import("list.zig").List;
const List = @import("list_arena.zig").List;

pub fn main() !void {
    // our good old gpa
    // var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    // defer std.debug.print("Deallocating gpa: {}\n", .{gpa.deinit()});
    //logs all allocations and frees.
    //var logging_alloc = std.heap.loggingAllocator(gpa.allocator());
    var logging_alloc = std.heap.loggingAllocator(std.heap.page_allocator);
    // for the arena.
    const allocator = logging_alloc.allocator();
    var list = try List(u32).init(allocator, 0);
    defer list.deinit();
    try list.append(1);
    try list.append(2);

    // when itegrating with c, use
    // std.heap.c_allocator
    //
    // when targetting wasm use
    // std.heap.wasm_allocator
    //
}

test "allocation failure" {
    const allocator = std.testing.failing_allocator;
    const list = List(u8).init(allocator, 43);
    try std.testing.expectError(error.OutOfMemory, list);
}

// Use a memory pool when all the objects being allocated have the same type.
// This is more efficient since previously allocated slots can be re-used
// instead of allocating new ones.
test "memory pool: basic" {
    const MemoryPool = std.heap.MemoryPool;

    var pool = MemoryPool(u32).init(std.testing.allocator);
    defer pool.deinit();

    const p1 = try pool.create();
    const p2 = try pool.create();
    const p3 = try pool.create();

    // Assert uniqueness
    try std.testing.expect(p1 != p2);
    try std.testing.expect(p1 != p3);
    try std.testing.expect(p2 != p3);

    pool.destroy(p2);
    const p4 = try pool.create();

    // Assert memory reuse
    try std.testing.expect(p2 == p4);
}
