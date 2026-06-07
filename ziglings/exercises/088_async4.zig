//
// When you have many tasks that don't return individual values,
// use a Group! A Group is an unordered set of tasks that can
// only be awaited or canceled as a whole:
//
//     var group: std.Io.Group = .init;
//     group.async(io, myTask, .{arg1});
//     group.async(io, myTask, .{arg2});
//     try group.await(io);  // blocks until ALL tasks finish
//
// Important rules:
//   * The return type of functions spawned in a group must be
//     coercible to Cancelable!void (i.e. void, or error{Canceled}!void).
//   * Once you call group.async(), you MUST eventually call
//     group.await() or group.cancel() to release resources.
//   * group.cancel() requests cancellation on ALL members,
//     then blocks until they all finish.
//
// Unlike Future, Group tasks don't return values to the caller.
// They're ideal for parallel work that communicates through
// shared state or side effects (like printing).
//
// Fix this program to await all tasks in the group.
//
const std = @import("std");
const print = std.debug.print;

pub fn main(init: std.process.Init) !void {
    const io = init.io;

    var group: std.Io.Group = .init;

    // Spawn 3 tasks in any order. Each sleeps for (id * 1) seconds
    // before printing, so the output order is deterministic.
    group.async(io, doWork, .{ io, 1 });
    group.async(io, doWork, .{ io, 3 });
    group.async(io, doWork, .{ io, 2 });

    // Wait for all tasks to finish.
    // What Group method blocks until all tasks complete?
    try group.???(io);

    print("All tasks finished!\n", .{});
}

fn doWork(io: std.Io, id: u32) void {
    // Sleep ensures deterministic output order.
    io.sleep(std.Io.Duration.fromSeconds(id), .awake) catch return;
    print("Task {} done.\n", .{id});
}
