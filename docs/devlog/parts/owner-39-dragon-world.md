# Owner feedback #39, part: the Dragon Realm's world (universe 5)

Spec §14.2a ("The Dragon Realm"), §14.1, §6; plan Task 26; the lead's notes `owner-39-portals-dragon.md`. Built by a
worker agent in its own worktree (branch `worktree-agent-a99c950600aa93273`, merged with the lead's
`worktree-agent-a317d3c66e402be33` at `1cf0b11`), without the editor or the emulator. The lead builds the portals,
crystals and the egg's hatching; two other workers the realm's monsters and the Sky Dragon. Following the Candy
Kingdom's pattern (M3 Task 4).

## What was built

### 1. Block page 11: the realm's blocks (ids 224-238, both styles; 239 free)

| id | block | notes |
|---|---|---|
| 224 | SKY_GRASS | the islands' violet-blue moss (sparkles); side: moss hanging over floatstone; breaks into floatstone (like grass) |
| 225 | FLOATSTONE | pale lavender rock |
| 226 | DEEP_FLOATSTONE | darker violet: the islands' tapering undersides |
| 227 | CRYSTAL_SPIRE | glows: amethyst pillars (the realm's "trees"), a geode's shell |
| 228, 229 | MUSHROOM_STEM, GLOW_CAP | a giant mushroom's stalk and its glowing cap (the axe fells one: `ToolPowers.LEAVES_OF`) |
| 230, 231 | DRAGON_SCALE, EMBER_SCALE | emerald and red-orange scale blocks |
| 232 | STARGLASS | cutout, transparency index 6 (1-5 are taken) |
| 233 | MOON_LAMP | glows |
| 234 | CLOUD | cutout, walk-through (`NON_SOLID`, no collision boxes, no mesh collision) |
| 235 | NEST ("Dragon Nest") | woven twigs: a nest's egg lies on one |
| 236 | FLOATSTONE_BRICK | the sky shrines' walls |
| 237 | DRAGON_GOLD | glows; secrets only (never given, never sold) |
| 238 | FAKE_FLOATSTONE ("Floatstone") | the realm's fake wall: a knock opens it (`SecretRules.is_fake_wall`); drops floatstone |

- `world/universes/dragon_blocks.gd` (`DragonBlocks`), registered in `BlockLibrary._static_init`. Pixel page
  `data/blocks/pages/dragon.png` by `tools/make_dragon_atlas.gd` (own RNG seed 20260939, original work); realistic twin
  `dragon_albedo.png` / `dragon_normal.png` by `tools/make_dragon_realistic.py` from CC0 ambientCG Grass005, Rock030,
  Rock035, Ice002, Bark001, Wood095, Plastic013A, Leather026, Snow004, Bark014, Bricks084, Metal034 (credited). Import
  settings as the other pages.
- `BlockIds.DRAGON_GROUND` (sky grass, floatstone, deep floatstone), wired like `CANDY_GROUND`: `BotRules.GROUND` and
  `NATURAL` (+ mushroom stem, glow cap, crystal spire, cloud), `SurpriseRules.METEOR_REPLACES` (+ cloud),
  `ToolPowers.GROUND` (sky grass, floatstone) and `LEAVES_OF` (stem -> cap), `CaptureRules.GROUND` (+ fake floatstone and
  clouds: the wand never wakes them). `GatherRules.DROPS`: fake floatstone and sky grass give floatstone.
  `ChatCommands.NEVER_GIVEN`: dragon gold, fake floatstone. None in the Sandbox palette. `COUNT` 240.

### 2. The terrain (`world/generators/dragon_shape.gd`, `dragon_generator.gd`)

Patterns (godot-prompter `procedural-generation`): **chosen** seeded 2D noise thresholded into an island mask (FBM,
0.011), a slow noise for each island's height, hash-drawn per-column features (plants) and ore cells, all functions of
(x, z) and the seed, so chunks meet without seams; **rejected** cellular automata and WFC for the islands (per-area
state, seams, cost) and 3D density noise (a 3D sample per voxel: far above Meadows' cost in GDScript).

- `DragonShape extends MeadowsShape`: `column(x, z)` = (top, bottom, deep top) or zero over the void. An island is
  where the mask is above 0.18; how deep inside it lies ((mask - 0.18) / 0.3) sets its thickness: 3 at the rim, up to
  ~33 in the middle (a tapered cone with a little wobble), never below `MIN_BOTTOM` 12. Tops at 62 +- 20 (a slow noise:
  neighbouring islands float at different heights) +- 2 of detail, the rim rounded down 2. Layers: sky grass, floatstone,
  the lower half deep floatstone. No bedrock (`bedrock_top` far below the world), no water, nothing below.
- **The home island**: a disc of radius 64 (+-8 % wobble) round a centre within 16 blocks of the origin (from the seed),
  at y 56, flatter (detail 0.8), blended into neighbouring islands over 28 blocks. `spawn_column()` searches rings round
  its middle for a flat (<= 2), plant-free spot. Tilly's stall, the Totem, the stone circle and the Theater all find
  their places on it (tested).
- **Void columns**: `height_at` = `VOID_HEIGHT` (the sea level, 24). Every spawner that wants dry land asks for more than
  sea + 1 (animals, Tilly, the circle, the Totem, the Theater, secrets, stars, rainbows); fish want water 2 below the sea:
  nothing is placed over the void (tested with AnimalRules on the real shape).
- **Plants**: crystal spires (5-14 tall, a shorter pillar beside) and giant mushrooms (a stalk 4-8, a round glowing cap
  7 across with a drooping rim), only where the island is >= 8 thick, thicker in groves. They count as trees.
- **Clouds**: flat-bottomed puffs 1-3 thick at y 18-45 (a slow noise for their base), in the air under and between
  islands (an island's rock wins).
- **Ores** by depth under the island's top (the Meadows `OreRules` bands are absolute y: they would put gold and
  diamonds in the void): coal 2-16, iron 5-24, gold 10-32, crystal 14-40, diamond 18-44; one vein of each at most per
  8³ cell, inside the cell; they only replace floatstone.
- `DragonGenerator extends MeadowsGenerator`: chunks under y 12 return at once (air); chunks over every island hold
  only plants and secrets; **each chunk stack's columns and plants are worked out once** (a cache of 1024 stacks behind a
  mutex, cleared with a new seed) and filled in runs. `reference_block` is the slow rule the tests compare against.

### 3. Secrets (`world/generators/dragon_secret_rules.gd`)

The five M2 kinds, same ids and dictionaries (the SecretDirector plays them unchanged), each tried at the drawn spot and
up to 8 spots round it (islands cover about a third of the sky), and kept only when **grounded**: every column under
it (every other one and the edges) is island rock reaching below its lowest block.
- buried treasure: an X of ember scales on sky grass, the chest 2-4 under it, rock under the chest;
- a hidden room inside an island: floatstone walls, a floatstone-brick floor, moon lamps; stairs up that never run
  out over the void, ending at a two-block door of fake floatstone;
- a sky shrine (the puzzle temple): floatstone-brick walls on a foundation, starglass windows, a stepped roof of dragon
  and ember scales with dragon gold on top and moon lamps at its corners; plates, note, golden door, vault;
- **a dragon nest** (`ISLAND`, words "You found a dragon nest!"): a small floating island (radius 3-4, six layers) of its
  own, clear of every island by a block, 2-10 blocks from a bigger island's edge and level with it (+0..2): a short
  bridge away. Dragon gold in its side; on top a nest of NEST blocks (a 3 x 3 floor and a ring one higher, two scales
  in the rim) and **`"egg": Vector3i`**, the hollow's air cell on the middle nest block (inside `inside`, air above
  it); the golden chest 2 blocks east of it (`/secret`'s spot is east of the chest: on the grass);
- an amethyst geode: a hollow ball of crystal spire (radius 4-5) with two diamonds and a dragon gold in its shell, 3+
  blocks under the moss of a thick island.
- The treasure pack (owner 42) builds a **DRAGON style** in `TreasurePlaces` (mineshaft, vault, ruins, haunted house,
  camp; the realm's palette: mushroom stems for wood, floatstone and its bricks, crystal-spire pillars, moon lamps,
  glow caps, dragon-scale roofs), grounded the same way.

### 4. The descriptor (`world/universes/dragon.gd`)

`&"dragon"`, "Dragon Realm", index 5; `monster_kinds` [slime, goblin] and `boss_kind` golem **with the lead's merge
comments** (`MonsterRules.DRAGON_KINDS`, `BossRules.SKY_DRAGON`); `music` {} (Green Meadows' loops); `classical`
[gymnopedie, mountain_king]; `ambience` wind by day, crickets at night; `sky` deep violet top, lilac-pink horizon,
purple fog, a dark ground_bottom; `trader_stock` 13 blocks at 1-5 Meadows gold (x 16 here); `has_void = true`;
`secret_words`; `generator_shape`, `generator`, `secret_rules`.

### 5. The ladder

`UniverseRegistry.LADDER` gets `{&"dragon", "Dragon Realm", card colours}`: five universes. Everything that reads the
ladder's size follows: the Candy Kingdom's boss portal leads to universe 5, the realm's to the hub, the grand
celebration moves to the realm (`BossDirector._last_universe`, untouched), `/universe 5`, the hub and Monster Wave
list five cards (1252 px with their 18 px gaps: they fit 1280; `test_five_universe_cards_fit_the_screen`), Plus by the
existing rule (`ShopCatalog.needs_plus(5)`). `ArenaShape.PALETTES[5]`: sky grass over floatstone and deep floatstone,
crystal-spire pillars and mushroom-stem walls as cover; the kit clamps to the cosmic tier (like universe 4).

### 6. The void rescue (`core/rules/dragon_rules.gd`, `entities/player/player.gd`, `world/void_watch.gd`)

- `DragonRules`: `RESCUE_Y` 4 (under every island's `MIN_BOTTOM` 12), `has_void(descriptor)`, `world_has_void(d,
  arena)`, `is_safe_spot` (on the floor, a solid block under the feet: a cloud, water or air holds nobody), `SafeSpot`
  (remembered at most every 0.5 s), `rescue_target` (the spot; its column's ground when its block is gone; home when
  that column is no island), `fate` (monsters puff, everyone else comes back), `return_spot` (a ring of 8 spots beside
  the child or the spawn, a block up), `CARRIED_BACK` "Whoosh! The wind carried you back.".
- Player section "Owner 39: the Dragon Realm's void" and one line in `_physics_process` (`_void_step`): every player's
  own game notes its safe spot and, below the line, `carry_back()`s (`spawn_at` the target, or `go_home`), a whoosh, and
  `carried_back(to)`. No damage, no knock-out, nothing dropped, every mode (Sandbox flyers too).
- `VoidWatch` (host, 4 Hz, sandbox section): monsters below the line puff away (`MonsterDirector.puff`: no gold);
  animals, pets, bot friends and buddies come back beside their child while it stands safely, else by the spawn.
  Monster and boss code are untouched. The existing -64 rules stay for every other world.
- Sandbox section "Owner 39: the Dragon Realm": `_start_dragon_host` (one line at the end of `_start_universe_host`,
  never in the arena) and `_dragon_local` (one line at the end of `_universe_hud`): the toast and a lilac sparkle where
  the player lands.

### 7. Tools

`tools/bench_generator.gd -- --dragon` (`BENCH_DRAGON`), `tools/dragon_smoke.gd` (+ `_steps`).

## Tests (RED -> GREEN)

Suite (`tests/suite_slots.sh tests/run_tests.sh`, on a snapshot of the staged index): **4502 of 4502** after merging
the lead's branch (`1cf0b11`) -> **4580 of 4580** (473 scripts) with the realm.

| Test file | Tests | RED (why it failed first) |
|---|---|---|
| `tests/unit/test_dragon_blocks.gd` | 18 | `DragonBlocks` not declared (written before the page and the ids) |
| `tests/unit/test_dragon_rules.gd` | 9 | `DragonRules` / `DragonShape` not declared |
| `tests/unit/test_dragon_shape.gd` | 13 | `DragonShape` not declared; then its `_detail` clashed with MeadowsShape's (renamed); then the home island's test asked for island in a 40-block *square* round the spawn (corners 57 away): now a disc, and the home island grew from 60 to 64 |
| `tests/unit/test_dragon_generator.gd` | 8 | written after the generator; mutation-checked: without the ore placement the reference and ore tests fail |
| `tests/unit/test_dragon_secrets.gd` | 11 | written after the rules; mutation-checked: without `grounded`, the nest's clearance and the egg's air box, 10 tests fail |
| `tests/unit/test_dragon_universe.gd` | 10 | the ladder had 4 universes, no arena palette for 5 (11 failures) |
| `tests/integration/test_dragon_void.gd` | 4 | written with the hook; mutation-checked: without the `_void_step` line the two falling tests fail |
| `tests/integration/test_dragon_world.gd` | 5 | written with the ladder (the menu fit test passed at once: 5 cards fit) |
| Changed | `test_candy_boss.gd` (the kingdom's portal now leads to universe 5; the last universe's to the hub), `test_universe_registry.gd` (five universes) | |

## Measurements

Generator (`bench_generator.gd -- --dragon`, 640 chunks, both generators alternating, load ~25): the timed second round
(the stack cache warm, as for the chunks above and below a first one):

| chunks | Meadows avg ms | Dragon avg ms |
|---|---|---|
| surface (y 0..79) | 1.89 | 0.60 |
| underground (the void) | 1.46 | 0.00 |
| sky (y 80..95) | 1.00 | 0.28 |
| all | 1.63 | 0.33 |

Cold (fresh generators, every chunk once; a scratch bench, load ~24): surface 2.69 / **1.24**, underground 2.08 /
**0.00**, sky 1.36 / **0.48**, all 2.31 / **0.67**. Before the stack cache the sky band cost 1.16 ms against Meadows' 1.02
(its island tops and plants are up there): the cache fixed that. A realm area's secrets: 0.63 ms average (worst 2.3).

Smoke run (`dragon_smoke.gd`, seeds 2633168239 and 401955317, load 30-39): **24 checks, 0 fails** each. Cost window on
the home island (headless desktop, only a hint): physics 5.4 ms average, process 3.9. The first seed's run showed the
known far-teleport gotcha (back from the nest, the player landed before the collision was built and fell through the
island): the wind caught it and put it back, the smoke run now waits until the player stands before the push.

## Rulings (decided on the owner's behalf; cost if wrong)

1. **`has_void`**, not `void` (a GDScript keyword). *Cost:* none.
2. **The rescue line is y 4, islands never reach below 12**; the fall from the home island takes about 2 s. *Cost:* one
   constant each.
3. **A void column's height is the sea level** (every spawner's "no dry land, no deep water"). `find_standing_y` there is
   y 24 in the air (a bot friend's catch-up spot over the void falls, and the VoidWatch brings it back). *Cost:* a future
   spawner that treats "<= sea level" as a beach would act in the air there.
4. **Rescue target**: the last safe spot while its block is there, else its column's ground, else home (bed or spawn).
   *Cost:* a child who stood on a bridge over the void and then broke it goes home.
5. **Other bodies are handled by the host's VoidWatch** (sandbox section), not in each entity (monster, boss and pet code
   stay untouched): monsters puff (no gold), wild animals come back by the spawn too (never lost). *Cost:* a wild sheep
   that fell reappears by the spawn.
6. **Nests float on their own, a short bridge (2-10 blocks) off an island, level with it (+0..2)**, never above one.
   *Cost:* a child with no blocks cannot reach one (Tilly sells floatstone and clouds).
7. **The treasure pack builds five of its kinds in the realm** (DRAGON style in `treasure_places.gd`), grounded like the
   realm's own. *Cost:* two lines (the style) if the pack should stay out.
8. **No caves in the islands; ores by depth under the island's top** (own veins, not `OreRules`' absolute bands).
   *Cost:* tune `ORE_VEINS` if Survivor children find too few.
9. **Clouds are cutout** (the brief) and kept thin (1-3): cutout blocks do not cull their neighbours, so a cloud draws
   its inner faces too. *Cost if they cost too much on the emulator:* make CLOUD `opaque` + `walk_through` (one line).
10. **The home island** (radius 64, y 56, near the origin) holds the spawn and every M2/M3 place round it; checked for 5
    seeds. *Cost:* a seed whose home island is crowded by a neighbour island at another height gets a step at the edge.
11. **No music of its own**; the classical favourites Gymnopédie and In the Hall of the Mountain King; wind by day.
12. **Arena palette 5**: sky grass, floatstone, deep floatstone, spire pillars, mushroom-stem walls; kit tier cosmic.
13. **The five-card menu rows fit without change** (1252 of 1280 px); a test guards it.

## What the lead should check on the emulator

1. `--universe=5` (or the hub/portals after the merge): the purple sky, islands at different heights, the void and
   clouds below, spires and glowing mushrooms, both styles (page 11), no shader hitch at the first chunk.
2. **Walk off an edge**: the fall, "Whoosh! The wind carried you back.", the sparkle, back where you stood; in Sandbox
   flying too. Is the fall (about 2 s from the home island) too long or too short?
3. **Clouds**: their look (cutout puffs) and their cost in the autopilot's flight over the void (many empty chunks,
   cheap; clouds draw inner faces).
4. Tilly, the Totem, the stone circle and the Theater on the home island; night monsters only on islands.
5. A dragon nest (`/secret island`): reachable with a few blocks; the egg's cell (the lead's egg entity).
6. Monster Wave in universe 5: flat sky grass with spire and mushroom-stem cover.

## Merge notes (for the lead)

- New: `world/universes/dragon.gd`, `dragon_blocks.gd`, `world/generators/dragon_shape.gd`, `dragon_generator.gd`,
  `dragon_secret_rules.gd`, `core/rules/dragon_rules.gd`, `world/void_watch.gd`, `data/blocks/pages/dragon*.png`
  (+ imports), `tools/make_dragon_atlas.gd`, `make_dragon_realistic.py`, `dragon_smoke.gd` (+ `_steps`), 8 test files.
- Shared (small, in place): `data/blocks/block_ids.gd` (a section after SADDLE, `COUNT` 240, `DRAGON_GROUND`, CLOUD in
  `NON_SOLID`, `_NAMES`), `world/block_library.gd` (one line in `_static_init`, a comment), `core/rules/bot_rules.gd`,
  `surprise_rules.gd`, `tool_powers.gd`, `core/magic/capture_rules.gd`, `core/survival/gather_rules.gd`,
  `core/rules/chat_commands.gd` (the lists), `world/generators/secret_rules.gd` (`is_fake_wall`),
  `world/generators/treasure_places.gd` (DRAGON style), `world/generators/arena_shape.gd` (palette 5),
  `world/universes/universe_registry.gd` (LADDER), `entities/player/player.gd` (one line + section at the end),
  `scenes/sandbox.gd` (two lines + section at the end), `tools/bench_generator.gd` (`--dragon`), `assets/CREDITS.md`,
  `docs/DEVELOPMENT.md`, tests `test_candy_boss.gd`, `test_universe_registry.gd`.
- **At the merge**: swap the descriptor's `monster_kinds` / `boss_kind` (the comments); the egg entity reads
  `secret.egg`; `BlockIds.NEST` is the block under it. Page 10 is untouched.
