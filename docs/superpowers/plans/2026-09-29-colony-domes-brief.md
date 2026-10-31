# Colonies under domes on the Moon and Mars — the agent brief (owner #77; spec §21c)

You are building **colonies** in EasyCraft (Godot 4.7.2, typed GDScript, Voxel Tools), a game for children. The owner:
"On the planets like moon, create domes for living creatures, something like [a famous rocket builder] is dreaming,
find it. same on the mars". Work autonomously; do not ask questions (decide, and note rulings with what they cost if
wrong in your notes file).

## Start
1. `git reset --hard lead-merge`; `git log --oneline -3`; `nice godot --headless --path . --import`.
2. Read `CLAUDE.md`, `docs/DEVELOPMENT.md`, spec §21, §21b, **§21c (your design)**, §3c (our own look). Study Mars
   end to end (`world/universes/mars.gd`, `mars_blocks.gd`, `MarsTerrain`, its secrets and sights, `tools/mars_smoke.gd`,
   `docs/devlog/parts/cosmos-mars.md`), the Moon (`world/universes/moon.gd` and its shape), Titan's page past the items'
   ids (`docs/devlog/parts/cosmos-titan.md`), how landmarks are stamped into a space world (the rover), how sights say
   facts (`world/space_sights.gd`), how animals spawn and why Mars has none (`UniverseRegistry.lifeless`, `animals`),
   the Science Lab's bench (spec §23).
3. **Find the real idea** (the owner's "find it"): what space agencies plan for a Moon base near the south pole and what
   rocket builders dream of for a city on Mars (domes and homes under the ground's shield, greenhouses, water from ice,
   oxygen from water or from Mars's carbon dioxide air, solar power, a big reusable rocket). Check facts against the
   agencies' own pages (NASA, ESA, JPL) and write them with sources in your notes. **No real person's, company's or
   mission's name in the game** (spec §21b.2).

## Allocation (fixed)
- Block atlas page **31**, block ids **544-559**. `BlockIds.COUNT` and `NEXT_PAGE_FIRST_ID` go to at least **560** (page
  30 is Mercury's 528-543, page 32 the rocket parts' 560-575: if COUNT is lower on your base, still take 544-559; the lead
  merges the numbers).
- New files: `world/colony/*` (the colony's layout and stamping, `ColonyRules` pure), `data/blocks/pages/colony.png`
  (+ `_albedo`, `_normal`), tests `tests/**/test_colony*.gd`, a smoke `tools/colony_smoke.gd`, notes
  `docs/devlog/parts/colony-domes.md`.
- Shared files with small additions: `world/universes/mars.gd`, `moon.gd` and their shapes/terrain (where the colony
  stands, flattened), the animal spawning (animals live **only inside the domes** on lifeless worlds), the sights,
  `data/blocks/block_ids.gd`, `world/block_library.gd`, Tilly's stock on those worlds. Never touch the School, the
  missions (another agent: the Launch Site, rocket parts, the Mission Board), other worlds.

## What to build (spec §21c.2)
- **Mars first, then the Moon**: a colony a short walk from the landing pad, seen from it, flattened ground.
- **The Great Dome** (glass, round, about 21 across): grass, a greenhouse garden in rows (vegetables, fruit trees,
  flowers) under grow lamps, a pond with fish, and animals the game already has (bunnies, chickens and the like) that
  live and stay inside it; warm light; the sky seen through the glass.
- **Smaller domes joined by glass tunnels**: homes (beds, a table), a lab with a Lab Bench (the Science Lab works
  there), the water plant (ice melting into a tank), the oxygen maker (bubbles), the control room (screens, a map).
- **Outside**: solar panel fields, a big rocket standing on its own pad (our own design: tall, silver, fins and legs),
  a rover garage, the ice mine (Mars: toward the ice cap; the Moon: a shadowed crater near the colony).
- **Facts**: each part says a real fact the first time a child walks in (sights; MY MAP shows the colony from the
  landing); the Space Book notes it (or a line in the planet's card, your ruling).
- **Friendly**: open doorways (the airlock is two doors in a row, pretend), always lit, never dark, peaceful; the
  world's own gravity inside; every step climbable at that gravity.
- **Build your own**: the colony's blocks (dome glass, colony panels, greenhouse soil, a grow lamp …) in Tilly's stock
  on those worlds.
- **Fast**: the generator no slower than the Moon's with the colony (bench it, `tools/bench_generator.gd`); the glass
  and the animals inside within the performance budget.

## Tests and checks (TDD)
Failing tests first (the colony's place and parts, the domes' shape, animals only inside, the facts, the blocks in both
styles, save and load). `--import` and grep Parse Error after new class_name scripts. Single tests with
`tests/run_tests.sh -gtest=…`. The smoke must print 0 fails (a private XDG_DATA_HOME containing "smoke"). Look with
`tools/space_shots.gd -- --universe=19` (and 16) windowed in both styles if you can open a window, else say so. The FULL
suite once at the end. Never open the editor or an emulator; never touch adb. Never merge or push. Never run more
agents.

## Finish
Notes (rulings, facts with sources, what a child sees, bench numbers, what the lead must check on the emulator); spec
§21c "As built"; `docs/DEVELOPMENT.md`; `assets/CREDITS.md` if you add anything. Commits ending with
`Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>`. Report: branch, commits, what a child sees, the
smoke and full-suite results, what the lead must look at.
