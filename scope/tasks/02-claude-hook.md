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
  - Title = project folder name; message = prompt or tool + detail.
- `agents/claude-code/install.sh [--uninstall] [config folders…]`: copies the
  hook to `~/.config/ghostty/agents/claude-code/` and adds it to each folder's
  `settings.json` (backed up first, safe to run twice).
- `agents/demo-states.sh`: cycles a tab through every state.

## Verify

- Hook output checked for each event.
- Installer tested on a scratch folder: install, reinstall, uninstall.

## Open

- Not yet installed into the real Claude folders (`~/.claude`,
  `~/.claude-account1`, `~/.claude-account2`, …). Run the installer when ready.
- No "error" mapping yet: find which hook or signal shows an API error.
