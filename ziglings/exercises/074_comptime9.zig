const std = @import("std");
const print = std.debug.print;

// We're going to (ab)use the power of Zig to make animal hybrid creatures!
// What do you think a GatorMouse would look like?  Eek.
//
// Let's try a MouseLlama instead.
//
// We'll make a function that runs at comptime and takes a short code describing
// the desired creature. A Mouse is represented by "m" and a Llama is "lm".
// A MouseLlama hybrid, then, would be represented by "mlm".

const Animal = enum {
    Mouse,
    Llama,
    Gator,
};

// makeCreature takes the count of animals making up the hybrid creature (so we
// know how big a pen we'll need) and a format string, like the "mlm" for
// MouseLlama.
fn makeCreature(comptime count: usize, comptime fmt: []const u8) [count]Animal {

    // Since not every animal is represented by a single character, we need to
    // track the state of things as we move along. For example, if we see an
    // "m", is that a new Mouse or the end of a Llama?
    const State = enum {
        start, // Ready to start a new animal.
        l, // This means we've seen an "l", so if we see an "m", we know it's a Llama.
    };
    var state = State.start;

    // We return an array of animals representing the creature. (This is why we
    // really needed the 'count' parameter. Arrays need a size.)
    var animals: [count]Animal = undefined;
    var next_animal: usize = 0;

    inline for (fmt) |char| {

        // This is a good spot to add a @compileLog() call if you need to debug
        // any variables... (Come back here after you see main().)

        switch (state) {
            .start => switch (char) {
                // We've seen the start of a Llama.
                'l' => state = .l,

                // Mice are smaller.  An "m" is a full Mouse.
                'm' => {
                    animals[next_animal] = .Mouse;
                    next_animal += 1;
                },

                // @compileError lets us stop the build immediately if something
                // is wrong. It's like @compileLog but it prints a message
                // instead of inspecting values.
                //
                // What do you think happens with Gators? Do they join with
                // other animals or is this an error?
                'g' => ???,

                else => @compileError(std.fmt.comptimePrint("No animal starts with '{c}'!", .{char})),
            },

            .l => switch (char) {
                // We've seen the end of a Llama.
                'm' => {
                    animals[next_animal] = .Llama;
                    next_animal += 1;
                    // Something is missing here. After we finish a Llama, we
                    // need to be ready to _start_ over with a new animal...
                    ???
                },

                else => @compileError("Only llamas start with 'l'!"),
            },
        }
    }

    if (state != .start) {
        @compileError("Oh no, an incomplete llama!");
    }
    if (next_animal != count) {
        @compileError("Creature is missing an animal (format string too short).");
    }

    return animals;
}

pub fn main() void {
    // Once you've fixed the ??? marks above, this makeCreature call will still
    // only succeed if you move it outside of main, so it will run at comptime.
    //
    // With the call here, Zig will try to make the creature at runtime, and
    // you'll get an interesting error.
    //
    // You may think the state got mixed up, but if you use @compileLog to check
    // some variables in makeCreature, you'll see that Zig is trying to compare
    // comptime values with "[runtime value]", which will never match.
    //
    // You can solve this by adding "comptime" to two of the variables in
    // makeCreature...
    const creature = makeCreature(2, "mlm");

    for (creature) |animal| {
        // @tagName gives us a string representing which variant of an enum we
        // have. This lets us print the names of animals without repeating them
        // here.
        print("{s}", .{@tagName(animal)});
    }
    print(" joins the crew!", .{});
}
