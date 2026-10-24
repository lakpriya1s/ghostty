# 13 · Context used, last message and git branch

**Phase:** P2 · **Status:** 🟡 built, needs checking

Design: [../designs/01-window-face-tabs.md](../designs/01-window-face-tabs.md#hover-card)

## Done (2026-10-23)

- [x] Two OSC 7501 extension keys, like `account`:
  - `context=<0-100>`: context window used. Read in any state.
  - `last=<base64>`: the agent's last reply, encoded and limited like `msg`.
  Parser, `Message.ProgramStatus` (`last` is 191 bytes), `apprt.action`
  (C union now 64 bytes on 64-bit, 36 on 32-bit), `ghostty.h`, Swift
  `ProgramStatus.context` / `.last`. Tests: `OSC 7501: context and last`,
  `ProgramStatus init`.
- [x] Hook: `last` from `Stop`'s `last_assistant_message`. No hook is told
  the context percent, so the hook reads the last reply's token counts
  (input + cache creation + cache read) from the transcript's last 200 lines
  and divides by the window: 1M for Opus 4.7+, Sonnet 5+, Haiku 5.5+ and
  `[1m]` models, otherwise 200k; `CLAUDE_CODE_MAX_CONTEXT_TOKENS` and
  `CLAUDE_CODE_DISABLE_1M_CONTEXT` respected. Needs `jq`. Sent with every
  report except `clear`.
- [x] Merge: a report without `context` / `last` keeps the terminal's
  previous ones (same app). Claude Code's own reports don't carry them.
- [x] Hover card: "Context used" + percent, 4pt bar (`#7db4ff`, `#f5a524`
  above 70%, track `#3a3d47`); last message in quotes, italic `#a8adb7`, on
  `#1c1d21`, radius 8, up to 3 lines. Each only shows when known.
- [x] Git branch: read by the app from the focused terminal's folder
  (`.git/HEAD`, worktree `.git` files too; short commit when detached),
  cached 5 s (`AgentGitBranch`). In the hover card footer and the Agents
  panel's TAB line (`Window 1 · tab 2 · feat/nav`).

## Verify

- [x] Hook output for `Stop`, `StopFailure`, `PostToolUse`; window size
  for ten model ids.
- [ ] On screen, after reinstalling the hook
  (`sh agents/claude-code/install.sh --all`) and restarting the dev app.
