const std = @import("std");
const heap = std.heap;
const print = std.debug.print;
const mem = std.mem;
const unicode = std.unicode;

//pub fn asBytes(allocator: *std.mem.Allocator, code_points: []const u21) ![]u8 {
//    const len = std.unicode.utf8EncodedSize(code_points);
//    const bytes = try allocator.alloc(u8, len);
//    _ = std.unicode.utf8Encode(bytes, code_points);
//    return bytes;
//}

fn asBytes(allocator: mem.Allocator, code_points: []const u21) ![]u8 {
    var list: std.ArrayList(u8) = .empty; // 0.15+: unmanaged
    defer list.deinit(allocator);

    var buf: [4]u8 = undefined;

    for (code_points) |cp| {
        const len = try unicode.utf8Encode(cp, &buf);
        try list.appendSlice(allocator, buf[0..len]);
    }

    return try list.toOwnedSlice(allocator);
}

fn asCodePointsAlloc(allocator: mem.Allocator, str: []const u8) ![]u21 {
    var list: std.ArrayList(u21) = .empty; // 0.15+: unmanaged
    defer list.deinit(allocator);

    var view = try unicode.Utf8View.init(str);
    var iter = view.iterator();

    while (iter.nextCodepoint()) |cp| try list.append(allocator, cp);

    return try list.toOwnedSlice(allocator);
}

fn asCodePoints(str: []const u8, out: []u21) ![]u21 {
    var view = try unicode.Utf8View.init(str);
    var iter = view.iterator();

    var i: usize = 0;
    while (iter.nextCodepoint()) |cp| : (i += 1) out[i] = cp;

    return out[0..i];
}

fn fail() !void {
    return error.Fail;
}

pub fn alloc() !void {
    var gpa = heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();
    const ptr = try allocator.create(u8);
    defer allocator.destroy(ptr);

    ptr.* = 42;
    print("{*} \n", .{
        ptr,
    });

    print("value ptr = {d}\n", .{
        ptr.*,
    });

    //try fail();

    const slice = try allocator.alloc(u8, 2);
    defer allocator.free(slice);
    slice[0] = 1;
    slice[1] = 2;

    print("slice[0] = {d}, slice[1] = {d}\n", .{
        slice[0],
        slice[1],
    });

    print("{any}\n", .{slice}); // 0.16: slices need {any}, not {d}
    const code_points_in = [_]u21{ 'H', 'é', 'l', 'l', 'o', ' ', '🦎' };

    const str_out = try asBytes(allocator, &code_points_in);
    defer allocator.free(str_out);

    for (str_out) |b| print("{x} ", .{b});
    print("\n", .{});

    const code_points_out = try asCodePointsAlloc(allocator, str_out);
    defer allocator.free(code_points_out);

    for (code_points_out) |cp| print("{u} ", .{cp});
    print("\n", .{});

    const str_in = "Héllo 🦎";
    var buf: [str_in.len]u21 = undefined;

    const code_points_out_2 = try asCodePoints(str_in, &buf);

    for (code_points_out_2) |cp| print("{u} ", .{cp});
    print("\n", .{});
}
