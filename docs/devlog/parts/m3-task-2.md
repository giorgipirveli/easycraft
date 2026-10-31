# M3 Task 2: the Sandstorm Desert, universe 2

Spec §14.1 ("Sandstorm Desert"), §5.1, §12.16 (secrets, adapted), §6 (fair fun); plan Task 2. Built in an
isolated worktree from `cd6649e` (branch `m2-survive-the-night`), no editor or emulator use. The ladder and
the registry are M3 Task 5's (built in parallel); this task writes the desert's descriptor to their
interface (below).

## What was built

### 1. Block atlas page 1: the desert's blocks (ids 64–79, both styles)

| id | block | notes |
|---|---|---|
| 64 | SANDSTONE | layered sides |
| 65 | CUT_SANDSTONE | big bricks (pyramids) |
| 66 | CHISELED_SANDSTONE ("Carved Sandstone") | an eye carving (pyramid floors, the doorway) |
| 67 | RED_SAND | mesa tops, the treasure X |
| 68 | RED_SANDSTONE | a mesa's stripes |
| 69 | CACTUS | pushes whoever walks into it a little (never hurts; see the traps) |
| 70 | DEAD_BUSH ("Dry Bush") | cutout, walk-through |
| 71 | DESERT_GLASS | cutout, transparency index 4 |
| 72, 73 | PALM_LOG ("Palm Wood"), PALM_LEAVES | the oasis palms; fronds drop nothing, like leaves |
| 74 | PYRAMID_GOLD | glows; a pyramid's tip (a treasure: never given, never in a palette) |
| 75 | DESERT_LAMP | glows; lights pyramids and mesa rooms |
| 76 | ARROW_SLIT | a pyramid trap's face (breaks into cut sandstone) |
| 77 | TRAP_SAND (named "Sand") | a sand pit's lid: looks like sand (faint ripples), holds nobody |
| 78 | FAKE_SANDSTONE (named "Sandstone") | the desert's fake wall: a tap knocks it open |
| 79 | free | |

- `world/universes/desert_blocks.gd` (`DesertBlocks`): the page's files and tiles; `BlockLibrary._static_init`
  registers it as the class loads (so every library, icon and break colour has it, however early).
- `BlockLibrary._page_models` learned a tile entry's fifth element, extras: `{"walk_through": true}` (no box,
  no physics surface, like the bush) and `{"transparency": n}`.
- Pixel page `data/blocks/pages/desert.png` by `tools/make_desert_atlas.gd` (own RNG seed 20260924; append new
  tiles at the end). Realistic twin `desert_albedo.png` / `desert_normal.png` (2048², page 0's import
  settings) by `tools/make_desert_realistic.py`, which reuses `make_realistic_atlas.py`'s helpers, from CC0
  ambientCG Ground096B, Ground093A, Bricks084, Tiles144, Ground097, Rock029, Bark014, Wood095, Grass001,
  Metal034, Ground079L (credited in `assets/CREDITS.md`).
- `BlockIds.COUNT` is 80; DEAD_BUSH and TRAP_SAND are in `NON_SOLID`; the drops of the secret-built blocks
  are what they look like (`GatherRules.DROPS`); `/give` never hands out PYRAMID_GOLD, ARROW_SLIT, TRAP_SAND or
  FAKE_SANDSTONE (`ChatCommands.NEVER_GIVEN`: the look-alikes would also take "sand" and "sandstone").
- `tests/unit/test_block_pages.gd` registers its test page as page 12 now (page 1 is the desert's for real).
- The Magic Wand never wakes the desert's natural ground (`CaptureRules.GROUND` += sandstone, red sand, red
  sandstone, trap sand; test `test_the_desert_ground_never_comes_alive`, RED: sandstone was capturable).

### 2. The terrain: dunes, mesas, oases, plants

`world/generators/desert_shape.gd` (`DesertShape extends MeadowsShape`, so every system typed `MeadowsShape`
takes it: `height_at`, `is_river` (always false), `tree_at`, `spawn_column`, `column_block`):
- a floor at 32 ± 4 (one low-frequency noise), dune ridges up to 9 high inside dune fields (ridged noise
  `1 - |n|`, squared, sampled on a sheared domain so ridges run across the wind);
- mesas where a mesa noise passes 0.42: 16 above the floor, in 3 terraces over a 0.06 band (ledges, never
  one sheer wall), striped red sandstone with a light sandstone stripe every 7 blocks, red sand on top;
- oases: at most one per 128 × 128 cell (45 %), a pond of radius 6–11 whose floor dips below the sea level
  (MeadowsShape's water fill makes the pond), grassy banks 6 wide, dunes flattened 10 further out, never
  next to a mesa; nothing else goes below the water line (tested), so no accidental lakes;
- layers: sand 4 deep (a dune is sand all through), sandstone 10 under the floor, then stone and deep stone;
- plants from a hash per column: cacti (1–3 tall, 5 ‰) and dry bushes (8 ‰) on the open desert, palms
  (trunk 5–7, a crown that droops, reach 2) on 2.5 % of oasis banks; plants count as trees (secrets keep off);
- the spawn: the nearest open desert whose 13 × 13 blocks rise and fall at most 3 (not a mesa, an oasis or a
  dune's side). `column(x, z)` gives (height, kind, floor) in one call.

`world/generators/desert_generator.gd` (`DesertGenerator extends MeadowsGenerator`): works out each column
once per chunk and fills its layers in runs (`fill_area`, only the runs that reach into the chunk); a chunk
wholly under the sandstone is one stone fill; chunks above `DesertShape.TOP` (53) skip the columns, the caves
and (above 62) the plants; under y = 0 the caves need no heights (the desert's shallowest crust limit is
15). Caves, ores and crystals are the parent's code. `reference_block` is the slow per-block reference.
`MeadowsGenerator` got two factories for it, `_make_shape` and `_make_secrets` (called by its seed setter).

### 3. Secrets (§12.16 adapted): five kinds

`world/generators/desert_secret_rules.gd` (`DesertSecretRules extends SecretRules`: the same kinds, ids,
dictionaries and area rules, so the `SecretDirector` plays them unchanged; `SecretRules._attempts()` is
overridable now):
- **buried treasure** (TREASURE): a red-sand X on open sand, the chest 2–4 blocks under it;
- **a hidden room in a mesa** (ROOM): a sandstone room with lamps and a chest inside a mesa at least 10 high,
  level with the desert outside; a 1 × 2 tunnel to a **fake sandstone** wall in the mesa's side (a light patch
  in a red cliff: a fair clue). `SecretRules.is_fake_wall` and `fake_wall_group` (and the tap in
  `secret_taps.gd`) accept FAKE_SANDSTONE;
- **a pyramid** (TEMPLE): 21 × 21, 11 steps of cut and plain sandstone with a glowing golden tip, on fairly flat
  open sand (a foundation under its lowest ground); the way in (3 wide) has an **arrow slit** on each side at
  head height and a **sand pit** (trap sand over one block of air) between them; the 7 × 7 chamber has the
  three **pressure plates** and the note; the **golden door** the plates open leads to the treasure room
  (the temple puzzle: the chest stays locked until the plates are pressed in the note's order);
- **a floating mesa** (ISLAND): red sand and red sandstone, gold studs, a golden chest;
- **a crystal geode** (GEODE): Green Meadows' own, deep down.
Seed 12345, 64 areas: 61 treasures, 23 pyramids, 23 geodes, 11 mesa rooms, 4 floating mesas.

### 4. Monsters: the mummy and the scorpion

`MonsterRules` (kinds `MUMMY`, `SCORPION`; `MEADOWS_KINDS` / `DESERT_KINDS`; behaviours `TANK`, `SPITTER`; a
per-kind health table; `windup(kind)`, `winds_up`, `push_scale`, `halves`; the spit's pure rules) and `Monster`
(sections marked M3 Task 2; the slime and the goblin are unchanged, and every M2 test that loops over
`MonsterRules.KINDS` — doors, lanterns, never editing a block, minds, the director — now covers the new kinds):

| | HP (l = 1…5) | Hit | Gold | Speed | Attack |
|---|---|---|---|---|---|
| Mummy (tank) | 10 + 5(l−1) | 2 + (l−1) | 4l | 2.2 + 0.2(l−1) | arms rise 1.1 s (goblin 0.8), then a grab within 2.4; takes 0.35 × a weapon's push |
| Mummy half (top or legs) | 5 | as level 1 | 2 | +1.0 | the top still grabs; the legs only walk |
| Scorpion (spitter) | 5 + 3(l−1) | 1 + l/2 | 3l | 3.0 + 0.2(l−1) | tail up and glowing 0.9 s, then a glob (cooldown 2.4 s) |

- **Unwrapping** (§14.1 "two halves at level ≥ 3"): the director's split spawns a crawling top half (the boxes
  above the waist, dropped to the ground; it keeps its arms) and walking legs (a bandaged stump on top), each
  level 1 with 5 HP, faster; halves never unwrap again. Slimes still split into two small slimes.
- **The spit** (fair, signalled): it spits at a target within 10 blocks (4 up or down); the glob flies at
  9 m/s (0.5–1.6 s) on a small arc to `spit_aim`: where the child will be after the flight (velocity × time,
  refined once), at most 3 blocks ahead, on the ground they stand over; it hurts whoever is within 1 block of
  where it lands (1.5 up or down). Every game flies the same glob (`SpitGlob`, by an RPC on the monster, one
  shared mesh); the host decides the hit. The scorpion keeps 5 blocks away and steps back from a child within
  3; it spits whatever tactic its mind picked (not while backing off).
- Looks: box models in the level colour with level-many spikes (bandage ends, back spikes), the mummy's arms
  and the scorpion's tail as the turning arm; the lit tail is a second shared mesh (brighter vertex colours,
  the same material). Voices: a moan and a hiss on first sight; the spit and splat sounds
  (`tools/make_desert_sounds.py`, original, also the Serpent's, the traps' and the sandstorm's).
- Night spawns and Totem waves take the universe's kinds (`MonsterDirector.kinds`, `WaveDirector.kinds`,
  `WaveRules.roster(..., kinds)`: the first kind is three in five, like the slimes); `/summon mummy 3` and
  `/summon scorpion` in Sandbox; the monster minds' hints name them ("Scorpions call their friends now...").

### 5. The boss: the Sand Serpent

`SerpentRules` (pure) and `SandSerpent` (`entities/monsters/`, a `StoneGolem` subclass, so the `BossDirector`'s
fight, health bar, honest help, gold, portal, win and loss run unchanged; `SerpentModels` shared box meshes).
A fixed order children can learn, every attack signalled:

| Phase | Time | What happens |
|---|---|---|
| RISE | 2.0 s | it rises out of the sand (no hits yet) |
| UP | 1.6 s | out of the sand: it can be hit |
| SWEEP_WARN → sweep | 1.1 s | it rears back and rattles its tail; the tail sweeps the ground within 5.5: 4 HP (a jump clears it) |
| DIZZY | 2.0 s | stars over its head: hits count double (the bar's x2) |
| DIVE | 2.6 s | under the sand towards the nearest child at 4.5 m/s (a child walks 6); a mound of sand and puffs show where; no hits |
| WARN | 1.4 s | the sand shakes in a ring where the child stood (Fx ripples, a rumble): step away! |
| BURST | 0.35 s | it bursts out there: 4 HP within 2.5 (in the air too), then UP |
| SPIT_WARN → sand ball | 1.0 s | head back, a glowing mouth; a ball of sand flies the Golem's rock arc to where its target stands: 3 HP there |

Up after a burst it alternates the tail and the ball (UP → SWEEP_WARN, next time UP → SPIT_WARN). Health 360 ×
(1 + 0.5 per extra player or bot friend), a tired one (three lost fights) 75 % and says so; it stays within 24
of where it rose. `BossDirector.boss_kind` picks the world's boss (`start(totem_pos, kind)` for `/summon
serpent`); the words come from `BossRules.words(kind)` (bar title and face, the busy, tired, win and summon
lines); `WaveRules.refusal_message(key, boss_name)` and `boss_word(name)` for the Totem. `GolemRock` takes a
look and dust colours so the sand ball reuses it.

### 6. Sandstorms

`SandstormRules` (pure) and `SandstormDirector` (node `Sandstorm`, every peer): the host keeps the clock (calm
spells of 240–420 s and storms of 45–80 s drawn from the world seed, a visit starts calm for at least 150 s,
"A sandstorm is coming! Find shelter!" 10 s before) and tells every game (an RPC, and the state to a joining
guest); every game eases the strength in and out over ~3 s. In a full storm:
- **monsters**: `StealthDirector.weather` multiplies the light around every player and bot friend by
  `SandstormRules.visibility` (× 0.5 outdoors, nothing deep under a roof): the monsters' sight is 16 × the
  visibility, so it halves;
- **players**: `Ambience.storm` puts `SandstormRules.mood` on the cave/water view: the fog's end at half the
  view distance (its start close), sandy fog, the sun at 0.7, a sandy screen tint (the water's own tint wins
  under water), nothing deep underground; a looping wind (`sandstorm.wav`) follows the strength.
Toasts: coming, "Sandstorm! Monsters can't see far either.", "The sandstorm is over."

### 7. Traps: cacti and arrow slits

`DesertRules` (pure) and `DesertTraps` (node `DesertTraps`, host ticks at 10 Hz, effects on every peer):
- a player walking into a cactus (at the feet, the head, or standing on one) is pushed 4 m/s away with a
  small hop (`Session.send_knockback`: their own game moves them), 0.8 s apart; never hurt;
- an arrow slit (from the pyramids' secret dictionaries) whose lane (4 cells in front, head and body height)
  a player stands in clicks with a puff of dust, and 0.6 s later a dart flies across: 2 HP to whoever is still
  in the lane (`Session.hurt_player`, so Cozy halves it), then 3 s of rest; a broken slit never shoots.
- the sand pit is only blocks (trap sand over one block of air).

### 8. The universe descriptor and the world glue

`world/universes/desert.gd` follows M3 Task 5's interface (read from its worktree: `UniverseRegistry`'s
comment; the descriptor is a plain script it loads by path): `name` `&"desert"`, `display_name`, `index` 2,
`generator_shape(seed)` (a `DesertShape`), `generator(seed)` (a `DesertGenerator`), `monster_kinds`,
`boss_kind` `&"serpent"`, `music` {day, night} (the boss keeps Green Meadows' loop), `sky` (the five daytime
colours: a pale hot blue, a sandy horizon), `trader_stock` (11 desert blocks, 1–5 Meadows gold each; the
ladder scales prices). Its own optional fields, read by this task's glue: `secret_rules(seed, shape)`,
`secret_words`, `weather` (`&"sandstorm"`), `traps`.

Glue (small, marked "M3 Task 2"). Until M3 Task 5 merged I carried stand-ins with its names (`Game.universe`,
`--universe=`, `WorldService.setup(..., universe)`); after merging `m2-survive-the-night` (`d304103`, Task 5
merged) those are Task 5's and my one addition is:
- `WorldService.descriptor()` → `UniverseRegistry.descriptor(universe)` (null for universe 1).
- `scenes/sandbox.gd` section "M3 Task 2": `_apply_universe_content` (monster kinds, the boss, the sandstorm
  and trap nodes; every peer), `_universe_secrets` (the SecretDirector's rules and found words),
  `_start_universe_host` (the storm clock, stealth's weather, the traps' slits from the secret rules),
  `_universe_hud` (the Totem's boss button names the Serpent; the storm's view and toasts). Guests call the
  same (their world knows the host's universe through M3 Task 5's handshake).
- `SecretDirector.found_text` (a var copy of `FOUND_TEXT`), `WaveDirector.kinds` / `boss_name`,
  `MonsterDirector.kinds`, `BossDirector.boss_kind`.
- Not mine (M3 Task 5's): per-universe save slots, `WorldMeta.universe`, the guest handshake, music and sky
  application, Tilly's prices by universe and her local stock, the portal to universe 2.

### 9. Smoke run on real terrain

`XDG_DATA_HOME=<private "smoke" dir> godot --headless --path . --script res://tools/desert_smoke.gd`
(seed 3295113389, load ~11): all 45 checks passed — a desert world (universe 2), standing on sand on open
desert, the desert's directors; 3 night monsters (mummies and a scorpion, universe 2) after 1.3 s; a summoned
scorpion's spit hit the player standing still after 1.6 s (20 → 19: Cozy halves 2); a level 3 mummy unwrapped
into two halves; a sandstorm made the player half as visible (light 1.00 → 0.50) and closed the fog in
(128 → 64), then cleared; the Sand Serpent rose and went through RISE, UP, SWEEP_WARN, DIZZY, DIVE, WARN,
BURST, SPIT_WARN in 18 s with its bar, was beaten (the portal opened, "You beat the Sand Serpent!"); the
nearest pyramid (80 blocks from the spawn) had its golden tip, two arrow slits, six trap sand lids and three
plates in the loaded world, walking into its chamber found it and its locked chest was there.
Cost window (20 desert monsters around the player, headless desktop, load ~11): physics 3.1 ms average, 4.9
worst; process 2.8 ms average, 16.7 worst (a quiet window while the world still streamed: physics 5.0,
process 20.8). Only a hint: the emulator's numbers are the lead's.

After merging M3 Task 5 (the world now in `survivor_u2`, the ladder's registry): seeds 2220006210 and
3851689083 failed once at "walking into the chamber found the pyramid". Found: the smoke run's 80-block
teleport (`spawn_at`) lands before the collision-only viewer has built the pyramid's collision, so the player
sank into the chamber floor (feet at y 35 under a floor top at 36) or fell through and got up at home. The
game itself never teleports that far without streaming (portals and travel arrive by a spawn that waits),
so the run now teleports again when the player is not in the chamber after 4 s (at most 4 times). Both seeds
then passed all 45 checks; cost window (load ~6): physics 3.7 ms average, 4.7 worst; process 2.4, 7.6 worst.

## Tests (RED → GREEN)

Suite (`tests/run_tests.sh`, exit 0 before every commit, run on a snapshot of the staged index): **2495 of 2496**
at the start (`cd6649e`) → 2531 (blocks, terrain, secrets) → 2555 (monsters) → 2580 (the Serpent) → 2606 (the
descriptor, sandstorms, traps, glue) → 2607 (the wand) → **2843** after merging `m2-survive-the-night` with
M3 Task 5 (and the other merged work) plus `test_the_ladder_reads_the_desert`.

| Test file | Tests | RED (why it failed first) |
|---|---|---|
| `tests/unit/test_desert_blocks.gd` | 11 | `DesertBlocks` / the new ids not declared (first a parse error: a `const` alias of a class isn't a constant expression) |
| `tests/unit/test_desert_shape.gd` | 9 | `DesertShape` not declared |
| `tests/unit/test_desert_secrets.gd` | 9 | `DesertSecretRules` not declared |
| `tests/unit/test_desert_generator.gd` | 6 | `DesertGenerator` not declared; then only its own threshold (a chunk count) |
| `tests/unit/test_desert_monster_rules.gd` | 11 | `MonsterRules.MUMMY` not declared; then a typed-array ternary (`halves`) and my own lead test (the lead was capped) |
| `tests/unit/test_serpent_rules.gd` | 9 | `SerpentRules` not declared |
| `tests/integration/test_sand_serpent.gd` | 10 | `SandSerpent` not declared; then its constants clashed with the Golem's (`BODY`, `DUST`: renamed) |
| `tests/integration/test_desert_boss.gd` | 6 | the director always spawned a Golem; `boss_kind`, `words`, `use_boss` missing |
| `tests/unit/test_sandstorm_rules.gd` | 5 | `SandstormRules` not declared |
| `tests/integration/test_sandstorm.gd` | 4 | `SandstormDirector` not declared; `StealthDirector.weather`, `Ambience.storm` missing |
| `tests/unit/test_desert_rules.gd` | 3 | `DesertRules` not declared |
| `tests/integration/test_desert_traps.gd` | 5 | `DesertTraps` not declared; then the dart's timer summed to a hair above 0 (fixed with a small epsilon) |
| `tests/unit/test_desert_universe.gd` | 6 | the descriptor file missing |
| `tests/integration/test_desert_world.gd` | 3 | `WorldService.setup` took no universe; then my own check read a chunk not loaded yet |
| `tests/integration/test_desert_monsters.gd` | 13 | `Monster` knew no half, windup per kind or glob; then one test of mine that stopped the wind-up by hand (it kept the scorpion still) |

The phase-1 snapshot suite found `/give sand` answering with the trap sand (fixed: `NEVER_GIVEN`).

## Generator cost (the brief: ≤ Green Meadows' per chunk)

`godot --headless --path . --script res://tools/bench_generator.gd -- --desert`: the same 640 chunks (8 × 8
columns of chunks, y −64…95), both generators alternating chunk by chunk, the second round timed (secret
areas cached, like a playing world). First version (per-block runs built as arrays): surface 4.84 ms against
3.54 (+37 %). After the rework (inline runs, whole-chunk shortcuts, one-octave floor and dunes, no detail
noise, an integer oasis test), at load 31:

| chunks | Meadows avg ms | Desert avg ms |
|---|---|---|
| surface (y 0…79) | 3.41 | 2.95 |
| underground | 2.42 | 2.19 |
| sky (y ≥ 80) | 1.52 | 0.06 |
| all | 2.82 | 2.36 |

A desert area's secrets (pyramids included) take 0.30 ms on average to place (once per area, then cached).

## Rulings (decided on the owner's behalf; cost if wrong)

1. **Desert blocks stay out of the Sandbox palette** (PLACEABLE): Sandbox is universe 1 only (M3 Task 5) and
   its grid would grow to 14 columns. They are gathered in the desert, sold by Tilly there, and valid in any
   hotbar (`/give sandstone` works in Sandbox). *Cost if wrong:* one list, and the palette's layout test.
2. **Cactus only pushes** (the brief's "decide gently"): no damage, a small push away and a cooldown.
3. **The pyramid is the desert's TEMPLE and the mesa room its ROOM**: the SecretDirector, the Secret Book and
   the loot work unchanged. *Cost if wrong:* the book says "puzzle temple" unless the desert's words are set
   (they are, see the director glue below).
4. **Trap sand is not revealed after a fall** (it never changes): its faint ripples are the fair clue, the pit
   is one block deep under the lid (feet 2 below the floor: a double jump gets out), no damage.
5. **Mummy halves are a crawling top and walking legs** (§14.1 "unwraps into two halves"), level 1 with half a
   level-1 mummy's health, faster, never unwrapping again. *Cost if wrong:* two model filters and a table.
6. **The scorpion's spit hurts its level's nip (1 + l/2, × 2 in universe 2)**, no lingering poison (a green
   splat only). *Cost if wrong:* a poison-over-time rule would need Health ticks and a HUD cue.
7. **The Sand Serpent is a StoneGolem subclass** so the BossDirector, bar, help, gold, portal and tests work
   unchanged. *Cost if wrong:* a common boss base class later; `BossDirector` types `StoneGolem` today.
8. **Serpent numbers**: 360 base health (the Golem 300: the second universe's boss is bigger, and its hits land
   only while it is up), burst 4, sweep 4, ball 3 (the Golem's sizes, not × 2: bosses keep the M2 hits; §5.1
   scaling is for monsters and gold), dizzy 2 s after each sweep. *Cost if wrong:* constants in SerpentRules.
9. **Sandstorms: calm 4–7 minutes, storms 45–80 s, a warning 10 s before, none in the first 150 s of a
   visit**; they only change seeing, never damage or movement. *Cost if wrong:* constants in SandstormRules.
10. **Traps are gentle**: a dart 2 HP (Cozy 1), 0.6 s after a click, 3 s rest per slit; bot friends and
    monsters are not shot or pushed (players only). *Cost if wrong:* the list in `DesertTraps.tick`.
11. **The desert's music**: two CC0 loops by iamoneabe for day and night; the boss fight keeps the M2 boss loop
    (no CC0 desert battle loop fitted). *Cost if wrong:* one more track in the descriptor's `music`.
12. **Tilly's desert stock** is the 11 buildable desert blocks at 1–5 Meadows gold (× 2 in universe 2); she
    buys none of them back (no gold loop). *Cost if wrong:* one dictionary in the descriptor.
13. **Glue stand-ins for M3 Task 5** (`Game.universe`, `--universe=`, `WorldService.setup`'s universe) were kept
    to Task 5's names; merging Task 5 took its side in each (`scenes/main.gd`, `world/world_service.gd`), and
    `WorldService.descriptor()` now reads `UniverseRegistry`. *Cost if wrong:* none left.

## Tried and rejected (the godot-prompter skills)

- **procedural-generation**: seeded noise per column with hash-drawn features (FastNoiseLite, one octave where
  it can be; oases from a per-cell hash like the secrets) — chosen; cellular automata or WFC for mesas —
  rejected (per-chunk state, seams, cost).
- **ai-navigation**: the monsters' own flat steering (seek, keep-distance, back-off) with the safe-step checks
  and 10 Hz decisions — chosen; NavigationAgent3D / navmesh baking — rejected (a streamed, editable voxel world
  would need constant re-baking, far over the monster cost budget).
- **3d-essentials**: the Environment's depth fog and the existing Ambience tint for the sandstorm — chosen
  (every renderer, no new shader); volumetric fog / FogVolume — rejected (Forward+ only: the emulator runs
  Compatibility, phones Mobile); GPU particles for blowing sand — rejected (a shader compile, DEVELOPMENT.md
  §8); the serpent's sand uses the shared `Fx` bursts and ripples.

## Hand-offs

- **Merged with M3 Task 5** (`d304103`): Task 5's `ShopRules` sells `trader_stock` (× 2 in universe 2), its
  Music and SkyCycle play and paint `music` and `sky`, its handshake gives guests the universe, and the
  BossDirector's win unlocks `UniverseRules.next_universe(Game.universe)` (the Serpent: universe 3, coming
  soon). Conflicts were in `audio.gd`, `block_ids.gd` (COUNT 210: the portals), `main.gd` and
  `world_service.gd` (Task 5's side), `sandbox.gd` and `DEVELOPMENT.md` (both).
- Other lists of natural blocks don't know the desert yet (harmless today): `BotRules.GROUND` / `NATURAL`,
  `ToolPowers.GROUND`, `SurpriseRules.METEOR_REPLACES`.
- `BlockIds.COUNT` is 210 after the merge (the portals); the desert keeps 64–78 (page 1, no item ids there).
- The Secret Book counts the desert's kinds under the same names (a pyramid is a "temple" there).

## What the lead should check on the emulator

1. **Open a desert world**: beat the Golem and walk through its portal (or pick the desert's card in the
   SURVIVOR hub); on the desktop `-- --survivor --new-world --universe=2` with a private `XDG_DATA_HOME`.
2. **Looks, both styles**: dunes, striped terraced mesas, an oasis pond with grass and palms, cacti, dry
   bushes; the page-1 blocks in BLOCKY and REALISTIC (sandstone layers, red cliffs, the pyramid's golden tip
   glowing at night); no new shader compile when the first desert chunk appears (page 1 has its own
   materials: watch the first seconds).
3. **Performance**: the autopilot's play phase and 2 km flight in the desert, both styles (the generator is
   cheaper than Meadows' on the desktop; mesas are taller than Meadows' hills, so check the meshing).
4. **Night**: mummies (bandages, sash in the level colour, arms raised before the grab) and scorpions (the tail
   glows green before the spit; the glob is dodgeable by a sidestep); a level 3 mummy unwraps into a crawling
   top and legs.
5. **A sandstorm** (wait about 3 minutes, or play long): the warning toast, the sandy tint and closer fog,
   the wind; readability of the HUD over the tint.
6. **A pyramid**: the clicks and darts of the arrow slits in the corridor, the sand pit (can a child climb out
   with the triple jump?), the plates' puzzle and the golden door, the treasure room's chest; a mesa's hidden
   room behind its lighter fake sandstone patch.
7. **The Sand Serpent** from the desert Totem after wave 5: the ring of shaking sand before each burst (is
   1.4 s enough on a phone?), the tail rattle before the sweep, the dizzy stars, the bar's serpent face.
8. **The desert music** loops (day and night) and the cactus's push.

