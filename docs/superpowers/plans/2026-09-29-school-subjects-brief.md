# A grade's subjects — the reusable agent brief (owner #70, #73; spec §22.4b)

The lead fills in **GRADE** (4-8) and **SUBJECTS** (e.g. "history, geography, citizenship"; or "maths, science, english:
the research's new units only") when starting an agent, and gives it this file.

You are writing the School's grade **GRADE** lessons for **SUBJECTS** in EasyCraft, a Godot 4.7.2 (typed GDScript) game
for children. The owner: the School must cover a full school programme and teach real things; it never ends (#71).
Work autonomously; do not ask questions (decide, and note rulings with what they cost if wrong in your notes file).

## Start
1. Your worktree was created from some commit; first run `git reset --hard lead-merge`, check `git log --oneline -3`,
   then `nice godot --headless --path . --import`.
2. Read `CLAUDE.md`, `docs/DEVELOPMENT.md` (the School section: data, every exercise type, sounds, the content test),
   spec §22 and §22.4b-c, and the research `docs/design/school-curriculum-research.md` §5.3 (how every unit is
   taught), §5.4 (safety and neutrality), §5.5 (rulings) and §6.x Grade GRADE (your units' goals and frameworks; the
   outline in `data/school/gradeGRADE.json` already has them, "Coming soon" until written).
3. Study the written units of the same subjects in grade 3 (`data/school/g3/<subject>/*`) and, for maths, science and
   English, grade GRADE's own written units (`data/school/gGRADE/<subject>/*`): match their style, and build on what
   grade 3 taught (the research's spiral: name what a unit builds on and what comes next). Notes of earlier agents:
   `docs/devlog/parts/m8-grade3-*.md`.

## Your job
- Every unit of your SUBJECTS in grade GRADE that has no `file` yet: one file `data/school/gGRADE/<subject>/<unit
  id>.json` = {id, lesson: [{text, picture?, sound?}], exercises: [...], generators: [...]}, linked in
  `gradeGRADE.json` with `"file": "gGRADE/<subject>/<id>.json"` (touch only your units' `file` fields; keep the tab
  indentation; you may sharpen a title or a goal, keeping ids; never change a written unit).
- Each unit: a lesson of 4-8 cards (a quick memory question first; one idea per card; a worked example; a "try it in
  the world" idea or what comes next last), real and correct content for the grade's age (the research's §6.2 table),
  pictures where they help; at least 12 hand-written exercises across levels 1-3 with at least two types (choice,
  truefalse, number, order, build, point, sort, match, robot, rhythm; sounds where listening is taught), each with a
  hint (a strategy, never the answer) and an explain (the worked answer).
- Generators where a subject calculates or drills (maths above all: endless practice): a new source
  `core/school/gen/gGRADE_<short>_gen.gd` ("gGRADE<letter>", a letter no source of that grade uses yet), registered at
  the END of SOURCES in `core/school/school_gen.gd`, seeded, level 1-3, with hint, explain and `data`, used by a written
  unit, tested in `tests/unit/test_gGRADE_<short>_gen.gd` (work every answer out again from `data`).
- Add `tests/unit/test_school_content_gGRADE_<short>.gd` with a test that every one of your units is written and meets
  the bar (3+ cards, ≥ 12 hand-written exercises, levels 1-3, two types, RoundPlan over seeds gives ≥ 12 distinct
  prompts, no hand-written exercise twice in a round). Write it FIRST and watch it fail.
- Safety (research §5.4): religion as culture and belief, no politics or living people, no brands or other games, no
  disputed borders; hard history (grades 7-8) with respect, listed for grown-ups; nothing about puberty or human
  reproduction; drugs, alcohol and gambling only from grade 5, factual.

## Words (the content test enforces these)
British spelling, kind words, English only, only ASCII plus × ÷ − ° ² ³ ½ ¼ ¾ • ’ “ ” — … √ ≤ ≥ π · (add a letter to
`ALLOWED` in `tests/unit/test_school_content.gd` only if a real name needs it and the School's font draws it). Check the
facts and the arithmetic of everything you write with a small script where you can;
`test_the_sums_in_the_lessons_are_right` checks plain sums.

A helper you may copy: `/tmp/claude-1000/-home-giorgi-Documents-game/39eee3cb-6bee-43a3-b86d-48d101218846/scratchpad/school_build.py`
(exercise helpers, limits and words checks, writes and links unit files). Copy it into your own scratch file.

## Testing and PC rules
- After new class_name scripts: `nice godot --headless --path . --import 2>&1 | grep -iE "parse error|script error"`.
- Single tests: `tests/run_tests.sh -gtest=res://tests/unit/<file>.gd`. GDScript gotchas: no `match` in lambdas; typed
  vars from untyped array indexing need explicit types.
- Look at your pictures and exercises with `tools/school_shots.gd -- --unit=<id> --exercises` (windowed; it writes PNGs
  to a private user folder) if your environment can open a window; otherwise say so in your report.
- At the end the FULL suite once: `tests/run_tests.sh > /tmp/<yourname>-suite.log 2>&1; tail -30`; fix what you broke.
- Never open the editor or an emulator; never touch adb. Never merge or push. Never run more agents.

## Finish
- Notes in `docs/devlog/parts/m8-gradeGRADE-<short>.md`. Commits on your branch, each ending with:
  `Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>`
- Report: branch, commits, unit and exercise counts, the full-suite result, what the lead must fix when merging.
