# 10 · Dock badge and menu bar summary

**Phase:** P2 · **Status:** 🟡 built, needs checking

Design: [../designs/04-notifications.md](../designs/04-notifications.md)

Code: `macos/Sources/Features/Agent Tabs/AgentSummary.swift`

## Done

- [x] `AgentSummary` follows every tab (through
      `AgentTabBarModel.changesPublisher`, debounced) and lists the tabs with
      an agent, most urgent first.
- [x] Dock badge: agents waiting or done-unread, added to Ghostty's own bell
      count in `AppDelegate.setDockBadge` (which already handles badge
      permission).
- [x] Menu bar item while any agent runs: "● 1 waiting  ● 1 working" with
      state-colored dots (also lists error / done / idle when present). Its
      menu has one row per agent; choosing it selects the tab and focuses the
      split whose status the tab shows. "Hide Menu Bar Summary" at the end.
- [x] Settings: tab bar right-click → Dock Badge, Menu Bar Summary (both on
      by default, remembered).

- [x] Menu bar style (2026-10-24): Compact "●1 ●1" (the default, asked
      for by the user), Full "● 1 waiting  ● 1 working" (the design), or
      Icon Only (one dot, most urgent state); the full
      text is the tooltip. Chosen in the summary's own menu (Menu Bar Style),
      View › Agents in Menu Bar (Hidden / Full / Compact / Icon Only) and
      the tab bar's right-click menu. The summary only shows while an agent
      runs.

- [x] The summary's menu shows a card per agent: still face, tab title,
      state in its color and for how long, what it's doing, account dot,
      name, folder and branch. Click jumps to the tab and split.

## Verify

- [ ] On screen: badge count, menu bar item, jump to tab.
