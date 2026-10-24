# 04 · Notifications

**Phase:** P0 · **Status:** ✅ done and tested

Design: [../designs/04-notifications.md](../designs/04-notifications.md)

## Done

When a terminal enters waiting, done or error and you're not looking at it,
a macOS notification is sent ("Claude Code needs you", "… finished",
"… stopped with an error") with the message as body. Uses Ghostty's existing
notifications, so clicking focuses that surface.

## To do

- [x] Seen on screen (2026-10-23): "needs you" and "finished" banners.
- [x] Title names the tab ("web · refactor nav needs you"), no subtitle.
- [x] "Open tab" / "Dismiss" actions (category `agentNotificationCategory`).
- [x] "took 4m 02s" on finished notifications, from when the request
      started working (time waiting on the user included).
- [x] Respects the `desktop-notifications` config.
- [x] `>_` image with a state-colored dot (`AgentNotificationIcon`). macOS
      always shows the app icon, so it's an attachment on the right.

## Notes

- The dev build is its own app to macOS (`com.mitchellh.ghostty.debug`):
  its notifications were off in System Settings. `log show` with
  `process == "NotificationCenter"` says `notificationsAllowed: false`.
- Test in a terminal without Claude running: once Claude reports its own
  status, test reports only set the account, context and last message.
