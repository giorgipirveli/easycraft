# M3 Task 3: Frostpeak, universe 3

Spec §14.1 ("Frostpeak"), §5.1, §12.16 (secrets, adapted), §6 (fair fun), §16; plan Task 3. Built in an
isolated worktree from `3aa44f7` (branch `m2-survive-the-night`, with M3 Task 2's desert and M3 Task 5's
ladder merged), no editor or emulator use. Frostpeak is the desert's sibling: the same descriptor interface,
the same generator structure, the same weather, monster-kind, boss, music, secrets and trader hooks.

## What was built

### 1. Block atlas page 2: Frostpeak's blocks (ids 80–91, both styles)

| id | block | notes |
|---|---|---|
| 80 | SNOW | peaks' caps, the X over buried treasure's corners |
| 81 | SNOWY_GRASS ("Snowy Grass") | the valleys' ground: snow on top, dirt sides with a snow lip, dirt below; breaks into dirt (like grass) |
| 82 | PACKED_SNOW | igloo floors, temple floors, stairs; never natural terrain (so the wand can wake builds of it) |
| 83 | ICE | frozen lakes; **slippery** (`FrostRules.grip`) |
| 84 | BLUE_ICE | even more slippery; the treasure X, icebergs, temple roofs |
| 85, 86 | PINE_LOG ("Pine Wood"), PINE_NEEDLES | pines; needles are leaves (cutout, transparency 1, drop nothing), their top tile has snow on it; the axe fells pines |
| 87 | FROZEN_ORE | ice crystals in stone under the peaks' snow; an ore (a wood pickaxe), drops itself |
| 88 | SNOW_BRICK | igloos, temples, hidden rooms |
| 89 | ICE_LANTERN | glows (cold blue) |
| 90 | FROSTED_GLASS | cutout, transparency 5 |
| 91 | FAKE_SNOW (named "Packed Snow") | the hidden way down in an igloo's floor: a knock opens it; breaks into packed snow; never given |

- `world/universes/frost_blocks.gd` (`FrostBlocks`): the page's files and tiles; `BlockLibrary._static_init`
  registers it next to the desert's page (one line).
- Pixel page `data/blocks/pages/frost.png` by `tools/make_frost_atlas.gd` (own RNG seed 20260925; append new
  tiles at the end). Realistic twin `frost_albedo.png` / `frost_normal.png` (2048², page 0's import settings) by
  `tools/make_frost_realistic.py` (the desert tool's pattern, `make_realistic_atlas.py`'s helpers) from CC0
  ambientCG Snow004, Snow003, Ice002, Ice003, Ground103, Bark001, Wood095, Grass001, Rock030, Bricks084
  (credited in `assets/CREDITS.md`).
- Natural-block lists (the lead's desert rule, `dc17713`): `BlockIds.FROST_GROUND` = snow, snowy grass, ice;
  `BotRules.GROUND` / `NATURAL` (+ pines, needles, frozen ore), `SurpriseRules.METEOR_REPLACES` (+ needles),
  `ToolPowers.GROUND` (+ snow, snowy grass) and `LEAVES_OF` (pine → needles: **the axe fells pines**),
  `CaptureRules.GROUND` (+ the fake floor). `GatherRules.DROPS`, `NEEDS_TIER` (frozen ore: wood),
  `ChatCommands.NEVER_GIVEN` (fake snow), `SecretRules.is_fake_wall` (fake snow knocks open).

### 2. The terrain: valleys, peaks, frozen lakes, pines, igloos

`world/generators/frost_shape.gd` (`FrostShape extends MeadowsShape`: `height_at`, `is_river` (false),
`tree_at`, `spawn_column`, `column_block` for every system typed `MeadowsShape`):
- a valley floor at 34 ± 5 (one octave), ridges `1 - |n|` squared up to 46 high inside mountain ranges (a
  low-frequency range noise; outside the ranges 12 % as high: low hills); ground at or above the snow line
  (46) is a **peak**: snow on stone (1 block of snow, so cliffs show their rock), frozen ore 1–3 blocks under
  the snow in 6 % of peak columns; everything else is a **valley**: snowy grass, 3 dirt, stone;
- **frozen lakes**: at most one per 112 × 112 cell (50 %), radius 8–15, never in a mountain range: a bed 5
  to 1 blocks below the sea level, water up to one block under it, and **ice** at `SEA_LEVEL - 1`, so the
  ice is level with the snowy banks (5 wide, rising 2), and the valley flattens down to them over 12 more;
  nothing else goes below the water line (tested);
- **pines**: a forest noise; 45 ‰ of forest columns, 4 ‰ in the open; never on a lake or its banks, at or
  above the tree line (58), or in an igloo's way; trunks 5–8 in a cone of needles (reach 2);
- **igloos**: at most one per 96 × 96 cell (65 %) on flat valley ground (the floor's middle and four points
  4 away within 2): a packed-snow floor and foundation, a snow-brick dome (7 × 7, 4 high, room inside), a
  doorway, an ice lantern opposite it and a frosted window. Igloos count as trees (`tree_at`), so secrets,
  spawns, animals and pines keep off them; `igloo_in_cell` is cached behind a mutex (generator threads);
- the spawn: the nearest valley whose 13 × 13 blocks rise and fall at most 3, not in a pine or an igloo.

`world/generators/frost_generator.gd` (`FrostGenerator extends MeadowsGenerator`, the desert generator's
structure): each column once per chunk (each lake cell looked up once per chunk: `lake_of_cell`,
`column_near`), runs with `fill_area`, whole-chunk stone and sky shortcuts, pines (the first roll inlined),
igloos (clipped boxes, like secrets), then secrets. Caves, ores and crystals are the parent's.
`reference_block` is the slow per-block reference (igloos included).

### 3. Secrets (§12.16 adapted): five kinds

`world/generators/frost_secret_rules.gd` (`FrostSecretRules extends SecretRules`: the same kinds, ids and
dictionaries, so the `SecretDirector` plays them unchanged):
- **buried treasure** (TREASURE): a blue-ice X in the snow (a slippery X: a fair clue), the chest 2–4 under;
- **a hidden room under an igloo** (ROOM; "igloos, with a secret inside sometimes"): under the nearest
  igloo that has room, two **fake packed-snow** blocks in its floor (away from the doorway, a faint crack
  from above) open with a knock onto a landing two blocks down (a double jump gets back up), five steps down
  away from the doorway (the natural ground is their walls and roof; only where the ground outside covers
  every step), and a snow-brick room with four ice lanterns and a chest (sometimes a riddle note). `dir` is
  UP, so `/secret` sends a child into the igloo over the floor; `path` lists where feet stand (tested: every
  step at most one down, room overhead, a floor under it);
- **an ice temple** (TEMPLE): the Meadows temple in snow bricks on a packed-snow floor (never slippery: the
  plates are stepped on in order), a stepped roof of packed snow and blue ice with a golden tip, frosted
  windows, ice lanterns, the three plates, the note and the golden door;
- **a floating iceberg** (ISLAND): snow, packed snow, ice and a cone of blue ice with gold, a golden chest;
- **a crystal geode** (GEODE): Green Meadows' own.
Seed 12345, 196 areas: 246 treasures, 53 rooms under igloos, 28 temples, 34 icebergs, 74 geodes.

## Generator cost (the brief: ≤ Green Meadows' per chunk)

`godot --headless --path . --script res://tools/bench_generator.gd -- --frost` (M3 Task 3: the desert's
comparison made shared, `_bench_universe`): the same 640 chunks, both generators alternating chunk by chunk,
the second round timed. First version: surface 4.00 ms against 3.12 (+28 %, load 26). The pines' roll and
the lake cells were the difference (a column cost 2.1 µs like Meadows'; `pine_base` 1 µs × 400 columns a
chunk). After looking each lake cell up once per chunk, skipping pines outside the chunk's heights and
inlining the pines' first roll, at load 16:

| chunks | Meadows avg ms | Frostpeak avg ms |
|---|---|---|
| surface (y 0…79) | 1.59 | 1.43 |
| underground | 1.15 | 1.01 |
| sky (y ≥ 80) | 0.80 | 0.54 |
| all | 1.33 | 1.17 |

A Frostpeak area's secrets take 0.28 ms on average to place (once per area, then cached).

### 4. Monsters: the yeti and the ice bat

`MonsterRules` (kinds `YETI` (`&"yeti"`) and `ICE_BAT` (`&"bat"`: `/summon bat`); `FROST_KINDS`; the new
behaviour `FLYER`; the health, hit and gold tables; the snowball's and the flight's pure rules) and `Monster`
(a section "M3 Task 3" at the end; small hooks in `_decide`, `_attack`, `_strike`, the step and the looks):

| | HP (l = 1…5) | Hit | Gold | Speed | Attack |
|---|---|---|---|---|---|
| Yeti (tank) | 14 + 7(l−1) | 2 + (l−1) | 5l | 1.9 + 0.2(l−1) | a snowball held over its head 1.2 s (a goblin's club: 0.8), then thrown (2.5–12 blocks, 5 up or down) or smashed down (up close); takes 0.3 × a weapon's push |
| Ice bat (flyer) | 3 + 2(l−1) | 1 + l/2 | 3l | 4.0 + 0.2(l−1) | hovers and screeches 0.8 s (wings flapping twice as fast, icy), then dives at 8 m/s |

- **The snowball** (the brief: "lead its shot like the desert's scorpion, never through walls"): `throw_aim` is
  `spit_aim` (where the child will be, at most 3 blocks ahead) when a grid ray from the yeti's hands to the aim
  is clear; at the child's feet when only the lead is blocked; no throw at all (INF) when a wall stands between.
  Checked when it starts the wind-up and again when it throws. `snowball_hits`: within 1.5 of where it lands
  and a clear line from there (a snow wall shields). Every game flies the same snowball (`SpitGlob` with a look,
  splat and sound; one shared mesh).
- **The ice bat** (the new flyer behaviour; no navmesh, no gravity): ten times a second it picks a point to fly
  to — over the ground at 3.5 blocks while it wanders (the ground under it and 1.5 ahead, looked at three times
  a second, so it rises over hills), over a child it chases 3.5 up and 4 to its side (`hover_spot`; a quarter
  turn when a hill fills that spot, then right over the child) — and steers there (accel 10). Near that point,
  seeing the child with a clear line, it signals (hover, fast icy wings, a screech), then dives in a straight
  line at the child's chest where they stood (no lead: a sidestep dodges it), hurting whoever it touches once,
  flutters low for 1.4 s (swords reach it) and climbs back. After 18–30 s of flying it looks up (5 blocks) for a
  ceiling or a branch and hangs there upside down for 6–10 s (`perched`, synced; no physics move), waking when
  it sees or hears a child or is hit; in the open sky it keeps flying. Weak bats keep 6 blocks from lanterns
  like the walkers. It has no creature-mind tactics (it flies its own way).
- Looks: box models in the level colour with level-many icicle spikes; the yeti's arms are the turning arm
  and its snowball a second shared arm mesh shown while it winds up (like the scorpion's lit tail); the bat's
  wings flap by swapping two shared meshes (up, down; icy while signalling). Voices: a roar, a screech
  (`tools/make_frost_sounds.py`, original).
- Night spawns, Totem waves (the yeti three in five), `/summon yeti|bat`, the minds' hints for the yeti.
- **Ice** (`FrostRules.grip`, the brief's "a pure rule, tested"): the grip under the feet scales how fast a
  walker speeds up and slows down — ice 0.15, blue ice 0.08, everything else 1. The player's ground
  acceleration, the monsters' walking and friction (looked at every decision) and the animals' steering use it.
  A child letting go at walking speed on ice slides 2–5 blocks (tested with a real player).

### 5. The boss: the Frost Giant

`FrostGiantRules` (pure) and `FrostGiant` (`entities/monsters/`, a `StoneGolem` subclass like the Serpent, so
the BossDirector's fight, bar, honest help, gold, portal, win and loss run unchanged; `GiantModels` shared box
meshes; `IceRing` the stomp's frost on the ground). A fixed order, a 2 s walk between, every attack signalled:

| Phase | Time | What happens |
|---|---|---|
| RISE | 2.2 s | it climbs out of the snow (no hits yet) |
| WALK | 2.0 s | towards the nearest child (2.2 m/s, the Golem's walk) |
| STOMP_WARN → stomp | 1.2 s | a leg lifted high, frost gathering round its feet; then a freezing ring of 6.5 along the ground: 4 HP (a jump clears it) and the ground within 8 is icy for 4 s (`IcyGround`, every game; never a block) |
| BREATH_WARN → BREATH | 1.3 s + 1.5 s | head back, mouth glowing; then a cone of cold the way it faced (9 far, 35° each side): 1 HP every 0.5 s to whoever is in it with a clear line from its mouth (a snow wall shields) |
| PANTING | 2.0 s | stars over its head: hits count double (the bar's x2) |
| THROW_WARN → snowball | 1.0 s | a giant snowball held up, thrown in the Golem rock's arc: 3 HP where it lands |

Health 420 × (1 + 0.5 per extra player or bot friend), a tired one (three lost fights) 75 % and says so; the
BossDirector's win opens the portal to `UniverseRules.next_universe(3)` = 4 and unlocks it (tested).
`BossRules.FROST_GIANT` (`&"giant"`), `words`, `max_hp_of`; `/summon giant`; the boss bar's giant face.

### 6. Snowstorms

The desert's storm code, in snow (the brief: "reuse the desert's weather code"): `SandstormDirector.snow`
(node "Snowstorm"; its words and wind from `SandstormRules.style(snow)`) and `SandstormRules.mood(m, s, snow)`
(white fog `SNOW_FOG`, a whiter screen `SNOW_TINT` a 0.32, the same half view distance and dimmer sun);
`Ambience.storm_snow`. The clock, warnings, visibility (× 0.5 outdoors for monsters' sight) and the sheltering
rule are the desert's, unchanged. Toasts: "A snowstorm is coming! Find shelter!", "Snowstorm! Monsters can't
see far either.", "The snowstorm is over."; a whistling wind loop (`snowstorm.wav`, original).

### 7. The universe descriptor, music and the world glue

`world/universes/frost.gd`: `name` `&"frost"`, `display_name` "Frostpeak", `index` 3, `generator_shape`,
`generator`, `monster_kinds` (yeti, bat), `boss_kind` `&"giant"`, `music` {day: "Village of Snow" by zesona,
night: "Icy Heights" by écrivain; CC0, `tools/make_frost_music.py`; the boss keeps Green Meadows' loop}, `sky`
(a crisp blue, a pale snowy horizon), `trader_stock` (10 Frostpeak blocks at 1–5 Meadows gold, × 4 in universe
3), `weather` `&"snowstorm"`, `secret_rules`, `secret_words`. Glue: `scenes/sandbox.gd`'s M3 Task 2 section
creates the storm director for either weather and tells Ambience it is snow (4 lines). `--universe=3` already
existed (M3 Task 5). No new Session signals or RPCs were needed.

### 8. Smoke run on real terrain

`XDG_DATA_HOME=<private "smoke" dir> godot --headless --path . --script res://tools/frost_smoke.gd`
(`tools/frost_smoke_steps.gd`). First run (seed 2793253508, load ~80: 8 agents): all 58 checks passed —
universe 3, snowy grass in a valley, Frostpeak's directors; 5 night monsters (yetis and a bat) after 3.8 s; a
yeti lifted its snowball and hit the player standing still (20 → 16, 1.9 s); an ice bat flew above the ground,
screeched and dived (16 → 14); a snowstorm made the player half as visible (1.00 → 0.50), the fog white and at
half the view (128 → 64), then cleared; the Frost Giant went through every phase, its stomp made the ground
icy, and it was beaten (the portal to universe 4, universe 4 unlocked); the nearest igloo with a secret room
had its dome and fake floor, a knock opened the floor and found the room; the player stood on a frozen lake's
ice, slippery. Its cost window then ran after a 300-block teleport (meaningless: streaming at load 80), so the
window moved to the spawn, after the Giant.
Second run (seed 2402774277, load ~45): 56 of 58; the ice bat never dived in 25 s. Found: its hover spot was
inside a hill beside the player, so it never got there. Fixed test-first
(`test_a_bat_whose_side_is_blocked_hovers_on_another_side_and_dives`, RED: no dive in 10 s): a quarter turn
round the child when the spot is blocked, then right over them; a dive also starts when it is close over the
child; the bat looks at the ground 1.5 ahead too. Cost windows at the spawn (load 45, 8 agents): quiet physics
11.5 ms average, busy (20 monsters) physics 44.0 ms average, 97.6 worst — the PC was overloaded, so this is no
measure. A controlled comparison on the same load (20 monsters round a player on flat ground, stepped by hand,
desert and Frostpeak alternating): **desert 0.81 ms a step, Frostpeak 0.84** (yetis alone 1.43, bats alone
0.37). The lead's emulator run is the real number.
Third run, after the fix, the same seed (2402774277, load ~31): all 49 checks passed (the bat dived after 2.2 s;
the igloo, its knock and the lake too). Cost windows at the spawn: quiet physics 4.76 ms average (8.0 worst),
process 3.49 (27.0); busy with 20 yetis and bats physics 8.41 ms average (20.9 worst), process 10.55 (27.3).
(The desert's, at load ~11: physics 3.1 average, 4.9 worst.)

## Tests (RED → GREEN)

Suite (`tests/run_tests.sh`, exit 0 before every commit, on a snapshot of the staged index): **2843** at the
base (`3aa44f7`, the desert's count after its merge) → **2902** (blocks, terrain, secrets) → **2952**
(monsters, ice, the Giant) → **2967** (snowstorms, the descriptor, music, the world glue, the bat fix).

| Test file | Tests | RED (why it failed first) |
|---|---|---|
| `tests/unit/test_frost_blocks.gd` | 13 | `FrostBlocks` / the ids not declared |
| `tests/unit/test_frost_shape.gd` | 12 | `FrostShape` not declared |
| `tests/unit/test_frost_generator.gd` | 8 | `FrostGenerator` not declared |
| `tests/unit/test_frost_secrets.gd` | 8 | `FrostSecretRules` not declared |
| `tests/unit/test_frost_monster_rules.gd` | 10 | `MonsterRules.YETI` / `FLYER` not declared |
| `tests/integration/test_frost_monsters.gd` | 16 | `arm_mesh_for` took no wing frame, then no flyer or thrower; later the blocked hover spot (above) |
| `tests/unit/test_frost_rules.gd` | 4 | `FrostRules`, `IcyGround` not declared |
| `tests/integration/test_frost_ice.gd` | 4 | `FrostRules` not declared; then my own timings (stone stops in 0.25 s, not 0.2) |
| `tests/unit/test_giant_rules.gd` | 6 | `FrostGiantRules` not declared |
| `tests/integration/test_frost_giant.gd` | 11 | `FrostGiant` not declared; then a `DUST` constant clashing with the Golem's; then no ground under it in the test (it fell, so its attacks missed) |
| `tests/integration/test_snowstorm.gd` | 4 | written first; its RED run was not recorded (the `SNOW_*` rules and `snow` did not exist yet) |
| `tests/unit/test_frost_universe.gd` | 7 | the descriptor missing (`load(...)` null; checked by moving the file away) |
| `tests/integration/test_frost_world.gd` | 3 | written with the descriptor; passed at once (the ladder's glue is M3 Task 5's) |

Changed shared tests: `test_monster_defenses.gd` (walkers only in the door tests: a bat flies over a roofless
wall, and a roof keeps it out, tested in `test_frost_monsters.gd`; the lantern test's monsters 2 blocks apart,
so six kinds stay within 32 blocks of the player). The single-door test failed with the yeti added (a level 4
goblin, pushed sideways by the crowd, hopped onto the door: `_door_at_wall` fixes it; 5 runs green).

## Rulings (decided on the owner's behalf; cost if wrong)

1. **Frostpeak blocks stay out of the Sandbox palette** (the desert's ruling 1). *Cost:* one list.
2. **Ice is slippery by acceleration, not by a PhysicsMaterial** (the physics-system skill's `friction`
   applies to RigidBodies; the game's walkers are CharacterBody3D moved by code): `FrostRules.grip` scales how
   fast they speed up and slow down. Air control and swimming are untouched. *Cost:* one constant table.
3. **Bot friends do not slide** (the brief names players, animals and monsters). *Cost:* one line in BotFriend.
4. **The ice bat's kind is `&"bat"`** (`/summon bat`). *Cost:* a rename of one StringName.
5. **Bats fly over walls; a roof keeps them out** (doors keep walkers out). *Cost:* none in code; a child's
   house without a roof lets bats in.
6. **The yeti smashes up close** (a tank's melee, the mummy's grab distance) and throws from 2.5 to 12 blocks.
7. **The Frost Giant's numbers**: 420 base health (the Serpent 360), stomp 4, snowball 3, breath 1 × 3 (the
   Golem's sizes; bosses keep M2's hits). *Cost:* constants in FrostGiantRules.
8. **The icy ground is time-limited state on every game, never a block** (the brief), shown by a flat frost
   ring (one shared mesh) that melts away. *Cost:* a guest joining mid-fight misses a ring (4 s).
9. **Snowstorms share the desert's clock and rules** (calm 4–7 min, storms 45–80 s). *Cost:* constants.
10. **Hidden rooms are under igloos** ("igloos, with a secret inside sometimes"): a fake packed-snow floor and
    stairs down; 53 rooms in 196 areas. Igloos themselves are terrain (`FrostShape`), not secrets.
11. **Frostpeak's music**: two CC0 loops (day, night); the boss keeps the M2 loop. *Cost:* one more track.
12. **Tilly's Frostpeak stock**: 10 buildable blocks at 1–5 Meadows gold; never the fake floor or frozen ore.

## Tried and rejected (the godot-prompter skills)

- **procedural-generation**: seeded noise per column (a range mask × squared ridges; lakes and igloos from a
  per-cell hash, like the desert's oases) — chosen; cellular automata or WFC for ranges or igloos — rejected
  (per-chunk state, seams, cost).
- **ai-navigation**: the monsters' own steering at 10 Hz for the flyer too (seek a hover point, a straight
  dive, perch lookups by a column of block reads) — chosen; NavigationAgent3D / a 3D navmesh for flyers —
  rejected (a streamed, editable voxel world; the budget).
- **audio-system**: short original WAVs through the existing `Audio` pool, looped wind on the storm's own
  player, OGG music loops with `loop=true` — chosen; new buses or `AudioStreamInteractive` — not needed.
- **physics-system** (consulted after the grip rule was written): acceleration scaled by grip (ruling 2) —
  kept; PhysicsMaterial friction — rejected (CharacterBody3D ignores it); Area3D ice zones for the Giant's
  rings — rejected (a physics object per stomp; a pure rule every game evaluates is cheaper and testable).
- **3d-essentials** (the desert's choice, reused): the Environment fog and the Ambience tint for the
  snowstorm; no GPU particles or FogVolume (a shader compile; Forward+ only).

## What the lead should check on the emulator

1. **Open a Frostpeak world**: beat the Sand Serpent and walk through its portal, or `-- --survivor
   --new-world --universe=3` on the desktop with a private `XDG_DATA_HOME`.
2. **Looks, both styles**: snowy valleys, stone peaks with snow caps (cliffs show rock), frozen lakes (ice
   level with the banks), pine forests, igloos; page 2 in BLOCKY and REALISTIC (the ice must read as blue
   and slippery; snowy needles); no shader compile when the first Frostpeak chunk appears.
3. **Ice**: walk onto a lake and let go: a short slide, never uncontrollable; monsters and sheep slide too.
4. **Night**: yetis (the snowball over the head, then the throw; hide behind a wall: no throw) and ice bats
   (hover + screech + icy wings before the dive; a sidestep dodges it; they hang under trees and caves).
5. **A snowstorm** (about 3 minutes in): white fog, a whiter screen, the HUD still readable over it.
6. **The Frost Giant** from the Frostpeak Totem after wave 5: the lifted leg and gathering frost before the
   stomp, the frost ring and the slide on it, the glowing mouth before the breath (hide behind a snow wall),
   panting stars, the snowball; the bar's giant face; the portal to universe 4 ("coming soon" until Candy).
7. **An igloo's secret**: the cracked packed snow in some igloos' floor, a knock, the stairs down (a double
   jump gets back up from the landing), the room and its chest.
8. **Performance**: the autopilot in Frostpeak, both styles; the cost window's numbers above were taken on
   an overloaded PC.

## Hand-offs

- **Candy (M3 Task 4) runs in parallel**: `BlockLibrary._static_init` (one line each), `MonsterRules.KINDS`,
  `BossRules.words`, `BossDirector._make_golem`, `BossBar.use_boss`, `ChatCommands.MONSTERS`/`BOSSES`, the
  natural-block lists and `Audio.SOUNDS` will conflict line by line: keep both sides.
- `test_monster_defenses.gd`'s door tests now skip flyers (`MonsterRules.FLYER`); a later flyer (Sky Islands'
  harpies) is covered by the roof rule.
- Bot friends do not slide on ice (ruling 3).
