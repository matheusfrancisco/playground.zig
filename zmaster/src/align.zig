const std = @import("std");
fn alig() void {

    // Natural alignments.
    inline for (.{ u8, u16, u32, u64 }) |T| {
        std.debug.print("alignOf({}) == {}\n", .{ T, @alignOf(T) });
    }
    std.debug.print("\n", .{});

    // Scalars
    const x: u8 align(8) = 13;
    std.debug.print("x: {*}\n", .{&x});

    const y: u32 = 33;
    std.debug.print("y: {*}\n", .{&y});

    const z: u8 = 42;
    std.debug.print("z: {*}\n", .{&z});
    std.debug.print("\n", .{});

    // Arrays
    const array = [_]u32{ 0, 1, 2 };
    for (&array, 0..) |*item, i| std.debug.print("array[{}]: {*} ", .{ i, item });
    std.debug.print("\n\n", .{});

    // Pointer alignment coercion and casting.
    const n: u32 = 42;
    std.debug.print("Type of &n: {}\n", .{@TypeOf(&n)});

    const pa: *align(8) const u32 = @alignCast(&n);
    std.debug.print("Type of pa: {}\n", .{@TypeOf(pa)});

    const pb: *const anyopaque = &n;
    std.debug.print("Type of pb: {}\n", .{@TypeOf(pb)});

    const pc: *const u32 = @ptrCast(@alignCast(pb));
    std.debug.print("Type of pc: {}\n", .{@TypeOf(pc)});

    // Pointer with unaligned address.
    const pd: *const u32 = @ptrFromInt(0x102d4964);
    _ = &pd;
}
