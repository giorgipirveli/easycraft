# Grade 4 maths, science and English: the research's new units written (owner #70, #73; 2026-09-29)

The owner: "start from grade 3 and finish all grades accordingly" and "research school programs, world leading schools
and create better school program". The research (`docs/design/school-curriculum-research.md` §6.4) merged Singapore P4
and England Y5 into grade 4 and added 11 units to the maths, science and English that were written in 2026-09-28's
first outline; they showed "Coming soon". This agent wrote all 11, following the reusable brief
(`docs/superpowers/plans/2026-09-29-school-subjects-brief.md`, GRADE = 4, SUBJECTS = maths, science, English: the
units with no `file`), with grade 4's written units of those subjects and grade 3's as the model. Branch
`worktree-agent-a94d3c56be40ceaba`, from `lead-merge` at 6b51a1d. Grade 4's maths (18), science (17) and English (18)
now have every unit of the outline written.

## What was written
| Unit | Cards | Hand-written exercises (levels 1/2/3) | Kinds | Generators |
|---|---|---|---|---|
| maths `tables_line_graphs` (Tables, line graphs and pie charts) | 8 | 19 (5/8/6) | number, choice, true or false, match, order, sort | `g4d.table_read`, `table_missing`, `line_read`, `line_change`, `pie_read` |
| science `circuits` (Electric circuits) | 8 | 18 (6/7/5) | choice, true or false, sort, order, match | `g4c.circuit_lights`, `conductor_sort` |
| science `heat_temperature` (Heat and temperature) | 8 | 19 (5/8/6) | number, choice, true or false, sort, match, order | `g4c.thermo_read`, `temp_change`, `heat_flow` |
| science `states_of_matter` (Solids, liquids and gases) | 8 | 19 (6/7/6) | choice, true or false, sort, match, number, order | `g4c.state_at`, `state_change` |
| science `sound` (Sound and hearing) | 8 | 19 (5/8/6) | choice (3 to listen to), true or false, sort, order, match | `g4c.sound_wave` |
| science `digestion_teeth` (Digestion and teeth) | 8 | 19 (5/8/6) | choice, true or false, order, match, number, sort | `g4c.gut_order` |
| English `myths_tales` (Myths and traditional tales) | 8 | 19 (5/7/7) | choice, true or false, match, sort, order | `g4c.myth_phrase` |
| English `accounts_evidence` (Accounts, reasons and evidence) | 8 | 18 (4/8/6) | choice, true or false, sort, order, match | `g4c.account_sort` |
| English `write_opinion` (Write an opinion) | 8 | 17 (4/7/6) | choice, true or false, order, sort | `g4c.link_word` |
| English `write_report` (Research and report) | 8 | 18 (5/7/6) | choice, true or false, sort, order, match | none |
| English `write_narrative` (Write a narrative) | 8 | 18 (5/7/6) | choice, true or false, order, sort | none |
| **All** | **88** | **203** | choice 115, true or false 34, number 19, order 14, sort 12, match 9 | 17 generators, each at levels 1-3 |

- **Files:** `data/school/g4/<subject>/<unit>.json`, linked from `data/school/grade4.json` (only these 11 units gain a
  `file` line; titles and goals kept).
- **Every unit:** 8 cards that open with "Quick memory:" and a question from an earlier unit or grade 3 (its answer in
  brackets: the heat unit asks what "Energy on the move" taught, the myths unit the Beaver and the Heron's message, the
  digestion unit grade 3's growing foods), teach one idea a card with a worked example and a picture where it helps,
  and end "Try it in the world: … Next: …" (research §5.3 rules 1, 7 and 8). 17-19 hand-written exercises, at least 4 at
  level 1, 7 at level 2 and 5 at level 3, of 4-6 kinds, each with a hint (a strategy) and an explain (the worked answer).
- **Maths (Singapore P4 statistics, England Y5):** tables (read along a row and down a column, a Total column, a missing
  number from the total, a two-way table's totals), line graphs (time along the bottom, reading a point on or halfway
  between lines, rises and falls, the steepest part), pie charts cut into equal parts (a slice's fraction, what one part
  stands for, how many more, how many were asked), which chart for which question. Builds on grade 3's bar graphs;
  next, grade 5's grid and percentages.
- **Circuits (England Y4, the Lab's circuit):** mains and battery safety (sockets), a complete loop from + to −, a cell,
  a gap and a switch, conductors and insulators (and water), testing a material across the gap, two bulbs in one loop
  glowing more dimly, a flat battery; the world idea is the game's lever and lamp. Next: grade 5's circuit symbols.
- **Heat and temperature (Singapore P4 heat, the Lab's melting):** °C and a thermometer's small marks, 0 °C, 100 °C, 20 °C
  and 37 °C, below zero with the minus sign (a freezer at about −18 °C), heat flowing from hotter to colder ("cold does
  not flow"), good and poor conductors of heat, insulators that trap air (a coat keeps your own heat in), the
  thermometer staying at 0 °C while ice melts, why metal feels colder at the same temperature.
- **Solids, liquids and gases (England Y4, Singapore P4 matter):** matter has mass and takes up space; the three states
  in jars (sand is a solid), volume kept when poured, melting and freezing at 0 °C, iron at 1,538 °C, boiling at 100 °C,
  evaporation below boiling and what speeds it, condensation (a cold can, a mirror), the water cycle. Next: grade 5's
  particles.
- **Sound (England Y4, 4-PS4-1):** vibrations, through air, water and solids (none in space), the eardrum and tiny
  bones, loud sounds and hearing, volume and taller waves, pitch and waves closer together (a low then a high note to
  listen to), shorter, tighter, thinner strings and smaller drums sound higher, muffling. Next: waves, then light.
- **Digestion and teeth (England Y4, Singapore P4):** the mouth (saliva), gullet, stomach (acid, a few hours), small
  intestine (about 6 metres, into the blood), large intestine (water back, the rectum and the toilet); incisors,
  canines, premolars and molars and their jobs, 20 milk teeth and up to 32 adult teeth, sugar, germs and acid, brushing
  twice a day for about two minutes with fluoride toothpaste. Next: grade 5's heart and lungs.
- **Myths and traditional tales (RL.4.9, RL.4.4):** tales told aloud before they were written; patterns (quests, good
  and evil, threes, tricksters, greed and pride); Anansi and the sky god's stories (West Africa); Cinderella and Ye Xian
  (China) compared; a Herculean task, an Achilles' heel, an odyssey, Pandora's box, the Midas touch; Thor and Maui as
  other cultures' myths.
- **Accounts, reasons and evidence (RI.4.6, RI.4.8):** first-hand (I, we, what the writer saw and felt) and second-hand
  accounts (more facts, dates, numbers), Mimi's diary and the report of the same small earthquake, why accounts differ,
  point, reason and evidence (bees and fruit trees), weak and strong evidence, the best source for a question.
- **Write an opinion (W.4.1):** a clear opinion, two or three reasons, facts and details, linking words (for example, in
  addition, in order to), a conclusion in new words, a worked pet-fish piece.
- **Research and report (W.4.2, W.4.7, W.4.8):** questions first, a few trusted sources that agree, notes in key words
  sorted into sections (bats' food and homes, as a table), own words and speech marks for quotes, a report's parts,
  exact words and special words explained, a list of sources.
- **Write a narrative (W.4.3, England Y5 composition):** an opening with a hook, events in order with time phrases,
  dialogue and speech words, the senses, showing feelings, an ending that follows from the story.

## The Science Lab (spec §23)
The Lab's `circuit` experiment lists `g4.science.circuits` and its `melting` experiment `g4.science.heat_temperature`
and `g4.science.states_of_matter`: those pages show TRY IT IN THE LAB, and their lessons match the experiments: the
circuits lesson says to close the switch, take out a wire to make a gap, and add a second bulb so both glow more dimly
(the Lab's result, in the same words); the heat lesson warms ice from −20 °C and says the thermometer stays at 0 °C while
it melts; the states lesson melts at 0 °C, boils at 100 °C and freezes again. `test_the_lab_experiments_match_the_lessons`
checks this from the Lab's own data (its scene's `melt` and `boil`), and `test_lab_links.gd` now checks that every
written unit an experiment lists fits its page with the button (its "Coming soon" case moved to
`g5.science.electric_systems`).

## Generators
- **`g4d`** (`core/school/gen/g4_data_gen.gd`, `G4DataGen`), every exercise with its picture: `table_read` (a cell or the
  row with the most; how many more; a row's or a column's total), `table_missing` (a Total column; three columns; a Total
  row too, so the missing number is found along its row or down its column), `line_read` (a point on a line of a 2s, 5s
  or 10s scale, or the highest point; a point halfway between two lines, or the lowest; when it showed a value, or
  halfway on a 10s or 20s scale), `line_change` (up, down or the same; by how much it rose or fell; over more than one
  step, or where it rose the most), `pie_read` (a slice's fraction or how many, in halves and quarters; thirds, sixths
  and eighths; how many more, or how many were asked, in sixths, eighths and twelfths). Topics: a farm's fruit, blocks
  mined, class pets, pages read; a day's temperature, a sunflower, Bram's savings, museum visitors, a rain barrel;
  fruit, ways to school, pets, snacks, team colours.
- **`g4c`** (`core/school/gen/g4_core_gen.gd`, `G4CoreGen`): `circuit_lights` (true or false from a circuit picture drawn
  with "?" bulbs: a switch; a gap and bulbs, buzzers or motors; a conductor or an insulator across the gap, sometimes
  with the switch open), `conductor_sort` (4-6 things), `thermo_read` (numbers only; marks of 1, 2 or 5; below zero),
  `temp_change` (in 5s; warmer or colder stories; across zero, counted to 0 and on), `heat_flow` (named things; two
  blocks, sometimes at the same temperature; two icy things below zero), `state_at` (water far from and near 0 °C and
  100 °C; gold, iron, aluminium and tin by their melting points), `state_change` (19 everyday events: 2, 4 or 5
  choices), `sound_wave` (the loudest or quietest; the highest or lowest pitch; three sounds), `gut_order` (3, 4 or 5 of
  the food's path, the labelled body at level 1), `myth_phrase` (what a phrase means; match four; in a sentence),
  `account_sort` (4-6 sentences; the worked answer lists each group when it fits), `link_word` (12 opinion sentences:
  3 choices, then 4).
- Registered at the end of `SchoolGen.SOURCES` (`"g4d"`, then `"g4c"`). `tests/unit/test_g4_data_gen.gd` (5 tests) and
  `tests/unit/test_g4_core_gen.gd` (12 tests) run 80 seeds × 3 levels and work every answer out again from the
  exercise's picture and `data`, with their own facts (which things are metals, melting points, the food's path, the
  changes of state, the phrases' meanings, the words of first-hand and second-hand accounts, which linking words fit
  each gap).

## Pictures (`ui/school/school_picture_g4core.gd`, `SchoolPictureG4Core`)
Seven kinds drawn from data (the header lists their fields), hooked into SchoolPicture like the history numerals (two
header lines, two dispatch blocks): `line_graph` (a scale of 1-10 steps from `from`, labels along the bottom, a marked
point), `pie_chart` (slices of equal parts from the top, clockwise, faint part lines, a key or names on the slices),
`circuit` (a loop of copper wire with the Lab's own battery, bulb and knife switch, `LabArt`; bulbs, buzzers and motors
along the top, a switch on the right, a gap in the bottom with what bridges it; `works()` is the complete-loop rule;
two bulbs glow a quarter as brightly; `glow: "?"` for "will it work?"), `thermometer` (1-3 side by side with names, minor
marks, minus signs; one on a wide card lies down with its scale underneath, so an exercise's numbers are big),
`states` (jars: a solid block, a liquid with a flat top, a gas's dots filling a closed jar), `teeth` (one jaw from above
on a half-ellipse arch, adult or milk, a colour key or one kind in orange) and `digestion` (a body with the mouth,
gullet, stomach, the coiled small intestine and the large intestine round it, labels, one organ in orange). Samples in
`tests/integration/test_school_picture_g4core.gd`: valid, drawn at three sizes, broken data found, the loop rule, the
jaws, the pie's parts.

**Looked at in a real window** (`tools/school_shots.gd -- --unit=… --exercises` for the maths unit, circuits, heat,
states, digestion, sound and the report): the circuits read clearly (the open switch lifted, the steel spoon across the
gap, two dimmer bulbs); the first thermometers were thin with small numbers and the first teeth arch used half a wide
card, so the thermometer lies down on wide cards (bigger numbers) and the arch became a half ellipse that fills the
card; the tables, line graphs, pie charts, jars, waves and the notes table fit.

## Rulings (decide and write down; cost if wrong)
1. **Every lesson opens with "Quick memory:" and ends with "Try it in the world: … Next: …"** (like grade 4 humanities),
   and the test enforces it. *Cost:* none.
2. **Two new generator sources, `g4d` (the lead's name) and `g4c`** ("core": science and English together, one letter
   not used in grade 4; other grade 4 agents at work use `g4a`). *Cost:* a rename if another branch took `c`.
3. **Pie charts are drawn cut into equal parts** (Singapore P4 reads fractions of a whole, not angles or percentages);
   wholes of 2, 3, 4, 6, 8 and 12 parts. Percentages wait for grade 5's unit. *Cost:* a `percent` field later.
4. **Temperatures are metric and exact where they are facts** (0, 100, 37, about 20 for a room, about −18 for a freezer,
   iron 1,538, gold 1,064, aluminium 660, tin 232 °C); water "above 100 °C is a gas" (at sea level, as the Lab says).
   *Cost:* none.
5. **Circuits use "battery" and "cell" both** (England Y4 says cell; children say battery): the lesson says a battery's
   proper name is a cell. The pictures reuse the Lab's own battery, bulb and switch drawings, so a lesson looks like the
   Lab. *Cost:* none.
6. **Digestion stops at the rectum and "the toilet"** (England Y4's parts); nothing about reproduction (research §5.4
   rule 4, and the test checks it). The gullet is named "gullet (oesophagus)" once, then gullet. *Cost:* a word.
7. **Myths are culture and belief** (research §5.4 rule 1): "myths are very old stories people told to explain the
   world"; Greek, Norse, West African, Chinese and Polynesian tales, all as stories; only the Midas story's lesson and
   the tales' patterns are taught as meanings. *Cost:* none.
8. **Tooth care is general** (twice a day, about two minutes, fluoride toothpaste, sugar at mealtimes), no brands or
   amounts of toothpaste. *Cost:* none.
9. **Writing units have no generators**: writing is taught with choose-the-best-sentence, fix-it, sort and build-the-
   sentence exercises (research §5.3); opinions get the linking-word drill and accounts a sorting drill. *Cost:* one
   generator each later.
10. **"Next" names the next unit of the teaching order or grade 5's unit** it leads to. *Cost:* none.
11. **A thermometer lies down on a wide card** (a single value, no names, wider than 1.8 times its height): children read
   big numbers under the tube; in lessons (taller cards) it stands up like the Lab's. *Cost:* none.
12. **The unit files are the source of truth**; the Python that wrote them (helpers, limits, letters, kind words, US
   spellings, every "a op b = c" worked out, orders never shown in order, matches never side by side) stayed in the
   agent's scratchpad.

## Tests
- `tests/unit/test_school_content_g4_core.gd` (written first; it failed 11 of 11: "names its file", "is written"): the
  outline has the 11 units with their files; grade 4's maths, science and English are complete; every unit meets the bar
  (4-8 cards, 12+ hand-written exercises at levels 1-3 of 2+ kinds, rounds that fill and vary, never a hand-written one
  twice in a round); hints are strategies and every exercise has a worked answer; memory first, world and next last; no
  question twice; the maths unit uses g4d at every level, the others g4c, and every g4d and g4c generator is used; the
  pictures each unit needs; sound is listened to; the Lab's experiments match; safety. 11/11 passing (88 cards, 203
  exercises).
- `tests/unit/test_g4_data_gen.gd` and `tests/unit/test_g4_core_gen.gd` (written first; they failed with "makes an
  exercise"): 5 + 12 tests, all passing.
- `tests/integration/test_school_picture_g4core.gd` (written first; it failed to parse before the class existed): 8/8.
- `tests/integration/test_lab_links.gd`: 7/7 (the new page-fit test included).
- The School's and the Lab's tests together (every `test_school*`, `test_g4_*`, `test_lab*`, unit and integration): 400
  of 400 passing; the shared `test_school_content.gd` counts 5,267 hand-written exercises in all written units.
- The full suite: see the end of this file.

## For the lead when merging
- `data/school/grade4.json`: only the 11 units gain a `file` line (other grade 4 agents add theirs to other units of
  the same file: a textual merge, no overlap).
- `core/school/school_gen.gd`: two SOURCES lines at the end, `"g4d"` then `"g4c"` (the arts branch adds `"g4a"` at the
  same place: keep all three).
- `ui/school/school_picture.gd`: two header lines and two dispatch blocks for `SchoolPictureG4Core` after the history
  ones (the arts branch adds `SchoolPictureG4Arts` at the same places: keep both).
- `tests/integration/test_lab_links.gd`: the "Coming soon" case uses `g5.science.electric_systems`; a new test.
- `docs/DEVELOPMENT.md`: one bullet after the grade 4 humanities bullet.
- After the merge: `godot --headless --path . --import` (new classes `SchoolPictureG4Core`, `G4DataGen`, `G4CoreGen`).
- Not done here (to avoid conflicts with the other agents): `python3 tools/school_outline.py --write
  docs/superpowers/plans/2026-09-28-school.md`, spec §22.4c's "as built", RESUME-HERE and the owner-feedback row.
- Next for these subjects (the game never ends): grade 5's `percent_intro`, `electric_systems` (which the Lab's circuit
  already lists) and the other grade 5 units still "Coming soon".

## The full suite
`tests/run_tests.sh` on this branch at bff979c (all 11 units written): **7,247 tests in 788 scripts: 7,245 passing,
0 failing, 2 risky** (the two world tests that never assert, as before), no script errors, exit 0. Then two texts were
proofread (the odyssey card now says "a long, adventurous journey" like its drills; a hint says sockets are kept away
from baths and sinks), and the School's and the Lab's tests (every `test_school*`, `test_g4_*` and `test_lab*`, unit and
integration) were run again on the final state: 400 of 400 passing.
