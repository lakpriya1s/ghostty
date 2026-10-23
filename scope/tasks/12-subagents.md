# 12 · Subagent badge

**Phase:** P2 · **Status:** 🟡 built, needs checking

## Found

Claude Code 2.1.309 reports its own subagents as OSC 7501 child records,
seen in the dev app's log during a real run:

```
state=working:app=claude-code:id=a6dc7b2c9fa2828be:title=<Count zig files in src/apprt>
state=clear:id=a6dc7b2c9fa2828be
```

So the hook doesn't need `SubagentStart` / `SubagentStop` (which exist, with
`agent_id` and `agent_type`). Adding them could count subagents twice if the
ids differ. Revisit for Claude versions without their own reports.

## Done

- [x] Core forwards reports with an `id` (`stream_handler.zig`) and carries
      the id through `Message.ProgramStatus`, the `program_status` action
      and `ghostty_action_program_status_s.id`. Test: "ProgramStatus init".
- [x] Each terminal keeps its child records (`programChildren`); `clear`
      with an id removes that record and the ones under it, `clear` without
      one removes all.
- [x] Each tab counts working or blocked child records across its splits
      (`BaseTerminalController.subagentCount`).
- [x] Badge as in the design: 18pt pill at the slot's bottom right (offset
      2pt out), `#1c1d21`, 1.5pt `#5ca0ff` border, bold 10pt `#d7e7ff`, only
      while the face is working.
- [x] Hover card: "… (2 subagents running)" while working. Also "Ready for a
      prompt" for an idle agent without a message (was the app name).

## Verify

- [x] Badge on screen (2026-10-24): a working face with two subagent
      records shows "2" by its spinner. Seen with test reports, not yet a
      real Claude run with subagents.
