const std = @import("std");

/// This imports the separate module containing `root.zig`. Take a look in `build.zig` for details.
const lib = @import("base64_lib");

//
//The algorithm behind a base64 encoder usually works on a window of 3 bytes. Because each byte has 8 bits, so, 3 bytes forms a set of
//bits. This is desirable for the base64 algorithm, because 24 bits is divisible by 6, which forms
//4 groups of 6 bits each  24/6 = 4
// so it works converting 3 bytes at a time into
//
// for example, the string "abc" would be encoded as follows:
// // 1. Convert each character to its ASCII value:
// //    'a' -> 97
// //    'b' -> 98
// //    'c' -> 99
// // 2. Combine the ASCII values into a single 24-bit number:
// //    97 (01100001) 98 (01100010) 99 (01100011)
// //    Combined: 01100001 01100010 01100011
// // 3. Split the 24-bit number into four 6-bit groups:
// //    011000 010110 001001 100011
// // 4. Convert each 6-bit group to a decimal value:
// //    24-bit groups: 24/6 = 4
// //    011000 -> 24
// //    010110 -> 22
// //    001001 -> 9
// //    100011 -> 35
// // 5. Map each decimal value to a Base64 character using the Base64 index table:
// //    Base64 index table: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
// //    24 -> 'Y'
// //    22 -> 'W'
// //    9  -> 'J'
// //    35 -> 'j'
// // 6. Combine the Base64 characters to get the final encoded
// //    Base64 encoded
// //    "abc" -> "YWJj="
//
//
//for the string hi it would be:
//// 1. Convert each character to its ASCII value:
/// //    'h' -> 104
/// //    'i' -> 105
/// // 2. Combine the ASCII values into a single 24-bit number:
/// //    104 (01101000) 105 (01101001)
/// //    Combined: 01101000 01101001
/// // 3. Split the 24-bit number into four 6-bit groups:
/// //    011010 000110 1001(00) fill with 0s the gap
/// // 4. Convert each 6-bit group to a decimal value:
/// //    011010 -> 26
/// //    000110 -> 6
/// //    100100 -> 36
/// //    00 -> 0
/// // 5. Map each decimal value to a Base64 character using the Base64 index table:
/// //    Base64 index table: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
/// //    26 -> 'a'
/// //    6  -> 'G'
/// //    36 -> 'k'
///
///
///decoder // is the reverse of the encoder, it takes a Base64 encoded string and decodes it back to the original string.
///// 1. Convert each Base64 character to its decimal value using the Base64 index table:
/////    Base64 index table: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
/////    'Y' -> 24
//////    'W' -> 22
/////    'J' -> 9
//////    'j' -> 35
///// 2. Combine the decimal values into a single 24-bit number:
////////    24 (011000) 22 (010110) 9 (001001) 35 (100011)
/////    Combined: 011000 010110 001001 100011
///// 3. Split the 24-bit number into three 8-bit groups:
//////    01100001 01100010 01100011
///// 4. Convert each 8-bit group to its ASCII value:
/////    01100001 -> 97 ('a')
/////    01100010 -> 98 ('b')
/////    01100011 -> 99 ('c')
///// 5. Combine the ASCII values to get the original string:
/////    97 ('a') 98 ('b') 99 ('c')
/////    Original string: "abc"
const Base64 = struct {
    _table: *const [64]u8,
    pub fn init() Base64 {
        const upper = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
        const lower = "abcdefghijklmnopqrstuvwxyz";
        const numbers_symbols = "0123456789+/";
        return Base64{
            ._table = upper ++ lower ++ numbers_symbols,
        };
    }

    pub fn _char_at(self: Base64, index: usize) u8 {
        return self._table[index];
    }

    pub fn encode(self: Base64, allocator: std.mem.Allocator, input: []const u8) ![]u8 {
        if (input.len == 0) {
            return "";
        }

        const n_out = try _calc_encode_length(input);
        var out = try allocator.alloc(u8, n_out);
        var buf = [3]u8{ 0, 0, 0 }; // Buffer for 3 bytes
        var count: u8 = 0;
        var iout: u64 = 0;
        for (input, 0..) |_, i| {
            buf[count] = input[i];
            count += 1;
            if (count == 3) {
                out[iout] = self._char_at(buf[0] >> 2);
                out[iout + 1] = self._char_at(((buf[0] & 0x03) << 4) + (buf[1] >> 4));
                out[iout + 2] = self._char_at(((buf[1] & 0x0f) << 2) + (buf[2] >> 6));
                out[iout + 3] = self._char_at(buf[2] & 0x3f);
                iout += 4;
                count = 0;
            }
        }

        if (count == 1) {
            out[iout] = self._char_at(buf[0] >> 2);
            out[iout + 1] = self._char_at((buf[0] & 0x03) << 4);
            out[iout + 2] = '=';
            out[iout + 3] = '=';
        }

        if (count == 2) {
            out[iout] = self._char_at(buf[0] >> 2);
            out[iout + 1] = self._char_at(((buf[0] & 0x03) << 4) + (buf[1] >> 4));
            out[iout + 2] = self._char_at((buf[1] & 0x0f) << 2);
            out[iout + 3] = '=';
            iout += 4;
        }

        return out;
    }

    fn _char_index(self: Base64, char: u8) u8 {
        if (char == '=')
            return 64;
        var index: u8 = 0;
        for (0..63) |i| {
            if (self._char_at(i) == char)
                break;
            index += 1;
        }

        return index;
    }

    fn decode(self: Base64, allocator: std.mem.Allocator, input: []const u8) ![]u8 {
        if (input.len == 0) {
            return "";
        }
        const n_output = try _calc_decode_length(input);
        var output = try allocator.alloc(u8, n_output);
        var count: u8 = 0;
        var iout: u64 = 0;
        var buf = [4]u8{ 0, 0, 0, 0 };

        for (0..input.len) |i| {
            buf[count] = self._char_index(input[i]);
            count += 1;
            if (count == 4) {
                output[iout] = (buf[0] << 2) + (buf[1] >> 4);
                if (buf[2] != 64) {
                    output[iout + 1] = (buf[1] << 4) + (buf[2] >> 2);
                }
                if (buf[3] != 64) {
                    output[iout + 2] = (buf[2] << 6) + buf[3];
                }
                iout += 3;
                count = 0;
            }
        }

        return output;
    }
};

fn _calc_encode_length(input: []const u8) !usize {
    if (input.len < 3) {
        return 4; // 1 byte -> 4 characters
    }

    const n_groups: usize = try std.math.divCeil(usize, input.len, 3);
    return n_groups * 4;
}

fn _calc_decode_length(input: []const u8) !usize {
    if (input.len < 4) {
        return 3; // 4 characters -> 1 byte
    }

    const n_groups: usize = try std.math.divCeil(usize, input.len, 4);
    var multiple_groups = n_groups * 3;
    var i: usize = input.len - 1;
    while (i > 0) : (i -= 1) {
        if (input[i] == '=') {
            multiple_groups -= 1;
        } else {
            break;
        }
    }
    return multiple_groups;
}

pub fn main() !void {
    var memory_buffer: [1000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&memory_buffer);
    const allocator = fba.allocator();

    const stdout = std.io.getStdOut().writer();
    const text = "Testing some more stuff";
    const etext = "VGVzdGluZyBzb21lIG1vcmUgc3R1ZmY=";
    const base64 = Base64.init();
    const encoded_text = try base64.encode(allocator, text);
    const decoded_text = try base64.decode(allocator, etext);
    try stdout.print("Encoded text: {s}\n", .{encoded_text});
    try stdout.print("Decoded text: {s}\n", .{decoded_text});
}
