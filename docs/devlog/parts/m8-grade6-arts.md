# Grade 6 computing, art and design, and music: every unit written (owner #70, #73; 2026-09-30)

The owner: "start from grade 3 and finish all grades accordingly" and "research school programs, world leading schools
and create better school program". The research (`docs/design/school-curriculum-research.md` §6.6) lists grade 6's
Computing (11), Art and Design (9) and Music (9) units; this agent wrote all 29, following the reusable brief
(`docs/superpowers/plans/2026-09-29-school-subjects-brief.md`, GRADE = 6, SUBJECTS = computing, art, music) and building
on grades 3, 4 and 5 of the same subjects (`m8-grade3-arts.md`, `m8-grade4-arts.md`, `m8-grade5-arts.md`). Branch
`worktree-agent-a36ee4fd09c7b007a`, from `lead-merge` at 1d4ff0af.

## What was written
| Subject | Units | Lesson cards | Hand-written exercises | Kinds of exercise | Generators used (`g6c`) |
|---|---|---|---|---|---|
| Computing | 11 | 88 | 180 | choice 68, number 51, true/false 37, sort 9, order 7, match 6, label 2 | `binary_value`, `to_binary`, `image_bits`, `light_colour`, `logic_check`, `gate_output`, `trace_program`, `flow_path`, `data_type`, `game_decision`, `storage_size`, `sheet_model`, `guess_count`, `phish_check`, `public_private`, `ai_guess` |
| Art and design | 9 | 72 | 147 | choice 71, true/false 29, number 21, match 8, sort 7, order 6, label 5 | `principle_spot`, `tile_angles`, `turn_angle`, `print_order`, `nature_numbers`, `critique_step` |
| Music | 9 | 72 | 160 | choice 94, true/false 25, number 23, rhythm 6, match 4, order 3, label 3, sort 2 | `scale_notes`, `interval_size`, `blues_bar`, `music_period`, `offbeat_rhythm`, `variation_change`, `chord_fit`, `instrument_family`, `sound_numbers` |
| **All** | **29** | **232** | **487** | | 31 generators (`g6c`), each at levels 1-3, in 25 units (world art, two-point perspective, expression and lettering have hand-written practice only) |

- **Files:** `data/school/g6/{computing,art,music}/<unit>.json`, linked from `data/school/grade6.json` (only these
  subjects' `file` fields, and one goal sharpened: keyboard skills' "on the game's keyboard" became "on a keyboard, one
  hand each", because the game has no keyboard yet; ids, titles and standards kept).
- **Every unit:** 8 lesson cards, one idea each, opening with "Quick memory:" and a question whose answer is in brackets
  (what grade 3, 4, 5 or an earlier grade 6 unit taught) and ending "Try it in the world: … Next: …" (research §5.3
  rules 1, 7, 8; the test checks both, and the Next); 16-19 hand-written exercises at levels 1, 2 and 3 (at least 4, 5
  and 5), of 3-7 kinds, each with a hint (a strategy, never the answer) and an explain (the worked answer).
- **Computing:** binary numbers (bits, place values that double, binary cards face up and down, counting, converting
  both ways, a byte holds 0-255), how pictures are stored (pixels, 1 bit a pixel for black and white, more bits more
  colours, red, green and blue light 0-255 adding up to yellow, cyan, magenta and white, resolution, sizes in bits and
  bytes), AND, OR, NOT (Boolean logic after George Boole, 1854; gates, truth tables, NOT in brackets), flowcharts and
  pseudocode (ovals, boxes, diamonds, back arrows; SET, IF, ELSE, REPEAT n TIMES, REPEAT UNTIL, OUTPUT; trace tables; a
  bug found by tracing), variables and data types (integer, real, string, Boolean; "5" + "5" joins, 5 + 5 adds; SET
  copies a value), complex decisions (combined and nested IFs in a game, ELSE, paths, testing the edge), hardware and
  software (the processor's fetch, decode, execute; memory forgets, storage keeps; the operating system; bits, bytes,
  KB, MB, GB; label the inside of a computer), spreadsheet models (inputs, formulas, outputs; =B3*C3, =AVERAGE, =D4/25;
  a class trip; what if), keeping accounts safe (long passwords of three random words, how each character multiplies
  the guesses, two-step checks, phishing's five clues and what to do), your online identity (nicknames, public and
  private, privacy settings, footprints last, places in photos), what is AI (learning from labelled examples, guesses
  that can be wrong, bias from narrow examples, what AI cannot do, checking what it says).
- **Art and design:** elements and principles (line, shape, form, colour, tone, texture, space; symmetrical,
  asymmetrical and radial balance, contrast, emphasis, rhythm, movement, pattern, unity, variety), world art 500-1500
  (illuminated books and the Book of Kells about 800, lapis lazuli, quills; Islamic geometric patterns with compass and
  ruler, the Alhambra in the 1300s; Benin's brass heads from the 1200s and plaques in the 1500s, lost-wax casting, the
  casters' guild still at work; Song dynasty shan shui (960-1279) and Fan Kuan about 1000), geometric patterns
  (tessellations: only triangles, squares and hexagons alone; pentagons' gaps; octagons with squares; rotational
  symmetry and the turn 360° ÷ order; eight-pointed stars; M. C. Escher), two-point perspective (the horizon at eye level,
  two vanishing points, the leading edge, verticals stay upright, above and below the horizon), expression and emotion
  (faces, poses, warm and cool colour, line; Picasso's Blue Period 1901-1904, Munch's The Scream 1893), layered prints
  (lightest first, multi-block woodblocks and Hokusai, kento registration, reduction linocuts, planning), lettering and
  calligraphy (baseline, x-height, ascenders, descenders; serifs and Trajan's Column AD 113; the broad pen's thick and
  thin; brush calligraphy's stroke order; monograms), art from nature (land art, photographing it, Spiral Jetty 1970,
  Fibonacci spirals of 34 and 55, leave no trace), analyse an artwork (describe, analyse, interpret, judge, with context:
  The Great Wave, The Starry Night, Hunters in the Snow).
- **Music:** scales and keys (major scales from any note, G, F and D major, key signatures of C, G, F, D, A and B flat,
  the home note), intervals (letters counted both ends: second, third, fourth, fifth, sixth, octave; heard; chords are
  root, third and fifth), the blues (its roots in African American communities of the southern USA, the 12-bar blues I
  IV V in C, G, D, A and E, A A B words, the blues scale, blue notes, improvising, W. C. Handy), early music (plainchant,
  Hildegard of Bingen (1098-1179), Guido of Arezzo's lines about 1025 and ut re mi, the estampie, lute and shawm,
  Renaissance polyphony and Tallis's 40-voice Spem in alium, Petrucci's printing in 1501, the first operas around 1600),
  syncopation (1 & 2 & 3 & 4 &, off-beat claps, ragtime and Scott Joplin (1868-1917), jazz, reggae, the backbeat),
  theme and variations (changing rhythm, pitch, harmony and order; Mozart's variations on Twinkle, Twinkle around 1781,
  Haydn's Surprise Symphony 1791, Elgar's Enigma Variations 1899), keyboard skills (finger numbers, C position for each
  hand, the left-hand chord 5-3-1, the chord that fits a melody note, passing notes, practising hands separately),
  instruments of the world (chordophones, membranophones, aerophones, idiophones; sitar, koto, djembe, bagpipes, steelpan,
  kora, erhu, didgeridoo, balafon, shakuhachi, bodhran; label them), the science of sound (vibrations, no sound in space,
  frequency in hertz with A4 at 440 Hz, octaves double, 20-20,000 Hz, amplitude and decibels with the 85 dB care line,
  harmonics and timbre heard, thunder about 1 km each 3 seconds).
- **Listening:** 45 music exercises and 25 lesson cards carry a sound; the seven listening units have 6 or more each
  (`test_the_music_units_let_you_listen`), and the science of sound plays a quiet note (volume) and pure, bright and
  hollow tones (timbre).

## New and grown code
- **SchoolSound's volume and tone** (`core/school/school_sound.gd`): any sound may have `volume` (0.1-1, the amplitude)
  and a tune `tone` (`TONES`: "plucked", the old default and unchanged; "pure", one frequency; "bright", every harmonic
  to the 8th; "hollow", the odd harmonics), so the science of sound can let a child hear loudness and timbre.
  `tests/unit/test_school_sound.gd` (`test_a_sound_can_be_quieter_and_have_its_own_tone`, `test_a_pure_tone_is_one_frequency`:
  220 cycles a second counted in the samples).
- **25 picture kinds** in `ui/school/school_picture_g6arts.gd` (`SchoolPictureG6Arts`, hooked into `SchoolPicture` after
  the grade 6 humanities kinds; its header lists every field): `bit_cards`, `rgb_mix` (bars, or three torches whose
  overlaps add up, drawn with `Geometry2D.intersect_polygons`), `logic_gate` (AND, OR and NOT symbols, lit wires, a NOT
  after), `computer_parts`, `phish_mail`, `privacy_panel`, `ai_examples`, `art_principle` (10 designs), `illuminated`,
  `star_pattern` (the circle, the lines joining every k-th point, the finished star, tiled), `ink_landscape`,
  `tessellation` (8 tilings clipped to the card; pentagons and circles show their gaps), `rotation_motif`, `two_point`,
  `feeling_art` (six feelings as faces or whole figures), `print_layers`, `stroke_letters` (capitals from strokes, with
  serifs, a broad nib's thick and thin, monograms), `letter_guides`, `land_art` (spirals, rings, a sunflower head by the
  golden angle), `masterwork` (small pictures after The Great Wave, The Starry Night and Hunters in the Snow),
  `key_signature` (drawn sharps and flats, note names with their signs), `twelve_bar`, `hand_keys`, `world_instrument`
  (8 instruments with their parts) and `decibel_scale`. `part_at(picture, part, size)` says where each labelled part is
  (the computer, the scroll, the instruments, the two-point box, the guide lines), so a label exercise's lines can be
  checked; `bits_value`, `gate_out`, `key_accidentals` and `twelve_bar_chords` are the facts the tests share. Samples,
  broken data and the facts in `tests/integration/test_school_picture_g6arts.gd`.
- **Grade 5's sheet grown** (`ui/school/school_picture_g5arts.gd`): `value()` works out `=AVERAGE(B2:B5)` and a share
  (`=D4/25`; dividing by 0 is a problem the content test finds), and a cell may hold 16 letters (=AVERAGE(B2:B5) is 15).
- **Generators** `core/school/gen/g6_arts_gen.gd` (`G6ArtsGen`, SchoolGen source `g6c`, the last SOURCES line): 31,
  seeded, levels 1-3, each with a strategy hint, a worked answer and `data`. `tests/unit/test_g6_arts_gen.gd` (31 tests)
  works every answer out again with its own binary, light, logic, program interpreter (SET with expressions, CHANGE,
  REPEAT, REPEAT UNTIL, IF with AND, OR, NOT and ELSE, OUTPUT), flowchart walk, data types, spreadsheet, codes,
  phishing clues, privacy table, learned rule, angles, rotation, ink lightness, Fibonacci numbers, critique table,
  scales by semitones, intervals by letters, the 12-bar blues, periods, off-beats, variations heard, chords, instrument
  families and places, and sound's numbers.

## Tests
- `tests/unit/test_school_content_g6_arts.gd` (written first; it failed until the units were written; 21 tests): every
  unit written and problem-free, 4-8 cards, ≥ 12 hand-written exercises at levels 1-3 of two kinds or more, rounds that
  vary and never repeat a hand-written exercise, hints and worked answers, memory first and the world and Next last,
  the seven listening units' sounds, the units use their own `g6c` generators and every one is used, no prompt asks for
  personal details, every label's line ends on its part; and the facts, with this test's own tables: binary numbers
  said and shown on cards, colours of light, every gate asked about and truth-table row, what every program outputs or
  leaves in a variable (its own interpreter), every spreadsheet cell asked about (AVERAGE and shares too), every
  regular shape's angle and "n fit round a point", rotation orders and turns, every major scale said and marked on a
  keyboard and every key signature, every interval said, heard or read, the blues scale and the 12-bar pictures, every
  chord said, the composers' and artists' years, every note's frequency in hertz, and the rhythms to copy.
- `tests/unit/test_g6_arts_gen.gd`, `tests/unit/test_school_sound.gd`, `tests/integration/test_school_picture_g6arts.gd`;
  the shared `test_school_content.gd` and `test_school_picture_kinds_unique.gd` pass with the new files.
- The units were built by scripts in this agent's scratch folder (the JSON files are now the source) that checked the
  limits, the words (kind, British, no brands, other games or living people, the School's letters), every sum and chain
  of sums (thousands commas too), every program run by an interpreter, spreadsheets, binary, light, gates and truth
  tables, scales, key signatures, intervals, the blues scale, frequencies, angles, the people's years, rhythms, and
  placed each label's pins at the side of its part, at least a finger apart.
- **Looked at:** every new kind in contact sheets at the label box's size, then all 29 units in the School's own
  screenshots (`tools/school_shots.gd -- --unit=… --exercises`, a window; no editor or emulator): about 1,220 of them,
  40-46 a unit, no script errors. Fixed from what they showed: instrument names overlapped the drawings (each part now
  has its own label spot), the unity design's squares overlapped, the two-point box was stretched and its orange mark
  vanished on an orange box (now shorter, in cool greys, a marked point ringed), serif letters crowded each other, the
  hand's fingers were tiny, the kora's strings were white on cream, the dB line crossed the names, a gate's JSON inputs
  showed "1.0", the computer's label pins covered the ports (now above and below it), a baseline question labelled its
  own answer, the broad nib's thick and thin were too even, and two cards gained pictures (13 on binary cards; the
  countdown's trace table).
- **The full suite** (`tests/run_tests.sh`, 2026-09-30 on this branch at 248fc3ea, from `lead-merge` 1d4ff0af): 936
  scripts, 8,521 tests, 8,518 passing, 2 risky world tests that do not assert (as before), 3,945,083 asserts, 46 min;
  1 failing, not this branch's: `test_prospect_blocks.gd`'s `test_the_held_page_stays_empty_for_the_domes` (the
  colonies already fill page 31 at 1d4ff0af; `lead-merge` has since rewritten the test as
  `test_the_page_held_for_the_domes_is_theirs`, so it passes after the merge).

## Rulings (decide and write down; cost if wrong)
1. **The game has no keyboard or music maker yet**, so keyboard skills teaches finger numbers, C position, chords that
   fit and practising with pictures of hands on keys and the School's sounds; its goal says "a keyboard". *Cost:* a
   card or two and a "play the keys" exercise type when the game gets a keyboard.
2. **SchoolSound gains `volume` and `tone`** instead of real instrument samples (no audio files, as before): loudness
   and timbre are heard as a quieter note and as pure, bright and hollow tones. One sound has one volume, so "which is
   louder?" is taught with wave pictures, not two sounds side by side. *Cost:* a per-note volume later (accents).
3. **Kilobyte means 1,000 bytes** (the SI prefixes, as the UK's KS3 teaches first); 1,024 is not mentioned. *Cost:* a
   card if the owner wants binary prefixes.
4. **Pseudocode is written in the School's block language** (SET, CHANGE, REPEAT n TIMES, REPEAT UNTIL, IF, ELSE,
   OUTPUT; NOT in brackets round one comparison) and drawn with grade 4's code picture, so blocks and pseudocode look
   alike; exam-board keywords (WHILE, ENDIF) wait for grade 7's "from blocks to text". *Cost:* none.
5. **Phishing and privacy use made-up addresses** (game-help-desk.biz, win-gold-now.biz) and no real company or app;
   nothing asks a child for personal details (a test). *Cost:* none.
6. **AI is taught as learning from labelled examples** (what every example in one group shares), with made-up labels
   (yes, blip, team A) on coloured shapes, so the learned rule can be checked; chatbots appear only as "check what it
   says". *Cost:* none.
7. **People:** artists, composers and makers of the past only (George Boole, Hokusai, van Gogh, Bruegel, Picasso, Munch,
   Escher, Robert Smithson, Hildegard of Bingen, Guido of Arezzo, Tallis, Palestrina, Petrucci, Monteverdi, W. C. Handy,
   Scott Joplin, Mozart, Haydn, Elgar); no living artist is named (land art is described through its ideas).
   *Cost:* none.
8. **Hard history, with respect:** the blues' roots in African American communities after slavery and syncopation's in
   West African rhythms are named as history, without detail; Benin's art is taught as art (its casters' guild still
   works), not through 1897, which grade 6 history names. *Cost:* none.
9. **Religion as culture:** plainchant, monks and nuns, mosques and palaces are described as what people made and sang;
   why many mosques use patterns rather than pictures is left to history lessons. *Cost:* none.
10. **Paintings are drawn "after" the artists** as simple pictures of our own (a wave with Mount Fuji, a swirling night
    sky, hunters in the snow), never copies; their titles and years are facts. *Cost:* none.
11. **Four art units have no generator** (world art, two-point perspective, expression, lettering): what they practise
    is looking and naming, and 16-17 hand-written exercises vary the rounds. *Cost:* a generator each later.

## Merging (for the lead)
- A dry run against `lead-merge` d712a67b (`git merge-tree`) merges with no conflicts. If another School agent lands
  first, expect "keep both" conflicts in `ui/school/school_picture.gd` (the grade 6 arts hooks after the grade 6
  humanities ones, each with its `return`), `core/school/school_gen.gd` (`g6c` at the end of SOURCES) and
  `docs/DEVELOPMENT.md`; `data/school/grade6.json` should merge by itself (only computing, art and music units and one
  music goal changed).
- Shared files changed beyond the new ones: `core/school/school_sound.gd` (volume and tone; old sounds unchanged),
  `ui/school/school_picture_g5arts.gd` (the sheet's AVERAGE, "/" and 16-letter cells), `tests/unit/test_school_sound.gd`.
- None of the 25 kinds is used by another picture file on `lead-merge` 1d4ff0af (`test_school_picture_kinds_unique.gd`
  passes); a later agent must not reuse `tessellation`, `feeling_art` or the others.
- Not done here, for the lead: the plan's outline (`python3 tools/school_outline.py --write
  docs/superpowers/plans/2026-09-28-school.md`) after the merge.

## What comes next (the School never ends, #71)
Grade 7 computing (blocks to text, lists, functions, searching), art (the Renaissance, colour harmony, drawing people)
and music (chord progressions, the Baroque, the Classical era); a keyboard in the game and a "play the keys" exercise;
per-note loudness in SchoolSound (accents for syncopation, the Surprise chord); real instrument timbres; world links: a
monastery scriptorium to illuminate a letter, an Islamic tiled courtyard, a land-art meadow, a blues stage.
