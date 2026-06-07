//
// Sometimes you want to race multiple tasks and act on whichever
// finishes first. That's what Select is for!
//
// Select is like a Group, but lets you receive individual results
// as tasks complete — one at a time:
//
//     const Race = std.Io.Select(union(enum) {
//         fast: u32,
//         slow: u32,
//     });
//
//     var buffer: [2]Race.Union = undefined;
//     var sel = Race.init(io, &buffer);
//
//     sel.async(.fast, fastFn, .{io});
//     sel.async(.slow, slowFn, .{io});
//
//     const winner = try sel.await();  // returns first completed
//     switch (winner) {
//         .fast => |val| ...,
//         .slow => |val| ...,
//     }
//     sel.cancelDiscard();  // cancel remaining, discard results
//
// As with all async primitives: tasks spawned in a Select MUST
// be cleaned up. Use sel.cancel() to get remaining results one
// by one (for resource cleanup), or sel.cancelDiscard() if you
// don't need them.
//
// The buffer must be large enough for all tasks that might
// complete before you call cancelDiscard().
//
// Fix this program to receive the winner of the race.
//
const std = @import("std");
const print = std.debug.print;

const RaceResult = std.Io.Select(union(enum) {
    hare: []const u8,
    tortoise: []const u8,
});

pub fn main(init: std.process.Init) !void {
    const io = init.io;

    var buffer: [2]RaceResult.Union = undefined;
    var sel = RaceResult.init(io, &buffer);

    sel.async(.hare, runHare, .{io});
    sel.async(.tortoise, runTortoise, .{io});

    // Wait for the first finisher.
    // What Select method returns the first completed result?
    const winner = try sel.???();

    switch (winner) {
        .hare => |msg| print("Hare: {s}\n", .{msg}),
        .tortoise => |msg| print("Tortoise: {s}\n", .{msg}),
    }

    // Clean up the loser — we don't need their result.
    sel.cancelDiscard();
}

fn runHare(io: std.Io) []const u8 {
    // The hare is fast — only 1 second!
    io.sleep(std.Io.Duration.fromSeconds(1), .awake) catch return "I got canceled!";
    return "I'm fast!";
}

fn runTortoise(io: std.Io) []const u8 {
    // The tortoise is slow — 10 seconds.
    io.sleep(std.Io.Duration.fromSeconds(10), .awake) catch return "I got canceled!";
    return "Slow and steady...";
}
