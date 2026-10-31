# Grade 6 health and PE, design and technology, projects: every unit written (owner #70, #73; 2026-09-30)

The owner: "start from grade 3 and finish all grades accordingly" and "research school programs, world leading schools
and create better school program". The research (`docs/design/school-curriculum-research.md` §6.6) lists grade 6's
Health and PE (11), Design and Technology (9) and Projects (3) units; this agent wrote all 23 of them, following the
reusable brief `docs/superpowers/plans/2026-09-29-school-subjects-brief.md` (GRADE 6, SUBJECTS health_pe, design_tech,
projects), building on grades 3, 4 and 5 of the same subjects (`docs/devlog/parts/m8-grade3-life.md`, `m8-grade4-life.md`,
`m8-grade5-life.md`). Branch `worktree-agent-a29f7b7966900b722`, from `lead-merge` ae6c999f ("the New Seven merged").

## What was written
| Subject | Units | Lesson cards | Hand-written exercises | Generators used (g6w) |
|---|---|---|---|---|
| Health and PE | 11 | 88 | 176 | pulse_rate, fitt_plan, fitt_change, formation, tactic_pick, relay_split, jump_measure, sprint_speed, success_rate, five_a_day, nutrient_job, wellbeing_way, box_breath, control_sort, substance_facts, emergency_call, naismith, kit_check |
| Design and Technology | 9 | 72 | 144 | spec_check, interview_q, nature_idea, truss_count, struct_force, lever_class, lever_balance, gear_ratio, linkage_move, sensor_pick, threshold_check, food_zone, microbe_double, date_check, unit_price, portion_cost, material_family, density_float, style_sort |
| Projects | 3 | 24 | 49 | market_price, weather_week, decision_matrix |
| **All** | **23** | **184** | **369** | **40 new generators**, each at levels 1-3 |

- **Files:** `data/school/g6/<subject>/<unit>.json`, linked from `data/school/grade6.json` (only these 23 units' `file`
  fields changed; titles, standards and goals kept; tab indentation kept).
- **Every unit:** a lesson of 8 cards that opens with "Quick memory: …?" naming the grade 3, 4 or 5 unit it builds on
  (its answer in brackets, then what today adds) and ends with "Try it in the world: … Next: …" (research §5.3 rules 1,
  7 and 8); 16-17 hand-written exercises (at least 4, 6 and 6 at levels 1, 2 and 3, so a round never repeats one) of
  3-6 kinds: choice, true or false, number, order, sort, match, build (one in every project) and label (the lever, the
  sensor system and the weather station, 5 in all); each with a hint (a strategy, never the answer) and an explain (the
  worked answer). Choices are written right-first (RoundPlan shows them in a seeded order).
- **Health and PE** (England PE and RSHE, SHAPE America, NHES, CASEL): training principles (FITT, the UK Chief Medical
  Officers' 60 minutes a day on average, the talk test, counting a pulse, overload, progression, specificity,
  reversibility, rest, warming up and cooling down); team tactics (formations like 4-4-2 without the goalkeeper; width,
  support, penetration and movement; pressure, cover, compactness, delay and marking; transition and counter-attacks;
  fair play); athletics technique ("On your marks" and "Set" in the blocks, the drive phase, the 4 × 100 m relay's 30 m
  takeover zone, check mark and "Hand!", upsweep and alternate hands, the long jump's phases and measuring to the nearest
  mark, the triple jump's hop, step and jump, no-jumps); analyse and improve (preparation, execution, recovery, teaching
  points, success rates, slow motion, What went well and Even better if, the improvement cycle); food as fuel (energy
  in words only, carbohydrates, protein, fibre, calcium, iron, vitamin C, the balanced plate, 5 A DAY by the NHS rules,
  6 to 8 glasses of fluid, a good breakfast); mental health (everyone has it, all feelings are normal, the five ways to
  wellbeing on a hand, when to get help, trusted adults, Childline 0800 1111); stress and coping (the body's stress
  signs, a little stress helps, box breathing (met in grade 4), 5-4-3-2-1 grounding, planning in steps, talking, the
  circle of control); respectful relationships (respect, trust and unsafe secrets, personal space, asking first before
  borrowing, hugging or sharing a photo, stereotypes, bullying in person and online, upstanding); smoking, vaping and
  alcohol (see Safety below); serious emergencies (what counts as one, 999 and 112, the four services, FAST for a stroke,
  heart attack signs, pressing on bad bleeding, cooling a burn for 20 minutes, CPR at 100-120 a minute heard as a beat
  and learned hands-on with a trained adult, the defibrillator); outdoor challenge (route planning, contours, Naismith's
  rule, route cards and escape routes, weather and kit, team roles, telling someone, 999 for the police and mountain
  rescue, six whistle blasts, the Countryside Code).
- **Design and Technology** (England D&T, Finland's crafts and home economics): user-centred design (users, interviews
  with open and closed questions, observation, user profiles, brief and specification, ACCESS FM, measurable points);
  ideas from nature (biomimicry: George de Mestral's burrs and hook-and-loop, the kingfisher's beak and a bullet train's
  nose, honeycomb panels, the lotus leaf and self-cleaning paint, the humpback's flipper and turbine blades, the termite
  mound and a cooled building in Harare, geckos, owls); structures and forces (compression, tension, bending, torsion,
  shear; struts and ties; triangulation; trusses with their squashed top and stretched bottom; frame, shell and solid
  structures; stability); mechanisms (the three classes of lever, moments in newtons with distances in marks, reverse,
  parallel and bell crank linkages, gear ratios and speeds, compound trains); sensors and switches (input, process,
  output; LDRs and thermistors, moisture, sound, PIR, tilt and reed switches; thresholds; push-to-make and push-to-break);
  food science (bacteria, moulds and yeasts, doubling every 20 minutes, the danger zone 5-63 °C, fridge 0-5 °C, freezer
  −18 °C, a core of 75 °C, 2 hours for leftovers, the bottom shelf for raw meat, use by and best before, proteins set,
  starch thickens, browning); cooking on a budget (planning, costing, cost per portion, price per 100 g, seasonal food,
  beans and lentils, frozen vegetables, less waste, cooking safely); material families (hardwoods, softwoods and boards,
  ferrous and non-ferrous metals, alloys, thermoplastics and thermosets, composites, properties, density); design
  movements (Arts and Crafts and William Morris, the Bauhaus, Walter Gropius and Marcel Breuer, Louis Sullivan's "form
  ever follows function").
- **Projects** (IB PYP, Finland's modules, Japan's integrated study, Cambridge Global Perspectives), each plan, make,
  test and present in the game's world: a medieval market town (a charter, guilds, fair prices by ratio, a 10% toll, a
  market court; build: a market square of area 24 and perimeter 20; the takings shared 2 : 3); a weather station (the
  instruments and where they go, making a rain gauge and a wind vane, a week's spreadsheet with =AVERAGE and =SUM, line
  and bar charts; build: 3/7 of a wall for the rainy days); design for a real need (interviewing Mimi's grandad, a
  brief and ACCESS FM, a decision matrix with and without weighting, a prototype, testing 3 times and the mean,
  improving one thing at a time, presenting; build: a raised bed of area 12 and perimeter 14).

## Safety (research §5.4)
- **Rule 5, harmful substances:** only in "Smoking, vaping and alcohol": the body (tar, carbon monoxide, nicotine and
  addiction, second-hand smoke, most lung cancers, alcohol slowing the brain's messages, balance, speech and judgement,
  the liver), the law in the UK (no sales of alcohol, cigarettes or nicotine vapes to under-18s, no buying them for
  under-18s, no smoking in a car with under-18s in England and Wales; "other countries have their own laws"), the norm
  (most young people do not smoke, vape or drink) and saying no (clearly, with a reason, something else to do, walking
  away, telling a trusted adult). Nothing shows use; the unit's only picture is the lungs (no people drawn). The test
  keeps the substance words out of the other 22 units and every generated exercise (the next-unit line of
  "Respectful relationships" says "how to say no to things that harm your body").
- **Rule 4:** nothing about puberty or reproduction; no weight talk (the word never appears, even in D&T: a lever lifts a
  "load", a lunch box has a "mass", a market's scales are "honest"), no calories or diets, no good or bad foods; energy
  balance in words only. Relationships stay with friends, family and everyone ("ask first"), never romance.
- **Money** is the game's gold; no personal questions (the interview questions are about bags, lunch boxes and walks).
- The content test checks it: `test_health_is_taught_kindly`, `test_harmful_substances_are_taught_only_factually_in_their_
  own_unit`, `test_money_is_gold_and_nothing_personal_is_asked`, `test_the_lessons_teach_their_facts`.

## New: pictures and generators
- **`SchoolPictureG6Health`** (`ui/school/school_picture_g6health.gd`, hooked into `SchoolPicture.problem` and `_draw`
  after `SchoolPictureG6Arts`), 18 kinds: `lever_class` (pivot, load and effort anywhere along a bar; the effort pushes
  down across the pivot and lifts up on the same side (`effort_up`); forces as values; a scale of marks from the pivot;
  `names: false` for labelling), `linkage` (reverse, parallel, bell crank, crank and slider; input and output arrows by
  `linkage_output`), `truss` (a Warren truss: `truss_counts` 2p − 1 triangles, 4p − 1 bars, 2p + 1 joints; forces
  coloured; triangles numbered; a load), `struct_force` (the five forces), `biomimicry` (six nature-and-design pairs),
  `material_swatch` (13 materials with their look), `design_style` (Arts and Crafts and Bauhaus patterns, chairs and
  lamps), `sensor_system` (input, process, output with icons; one hidden), `threshold_graph` (readings, a dashed
  threshold, `on_at`), `breath_box`, `control_rings`, `food_thermo` (the zones, `zone_of`), `microbe_split`,
  `weather_kit` (thermometer, rain gauge, wind vane, anemometer, barometer), `access_fm`, `talk_test`, `fast_signs`,
  `track_field` (the crouch start's two positions, the relay zone, the long jump with `jump_length`, the triple jump).
  `part_at` gives where a label's part is (lever, sensor system, weather kit, truss). Test:
  `tests/integration/test_school_picture_g6health.gd` (samples of every kind and option at five sizes, the rules, parts,
  broken data).
- **Generators** (`core/school/gen/g6_health_gen.gd`, `G6HealthGen`, SchoolGen source **"g6w"**, the last SOURCES line;
  seeded, levels 1-3, each with a hint, a worked answer and `data`): the 40 listed above. Test:
  `tests/unit/test_g6_health_gen.gd` works every answer out again with its own facts and rules (FITT, principles,
  tactics, 5 A DAY, nutrients, the five ways, control, substance facts, services, FAST, kit, ACCESS FM, open questions,
  nature, forces, lever tools, sensors, material families, styles and years), 120 seeds × 3 levels.

## Tests
- `tests/unit/test_school_content_g6_health.gd` (written first; it failed with the picture class missing, then with every
  unit not written): every unit written to the bar (4-8 cards, 12+ exercises at levels 1-3 of two kinds, rounds that
  fill, never repeat a hand-written exercise, and vary), the files, strategy hints and worked answers, memory first
  (naming grade 3, 4 or 5) and the world and Next last, no prompt twice, the "g6w" generators (each used), the facts
  each lesson must teach, kind health words, substances only in their unit and no people drawn there, gold and nothing
  personal, the pictures each unit needs, every label's line on its part (`part_at`), the CPR beat heard at 100-120 a
  minute, a build in every project, and the pictures' rules worked out again (lever classes, linkages, food zones,
  a truss's triangles and bars).
- The shared `test_school_content.gd`, `test_school_curriculum.gd` and `test_school_picture_kinds_unique.gd` pass with
  these units, as do grade 6's arts and humanities content tests.
- **The full suite** (`tests/run_tests.sh`, 2026-09-30, on 0cd6d649): 954 scripts, 8,692 tests, 8,689 passing, 1
  failing, 2 risky (not asserting, not this agent's: `test_the_column_cache_changes_nothing`,
  `test_chunks_meet_without_seams`), in 3,005 s. The failure is not this agent's:
  `test_world_sync.gd::test_a_change_while_a_saved_chunk_is_compared_off_the_main_thread_reaches_the_guest` (its
  15 s wait for "a saved chunk is being compared" ends with the list empty, then line 207 reads index 0); it fails
  alone too, on a PC with a load of about 15 (two other agents' full suites running), and this branch changes no world,
  sync or network file.
- The unit files were made with scratch Python scripts (lengths, levels, first and last cards, words: US spellings,
  unkind words, health words, substance words outside their unit, brands, currencies, letters, sums, label pins apart).
- Pictures looked at with a scratch render script (every sample at card and choice sizes) and with
  `tools/school_shots.gd` (windowed, its own XDG folder) for the mechanisms and weather station units: the lever sat low
  on tall cards, so it is now centred up and down; the sprint start's figure was redrawn from real positions; the food
  thermometer was centred with its unit under the bulb; the whale's flipper was redrawn; a barometer lives indoors (no
  ground line); the outdoor map's points were moved off the contour labels.

## Facts checked (2026-09-30)
- NHS: burns cooled under cool or lukewarm running water for 20 minutes, never ice or butter, cling film
  (https://www.nhs.uk/conditions/burns-and-scalds/); FAST (https://www.nhs.uk/conditions/stroke/symptoms/); five steps to
  mental wellbeing (https://www.nhs.uk/mental-health/self-help/guides-tools-and-activities/five-steps-to-mental-wellbeing/);
  5 A DAY: potatoes do not count, juice and smoothies 150 ml once, beans and pulses once, 80 g a portion
  (https://www.nhs.uk/live-well/eat-well/5-a-day/5-a-day-what-counts/).
- UK Chief Medical Officers: children and young people, an average of at least 60 minutes of moderate-to-vigorous
  activity a day across the week
  (https://www.gov.uk/government/publications/physical-activity-guidelines-uk-chief-medical-officers-report).
- Resuscitation Council UK: compressions at 100-120 a minute, the same for adults and children
  (https://www.resus.org.uk/professional-library/2025-resuscitation-guidelines/adult-basic-life-support-guidelines).
- Food - a fact of life (the British Nutrition Foundation's schools programme): the danger zone 5-63 °C, bacteria best
  at about 37 °C, the 4 Cs, core 75 °C, fridge 0-5 °C, freezer −18 °C; the FSA's legal limit for chilled food is 8 °C
  (ruling 7).
- NHS England Digital, Smoking, Drinking and Drug Use among Young People in England 2023: 11% of 11-15-year-olds had
  ever smoked, 25% had ever vaped, 9% vaped now, so most do not
  (https://digital.nhs.uk/data-and-information/publications/statistical/smoking-drinking-and-drug-use-among-young-people-in-england/2023).
- UK law: smoking in vehicles carrying under-18s banned in England and Wales from 1 October 2015
  (https://www.gov.uk/government/news/smoking-in-vehicles); age of sale 18 for alcohol, tobacco and nicotine vapes, and
  proxy purchasing an offence. Cancer Research UK: tar, carbon monoxide and nicotine
  (https://www.cancerresearchuk.org/about-cancer/causes-of-cancer/smoking-and-cancer/whats-in-a-cigarette); smoking
  causes about 7 in 10 lung cancers ("most").
- World Athletics: the 4 × 100 m takeover zone is 30 m (the 10 m acceleration zone merged in, rule change 2017-2018)
  (https://worldathletics.org/news/iaaf-news/competition-rule-amendments-june-2018); the long jump measured from the
  take-off line to the nearest mark.
- Naismith's rule: 1 hour for 5 km plus 1 minute for every 10 m of ascent (https://en.wikipedia.org/wiki/Naismith's_rule).
- Countryside Code (2021): respect everyone, protect the environment, enjoy the outdoors; leave gates as you find them;
  take litter home (https://deframedia.blog.gov.uk/2021/04/01/new-countryside-code-launched-to-help-people-enjoy-the-outdoors/).
- Met Office: thermometers 1.25 m above short grass in a screen; the rain gauge's rim 30 cm above short grass
  (https://www.metoffice.gov.uk/binaries/content/assets/metofficegovuk/pdf/weather/guides/10_0230_fs_17_observations.pdf).
- George de Mestral: burdock burrs on a 1941 walk with his dog in the Alps, patented in 1955
  (https://en.wikipedia.org/wiki/George_de_Mestral). The 500 Series Shinkansen's kingfisher-beak nose: quieter tunnel
  entry, about 15% less electricity (https://en.wikipedia.org/wiki/500_Series_Shinkansen).
- From the record: William Morris (1834-1896) and "Have nothing in your houses that you do not know to be useful, or
  believe to be beautiful" ("The Beauty of Life", 1880); Morris, Marshall, Faulkner & Co. (1861); the Arts and Crafts
  Exhibition Society's first show (1888); the Bauhaus (Weimar 1919, Dessau 1925, Berlin 1932, closed 1933; Walter
  Gropius); Marcel Breuer's tubular steel chair (1925); Louis Sullivan, "form ever follows function" (1896); James Watt
  (1769); the lever classes; brass (copper and zinc), bronze (copper and tin), steel (iron and carbon); balsa is a
  hardwood; densities (pine about 0.5, oak about 0.75, balsa about 0.16, polythene about 0.92, acrylic about 1.2,
  aluminium 2.7, concrete about 2.4, steel about 7.9 g/cm³); LDRs (less resistance in bright light) and thermistors;
  a push-to-break fridge switch; UK emergency numbers 999 and 112; Childline 0800 1111; 6 whistle blasts.

## Rulings (decided here; cost if wrong)
1. **The generator source is "g6w"** (file `g6_health_gen.gd`, class `G6HealthGen`), like g4w and g5w; grade 6 already
   has g6n, g6a, g6h and g6c. *Cost:* a rename.
2. **Harmful substances only in their own unit**, factual (the body, the law, the norm and saying no), with only the
   lungs drawn; **gambling is not taught** here (the outline's goals name smoking, vaping and alcohol only). *Cost:* a
   card and a fact bank if the owner wants gambling (a citizenship money unit would fit better).
3. **UK law, framed as the UK's** ("other countries have their own laws"); the sale law says "nicotine vapes", the
   narrowest true statement; the single-use vape ban (2025) and the Tobacco and Vapes Bill are not taught while laws
   change. *Cost:* a line.
4. **CPR is named, heard and not taught as a technique** (the outline: "learned hands-on with a trained adult"); a child
   learns when to call, the rate (a clap at 110 and 120 a minute) and that the 999 call handler guides anyone. *Cost:* a
   unit in a later grade.
5. **No maximum heart rate formula** (220 − age is a rough adult estimate); the talk test and counting your own pulse are
   what a child can check. *Cost:* a card.
6. **Energy balance in words only**: no kilojoules or calories counted for a child's own food, no weight words (research
   §5.4 rule 4, the lead's "no body shaming"). *Cost:* a card.
7. **The danger zone is 5-63 °C**, as UK schools teach it (Food - a fact of life), though the FSA's legal limit for
   chilled food is 8 °C; the fridge 0-5 °C, the freezer −18 °C or colder, a core of 75 °C. `food_thermo`'s `zone_of`
   leaves −17 to −1 °C in no zone, and no exercise uses those temperatures. *Cost:* numbers in three cards and a rule.
8. **5 A DAY by the NHS's rules, counted in items** (juice and smoothies once, beans and pulses once, potatoes never),
   not in grams. *Cost:* a generator table.
9. **Lever forces in newtons** (as grade 5 science wrote them) **and distances in marks** along the bar (no unit), so
   moments stay whole numbers a child can check; the effort's arrow follows the physics (`effort_up`), where grade 3's
   `lever` always pushes down. *Cost:* none.
10. **Warren trusses only** (2p − 1 triangles, 4p − 1 bars): on two supports with a load, the top chord is squashed and
    the bottom stretched. *Cost:* other truss types.
11. **Living people are not named**: the bullet train's engineer is "a train engineer who watched birds", the Harare
    building is unnamed; the people named (de Mestral, Morris, Gropius, Breuer, Sullivan, Watt) are of the past. No
    brand names ("hook-and-loop fastener"). *Cost:* none.
12. **The Bauhaus "closed in 1933"**, without its politics (hard history is history's, and D&T at grade 6 tells the design
    story). *Cost:* a sentence.
13. **Formations are football's** (11-, 7- and 5-a-side), counted without the goalkeeper. *Cost:* a table for hockey or
    netball.
14. **Projects' memory questions name grade 5** (the fair, the expedition, test and review), though they also draw on
    grade 6 units (castles_feudal, ratios, spreadsheet_models, climate_graphs); the content test asks for grades 3-5.
    *Cost:* none.
15. **Labels test knowledge**: the lever is drawn without its words (`names: false`), the weather kit without its names,
    the sensor system without its headings; pins sit beside the drawing with a line to the part (`part_at`, checked).
    *Cost:* none.
16. **"Ask first" is the RSHE primary level of consent** (borrowing, hugging, sharing a photo), with friends and family;
    no romantic relationships. *Cost:* a unit in a later grade.
17. **Bram is "he", and Tilly, Zara and Mimi "she"**, as the other School units write them; the generators' prompts use
    names. *Cost:* none.

## For the lead (merging)
- `test_world_sync.gd::test_a_change_while_a_saved_chunk_is_compared_off_the_main_thread_reaches_the_guest` failed in
  this branch's full suite and alone (see Tests); it is outside this work (no world or sync file changed): check it on
  `lead-merge` when the PC is quieter.
- Conflicts to expect: `core/school/school_gen.gd` (a SOURCES line at the end: "g6w"), `ui/school/school_picture.gd` (a
  header paragraph and two hooks after `SchoolPictureG6Arts`), `data/school/grade6.json` (the `file` lines of these 23
  units), `docs/DEVELOPMENT.md` (a bullet at the end of the School section), the spec's §22.4f (one bullet).
- After merging: `python3 tools/school_outline.py --write docs/superpowers/plans/2026-09-28-school.md` (not run here).
- Picture kind names are new and checked unique (`test_school_picture_kinds_unique.gd`); a parallel agent's new kinds
  could still collide on merge.
