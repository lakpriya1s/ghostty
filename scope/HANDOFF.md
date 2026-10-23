# Handoff

Everything needed to pick this work up cold. Read this, then
[README.md](README.md) (scope) and [tasks/README.md](tasks/README.md) (status).

_Last updated: 2026-10-23._

## What this is

A fork of Ghostty where each tab is an animated **face** showing what the
coding agent inside it is doing (idle, working, waiting on you, done, error).
Claude Code first; other agents later through the same protocol.

- Repo: https://github.com/lakpriya1s/ghostty, branch **`agent-tabs`**
  (upstream remote: `ghostty-org/ghostty`)
- Design canvas: https://claude.ai/artifact/GqsEQ9WZbmCBrk5RGNcBKX
  (copied into [designs/](designs/README.md); open `designs/canvas-export.html`
  in a browser)

## Where it stands

**Working and confirmed on screen**

- OSC 7501 status reports reach the macOS app (core tests pass).
- Face tab bar at the top replaces the native macOS tabs, shows from the start
  with one tab, and the native bar stays hidden as tabs are added.
- Faces animate per state; the demo script cycles them.

**Built, not yet confirmed on screen**

- Hover card (task 06), left position and S/M/L sizes (task 05),
  notifications (task 04).
- Claude Code hook in real use: the installer was only tested on a scratch
  folder, not run on the real `~/.claude*` folders.

**Not started:** accounts and face rings, `+` menu, dock badge, Agents panel,
subagent badge, context / last message, other agents, Linux. See
[tasks/README.md](tasks/README.md).

## Build and run

One-time setup on this Mac (already done):

```sh
brew install zig                              # needs Zig 0.17.0
xcodebuild -downloadComponent MetalToolchain  # Xcode's Metal compiler
```

After changing anything in `src/` (Zig core) or `include/ghostty.h`:

```sh
zig build -Demit-macos-app=false   # rebuilds the library the app links
```

After any change (Swift or core):

```sh
cd macos && xcodebuild -target Ghostty -configuration Debug
```

Run it (quit the running dev copy first, or the old one keeps running):

```sh
A=/Volumes/External/ghossty-new/macos/build/Debug/Ghostty.app
osascript -e "tell application \"$A\" to quit"
open "$A"
```

Tests: `zig build test -Dtest-filter=ProgramStatus`

See it work without Claude: run `agents/demo-states.sh` in a tab.

## Gotchas

- **Don't launch `zig-out/Ghostty.app` after a plain `zig build`.** That build
  copies the app over the old one in place, macOS keeps the old code signature
  cached, and the launch fails ("Launchd job spawn failed", code 162; the
  binary exits 137). Use `macos/build/Debug/Ghostty.app`, which is what the
  repo's `macos/AGENTS.md` says anyway. Fix: `rm -rf zig-out/Ghostty.app` and
  copy it again. Task 07.
- **Two builds at once collide** on the Sparkle package download. Run one.
- **`macos/build.nu`** (the official app build script) needs `nu`, which isn't
  installed; the `xcodebuild` command above is what it runs.
- **SwiftLint isn't installed**, so Swift lint hasn't been run
  (`brew install swiftlint`, then `swiftlint lint --strict` in `macos/`).
- **SourceKit errors in the editor** ("Cannot find type 'Ghostty' in scope")
  are the indexer lacking project context. The Xcode build is the real check.
- **Screenshots:** the agent can't capture the screen on this Mac, so visual
  checks need screenshots from the user.

## How it fits together

```
Claude Code hook ──OSC 7501──▶ core (Zig) ──program_status action──▶ macOS app
```

| Layer | Files |
| --- | --- |
| Hook + installer | `agents/claude-code/ghostty-agent-status`, `agents/claude-code/install.sh`, `agents/demo-states.sh` |
| Core: parse → app | `src/termio/stream_handler.zig` (forward + query reply), `src/apprt/surface.zig` (`Message.ProgramStatus` + test), `src/Surface.zig`, `src/apprt/action.zig` (`ProgramStatus` action, C union size 24 → 40), `include/ghostty.h`, `src/apprt/gtk/class/application.zig` (ignored on Linux) |
| Swift model | `macos/Sources/Ghostty/Ghostty.Action.swift` (`ProgramStatus`), `Ghostty.App.swift` (action → surface), `Surface View/OSSurfaceView.swift` (`programStatus`), `Surface View/SurfaceView_AppKit.swift` (update, notifications, "seen" on focus/typing) |
| Per tab | `Features/Terminal/BaseTerminalController.swift` (most urgent status of all splits, `createdAt`, `agentTabBar` hook) |
| UI | `Features/Agent Tabs/AgentFaceView.swift` (faces), `Features/Agent Tabs/AgentTabBar.swift` (settings, model, bar, hover card panel), `Features/Terminal/TerminalView.swift` (bar placement), `Features/Terminal/TerminalController.swift` (owns the model), `Window Styles/TerminalWindow.swift` (hides native tab bar and title) |

Key decisions in the code:

- Tabs are still **native macOS window tabs**; the face bar only redraws them,
  so ⌘T / ⌘W / ⌘1–9 / restore all keep working.
- The native bar is hidden by setting its titlebar accessory's `isHidden`
  (in `TerminalWindow.addTitlebarAccessoryViewController` and
  `syncNativeTabBarVisibility`). `toggleTabBar` did not work.
- `agentTabBar` must be declared on `BaseTerminalController` (where the
  `TerminalViewModel` conformance is) and overridden in `TerminalController`;
  declaring it only on the subclass silently used the protocol default (nil).
- The hover card is a borderless, non-activating child panel
  (`AgentTabCardPanel`) so it can draw over the terminal without taking focus.
- Settings (position, face size) live in `UserDefaults`, changed from the
  bar's right-click menu. Not Ghostty config keys yet.

## Next steps

1. Confirm the hover card and left position on screen; fix differences
   (tasks 05, 06).
2. Run the installer on the real Claude folders and try a real session
   (task 02), then check notifications (task 04).
3. Accounts and face rings (task 08), then the `+` menu (task 09).

## Rules from the repo

- `AGENTS.md`: never create issues or PRs; format Zig with `zig fmt`, Swift
  with `swiftlint`.
- `macos/AGENTS.md`: build the app with `macos/build.nu` / xcodebuild, not
  `zig build`.
- Commit messages end with the co-author line used in this branch's commits.
