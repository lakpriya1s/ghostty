# 07 · Dev build launches reliably

**Phase:** P0 · **Status:** ✅ done

## Problem

After a rebuild, `open zig-out/Ghostty.app` fails ("Launchd job spawn
failed", code 162; running the binary exits 137). `zig build` copies the new
app over the old one in place, and macOS keeps the old code signature cached
for that file, so it kills the new binary.

## Workaround

`rm -rf zig-out/Ghostty.app && cp -R macos/build/Debug/Ghostty.app zig-out/`,
or open `macos/build/Debug/Ghostty.app` directly.

## Done

- [x] `scripts/dev-run.sh` rebuilds the core only when `src/` or `include/`
      changed (or with `--core`), builds the app with xcodebuild, quits the
      running dev copy, waits for it to exit, and opens the new build.
      `--no-build` just restarts. It runs `macos/build/Debug/Ghostty.app`, so
      the `zig-out` signature problem never comes up.
