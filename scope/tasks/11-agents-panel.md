# 11 · Agents panel and next waiting agent

**Phase:** P2 · **Status:** 🟡 built, needs checking

Design: [../designs/05-agents-panel.md](../designs/05-agents-panel.md)

Code: `macos/Sources/Features/Agent Tabs/AgentsPanel.swift`

## Done

- [x] ⌘⇧A toggles a 748×488 floating panel (the design's size inside its
      36pt margin), centered a little above the middle of the active window.
      Escape or clicking elsewhere closes it.
- [x] Filter field (focused on open; matches title, doing, location,
      account, state) and chips All N · Waiting N · Working N · Done N.
- [x] Columns: face (24pt, the design's 0.6 scale) · TAB (title +
      `Window 1 · tab 2`) · DOING (amber when waiting, gray when idle) ·
      ACCOUNT (3×14 color bar + name) · TIME (live, tabular digits).
- [x] Sorted by urgency, then window and tab. ↑/↓ select, Enter or click
      jumps to the tab and split. Updates every second while open.
- [x] Footer: `↵ jump to tab` · `⌘J next waiting agent` · `N agents · N windows`.
- [x] ⌘J jumps to the next agent waiting on you, cycling. With none
      waiting, ⌘J keeps Ghostty's default (scroll to selection).

## Open

- Git branch in the TAB line (`Window 1 · tab 2 · feat/nav`): added with
  task 13, needs checking on screen.

## Verify

- [ ] On screen: look vs. the design, filter, keyboard, jump, ⌘J.
