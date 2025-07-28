const std = @import("std");
const stdout = std.io.getStdOut().writer();
const stdin = std.io.getStdIn().reader();

pub fn main() !void {
    //try stdout.writeAll("Type your name\n");
    //var buffer: [20]u8 = undefined;
    //@memset(buffer[0..], 0);
    //_ = try stdin.readUntilDelimiterOrEof(buffer[0..], '\n');
    //try stdout.print("Your name is: {s}\n", .{buffer});

    var f = try std.fs.cwd().openFile("file.txt", .{});
    defer f.close();

    var buffered = std.io.bufferedReader(f.reader());
    var bufreader = buffered.reader();

    var file_buffer: [1000]u8 = undefined;
    @memset(file_buffer[0..], 0);
    _ = try bufreader.readAll(file_buffer[0..]);
    try stdout.print("File content: {s}\n", .{file_buffer});
    const cwd = std.fs.cwd();
    const file = try cwd.createFile("foo.txt", .{});
    // Don't forget to close the file at the end.
    defer file.close();
    // Do things with the file ...
    var fw = file.writer();
    _ = try fw.writeAll("Writing this line to the file\n");
}

fn readf() !void {
    const cwd = std.fs.cwd();
    const file = try cwd.createFile("foo.txt", .{ .read = true });
    defer file.close();

    var fw = file.writer();
    _ = try fw.writeAll("We are going to read this line\n");

    var buffer: [300]u8 = undefined;
    @memset(buffer[0..], 0);
    try file.seekTo(0);
    var fr = file.reader();
    _ = try fr.readAll(buffer[0..]);
    try stdout.print("{s}\n", .{buffer});
    //const cwd = std.fs.cwd();
    //try cwd.deleteFile("foo.txt");
    // copy files
    // try cwd.copyFile("foo.txt", "bar.txt");
    // https://ziglang.org/documentation/master/std/#std.fs.Dir
    //The position indicators of a file descriptor object can be changed (or altered) by using the “seek” methods from this file descriptor, which are: seekTo(), seekFromEnd() and seekBy(). These methods have the same effect, or, the same responsibility that the fseek()13 C function.
    //Considering that offset refers to the index that you provide as input to these “seek” methods, the bullet points below summarises what is the effect of each of these methods. As a quick note, in the case of seekFromEnd() and seekBy(), the offset provided can be either a positive or a negative index
    //seekTo() will move the position indicator to the location that is
    //offset bytes from the beginning of the file.
    //seekFromEnd() will move the position indicator to the location that is
    //offset bytes from the end of the file.
    //seekBy() will move the position indicator to the location that is
    //offset bytes from the current position in the file.
}
