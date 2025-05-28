const std = @import("std");
const List = @import("list.zig").List;
const ListArena = @import("list_arena.zig").List;

pub fn main() !void {
    // we use the GeneralPurposeAllocator for normal allocations
    //var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    //defer _ = gpa.deinit();
    //const allocator = gpa.allocator();

    // We use the page_allocator as backing allocator for the
    //ArenaAllocator page_allocator is not recommended for
    //normal allocations since it allocates a full page of
    //memory per allocation.
    const allocator = std.heap.page_allocator;

    const iterations: usize = 100;
    const item_count: usize = 1_000;

    var timer = try std.time.Timer.start();
    // loop
    for (0..iterations) |_| {
        // create the list.
        var list = try ListArena(usize).init(allocator, 0);
        errdefer list.deinit();
        // add items allocatting each time
        for (0..item_count) |i| {
            try list.append(i);
        }

        // free allocated memory once per item for non-arena
        list.deinit();
    }

    var took: f64 = @floatFromInt(timer.read());
    took /= std.time.ns_per_ms;
    std.debug.print("Took: {}ms\n", .{took});
}
