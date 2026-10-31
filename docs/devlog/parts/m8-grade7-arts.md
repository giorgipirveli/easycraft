# Grade 7 computing, art and design, and music: every unit written (owner #70, #73; 2026-09-30)

The owner: "start from grade 3 and finish all grades accordingly" and "research school programs, world leading schools
and create better school program". The research (`docs/design/school-curriculum-research.md` §6.7) lists grade 7's
Computing (11), Art and Design (9) and Music (9) units; this agent wrote all 29, following the reusable brief
(`docs/superpowers/plans/2026-09-29-school-subjects-brief.md`, GRADE = 7, SUBJECTS = computing, art, music), one step up
from grade 6 (`m8-grade6-arts.md`: pseudocode, binary, passwords; principles, world art 500-1500, prints, lettering;
scales, intervals, the blues). Branch `worktree-agent-af8d20a2e30288eb0`, from `lead-merge` at 09ac5d3a.

## What was written
| Subject | Units | Lesson cards | Hand-written exercises | Kinds of exercise | Generators used (`g7c`) |
|---|---|---|---|---|---|
| Computing | 11 | 88 | 174 | choice 70, number 57, true/false 30, order 6, match 5, sort 5, label 1 | `text_output`, `syntax_error`, `list_item`, `list_loop`, `function_value`, `linear_checks`, `binary_checks`, `bubble_step`, `merge_step`, `test_data`, `ip_address`, `route_hops`, `caesar_word`, `clean_data`, `validate_entry`, `habit_check`, `public_domain`, `licence_use` |
| Art and design | 9 | 72 | 144 | choice 76, true/false 26, number 19, match 8, label 6, order 6, sort 3 | `scheme_pick`, `head_heights`, `scale_drawing`, `thirds_place`, `block_print`, `art_dates` |
| Music | 9 | 72 | 148 | choice 87, number 25, true/false 16, match 7, rhythm 7, order 3, sort 2, label 1 | `primary_chord`, `cadence_ear`, `ornament_play`, `era_facts`, `bass_note`, `dotted_beats`, `riff_repeat`, `film_cue`, `mix_balance`, `song_length`, `folk_metre` |
| **All** | **29** | **232** | **466** | | 35 generators (`g7c`), each at levels 1-3, in 27 units (graphic design and the portfolio have hand-written practice only) |

- **Files:** `data/school/g7/{computing,art,music}/<unit>.json`, linked from `data/school/grade7.json` (only these
  subjects' `file` fields, and folk music's `"hard": "work songs of enslaved people in the Americas"` for the grown-ups'
  page; ids, titles, goals and standards kept).
- **Every unit:** 8 lesson cards, one idea each, opening with "Quick memory:" and a question whose answer is in brackets
  (grade 4, 5 or 6, or an earlier grade 7 unit) and ending "Try it in the world: … Next: …" (the last unit of each
  subject names grade 8's first); 15-18 hand-written exercises at levels 1, 2 and 3 (at least 4 each), of 3-6 kinds,
  each with a hint (a strategy, never the answer) and an explain (the worked answer).
- **Computing:** from blocks to text (print, = and ==, if/else with colons and 4-space steps, for and range, syntax
  errors found by line), lists (indexes from 0 and -1, len, append, changing an item, loops for a total, a count, the
  biggest, the index error), functions with parameters (def, arguments into parameters in order, return versus print,
  calls inside calls, local variables), searching (linear, binary on a sorted list with the middle rounded down, at most
  10 checks for 1,000 items and 20 for 1,000,000), sorting (bubble sort's passes and swaps, merge sort's splits and
  merges, John von Neumann 1945), testing (syntax, runtime and logic errors; test plans; normal, boundary and erroneous
  data; the bug at the edge; one fix at a time), how the internet works (ARPANET's LO in 1969, IP addresses, the DNS,
  packets and routers, a lost packet, protocols TCP/IP, HTTP and HTTPS, the web on the internet), secret codes (the
  Caesar cipher both ways, 25 keys, al-Kindi's letter counts, Turing and Bletchley Park, long keys and public keys, a
  PIN's 100,000 codes), collecting and cleaning data (forms and sensors, closed and open questions, presence, type,
  range, length and format checks, slips, copies, gaps and spellings, a mean before and after), wellbeing online (how
  feeds keep you scrolling: endless scroll, autoplay, notifications, likes and rewards that come now and then;
  comparison; habits you choose; the 20-20-20 rule; telling a grown-up), copyright and sharing (copyright from the
  moment a work is made, 70 years after the creator's death to the end of that year, the public domain, the Statute of
  Anne 1710, Creative Commons CC0, BY, SA, NC and ND, full credits, plagiarism, fair dealing, this game's CC0 assets).
- **Art and design:** Renaissance art (Florence, Brunelleschi's perspective about 1415, Masaccio's Holy Trinity about
  1427, Raphael's School of Athens and its vanishing point, Leonardo's Vitruvian Man, chiaroscuro and sfumato, the Mona
  Lisa 1503, van Eyck's oil glazes and the Arnolfini Portrait 1434, Michelangelo's David and the Sistine ceiling),
  colour harmony (complementary, analogous, triadic, split-complementary, monochrome, warm and cool, mood and value,
  Itten at the Bauhaus), drawing people (the 8-head figure and its landmarks, children's proportions, arm span, gesture
  sketches and the line of action, mannequins of shapes), world art 1450-1750 (Akbar's workshops and Mughal miniatures,
  Jahangir's nature studies, ukiyo-e and Hishikawa Moronobu, the print's team, Iznik tiles and their colours and
  flowers, the Blue Mosque's 20,000 tiles, Chinese blue-and-white, art along trade routes), graphic design (logos that
  work tiny and in one colour, hierarchy, grids, margins, white space, typefaces), designing buildings (plans, front and
  side elevations, symbols, scale drawings at 1:100, 1:50 and 1:20, area, Wren's Great Model at 1:25), composition (the
  rule of thirds and its crossings, horizons, leading lines, framing, viewpoint, the game's photo mode), woodcut prints
  (relief printing, the mirrored print, gouges and safety, the key block, kento and baren, editions, Dürer's Rhinoceros
  1515), curating a portfolio (choosing, arranging, photographing, labels, an artist's statement, hanging at 1.5 m, kind
  and specific feedback).
- **Music:** chord progressions (triads on every degree, I, IV and V, perfect, plagal and imperfect cadences heard,
  I-V-vi-IV, the chord that fits a note, in C, G, F and D), Baroque music (terraced dynamics heard as an echo, basso
  continuo, ground bass heard and Pachelbel's 8 notes, trills, mordents and turns, Vivaldi's concertos and Four Seasons
  1725, Bach's fugues, Handel's Messiah 1741), the Classical era (question and answer phrases heard, the piano, the
  Alberti bass heard and on the bass clef, the four-movement symphony, sonata form, Haydn's 104, Mozart's 41,
  Beethoven's nine, the Fifth and Ode to Joy heard), how popular music is built (sections, hooks, riffs, the drum kit
  and backbeat, the band, rock and roll, hip-hop in the Bronx in the 1970s, tempo in beats a minute), riffs and hooks
  (the pentatonic scale, repeating and changing a riff, moving it with the chords, hooks, layers), film music (mood,
  leitmotifs and Wagner, Peter and the Wolf's instruments, hero and villain themes heard, tension, a theme changed to
  minor, diegetic music, silent films), performing together (parts, balance heard in and out of balance, the mixing
  desk, count-ins, dynamics, rounds), the bass clef (the F clef, G B D F A and A C E G, middle C, the grand stave, dotted
  notes, ties and slurs, heard), folk music (by ear, work songs and call and response heard, enslaved people's songs and
  what grew from them, sea shanties, celebration music of five places, jigs and reels, drones heard, Cecil Sharp and Bela
  Bartok).
- **Listening:** 58 music exercises and 28 lesson cards carry a sound; every music unit has 6 or more exercises to
  listen to (`test_the_music_units_let_you_listen`: "notes" in six units, any sound in popular music, performing
  together and folk music).

## New and grown code
- **SchoolSound's parts** (`core/school/school_sound.gd`): a tune may have `parts`, 1-3 more tunes `{notes, volume?,
  tone?}` played together from its start at its beat (a melody over a quieter bass, a ground bass, an Alberti bass, a
  drone, a riff under a tune, a mix out of balance), every voice a little softer so the sum never clips; the sound lasts
  as long as its longest part; `"-:n"` is n beats of rest. Old sounds are unchanged. `test_school_sound.gd`
  (`test_parts_play_together_with_the_tune`: problems, duration, a part's own volume, no clipping with a chord over two
  parts).
- **27 picture kinds** in `ui/school/school_picture_g7arts.gd` (`SchoolPictureG7Arts`, hooked into `SchoolPicture` after
  `SchoolPictureG6Health`; its header lists every field): `text_code`, `list_boxes`, `func_machine`, `search_steps`,
  `sort_bars`, `internet_trip`, `cipher_wheel`, `data_sheet`, `phone_feed`, `licence_tags`, `old_master`,
  `colour_scheme`, `figure_study`, `world_art_piece`, `poster_layout`, `house_drawing`, `thirds_frame`, `carved_block`,
  `gallery_wall`, `chord_chart`, `ornament_signs`, `symphony_plan`, `drum_kit`, `piano_roll`, `film_strip`, `mixer`,
  `clef_stave`. The facts they share with the tests: `search_checks`, `bubble_after`, `merge_rows`, `route_hops`,
  `caesar`, `scheme_colours`, `chord_name`, `chord_letters`, `ornament_notes`, `on_thirds`, `power_point`,
  `print_rows`, `clef_step`, `HOUSE`; `part_at(picture, part, size)` for label pins (the phone, the drum kit, the
  poster, the 8-head figure, the house's plan and front, the Mughal page, the Iznik tile, the Japanese print). Samples,
  broken data and the facts in `tests/integration/test_school_picture_g7arts.gd`.
- **The tests' text-code runner** `tests/fakes/text_code_runner.gd` (not part of the game): a small interpreter for the
  School's text code, with Python's rules for what it prints (3.5, 3.0, True, [1, 2]) and the line each error stops
  on (a block's missing step in is reported on the line that should step in, as Python does).
- **Generators** `core/school/gen/g7_arts_gen.gd` (`G7ArtsGen`, SchoolGen source `g7c`, the last SOURCES line): 35,
  seeded, levels 1-3, each with a strategy hint, a worked answer and `data`. `tests/unit/test_g7_arts_gen.gd` (23
  tests) works every answer out again: programs by the runner, and its own search, sort, test-data, IP, route, cipher,
  cleaning, validation, feed, copyright, licence, wheel, heads, scale, thirds, print, dates, chord, cadence, ornament,
  period, bass clef, beats, riff, film, mix, tempo and metre rules.

## Tests
- `tests/unit/test_school_content_g7_arts.gd` (written first; it failed with 25 failures until the units were written;
  29 tests): every unit written and problem-free, 4-8 cards, ≥ 12 hand-written exercises at levels 1-3 of two kinds or
  more, rounds that vary and never repeat a hand-written exercise, hints and worked answers, memory first and the world
  and Next last, the nine music units' sounds, the units use their own `g7c` generators and every one is used, no prompt
  asks for personal details, every label's line ends on its part; and the facts, with this test's own tables and rules:
  every program in a picture runs as its picture shows (its output panel, its marked mistake's line), every "What does
  it print?", "What is x when it ends?" and "Which line stops it?" run by the runner, list items and lengths, linear
  and binary checks and "at most N checks for M items", bubble passes and swaps, Caesar statements both ways and cipher
  pictures, every IP address an example one, copyright's died-in and free-from years, "X and Y are complementary",
  analogous and triads and every scheme picture, scale-drawing statements, thirds judged, mirrored prints, the people's
  years (33 people), "Chord IV in G major is C" and "The C major chord is C, E and G", a hidden chord on a chart,
  cadences heard, the bass clef's lines and spaces and every bass note asked, "a dotted minim lasts 3 beats" and ties
  and every beat count, the tempo's seconds, the loudest fader, the symphonies' numbers, rhythms to copy, and ornaments'
  notes.
- `tests/unit/test_g7_arts_gen.gd`, `tests/unit/test_school_sound.gd`, `tests/integration/test_school_picture_g7arts.gd`;
  the shared `test_school_content.gd` (every generator valid at every level for 120 seeds, varied, used; kind, British,
  English words; the sums in the lessons) and `test_school_picture_kinds_unique.gd` pass with the new files.
- The units were built by scripts in this agent's scratch folder (the JSON files are now the source) that checked the
  limits, the words (kind, British, no other games), every sum, and ran **every text program with real Python**
  (outputs, variables, the line a mistake stops on) before the runner re-checked them in GDScript; they also placed each
  label's pins beside the drawing, at least 58 px apart, with lines to the parts by the pictures' own geometry.
- **Looked at:** every picture the units use in contact sheets at the exercise size (206 pictures, and 16 choice
  pictures at the choice size), the samples at every kind, and the School's own screens (`tools/school_shots.gd`, a
  window; no editor or emulator) for two units, from blocks to text and world art 1450-1750 (about 90 shots: every lesson
card, and every exercise before and after its worked answer). Fixed from what
  they showed: the woodcut print view mirrored its rows a second time (a choice showed the block, not its print: the
  print view now draws its rows as the print), the DNS lookup's messages overlapped (now numbered arrows and the steps
  listed below), the phone's likes sat off the phone (it now spans 0.2-0.5 across so its parts land on it), the School
  of Athens' floor lines left the card, the time signature touched the bass clef's dots, the grand stave was tiny, the
  Japanese print's face vanished into the paper, the tree frame spilled out of the photo, a label was clipped, and short
  programs now use bigger rows.
- **The full suite** (`tests/run_tests.sh`, 2026-09-30 on this branch): see the last section.

## Facts checked, with sources
The first 14 rows were checked on the web on 2026-09-30 (the facts least often taught); the rest are standard reference
facts, cited to where they can be checked.

| Fact | Source |
|---|---|
| Hishikawa Moronobu (1618-1694), first great master of ukiyo-e | Britannica, "Hishikawa Moronobu" |
| The Blue Mosque built 1609-1616, more than 20,000 Iznik tiles | Blue Mosque (bluemosque.tr); Architectuul, "Blue Mosque" |
| Iznik's bole red about 1555-1560, first in tiles at the Süleymaniye (1557); cobalt, turquoise, green; tulips, carnations, saz leaves | Ashmolean, "Iznik Pottery: Peak (1560-1600)"; Qatar Museums, "Inscribed Iznik Tiles" |
| Masaccio's Holy Trinity about 1425-1427, among the first paintings in linear perspective | Basilica of Santa Maria Novella (smn.it); Smarthistory/Lumen "Masaccio's Holy Trinity" |
| Brunelleschi's Baptistery panel about 1415 (dates range c. 1401-1425) | WebExhibits, "The Arrow in the Eye", ch. III |
| Full-colour prints (nishiki-e) from 1765, Suzuki Harunobu | Britannica, "Nishiki-e" |
| Vivaldi's Four Seasons printed in Amsterdam in 1725 (Op. 8) | Britannica, "The Four Seasons" |
| ARPANET's first message, 29 October 1969: "LO", the computer crashed before LOGIN | Leonard Kleinrock, UCLA (lk.cs.ucla.edu/internet_first_words.html); Poynter |
| UK copyright: 70 years from the end of the calendar year the author dies | Copyright, Designs and Patents Act 1988 s. 12 (legislation.gov.uk); The National Archives |
| Dürer's Rhinoceros 1515, from a letter and sketch from Lisbon; he never saw it | Natural History Museum, "The legacy of Dürer's Rhinoceros"; National Gallery of Art |
| Peter and the Wolf (1936): bird flute, duck oboe, cat clarinet, grandfather bassoon, wolf three horns, Peter strings | Peter and the Wolf (Prokofiev's own programme), orchestra notes (e.g. Lansdowne SO listening guide) |
| Wren's Great Model of St Paul's (1673-1674), a design, at 1:25, to walk through at eye level | St Paul's Cathedral (stpauls.co.uk); Britannica, "Christopher Wren" |
| al-Kindi (801-873) and frequency analysis, the oldest known book on cryptology | Britannica/Wikipedia "al-Kindi"; 1001 Inventions |
| Cecil Sharp (1859-1924), English and Appalachian folk song collector (1916-1918) | English Folk Dance and Song Society (efdss.org) |
| Leonardo (1452-1519), Mona Lisa begun 1503; Raphael (1483-1520), School of Athens 1509-1511; Michelangelo (1475-1564), David 1501-1504 (5.17 m), Sistine ceiling 1508-1512; van Eyck (about 1390-1441), Arnolfini Portrait 1434; Dürer (1471-1528) | Britannica, each artist's article; the National Gallery, London (Arnolfini Portrait) |
| Akbar (1542-1605, emperor from 1556) and the imperial workshops; Jahangir (1569-1627) and nature studies; the Mughals from 1526; the Taj Mahal begun 1632 by Shah Jahan | The Met, Heilbrunn Timeline "Art of the Mughal Period"; V&A, "Mughal painting" |
| Itten (1888-1967) taught colour at the Bauhaus | Bauhaus-Archiv / Britannica "Johannes Itten" |
| Bach (1685-1750), Handel (1685-1759, Messiah 1741), Vivaldi (1678-1741), Purcell (1659-1695), Pachelbel (1653-1706) and the Canon's ground bass D A B F# G D G A | Britannica, each composer; the Canon's score (IMSLP) |
| Haydn (1732-1809) 104 symphonies; Mozart (1756-1791) 41 numbered; Beethoven (1770-1827) nine, the Fifth 1808, the Ninth 1824 | Britannica, each composer |
| Wagner (1813-1883) and leitmotifs; Prokofiev (1891-1953); Bartók (1881-1945) collected Hungarian and Romanian folk music | Britannica |
| Julius Caesar (100-44 BC) and his cipher; Turing (1912-1954) and Bletchley Park's Enigma work | Britannica; Bletchley Park (bletchleypark.org.uk) |
| The Statute of Anne 1710, Britain's first copyright law | The British Library / UK IPO history |
| Merge sort described by John von Neumann in 1945; binary search's worst case ⌊log₂ n⌋ + 1 checks | Knuth, The Art of Computer Programming vol. 3 |
| Hip-hop's start at Bronx block parties in the 1970s | Smithsonian National Museum of African American History and Culture |
| The 20-20-20 rule (20 feet is about 6 m) | NHS / American Academy of Ophthalmology eye-strain advice |
| Reserved example addresses 192.0.2.x, 198.51.100.x, 203.0.113.x (RFC 5737), private 192.168.x.x and 10.x (RFC 1918), `.example` names (RFC 2606) | IETF RFCs |

Every sum, program, cipher, chord, scale, beat count and tempo in the units was worked out by the build scripts and
again by the tests (above).

## Rulings (decide and write down; cost if wrong)
1. **Text code is a Python-like subset, and no language is named** (a language's name is a trademark; the brief says
   no brand names): print, =, ==, if/elif/else with colons, 4-space steps, for over range or a list, while, def and
   return, lists with append, len, max, min, sum. Everything a unit shows runs in real Python with the output it says.
   *Cost:* a card naming the language, if the owner wants it named.
2. **The game never runs code**: the interpreter is the tests' (`tests/fakes/`), and children read, trace and fix code
   with choices and the number pad (phones have no good keyboard, research §5.3). *Cost:* an in-game code editor later
   needs its own interpreter.
3. **Boundary data is the range's edges only**; values just outside are called erroneous (exam boards differ: some call
   them boundary too), so the School never asks about "just outside". *Cost:* a card if the owner wants the wider
   meaning.
4. **Binary search's middle is (low + high) ÷ 2 rounded down**, and its worst case ⌊log₂ n⌋ + 1 checks (1,000 items: 10;
   100: 7). *Cost:* none (rounding up is the other convention; only "which is checked first" would change).
5. **Copyright is taught with the UK and many countries' rule** (70 years after death, to the end of that year); other
   countries' terms are not taught. *Cost:* a card.
6. **Creative Commons is named** as the licence system (CC0, BY, SA, NC, ND are how shared work is labelled online), and
   linked to this game's own CC0 assets. *Cost:* call it "open licences" if the owner prefers.
7. **Only example IP addresses and `.example` names** appear (a test), so no real computer or site is named. *Cost:*
   none.
8. **Wellbeing names no app and no brand**; the game's own words rule out "streak", so the reward trick is taught as
   rewards that come now and then; the unit says the School has no timers and the game no random prize boxes (true of
   both; the game does have a rocket's launch countdown, so "no countdowns" is not claimed). *Cost:* none.
9. **Hard history, with respect:** folk music names the work songs of enslaved African people in the Americas and what
   grew from them (spirituals, the blues, gospel), in one card and one exercise, with no detail of suffering; the
   outline's `hard` field lists it on the grown-ups' page. *Cost:* none.
10. **People of the past only** (33 named with years in the test's table), no living musician, band, artist or
    designer; hip-hop and rock are taught through what they are, not who; the tunes heard are our own or long free
    (Ode to Joy, Beethoven's Fifth, Pachelbel's ground bass). *Cost:* none.
11. **Religion as culture:** the Holy Trinity fresco, Messiah, a hymn's Amen cadence, the Blue Mosque and St Paul's are
    named as the art, music and buildings of their places. *Cost:* none.
12. **Drawing people uses clothed mannequin figures** and the artist's 8-head canon (real grown-ups 7½-8), a young child
    6 heads and a baby 4; nothing about bodies changing as they grow (research §5.4 rule 4). *Cost:* none.
13. **Ornaments:** a trill starts on the note above (Baroque practice) and a mordent is read the modern way (the note,
    the one above, the note). *Cost:* a card on the lower mordent and the older signs.
14. **Balance is heard with SchoolSound's parts**, not recordings; a part is never louder than the main tune, so "the
    chords drown the tune" puts the chords in the main tune and the tune in a quiet part. *Cost:* a per-part gain above
    1 later.
15. **Composing is a "try it in the world" task** (riffs, hooks, a round), practised in the School by hearing, reading
    piano rolls and moving riffs; there is no composing exercise type yet. *Cost:* a piano-roll editor exercise later.
16. **Graphic design and the portfolio have no generator**: what they practise is judging and naming, and 16
    hand-written exercises each vary the rounds (grade 6 did the same for four art units). *Cost:* a generator each.
17. **`carved_block`'s print view draws its rows as the print** (a choice picture shows exactly what its data says);
    `print_rows` is the block-to-print rule the pictures, generators and tests share. *Cost:* none.
18. **A new generator source `g7c`** (grade 7's other sources are `g7n` and `g7g`; the grade 7 humanities agent is
    expected to use another letter). *Cost:* a rename if the lead's merge finds a clash.

## Merging (for the lead)
- Expect "keep both" conflicts where the grade 7 humanities agent also adds lines: `ui/school/school_picture.gd` (the
  grade 7 arts hooks after the grade 6 health ones, each with its `return`, and the header's kind list),
  `core/school/school_gen.gd` (`g7c` at the end of SOURCES), and `docs/DEVELOPMENT.md` (the grade 7 bullets after grade
  6's). `data/school/grade7.json` should merge by itself (only computing, art and music `file` fields and folk music's
  `hard`).
- Shared files changed beyond the new ones: `core/school/school_sound.gd` (parts and "-:n" rests; old sounds
  unchanged), `tests/unit/test_school_sound.gd`.
- None of the 27 kinds is used by another picture file on `lead-merge` 09ac5d3a (`test_school_picture_kinds_unique.gd`
  passes); a later agent must not reuse `text_code`, `mixer` or the others.
- Not done here, for the lead: the plan's outline (`python3 tools/school_outline.py --write
  docs/superpowers/plans/2026-09-28-school.md`) after the merge, and a line in the spec's §22.4 "as built" for grade 7.

## What comes next (the School never ends, #71)
Grade 8 computing (a bigger program, comparing algorithms, databases), art (Impressionism, modern movements, animation)
and music (Romantic music, jazz, producing a track); a keyboard in the game for typing code and playing notes; an in-game
code runner with its own tests; a piano-roll exercise for composing riffs; a thirds grid in the game's photo mode;
world links: a Renaissance workshop, an Iznik tile workshop, a woodcut press, a ceilidh, a film studio with a leitmotif
maker.

## The full suite
`tests/run_tests.sh`, 2026-09-30 on this branch at 04a84d9b (from `lead-merge` 09ac5d3a): 981 scripts, 8,952 tests,
8,948 passing, 2 risky (the world tests that do not assert, as before), 4,478,627 asserts, 48.5 min; 2 failing:
- `test_no_guilt_words.gd`: the film-music generator's choice "the hero is sad or in trouble" (the game's words never
  say "is sad"). Fixed in d38b0ce1 ("the hero is in trouble and losing hope", in the generator, its test and the unit);
  the test, `test_g7_arts_gen.gd` and the other tests that read every string literal (English only, identity words,
  plurals, inner classes, costumes, shader sources) pass.
- `test_nakama_account_key.gd` (`test_a_new_browser_signs_in_with_the_key_and_the_account_feels_loaded`: the wallet's
  gold 2,000, not 1,000): not this branch's (no account or wallet code changed); it passes run alone, so it is a
  timing flake under the PC's load (load average 15 during the run).
