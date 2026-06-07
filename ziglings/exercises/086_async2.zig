//
// Now that we know how to get an Io value, let's use it for
// asynchronous execution!
//
// io.async() launches a function and returns a Future. The result
// won't necessarily be available until you call .await() on it:
//
//     var future = io.async(someFunction, .{ arg1, arg2 });
//     const result = future.await(io);
//
// The function *may* run immediately or on another thread -
// your code doesn't need to care! That's the beauty of the
// Io abstraction.
//
// IMPORTANT: Every Future MUST be either .await()ed or .cancel()ed.
// Failing to do so leaks resources! A safe pattern is:
//
//     var future = io.async(myFn, .{});
//     defer _ = future.cancel(io);  // safety net
//     // ... later, if we want the result:
//     const result = future.await(io);
//     // (await after cancel is fine — it just returns the result)
//
// Both .await() and .cancel() block until the task finishes and
// return the result. The difference is that .cancel() also
// requests the task to stop at its next cancellation point.
// Calling either one more than once is safe — subsequent calls
// just return a copy of the result.
//
// Fix this program so that computeAnswer runs asynchronously
// and its result is properly awaited.
//
const std = @import("std");
const print = std.debug.print;

pub fn main(init: std.process.Init) !void {
    const io = init.io;

    // Launch computeAnswer asynchronously.
    var future = io.async(computeAnswer, .{ 6, 7 });
    defer _ = future.cancel(io); // always clean up!

    print("Computing... ", .{});

    // Now collect the result. What method on Future gives us
    // the value, blocking until it's ready?
    const answer = future.???(io);

    print("The answer is: {}\n", .{answer});
}

fn computeAnswer(a: u32, b: u32) u32 {
    return a * b;
}
