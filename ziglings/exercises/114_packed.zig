//
// We've already learned plenty about bit manipulation using bitwise operations
// in exercices 097 and 098 and in quiz 110. The techniques we already know work
// just fine, but creating masks and shifting individual bits around can become
// quite tedious and unwieldy pretty quickly.
// What if there was a better, a more convenient way to control invidivual bits?
//
// Luckily, Zig has a keyword for exactly this purpose:
//
//     packed
//
// It doesn't do anything on its own, to unlock its potential (and to get our
// program to compile) we have to attach it either to a struct or to a union
// declaration:
//
//     const Foo = packed struct { ... };
//     const Bar = packed union { ... };
//
// Now, what does this keyword even do?
// To answer this question we first have to talk about *container layouts*.
//
// Plain structs and unions use the `auto` layout; it gives no guarantees about
// their size or the order of the fields they contain, both are fully up to the
// compiler (though both size and field order *are* guaranteed to be the same
// across any single compilation unit).
//
// Attaching the `packed` keyword to a container makes it use `packed` layout:
// Suddenly, all of its fields are *packed* together tightly without any padding
// in between and their order is guaranteed to be the same as the one specified
// in our source code. For structs, the size of the container is guaranteed to
// be the sum of the (bit-)sizes of all of its fields. For unions, all fields
// have to have the exact same (bit-)size (no padding allowed!); the union itself
// is also guaranteed to be exactly of this size.
//
// If you're familiar with C, you might have already heard of structure packing
// in a different context: arranging fields in a way that minimizes the amount
// of alignment padding between them (or having the compiler do it for you).
// This is *not* what Zig's `packed` keyword is for!
//
// Try to make the comptime assertions below pass:

const PackedStruct = packed struct {
    a: u2,
    b: u?,
};

comptime {
    assert(@bitSizeOf(PackedStruct) == 6);
}

const PackedUnion = packed union {
    a: bool,
    b: u?,
};

comptime {
    assert(@bitSizeOf(PackedUnion) == 1);
}

// Now, how can we use this new knowledge to manipulate some bits?
//
// As you might have already guessed, `packed` containers are very useful for
// representing bitflags or other tightly packed collections of bit-sized values
// often found in file headers and network protocols.
//
// Let's take a look at a real-life example:
// The LZ4 compression format (†) specifies a frame format to describe compressed
// data. Each LZ4 frame has a descriptor, and each descriptor contains a 'FLG'
// byte that specifies the contents of its frame:

/// |  BitNb  |  7-6  |   5   |    4     |  3   |    2     |   1    |   0  |
/// | ------- |-------|-------|----------|------|----------|--------|------|
/// |FieldName|Version|B.Indep|B.Checksum|C.Size|C.Checksum|Reserved|DictID|
///
const FLG = packed struct(u8) {
    dict_id: bool,
    reserved: u1 = 0,
    content_checksum: bool,
    content_size: bool,
    block_checksum: bool,
    block_indepencence: bool,
    version: u2,
};

// Wait, what's with the `(u8)` after the `struct` keyword? What do integers have
// to do with all of this?
// Well, this is a good opportunity to come clear about something:
// packed structs and packed unions aren't actually structs or unions at all...
// They are merely integers in disguise! For all intents and purposes, their
// fields are just convenient names for ranges of their underlying bits. To make
// it easier to enforce size requirements for packed containers, Zig allows us
// to specify a *backing integer* for them, just like for enums.
//
// In the case of `FLG`, we want our struct to occupy exactly a single byte, so
// we specify `u8` as the backing integer. It's safe to convert between a packed
// container and its backing integer using the builtin `@bitCast`.
// The LZ4 spec also mandates that reserved bits must always be zero, so it's
// good practice to set `0` as a default value for `reserved`.
//
// The fields of a packed struct start at the least significant bit of its backing
// integer and end at its most significant bit. This is the case no matter what
// endianness our target has.
//
// Try to silence the complaints below:

const Bits = packed struct(u4) {
    a: u1 = 0,
    b: u1 = 0,
    c: u1 = 0,
    d: u1 = 0,
};

pub fn main() void {
    {
        const expected: Bits = @bitCast(@as(u4, 0b1000));
        const my_bits: Bits = .{};
        if (my_bits != expected) complain(my_bits, expected, @src());
    }

    {
        const expected: Bits = @bitCast(@as(u4, 0b0001));
        const my_bits: Bits = .{};
        if (my_bits != expected) complain(my_bits, expected, @src());
    }

    {
        const expected: Bits = @bitCast(@as(u4, 0b0010));
        const my_bits: Bits = .{};
        if (my_bits != expected) complain(my_bits, expected, @src());
    }

    {
        const expected: Bits = @bitCast(@as(u4, 0b0011));
        const my_bits: Bits = .{};
        if (my_bits != expected) complain(my_bits, expected, @src());
    }

    {
        const expected: Bits = @bitCast(@as(u4, 0b1101));
        const my_bits: Bits = .{};
        if (my_bits != expected) complain(my_bits, expected, @src());
    }
}

// As we can see, equality comparisons (`==` and `!=`) work for packed structs.
// They also work for packed unions. However, since packed containers are not
// naturally ordered, we can't use any other comparison operators on them.
//
// It's also possible to use packed containers in `switch` statements, which we
// will cover in the next exercise!
//
// Since packed containers make very strong guarantees about their memory layout,
// only a handful of types are eligible to be part of them.
// The following types are allowed as field types:
//
// - integers
// - floats
// - bool
// - void
// - enums with explicit backing integers
// - packed unions
// - packed structs
//

const std = @import("std");
const assert = std.debug.assert;

fn complain(my_bits: Bits, expected: Bits, src_loc: std.builtin.SourceLocation) void {
    std.debug.print(
        "That's not quite right! You've got 0b{b:0>4}, but we want 0b{b:0>4} in line {d}.\n",
        .{ @as(u4, @bitCast(my_bits)), @as(u4, @bitCast(expected)), src_loc.line },
    );
}

// (†) https://github.com/lz4/lz4/blob/5c4c1fb2354133e1f3b087a341576985f8114bd5/doc/lz4_Frame_format.md#frame-descriptor
