# Ghostty Agent Tabs — Scope

A fork of [Ghostty](https://github.com/ghostty-org/ghostty) for AI-native
developers. Every tab shows what the coding agent inside it is doing, so you
never lose track of an agent that is working, finished, or waiting on you.

- Fork: https://github.com/lakpriya1s/ghostty (branch `agent-tabs`)
- Design canvas: https://claude.ai/artifact/GqsEQ9WZbmCBrk5RGNcBKX
- Designs, copied here: [designs/](designs/README.md)
- Task list: [tasks/](tasks/README.md)
- Handoff (build, gotchas, where things are): [HANDOFF.md](HANDOFF.md)

## The problem

Developers run several agents (Claude Code, later others) in many terminal
tabs. They miss the tab that finished, or the one blocked on a permission
prompt, because nothing on the tab says what is happening inside it.

## The idea

- Tabs become **faces**, no text. Hover a face for details.
- Each face shows the agent's **state** with color, expression and motion.
- The tab bar can sit on the **top** or the **left**, with S/M/L face sizes.
- **Notifications** when an agent finishes or needs you while you're elsewhere.
- **Multiple Claude accounts**, each with its own color (ring on the face).
- Built on an open protocol, so other agents can be added later.

## States

| State          | Face                                   | Claude Code hook              |
| -------------- | -------------------------------------- | ----------------------------- |
| Idle           | Gray, eyes closed, "z"                 | `SessionStart`, after read    |
| Working        | Blue, eyes moving, spinner ring        | `UserPromptSubmit`, tool use  |
| Waiting on you | Amber, surprised, bouncing, "?"        | `Notification`                |
| Done (unread)  | Green, happy, white dot until seen     | `Stop`                        |
| Error          | Red, X eyes                            | API or session error (TBD)    |
| Plain shell    | Gray `>_` square                       | none                          |

A tab with splits shows its most urgent state:
waiting > error > done > working > idle.

## How it works

```
Claude Code ──hooks──▶ ghostty-agent-status ──OSC 7501──▶ Ghostty core (Zig)
                                                              │ program_status action
                                                              ▼
                                   macOS app: face tab bar · hover card · notifications
```

- **Protocol:** OSC 7501, the Program Status Protocol
  (`ESC ] 7501 ; state=working:app=claude-code:msg=<base64> ESC \`). Upstream
  Ghostty already parsed it; this fork connects it to the app.
- **Hook:** `agents/claude-code/ghostty-agent-status`, installed into each
  Claude config folder's `settings.json` by `agents/claude-code/install.sh`.
- **App:** each terminal keeps its latest status; each tab shows the most
  urgent one; the custom tab bar draws the tabs of the native macOS tab group,
  so shortcuts, menus and window restore keep working.

## Phases

**P0 — MVP (macOS)**
- OSC 7501 from the core to the macOS app
- Claude Code hook and installer
- Faces, face tab bar (top/left, S/M/L), hover card
- Notifications when done / waiting / error while you're elsewhere
- "Done" goes back to idle once you've seen it

**P1 — Multiple accounts**
- Account profiles (name, `CLAUDE_CONFIG_DIR`, color)
- `+` menu: new Claude tab per account, new split, start in a git worktree
- Account color as the ring around each face

**P2 — Never lose an agent**
- Agents panel (⌘⇧A) listing every agent in every window
- Jump to the next agent waiting on you (⌘J)
- Dock badge with the count waiting, menu bar summary
- Subagent count badge, context used and last message in the hover card

**P3 — Later**
- Other agents: Codex, Gemini CLI, opencode (same protocol, new hook)
- Linux (GTK) app
- Quiet mode, sounds, grouping faces by project, drag a face to a new window

## Decisions

- **macOS first.** The Linux app is a separate code path.
- **Faces, not dots.** Chosen on the design canvas.
- **No text on tabs.** Details live in the hover card.
- **Top or left**, chosen by right-clicking the tab bar. Remembered.
- **OSC 7501** instead of a custom escape code, because it's an existing spec.
- **Keep native macOS tabs underneath** and only replace how they're drawn.

## Status

See [tasks/README.md](tasks/README.md). P0 is mostly built; the face tab bar
needs to be checked against the design.
