# The world's wonders — the agent brief (owner #78; spec §24)

The lead fills in **TOUR** (the first: "the Seven Wonders of the Ancient World"; then "the New Seven Wonders", "wonders
of nature", "wonders people built later") when starting an agent, and gives it this file.

You are building **TOUR** in EasyCraft (Godot 4.7.2, typed GDScript, Voxel Tools), a game for children. The owner:
"we must have world wonders, all wonders in the game. so all things must be educational in the game, close to real
world". Work autonomously; do not ask questions (decide, and note rulings with what they cost if wrong in your notes).

## Start
1. `git reset --hard lead-merge`; `git log --oneline -3`; `nice godot --headless --path . --import`.
2. Read `CLAUDE.md`, `docs/DEVELOPMENT.md`, spec **§24 (your design)**, §21 and §21b (how a world is a universe with a
   descriptor, shape, generator, secrets, sights and cards), §3c (our own look), §22.4 safety (religion as culture and
   belief, no living people, no brands). Study Mars end to end as the model of a world with landmarks and sights that
   teach (`world/universes/mars.gd`, `MarsTerrain`, `world/space_sights.gd`, `docs/devlog/parts/cosmos-mars.md`), and a
   home world's generator (Green Meadows) for an Earth-like ground.

## Allocation (fixed; for the first tour — later tours get theirs from the lead)
- **World 41, "Wonders of the World"**: Earth's own range 41-60 (`UniverseRules.MAX_UNIVERSE` 60; find every place that
  assumes 40 — the save slots, the registry, the Star Map, the server's checks if any — and move it, with tests). It is
  free for everyone, peaceful, with Earth's gravity, sky and animals.
- Block atlas pages **33 and 34**, block ids **576-607** (`BlockIds.COUNT` and `NEXT_PAGE_FIRST_ID` to at least 608;
  pages 30-32 belong to other agents: take your ids even if COUNT is lower on your base; the lead merges the numbers).
  Reuse the game's blocks where they fit (sandstone, stone, marble-like, gold); new ones only for what is missing.
- New files: `world/universes/wonders.gd` (+ its blocks, shape/terrain, sights, secrets), `core/books/wonders_passport*`
  (the Books' page), `data/blocks/pages/wonders*.png` (+ `_albedo`, `_normal`), tests `tests/**/test_wonders*.gd`, a
  smoke `tools/wonders_smoke.gd`, notes `docs/devlog/parts/wonders-<tour>.md`.
- Shared files with small additions: the registry, `UniverseRules`, `StarMap` (the Earth card: "Wonders of the World:
  LAND"), the Books (a WONDERS page), `data/blocks/block_ids.gd`, `world/block_library.gd`. Never touch the School's
  units, the missions (another agent), the colonies (another agent), other worlds.

## What to build (spec §24)
- **The tour**: every wonder of TOUR standing along a path from the landing spot (signposts, a map in MY MAP), each at
  a size a child can walk round, walk into where the real one can be entered, and climb where it is safe; recognisable
  from its real shape and colours (our own blocks' look; no copied art).
- **Real stories**: at each wonder, sights that say real facts (when and who built it, how, how big, what happened to
  it; for the lost ancient ones, that they are gone and what people believe they looked like; for the Hanging Gardens,
  that no one knows for sure they existed), checked against good sources (encyclopaedias, museums, UNESCO), listed in
  your notes. People of history only, never living people. Religion as culture and belief.
- **The Wonders Passport**: a page of the Books with a stamp for each wonder visited (save it in the profile the way the
  Space Book saves bodies: merged by the backup without loss).
- **Secrets**: a treasure or a hidden room at some wonders (the pyramid's chambers!), each find ending with a real fact.
- **Getting there**: the Star Map's Earth card says "Wonders of the World: LAND" (the route rules of the missions agent
  may later ask for a plane; for now, land from the Star Map).
- **Fast**: the generator no slower than Green Meadows' (bench it with `tools/bench_generator.gd`); the wonders within
  the performance budget.

## Tests and checks (TDD)
Failing tests first (the world's descriptor and number range, each wonder's place and shape, its facts, the passport,
the blocks in both styles, save and load). `--import` and grep Parse Error after new class_name scripts. Single tests
with `tests/run_tests.sh -gtest=…`. The smoke must print 0 fails (a private XDG_DATA_HOME containing "smoke"). Look with
`tools/space_shots.gd -- --universe=41` (windowed, both styles) if you can open a window, else say so. The FULL suite
once at the end. Never open the editor or an emulator; never touch adb. Never merge or push. Never run more agents.

## Finish
Notes (rulings, facts with sources, what a child sees, bench numbers, what the lead must check on the emulator); spec
§24 "As built"; `docs/DEVELOPMENT.md`; `assets/CREDITS.md` if you add anything. Commits ending with
`Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>`. Report: branch, commits, what a child sees, the
smoke and full-suite results, what the lead must look at.
