const std = @import("std");
const User = struct {
    power: i32,
    id: []const u8,

    fn levelUp(self: *User) void {
        self.power += 1;
    }
};

pub fn pointers() !void {
    var user = User{ .power = 9000, .id = "Goku" };

    std.debug.print("{*}\n{*}\n{*}\n", .{ &user, &user.id, &user.power });

    // no longer needed
    // user.power += 1;
    levelUp(&user);

    std.debug.print("user {s} has no power of {d}\n", .{ user.id, user.power });
}

fn levelUp(user: *User) void {
    user.power += 1;
}
