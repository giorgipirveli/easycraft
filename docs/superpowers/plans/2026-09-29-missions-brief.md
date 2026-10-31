# Missions: build a rocket to reach a planet — the agent brief (owner #78, #79; spec §21d, §25)

You are building **missions** in EasyCraft (Godot 4.7.2, typed GDScript, Voxel Tools), a game for children. The owner:
"we have to have a mission to mars, mission to moon and etc. where you must build a ship, rocket to get into planets,
which can be built by team or alone … all things must be educational in the game, close to real world", and (#79)
"at the end if you have sufficient gold you can build a rocket or space ship to get into another planets". Work
autonomously; do not ask questions (decide, and note rulings with what they cost if wrong in your notes file).

## Start
1. `git reset --hard lead-merge`; `git log --oneline -3`; `nice godot --headless --path . --import`.
2. Read `CLAUDE.md`, `docs/DEVELOPMENT.md`, and spec §21, §21b, **§21d (your design)**, §21e (context only) and §3c
   (our own look). Study how the game does the things you will reuse:
   - where to stand a building: `core/rules/theater_site.gd`, `entities/theater/*`, `scenes/sandbox.gd` `_setup_theater`
     (the seed's site, saved in `WorldMeta`, searched on a worker);
   - space travel: `world/space_director.gd`, `ui/space/space_panel.gd`, `core/rules/star_map.gd`, the sandbox's
     `travel` for space worlds, `WonderData.bodies` (SEEN/LANDED), `SpaceRules`;
   - blocks on their own page: Titan's (`world/universes/titan_blocks.gd`, `docs/devlog/parts/cosmos-titan.md`: page 29,
     the first past the items' ids, and how its blocks save, load, mesh and travel in gifts);
   - checking a build: `core/school/build_check.gd`; a block page's art: `tools/make_space_atlas.gd`,
     `tools/make_space_realistic.py`; the palette's rows, Tilly's stock, `Recipes`.

## Allocation (fixed)
- Block atlas page **32**, block ids **560-575** (the rocket parts). `BlockIds.COUNT` and `NEXT_PAGE_FIRST_ID` move to
  **576** (page 30 = Mercury 528-543 and page 31 = the colony domes 544-559 belong to other agents: if COUNT is lower
  on your base, still take 560-575 and set COUNT to 576; the lead merges the numbers).
- New files: `core/rules/rocket_check.gd` (pure), `core/rules/mission_rules.gd` (the missions table, the route rules),
  `core/rules/launch_site.gd` (the site), `entities/launch/*` (the site's models, the launch), `ui/missions/*` (the
  Mission Board, the rocket science panel), `data/blocks/pages/rockets.png` (+ `_albedo`, `_normal`), tests
  `tests/**/test_rocket*.gd`, `test_mission*.gd`, `test_launch*.gd`, a smoke `tools/mission_smoke.gd`, notes
  `docs/devlog/parts/missions.md`.
- Shared files you may touch with small additions: `scenes/sandbox.gd`, `world/world_meta.gd`, `core/rules/star_map.gd`
  (the new state), `ui/space/space_panel.gd` (its words), `data/blocks/block_ids.gd`, `world/block_library.gd`, the
  palette, `Recipes`, Tilly's stock. Never touch the School, the Science Lab, other worlds' files beyond registry lines.

## What to build (spec §21d, in this order)
1. **RocketCheck** (TDD, the educational heart). A rocket is the stack of parts standing on the pad's square, read
   bottom to top; stage separators split it into stages (the bottom stage fires first, then drops). Each part has
   real-ish numbers in one table: mass (tonnes; a tank full and empty), an engine's push (tonnes-force) and its
   efficiency (specific impulse), what it gives the crew (seats, days of air and water). The check returns, in words a
   child follows (and numbers): lift-off (push against weight at the pad, with a margin), how far the fuel takes you
   (the real rocket equation per stage: Δv = Isp × g₀ × ln(full ÷ empty), summed, each stage carrying the ones above),
   shown against the mission's need (Earth orbit about 9.4 km/s; the Moon landing and return about 6 more; Mars about 8
   more; your table, with sources in the notes), the crew (a seat each, air and water for the whole trip, a heat shield
   to come home, landing legs, a parachute where there is air). Every miss says why and what real rockets do.
2. **The missions table** (MissionRules): the Moon (3 days), Mars (about 7 months), then every planet world that exists
   (`SpaceRules.WORLDS`), in order, each with its need and one line of its real trip. **The route**: a planet reached by
   a mission once (or landed on before missions: `WonderData.bodies` LANDED) is on the route: the Star Map's LAND works
   for it; one not reached shows a new state, **MISSION** ("Mission needed: build a rocket at the Launch Site"), with
   the card and facts still free to see. Boing and Rainbow stay reachable by flying up.
3. **The rocket parts**: engine, fuel tank, nose cone, crew capsule (a window, a seat), service module, heat shield,
   landing legs, fins, stage separator, solar panel, parachute pack (11-16 blocks), our own look in both styles, solid,
   never painted. **They cost gold in every mode** (spec §25.3: bought at the Launch Site's shop, priced in one table so
   the Moon's rocket takes a few days of learning and Mars's a few weeks; the rest of Sandbox stays free). Survivor may
   also craft some at a workbench from real materials (the recipe teaches what each is made of): your ruling.
4. **The Launch Site** near every home world's spawn (placed like the Theater, never in front of it; the save keeps it):
   the **pad** is a square of voxel blocks the child builds on (stamped once when the site is chosen and saved; parts
   are ordinary voxel blocks, so friends in a shared world build together), a **service tower** and **Mission
   Control** with the **Mission Board** (models, nobody can break them). Walking up to the board opens it.
5. **The Mission Board** (UI, one panel, big buttons, read aloud like the School): the missions, each card with where,
   the trip, what the rocket needs; CHECK MY ROCKET (the rocket science panel: each stage, the numbers, the bar to the
   planet, green ticks and kind "not yet" lines); **LAUNCH** when it all passes.
6. **The launch hands over to the flight** (another agent builds `RocketFlight` now: spec §25.3; brief
   `2026-09-29-rocket-flight-brief.md`). LAUNCH makes the **rocket** description — `{"destination": int, "cells":
   {Vector3i (relative to the pad's corner, y up): block id}, "stages": [[Vector3i, …] (bottom stage first), …],
   "seats": int}` — and calls a Callable `fly` (the sandbox's; until the flight is merged it defaults to the plain
   space travel that lands the child on the planet: the landing words, the Space Book). The parts stay built on the
   pad at home. Never touch the flight's files.
7. **Friends**: phase 1 only (spec §21d.6): everyone in a shared world builds on the pad and sees the check; LAUNCH flies
   the one who pressed it, and says so to the others.

## Tests and checks (TDD)
Failing tests first (RocketCheck's numbers worked out by hand in the test, the route, the Star Map's MISSION state, the
site, the blocks in both styles, the board's flow). `--import` and grep Parse Error after new class_name scripts.
Single tests with `tests/run_tests.sh -gtest=…`. The smoke must print 0 fails (a private XDG_DATA_HOME containing
"smoke"). Look with windowed shots if you can open a window (a tool of your own like `tools/space_shots.gd`), else say
so. The FULL suite once at the end. Never open the editor or an emulator; never touch adb. Never merge or push. Never
run more agents. If you change the server (gifts carry block ids to 1023 already, module 0.2.15), bump its version and
say so.

## Finish
Notes (rulings, the numbers table with sources, what a child sees, what the lead must check on the emulator); spec
§21d "As built"; `docs/DEVELOPMENT.md`; `assets/CREDITS.md` if you add anything. Commits ending with
`Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>`. Report: branch, commits, what a child sees, the
smoke and full-suite results, what the lead must look at.
