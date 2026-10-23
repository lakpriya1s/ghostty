# 09 · `+` menu with accounts

**Phase:** P1 · **Status:** 🟡 built, needs checking

Design: [../designs/03-new-tab-menu.md](../designs/03-new-tab-menu.md)

Code: `macos/Sources/Features/Agent Tabs/AgentNewTabMenu.swift`

## Done

- [x] `+` opens the menu (a key-capable borderless panel styled like the
      design: 330pt, radius 12, `#26282f`, blue `#3b6fd8` hover). Click
      outside or Escape closes it; clicking `+` again closes it. ⌘T still
      opens a plain tab.
- [x] New Tab ⌘T, New Split ⌘D.
- [x] CLAUDE CODE section: one row per account (swatch, name,
      `~/folder · N running`, ⌥⌘N). The row opens a new tab in the focused
      terminal's folder with `CLAUDE_CONFIG_DIR` set for the tab and types
      `claude`, so the shell stays when Claude exits.
- [x] Folder choice (not in the design; asked for after the first try
      started Claude in the home folder and it asked to trust all of it):
      an "in ~/folder ⌄" row under CLAUDE CODE. Default: the terminal's
      folder, unless it's `~` or `/`, then the folder last chosen, then the
      most recent Claude project. The list shows the terminal's folder,
      recent Claude folders (from every account's `.claude.json` projects,
      ordered by their `projects/<name>` dates, leaving out `~`, config
      folders and missing ones) and Choose Folder…, which reopens the menu
      in the picked folder.
- [x] ⌥⌘1 … ⌥⌘9 for the first nine accounts (key codes, so any layout).
- [x] "N running" = tabs in all windows whose agent reports that account.
- [x] Add existing account… picks a config folder (hidden files shown).
- [x] New account… asks for a name, creates `~/.claude-<name>` with a
      `settings.json` that runs the status hook (as `install.sh` does; only
      if the hook is installed), adds the account and opens a tab running
      `claude` there to log in. An existing folder is left as it is.
- [x] Right-click an account row: Rename…, Color, Remove.
- [x] "Start in a new git worktree" (remembered; disabled outside a git
      repo): types `git worktree add -b agent/<MMdd-HHmmss>
      <repo>.worktrees/agent-<stamp> && cd … && claude`.
- [x] Codex / Gemini CLI disabled, "later".

## Verify

- [x] On screen (user screenshot): menu look, blue hover, folder row with
      "Change ⌄", "1 running" on an account.
- [ ] ⌥⌘1 shortcut, worktree option, New account…, Add existing account…, Rename.
