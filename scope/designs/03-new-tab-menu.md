# 3 · `+` button: new tab by account

Source: [source/NewTab.dc.html](source/NewTab.dc.html)

Clicking `+` opens a menu (330px wide, radius 12px, background `#26282f`):

1. **New Tab** ⌘T
2. **New Split** ⌘D
3. — divider —
4. Section **CLAUDE CODE**: one row per account
   - Color swatch (10px, radius 3px), account name
   - Second line: config folder · how many running (e.g. `~/.claude-account1 · 2 running`)
   - Shortcut on the right: ⌥⌘1, ⌥⌘2, …
5. **Add account…**
6. — divider —
7. Checkbox: **Start in a new git worktree**
8. — divider —
9. **Codex**, **Gemini CLI**, disabled, marked "later"

Each account runs `claude` with its own `CLAUDE_CONFIG_DIR`. Its color shows
on every tab it owns (the ring around the face).
