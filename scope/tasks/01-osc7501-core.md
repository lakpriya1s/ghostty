# 01 · OSC 7501 from the core to the macOS app

**Phase:** P0 · **Status:** ✅ done and tested

## Goal

Ghostty reads OSC 7501 (Program Status Protocol) reports from programs and
passes them to the app as a `program_status` action.

## Done

- `src/termio/stream_handler.zig`: answers the support query (`OSC 7501 ; ?`)
  and forwards reports about the program itself (no `id`) to the surface.
- `src/apprt/surface.zig`: `Message.ProgramStatus`, a fixed-size copy of a
  report (state, kind, progress, app, title, msg).
- `src/Surface.zig`: turns the message into the `program_status` action.
- `src/apprt/action.zig` + `include/ghostty.h`: the action and its C types
  (`ghostty_action_program_status_s`). The C action union grew from 24 to 40
  bytes on 64-bit.
- GTK ignores the action for now.
- Test: `ProgramStatus init` in `src/apprt/surface.zig`.

## Verify

`zig build test -Dtest-filter=ProgramStatus` → all pass.

## Later

- Reports with an `id` (child records) are ignored. Needed for subagents (task 12).
