const std = @import("std");
const mem = std.mem;

// A friendly alias for our generic hash map type.
const NodeMap = std.AutoHashMap(u8, Node);

// Trie nodes are recursive data structures. They contain
// maps of child nodes.
const Node = struct {
    // If this node marks the end of a contained string.
    terminal: bool = false,
    children: NodeMap,

    fn init(allocator: mem.Allocator) Node {
        return .{ .children = NodeMap.init(allocator) };
    }

    // Being a recursive data structure, we have recursive
    // allocations that need freeing.
    fn deinit(self: *Node) void {
        var iter = self.children.valueIterator();
        while (iter.next()) |node| node.deinit();
        self.children.deinit();
    }
};

allocator: mem.Allocator,
root: Node,

const Trie = @This();

pub fn init(allocator: mem.Allocator) Trie {
    return .{
        .allocator = allocator,
        .root = Node.init(allocator),
    };
}

// This sinle call will descend down to all the child nodes,
// freeing their allocations.
pub fn deinit(self: *Trie) void {
    self.root.deinit();
}

pub fn insert(self: *Trie, str: []const u8) !void {
    var node = &self.root;

    for (str, 0..) |b, i| {
        // A get or put result contains pointers to the
        // key and value of a map entry.
        var gop = try node.children.getOrPut(b);

        // found_existing tells us if we need a new Node.
        if (!gop.found_existing) {
            gop.value_ptr.* = Node.init(self.allocator);
        }

        // If this is the last byte in the string, we set the
        // terminal flag for subsequent lookups.
        if (i == str.len - 1) gop.value_ptr.terminal = true;

        // Keep on descending for the next byte.
        node = gop.value_ptr;
    }
}

pub fn lookup(self: Trie, str: []const u8) bool {
    var node = self.root;

    for (str, 0..) |b, i| {
        if (node.children.get(b)) |n| {
            // Lookup succeeds if we have a node and it's a terminal.
            if (i == str.len - 1 and n.terminal) return true;

            // Descend for the next byte.
            node = n;
        } else break; // No node, no match.
    }

    return false;
}
