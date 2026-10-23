# 04 · Notifications

**Phase:** P0 · **Status:** 🟡 built, not checked by the user yet

Design: [../designs/04-notifications.md](../designs/04-notifications.md)

## Done

When a terminal enters waiting, done or error and you're not looking at it,
a macOS notification is sent ("Claude Code needs you", "… finished",
"… stopped with an error") with the message as body. Uses Ghostty's existing
notifications, so clicking focuses that surface.

## To do

- [ ] Check it on screen: run the demo, switch tabs, see the banners.
- [ ] Title should name the tab (e.g. "web · refactor nav needs you").
- [ ] "Open tab" / "Dismiss" actions.
- [ ] "took 4m 02s" on finished notifications.
- [ ] Respect the `desktop-notifications` config.
