# Owner feedback #45 — more quests, and a bigger world to explore
(Use `owner-common.md` as the house rules header. Start after M3 Task 4 (Candy) and the #41 animals and #42
treasures packs are merged: quests use their animals, secrets and chests. Split into two agents if both halves are big: 45a quests,
45b world; give each its own ids from the M3 plan's Allocations.)

The owner (2026-09-24 21:49): "save into plan that we should continue implementing new quests and also we should extend the world".
Read: spec §12 (Survivor), §14 (M3), §16 (signature moments); `docs/design/` (the fair-fun rules: no streaks, no
expiring rewards, no loss surprises); the adventure board (`core/progress/board_rules.gd`: 3 picture goals the
child picks, never expiring; 24 goals today), levels and titles (`core/progress/level_rules.gd`), secrets
(`world/generators/secret_rules.gd`, the desert/frost/candy secret rules), `docs/devlog/parts/m3-task-12.md`,
and rows #41, #42, #45 of `docs/playtests/owner-feedback.md`. Write spec §14 additions and a plan line first.

## 45a — Quests (continue the adventure board into real quests)
1. **More board goals** in every universe: at least 30 new picture goals (the desert, Frostpeak, Candy,
   crafting, the Monster Wave mode, pets, the #41 animals, the #42 treasures, races, building). Every goal is
   reachable in both modes where it makes sense, and a Sandbox-only goal never pays Survivor gold.
2. **Quest givers and quest chains**: friendly characters with a picture bubble (Tilly, plus one helper
   per universe: a desert explorer, a frost ranger, a candy baker) give **short chains of 3–5 steps** with a
   little story told in pictures and read-aloud words ("Find my lost map piece → follow it to the pyramid →
   open the hidden door → bring the golden scarab"). A chain ends with a keepsake for the Secret Book
   shelf, a title, gold (Survivor) and a new place marked on the map.
3. **A quest book** (picture page in MORE): the current chain's step with an arrow to follow, the finished
   chains and their keepsakes. It never expires, has no timers, and never nags. A child can stop a chain
   and pick it up later.
4. Co-op: in LAN or online games, friends can share a chain (the host decides; everyone who helped
   gets the reward). Bot friends help ("follow the arrow").
Tests first: goal definitions (every kind has a counter that is really raised), chain steps and their
checks, rewards once only, save/load of progress in a chain, no timer anywhere, co-op sharing rules.

## 45b — Extend the world (more to find, farther away)
The world is already endless. "Extend" means more variety and more reasons to travel.
1. **New Meadows biomes** blended into the existing noise: birch and dark forests, flower fields, a
   swamp with lily pads, rivers that run to **a sea with islands and beaches**, tall mountains with
   snowy tops, and deeper cave layers (a glowing mushroom cave, an underground lake). New blocks go on a free block page
   (next free 16-id page in the M3 plan's Allocations, both styles).
2. **Places to find**: small **villages** (a few houses, a well, a farm, villagers who wave and trade,
   quest givers from 45a), ruins, a lighthouse, a windmill, a ship on the shore, towers with a view. The
   rarity grows with the distance from the spawn, so going farther always finds something new.
3. **A world map** (picture page): places you found appear on it with their picture. Tap one to set an arrow
   toward it. No map of places you haven't found (secrets stay secret).
4. Performance: the generator stays at or under Meadows' current cost per chunk (the desert and Candy set
   the bar: `tools/bench_generator`), with no new per-frame cost. Measure it on the emulator in both styles.
Tests first: the biome picks (deterministic per seed), rivers reach the sea, villages never cut
into water or cliffs, every place's rarity against the distance, the map's found-only rule, the generator benchmark.

Notes: `docs/devlog/parts/owner-45-quests-world.md` (and `-a`/`-b` if split). Emulator checks for the lead:
a quest chain start to finish, a village, the sea and an island, the map, the autopilot's 2 km flight over
the new biomes in both styles.
