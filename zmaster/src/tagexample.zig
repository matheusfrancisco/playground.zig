const std = @import("std");

// Simple token type using an enum.
const Token = enum {
    lparen,
    rparen,
    lbrace,
    rbrace,

    kw_var,
    kw_fn,

    plus,
    minus,
    star,
    slash,

    pub fn format(
        self: Token,
        comptime _: []const u8,
        _: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        switch (self) {
            .plus => try writer.writeByte('+'),
            .minus => try writer.writeByte('-'),
            .star => try writer.writeByte('*'),
            .slash => try writer.writeByte('/'),
            else => {},
        }
    }
};

// Statements can be more complex, so we use a tagged union.
const Statement = union(enum) {
    var_decl: VarDecl,
    print: Expression,

    pub fn format(
        self: Statement,
        comptime _: []const u8,
        _: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        switch (self) {
            .print => |expr| try writer.print("print {}", .{expr}),
            inline else => |it| try writer.print("{}", .{it}),
        }
    }
};

// Tagged union fields can have simple or complex structure.
const VarDecl = struct {
    ident: []const u8,
    value: Expression,

    pub fn format(
        self: VarDecl,
        comptime _: []const u8,
        _: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        try writer.print("var {s} = {}", .{ self.ident, self.value });
    }
};

// Same goes for expressions.
const Expression = union(enum) {
    ident: []const u8,
    prefix: Prefix,
    infix: Infix,

    pub fn format(
        self: Expression,
        comptime _: []const u8,
        _: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        switch (self) {
            .ident => |str| try writer.writeAll(str),
            inline else => |it| try writer.print("{}", .{it}),
        }
    }
};

const Prefix = struct {
    op: Token,
    right: *const Expression,

    pub fn format(
        self: Prefix,
        comptime _: []const u8,
        _: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        try writer.print("({}{})", .{ self.op, self.right });
    }
};

const Infix = struct {
    left: *const Expression,
    op: Token,
    right: *const Expression,

    pub fn format(
        self: Infix,
        comptime _: []const u8,
        _: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        try writer.print("({} {} {})", .{
            self.left,
            self.op,
            self.right,
        });
    }
};

fn dbg(stmt: Statement) void {
    std.debug.print("{}\n", .{stmt});
}

pub fn main() !void {
    // This would be built by a parser.
    const x_decl = Statement{ .var_decl = .{
        .ident = "x",
        .value = .{ .prefix = .{
            .op = .minus,
            .right = &.{ .ident = "y" },
        } },
    } };

    const x_print = Statement{ .print = .{ .ident = "z" } };

    // Now we can debug print our AST nodes.
    dbg(x_decl);
    dbg(x_print);

    // Nice for testing the parsed tree.
    var buf: [256]u8 = undefined;
    const ast_str = try std.fmt.bufPrint(&buf, "{}", .{x_decl});
    std.debug.assert(std.mem.eql(u8, "var x = (-y)", ast_str));
}
