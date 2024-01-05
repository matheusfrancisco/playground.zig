const std = @import("std");

// Global const
const global_const: u8 = 42;

// Global var
var global_var: u8 = 0;

fn printInfo(name: []const u8, x: anytype) void {
    std.debug.print("{s:>10} {any:^10}\t{}\n", .{ name, x, @TypeOf(x) });
}

pub fn main() !void {
    std.debug.print("{s:>10} {s:^10}\t{s}\n", .{ "name", "value", "type" });
    std.debug.print("{s:>10} {s:^10}\t{s}\n", .{ "-----", "----", "----" });

    // type inference and const defines an immutable value accessed vai the name
    const a_const = 42;

    printInfo("a_const", a_const);
    var a_var: u8 = 2;
    a_var += 1;
    printInfo("a_var", a_var);

    comptime var b_var = 2;
    printInfo("b_var", b_var);
    // both have to be initialized with a value.
    // const b_const;
    // var c_var: u8;

    var d_var: u8 = undefined;
    printInfo("d_var", d_var);
    d_var = 42;
    printInfo("d_var", d_var);

    var e_var: u8 = 42;
    //As a work arround, you can use the underscore special name to ignore something
    _ = e_var;

    // Integers
    // u-8bit, u-16bit, u-32bit, u-64bit, u-128bit, u-sizebit
    // Unsigned u8, u16, u32, u64, u128, usize (u(0-65535))
    // Signed i8, i16, i32, i64, i128, isize (i(-655335))
    // Literals can be decimal, binary,hex, and octal.
    // Optional underscores can be used to improve readability
    _ = 1_000_000; //decimal
    _ = 0x10ff_ffff; //hex
    _ = 0o777; //octal
    _ = 0b1111_0101_0111; //binary

    var f_var: u1 = 0;
    _ = f_var;

    //Floating point
    //f16, f32, f64, f128
    _ = 123.0E+77; //exponential notation
    _ = 123.0;
    _ = 123.0e+77;

    _ = 0x103.70; //hex floating point
    _ = 0x103.70p-5; //hex floating point with exponent
    _ = 0x103.70P-5; //hex floating point with exponent

    //Optional

    //Infinity
    _ = std.math.inf(f32); // positive inf
    _ = -std.math.inf(f64); // negative inf
    _ = -std.math.nan(f64); // not a number

    const i_const = 1.2;
    printInfo("i_const", i_const);
}
