const std = @import("std");

pub const Stringer = struct {
    ptr: *anyopaque,
    toStringFn: *const fn (*anyopaque, []u8) anyerror![]u8,

    pub fn toString(self: Stringer, buf: []u8) anyerror![]u8 {
        return self.toStringFn(self.ptr, buf);
    }
};

/// User implementation.
pub const User = struct {
    name: []const u8,
    email: []const u8,

    pub fn toString(ptr: *anyopaque, buf: []u8) ![]u8 {
        const self: *User = @ptrCast(@alignCast(ptr));
        return std.fmt.bufPrint(buf, "User(name: {[name]s}, email: {[email]s})", self.*);
    }

    pub fn stringer(self: *User) Stringer {
        return .{
            .ptr = self,
            .toStringFn = User.toString,
        };
    }
};

/// Animal implementation.
pub const Animal = struct {
    name: []const u8,
    greeting: []const u8,

    pub fn toString(ptr: *anyopaque, buf: []u8) ![]u8 {
        const self: *Animal = @ptrCast(@alignCast(ptr));
        return std.fmt.bufPrint(buf, "{[name]s} says {[greeting]s}", self.*);
    }

    pub fn stringer(self: *Animal) Stringer {
        return .{
            .ptr = self,
            .toStringFn = Animal.toString,
        };
    }
};
