# simple watcher e.g 

 Structure: src/fs_watcher.zig is now 23 lines: WaitResult, a Backend enum, and the comptime selection. The backends moved to their own files using the file-as-struct
  pattern (const Linux = @This(); with fields at top level), so each file is its watcher type:

  - src/watcher/linux.zig: the fanotify backend, unchanged in behavior
  - src/watcher/macos.zig: the FSEvents backend with all the CoreServices FFI now out of the shared file
  - src/watcher/poll.zig: new portable fallback: each wait() sleeps, rescans the tree, and compares an order-independent snapshot hash (Wyhash of each entry's path + size +
  mtime, combined with wrapping add; directories hash their existence so empty-dir create/delete is caught)

  No wrapper struct: as the follow-up suggested, Watcher is now just the selected type directly. WatcherImpl(comptime backend: Backend) type does the selection, with .auto
  dispatching on builtin.os.tag; since the poll backend exists, unsupported OSes now fall back to it instead of @compileError. Watcher = WatcherImpl(.auto) keeps call sites
  unchanged.

  The build flag: `-Dwatch-backend={auto,fanotify,fsevents,poll}` via `b.addOptions()`, wired only into the exe's root module per the reusable-library caveat. main.zig
  translates the generated enum into the library's Backend with an exhaustive switch, so the two enums drifting apart is a compile error, and prints the active backend at
  startup.

  One correction to the advice: std.posix.close doesn't exist in Zig 0.16 (file closing went through std.Io.File), which is why the original closeFd switch was there. The
  helper still died in the refactor Linux code in its own file just calls std.os.linux.close directly, no switch.

  Verified: all four build configs pass (native auto, native poll, x86_64-linux auto, x86_64-linux -Dwatch-backend=fanotify the cross-builds proving the unselected backend
  files are never analyzed), zig build test passes, and I ran both the poll and FSEvents backends against a scratch directory both detected a file append (and poll also
  caught a new empty directory) while staying quiet during idle periods.
