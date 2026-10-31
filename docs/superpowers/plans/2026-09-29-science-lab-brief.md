# The Science Lab — the agent's brief (spec §23, owner #74)

You are building **the Science Lab** for EasyCraft, a Godot 4.7.2 (typed GDScript) + Voxel Tools game for children: a
lab bench block that opens a page of real experiments, each done in three steps (predict, try it, what happened and
why) and kept in the Lab Book. Work autonomously; do not ask questions (decide, and note rulings with their cost if
wrong in your notes file).

## Start
1. Your worktree was created from some commit; first run `git reset --hard lead-merge`. Check `git log --oneline -3`
   (spec §23 must be in `docs/superpowers/specs/2026-09-23-realm-hoppers-design.md`). Then `nice godot --headless
   --path . --import` once.
2. Read `CLAUDE.md`, `docs/DEVELOPMENT.md`, spec §23 (your feature), §22 (the School: its data-first style, the
   content test, `SchoolPicture` drawn from data, `ReadAloud`), §6 (fair-fun rules), §3c (our own look).
3. Study: the School (`core/school/curriculum.gd`, `ui/school/school_screen.gd`, `ui/school/school_picture.gd`,
   `tests/unit/test_school_content.gd`), the books (`ui/hud/secret_book.gd` tabs, `ui/books/space_book_page.gd`,
   `core/books/wonder_data.gd`), blocks (`data/blocks/block_ids.gd`, `world/block_library.gd`, a `*_page.gd` such as
   `data/blocks/smart_page.gd`, `tools/make_atlas.gd` / `tools/make_space_atlas.gd` for pixel tiles and
   `tools/make_realistic_atlas.py` for the realistic twin), how a block opens a panel when tapped (the crafting table,
   the Books' bookshelf, a chest: grep `interact` / `on_block_tapped` in `scenes/sandbox.gd` and `world/`), crafting
   recipes (`core/crafting/`), village houses (`world/generators/mouse_villages.gd`).

## Your allocation (fixed)
- One block: **the lab bench**, on a free atlas page (check `BlockLibrary` and every `*_page.gd`; pages 3-7 or 18+ are
  candidates — 18 may be taken by Mars, so prefer 19 if free) and a free id range the lead has not given away (ids
  352-367; check `BlockIds.COUNT`).
- New files under `core/lab/`, `ui/lab/`, `data/lab/`, `tests/unit/test_lab*.gd`, `tests/integration/test_lab*.gd`,
  notes `docs/devlog/parts/science-lab.md`. Small, clearly marked hooks in `scenes/sandbox.gd` (the tap on the bench),
  the Secret Book (a LAB tab or a page), the School's unit page (TRY IT IN THE LAB), crafting and villages.
- Never touch the School's content (`data/school/*`), the Star Map (`ui/space/*`, `core/rules/star_map.gd`) or other
  universes.

## What to build (spec §23.1)
- Experiments as data (`data/lab/<id>.json`: id, title, units (School unit ids it goes with), predict {prompt,
  choices, answer}, the small scene's data, result words, why card), with a content test (words: British spelling,
  kind, English only, the letters the School allows; every unit id exists in the outline; every scene can be drawn).
- The six first experiments: float or sink, magnetic or not, melting and freezing (a thermometer in °C), mixing colours
  (paint and light), a fair test of what plants need (over two game days), a simple circuit (battery, wires, bulb,
  switch; a gap stops it). Facts must be correct.
- The Lab screen (a big card per experiment; 64 px touch targets at least; read aloud), each experiment's small 2D scene
  the child works with taps (drag is optional; taps must always work), the three steps, never a "wrong" mark for a
  prediction.
- The Lab Book: a page of the book (a tab or inside the Space/Secret Book's tabs: pick the one that fits the 720 px
  height; tests exist for the book's fit) with each experiment's prediction, result and a star; saved in the profile
  (backed up and merged without loss, like `WonderData`).
- Links both ways with the School: TRY IT IN THE LAB on a unit's page when an experiment lists that unit (only when a
  lab bench is reachable? decide: simplest is that the School's button opens the Lab directly), LEARN MORE from the Lab.

## Tests and checks (TDD)
- Failing tests first for the rules and data, then the UI (sizes fit 1280 × 720, every step reachable by taps).
- After new class_name scripts: `nice godot --headless --path . --import 2>&1 | grep -iE "parse error|script error"`
  prints nothing. Single tests: `tests/run_tests.sh -gtest=res://tests/...`. GDScript gotchas: no `match` in lambdas;
  typed vars from untyped array indexing need explicit types.
- A picture tool like `tools/star_map_shots.gd` for the Lab's screens (windowed; save PNGs to a temp folder) and look at
  them: our own friendly look, readable words.
- At the end run the FULL suite once: `tests/run_tests.sh > /tmp/<yourname>-suite.log 2>&1; tail -30`, fix what you
  broke. Never open the Godot editor or an emulator; never touch adb. Never merge or push. Never run more agents.

## Finish
- Notes in `docs/devlog/parts/science-lab.md`; spec §23 "As built" lines.
- Commit on your branch, each message ending with the line:
  `Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>`
- Report: branch, commits, what a child sees, the suite's result, what the lead must check on the emulator.
