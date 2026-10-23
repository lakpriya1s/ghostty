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
- [ ] Idle "z" should fade in and out (static now).
- [ ] Unread dot border should match the bar background.
- [ ] Check CPU use with many animating tabs.
