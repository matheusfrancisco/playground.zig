//
// We've already learned about switch statements in exercises 030, 031 and 108.
// They also work with packed containers:

const S = packed struct(u2) {
    a: bool,
    b: i1,
};

// Try to make it compile without adding an `else` prong!

comptime {
    const s: S = .{ .a = true, .b = -1 };
    switch (s) {
        .{ .a = true, .b = -1 } => {}, // ok!
        .{ .a = true, .b = ??? },
        .{ .a = ???, .b = 0 },
        .{ .a = ???, .b = ??? },
        => @compileError("We don't want to end up here!"),
    }
}

// As we can see, switching on packed structs is pretty straightforward.
// When switching on packed unions however, we'll realize that a packed
// union never keeps track of its active tag, not even in debug mode! This
// means that packed unions compare solely by their bit pattern (again, just
// like integers).

const U = packed union(u2) {
    a: u2,
    b: i2,
};

// Find and remove the duplicate case!

comptime {
    const u: U = .{ .a = 3 };
    switch (u) {
        .{ .a = 3 } => {}, // ok!
        .{ .a = 2 },
        .{ .b = 1 },
        .{ .b = -1 },
        .{ .a = 0 },
        => @compileError("We don't want to end up here!"),
    }
}

// Since packed unions don't have the concept of an active tag, it's always legal
// to access any of their fields. This can be useful to view the same data from
// different perspectives seamlessly.
//
// Try to make the float below negative:

/// IEEE 754 half precision float
const Float = packed union(u16) {
    value: f16,
    bits: packed struct(u16) {
        mantissa: u10,
        exponent: u5,
        sign: u1,
    },
};

pub fn main() void {
    // Reminder: if the sign bit of a float is set, the number is negative!

    var number: Float = .{ .value = 2.34 };
    number.bits.??? = ???;
    if (number.value != -2.34) {
        std.debug.print("Make it negative!\n", .{});
    }
}

// This concludes our introduction to packed containers. The next time you need
// control over individual bits, keep them in mind as a potent alternative!
//

const std = @import("std");
