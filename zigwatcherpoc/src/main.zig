const std = @import("std");
const fs_watcher = @import("zigwatcherpoc");
const build_options = @import("build_options");

// Translate the build flag's generated enum into the library's own Backend
// enum. The switch is exhaustive, so if the two enums drift apart this fails
// to compile instead of silently misbehaving.
const backend: fs_watcher.Backend = switch (build_options.watch_backend) {
    .auto => .auto,
    .fanotify => .fanotify,
    .fsevents => .fsevents,
    .poll => .poll,
};
const Watcher = fs_watcher.WatcherImpl(backend);

pub fn main(init: std.process.Init) !u8 {
    const io = init.io;

    var arena = std.heap.ArenaAllocator.init(init.gpa);
    defer arena.deinit();

    const args = try init.minimal.args.toSlice(arena.allocator());
    const watch_path = if (args.len > 1) args[1] else ".";
    std.debug.print("watching: {s} (backend: {s})\n", .{ watch_path, @tagName(backend) });
    std.debug.print("press Ctrl+C to stop\n", .{});

    var watcher = try Watcher.init(io, init.gpa, &.{watch_path});
    defer watcher.deinit();

    const watcher_thread = try std.Thread.spawn(.{}, watchLoop, .{&watcher});
    const server_thread = try std.Thread.spawn(.{}, serveLoop, .{io});

    watcher_thread.join();
    server_thread.join();

    std.debug.print("\nstopped cleanly\n", .{});
    return 0;
}

fn watchLoop(watcher: *Watcher) void {
    var change_count: usize = 0;
    while (true) {
        const result = watcher.wait(100) catch |err| {
            std.debug.print("watch error: {s}\n", .{@errorName(err)});
            return;
        };
        if (result == .changed) {
            change_count += 1;
            std.debug.print("[watcher] change #{d} detected\n", .{change_count});
        }
    }
}

fn serveLoop(io: std.Io) void {
    var request_count: usize = 0;
    while (true) {
        std.Io.sleep(io, .fromMilliseconds(500), .awake) catch return;
        request_count += 1;
        std.debug.print("[server] fake request #{d} served\n", .{request_count});
    }
}
