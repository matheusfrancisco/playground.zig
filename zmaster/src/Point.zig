const std = @import("std");

x: i32,
y: i32 = 1,

const Point = @This();

pub var step: i32 = 1;
pub const origin = Point{ .x = 0, .y = 0 };

pub fn new(x: i32, y: i32) Point {
    return .{ .x = x, .y = y };
}

pub fn add(self: Point, other: Point) Point {
    return .{ .x = self.x + other.x, .y = self.y + other.y };
}

pub fn increment(self: *Point) void {
    self.x += Point.step;
    self.y += Point.step;
}

pub fn format(
    self: Point,
    comptime fmt: []const u8,
    options: std.fmt.FormatOptions,
    writer: anytype,
) !void {
    _ = fmt;
    _ = options;
    try writer.print("Point{{ .x = {[x]d:.2}, .y = {[y]d:.2} }}", self);
}
