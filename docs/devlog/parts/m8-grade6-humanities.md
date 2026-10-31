# Grade 6 history, geography and citizenship: every unit written (owner #70, #73; 2026-09-29)

The owner: "start from grade 3 and finish all grades accordingly" and "research school programs, world leading schools and
create better school program". The research (`docs/design/school-curriculum-research.md` §6.6) lists grade 6's History
(10: the medieval world), Geography (10) and Citizenship (11) units; this agent wrote all 31, following the reusable
brief (`docs/superpowers/plans/2026-09-29-school-subjects-brief.md`, GRADE = 6, SUBJECTS = history, geography,
citizenship) and building on grades 3, 4 and 5 (`m8-grade5-humanities.md` above all). Branch
`worktree-agent-aaa02874aafc9fba2`, from `lead-merge` at 1a2ff5ba.

## What was written
| Subject | Units | Lesson cards | Hand-written exercises | Generators used |
|---|---|---|---|---|
| History | 10 | 80 | 150 | `g6h.century` (after Rome), `g6h.medieval_order` (Anglo-Saxons and Vikings; Tang and Song), `g6h.al_jabr` (Baghdad), `g6h.three_fields` (castles and villages), `g6h.medieval_years` (Magna Carta), `g6h.caravan` (African kingdoms), `g6h.quipu_number` (Aztecs and Incas), `g6h.harvest_workers` (the Black Death) |
| Geography | 10 | 80 | 150 | `g6h.density`, `g6h.population_change`, `g6h.city_growth`, `g6h.sector_sort`, `g6h.grid_ref` + `g6h.contours` + `g6h.map_scale` (detailed maps), `g6h.climate_read` (climate graphs; Asia's monsoon), `g6h.river_sort`, `g6h.africa_places`, `g6h.asia_places`, `g6h.layer_query` |
| Citizenship | 11 | 88 | 165 | `g6h.branch_sort`, `g6h.seat_count`, `g6h.argue_well`, `g6h.take_home_pay`, `g6h.compound_growth`, `g6h.insurance_pool`, `g6h.scam_signs`, `g6h.footprint` |
| **All** | **31** | **248** | **465** | 28 generators in 27 units, each at levels 1-3 (medieval Japan, police and courts, human rights, and identity have hand-written practice only) |

- **Files:** `data/school/g6/<subject>/<unit>.json`, linked from `data/school/grade6.json` (only these 31 units' `file`
  fields changed; titles and goals kept).
- **Every unit:** 8 cards that open with "Quick memory:" and a question from grade 3, 4 or 5 **naming that grade** (the
  spiral; the test enforces it), one idea a card with a worked example, and a last card "Try it in the world: … Next: …";
  15 hand-written exercises, 5 at each level (no round repeats one), of 3-5 kinds: choice (239), true or false (77),
  number (76), sort (30), match (28), order (15). Every exercise has a hint (a strategy) and an explain (the worked
  answer); no unit asks the same question twice.
- **History, the medieval world:** after Rome (Constantinople 330, the split 395, the west's end 476, Justinian's code
  534 and Hagia Sophia 537, the land walls, 1453, counting in centuries); Anglo-Saxons and Vikings (settlers from across
  the North Sea, kingdoms, Old English and place names, Sutton Hoo about 625 found 1939, Lindisfarne 793, the Danelaw
  and Norse words, Alfred 871 and Edington 878, burhs, Athelstan 927); Baghdad and the House of Wisdom (762, scholars of
  three faiths translating into Arabic, paper by 794, al-Khwarizmi's al-jabr about 820 with worked puzzles, algorithm,
  the digits' journey, al-Razi, astrolabes, 1258); castles and medieval life (1066, motte and bailey, stone keeps, the
  White Tower about 1078, concentric castles, the feudal pyramid, Domesday 1086, three fields, towns and guilds); Magna
  Carta (John 1199, Runnymede 15 June 1215, clauses 39 and 40, who it helped, cancelled and reissued 1216, 1217, 1225;
  parliaments, de Montfort 1265, 1295, Lords and Commons); Tang and Song inventions (618-907 and 960-1279, woodblocks and
  the Diamond Sutra 868, Bi Sheng's type about 1040, paper money 1024, Shen Kuo's compass 1088, gunpowder first for
  fireworks); great African kingdoms (gold and salt, Ghana, Sundiata about 1235, Timbuktu, Mansa Musa 1324, Benin's
  brass, 1897, Great Zimbabwe about 1100-1450); medieval Japan (Heian-kyo 794, Genji about 1010, samurai, shoguns from
  1192, the Mongol fleets 1274 and 1281, calligraphy and rock gardens); the Aztecs and Incas (Tenochtitlan about 1325,
  chinampas, cacao money, Nahuatl words, Pachacuti 1438, Machu Picchu about 1450, 40,000 km of roads, chasquis, quipus,
  the fall in the 1520s-1530s); the Black Death and change (1347 and 1348, bacteria and fleas, a third to a half of
  Europe, fewer workers and higher pay, the Statute of Labourers 1351, the Peasants' Revolt 1381, the end of serfdom).
- **Geography:** where people live (density, Bangladesh and Mongolia, physical and human reasons, the Nile, sparse
  places); people on the move (push and pull, refugees, barriers, natural change and migration, effects); cities
  (urbanisation since about 2007, megacities, the zones, land use, regeneration, sprawl and green belts, planning); jobs
  and industry (four sectors, a loaf's journey, economies changing, 4 in 5 UK jobs services); detailed maps (1 km
  grid, four- and six-figure references, contours and spot heights, 1:25,000 and 1:50,000, symbols); climate graphs
  (weather and climate, reading bars and line, range and total, London, Mumbai's monsoon, why climates differ, the North
  Atlantic Drift); river processes (long profile, erosion's four ways, transport, deposition, waterfalls and gorges,
  meanders, ox-bow lakes, levees, floods); Africa (Equator and both tropics, the Sahara, the Nile, the Congo, savannas,
  the Rift Valley, Kilimanjaro, people and languages, East Africa); Asia (size and people, the Himalayas and Everest, great
  rivers, the monsoon, megacities, China and India); maps with layers (GIS layers, points, lines and areas, data sources,
  planning, location privacy).
- **Citizenship:** how a country is run (three powers, Montesquieu 1748, parliamentary and presidential systems,
  constitutional monarchies, constitutions); elections (ballots, the secret vote since 1856/1872, voting ages, first past
  the post and proportional representation, turnout, majorities); police and courts (police, criminal and civil law,
  prosecution and defence, judge and jury, innocent until proven guilty, sentences, restorative justice); human rights
  (the UDHR, 10 December 1948, 30 articles, universal, rights and responsibilities, balancing, ECHR 1950); identity and
  belonging (many parts, changing, groups, peer pressure, online selves; no personal questions); disagreeing well (the
  idea not the person, saying back, four ways arguments go wrong, changing your mind, compromise, a community of
  enquiry); income and taxes (wages and salaries, gross and net, a worked tax, bands, public services, who decides);
  saving and compound interest (a worked 3 years, simple compared, the rule of 72, debts compound too, goals); risk and
  protection (avoid, reduce, share, accept; an emergency fund; insurance as a shared pot; claims and excess); spot a scam
  (warning signs, game scams, stop-think-check, tell a grown-up, REPORT and BLOCK, passwords); sustainable choices
  (footprints, swaps, buy less and repair, measure again as a percentage).

## Generators (`core/school/gen/g6_humanities_gen.gd`, `G6HumanitiesGen`, SchoolGen source "g6h", the last SOURCES line)
Seeded, levels 1-3, each with a hint, a worked answer and `data`:
- History: `century` (1001-1599 chosen from four; 401-1999 typed; BC centuries, or which year fits a century; years
  ending in 00 left out), `three_fields` (what a field grows next year or in year n; strips growing food; years
  resting), `medieval_years` (years apart; BC to AD with no year 0; anniversaries, `"year": true`), `medieval_order`
  (3, 4 or 5 of 27 dated events), `al_jabr` ("a thing and a make b"; k things; k things and a equal m things and b),
  `caravan` (slabs; days across the desert; salt shared among towns), `quipu_number` (one cord 1-99 or 100-999 with an
  empty place; three named cords' total or difference, on the quipu picture), `harvest_workers` (fewer workers, more
  days; a village with a fraction of its people; a reaper's week after a rise).
- Geography: `density` (dots on squares; an island; which of two is more crowded, or people from density × area),
  `population_change` (moving; births, deaths and moving; the year's end, which can fall), `city_growth` (more people;
  times bigger; a percentage urban), `sector_sort` (jobs into three sectors; with quaternary; one job's sector),
  `grid_ref` (a 4 × 2 map: a symbol's square; a point's six figures; what or which point is at a reference),
  `contours` (the steep side; a line's height; a climb), `map_scale` (1:25,000 and 1:50,000 cm to km; km to cm; a walk's
  minutes), `climate_read` (a made-up place from five climates, some in the southern hemisphere: the wettest or warmest
  month; the range or the wettest rain on grid lines; the climate or the hemisphere), `river_sort` (upper or lower
  course; erosion or deposition; a process from what it does), `africa_places` and `asia_places` (N or S; the furthest
  of 3-4 places whose names keep clear on the grid; degrees of latitude apart), `layer_query` (houses; houses in the
  flood zone; buildings outside it, or which layers to switch on).
- Citizenship (gold): `branch_sort` (jobs into making, carrying out and judging laws; which part acts in a case),
  `seat_count` (an area's winner; seats of five areas; a majority), `argue_well` (helps or gets in the way; name the
  mistake), `take_home_pay` (gross − tax; a tax-free part and a rate; two bands), `compound_growth` (a first year; two
  years at 10%, 5% or 20%; three years at 10%, or compound − simple), `insurance_pool` (a year's premium; a shared pot
  after claims; years plus an excess), `scam_signs` (warning signs or safe habits; what to do about a message),
  `footprint` (a week's table: total; points saved by a swap; the fall as a whole percentage).

## Pictures (`ui/school/school_picture_g6hum.gd`, `SchoolPictureG6Hum`, 11 kinds, hooked in `SchoolPicture` after `SchoolPictureG5Arts`)
`event_timeline` (years under the line, BC/AD where it crosses AD 1, shaded eras, labels placed in the lowest free row),
`quipu` (main cord, pendant cords, places from thousands down, single knots in columns of up to 5, long knots,
figure-of-eight; `quipu_digits`, `knot_kind`), `feudal_pyramid` (land down, service and loyalty up), `castle_type`
(motte and bailey and stone keep from the side, concentric from above, labels spread so they never overlap),
`dot_density` (km² squares with a dot a person), `city_zones` (the four rings), `os_map` (blue lines 1 km apart with
their numbers, tenth ticks, contour rings bunched on a steep side with their heights, spot heights, a river, eight
symbols, lettered points, a 1 km bar; `six_figure`, `four_figure`), `climograph` (rain bars on the right scale, the
temperature line on the left, the same number of steps, 0 °C marked), `river_course` (long profile with each course's
valley; plan with source, tributary, confluence, meanders, ox-bow and mouth; a meander's cliff and slip-off slope; a
waterfall's hard and soft rock, overhang, plunge pool and gorge), `layer_map` (overlay with a key, or stacked sheets),
`savings_growth` (saved and interest parts; simple interest beside; `compound`, `simple`).
- **Looked at in a real window:** every sample at three sizes, all 47 lesson and exercise pictures of the 31 units, 75
  generated pictures, and `school_shots.gd` for `g6.geography.detailed_maps` and `g6.history.aztec_inca` (with
  exercises). The looks found and fixed: timeline labels overlapping (now placed row by row), castle labels overlapping
  (spread), hidden bailey huts (their roofs now show over the palisade), a quipu's 9 knots too small to count (columns
  of 5), map symbols too small, 5 × 4 maps too small to read tenths on an exercise's card (4 × 2 squares, tenth ticks),
  Tokyo's name written leftwards over Beijing (places now chosen so names keep clear), a stack of layers using half its
  card, footprint tables' long names.

## Rulings (decide and write down; cost if wrong)
1. **Every lesson opens with "Quick memory:" naming grade 3, 4 or 5, and ends "Try it in the world: … Next: …"** (the
   test enforces both). *Cost:* none.
2. **Dates as historians give them:** "about" for 410, 625, 820, 1000, 1040, 1078, 1100-1450, 1235, 1325, 1450;
   traditions called so; exact dates exact (1066, 1215, 1348, 1381, 1453). The generator's `EVENTS` holds the same.
   *Cost:* none.
3. **Hard history is named, never shown** (research §5.4 rule 3); the test bans gruesome words (blood, torture,
   massacre, sacrifice, execution…). **For grown-ups to preview** (no code list of preview units exists yet; the research
   lists only grade 7-8 units): the Viking raid on Lindisfarne (793); the Battle of Hastings and the Norman Conquest;
   Baghdad taken in 1258; the Mongol fleets (1274, 1281); Constantinople taken (1453); British soldiers taking Benin's
   bronzes (1897); the Spanish conquest of the Aztec and Inca empires with new diseases (1520s-1530s, "grade 7 tells
   more"); the Black Death (a third to a half of Europe's people died; no symptoms described); the Peasants' Revolt;
   refugees fleeing war; the Second World War named as the reason for the UDHR; "no one may be enslaved" (article 4).
   *Cost:* a line on the grown-ups' page if the owner wants a preview list for grade 6 too.
4. **Left out at grade 6:** Aztec human sacrifice (their religion is "temples to their gods of the sun and the rain")
   and the blaming and attacking of Jewish communities during the Black Death. *Cost:* an incomplete picture; grade 7's
   encounters unit and grade 8's prejudice and remembrance units are the place for them.
5. **Religion as culture and belief** (rule 1): a Buddhist text, Zen temples, mosques and schools in Timbuktu, the
   direction of Mecca for prayer, Mansa Musa's journey, scholars of three faiths in Baghdad, faith groups, "God's anger"
   as a medieval belief. *Cost:* none.
6. **Politics in general terms** (rule 2): systems named for countries as plain facts (UK, India, Japan; USA, Brazil;
   UK, Japan, Spain, Norway, Sweden as constitutional monarchies); absolute monarchies not named; no parties (the test
   bans real ones; elections use made-up Oak, River and Sun parties); for counting systems and taxes, "people argue about
   which is fairer"; no living people. *Cost:* none.
7. **No borders:** the world grid shows places as dots (grade 5's ruling 4: no coastlines); only undisputed capitals;
   Tibet, Kashmir and Taiwan are not mentioned (the Tibetan Plateau is named as a landform). *Cost:* a continent outline
   later.
8. **Money is gold everywhere**, medieval wages and taxes too; tax rules are made up and simple (no real allowances).
   *Cost:* none.
9. **Footprint points** are the game's own measure (car trip 4, bus 2, beef burger 6, bean burger 1, new T-shirt 5,
   used 1, bath 3, shower 1), not kg of CO₂. *Cost:* real figures in grade 7-8 if wanted.
10. **Megacities are listed, not ranked**: the UN's 2025 figures moved Jakarta and Dhaka above Tokyo, so no "largest
    city" is claimed. *Cost:* none.
11. **The quipu follows the usual reading** (single knots for tens and above, long knots of 2-9 turns and a
    figure-of-eight for 1 in the ones); clusters of 6-9 are drawn in two columns so they can be counted. Real quipus
    also have knot directions, colours with meanings and subsidiary cords, not taught. *Cost:* one kind's drawing.
12. **The detailed map is our own drawing**, not an Ordnance Survey map: 8 simplified symbols (place of worship with a
    tower, Sch, Fm, P, campsite, viewpoint, castle, bridge) and tenth ticks that real maps do not have. Six-figure
    references are chosen, never typed (the pad would group 324617 as 324,617). *Cost:* none.
13. **Climate graphs:** London's and Mumbai's months are rounded typical values; the generator draws made-up places from
    five climates, asks a range only where it can be read, and puts the asked value on a grid line. *Cost:* none.
14. **"year": true** on every number whose answer is a year (1066; 2015; the generator's anniversaries); the test checks
    every "what/which year" number, hand-written and generated. Centuries leave out years ending in 00. *Cost:* none.
15. **Identity without personal questions:** every exercise is about Zara, Bram, Mimi or a new pupil; online safety
    in four units (identity, GIS location, scams, passwords). *Cost:* none.
16. **The unit files are the source of truth**; the Python that wrote them (limits, letters, kind, British, currency,
    gruesome and party words, sums and year checks) stayed in the agent's scratchpad.

## Facts checked (with sources)
- The Diamond Sutra, 11 May 868, the earliest dated printed book (British Library; cabinet.ox.ac.uk).
- Shen Kuo's Dream Pool Essays, 1088, the first description of the magnetic needle compass (Wikipedia, AAAS).
- Bi Sheng's clay movable type about 1040; the first official paper money (jiaozi) 1024 (Wikipedia).
- Mansa Musa in Cairo 1324; al-Umari: gold's value fell there for about twelve years (World History Commons).
- Great Zimbabwe 11th-15th century; Great Enclosure walls up to 11 m, no mortar (Met Museum, Wikipedia).
- Benin: the 1897 British expedition took 3,000-5,000 objects, including about 900 brass plaques (British Museum, NMS).
- Tenochtitlan about 1325 on Lake Texcoco, about 200,000 people, causeways, chinampas (National Geographic).
- The Inca road system about 40,000 km; quipus of knotted cords (UNESCO, Wikipedia); Machu Picchu about 1450.
- Black Death: England 1348 via Melcombe; a third or more of Europe; the Statute of Labourers 1351 (Wikipedia).
- Magna Carta: four surviving 1215 copies; annulled by Innocent III on 24 August 1215; reissued 1216, 1217, 1225 (BL).
- Simon de Montfort's parliament, 20 January 1265, the first with townspeople; the Model Parliament 1295 (UK Parliament).
- Baghdad founded 762; a paper mill by 794; al-Khwarizmi's al-jabr about 820 (Wikipedia, History Hit).
- The Tale of Genji about 1010; Yoritomo shogun 1192; Mongol invasions 1274 and 1281, storms (Wikipedia, Asia Society).
- The UDHR: 10 December 1948, Paris, 30 articles; 48 for, none against, 8 abstained, 2 did not vote (UN).
- The secret ballot: Victoria 1856; Britain's Ballot Act 1872 (National Museum of Australia, Britannica).
- Africa alone crossed by the Equator and both tropics; Kilimanjaro 5,895 m; the Sahara about 9.2 million km²; the
  Congo about 220 m deep (Wikipedia, World Atlas).
- OS 1:25,000: 4 cm to 1 km; contours usually 5 m, 10 m in mountains (OS Maps guide).
- More than half the world's people urban since 2007; the UN's 2025 megacity ranking (UN DESA).
- The Peasants' Revolt: the 1380 poll tax, Wat Tyler, Richard II aged 14 (Britannica).
- Sutton Hoo about 625, found 1939, a 27 m ship; Athelstan king of all England 927; Alfred's burhs (British Museum).
- Justinian's code 529-534; Hagia Sophia finished 537, the largest dome until Florence's (1436); the Theodosian walls
  (World History Encyclopedia).
- Everest 8,848.86 m (2020); the Yangtze about 6,300 km (Wikipedia). Montesquieu, The Spirit of the Laws, 1748.
- Nahuatl gave tomato, avocado, chocolate and chilli (Merriam-Webster). UK services about 81% of jobs (Statista/ONS).
- Sundiata and the battle of Kirina about 1235; Timbuktu's Sankore and its manuscripts; Ghana's gold and salt trade.

## Tests
- `tests/unit/test_school_content_g6_humanities.gd` (written first; it failed with "g6.history.after_rome is written" and
  the other 30): the outline's 10 + 10 + 11 units; every unit written with no problems, 3+ cards, 12+ exercises at levels
  1-3 of 2+ kinds, rounds that fill and vary and never repeat a hand-written one; hints are strategies; memory first with
  the grade named, the world last with what comes next; no question twice; only g6h generators and every g6h generator
  used; each unit's pictures; a year is a year; gold only; no gruesome words or parties: 10/10 (465 exercises).
- `tests/unit/test_g6_humanities_gen.gd` (written before the source was registered; it failed with "g6h.… makes an
  exercise"): 27 tests, 80 seeds × 3 levels, each answer worked out again from `data` with the test's own facts (events,
  fields, sectors, symbols, rivers' groups and processes, places, branches, mistakes, scam signs, points), the maps'
  places on their pictures, the climate graphs' values on grid lines, places' names clear of each other: 27/27.
- `tests/integration/test_school_picture_g6hum.gd`: 36 samples valid and drawn at four sizes, 56 broken pictures, the
  quipu's knots, grid references, compound and simple interest, timeline years: 8/8.
- The shared `tests/unit/test_school_content.gd` passes with the 31 new units (7,800 hand-written exercises in all
  written units); `test_school_picture_kinds_unique.gd` finds the new file's 11 kinds and no clash.

## For the lead when merging
- `data/school/grade6.json`: only the 31 humanities units gain a `file` line (other grade 6 agents touch other units).
- `core/school/school_gen.gd`: one SOURCES line `"g6h"`, the last. `ui/school/school_picture.gd`: a header paragraph and
  two hooks (`problem`, `draw`) after `SchoolPictureG5Arts`'s. Run `godot --headless --path . --import` after the merge
  (new classes `G6HumanitiesGen`, `SchoolPictureG6Hum`).
- Kind names checked unique against every `school_picture*.gd` on `lead-merge` at 1a2ff5ba; if another agent's new file
  uses `event_timeline`, `quipu`, `feudal_pyramid`, `castle_type`, `dot_density`, `city_zones`, `os_map`, `climograph`,
  `river_course`, `layer_map` or `savings_growth`, `test_school_picture_kinds_unique.gd` will say so.
- `docs/DEVELOPMENT.md`: one bullet after grade 5's humanities bullet.
- Not done here (to avoid conflicts): `python3 tools/school_outline.py --write docs/superpowers/plans/2026-09-28-school.md`,
  the spec's §22.4 "as built" line, RESUME-HERE, the owner-feedback row, and a grown-ups' preview line for rule 3's list.

## The full suite (2026-09-29, this branch at 939b054b; the later commits change only docs)
`tests/run_tests.sh`: **7,615 tests in 825 scripts: 7,613 passing, 0 failing, 2 risky** (the two world tests that never
assert, as before), no script or parse errors, exit 0.
