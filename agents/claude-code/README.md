# Claude Code status for Ghostty

Shows what Claude Code is doing as a face on the Ghostty tab, and sends a
notification when it finishes or needs you while you're in another tab.

| Claude Code event  | Tab face                         |
| ------------------ | -------------------------------- |
| `SessionStart`     | Idle (gray, sleeping)            |
| `UserPromptSubmit` | Working (blue, spinner)          |
| `PreToolUse`       | Working, with the tool in hover  |
| `PostToolUse`      | Working                          |
| `Notification`     | Waiting on you (amber, bouncing) |
| `Stop`             | Done (green, until you look)     |
| `SessionEnd`       | No face                          |

## Install

```sh
./install.sh                       # ~/.claude, or $CLAUDE_CONFIG_DIR
./install.sh ~/.claude-account1 ~/.claude-account2   # several accounts
```

This copies `ghostty-agent-status` to `~/.config/ghostty/agents/claude-code/`
and adds it to each folder's `settings.json` (backed up to `settings.json.bak`
first). Restart running Claude Code sessions to pick it up.

Remove it with `./install.sh --uninstall [folders...]`.

## How it works

The hook writes an [OSC 7501](https://www.superlogical.com/rex/docs/build/program-status)
(Program Status Protocol) report to the terminal, for example:

```
ESC ] 7501 ; state=blocked:app=claude-code:kind=permission:title=<base64>:msg=<base64> ESC \
```

Any program can send these, so other agents can be supported by writing a
similar hook. It does nothing outside Ghostty (`TERM_PROGRAM` must be
`ghostty`). Requires `jq` for installing; the hook itself uses `jq` when
present to read tool details.
