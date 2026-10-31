# Grade 3 maths (owner #70: "start from grade 3 and finish all grades accordingly")

Branch `worktree-agent-a8abe9809bb4c73e0`, cut from `lead-merge` at 73566c3 ("grade 3's outline"). The School's grade 3
maths is written for every unit of the outline: 18 units, 120 lesson cards, 329 hand-written exercises, 97 generators,
13 new picture kinds.

## The outline (the lead's change of plan, 2026-09-29)

The research's §6.3 "Grade 3 → Maths (18)" table (`docs/design/school-curriculum-research.md`) replaced the maths units of
`data/school/grade3.json` (only the maths subject was touched): ids, titles, goals split on ";", standards from "Follows"
(`CC 3.OA.1, 3.OA.3` becomes `3.OA.1`, `3.OA.3`; `UK Y4 …` and `SG P3 …` kept whole). One goal was reworded:
"Measure and convert km, m, cm, mm, kg, g, l and ml" → "… g, litres and millilitres" (the School writes L and mL, and
SchoolSpeech reads those; ruling 2). The stop-fits test passes for every new title.

| unit | title | cards | exercises | exercise kinds | generators |
|---|---|---|---|---|---|
| numbers_to_10000 | Numbers to 10,000 | 7 | 18 | choice, number, order, truefalse | g3m.place_value, blocks_number, expanded, compare, order_numbers, round_number, roman |
| add_subtract | Add and subtract to 10,000 | 7 | 17 | choice, number, order, truefalse | g3m.bond, mental, column_add, column_subtract, check_inverse, add_story |
| multiply_meaning | Equal groups and arrays | 6 | 18 | build, choice, number, truefalse | g3m.groups_total, groups_sentence, array_build, repeated_add, groups_story |
| divide_meaning | Sharing and grouping | 6 | 19 | build, choice, number, order, truefalse | g3m.share, grouping, divide_build, unknown_factor, fact_family, divide_story |
| times_tables | Times tables to 12 × 12 | 6 | 19 | choice, number, order, truefalse | g3m.times_fact, divide_fact, grid_hidden, even_odd, in_table, skip_count |
| multiply_properties | Multiplying made easier | 6 | 18 | choice, number, order, truefalse | g3m.swap, split, group_three, split_area |
| multiply_divide_written | Multiply and divide by one digit | 7 | 19 | choice, number, truefalse | g3m.times_tens, short_multiply, short_divide, remainder, remainder_story |
| two_step_problems | Two-step problems with bar models | 7 | 18 | choice, number, truefalse | g3m.two_step, letter_unknown, estimate_check, model_sentence |
| unit_fractions | Fractions of a whole and of a set | 7 | 18 | build, choice, number, order, truefalse | g3f.name_fraction, pick_picture, fraction_of_set, equal_parts, build_fraction |
| fractions_number_line | Fractions on a number line | 6 | 18 | choice, number, order, truefalse | g3f.fraction_on_line, jumps, whole_as_fraction, order_on_line, compare_to_one |
| equivalent_fractions | Equal fractions and comparing | 7 | 18 | choice, number, order, truefalse | g3f.equivalent_missing, is_equivalent, compare_fractions, add_same, order_unit_fractions |
| money | Money and change | 6 | 18 | choice, number, truefalse | g3f.money_total, money_change, can_afford, price_list |
| time | Time and how long | 7 | 19 | choice, number, order, truefalse | g3g.read_clock, to_24h, duration, end_time, time_units |
| measure | Length, mass and volume | 7 | 19 | choice, number, order, truefalse | g3g.convert_length, convert_mass_volume, read_scale, read_jug, read_ruler, which_unit, measure_story |
| area | Area with squares | 7 | 18 | build, choice, number, truefalse | g3g.count_squares, rect_area, area_build, l_area, missing_side_area |
| perimeter | Perimeter | 7 | 18 | build, choice, number, truefalse | g3g.rect_perimeter, polygon_perimeter, missing_side, grid_perimeter, same_perimeter |
| shapes_lines_angles | Shapes, lines and right angles | 7 | 19 | choice, number, order, truefalse | g3g.name_shape, shape_true, right_angles, angle_size, lines_kind, cut_fraction, g3f.equal_parts |
| graphs | Bar graphs, pictograms and line plots | 7 | 18 | choice, number, order, truefalse | g3g.pictogram_read, pictogram_compare, bar_read, bar_compare, bar_pick, plot_read, plot_pick |

## How the units teach (the research's §5.3)

- **Start with memory:** every lesson's first card is a "Quick memory" question from an earlier unit (or grade 2), with
  its answer on the card (cards are read, not answered).
- **Concrete → picture → symbols:** blocks, arrays, groups and the block board first (build exercises in 5 units), then
  a bar model, a fraction wall, a number line or a diagram, then the numbers.
- **Hoot's puzzle** cards compare two characters' ways (346 + 278 in columns or in jumps; 6 × 12 split or doubled; the
  pie that Zara and Bram share); every hint is about the strategy, every worked answer shows the steps.
- **Spiral:** each lesson's last card says what comes next ("Next, in grade 4: …").
- Money is whole gold coins (ruling 5.5.6); measures are metric; time uses the clock and a 24-hour digital clock.

## Pictures: SchoolPictureG3 (`ui/school/school_picture_g3.gd`)

13 kinds, drawn with UI draw calls and the game's block icons (hooked into SchoolPicture at its two dispatch points, like
SchoolPictureG5): `pictogram` (a key, half symbols), `bar_graph` (a scale; small pictures number every other line),
`jug` (1-3 measuring jugs, L or mL, small marks), `dial_scale` (a kitchen scale's dial, g or kg, a block on the plate),
`ruler` (cm, mm marks, a stick that may not start at 0), `cut_shape` (circle, square, rectangle, hexagon, triangle cut
into equal or unequal parts), `unit_squares` (shapes of squares, split colours, side lengths), `side_lengths`
(ShapeFacts shapes or any corners, with "?"), `fraction_plot` (line plots in wholes, halves and quarters: "2½"),
`bar_model` (Singapore bar models: parts, a total bracket, a comparison gap), `digital_clock`, `times_grid` (a window of
the 12 × 12 grid with hidden cells and shading), `fraction_wall` (rows of parts without words). Every kind was looked at
in the School (`tools/school_shots.gd` for the area, measure and graphs units) and in sheets of samples and generated
pictures at the lesson, exercise and choice sizes; `tests/integration/test_school_picture_g3.gd` checks every sample,
the broken data, the plot keys, the L-shape's sides and that every cut's parts are equal.

## Generators

`G3MathsGen` "g3m" (43, units 1-8), `G3FractionsGen` "g3f" (19, units 9-12), `G3MeasureGen` "g3g" (35, units 13-18),
registered in `SchoolGen.SOURCES` after the grade 8 lines. Seeded, levels 1-3, each with a strategy hint, a worked
answer and `data`; `tests/unit/test_g3_maths_gen.gd` works every answer out again from `data` (60 seeds × 3 levels) and
checks every picture and every choice (the wrong ones are wrong: never the turned-round fact, never an equivalent
fraction, never "intersecting" for perpendicular lines).

## The lead's review: a wrong sum

The lead found "346 + 278 … 724" in a lesson card (it is 624). Fixed, and guarded for good:
`test_every_sum_in_grade_3_maths_is_right` (in `test_school_content_g3_maths.gd`) finds every "a op b = c" (and "<", ">",
"1/4 of 12 = 3", "29 ÷ 4 = 7 remainder 1") in grade 3's lesson cards, hints, worked answers and questions, hand-written
and generated (20 seeds × 3 levels of every g3 generator), and every written column sum in a picture, and works each
out: 5,956 sums. A true-or-false question whose answer is false is the only text allowed a false sum. The content was
also built with the same check in Python, and every card and exercise was read through by hand (worked steps such as
"write 2 and carry 4", exchanges, clock readings, plot counts).

## Read aloud

SchoolSpeech now says "2½ cm" as "2 and a half centimetres" and "1¾ m" as "1 and 3 quarters metres" (two lines;
`tests/unit/test_school_speech_g3.gd`; the grade 4 and 5 speech tests unchanged). The litres card says "litres (L) and
millilitres (mL): 1 L = 1,000 mL" so the voice does not repeat itself.

## Rulings (decided here; cost if wrong)

1. **A third generator source, `g3f`** (fractions and money), as grade 4 has g4m/g4f/g4g: the brief's ~900-line guide
   (g3m and g3g are about 1,200 lines each). *Cost:* one SOURCES line; ids would move if merged into one file.
2. **"l and ml" in a goal became "litres and millilitres"**; the lessons write L and mL like grade 4. *Cost:* one word.
3. **Picture kinds with grade 3 names** (`dial_scale`, `cut_shape`, `unit_squares`, `side_lengths`, `fraction_plot`,
   `bar_model`, `digital_clock`, `times_grid`, `fraction_wall`) so the other grade 3 agents' kinds are unlikely to
   clash; `test_no_kind_is_another_grades` checks against grades 4-5. *Cost:* a rename if another agent used one.
4. **`fraction_wall` beside the base `bar` kind:** `bar` always writes "3/4" by the wall, which would give the answer
   away in "1/2 = ?/4". *Cost:* none.
5. **Line plots in halves and quarters of a centimetre** (3.MD.4 in metric), labelled "2½", "2¼". *Cost:* none.
6. **12-hour times say "in the morning / afternoon / evening"**, not am and pm; 24-hour times are written 09:05, 15:45.
   Hours 0 and 12 are left out of the 24-hour generator (midnight and noon words). *Cost:* a word list.
7. **Shape names that every definition agrees on:** a rhombus is never offered "kite" or "trapezium" as a wrong name, a
   square never "rectangle" or "rhombus", an equilateral triangle never "isosceles"; triangles by their sides are named
   from written side lengths, never judged from a drawing; parallel-side claims are about "this shape" as drawn.
   *Cost:* none.
8. **Angles:** "smaller / bigger than a right angle" at levels 1-2, "acute / obtuse" at level 3, always at least 20°
   from a right angle. *Cost:* none.
9. **Rounding: 5 or more rounds up** (6,500 → 7,000). Remainder stories: boats (one more for the leftovers), boxes
   (only full ones), leftovers. *Cost:* none.
10. **Hand-written choices are written right-first** (RoundPlan mixes them, as for grade 4). *Cost:* none.
11. **The content's Python build scripts stayed in the agent's scratchpad**; the unit files are the plain JSON the
    School reads, and the sum test guards every edit. *Cost:* none.

## Tests

- `tests/unit/test_school_content_g3_maths.gd` (written first and watched fail: 18 units "is written"):
  `test_grade_3_maths_is_written_for_every_unit`, `test_every_grade_3_maths_unit_uses_grade_3_generators`,
  `test_every_grade_3_maths_lesson_has_a_picture`, `test_the_sum_checker`, `test_every_sum_in_grade_3_maths_is_right`.
- `tests/unit/test_g3_maths_gen.gd`: 31 tests, one or more per unit, and `test_every_grade_3_generator_is_tested_here`.
- `tests/integration/test_school_picture_g3.gd`: 8 tests.
- `tests/unit/test_school_speech_g3.gd`: 3 tests.
- The shared `test_school_content.gd` runs all 97 generators (120 seeds × 3 levels) and every hand-written exercise
  through their checkers, and the words (kind, British, English letters).

## The full suite

`tests/run_tests.sh` (2026-09-29, 26 min): 741 scripts, **6,837 tests, 6,835 passing, 0 failing**, 2 risky or pending
(the suite's usual ones), exit 0. The last wording commit (358aa7e) landed while it ran; after it the grade 3 generator
and content tests (36), the shared content test, the speech, picture and School screen tests (45) all pass again.

After the suite, two exercises of every generator at every level were read through and their words fixed (singular
and plural, "no right angles", hints that never show the answer, count-on steps for time).

## For the lead when merging

- `core/school/school_gen.gd`: three SOURCES lines after the g8 lines (`g3m`, `g3f`, `g3g`); other agents append there.
- `ui/school/school_picture.gd`: a header line and one `SchoolPictureG3` check at each of the two dispatch points (after
  SchoolPictureG5's), like the grade 5 hook; another grade 3 agent may add its own file the same way.
- `data/school/grade3.json`: only the maths subject's `units` changed (the new outline and every `file`).
- `core/school/school_speech.gd`: two lines (`_unit` accepts ½ ¼ ¾ before a unit; `_mixed`).
- `docs/DEVELOPMENT.md`: one bullet in "School: content, tests and pictures".
- Spec §22.7 ("As built") is not touched: the lead's summary line for grade 3 maths can come from this note.
