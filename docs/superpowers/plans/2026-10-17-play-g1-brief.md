# Play G1: the maths signature games, wave 1 — the agents' brief (owner #122)

The owner (2026-10-17, #122): "all lessons should be game, part of game, mini games and etc but games, not lectures
and slides and classical lessons … this must be future of education". G0 makes every unit playable with generic
mechanics; **G1 builds the maths games whose winning move is the concept itself** (`docs/design/learning-is-play.md`
§3 rule 1, §5.2). Wave 1 is two agents side by side, two games each, chosen for the most units and the strongest
evidence (fractions and early algebra are where children struggle most; the DragonBox balance is the best-known
success [G5]):

| Agent | Games | Units it gives a game (P1) |
|---|---|---|
| **G1a** | **Fraction Bakery**, **Balance Altar** | g3 unit_fractions, equivalent_fractions; g4 equal_fractions, add_fractions, fraction_times; g5 unlike_fractions, fractions_as_division, multiply_fractions, scaling, divide_unit_fractions; g6 divide_fractions · g5 expressions; g6 equivalent_expressions, equations, variables, exponents_expressions; g7 expressions, equations, inequalities; g8 linear_equations, systems, expand_factorise |
| **G1b** | **Array Farm**, **Frog Jump** | g3 multiply_meaning, divide_meaning, times_tables, multiply_properties, multiply_divide_written, area, perimeter; g4 times_as_many, multiply, divide, factors, area_perimeter; g5 multiply_whole, divide_whole; g6 gcf_lcm, area, multi_digit; g7 primes_estimation · g3 fractions_number_line; g4 decimals, patterns; g5 decimal_add_subtract, decimal_multiply_divide; g6 negatives; g7 integers_add, integers_multiply, rational_numbers; g8 irrational |

A unit may also keep G0's mechanic for an exercise its game can't express (say which, and why, in the notes). Waves 2-3
(after these merge): Builder's Count with Size Magic Zoom (place value, powers of ten, scientific notation), Market
Change, Data Lab, Ratio Kitchen, Shape Forge, Angle Launcher, Treasure Grid, Size Magic Volumes, Function Factory, Fair
Festival, and a measuring game for time and units (the Clock Tower).

## Read first
- `docs/design/learning-is-play.md` (all of it: the seven rules, the loop, §5.2), spec §22.0 and **G0 as built**:
  `docs/devlog/parts/play-g0.md`, spec §22.0's "As built (G0)", DEVELOPMENT.md's play section. **G0's play layer is
  your contract** (its loop, its places, the referee bridge to `ExerciseCheck`, the record in `MasteryRules`, the coach
  and ghost hands, the `play` block, the audit's play levels): a signature game is a new kind of place in that layer,
  chosen by a unit's `play.game`. Build on it; change it only with a marked hook and a ruling.
- The units you serve: `data/school/g<N>/maths/<unit>.json` (their goals, cards, exercises and `standards`) and their
  generators (`core/school/gen/*`, `SchoolGen.SOURCES`): your challenges at levels 1-3 come from them, so a game's round
  is the unit's exercises played, and stars, reviews and gold keep working.
- Life's rooms and ghost hands (`entities/life/*`, `LifeRoomKit`) and the rooms' look notes (`docs/devlog/parts/
  rooms-look.md`, if merged) for how a place looks; Size Magic (`docs/DEVELOPMENT.md`) for Frog Jump's zoom.

## The games (what the child does; the move is the concept)
### Fraction Bakery (G1a)
A bakery where buddies order shares: "3/4 of a pie, please". **Cut** with a knife that only makes equal cuts (the
number of cuts is the denominator: the bottom number is "how many equal pieces"); **serve** pieces (the numerator).
The world answers: an exact order makes a happy buddy; too little leaves them hungry (the gap shows), too much leaves
leftovers. **Fair shares** (unit fractions): a wonky cut is not a fraction (a level asks "fair or not?"). **Equivalent**:
recut a half into quarters: the same amount, laid over each other. **Add and subtract**: slices go into one tin; only
same-size slices fit together, so 1/2 + 1/3 means recutting both into sixths (the common denominator *is* the move).
**Fractions as division**: 3 pies shared by 4 buddies, each gets 3/4. **Times a whole**: 3 buddies want 2/5 each.
**Fraction of a fraction**: half of a 3/4 piece is cut from it. **Scaling**: a recipe × 1/2 or × 3/2. **Divide by a
unit fraction / divide fractions** (g6): how many 3/4-cup scoops are in 2 1/4 cups of flour: scoop and count. Mixed
numbers as whole pies and pieces. VR: the knife and the pieces in the hand.

### Balance Altar (G1a)
An equation is a balance in a temple: crystal bags (x) and weights on two pans; free the crystal by **doing the same
to both sides** (the altar takes a move only when it is done to both pans: a rune applies it to both). Take away the
same weights; split both pans into n equal groups (divide); balloons are negatives (they lift: −1). Pictures first,
symbols later (the DragonBox principle: by level 3 the bags read *x* and the weights numbers). **Expressions**: recipe
boxes; like crystals stack (x + x + 3 = 2x + 3); **expand** a box of 3 × (x + 2) into 3x + 6 by opening it;
**factorise** by packing equal boxes. **Inequalities**: a see-saw that stays tipped; find every x that keeps it so (a
ray of crystals on the number line). **Systems** (g8): two altars share the same crystals; solve one, use it in the
other. **Exponents** in expressions: a box of boxes. VR: lift weights off both pans by hand.

### Array Farm (G1b)
Plant a field in rows and columns: **multiplication** is the field (4 rows of 6 seeds: the harvest is 24), **division**
shares seeds into equal rows (24 into 4 rows: 6 a row; a remainder is the seeds left in the bag). Tables by quick
plantings; **properties**: turn the field (4 × 6 = 6 × 4), split it with a fence (7 × 6 = 5 × 6 + 2 × 6), the area
model for written multiplication (23 × 14 as four plots). **Area**: the crop grows in the squares you planted
(length × width; g6 triangles as half a rectangle, parallelograms by moving a slice); **perimeter**: fence posts round
the edge. **Factors**: every rectangle field you can make from 12 plants (the factor pairs); **primes** (g7): a prime
number of plants makes only one long row. **GCF and LCM** (g6): the biggest square paving stone that tiles two fields
exactly; two crops planted every 4 and every 6 steps line up at 12. VR: plant and fence by hand.

### Frog Jump (G1b)
A number line over a river; lily pads at its numbers; the frog must land exactly where the fly is. **Add** jumps
right, **subtract** jumps left; **negatives** past the zero bank, on the cold side; **multiply integers**: repeated
jumps, and a negative multiplier turns the frog round. **Fractions on the line** (g3): pads split into equal parts.
**Decimals**: Size Magic zooms between two pads into ten smaller ones (tenths), again (hundredths); add and subtract
decimals by jumps at the zoom you need; multiply and divide by 10 and 100 by zooming. **Patterns** (g4): skip-count
jumps, the rule you jump by. **Rational numbers** (g7): order, compare and place them. **Irrational** (g8): √2 is
between 1.4 and 1.5, and between 1.41 and 1.42 … the zoom never lands. VR: point where to jump.

## For every game
- **The loop** (G0's): the hook (the problem appears in the place), the try at level 1 before any words, the coach's
  one line after (≤ 12 words, read aloud), ghost hands after two misses (one step in the game), rounds at levels 1-3
  from the unit's exercises and generators, the unit's "try it in the world" as a quest card, reviews that come back
  with new challenges.
- **The referee:** the child's move is turned into the exercise's answer and checked by `ExerciseCheck.is_right`
  (first try counts as now), so `MasteryRules` keeps the record. Generated challenges come from the unit's own
  generators; a game may add its own generator (in `core/play/*`'s files you own, never `core/school/gen/*`).
- **Every exercise kind** in your units goes somewhere: played by your game, or by G0's mechanic (listed in the notes
  with the reason). The audit's play level becomes **P1** for each unit your game serves.
- Flat and VR (the hands do the move); read aloud everywhere; the phones' budget (≥ 30 FPS average, no frame over
  100 ms on the emulator; the Quest's ≤ 100 draws a frame); calm and kind (a miss is the world answering, never a
  buzzer); no timers that hurry; no gold beyond what the School pays now.
- Each game's pure rules in `core/play/<game>*.gd` with their own tests (the maths itself checked: a fraction's
  equivalence, a balance's moves, an array's product, a jump's landing), the place in `entities/play/<game>*.gd`, its UI
  in `ui/play/<game>*.gd`; a smoke `tools/play_<game>_smoke.gd` that plays every unit it serves at levels 1-3.

## Allocation and rules
- **G1a** owns `core/play/fraction_*`, `core/play/balance_*`, `entities/play/fraction_*`, `entities/play/balance_*`,
  `ui/play/fraction_*`, `ui/play/balance_*`, the `play` blocks of its units' files, tests `test_play_fraction*` and
  `test_play_balance*`, notes `docs/devlog/parts/play-g1a.md`. **G1b** the same with `array_*` and `frog_*`, notes
  `play-g1b.md`. Shared play-layer files (G0's registry of games, the audit): one marked line each ("owner #122 (G1a)").
- TDD; the matching godot-prompter skills first (3d-essentials, godot-ui, tween-animation, xr-development,
  component-system); `--import` after new class_name scripts; logs `play1a_*` / `play1b_*` in the session scratchpad;
  look at every game in a real window under `nice` (pictures in the notes); the FULL suite once at the end, right after
  merging lead-merge. Never open the editor or an emulator, never touch adb; never merge or push; no downloads; never
  start agents. Commits end with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
- The PC's memory guard may stop a background run while the session is idle: if your full suite is cut off, merge
  lead-merge in first, then run it once more; report it either way.

## Finish
Notes: what a child does in each game at levels 1-3, flat and VR; the units served and the exercises left to G0's
mechanics; the rulings and their costs; the pictures; what the lead must check on the emulator and the Quest 3.
DEVELOPMENT.md (each game's section), spec §22.0 "As built (G1)". Report: branch, commits, the games, the units at P1,
the smoke's and the full suite's results.
