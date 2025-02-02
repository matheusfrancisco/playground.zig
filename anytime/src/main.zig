const std = @import("std");

pub fn main() !void {
    const a = A{};
    const b = B{};
    const c = C{};
    const d = D.d;

    print(a);
    print(b);
    print(c);
    print(d);
}

const A = struct {
    // Method
    fn toString(_: A) []const u8 {
        return "A";
    }
};

const B = struct {

    // not a method
    fn toString(s: []const u8) []const u8 {
        return s;
    }
};

const C = struct {
    // to a even a function
    const toString: []const u8 = "C";
};

const D = enum {
    a,
    d,
    // Method
    fn toString(self: D) []const u8 {
        return @tagName(self);
    }
};

fn print(x: anytype) void {
    const T = @TypeOf(x);
    // do we have a to string declaretion
    if (!@hasField(T, "toString")) return;

    // is  it a function?
    const decl = @TypeOf(@field(T, "toString"));
    if (@typeInfo(decl) != .Fn) return;

    //is it a method?
    std.debug.print("{s}\n", .{x.toString()});
    const args = std.meta.ArgsTuple(decl);
    inline for (std.meta.fields(args), 0..) |arg, i| {
        if (i == 0 and arg.type == T) {
            // now we know we can call it as a method.
            std.debug.print("{s}\n", .{x.toString()});
        }
    }
}
