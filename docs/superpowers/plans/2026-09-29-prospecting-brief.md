# Prospecting and mining: the real world's riches, found by quests — the agent brief (owner #80; spec §26)

The lead fills in **PART** when starting an agent (the first: "Earth: gold, copper, iron, coal, oil and salt in Green
Meadows and the Sandstorm Desert"; then "the Moon's and Mars's ice and metals"; then more).

You are building **PART** of prospecting and mining in EasyCraft (Godot 4.7.2, typed GDScript, Voxel Tools), a game for
children. The owner: "we should have minnings on planets and on eath, where we find preious metals, petrols and other
things like a real world has. to find such places you need find them with quests which include solving problems, quizes,
maps, advantures, findings and other exciting things". Work autonomously; do not ask questions (decide, and note rulings
with what they cost if wrong in your notes file).

## Start
1. `git reset --hard lead-merge`; `git log --oneline -3`; `nice godot --headless --path . --import`.
2. Read `CLAUDE.md`, `docs/DEVELOPMENT.md`, spec **§26 (your design)**, §25 (the core loop: gold and the rocket), §3c,
   §4 and `docs/design/` (fair fun). Study what exists: the ores and their generation (the meadows' and desert's
   generators, `BlockIds` ores, Survivor's selling, `ShopRules`), quests and the adventure board (M3 Task 12), secrets
   and MY MAP, the Secret Book, `SpaceSights`, Tilly's stock, `Recipes` and the furnace/workbench, the School's
   exercise types (`ExerciseCheck`: a quest's quiz can be School exercises shown in the world).

## Allocation
- Block atlas page(s) and ids: the lead gives them when starting you (**IDS**), past every page other agents hold.
- New files: `core/prospecting/*` (pure rules: deposits, quests' steps, surveys, refining), `world/prospecting/*`
  (placing deposits, the mine, the oil well, the refinery), `ui/prospecting/*`, tests `tests/**/test_prospect*.gd`,
  `test_deposit*.gd`, `test_refin*.gd`, a smoke `tools/prospecting_smoke.gd`, notes `docs/devlog/parts/prospecting-<part>.md`.
- Small additions elsewhere (generators, Tilly's stock and prices, recipes, MY MAP). Never touch the School's units,
  the missions, the flight, the invite system, the colonies or the wonders (other agents).

## What to build (spec §26)
- **Deposits where real geology puts them**, rich and hidden (seeded, the same for a seed): each kind with its real
  setting and its telltale signs a child can learn to read.
- **Prospecting quests** (at least one per resource of PART): 4-7 steps each, mixing a map to read (coordinates, the
  compass, the scale), a clue from real geology, a problem (a survey's echo time to depth; a detector's beeps), a short
  quiz of what the quest taught (School-style exercises), and an adventure to reach it; the last step marks the deposit
  on MY MAP; gold for finishing (in the core loop's table if it exists on your base, else your own table).
- **Mining and refining** in real steps with the right tool (a mine for a vein, panning for river gold, an oil well
  with a derrick and a pump jack, a quarry), then refining (smelting ore to metal; oil to fuels, kerosene for rockets,
  plastics; salt), each step with one real fact; what comes out sells at a fair price (never a loop that mints gold)
  or goes into building.
- **Friendly and fast**: never dangerous or scary (no explosions, no gas leaks; oil is shown clean and careful, with
  one honest line that burning oil warms the planet, which is why rockets and cars are learning cleaner fuels);
  generators no slower than now (bench), within the performance budget.

## Tests and checks (TDD)
Failing tests first (deposit placement and signs, each quest's steps and answers, surveys' maths, refining's recipes and
prices, save and load). `--import` and grep Parse Error after new class_name scripts. Single tests with
`tests/run_tests.sh -gtest=…`; the smoke 0 fails (a private XDG_DATA_HOME containing "smoke"); windowed shots if you can
open a window; the FULL suite once at the end. Never open the editor or an emulator; never touch adb. Never merge or
push. Never run more agents.

## Finish
Notes (rulings, the facts with sources, what a child sees and does, bench numbers, what the lead must check on the
emulator); spec §26 "As built"; `docs/DEVELOPMENT.md`. Commits ending with
`Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>`. Report: branch, commits, what a child sees,
the smoke and full-suite results, what the lead must look at.
