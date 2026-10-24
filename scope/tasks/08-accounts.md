# 08 · Account profiles and face rings

**Phase:** P1 · **Status:** 🟡 built, needs checking

Designs: [01](../designs/01-window-face-tabs.md), [02](../designs/02-agent-faces.md), [03](../designs/03-new-tab-menu.md)

## Goal

Support several Claude accounts, each a `CLAUDE_CONFIG_DIR`, and show which
account each tab uses.

## Done

- [x] **Protocol:** an `account` key in OSC 7501 (an extension; other
      terminals skip unknown keys). Parsed in
      `src/terminal/osc/parsers/program_status.zig` (a name like `app`, up to
      32 bytes) and carried through `Message.ProgramStatus`, the
      `program_status` action and `ghostty_action_program_status_s.account`.
      Tests: "OSC 7501: account", "ProgramStatus init".
- [x] **Hook** sends `account=<config folder name>`, e.g. `.claude-account1`,
      or `.claude` when `CLAUDE_CONFIG_DIR` isn't set.
- [x] **Account list** (`Features/Agent Tabs/AgentAccounts.swift`): id (the
      folder name), name, color, folder, saved in UserDefaults
      (`AgentAccounts`). Seeded on first use from every `~/.claude*` folder
      that holds a config (`settings.json`, `.claude.json` or `projects/`);
      an account first seen in a report is added then. Names: `.claude` →
      "default", `.claude-work` → "work".
- [x] **Colors:** each new account takes the next unused color: violet
      `#8b7cf6` and teal `#2dd4bf` (the design's Work and Personal), then
      pink, sand, lavender, white. None is a state color.
- [x] **Ring:** the slot's 2pt border in the account color, as in the design;
      transparent for shells and agents without an account.
- [x] **Tab background (default, asked for after seeing the ring):** the
      tab gets a light tint of the account color (8% over the bar, 14% on
      hover, 16% over the selected gray). A 3pt stripe along the edge was
      tried and removed at the user's request. A first try at
      16/26/42% was too strong: it drowned the faces and hid which tab was
      selected. Shells keep the gray highlight. The unread dot's cutout uses the same color. Tab bar
      right-click → Account Color → Tab Background / Ring switches back to
      the design's ring.
- [x] **Hover card footer:** account color dot · account name · folder.
- [x] **Change color:** right-click a face → Account Color.
- [x] **Installer** `--all` installs for every account folder.

## Verify

- Checked on the dev app by writing reports to its terminals' ttys: two
  accounts reported, six accounts saved with distinct colors, `.claude-monitor`
  (empty) skipped.
- [x] Ring on screen with a real Claude run (`CLAUDE_CONFIG_DIR=~/.claude-cc
      claude -p …` in the dev app): reports carry `account=.claude-cc`, sand
      ring drawn.
- [x] Ring in an interactive session (`claude` on account1 → teal ring,
      kept through working → done → idle), after the merge fix below and the
      hook's tty fix (task 02).
- [x] Hover card footer on screen: "● account1 · /Volumes/External/ghossty-new".

## Found: Claude Code reports its own status

Claude Code 2.1.309 has built-in OSC 7501 support. It probes with
`OSC 7501 ; ?`, and since this build answers, an interactive session sends its
own reports (`app=claude-code`, state, kind, progress, title, msg), but no
`account`. Those replaced the hook's reports, so the ring vanished (`claude -p`
doesn't report on its own, which is why the ring showed there). Claude
turns this off with `CLAUDE_CODE_DISABLE_TERMINAL_TITLE`.

Fix (`SurfaceView_AppKit.updateProgramStatus`): a report without an account
keeps the terminal's last account (same `app`); once the program has
reported on its own, a report with an account only sets the account and
leaves the state to the program. Without the program's own reports, the
hook's reports are used in full.

## Open

- Renaming accounts and choosing a folder for a new one: with the `+` menu's
  "Add account…" (task 09).
- Native-tabs position doesn't show the ring (its face is 16pt).
