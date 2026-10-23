# 2 · Agent faces

Source: [source/States.dc.html](source/States.dc.html)

Faces are drawn on a 40×40 grid. Each state differs in color, expression
**and** motion, so they can be told apart without color.

| State       | Color     | Eyes                         | Mouth                 | Extra                                        |
| ----------- | --------- | ---------------------------- | --------------------- | -------------------------------------------- |
| Idle        | `#8b9099` | Closed lines 7×2.5           | Short line 6×2.5      | "z" top-right, fades in and out (2.6s)       |
| Working     | `#5ca0ff` | 5×8, look left/right (1.3s)  | Line 7×2.5            | Spinner ring, inset −6px, 2.5px, 0.9s/turn   |
| Waiting     | `#f5a524` | Big 6×9                      | "o" ring 9×9          | Bounces 2px and pulses (1.5s), "?" top-right |
| Done        | `#3fb950` | Happy arcs ^ ^               | Smile arc 16×8        | White unread dot top-right                   |
| Error       | `#f85149` | X X                          | Frown arc 12×6        | —                                            |
| Plain shell | `#2a2c33` | —                            | —                     | Rounded square, `>_`, border `#4a4e59`       |

## Rules

- **Ring = account.** The colored ring around a face shows the Claude account.
- **Badge = subagents.** A small number shows running subagents.
- **White dot = unread.** Done stays happy until you open the tab, then
  goes back to idle.
