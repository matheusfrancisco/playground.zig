const std = @import("std");
const Io = std.Io;

fn printMem(
    param: *const u8,
    constant: *const u8,
    variable: *const u8,
) void {
    std.debug.print("param: {x} const: {x} var: {x}\n", .{
        @intFromPtr(param),
        @intFromPtr(constant),
        @intFromPtr(variable),
    });
}

fn a(p: u8) void {
    const lc: u8 = 42;
    var lv: u8 = 99;
    std.debug.print("a: ", .{});
    printMem(&p, &lc, &lv);
}

fn b(p: u8) void {
    const lc: u8 = 42;
    var lv: u8 = 99;
    std.debug.print("b: ", .{});
    printMem(&p, &lc, &lv);
}

fn c(p: u8) struct { *const u8, *u8 } {
    const lc: u8 = 3;
    var lv: u8 = 99;
    std.debug.print("c: ", .{});
    printMem(&p, &lc, &lv);

    b(0);

    return .{ &lc, &lv };
}
// container level (globals)
const global_const: f32 = 3.14;
var global_var: usize = 4233;

pub fn main(_: std.process.Init) !void {
    const x: u8 = 42;
    var y: u8 = 99;
    const cpcx: *const u8 = &x;
    // cant modify the cpcx and cant modify the x through cpcx
    //cpcx.* = 43;
    //nor this
    //cpcx = &y;

    std.debug.print("x: {d}  cpcx: {x}, type: {}\n", .{ x, @intFromPtr(cpcx), @TypeOf(cpcx) });

    const cpvy: *u8 = &y;
    cpvy.* = 100; // you can do this
    // but can change the cpvy to point to something else

    std.debug.print("y: {d}  cpvy: {x}, type: {}\n", .{ y, @intFromPtr(cpvy), @TypeOf(cpvy) });

    std.debug.print("---------------------\n", .{});
    std.debug.print("---------------------\n", .{});
    std.debug.print("---------------------\n", .{});

    // container level (globals)
    std.debug.print("global_const: {x}  global_var: {x}\n", .{
        @intFromPtr(&global_const),
        @intFromPtr(&global_var),
    });

    // heap
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const heap_1 = try allocator.create(u8);
    defer allocator.destroy(heap_1);
    const heap_2 = try allocator.create(u8);
    defer allocator.destroy(heap_2);

    std.debug.print("heap_1: {x}  heap_2: {x}\n", .{
        @intFromPtr(heap_1),
        @intFromPtr(heap_2),
    });

    a(13);
    b(14);
    const ptr_to_const, const ptr_to_var = c(15);

    // Pointer to const and local var.
    std.debug.print("\nptr_to_const: {x} = {} ptr_to_var: {x} = {}\n", .{
        @intFromPtr(ptr_to_const),
        ptr_to_const.*,
        @intFromPtr(ptr_to_var),
        ptr_to_var.*,
    });

    b(14);

    // ...and again.
    std.debug.print("ptr_to_const: {x} = {} ptr_to_var: {x} = {}\n", .{
        @intFromPtr(ptr_to_const),
        ptr_to_const.*,
        @intFromPtr(ptr_to_var),
        ptr_to_var.*,
    });

    if (true) {
        return;
    }

    //array literal style, cannot grow
    //var array = [_]u8{1, 2, 3};

    //
    //tuple literal style
    //const array: [3]u8 = .{ 1, 2, 3 };
    //std.debug.print("Array: {any}\n", .{array});
    //

    // you can leave it undefined for now.
    var array: [3]u8 = undefined;
    array[0] = 1;
    array[1] = 2;
    array[2] = 4;
    //using destructuring to assign values to the array
    array[0], array[1], array[2] = .{ 1, 2, 3 };
    std.debug.print("Array: {any}\n", .{array});
    std.debug.print("Array length: {d}\n", .{array.len});

    //const a, const b, const c = array;
    //std.debug.print("a: {d}, b: {d}, c: {d}\n", .{ a, b, c });

    // multidimensional arrays are arrays of arrays

    const grid3x3 = [_][3]u8{
        .{ 1, 2, 3 },
        .{ 4, 5, 6 },
        .{ 7, 8, 9 },
    };
    std.debug.print("Grid 3x3: {any}\n", .{grid3x3});

    // with sentinel-terminated
    const with_sentinel = [_:0]u8{ 1, 2, 3, 4 };
    std.debug.print("With sentinel: {any}\n", .{with_sentinel});
    std.debug.print("sentinel: {}\n", .{with_sentinel[with_sentinel.len]});

    // string literal are actually pointers to sentinel
    // terminated arrays with sentinel 0. This is what is
    // known as null terminated string in C.

    const str = "Hello";
    std.debug.print("type of str: {}\n", .{@TypeOf(str)});

    //but you can easyly coerce this type into a slice of
    //byte, which is what zig calls a string.
    const bytes: []const u8 = str;
    std.debug.print("type of bytes: {}\n", .{@TypeOf(bytes)});

    // arrays are copied by-value, so copies are new arrays.
    var copy = array;
    copy[2] = 5;
    std.debug.print("copy: {any}\n", .{copy});
    std.debug.print("array: {any}\n", .{array});

    //mental model
    //memory units smallest addressable unit of memory is one byte (8bits)
    // zig understands memory as a linear array of bytes, each with a unique address.
    // debug zig undefined, zig will write a value 0xaa to each byte
    // of allocated memory to help in spotting undefined memory in a debugger.
    //

}
