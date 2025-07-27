const std = @import("std");
// zig provide linked lists

const stdout = std.io.getStdOut().writer();
fn singly() !void {
    const NodeU32 = struct {
        data: u32,
        node: std.SinglyLinkedList.Node = .{},
    };

    var list: std.SinglyLinkedList = .{};
    var one: NodeU32 = .{ .data = 1 };
    var two: NodeU32 = .{ .data = 2 };
    var three: NodeU32 = .{ .data = 3 };
    var five: NodeU32 = .{ .data = 5 };

    list.prepend(&two.node); // {2}
    two.node.insertAfter(&five.node); // {2, 5}
    two.node.insertAfter(&three.node); // {2, 3, 5}
    list.prepend(&one.node); // {1, 2, 3, 5}

    try stdout.print("Number of nodes: {}", .{list.len()});
}

fn doubly() !void {
    const NodeU32 = struct {
        data: u32,
        node: std.DoublyLinkedList.Node = .{},
    };

    var list: std.DoublyLinkedList = .{};
    var one: NodeU32 = .{ .data = 1 };
    var two: NodeU32 = .{ .data = 2 };
    var three: NodeU32 = .{ .data = 3 };
    var five: NodeU32 = .{ .data = 5 };

    list.append(&one.node); // {1}
    list.append(&three.node); // {1, 3}
    list.insertAfter(&one.node, &five.node); // {1, 5, 3}
    list.append(&two.node); // {1, 5, 3, 2}

    try stdout.print("Number of nodes: {}", .{list.len()});
}
