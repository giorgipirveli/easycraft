# Grade 4 computing, art and design, and music: every unit written (owner #70, #73; 2026-09-29)

The owner: "start from grade 3 and finish all grades accordingly" and "research school programs, world leading schools
and create better school program". The research (`docs/design/school-curriculum-research.md` §6.4) lists grade 4's
Computing (11), Art and Design (9) and Music (9) units; this agent wrote all 29 (brief:
`docs/superpowers/plans/2026-09-29-school-subjects-brief.md`, GRADE = 4, SUBJECTS = computing, art, music), building on
grade 3's units of the same subjects (`docs/devlog/parts/m8-grade3-arts.md`). Branch
`worktree-agent-a5f97cfdca2271e3e`, from `lead-merge` e74c9cd, with the grade 3 arts branch merged in first (its picture
kinds and its content are built on) and `lead-merge` merged again at the end.

## What was written
| Subject | Units | Lesson cards | Hand-written exercises | Kinds of exercise | Generators used |
|---|---|---|---|---|---|
| Computing | 11 | 88 | 163 | choice 70, true/false 30, number 18, sort 17, match 13, order 11, robot 4 | `event_turns`, `if_else`, `trace_variable`, `plan_route`, `table_query` |
| Art and design | 9 | 72 | 137 | choice 58, true/false 25, number 14, sort 12, match 9, mix 9, order 8, build 2 | `complement`, `warm_cool`, `mix_wheel`, `tone_scale`, `pixel_count`, `which_print` |
| Music | 9 | 72 | 153 | choice 76, number 24, true/false 21, match 9, sort 9, order 8, rhythm 6 | `note_beats`, `fill_the_bar`, `count_the_bar`, `name_the_note`, `step_or_leap`, `round_parts`, `ostinato_count` |
| **All** | **29** | **232** | **453** | | 18 generators (`g4a`), each at levels 1-3 |

- **Files:** `data/school/g4/{computing,art,music}/<unit>.json`, linked from `data/school/grade4.json` (only these
  subjects' `file` fields changed; titles, goals and standards kept).
- **Every unit:** 8 lesson cards, one idea each, opening with a quick memory question (its answer in brackets, often
  naming what grade 3 taught) and ending "Try it in the world: …" with what comes next (research §5.3 rules 1, 7, 8);
  14-19 hand-written exercises at levels 1, 2 and 3 (at least 4, 5 and 5 of them, so a round never repeats one), of 3-7
  kinds, each with a hint (a strategy, never the answer) and an explain (the worked answer).
- **Computing:** events (WHEN blocks, one program with many events, inputs and sensors make events; this game's doors
  open on a tap), if … then … else (conditions are true or false; IF … ELSE runs one part; comparing numbers with >, <,
  = and ≥; an IF inside an ELSE; a robot that turns at walls), variables (a named box; SET replaces, CHANGE adds or takes
  away; a score with events and IF; the bug of SET inside the event), plan before you code (flowcharts: rounded START and
  END, rectangles, diamonds, a loop back; decomposition; dry runs of robot programs; the robot type with gems and "at
  most N commands"), networks (cables and radio waves, the router, servers and clients, packets, addresses; this game's
  online worlds on a server), search smart (the index, keywords, exact phrases, ranking, adverts, searching safely), is
  it true? (who, when, why; other good sources; fact and opinion; tricks and changed photos; Pluto and the 1998 page),
  data in tables (rows and columns, sorting, filtering, both), your digital footprint (on purpose and without noticing,
  copies stay, THINK, what photos give away, asking first), getting help online (OK and not OK, warning signs, never
  your fault, trusted adults; this game's MUTE, BLOCK and REPORT with MEAN WORDS, SCARY, ASKED SECRETS, SOMETHING ELSE),
  computers that changed the world (people who computed, the abacus, the 1804 punched-card loom, Ada Lovelace 1843,
  ENIAC 1945, the Moon 1969, microchips, the web 1989, phones in the 2000s).
- **Art and design:** the colour wheel (primaries a third apart, secondaries between, six tertiaries at 2 : 1,
  complementary opposites that brighten each other and mix to a dull brown, warm and cool; van Gogh; Newton's wheel of
  1704), light and shade (tone scales, the lit side, the highlight, the shadow and the cast shadow, H and B pencils,
  hatching and stippling; chiaroscuro, Rembrandt, Leonardo), portraits (the egg, eyes halfway, the nose and mouth
  lines, five eyes wide, the ears; the Mona Lisa, van Gogh and Rembrandt's self-portraits, Arcimboldo, Frida Kahlo),
  landscapes (foreground, middle ground, background, the horizon at eye level, smaller, paler and bluer far away,
  overlapping; Hokusai, Constable, Monet), art of the first civilisations (Ancient Egypt's rules, the pharaoh bigger,
  the grid, earth paints and Egyptian blue, hieroglyphs for sounds, the cartouche, the Rosetta Stone and Champollion;
  the Egyptians' gods as their belief), printmaking (relief prints, a print is the block's mirror image, repeats;
  Hokusai's blocks, Dürer's rhinoceros), relief sculpture (in the round, low, high and sunken relief, coins, Egyptian
  temples, the Parthenon frieze, Ghiberti's doors, side light), pixel art (pixels, resolution, 4 times the pixels at
  twice the size, the BLOCKY style's 16 × 16 faces, light's red, green and blue, mosaics), talking about art (kind,
  specific, helpful; I like, I notice, I wonder; two stars and a wish; drafts).
- **Music:** note values (semibreve, minim, crotchet, quavers with the US names; bars of 4/4; heard as long and short
  tones), beats in a bar (time signatures; marches and waltzes heard as oom-pah and oom-pah-pah; common time; conducting
  patterns; The Blue Danube), notes on the stave (the treble clef round G, E G B D F and F A C E, middle C's ledger line,
  the octave; words spelled in notes), compose a melody (the C pentatonic scale, steps and leaps by letter, the home
  note, question and answer phrases), layers and ostinato (patterns that repeat, drones, texture; Ravel's Boléro), the
  orchestra (the four families and where they sit, how each sounds, the oboe's A; Peter and the Wolf), rounds (Frère
  Jacques line by line, who sings what when, harmony, Sumer Is Icumen In), music long ago (bone and ivory flutes about
  40,000 years old, Jiahu's crane-bone flutes, the lyres of Ur, Egyptian harps, the Hurrian song on a clay tablet, the
  aulos, the 65 bells), music for moving pictures (setting the mood, silent films' live music, major and minor heard,
  leitmotifs, game music that loops; this game's day and night music).
- **Listening:** 44 music exercises and 22 lesson cards carry a sound (claps or the plucked tone); the seven listening
  units have at least 6 each (the test: `test_the_music_units_let_you_listen`).

## New picture kinds (`ui/school/school_picture_g4arts.gd`, `SchoolPictureG4Arts`, hooked into `SchoolPicture` after the grade 3 arts kinds)
- `stave` {notes (C4-A5 naturals, 1-8), values? (semibreve, minim, crotchet), names?, mark?, time?, bars?}: the treble
  stave with a drawn G clef, ledger lines, stems up below the middle line and down from it, time signatures and bars.
  `stave_step(note)` is the note's place (E4 = 0, middle C = -2).
- `code` {lines (1-9, two spaces a step in), mark?}: block code coloured by the first word: WHEN (events), IF, ELSE,
  REPEAT, FOREVER, WAIT (control, their inner lines hanging from a bar), SET and CHANGE (variables), the rest actions.
- `flowchart` {steps: [{shape: start | end | step | decision, text, no? | back?}] (2-6)}: a decision's "no" goes to a
  side box that joins the step after the "yes" step, or loops back up.
- `network` {devices, wired?, router?, internet?, server?, mark?}: devices by cable (solid) or radio (dashed).
- `colour_wheel` {size 6 | 12, blank?, mark?, line?, half? (warm | cool), names?}: the painters' wheel, yellow at the
  top; `opposite(colour)`.
- `shading` {shape: sphere | cube | cylinder, light: left | right, labels?, flat?, lamp?}; `face` {guides?, mark?,
  eyes? (high: the common mistake)}; `landscape` {mark?, labels?}; `pixel_art` {rows, key, grid?} (`pixels_of`);
  `relief` {what: low | high | sunken | round} (from the side and from the front); `print` {items: [{text, on: block |
  paper, flip: none | mirror | upside down}], arrows?}; `orchestra` {mark?, hide?}; `glyphs` {signs: water, mouth,
  bread, stool, basket, reed, foot; cartouche?; names? (the sounds n, r, t, p, k, i, b)}.
- Grade 3's `notation` gains `semibreve` (4 beats), `dotted minim` (3) and `time` (2/4, 3/4, 4/4: drawn, and bars
  every bar of it); its `COLOURS` gain the six tertiary colours (their hues between their neighbours': a test).
- `ColourMix.RECIPES` gains the tertiaries (red-orange = 2 red and 1 yellow, …) and the tone scale's light grey (2
  white, 1 black) and dark grey (1 white, 2 black): `tests/unit/test_colour_mix_tertiary.gd`.
- Samples of every kind at the School's three sizes, broken data, the stave's lines and spaces, the wheel's opposites:
  `tests/integration/test_school_picture_g4arts.gd`.
- **Looked at:** every kind in contact sheets at the three sizes, then 21 of the 29 units in the School's own
  screenshots (`tools/school_shots.gd -- --unit=… --exercises`, a window; no editor or emulator; every lesson card and
  hand-written exercise, about 70 pictures a unit; no script errors). Fixed from what they showed: the flowchart's "no"
  box joins after the "yes" step and its label sits over the arrow, network labels sit under the devices, the wheel's
  warm and cool groups get an arc and a word and a marked colour a dark outline and a pointer (orange vanished on red),
  the horizon mark is bold, the landscape's tree stays in the frame and its house beside it, code and flowchart text is
  bigger in exercise pictures, and a hidden orchestra family's "?" is big. **A melody picture scales each tune to its
  own height**, so C D E D C and C E G E C draw the same hill: "which picture shows the tune" only offers tunes of other
  shapes (the build script now checks the drawn shapes differ).

## Generators (`core/school/gen/g4_arts_gen.gd`, `G4ArtsGen`, SchoolGen source "g4a", the last SOURCES line)
Seeded, levels 1-3, each with a strategy hint, a worked answer and `data`; `tests/unit/test_g4_arts_gen.gd` (20 tests)
works every answer out again with its own code: a small interpreter for the code pictures (SET, CHANGE, REPEAT, IF,
ELSE, SAY), its own robot and shortest route, its own wheel, recipes, tones, note values, stave, letter distances and
round tables. The generators: `event_turns`, `if_else`, `trace_variable`, `plan_route` (robot), `table_query`,
`complement`, `warm_cool` (sort), `mix_wheel` (mix), `tone_scale` (order), `pixel_count`, `which_print`, `note_beats`,
`fill_the_bar`, `count_the_bar` (listening), `name_the_note`, `step_or_leap` (listening), `round_parts`,
`ostinato_count` (listening; level 3: which time round one beat changes).

## Tests
- `tests/unit/test_school_content_g4_arts.gd` (written first; it failed until the units were written): every unit
  written and problem-free, 4-8 cards, ≥ 12 hand-written exercises at levels 1-3 of two kinds or more, rounds that vary
  and never repeat a hand-written exercise, hints and worked answers, memory first and the world last, the listening
  units' sounds, the units use their own `g4a` generators and every one is used; every paint mix, every complementary
  pair and opposite stated, every warm and cool sort follows the wheel; every stave read (a note or a word) is the
  notes' letters; every "how many beats" is the notes' beats; every robot program is run by RobotCheck; every rhythm to
  copy starts with a clap; every mix names its recipe's paints and drops; no prompt asks for personal details; the font
  draws ü, ç, è and é and the units name Dürer, Jean-François Champollion, Frère Jacques and Boléro.
- `tests/unit/test_g4_arts_gen.gd`, `tests/unit/test_colour_mix_tertiary.gd`, `tests/integration/test_school_picture_g4arts.gd`.
- The units were built by scripts (in this agent's scratch folder; the JSON files are now the source) that checked the
  limits, the words (kind, British, no brands or other games, ASCII and the font's letters), every sum and chain of
  sums, every paint and tint fact, every complementary claim, every warm and cool sort, every stave answer, every
  robot board (solved, and every program in a choice run), every rhythm's boxes, and every listening answer worked out
  from its sound (bars counted from the low notes, staves and melodies against the tune, steps and leaps, long notes,
  the changed ostinato, the lines of Frère Jacques): 28 listening answers checked.

- **The full suite** (`tests/run_tests.sh`, 2026-09-29 on this branch after merging `lead-merge` 43290ab): 776 scripts,
  7,161 tests, 7,158 passing, 2 risky that do not assert (`test_the_column_cache_changes_nothing`,
  `test_chunks_meet_without_seams`: world tests this branch does not touch), 1 failing: the Science Lab's
  `test_paint_mixes_by_recipe_and_light_adds`, which expected 2 red + 1 yellow to have no name. The Lab names its bowl
  from `ColourMix.RECIPES`, so it now says "Red and yellow make red-orange!", which is right; the test expects that now
  and keeps its "no name" check with 3 red + 1 yellow. It and the School's tests were run again after the fix: 70 of 70
  passing (the Lab's models, both content tests, the generators, the tertiary recipes, the pictures).

- **The full suite again on the final branch** (after merging `lead-merge` 6ea975e, with the Lab test fixed): 779
  scripts, 7,190 tests, 7,188 passing, 0 failing, 2 risky world tests that do not assert, 2,192,309 asserts, 30 min
  7 s; exit 0.

## Rulings (decide and write down; cost if wrong)
1. **Tertiary colours are 2 : 1 drops** of a primary and the other primary of its neighbouring secondary (red-orange =
   2 red + 1 yellow), the recipe ColourMix checks; the lesson also says "a primary and the secondary next to it" (red
   and orange make red-orange). Names use purple, not violet (red-purple, blue-purple), as grade 3's secondaries do.
   *Cost:* a recipe line each if a school teaches 3 : 1 or "violet".
2. **Warm and cool are sorted only for clear colours** (reds, oranges, yellows; blues, greens, purples and blue-green,
   blue-purple); yellow-green and red-purple sit on the border and are never sorted. *Cost:* none.
3. **A step is the next letter name** (C to D), a leap jumps over a letter (E to G, even in the pentatonic scale where
   no F lies between), as a child reads them on the stave. *Cost:* one card if a school counts scale steps instead.
4. **Beats in a bar are heard as oom-pah**: SchoolSound has one loudness, so the strong first beat is a low note and
   the others higher (a march, a waltz, 4/4). Minims and semibreves are heard as long plucked notes; claps can't hold a
   note, so no "which rhythm did you hear" offers a rest where a long note could be. *Cost:* a loudness field in
   SchoolSound, then accented claps.
5. **Rounds, layers and the orchestra are taught in words, tables and single lines**: SchoolSound plays one line at a
   time and one tone. The lines of Frère Jacques (traditional, public domain) are played one by one. *Cost:* chords and
   instrument sounds in SchoolSound.
6. **Real names keep their letters:** ç, è, é and ü join ALLOWED in `test_school_content.gd` (the School's font draws
   them: `test_the_font_draws_the_names_letters`). *Cost:* none.
7. **People:** artists, composers and inventors of the past only (Leonardo, Rembrandt, van Gogh, Arcimboldo, Frida
   Kahlo, Hokusai, Constable, Monet, Dürer, Champollion, Strauss, Ravel, Wagner, Prokofiev, Ada Lovelace, Newton); the
   web's inventor (living) is not named. No brands: "a search engine", "radio waves", "a phone". *Cost:* none.
8. **Online safety uses the game's own buttons** as they ship: MUTE, BLOCK, REPORT with its four reasons; nothing asks a
   child for personal details (a test); "stay away" replaces a wrong choice that used the guilt phrase "don't go".
   *Cost:* a card if the buttons change.
9. **Programs are written in the School's own block language** (WHEN, IF, ELSE, REPEAT, SET, CHANGE, SAY and the robot's
   FORWARD, TURN LEFT, TURN RIGHT), drawn as blocks; no other product's name. The robot type still has no REPEAT or IF
   key, so conditions are traced in the code pictures and loops appear as "at most N commands". *Cost:* a REPEAT key in
   RobotAnswer would let children write them.

## Merging (for the lead)
- This branch already contains `lead-merge` up to 6ea975e (grade 3 arts, grade 3 life, the Science Lab, grade 4
  history, geography and citizenship). Its conflicts were resolved here, keeping both: `ui/school/school_picture.gd`
  (the grade 3 life and grade 4 history hooks, then the grade 4 arts hooks, each with its `return`) and
  `core/school/school_gen.gd` (`g3p`, `g4h`, then `g4a` last in SOURCES); `data/school/grade4.json` merged by itself
  (history, geography, citizenship, computing, art and music all linked). Grade 4 history's Egypt and this art unit
  agree (hieroglyphs, the Rosetta Stone, Champollion in 1822).
- If `lead-merge` moved on, expect the same kind of "keep both" conflicts in those two files and in
  `tests/unit/test_school_content.gd` (ALLOWED gains ç è é ü), `data/school/grade4.json` (only the computing, art and
  music `file` fields), `docs/DEVELOPMENT.md` (the School section's two grade 4 arts bullets).
- Shared files changed here beyond the new ones: `ui/school/school_picture_arts.gd` (notation's semibreve, dotted minim
  and time; the tertiary COLOURS), `core/school/colour_mix.gd` (eight recipes, which the Science Lab's bowl now names
  too), `tests/unit/test_lab_models.gd` (2 red + 1 yellow is red-orange; 3 red + 1 yellow has no name).

## What comes next (the School never ends, #71)
Grade 5 computing, art and music (research §6.5), instrument sounds, chords and loudness in SchoolSound (rounds and
layers heard together, accents), a REPEAT and an IF key for the robot, and the world links: a gallery with the colour
wheel, a relief wall and a pixel-art board, a band stage for rounds and ostinatos, a network of routers in a village.
