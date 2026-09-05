const std = @import("std");
const mem = std.mem;
const heap = std.heap;
const log = std.log;
const print = std.debug.print;

pub fn Stack(comptime T: type) type {
    return struct {
        allocator: mem.Allocator,
        items: []T = &.{},
        cap: usize = 0,

        const growth_factor = 2;
        const Self = @This();

        pub fn freeAndReset(self: *Self) void {
            if (self.cap == 0) return;
            self.allocator.free(self.items.ptr[0..self.cap]);
            self.items = &.{};
            self.cap = 0;
        }

        pub fn push(self: *Self, item: T) !void {
            if (self.items.len + 1 >= self.cap) try self.grow();
            self.items.ptr[self.items.len] = item;
            self.items.len += 1;
        }

        pub fn pop(self: *Self) ?T {
            if (self.items.len == 0) return null; //error.StackUnderflow;
            self.items.len -= 1;
            return self.items.ptr[self.items.len];
        }

        pub fn format(
            self: Self,
            comptime _: []const u8,
            _: std.fmt.FormatOptions,
            writer: anytype,
        ) !void {
            try writer.writeAll("Stack{ ");

            for (self.items, 0..) |item, i| {
                if (i != 0) try writer.writeAll(", ");
                try writer.print("{}", .{item});
            }

            try writer.writeAll(" }");
        }

        fn grow(self: *Self) !void {
            const old_len = self.items.len;
            const new_cap = if (self.cap == 0) 8 else self.cap * growth_factor;
            self.items = try self.allocator.realloc(self.items.ptr[0..self.cap], new_cap);
            log.debug("Stack grown: old cap = {}, new cap = {}\n", .{ self.cap, new_cap });
            self.cap = new_cap;
            self.items.len = old_len;
        }
    };
}

pub fn run() !void {
    var gpa = heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var stack = Stack(u8){ .allocator = allocator };
    defer stack.freeAndReset();

    for (0..10) |i| {
        try stack.push(@intCast(i));
        print("{}\n", .{stack});
    }

    while (stack.pop()) |item| {
        print("{}\n", .{item});
        print("{}\n", .{stack});
    }

    stack.freeAndReset();

    for (0..20) |i| {
        try stack.push(@intCast(i));
        print("{}\n", .{stack});
    }
}
