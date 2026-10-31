# Grade 3 health and PE, design and technology, projects — the agent's brief (owner #70, #73; spec §22.4b)

You are writing the School's grade 3 **HEALTH AND PE** (`health_pe`, 11 units), **DESIGN AND TECHNOLOGY** (`design_tech`, 9)
and **PROJECTS** (`projects`, 3) lessons
for EasyCraft, a Godot 4.7.2 (typed GDScript) game for children. The owner: the School must cover a full school
programme ("start from grade 3 and finish all grades accordingly") and teach real things. Work autonomously; do not ask
questions (decide, and note rulings in your notes file).

## Start
1. Your worktree was created from some commit; first run `git reset --hard lead-merge`. Check `git log --oneline -3`
   (it must have "sounds for listening practice", 4f46a96, or later). Then `nice godot --headless --path . --import`.
2. Read `CLAUDE.md`, `docs/DEVELOPMENT.md` (the School section: data, exercise types incl. sort, match and sound),
   spec §22 and §22.4b, and the research `docs/design/school-curriculum-research.md` §5.3 (how every unit is taught:
   a quick memory question first, one idea per card, a strategy hint, a "try it in the world" idea), §5.4 (safety,
   neutrality: no living people, no brands, online safety every grade), §6.3 Grade 3 → Health and PE, Design and
   Technology, Projects (your units' goals; the outline in `data/school/grade3.json` already has them, "Coming soon").
3. Study written units as models: `data/school/g3/science/*`, `data/school/g3/english/*` (sort and match in use),
   `data/school/g4/*`; `core/school/exercise_check.gd` (types: choice, truefalse, number, order, build, point, sort,
   match; limits), `core/school/school_sound.gd` (tunes and claps: `{"kind": "notes", "notes": ["C4", "E4", "G4:2"]}`,
   `{"kind": "rhythm", "pattern": "x-x-xx--", "tempo": 90}` on any exercise or lesson card; LISTEN plays it),
   `ui/school/school_picture.gd` (picture kinds, e.g. grid, table, icon, shape), `tests/unit/test_school_content.gd`.

## Your job
- One file per unit: `data/school/g3/<subject>/<unit id>.json` = {id, lesson: [{text, picture?, sound?}], exercises:
  [...], generators: []}, linked in grade3.json with `"file": "g3/<subject>/<id>.json"` (only touch the health_pe, design_tech
  and projects units' `file` fields in grade3.json; keep its tab indentation).
- Each unit: a lesson of 4-8 cards teaching real, correct content for 8-9-year-olds, and at least 12 hand-written
  exercises across levels 1-3 with at least two types; every exercise has a hint (a strategy) and an explain.
  - **Health and PE:** movement skills (run, jump, throw, catch: the how, in words and pictures), balance and a
    sequence, playing fair, dance to a beat (**rhythm sounds** help), heart and exercise (feel your pulse: it goes up
    with exercise), eating well (food groups, a balanced plate, water), sleep (about 9-12 hours for this age), germs
    and hygiene (washing hands for about 20 seconds), naming feelings and calming down, staying safe (roads, water,
    sun, fire), getting help in an emergency (say what is wrong and where; the number depends on the country: 999 in
    the UK, 911 in the US, 112 in much of Europe: "learn yours with a grown-up"). Never shaming about bodies or food;
    no weight talk. Nothing about puberty or reproduction (research §5.4).
  - **Design and Technology:** the design cycle (idea, plan, make, test, improve), strong structures (triangles, frame
    and shell), levers and linkages, sewing and weaving (running stitch, over-under weave), tools and safety (with a
    grown-up), where food comes from (grown, reared, caught; seasons), a healthy snack recipe (steps in order, clean and
    safe), boxes and nets (which net folds into a cube: use pictures), designs that changed the world (the wheel, the
    zip, the light bulb; no brands). Link each to building in the game ("try it in the world").
  - **Projects (3):** each a real mini-project in the game's world using several subjects (the research's table:
    a habitat park, map my village, a Stone Age camp): a lesson that plans it in steps, exercises that check the
    thinking (area and perimeter of the park, map symbols and grid references, which tools and food a Stone Age camp
    needs), and a "try it in the world" build challenge; `build` exercises where a small build on the block board fits.
- Optional generators (e.g. "how many beats?", "higher or lower?", colour mixing): `core/school/gen/g3_health_gen.gd`
  (source "g3p"), registered at the END of SOURCES in `core/school/school_gen.gd`, seeded, level 1-3, with hint,
  explain and `data`, used by a written unit, tested in `tests/unit/test_g3_health_gen.gd` (work each answer out again
  from `data`).
- Add `tests/unit/test_school_content_g3_life.gd` with `test_grade_3_health_dt_projects_are_written_for_every_unit`
  (every unit has content, 3+ cards, ≥ 12 hand-written exercises (projects: ≥ 10), levels 1-3, two types, rounds that
  vary: RoundPlan over seeds gives ≥ 12 distinct prompts). Write it FIRST and watch it fail.
- Do NOT touch other subjects' files, `ui/school/*` (except a new picture kind file if you truly need one, e.g.
  `ui/school/school_picture_life.gd` for a plate of food groups or a net, hooked like SchoolPictureG5), or other agents' areas.

## Words (the content test enforces these)
British spelling (colour, centre, programme, favourite, grey, organise…), kind words, no other games' names, no brands
(no app, website or company names), no living people, only ASCII plus × ÷ − ° ² ³ ½ ¼ ¾ • ’ “ ” — … √ ≤ ≥ π ·. English
only. Facts correct.

A helper you may copy: `/tmp/claude-1000/-home-giorgi-Documents-game/39eee3cb-6bee-43a3-b86d-48d101218846/scratchpad/school_build.py`
(C/T/O helpers, limits and words checks, writes and links unit files: `build(3, "health_pe", UNITS)`; extend it for sort,
match, pictures and sounds). Copy it into your own scratch file.

## Testing and PC rules
- After new class_name scripts: `nice godot --headless --path . --import 2>&1 | grep -iE "parse error|script error"`.
- Single tests: `tests/run_tests.sh -gtest=res://tests/unit/<file>.gd`. Gotchas: no `match` in lambdas; typed vars from
  untyped array indexing need explicit types.
- At the end the FULL suite once: `tests/run_tests.sh > /tmp/<yourname>-suite.log 2>&1; tail -30`; fix what you broke.
- Never open the editor or an emulator; never touch adb. Never merge or push. Never run more agents.

## Finish
- Notes in `docs/devlog/parts/m8-grade3-life.md`. Commit on your branch, each message ending with:
  `Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>`
- Report: branch, commits, unit and exercise counts, the full-suite result, anything the lead must fix when merging.
