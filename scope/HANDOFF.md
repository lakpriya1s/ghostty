# Handoff

Everything needed to pick this work up cold. Read this, then
[README.md](README.md) (scope) and [tasks/README.md](tasks/README.md) (status).

_Last updated: 2026-10-23 (evening)._

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

**Committed, not pushed:** tasks 07–13 are in five commits after
`f2d33a991` on `agent-tabs` (core, macos, hook, dev script, scope). Ask the
user before pushing.

**Working and confirmed on screen**

- Face tab bar at the top replaces the native tabs (task 05); faces animate
  (task 03); hover card with account footer (tasks 06, 08).
- Real Claude Code sessions drive the faces: hook installed in all six
  `~/.claude*` folders (task 02).
- Accounts: tab background tinted with the account color, interactive and
  `-p` sessions (task 08). The face goes back to `>_` when Claude exits.
- `+` menu with accounts and a folder picker (task 09).
- `scripts/dev-run.sh` (task 07).

**Built, needs checking on screen:** left position and S/M/L (05),
notifications (04), dock badge and menu bar summary (10), Agents panel ⌘⇧A
and ⌘J (11), subagent badge (12), ⌥⌘1–9, worktree option, Add account….

**Built, needs the hook reinstalled and checking on screen:** context used,
last message and git branch in the hover card and Agents panel, `StopFailure`
→ error (13).

**Not started:** other agents (14), Linux (15). See [tasks/README.md](tasks/README.md).
## Build and run

One-time setup on this Mac (already done):

```sh
brew install zig                              # needs Zig 0.17.0
xcodebuild -downloadComponent MetalToolchain  # Xcode's Metal compiler
```

Build and restart in one step (rebuilds the core only when `src/` or
`include/` changed):

```sh
scripts/dev-run.sh             # --core to force a core rebuild, --no-build to just restart
```

Or by hand. After changing anything in `src/` (Zig core) or `include/ghostty.h`:

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
  binary exits 137). Use `macos/build/Debug/Ghostty.app` (what
  `scripts/dev-run.sh` runs, and what `macos/AGENTS.md` says anyway).
- **Restarting the dev app closes the user's Claude sessions in it.** Check
  first (`ps -t <tty>` for each terminal's tty, from AppleScript) and ask, or
  let the user run `scripts/dev-run.sh --no-build`.
- **Launching the dev app from a Claude Code session** passes Claude's
  `CLAUDE_*` variables to every terminal in it: `claude` there turns off
  transcript saving ("inherited CLAUDE_CODE_CHILD_SESSION marker"), which
  also loses the context bar, and `CLAUDE_CONFIG_DIR` pins every tab to one
  account. `scripts/dev-run.sh` strips them; a bare `open` doesn't.
- **Don't launch a second copy** (`open -n`) to test: it restores the user's
  windows, and they may start working in it.
- **The agent can't edit `~/.claude*/settings.json`** (Claude Code's permission
  check blocks it as persistence). The user runs the installer:
  `sh /Volumes/External/ghossty-new/agents/claude-code/install.sh --all` on
  one line (a wrapped paste runs without `--all`).
- **Two builds at once collide** on the Sparkle package download. Run one.
- **`macos/build.nu`** (the official app build script) needs `nu`, which isn't
  installed; the `xcodebuild` command above is what it runs.
- **SwiftLint** is installed (Homebrew): `swiftlint lint --strict` in
  `macos/` passes. **Prettier isn't installed**, so Markdown isn't formatted.
- **The deployment target is below macOS 14**: e.g. `NSMenuItem.sectionHeader`
  doesn't build.
- **SourceKit errors in the editor** ("Cannot find type 'Ghostty' in scope")
  are the indexer lacking project context. The Xcode build is the real check.
- **Screenshots:** capture only the dev app's window, never the whole screen
  (it shows the user's other apps): get its window number with
  `CGWindowListCopyWindowInfo` for the app's pid, then
  `screencapture -x -o -l <number> out.png`. Drive it with AppleScript
  (`input text … to terminal id "<id>"`, then `send key "enter"`; pasted text
  waits for Enter). `log` is a zsh builtin; use `/usr/bin/log show`.
- **Debugging hooks:** `claude --debug-file <path>` logs every hook run and its
  exit status.
## How it fits together

```
Claude Code ──its own OSC 7501 (state, subagent child records)──┐
Claude Code hook ──OSC 7501 (state + account)───────────────────┤
                                                                ▼
            core (Zig) ──program_status action──▶ macOS app (per terminal, per tab, summary)
```

| Layer | Files |
| --- | --- |
| Hook + installer | `agents/claude-code/ghostty-agent-status`, `agents/claude-code/install.sh` (`--all`), `agents/demo-states.sh` |
| Core: parse → app | `src/terminal/osc/parsers/program_status.zig` (adds the `account`, `context`, `last` keys), `src/termio/stream_handler.zig` (forwards root and child reports, query reply), `src/apprt/surface.zig` (`Message.ProgramStatus` with `account`, `id` + test), `src/Surface.zig`, `src/apprt/action.zig` (C union 64 bytes on 64-bit), `include/ghostty.h`, `src/apprt/gtk/class/application.zig` (ignored on Linux) |
| Swift model | `Ghostty/Ghostty.Action.swift` (`ProgramStatus`), `Ghostty.App.swift` (action → surface; clears on command finished), `Surface View/OSSurfaceView.swift` (`programStatus`, `programChildren`), `Surface View/SurfaceView_AppKit.swift` (merge rules, children, notifications, "seen") |
| Per tab | `Features/Terminal/BaseTerminalController.swift` (most urgent status, `subagentCount`, `createdAt`, `agentTabBar`) |
| UI (`Features/Agent Tabs/`) | `AgentFaceView.swift` (faces), `AgentTabBar.swift` (settings, model, bar, tint, badge, hover card), `AgentAccounts.swift` (account store), `AgentNewTabMenu.swift` (`+` menu, launcher, ⌥⌘1–9, folder picker), `AgentSummary.swift` (dock badge, menu bar), `AgentsPanel.swift` (⌘⇧A, ⌘J) |
| Window | `Features/Terminal/TerminalView.swift` (bar placement), `TerminalController.swift` (owns the model, installs shortcuts), `Window Styles/TerminalWindow.swift` (hides native tab bar and title), `App/AppDelegate.swift` (dock badge count, starts the summary) |
| Dev | `scripts/dev-run.sh` |

Key decisions in the code:

- Tabs are still **native macOS window tabs**; the face bar only redraws them,
  so ⌘T / ⌘W / ⌘1–9 / restore all keep working.
- The native bar is hidden by setting its titlebar accessory's `isHidden`
  (in `TerminalWindow.addTitlebarAccessoryViewController` and
  `syncNativeTabBarVisibility`). `toggleTabBar` did not work.
- `agentTabBar` must be declared on `BaseTerminalController` (where the
  `TerminalViewModel` conformance is) and overridden in `TerminalController`;
  declaring it only on the subclass silently used the protocol default (nil).
- **Two reporters.** Claude Code 2.1.309 sends its own OSC 7501 once Ghostty
  answers its `?` probe (no account; subagents as child records `id=<agent
  id>`). The hook adds the account. A report without an account keeps the
  last one; once the program reports itself, the hook only sets the account.
- **Hooks have no controlling terminal** in interactive sessions, so the hook
  writes to the tty of its nearest parent that has one (Claude Code).
- A terminal's status is cleared when shell integration reports the command
  finished, so a crashed or interrupted agent doesn't leave a stale face.
- `AgentTabBarModel.setNeedsRefresh()` is the hub every change goes through;
  the summary listens to `changesPublisher`.
- Popovers (hover card, `+` menu, Agents panel) are borderless child panels;
  the menu and Agents panel can become key, the hover card can't.
- Settings (position, face size, account style, dock badge, menu bar, last
  folder, worktree) live in `UserDefaults`, from the bar's right-click menu.
  Accounts too (`AgentAccounts`). Not Ghostty config keys yet.
- Departures from the design, asked for by the user: account color is a tab
  tint, not a ring (ring kept as an option); the `+` menu has a folder row.
## Next steps

1. The user checks on screen: tint strength, subagent badge, ⌘⇧A, ⌘J,
   menu bar and dock badge, left position, notifications.
2. Reinstall the hook (`sh agents/claude-code/install.sh --all`, adds
   `StopFailure`) and check task 13 on screen.
3. Push when the user asks. Then task 14 (other agents).

Testing without the user: AppleScript gives each dev-app terminal's tty
(`tell application "<path>/Ghostty.app" to get tty of every terminal`), and
writing an OSC 7501 report to that tty updates its tab, just like the hook.
## Rules from the repo

- `AGENTS.md`: never create issues or PRs; format Zig with `zig fmt`, Swift
  with `swiftlint`.
- `macos/AGENTS.md`: build the app with `macos/build.nu` / xcodebuild, not
  `zig build`.
- Commit messages end with the co-author line used in this branch's commits.
