# 7 · Grid View (⌘⇧E)

Every tab of a window on one screen, as live terminals you can type in, so
there's no need to open separate windows and tile them by hand.

- **Turn on/off:** the grid button after `+` in the face tab bar (shown when
  the window has 2+ tabs), View › Show Tabs in Grid, or `⌘⇧E`.
- **Layout:** as square as possible: 2 → 2×1, 3–4 → 2×2, 5–6 → 3×2,
  7–9 → 3×3. A tab with splits keeps its splits inside its tile.
- **Tile header:** tab color dot · face · title · `⌘N` · expand · close.
- **Focus:** click a terminal to type in it. The focused tile gets a border
  in its tab color (accent if none); the others dim like unfocused splits.
  Clicking a face in the tab bar focuses that tile instead of switching tabs,
  and the bar marks the focused tile's tab.
- **Back to tabs:** the grid button / `⌘⇧E` (keeps the focused tab
  selected), the expand button, or double-clicking a tile header.
- New tabs opened in the grid join it. Closing a tile closes the tab.

Terminals in small tiles get fewer columns and re-wrap, as when a window is
resized; they get their full size back when the grid closes.

Implementation: `macos/Sources/Features/Terminal Grid/`.
