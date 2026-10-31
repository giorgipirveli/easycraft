# Cosmos: Titan, world 22 (spec §21b.2)

The owner: "add cosmos, stars and planets where is planet is different universe" (#72) and "make the universies closer to
real worlds so player start learning real things" (#74). Brief: `docs/superpowers/plans/2026-09-29-cosmos-planet-brief.md`
with BODY = Titan, WORLD = 22, PAGE = 29, IDS = 512-527. Built by a worker agent in its own worktree (branch
`worktree-agent-a351cd697758f9e2f`, reset to `lead-cosmos` 8e64dea0 first: lead-merge plus the id fix "ids 400-511 are the
items' forever; the next block page is 29"), without the editor, the emulator or adb (two windowed runs of
`tools/space_shots.gd` for pictures).

## Allocations (used; nothing else touched)

| What | Allocated | Used | Free |
|---|---|---|---|
| World number | 22 (`SpaceRules.TITAN`, already in `SpaceRules` and the Star Map) | Titan | |
| Block ids, page 29 (`TitanBlocks`) | 512-527 | 512-522 | 523-527 |
| `BlockIds.COUNT` | 400 → 528 (400-511 stay the items': empty models in the voxel library) | | |
| `BlockIds.NEXT_PAGE_FIRST_ID` | 512 → 528 (page 30 is the next) | | |
| Atlas page | 29 (`data/blocks/pages/titan*.png`) | rows 0-2 | rows 3-7 |
| Item ids, animals, HUD spots | none | | |
| Server module | 0.2.14 → 0.2.15 (`BuildRules`: blocks up to 1023 travel in builds) | | |

## What a child sees on Titan

1. **Getting there:** fly up above any world; the Star Map opens; Titan's card (Saturn's moon, its three facts: the lead's
   in `StarMap`) now says **LAND**.
2. **Landing:** "You landed on Titan! Look up at Saturn through the orange haze!" on the landing pad, the golden portal
   home three steps away; the Space Book marks Titan landed on.
3. **Around the pad:** plains of orange-brown soil with pale patches of ice pebbles, a few white ice boulders, gentle
   swells; small methane lakes here and there in round hollows (dark amber liquid, a wet dark beach level with it, a ring
   of glowing shore crystals, a gentle coast up to the plains); an **orange haze** for a sky, paler and golden at the
   horizon, an orange fog far away, and **Saturn**, pale and banded with its rings, hanging still in it day and night (at
   night among the stars; no moon disc of home). A soft wind; Morning Mood and Air on the G String. No animals, no
   monsters.
4. **Jumping:** gravity 0.14 (real: 1.35 m/s²): a jump reaches ~12 blocks (1.7 at home) and floats for ~5 s. Every step
   Titan's terrain makes is 8 or less; round every lake and the sea one block. Walking into a 1-block step hops as on the
   Moon (Europa's `LabRules.step_velocity`).
5. **The Landing Probe** (~45-55 blocks from the pad, facing it): a round probe of gold foil and white shell (a foot, a
   wide rim with four lamps, a top), a little mast with a lamp, a step up its front, a golden chest on top, and its
   striped orange-and-white parachute lying flat on the ground behind it. On top: "You found the Landing Probe! A probe
   landed on Titan in 2005: the farthest landing ever."
6. **The methane sea** (MY MAP "Methane Sea", its beach ~150-180 blocks **north** of the pad): a sea ~230 blocks across
   whose shore wanders a little, 8 deep in the middle, a beach level with it all round, a gentle coast. On its beach or
   swimming in it: "You found a sea of liquid methane! Titan's biggest seas lie near its north pole."
7. **Swimming: very floaty.** The methane swims like the game's water (it is the game's water, shown as methane; the view
   under it turns amber) and never hurts. Floating at its surface, **JUMP leaps the child out like a dolphin**: ~6 blocks
   over the methane, ~4 s in the air, a splash back in; holding JUMP they leap again after a moment. Near a bank, JUMP
   climbs out as everywhere.
8. **Methane lakes** (small, more of them to the north; a lake where found goes on MY MAP): "You found a methane lake!
   Titan's rain is methane too: it fills its lakes and rivers."
9. **The dunes** (MY MAP "Dark Dunes", ~150-200 blocks **south** of the pad and on south for ever): long ridges of dark
   grains running east-west, 28 apart, 5-8 high, with pale corridors of soil and pebbles between them. On a dune: "You
   found Titan's dunes! Scientists think their dark grains fell from the orange haze."
10. **The icy mountains** (MY MAP "Icy Mountains", ~200-235 blocks east or west of the pad): a range ~120 long of icy rock
    rising a block per block to a top 30 over the plains (highest in its middle), pale with ice pebbles on top. On top:
    "You climbed Titan's icy mountains! Its tallest peak is about 3.3 km high."
11. **Secrets** (the Secret Book counts them): buried treasure under an X of shore crystals, a hidden ice room of icy rock
    behind a fake icy-rock door, lit by shore crystals, the explorers' station (the puzzle temple in station bricks with
    probe lamps, star gold on top: friendly and made up), shore crystal geodes in the icy rock. No secret is built into the
    methane or on its shores. Each banner: a find, then a fact (below).
12. **Tilly** (Survivor) sells Titan's soil, ice pebbles, dune grains, wet shore, icy rock, shore crystals, station bricks,
    the probe's shell, parachute and lamps, and the landing pad at home prices; never star gold or the fake door.
13. **Home:** walk into the portal or fly up and tap HOME: back on the take-off column, the water water again.

## How it plugs in (the Moon's, Mars's, Europa's and Io's pattern)

- **New files:** `world/universes/titan.gd` (the descriptor), `world/universes/titan_blocks.gd` (page 29),
  `world/generators/titan_terrain.gd` (`TitanTerrain`: the regions as pure rules), `core/rules/titan_rules.gd`
  (`TitanRules`: the methane, its leap and its underwater view), `data/blocks/pages/titan{,_albedo,_normal}.png` (+
  imports, the pages' import settings), `tools/titan_smoke.gd`, `tools/titan_smoke_steps.gd`, tests (below).
- **Shared, small and additive:** `data/blocks/block_ids.gd` (ids, names, `SPACE_GROUND`, `COUNT` 528,
  `NEXT_PAGE_FIRST_ID` 528), `world/block_library.gd` (one register line; `set_liquid` sets the water shader's `methane`,
  `liquid_methane()`), `shaders/water.gdshader` (a `methane` uniform and colour beside the chocolate's: uniforms only, no
  new shader to compile), `world/ambience.gd` + `scenes/sandbox.gd` (`Ambience.methane`: the amber view, one line in
  `_candy_local`), `entities/player/player.gd` (the leap: a few lines in `_swim`, `_floaty_liquid()`),
  `world/generators/space_shape.gd` (planet `TITAN`: a branch per method, `titan_columns`, `titan_kind`,
  `_titan_block_at`, `_titan_calm`, `top_of` fills Titan's basins with liquid, `is_river` is true over them, `sight_at` /
  `sights`), `world/generators/space_generator.gd` (Titan's stack, `_write_titan_column`), `world/generators/
  space_secret_rules.gd` (Titan's palette, `_landing_probe`, `_titan_fits`), `world/universes/universe_registry.gd`
  (`SPACE[22]`), `core/rules/space_rules.gd` (`WORLDS` has 22), the natural-block lists (`bot_rules`, `surprise_rules`,
  `capture_rules`, `gather_rules`, `chat_commands`, `secret_rules.is_fake_wall`), `core/gifts/build_codec.gd` and the
  server's `server/modules/src/rules/build_rules.ts` (blocks up to 1023 travel, never the items' 400-511; module 0.2.15),
  `ui/universe/universe_art.gd` (Titan's card: the Landing Probe and its parachute on orange soil by a methane lake,
  Saturn with its rings in the haze), `core/rules/loading_hints.gd` (seven Titan hints), `tools/make_space_atlas.gd`
  (page 29; `-- titan`), `tools/make_space_realistic.py` (`titan`), `tools/bench_generator.gd` (`BENCH_TITAN_<REGION>`),
  `assets/CREDITS.md`, `docs/DEVELOPMENT.md`, `server/README.md`, spec §21b.2 ("As built").
- **Not touched:** the School, the Science Lab, `ui/space/*` (the Star Map UI), `StarMap`, `WonderData`, the other
  worlds' files (Io's and Europa's tests only for the new `WORLDS` and `COUNT`).
- **Shared tests updated:** `test_space_rules` (WORLDS), `test_space_registry` (warm_space, space_available),
  `test_planet_universes` (space_available), `test_realistic_pack` (TitanBlocks.FILES), `test_io_blocks` (COUNT is past
  the items' ids now), `test_block_id_space` (NEXT_PAGE_FIRST_ID 528), `test_block_pages` (page 29 is 512),
  `test_build_codec` and `test_meadows_blocks` (BLOCK_MAX 1023, the reserved 400-511 checked against the server's),
  `test_space_shape` (the dry-land test skips Titan's methane, like Europa's well), the server's `gift_rules.test.ts`
  (ids) and the module version tests (0.2.15). The shared planet tests (`test_space_shape`, `test_space_secrets`,
  `test_space_generator`) now also run for Titan (it is in `SpaceShape.PLANETS`).

## The big id gap (the brief: "check every table sized by COUNT and the voxel library handle the big gap")

- `BlockLibrary.build()` sizes the models by `COUNT` (528); every id no page owns, the items' 400-511 among them, gets a
  `VoxelBlockyModelEmpty` (`test_the_items_ids_stay_empty_in_the_library`). The voxel type channel is 16-bit, the net
  edit codec and the rewind log write 16-bit ids: nothing to change.
- `BlockIds.is_block_id` / `is_solid` / `is_valid` refuse 400-511 (the lead's fix); `ChatCommands.giveable_ids` loops to
  `COUNT` and gives Titan's blocks (`/give`); `ItemIds.is_item` is a membership test, never "400 and up".
- **`BuildCodec.BLOCK_MAX` was 399** (gifts, showcases, bottles): `test_every_block_of_the_game_can_travel` failed for
  Titan's blocks. The client and the server now let blocks up to 1023 travel, never the items' 400-511
  (`RESERVED_FIRST`/`RESERVED_END` on both sides, `test_the_limits_are_the_servers` compares them); module 0.2.15.
- The real terrain meshes Titan's blocks (a body is stopped by icy rock, id 516) and its SQLite stream saves and loads
  every one of them (`tests/integration/test_titan_world.gd`).

## Rulings (decided on the owner's behalf; cost if wrong)

1. **Titan is a planet kind of `SpaceShape`, its regions in `TitanTerrain`** (Mars's, Europa's and Io's ruling 1). *Cost:*
   none new.
2. **The methane is the game's water** (`BlockIds.WATER`, shown as methane in Titan's world by the one water material's
   `methane` uniform, the Candy Kingdom's chocolate pattern): it swims, flows, splashes and never hurts like water, the
   swim code and every water rule stay one, and a child who places water on Titan gets methane (a bucket of Titan). No
   block id of its own. *Cost:* a separate liquid block would need its own swim, flow and mesher rules.
3. **One liquid level** (`TitanTerrain.LIQUID_TOP` 45): every column whose ground lies under it is filled up to it (like
   Planet Boing's jelly pools, `SpaceShape.top_of`); the plains never dip under it (47+). `is_river` is true over the
   methane, so every spawner's "dry land" (Tilly's spot, the theater, secrets, bots) keeps off it. *Cost:* a river
   flowing downhill would need a second level per river (next).
4. **Very floaty** (the spec: "swim: very floaty, not harmful") is the leap: floating at the surface, JUMP (held or
   tapped) throws the swimmer up at 0.75 of a jump's speed (~6.8 blocks over the start in Titan's gravity, ~4 s in the
   air), the methane letting it go for 0.3 s, the next leap after 0.6 s back in it; a bank in reach is climbed instead
   (owner #30's rule first). It is a game rule, **not a real fact**: a real person would sink in liquid methane (about
   half as dense as water), so no word the game says is about floating in it; the hint says "JUMP to leap out like a
   dolphin". *Cost:* `TitanRules.LEAP`, one line in `player.gd`; the lead should feel it on the emulator (and the HUD's UP
   button while swimming, which holds the same action).
5. **Never harmful:** the game's water never hurts (no drowning exists); the smoke checks the hearts after a swim and a
   leap. The real methane is about −180 °C; the game says nothing about touching it. *Cost:* none.
6. **The sky:** Titan's thick air: `space_sky` 0 (never space's black), `photo_sky` false, an orange palette by day
   (bright: the real noon on Titan is far dimmer than Earth's; spec §3c keeps it friendly), the usual night with stars.
   **Saturn is shown** (the spec: "Saturn's rings in the sky"), 84 across (134 with its rings; the real Saturn is ~5.5°
   from Titan, its rings ~13°), pale and banded, fixed in the sky (Titan is tidally locked), no other moons (the haze).
   The real haze is so thick that Saturn could hardly be seen from Titan's ground: the game shows it anyway and never
   says it can be seen. *Cost:* numbers in the descriptor.
7. **The sea is to the north, the dunes to the south, the mountains east or west** (like the real map: the biggest seas
   near the north pole, the dunes round the equator; north is -z on MY MAP). The sea's middle 250-290 north of the world's
   middle (±60 east-west), its waterline 115 ± 16; the dunes from 130-170 south; the range 220-260 east or west. The pad:
   ≥ 90 from the sea's coast, 80 north of the dunes, 70 from the mountains' foot, 64 from any lake's coast (so the
   Landing Probe, 44-56 away, stays clear of them all). *Cost:* constants in `TitanTerrain` and `_titan_calm`.
8. **Every basin is walked out of:** a waterline one deep (wading, 3 blocks wide), a block deeper every 3 blocks in, a
   beach 4 wide level with the methane's top, a coast of 16 up to the plains; the tests walk 16 ways out of the sea and
   every lake. *Cost:* constants (`SLOPE`, `BEACH`, `COAST`).
9. **Scale:** dunes 5-8 high, 28 apart (real: ~100 m high, 1-3 km apart, hundreds of km long); the mountains 30 over the
   plains (real: up to ~3.3 km); the sea 8 deep (real Kraken Mare: hundreds of metres), lakes 3 deep, radius 8-10.
   *Cost:* constants.
10. **Rock:** icy rock all the way down (water ice as hard as stone), ores in it; no layers, no caves (§21.4). *Cost:*
    none.
11. **Sounds:** no new audio: the wind loop by day and night (thick air; gentle breezes), Morning Mood (the orange haze
    all day) and Air on the G String. *Cost:* a `MusicPieces` entry for a CC0 recording later.
12. **No mission names** (spec §21b.2): "a probe" (Huygens), "the Landing Probe" (made up), "scientists". A test checks
    the words for Huygens, Cassini, Dragonfly, Voyager, Pioneer, Hubble, NASA, ESA and JPL.
13. **Fewer boulders and crystals than the first try:** the first pictures showed a field of white boulders and a thick
    ring of crystals round the sea: ice boulders 2 per mille of plains columns, shore crystals 40 of beach columns; the
    methane went a darker amber so it reads against the haze. *Cost:* three constants.
14. **Gifts carry Titan's blocks:** `BuildCodec.BLOCK_MAX` and the server's `BuildRules.BLOCK_MAX` rose to 1023 with
    400-511 refused on both sides (module 0.2.15). *Cost:* **the lead deploys the server module before shipping this
    client**; until then the server would refuse a gift holding a Titan block (the old client never sends one).

## The facts (every Titan fact in the game, and its check)

| Where | Words | Check |
|---|---|---|
| gravity | 0.14 | 1.352 m/s² ÷ 9.81 = 0.138 (NASA's Saturnian satellite fact sheet; Wikipedia "Titan (moon)") |
| landing | "You landed on Titan! Look up at Saturn through the orange haze!" | the game's sky (ruling 6); "a thick, orange-colored haze" ([NASA: Titan](https://science.nasa.gov/mission/cassini/science/titan/)) |
| treasure | "Titan is bigger than the planet Mercury." | "Titan is bigger than Earth's moon, and larger than even the planet Mercury" ([NASA: Titan facts](https://science.nasa.gov/saturn/moons/titan/facts/)) |
| hidden room | "Titan's rocks are water ice, frozen as hard as stone." | "so cold (−179 °C) that water ice plays the role of rock" (NASA Titan facts); "hills made from ice … rendered hard as rock by the extreme cold" ([ESA: Huygens highlights](https://www.esa.int/Science_Exploration/Space_Science/Results_from_Mars_Express_and_Huygens/Highlights_of_ESA_s_Huygens_mission)) |
| station | "A day on Titan lasts about 16 Earth days." | "Titan takes 15 days and 22 hours to complete a full orbit of Saturn … tidally locked … always shows the same face" (NASA Titan facts) |
| Landing Probe | "A probe landed on Titan in 2005: the farthest landing ever." | "At 13:34 CET on 14 January 2005, Huygens became the most distant manmade object to land on another world … the most distant landing from Earth" ([ESA](https://www.esa.int/Science_Exploration/Space_Science/Cassini-Huygens/Celebrating_the_fifth_anniversary_of_Huygens_Titan_touchdown)); it came down under parachutes (ESA: "2 hours and 28 minutes descending by parachute") |
| geode | "Drying lakes on Titan leave bright rings, like a bathtub." | "'bathtub rings' similar to those observed by Cassini around some of the Northern lakes" ([NASA Astrobiology, JPL Titan team](https://astrobiology.nasa.gov/nai/annual-reports/2011/jpl-titan/task-332-precipitation-of-organics-in-titan-lakes/index.html)); evaporite "the Titan equivalent of salt flats" ([JPL PIA17470](https://www.jpl.nasa.gov/images/pia17470-titans-northern-lakes-salt-flats/)) |
| sea | "Titan's biggest seas lie near its north pole." | "Kraken Mare, Titan's largest sea, sprawls from just below … the north pole … Ligeia Mare, Titan's second largest sea … above the north pole" ([JPL PIA17655](https://www.jpl.nasa.gov/images/pia17655-titans-north/)); the liquid "mostly methane and ethane" |
| lake | "Titan's rain is methane too: it fills its lakes and rivers." | "Methane and ethane … carves river channels and fills great lakes with liquid natural gas" (NASA Titan facts); Huygens landed by a dry riverbed "which probably funnels the methane rain off the hills" (ESA highlights) |
| dunes | "Scientists think their dark grains fell from the orange haze." | "The long, linear dunes are thought to be comprised of grains derived from hydrocarbons that have settled out of Titan's atmosphere" ([JPL: Dunes of Shangri-La](https://www.jpl.nasa.gov/videos/dunes-of-shangri-la-on-saturns-moon-titan/)); the haze is that smog ([NASA: Titan](https://science.nasa.gov/mission/cassini/science/titan/)) |
| mountains | "Its tallest peak is about 3.3 km high." | "Titan's tallest peak is 10,948 feet (3,337 meters) high … within … the Mithrim Montes" ([JPL: Cassini spies Titan's tallest peaks](https://www.jpl.nasa.gov/news/cassini-spies-titans-tallest-peaks/)) |
| hint | "On Titan you jump about 7 times as high!" | 1 ÷ 0.138 = 7.2 |
| hint | "Titan's thick air is mostly nitrogen, like Earth's!" | "mostly nitrogen (about 95 percent) and methane (about 5 percent)" (NASA Titan facts); Earth's is 78 % nitrogen |
| hint | "Titan's air presses about 1.5 times as hard as Earth's." | 146.7 kPa at the surface, 1.45 times Earth's (Wikipedia, from Huygens); NASA: "about 60 percent greater" |
| hint | "Titan has rain, rivers and seas, but of methane!" | NASA Titan facts (above); "the only world in our solar system other than Earth that has stable liquid on its surface" (JPL PIA17655) |
| hint | "In methane lakes, JUMP to leap out like a dolphin!" | the game's own rule (ruling 4) |
| terrain | ice pebbles round the probe | "Water-ice pebbles up to a few centimetres in diameter were scattered near the landing site" (ESA highlights) |

(The Star Map's own three Titan facts are the lead's, in `core/rules/star_map.gd`; unchanged.)

## Tests (RED → GREEN)

| Test file | Tests | RED (why it failed first) |
|---|---|---|
| `tests/unit/test_titan_blocks.gd` | 10 | `BlockIds.TITAN_SOIL` …, `TitanBlocks` not declared — run and seen |
| `tests/unit/test_titan_shape.gd` | 14 | written before `TitanTerrain` (not declared); first run after the terrain was written (all green) |
| `tests/unit/test_titan_generator.gd` | 6 | the generic column writer: plains layers everywhere and Boing's jelly in the basins — run and seen |
| `tests/unit/test_titan_secrets.gd` | 7 | the Moon's palette and the Moon Base on Titan — run and seen; the test's own box count then used a box's exclusive end |
| `tests/unit/test_titan_universe.gd` | 12 | `TitanRules` not declared, no `titan.gd` — run and seen |
| `tests/unit/test_titan_swim.gd` | 6 | `TitanRules`, `BlockLibrary.liquid_methane()` not found — run and seen; a float alpha compared exactly, then almost |
| `tests/integration/test_titan_world.gd` | 5 | written with the descriptor (the save, load and mesh checks past the id gap) |
| `tests/integration/test_titan_sky.gd` | 2 | written with the descriptor; its ring check first sampled a row the ring does not cross |
| `tests/integration/test_titan_sights.gd` | 4 | written with the descriptor |
| shared (see above) | | WORLDS, warm_space and space_available lists, COUNT, the id plan, the realistic pack's pages, BuildCodec's limit, the dry-land test |

## Measurements

Generator bench (`bench_generator.gd -- --space moon io titan`, 640 chunks per planet alternating with Green Meadows; the
PC's load 13-15 on 24 cores):

| chunks | Meadows avg ms | Moon | Io | Titan |
|---|---|---|---|---|
| surface, warm (stacks cached) | 1.52-1.57 | 1.40 | 0.74 | **0.65** (worst 1.66) |
| surface, cold (fresh generators, a stack's chunks in a row) | 1.66-1.83 | 1.99 | 1.27 | **0.95** (worst 2.68) |
| underground | 1.12-1.17 | 0.29 | 0.28 | **0.28** |
| sky (y 80+) | 0.77-0.83 | 0.01 | 0.01 | **0.01** |
| all, cold | 1.36-1.51 | 1.11 | 0.76 | **0.59** |
| a new area's secrets (once, then cached) | — | 0.59 (worst 1.33) | 0.45 (worst 1.07) | **0.44 (worst 1.38)** |

Titan's regions (`BENCH_TITAN_<REGION>`, fresh generators over 4 × 4 whole chunk stacks, y -64..159, against the meadows
on the same chunks): the sea's shore 0.43 ms vs 1.24 (worst 2.35), the dunes 0.44 vs 1.21 (worst 2.14), the mountains'
flank 0.48 vs 0.91 (worst 2.46); underground 0.29-0.31 vs 1.19-1.26. `TitanTerrain.column` costs ~3.2 µs.

Geography (`SpaceShape`/`TitanTerrain`, printed by a scratch script; kinds over 20,000 columns in ±1000):

| seed | pad (ground) | sea's beach (from the pad) | first dune south | mountains' top (from the pad, its height) | Landing Probe | lakes in 16 × 16 cells | plains / pebbles / dunes / shores / lakes / sea |
|---|---|---|---|---|---|---|---|
| 12345 | (-16, 28) at 49 | (3, -153), 182 | (-16, 176), 148 | (-248, -9), 235, 81 | (-59, 49, 55) | 81 | 62.5 / 13.4 / 20.4 / 1.9 / 0.4 / 1.1 % |
| 77 | (0, 0) at 50 | (-9, -171), 171 | (0, 150), 150 | (232, -5), 232, 80 | (-26, 50, -47) | 77 | 61.4 / 13.3 / 21.1 / 2.3 / 0.6 / 0.9 % |
| 777 | (0, 0) at 50 | (20, -153), 154 | (0, 149), 149 | (228, -38), 231, 80 | (-24, 51, 39) | 76 | 62.8 / 13.5 / 20.4 / 1.6 / 0.5 / 1.0 % |
| 42 | (-45, -16) at 50 | (-35, -168), 152 | (-45, 180), 196 | (-247, -13), 202, 81 | (-28, 51, -60) | 76 | 61.7 / 13.8 / 20.6 / 2.0 / 0.5 / 1.1 % |

## Smoke runs

- `tools/titan_smoke.gd` (seed 12345, a private `XDG_DATA_HOME` with "smoke" in its path and a copy of `profile.json`):
  **43 checks, 0 fails** (exit 0; twice, the second after the last tuning): a new Green Meadows Sandbox world (home's
  water is water); the Star Map; Titan's card (3 facts, LAND); Titan's own world `sandbox_22`, its terrain, gravity 0.14,
  never space's black sky, an orange haze by day, never the photo sky, Saturn and its rings, no other moons, the water
  shown as methane and the amber view under it, on the landing pad, peaceful, no animals, MY MAP's pad and three sights,
  the Space Book's LANDED mark, the sights watched, no geysers; the portal home by the pad; a slow fall (0.95 m/s after
  0.3 s); the Landing Probe is the landmark and is found on its top, then shown on MY MAP; the sea's beach says its fact;
  the sea is liquid; swimming in it; **JUMP leaps the swimmer out like a dolphin (feet 5.8 blocks over the methane at the
  top)**, hearts unchanged (20); a dune says its fact (standing on dune grains); the mountains' top says its fact (height
  80); a lake's beach says its fact; through the portal home: Green Meadows `sandbox_1`, on the take-off column, home
  gravity, the water water again.
- After this work's shared changes: `tools/io_smoke.gd` **36 checks, 0 fails**; `tools/europa_smoke.gd` **34, 0 fails**;
  `tools/space_smoke.gd` (the Moon and Planet Boing) **36, 0 fails**; `tools/candy_smoke.gd` (the chocolate water) **47,
  0 fails**. The server module's tests: **323 pass** (`npm test`, with the main checkout's `node_modules`).

## Pictures (`tools/space_shots.gd -- --universe=22 --sights`, windowed, both styles)

Seen: from over the pad, an orange haze paler and golden toward the horizon, Saturn pale and banded with its rings high
in the sky; orange-brown plains to the horizon with pale patches of ice pebbles, contour lines where the ground steps,
round lake hollows with a ring of white shore crystals, a few ice boulders; at sunset the haze turns a dusky pink-orange;
at night Saturn and its rings among the stars on a dark blue sky. The sea from its beach: a wide flat dark-amber liquid
reaching into the orange fog, a dark wet beach with white crystals. The dunes: long dark-brown ridges in bands with pale
corridors. The mountains' top: a pale pebbly summit, grey icy rock down its sides. The first pictures showed a field of
white boulders and a sea blending with the haze (ruling 13). REALISTIC looks close to BLOCKY at 640 × 360. A "Theater"
building stood near the pad (the places system's, not Titan's).

## Full suite

`tests/run_tests.sh` (2026-09-29 ~19:27-20:05, load 13-17, on the code of commit 189fb112): **814 scripts, 7449 tests,
7447 passing, 0 failing, 2 risky** (`test_meadows_biome_generator.gd`'s two that never assert, as before this work), no
script errors. After it only the docs and one hint's words changed ("about 1.5 times"; its ≤ 10 words check is
`test_titan_universe`'s).

## The lead's checklist (emulator, both styles)

1. **Deploy the server module 0.2.15** (builds may hold blocks up to 1023) before or with this client (ruling 14).
2. Sandbox, Green Meadows: fly up; on the Star Map tap Titan: LAND. The loading card shows Titan's picture (the Landing
   Probe and its parachute by a methane lake, Saturn with its rings in the haze) and a Titan hint.
3. On Titan: the orange haze (too bright? too orange?), Saturn (too big through a haze?), the plains' pebbles and boulders.
4. Jump: ~12 blocks, a ~5 s float. Walk over the plains' 1-block steps (the gentle hop).
5. MAP → Methane Sea: walk down the beach into it (wading, then swimming), the amber view under it; hold JUMP at the
   surface: the dolphin leap (~6 blocks) — is it fun, is it clear? Does the HUD's UP button while swimming leap too? Walk
   out on the beach. A small lake's beach.
6. MAP → Dark Dunes: walk over them (1-2 block steps), their dark grains in both styles.
7. MAP → Icy Mountains: up the slope (a block per block), the pale top.
8. The Landing Probe (the step or a jump to its top), the station's puzzle, a shore crystal geode (dig), the ice room.
9. Survivor: the bag goes to Titan and home; Tilly's Titan things. A gift or showcase holding a Titan block (after the
   server deploy).
10. Page 29's first frames compile its materials (like any new universe). Performance by the sea (a big water surface;
    ≥ 30 FPS, no frame over 100 ms): the autopilot with `--universe=22`.

## Next (the game never ends)

Methane rain (slow, big drops; check the numbers against a source before it goes in the game) and the lakes filling and shrinking with the
seasons; rivers running down into the sea in canyons (Vid Flumina-like) and flooded river valleys along its shore; dry
lake beds with evaporite floors in the south; cryovolcano candidates; the far side where Saturn is never seen; a flying
robot to find (a rotorcraft is being built to explore Titan); Titan's own music; a Planet Book page for Titan.
