# 03 · Agent faces

**Phase:** P0 · **Status:** 🟡 built, needs checking against the design

Design: [../designs/02-agent-faces.md](../designs/02-agent-faces.md)

## Done

`macos/Sources/Features/Agent Tabs/AgentFaceView.swift`: all six faces drawn
on the 40×40 grid with the design's colors; working (moving eyes, spinner)
and waiting (bounce, pulse) animate; "z" on idle, "?" on waiting, unread dot
on done.

## To do

- [ ] Compare side by side with the design at S / M / L.
- [x] Idle "z" fades in and out and drifts (2.6s, already built; the note
      saying it was static was out of date).
- [x] Unread dot border: cut out of the tab's actual background (selected,
      hovered and account-tinted included).
- [x] CPU (2026-10-24, debug build): a still face costs nothing; any
      animating face costs ~14% of the main thread, because every frame
      lays out the whole window (`NSHostingView.layout`). The cost is per
      frame, not per face. Now faces only move when someone can see them
      (`AgentFaceView.Motion`, set by `AgentTabBarModel.faceMotion`):
      everything while Ghostty is active, only working and waiting while
      it's in the background, nothing while the window isn't visible
      (covered, minimized, other space, screen locked). Measured: 0% with
      the screen locked.
- [ ] Measure with Ghostty active and in the background but visible.
- [ ] Later, if needed: draw faces in their own layer so a frame doesn't
      lay out the window.
