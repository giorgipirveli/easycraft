# Grade 3 health and PE, design and technology, projects: every unit written (owner #70, #73; 2026-09-29)

The owner: "start from grade 3 and finish all grades accordingly" and "research school programs, world leading schools
and create better school program". The research (`docs/design/school-curriculum-research.md` §6.3) lists grade 3's
Health and PE (11), Design and Technology (9) and Projects (3) units; this agent wrote all 23 of them, in parallel with
the agent writing grade 3's computing, art and music. Brief: `docs/superpowers/plans/2026-09-29-grade3-life-brief.md`.
Branch `worktree-agent-a43ea7a8526ca2790`, from `lead-merge` 3bf89b6 ("code the robot").

## What was written
| Subject | Units | Lesson cards | Hand-written exercises | Generators used |
|---|---|---|---|---|
| Health and PE | 11 | 86 | 163 | `g3p.count_claps` (Dance), `g3p.pulse_minute` (Your heart), `g3p.food_sort` (Eating well), `g3p.sleep_hours` (Sleep) |
| Design and Technology | 9 | 72 | 130 | `g3p.food_source` (Where food comes from), `g3p.recipe_scale` (A healthy snack), `g3p.cube_net` (Boxes and nets) |
| Projects | 3 | 23 | 42 | `g3p.park_fence` (Habitat park), `g3p.map_distance` and `g3h.grid_ref` (Map my village), `g3p.camp_kit` (Stone Age camp) |
| **All** | **23** | **181** | **335** | 10 new generators (`g3p`), each at levels 1-3, plus one borrowed (`g3h.grid_ref`) |

- **Files:** `data/school/g3/<subject>/<unit>.json`, linked from `data/school/grade3.json` (only these 23 units' `file`
  fields changed; titles, standards and goals kept; tab indentation kept).
- **Every unit:** a lesson of 7-8 cards that opens with "Quick memory: …?" (a question from an earlier unit, its answer
  in brackets) and ends with "Try it in the world: …" (research §5.3 rules 1 and 8); 14-17 hand-written exercises (the
  projects 14) at levels 1, 2 and 3 (at least 4, 4 and 5 of them, so a round never repeats one), of 4-7 kinds:
  choice (174), true or false (69), order (23), sort (23), match (21), number (19) and build (6). Every exercise has a
  hint (a strategy, never the answer) and an explain (the worked answer).
- **Health and PE** (England PE and RSHE, SHAPE America, NHES, CASEL): run, jump, throw, catch (the how, with stick
  figures: run tall, spring landing, side-on throw with the opposite foot, "give" with the ball); balance and roll
  (still shapes for a count of three, base, points and patches, star/tuck/straight/pike, log and egg rolls on a mat,
  a sequence); playing fair (a good sport, winning and not winning well, attack and defence, sorting out a disagreement);
  dance (the beat, counting in eights, tempo, x-and-dash rhythms, levels, pathways, dynamics, motifs, unison, canon,
  mirroring; **9 sounds** to LISTEN to); your heart and exercise (the size of your fist, feeling the pulse with two
  fingers, 15 seconds × 4, before and after running, warm up and cool down, at least 60 minutes a day; a heartbeat and a
  fast pulse to hear); eating well (the food groups and their jobs, the balanced plate, 5 a day and the palm-sized
  portion, potatoes are starchy, treats now and then, water and 6 to 8 drinks a day, swaps); sleep (9 to 12 hours, what
  sleep does, counting hours across midnight, a bedtime routine, screens off an hour before); germs and hygiene (catch
  it, bin it, kill it; hands for about 20 seconds with soap; when to wash; teeth twice a day for 2 minutes, spit don't
  rinse); naming feelings (body clues, name it to tame it, flower-and-candle breathing, telling someone you trust,
  others' feelings); staying safe (the road crossing steps, lifeguards and the red and yellow flags, float like a star,
  sun, fire and smoke, safe people when lost, private details online); getting help in an emergency (999 in the UK, 911
  in the US, 112 in much of Europe, "learn yours with a grown-up"; which service, what is wrong and where; stay on the
  line; joke calls; first aid for a cut, a burn and a nosebleed).
- **Design and Technology** (England D&T, Finland crafts and home economics, Japan handicrafts, China labour): the design
  cycle (a brief, a prototype, idea-plan-make-test-improve); strong structures (frame and shell, triangles against the
  pushed square, folding and rolling card, a wide base, stiff and strong, a fair test of paper bridges); levers and
  linkages (pivot, effort, load, far from the pivot is easier, fixed and loose pivots, moving pictures); sewing and
  weaving (threading and knotting, running stitch, backstitch, overstitch, needle safety, warp and weft, over one and
  under one, stripes); tools and safety (the right tool, bench hook and clamp, goggles, carrying and passing scissors,
  one person one tool one job, card corner triangles); where food comes from (grown, reared, caught; made from; the UK's
  seasons, food in season); a healthy snack (getting ready, ingredients and method, rainbow fruit kebabs, the bridge hold
  and the claw grip, scaling a recipe, allergies, clearing up); boxes and nets (6 faces, 12 edges, 8 vertices, which nets
  fold, 11 nets, cuboid and pyramid nets, tabs and scoring; **build a net of a cube on the block board**); designs that
  changed the world (the wheel over 5,000 years ago, spokes and tyres, paper in China about 2,000 years ago, the printing
  press about 1440, the light bulb about 1879 (Swan and Edison), the zip in 1913 (Sundback), how to judge a design).
- **Projects** (Finland's modules, Japan's integrated study, IB PYP, Cambridge GP): a habitat park (animals' needs,
  area 6 × 4 = 24, a fence of 20 m, 24 fence blocks round the outside in the world; builds: area 12 with fence 14, area
  18 with fence 18); map my village (survey, from above, key, grid, north arrow, scale; a village map to read; build the
  4 × 4 green); a Stone Age camp (hunter-gatherers, skin tents, mammoth-bone huts, fire and its stone ring, flint,
  bone needles, hunted and gathered food, fact or opinion; build the other half of the tent, a mirror build).

## New: pictures, a net rule, a build goal (the brief allowed a picture file; the goal is small and tested)
- **`SchoolPictureLife`** (`ui/school/school_picture_life.gd`, called from `SchoolPicture.problem` and `_draw` like
  `SchoolPictureG5`): `net` (squares of card, faces lettered A-F), `plate` (the healthy plate with its key and a glass of
  water, one part hidden as "?"), `lever` (bar, pivot, crate, effort arrow, tags such as A/B/C), `frame` (square, braced,
  triangle, pushed), `weave` (warp and weft, over and under, row numbers, weft colours), `stitch` (running with the
  needle, back, over), `pose` (12 stick figures: stand, run, crouch, jump, land, throw, catch, star, stork, tuck,
  stretch, clap). Test: `tests/integration/test_school_picture_life.gd` (samples, broken data, every size, every pose a
  whole figure standing on the ground, a jump in the air).
- **`CubeNet`** (`core/school/cube_net.gd`): rolls a cube across the squares; 6 joined squares, no 2 × 2 block, six
  different faces = a net; `faces()` and `opposite()`. **BuildCheck goal `cube_net {}`**: six blocks that fold into a
  cube, given blocks kept; `example()` grows a net from the given squares (each shape tried once). Test:
  `tests/unit/test_cube_net.gd` grows all 216 fixed hexominoes and finds that exactly 11 of the 35 free ones fold.
- **Generators** (`core/school/gen/g3_health_gen.gd`, `G3HealthGen`, SchoolGen source "g3p", the last SOURCES line;
  seeded, levels 1-3, each with a hint, a worked answer and `data`): `pulse_minute` (30 s × 2, 15 s × 4, 10 s × 6, or a
  minute's beats ÷ 4; resting 70-100, after exercise 110-160), `sleep_hours` (across midnight, half past at level 2,
  "needs 10 hours, wakes at 7 am: when to sleep?"), `count_claps` (a rhythm to LISTEN to: how many claps), `food_sort`
  and `food_source` (sorts from food banks; level 3 adds potatoes, peas, nuts, lentils and made foods), `cube_net` (will
  it fold? which net folds? which face is opposite A?), `park_fence` (area, perimeter, a build of both, fence blocks with
  corners), `recipe_scale` (double, times 3 or 4, halve, via 1 or 2 people), `map_distance` (squares × scale, straight
  or along and then up), `camp_kit` (Stone Age camp or much later). Test: `tests/unit/test_g3_health_gen.gd` works every
  answer out again from `data` with its own food tables, its own lists of Stone Age things and its own 3D cube fold
  (vectors rotated, not CubeNet's table), and checks the 11 nets make 64 shapes turned and flipped.

## Tests
- `tests/unit/test_school_content_g3_life.gd` (written first; it failed with every unit "not written"):
  `test_grade_3_health_dt_projects_are_written_for_every_unit` (the outline's 11 + 9 + 3 units, 3+ cards, 12+ exercises
  (projects 10+), levels 1-3, two kinds, rounds that fill, never repeat a hand-written exercise and vary: 12+ distinct),
  `test_the_files_are_their_own`, `test_every_exercise_has_a_strategy_hint_and_a_worked_answer`,
  `test_every_lesson_starts_with_a_memory_question_and_ends_in_the_world`, `test_the_units_use_their_own_generators`
  (g3p; a project may borrow g3h; every g3p used), `test_dance_and_the_heart_can_be_heard`,
  `test_the_safety_facts_are_taught` (999, 911, 112, "grown-up", "where"; 20 seconds and soap; 9 to 12 hours; look,
  listen, float, shade), `test_health_is_taught_kindly` (no weight, calories, junk, naughty, bad food, puberty,
  reproduction or sex in any of the 23 units), `test_nets_have_pictures_and_projects_have_builds`.
- The shared `test_school_content.gd` passes with these units (validity, own answers only, pictures, sounds, kind and
  British words, the font's letters, plain sums).
- The unit files were made with a scratch Python script that applies the same checks before writing (lengths, words
  incl. extra US forms and brand names, letters, sums, levels 2/3/4, first and last cards, no spaced hyphen, which the
  speech would read as "minus").
- **The full suite** (`tests/run_tests.sh`, 2026-09-29): 751 scripts, 6,912 tests, 6,910 passing, 0 failing, 2 risky
  (not asserting, not this agent's: `test_the_column_cache_changes_nothing`, `test_chunks_meet_without_seams`), in 1,604 s.
- Pictures looked at with `tools/school_shots.gd` (windowed, own XDG folder) for 11 units: poses, plate, levers,
  frames, weaves, stitches, nets, the net builds and the tent mirror build.

## Rulings (decided here; cost if wrong)
1. **Stick figures for movement skills** (the brief: "the how, in words and pictures"): a `pose` picture of 12 named
   figures, not animations or photos. *Cost:* more poses are data (joint positions); a moving figure would be a new kind.
2. **The healthy plate follows the UK's guide** (about a third fruit and vegetables, about a third starchy foods, some
   protein, some dairy, a little oil; water; 5 a day; 6 to 8 drinks), the same food groups and jobs as grade 3 science.
   Foods are never "good" or "bad": treats are "now and then, in small amounts". *Cost:* another country's plate is a
   picture's shares and a card.
3. **Emergency numbers:** 999 (UK), 911 (US), 112 (much of Europe), always with "learn yours with a grown-up"; the
   exercises only ask the UK and US numbers directly (112 also works in the UK, so it is never a wrong choice there).
   *Cost:* other countries' numbers are table rows.
4. **Seasons are the UK's** ("In the UK, …"), as the geography agent did; the world has other seasons. *Cost:* a line.
5. **A fence round a park:** the perimeter in metres (1 block = 1 m) is the maths; in the world, fence blocks go round the
   outside, so a w × h park needs 2(w + h) + 4 blocks (one per corner). Both are taught. *Cost:* none.
6. **`cube_net` is a BuildCheck goal** (core, 30 lines and a test), because "build a net" is the D&T making task the
   block board suits best. *Cost:* if the lead prefers, the two build exercises can become picture choices.
7. **Projects may use `g3h.grid_ref`** (geography's generator) as projects join subjects. *Cost:* a line in the test.
8. **Heartbeat sounds:** a lesson card's "lub-dub" is `xx--` at tempo 150 (about 75 beats a minute); an exercise's fast
   pulse is claps at tempo 150 (150 a minute). *Cost:* numbers in the data.

## For the lead (merging)
- **`SortAnswer`'s legend does not wrap** (`ui/school/sort_answer.gd`, not this agent's to change): "Tap each one to put
  it in a group:  a  ·  b  ·  c" at 20 px is wider than the 560 px items for most group names, so the column grows and
  runs past the panel's right edge (seen on "Eating well"'s 3-group sort; measured with the fallback font, 28 grade 3
  hand-written sorts of every agent and the `g3p.food_sort` sorts are over 540 px). Fix: `legend.autowrap_mode =
  TextServer.AUTOWRAP_WORD_SMART` with `custom_minimum_size.x = ITEM.x` (or the group names on their own line).
- `tools/school_shots_steps.gd`'s `_force_answer` has no sort, match or build case, so a round's shots repeat the same
  sort, and a build's "shown" shot shows no worked answer.
- Conflicts to expect: `data/school/grade3.json` (the other grade 3 agent adds `file` lines to computing, art and
  music), `core/school/school_gen.gd` (both add a SOURCES line at the end), `ui/school/school_picture.gd` (both may hook
  a picture file in `problem()` and `_draw()`), `docs/DEVELOPMENT.md` (a bullet each at the end of the School section).
