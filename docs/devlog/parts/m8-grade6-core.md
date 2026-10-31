# Grade 6 maths, science and English: the research's last units written (owner #70, #73; 2026-09-30)

The owner: "start from grade 3 and finish all grades accordingly" and "research school programs, world leading schools
and create better school program". The research (`docs/design/school-curriculum-research.md` §6.6) merged Singapore P6
(problem-solving heuristics, energy conversion) and England Year 7 / KS3 (skeleton and muscles, nutrition and digestion,
classification, light) into grade 6, and added Common Core's reading, writing, research and speaking standards that the
first outline left out; these 13 units showed "Coming soon". This agent wrote all 13, following the reusable brief
(`docs/superpowers/plans/2026-09-29-school-subjects-brief.md`, GRADE = 6, SUBJECTS = maths, science, English: the units
with no `file`), with grade 6's written units of those subjects and grade 5's core units as the model and grades 3-5 as
the spiral. Branch `worktree-agent-a3492f9a33488e9d6`, from `lead-merge` at 87b74317. **After it, every one of grade 6's
136 units is written**: maths 18, science 17, English 18, and the nine other subjects written earlier the same day.

## What was written
| Unit | Cards | Hand-written exercises (levels 1/2/3) | Kinds | Generators (g6k) |
|---|---|---|---|---|
| maths `problem_solving_toolkit` | 8 | 18 (6/6/6) | number 12, choice 2, truefalse 2, order 1, match 1 | `work_back`, `bar_problem`, `systematic_list`, `guess_check`, `find_pattern`, `strategy_pick` |
| science `skeleton_muscles` | 8 | 18 (6/6/6) | choice 8, truefalse 3, label 3, match, number, sort, order | `bone_job`, `muscle_work`, `joint_type` |
| science `nutrition_digestion` | 8 | 18 (6/6/6) | choice 10, truefalse 3, match 2, sort, order, number | `nutrient_find`, `food_test_read`, `enzyme_job` |
| science `classification` | 8 | 18 (6/6/6) | choice 11, truefalse 2, sort 2, match, order, number | `vertebrate_group`, `invertebrate_group`, `key_walk`, `kingdom_pick`, `taxon_order` |
| science `light_travels` | 8 | 18 (6/6/6) | choice 6, number 5, truefalse 3, label 2, sort, order | `shadow_size`, `mirror_angle`, `light_kind` |
| science `energy_changes` | 8 | 18 (6/6/6) | choice 8, truefalse 3, number 3, order 2, match, sort | `energy_convert`, `energy_waste`, `save_energy` |
| science `engineering_design` | 8 | 18 (6/6/6) | choice 9, truefalse 3, number 3, sort 2, order | `criteria_sort`, `design_pick`, `decision_matrix`, `trial_mean` |
| English `read_closely` | 8 | 18 (6/6/6) | choice 11, truefalse 4, sort 2, order | `stated_or_inferred`, `best_evidence`, `story_or_fact` |
| English `write_argument` | 8 | 18 (6/6/6) | choice 11, truefalse 3, order 2, label, sort | `argument_part`, `argument_link`, `formal_style` |
| English `write_informative` | 8 | 18 (6/6/6) | choice 10, truefalse 3, order 2, match, label, sort | `precise_word`, `info_feature` |
| English `write_narrative` | 8 | 18 (6/6/6) | choice 11, truefalse 3, order 2, label, sort | `hook_pick`, `pace_pick`, `vivid_verb` |
| English `research_sources` | 8 | 18 (6/6/6) | choice 12, truefalse 3, order 2, sort | `paraphrase_pick`, `source_trust`, `cite_order` |
| English `discuss_present` | 8 | 18 (6/6/6), 4 to listen to | choice 12, truefalse 4, order, sort | `build_on`, `chart_choice` |
| **All** | **104** | **234** | choice 121, true or false 39, number 26, order 18, sort 15, label 8, match 7 | 43 generators, every unit's at levels 1-3 |

- **Files:** `data/school/g6/<subject>/<unit>.json`, linked from `data/school/grade6.json` (only these 13 units gain a
  `file` line; titles, goals and every written unit unchanged).
- **Every unit:** 8 cards that open with "Quick memory:" and a question from grade 3, 4 or 5 (named, with its answer in
  brackets), teach one idea a card with worked examples and pictures, and end "Try it in the world: … Next: …"
  (research §5.3 rules 1, 7 and 8); 18 hand-written exercises of 4-7 kinds, 6 at each level, each with a hint (a
  strategy) and an explain (the worked answer); g6k generators at every level for endless practice.
- **The problem-solving toolkit (Singapore P6 heuristics, EEF [C3]):** Polya's four steps (How to Solve It, 1945), then
  one card a strategy with a worked example and its picture: draw a model (a bar model, "3 times as many"), work
  backwards (a function machine and its undo row), a systematic list (handshakes), guess and check (a table of
  guesses), look for a pattern (towers; the 20th term). Builds on grade 3's two-step problems and bar models and grade
  5's fractions; next, grade 7's ratio, rates and equations.
- **Skeleton and muscles (England KS3):** 206 bones and the four jobs (support, protection, movement, blood cells in
  the marrow), what the skull, ribs and spine protect, living bone, calcium and vitamin D, joints (hinge, ball and
  socket, pivot, fixed) with ligaments and cartilage, muscles that only pull by contracting, tendons, pairs (biceps
  and triceps, hamstrings and quadriceps). Builds on grade 3's food and skeletons.
- **Nutrition and digestion (England KS3, Singapore spiral):** the seven parts of a balanced diet and their jobs,
  deficiency (scurvy, anaemia; James Lind, 1747), the food tests (iodine, Benedict's heated, biuret, the paper spot),
  enzymes as the cutters (amylase, protease, lipase; bile), villi in the small intestine, the large intestine taking
  back water. Builds on grade 4's digestion and teeth.
- **Classifying life (England Y6, Singapore diversity):** five kingdoms (animals, plants, fungi, protists, bacteria),
  fungi are not plants, the five vertebrate groups and their features, invertebrates (about 97% of animal species),
  Linnaeus (1735; two-part names such as Homo sapiens and Canis lupus), the levels from kingdom to species, species,
  why classify, chain keys. Builds on grade 3's keys and animal groups.
- **Light travels (England Y6, Singapore S1 preview):** straight lines at about 300,000 km a second (8 minutes from
  the Sun), sources and reflectors, transparent, translucent and opaque, shadows sized by the rays' straight lines (a
  maths link: similar triangles, far ÷ near), the normal and the law of reflection, the periscope (two mirrors at 45°,
  mirror writing on ambulances), the pinhole camera's upside-down image, never looking at the Sun. Builds on grade 3's
  shadows and grade 4's seeing; next, grade 7's light and colour.
- **Energy changes (Singapore P6, England KS3):** eight forms (chemical, electrical, kinetic, light, sound, heat,
  gravitational, elastic), chains (a torch, a dam, a bouncing ball), energy never made or destroyed, joules (James
  Joule, 1840s), useful and wasted energy on Sankey diagrams, efficiency (useful ÷ total × 100), wasting less. Builds on
  grade 4's energy and grade 6's energy transfer; next, the water cycle.
- **Engineering design (NGSS MS-ETS1-1 to 4):** criteria and constraints, ideas judged with a weighted decision matrix,
  prototypes and fair, repeated tests with a mean, combining the best features (iteration), the Wright brothers' 1901
  wind tunnel (about 200 wing shapes) and the 1903 flight, trade-offs, safety and the environment. Builds on grade 3's
  fair tests and design solutions.
- **Read closely and compare (RL.6.1, RI.6.1, RL.6.9):** explicit and inferred, evidence as short exact quotes with an
  explanation (Old Tam and the coming storm), a story and a fact text on the same topic compared by purpose, words and
  scope (a table). Builds on grade 5's quoting; next, grade 6's central idea.
- **Write an argument (W.6.1):** claim, reasons and evidence on an argument map, a counterclaim and its rebuttal,
  linking words, a formal style that answers ideas, never people, a conclusion. Builds on grade 5's opinion pieces.
- **Write to inform (W.6.2):** an introduction, sections with subheadings, definitions, examples and quotations,
  precise words, features (a labelled diagram, a caption, bullet points, a glossary), a conclusion (volcanoes as the
  example). Builds on grade 5's explanations.
- **Write a narrative (W.6.3):** hooks, the story arc (exposition to resolution), building tension, pacing with short
  and long sentences, dialogue and its punctuation, vivid words and showing feelings. Builds on grade 5's story
  techniques and grade 6's plot and character.
- **Research and sources (W.6.7, W.6.8):** a researchable question, several sources judged for reliability (author,
  date, purpose, agreement), notes in your own words with their sources, paraphrase, plagiarism and quoting, a source
  list A to Z by surname. Builds on grade 5's many sources.
- **Discuss and present (SL.6.1, SL.6.4, SL.6.5):** preparation and rules, building on others' ideas and disagreeing
  politely, a talk's shape, a chart as evidence, pace, volume (a quiet speaker heard at 0.2 volume), pauses, eye
  contact. Builds on grade 5's talks; next, grade 7's speeches and media.

## Generators (`core/school/gen/g6_core_gen.gd`, `G6CoreGen`, "g6k", registered last in `SchoolGen.SOURCES`)
43 generators, each at levels 1-3, with a hint, a worked answer and `data`: a function machine run backwards (two steps,
three with × and ÷, a story of gold), bar models (a total and a difference, "times as many", a fraction then a fraction
of the rest), systematic lists (choices, handshakes or league games, ways to pay with two coins), guess and check (hens
and cows, beetles and spiders, coins), patterns (the next tower, the 10th-20th, which term, 1 + … + n), the best
strategy; bones, muscle pairs, joints; nutrients by food, job and lack, food tests read from the tubes, enzymes and where
digestion happens; vertebrate and invertebrate groups, chain keys walked from a description, kingdoms, the levels in
order; shadows (bigger or smaller, the shadow, the card, its distance), reflected angles (from the normal, from the
mirror, between the rays), light sources, materials and seeing in order; energy changes and chains, Sankey diagrams
(wasted, useful, efficiency), saving energy; criteria and constraints, a design from test results, weighted decision
matrices, repeated trials and the odd one out; and in English banks for stated or inferred, the best evidence, story or
fact, an argument's parts and links, formal sentences, precise words, an information text's features, hooks, pace,
vivid verbs, paraphrases, trustworthy sources, a source list in A-to-Z order (generated names and titles), building on
ideas and the right chart. `tests/unit/test_g6_core_gen.gd` (44 tests, 80 seeds × 3 levels) works every answer out
again with its own arithmetic and tables: its own function-machine interpreter, bar-model formulas, brute-force counts
(pairs, handshakes, coins, heads and legs), pattern loops, a key walked with its own table of what each living thing
has, similar triangles, the law of reflection, energy sums, the brief checked row by row, weighted totals, the median's
odd one out, keyword tables for the banks, an informal-word list, sentence counts for pace, and a letter-by-letter A to Z.

## Pictures (`ui/school/school_picture_g6core.gd`, `SchoolPictureG6Core`)
18 kinds drawn from data (the header lists their fields), hooked into SchoolPicture after SchoolPictureG6Health (one
header paragraph, one `problem()` block, one `draw()` block ending in `return`): `skeleton` (bones named with lines, one
orange, one "?"), `joint` (hinge, ball and socket, pivot, fixed; bone, cartilage, ligament), `muscle_pair` (the
contracting muscle short and fat), `food_test` (tubes in their colours, the paper spot; `colour_word`), `enzyme_cut`
(chains of beads cut by the enzyme), `key_tree` (a chain key, a path in orange; `key_end`), `kingdoms` (a fox, a
flower, a toadstool, an amoeba, rod bacteria), `taxon_levels` (kingdom to species, with the wolf's names),
`shadow_rays` (a lamp, a card and a screen to scale; `shadow_height`), `reflection` (the normal, arcs from the normal or
the mirror; `angle_of`), `light_device` (a periscope, a pinhole camera), `energy_chain` (forms with icons, wasted
arrows), `sankey` (bands as wide as the energy, the wasted ones bending down round one centre; the parts must add up to
the total; `efficiency`), `op_chain` (a function machine with an undo row; `run`, `undo`; a picture whose start and end
disagree is a problem), `handshakes` (people in a ring; `handshake_count`), `argument_map`, `story_arc` (tension over
time, the stages named under the time line), `info_page` (title, introduction, subheading, diagram, caption, glossary).
`part_at` gives each labelled part's place for label exercises; an argument map's and a page's lines end at the outer
side of a box, so they never cross its words. `tests/integration/test_school_picture_g6core.gd` (6 tests): 69 samples
valid and drawn at five sizes, every kind and option sampled, the rules worked out again, parts found, broken data
found. `test_school_picture_kinds_unique.gd` finds the file by itself: no kind shares a name.

**Looked at in a real window** (a gallery of the samples, then `tools/school_shots.gd -- --unit=… --exercises` for all
13 units, 74 shots each, no script errors): the first joints ran off the card (now sized to it, the hinge's lower bone
turned), the kingdoms' bacteria were specks (bigger rods), the periscope's and pinhole camera's names sat on the
drawings (placed beside them; the pinhole image now stands upside down on a lit screen), the Sankey's wasted bands were
nonsense until they bent round one centre, bands side by side now alternate shades, the story arc's names overlapped
the line (now under the time line, evenly spaced), handshake names sat on faces, argument-map titles were tiny, label
lines crossed the words of argument maps and pages (now end at the box's side), Sankey numbers had no thousands commas,
and a choice ending in "?" read "Does it have 8 legs?." (reworded). Then the lessons, labels, tables, keys and charts
read clearly.

## Rulings (decide and write down; cost if wrong)
1. **One generator source, `g6k`, for all three subjects** ("c" is grade 6 arts'); every unit uses it at every level.
   *Cost:* a rename if another branch took "k".
2. **The new units are grade 5 core's size (8 cards, 18 exercises), richer than grade 6's first-outline units (4 cards,
   8-15 exercises)**, which are kept unchanged (never change a written unit). *Cost:* none; the older units could grow
   later.
3. **Energy is taught as forms (Singapore P6: chemical, electrical, kinetic, light, sound, heat, gravitational,
   elastic)**, the goal's own words ("chemical to movement"), rather than KS3's stores and pathways. *Cost:* a card's
   wording if the owner prefers stores.
4. **Five kingdoms, "protists"** (England KS3 teaches five; "protists" is the simpler word for protoctists). *Cost:* a
   word.
5. **"George Polya", without the ó**, so the School's letters need no new one. *Cost:* adding ó to `ALLOWED` if wanted.
6. **Food tests are shown and read, and done "only in a lab, with a teacher"; fat is found with the paper spot**, not
   the ethanol emulsion test, so no alcohol word appears in science (research §5.4 rule 5). *Cost:* a card if the
   owner wants the emulsion test.
7. **The body units are kind** (the grade 6 health test's words): a balanced diet and deficiencies factually, no
   weight, calories or "bad foods"; the bones question offers habits, not foods, as wrong answers. Species "can have
   young together" (animals and plants; nothing about people). *Cost:* none.
8. **Label pins sit beside the drawing with a line to the part** (`part_at`, checked by the content test within 14 px);
   untitled argument maps shrink to leave room for pins. *Cost:* none.
9. **A speaker's pace and volume are heard as claps** (grade 6's `volume`: 0.2 is too quiet for the back of the room;
   tempo 170 with no rests is too fast). *Cost:* recorded speech would need audio files.
10. **Example energy flows are one test's numbers** ("a kettle takes in 2,000 J…"), within real ranges (a filament bulb
   about 10% light, the standard teaching figure; kettles 80-90%, motors 60-80%, car engines 20-30%). *Cost:* none.
11. **Writing units practise by choosing, sorting, ordering and labelling** (research §5.3: phones have no good
   keyboard for children). *Cost:* none.
12. **The unit files are the source of truth**; the Python that built and checked them (limits, letters, British
   spelling, kind words, every "a op b = c", pins 56 px apart) stayed in the agent's scratchpad.

## Facts checked (and sources)
- 206 bones in an adult; the skeleton's four jobs, blood cells made in the marrow (Oak National Academy KS3 "The human
  skeleton"; Kablow KS3; Doc Brown's biology). About 275-300 bones at birth, some joining as we grow (Cleveland Clinic,
  "How many bones does a baby have"; Popular Science). 12 pairs of ribs; the femur the longest bone, the stirrup bone in the ear the smallest.
- The seven components of a balanced diet; scurvy (vitamin C), rickets (vitamin D), anaemia (iron) (Seneca KS3,
  Shalom Education KS3; Britannica, nutritional disease). James Lind's 1747 trial with oranges and lemons.
- Food tests: iodine orange-brown to blue-black with starch; Benedict's, heated, blue to brick red with sugar; biuret
  blue to purple with protein (BBC GCSE Bitesize food tests; Doc Brown's food tests). The paper spot for fat (KS2-3
  practical).
- Enzymes: salivary amylase starch to sugars, pepsin (a protease) in the stomach, lipase to fatty acids and glycerol,
  bile emulsifies fat (OpenStax Concepts of Biology 15.3; Open University OpenLearn 2.9). Small intestine about 6 m,
  large intestine about 1.5 m (as grade 4's digestion unit; NHS).
- Five kingdoms: animals, plants, fungi, protoctists, prokaryotes (Doc Brown's classification; Cambridge IGCSE notes);
  about 97% of animal species are invertebrates (CK-12; AMNH). Carl Linnaeus, 1707-1778, Systema Naturae 1735
  (Britannica; Wikipedia); Homo sapiens and Canis lupus (Linnaeus, 1758).
- Light: about 300,000 km a second; sunlight about 8 minutes 20 seconds (BBC Sky at Night; Wikipedia, speed of light).
  The law of reflection, periscopes' 45° mirrors, the pinhole camera's inverted image, mirror writing on ambulances.
- A filament bulb gives about 10% of its energy as light (Siyavula Natural Sciences grade 7, 15.1; Science Photo
  Library's Sankey diagrams). James Prescott Joule's 1840s experiments.
- The Wright brothers' 1901 wind tunnel: "as many as 200" wing shapes tested (NASA Glenn, Wright 1901 wind tunnel
  tests; Smithsonian, Researching the Wright Way); first powered flight 17 December 1903.
- George Polya, How to Solve It (1945), four steps (Pólya; LibreTexts 5.2). Singapore's primary heuristics (MOE list,
  summarised by Seriously Addictive Maths).
- Children need 60 active minutes a day (UK Chief Medical Officers' guidelines; grade 6 health's unit). Honeybees' waggle
  dance; sharks sense electric fields; an octopus has three hearts and blue blood; thunder is air heated by lightning;
  Mount Etna in Sicily erupts often.
- Every sum in the texts is checked by the builder and by `test_the_sums_in_the_lessons_are_right`; the pictures'
  answers by `test_school_content_g6_core.gd`; generated answers by `test_g6_core_gen.gd`.

## Tests
- `tests/unit/test_school_content_g6_core.gd` (written first: 9 of 13 failed, "is not written"): the outline has the 13
  units with their files; grade 6's maths (18), science (17) and English (18) are complete; every unit meets the bar
  (4-8 cards, 12+ hand-written exercises at levels 1-3 of 2+ kinds, rounds that fill and vary, never a hand-written one
  twice); hints and worked answers; memory first naming grade 3-6, the world and Next last; no question twice; g6k at
  every level, every g6k generator used; the facts each lesson teaches; each unit's pictures; every label's line on its
  part; the pictures' answers worked out again with its own rules (a function machine undone, handshakes, towers,
  shadows, reflected angles, energy flows: 14 checked); a speaker to listen to, one too quiet; safety (no puberty,
  reproduction, drugs, alcohol, smoking or gambling words, no personal questions, kind body words, never looking at
  the Sun). 13/13.
- `tests/unit/test_g6_core_gen.gd`: 44/44. `tests/integration/test_school_picture_g6core.gd`: 6/6.
- The School's and the Lab's tests together (every `test_school*`, `test_lab*`, `test_g6*`, `test_curriculum*`, unit and
  integration): 732 of 732 in 71 scripts; the shared `test_school_content.gd` counts 9,116 hand-written exercises.
- The full suite: see the end of this file.

## For the lead when merging
- `data/school/grade6.json`: only the 13 units gain a `file` line.
- `core/school/school_gen.gd`: one SOURCES line at the end, `"g6k"`.
- `ui/school/school_picture.gd`: one header paragraph and a `problem()` and a `draw()` block for `SchoolPictureG6Core`,
  after the G6Health ones.
- `docs/DEVELOPMENT.md`: one bullet after grade 6 health's; spec §22.4f: one bullet at its end.
- After the merge: `godot --headless --path . --import` (new classes `SchoolPictureG6Core`, `G6CoreGen`) and
  `python3 tools/school_outline.py --write docs/superpowers/plans/2026-09-28-school.md`.
- Not done here (other agents' files): RESUME-HERE, the owner-feedback row, the outline.
- Next for these subjects (the game never ends): grades 7 and 8's research units still "Coming soon" (grade 7: primes
  and estimation, speed and rate, misleading graphs, the periodic table, mixtures, acids and alkalis, light and colour,
  the carbon cycle, strong evidence, fiction and history, speeches and media, argument, informative and narrative
  writing), and in-world challenges (a periscope to build, a Sankey of a furnace, a key for the worlds' animals).

## The full suite
`tests/run_tests.sh` on this branch at 6c68bbbe (all 13 units written): **8,867 tests in 971 scripts: 8,863 passing,
2 failing, 2 risky** (the two world tests that never assert, as before), no script errors. The two failures were world
tests under the shared PC's load: `test_world_bulk_edits.gd::test_scattered_cells_go_one_by_one` and
`test_world_sync.gd::test_edits_from_an_earlier_session_reach_the_guest_by_a_diff` (the Saturn's rings branch logged the
same file as a load flake the same day). Run again on their own they pass (13 of 13), and this branch changes only the
School's files (`data/school`, `core/school`, `ui/school`, their tests and docs). A trial merge into `lead-merge` at
09ac5d3a (`git merge-tree`) has no conflicts.
