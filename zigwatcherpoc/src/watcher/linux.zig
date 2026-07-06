//! fanotify-based watcher backend for Linux.
const std = @import("std");
const WaitResult = @import("../fs_watcher.zig").WaitResult;

const Linux = @This();

fd: std.posix.fd_t,
allocator: std.mem.Allocator,
io: std.Io,
mask: std.os.linux.fanotify.MarkMask,
watch_dir: []const u8,

pub fn init(io: std.Io, allocator: std.mem.Allocator, paths: []const []const u8) !Linux {
    const fan = std.os.linux.fanotify;
    const fd = try std.posix.fanotify_init(.{
        .CLOEXEC = true,
        .NONBLOCK = true,
        .CLASS = .NOTIF,
        .REPORT_NAME = true,
        .REPORT_DIR_FID = true,
        .REPORT_FID = true,
        .REPORT_TARGET_FID = true,
    }, 0);
    errdefer _ = std.os.linux.close(fd);

    const mask: fan.MarkMask = .{
        .CLOSE_WRITE = true,
        .CREATE = true,
        .DELETE = true,
        .DELETE_SELF = true,
        .EVENT_ON_CHILD = true,
        .MOVED_FROM = true,
        .MOVED_TO = true,
        .MOVE_SELF = true,
        .ONDIR = true,
    };

    for (paths) |path| {
        markDirTree(io, fd, mask, path);
    }
    const watch_dir = try allocator.dupe(u8, paths[0]);
    return .{ .fd = fd, .allocator = allocator, .io = io, .mask = mask, .watch_dir = watch_dir };
}

fn markDirTree(io: std.Io, fd: std.posix.fd_t, mask: std.os.linux.fanotify.MarkMask, dir_path: []const u8) void {
    const cwd = std.Io.Dir.cwd();
    std.posix.fanotify_mark(fd, .{ .ADD = true, .ONLYDIR = true }, mask, cwd.handle, dir_path) catch return;
    var dir = cwd.openDir(io, dir_path, .{ .iterate = true }) catch return;
    defer dir.close(io);
    var iter = dir.iterate();
    while (iter.next(io) catch null) |entry| {
        if (entry.kind != .directory) continue;
        var buf: [std.fs.max_path_bytes]u8 = undefined;
        const sub = std.fmt.bufPrint(&buf, "{s}/{s}", .{ dir_path, entry.name }) catch continue;
        markDirTree(io, fd, mask, sub);
    }
}

pub fn deinit(self: *Linux) void {
    self.allocator.free(self.watch_dir);
    _ = std.os.linux.close(self.fd);
}

pub fn wait(self: *Linux, timeout_ms: u32) !WaitResult {
    var pfds: [1]std.posix.pollfd = .{.{
        .fd = self.fd,
        .events = std.posix.POLL.IN,
        .revents = undefined,
    }};
    const n = try std.posix.poll(&pfds, @intCast(timeout_ms));
    if (n == 0) return .timeout;

    var buf: [4096]u8 = undefined;
    const len = std.posix.read(self.fd, &buf) catch |err| switch (err) {
        error.WouldBlock => return .timeout,
        else => return err,
    };
    return self.parseEvents(buf[0..len]);
}

fn parseEvents(self: *Linux, buf: []u8) !WaitResult {
    const fan = std.os.linux.fanotify;
    const M = fan.event_metadata;
    if (buf.len < @sizeOf(M)) return .timeout;

    var meta: [*]align(1) M = @ptrCast(@alignCast(buf.ptr));
    var remaining = buf.len;
    while (remaining >= @sizeOf(M) and meta[0].event_len >= @sizeOf(M) and meta[0].event_len <= remaining) {
        // Auto-mark newly created subdirectories.
        if (meta[0].mask.CREATE and meta[0].mask.ONDIR) {
            const fid: *align(1) fan.event_info_fid = @ptrCast(meta + 1);
            if (fid.hdr.info_type == .DFID_NAME) {
                const file_handle: *align(1) std.os.linux.file_handle = @ptrCast(&fid.handle);
                const name_ptr: [*:0]u8 = @ptrCast((&file_handle.f_handle).ptr + file_handle.handle_bytes);
                const name = std.mem.span(name_ptr);
                var path_buf: [std.fs.max_path_bytes]u8 = undefined;
                if (std.fmt.bufPrint(&path_buf, "{s}/{s}", .{ self.watch_dir, name })) |new_dir| {
                    markDirTree(self.io, self.fd, self.mask, new_dir);
                } else |_| {}
            }
        }
        remaining -= meta[0].event_len;
        meta = @ptrCast(@as([*]u8, @ptrCast(meta)) + meta[0].event_len);
    }
    return .changed;
}
