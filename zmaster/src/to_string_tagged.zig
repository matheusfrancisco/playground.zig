const std = @import("std");

pub const Stringer = union(enum) {
    user: User,
    animal: Animal,

    pub fn toString(self: Stringer, buf: []u8) ![]u8 {
        return switch (self) {
            inline else => |s| s.toString(buf),
        };
    }
};

/// User implementation.
pub const User = struct {
    name: []const u8,
    email: []const u8,

    pub fn toString(self: User, buf: []u8) ![]u8 {
        return std.fmt.bufPrint(buf, "User(name: {[name]s}, email: {[email]s})", self);
    }
};

/// Animal implementation.
pub const Animal = struct {
    name: []const u8,
    greeting: []const u8,

    pub fn toString(self: Animal, buf: []u8) ![]u8 {
        return std.fmt.bufPrint(buf, "{[name]s} says {[greeting]s}", self);
    }
};
