# 4 · Notifications and dock badge

Source: [source/Notify.dc.html](source/Notify.dc.html)

## When to notify

Only when the tab isn't the one you're looking at. Clicking a banner jumps
to that exact tab **and split**.

## Banners (macOS notifications)

- Icon: Ghostty `>_` with a small state-colored dot (amber waiting, green done).
- Title: `<tab> needs you` / `<tab> finished`
- Body: e.g. `Permission requested: Bash(npm test)` or
  `Updated CHANGELOG.md for v1.4 · took 4m 02s`
- Actions: **Open tab**, **Dismiss**

## Dock badge

Red count on the Ghostty dock icon: the number of agents that need attention
(waiting + done unread).

## Menu bar

A summary in the menu bar: `● 1 waiting  ● 1 working` (amber and blue dots).
