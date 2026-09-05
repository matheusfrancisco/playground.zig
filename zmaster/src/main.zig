const std = @import("std");
const Io = std.Io;
const print = std.debug.print;
const Trie = @import("Trie.zig");
const heap = std.heap;
const mem = std.mem;

const zmaster = @import("zmaster");
const Point = @import("Point.zig");
const protocol = @import("protocol.zig");
const u = @import("uniontag.zig");
const a = @import("alloc.zig");
const stack = @import("stack.zig");

//const Point = struct {
//    x: i32,
//    y: i32 = 1,
//
//    var step: i32 = 1;
//    const origin = Point{ .x = 0, .y = 0 };
//
//    fn new(x: i32, y: i32) Point {
//        return .{ .x = x, .y = y };
//    }
//
//    fn add(self: Point, other: Point) Point {
//        return .{ .x = self.x + other.x, .y = self.y + other.y };
//    }
//
//    fn increment(self: *Point) void {
//        self.x += Point.step;
//        self.y += Point.step;
//    }
//};
//
pub const S = struct {
    a: u8 = 1,
    b: u32 = 2,
    c: u8 = 3,
};

fn layout(s: *const S) void {
    // Info about struct type S.
    std.debug.print("Type:\t{}\n", .{S});
    std.debug.print("\tsize:\t{}\n", .{@sizeOf(S)});
    std.debug.print("\talign:\t{}\n", .{@alignOf(S)});
    std.debug.print("\n", .{});

    // Info about struct type S fields.
    const info = @typeInfo(S);

    inline for (info.@"struct".fields) |field| {
        std.debug.print("Field:\t{s}\n", .{field.name});
        std.debug.print("\tsize:\t{}\n", .{@sizeOf(field.type)});
        std.debug.print("\toffset:\t{}\n", .{@offsetOf(S, field.name)});
        std.debug.print("\talign:\t{?}\n", .{field.alignment}); // 0.16: alignment is ?usize
        std.debug.print("\taddr:\t{*}\n", .{&@field(s, field.name)});
        std.debug.print("\n", .{});
    }
}

// Utility: print the memory layout of a struct instance
fn layout2(s: *const Sp) void {
    std.debug.print("size of S = {}\n", .{@sizeOf(S)});
    std.debug.print("align of S = {}\n", .{@alignOf(S)});

    // Fields are comptime info -> inline for
    inline for (std.meta.fields(S)) |field| {
        std.debug.print(
            "field {s}: size={} offset={} align={?} addr={*}\n",
            .{
                field.name,
                @sizeOf(field.type),
                @offsetOf(S, field.name), // byte offset from struct base
                field.alignment,
                &@field(s.*, field.name),
            },
        );
    }
}

const Sp = packed struct {
    a: u3 = 0,
    b: u3 = 0,
    c: u2 = 0,
};

pub fn mytrie(init: std.process.Init) !void {
    const io = init.io; // 0.16: Io instance for clocks/files
    var gpa = heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Alice in Wonderland text embedded as a static
    // string directly in the binary.
    const corpus = @embedFile("alice.txt");

    // We split on space, skipping empty fields.
    var iter = mem.tokenizeScalar(u8, corpus, ' ');

    // Initialize the Trie and ensure its cleanup.
    var trie = Trie.init(allocator);
    defer trie.deinit();

    // A preliminary test.
    try trie.insert("caterpillar");
    try trie.insert("category");
    print("caterpillar: {} | ", .{trie.lookup("caterpillar")});
    print("category: {} | ", .{trie.lookup("category")});
    print("cat: {}\n\n", .{trie.lookup("cat")});

    // Some counters.
    var words: usize = 0;
    var found: usize = 0;

    // Prepare a timer to see how long these ops take.
    const t_start = std.Io.Clock.awake.now(io); // 0.16: Timer is gone; use Io.Clock

    // Insertions.
    while (iter.next()) |word| {
        try trie.insert(word);
        words += 1;
    }

    // Reset the iterator.
    iter.index = 0;

    // Now lookups.
    while (iter.next()) |word| {
        if (trie.lookup(word)) found += 1;
    }

    // Print summary stats. Note multi-line literal for format.
    // 0.16: Io.Duration has a format method — print it with {f}.
    print(
        \\words:    {}
        \\found:    {}
        \\took:     {f}
        \\
    , .{
        words,
        found,
        t_start.durationTo(std.Io.Clock.awake.now(io)),
    });
}
pub fn main(i: std.process.Init) !void {
    try mytrie(i);
    if (true) return;
    try stack.run();
    if (true) return;
    u.bare();
    print("\n", .{});
    try a.alloc();
    if (true) return;

    const s = S{};
    layout(&s);

    const s1 = Sp{};
    layout2(&s1);

    const bits: u8 = 0b11_011_101;
    const s2: Sp = @bitCast(bits);
    std.debug.print("s2: a={}, b={}, c={}\n", .{ s2.a, s2.b, s2.c });

    const h_original = protocol.Header{ .version = 0, .code = .get, .total = 1, .index = 0 };
    std.debug.print("original: {any}\n", .{h_original});

    var buf: [256]u8 = undefined;
    h_original.write(&buf);
    std.debug.print("buf: {x}\n", .{buf[0..protocol.Header.len]});

    const h_received = protocol.Header.read(&buf);
    std.debug.print("received: {any}\n", .{h_received});

    std.debug.print("----\n\n\n", .{});

    const p = Point{ .x = 10, .y = 20 };
    // type
    std.debug.print("Type of p: {}\n", .{@TypeOf(p)});

    const p2 = Point.new(30, 40);
    std.debug.print("Type of p: {}\n", .{@TypeOf(p2)});

    const p3 = p.add(p2);
    std.debug.print("Type of p: {}\n", .{@TypeOf(p3)});

    var d = Point.origin;
    d.increment();
    std.debug.print("Type of d: {}\n", .{@TypeOf(d)});
    std.debug.print("d: x={}, y={}\n", .{ d.x, d.y });

    std.debug.print("d: {}\n", .{d});
}
