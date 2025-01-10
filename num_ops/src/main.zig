const std = @import("std");

pub fn main() !void {
    const zero: u8 = 0;
    const one: u8 = 1;
    const two: u8 = 2;
    const two_fifty: u8 = 250;

    var result = zero + one + two + two_fifty;
    std.debug.print("result: {}\n", .{result});

    //const overfflow: u8 = 259;
    //std.debug.print("result: {}\n", .{overfflow});
    //result = two_fifty * two_fifty;

    //wrapping
    result = two_fifty *% two;
    std.debug.print("*% result: {}\n", .{result});

    //saturating
    result = two_fifty *| two;
    std.debug.print("*| result: {}\n", .{result});

    // overflowing (wrapping)
    result = zero -% one;
    std.debug.print("-% result: {}\n", .{result});

    // overflowing (saturating)
    result = zero -| one;
    std.debug.print("-% result: {}\n", .{result});

    const neg_one_twenty_eight: i8 = -128;
    std.debug.print("-% -128 i8 result: {}\n", .{-%neg_one_twenty_eight});

    //Shifts
    _ = 1 << 2;
    _ = 1 <<| 2;
    _ = 32 >> 1;

    // Bit ops
    _ = 32 | 2; //or
    _ = 32 & 1; //and
    _ = 32 ^ 0; //xor
    const one_bit: u8 = 0b0000_0001;
    _ = ~one_bit; //not

    // Comparison
    _ = 3 < 9;
    _ = 3 <= 9;
    _ = 3 > 9;
    _ = 3 >= 9;
    _ = 3 == 9;
    _ = 3 != 9;

    //Type coerce when it's safe.
    const byte: u8 = 200;
    const word: u16 = 999;
    const dword: u32 = byte + word;
    std.debug.print("dword: {}\n", .{dword});

    const word_2: u16 = @intCast(dword);
    std.debug.print("word_2: {}\n", .{word_2});

    var a_float: f32 = 3.1415;
    const an_int: i32 = @intFromFloat(a_float);
    std.debug.print("an_int: {}\n", .{an_int});

    a_float = @floatFromInt(an_int);
    std.debug.print("a_float: {}\n", .{a_float});

    // Numeric op builtins
    // @addWithOverflow, @subWithOverflow, @mulWithOverflow, @min, @max
    // @mod, @rem, @fabs, @sqrt, @pow, @sin, @cos, @tan, @asin, @acos, @atan, @atan2
    // std.math
    // std.math.add, std.match.sub, std.math.mul, std.math.div, std.math.min, std.math.max
}
