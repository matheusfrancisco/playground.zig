//
// In exercise 089, we learned that cancellation happens at
// "cancellation points" — any Io function that can return
// error.Canceled.
//
// But sometimes a task has a critical section that MUST NOT
// be interrupted — for example, writing a consistent state
// to disk, or completing a transaction.
//
// Io provides CancelProtection for this:
//
//     const old = io.swapCancelProtection(.blocked);
//     defer _ = io.swapCancelProtection(old);

//     // In this block, NO Io function will return error.Canceled.
//     // The cancel request is held until protection is restored.
//
// There are two states:
//   .unblocked — normal: cancellation points can fire (default)
//   .blocked   — protected: error.Canceled is never returned
//
// There's also io.checkCancel() — a pure cancellation point
// that does nothing except return error.Canceled if a cancel
// request is pending. Useful in long CPU-bound loops.
//
// And io.recancel() — re-arms a consumed cancel request so
// the NEXT cancellation point will fire again.
//
// Fix this program so the critical section completes even
// when the task is canceled.
//
const std = @import("std");
const print = std.debug.print;

pub fn main(init: std.process.Init) !void {
    const io = init.io;

    var future = io.async(importantTask, .{io});
    defer _ = future.cancel(io);

    // Give the task time to start and enter its critical section.
    io.sleep(std.Io.Duration.fromMilliseconds(200), .awake) catch {};

    // Cancel while the task is in its protected section.
    const result = future.cancel(io);
    print("Task result: {s}\n", .{result});
}

fn importantTask(io: std.Io) []const u8 {
    print("Starting critical section...\n", .{});

    // Protect this section from cancellation.
    // What method swaps the cancel protection state?
    const old = io.???(.blocked);
    defer _ = io.???(old);

    // This sleep will NOT return error.Canceled even though
    // we get canceled during it — protection is active!
    io.sleep(std.Io.Duration.fromMilliseconds(300), .awake) catch |err| switch (err) {
        error.Canceled => {
            // This should never happen while protected!
            return "ERROR: canceled during critical section!";
        },
    };

    print("Critical section completed safely.\n", .{});
    return "All data saved.";
}
