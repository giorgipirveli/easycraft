# Grade 5 maths, science and English: the research's new units written (owner #70, #73; 2026-09-29)

The owner: "start from grade 3 and finish all grades accordingly" and "research school programs, world leading schools
and create better school program". The research (`docs/design/school-curriculum-research.md` §6.5) merged Singapore P5
and England Y6 into grade 5 and added 12 units to the maths, science and English written in 2026-09-28's first outline;
they showed "Coming soon". This agent wrote all 12, following the reusable brief
(`docs/superpowers/plans/2026-09-29-school-subjects-brief.md`, GRADE = 5, SUBJECTS = maths, science, English: the
research's new units only), with grade 5's written units of those subjects and grade 4's core units as the model.
Branch `worktree-agent-ae375bd317e325404`, from `lead-merge` at 64f4f821. Grade 5's maths (18), science (17) and English
(18) now have every unit of the outline written. Grade 5 computing, art and music (another agent, "g5a") were not
touched.

## What was written
| Unit | Cards | Hand-written exercises (levels 1/2/3) | Kinds | Generators (g5c) |
|---|---|---|---|---|
| maths `percent_intro` (Percentages) | 8 | 19 (6/7/6) | number, choice, true or false, match, order, sort | `percent_square`, `percent_convert`, `percent_of`, `discount`, `percent_order` |
| maths `angles_triangles_quads` (Angles in triangles and quadrilaterals) | 8 | 18 (5/7/6) | number, choice, true or false, sort, order | `angle_line`, `angle_point`, `angle_cross`, `triangle_angle`, `quad_angle` |
| science `forces_machines` (Friction, air resistance and machines) | 8 | 18 (5/7/6) | choice, true or false, sort, match, order, number | `force_name`, `friction_test`, `lever_push`, `machine_gears` |
| science `electric_systems` (Electric systems) | 8 | 18 (6/7/5) | choice, true or false, number, sort, match, order | `circuit_lit`, `circuit_bright`, `circuit_symbol` |
| science `reproduction_life` (How living things reproduce) | 8 | 18 (5/7/6) | choice, true or false, order, match, sort | `cycle_order`, `seed_travel`, `young_birth` |
| science `breathing_heart` (Breathing and the heart) | 8 | 18 (5/7/6) | choice, true or false, order, number, match, sort | `pulse_rate`, `body_path`, `organ_match` |
| English `quote_to_prove` (Quote to prove it) | 8 | 17 (5/6/6) | choice, true or false, order, sort | `quote_pick`, `quote_exact` |
| English `many_sources` (Many sources, one answer) | 8 | 17 (5/6/6) | choice, true or false, match, sort, order | `source_pick` |
| English `write_opinion` (Write an opinion piece) | 8 | 17 (5/6/6) | choice, true or false, order, sort | `opinion_link`, `formal_pick` |
| English `write_explain` (Write to explain) | 8 | 17 (5/6/6) | choice, true or false, order, sort | `text_feature` |
| English `story_techniques` (Story techniques) | 8 | 17 (5/6/6) | choice, true or false, sort, order | `show_feeling`, `speech_marks` |
| English `present_speak` (Speak and present) | 8 | 16 (5/6/5), 3 to listen to | choice, true or false, order, sort | `summary_pick` |
| **All** | **96** | **210** | choice 103, true or false 44, number 22, order 19, sort 16, match 6 | 32 generators, each at levels 1-3 |

- **Files:** `data/school/g5/<subject>/<unit>.json`, linked from `data/school/grade5.json` (only these 12 units gain a
  `file` line; titles and goals kept).
- **Every unit:** 8 cards that open with "Quick memory:" and a question from an earlier unit or grade (its answer in
  brackets), teach one idea a card with a worked example and a picture where it helps, and end "Try it in the world: …
  Next: …" (research §5.3 rules 1, 7 and 8). 16-19 hand-written exercises of 4-6 kinds at levels 1-3, each with a hint
  (a strategy) and an explain (the worked answer). Every unit also has g5c generators.
- **Percentages (Singapore P5, England Y6):** per cent as "out of 100" on a hundred square, the whole as 100%, fractions,
  decimals and percentages as one amount (1/2, 1/4, 3/4, 1/10, 1/5 by heart; ×100 for decimals), a percentage of an
  amount built from 10% (and 5% as half of it), a 25% discount on a 40-gold saddle as a bar model. Builds on grade 4's
  hundredths and pie charts; next, grade 6's percent unit.
- **Angles (Singapore P5, England Y6):** angles on a straight line (180°), round a point (360°), vertically opposite
  angles, the triangle (torn corners make a straight line) and quadrilateral (two triangles: 360°) sums, isosceles and
  equilateral triangles, parallelograms' opposite angles. Builds on grade 4's measured angles; next, grade 6's area of
  triangles and grade 7's angle facts.
- **Forces and machines (England Y5, Singapore P6 preview):** friction against the motion, useful and a nuisance, oil;
  air resistance (a parachute; newtons), water resistance and streamlining; levers (push far from the pivot), pulleys
  (a moving pulley halves the effort), gears (a small gear turns a big one slower, with more force); balanced forces at a
  steady speed; the hammer and feather on the Moon. Builds on grade 3's forces and grade 5's gravity.
- **Electric systems (Singapore P5, England Y6; the Lab's circuit):** symbols (cell, battery, lamp, switches, buzzer,
  motor), safety (sockets, water, power lines, button batteries), series circuits (dimmer with more lamps, all out if one
  breaks; voltage, about 1.5 V a cell), parallel circuits (each branch its own path, as bright as a lamp alone; homes),
  a branch's switch and a main switch; the Lab card in the Lab's own words.
- **Reproduction (Singapore P5, England Y5):** a flower's parts and jobs, pollination by animals and wind, the ovule
  becoming a seed, seeds travelling, spores (ferns, mosses, fungi), new plants from one parent (tubers, bulbs, runners);
  mammals born alive and fed on milk (the platypus lays eggs), birds' eggs, metamorphosis in amphibians and insects,
  nymphs; Maria Sibylla Merian (1705). Plants and animals only (research §5.4 rule 4).
- **Breathing and the heart (Singapore P5, England Y6):** the air's path to the air sacs, the diaphragm breathing in and
  out, gas exchange (21% oxygen in, about 16% oxygen and 4% carbon dioxide out), the heart (a fist, about 100,000 beats a
  day), arteries, veins, capillaries, the double loop (Ibn al-Nafis, 1200s; William Harvey, 1628), the pulse (about 70 to
  110 a minute at rest for a child) and exercise, blood is always red. Builds on grade 4's digestion; next, grade 6's
  body systems.
- **Quote to prove it (RL.5.1, RI.5.1):** quoting exact words in speech marks, the ellipsis, explicit answers and
  inferences from a clue, Point-Evidence-Explain, the best quote; our own passage about Juno and an overgrown garden.
- **Many sources (RI.5.7, RI.5.9):** kinds of sources, finding answers fast (contents, index, headings, glossary; skim and
  scan), checking facts in two or more sources, integrating facts about honeybees by topic, notes with sources.
- **Write an opinion piece (W.5.1, L.5.3b, England Y6):** a clear opinion, reasons in a logical order (strongest last),
  facts and details (specifically), linking words for results, additions and contrasts, formal and informal language
  (If I were; the formal "results will be announced").
- **Write to explain (W.5.2):** title, introduction, sections with subheadings, definitions and a glossary, facts and an
  expert's quotation, cause-and-effect linking words (because, as a result, in contrast, especially), precise words,
  present tense, third person, diagrams and captions, a conclusion (volcanoes as the example).
- **Story techniques (W.5.3, England Y6 composition):** dialogue and its punctuation, speech verbs, the senses, show
  don't tell, pacing with short and long sentences, characters' responses, time words.
- **Speak and present (SL.5.2-5.4, England Y6 spoken language):** purpose and audience, a hook, main points with facts,
  cue cards, a steady pace with pauses (claps to listen to: steady, rushed, and grouped with a pause), eye contact,
  practice, listening for points and their support, summarising a talk.

## The Science Lab (spec §23)
The Lab's `circuit` experiment lists `g5.science.electric_systems`, so its page shows TRY IT IN THE LAB, and card 7 says
what the Lab does in its own words (close the switch, take out a wire to make a gap, add a second bulb: both glow more
dimly). `test_the_lab_experiment_matches_the_lesson` checks it. `tests/integration/test_lab_links.gd` used this unit as
its "Coming soon" case; it now picks any unit the Lab lists that is not written yet (today
`g8.science.circuits_voltage`), and passes when there is none.

## Generators (`core/school/gen/g5_core_gen.gd`, `G5CoreGen`, "g5c", registered last in `SchoolGen.SOURCES`)
32 generators, each at levels 1-3, with a hint, a worked answer and `data`:
- percentages: `percent_square` (a hundred square: shaded, not shaded, as a decimal), `percent_convert` (tenths and
  hundredths; decimals both ways; halves to fiftieths, and a percentage as a fraction in its simplest form),
  `percent_of` (50% and 10%; 25%, 75%, 20-40%; 5%, 15%, 35%, 45%, 60-90%, as sums or stories), `discount` (the gold off;
  the sale price; harder discounts or the cheaper of two shops), `percent_order` (the largest of three or four mixed
  forms; four in order);
- angles: `angle_line`, `angle_point`, `angle_cross`, `triangle_angle` (a right angle as its square; isosceles),
  `quad_angle` (parallelograms; two equal angles marked a), every one with its picture;
- forces: `force_name` (21 situations), `friction_test` (two surfaces; a toy car's results table: the most friction,
  the order, how much farther), `lever_push` (levers as picture choices), `machine_gears` (which way; how many turns;
  three gears or a moving pulley);
- circuits: `circuit_lit` (how many lamps light; series, parallel, a main switch; true or false about a lettered lamp),
  `circuit_bright` (brighter, dimmer or the same as one lamp on one cell; the brightest of three circuits),
  `circuit_symbol` (what a symbol stands for; which symbol is a part);
- life: `cycle_order` (12 life cycles; the missing stage from a drawn cycle), `seed_travel` (12 plants, 6 ways),
  `young_birth` (eggs or live young; the platypus);
- body: `pulse_rate` (15, 10 or 30 seconds; breaths; after exercise), `body_path` (the air's path; the blood's loop),
  `organ_match`;
- English: `quote_pick` (12 short texts), `quote_exact`, `source_pick`, `opinion_link`, `formal_pick`, `text_feature`,
  `show_feeling`, `speech_marks`, `summary_pick`.
`tests/unit/test_g5_core_gen.gd` (33 tests, 80 seeds × 3 levels) works every answer out again from the exercise's
picture and `data` with its own facts and rules: its own percent arithmetic, angle sums, a circuit rule of its own,
friction order, gear turns, life cycles, seed ways, animals, the blood's loop, the body's jobs, keyword tables for the
English banks, a formal/informal marker list, and a speech-mark rule checker (marks round the words, punctuation inside,
capitals, a split sentence in small letters, a question asked with ?, only a speech tag outside the marks).

## Pictures (`ui/school/school_picture_g5core.gd`, `SchoolPictureG5Core`)
Eight kinds drawn from data (the header lists their fields), hooked into SchoolPicture after SchoolPictureG5Life (one
header line pair, one `problem()` block, one `draw()` block ending in `return`):
`hundred_square` (a big 10 × 10 square, whole rows first; a label only when a lesson wants one), `angle_facts`
(straight, point, cross, triangle, quad: corners computed from the angles by the law of sines, a quad as two triangles
on its diagonal; labels, "?", letters, right-angle squares, equal-side ticks), `circuit_symbols` (a key of symbols in
rows, or a circuit in series or in parallel with a main switch, cells, lettered loads and lamps that glow as `power`
says), `force_arrows` (a crate, a toy car, a parachute, a skydiver, a boat or a ball, arrows by size, grounds from ice
to sand), `life_cycle` (boxes round a loop with arrows), `flower_parts` (a cut flower: parts or stamen and carpel named,
one in orange or "?", a bee with pollen), `lungs` (breathing in or out: the diaphragm, ribs, windpipe, heart) and
`blood_loop` (lungs, heart and body with blue and red vessels and the flow). The rules they draw by are tested in
`tests/integration/test_school_picture_g5core.gd` (7 tests: samples valid at four sizes, every kind and mode sampled,
the angle corners measured again, the circuit rule, only the marked part orange, broken data found).
`tests/unit/test_school_picture_kinds_unique.gd` now lists G5Life and G5Core too.

**Looked at in a real window** (`tools/school_shots.gd -- --unit=… --exercises`, every unit with pictures): the first
hundred square was the `bar` kind's (58 px, with a "42/100" label that gave the answer away), so `hundred_square` was
made; angle labels sat on the vertex (now at least half a ray out, bigger, and a cross's lines use the card's width);
forces and labels were small (bigger now; no speed lines under an arrow pointing back); the circuit key had six tiny
symbols in one row (now rows, names under each); a tag on the top row fell off the card (room left now); the blood
loop's unnamed lung vessels turned orange with no mark (fixed; `part_colour` tested). The tables, bar models, flowers,
life cycles, lungs and circuits then read clearly in lessons and exercises.

## Rulings (decide and write down; cost if wrong)
1. **Every lesson opens with "Quick memory:" and ends with "Try it in the world: … Next: …"** (as grade 4's core units);
   the test enforces it. *Cost:* none.
2. **One generator source, `g5c`, for all three subjects** (the lead's letter), 32 generators, every unit using some,
   the maths units at every level. *Cost:* a rename if another branch took `c`.
3. **A new `hundred_square` kind instead of the `bar` kind's hundred square**, which is too small to count and names its
   own fraction. Other units' `bar` pictures are unchanged. *Cost:* none; the `bar` kind could adopt it later.
4. **Percentages use the game's gold** (research §5.5 ruling 6), whole answers, discounts of 5-75%. *Cost:* none.
5. **Quadrilaterals are convex** (every angle under 180°), triangles drawn from their angles; the right angle is shown
   by its square, not "90°", once taught. *Cost:* a reflex quadrilateral would need a new drawing.
6. **Circuits follow an ideal cell:** in series the cells are shared by the loads on the loop; each parallel branch gets
   the full push (as bright as one lamp alone); a main switch sits before the paths split; a branch always holds a lamp,
   buzzer or motor (no short circuits drawn). One cell "about 1.5 V". *Cost:* real cells sag a little; the lesson says
   "about".
7. **Safety in electricity:** sockets, water, power lines and button batteries ("tell a grown-up at once", NHS advice).
   *Cost:* none.
8. **Reproduction is plants' and animals' only** (research §5.4 rule 4): pollination, seeds, spores, one-parent plants,
   live young and eggs, metamorphosis; nothing about human reproduction, and the test bans its words. *Cost:* none.
9. **Breathing and the heart name no drugs, tobacco or vaping** (grade 5's life ruling: only health and PE's "Medicines
   and harmful substances" does); smoke and dirty air are "bad for the lungs". *Cost:* a line if the owner wants it.
10. **Historical figures only:** Ibn al-Nafis, William Harvey, Maria Sibylla Merian; the Moon's hammer and feather
   without the (living) astronaut's name. *Cost:* none.
11. **Speaking is heard as claps** (SchoolSound has no voice): a steady pace, a rushed one and a pause, each clap a word.
   *Cost:* a spoken recording would need audio files (the game makes all sounds in code).
12. **Writing units practise by choosing, sorting, ordering and building sentences** (research §5.3; phones have no good
   keyboard for children), with generators for linking words, formality, features, feelings, speech marks, summaries.
   *Cost:* none.
13. **A child's resting pulse is "about 70 to 110 a minute"** (MedlinePlus 6-10 years: 70-110; Children's Health 5-12:
   75-118); generated pulses at rest are 68-100. *Cost:* none.
14. **The unit files are the source of truth**; the Python that built and checked them (helpers, limits, letters, kind
   words, US spellings, every "a op b = c", orders never shown in order, matches never side by side) stayed in the
   agent's scratchpad.

## Facts checked (and sources)
- Air in about 21% oxygen, 0.04% carbon dioxide; air out about 16% oxygen, 4% carbon dioxide (Save My Exams, CIE O Level
  gas exchange; CK-12).
- Children's resting heart rate (Children's Health Dallas; PMC3789232, median about 82 at 10 years); about 100,000 beats
  a day (70 × 1,440).
- Ibn al-Nafis described the blood's path through the lungs in the 13th century; Harvey's *De Motu Cordis*, 1628
  (Wikipedia; Circulation Research, "William Harvey and the Discovery of the Circulation of the Blood").
- Maria Sibylla Merian, *Metamorphosis insectorum Surinamensium*, 1705 (Public Domain Review, Britannica).
- Worker honeybees live about 5-7 weeks in summer (Mann Lake; Wikipedia, Worker bee).
- Swallowed button batteries: to A&E straight away (Great Ormond Street Hospital, CAPT, NHS England alert).
- Known facts used as taught in England Y5-Y6 and Singapore P5: a cell about 1.5 V, parallel wiring at home, the moving
  pulley halving the effort, the Apollo 15 hammer and feather, the platypus and echidna laying eggs, ferns' spores, the
  frog's, butterfly's, ladybird's, grasshopper's and dragonfly's cycles, seed dispersal (sycamore, dandelion, burdock,
  goosegrass, blackberry, cherry, coconut, water lily, pea, gorse, oak), the elephant's boneless trunk, Etna in Sicily.
- Every sum in the texts is checked by the builder and by `test_the_sums_in_the_lessons_are_right`; generated answers by
  `test_g5_core_gen.gd`.

## Tests
- `tests/unit/test_school_content_g5_core.gd` (written first; it failed 11 of 14, "is written"): the outline has the 12
  units with their files; grade 5's maths, science and English are complete; every unit meets the bar (4-8 cards, 12+
  hand-written exercises at levels 1-3 of 2+ kinds, rounds that fill and vary, never a hand-written one twice in a
  round); hints are strategies and every exercise has a worked answer; memory first, world and next last; no question
  twice; every unit uses g5c and every g5c generator is used, the maths units at every level; each unit's pictures;
  hundred squares that never give the answer away; the angle facts and all five figures; circuits in series and in
  parallel with the symbols named; listening in the speaking unit; the Lab's experiment; safety. 14/14.
- `tests/unit/test_g5_core_gen.gd`: 33/33. `tests/integration/test_school_picture_g5core.gd`: 7/7.
- The School's and the Lab's tests together (every `test_school*`, `test_g5*`, `test_lab*`, unit and integration): 554
  of 554 in 60 scripts; the shared `test_school_content.gd` counts 7,117 hand-written exercises in all written units.
- The full suite: see the end of this file.

## For the lead when merging
- `data/school/grade5.json`: only the 12 units gain a `file` line (the g5a branch adds its own to computing, art and
  music units of the same file: a textual merge, no overlap).
- `core/school/school_gen.gd`: one SOURCES line at the end, `"g5c"` (g5a adds its line at the same place: keep both).
- `ui/school/school_picture.gd`: two header lines and a `problem()` and a `draw()` block for `SchoolPictureG5Core`
  after the G5Life ones (g5a may add SchoolPictureG5Arts at the same places: keep both, each draw block ending in
  `return`).
- `tests/unit/test_school_picture_kinds_unique.gd`: the lists gain "G5Life" and "G5Core" (add g5a's list beside them).
  My kinds: hundred_square, angle_facts, circuit_symbols, force_arrows, life_cycle, flower_parts, lungs, blood_loop;
  check none is in g5a's KINDS.
- `tests/integration/test_lab_links.gd`: the "Coming soon" case picks any unwritten unit the Lab lists.
- `docs/DEVELOPMENT.md`: one bullet after the grade 5 life bullet.
- After the merge: `godot --headless --path . --import` (new classes `SchoolPictureG5Core`, `G5CoreGen`).
- Not done here (to avoid conflicts with the other agents): `python3 tools/school_outline.py --write
  docs/superpowers/plans/2026-09-28-school.md`, spec §22.4's "as built" for grade 5, RESUME-HERE and the owner-feedback
  row.
- Next for these subjects (the game never ends): grade 6's research units still "Coming soon", and in-world build
  challenges for percentages (a shop's sale) and angles.

## The full suite
`tests/run_tests.sh` on this branch at 665bdaa9 (all 12 units written): **7,504 tests in 813 scripts: 7,501 passing,
1 failing, 2 risky** (the two world tests that never assert, as before), no script errors. The one failure was
`tests/integration/test_nakama_account_key.gd` ("the wallet's gold": 2000, not 1000), which runs against the shared local
Nakama dev server that other agents' suites use at the same time; run again on its own it passes (1/1), and nothing on
this branch touches profiles, gold or the server. The School's and the Lab's tests (every `test_school*`, `test_g5*`,
`test_lab*`): 554 of 554.
