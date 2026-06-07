//
// Tasks often need to communicate! Io provides Queue for this —
// a bounded, thread-safe channel for passing data between tasks:
//
//     var backing: [16]u32 = undefined;
//     var queue: std.Io.Queue(u32) = .init(&backing);
//
//     // Producer task:
//     try queue.putOne(io, value);    // blocks if queue is full
//
//     // Consumer task:
//     const val = try queue.getOne(io);  // blocks if queue is empty
//
// When the producer is done, it calls queue.close(io) to signal
// that no more data is coming. After that, getOne() will return
// error.Closed once the queue is drained.
//
// This is the classic producer/consumer pattern — one task
// generates work, another processes it, and the queue handles
// all the synchronization automatically.
//
// Fix this program: the producer sends numbers 1..10, the
// consumer sums them up. The expected sum is 55.
//
const std = @import("std");
const print = std.debug.print;

pub fn main(init: std.process.Init) !void {
    const io = init.io;

    var backing: [4]u32 = undefined;
    var queue: std.Io.Queue(u32) = .init(&backing);

    var group: std.Io.Group = .init;

    group.async(io, producer, .{ io, &queue });
    group.async(io, consumer, .{ io, &queue });

    try group.await(io);
}

fn producer(io: std.Io, queue: *std.Io.Queue(u32)) void {
    // Send numbers 1 through 10 into the queue.
    for (1..11) |i| {
        // What Queue method sends a single element, blocking if full?
        queue.???(io, @intCast(i)) catch return;
    }
    // Signal that we're done sending.
    queue.close(io);
}

fn consumer(io: std.Io, queue: *std.Io.Queue(u32)) void {
    var sum: u32 = 0;
    while (true) {
        const value = queue.getOne(io) catch |err| switch (err) {
            error.Closed => break,
            error.Canceled => return,
        };
        sum += value;
    }
    print("Sum of 1..10 = {}\n", .{sum});
}
