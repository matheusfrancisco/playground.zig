//
// Quiz Time — Async I/O!
//
// Doctor Zoraptera's insect simulation is going well, but she
// realized that her virtual garden needs weather data! Insects
// behave differently depending on temperature, humidity, and
// wind conditions.
//
// She has set up three weather sensors around the garden that
// measure conditions in parallel and report their readings
// through a shared data channel. A collector task gathers the
// readings, and after all sensors have reported, a garden
// report is printed.
//
// But Doctor Z rushed through the code (she was being chased
// by a grasshopper) and left several bugs. Can you fix them?
//
// Here's what the program should do:
//   1. Three sensor tasks send exactly 3 readings each through
//      a Queue
//   2. A collector task receives readings concurrently,
//      protected by a Mutex
//   3. After all sensors finish, the queue is closed
//   4. The final report is written in a cancel-protected section
//
// *************************************************************
// *                A NOTE ABOUT THIS EXERCISE                 *
// *                                                           *
// * This quiz uses concepts from exercises 085-094.           *
// * There are 6 bugs to fix — look for the ???s!              *
// *                                                           *
// *************************************************************
//
const std = @import("std");
const print = std.debug.print;

const SensorType = enum { thermometer, hygrometer, anemometer };

const Reading = struct {
    sensor_type: SensorType,
    value: i32,
};

const GardenWeather = struct {
    temperature: i32 = 0,
    humidity: i32 = 0,
    wind: i32 = 0,
    readings_count: u32 = 0,
    mutex: std.Io.Mutex = .init,

    fn addReading(self: *GardenWeather, io: std.Io, reading: Reading) void {
        // Bug 1: The collector needs to lock before modifying
        // shared state. What Mutex method acquires the lock?
        self.mutex.???(io) catch return;
        defer self.mutex.unlock(io);

        switch (reading.sensor_type) {
            .thermometer => self.temperature = reading.value,
            .hygrometer => self.humidity = reading.value,
            .anemometer => self.wind = reading.value,
        }
        self.readings_count += 1;
    }
};

pub fn main(init: std.process.Init) !void {
    const io = init.io;

    var weather = GardenWeather{};

    var reading_buf: [8]Reading = undefined;
    var queue: std.Io.Queue(Reading) = .init(&reading_buf);

    // The collector must run concurrently so it can process
    // readings while the sensors are still sending.
    // Start it FIRST to ensure its concurrency unit is reserved.
    //
    // Bug 2: The collector needs guaranteed concurrency.
    // What method ensures a separate unit of concurrency?
    // (Don't forget: it can fail!)
    var collector_future = try io.???(collector, .{ io, &queue, &weather });
    defer _ = collector_future.cancel(io);

    // Sensor group: the sensors can use async — they just need
    // to run, and async is more portable.
    var sensors: std.Io.Group = .init;

    sensors.async(io, sensor, .{ io, &queue, .thermometer, 20 });
    sensors.async(io, sensor, .{ io, &queue, .hygrometer, 60 });
    sensors.async(io, sensor, .{ io, &queue, .anemometer, 10 });

    // Bug 3: Wait for ALL sensors to finish sending their readings.
    // What Group method blocks until all tasks complete?
    try sensors.???(io);

    // All sensors done — close the queue so the collector knows
    // there's no more data coming.
    queue.close(io);

    // Bug 4: How do we wait for the collector to drain the remaining queue?
    _ = collector_future.???(io);

    // Now write the garden report. This is critical — it must
    // NOT be interrupted, even if something tries to cancel us!
    //
    // Bug 5: Protect this section from cancellation.
    // What Io method swaps the cancel protection state?
    const old_protection = io.???(.blocked);
    defer _ = io.???(old_protection);

    printGardenReport(&weather);
}

fn sensor(
    io: std.Io,
    queue: *std.Io.Queue(Reading),
    sensor_type: SensorType,
    base_value: i32,
) void {
    // Each sensor takes exactly 3 measurements.
    for (1..4) |i| {
        io.sleep(std.Io.Duration.fromMilliseconds(100), .awake) catch return;

        const reading = Reading{
            .sensor_type = sensor_type,
            .value = base_value + @as(i32, @intCast(i)),
        };

        // Bug 6: Send the reading into the queue.
        // What Queue method sends a single element?
        queue.???(io, reading) catch return;
    }
}

fn collector(
    io: std.Io,
    queue: *std.Io.Queue(Reading),
    weather: *GardenWeather,
) void {
    while (true) {
        const reading = queue.getOne(io) catch |err| switch (err) {
            error.Closed => break,
            error.Canceled => return,
        };
        weather.addReading(io, reading);
    }
}

fn printGardenReport(weather: *GardenWeather) void {
    print("=== Doctor Zoraptera's Garden Report ===\n", .{});
    print("Temperature : {}C\n", .{weather.temperature});
    print("Humidity    : {}%\n", .{weather.humidity});
    print("Wind        : {} km/h\n", .{weather.wind});
    print("Readings    : {}\n", .{weather.readings_count});

    if (weather.temperature > 20 and weather.wind < 15) {
        print("Bee-friendly conditions! Expect high pollination.\n", .{});
    } else {
        print("Grasshoppers will be grumpy today.\n", .{});
    }
}

// Further reading for the curious:
//
// This quiz covered the main async I/O primitives:
//   io.async()              - launch a task (may run inline)
//   io.concurrent()         - guaranteed unit of concurrency
//   Future.await/cancel     - collect or cancel a single task
//   Group.async/await/cancel - manage fire-and-forget tasks
//   Select.async/await      - race tasks, act on first completion
//   Queue                   - bounded channel between tasks
//   Mutex                   - protect shared state
//   CancelProtection        - shield critical sections
//
// There are more synchronization primitives we didn't cover:
//   Condition  - wait for a condition to become true
//   RwLock     - multiple readers OR one writer
//   Semaphore  - limit concurrent access to a resource
//   Futex      - low-level wait/wake on a memory address
//   Batch      - submit multiple I/O operations at once
//
// The key insight: all of these work through the Io VTable,
// so your code is portable across backends — whether Threaded
// (OS thread pool), or Evented (M:N green threads / fibers
// that can provide concurrency even on a single OS thread).
//
// Doctor Zoraptera approves.
