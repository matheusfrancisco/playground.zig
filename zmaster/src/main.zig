const std = @import("std");
const Io = std.Io;
const print = std.debug.print;
const Trie = @import("Trie.zig");
const heap = std.heap;
const mem = std.mem;

const simd = @import("simd.zig");
const zmaster = @import("zmaster");
const Point = @import("Point.zig");
const protocol = @import("protocol.zig");
const u = @import("uniontag.zig");
const al = @import("alloc.zig");
const stack = @import("stack.zig");
const ts = @import("to_string_tagged.zig");
const tp = @import("to_string_ptr.zig");

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

fn typeNameLength(comptime T: type) usize {
    const name = @typeName(T);
    return name.len;
}

const Foo = struct {
    a: i32,
    b: i64,
    c: i32,
};
fn printStringer(s: tp.Stringer) !void {
    var buf: [256]u8 = undefined;
    const str = try s.toString(&buf);
    std.debug.print("{s}\n", .{str});
}
fn work(id: usize) void {
    std.debug.print("Thread {} is working\n", .{id});
    // Simulate some work with a sleep
    //    std.time.sleep(1 * std.time.second);
    std.debug.print("Thread {} has finished working\n", .{id});
}

fn work2(io: Io, i: usize) void {
    _ = io;
    std.debug.print("job {d}\n", .{i});
}
pub fn main(init: std.process.Init) !void {

    //bit about threads

    const cpus = try std.Thread.getCpuCount();
    // no thread
    //    for (0..cpus) |id| {
    //        work(id);
    //    }
    //

    //var handles: [14]std.Thread = undefined;
    //for (0..cpus) |id| {
    //    handles[id] = try std.Thread.spawn(.{}, work, .{id});
    //}

    //// this wait until it finish
    //for (handles) |handle| {
    //    handle.join();
    //}
    //
    //this leave the main thread
    //not wait to finish
    for (0..cpus) |id| {
        var handle = try std.Thread.spawn(.{}, work, .{id});
        handle.detach();
    }

    const clock = std.Io.Clock.awake;

    try std.Io.sleep(init.io, std.Io.Duration.fromMicroseconds(1001), clock);
    // but we dont have guarantee that the threads will finish before the main thread exits, so we sleep for a while to let them finish
    //

    const io = init.io;

    var group: std.Io.Group = .init;
    defer group.cancel(io);
    for (0..cpus) |id| {
        group.async(io, work2, .{ io, id });
        group.async(io, work, .{id});
    }

    try group.await(io);

    if (true) return;
    var gpa = heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    //multi
    var multi = std.MultiArrayList(Foo){};
    defer multi.deinit(allocator);

    try multi.append(allocator, .{ .a = 1, .b = 2, .c = 3 });
    // pre allocate to add more items;
    try multi.ensureUnusedCapacity(allocator, 2);

    multi.appendAssumeCapacity(.{ .a = 3, .b = 2, .c = 3 });
    multi.appendAssumeCapacity(.{ .a = 3, .b = 3, .c = 3 });

    std.debug.print(".a: {any}\n", .{multi.items(.a)});
    std.debug.print(".b: {any}\n", .{multi.items(.b)});
    std.debug.print(".c: {any}\n\n", .{multi.items(.c)});
    // If you will be accessing more than one field, it's
    // better to get the slice of all fields first, and then
    // call `items` on that. This provides better performance.
    //
    const sliced = multi.slice();
    const a_fields = sliced.items(.a);
    const b_fields = sliced.items(.b);
    const c_fields = sliced.items(.c);
    std.debug.print("first .a = {}\n", .{a_fields[0]});
    std.debug.print("second .b = {}\n", .{b_fields[1]});
    std.debug.print("third .c = {}\n\n", .{c_fields[2]});
    // And that's one way to iterate over a field for all items.
    for (a_fields, 0..) |a, i| std.debug.print("{}: .a = {}\n", .{ i, a });
    for (b_fields, 0..) |b, i| std.debug.print("{}: .b = {}\n", .{ i, b });
    for (c_fields, 0..) |c, i| std.debug.print("{}: .c = {}\n", .{ i, c });

    //you ca get an index in the list.
    const first_foo = multi.get(0);
    std.debug.print("first foo: {any}\n", .{first_foo});
    // You can set an item at an index in the list.
    // This overwrites the existing item at that index.
    multi.set(1, .{ .a = 4, .b = 4, .c = 4 });

    // As with `ArrayList` you can use `MultiArrayList` as a stack.
    const head = multi.pop();
    std.debug.print("head: {any}\n", .{head});
    try multi.append(allocator, .{ .a = 5, .b = 5, .c = 5 }); // push
    // `popOrNull` to use the list as an iterator with `while`.
    var i: usize = 0;

    while (multi.pop()) |item| : (i += 1)
        std.debug.print("items[{}]: {any}\n", .{ i, item });

    std.debug.print("\n", .{});

    // Beware! If the list structure is modified, the previously
    // obtained slices are invalidated. This may occur when appending
    // or removing / popping items.
    std.debug.print("a_fields.len: {}\n", .{a_fields.len});
    std.debug.print("b_fields.len: {}\n", .{b_fields.len});
    std.debug.print("c_fields.len: {}\n", .{c_fields.len});
    std.debug.print("list len: {}\n", .{multi.items(.a).len});
    if (true) return;
    try simd.simd();

    if (true) return;

    //const bob = ts.Stringer{ .user = ts.User{
    //    .name = "Bob",
    //    .email = "a@b.com",
    //} };

    //try printStringer(bob);

    //const donald = ts.Stringer{ .animal = ts.Animal{
    //    .name = "Donald",
    //    .greeting = "Quack!",
    //} };

    //try printStringer(donald);
    // Pointer cast interface.
    var bob = tp.User{
        .name = "Bob",
        .email = "bob@example.com",
    };
    const bob_impl = bob.stringer();
    try printStringer(bob_impl);

    var donald = tp.Animal{
        .name = "Donald Duck",
        .greeting = "Quack!",
    };
    const donald_impl = donald.stringer();
    try printStringer(donald_impl);
    if (true) return;

    const numss = [_]i32{ 2, 4, 6 };
    var sum: usize = 0;

    inline for (numss) |n| {
        const T = switch (n) {
            2 => f32,
            4 => i8,
            6 => bool,
            else => unreachable,
        };
        sum += typeNameLength(T);
    }

    std.debug.print("Sum of type name lengths: {}\n", .{sum});

    if (true) return;
    try mytrie(init);
    if (true) return;
    try stack.run();
    if (true) return;
    u.bare();
    print("\n", .{});
    try al.alloc();
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
