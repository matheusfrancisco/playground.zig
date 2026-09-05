const std = @import("std");

const print = std.debug.print;

// Implicit backing integer type and field values.
const Suit = enum {
    Clubs,
    Diamonds,
    Hearts,
    Spades,
};

// Explicit backing integer type and start value.
const Face = enum(u8) {
    Ace = 1,
    Two,
    Three,
    Four,
    Five,
    Six,
    Seven,
    Eight,
    Nine,
    Ten,
    Jack,
    Queen,
    King,

    fn lessThan(self: Face, other: Face) bool {
        return @intFromEnum(self) < @intFromEnum(other);
    }
};

const Card = struct {
    face: Face,
    suit: Suit,

    fn init(face: Face, suit: Suit) Card {
        return .{ .face = face, .suit = suit };
    }

    fn lessThan(self: Card, other: Card) bool {
        return self.face.lessThan(other.face);
    }

    pub fn format(
        self: Card,
        comptime options: []const u8,
        fmt: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        // Unused here.
        _ = options;
        _ = fmt;

        try writer.print("{s} of {s} with value {}", .{
            @tagName(self.face),
            @tagName(self.suit),
            @intFromEnum(self.face),
        });
    }
};

pub fn enump() void {
    const jack = Card.init(.Jack, .Spades);
    print("{}\n", .{jack});

    const queen = Card.init(.Queen, .Hearts);
    print("{}\n", .{queen});

    print("Queen < Jack?: {}\n", .{queen.lessThan(jack)});
}
