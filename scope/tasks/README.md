# Tasks

Status: ✅ done and tested · 🟡 built, needs checking · ⬜ not started

| #   | Task                                                        | Phase | Status |
| --- | ----------------------------------------------------------- | ----- | ------ |
| 01  | [OSC 7501 from the core to the macOS app](01-osc7501-core.md) | P0  | ✅     |
| 02  | [Claude Code hook and installer](02-claude-hook.md)         | P0    | ✅     |
| 03  | [Agent faces](03-faces.md)                                  | P0    | 🟡     |
| 04  | [Notifications](04-notifications.md)                        | P0    | 🟡     |
| 05  | [Face tab bar, top and left](05-face-tab-bar.md)            | P0    | 🟡     |
| 06  | [Hover card matches the design](06-hover-card.md)           | P0    | 🟡     |
| 07  | [Dev build launches reliably](07-dev-build.md)              | P0    | ⬜     |
| 08  | [Account profiles and face rings](08-accounts.md)           | P1    | ⬜     |
| 09  | [`+` menu with accounts](09-new-tab-menu.md)                | P1    | ⬜     |
| 10  | [Dock badge and menu bar summary](10-dock-menubar.md)       | P2    | ⬜     |
| 11  | [Agents panel and next waiting agent](11-agents-panel.md)   | P2    | ⬜     |
| 12  | [Subagent badge](12-subagents.md)                           | P2    | ⬜     |
| 13  | [Context used and last message](13-context-last-message.md) | P2    | ⬜     |
| 14  | [Other agents](14-other-agents.md)                          | P3    | ⬜     |
| 15  | [Linux (GTK) app](15-linux.md)                              | P3    | ⬜     |

Work happens on the `agent-tabs` branch. Build with `zig build`; the app is
at `zig-out/Ghostty.app` (see task 07 if it won't launch).
