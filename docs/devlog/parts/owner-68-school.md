# Owner feedback #68: School, grades 4 to 8 — the foundation and grade 4 (2026-09-28)

The owner: "dont forget about school educational program implementation, at the end we should have full school
4-5-6-7-8 grade programs in the game". Spec §22, plan `docs/superpowers/plans/2026-09-28-school.md` (with the whole
outline of grades 4-8). This agent built the framework and grade 4's content; later agents write grades 5-8 on the same
files (below, "What the next agents do").

## What a child sees
The main menu's **SCHOOL** (teal, left of AVATAR and SETTINGS) opens the School inside the menu's panel. The first visit:
Professor Hoot (the game's own owl in a drawn square cap) and "Which grade are you in?" (GRADE 4-8, with ages). Then the
**map**: MATHS / SCIENCE / ENGLISH tabs and the grade's units as numbered stops with their stars, a gold medal once a unit
is mastered, a green leaf when a review would help, and grey "Coming soon" stops for units not written yet. A **unit**:
"You will learn to:" (its goals), its standards in small letters, Professor Hoot's tip, LESSON and PRACTICE (REVIEW when
due). A **lesson**: cards with a picture and a speaker, PREVIOUS / NEXT, then LET'S PRACTISE!. A **round**: 6 exercises
(STOP leaves without recording anything), then the end: "5 of 6 right the first time!", the stars, and the first time a
unit is mastered "+100 gold for Survivor, and the … badge!" with the coin shower. **GROWN-UPS** (behind the parent gate):
the grade, "Only a grown-up changes the grade" ON / OFF, and every unit's stars, rounds, share right the first time and
the day last practised.

## Rulings (the owner's rule: decide and write down; cost if wrong)
Spec §22.6 has the twelve design rulings (the framework: Common Core + NGSS; three subjects; British spelling; metric,
time and gold; the menu first; the block board as the in-world exercise type; mastery 5 of 6, remembered on a later day,
reviews at 1/3/7/21/60 days; 100 Survivor gold once per unit; the child picks the grade, a grown-up can fix it; Professor
Hoot; the lazy load; the sync line left to the sync agent). Rulings made while building:

1. **Curriculum as JSON** (`data/school/grade<N>.json`, one file per written unit), **generators as GDScript**
   (`core/school/gen/`). JSON is easy to write and check without the editor; generators need code. *Cost:* another format
   is a loader change in `Curriculum`.
2. **Every number answer is compared by exact value** (`NumberAnswer`: reduced fractions of whole ints): 5/8 = 10/16,
   0.5 = 0.50, commas ignored. A child who writes an equal fraction is right. *Cost:* an exercise that wants a particular
   form (lowest terms) needs a `form` field in `ExerciseCheck` (none in grade 4 does).
3. **The pad shows `.`, `/` and `-` only when the answer has one.** It helps (the form of the answer shows) and keeps the
   pad simple. *Cost:* an exercise can name its keys (`"pad": [".", "/"]`) to hide the hint.
4. **A choice or TRUE / FALSE answers at the tap**; a number, an order or a build answers with CHECK. *Cost:* a line in
   `ExercisePanel` (`taps`).
5. **A miss rests the tried choice, clears an order, keeps a typed number and a build** (the child fixes it). The second
   miss shows the worked answer (`explain`, or "The answer is …") and the right answer on the widget.
6. **Only the first try counts** towards stars; a right second try is praised ("You kept going and got it!").
7. **Rounds go easy to harder** (`RoundPlan.TARGETS`: levels 1,1,2,2,2,3 at no stars; 1,2,2,2,3,3 at one; 2,2,3,3,3,3
   from two), a hand-written exercise never twice in a round while others of its level are left.
8. **British words**: "trapezium" (not "trapezoid"), "maths", "metres", "practise" (the verb), numbers in words with "and"
   ("three hundred and five"). *Cost:* a spelling pass over the data; `test_school_content.gd`'s US list guards it.
9. **Days are the device's calendar days** (`SchoolClock`), used only for review suggestions and the grown-ups' "last
   practised"; a day going backwards changes nothing earned (tested). *Cost:* none.
10. **At most 18 units per subject** (the map's 6 × 3 grid, no scrolling). The outline has 11-17. *Cost:* a scrolling map.
11. **Texts have limits** so every exercise fits its panel: a prompt 180 letters, a hint 200, an explanation 260, a choice
    48, a lesson card 260 (`ExerciseCheck.MAX_*`, the content test). *Cost:* none; longer reading goes on lesson cards.
12. **Pictures are drawn from data** (`SchoolPicture`, 15 kinds) with the game's blocks, animals and board pictures: no new
    asset files (nothing to credit). *Cost:* a kind needs drawing code; the content test checks every picture's data.
13. **The School's frame is 1180 × 636** (inside the menu's panel: 1236 × 692 on a 720 px screen), so the menu always
    gives it the whole height and hides the logo. *Cost:* none.
14. **School gold goes to the Survivor purse** through `Wallet` outside a world, like the code field and the avatar
    editor; online, the wallet sync reports it (`OnlineService.sync_wallet`). *Cost:* none.
15. **The profile backup's merge is not touched** (the owner's split: another agent builds profile sync).
    `SchoolData.merge_from` is ready and tested; **the lead (or the sync agent) adds one line** to
    `ProfileBackup.merge`: `out.school.merge_from(other.school)   # owner #68`, and `and p.school.is_empty()` to
    `ProfileBackup.is_new`. Until then the newer profile wins for the School as for every field without a merge rule.
16. **Grade 4 science's first unit is "Rock layers and fossils"** (4-ESS1-1): it ties to the game's own layers (grass, dirt,
    stone, deep stone, bedrock) and its pictures are the game's blocks. **English: a story of our own** ("Juno and Wick":
    characters, events, theme, point of view) and **"Words that sound alike"** (to/too/two, there/their/they're,
    your/you're, its/it's), whose generators make endless blanks from our own 31 sentences.

## What is built
- **Data:** `data/school/grade4.json` … `grade8.json`: the whole outline, 201 units (grade 4: 42, 5: 41, 6: 40, 7: 39, 8:
  39), each with its standards and 1-3 goals; `data/school/g4/maths/*.json` (17 units), `g4/science/rock_layers.json`,
  `g4/english/story_characters.json`, `g4/english/sound_alike.json`.
- **Rules** (`core/school/`): `Curriculum`, `SchoolData` (in `ProfileData.school`), `MasteryRules`, `ExerciseCheck`,
  `NumberAnswer`, `NumberPad`, `NumberWords`, `BuildCheck`, `RoundPlan`, `SchoolGen`, `SchoolSpeech`, `SchoolWords`,
  `SchoolClock`, `ShapeFacts`; generators `core/school/gen/`: `GenKit`, `G4MathsGen` (g4m, 37), `G4FractionsGen` (g4f,
  24), `G4MeasureGen` (g4g, 25), `G4ScienceGen` (g4s, 3), `G4EnglishGen` (g4e, 2) with `GenWords`.
- **UI** (`ui/school/`): `SchoolScreen`, `SchoolUi` (frame, colours, stars, Professor Hoot, fitted titles), `UnitStop`,
  `SchoolPicture`, `ExercisePanel`, `ChoiceAnswer`, `NumberAnswerPad` (also typed on a keyboard), `OrderAnswer`,
  `BuildBoard` (tap or slide to paint), `SchoolGrownUpsPage`.
- **Entry:** `ui/menus/menu.gd` section "Owner #68: School" (loads the screen's script on press).
- **Tool:** `tools/school_shots.gd` (pictures of every page; below). `tools/school_outline.py` (the plan's outline).

## Grade 4 content
| Subject | Units written | Lesson cards | Hand-written exercises | Generators (slots in units) |
|---|---|---|---|---|
| Maths | 17 of 17 | 71 | 143 | 86 (220) |
| Science | 1 of 12 (rock layers and fossils) | 6 | 13 | 3 (8) |
| English | 2 of 13 (a story; words that sound alike) | 12 | 23 | 2 (6) |

Every maths unit fills a round at every level with at least 25 different exercises over 60 rounds (the content test).

## Tests (all written first; the suite's `test_school_*`, `test_g4_*`, `test_number_words.gd`)
Unit: `test_school_number_answer` (exact values), `test_school_number_pad`, `test_number_words`, `test_school_build_check`
(every goal kind, examples, impossible goals), `test_school_exercise_check` (every type, problems, limits),
`test_school_mastery` (stars, reviews, the reward once, a day going backwards, certificates), `test_school_data` (parsing,
merging, the profile round trip, size), `test_school_curriculum` (the five grades' outlines, lookups, a missing file),
`test_school_round_plan`, `test_school_speech` (maths said aloud, the teacher's words), `test_school_clock`,
`test_school_shape_facts` (the drawn shapes agree with their facts), `test_school_content` (every written unit and every
generator for 120 seeds × 3 levels: valid, right by its own answer, wrong answers wrong, pictures drawable, kind words,
British spelling, the font's letters only), `test_g4_maths_gen`, `test_g4_more_gen` (answers against arithmetic done in
the test, every "… = ?" equation evaluated exactly), `test_g4_words_gen`. Integration: `test_school_picture` (every kind
draws), `test_school_exercise_panel` (every answer widget, hints, the worked answer, once-only), `test_school_screen`
(every page, the round with its gold once, STOP records nothing, the gate, every page fits, every stop of every grade
fits), `test_school_menu` (SCHOOL on the menu, every School button on the screen at 1280 × 720 and 2400 × 1080).

## Pictures (a window, no editor or emulator)
`XDG_DATA_HOME=/tmp/easycraft-school-shots godot --path . --disable-vsync --script res://tools/school_shots.gd -- --unit=g4.maths.area_perimeter --exercises`
(`--wide` for the 20:9 canvas). Looked at while building: the welcome, the three maps, units, lessons of maths, science and
English, rounds of every answer type, the round's end, the gate and the grown-ups' page. Fixed from the pictures: clipped
header titles (now fitted), the grown-ups' rows (stars over the words), long stop titles, Professor Hoot's cap.

## For the lead (the emulator check)
SCHOOL on the main menu at 20:9; pick grade 4; a maths lesson read aloud (the speaker and "Read to me"); a round with a
number (the pad), an order, a build (tap and slide on the board with a finger); the round's end with the coin shower;
GROWN-UPS through the gate. In a desktop browser: typing digits and Enter on the pad.

## What the next agents do (one grade per agent; the plan's "Later tasks")
- **Grade 5** (16 maths, 13 science, 12 English units in `grade5.json`): unit files in `data/school/g5/<subject>/`,
  generators in `core/school/gen/g5_*_gen.gd` registered in `SchoolGen.SOURCES` ("g5m", …), `"file"` in `grade5.json`,
  the outline refreshed. New pictures it needs: a **coordinate grid** (5.G.1-2), **cubes in 3D** for volume (5.MD.3-5: a
  box of unit cubes, the block style), a **shape family tree** (5.G.3-4). New answer type: **tap a point on a grid** (write
  it in `ExerciseCheck` first). Decimal answers to thousandths fit the pad (9 characters).
- **Grade 6**: negative numbers (the pad's `-` exists), ratios tables (the `table` picture), dot plots / histograms /
  box plots (new picture kinds), nets of boxes (a new picture), exponents written with ² ³ (the font has them).
- **Grade 7**: probability without gambling: spinners and bags of coloured blocks, never money bets; circles (π is in
  the font); scale drawings on the grid picture.
- **Grade 8**: the Moon's and the planets' gravity (the space worlds, §21) in "Gravity and orbits"; the Pythagorean
  theorem on the grid; scatter plots (a new picture); √ is in the font.
- **English for every grade**: stories and texts of our own (public-domain text only if quoted and credited in the unit
  file); short questions; sentences with blanks make good generators (`GenWords` shows how).
- **Science for every grade**: pictures from the game's blocks, animals and worlds where they fit (biomes, the Moon's
  gravity, water, lava, the day and night).
- **The in-world school (after grade 5)**: a School building and Professor Hoot in the worlds (a node like the Theater),
  build challenges checked by `BuildCheck` on the world's cells (`BuildPicker`), science field trips as quest chains,
  `Progress.event(&"school_unit")` for the board and the Memory Book; a Scholar's Cap avatar item for a grade's maths.

## The full suite (2026-09-28, `tests/run_tests.sh`, one PC-wide slot)
717 scripts, 6565 tests: **6560 pass, 3 fail, 2 risky/pending, no script errors**. None of the three is the School's:
- `test_realistic_before_the_pack.gd` `test_the_settings_say_the_realistic_pictures_are_on_their_way` (the settings panel is
  1590 px wide with the realistic note beside SIMPLE / CLASSIC): it fails the same on a clean export of this branch's
  base (9187c8b); `lead-merge` fixed it since (a2e07dd, the note wrapped beside REALISTIC).
- `test_nakama_profile_backup.gd` (2 asserts: the gold read back is 25): the development Nakama runs module 0.2.12
  (owner #67: the server never keeps gold in the backup), while this branch's copy of the test predates #67;
  `lead-merge` updated the test (it checks `universe_unlocked` instead).

## For the merge
- Checked with `git merge-tree` against `lead-merge` 1dda320: clean (the School's three `ProfileData` lines sit beside
  the books', away from #67's `stamps`).
- #67 rewrote `ProfileBackup.merge` (per choice, by version, without gold). The School's line to add there:
  `out.school.merge_from(other.school)   # owner #68` (a stars-and-counts union, never loses anything), and
  `p.school.is_empty()` in `is_new`. The server's backup cleaning (module 0.2.12, `ProfileRules.DROPPED`) keeps `school`.
- The School's gold (+100 once per unit mastered, in the menu) is a change "off the server's watch", like the menu's
  shop: `Profile.save` → the backup upload → `OnlineService.sync_wallet` reports it (unchanged by #67).
