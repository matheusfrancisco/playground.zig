//
// One of the most important features of the new Io system is
// structured cancellation!
//
// Every Future has a .cancel() method that:
//   1. Requests the task to stop (via error.Canceled at the
//      next "cancellation point")
//   2. BLOCKS until the task actually finishes
//   3. Returns whatever result the task produced
//
// A "cancellation point" is any Io function that can return
// error.Canceled - most commonly io.sleep():
//
//     fn myTask(io: std.Io) u32 {
//         io.sleep(...) catch |err| switch (err) {
//             error.Canceled => return 0,  // error handle
//         };
//         return 42;
//     }
//
// This is fundamentally different from killing a thread -
// the task gets a chance to clean up and return a value!
//
// Remember: both .await() and .cancel() block and return the
// result. The only difference is that .cancel() also sends
// the cancellation request. And both are idempotent — calling
// either one again just returns the same result.
//
// Fix this program: the slow task would take 10 seconds,
// but we cancel it after 1 second. The task should detect
// the cancellation and return early.
//
const std = @import("std");
const print = std.debug.print;

pub fn main(init: std.process.Init) !void {
    const io = init.io;

    var future = io.async(slowTask, .{io});
    defer _ = future.cancel(io); // safety net

    // Wait 1 second, then cancel instead of waiting the full 10.
    io.sleep(std.Io.Duration.fromSeconds(1), .awake) catch {};

    print("Canceling slow task...\n", .{});

    // We don't want to wait 10 seconds!
    // Which Future method requests cancellation AND returns the result?
    const result = future.???(io);

    print("Task returned: {}\n", .{result});
}

fn slowTask(io: std.Io) u32 {
    print("Starting long computation...\n", .{});

    // Try to sleep for 10 seconds - but we might get canceled!
    io.sleep(std.Io.Duration.fromSeconds(10), .awake) catch |err| switch (err) {
        error.Canceled => {
            print("Task was canceled, cleaning up.\n", .{});
            return 0;
        },
    };

    print("Task completed normally.\n", .{});
    return 42;
}
