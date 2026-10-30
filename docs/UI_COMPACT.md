# Compact workshop layout — 0.6.2

The reported large portrait layout stretched each board row to a fraction of
all available height. Once bottles reached their size cap, the remaining height
became empty space above recipes and between rows.

Rows now use their content height with a 24 dp gap and up to 12 dp of top
clearance. Short screens still constrain bottle height to fit. Wider boards
allow a 144 dp bottle width rather than the phone's 114 dp cap. The bottom
tools stay anchored while spare height shows the garden backdrop.

The header and prompt are slightly shorter. One score strip replaces the two
wide plates, and its width is capped at 420 dp. The mathematical label is now
“7 pours or fewer” for order 3, beside the current star rating. Its accessibility
label explicitly explains that this earns three stars. The counter uses
“1 pour” for a single move.

The UI regression checks keep the first recipe near the prompt, bound the gap
between rows and verify that tools remain clear. Coverage includes 390×1000,
758×1216 and 800×1280 in addition to small phones and landscape. Four-layer
and five-bottle puzzles also run at the reported large portrait size.

The home bento grid, bottle flight calculations, game rules, all 1,000 orders,
progress storage and update signing identity remain compatible with 0.6.1.
`COMPACT_GAMEPLAY.png` is a capture from the real Flutter widget tree.
