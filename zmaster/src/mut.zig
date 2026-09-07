const std = @import("std");
const Io = std.Io;
const time = std.time;
const Mutex = Io.Mutex;

const SharedData = struct {
    mutex: Mutex,
    value: i32,
    io: Io,

    pub fn updateValue(self: *SharedData, inc: i32) void {
        try self.mutex.lock(self.io);
        defer self.mutex.unlock(self.io);
        for (0..100) |_| {
            self.value += inc;
        }
    }
};

pub fn run(init: std.process.Init) !void {
    const io = init.io;
    var shared_data = SharedData{
        .mutex = .init,
        .value = 0,
        .io = io,
    };

    // this block is necessary to ensure that all threas are joined before proceeding.
    {
        const t1 = try std.Thread.spawn(.{}, SharedData.updateValue, .{ &shared_data, 1 });
        defer t1.join();
        const t2 = try std.Thread.spawn(.{}, SharedData.updateValue, .{ &shared_data, 2 });
        defer t2.join();
    }
    try std.testing.expectEqual(shared_data.value, 30_000);
}
