//! Portable polling watcher backend. No OS notification API: each wait()
//! sleeps for the timeout, rescans the tree, and compares a snapshot hash
//! of every entry's path, size, and mtime. The per-entry hashes are
//! combined with wrapping addition so the result is independent of
//! directory iteration order.
const std = @import("std");
const WaitResult = @import("../fs_watcher.zig").WaitResult;

const Poll = @This();

io: std.Io,
arena: std.heap.ArenaAllocator,
roots: [][]const u8,
snapshot: u64,

pub fn init(io: std.Io, allocator: std.mem.Allocator, paths: []const []const u8) !Poll {
    var arena = std.heap.ArenaAllocator.init(allocator);
    errdefer arena.deinit();

    const roots = try arena.allocator().alloc([]const u8, paths.len);
    for (paths, roots) |path, *root| {
        root.* = try arena.allocator().dupe(u8, path);
    }

    var self: Poll = .{ .io = io, .arena = arena, .roots = roots, .snapshot = 0 };
    self.snapshot = self.scan();
    return self;
}

pub fn deinit(self: *Poll) void {
    self.arena.deinit();
}

pub fn wait(self: *Poll, timeout_ms: u32) !WaitResult {
    try std.Io.sleep(self.io, .fromMilliseconds(timeout_ms), .awake);
    const snapshot = self.scan();
    if (snapshot != self.snapshot) {
        self.snapshot = snapshot;
        return .changed;
    }
    return .timeout;
}

fn scan(self: *Poll) u64 {
    var sum: u64 = 0;
    for (self.roots) |root| {
        self.scanDir(root, &sum);
    }
    return sum;
}

fn scanDir(self: *Poll, dir_path: []const u8, sum: *u64) void {
    const cwd = std.Io.Dir.cwd();
    var dir = cwd.openDir(self.io, dir_path, .{ .iterate = true }) catch return;
    defer dir.close(self.io);
    var iter = dir.iterate();
    while (iter.next(self.io) catch null) |entry| {
        var buf: [std.fs.max_path_bytes]u8 = undefined;
        const path = std.fmt.bufPrint(&buf, "{s}/{s}", .{ dir_path, entry.name }) catch continue;
        if (entry.kind == .directory) {
            // Hash the directory's existence too, so creating or deleting
            // an empty directory still changes the snapshot.
            sum.* +%= std.hash.Wyhash.hash(0, path);
            self.scanDir(path, sum);
        } else {
            const stat = dir.statFile(self.io, entry.name, .{}) catch continue;
            var hasher = std.hash.Wyhash.init(0);
            hasher.update(path);
            hasher.update(std.mem.asBytes(&stat.size));
            hasher.update(std.mem.asBytes(&stat.mtime.nanoseconds));
            sum.* +%= hasher.final();
        }
    }
}
