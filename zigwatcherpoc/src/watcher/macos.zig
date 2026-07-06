//! FSEvents-based watcher backend for macOS. CoreServices is loaded
//! dynamically so no framework linking is needed at build time.
const std = @import("std");
const WaitResult = @import("../fs_watcher.zig").WaitResult;

const MacOs = @This();

core_services: std.DynLib,
rs: ResolvedSymbols,
semaphore: std.c.dispatch.semaphore_t,
dispatch_queue: std.c.dispatch.queue_t,
stream: ?FSEventStreamRef = null,
paths_arena: std.heap.ArenaAllocator,
watch_roots: [][:0]const u8,

pub fn init(_: std.Io, allocator: std.mem.Allocator, paths: []const []const u8) !MacOs {
    var core_services = std.DynLib.open(
        "/System/Library/Frameworks/CoreServices.framework/CoreServices",
    ) catch return error.OpenFrameworkFailed;
    errdefer core_services.close();

    var rs: ResolvedSymbols = undefined;
    inline for (@typeInfo(ResolvedSymbols).@"struct".fields) |f| {
        @field(rs, f.name) = core_services.lookup(f.type, f.name) orelse {
            std.log.err("fs_watcher: missing CoreServices symbol: {s}", .{f.name});
            return error.MissingCoreServicesSymbol;
        };
    }

    const semaphore = std.c.dispatch.semaphore_create(0) orelse return error.SystemResources;
    errdefer semaphore.as_object().release();

    const dispatch_queue = std.c.dispatch.queue_create("watcher-playground", .SERIAL()) orelse return error.SystemResources;
    errdefer dispatch_queue.as_object().release();

    var paths_arena = std.heap.ArenaAllocator.init(allocator);
    errdefer paths_arena.deinit();

    const watch_roots = try paths_arena.allocator().alloc([:0]const u8, paths.len);
    for (paths, watch_roots) |path, *root| {
        root.* = try paths_arena.allocator().dupeZ(u8, path);
    }

    var self: MacOs = .{
        .core_services = core_services,
        .rs = rs,
        .semaphore = semaphore,
        .dispatch_queue = dispatch_queue,
        .stream = null,
        .paths_arena = paths_arena,
        .watch_roots = watch_roots,
    };

    try self.startStream(allocator);
    return self;
}

fn startStream(self: *MacOs, allocator: std.mem.Allocator) !void {
    const rs = self.rs;

    const cf_paths = try allocator.alloc(?CFStringRef, self.watch_roots.len);
    defer allocator.free(cf_paths);
    @memset(cf_paths, null);
    defer for (cf_paths) |o| if (o) |p| rs.CFRelease(p);

    for (self.watch_roots, cf_paths) |path, *cf_path| {
        cf_path.* = rs.CFStringCreateWithCString(null, path, .utf8);
    }

    const cf_paths_array = rs.CFArrayCreate(null, @ptrCast(cf_paths), @intCast(cf_paths.len), null);
    defer rs.CFRelease(cf_paths_array);

    const callback_ctx: EventCallbackCtx = .{ .semaphore = self.semaphore };
    const stream = rs.FSEventStreamCreate(
        null,
        &eventCallback,
        &.{
            .version = 0,
            .info = @constCast(&callback_ctx),
            .retain = null,
            .release = null,
            .copy_description = null,
        },
        cf_paths_array,
        .since_now,
        0.05,
        .{ .watch_root = true, .file_events = true },
    );
    if (stream == null) return error.StreamCreateFailed;
    self.stream = stream;

    rs.FSEventStreamSetDispatchQueue(stream, self.dispatch_queue);
    if (!rs.FSEventStreamStart(stream)) return error.StreamStartFailed;

    // Drain initial events (history_done, root scan, etc.) by waiting
    // in a loop until no event arrives within a 100ms window.
    var attempts: u8 = 0;
    while (attempts < 20) : (attempts += 1) {
        const r = self.semaphore.wait(.time(.NOW, 100 * std.time.ns_per_ms));
        if (r != 0) break;
    }
}

pub fn deinit(self: *MacOs) void {
    if (self.stream) |stream| {
        self.rs.FSEventStreamStop(stream);
        self.rs.FSEventStreamInvalidate(stream);
        self.rs.FSEventStreamRelease(stream);
    }
    self.semaphore.as_object().release();
    self.dispatch_queue.as_object().release();
    self.core_services.close();
    self.paths_arena.deinit();
}

pub fn wait(self: *MacOs, timeout_ms: u32) !WaitResult {
    const timeout_ns: u64 = @as(u64, timeout_ms) * std.time.ns_per_ms;
    const result = self.semaphore.wait(.time(.NOW, @intCast(timeout_ns)));
    return switch (result) {
        0 => .changed,
        else => .timeout,
    };
}

const EventCallbackCtx = struct {
    semaphore: std.c.dispatch.semaphore_t,
};

fn eventCallback(
    _: ConstFSEventStreamRef,
    client_callback_info: ?*anyopaque,
    num_events: usize,
    _: *anyopaque,
    events_flags: [*]const FSEventStreamEventFlags,
    _: [*]const FSEventStreamEventId,
) callconv(.c) void {
    const ctx: *const EventCallbackCtx = @ptrCast(@alignCast(client_callback_info));
    var i: usize = 0;
    while (i < num_events) : (i += 1) {
        if (events_flags[i].history_done) continue;
        _ = std.c.dispatch.semaphore_signal(ctx.semaphore);
        return;
    }
}

const ResolvedSymbols = struct {
    FSEventStreamCreate: *const fn (
        allocator: CFAllocatorRef,
        callback: FSEventStreamCallback,
        ctx: ?*const FSEventStreamContext,
        paths_to_watch: CFArrayRef,
        since_when: FSEventStreamEventId,
        latency: CFTimeInterval,
        flags: FSEventStreamCreateFlags,
    ) callconv(.c) FSEventStreamRef,
    FSEventStreamSetDispatchQueue: *const fn (stream: FSEventStreamRef, queue: std.c.dispatch.queue_t) callconv(.c) void,
    FSEventStreamStart: *const fn (stream: FSEventStreamRef) callconv(.c) bool,
    FSEventStreamStop: *const fn (stream: FSEventStreamRef) callconv(.c) void,
    FSEventStreamInvalidate: *const fn (stream: FSEventStreamRef) callconv(.c) void,
    FSEventStreamRelease: *const fn (stream: FSEventStreamRef) callconv(.c) void,
    CFRelease: *const fn (cf: *const anyopaque) callconv(.c) void,
    CFArrayCreate: *const fn (
        allocator: CFAllocatorRef,
        values: [*]const usize,
        num_values: CFIndex,
        call_backs: ?*const CFArrayCallBacks,
    ) callconv(.c) CFArrayRef,
    CFStringCreateWithCString: *const fn (
        alloc: CFAllocatorRef,
        c_str: [*:0]const u8,
        encoding: CFStringEncoding,
    ) callconv(.c) CFStringRef,
};

const CFAllocatorRef = ?*const opaque {};
const CFArrayRef = *const opaque {};
const CFStringRef = *const opaque {};
const CFTimeInterval = f64;
const CFIndex = i32;
const FSEventStreamRef = ?*opaque {};
const ConstFSEventStreamRef = ?*const opaque {};

const FSEventStreamCallback = *const fn (
    stream: ConstFSEventStreamRef,
    client_callback_info: ?*anyopaque,
    num_events: usize,
    event_paths: *anyopaque,
    event_flags: [*]const FSEventStreamEventFlags,
    event_ids: [*]const FSEventStreamEventId,
) callconv(.c) void;

const FSEventStreamContext = extern struct {
    version: CFIndex,
    info: ?*anyopaque,
    retain: ?*const fn (?*const anyopaque) callconv(.c) *const anyopaque,
    release: ?*const fn (?*const anyopaque) callconv(.c) void,
    copy_description: ?*const fn (?*const anyopaque) callconv(.c) CFStringRef,
};

const FSEventStreamEventId = enum(u64) {
    since_now = std.math.maxInt(u64),
    _,
};

const FSEventStreamCreateFlags = packed struct(u32) {
    use_cf_types: bool = false,
    no_defer: bool = false,
    watch_root: bool = false,
    ignore_self: bool = false,
    file_events: bool = false,
    _: u27 = 0,
};

const FSEventStreamEventFlags = packed struct(u32) {
    must_scan_sub_dirs: bool,
    user_dropped: bool,
    kernel_dropped: bool,
    event_ids_wrapped: bool,
    history_done: bool,
    root_changed: bool,
    mount: bool,
    unmount: bool,
    _: u24 = 0,
};

const CFStringEncoding = enum(u32) {
    invalid_id = std.math.maxInt(u32),
    mac_roman = 0,
    windows_latin_1 = 0x500,
    iso_latin_1 = 0x201,
    next_step_latin = 0xB01,
    ascii = 0x600,
    unicode = 0x100,
    utf8 = 0x8000100,
    non_lossy_ascii = 0xBFF,
};

const CFArrayCallBacks = opaque {};
