# Grade 8 computing, art and design, and music: every unit written (owner #70, #73, #111; 2026-10-17)

The owner (#111, 2026-10-16): "when all remaining tasks are done, you continue adding educational materials, as you know
we want to have full school programs and sylabusse content in the game"; and for the platform (#112, #115, #117): learn
by doing. The research (`docs/design/school-curriculum-research.md` §6.8) lists grade 8's Computing (11), Art and Design
(9) and Music (9) units; this agent wrote all 29, following the reusable brief
(`docs/superpowers/plans/2026-09-29-school-subjects-brief.md`, GRADE = 8, SUBJECTS = computing, art, music), one step up
from grade 7 (`m8-grade7-arts.md`: text code, lists, functions, searching and sorting, the internet, ciphers;
Renaissance art, colour harmony, world art 1450-1750; chord progressions, Baroque, Classical, the bass clef, folk music).
Branch `worktree-agent-school8c`, from `lead-merge` at b585e78b (the first worktree was cleaned away while it was still
empty, so this one was made again from the same commit); `lead-merge` merged in again at 97072ab3 (Life L3a) and at
8ce66716 (the grade 8 humanities).

## What was written
| Subject | Units | Lesson cards | Hand-written exercises | Kinds of exercise | Generators (`g8c`) |
|---|---|---|---|---|---|
| Computing | 11 | 88 | 181 | number 52, choice 51, true/false 34, sort 17, match 12, order 12, robot 2, label 1 | 16 |
| Art and design | 9 | 72 | 145 | choice 44, number 32, true/false 27, sort 17, match 11, order 9, label 4, mix 1 | 12 |
| Music | 9 | 72 | 146 | choice 53, number 28, true/false 26, sort 11, match 10, order 9, rhythm 7, label 2 | 18 |
| **All** | **29** | **232** | **472** | | **46**, each at levels 1-3, every one used |

- **Files:** `data/school/g8/{computing,art,music}/<unit>.json`, linked from `data/school/grade8.json` (only these
  units' `file` fields; ids, titles, goals and standards kept).
- **Every unit:** 8 lesson cards, one idea each, opening with "Quick memory:" and a question whose answer is in brackets
  (from grades 3-7) and ending "Try it in the world: … Next: …"; at least 3 of the 6 teaching cards have a picture;
  16-19 hand-written exercises, at least 5 at each level, of 6-8 kinds, at most 59% choice or true-or-false, each with a
  strategy hint and a worked answer; every unit 100 on `tools/school_audit.py` and under no part of the quality bar.
- **Computing** (`bigger_programs` Build a bigger program; `compare_algorithms` Comparing algorithms;
  `models_abstraction` Models and abstraction; `how_code_runs` How a computer runs code; `data_as_bits` Text, sound and
  pictures as bits; `logic_gates` Logic gates; `databases` Databases; `machine_learning` How machines learn;
  `cyber_security` Cyber security; `design_for_users` Design for users; `computing_society` Computing and society):
  decomposition and structure charts, functions that call functions, unit and integration tests, programs run by the
  tests' interpreter (and by real Python when written); worst cases (linear n, binary ⌊log₂ n⌋ + 1, bubble sort
  n(n − 1) ÷ 2, merge sort's fewer than 9,000 for 1,000 items), the game's robot routes with a command limit; Harry
  Beck's map and a town's real map against its model, state machines (a UK traffic light, a game's menu), a model that
  predicts; the stored program (von Neumann 1945), fetch-decode-execute, the control unit, ALU and registers, the
  School's little machine (LOAD, ADD, SUB, OUT, HALT), compilers and interpreters, clock speed and cores; ASCII and
  Unicode, samples and bits, colour depth and file sizes; AND, OR and NOT, truth tables, circuits of up to three gates,
  Claude Shannon; tables, records, fields, primary keys, SQL queries with AND and OR, data types; training data, a
  nearest-neighbour model and a 3-vote, accuracy, bias through data, what AI can and cannot do, chatbots that are wrong;
  malware (virus, worm, trojan, ransomware, spyware), social engineering, passwords and **this game's own rules** (#105:
  6 letters or more, never the name, never shared; 5 tries in 15 minutes; a new device logs the old one out), HTTPS,
  firewalls, public wireless; usability, accessibility, contrast 4.5 to 1, user tests, Louis Braille; jobs, e-waste
  (62 million tonnes in 2022, under a quarter recycled), watts and kWh, data protection and computer misuse laws, the
  digital divide, Katherine Johnson.
- **Art and design** (`impressionism` Impressionism and light; `modern_movements` Modern art movements;
  `art_and_technology` Art and new technology; `identity_art` Art about identity; `public_art` Public art and murals;
  `designing_objects` Designing objects; `animation` Animation; `installation` Sculpture and installation;
  `exhibition` Your exhibition): Monet's Impression, Sunrise and haystacks, coloured shadows, broken colour, paint tubes,
  Morisot, Pissarro, Seurat's dots; Fauvism, Cubism, Surrealism, Pop Art, Tarsila do Amaral and Amrita Sher-Gil; the
  camera obscura and Ibn al-Haytham, Niépce, Daguerre, Muybridge, film, raster and vector, AI pictures' questions;
  self-portraits (Dürer, Rembrandt, Kahlo), symbols, the face's proportions; murals and monuments (Rivera, the Statue of
  Liberty, Christ the Redeemer), the grid method, paint by area; form and function (Sullivan), the balanced-arm lamp,
  the Bauhaus and Breuer, ergonomics, phones, Sori Yanagi, repair; frames, drawing on twos, timing and spacing, slow in
  and slow out, squash, stop-motion and Lotte Reiniger; carving, modelling, casting, installations (Bourgeois, Christo
  and Jeanne-Claude), Calder's mobiles and weight × distance, maquettes at scale; curating, labels, hanging at 1.5 m,
  equal gaps, a welcoming room.
- **Music** (`romantic_era` Romantic music; `twentieth_century` Music of the 20th century; `jazz_improvise` Jazz and
  improvising; `produce_a_track` Produce a track; `arranging` Arranging; `music_identity` Music and identity;
  `big_forms` Big musical forms; `sight_reading` Sight-reading; `composition_project` Composition project): bigger
  orchestras, programme music, Chopin, Tchaikovsky, Smetana, Fanny Mendelssohn and Clara Schumann, waltz or march, leaps,
  rubato; the whole-tone scale, The Rite of Spring, jazz in New Orleans, all 12 notes, Cage's silence, the theremin,
  recorded sounds, minimalism and loops that meet again (lowest common multiples); the jazz band, swing, the C blues
  scale, call and response, the head and solos, trading fours; layers, arrangement, faders, panning, EQ, reverb and
  echo, the game's LOOP (4 bars at 100 beats a minute: 9.6 seconds), safe listening; ranges, transposing, texture,
  timbre (the School's tones), a string quartet; music for life's moments, styles and places, griots and the kora,
  music that travels, music and feelings, festivals; the symphony, concerto and cadenza, opera (recitative and aria,
  Monteverdi, Mozart, Verdi, Peking opera), ballet and the musical; key and time signatures, clapping first, keeping
  going, steps and leaps; purpose, ABA and rondo, motifs (sequence, inversion, augmentation), chords I, IV and V, drafts
  and feedback.
- **Listening:** every music unit has 6 or more exercises to listen to (64 in all, and 5 lesson cards with a sound): a
  melody's leaps, a nocturne's tempo, waltz or march, major or minor, a four-note chord, an octave higher; the whole-tone
  and major scales, an atonal row, a repeating pattern, loops that drift and meet, a canon; swung and straight quavers,
  a call answered, a walking bass, the blues scale; layers, a bass line, chords drowning a tune, a tempo, the quietest
  part, a bass joining; textures, tones, octaves; a lullaby, a parade, a drone, five notes; fast or slow, recitative or
  aria, soloist and orchestra, a cadenza, a minuet; the tune that matches the notes, the wrong note, F sharp; a
  sequence, an inversion, augmentation, finished or unfinished, ABA. Rhythms to copy: 7.
- **Life and Success links** (owner #112, #115, #117; the last card names the Experience in the LIFE tab):
  cyber security → The Connections Book (its big track: trust and staying safe online); design for users → Success
  Stories (Louis Braille); computing and society → Success Stories (Katherine Johnson); designing objects → the Tool
  Book; installation → Real Builder; exhibition → Talk & Deal (its big track: a pitch); music and identity → Calm
  Corner; composition project → The Goal Board (a goal, its steps and a plan for getting stuck).
- **The game's own tools** in the lessons: the paint bucket's 16 colours for a mural, photo mode for Monet's light, the
  Xylophone, Bongo Drums and LOOP for producing, improvising, arranging and composing, MAKE A SHORT for animation, a lamp
  between two levers as an OR gate (PowerRules: a lamp touching either powered lever lights), and the robot board.

## New code
- **27 picture kinds** in `ui/school/school_picture_g8arts.gd` (`SchoolPictureG8Arts`, hooked after `SchoolPictureG7Life`
  in `SchoolPicture.problem` and `_draw`; its header lists every field): `structure_chart`, `step_growth`
  (`steps_for`), `state_machine`, `abstract_map` (`stops_between`), `cpu_cycle`, `sampled_wave`, `gate_circuit`
  (`circuit_out`, `circuit_letters`), `db_table`, `scatter_learn` (`nearest`), `threat_card`, `app_screen`,
  `light_series`, `brushwork`, `movement_piece`, `camera_obscura`, `raster_vector`, `symbol_portrait`, `grid_enlarge`,
  `object_design`, `flip_frames` (`ball_at`), `mobile_balance` (`turning`), `gallery_plan`, `wall_label`, `jazz_band`,
  `instrument_ranges` (`range_of`, `pitch_of`), `opera_house`, `swing_beats`. `part_at` places label pins on the
  processor, the camera obscura, the four objects, the jazz band, the opera house and the clear app screen (`RATIOS`: a
  fixed shape, so a pin's line is worked out from the label box). Samples, broken data and the shared facts in
  `tests/integration/test_school_picture_g8arts.gd` (12 tests).
- **Generators** `core/school/gen/g8_arts_gen.gd` (`G8ArtsGen`, SchoolGen source `g8c`, the last SOURCES line): 46,
  seeded, levels 1-3, each with a strategy hint, a worked answer and `data`. Computing: `module_trace`, `step_count`,
  `state_next`, `model_keep`, `machine_trace`, `char_code`, `file_size`, `gate_out`, `truth_rows`, `db_query`,
  `nearest_guess`, `accuracy`, `password_space`, `trick_sort`, `user_test`, `device_energy`. Art: `art_order`,
  `tech_order`, `artist_movement`, `pixel_count`, `face_measure`, `grid_scale`, `paint_tins`, `form_function`,
  `frame_count`, `balance_mobile`, `maquette`, `hang_height`. Music: `composer_match`, `music_order`, `whole_tone`,
  `loop_lcm`, `swing_hear`, `blues_scale`, `chorus_count`, `loop_time`, `eq_band`, `transpose`, `range_fit`,
  `texture_hear`, `culture_match`, `form_plan`, `note_read`, `bar_check`, `motif_move`, `chord_fit` (heard ones carry a
  sound). Helpers start with "_" (SchoolGen takes every public static function for a generator).
  `tests/unit/test_g8_arts_gen.gd` (45 tests) works every answer out again: programs by the tests' text-code runner,
  and its own machine, ASCII, sizes, gates, queries, nearest points, percentages, passwords, energy, years, movements,
  proportions, scales, mobiles, frames, ranges, scales by semitones, textures, swing, chords and motifs.
- Shared files touched: `ui/school/school_picture.gd` (two hooks and a header line) and `core/school/school_gen.gd` (the
  `g8c` line); `data/school/grade8.json` (29 `file` lines).

## Tests
- `tests/unit/test_school_content_g8_arts.gd` (written first; it failed for 29 unwritten units; 27 tests): every unit
  written, problem-free, 4-8 cards, ≥ 12 hand-written exercises at levels 1-3 of two kinds or more, rounds that vary and
  never repeat a hand-written exercise, **the quality bar** (`test_school_quality.gd`'s `bar`, whose own scope is
  grades 3-7), hints and worked answers, memory first and "Try it in the world" with Next last, 6 sounds in every music
  unit, the units' own `g8c` generators (every one used), no prompt asking for personal details, the Life links (each a
  real Experience's title through `LifeExperience.data`, or the Tool Book), every label's line on its part; and the
  facts, by this test's own rules: every text program in a picture runs (and prints its output panel), every "What
  does it print?", "This program prints N" and "Which line stops it?", the little machine's outputs and instructions,
  ASCII ("A is 65", "CAT is stored as 67, 65, 84", the code tables and their binary), every circuit's lamp and the AND
  truth table, every query's records, the nearest examples' votes, the journeys' stops, the 42 people's years (and no
  other "Name (born-died)" in the texts), complementary colours, mobiles, the mural's squares, the gallery's path, a
  label's medium, the instruments' ranges, notes read and heard (matches, the wrong note, beats, leaps, the key's sharp
  or flat), scales heard (whole-tone, major, blues, five notes), textures and swing heard, and loops that meet again.
- `tests/unit/test_g8_arts_gen.gd`, `tests/integration/test_school_picture_g8arts.gd`; the shared
  `test_school_content.gd` (every generator valid at every level for 120 seeds, varied, used; kind, British, English
  words; the sums in the lessons), `test_school_picture_kinds_unique.gd`, `test_no_guilt_words.gd`,
  `test_identity_words.gd`, `test_english_only.gd` and `test_school_quality.gd` pass with the new files.
- The units were built by scripts in this agent's scratch folder (the JSON files are now the source) that checked the
  limits, the words (kind, British, no other games, no body-shape words), every plain sum, every program (by real
  Python), the robot's shortest routes (a breadth-first search with RobotCheck's rules), every query, gate, file size,
  mobile and loop, and the audit's own measures (long sentences, pictures on the teaching cards, level 3's demand, near
  duplicates).
- **Looked at:** every picture the units use, in contact sheets at the School's sizes (118 lesson-card pictures at
  560 × 380 and 57 exercise pictures at 580 × 250), every kind's samples at five sizes, and the School's own screens
  (`tools/school_shots.gd`, a window; no editor or emulator) for jazz and improvising and databases (about 140 shots: the
  lesson, every exercise before and after its worked answer, a round). Fixed from what they showed: the step chart's
  axis title over its top number and its ticks on fractions, values at the dashed line on top of each other, a state
  machine's labels piled in the middle (one-way arrows now bend outwards), the processor's title under its boxes, a
  4-bit wave's crowded numbers, the haystacks drawn as arches with streaky dabs and a shadow running out of the panel,
  noisy pointillist dots, a made-up pixel staircase in the zoomed raster, a narrow phone, a mobile's big weight off the
  card, the saxophone in the double bass, a phishing hook that missed its envelope, a 6-frame strip with no frame on
  the ground, and swing on a 12-step grid whose dividers fell every 4 steps (now `swing_beats`).
- **The full suite** (`tests/run_tests.sh`): see the last section.

## Facts checked, with sources
The first three rows were checked on the web on 2026-10-17; the rest are standard reference facts, cited to where they
can be checked.

| Fact | Source |
|---|---|
| Louise Bourgeois's Maman (1999) is about 9.3 m tall ("over 9 m") | Wikipedia "Maman (sculpture)"; Art Gallery of New South Wales; Tate |
| Christo and Jeanne-Claude's The Gates, Central Park, February 2005: 7,503 gates | Whitney Museum collection record; Wikipedia "The Gates" |
| Rembrandt's self-portraits: about 40-50 paintings, 31-32 etchings, about 7 drawings ("about 80"; some count near 100) | Wikipedia "Self-portraits by Rembrandt"; National Gallery of Art |
| Impression, Sunrise (1872), the first Impressionist exhibition (Paris, 1874), the critic's mocking name; Monet's haystacks (about 25, 1890-1891) | Musée Marmottan Monet; Art Institute of Chicago, "Stacks of Wheat" |
| Paint in collapsible tubes patented by John Goffe Rand, 1841 | Smithsonian Archives of American Art |
| Seurat's A Sunday on La Grande Jatte, 1884-1886 | Art Institute of Chicago |
| Fauvism 1905 (Salon d'Automne), Les Demoiselles d'Avignon 1907, the Surrealist manifesto 1924, The Persistence of Memory 1931, Abaporu 1928, Pop Art from the mid-1950s in Britain | MoMA; Tate glossary; MALBA (Abaporu) |
| Ibn al-Haytham (about 965-1040) and the camera obscura (Book of Optics, 1011-1021); Niépce's View from the Window at Le Gras (about 1826-1827); the daguerreotype (1839); Muybridge's The Horse in Motion (1878); the Lumière brothers' first public film show (1895) | Britannica; Harry Ransom Center (Niépce); Library of Congress (Muybridge) |
| Lotte Reiniger's The Adventures of Prince Achmed (1926), the oldest surviving animated feature film; film at 24 frames a second; the thaumatrope (1825) and zoetrope (1834) | BFI; Britannica |
| Frida Kahlo painted 55 self-portraits; Dürer's self-portrait of 1500 | Frida Kahlo Foundation and museum texts; Alte Pinakothek |
| Diego Rivera's Detroit Industry murals (1932-1933); the Statue of Liberty (dedicated 1886, 46 m statue); Christ the Redeemer (1931) | Detroit Institute of Arts; US National Park Service |
| Louis Sullivan, "form ever follows function" (1896); the Bauhaus (1919-1933); Breuer's tubular steel chair (1925, from bicycle handlebars); Carwardine's balanced-arm lamp (1932); Sori Yanagi's Butterfly Stool (1954) | Britannica; Bauhaus-Archiv; V&A; Design Museum |
| Calder's first mobiles, 1931-1932; Hepworth, Moore | Calder Foundation; Tate |
| John von Neumann's First Draft (1945) and the stored program; Claude Shannon's 1937 thesis on switching circuits | Britannica; MIT |
| ASCII (1963): A 65, a 97, 7 bits; Unicode 16.0 (2024): 154,998 characters | ANSI X3.4-1963; Unicode Consortium |
| CD audio: 44,100 samples a second, 16 bits a sample | IEC 60908 (Red Book) |
| Harry Beck (1902-1974) designed the Underground diagram in 1931 (printed 1933) | London Transport Museum |
| Katherine Johnson checked the electronic computer's orbit for John Glenn, 1962; Louis Braille's dots, 1824, aged 15 | NASA; `data/success/stories.json`'s sources |
| Global e-waste 2022: 62 million tonnes, 22.3% documented as collected and recycled | Global E-waste Monitor 2024 (UNITAR/ITU) |
| Contrast of at least 4.5:1 for ordinary text | W3C WCAG 2.2, success criterion 1.4.3 |
| Chopin (1810-1849), Tchaikovsky (1840-1893; Swan Lake 1877, The Nutcracker 1892), Smetana (1824-1884; Vltava 1874), Fanny Mendelssohn (1805-1847, over 450 works), Clara Schumann (1819-1896) | Britannica; Grove Music Online |
| Debussy (1862-1918) and the whole-tone scale; The Rite of Spring (Paris, 1913); Schoenberg (1874-1951); Cage's 4′33″ (1952); the theremin (about 1920); Pierre Schaeffer's musique concrète (1948) | Britannica; Grove |
| Jazz in New Orleans around 1900; Louis Armstrong (1901-1971); Ella Fitzgerald (1917-1996); the blues scale (1, ♭3, 4, ♯4, 5, ♭7) | Smithsonian National Museum of African American History and Culture; Britannica |
| Monteverdi's L'Orfeo (1607); The Magic Flute (Vienna, 1791); Verdi (1813-1901); Peking opera from about 1790, painted faces (red loyal, white sly); Show Boat (1927) | Britannica; UNESCO (Peking opera, 2010) |
| Griots and the 21-string kora; tango (Argentina and Uruguay), flamenco, fado, reggae (Jamaica, 1960s; Bob Marley 1945-1981), samba, gamelan, calypso, mariachi, highlife | UNESCO intangible heritage lists; Britannica |
| Long exposure above about 85 dB risks hearing | WHO "Make Listening Safe" |

Every sum, program, query, circuit, file size, scale, transposition, beat count, tempo and loop in the units was worked
out by the build scripts and again by the tests (above).

## Rulings (decide and write down; cost if wrong)
1. **The outline stays as the research wrote it** (11 + 9 + 9 units; only `file` fields added, as the lead asked).
   Networks and the internet, and online privacy, are taught inside cyber security (HTTPS, firewalls, public wireless,
   the game's log-in rules), as grade 8 has no networks unit. *Cost:* a networks unit if the lead adds one to the
   outline.
2. **Text code continues grade 7's Python-like subset, unnamed; SQL is named** as "the query language most databases
   use" (an ISO standard, not a brand). *Cost:* call it "a query language".
3. **The little machine** (LOAD n, ADD n, SUB n, OUT, HALT, one accumulator) is the School's own teaching instruction
   set; machine code is described, not shown as binary op codes. *Cost:* a card on op codes.
4. **Worst cases:** binary search ⌊log₂ n⌋ + 1 (grade 7's rule), bubble sort n(n − 1) ÷ 2 with every pass to the end;
   merge sort "fewer than 9,000 comparisons for 1,000 items" (its worst case is 8,977). *Cost:* none.
5. **AI honestly:** a nearest-neighbour model is the concrete way a machine learns from labelled examples; what AI
   cannot do is said plainly; bias is taught through data, with a made-up training set in a pie chart (8 to 1) and the
   documented face and voice cases, unnamed. *Cost:* another example if the owner prefers not to name skin tone.
6. **Passwords and log-ins use this game's own rules** (#105). *Cost:* the cards change if the rules do.
7. **ASCII at 8 bits a character** in the worked examples (7-bit codes stored in a byte). *Cost:* none.
8. **Devices' watts are typical round values**, labelled "about"; e-waste numbers are 2022's. *Cost:* new numbers when a
   newer report appears.
9. **People of the past only** (42 named with years, in the test's table): minimalism's founders are living, so it is
   taught by what it is; no living artist (Kusama, Gormley, Lin) is named. *Cost:* none.
10. **No brands:** Warhol's soup cans and the balanced-arm lamp without trade names, the animators' rules of thumb
    unnamed, no phone or console makers, "public wireless" not the trademark. *Cost:* none.
11. **Names in the font's letters:** Dali (not Dalí), Bedrich Smetana (not Bedřich); René, Frédéric, Nicéphore Niépce
    and Dürer keep their letters (the font has them). *Cost:* none.
12. **Religion as culture:** Christ the Redeemer is a monument; Diwali, Christmas carols, the Lunar New Year and Carnival
    are festivals' music, side by side. *Cost:* none.
13. **Instrument ranges are the commonly taught sounding ranges** (a table in the picture file; the voices are choir
    ranges); exercises ask only about notes well inside or outside a range. *Cost:* another book's limits differ by a
    note or two.
14. **Swing is long-short at about 2 to 1** (heard: notes of 2 and 1 units; drawn: `swing_beats`). *Cost:* none.
15. **The game's LOOP is 4 bars of 4 beats at 100 beats a minute** (spec: "records four bars at 100 beats a minute"):
    16 beats, 9.6 seconds. *Cost:* the worked example if LOOP's bars are not 4 beats.
16. **Ages are asked "at the end of that year"** (birthdays not needed). *Cost:* none.
17. **New kinds in this agent's own file**, and `swing_beats` instead of changing grade 5's `beat_grid` (whose dividers
    assume 4 steps a beat past 8 steps). *Cost:* none.
18. **The quality bar is held by this agent's content test**, as `test_school_quality.gd` covers grades 3-7. *Cost:* a
    line in that test when the lead brings grade 8 into its scope.
19. **No hard history in these units:** music and identity says people who moved brought their songs, without naming
    slavery (grade 7's folk music already does, with its `hard` field). *Cost:* none.
20. **A new generator source `g8c`**, as the lead assigned. *Cost:* none.

## Merging (for the lead)
- `lead-merge` at 8ce66716 (the grade 8 humanities) is merged into this branch already: its three "keep both" conflicts
  were joined with the humanities' lines first and this agent's after them, as the lead asked: `g8c` after `g8h` at the
  end of SOURCES (`core/school/school_gen.gd`), the grade 8 arts hooks after `SchoolPictureG8Hum`'s in
  `ui/school/school_picture.gd` (the header's kind list, `problem` and `_draw`; the join had dropped the humanities'
  `return` after its draw call, restored), and the DEVELOPMENT.md bullet after the humanities' one. The grade 8 health,
  D&T and projects agent (`g8l`) adds its lines after these.
- `data/school/grade8.json` merged by itself (only computing, art and music `file` lines here; the humanities' `hard`
  lines kept).
- Tests that pinned grade 8's old state were already relaxed on `lead-merge` (`test_daily_mission.gd` builds its own
  three-subject grade; `test_g7_life_gen.gd` checks `g7w` after grade 7's sources), so nothing else changed.
- None of the 27 kinds is used by another picture file (`test_school_picture_kinds_unique.gd` passes with the
  humanities' 10); a later agent must not reuse `gate_circuit`, `db_table`, `jazz_band` or the others.
- Not done here, for the lead: the plan's outline (`python3 tools/school_outline.py --write
  docs/superpowers/plans/2026-09-28-school.md`) after the merge; a line in the spec's §22.4 "as built" for grade 8;
  `data/life/life.json` (Life's file) could list grade 8's cyber security under "Life online" and music and identity
  under "My feelings", as grade 7's units are listed.

## What comes next (the School never ends, #71)
Grade 8 networks (routers, the cloud, data centres) and a project that builds a whole program; an in-game code runner
and a piano-roll composer for the composition project; a mural wall in the game with a grid overlay; a gallery room
where a child hangs their own photos with labels; a theremin block; grade 9's computing, art and music.

## The full suite
`tests/run_tests.sh`, 2026-10-17 on this branch at 6d78ecce (with `lead-merge` 8ce66716: Life L3a and the grade 8
humanities merged in): 1,225 scripts, 11,388 tests, **11,385 passing, 0 failing**, 3 risky or pending as before (two
world tests that do not assert, and the move by code that is off on the server), 10,963,900 asserts, 77.7 minutes. An
earlier run was stopped partway by the PC's memory guard while the session was idle (not a failure); before the
humanities merge, that run had found only three tests that pinned grade 8's old state (the daily mission's "grade 8 so
far", `g7w` as the last SOURCES line), which `lead-merge` had already relaxed.
