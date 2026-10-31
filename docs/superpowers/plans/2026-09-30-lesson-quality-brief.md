# The School's lessons, better — the agent brief (owner #94: "lessons quality improvements up to grade 7")

You are improving the **quality of the School's written lessons** in EasyCraft (Godot 4.7.2, typed GDScript), a game
for children: grades 3-6 (every subject, 546 units, written by many agents in a few days) and grade 7's written units.
The owner (2026-09-30): "lets pause lessons on grade 7 and continue game improvement, lessons quality improvements up to
grade 7". No new units: make the ones we have **correct, clear, well pictured, varied and a joy to learn from**. Work
autonomously; do not ask questions (decide, and note rulings with what they cost if wrong in your notes file).

## Start
1. `git reset --hard lead-merge`; `git log --oneline -3`; `nice godot --headless --path . --import`.
2. Read `CLAUDE.md`, `docs/DEVELOPMENT.md` (the School section: the data, every exercise type, pictures, sounds, the
   content tests), spec §22 (the School), the research `docs/design/school-curriculum-research.md` (§5.3 how every unit is
   taught, §5.4 safety and neutrality, §5.5 rulings, §6.2 the age table), `docs/design/` (fair fun), and the agents'
   notes `docs/devlog/parts/m8-grade*.md`.

## What to do
1. **Measure every unit** with a tool of your own (`tools/school_audit.py` or a `--script`), written first and kept:
   per unit — cards (4-8), words per card and the reading level against the grade's age (a simple readability score),
   cards without a picture where a picture would teach, the memory question first and the "try it in the world / next"
   last, exercises per level (1-3) and their types (at least two, better three or more), hints and worked answers,
   near-duplicate exercises, generator use, sounds where listening is taught, the facts' sources in the notes, the spiral
   (what it builds on, what comes next). Print a table per grade and a list of **the weakest units** (a score); write
   the first report into your notes.
2. **Fix, weakest first**, in rounds, and measure again after each round: rewrite dense or long cards (one idea a card,
   short sentences, a worked example), add or improve pictures (use existing picture kinds; add a kind only where none
   fits, in a new file `ui/school/school_picture_quality.gd`, never reusing a kind name), add exercise variety (build,
   sort, match, order, point, label where they teach better than choice), fix anything wrong (check facts; maths answers
   are worked out by the tests), make hints kinder and more useful, make "try it in the world" point at something the
   game really has (the Launch Site, the Science Lab, MY MAP, the planets, the wonders, prospecting). Keep every unit's
   id and its generators; change a unit's file only to make it better.
3. **The School's teaching, beyond the files** (small and safe): after a wrong answer, show the worked answer and why
   (if a unit has one and it isn't shown); a short "well done" variety; a card's picture never cut off at phone size
   (`tools/school_shots.gd` in a window if you can open one). Say what you changed in the notes.
4. **Report the before and after** per grade: the audit's numbers, the units rewritten, the facts fixed (with sources).

## Allocation and rules
- Yours: `data/school/g3..g7/**/*.json` (the written units only; never add units; grade 7's unwritten units stay paused),
  the audit tool, `ui/school/school_picture_quality.gd` if needed, tests `tests/**/test_school_quality*.gd`, notes
  `docs/devlog/parts/lesson-quality.md`. Small changes to the School's UI where they teach better (say which).
- Other agents now: **EasyCraft Shorts** (makes "Lesson in a minute" Shorts from these lesson files at run time: keep
  the lesson format; don't rename fields), **animations** (may add animated drawing to picture kinds: don't edit the
  existing `school_picture_*.gd` drawing code except to fix a real bug, and say so).
- The rules: facts checked (sources in notes); safe and neutral (§5.4); English only; only people of the past named; no
  guilt words (`test_no_guilt_words`); no brand names. TDD for code; the content tests stay green after every round.
  Never open the editor or an emulator; never touch adb; never merge or push; never start agents. One full suite at
  the end (tests/run_tests.sh waits for a PC-wide slot); the School's tests after every round
  (`tests/run_tests.sh -gtest=` with the `test_school*` and generator tests). After merging the lead runs
  `python3 tools/school_outline.py --write docs/superpowers/plans/2026-09-28-school.md`.

## Finish
Notes (the audit before and after, the units rewritten and why, facts fixed with sources, rulings); `DEVELOPMENT.md`
(the audit tool); commits ending with `Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>` (commit
each round). Report: branch, commits, the audit's before/after per grade, what changed, the full suite's result, what the
lead should look at.
