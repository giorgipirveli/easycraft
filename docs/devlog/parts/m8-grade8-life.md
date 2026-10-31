# Grade 8 health and PE, design and technology, projects: every unit written (owner #70, #73, #111; 2026-10-17)

The owner: "start from grade 3 and finish all grades accordingly" (#70) and, on 2026-10-16 (#111), "when all remaining
tasks are done, you continue adding educational materials, as you know we want to have full school programs and
sylabusse content in the game"; for the whole platform (#112, #115, #117, #118): learn by doing, and dangerous things
learned safely. The research (`docs/design/school-curriculum-research.md` §6.8) lists grade 8's Health and PE (11),
Design and Technology (9) and Projects (3); grade 8's history, geography and citizenship were merged before this, and
its computing, art and music were being written by another agent at the same time. This agent wrote all 23, following
the reusable brief (`docs/superpowers/plans/2026-09-29-school-subjects-brief.md`, GRADE 8, SUBJECTS health_pe,
design_tech, projects) with the lead's changes: `git merge lead-merge` (at 8ce66716) instead of a reset; the project's
tools instead of the old scratch helper; the source `g8l`; and **a unit whose topic is a Life or Success Experience ends
by sending the child to it, by its own title, in the LIFE tab**. One step up from grade 7
(`school-g7-dt-hpe-projects.md`), never repeating it. Branch `worktree-agent-adf0acd78064251e8`.

## What was written
| Subject | Units | Cards | Hand-written exercises | Kinds of exercise | Generators (`g8l`) |
|---|---|---|---|---|---|
| Health and PE | 11 | 88 | 172 | choice 55, number 34, true/false 32, sort 18, order 16, match 12, label 3, rhythm 2 | 26 |
| Design and technology | 9 | 72 | 144 | choice 40, number 39, true/false 26, sort 16, order 10, match 9, label 4 | 26 |
| Projects | 3 | 24 | 48 | choice 13, number 13, true/false 9, order 4, sort 3, match 3, build 3 | 8 |
| **All** | **23** | **184** | **364** | | **60**, each at levels 1-3 |

- **Files:** `data/school/g8/{health_pe,design_tech,projects}/<unit>.json`, linked from `data/school/grade8.json` (only
  these 23 units' `file`; titles, goals and standards kept; the file round-trips through `json.dumps` with tabs).
- **Every unit:** 8 cards, one idea each: "Quick memory:" with a question from grade 5, 6 or 7 (its answer in
  brackets) first, a worked example, "Try it in the world: … Next: …" last; 15 or 16 hand-written exercises (4-6 at each
  level) of 5-7 kinds, at most 63% choice or true-or-false, each with a strategy hint and a worked answer; 2-4
  generators at each level. Choices are written right-first (RoundPlan shows them shuffled).
- **The audit** (`tools/school_audit.py --grades 8 --units`): every unit 100 once this file names it (98 before: only
  "not in the notes"); a polish pass split long sentences, added a picture (technology's effects), gave level 3 of game
  strategy and bouncing back fuller worked answers (they were "flat"), and moved table cells under 17 px to shorter
  words (`tools/school_check.gd`: 0 problems in the 23 units).

### Health and PE (England KS3 PE and RSHE, SHAPE America, NHES, CASEL, Jump$tart)
- **Game strategy** (`game_strategy`): scanning before the ball arrives, formations counted from the back (4-4-2 is
  4 + 4 + 2 = 10 and the keeper), changing tactics with the game (an overload in midfield, chasing a goal, protecting a
  lead), match statistics (possession, pass completion 240 ÷ 300 = 80%, shots on target), net games' gaps, fielding
  where the batters hit, a half-time talk. Builds on grade 7's advanced tactics.
- **Fitness testing** (`fitness_testing`): one test for each part (the multistage fitness test, sit-and-reach,
  hand-grip, 30 m sprint, Illinois agility run, stork stand, vertical jump), valid and reliable, fair conditions, the
  best of three and the mean, lower is better for timed tests, a fitness profile as a spider chart and its retest, a
  club's rating table, improvement in percent. Builds on grade 5's personal best.
- **Active for life** (`active_for_life`): adults' 150 minutes moderate or 75 vigorous and strength twice a week (UK
  CMOs), one vigorous minute about two moderate ones, kinds of activity, why people keep going, clubs, taster sessions
  and safe coaching, barriers and fixes, active travel.
- **Looking after mental health** (`mental_health_support`): anxiety as the alarm (fight, flight or freeze), the best
  zone of pressure, low mood, thinking traps (catastrophising, mind reading, all-or-nothing, fortune telling), avoidance
  and staying until anxiety falls, getting help (two weeks, everyday life, any thought of self-harm: a trusted adult or
  the GP; Childline 0800 1111), helping a friend. Builds on grade 6's mental health and stress units.
- **Bouncing back** (`bouncing_back`): resilience as skills, a setback as information, the three traps after a setback
  (forever, everything, all me) and fairer thoughts, what went well and even better if, the bounce-back steps,
  support, Wilma Rudolph (polio, a leg brace, three Olympic golds in 1960). Builds on grade 5's "yet".
- **Respect online** (`respect_online`): the same respect as face to face, healthy friendships and signs of control,
  consent (a free yes that can change), private pictures and the UK law for under-18s told plainly and kindly, never
  your fault, don't reply, keep the evidence, block, report, tell; Childline's Report Remove and CEOP; the digital
  footprint; being an upstander. Builds on grade 6's respectful relationships.
- **Chance, gambling and spending** (`gambling_harms`): see Safety.
- **Alcohol, drugs and peer pressure** (`pressure_and_substances`): see Safety.
- **CPR and defibrillators** (`cpr_defibrillator`): a cardiac arrest, the first steps (danger, response, shout, airway,
  breathing for 10 seconds, 999 or 112 on speaker, send for a defibrillator), CPR with straight arms on the centre of the
  chest, 5 to 6 cm, 100 to 120 a minute (heard, and copied twice), 30 and 2 for trained rescuers, hands-only otherwise,
  the AED's pads and stand-clear, public defibrillators, Frank Pantridge's portable defibrillator (Belfast, 1965);
  practise only with a trained adult and a dummy. Builds on grade 5's DR ABC and grade 6's serious emergencies.
- **Speak up for health** (`health_campaign`): advocacy, a campaign's steps, a survey's evidence (45 ÷ 150 = 30%), a
  SMART aim, audiences and honest messages (no shaming, no scare stories), measuring before and after in percentage
  points.
- **Digital balance** (`digital_balance`): screens fitted around sleep, school, activity and family (a day in 2-hour
  parts), design tricks (notifications, autoplay, endless scroll, likes), focus and switching, a year's hours (3 × 365),
  screens off an hour before bed and the phone outside the bedroom, the 20-20-20 rule. Builds on grade 7's teenage
  sleep.

### Design and technology (England KS3 D&T, Finland's crafts and home economics)
- **From brief to product** (`brief_to_product`): the design brief and the client, research and anthropometrics,
  constraints, a specification of checkable points under ACCESS FM, scoring ideas (and weighting), a Gantt chart, a
  cutting list, tolerances (written "plus or minus": the School's font list has no ±) and quality control.
- **Smart and modern materials** (`smart_materials`): smart materials and triggers; shape-memory alloy
  (nickel-titanium), thermochromic pigments, photochromic lenses (ultraviolet), piezoelectric crystals, hydrogels;
  composites as fibres in a matrix (GRP, carbon fibre, reinforced concrete), hard to recycle; density (steel 7.8,
  titanium 4.5, aluminium 2.7, carbon fibre 1.6 g/cm³) and mass; graphene. Builds on grade 6's material families and
  grade 7's smart textiles.
- **A programmable product** (`programmable_product`): input, process and output, a sensor's threshold (a plant
  waterer), a flowchart, the code (a loop each minute, `pause(60000)`), open and closed loops, a case, safe wiring and
  battery life (mAh ÷ mA), testing at the threshold. Builds on grade 6's sensors and grade 7's microcontrollers.
- **Mechanical advantage** (`mechanical_advantage`): MA = load ÷ effort, a lever's distances, gear ratio and output
  speed in rpm, the idler gear, compound trains (multiply the stages), a block and tackle's ropes, velocity ratio and
  efficiency (MA ÷ VR). Builds on grade 5's gears and pulleys and grade 6's mechanisms.
- **Engineering big structures** (`big_structures`): dead, live and environmental loads, the factor of safety, towers
  in wind (a wide base, a stiff core, cross-bracing, the tuned mass damper), earthquakes (base isolation on rubber
  bearings), suspension and cable-stayed bridges (tension and compression), wind tunnels and shake tables, the Tacoma
  Narrows Bridge (1940). Builds on grade 6's forces.
- **Nutrition for life** (`nutrition_for_life`): macronutrients and micronutrients, vitamins A, C and D, calcium and
  iron, deficiencies (rickets, anaemia, scurvy), about 25 g of fibre and at most 6 g of salt a day for teenagers,
  labels per 100 g and per portion, dietary needs (coeliac disease and gluten, lactose intolerance, vegan B12, allergies,
  religious rules). The outline's goal "Plan for special diets" is kept; the lesson says "dietary needs" (ruling 4).
- **How food is produced** (`food_production`): arable and livestock, intensive and organic, primary and secondary
  processing, pasteurising at 72 °C for 15 seconds, food miles and footprints (food flown by air; beef about 100 times
  peas), seasonal food, sustainable choices.
- **Circular design** (`circular_design`): linear and circular economies, the technical loops (maintain, reuse,
  refurbish and remanufacture, recycle) and the biological ones (compost, biogas), design for repair and disassembly,
  cost per year, renting, take-back and repair cafés, right to repair (UK and EU, 2021). Builds on grade 7's product
  life cycle and 6 Rs.
- **Future technology** (`future_tech`): artificial intelligence, robots and drones, 3D-printed buildings, batteries,
  the internet of things, the levels of driving automation (0 to 5), social, environmental, economic and ethical
  effects, standby energy (2 × 24 = 48 watt-hours), weighing a decision (delivery drones), responsible design. Grade 8
  citizenship's "Big questions about technology" holds AI's bias and personal data; this unit is about products.

### Projects (IB MYP personal and community projects, Cambridge Global Perspectives, Finland's modules)
- **An invention expo** (`invention_expo`): a real problem and user (an automatic plant waterer), a plan for six
  weeks, a parts budget, the program, fair tests and reliability (18 of 20 = 90%), versions and percentage points, the
  expo stand and a live demo; a build: the stand's floor (area 12, perimeter 14).
- **A history documentary** (`history_documentary`): a turning point (the first inter-city railway 1830, the first
  powered flight 1903, votes on equal terms 1928, the Moon landing 1969, the Berlin Wall 1989), primary and secondary
  sources, a question to answer, a storyboard (wide, medium, close-up, narration), stop-motion frames (12 × 10 = 120),
  accuracy, credit and respect; a build: a storyboard of 2 rows of 4 frames. Not marked as hard history: the
  turning points are peaceful ones, and the unit asks for sad parts to be told with respect (ruling 7).
- **A global goal campaign** (`global_goal_campaign`): one of the 17 Global Goals and a local problem, samples and
  fair (not leading) questions, rates per 100 m, bar charts and scatter graphs, correlation that is not cause, a SMART
  aim, a fall of 60 percent, estimating a whole beach from a sample; a build: 3/5 of the beach clean. Grade 8
  citizenship's "A Global Goal in action" holds the SMART target and progress; this project is about the data.

## Life links (owner #112, #115, #117: the School and Life work together)
Each unit below keeps its lesson and practice, and its last card names an Experience by its own title (in
`data/life/experiences/`, `data/success/experiences/` or `data/tools/real_builder.json`, read only) or the Tool Book's
tools by their names in `data/tools/tools.json`; the test checks each name.

| Unit | Last card points to |
|---|---|
| fitness_testing | the Goal Board (training), the Tool Book's stopwatch and tape measure |
| active_for_life | the Goal Board (a habit) |
| mental_health_support | Calm Corner (calming a stressed body, talking about worries) |
| bouncing_back | the Goal Board (bouncing back), Success Stories (people who kept trying) |
| respect_online | Calm Corner (unkind messages), the Connections Book (a good name online) |
| gambling_harms | My Money Stall (tricks and scams) |
| pressure_and_substances | Calm Corner (saying no to pressure), the Poisons Cupboard (medicines and chemicals) |
| cpr_defibrillator | Little Lifesaver (hands-only CPR at 100 to 120 a minute) |
| health_campaign | Talk & Deal (a pitch) |
| digital_balance | the Goal Board (a habit), Calm Corner (winding down) |
| brief_to_product | Real Builder (planning a shed) |
| smart_materials | Real Builder (a lintel: reinforced concrete) |
| programmable_product | the Poisons Cupboard (a carbon monoxide alarm), the Tool Book's carbon monoxide alarm |
| mechanical_advantage | the Tool Book's spanner and claw hammer (levers) |
| big_structures | Earth and Weather (sheltering in an earthquake), Real Builder (a wall in bond) |
| nutrition_for_life, food_production | The Kitchen |
| circular_design | the Tool Book's sandpaper and pliers |
| future_tech, history_documentary | Success Stories |
| invention_expo | Talk & Deal, the Tool Book's stopwatch |
| global_goal_campaign | the Goal Board, Talk & Deal |

Game strategy names none (no Experience is about games' tactics).

## Safety (research §5.4)
- **Rule 5, substances:** alcohol, drugs, tobacco, vaping and solvents only in "Alcohol, drugs and peer pressure",
  factually: alcohol slows the brain and body, the brain develops until about 25, the UK CMOs' alcohol-free childhood,
  the UK law (no sale of alcohol, tobacco or vapes to under-18s, adults must not buy alcohol for them, police can take
  alcohol from under-18s in public, single-use vapes banned from sale since 1 June 2025), nicotine's addiction and vapes
  only for adults stopping smoking, kinds of peer pressure and the norm (most young people don't drink, smoke or vape),
  ways to say no and a code word, help (a trusted adult, the GP or school nurse, FRANK 0300 123 6600, Childline 0800
  1111, 999). **No street drug is named**, nothing shows or invites use, and no people are drawn there (tables and step
  chains only). Its "Next" lines elsewhere avoid the words (the gambling unit's says "the law on harmful substances").
- **Rule 5, gambling:** only in "Chance, gambling and spending", factually: what gambling is, 18 and over for most of
  it in the UK, the house's share (a prize wheel's expected win), chance has no memory, near misses, mystery boxes and
  loot boxes as paying for chance (Belgium, 2018), the tricks, the harms and signs, help (a trusted adult, Childline, the
  National Gambling Helpline 0808 8020 133, free, every hour of the day). Nothing suggests a way to win.
- **Rule 4:** no weight words (a load is in newtons, a part has a mass), no calories or diets (the nutrition lesson
  says "dietary needs" and "a little fat in meals"), no good or bad foods; nothing about puberty or reproduction. The
  private-pictures card says "nude or nearly nude" once, as Childline's Report Remove does, with the law and "never
  your fault" (ruling 3).
- **Rule 7:** no brands or living people (nickel-titanium, not a trade name; a classroom board; Frank
  Pantridge and Wilma Rudolph, people of the past). The test lists apps, consoles and trade names
  to keep out.
- **Money** is gold; no personal questions; kind words throughout (the shared test's list: no "lazy", "failure",
  "lonely"…; a survey's leading example is "Surely driving short trips is wrong?").

## New code
- **`SchoolPictureG8Life`** (`ui/school/school_picture_g8life.gd`, hooked into `SchoolPicture.problem` and `_draw`
  after `SchoolPictureG8Hum`; it reuses `SchoolPictureG7Life`'s helpers and label bands), 10 kinds (its header lists
  every field): `fitness_profile` (a spider chart and a retest; `weakest`), `feeling_curve` (pressure's best zone,
  `pressure_zone`; anxiety staying or escaping), `chance_wheel` (groups spread round a prize wheel with a key; `chance`,
  `expected_win`), `cpr_aed` (hands on the chest, the pads, the machine), `making_plan` (a Gantt chart; `plan_end`),
  `smart_material` (before, the trigger, after; a composite's layers), `gear_train` (compound stages on shared shafts;
  `train_ratio`, `train_turns`), `block_tackle` (`tackle_effort`), `tall_structure` (a tuned mass damper, base
  isolation, suspension and cable-stayed bridges), `circular_loop` (technical and biological loops with a numbered key).
  `part_at` places label pins on the four labelled kinds; `pins` (true) leaves room for a label exercise's pins: bands
  on wide diagrams, side columns on narrow ones (`SIDE_PINS_RATIO`, `PIN_SIDE`). Tests:
  `tests/integration/test_school_picture_g8life.gd` (49 samples at five sizes, every kind, view, material and type,
  broken data, the rules, every labelled part's place).
- **`G8LifeGen`** (`core/school/gen/g8_life_gen.gd`, SchoolGen source **`g8l`**, the last SOURCES line): 60
  generators (formation, match_stats, tactic_change, fitness_test, test_result, profile_read, week_activity,
  activity_kind, thinking_trap, coping_choice, three_ps, review_step, online_sign, online_action, wheel_odds, loot_odds,
  chance_myth, pressure_kind, substance_law, refusal, cpr_count, cpr_step, survey_share, campaign_plan, screen_time,
  focus_habit; spec_point, plan_time, cutting_list, smart_use, material_mass, composite_part, threshold_output,
  battery_life, control_loop, lever_ma, gear_ratio, tackle_effort, ma_efficiency, safety_factor, structure_feature,
  nutrient_job, per_portion, dietary_need, processing, food_footprint, loop_order, cost_per_year, repair_feature,
  impact_kind, standby_energy, automation_level; reliability, parts_budget, frame_count, source_type, years_between,
  goal_rate, correlation, survey_question). Test: `tests/unit/test_g8_life_gen.gd` (every generator valid at every level
  for 120 seeds with a hint, a worked answer, `data` and a valid picture; every answer, 21,600 of them, worked out again
  with the test's own facts and rules, including its own correlation coefficient; no hint names the right choice).
- **The content test** `tests/unit/test_school_content_g8_life.gd` (written first; it failed with the picture class
  missing, then with every unit unwritten): the bar (4-8 cards, 12+ exercises at three levels, two kinds, rounds that
  fill, vary and never repeat), the School's quality bar (`test_school_quality.gd`'s `bar`, whose scope is grades 3-7),
  the files, hints and worked answers, memory of grades 3-7 first and the world last, no prompt twice, the `g8l`
  generators each used, the facts each lesson teaches, kind health words, substances and gambling each only in their
  unit with no street names and nothing that invites use, gold, nothing personal and no brands, the pictures each unit
  needs, every new kind on a lesson card, every label's line on its part (`part_at`), the Life links, the CPR beat heard
  and a build in every project, and the pictures' rules worked out again (a gear train's ratio, a tackle's effort, a
  wheel's expected win and loss, a plan's end).

## Tests
- Looked at (a window was available): every picture sample in contact sheets at the label box's size, and the School's
  own screens (`tools/school_shots.gd --exercises`) for CPR and defibrillators, Engineering big structures, Smart and
  modern materials and Circular design (cards and label exercises). Fixed from what they showed: the profile's title
  and ring numbers ran into the top label; the stay curve's key met the label band; the rescuer's head floated (now on a
  neck, forward over the patient, clear of the top pin); the pads' wires looped; the shape-memory wire's "set shape"
  is straight; the circular economy's words crossed the loops (now numbered tags and a key); narrow diagrams' pins
  covered the drawing (now side columns); the shock button's pin crossed the pads pouch (the buttons moved); the loops
  exercise labels four well-spaced loops (maintain and reuse are too close to label both).
- The new content, generator and picture tests (18 + 4 + 7 tests, 155,072 asserts) pass on the final commit; the shared
  `test_school_content.gd`, `test_school_quality.gd`, `test_school_curriculum.gd`, `test_school_data.gd` and
  `test_school_picture_kinds_unique.gd` pass (their first run found "you lose", a word the shared kind-words list keeps
  out, in the prize wheel's worked answer: now "each spin costs … more than it pays back"); `tools/school_check.gd`
  finds no problem in the 23 units; `python3 tools/school_audit.py --check` finds none.
- **The full suite** (2026-10-17, `tests/run_tests.sh`, on the final commit): 1,225 scripts, 11,333 tests: 11,330
  passing, 0 failing, 3 risky or pending, in 4,323 s; exit 0, no SCRIPT ERROR or parse error. The three are not this
  branch's: `test_the_column_cache_changes_nothing` and `test_chunks_meet_without_seams` (the meadows generator, noted
  by earlier agents) and the Nakama move test (no server here).

## Facts checked
Checked on the web on 2026-10-17: the National Gambling Helpline 0808 8020 133 (GamCare; free, 24 hours); the Belgian
Gaming Commission's April 2018 finding that paid loot boxes are games of chance under Belgian law; the UK's ban on the
sale of single-use vapes from 1 June 2025; Childline and the IWF's Report Remove for under-18s; Frank Pantridge's
portable defibrillator, Belfast, winter 1965 (on the road on 1 January 1966 in some sources); the UK CMOs' 2019
guidelines (150 moderate or 75 vigorous minutes, strength on 2 days; one vigorous minute about two moderate ones, the
NHS's and the Nutrition Society's rule of thumb, which a 2025 study says undercounts vigorous activity); the NHS's two
weeks for low mood; CPR at 5 to 6 cm and 100 to 120 a minute, 30:2 for trained rescuers, the pads below the right
collarbone and on the left side (Resuscitation Council UK summaries); the UK's right to repair rules from 1 July 2021
(spare parts for 7 or 10 years for washing machines, fridges, dishwashers and screens); the NHS's 25 g of fibre a day
for 11-16-year-olds and SACN's 6 g of salt from age 11. From the record (standard references): Wilma Rudolph (polio,
three golds in Rome, 1960); the Tacoma Narrows Bridge (7 November 1940); pasteurisation at 72 °C for 15 seconds;
densities of steel, titanium, aluminium and carbon fibre composite; Poore and Nemecek (2018) on food's greenhouse gases
(beef about 100 kg a kg, peas about 1); the levels of driving automation (0-5, SAE J3016); the UK CMOs' alcohol-free
childhood (2009); the Confiscation of Alcohol (Young Persons) Act 1997; FRANK and Childline; the 17 Global Goals; the
first inter-city railway (Liverpool and Manchester, 1830), the first powered flight (1903), votes on equal terms (1928),
the Moon landing (1969), the Berlin Wall (1989), the first website (1991).

## Rulings (decided here; cost if wrong)
1. **The source is `g8l`** (`g8_life_gen.gd`, `G8LifeGen`), as the lead gave it. *Cost:* none.
2. **No street drug is named** (grade 7's ruling kept); the substances unit teaches alcohol, nicotine and the law on
   sale, and FRANK for drugs. *Cost:* a card if the owner wants named drugs.
3. **Private pictures are taught as RSHE does:** "nude or nearly nude" once, the UK law for under-18s, "never your
   fault", Report Remove and CEOP, with no other detail. *Cost:* a card's words if the owner wants it gentler (or the
   unit listed for grown-ups, like hard history).
4. **"Dietary needs", never "diet":** the outline's goal "Plan for special diets" is kept unchanged (only `file` fields
   were touched), while lessons avoid the word (health is taught kindly). *Cost:* one goal's wording.
5. **"Plus or minus", not ±:** the School's letters (`ALLOWED`) have no ±; tolerances are written in words. *Cost:*
   adding ± to `ALLOWED` if the font draws it.
6. **One vigorous minute counts as about two moderate ones** (the NHS's rule of thumb), stated as "about". *Cost:* a
   card if newer research changes the guidance.
7. **The history documentary is not marked hard history:** its turning points are peaceful; sad parts are to be told
   "truthfully and with respect". *Cost:* a `hard` line if the owner wants it listed.
8. **"The first inter-city railway (1830)"**, not "the first passenger railway" (the Stockton and Darlington carried
   passengers from 1825). *Cost:* none.
9. **Fitness ratings are "this club's table"**, not national norms. *Cost:* a table if norms are wanted.
10. **Life links name only Experiences that exist now** (Life L3b's, being written at the same time, are not named).
    *Cost:* a line each when new ones land.

## For the lead (merging)
- Conflicts to expect: `core/school/school_gen.gd` (a SOURCES line after `g8h`; the arts agent adds `g8c`),
  `ui/school/school_picture.gd` (a header paragraph and two hooks after `SchoolPictureG8Hum`; the arts agent adds its
  own), `data/school/grade8.json` (23 `file` lines), `docs/DEVELOPMENT.md` (a bullet after grade 8's humanities), the
  spec's §22.4h.
- **Life's map** (`data/life/life.json`, not touched here): these School units could join its areas as `school: true`
  units: mental_health_support and bouncing_back (feelings), respect_online (people), gambling_harms (money),
  pressure_and_substances and cpr_defibrillator (safe), nutrition_for_life and food_production (home), circular_design
  and future_tech (world).
- After merging: `python3 tools/school_outline.py --write docs/superpowers/plans/2026-09-28-school.md` (not run here).
- Grade 8 now has nine subjects written by this branch and the humanities; with the arts agent's three it has all
  twelve. Next for grade 8: the research's remaining maths, science and English units.
