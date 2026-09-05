const std = @import("std");
const print = std.debug.print;

// Bare union.
const Number = union(enum) {
    float: f64,
    int: i32,
};

const Tag = enum {
    float,
    int,
};

const TaggedNumber = union(Tag) {
    float: f64,
    int: i32,

    pub fn is(self: TaggedNumber, tag: Tag) bool {
        return self == tag;
    }
};

fn tagged() void {
    print("size of taggenumber: {}\n", .{@sizeOf(TaggedNumber)});

    var num: TaggedNumber = .{ .int = 42 };
    print("int: {}\n", .{num.int});
    num = .{ .float = 3.1415 };
    print("float: {}\n", .{num.float});

    // coearce and compares
    if (num == .float) print("num is a float\n", .{});
    num = .{ .int = 12 };

    switch (num) {
        .float => |f| print("num is a float: {}\n", .{f}),
        .int => |i| print("num is an int\n", .{i}),
    }

    print("num is .int?", .{num.is(.int)});
}

pub fn bare() void {
    print("Size of Number: {}\n", .{@sizeOf(Number)});

    var num: Number = .{ .int = 42 };
    print("int: {}\n", .{num.int});

    num = .{ .float = 3.1415 };
    print("float: {}\n", .{num.float});
}
