const std = @import("std");
const fmt = std.fmt;
const mem = std.mem;

// 1280 byte max non-fragment IP packet
//   60 byte IP header
// - 8 byte UDP header
// ----
// 1212 byte max UDP payload
pub const udp_payload_len = 1212;
pub const data_len = udp_payload_len - Header.len; // 1212 - 8 = 1204 bytes
// message type codes.

pub const Code = enum(u4) {
    /// Test connectivity.
    ping,
    /// Request a resource.
    get,
};

// the payload header. this is not the ip or udp header.
// it is our own header at the strat of the udp payload segment.
// Layout: version:4 | code:4 | total:28 | index:28  == 64 bits
pub const Header = packed struct {
    // 4 bit version
    // 4 bit code
    // 28 bit datagram sequence index
    // 28 bit total datagrams
    // ---
    // 64 bits = 8 bytes
    pub const Type = u64;
    pub const len = @sizeOf(Type); // 8 bytes

    // 4 bit version number
    version: u4 = 0,
    code: Code = .get, // enum backed by a 4-bit integer here
    total: u28 = 1,
    index: u28 = 0,

    /// Decode a header from received bytes.
    pub fn read(buf: []const u8) Header {
        // bytes -> u64 -> Header
        return @bitCast(mem.readInt(Type, buf[0..len], .big));
    }

    /// Encode this header into a byte buffer.
    pub fn write(self: Header, buf: []u8) void {
        // Header -> u64 -> bytes. Big-endian: conventional for network order;
        // must match whatever read() uses.
        mem.writeInt(Type, buf[0..len], @bitCast(self), .big);
    }
};
