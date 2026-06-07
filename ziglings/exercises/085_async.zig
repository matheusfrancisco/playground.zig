//
// In previous versions of Zig, async/await used special keywords
// like 'suspend', 'resume', and 'async' that operated on stackframes
// directly. Those keywords no longer exist!
//
// Zig 0.16 replaced them with a unified I/O interface: std.Io.
// This interface uses a VTable pattern - a struct of function pointers -
// to abstract over different concurrency backends:
//
//   * Threaded  - thread-pool based I/O
//   * Evented   - chooses the best event-loop backend for your OS:
//       * Uring    on Linux (io_uring)
//       * Kqueue   on BSD/macOS
//       * Dispatch on macOS (Grand Central Dispatch)
//
// The Io struct itself is tiny:
//
//     const Io = struct {
//         userdata: ?*anyopaque,   // opaque state of the backend
//         vtable: *const VTable,   // table of function pointers
//     };
//
// Your code receives an Io value and calls methods on it.
// The backend is chosen at initialization time - your code doesn't
// need to know which one it is!
//
// In Zig 0.16, main() receives a std.process.Init struct to opt
// into I/O and concurrency support:
//
//     pub fn main(init: std.process.Init) !void {
//         const io = init.io;
//         // ... use io ...
//     }
//
// Let's start simple. Fix the main function to extract the Io
// interface from init, then use it to get the current time.
//
const std = @import("std");

pub fn main(init: std.process.Init) !void {
    const io = init.???;

    // Get the current wall-clock time using the Io interface.
    // Hint: Timestamp.now() takes an Io and a Clock type (.real = wall clock).
    const timestamp = std.Io.Timestamp.now(io, .real);

    // Print the timestamp in seconds since the Unix epoch.
    std.debug.print("Current time: {}s since epoch\n", .{timestamp.toSeconds()});
}
