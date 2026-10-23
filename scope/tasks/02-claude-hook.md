# 02 · Claude Code hook and installer

**Phase:** P0 · **Status:** ✅ done and tested

## Goal

Claude Code reports its state to Ghostty through hooks.

## Done

- `agents/claude-code/ghostty-agent-status`: maps hook events to OSC 7501 and
  writes to the terminal. Does nothing outside Ghostty.
  - `SessionStart` → idle, `UserPromptSubmit` / `PreToolUse` / `PostToolUse`
    → working, `Notification` → waiting (permission or question),
    `Stop` → done, `SessionEnd` → clear.
  - Title = project folder name; message = prompt or tool + detail;
    account = config folder name (task 08).
- `agents/claude-code/install.sh [--uninstall] [--all | config folders…]`:
  copies the hook to `~/.config/ghostty/agents/claude-code/` and adds it to
  each folder's `settings.json`. `--all` finds every `~/.claude*` config
  folder. The original is kept once as `settings.json.before-ghostty` (it
  used to write `settings.json.bak`, which would have overwritten a backup
  already in `~/.claude`). Safe to run twice.
- `agents/demo-states.sh`: cycles a tab through every state.

## Verify

- Hook output checked for each event.
- Installer tested on a scratch home: install, reinstall, uninstall, `--all`
  skips empty folders, an existing `settings.json.bak` is left alone.

## Open

- Not yet installed into the real Claude folders. Claude Code's permission
  check blocks the agent from editing them, so run it yourself:
  `agents/claude-code/install.sh --all`.
- Fixed: the face stayed on "working" after `claude -p` exited (no final
  report reached the tab). The app now clears a terminal's status when shell
  integration reports the command finished (`commandFinished` in
  `Ghostty.App.swift`), so an agent that crashes, is interrupted or skips its
  last report doesn't leave a stale face.
- Fixed: in interactive sessions Claude Code starts hooks without a
  controlling terminal, so writing to `/dev/tty` failed silently and no hook
  report arrived (only Claude's own OSC 7501 reports, see task 08). Hook runs
  were confirmed with `claude --debug-file` (all exit 0). The hook now falls
  back to the terminal of the nearest parent process that has one (Claude
  Code). `claude -p` worked before because its hooks keep the terminal.
- `StopFailure` (the turn ended on an API error) maps to `error`, with
  `error_details` (or `Error: <error>`) as the message. Registered by the
  installer, so rerun it. `Stop` also sends `last`, and every report sends
  `context` (task 13).
