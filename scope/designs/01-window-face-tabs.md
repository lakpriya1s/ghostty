# 1 · Window with face tabs

Source: [source/Main.dc.html](source/Main.dc.html) (interactive on the canvas)

## Layout

- Window: title bar with traffic lights, then the **face tab bar**, then the
  terminal.
- **Top position:** a row of faces under the title bar, `+` at the end,
  1px divider below.
- **Left position:** a column of faces on the left, `+` at the bottom,
  1px divider to the right.
- The user switches Top / Left and face size S / M / L. Remembered.

## Tab (one per tab)

- Face only. **No title text.**
- Face is 40px at M (S = 0.8×, L = 1.25×), inside a round slot of
  face + 18px. The slot's 2px border is the **account color** (transparent
  for plain shells).
- Button padding 5px, corner radius 14px.
  - Selected: background `#363944`
  - Hover: background `#2c2e35`
- **Subagent badge:** bottom-right, 18px pill, dark background, blue border,
  number of running subagents. Only while working.
- `+` button: circle at 0.7× the slot size, 1.5px **dashed** border `#4a4e59`,
  "+" in `#a8adb7`.

## Hover card

Appears below the face (top position) or to its right (left position).
300px wide, padding 14px, radius 12px, background `#24262d`, border `#3a3d47`.

1. **Title** (bold, 13.5px) and the **⌘N shortcut** on the right.
2. **State label** in the state's color, then `· elapsed` in gray.
3. **What it's doing**, e.g. "Editing src/auth/session.ts (2 subagents running)".
4. **Context used**: label + percent, 4px bar (blue, amber above 70%).
5. **Last message** in quotes, italic, on a darker inset.
6. **Account dot · account name · folder · git branch** (11.5px, gray).

Plain shell tabs show only the title, "Shell", and the folder.

## Behavior

- Click a face to select the tab. Selecting a **done** tab marks it read:
  the face goes back to idle.
- A **waiting** tab that isn't selected stands out (amber pulse).
