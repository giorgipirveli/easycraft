# Grade 5 computing, art and design, and music: every unit written (owner #70, #73; 2026-09-29)

The owner: "start from grade 3 and finish all grades accordingly" and "research school programs, world leading schools
and create better school program". The research (`docs/design/school-curriculum-research.md` §6.5) lists grade 5's
Computing (11), Art and Design (9) and Music (9) units; this agent wrote all 29 (brief:
`docs/superpowers/plans/2026-09-29-school-subjects-brief.md`, GRADE = 5, SUBJECTS = computing, art, music), building on
grades 3 and 4 of the same subjects (`m8-grade3-arts.md`, `m8-grade4-arts.md`). Branch `worktree-agent-a3d0dff08250ebdef`,
from `lead-merge` b6800bf.

## What was written
| Subject | Units | Lesson cards | Hand-written exercises | Kinds of exercise | Generators used (`g5a`) |
|---|---|---|---|---|---|
| Computing | 11 | 88 | 157 | choice 59, number 36, true/false 27, sort 12, order 11, match 10, robot 2 | `trace_game`, `nested_count`, `pen_loop`, `call_count`, `bounce_sim`, `packet_count`, `rank_results`, `sheet_sum`, `chart_read`, `odd_shadow` |
| Art and design | 9 | 72 | 127 | choice 63, true/false 25, order 10, match 9, sort 9, number 9, mix 2 | `mosaic_tiles`, `column_order`, `building_facts`, `light_and_shadow`, `weave_next` |
| Music | 9 | 72 | 144 | choice 65, number 29, true/false 20, rhythm 13, match 8, order 6, sort 3 | `major_or_minor`, `build_chord`, `scale_steps`, `form_count`, `syllable_beats`, `composer_years`, `world_pattern`, `melody_beats`, `conduct`, `loop_time` |
| **All** | **29** | **232** | **428** | | 25 generators (`g5a`), each at levels 1-3 |

- **Files:** `data/school/g5/{computing,art,music}/<unit>.json`, linked from `data/school/grade5.json` (only these
  subjects' `file` fields, and one goal sharpened: music technology's "in the game's music maker" became "music (a step
  grid and tracks)", because the game has no music maker yet; ids, titles and standards kept).
- **Every unit:** 8 lesson cards, one idea each, opening with "Quick memory:" and a question whose answer is in brackets
  (often what grade 3 or 4 taught) and ending "Try it in the world: … Next: …" (research §5.3 rules 1, 7, 8); 13-16
  hand-written exercises at levels 1, 2 and 3 (at least 4, 5 and 5), of 3-7 kinds, each with a hint (a strategy, never
  the answer) and an explain (the worked answer).
- **Computing:** variables at work (score, lives, level; events change them, conditions read them; SET at the start;
  the SET-instead-of-CHANGE bug), loops inside loops (walls, clocks, pens drawing rows of squares; the indent says which
  loop; the robot up a walled staircase and along a zigzag, "at most N commands"), procedures (DEFINE and calls, calls
  inside loops and procedures calling procedures, the misspelt call), simulations (a plant's steady growth, a ball
  bouncing off the floor with an IF, gravity: the speed changes each step; rules checked against the real thing),
  remix and credit (licences, credit lines, saying what you changed; CC0 and this game's credits), how messages travel
  (packets with numbers and addresses, IP addresses, routers and routes, out of order and resent; copper, light and
  radio; undersea cables), how search engines rank (crawlers, the index, clues: words, title, links, new, language;
  adverts marked Ad or Sponsored; the top result checked), real or edited (clues: shadows, light, edges, copies; false
  captions, cropping, computer-made pictures, charts whose axis starts above 0, clickbait), spreadsheets (cells named
  B3, data with headings, =B2+B3, =SUM, =MAX, =MIN, B2*C2, formulas that work themselves out again, fair charts),
  people you meet online (anyone can be anyone; private details; warning signs; the game's MUTE, BLOCK and REPORT with
  ASKED SECRETS; never meet without a trusted adult; never your fault), technology for everyone (captions, screen
  readers, alt text, big text, high contrast, voice control and switches, colour blindness about 1 in 12 boys, Louis
  Braille, this School reading every card aloud).
- **Art and design:** one-point perspective (the vanishing point on the horizon at eye level, orthogonals, a road and
  a room, shrinking posts; Brunelleschi about 1415, Alberti 1435, Raphael's The School of Athens 1511), Greek and Roman
  art (Doric, Ionic and Corinthian capitals; black-figure and, from about 530 BC, red-figure pots; statues once painted;
  Roman copies and portraits; frescoes; Pompeii and Vesuvius AD 79; the Parthenon 447-432 BC), mosaics (tesserae,
  grout, andamento, planning on squared paper, counting tiles and borders; Ravenna, zellige), architecture (post and
  lintel, round arches and the keystone, the Pantheon's 43 m concrete dome, pointed arches, steel frames from Chicago
  in the 1880s; the Great Pyramid, the Taj Mahal, pagodas; plans), still life (arranging in odd numbers, one lamp,
  highlight, shadow side, cast shadow, reflected light, negative space; Rachel Ruysch, van Gogh's Sunflowers 1888,
  Cézanne's apple), abstract art (Kandinsky's colours like music and circles in squares, Mondrian's grids, Hilma af
  Klint from 1906, Klee; balance, contrast, rhythm; mixing green and purple), textile art (plain weave, twill and
  denim, basket weave; indigo, madder, weld, cochineal; tie-dye, bandhani, shibori, batik; kente; the Bayeux Tapestry,
  about 70 m, 1066), illustration and comics (panels, gutters, speech and thought bubbles, captions, sound words,
  wide shots and close-ups; Hokusai's manga 1814), develop an idea (sketchbooks, Leonardo's notebooks, thumbnails,
  changing one thing at a time, feedback, looking back).
- **Music:** major and minor (the third: 4 or 3 semitones; tones and semitones; the major scale's T T S T T T S on the
  white keys from C; A minor's T S T T S T T), chords (root, third, fifth by skipping letters; C, F, G, Am, Dm, Em;
  C F G C; broken chords), how songs are built (sections as letters; binary, ternary, rondo, Für Elise; verse, chorus,
  bridge, intro, outro; forms heard as phrases), write a song (a note per syllable, strong syllables on strong beats,
  rhymes, the chorus and its hook, ending on the home note), great composers (the Baroque and Classical periods; Bach
  1685-1750, Handel 1685-1759, Haydn 1732-1809, Mozart 1756-1791 (and Vivaldi 1678-1741); fugues, Water Music, 104
  symphonies, the Surprise Symphony's tune, Mozart's variations on Twinkle, Twinkle; the harpsichord), rhythms of the
  world (polyrhythm, the djembe, bell patterns, call and response; samba's surdo and the leader's whistle; gamelan's
  cycles and gong; 3 + 3 + 2; layers), reading melodies (pitch and rhythm; semibreve to quaver; time signatures and bars;
  steps and leaps; E G B D F and F A C E; reading in four stages), playing together (the pulse, the conductor, beat
  patterns in 2, 3 and 4, downbeat and upbeat, adagio, andante, allegro), music technology (microphones and
  waveforms, loops, step sequencers, tracks and layers, trimming and fading, beats and seconds, safe headphone volume).
- **Listening:** 53 music exercises and 15 lesson cards carry a sound (tunes, chords or claps); the eight listening
  units have 6 or more each (the test: `test_the_music_units_let_you_listen`).

## New and grown code
- **SchoolSound plays chords** (`core/school/school_sound.gd`): 2-4 note names joined by "+" sound together
  ("C4+E4+G4:2", two beats), each note a little softer (0.61, 0.5, 0.43 of a note alone) so a chord never clips.
  `tests/unit/test_school_sound.gd` (`test_a_chord_is_notes_played_together`). Major and minor, chords and the "same or
  different chords" exercises use it.
- **27 picture kinds** in `ui/school/school_picture_g5arts.gd` (`SchoolPictureG5Arts`, hooked into `SchoolPicture` after
  the grade 4 life kinds; its header lists every field): `pen` (a pen on squared paper runs the program: FORWARD n, TURN,
  PEN UP/DOWN, REPEAT, DEFINE and calls; `trace()` must stay on the paper and draw something), `var_boxes`, `sim_frames`
  (a ball or a plant step by step), `packets` (`packets_of()`: a message cut into numbered envelopes, maybe arriving in a
  muddle), `search_page` (results with Ad tags), `shadow_photo` (shadows fall away from the sun; `odd` is pasted in),
  `column_chart` (an axis that may start above 0), `sheet` (a spreadsheet; `value()` works out =SUM/MAX/MIN(B2:B5),
  =B2+C2, =B2-C2, =B2*C2, through other formulas; a formula bar for the marked cell; `show: "formulas"` for questions),
  `chat`, `access_feature` (captions, read aloud, big text, high contrast, voice, alt text), `perspective` (road, room,
  rails; the vanishing point, the horizon, the lines to the point), `greek_column`, `greek_vase`, `mosaic` (tiles in
  grout), `building` (pyramid, Parthenon, Pantheon, aqueduct, cathedral, Taj Mahal, pagoda, skyscraper, post and lintel,
  round and pointed arches), `still_life` (shading layered towards the light, cast shadows, labels), `abstract` (grid,
  shapes, circles; 4 variants), `dye` (tie-dye rings and spiral, batik, tied cloth), `comic` (panels, captions, speech
  and thought bubbles, sound words, wide, medium and close shots), `keyboard` (marked keys, letters, T and S between
  marked notes; `scale` says what a marked scale is), `chord_stave` (chords stacked on the treble stave, named),
  `song_form`, `lifespans`, `beat_grid` (a step grid with 1 & 2 & counts), `beat_pattern` (the conductor's patterns),
  `tracks` (clips on a music maker's timeline, a loop shaded), `waveform` (a recording, the part kept by trimming).
  Samples, broken data and the facts (the pen's path, the formulas, the packets, quavers and dotted minims) in
  `tests/integration/test_school_picture_g5arts.gd`.
- **Grade 4's kinds grown** (`ui/school/school_picture_g4arts.gd`): the `stave` gains `quaver` (half a beat, with its
  flag) and `dotted minim` values (the bars are counted in half beats: `VALUE_HALVES`) and `words` (a syllable under each
  note); the `code` picture gains DEFINE blocks (purple, a hat and a bar for its lines) and their calls (a line that is
  only a procedure's name, in the same purple), and its marked line now has an orange pointer as well as its border (a
  thin border alone was hard to see at exercise size). Grade 4's broken-sample test now uses a semiquaver (a quaver is
  allowed).
- **Generators** `core/school/gen/g5_arts_gen.gd` (`G5ArtsGen`, SchoolGen source `g5a`, the last SOURCES line): 25,
  seeded, levels 1-3, each with a strategy hint, a worked answer and `data`. `tests/unit/test_g5_arts_gen.gd` (26 tests)
  works every answer out again with its own interpreter (SET, CHANGE by a number or a variable, REPEAT, IF with ELSE,
  DEFINE and calls; how many times each line runs), its own pen length, spreadsheet evaluator, search ranking, weave
  rules, chord and scale semitones, phrase forms, syllables and rhymes, the composers' years, beat grids, note values,
  conducting directions and track bars; a wrong pen drawing must differ from the right one (SchoolPictureG5Arts.trace).

## Tests
- `tests/unit/test_school_content_g5_arts.gd` (written first; it failed until the units were written; 18 tests):
  every unit written and problem-free, 4-8 cards, ≥ 12 hand-written exercises at levels 1-3 of two kinds or more,
  rounds that vary and never repeat a hand-written exercise, hints and worked answers, memory first and the world
  last, the eight listening units' sounds, the units use their own `g5a` generators and every one is used; and the
  facts: every "the C major chord is C, E and G" and every named chord on a chord stave by semitones (major third 4,
  minor 3, fifth 7); every "major or minor?" by ear from its sound (a chord's third, or a tune's third above its home
  note, never both); every 8-note keyboard scale by its tones and semitones; every stave read by its letters; every
  "how many beats" by the notes (quaver ½, dotted minim 3); every "how many times does the marked line run" by running
  the code (loops inside loops, procedures); every "what will B5 show" by the test's own spreadsheet; every composer's
  years (Vivaldi, Bach, Handel, Haydn, Mozart, Beethoven) in the texts and the lifespans pictures; every robot program
  run by RobotCheck; rhythms that start with a clap; no prompt asks for personal details.
- `tests/unit/test_g5_arts_gen.gd`, `tests/unit/test_school_sound.gd`, `tests/integration/test_school_picture_g5arts.gd`.
- The units were built by scripts in this agent's scratch folder (the JSON files are now the source) that checked the
  limits, the words (kind, British, no brands, other games or living people, the School's letters), every sum and chain
  of sums, paint mixes, stave letters and beats, every code picture's variables and marked lines by running them,
  every pen program on its paper, every spreadsheet formula, every chord and scale by semitones, every major or minor
  sound, the composers' years, robot boards (solved; every program in a choice run) and rhythms.
- **Looked at:** every new kind in contact sheets at the School's three sizes, then all 29 units in the School's own
  screenshots (`tools/school_shots.gd -- --unit=… --exercises`, a window; no editor or emulator). Fixed from what they
  showed: the search box's query was white on white, shadows were thin lines (now flat ellipses), a pointed arch was
  round at its top (now two arcs of twice the half-width, an equilateral arch), the room's walls did not meet at the
  vanishing point (the back wall is now the frame shrunk towards it), the Pantheon's dome was a tall blob (now low on
  its drum), the Taj Mahal's dome floated (now on a drum), the spiral dye spilled off the cloth, comic tails were long
  lines and thought clouds broke up, the conductor's patterns crossed themselves (now one path through the beats, the
  last beat at the top), the captions' speaker got a face, and a flat still life drew an ellipse round a bottle. From
  the School's screenshots (about 1,950 of them, 66-74 a unit, no script errors): the code picture's marked line got its
  pointer, a simulation's ball stays inside its frame, a crowded chart axis numbers every other line (and Tilly's block
  chart uses even numbers), mosaic tiles keep their colour so white stays white, still-life objects are bigger in small
  choice pictures, the marked horizon is thicker, a 16-step beat grid gets taller boxes, a choice between two
  unlabelled all-orange keyboards (unreadable) became "read this scale's steps: major or minor?", and the song line's
  last note is a minim, as it sounds.

- **The full suite** (`tests/run_tests.sh`, 2026-09-29 on this branch at eb4f378, from `lead-merge` b6800bf): 794
  scripts, 7,334 tests, 7,332 passing, 0 failing, 2 risky world tests that do not assert
  (`test_the_column_cache_changes_nothing`, `test_chunks_meet_without_seams`, as before), 2,440,655 asserts, 36 min;
  exit 0. After it, one word only (textile art: yellow from "the weld plant", not only its flowers), and the School's
  tests were run again.

## Rulings (decide and write down; cost if wrong)
1. **Chords are notes sounding together in SchoolSound** ("C4+E4+G4:2"), not only broken chords: a chord is heard as
   one sound, which is what grade 5's chords and major and minor units teach. *Cost:* none; old sounds are unchanged.
2. **Major or minor is decided by the third above the home note** (4 semitones major, 3 minor), and every "major or
   minor?" tune starts on its home note and has that third (a test). The moods are "often bright" and "often darker or
   sad", never "always". *Cost:* none.
3. **Scales and chords stay on white keys where they can** (C major, A minor; C, F, G, Am, Dm, Em), with E flat, F
   sharp, B flat and C sharp only where a scale needs them (the `scale_steps` generator's level 3). *Cost:* none.
4. **The game has no music maker yet**, so music technology teaches recording, loops, step grids, tracks and editing
   with pictures of them and the School's own rhythm grid; the goal was sharpened to say so. *Cost:* a card or two when
   a music maker (the roadmap's music blocks) exists.
5. **Loops and procedures are written in the School's block language** (REPEAT n TIMES, DEFINE name, a call is the
   name alone) and drawn by a pen on squared paper. The robot still has no REPEAT key, so loops appear as "at most N
   commands" and as unrolled programs (the stairs, the zigzag, corner, corner). *Cost:* a REPEAT key in RobotAnswer.
6. **People:** artists, composers, architects and inventors of the past only (Brunelleschi, Alberti, Raphael, Rachel
   Ruysch, van Gogh, Cézanne, Kandinsky, Mondrian, Hilma af Klint, Klee, Hokusai, Leonardo, Louis Braille, Vivaldi,
   Bach, Handel, Haydn, Mozart, Beethoven). No brands: "a search engine", "a spreadsheet", "music software". *Cost:*
   none.
7. **Online safety uses the game's own buttons** as they ship (MUTE, BLOCK, REPORT with ASKED SECRETS); nothing asks a
   child for personal details (a test); "never meet without a trusted adult"; "it is never your fault". *Cost:* a card
   if the buttons change.
8. **Composers' ages:** "how many years did he live" is only asked for composers whose birthday came before the day
   they died in their last year (Vivaldi, Bach, Handel, Haydn, Mozart), so died − born is their age; birth-year gaps are
   asked as "how many years after". *Cost:* none.
9. **Samba, West African and gamelan patterns are shown as illustrations of how the music works** (a surdo on the
   second beat, a bell pattern, layers), not as transcriptions of named pieces. *Cost:* none.
10. **The Surprise Symphony's tune and Twinkle, Twinkle** (Mozart's variations) are played as public-domain tunes; the
    surprise chord itself is told, not played (SchoolSound has one loudness). *Cost:* a loudness field in SchoolSound.

## Merging (for the lead)
- A dry run against `lead-merge` ccbbdf6 (`git merge-tree`, nothing changed) conflicts in two files only, both "keep
  both": `ui/school/school_picture.gd` (the grade 5 arts hooks next to the grade 4 core ones, each with its `return`)
  and `core/school/school_gen.gd` (`g5a` and the grade 5 humanities' `g5h` both at the end of SOURCES);
  `data/school/grade5.json` and `docs/DEVELOPMENT.md` merge by themselves.
- After the merge, add `"G5Arts": SchoolPictureG5Arts.KINDS` to `tests/unit/test_school_picture_kinds_unique.gd` (new on
  `lead-merge`). None of the 27 kinds here is used by another file on `lead-merge` ccbbdf6 (checked by name against
  grade 4 core's, the history, grade 5 maths and every older kind).
- Shared files changed here beyond the new ones: `core/school/school_sound.gd` (chords), `ui/school/school_picture_g4arts.gd`
  (stave values and words, code DEFINE and the mark's pointer), `tests/integration/test_school_picture_g4arts.gd` (the
  broken sample is a semiquaver now), `tests/unit/test_school_sound.gd` (the chord test).
- Not done here, for the lead: the plan's outline (`python3 tools/school_outline.py --write
  docs/superpowers/plans/2026-09-28-school.md`) after the merge, and spec §22.4c's as-built line for grade 5.

## What comes next (the School never ends, #71)
Grade 6 computing (binary, pixels, Boolean logic, pseudocode, data types, spreadsheet models, AI), art (elements and
principles, world art 500-1500, tessellations, two-point perspective, lettering) and music (scales and keys, intervals,
the blues, early music, syncopation, theme and variations); a REPEAT key for the robot; loudness and instrument sounds
in SchoolSound (the Surprise chord, accents, layers heard together); a music maker in the game (step grid and tracks)
for the music technology unit; world links: a Greek temple and a mosaic floor to build, a gallery of still lifes and
abstract walls, a samba band stage.
