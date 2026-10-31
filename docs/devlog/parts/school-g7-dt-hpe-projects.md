# Grade 7 health and PE, design and technology, projects: every unit written (owner #70, #73, #111; 2026-10-16/17)

The owner: "start from grade 3 and finish all grades accordingly" (#70) and, on 2026-10-16 (#111), "when all remaining
tasks are done, you continue adding educational materials, as you know we want to have full school programs and
sylabusse content in the game"; for the whole platform (#112, #117): learn by doing. The research
(`docs/design/school-curriculum-research.md` §6.7) lists grade 7's Health and PE (11), Design and Technology (9) and
Projects (3); grade 7 had the other nine subjects. This agent wrote all 23, following the reusable brief
(`docs/superpowers/plans/2026-09-29-school-subjects-brief.md`, GRADE 7, SUBJECTS design_tech, health_pe, projects) with
the lead's changes: `git merge lead-merge` (at 979caa1d) instead of a reset; the project's tools instead of the old
scratch helper; and **a unit whose topic is a Life Experience ends by sending the child to it, by name, in the LIFE
tab** (D&T's structures, materials and tools to Real Builder and the Tool Book). One step up from grade 6
(`m8-grade6-health.md`). Branch `worktree-agent-a950124f6e4f4a24a`.

## What was written
| Subject | Units | Cards | Hand-written exercises | Kinds of exercise | Generators (`g7w`) |
|---|---|---|---|---|---|
| Health and PE | 11 | 88 | 180 | choice 60, true/false 39, number 32, sort 16, order 15, match 14, rhythm 3, label 1 | 23 |
| Design and technology | 9 | 72 | 149 | choice 46, number 36, true/false 27, sort 12, match 12, order 12, label 4 | 20 |
| Projects | 3 | 24 | 51 | number 20, choice 9, true/false 9, build 5, match 3, order 2, sort 2, label 1 | 6 |
| **All** | **23** | **184** | **380** | | **49**, each at levels 1-3 |

- **Files:** `data/school/g7/{health_pe,design_tech,projects}/<unit>.json`, linked from `data/school/grade7.json` (only
  these 23 units' `file`; titles, goals and standards kept; the file round-trips through `json.dumps` with tabs).
- **Every unit:** 8 cards, one idea each: "Quick memory:" with a question from grade 3, 5 or 6 (its answer in
  brackets) first, a worked example, "Try it in the world: … Next: …" last (the last unit of each subject names grade
  8's first: game strategy, from brief to product, an invention expo); 16 or 17 hand-written exercises (5, 5-6 and 5-6
  at levels 1, 2 and 3) of 5-7 kinds, at most 65% choice or true-or-false, each with a strategy hint and a worked answer;
  2-3 generators at each level. Choices are written right-first (RoundPlan shows them shuffled).
- **The audit** (`tools/school_audit.py`, owner #94's): every unit 100 once this file names it (98 before: only "not in
  the notes"); cards of 45 words or fewer, sentences of 22 or fewer, pictures on half the teaching cards in D&T and a
  third elsewhere, level 3 asking at least 1.1 × level 1 (a polish pass split the long sentences, shortened the long
  cards, added six pictures (a CAD model, material swatches, a calm chat, a date-label table, a chart of versions, the
  Columbian exchange) and gave level 3 fuller worked answers).

### Health and PE (England KS3 PE and RSHE, SHAPE America, NHES, CASEL)
- **Invasion games: advanced** (`invasion_advanced`): the overlap, the third-man run, the switch of play, decoy runs,
  the give-and-go, the basketball screen; man-to-man and zonal marking, goal-side, pressing as a team, the compact
  block, transition and the counter-attack, a 3 v 2 drawn on the pitch. Builds on grade 6's team tactics.
- **Racket sports** (`racket_sports`): the handshake and thumb grips, the base and the split step, the clear, drop
  shot, smash, drive and net shot (drawn as flights), choosing a shot by the opponent's place, badminton's rally scoring
  (21, 2 clear, 30 at 29-all; the serving court by an even or odd score), table tennis to 11 (the serve every 2
  points), tennis's love-15-30-40, deuce and advantage, a set's 6 games and 2 clear, doubles' front and back.
- **Your fitness plan** (`fitness_plan`): health and skill parts of fitness, 60 minutes a day on average and 3 days
  of hard and muscle- and bone-strengthening activity (WHO), the maximum heart rate about 220 − age (an estimate), the
  zones (warm-up 50-60%, aerobic 60-80%, anaerobic 80-90%), a worked zone for a 12-year-old (about 125 to 166), a week's
  plan with a rest day, progression of about 10%, SMART goals and a log.
- **Dance styles** (`dance_styles`): counting in 8s (heard), street dance (breaking's toprock, footwork and freezes in
  New York in the 1970s; popping; locking), folk dance (Irish step, Morris, Bhangra at harvest in Punjab, Georgian
  dancing on the toes, circle dances), contemporary (floorwork, fall and recovery, contraction and release, Martha
  Graham 1894-1991), unison, canon, mirroring, levels and dynamics; three rhythms to copy.
- **Leading and officiating** (`lead_and_officiate`): the referee, captain and coach; football's signals (advantage,
  direct and indirect free kicks, the penalty, the cards: drawn), advantage and its few seconds, fair play, feedback
  that is short and specific, knockouts (n − 1 matches) and round robins (n(n − 1) ÷ 2), courts and time.
- **Sleep for teenagers** (`teen_sleep`): 9-12 hours at 6-12 and 8-10 at 13-18, the body clock moving later
  (melatonin), deep and dreaming sleep in cycles of about 90 minutes, screens and the phone outside the bedroom, the same
  times every day, daylight, caffeine after lunch, sleep debt and weekend lie-ins, a sleep dial (hours across midnight).
- **What influences your choices** (`health_influences`): family, friends and peers, media, adverts, culture and
  school; the norm (most young people choose healthily); adverts' tricks (a famous person, the bandwagon, a free gift,
  a health claim, small print) on a drawn poster to label; paid posts and '#ad'; an energy drink's left-out label; the
  steps of a choice.
- **Self-image and media** (`self_image`): self-image and self-esteem, how photos are edited (drawn before and after:
  light, filter, smoothed skin, eyes, teeth, background), the signs of editing, computer-made faces, highlights and
  comparison, Norway's label (2022) and the UK's rule on beauty filters (2021), kind self-talk and strengths.
- **Drugs, risks and the law** (`drugs_and_the_law`): see Safety.
- **Resolving conflicts** (`resolve_conflict`): escalate and de-escalate, five steps (calm down, I-statements, listen
  and say back, solutions and win-wins, agree and check), compromise, mediators, online conflict, when an adult must
  help (bullying, threats).
- **Where to get help** (`where_to_get_help`): trusted adults on a hand, how to ask, confidentiality and its limit,
  999 and 112, NHS 111, 101, a GP and a pharmacist, Childline 0800 1111, 116 111 in many European countries, the CEOP
  button, "learn yours with a grown-up".

### Design and technology (England KS3 D&T, Finland's crafts and home economics)
- **Product analysis** (`product_analysis`): ACCESS FM, a torch's exploded view (to label), each material and why (ABS,
  acrylic, steel, brass), injection moulding, pressing, vacuum forming and casting, screws and repair, one-off, batch and
  mass production, a mould's cost shared over 1,000 or 10,000 parts.
- **From screen to object** (`cad_cam`): CAD in 2D and 3D, CAM files, the laser cutter (cut and engrave lines, the
  kerf), the 3D printer (filament, layers, supports; to label), additive and subtractive, safety (never alone, the lid,
  fumes, a 200 °C nozzle), layers = height ÷ layer, a cut's perimeter and time.
- **Electronic circuits** (`electronic_circuits`): UK symbols (drawn: cells, switches, push switches, pads, reed and
  tilt switches, resistors, LEDs either way round, lamps, buzzers, motors, LDRs), volts and milliamps, the LED's long
  leg, the resistor sum (9 − 2) ÷ 0.02 = 350 and the next standard value, the colour code (drawn bands), a simple alarm,
  breadboard then solder with a grown-up.
- **Microcontrollers** (`microcontrollers`): inputs, decisions and outputs, a classroom board (a 5 × 5 LED grid,
  buttons A and B, a speaker, pins; to label), text code (show, pause in milliseconds, clear, forever loops), events and
  a count, x and y on the grid, a night light, and/or, a plant waterer, traffic lights.
- **Technical textiles** (`smart_textiles`): fibres and yarns, technical textiles, the breathable membrane (to label),
  taped seams, fluorescent by day and reflective glass beads at night, thermochromic dyes, e-textiles and conductive
  thread, aramid fibres, a winter cycling jacket.
- **Food of the world** (`world_cooking`): staples by climate, dishes from seven places on the map (paella, dal, jollof
  rice, tacos, sushi, khachapuri, couscous), spices and the Columbian exchange, festivals' food in many traditions,
  vegetarian, vegan, halal and kosher, the UK's 14 allergens, scaling a recipe.
- **Cooking with less waste** (`less_food_waste`): a fifth of food wasted, 79 kg a person a year at home, methane;
  planning, lists and offers; use by and best before; first in, first out; the fridge 0-5 °C and the freezer −18 °C;
  portions; leftovers within 2 hours and 2 days (rice 1 day), reheated once; leftovers into meals; compost.
- **A product's life** (`product_life_cycle`): the five stages, life cycle assessment (a phone's footprint is in its
  making, a washing machine's in its use), the end of life, the 6 Rs, the circular economy, design for repair and
  planned obsolescence, plastics' codes 1, 2, 4, 5 and 6, the waste hierarchy.
- **Prototype and improve** (`prototype_improve`): kinds of prototype, iteration as a loop, user tests and open
  questions, fair tests and the mean, a table of versions, improvement in percent, the Wright brothers' gliders, wind
  tunnel and 1903 Flyer.

### Projects (IB PYP, Finland's modules, Cambridge Global Perspectives): plan, make, test, present
- **A voyage of exploration** (`voyage`): ports by latitude and longitude on a map, nautical miles (60 to a degree),
  knots and the log line, a day's run, water and food for a crew with a spare fifth, barrels, scurvy, navigating by
  compass, the Pole Star and dead reckoning, a logbook, and the people already living on every coast; builds: the hold
  (area 18, perimeter 18) and 3/4 of it in barrels.
- **An eco-district** (`eco_district`): a district plan, BedZED and Vauban, insulation, double glazing, solar panels,
  heat pumps (an eco-home to label), kWh, 8 W LEDs for 60 W bulbs, 140 litres a person a day, rain (1 mm on 1 m² is 1
  litre), green roofs, walking, cycling and trees, carbon at about 0.2 kg a kWh, before and after; builds: the park (area
  24, perimeter 22) and 3/5 of a green roof.
- **A mini business** (`mini_business`): market research, a prototype, fixed and variable costs, markup, break-even on
  a chart, a logo (the other half built as a mirror), an honest poster, a spreadsheet's takings and profit, discounts,
  a social enterprise.

## Life links (owner #112, #117: the School and Life work together)
Each unit below keeps its lesson and practice, and its last card sends the child to LIFE (the School's last tab) by
name; the test checks each name against the Experiences' data and the Tool Book's tools (read only: Life's files were
not touched).

| Unit | Last card points to |
|---|---|
| teen_sleep | Calm Corner's slow balloon breaths to wind down |
| health_influences, drugs_and_the_law | Calm Corner's stories: saying no to pressure |
| self_image | Calm Corner: name a feeling, calm it |
| resolve_conflict | Calm Corner's stories: a quarrel to solve fairly |
| where_to_get_help | Little Lifesaver (calling for help) and Calm Corner (talking about worries) |
| product_analysis | the Tool Book's screwdriver |
| cad_cam, prototype_improve, eco_district | Real Builder (course by course; the spirit level; a small house) |
| electronic_circuits | Fire Escape's smoke alarm, and the Tool Book's smoke alarm (test it every month) |
| microcontrollers | Safe Streets' button crossing (input, controller, the green man) |
| smart_textiles | Safe Streets: being seen at night |
| world_cooking, less_food_waste | The Kitchen (its recipes; its Big track's week of meals on a budget) |
| product_life_cycle | the Tool Book's screwdriver and Allen key |
| voyage | the Tool Book's compass |
| mini_business | My Money Stall |

## Safety (research §5.4)
- **Rule 5, drugs:** only in "Drugs, risks and the law", factual: what a drug is (medicines; caffeine, nicotine and
  alcohol legal for adults and still risky), illegal drugs' unknown contents and strength, mixing, the risks to body,
  mind and future, gas, glue and aerosols stopping the heart, the UK's Misuse of Drugs Act 1971 (classes A, B and C by
  harm; possession; supply even when free; "other countries have their own laws"), the norm (most young people never
  take them), saying no, and help (trusted adults, the GP or school nurse, FRANK 0300 123 6600, Childline 0800 1111,
  999 and the recovery position). **No street drug is named**, nothing shows or invites use, and no people are drawn
  there (a table and a hand). The test keeps every drug, alcohol, tobacco, solvent and gambling word out of the other 22
  units and their generators (the self-image unit's Next line says "harmful substances, risks and the law").
- **Rule 4:** no weight words (a ship's "junk" became a treasure ship and a magnet "weight" a foot, for the word list),
  no diets or calories, no good or bad foods; bodies in self-image as "what your body can do"; the edited portrait is a
  smiling face (light, filter, skin, eyes, teeth, background), not a body; nothing about puberty or reproduction.
- **Rule 7:** no brands (hook-and-loop, aramid fibres, elastane, a classroom microcontroller board); people of the past
  only (Martha Graham, the Wright brothers); no living people.
- **Money** is gold; no personal questions (the help unit asks the child to name trusted adults to themselves, never
  to type them).

## New code
- **`SchoolPictureG7Life`** (`ui/school/school_picture_g7life.gd`, hooked into `SchoolPicture.problem` and `_draw`
  after `SchoolPictureG7Hum`), 14 kinds (its header lists every field): `hr_zones` (`zone_of`, `zone_bpm`, a session's
  trace and a marked point), `shot_paths` (badminton and tennis flights, names or letters, stacked where they land
  close), `sleep_dial` (a 24-hour dial: `sleep_hours`, `minutes_of`, `hours_text`, a phone at screens-off), `photo_edit`,
  `advert` (tricks, labels by `TRICK_NAMES`), `influence_map`, `ref_signal`, `schematic` (UK symbols, current clockwise,
  `conducts`), `resistor` (`resistor_ohms`), `micro_board` (`led_at`), `exploded` (a torch), `cam_process` (a laser
  cutter or a 3D printer), `fabric_section` (breathable, reflective, smart), `eco_home`; `part_at` for label pins on the
  six diagram kinds. Tests: `tests/integration/test_school_picture_g7life.gd` (47 samples at five sizes, every kind,
  variant and symbol, broken data, the rules, every part's place).
- **`G7LifeGen`** (`core/school/gen/g7_life_gen.gd`, SchoolGen source **`g7w`**, the last SOURCES line): 49
  generators (tactics, overloads, serving courts and the end of a badminton game, tennis calls, shots, maximum heart
  rates and zones, a week's minutes, dance counts and styles, referees' calls, tournaments, sleep hours and habits,
  adverts' tricks, influences, edited photos, kind thoughts, drug facts and help, I-statements, conflict moves, help
  services; a torch's materials, production scales and a mould's cost, print layers and laser cuts, additive or
  subtractive and the kerf, resistor codes, LED resistors and E12, circuits that work, board LEDs, pauses and counts,
  sensor decisions, fabrics, fibres, recipes, dishes and staples, waste shares, storage and first in, first out, life
  stages, the 6 Rs and plastic codes, test means, fair tests; sea miles, supplies, energy and carbon, water and rain,
  markups and discounts, profit, loss and break-even). Test: `tests/unit/test_g7_life_gen.gd` (every generator valid at
  every level for 120 seeds with a hint, a worked answer, `data` and a valid picture; every answer, 17,640 of them,
  worked out again with the test's own rules and facts).
- **The content test** `tests/unit/test_school_content_g7_life.gd` (written first; it failed with the picture class
  missing, then with every unit unwritten): the bar (4-8 cards, 12+ exercises at three levels, two kinds, rounds that
  fill, vary and never repeat), the files, hints and worked answers, memory and the world, no prompt twice, the `g7w`
  generators each used, the facts each lesson teaches, kind health words, drugs only in their unit with no street names,
  gold and nothing personal, the pictures each unit needs, every label's line on its part (`part_at`), the Life links
  (titles from the Experiences' data, tools from the Tool Book), the dance heard and a build in every project, and the
  pictures' rules worked out again (a resistor's ohms, a pulse's zone, hours of sleep).
- `tests/unit/test_school_quality.gd` and `tools/school_audit.py` hold grade 7's health and PE, D&T and projects to the
  quality bar now (`GRADE7_SUBJECTS`); `NOT_YET` stays empty.

## Tests
- The new content, generator and picture tests (19 + 10), and the shared `test_school_content.gd`,
  `test_school_quality.gd`, `test_school_curriculum.gd` and `test_school_picture_kinds_unique.gd` (33) pass;
  `tools/school_check.gd` finds no problem in the 23 units; `python3 tools/school_audit.py --check` finds none.
- **Looked at** (a window was available): every picture sample in contact sheets at the card and label sizes, and the
  School's own screens (`tools/school_shots.gd --exercises`) for "From screen to object" and "What influences your
  choices" (every card, every exercise before and after its worked answer). Fixed from what they showed: the referee's figure filled the card and his raised
  arm ran through his head; circuit symbols were tiny and their paper patch spilled out of the card; shot names landed
  on each other (now stacked); the player's racket now meets the first shot; the badminton net has a mesh; the sleep
  dial's phone sat on a time (now inside the rim, with a "phone off" line); tennis tags overlapped; two label pins
  covered the advert's "Everyone's got one!" and "#ad" (the stickers now keep clear of the pins' strips, and each line
  ends on the sticker's edge facing its pin, `TRICK_EDGE`).
- **The full suite:** see the last section.

## Facts checked
Checked on the web on 2026-10-17 (the least often taught): Norway's label on adverts where body shape, size or skin is
retouched, from 1 July 2022 (Forbrukertilsynet, "Guideline on labelling retouched advertising"); the ASA's 2021 rulings
that beauty filters must not exaggerate a product (RPC, Osborne Clarke on the Skinny Tan and Tanologist rulings); 116
111, the harmonised European child helpline number, reserved 2007, in most EU states (Child Helpline International);
the UNEP Food Waste Index Report 2024 (1.05 billion tonnes, almost a fifth of food, 60% in homes, 28% food service, 12%
retail, 79 kg a person at home). From the record (standard references): WHO 2020 activity guidelines for 5-17-year-olds
(60 minutes a day on average; vigorous and muscle- and bone-strengthening on at least 3 days); the American Academy of
Sleep Medicine's 9-12 and 8-10 hours; BWF Laws (21, 2 clear, 30; service courts by even and odd scores); ITTF (11, the
serve every 2 points); tennis scoring; IFAB Law 5 signals and advantage; the Misuse of Drugs Act 1971 (classes; supply
includes giving); FRANK 0300 123 6600, Childline 0800 1111, NHS 111, police 101, CEOP; the UK's 14 allergens (FIR);
the FSA (fridge 0-5 °C, freezer −18 °C, leftovers cooled and chilled within 2 hours, eaten within 2 days, rice within 1,
reheated once); WRAP's 75 g of rice a person; aluminium recycling saving about 95%; resin codes; E12 values and the
resistor colour code; a red LED's 2 V and 20 mA; PLA printing at about 200 °C; the Wright brothers (gliders 1900-1902,
the 1901 wind tunnel's ~200 wings, the 1903 Flyer); a nautical mile of 1,852 m and 60 to a degree of latitude; the log
line and sand glass; Lisbon 38.7°N 9.1°W, Las Palmas 28.1°N 15.4°W, Praia 14.9°N 23.5°W, Plymouth 50.4°N, Recife 8°S;
BedZED (2002) and Vauban (Freiburg); the Energy Saving Trust's quarter of heat through an uninsulated roof and LEDs for
60 W bulbs; the UK grid's about 0.2 kg CO2e a kWh (DESNZ 2024: 0.207); a heat pump's about 3 units of heat for each of
electricity; Martha Graham (1894-1991).

## Rulings (decided here; cost if wrong)
1. **The source is `g7w`** (`g7_life_gen.gd`, `G7LifeGen`), like g4w, g5w and g6w. *Cost:* a rename.
2. **Heart-rate zones use 220 − age**, called an estimate, with the talk test kept (grade 6's ruling 5 left the formula
   to a later grade); zones as GCSE PE teaches them (aerobic 60-80%, anaerobic 80-90%), plus warm-up 50-60% and maximum
   90-100%. *Cost:* the zones' table.
3. **No street drug is named**; the law's classes are taught by harm and penalty. *Cost:* a card if the owner wants
   names (KS3 teaches some).
4. **Caffeine is named outside the drugs unit** (sleep and adverts for energy drinks), as grade 5's sleep unit does; the
   drugs unit calls it a drug. *Cost:* none.
5. **UK law and services, framed as the UK's**, with 112 and 116 111 for elsewhere and "learn yours with a grown-up";
   FRANK only in the drugs unit. *Cost:* lines per country.
6. **Football's signals stand for officiating** (one sport's laws, drawn plainly). *Cost:* other sports' signals.
7. **The microcontroller is "a classroom board"** with made-up but plain functions (show, pause, clear, plot,
   light_level, temperature, moisture), no brand. *Cost:* none.
8. **The torch is the product analysed** (one exploded view); more products later. *Cost:* a picture per product.
9. **Life links name only Experiences that exist now** (Life L3a's Water Safety and Earth and Weather were not merged);
   the voyage names the Tool Book's compass. *Cost:* a line each when new ones land.
10. **Food rules are named respectfully as culture** (vegetarian, vegan, halal, kosher; festivals of many traditions).
    *Cost:* none.
11. **The edited photo is a face, not a body**, and Norway's rule is quoted with its own words (shape, size, skin).
    *Cost:* none.
12. **Sleep debt is taught, not "catching up"**: weekend lie-ins shift the body clock. *Cost:* none.
13. **"practice" stays as the British noun** (football practice); "practise" is the verb. *Cost:* none.

## For the lead (merging)
- Conflicts to expect: `core/school/school_gen.gd` (a SOURCES line after `g7h`), `ui/school/school_picture.gd` (a header
  paragraph and two hooks after `SchoolPictureG7Hum`), `data/school/grade7.json` (23 `file` lines),
  `tests/unit/test_school_quality.gd` and `tools/school_audit.py` (`GRADE7_SUBJECTS`), `docs/DEVELOPMENT.md` (a bullet at
  the end of the School section), the spec's §22.4g.
- **Life's map** (`data/life/life.json`, not touched here): these School units could join its areas as `school: true`
  units: teen_sleep and fitness_plan (body), self_image (feelings), resolve_conflict (people), where_to_get_help and
  drugs_and_the_law (safe), health_influences (thinking), world_cooking and less_food_waste (home), mini_business
  (money), eco_district and product_life_cycle (world).
- After merging: `python3 tools/school_outline.py --write docs/superpowers/plans/2026-09-28-school.md` (not run here).
- Grade 7 now has all twelve subjects. Next for grade 7: the research's remaining maths, science and English units
  (maths 15 of 18, science 12 of 17, English 12 of 18 are written).

## The full suite (2026-10-17, `tests/run_tests.sh`, on df78baa5 with the advert fix being made during the run)
1,203 scripts, 11,069 tests: 11,065 passing, 1 failing, 3 risky, in 4,404 s (the PC's load reached 22 with other
agents' suites). The failure was this branch's own `test_every_label_points_at_its_part`, which ran while the advert's
anchors were being moved (the picture and the unit's pins were one edit apart); after the edit, the School's tests
were run again on the final commit: see below. The risky three are not this branch's: `test_the_column_cache_changes_nothing`
and `test_chunks_meet_without_seams` (the meadows generator, noted by earlier agents) and `test_device_move_nakama.gd`
(no Nakama server here). No SCRIPT ERROR or parse error.
- **After the fix, on the final commit:** `test_school_content_g7_life.gd`, `test_school_picture_g7life.gd`,
  `test_g7_life_gen.gd`, `test_school_quality.gd`, `test_school_content.gd` and `test_school_picture_kinds_unique.gd`:
  6 scripts, 51 tests, all passing (607 s).
