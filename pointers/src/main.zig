const std = @import("std");

pub fn main() !void {
    //single item pointer to a constant.
    const a: u8 = 0;
    const a_ptr = &a;
    // a_ptr.* += 1 ;
    std.debug.print("a_ptr: {}, type of a_ptr: {}\n", .{ a_ptr.*, @TypeOf(a_ptr) });

    var b: u8 = 0;
    const b_ptr = &b;
    b_ptr.* += 1;
    std.debug.print("b_ptr: {}, type of b_ptr: {}\n", .{ b_ptr.*, @TypeOf(b_ptr) });

    // both are const and can't be modified themselves.
    //a_ptr = &b;
    //b_ptr = &a;
    var c_ptr = a_ptr;
    c_ptr = b_ptr;
    std.debug.print("c_ptr: {}, type of c_ptr: {}\n", .{ c_ptr.*, @TypeOf(c_ptr) });

    //multi item pointer
    var array = [_]u8{ 1, 2, 3, 4, 5, 6, 7 };
    var d_ptr: [*]u8 = &array;

    std.debug.print("d_ptr: {any}\n", .{
        array,
    });
    std.debug.print("d_ptr[0]: {}, type of d_ptr: {}\n", .{ d_ptr[0], @TypeOf(d_ptr) });
    d_ptr[1] += 1; // change the array by change the pointer position
    d_ptr += 1; // pointer arithmetic
    std.debug.print("d_ptr: {any}\n", .{
        array,
    });
    std.debug.print("d_ptr[0]: {}, type of d_ptr: {}\n", .{ d_ptr[0], @TypeOf(d_ptr) });
    d_ptr -= 1; // pointer arithmetic
    std.debug.print("d_ptr[0]: {}, type of d_ptr: {}\n", .{ d_ptr[0], @TypeOf(d_ptr) });
    //std.debug.print("d_ptr[1]: {}, type of d_ptr: {}\n", .{ d_ptr[1], @TypeOf(d_ptr) });
    //
    const e_ptr = &array;
    std.debug.print("e_ptr[0]: {}, type of e_ptr: {}\n", .{ e_ptr[0], @TypeOf(e_ptr) });
    e_ptr[1] += 1; //
    std.debug.print("e_ptr[1]: {}, type of e_ptr: {}\n", .{ e_ptr[1], @TypeOf(e_ptr) });
    std.debug.print("array[1] {}\n", .{array[0]});
    std.debug.print("e_ptr.len {}\n", .{e_ptr.len});

    // sentinel terminated pointer
    array[3] = 0;
    const f_ptr: [*:0]const u8 = array[0..3 :0];
    std.debug.print("f_ptr[1]: {}, type of f_ptr: {}\n", .{ f_ptr[1], @TypeOf(f_ptr) });

    //if you ever need to get the addresses as an integer
    const addrss = @intFromPtr(f_ptr);
    std.debug.print("addrss: {}\n", .{addrss});

    //and the other way around
    const g_ptr: [*:0]const u8 = @ptrFromInt(addrss);
    std.debug.print("g_ptr[1]: {}, type of g_ptr: {}\n", .{ g_ptr[1], @TypeOf(g_ptr) });

    // if you need a pointer that can be null like in c use an optional pointer
    var h_ptr: ?*const usize = null;
    std.debug.print("h_ptr: {?}, type of h_ptr: {}\n", .{ h_ptr, @TypeOf(h_ptr) });
    h_ptr = &addrss;
    std.debug.print("h_ptr: {?}, type of h_ptr: {}\n", .{ h_ptr, @TypeOf(h_ptr) });
    std.debug.print("h_ptr size: {}, *usize size: {}", .{ @sizeOf(@TypeOf(h_ptr)), @sizeOf(*usize) });
    //there is also  [*c] but that is only transitioning from c
}
