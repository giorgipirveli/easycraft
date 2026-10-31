# Grade 5 health and PE, design and technology, projects: every unit written (owner #70, #73; 2026-09-29)

The owner: "start from grade 3 and finish all grades accordingly" and "research school programs, world leading schools
and create better school program". The research (`docs/design/school-curriculum-research.md` §6.5) lists grade 5's
Health and PE (11), Design and Technology (9) and Projects (3) units; this agent wrote all 23 of them, following the
reusable brief `docs/superpowers/plans/2026-09-29-school-subjects-brief.md` (GRADE 5, SUBJECTS health_pe, design_tech,
projects), built on grades 3 and 4 of the same subjects (`docs/devlog/parts/m8-grade3-life.md`, `m8-grade4-life.md`).
Branch `worktree-agent-a7203bfe69a60a71e`, from `lead-merge` e60cd98 ("spec §22.4d grade 4 as built").

## What was written
| Subject | Units | Lesson cards | Hand-written exercises | Generators used (g5w) |
|---|---|---|---|---|
| Health and PE | 11 | 88 | 179 | court_target, tennis_score, pass_lane, dance_counts, motif_claps, pb_best, goal_plan, health_facts, allergen_find, fever_check, bedtime, map_scale, pace_count, bearing |
| Design and Technology | 9 | 72 | 144 | gear_turns, gear_direction, cam_rises, bridge_piers, bridge_test, block_views, scale_drawing, control_trace, recipe_servings, season_pick, cook_timing, reuse_count, breakdown_order, fibre_sort, weave_next, test_average, criteria_score |
| Projects | 3 | 24 | 48 | roman_grid, expedition_web, biome_weather, fair_money |
| **All** | **23** | **184** | **371** | **35 new generators**, each at levels 1-3 |

- **Files:** `data/school/g5/<subject>/<unit>.json`, linked from `data/school/grade5.json` (only these 23 units' `file`
  fields changed; titles, standards and goals kept; tab indentation kept).
- **Every unit:** a lesson of 8 cards that opens with "Quick memory: …?" (a question from grade 3 or 4, its answer in
  brackets, then what today builds) and ends with "Try it in the world: …" (research §5.3 rules 1, 7 and 8); 16-17
  hand-written exercises at levels 1, 2 and 3 (at least 4, 6 and 6, so a round never repeats one), of 3-7 kinds: choice
  (168), true or false (81), number (37), order (28), sort (23), match (22), build (5), rhythm (3), robot (2) and point
  (2). Every exercise has a hint (a strategy, never the answer) and an explain (the worked answer).
- **Health and PE** (England PE and RSHE, SHAPE America, NHES, CASEL): net and wall games (serves, rallies, the ready
  position and the base, placing the ball deep, short or wide, forehand and backhand, tennis scoring with deuce,
  badminton to 21, volleyball to 25 with 3 touches, table tennis to 11; shots: drop, lob, smash, drive); tactics (plans
  to attack and defend, football positions, netball's 7 bibs and who may score, overloads, the one-two, goal-side,
  passing lanes, player-to-player and zone defence, switching when the ball is lost); create a dance (stimulus, motif,
  development, relationships, formations, ABA and the rondo ABACA; claps to LISTEN to and copy); personal best (fitness
  tests for each part of fitness, fair tests, comparing with yourself, SMART goals, a weekly plan and a bar chart, rest);
  liking yourself (self-esteem, strengths and qualities, kind self-talk and "yet", every body is different and deserves
  respect, edited pictures online, telling a trusted adult); changing friendships (healthy and unhealthy friendships,
  falling out and making up with 'I' messages and compromise, peer pressure, good and unhealthy, saying no, upstanders,
  online pressure); medicines and harmful substances (see Safety below); allergies and illness (allergens, the UK's 14
  labelled allergens, mild reactions and antihistamines, anaphylaxis: 999 and the adrenaline auto-injector straight away,
  asthma and the blue reliever inhaler, vaccines, antibiotics and viruses, a high temperature is 38 °C or more); sleep
  and screens (9 to 12 hours, the body clock, melatonin, screen light, screens off an hour before bed, phones out of the
  bedroom, sleep cycles, working out a bedtime, caffeine); emergency first aid (DR ABC, opening the airway, checking
  breathing for up to 10 seconds, 999 on speaker, the recovery position, CPR talked through by the call handler, the
  AED, choking: keep coughing, or get an adult at once for back blows); orienteering (setting the map with a compass,
  8 points, bearings in degrees, 1:5,000 and 1:10,000 scales, pace counting, handrails and attack points, 6 whistle
  blasts).
- **Design and Technology** (England D&T, Finland's crafts): gears and pulleys (driver, driven and idler gears,
  opposite turns, teeth and speed, a bicycle's chain, bevel and worm gears, belts open and crossed, a fixed pulley and
  two pulleys halving the effort); cams (rotary, linear, reciprocating, oscillating; round, pear, snail and oval cams
  and their followers, a cam toy, camshafts); bridges (compression and tension, beam, arch with its keystone and
  abutments, truss, suspension over 2 km, fair tests with washers, strength for its own mass); design on screen (CAD, a
  blueprint's plan, front and side views of a block model, scales like 1:50, 3D printing and laser cutting: CAM);
  control it with code (input, process, output; sensors, IF, FOREVER, REPEAT and waits, the UK traffic-light sequence,
  a buggy coded on the robot board, debugging); seasonal cooking (UK seasons, savoury dishes, food safety, peeling,
  grating, the claw and the bridge, oven gloves, seasoning, scaling a recipe); reuse and redesign (the waste hierarchy,
  upcycling, choosing waste by its properties, safety with tins, how long waste lasts in the sea, recycling aluminium,
  a circular economy); fabrics and clothes (plant, animal and made fibres, viscose from wood pulp, spinning and the
  spinning jenny, plain and twill weaves, knitting and felt, Jacquard's punched cards); test and review (evaluating
  against criteria, fair tests repeated 3 times and the mean, user scores in a table, specific improvements, product
  analysis).
- **Projects** (IB PYP, Finland's modules, Cambridge Global Perspectives): a Roman town (the grid of streets, the
  forum, basilica and temples, the baths' three rooms, aqueducts, layered and cambered roads, mosaics; points to tap on
  a coordinate grid; builds: the other half of a symmetrical temple, a forum of area 24 and perimeter 20); a biome
  expedition (biomes and climate, planning, a weather table, food webs of a woodland, the Arctic tundra and a desert,
  adaptations, writing the report; builds: 3/10 of a wall for the rainy days, a camp of area 12 and perimeter 14; in the
  world: the Sandstorm Desert, Frostpeak and the Green Meadows' forests); a fair on a budget (stalls, a budget in gold,
  income, costs and profit, discounts of 10, 25 and 50%, persuasive posters, fair prices; build: a field of area 20 and
  perimeter 18).

## Safety (research §5.4)
- **Rule 5, harmful substances:** grade 5 is the first grade that names them, and only in "Medicines and harmful
  substances": medicines as drugs that help, only from a trusted adult and as the label says; tobacco, nicotine and
  addiction, second-hand smoke; vaping (for adults who smoke and want to stop, nicotine and growing brains); alcohol
  (slows the brain and body; the UK Chief Medical Officers' alcohol-free childhood); the law (no sales of alcohol,
  cigarettes or nicotine vapes to under-18s in the UK; other countries have their own laws); saying no and telling a
  trusted adult. Nothing shows use: no figures or pictures in that unit, no words that invite trying anything (the test
  checks phrases like "try vaping"); gambling is not taught in these units (ruling 3).
- **Rule 4:** nothing about puberty or reproduction; no weight talk or food shaming ("every body is different … deserves
  respect"; treats are never "bad"; "weight" is avoided even in D&T: a bridge holds a "load", a washer has a "mass").
- The content test checks it: `test_health_is_taught_kindly`, `test_harmful_substances_are_taught_only_factually_in_
  their_own_unit` (the substance words appear in no other unit, card, exercise or generated exercise).

## New: pictures and generators
- **`SchoolPictureG5Life`** (`ui/school/school_picture_g5life.gd`, hooked into `SchoolPicture.problem` and `_draw` after
  `SchoolPictureG4Life`): `net_court` (badminton, tennis or volleyball lines, the net and its posts, blue and red
  players, yellow target spots, a dashed shot), `gears` (1-4 meshing gears sized by their teeth, teeth that interleave,
  turn arrows by `gear_turns`, marks to count turns, labels), `pulleys` (two wheels on an open or crossed belt, or a
  crate lifted by one fixed pulley or a fixed and a moving one), `cam` (a round, pear, snail or oval cam turned under
  its follower in a toy's frame, a flag on top, labels, the follower's height over one turn as a graph; a small picture,
  such as a choice, draws the cam's shape alone), `bridge` (beam, arch, truss, suspension, cable-stayed over a river;
  piers, a crate, squash and stretch arrows with their key, part names, a part in orange), `views` (a block model in 3D
  from the front right, its plan with numbers, its front and side views), `compass` (4 or 8 points, degrees, a hidden
  point, a needle, a bearing arrow), `food_web` (boxes on a 4 × 4 layout, plants green and animals sand, arrows from
  food to eater, a marked or hidden living thing) and `lying` (seen from above: on the back with the head tilted back, or
  in the recovery position, with labels). The rules they draw by are functions the tests check: `gear_turns`,
  `pulley_turns`, `cam_radius`, `cam_height`, `front_view`, `side_view`. Test: `tests/integration/test_school_picture_
  g5life.gd` (samples of every kind, sport, cam, bridge, view and pose at every size; the rules; broken data).
- **Generators** (`core/school/gen/g5_health_gen.gd`, `G5HealthGen`, SchoolGen source **"g5w"**, the last SOURCES line;
  seeded, levels 1-3, each with a hint, a worked answer and `data`): court_target (the spot farthest from every red
  player, a square clearer than any other), tennis_score (love to game, deuce and advantage), pass_lane (the one clear
  or blocked passing lane), dance_counts, motif_claps (rhythm to copy), pb_best (longest, fastest, a bar graph's
  improvement, a mean), goal_plan, health_facts (a checked bank of true or false facts: medicines; tobacco and vaping;
  alcohol and the law), allergen_find (contains, safe, sort), fever_check, bedtime (a digital clock of the wake-up
  time), map_scale, pace_count, bearing (a compass), gear_turns, gear_direction (gears or belts), cam_rises (with the
  cam), bridge_piers (with the bridge), bridge_test (tables; the best for its own mass is never simply the biggest load),
  block_views (a plan's count; front and side views as picture choices that all look different), scale_drawing,
  control_trace (code pictures of IF sensors and REPEAT loops), recipe_servings, season_pick, cook_timing,
  reuse_count, breakdown_order, fibre_sort, weave_next (plain weave rows, 8-thread twills), test_average (with a slip to
  leave out), criteria_score (a table), roman_grid (tap, name, walk the roads), expedition_web (three food webs; wrong
  choices never real food of that animal, and "which animal loses food" only among animals the lost one never feeds),
  biome_weather (a table with minus temperatures), fair_money (budget left, discounts, profit). Test:
  `tests/unit/test_g5_health_gen.gd` works every answer out again with its own facts and rules, 150 seeds × 3 levels.

## Tests
- `tests/unit/test_school_content_g5_life.gd` (written first; it failed with every unit not written):
  `test_grade_5_health_dt_projects_are_written_for_every_unit` (the outline's 11 + 9 + 3 units, 3+ cards, 12+ exercises,
  levels 1-3, two kinds, rounds that fill, never repeat a hand-written exercise and vary: 12+ distinct),
  `test_the_files_are_their_own`, `test_every_exercise_has_a_strategy_hint_and_a_worked_answer`,
  `test_every_lesson_starts_with_a_memory_question_and_ends_in_the_world`, `test_the_units_use_their_own_generators`
  (g5w; every g5w used), `test_the_safety_facts_are_taught` (first aid: danger, response, airway, breathing, 999, the
  recovery position, choking, cough, grown-up; medicines: trusted adult, label, never, 18, nicotine, addictive, alcohol,
  vaping, tobacco, say no, lungs; allergies: allergen, peanuts, anaphylaxis, 999, auto-injector, wash, 38; sleep: 9 to 12
  hours, screens, an hour before, light, bedtime; friendships, self-esteem, orienteering, cooking, gears, bridges,
  control), `test_health_is_taught_kindly`, `test_harmful_substances_are_taught_only_factually_in_their_own_unit`,
  `test_the_units_are_drawn` (each unit's pictures, from courts to food webs), `test_the_dance_is_heard_the_model_coded_
  and_projects_built` (claps to copy and beats on the cards, two robot buggies, two points on the Roman grid, a build in
  every project).
- The shared `test_school_content.gd`, `test_school_curriculum.gd` and `test_lab_content.gd` pass with these units.
- The unit files were made with scratch Python scripts (the grade 4 life kit, copied: lengths, words incl. extra US forms
  and brand names, the health words, the substance words outside their unit, letters, sums, levels 3/4/5 or more, first
  and last cards, no spaced hyphen; a solver for the robot boards so each worked answer is a shortest program).
- Pictures looked at with a render script (every sample at card and choice sizes) and with `tools/school_shots.gd`
  (windowed, own XDG folder) for 14 units: courts, cams (a choice of cam pictures was too small to read, so a small cam
  picture now draws the cam alone), bridges, views, weaves, code and the buggy, the recovery position, compasses, the
  Roman grid, food webs (a long name overflowed its box, so the longest name now sets the size), tables, the dance's
  claps and levels (the jump looked like the stretch, so the levels are a stretch, a stand and a crouch).
- **The full suite** (`tests/run_tests.sh`, 2026-09-29, on fec2865): 794 scripts, 7,318 tests, 7,316 passing, 0
  failing, 2 risky (not asserting, not this agent's: `test_the_column_cache_changes_nothing`,
  `test_chunks_meet_without_seams`), in 2,089 s. After it, one card's words only ("a volleyball set 25"), with the
  content tests run again.

## Facts checked (2026-09-29)
Badminton (games to 21, 2 clear up to 30, the low underarm serve diagonally), tennis (love, 15, 30, 40, deuce,
advantage), volleyball (sets to 25, 3 touches), table tennis (11), netball (7 bibs; only GS and GA score, in the
circle; the centre pass), NHS (a high temperature in a child is 38 °C or more; anaphylaxis: auto-injector and 999;
asthma: sit up, the blue reliever inhaler, 999 if no better; hay fever and antihistamines; antibiotics and viruses),
the UK's 14 allergens on labels, the AASM (9 to 12 hours for ages 6-12), melatonin and screen light, St John Ambulance
and the British Red Cross (DR ABC, look, listen and feel for 10 seconds, the recovery position, choking: coughing, then
back blows by an adult, 999; the AED's spoken steps), UK law (alcohol, tobacco and, since 1 October 2015, nicotine
vapes: no sales to under-18s), the UK Chief Medical Officers (an alcohol-free childhood), tobacco smoke (thousands of
chemicals, about 70 that can cause cancer), orienteering (1:5,000 is 50 m a cm, 1:10,000 100 m; a pace is two steps;
6 whistle blasts), gears, cams, pulleys and bridges (a whisk's bevel gears, a camshaft's valves, two pulleys about half
the effort, stone strong in compression, the longest suspension span 2,023 m), UK seasons (asparagus, rhubarb, wild
garlic; strawberries, raspberries, peas, broad beans, courgettes, cherries; apples, pears, pumpkins, squash; leeks,
parsnips, Brussels sprouts, kale, swede), NOAA's marine-debris estimates (a paper towel 2-4 weeks, an apple core 2
months, a wool glove 1 year, a plastic bag 20 years, a tin can 50 years, an aluminium can 200 years, a plastic bottle
450 years), aluminium recycling (about 95% less energy), the spinning jenny (Hargreaves, 1764-65, 8 spindles), the
Jacquard loom (1804, punched cards), denim is a twill, viscose from wood pulp, Roman towns (the grid, forum, basilica,
caldarium, tepidarium, frigidarium, aqueducts, layered cambered roads, mosaics), biomes (hot deserts under 250 mm of
rain a year, rainforests over 2,000 mm; camels' humps store fat; arctic foxes' white winter fur; drip tips), the three
food webs (who eats whom, each link a real one), the UK traffic-light sequence.

## Rulings (decided here; cost if wrong)
1. **The generator source is "g5w"** (file `g5_health_gen.gd`, class `G5HealthGen`), as the lead suggested: grade 5's
   sources are g5n, g5f and g5m (maths); the other grade 5 agents are expected to take g5h and g5a. *Cost:* a rename.
2. **Harmful substances only in their own unit**, as facts about health, the law and saying no; the words (drug,
   alcohol, tobacco, smoking, vaping, nicotine, gambling …) appear in no other grade 5 life unit, and that unit has no
   figures. *Cost:* a word list in the test if another unit ever needs one.
3. **Gambling is not taught here:** the research allows it from grade 5, but the outline's goals for these units name
   tobacco, vaping and alcohol only, and the fair uses games of skill (hoopla, a bean bag throw), never raffles.
   *Cost:* a card and a fact bank if the owner wants it (a citizenship money unit would fit better).
4. **UK law and advice** ("In the UK, …; other countries have their own laws"), as grades 3 and 4 named the UK's 999,
   Childline and the RNLI's flags. The vape law says "nicotine vapes", the narrowest true statement. *Cost:* a line.
5. **CPR is named, not taught:** the call handler talks anyone through it; a 10-year-old learns DR ABC, the recovery
   position, choking signs and to get an adult (the outline's goals). *Cost:* a unit in a later grade.
6. **The recovery position and the first aid checks are drawn from above as stick figures** (`lying`), labelled; the
   airway is shown by the words, since a head's tilt cannot be seen from above. *Cost:* a picture's joints.
7. **Tennis and badminton on the court picture are drawn in proportion to their real lines** (12 × 6 squares, the net
   at 6); volleyball's 18 m × 9 m fits exactly. *Cost:* constants.
8. **A block model's side view is seen from the right, the front row on the left** (as a viewer on the right sees it);
   the lessons and exercises say "from the right". *Cost:* reversing `side_view`.
9. **Twill rows are 8 threads wide** (two whole repeats of over two, under two), so moving a row one thread along is
   exactly the next row of a real twill. *Cost:* none.
10. **Waste's breakdown times are NOAA's classroom estimates in the sea**, taught as "scientists estimate … about", and
    ordered only where each is at least twice the one before. *Cost:* a table.
11. **Bram is "he", and Tilly, Zara and Mimi "she"**, as the other School units write them; generators use names, not
    pronouns. *Cost:* none.
12. **Pressure plates light lamps in the game** (`PowerRules`: a plate someone stands on powers what it touches), so
    "control it with code" ends with one as an input and a lamp as an output. *Cost:* a line.

## For the lead (merging)
- Conflicts to expect: `core/school/school_gen.gd` (each grade 5 agent adds a SOURCES line at the end),
  `ui/school/school_picture.gd` (a header line and two hooks after `SchoolPictureG4Life`), `data/school/grade5.json`
  (each agent adds `file` lines to its own subjects), `docs/DEVELOPMENT.md` (a bullet each at the end of the School
  section).
- After merging: `python3 tools/school_outline.py --write docs/superpowers/plans/2026-09-28-school.md` (not run here),
  and spec §22.4's "as built" line for grade 5.
- The long outline title "Medicines and harmful substances" is drawn small on its map stop (it fits, per the stop test).
