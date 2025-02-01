pub fn Point(comptime T: type) type {
    return struct {
        x: T,
        y: T = 0,

        const Self = @This();

        pub fn new(x: T, y: T) Self {
            return .{ .x = x, .y = y };
        }

        // Method.
        pub fn distance(self: Self, other: Self) T {
            const diffx = self.x - other.x;
            const diffy = self.y - other.y;
            return @sqrt(diffx * diffx + diffy * diffy);
        }
    };
}
