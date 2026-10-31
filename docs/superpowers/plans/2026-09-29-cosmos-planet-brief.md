# A real planet or moon as a world — the reusable agent brief (spec §21b.2)

The lead fills in **BODY** (e.g. Europa), **WORLD** (its number, `SpaceRules`), **PAGE** (a free block atlas page) and
**IDS** (a free block id range of 16) when starting an agent, and gives it this file. Block ids 400-511 are the items'
(`BlockIds.RESERVED_FIRST`/`RESERVED_END`): the next pages are 29 (ids 512-527), 30 (528-543) …; move
`BlockIds.NEXT_PAGE_FIRST_ID` on when a page is taken. Mars (world 19) is the model:
`world/universes/mars.gd`, `mars_blocks.gd`, its shape and secrets, `world/space_sights.gd`, `tools/mars_smoke.gd`,
notes `docs/devlog/parts/cosmos-mars.md`.

You are building **BODY** as world **WORLD** of EasyCraft's cosmos (Godot 4.7.2, typed GDScript, Voxel Tools). The owner:
"cosmos, stars and planets where each planet is a different universe" (#72), "closer to real worlds so the player
starts learning real things" (#74). Work autonomously; do not ask questions (decide, and note rulings with what they
cost if wrong in your notes file).

## Start
1. `git reset --hard lead-merge`; `git log --oneline -3`; `nice godot --headless --path . --import`.
2. Read `CLAUDE.md`, `docs/DEVELOPMENT.md`, spec §21 and §21b (BODY's row in §21b.2: what it looks like and what to
   find), the Mars notes, and the Moon's and Mars's files end to end.

## Allocation (fixed)
- World **WORLD** (`SpaceRules`: add it to `WORLDS`; its body in `StarMap` already has this world number), its entry in
  `UniverseRegistry.SPACE`, block atlas page **PAGE** (check it is free), block ids **IDS** (`BlockIds.COUNT` moves
  past them). New files: `world/universes/<body>.gd`, `<body>_blocks.gd`, `data/blocks/pages/<body>.png` (+ `_albedo`,
  `_normal`), its shape (a planet kind in `SpaceShape` or its own class), its secrets, tests `tests/**/test_<body>*.gd`, a
  smoke `tools/<body>_smoke.gd` (the Mars smoke's pattern), notes `docs/devlog/parts/cosmos-<body>.md`.
- Never touch the School, the Science Lab, the Star Map UI, or other worlds' files beyond the registry lines.

## What to build
- **Real:** its real gravity (spec §21b.2's number), colours, landmarks and sky (what hangs in it: Jupiter over Europa
  and Io, Saturn over Titan, Neptune over Triton, Charon over Pluto; `SkyCycle.show_planet` with `moons`, as Mars does),
  `photo_sky = false` when its sky is not Earth's, `lifeless = true` unless the spec says otherwise (no animals, no
  monsters; peaceful), sounds that fit (existing ambience and classical pieces only; no new audio files unless CC0).
- **To find:** its landmarks as secrets and sights (the Mars pattern: each find's banner ends with a real fact; MY MAP
  shows them once found; the Space Book flags the body when the child lands, already wired).
- **Friendly:** every step climbable at its gravity (a jump's height there), a landing pad and the portal home, never
  dark and scary (spec §3c); facts written for 8-14-year-olds and checked against sources (NASA, JPL, ESA, USGS…),
  listed in the notes.
- **Fast:** its generator no slower than the Moon's (bench it: `tools/bench_generator.gd`, record the numbers).
- **Look:** `tools/space_shots.gd -- --universe=WORLD` (windowed) in both styles if you can open a window; describe what
  you saw, or say you could not.

## Tests and checks (TDD)
- Failing tests first (descriptor, shape, blocks in both styles, secrets and sights, `SpaceRules.WORLDS`, `StarMap`
  says LAND). `--import` and grep Parse Error after new class_name scripts. Single tests with `tests/run_tests.sh
  -gtest=…`. The smoke must print 0 fails (a private XDG_DATA_HOME containing "smoke"). The FULL suite once at the end.
- Never open the editor or an emulator; never touch adb. Never merge or push. Never run more agents.

## Finish
- Notes; spec §21b.2 "As built" row. Commits ending with
  `Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>`.
- Report: branch, commits, what a child sees, bench numbers, the smoke and full-suite results, what the lead must look
  at.
