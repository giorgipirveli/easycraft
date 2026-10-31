# Grade 3 computing, art and design, and music: every unit written (owner #70, #73; 2026-09-29)

The owner: "start from grade 3 and finish all grades accordingly" and "research school programs, world leading schools
and create better school program". The research (`docs/design/school-curriculum-research.md` §6.3) lists grade 3's
Computing (11), Art and Design (9) and Music (9) units; this agent wrote all 29 (brief:
`docs/superpowers/plans/2026-09-29-grade3-arts-brief.md`), in parallel with the other grade 3 agents. Branch
`worktree-agent-a842e5f8d382022d2` (from `lead-merge` 4ad2af7; `lead-merge` and `lead-school` merged in for the lead's
new exercise types: "code the robot" 3bf89b6, "copy the rhythm" eb8adc1, "mix the colour" 33562e1).

## What was written
| Subject | Units | Lesson cards | Hand-written exercises | Kinds of exercise | Generators used |
|---|---|---|---|---|---|
| Computing | 11 | 83 | 169 | choice 75, true/false 35, robot 14, number 14, sort 13, order 11, match 7 | `robot_moves`, `code_robot`, `loop_count`, `fix_the_bug` |
| Art and design | 9 | 71 | 149 | choice 82, true/false 27, sort 11, mix 10, order 10, match 7, number 2 | `mix_colour`, `mix_paint`, `next_in_pattern` |
| Music | 9 | 72 | 153 | choice 88, true/false 30, number 13, rhythm 9, match 7, sort 4, order 2 | `count_claps`, `which_rhythm`, `claps_in_rhythm`, `copy_rhythm`, `higher_lower`, `tune_direction`, `faster_slower` |
| **All** | **29** | **226** | **471** | | 14 generators (`g3a`), each at levels 1-3 |

- **Files:** `data/school/g3/{computing,art,music}/<unit>.json`, linked from `data/school/grade3.json` (only these
  subjects' `file` fields changed; titles and goals kept).
- **Every unit:** 7-8 lesson cards, one idea each, opening with a quick memory question (its answer in brackets) and
  ending "Try it in the world: …" (research §5.3 rules 1 and 8); 14-25 hand-written exercises at levels 1, 2 and 3 (at
  least 3, 4 and 4 of them, so a round never repeats one), of 3-7 kinds, each with a hint (a strategy, never the answer)
  and an explain (the worked answer).
- **Computing:** algorithms (recipes, clear and exact steps, order, the School's robot), code a robot (sequences;
  FORWARD, TURN LEFT, TURN RIGHT; "FORWARD 3" is short for three FORWARDs; a turn doesn't move the robot), loops
  (repeat, counting a loop's squares, a square with repeat 4 times, stairs to climb with the same steps), find the bug
  (a detective runs it step by step; the 1947 moth), decomposition (castles, sandwiches, a game's parts, gems then the
  flag), inside a computer (input, processing, output, storage; hardware and software; a touch screen does two jobs),
  data (tallies in fives, tables, block-tower bar charts), the internet and the web (networks, packets, cables under the
  sea, the web of 1989 on the older internet), keep it private (personal information, player names, three random words
  and a number, this game's chat filter and REPORT, ASKED SECRETS), being kind online (true, kind, face to face;
  cyberbullying is never your fault; MUTE, BLOCK, REPORT; upstanders), screens and balance (a balanced day, tired eyes,
  no screens before bed, the 20-seconds rest for eyes, STOP FOR TODAY when your player sleeps).
- **Art and design:** lines and shapes (straight, curved, zigzag, wavy, spiral, dotted, dashed, thick and thin; feelings
  in lines; geometric and organic shapes; simple shapes first), mixing colours (primaries, secondaries, tints with white,
  shades with black, all three make a muddy brown; the paint bowl), drawing what you see (big shapes lightly, details,
  light and shade, sketchbooks, Leonardo da Vinci's notebooks), patterns and prints (motifs, stamps, a print is a mirror
  image, block printing on cloth), texture and collage (rubbings, hatching, cross-hatching, stippling, scribbles; collage
  from the French "to glue"), sculpture (3D, carving, modelling, constructing; every side; a wide base; building in the
  game is constructing; ivory carvings over 30,000 years old), art long ago (Lascaux, Chauvet, Altamira; ochre, charcoal,
  chalk; hand stencils; fat lamps; nobody knows why; dating charcoal), looking at art (describe, feel, why; van Gogh's
  The Starry Night 1889, Hokusai's The Great Wave about 200 years ago, Seurat's dots), your gallery (curators, titles,
  labels with a made-up artist name and never an address, hanging, kind visitors).
- **Music:** pulse and rhythm (the steady beat, "pear" and "ap-ple", echo clapping, copy the rhythm), high and low
  (pitch, steps and leaps, a tune's shape, bigger instruments lower), loud, quiet, fast, slow (forte, piano, crescendo,
  diminuendo, tempo, accelerando, rallentando; Grieg's In the Hall of the Mountain King), instrument families (strings,
  woodwind, brass, percussion, keyboards; claps are body percussion), reading rhythms (crotchet (quarter note), quavers
  (eighth notes), the crotchet rest, bars of 4 beats; two boxes a beat when you copy), singing well (posture, breathing,
  warm-ups, in tune, echo songs, looking after your voice), music loops (ostinato, rhythm and melody loops, layers,
  composing steps), music around the world (djembe, talking drum, call and response, pentatonic tunes, gamelan, steel
  pans, the Cuban clave, sitar, tabla, erhu, didgeridoo), music that tells a story (Saint-Saëns's The Carnival of the
  Animals, 1886: The Elephant, The Aviary, Tortoises, The Swan, The Cuckoo; Rimsky-Korsakov's Flight of the Bumblebee).
- **Listening:** 76 music exercises and 31 lesson cards carry a sound (claps or a plucked tune); every listening unit has
  at least 6 (the test: `test_the_music_units_let_you_listen`).

## New picture kinds (`ui/school/school_picture_arts.gd`, `SchoolPictureArts`; hooked into `SchoolPicture` like the grade 5 and grade 3 maths kinds)
- `swatches` {items (1-8): a colour of `COLOURS` maybe with a shape ("red circle"), or "+", "=", "?"; names?; shape?}:
  paint patches ("red + yellow = ?") and patterns of coloured shapes. `COLOURS` uses ColourMix's names (lilac, cream);
  `TINTS` and `SHADES` say which colour each tint and shade comes from (the picture test checks they are lighter and
  darker, and each secondary's hue sits between its primaries').
- `notation` {beats: "crotchet", "quavers", "rest", "minim" (2 beats, for grade 4), "?" (1-8 beats); words?; bars?}:
  rhythms drawn (the font has no music signs): filled heads, stems, beams, the rest's zigzag, bar lines, "ta, ti-ti".
- `melody` {notes (SchoolSound names, 2-12), mark?}: a tune's shape as joined dots (a rest leaves a gap).
- `robot` {cols, rows, start, facing?, goal?, walls?, gems?, path?}: RobotCheck's board drawn as RobotAnswer draws it
  (the same robot, walls, gems and flag), with the robot's trail.
- `marks` {what: 1-4 of straight, curved, zigzag, wavy, spiral, loops, dotted, dashed, thick, thin, hatching,
  cross-hatching, stippling, scribble; names?}.
- Looked at in the School's screenshots (`tools/school_shots.gd`, a window, no editor or emulator): the zigzag and waves
  were squashed four to a card and the stippling was faint, both fixed (474914a).

## Generators (`core/school/gen/g3_arts_gen.gd`, `G3ArtsGen`, SchoolGen source "g3a", the last SOURCES line)
Seeded, levels 1-3, each with a hint, a worked answer and `data`; `tests/unit/test_g3_arts_gen.gd` works every answer
out again with its own code (its own claps, pitches, shapes, paint table and robot):
- Music: `count_claps` (how many claps you hear), `which_rhythm` (notation pictures to choose; level 3 differs by one
  beat), `claps_in_rhythm` (claps in a written rhythm, two bars at level 3), `copy_rhythm` (the "rhythm" type: 2, 3, 4
  beats), `higher_lower` (a big jump, a jump, a small step or the same), `tune_direction` (up, down, a hill, a valley;
  level 3 chooses the shape's picture), `faster_slower` (gaps that shrink or grow; level 3 also steady).
- Art: `mix_colour` (what two paints make; which two make it; white or black; what to add for a tint or a shade; all
  three primaries; choose the patch), `mix_paint` (the "mix" type: secondaries, then a tint or a shade, then three
  paints), `next_in_pattern` (AB, then ABB/AAB/ABC, then 4-piece motifs; every piece differs in shape and colour).
- Computing: `robot_moves` (which program reaches the flag; wrong ones are a child's slips, each run to be sure it
  misses), `code_robot` (the "robot" type: open ground, then walls and gems, then walls in the way and "at most N
  commands", N a shortest program's length), `loop_count` (squares a loop moves; a board picture from the loop's trail,
  turned a random quarter turn), `fix_the_bug` (one command changed; "step 2: TURN RIGHT" fixes it; the buggy trail
  drawn).

## Tests
- `tests/unit/test_school_content_g3_arts.gd` (written first; it failed until the units were): every unit written and
  problem-free, 4-8 cards, ≥ 12 hand-written exercises at levels 1-3 of two kinds or more, rounds that vary (over boards
  and sounds too) and never repeat a hand-written exercise; hints and worked answers; memory question first, the world
  last; the listening units' sounds; the units use their own `g3a` generators and every one is used; every
  "red and yellow make orange" is paint's truth; no prompt asks for personal details; the font draws "ë" and the unit
  names Saint-Saëns; every robot program (worked answers and choices) is run by RobotCheck; every rhythm to copy starts
  with a clap; every "mix" worked answer names exactly its recipe's paints.
- `tests/unit/test_g3_arts_gen.gd` (15 tests, about 20,000 asserts), `tests/integration/test_school_picture_arts.gd`
  (samples of every kind at the School's sizes, broken data, tints and shades).
- The units were built by a script (in this agent's scratch folder; the JSON files are now the source) that checked the
  limits, the words (kind, British, ASCII and the font's symbols), every sum and chain of sums, every paint fact, every
  sound's length, every answer about a sound worked out from the sound (claps counted, pitches compared, shapes found,
  gaps measured), every robot board solved and every program run, and every "copy the rhythm" box list.

- **The full suite** (`tests/run_tests.sh`, 2026-09-29 on this branch at 4d8822c): 753 scripts, 6,967 tests, 6,965
  passing, 0 failing, 2 risky that do not assert (`test_the_column_cache_changes_nothing`,
  `test_chunks_meet_without_seams`: world tests this branch does not touch), 1,931,707 asserts, 29 min 26 s; exit 0.

## Rulings (decide and write down; cost if wrong)
1. **One robot, one language.** The lead's "code the robot" type arrived mid-task, so everything robot uses RobotCheck's
   FORWARD, TURN LEFT and TURN RIGHT (a picture of a board looks like RobotAnswer's board); texts write a run of
   FORWARDs short ("FORWARD 3"), taught on a card. The first generator draft (absolute moves "right 3, up 2") was
   rewritten. *Cost:* none now; absolute moves later would be a second language.
2. **Loud and quiet are taught in words.** SchoolSound plays every note and clap at one loudness, so dynamics are read
   and matched, while tempo is heard (rhythm tempo and the tunes' `beat`). *Cost:* a loudness field in SchoolSound, then
   a few listening exercises.
3. **Instrument families are taught in words** (the School has one plucked tone and claps); only claps (body
   percussion) are heard. *Cost:* instrument sounds in SchoolSound.
4. **A rhythm never starts with a rest** (a rest before the first clap can't be heard, so two rhythms could sound the
   same). **Copy-the-rhythm boxes are half beats**, two to a beat (ta fills the first, ti-ti both, a rest none), as the
   rhythm type's pattern is; a reading-rhythms card says so. *Cost:* none.
5. **Rhythm names:** "ta", "ti-ti", "rest" (the Kodaly names many schools use) and the words "pear" and "ap-ple";
   British note names with the US names once in brackets; minims wait for grade 4 (the notation kind already draws
   them). *Cost:* none.
6. **Paint is the painters' red, yellow and blue** (RYB, as ColourMix). The lessons never claim a primary "can't be
   mixed" (magenta and yellow make a red); yellow with black is never called "dark yellow" (it turns olive); tints and
   shades use ColourMix's names (lilac, cream). *Cost:* none.
7. **Never colour alone** (spec §5.15): every piece of a pattern differs in shape as well as colour, and swatches show
   their names except where the name is the answer. *Cost:* none.
8. **Online safety uses the game's rules as it ships** (age rules are off, #69): the chat filter (no phone numbers,
   addresses, emails or links), MUTE, BLOCK, REPORT with ASKED SECRETS, STOP FOR TODAY. Nothing mentions the
   under-13 quick-chat-only rule. No exercise asks the child for anything personal (a test). *Cost:* a card if age rules
   return.
9. **People:** artists and composers of the past only (Leonardo da Vinci, van Gogh, Hokusai, Seurat, Saint-Saëns,
   Grieg, Rimsky-Korsakov); the web's inventor (living) is not named, only its year. *Cost:* none.
10. **The Carnival's tunes are our own sketches** in the School's tone (low and slow, a falling cuckoo call, hops, a
    smooth line); the cards say what the real pieces use (double bass, flute, cello, clarinet). *Cost:* none.
11. **"ë"** joins the content test's ALLOWED letters (the School draws with the engine's default font, which has it:
    `test_the_font_draws_saint_saens_name`). The shared test `test_generators_vary_with_the_seed` now counts a
    generator's sound as variety (a rhythm to copy is only its sound). *Cost:* none.
12. **Loops without a REPEAT key:** the robot type has no loop command, so loops are read and counted in text, and the
    robot exercises with repeating paths ask for "at most N commands" (the lead's suggestion). *Cost:* a REPEAT key in
    RobotAnswer would let children write loops.

## Merging (for the lead)
- Expected textual conflicts, all "keep both": `core/school/school_gen.gd` (the `g3a` line last in SOURCES),
  `ui/school/school_picture.gd` (the arts hooks right after the grade 3 maths ones: header, `problem`, `_draw`; keep the
  `return` after `SchoolPictureG3.draw`), `tests/unit/test_school_content.gd` (ALLOWED gains "ë"; the vary-with-seed key
  gains the sound), `data/school/grade3.json` (only computing, art and music `file` fields), `docs/DEVELOPMENT.md` (the
  Pictures bullet).
- This branch already contains `lead-school` up to 33562e1.

## What comes next (the School never ends, #71)
Grade 4 computing, art and music (research §6.4: events, conditions, variables, networks; the colour wheel, light and
shade, portraits; note values, the stave, the orchestra), instrument sounds and loudness in SchoolSound, a REPEAT key
for the robot, and the world links (a band stage, a gallery, a music corner) as in-world projects.
