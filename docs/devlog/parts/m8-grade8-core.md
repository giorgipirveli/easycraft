# Grade 8 maths, science and English: the research's last 14 units (owner #70, #73, #111; 2026-10-17)

The owner (#111, 2026-10-16): "we want to have full school programs and sylabusse content in the game"; the School never
ends (#71). Grade 8's maths, science and English were written in the first School (2026-09-28: 16 + 11 + 12 units); the
research (`docs/design/school-curriculum-research.md` §6.8) added 14 more that stayed "Coming soon": Singapore Secondary
2's expanding, factorising and trigonometry, England's KS3 pressure, energy bills, energetics, current and voltage and
gas exchange, NGSS MS-PS1-6 and MS-LS4-5, and Common Core RL/RI.8.1, RL.8.9, W.8.1-3 and SL.8.4-5. This agent wrote all
14, following the reusable brief (`docs/superpowers/plans/2026-09-29-school-subjects-brief.md`, GRADE 8, SUBJECTS
maths, science, english), with the source `g8k` and the lead's rule that a unit whose topic is a Life or Success
Experience ends by naming it in the LIFE tab. Branch `worktree-agent-ae2f723b8549946b1`, from lead-merge at 802d299b.

## What was written
| Subject | Units | Cards | Hand-written exercises | Kinds of exercise | Generators (`g8k`) |
|---|---|---|---|---|---|
| Maths | 2 | 16 | 33 | number 13, choice 5, true/false 4, match 4, sort 2, order 2, label 2, build 1 | 6 |
| Science | 6 | 48 | 96 | number 29, choice 23, true/false 16, sort 8, order 8, match 7, label 5 | 17 |
| English | 6 | 48 | 96 | choice 40, true/false 20, sort 13, order 13, match 10 | 14 |
| **All** | **14** | **112** | **225** | | **37**, each at levels 1-3 |

- **Files:** `data/school/g8/{maths,science,english}/<unit>.json`, linked from `data/school/grade8.json` (only these 14
  units' `file`; titles, goals and standards kept; the file round-trips through `json.dumps` with tabs). Grade 8 now has
  all 136 units of its outline written (`docs/superpowers/plans/2026-09-28-school.md` regenerated).
- **Every unit:** 8 cards, one idea each: "Quick memory:" with a question from grade 5, 6 or 7 (its answer in
  brackets) first, a worked example, "Try it in the world: … Next: …" last; 16 hand-written exercises (17 in expanding
  and factorising), 5 or 6 at each level, of 5-8 kinds, at most 62% choice or true-or-false, each with a strategy hint
  and a worked answer; two or three generators at each level. Pictures on at least half the teaching cards in maths and
  science, a third in English. Choices are written right-first (RoundPlan shows them shuffled).
- **The audit** (`python3 tools/school_audit.py --grades 8 --units`): every one of the 14 scores 100 once this file
  names it. Before this file: 95-100, with "not in the notes" and five units' level 3 "no harder than level 1"; the
  level-1 matches (many items) moved to level 2 and a short level-2 true-or-false to level 1, and three level-3 worked
  answers got their full steps. `tools/school_check.gd` finds no problem in the 14 (a ratio table's cells first shrank
  to 16 px: now "on top" and "under the line" columns).

### Maths (Singapore Secondary 2, England KS3)
- **Expanding and factorising** (`expand_factorise`): two brackets as a rectangle's four parts (an area model), every
  term times every term and the signs, the special products (a + b)² and (a + b)(a − b), factorising as expanding
  backwards (a common factor first; two numbers that multiply to the number term and add to the middle one), a
  difference of two squares, checking by expanding, the parabola y = x² (symmetrical, its vertex) and y = x² − 4's
  crossings; a build (with x = 3, the rectangle (x + 2)(x + 1)); 21 × 19 by (20 + 1)(20 − 1). Builds on grade 7's
  expressions; next: transformations.
- **Sine, cosine and tangent** (`trig_ratios`): the sides named from the marked angle (at the bottom left, and at the
  top, where the opposite side becomes the base), similar triangles make each ratio depend on the angle alone, SOH CAH
  TOA, a 3, 4, 5 triangle, finding a side by multiplying (a ladder at 60°) or dividing (tan 40°), finding an angle with
  the inverse key or a table of ratios to 2 decimal places. Builds on grade 7's scale drawings and grade 8's
  Pythagoras; next: volume. **Ruling 1** below (ratios to 2 decimal places).

### Science (England KS3, NGSS, Singapore Secondary 2)
- **Pressure** (`pressure`): pressure = force ÷ area in pascals, the same brick on two faces, pins and snowshoes,
  pressure in liquids growing with depth and pushing in all directions (a raised tank's spouts, a dam), about 10 kPa a
  metre of sea water, air pressure (about 100 kPa at sea level, falling with height: a line graph from 101 kPa to
  36 kPa at 8 km), upthrust and floating (less dense than water; a steel ship's hull; a submarine's tanks), density.
  Builds on grade 7's particles; Life: Water Safety (lying flat on ice spreads the force).
- **Energy, power and bills** (`energy_bills`): a watt is a joule each second, energy = power × time, appliances'
  powers, kilowatt-hours (units), the electricity counter's readings, cost = units × price in gold and a daily
  standing charge, standby, LEDs (about 8 W for a 60 W filament bulb's light), why a high power for a short time can
  use less. Builds on grade 6's Sankey diagrams; Life: Electricity Safety (a 3 kW kettle takes about 13 A, all a socket
  gives). **Ruling 2** ("electricity counter").
- **Hot and cold reactions** (`hot_cold_reactions`): measuring a temperature change, exothermic and endothermic
  examples, energy level diagrams, breaking bonds takes energy in and making them gives it out, activation energy (a
  match), uses (hand warmers, self-heating cans, gel warmers, instant cold packs). Builds on grade 7's reactions; Life:
  the Poisons Cupboard (never mix cleaners).
- **Current, voltage and resistance** (`circuits_voltage`): current in amps by an ammeter in series, voltage in volts by
  a voltmeter in parallel, series (the same current, shared voltages) and parallel (the full voltage, currents that
  add), resistance = voltage ÷ current in ohms, Ohm's law's straight line and a lamp's bending one. Builds on grade 5's
  electric systems; Life: Electricity Safety (the fuse box and the RCD). "Ω" is not in the School's font list, so the
  lessons write "ohms".
- **Transport in plants and animals** (`transport_systems`): diffusion and why big living things need transport, xylem
  and phloem, root hairs, transpiration and stomata, the heart's four chambers seen from the front (the person's right
  on the picture's left), valves, arteries, veins and capillaries, the blood's parts, gas exchange in the alveoli
  (21% oxygen breathed in, about 16% out; 0.04% carbon dioxide in, about 4% out). Builds on grade 5's breathing and
  the heart; Life: Little Lifesaver (CPR moves the blood) and Medical Emergencies (an inhaler opens the airways).
- **Breeding and genes** (`breeding_genes`): selective breeding over generations (wild cabbage, wolves to dogs, milk,
  wheat), its problems (close relatives, crops all alike), genetic engineering (a gene moved into a bacterium's
  plasmid; insulin from bacteria since the 1980s), GM crops and Golden Rice (beta-carotene, vitamin A), the questions
  they raise weighed on a balance, bacteria doubling every 20 minutes. Builds on grade 5's inheritance and grade 8's
  genes; next: natural selection. No Life link (no Experience is about breeding).

### English (Common Core grade 8)
- **The strongest evidence** (`strongest_evidence`): relevant, specific and hard to read another way; explicit and
  inferred; actions over words for an inference; one precise quote over three loose ones; point, evidence, explain.
  Builds on grade 6's close reading.
- **Old stories, new versions** (`old_stories_new`): borrowed patterns, character types, themes and symbols; rags to
  riches, the quest, star-crossed lovers, the hero's journey; archetypes (Anansi the trickster); Romeo and Juliet from
  Arthur Brooke's poem of 1562, West Side Story (1957); Frankenstein (1818), The Modern Prometheus; what a new version
  keeps, changes and why (our own story, The Midnight Code). Builds on grade 7's allusions.
- **Argue like a pro** (`write_argument`): claims, counterclaims and rebuttals, signal words, credible sources, logical
  reasoning (no bandwagon, no attacking the person), formal style, a strong conclusion with a call to action. Builds on
  grade 6's argument maps; Life: Talk & Deal (answering an investor's doubt).
- **Explain complex ideas** (`write_informative`): an introduction, sections under headings, structures and their
  signal words, graphics with captions and references, precise words and definitions, transitions, a conclusion.
  Builds on grade 6's information page.
- **Craft a narrative** (`write_narrative`): flashbacks and their signals ("had", a time phrase, a way back), story
  order and time order (drawn as two rows whose lines cross), telling details and the senses, pacing, reflection,
  transitions. Builds on grade 6's story arc; Life: Success Stories (retell a true story with a flashback opening).
- **Present with multimedia** (`present_multimedia`): one sentence for the findings, salient points with evidence,
  media that earn their place, clear and crammed slides, speaker notes, delivery (eye contact, volume, pronunciation, a
  pause before the key number), credit, practice, music kept under the voice, a screen that fails. Six sounds: a steady
  pace, one too quiet, one too fast, a pause, and a mix whose chords drown the tune (grade 7's balance pattern). Builds
  on grade 6's talks with charts; Life: Talk & Deal (a pitch, looking at each investor).

## Life links (owner #112, #115, #117: the School and Life work together)
| Unit | Last card points to |
|---|---|
| trig_ratios | Real Builder (the roof's slope) |
| pressure | Water Safety (spreading out on ice) |
| energy_bills | Electricity Safety (the crammed adaptor) |
| hot_cold_reactions | The Poisons Cupboard (never mix cleaners) |
| circuits_voltage | Electricity Safety (the fuse box and the RCD) |
| transport_systems | Little Lifesaver (CPR), Medical Emergencies (an inhaler) |
| write_argument, present_multimedia | Talk & Deal (a pitch to investors) |
| write_narrative | Success Stories (true stories retold) |

The others name none: no Experience is about algebra, breeding, evidence, old stories or explaining.

## Safety (research §5.4)
- Rule 4: breeding and transport stay with plants, animals and the body's systems; nothing about puberty or human
  reproduction (the content test lists the words to keep out). The heart unit says "the person's right"; no body-shape
  words.
- Rule 2: GM crops are taught as benefits and questions people raise, weighed on a balance, with "countries have
  different rules" left out of the lesson rather than naming any; no living people, no companies (the insulin story says
  "since the 1980s", no maker).
- Rule 7: no brands: slides, not a presentation program; "a games console" is not used; Golden Rice is a project's
  name, not a brand. People of the past only (Shakespeare, Arthur Brooke, Mary Shelley).
- Money is gold (0.25 gold a unit); no personal questions.

## New code
- **`SchoolPictureG8Core`** (`ui/school/school_picture_g8core.gd`, hooked into `SchoolPicture.problem` and `_draw` after
  `SchoolPictureG8Life`; it reuses `SchoolPictureG7Life`'s helpers, label bands and circuit symbols), 12 kinds (its
  header lists every field): `parabola`, `trig_triangle`, `fluid_pressure`, `energy_meter`, `energy_profile`,
  `meter_circuit`, `plant_transport`, `heart_chambers`, `air_sac`, `gene_transfer`, `slide_design`, `story_order`. Its
  rules: `parabola_y`, `roots`, `vertex`, `equation`, `meter_used`, `reading` (a meter's reading from the cell and the
  parts' resistances; `problem` refuses a number that disagrees), `flashback`. `part_at` places label pins on seven
  diagrams. Tests: `tests/integration/test_school_picture_g8core.gd` (64 samples at five sizes, every kind, view, type,
  scene and image, 66 broken pictures, the rules, every labelled part's place, and the opposite side moving with the
  marked angle).
- **`G8CoreGen`** (`core/school/gen/g8_core_gen.gd`, SchoolGen source **`g8k`**, the last SOURCES line): 37 generators
  (expand_brackets, factorise_quadratic, parabola_point, trig_sides, trig_side, trig_angle; pressure_calc,
  depth_pressure, float_sink, energy_joules, energy_kwh, energy_cost, temp_change, reaction_type, bond_energy, ohms_law,
  series_volts, parallel_amps, transport_route, transport_job, air_in_out, breed_pick, gm_or_bred; evidence_pick,
  evidence_kind, story_pattern, archetype_match, argument_part, credible_source, formal_style, graphic_pick,
  precise_word, time_order, telling_detail, shift_signal, media_pick, slide_rule). Test: `tests/unit/test_g8_core_gen.gd`
  (every generator valid at every level for 120 seeds with a hint, a worked answer, `data` and a valid picture; every
  answer, 13,320 of them, worked out again with the test's own facts: its own polynomial writer and bracket reader, the
  true sine, cosine and tangent, Ohm's law, the densities, the transport routes and jobs, the stories' time orders; no
  hint names the right choice).
- **The content test** `tests/unit/test_school_content_g8_core.gd` (written first; it failed with the picture class
  missing, then with the units unwritten): the bar (4-8 cards, 12+ exercises at three levels, two kinds, rounds that
  fill, vary and never repeat), the School's quality bar (`test_school_quality.gd`'s `bar`, whose scope is grades 3-7),
  the files, hints that never say a number answer, memory of grades 3-7 first and the world last, no prompt twice, the
  `g8k` generators each used, the facts each lesson teaches, nothing about puberty or human reproduction, gold, nothing
  personal and no brands, the pictures each unit needs, every new kind on a lesson card, every label's line on its part
  (`part_at`), the nine Life links, the talk's sounds, and the pictures' rules worked out again (a triangle's missing
  side or angle against the true ratios, a circuit's "?" meter by Ohm's law, the counter's units, a parabola's
  crossing, an energy level diagram's change; 40 or more checked).

## Rulings (with what they cost if wrong)
1. **Trigonometry without a calculator:** every exercise gives the ratio it needs to 2 decimal places ("tan 37° =
   0.75") and the answer follows from that value; finding an angle uses a table of 30°, 37°, 45°, 53° and 60° and sides
   that give those ratios exactly (3, 4, 5 triangles; 1 : 2; equal sides). The content test checks each answer against
   the true ratio within 3%. *Cost:* a child with a calculator gets 14.30 where the game says 14.3: the same to 1
   decimal place, which the prompts ask for.
2. **"Electricity counter":** the School's, Life's and Success's spelling tests (five files) ban "meter" as the US
   spelling of "metre", and no unit says "electricity meter". The energy unit says "the electricity counter" (the box
   that adds up the units). *Cost:* children learn a plain description instead of the usual word; if the lead allows
   "electricity meter" in those five lists, two cards and two exercises change one word each (and the generator's
   level-1 prompt).
3. **"ohms" in words:** the font list has no Ω. *Cost:* none.
4. **No Life link for algebra, breeding, evidence, old stories and explaining:** only units whose topic is an
   Experience name one. *Cost:* none.
5. **Level 3 harder than level 1:** where a unit was flat by the audit's measure, its level-1 match (many items) moved
   to level 2 and a short level-2 true-or-false to level 1, rather than making level 3 artificially long. *Cost:* none.
6. **Grade 8's older 39 maths, science and English units** are untouched (the brief: never change a written unit).
   They score 51-73 on the audit (no memory card, no "in the world" card, few pictures); the quality work that raised
   grades 3-7 has not reached them. *Cost:* the grade's units are uneven until a lesson-quality round reaches grade 8.

## Facts checked (2026-10-17)
- Inhaled air about 21% oxygen and 0.04% carbon dioxide, exhaled about 16% and 4% (GCSE and IGCSE notes: Save My Exams,
  TutorChase); alveoli about 480 million with 70-80 m² of surface (Wikipedia, "Pulmonary alveolus"; Scientific
  American gives 80-90 m²): the lesson says "about 70 m²" and "millions".
- Arthur Brooke's The Tragical History of Romeus and Juliet (1562), from Boaistuau's French version of Bandello's
  Italian novella, Shakespeare's main source (Wikipedia); West Side Story opened on Broadway on 26 September 1957
  (Opera America); Frankenstein; or, The Modern Prometheus (1818).
- Human insulin made by genetically engineered E. coli, approved in the UK and the US in 1982 (Genetics Unzipped,
  ACSH): "since the 1980s". Golden Rice makes beta-carotene, which the body turns into vitamin A, against blindness from
  vitamin A deficiency (SciDev.Net and others). E. coli can divide about every 20 minutes in ideal conditions (JoVE;
  Reports on Progress in Physics table).
- Instant cold packs dissolve ammonium nitrate or urea in water, taking heat in; self-heating cans use calcium oxide
  and water (CaO + H₂O → Ca(OH)₂, giving out heat; patents and a British Council activity sheet); reusable gel warmers
  crystallise sodium acetate (textbook chemistry). Bleach and acid toilet cleaners give off chlorine when mixed.
- An LED of 8-10 W gives the 800 lumens of a 60 W filament bulb (lighting suppliers); UK sockets give 13 A, and a 3 kW
  kettle on 230 V draws 3,000 ÷ 230, about 13 A; RCDs are rated 30 mA and trip within about 40 ms (product data).
- Air pressure: 101 kPa at sea level, about 80 at 2 km, 62 at 4 km, 47 at 6 km and 36 at 8 km (the standard
  atmosphere); about a third on Everest's summit, 31-34 kPa (Live Science on an Eos study). Sea water adds about
  10 kPa a metre (its density about 1,025 kg/m³ × 9.8).
- Wild cabbage (Brassica oleracea) bred into cabbage, kale, broccoli, cauliflower and Brussels sprouts; dogs from
  wolves; Anansi from Akan (West African) tales; Aesop's fables.

## Tests
- The new content, generator and picture tests pass (17 + 4 + 6 tests; 27,096 + 71,637 + 253 asserts). The shared
  `test_school_content.gd` found two things the new tests had not: `g8k.air_in_out` made only three different exercises
  at level 2 over 40 seeds (it needs four: the breaths are now 300-800 mL), and "lonely" (on the shared kind-words
  list) in a story summary (now "Rejected and angry"). Then `test_school_content.gd`, `test_school_quality.gd`,
  `test_school_curriculum.gd`, `test_school_picture.gd` and `test_school_picture_kinds_unique.gd` pass.
- **The full suite** (2026-10-17, `tests/run_tests.sh`, on this branch merged with lead-merge at c9aff724, which
  includes Life L3c and 71e6322c): 1,244 scripts, 11,535 tests: 11,532 passing, 0 failing, 3 risky or pending, in
  4,808 s; exit 0, no SCRIPT ERROR or parse error. The three are not this branch's: `test_the_column_cache_changes_nothing`
  and `test_chunks_meet_without_seams` (the meadows generator, noted by earlier agents) and the Nakama move test (no
  server here).
- Looked at (a window was available): every picture sample in contact sheets at the label box's size, and the School's
  own screens (`tools/school_shots.gd --exercises`) for sine, cosine and tangent, transport, hot and cold reactions and
  breeding (cards and label exercises). Fixed from what they showed: a vertex's coordinates on the frame, side labels on
  a wall or the ground (now on cards of their own), thin letters eaten by white edges on the energy diagram, voltmeter
  readings on their wires, part names running together, a parallel circuit's cell voltmeter that was joined across
  plain wire (now across the cell), eight crowded heart labels (`parts`), the air sac's caption on the airway, and a
  plant whose tubes were 8 px wide in a label exercise (now twice as wide).
