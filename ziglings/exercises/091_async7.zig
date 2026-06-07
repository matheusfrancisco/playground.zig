//
// When multiple async tasks access shared data, you need
// synchronization! Io provides a Mutex for this:
//
//     var mutex: std.Io.Mutex = .init;
//
//     // In a task:
//     try mutex.lock(io);       // blocks until lock is acquired
//     defer mutex.unlock(io);
//     // ... critical section: safe to modify shared data ...
//
// Without the mutex, concurrent tasks could read and write the
// same memory simultaneously, causing a data race — the result
// would be unpredictable.
//
// mutex.lock() is a cancellation point — it can return
// error.Canceled. There's also tryLock() which returns
// immediately (true if acquired, false if not).
//
// Fix this program so the counter is correctly synchronized.
// Without the fix, the final count would be unpredictable.
// With it, four tasks incrementing 100 times each = 400.
//
const std = @import("std");
const print = std.debug.print;

const SharedState = struct {
    counter: u32 = 0,
    mutex: std.Io.Mutex = .init,
};

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    var state = SharedState{};

    var group: std.Io.Group = .init;

    group.async(io, increment, .{ io, &state, 100 });
    group.async(io, increment, .{ io, &state, 100 });
    group.async(io, increment, .{ io, &state, 100 });
    group.async(io, increment, .{ io, &state, 100 });

    try group.await(io);

    print("Counter: {}\n", .{state.counter});
}

fn increment(io: std.Io, state: *SharedState, times: u32) void {
    for (0..times) |_| {
        // Acquire the lock before modifying shared state.
        // What Mutex method blocks until the lock is acquired?
        state.mutex.??? catch return;
        defer state.mutex.unlock(); // <-- what's missing here?

        // Sleep to give the other tasks a chance to run in the meantime.
        // We do this here only to make nondeterminism more visible.
        io.sleep(std.Io.Duration.fromMilliseconds(1), .awake) catch {};

        // What happens if you neglect to lock the mutex?

        state.counter += 1;
    }
}
