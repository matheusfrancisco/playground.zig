const builtin = @import("builtin");

pub const WaitResult = enum { changed, timeout };

pub const Backend = enum { auto, fanotify, fsevents, poll };

/// Returns the watcher type for the given backend. Only the selected file is
/// ever analyzed, so e.g. a Linux build never sees the macOS FFI and vice
/// versa. All backends expose the same init/deinit/wait shape.
pub fn WatcherImpl(comptime backend: Backend) type {
    return switch (backend) {
        .auto => switch (builtin.os.tag) {
            .linux => @import("watcher/linux.zig"),
            .macos => @import("watcher/macos.zig"),
            else => @import("watcher/poll.zig"),
        },
        .fanotify => @import("watcher/linux.zig"),
        .fsevents => @import("watcher/macos.zig"),
        .poll => @import("watcher/poll.zig"),
    };
}

pub const Watcher = WatcherImpl(.auto);
