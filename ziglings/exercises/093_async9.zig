//
// We've been using io.async() to launch tasks. But there's a
// stronger variant: io.concurrent().
//
// The difference:
//
//   io.async():
//     * The function MAY run on a separate unit of concurrency,
//       or it may run immediately on the caller (synchronously).
//     * Never fails — if no concurrency is available, it just
//       runs the function right away.
//     * More portable, works with all Io backends.
//
//   io.concurrent():
//     * GUARANTEES a separate unit of concurrency.
//     * Can fail with error.ConcurrencyUnavailable if resources
//       are exhausted or the backend doesn't support it.
//     * Use when you NEED the task to run independently of the
//       caller.
//
// What is a "unit of concurrency"? That depends on the backend!
// The Threaded backend uses OS threads. But the Evented backends
// (Uring, Kqueue, Dispatch) use M:N green threads / fibers,
// which can provide concurrency even on a SINGLE OS thread.
// Your code doesn't need to know the difference.
//
// Because concurrent() can fail, you must handle the error:
//
//     var future = try io.concurrent(myFn, .{args});
//     defer _ = future.cancel(io);
//     const result = future.await(io);
//
// Let's try a slightly simplified example from signal processing:
// Suppose we're looking for the beginning of a signal above the noise
// level. To do this, we compare each entry from beginning to end with
// the threshold. To speed things up a bit, we split the signal into
// two halves and have two parallel workers search for them.
// Who finds the beginning first "wins" and thus ends the other one.
//
// As I said, this is a simplified explanation,
// but in practice it's done more or less like this.
//
const std = @import("std");
const Io = std.Io;
const print = std.debug.print;

const SearchResult = struct {
    found: bool,
    worker_id: u8 = 0,
    index: usize = 0,
};

pub fn main(init: std.process.Init) !void {
    const io = init.io;

    const data = [_]u32{ 10, 23, 45, 67, 12, 69, 3, 54, 69, 42, 68, 56, 71, 79, 79, 75, 70, 77 };
    const threshold = 70;
    const mid = data.len / 2;

    // A queue with space for one result.
    var buf: [1]SearchResult = undefined;
    var queue = Io.Queue(SearchResult).init(&buf);

    // Launch two workers, each searching half the array.
    // Remember, we want them to be guaranteed separate units of concurrency.
    var f1 = ???(searchThreshold, .{ io, data[0..mid], threshold, 0, 0, &queue });
    defer _ = f1.cancel(io);

    var f2 = ???(searchThreshold, .{ io, data[mid..], threshold, mid, 1, &queue });
    defer _ = f2.cancel(io);

    // Wait for the first result.
    const result = try queue.getOne(io);

    if (result.found)
        print("Worker {} found signal start over threshold at index {}!\n", .{ result.worker_id, result.index });
}

fn searchThreshold(
    io: Io,
    slice: []const u32,
    threshold: u32,
    base_offset: usize,
    worker_id: u8,
    queue: *Io.Queue(SearchResult),
) void {
    for (slice, 0..) |val, i| {
        // This pause is necessary so that the process can be canceled
        // if another one has already finished. Without this pause,
        // all workers would continue until the end.
        io.sleep(Io.Duration.fromMilliseconds(1), .awake) catch return;

        // To test this, you can uncomment this to view the work of the workers
        // and then comment out the pause.
        // print("id: {} - val: {}\n", .{ worker_id, val });

        if (val >= threshold) {
            queue.putOne(io, .{
                .found = true,
                .worker_id = worker_id,
                .index = base_offset + i,
            }) catch return;
            return;
        }
    }

    // Nothing found
    queue.putOneUncancelable(io, .{ .found = false }) catch return;
}
