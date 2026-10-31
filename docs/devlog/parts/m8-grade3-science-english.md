# Grade 3 science and English (owner #70, 2026-09-29)

The owner (#70): the School must cover a full school programme, "start from grade 3 and finish all grades
accordingly". This agent wrote every **science** and **English** unit of grade 3 (a parallel agent writes grade 3 maths).
Branch `worktree-agent-aecb844696e423581`, cut from `lead-merge` (73566c3), with `lead-school` (7b0bba5, the sort and
match exercise types and the research's other subjects) merged in on the lead's word.

## What is written
- **The outline** is the research's (the lead's change of outline mid-task): `docs/design/school-curriculum-research.md`
  §6.3 "Grade 3 → English (18)" and "Science (18)" replace grade 3's first science (14) and English (16) units in
  `data/school/grade3.json` (ids, titles, goals split on ";", standards split from "Follows"). No unit had been written
  under the old ids, so no file was renamed.
- **36 units, all written** (`data/school/g3/science/*.json`, `data/school/g3/english/*.json`): 239 lesson cards (5-8 a
  unit), **576 hand-written exercises** (15-18 a unit: 373 choice, 108 true or false, 40 order, 21 number, 17 sort, 17
  match), every one with a hint and a worked answer, at levels 1, 2 and 3; 105 generator slots.
  - Science (NGSS 3-LS/PS/ESS and 3-5-ETS1, England Y3-4, Singapore P3): living and non-living, keys, life cycles,
    plants' parts and needs, living in groups, traits (inherited, shaped by the surroundings, learned), fossils,
    surviving in a habitat (and when it changes), food, skeletons and muscles, materials, rocks and soils, forces and
    friction (with patterns of motion), magnets (with static electricity: 3-PS2-3's electric side), light and shadows,
    weather and climate, weather hazards, working like a scientist, design and test.
  - English (Common Core RL/RI/RF/L/W grade 3, England Y3-4): retelling fables and folk tales, characters' feelings,
    point of view, poems and plays, main idea, text features, sequence and cause, comparing two texts, word building and
    syllables, spelling patterns and the dictionary, nouns and pronouns, verbs and tenses (with the present perfect),
    adjectives and adverbs, joining sentences, speech marks and apostrophes, word meanings, writing stories, writing
    facts and opinions.
  - **Our own texts:** the fable *The Beaver and the Heron*; the folk tale *Stone Soup* retold in our words; *Bram and the
    Bridge* (characters); the poem *Rain, Then Sun* (two verses) and a play scene with Pip and Nell; the fact texts
    *Hedgehogs: Prickly Night Walkers*, a volcano book's contents page and map, *From Wheat to Bread*, and two texts on
    emperor penguins (a fact page and a scientist's diary); two stories by one writer (*Pip's Kite*, *Nell's Sled*).
  - **Pictures from the existing kinds:** the game's animals (frog, chicken, duck, penguin, hedgehog, parrot, sheep…),
    blocks (flowers, planks, iron, stone, water…), tables (a yes/no key, weather weeks, seasons, test results, bridges,
    a contents page), rock layers with fossils, light rays (sun, lamp, a dark cave, a mirror), block towers as a bar
    graph, and a volcano map with its key. No new picture kind.
- **35 generators** (registered at the end of `SchoolGen.SOURCES`):
  - `g3s` (`core/school/gen/g3_science_gen.gd`, `G3ScienceGen`, 22): living_or_not, key_walk, life_cycle_order,
    life_cycle_next, plant_part, trait_kind, variation_table, fossil_clue, habitat_fit, food_group, material_job,
    tug_of_war, surface_test, motion_next, magnet_poles, magnetic_or_not, shadow_size, weather_table, climate_clue,
    hazard_design, tool_unit, design_pick.
  - `g3e` (`core/school/gen/g3_words_gen.gd`, `G3WordsGen`, 13): plural, pronoun, past_tense, verb_agree, compare,
    conjunction, possessive, speech_marks, add_suffix, alpha_order, word_part, syllables, fact_opinion.
- **`SchoolSpeech`** reads "°C" as "degrees Celsius" (it said "degreesC"; this helps grade 4-8's temperatures too).

## Tests
- `tests/unit/test_school_content_g3_words.gd` (written first; it failed with "… is written" for all 30 units of the
  first outline, then 36): `test_grade_3_science_and_english_are_written_for_every_unit` (18 + 18 units, no content
  problems, a lesson of 3+ cards, 12+ hand-written exercises each with a hint and a worked answer, levels 1-3, two or
  more kinds, rounds that fill at every star count, 12+ distinct prompts, no hand-written exercise twice in a round),
  `test_grade_3_science_and_english_files_are_their_own`, `test_grade_3_units_use_grade_3_generators` (and every g3
  generator is used).
- `tests/unit/test_g3_science_gen.gd` (22 tests) and `tests/unit/test_g3_words_gen.gd` (13 tests): every generator, 60
  seeds × 3 levels, valid, with its answer worked out again from `data` by the test's own facts and rules (its own life
  cycles, food groups, key walk, friction order, shadow sizes, climate rule; its own plural, past-tense, agreement,
  comparing, apostrophe, speech-mark and suffix rules and irregular lists; sorted words; syllable splits; opinion
  words).
- `tests/unit/test_school_speech_g3.gd` (failed first): "21 °C" said "21 degrees Celsius"; an angle keeps "degrees".
- The shared `tests/unit/test_school_content.gd` passes (every exercise right by its own answer only, pictures drawn,
  kind words, British spelling, the font's letters). The full suite: see the end of this file.

## Rulings (decide and write down; cost if wrong)
1. **The research's §6.3 lists replace the first grade 3 outline** for science and English (the lead's order). Standards
   are the "Follows" codes; a writers' note in brackets ("only words spelled the same in UK and US English") is left out
   of the codes. *Cost:* the two units lists in `grade3.json` edited again.
2. **Every lesson opens with a "Remember?" card** (research §5.3.1): a quick question about an earlier grade 3 unit (in
   teaching order) or what a grade 2 child knows, with its answer, so a unit still makes sense out of order. *Cost:* one
   card per unit.
3. **Static electricity sits in the magnets unit** (one card, two exercises): the research's outline has no unit for it,
   and 3-PS2-3 names electric and magnetic interactions together. *Cost:* a unit of its own later.
4. **Speech punctuation uses the game's double speech marks** (ASCII "), named "inverted commas, also called speech
   marks" (England Y3's term); the full stop or comma goes inside the marks. **Addresses** are British, on one line with
   commas ("14 Oak Lane, Riverton"). *Cost:* none.
5. **Spelling and grammar never test UK/US-different words** (spec §22.6 ruling 3): no travelled, cancelled, -ise/-ize;
   "playtime", not "recess"; "tyre", "wellies", "yoghurt", "colour" in the game's own words. The word generators' wrong
   choices are hand-written (so no wrong choice is secretly right, like "persons" or "fishes"); two real-word
   distractors are kept on purpose because the lesson teaches them (hoped/hopped, hoping/hopping, careless/carless).
   *Cost:* a word list edit.
6. **Life cycles are plants and animals only; mammals are "born alive and drink their mother's milk"** (research §5.4
   rule 4: no human reproduction). *Cost:* none.
7. **Science facts are kept to what a grade 3 book says and is true:** e.g. a plant in the dark grows "pale, thin and
   floppy" (not "shorter": dark-grown seedlings can be taller); water, not light, is the variable in the height test;
   "steel" things are paper clips, pins, nails (not stainless cutlery or keys, which may not be magnetic); aluminium,
   copper, gold and silver are the non-magnetic metals; habitat distractors are only living things that cannot live
   there (no frogs as a desert's "cannot", since some desert frogs exist). *Cost:* none.
8. **Two generator test files** (`test_g3_science_gen.gd`, `test_g3_words_gen.gd`) instead of one: they check
   different things. *Cost:* none.
9. **Table pictures keep their cells short** (my kit's rule: 16 letters for 2 columns, 12 for 3, 9 for 4), because a
   table cell does not wrap. Not checked on screen (no editor or emulator for this agent). *Cost:* a cell to shorten if
   the lead's screenshot shows it tight.
10. **Sort and match** (the lead's new types) are used once in 34 of the 36 units (not joining sentences or main idea).

## For the lead (merging)
- `data/school/grade3.json`: this branch changes only the science and English `units` (replaced, with `file`s). The maths
  agent changes the maths units: take both. The file round-trips through `json.dumps(indent="\t", ensure_ascii=False)`.
- `core/school/school_gen.gd`: `g3s` and `g3e` are appended at the end of `SOURCES`; the maths agent may append its own
  lines there too: keep all of them.
- `core/school/school_speech.gd`: one `SIGNS` pair added (`"°C"`) and `"( "` tidied to `"("` in `spoken()`.
- `lead-school` (7b0bba5) is already merged into this branch.
- After merging, rerun `python3 tools/school_outline.py --write docs/superpowers/plans/2026-09-28-school.md` (the grade 3
  outline changed and 36 units are now "(written)").
- A visual check is worth one look: `--unit=g3.science.weather_climate --exercises`, `g3.science.classification_keys`
  (the key table), `g3.english.poems_plays` (the poem cards use line breaks), `g3.english.text_features` (the map).

## Full suite
`tests/run_tests.sh` on this branch (after the sort and match exercises; 2026-09-29, 1,597 s): **6,836 tests, 6,833
passing, 1 failing, 2 risky**.
- The failure is not this branch's: `test_g5_measure_gen.gd` › `test_grade_5_maths_is_written_for_every_unit` wants
  every grade 5 maths unit written, but `lead-school` 7b0bba5 (merged here) added the research's new grade 5 units
  (`percent_intro`, `angles_triangles_quads`) without files. `lead-school` has since relaxed that test (only units that
  name a file), so it passes once the lead's newer commits meet this branch.
- The two risky tests are the terrain's `test_the_column_cache_changes_nothing` and `test_chunks_meet_without_seams`
  (they assert nothing on this PC's run; not School code).
- After the last change (the match exercises' order varies), the School's tests were run again: test_school_content,
  test_school_content_g3_words, test_g3_science_gen, test_g3_words_gen, test_school_speech_g3, test_school_curriculum,
  test_school_screen, test_school_exercise_panel: 99 tests, all passing.
- `lead-school`'s newer `test_the_sums_in_the_lessons_are_right` (4371155) was replayed on grade 3's files with the same
  pattern: all 12 sums the lessons state are right.
