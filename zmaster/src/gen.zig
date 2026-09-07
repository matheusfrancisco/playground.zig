const std = @import("std");

pub fn Point(comptime T: type) type {
    return struct {
        x: T,
        y: T,
        const Self = @This();

        pub fn new(x: T, y: T) Self {
            return Self{ .x = x, .y = y };
        }

        pub fn distance(self: Self, other: Self) T {
            const diffx = other.x - self.x;
            const diffy = other.y - self.y;
            return @sqrt(diffx * diffx + diffy * diffy);
        }
    };
}
