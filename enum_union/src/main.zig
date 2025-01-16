const std = @import("std");

const Color = enum {
    red,
    green,
    blue,

    fn isRed(this: Color) bool {
        return this == Color.red;
    }
};

const Number = union { int: u8, float: f64 };

const Token = union(enum) {
    keyword_if,
    keyword_swtich: void,
    digit: usize,

    fn is(self: Token, tag: std.meta.Tag(Token)) bool {
        return self == tag;
    }
};

pub fn main() !void {
    const color = Color.red;

    std.debug.print("color: {s}, is red? {}\n", .{ @tagName(color), color.isRed() });

    std.debug.print("{any} \n", .{color.isRed()});
    std.debug.print("{any} \n", .{@intFromEnum(color)});

    const fav: Color = @enumFromInt(2);
    std.debug.print("color: {s}, is red? {}\n", .{ @tagName(fav), fav.isRed() });

    switch (fav) {
        .red => std.debug.print("red\n", .{}),
        .green => std.debug.print("green\n", .{}),
        .blue => std.debug.print("blue\n", .{}),
    }
    var tok: Token = .keyword_if;
    std.debug.print("token: {s}, is keyword_if? {}\n", .{ @tagName(tok), tok.is(.keyword_if) });

    tok = .{ .digit = 42 };
    switch (tok) {
        .keyword_if => std.debug.print("keyword_if\n", .{}),
        .keyword_swtich => std.debug.print("keyword_swtich\n", .{}),
        .digit => |d| std.debug.print("digit {} \n", .{d}),
    }
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
