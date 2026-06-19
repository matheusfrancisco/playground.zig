//
// It's important to note that variable pointers and constant pointers
// are different types.
//
// Given:
//
//     var foo: u8 = 5;
//     const bar: u8 = 5;
//
// Then:
//
//     &foo is of type "*u8"
//     &bar is of type "*const u8"
//
// You can always make a const pointer to a mutable value (var), but
// you cannot make a var pointer to an immutable value (const).
// This sounds like a logic puzzle, but it just means that once data
// is declared immutable, you can't coerce it to a mutable type.
// Think of mutable data as being volatile or even dangerous. Zig
// always lets you be "more safe" and never "less safe."
//
const std = @import("std");

pub fn main() void {
    var a: u8 = 12;
    const b: *u8 = &a; // fix this!

    std.debug.print("a: {}, b: {}\n", .{ a, b.* });
}
//
// A look into the future:
// When you allocate memory, you store the returned address in
// a const var. The pointer itself never changes — it always
// refers to the same allocation — but you can still read and
// write the data it points to.
//
// Example:
//
//     const buf = try allocator.alloc(u8, 1024);
//     buf[0] = 42;  // fine: the *contents* are mutable
//
// Note:
// Passing this pointer to a function is cheap: it's just an address
// copied on the stack. The caller can work with the data without
// needing to know where it came from or how it was allocated.
