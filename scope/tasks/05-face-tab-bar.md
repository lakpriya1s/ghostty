# 05 · Face tab bar, top and left

**Phase:** P0 · **Status:** 🟡 built, needs checking against the design

Design: [../designs/01-window-face-tabs.md](../designs/01-window-face-tabs.md)

## Done

`macos/Sources/Features/Agent Tabs/AgentTabBar.swift`:
- Native macOS tab bar hidden; tabs drawn as faces (no text), even with one tab.
- Top or left, face size Small / Medium / Large, both from the bar's
  right-click menu and remembered. "Native macOS Tabs" brings the old bar back.
- Selected and hover highlights, dashed `+`, right-click "Close Tab".
- Tabs are still native window tabs: ⌘T, ⌘W, ⌘1–9, restore all work.

## Matched to the design (build of 2026-10-23)

- [x] Face 40pt at M (S 0.8×, L 1.25×), slot face + 18, button padding 5,
      radius 14.
- [x] Bar `#22242a`, selected `#363944`, hover `#2c2e35`, 1px `#2e3038`
      divider; padding 8/10 (top) and 12/8 (left); 6pt gap.
- [x] Dashed round `+` at 0.7× the slot, hover colors.
- [x] Bar shows from the start, even with one tab. Confirmed on screen.
- [x] Native tab bar stays hidden when tabs are added. Confirmed on screen.
- [x] Window title hidden, title bar shows only the window buttons.
- [x] Account color: tab tint, or ring as an option (task 08).
- [x] Subagent badge (task 12; needs checking on screen there).
- [x] Top position checked on screen.
- [ ] Left position checked on screen.
- [ ] Bottom and Right positions checked on screen.
- [ ] Hover card checked on screen (task 06).

## Later

- Drag faces to reorder; drag a face out to a new window.
- Hold ⌘ to show 1–9 on the faces.

## Title bar (2026-10-23)

- Top and Left show the window title in the title bar again (it was hidden
  for the design's buttons-only title bar).
- New position **Title Bar** (right-click the bar): faces in the title bar
  after the window buttons, the selected tab's title after `+`, empty space
  drags the window (double-click zooms or minimizes per the system
  setting). The window gets `.fullSizeContentView` and a transparent title
  bar while it's on (`TerminalWindow.syncAgentTabBarInTitlebar`), undone when
  switching away; the transparent style clears its painted title bar
  background. Falls back to Top for the `tabs` and `hidden` title bar styles
  and in full screen. Departure from the design, asked for by the user.
- [x] Checked on screen by the user (2026-10-23).
- New positions **Bottom** and **Right** (bar's right-click menu and
  View › Agent Tab Bar). The bar's border faces the terminal, and the hover
  card and `+` menu open away from the bar: above it at the bottom, to its
  left on the right.
