const std = @import("std");

pub fn simd() !void {
    // vector items can only be booleans, intergers, floats, or pointers. They are credate with @Vector
    const bools_vec_a: @Vector(3, bool) = .{ true, false, true }; // tuple literal init
    const bool_array_a: [3]bool = [_]bool{ true, true, true };
    const bools_vec_b: @Vector(3, bool) = bool_array_a; // array coercion init
    const bool_vec_c = bools_vec_a == bools_vec_b;
    std.debug.print("bool_vec_c: {any} , {}\n\n", .{ bool_vec_c, @TypeOf(bool_vec_c) });
    const bool_array_b: [3]bool = bool_vec_c; // coerce back to array
    std.debug.print("bool_array_b: {any} , {}\n\n", .{ bool_array_b, @TypeOf(bool_array_b) });

    // Arithmetic ops on vectors.
    const int_vec_a = @Vector(3, u8){ 1, 2, 3 };
    const int_vec_b = @Vector(3, u8){ 4, 5, 6 };
    const int_vec_c = int_vec_a + int_vec_b;
    std.debug.print("int_vec_c: {any}\n\n", .{int_vec_c});
    // with simd this will happen all at once
    //

    // Use @splat to turn a scalar into a vector.
    const twos: @Vector(3, u8) = @splat(2);
    const int_vec_d = int_vec_a * twos;
    std.debug.print("int_vec_d: {any}\n\n", .{int_vec_d});

    // Use @reduce to obtain a scalar from a vector.
    // Supported ops: .Or, .And, .Xor, .Min, .Max, .Add, .Mul
    const all_true = @reduce(.And, bools_vec_a);
    std.debug.print("all_true: {}\n\n", .{all_true});
    const any_true = @reduce(.Or, bools_vec_a);
    std.debug.print("any_true: {}\n\n", .{any_true});

    // You can also use array index syntax.
    std.debug.print("bools_vec_a[1]: {}\n\n", .{bools_vec_a[1]});

    // Use @shuffle to change the order of vector elements.
    const a = @Vector(7, u8){ 'o', 'l', 'h', 'e', 'r', 'z', 'w' };
    const b = @Vector(4, u8){ 'w', 'd', '!', 'x' };

    // To shuffle within a single vector, pass undefined as the second argument.
    // Notice that we can re-order, duplicate, or omit elements of the input vector
    const mask1 = @Vector(5, i32){ 2, 3, 1, 1, 0 };
    const res1: @Vector(5, u8) = @shuffle(u8, a, undefined, mask1);
    std.debug.print("res1: {s}\n\n", .{&@as([5]u8, res1)});

    // Combining two vectors
    const mask2 = @Vector(6, i32){ -1, 0, 4, 1, -2, -3 };
    const res2: @Vector(6, u8) = @shuffle(u8, a, b, mask2);
    std.debug.print("res2: {s}\n\n", .{&@as([6]u8, res2)});
    // SIMD ASCII caseless equal.
    std.debug.print("a == A: {}\n", .{asciiCaselessEql('a', 'A')});
    std.debug.print("a == a: {}\n", .{asciiCaselessEql('a', 'a')});
    std.debug.print("A == A: {}\n", .{asciiCaselessEql('A', 'A')});
    std.debug.print("A == a: {}\n", .{asciiCaselessEql('A', 'a')});
    std.debug.print("a == B: {}\n", .{asciiCaselessEql('a', 'B')});
    std.debug.print("a == b: {}\n", .{asciiCaselessEql('a', 'b')});
    std.debug.print("A == B: {}\n", .{asciiCaselessEql('A', 'B')});
    std.debug.print("A == b: {}\n", .{asciiCaselessEql('A', 'b')});
}

fn asciiCaselessEql(a: u8, b: u8) bool {
    // Check if ASCII letters.
    std.debug.assert(std.ascii.isAlphabetic(a) and std.ascii.isAlphabetic(b));
    // Check if exactly equal.
    if (a == b) return true;
    // Create vectors for comparison.
    const a_vec: @Vector(2, u8) = .{ a, a };
    const b_vec: @Vector(2, u8) = .{ b, b ^ 0x20 }; // ^ 0x20 flips case
    // Compare
    const table = a_vec == b_vec;
    // Reduce to scalar boolean result.
    return @reduce(.Or, table);
}
