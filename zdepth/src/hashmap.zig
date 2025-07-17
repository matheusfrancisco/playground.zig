const std = @import("std");

const User = struct {
    allocator: std.mem.Allocator,
    id: usize,
    email: []u8,

    fn init(
        allocator: std.mem.Allocator,
        id: usize,
        email: []const u8,
    ) !User {
        return User{
            .allocator = allocator,
            .id = id,
            .email = try allocator.dupe(u8, email),
        };
    }

    fn deinit(self: *User) void {
        self.allocator.free(self.email);
    }
};

const UserData = struct {
    map: std.AutoHashMap(usize, User),

    fn init(allocator: std.mem.Allocator) UserData {
        return UserData{
            .map = std.AutoHashMap(usize, User).init(allocator),
        };
    }

    fn deinit(self: *UserData) void {
        self.map.deinit();
    }

    fn put(self: *UserData, user: User) !void {
        try self.map.put(user.id, user);
    }

    fn get(self: UserData, id: usize) ?User {
        return self.map.get(id);
    }

    fn del(self: *UserData, id: usize) ?User {
        if (self.map.fetchRemove(id)) |kv| {
            // Optionally free the user data if needed
            return kv.value;
        } else {
            return null;
        }
    }
};

fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var users = UserData.init(allocator);
    defer users.deinit();

    var jeff = try User.init(allocator, 1, "jeff$foo.io");
    defer jeff.deinit();
    try users.put(jeff);

    var jeff2 = try User.init(allocator, 2, "jeff2$foo.io");
    defer jeff2.deinit();
    try users.put(jeff2);

    var jeff3 = try User.init(allocator, 3, "jeff3$foo.io");
    defer jeff3.deinit();
    try users.put(jeff3);

    if (users.get(jeff.id)) |user| {
        std.debug.print("User 1: {s}\n", .{user.email});
    } else {
        std.debug.print("User 1 not found\n", .{});
    }

    if (users.get(jeff2.id)) |user| {
        std.debug.print("User 2: {s}\n", .{user.email});
    } else {
        std.debug.print("User 2 not found\n", .{});
    }

    if (users.get(jeff3.id)) |user| {
        std.debug.print("User 3: {s}\n", .{user.email});
    } else {
        std.debug.print("User 3 not found\n", .{});
    }

    _ = users.del(jeff.id);
    if (users.get(jeff.id)) |user| {
        std.debug.print("User 1: {s}\n", .{user.email});
    } else {
        std.debug.print("User 1 not found\n", .{});
    }
    // count
    std.debug.print("User count: {}\n", .{users.map.count()});
    // check if entry in map
    if (users.map.contains(jeff2.id)) {
        std.debug.print("User 2 is still in the map\n", .{});
    } else {
        std.debug.print("User 2 has been removed from the map\n", .{});
    }

    var entry_iter = users.map.iterator();
    while (entry_iter.next()) |entry| {
        std.debug.print("User ID: {}, Email: {s}\n", .{ entry.key_ptr.*, entry.value_ptr.email });
    }

    const gopr = try users.map.getOrPut(jeff.id);
    if (!gopr.found_existing) gopr.value_ptr.* = jeff;

    if (users.get(jeff.id)) |user| {
        std.debug.print("User 1 after getOrPut: {s}\n", .{user.email});
    } else {
        std.debug.print("User 1 not found after getOrPut\n", .{});
    }

    //if you need a set of unique items
    var primes = std.AutoHashMap(usize, void).init(allocator);
    defer primes.deinit();
    try primes.put(2, {});
    try primes.put(2, {});
    try primes.put(4, {});
    try primes.put(4, {});
    try primes.put(5, {});
    try primes.put(7, {});
    std.debug.print("Unique primes count: {}\n", .{primes.count()});
}

test "UserData operations" {
    try main();
}
