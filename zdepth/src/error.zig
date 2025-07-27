const std = @import("std");

pub fn errors_test() !void {
    const stdout = std.io.getStdOut().writer();
    try stdout.print("This is a test for error handling in Zig.\n", .{});
}

const A = error{
    ConnectionTimeoutError,
    DatabaseNotFound,
    OutOfMemory,
    InvalidToken,
};

const B = error{
    OutOfMemory,
};

fn cast(err: B) A {
    return err;
}

//fn create_user(db: Database, allocator: Allocator) !User {
//    const user = try allocator.create(User);
//    errdefer allocator.destroy(user);
//
//    // Register new user in the Database.
//    _ = try db.register_user(user);
//    return user;
//}

test "coerce error value" {
    const error_value = cast(B.OutOfMemory);
    try std.testing.expect(error_value == A.OutOfMemory);
}
