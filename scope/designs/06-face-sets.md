# 6 · Face sets

Sources: [Orbs](source/FacesOrbs.dc.html), [Shapes](source/FacesShapes.dc.html),
[Bots](source/FacesBots.dc.html), [Spark](source/FacesSpark.dc.html)

Alternatives to the faces in [02-agent-faces.md](02-agent-faces.md), chosen
with **Face Style** in the tab bar's right-click menu or **View › Agent Face
Style**. Same 40×40 grid, same state colors, same white unread dot; only the
look changes. The plain shell changes with the set.

| State       | A · Orbs                     | B · Shapes                   | C · Bots                               | D · Spark                       |
| ----------- | ---------------------------- | ---------------------------- | -------------------------------------- | ------------------------------- |
| Idle        | Dim dot, breathes (3.2s)     | Hollow ring, fades (3s)      | Eyes shut, lamp off                    | Small, dim, breathes (3.2s)     |
| Working     | Glow, two rings orbit        | Three hopping dots (1s)      | Visor scans, lamp blinks (0.8s)        | Spins (2.2s), gradient rays     |
| Waiting     | Rings ripple out (1.6s)      | Warning triangle, bobs       | Wide eyes, bobs, lamp flashes (0.5s)   | Throbs (1s), "?"                |
| Done        | Solid with a check           | Filled circle, check         | Happy eyes, green lamp                 | Opens into petals               |
| Error       | "!", shakes (2.4s)           | Stop-sign octagon, X         | X eyes, bent antenna, shakes           | Breaks into an X, shakes        |
| Plain shell | Dark square, blinking cursor | Gray square, `>_` in ink     | Empty head, no antenna, `>_`           | Rays form `>_`                  |

Notes from the boards: Orbs is the quietest, Shapes the most color-blind
friendly, Bots has the most character, Spark feels closest to the CLI spinner.

Motion follows the same rules as the faces: everything moves while Ghostty
is active, only working and waiting in the background, nothing when the
window can't be seen.
