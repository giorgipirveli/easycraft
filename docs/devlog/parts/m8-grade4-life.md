# Grade 4 health and PE, design and technology, projects: every unit written (owner #70, #73; 2026-09-29)

The owner: "start from grade 3 and finish all grades accordingly" and "research school programs, world leading schools
and create better school program". The research (`docs/design/school-curriculum-research.md` §6.4) lists grade 4's
Health and PE (11), Design and Technology (9) and Projects (3) units; this agent wrote all 23 of them, following the
reusable brief `docs/superpowers/plans/2026-09-29-school-subjects-brief.md` (GRADE 4, SUBJECTS health_pe, design_tech,
projects), in parallel with the agents writing grade 4's history, geography and citizenship, and its computing, art and
music. Built on grade 3's units of the same subjects (`docs/devlog/parts/m8-grade3-life.md`).
Branch `worktree-agent-a7caa1e0a9680cb8d`, from `lead-merge` b72e3d4 ("the Lab live; the space worlds' looks").

## What was written
| Subject | Units | Lesson cards | Hand-written exercises | Generators used (g4w) |
|---|---|---|---|---|
| Health and PE | 11 | 88 | 169 | find_space, jump_measure, relay_time, circuit_training, fitness_sort, label_light, sugar_cubes, orienteer |
| Design and Technology | 9 | 72 | 135 | circuit_lights, wheel_roll, fabric_cut, frame_struts, bread_recipe, bake_time, meal_missing, user_survey, material_job, invention_order |
| Projects | 3 | 24 | 45 | museum_sort, river_fields, tune_shape, circuit_lights |
| **All** | **23** | **184** | **349** | **21 new generators**, each at levels 1-3 |

- **Files:** `data/school/g4/<subject>/<unit>.json`, linked from `data/school/grade4.json` (only these 23 units' `file`
  fields changed; titles, standards and goals kept; tab indentation kept).
- **Every unit:** a lesson of 8 cards that opens with "Quick memory: …?" (a question from grade 3's units, its answer in
  brackets, then what today builds) and ends with "Try it in the world: …" (research §5.3 rules 1, 7 and 8); 14-17
  hand-written exercises at levels 1, 2 and 3 (at least 4, 5 and 5, so a round never repeats one), of 4-7 kinds: choice
  (164), true or false (76), number (35), sort (25), order (22), match (22) and build (5). Every exercise has a hint (a
  strategy, never the answer) and an explain (the worked answer).
- **Health and PE** (England PE and RSHE, SHAPE America, NHES, CASEL): striking and fielding (rounders: batting square,
  4 posts numbered anticlockwise, a rounder; side-on batting, aiming for spaces; the long barrier; catching fingers up
  or down; throwing to the next post; cricket's 3 stumps, 2 bails, 6 over the boundary); attack and defend (invasion
  games, free and marked players on a pitch, pass and move, marking goal-side, intercepting, width and depth, netball's
  3 seconds, dribbling); gymnastics sequences (start and finish shapes, the five basic jumps, soft landings, transitions,
  the forward roll, contrasts, unison, canon, mirroring, counter balance and tension; a partner mirror build);
  athletics (personal bests, sprint starts, relay changeovers in the box, the long jump measured from the board, the
  triple jump, the shot pushed; m and cm); parts of fitness (stamina, strength, speed, flexibility; a three-part
  warm-up, a cool-down, circuit training; 60 minutes a day on average, muscles and bones on 3 days a week); reading food
  labels (per 100 g, the UK traffic lights, sugars low at 5 g or less and high above 22.5 g, 4 g sugar cubes, 24 g of
  free sugars and 5 g of salt a day for ages 7 to 10, ingredients by amount, allergens in bold, use by, drinks: water and
  milk, 150 mL of juice); big feelings (anger's warning signs, box breathing, worry: likely? what can I control?, the
  5, 4, 3, 2, 1 game, sadness, asking for help is brave); safe and unsafe (the right to feel safe, body warning signs,
  surprises and unsafe secrets, your body belongs to you, the helping hand of five trusted adults, keep telling,
  Childline 0800 1111, online secrets and dares); water safety (the RNLI's red and yellow, red, chequered flags and the
  orange windsock; the Water Safety Code; float to live for 60 to 90 seconds; rip currents; 999 and the Coastguard,
  or the fire service inland; throw, don't go; 25 m); first aid basics (danger first, small cuts, bleeding that will not
  stop, bruises: something cold for about 10 minutes, head bumps and the signs to get help, burns: cool running water for
  20 minutes, cling film, never ice or butter); outdoor adventure (orienteering: start triangle, control circles, the
  finish's double circle, setting the map, map colours, 8 compass points, team challenges, 6 whistle blasts, the
  Countryside Code).
- **Design and Technology** (England D&T, Finland's, Estonia's and Japan's crafts and home economics, China's labour):
  electrical products (circuits, switches, a torch, a fan and an alarm, pressure pads, conductors and insulators,
  battery safety); wheels and axles (chassis, axles, holders, fixed and free axles, parallel axles at right angles,
  round wheels, friction, a wheel rolls its distance round each turn, a fair ramp test); make a bag (design, fabrics,
  a paper pattern, 1 cm seam allowances, right sides together, backstitch, hems, handles, fastenings, patches); shelters
  and frames (braced frames, domes, guy ropes, sloping roofs, the ger, the tipi, the igloo, triangles in a row); bread
  and grains (wheat 10,000 years ago, the combine harvester, the mill, wholemeal, other grains, a loaf's recipe,
  kneading, yeast's carbon dioxide, rising, flatbreads); plan a balanced meal (the groups and their jobs, the plate,
  meals around the world, swaps, the 4 Cs of food safety, the fridge at 5 °C); design for someone (users, interviews,
  surveys, observing, product analysis, needs and wants, testable design criteria, inclusive design, braille);
  choosing materials (properties, choosing for the job, cost, looks and the planet, recycling, reduce, reuse,
  recycle); inventors and engineers (Al-Jazari 1206, Watt 1769, Volta 1800, the Stephensons' Rocket 1829, Lovelace
  1843, Knight 1871, Bell 1876, Benz 1886 and Bertha Benz's 106 km in 1888, Cochrane 1886, the Wright brothers 1903,
  Anderson 1903, Morgan 1923, Baird 1926).
- **Projects** (Finland's modules, Japan's integrated study, IB PYP, Cambridge GP): a museum of the first
  civilisations (Egypt by the Nile, the Indus Valley, Shang China by the Yellow River; objects, labels of facts, caring
  for finds; builds: a room's floor of area 12 and perimeter 14, the other half of a pyramid); a river town (source,
  tributaries, meanders, mouth, why towns grow by rivers, a plan with a grid and a key, the watermill, beam, arch and
  suspension bridges, field areas and fences, an L-shaped field, bridge supports; build: a field of area 20 and fence
  18); a light and sound show (loops and switches, two bulbs dimmer, sound as vibration, pitch, the pentatonic scale the
  game's blocks sing, a running order; 5 tunes to LISTEN to; build: a stage of area 18 and perimeter 18).

## New: pictures and generators
- **`SchoolPictureG4Life`** (`ui/school/school_picture_g4life.gd`, called from `SchoolPicture.problem` and `_draw` like
  `SchoolPictureLife`): `circuit` (real-looking parts round a loop: a battery with + and −, a bulb in its holder, a
  switch open or closed, a buzzer, a motor with a fan, an LED, a gap between clips with or without a material; lit or
  not; names), `beach_flags` (red over yellow, red, black and white quarters, the orange windsock, on poles on sand),
  `food_label` (front-of-pack boxes coloured green, amber or red with LOW, MED or HIGH, a white box, or a grey ? to work
  out; per 100 g), `pitch` (a pitch from above with blue circles for your team and red squares for the other, tags and
  the ball; layouts `invasion`, `rounders` with its batting and bowling squares and posts 1-4 anticlockwise, and
  `court`), `site_plan` (a place on squares: open land, water, bridge, trees, field, house, mill, path, hill, rocks,
  and orienteering's purple start triangle, numbered controls and finish; grid letters and numbers, a north arrow, a
  key), `chassis` (a model vehicle from above: axles square or crooked, a smaller wheel, labels) and `hand` (the
  helping hand: five trusted adults round a palm). Test: `tests/integration/test_school_picture_g4life.gd` (samples of
  every kind, part, flag, level, symbol and layout; broken data; every size).
- **Generators** (`core/school/gen/g4_health_gen.gd`, `G4HealthGen`, SchoolGen source **"g4w"**, the last SOURCES line;
  seeded, levels 1-3, each with a hint, a worked answer and `data`): `find_space` (pass to the free teammate, or which
  is marked most closely: built so the free one is 3+ squares from every red player and the marked ones have one within
  1.5), `jump_measure` (m and cm, how much further, a triple jump added), `relay_time` (legs added, how much faster),
  `circuit_training` (stations × seconds, with rests, rounds in minutes), `fitness_sort`, `label_light` (read the
  colours, compare two cereals per 100 g, sugars' colour from its grams), `sugar_cubes` (grams, a bottle's sugar from
  its grams per 100 mL, in 4 g cubes), `orienteer` (walk n squares, which way on 8 compass points, metres along rows
  and columns), `circuit_lights` (true or false: the bulb will light; which material across the gap), `wheel_roll`,
  `fabric_cut`, `frame_struts` (2n + 1), `bread_recipe` (loaves, half a loaf, rolls), `bake_time` (clock times, am
  and pm), `meal_missing`, `user_survey` (a table), `material_job` (the material, or why), `invention_order`,
  `museum_sort`, `river_fields` (area, fence, an L-shape, a build) and `tune_shape` (LISTEN: up or down, how many
  notes, which is highest). Test: `tests/unit/test_g4_health_gen.gd` works every answer out again with its own facts
  (distances, the traffic-light thresholds, the compass, metals, Euler's V − E + F = 2 for the struts, the loaf, the
  food groups, the materials, the dates, the civilisations, the notes' pitches), 150 seeds × 3 levels.

## Tests
- `tests/unit/test_school_content_g4_life.gd` (written first; it failed with every unit not written):
  `test_grade_4_health_dt_projects_are_written_for_every_unit` (the outline's 11 + 9 + 3 units, 3+ cards, 12+
  exercises, levels 1-3, two kinds, rounds that fill, never repeat a hand-written exercise and vary: 12+ distinct),
  `test_the_files_are_their_own`, `test_every_exercise_has_a_strategy_hint_and_a_worked_answer`,
  `test_every_lesson_starts_with_a_memory_question_and_ends_in_the_world`, `test_the_units_use_their_own_generators`
  (g4w; every g4w used), `test_the_safety_facts_are_taught` (water: red and yellow, red flag, float, 999, Coastguard,
  throw; first aid: danger, 20 minutes, running water, press, cold, 999; safe and unsafe: trusted, secret, surprise,
  body belongs to you, keep telling; labels: per 100 g, sugar, salt, fat, green, red, water; feelings; fitness;
  circuits: battery, never, sockets; bread: wheat, flour, yeast, gas, knead), `test_health_is_taught_kindly` (no
  weight, calories, junk, diet, puberty, reproduction or sex, and no drugs, alcohol, smoking, vaping or gambling
  (research §5.4 rule 5: grade 5), in any card, exercise or generated exercise), `test_the_units_are_drawn` (flags,
  labels, circuits, chassis, pitches, plans, the hand, and grade 3's plate, poses, frames and stitches where they
  teach), `test_the_show_can_be_heard_and_projects_have_builds`.
- The shared `test_school_content.gd` and `test_lab_content.gd` pass with these units.
- The unit files were made with scratch Python scripts (the grade 3 life kit, copied: lengths, words incl. extra US forms
  and brand names, the health words, letters, sums, levels 2/3/4 or more, first and last cards, no spaced hyphen).
- Pictures and exercises looked at with `tools/school_shots.gd` (windowed, own XDG folder) for 14 units: flags, labels,
  circuits, pitches, rounders, plans, the hand, chassis, poses, the partner mirror build, the pyramid build, sorts and
  matches, the show's LISTEN cards.
- **The full suite** (`tests/run_tests.sh`, 2026-09-29, on 1fa7d47): 775 scripts, 7,140 tests, 7,138 passing, 0
  failing, 2 risky (not asserting, not this agent's: `test_the_column_cache_changes_nothing`,
  `test_chunks_meet_without_seams`), in 1,744 s.

## Facts checked (2026-09-29)
NHS (sugar: 24 g of free sugars, 6 cubes, for ages 7-10; salt 5 g; the traffic-light thresholds per 100 g; ingredients
by weight; 150 mL of juice; burns: cool or lukewarm running water for 20 minutes, cling film, never ice, butter or
cream; cuts: pressure, rinse, pat dry, plaster; head injuries: when to get help; nosebleeds), St John Ambulance (DR ABC:
danger first; bruises: a cold compress for about 10 minutes, wrapped, never straight on skin), RNLI and RLSS UK (the
flags; float to live 60-90 s; rips: wade, swim parallel, raise a hand; the Water Safety Code: stop and think, stay
together, call 999 (Coastguard at the coast, fire and rescue inland), float), Childline (0800 1111, free, any time),
Food Standards Agency (the 4 Cs, the fridge at 5 °C or below), Rounders England (posts 1-4 anticlockwise, a rounder),
orienteering (ISOM colours, purple start triangle, control circles, double-circle finish), the alpine distress signal
(6 blasts a minute, 3 in reply), WHO 2020 (60 minutes a day on average; muscles and bones on 3 days a week), invention
dates (Al-Jazari 1206, Watt 1769, Volta 1800, Rocket 1829, Lovelace 1843, Knight 1871, Bell 1876, Benz 1886, Bertha
Benz 1888 (106 km), Cochrane 1886, the Wrights 17 Dec 1903 (12 s, 36 m), Anderson 1903, Morgan 1923, Baird 26 Jan 1926).

## Rulings (decided here; cost if wrong)
1. **The generator source is "g4w"** (file `g4_health_gen.gd`, class `G4HealthGen`), not "g4p" as the lead's message
   said: `g4p` (`g4_physical_gen.gd`) and `g4l` (`g4_life_gen.gd`) are grade 4 science's; `g4h` and `g4a` are being
   taken by the other two grade 4 agents. *Cost:* a rename.
2. **Personal safety teaches body autonomy** ("your body belongs to you; you can say no to hugs, tickles or touches you
   do not want; no one should ask you to keep a secret about touching"), as England's RSHE personal safety and the
   NSPCC's PANTS do, with nothing about puberty, reproduction or sex (research §5.4 rule 4). *Cost:* one card and one
   true-or-false exercise if the owner wants it out.
3. **Childline (UK) is named**, with "many countries have a children's helpline", as grade 3 named 999, 911 and 112.
   *Cost:* a line.
4. **Food labels are the UK's traffic lights** (per 100 g; NHS thresholds), and energy is never shown in calories (the
   kind-words list bans them); reds are "to have less often", never "bad". *Cost:* another country's label is a card.
5. **Beach flags are the RNLI's** (UK); other countries use other flags. *Cost:* a card.
6. **"weights" is banned in these subjects' words** (the health list), so the Indus Valley's cube weights are "stone
   cubes for weighing". *Cost:* none.
7. **"program" is British for a computer program**: the grade 3 kit's extra US list had it; this agent's kit does not
   (the shared test never banned it). "Appliqué" and "café" are avoided (é is not in the School's letters): a patch, a
   restaurant. *Cost:* none.
8. **Level 1 generators with few cases** (circuits, frames, a loaf, materials) make 3-4 distinct exercises at level 1 by
   nature; the gen test wants 3 at level 1 and 6 at levels 2-3. *Cost:* none.
9. **The Lab's circuit experiment names two of these units** (`g4.design_tech.electric_products`,
   `g4.projects.light_and_sound_show`), so their pages show TRY IT IN THE LAB (6 units, the Lab's maximum). *Cost:*
   one line in `data/lab/circuit.json`.
10. **Rounders is drawn from above with the batting square at the bottom** and posts 1-4 anticlockwise (1st on the
    batter's right). *Cost:* a picture's constants.
11. **Phone numbers get their spoken form** in brackets once, as grade 3 did ("999 (nine nine nine)", "0800 1111 (oh
    eight hundred, eleven eleven)"), so the voice reads them as numbers to dial. *Cost:* none.

## For the lead (merging)
- Conflicts to expect: `core/school/school_gen.gd` (the grade 4 humanities agent adds "g4h", the arts agent "g4a", this
  one "g4w", all at the end of SOURCES), `ui/school/school_picture.gd` (each adds a header line and two hooks after
  `SchoolPictureLife`), `data/school/grade4.json` (each adds `file` lines to its own subjects), `docs/DEVELOPMENT.md` (a
  bullet each at the end of the School section).
- After merging: `python3 tools/school_outline.py --write docs/superpowers/plans/2026-09-28-school.md` (not run here, to
  keep the three branches from conflicting on a generated file), and spec §22.4c's "as built" line for grade 4.
- The `circuit` picture kind is ready for grade 4 science's "Electric circuits" unit (not yet written).
