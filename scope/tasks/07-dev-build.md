# 07 · Dev build launches reliably

**Phase:** P0 · **Status:** ⬜ not started

## Problem

After a rebuild, `open zig-out/Ghostty.app` fails ("Launchd job spawn
failed", code 162; running the binary exits 137). `zig build` copies the new
app over the old one in place, and macOS keeps the old code signature cached
for that file, so it kills the new binary.

## Workaround

`rm -rf zig-out/Ghostty.app && cp -R macos/build/Debug/Ghostty.app zig-out/`,
or open `macos/build/Debug/Ghostty.app` directly.

## To do

- [ ] A small `scripts/dev-run.sh` that builds, replaces the app cleanly,
      quits the running dev copy and opens the new one.
