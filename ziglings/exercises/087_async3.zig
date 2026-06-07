//
// The real power of async shows when you launch MULTIPLE tasks!
//
// With io.async(), you can start several operations, then await
// them all. The Io backend may run them concurrently:
//
//     var f1 = io.async(taskA, .{});
//     defer _ = f1.cancel(io);
//     var f2 = io.async(taskB, .{});
//     defer _ = f2.cancel(io);
//     const a = f1.await(io);
//     const b = f2.await(io);
//
// Notice the defer pattern: each async call is immediately
// followed by a defer cancel. This ensures cleanup even if
// we return early or hit an error before reaching await.
// Since await/cancel are idempotent, the defer is harmless
// if we've already awaited.
//
// Fix this program to launch both tasks and collect their results.
//
const std = @import("std");
const print = std.debug.print;

pub fn main(init: std.process.Init) !void {
    const io = init.io;

    // Launch both tasks asynchronously.
    var future_a = io.async(slowAdd, .{ 1, 2 });
    defer _ = future_a.cancel(io);
    var future_b = ???(slowMul, .{ 6, 7 });
    defer _ = future_b.cancel(io);

    // Await both results.
    const sum = future_a.await(io);
    const product = future_b.await(io);

    print("{} + {} = {}\n", .{ 1, 2, sum });
    print("{} * {} = {}\n", .{ 6, 7, product });
    print("Total: {}\n", .{sum + product});
}

fn slowAdd(a: u32, b: u32) u32 {
    return a + b;
}

fn slowMul(a: u32, b: u32) u32 {
    return a * b;
}
