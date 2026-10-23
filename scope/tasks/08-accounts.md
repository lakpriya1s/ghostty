# 08 · Account profiles and face rings

**Phase:** P1 · **Status:** ⬜ not started

Designs: [01](../designs/01-window-face-tabs.md), [02](../designs/02-agent-faces.md), [03](../designs/03-new-tab-menu.md)

## Goal

Support several Claude accounts, each a `CLAUDE_CONFIG_DIR`, and show which
account each tab uses.

## To do

- [ ] Account list: name, config folder, color. Detect existing
      `~/.claude*` folders as suggestions.
- [ ] Know each tab's account: the hook sends it (e.g. from
      `CLAUDE_CONFIG_DIR`), or the tab was opened from an account.
- [ ] Ring in the account color around the face.
- [ ] Account in the hover card.
- [ ] Installer runs for every configured account.
