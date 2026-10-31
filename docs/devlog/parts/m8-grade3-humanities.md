# Grade 3 history, geography and citizenship: every unit written (owner #70, #73; 2026-09-29)

The owner: "start from grade 3 and finish all grades accordingly" and "research school programs, world leading schools
and create better school program". The research (`docs/design/school-curriculum-research.md` §6.3) lists grade 3's
History (10), Geography (10) and Citizenship (11) units; this agent wrote all 31 of them, in parallel with the agents
writing grade 3's maths, science and English. Branch `worktree-agent-a8fd01c35cab8b7b9` (from `lead-merge`, with
`lead-school` 7b0bba5 merged in for the new sort and match exercise types).

## What was written
| Subject | Units | Lesson cards | Hand-written exercises | Generators used |
|---|---|---|---|---|
| History | 10 | 77 | 138 | `g3h.year_order`, `g3h.decade_century`, `g3h.years_between` (Timelines) |
| Geography | 10 | 76 | 145 | `g3h.compass_turn`, `g3h.compass_map` (Compass directions), `g3h.grid_ref` (Finding places on a grid) |
| Citizenship | 11 | 88 | 154 | `g3h.coins_spend` (Needs and wants), `g3h.coins_earn` (How people earn money), `g3h.coins_save` (Saving for later) |
| **All** | **31** | **241** | **437** | 9 generators, each at levels 1-3 |

- **Files:** `data/school/g3/<subject>/<unit>.json`, linked from `data/school/grade3.json` (only the history, geography
  and citizenship units' `file` fields changed; titles and goals kept).
- **Every unit:** a lesson of 7-8 cards that opens with a quick memory question from an earlier unit (its answer in
  brackets) and ends with "Try it in the world: …" (research §5.3 rules 1 and 8); 13-16 hand-written exercises at levels
  1, 2 and 3 (at least 2, 3 and 4 of them, so a round never repeats one), of 3-5 kinds: choice (243), true or false
  (123), order (35: timelines, steps), number (6: counting on a map, reading a table), and the lead's new **sort** (15)
  and **match** (15) (30 in all:
  primary or secondary source, then or now, hunter-gatherers or farmers, known or still a mystery, continent or ocean,
  hemispheres, land or water, physical or human features, needs or wants, the three Rs; time words, metals, tools and
  their ages, map symbols, opposite directions, river parts, climates, foods, rights and examples, helpers, jobs and
  skills, ideas of fair). Every exercise has a hint (a strategy, never the answer) and an explain (the worked answer).
- **History:** timelines (decade, century, millennium, BC/AD and BCE/CE, no year 0), history detectives (primary and
  secondary sources, layers in a dig), then and now (the 1920s: homes, washing day, school slates, toys), the story of a
  place (Millbrook's table 1850-today, names as clues, oral history), Stone Age hunter-gatherers (flint, fire, bone
  needles, Lascaux ~17,000 years), the first farmers (the Middle East ~12,000 years ago, Britain ~6,000, Skara Brae ~5,000
  and the 1850 storm), stone circles (Stonehenge's stages ~3000 and ~2500 BC, sarsens ~25 km, bluestones ~240 km from the
  Preseli Hills, sledges and antler picks, solstice lines, known and still a mystery, Avebury), the Bronze Age (smelting,
  9:1 copper and tin, moulds, the Great Orme, Cornish tin, trade, the Dover Boat), the Iron Age (800 BC-AD 43,
  blacksmiths, roundhouses, hill forts, Maiden Castle, the first British coins, Roman writers as outsiders), great
  inventions (the wheel ~3500 BC to the Web 1989, one invention leading to the next).
- **Geography:** maps and keys (the game's `map` picture with a key), eight compass points (a 3 × 3 table), grid
  references (letters and numbers, then four figures; "along the corridor, then up the stairs"; the bottom-left rule),
  7 continents and 5 oceans (tables), the globe, the Equator and the hemispheres (the torch test, opposite seasons),
  hills, rivers and coasts (a river drawn on the `map` picture), settlements (hamlet to megacity, why people settled,
  -ford and -mouth), the local area (a land-use map and Bram's survey as tables, fieldwork with a grown-up), hot and cold
  places (climate, °C with minus temperatures, a weather map of Frostpeak, the Meadows and the Desert), where food comes
  from (cocoa, rice, potatoes, Britain's seasons, food miles).
- **Citizenship:** rules and fairness (with children's rights: the UN Convention on the Rights of the Child, 1989, in a
  child's words, and rights with responsibilities), honesty (Zara, Tilly and the cracked lantern; the boy who cried
  wolf), kindness and respect (differences, festivals, empathy), friends and falling out (four steps, I sentences,
  win-win, a real sorry), people who help us (volunteers, the bread chain, emergency numbers 999/112/911), needs and wants
  (opportunity cost with gold), how people earn money (barter, Lydia's first coins, jobs and skills, unpaid work), saving
  (a goal, a plan, a money box or a bank, interest, never sharing passwords), caring for nature (the three Rs, bees,
  plastic, bug hotels), jobs and responsibilities (Japan's class duties, promises), and a big question: what is fair?

## Generators (`core/school/gen/g3_humanities_gen.gd`, `G3HumanitiesGen`, SchoolGen source "g3h", the last SOURCES line)
Seeded, levels 1-3, each with a hint, a worked answer and `data`:
- `compass_turn`: "Zara faces east and makes a quarter turn anticlockwise…" (1: four points, quarter turns; 2: half and
  three-quarter turns; 3: all eight points, eighth turns).
- `compass_map`: a table map with "north" over the top: the direction between two places (1: straight; 2: mostly
  diagonals) or (3) "walk 3 squares west, then 1 square north: where are you?".
- `grid_ref`: letters and numbers (1), four-figure references (2, 3): "What is the grid reference of the well?" (the
  numbers the wrong way round is always a wrong choice) or "What is in square 2253?".
- `year_order`: years in order, earliest first (1: AD; 2: BC; 3: BC and AD, or BCE and CE).
- `decade_century`: the decade (1), the hundred years (2), the century as an ordinal (3).
- `years_between`: whole hundreds (1), any AD years (2), BC years (3).
- `coins_earn`, `coins_save`, `coins_spend`: gold for work (then spending some), days to save for a goal (exactly, with
  some saved, or going past the price), and choosing (can she buy both? how much is left? which pair fits, and what is
  given up?).

## Rulings (decide and write down; cost if wrong)
1. **Every lesson opens with a memory question and ends with a world idea**, and the test enforces it for these units
   (`test_every_lesson_starts_with_a_memory_question_and_ends_in_the_world`). *Cost:* none; other subjects may adopt it.
2. **BC and AD are explained by where the count starts** ("the year people long ago worked out for the birth of Jesus";
   other calendars start from other years), and BCE/CE are given as equal names (research §5.4 rule 1). *Cost:* one
   card.
3. **No sum crosses from BC to AD at grade 3** (`years_between` keeps both years BC or both AD): there is no year 0, and
   that trap is for later grades. The lesson and one exercise teach "no year 0". *Cost:* a level 4 later.
4. **Centuries avoid years ending in 00** (1900 is the last year of the 19th century), and decades never read "the
   1900s" (which children read as a hundred years). *Cost:* none.
5. **Grid references on a table picture label the squares**, and the lesson says that on a real map the numbers sit on
   the lines and a square takes the numbers at its bottom-left corner. Column and row numbers never overlap (10-29 and
   30-64), so a swapped reference is never another square. No new picture kind (this agent did not touch `ui/school/`).
   *Cost:* a `grid_lines` picture kind if the owner wants Ordnance Survey-style lines.
6. **History is world history with England's KS2 spine** (research §5.5 ruling 5): Stonehenge, Skara Brae, Maiden
   Castle and the Great Orme beside Lascaux, Mesopotamia, Egypt, China and the Americas. Dates say "about" where
   archaeologists give a range; mysteries are called mysteries. *Cost:* none.
7. **No living people:** inventions are named without inventors (the Web without its inventor); only fable and game
   characters speak. **No brands** (no maker of a toy, a phone or a cereal; the mnemonic is "Naughty Elephants Squirt
   Water"). **Festivals** appear together, from many traditions (Diwali, Eid, Christmas, Hanukkah, Lunar New Year).
8. **Rights (UNCRC) sit in "Rules and fairness"** (the grade 3 list has no rights unit of its own) and come back in
   "Jobs and responsibilities" (a right with its responsibility). *Cost:* a unit in grade 4's list if wanted.
9. **Money is whole gold coins** (research §5.5 ruling 6) and the jobs are the game's helpers' (Mimi bakes cakes, Bram
   plants trees, Zara draws maps, Tilly weaves baskets and keeps the stall). Emergency numbers show 999, 112 and 911,
   because players are worldwide. *Cost:* none.
10. **"Try it in the world" asks only for things the game has** (blocks, farms, a furnace, hay, chests, signs, photos,
    buddies); nothing claims where the game's Sun rises. *Cost:* none.
11. **Food seasons are Britain's** (the game's British English), and the food facts are world facts. *Cost:* a line
    per season for another country.
12. **Table cells are kept to about 16 letters** (SchoolPicture's cells are at most 190 px wide at 22 px letters). This
    was measured by a letter-width estimate, not by a screenshot (agents do not open the editor or a window).
13. **The unit files are the source of truth** (as for every other grade); the Python that wrote them stayed in the
    agent's scratchpad.

## Tests
- `tests/unit/test_school_content_g3_humanities.gd` (written first; it failed with "g3.history.timelines is written" and
  the rest): `test_the_outline_has_every_unit_of_the_research`,
  `test_grade_3_history_geography_citizenship_are_written_for_every_unit` (content, no problems, a lesson of 3+ cards,
  at least 12 hand-written exercises at levels 1-3 of 2+ kinds, rounds that fill and vary with at least 12 different
  exercises, never a hand-written one twice in a round), `test_every_exercise_has_a_strategy_hint_and_a_worked_answer`,
  `test_every_lesson_starts_with_a_memory_question_and_ends_in_the_world`, `test_the_units_use_their_own_generators`.
- `tests/unit/test_g3_humanities_gen.gd` (written first; it failed with "g3h.… makes an exercise"): nine tests, one per
  generator, 80 seeds × 3 levels, each answer worked out again from `data` (the compass point from the start and the
  eighths turned; the direction or the walk from the places' squares; the grid reference from the labels; BC/AD text
  parsed back to signed years and checked in order; the decade, hundreds and ordinal century; years between; days to save
  with ceil; the single pair that fits and what is given up; gold earned minus spent).
- The shared `tests/unit/test_school_content.gd` checks every exercise's own answer, every picture, the kind words,
  British spelling and the letters.
- The full suite: see the end of this file.

## For the lead when merging
- `data/school/grade3.json`: only the 31 history, geography and citizenship units gain a `file` line; the maths, science
  and English agents add theirs to other units of the same file (a textual merge, no overlap).
- `core/school/school_gen.gd`: one SOURCES line at the end (`"g3h"`); the other agents may add their own lines there.
- This branch merged `lead-school` (7b0bba5: sort and match, the full outline for grades 3-8), so it carries those
  commits too.
- Not done here (to avoid conflicts with the other grade 3 agents): `python3 tools/school_outline.py --write
  docs/superpowers/plans/2026-09-28-school.md`, `docs/DEVELOPMENT.md` and the spec's "as built". Worth a look in the real
  screen: `school_shots.gd -- --unit=g3.geography.grid_references --exercises` and `--unit=g3.geography.local_area`
  (the table maps).

## The full suite (2026-09-29, this branch at 01ca5f3 with `lead-school` merged)
`tests/run_tests.sh`: **6807 passing, 1 failing, 2 risky** (the two world tests that never assert, as before), no script
errors. The one failure is not from this work: `test_g5_measure_gen.gd::test_grade_5_maths_is_written_for_every_unit`
wants every grade 5 maths unit written, and `lead-school`'s outline (cb55e33, the research's programme) adds
`g5.maths.percent_intro` and `g5.maths.angles_triangles_quads` without files. The lead's fix: skip units without a
`file` there, as `test_school_content.gd` now does (this agent does not touch maths files). The humanities' own tests:
`test_school_content_g3_humanities.gd` 5/5 and `test_g3_humanities_gen.gd` 9/9, and `test_school_content.gd` passes with
the 31 new units (2,910 hand-written exercises in all written units).
