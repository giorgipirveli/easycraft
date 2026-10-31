# Cosmos: Io, world 21 (spec §21b.2)

The owner: "add cosmos, stars and planets where is planet is different universe" (#72) and "make the universies closer to
real worlds so player start learning real things" (#74). Brief: `docs/superpowers/plans/2026-09-29-cosmos-planet-brief.md`
with BODY = Io, WORLD = 21, PAGE = 21, IDS = 384-399. Built by a worker agent in its own worktree (branch
`worktree-agent-a80015e58b176d89e`, reset to `lead-merge` c10175ca first), without the editor, the emulator or adb (two
windowed runs of `tools/space_shots.gd` for pictures).

## Allocations (used; nothing else touched)

| What | Allocated | Used | Free |
|---|---|---|---|
| World number | 21 (`SpaceRules.IO`, already in `SpaceRules` and the Star Map) | Io | |
| Block ids, page 21 (`IoBlocks`) | 384-399 | 384-398 | 399 |
| `BlockIds.COUNT` | 384 → 400 | | |
| Atlas page | 21 (`data/blocks/pages/io*.png`; it was `test_block_pages.gd`'s test page: moved to 99) | rows 0-3 | rows 4-7 |
| Item ids, animals, HUD spots | none | | |

**Page 21 is the last block page under the items' ids** (items own 400-499: gadgets 400-429, treats 430-434, paint
435-450, the stick 451, gift stamps 460-479, crystals 480-484, the child's stamps 495-499). The next planet (Titan,
world 22) needs a new id plan from the lead: page 29 (ids 512-527) is the first whole page past the items; `COUNT` would
then pass through 400-511, and `BlockIds.is_solid(id)` is `id < COUNT and not NON_SOLID` (an item id would read as solid:
check its callers first), `is_valid` refuses them (no names).

## What a child sees on Io

1. **Getting there:** fly up above any world; the Star Map opens; Io's card (Jupiter's moon, its three facts: the lead's
   in `StarMap`) now says **LAND**.
2. **Landing:** "You landed on Io! Watch the volcanoes and look up at Jupiter!" on the landing pad, the golden portal home
   three steps away; the Space Book marks Io landed on.
3. **Around the pad:** bright yellow sulphur plains with big orange patches and white frost (frozen sulphur dioxide),
   gentle swells, a 1-block step now and then; a few glowing sulphur crystals and black lava boulders; small lava lakes
   here and there (a hollow of black crust with glowing orange cracks and a black shore); black space overhead with stars
   by day (almost no air); **giant Jupiter**, bigger than over Europa (Io is closer), banded, its Great Red Spot, hanging
   still in the sky day and night, with little white Europa and grey Ganymede elsewhere (no moon disc of home). Soft
   chimes; Figaro by day, the Moonlight Sonata at night. No animals, no monsters.
4. **Jumping:** gravity 0.18 (real: 1.80 m/s²): a jump reaches ~9.4 blocks (1.7 at home), floats ~4.2 s. Every step Io's
   terrain makes is 8 or less. Walking into a 1-block step hops as on the Moon (Europa's `LabRules.step_velocity`).
5. **The Volcano Lander** (~45-55 blocks from the pad, facing it): four metal legs, a body of white heat tiles with a gold
   stripe, lights on the deck's corners, a mast with the glowing heat camera looking out, a dish, two steps up its front,
   a heat probe down into the ground, a golden chest on the deck. On the deck: "You found the Volcano Lander! A spacecraft
   first saw a volcano erupting on Io in 1979."
6. **Volcanoes** (about one per 170 × 170 blocks; MY MAP shows the one nearest the pad, "Volcano"): a stepped cone of
   black lava rock 6 high, a crater on top with the glowing vent at its bottom, a skirt of black lava round its foot and
   a ring of red sulphur further out. The volcanoes near the child erupt now and then (each on its own beat: 3 s of every
   9), puffs of yellow sulphur rising from the vent (`SpaceGeysers`, a soft whoosh). On the cone: "You found an erupting
   volcano! Io's plumes shoot up to about 400 km high." Step down onto the vent: **whoosh**, the plume throws the child
   ~30 blocks up and they float down for ~7 s. On a red ring: "You found a red ring! Some plumes drop red sulphur in rings
   over 1,000 km wide." (MY MAP marks it there.)
7. **The lava lake** (MY MAP "Lava Lake", ~180-230 blocks from the pad): a round hollow 62 across; a rim of black lava
   rock one block over the flat ground round it (a fence); inside it a moat of bright hot lava **two blocks wide**, five
   under the rim's top; inside the moat a flat crust of black lava with glowing cracks (safe to walk on), three under the
   ground, with hot lava under it (a child who digs through meets it). **Four causeways** of black lava rock step down one
   block at a time from the rim across the moat to the crust. On the rim (before the hot lava) or anywhere on the lake:
   "You found a lava lake! Io's biggest is about 200 km across. Its crust sinks in slow waves."
8. **Hot lava never hurts** (ruling 2): touching it, a warm bounce (orange sparks, a soft boing) throws the child ~7 blocks
   up, keeping the way they were going: out of the moat (two blocks wide) onto the crust or the rim, with ~3.7 s in the
   air to steer. The smoke checks it: up 4+ blocks at once, health unchanged.
9. **The tall mountain** (MY MAP "Tall Mountain", ~210-330 blocks from the pad, on the far side from the lake): a tilted
   block of crust 110 long and 72 wide, rising gently (a block per block) from one long side to a flat top 40 over the
   plains, white with frost, and falling steeply (3 blocks per block: a jump each) on the other sides, its faces showing
   Io's rock in layers of black lava. On top: "You climbed an Io mountain! The tallest is about twice as high as Mount
   Everest."
10. **Secrets** (the Secret Book counts them): buried treasure under an X of sulphur crystals, a hidden warm room of black
    lava rock (like a lava tube) behind a fake Io-rock door, lit by glowing lava crust, the explorers' station (the puzzle
    temple in sulphur bricks, heat cameras for lamps, star gold on top: friendly and made up), sulphur crystal geodes. No
    secret is built into the big lava lake or onto a volcano. Each banner: a find, then a fact (below).
11. **Tilly** (Survivor) sells Io's sulphur (four colours), Io rock, black lava rock, lava crust, sulphur crystals and
    bricks, heat tiles, lander legs, heat cameras and the landing pad at home prices; never hot lava, a vent, star gold or
    the fake door.
12. **Home:** walk into the portal or fly up and tap HOME: back on the take-off column.

## How it plugs in (the Moon's, Mars's and Europa's pattern)

- **New files:** `world/universes/io.gd` (the descriptor), `world/universes/io_blocks.gd` (page 21),
  `world/generators/io_terrain.gd` (`IoTerrain`: the regions as pure rules), `data/blocks/pages/io{,_albedo,_normal}.png`
  (+ imports, the pages' import settings), `tools/io_smoke.gd`, `tools/io_smoke_steps.gd`, tests (below).
- **Shared, small and additive:** `data/blocks/block_ids.gd` (ids, names, `SPACE_GROUND`, `COUNT` 400),
  `world/block_library.gd` (one register line), `world/generators/space_shape.gd` (planet `IO`: a branch per method,
  `io_columns`, `io_kind`, `_io_block_at`, `_io_calm`, `sight_at`/`sights`; new generic `vents_near`, `has_vents`,
  `_pad_blend`), `world/generators/space_generator.gd` (Io's stack, `_fill_io_layers`, `_write_io_column`),
  `world/generators/space_secret_rules.gd` (Io's palette, `_volcano_lander`, `_io_fits`), `world/universes/universe_registry.gd`
  (`SPACE[21]`), `core/rules/space_rules.gd` (`WORLDS` has 21), `core/rules/pad_rules.gd` (the volcano vent at
  `GEYSER_SPEED`, hot lava at `LAVA_SPEED`) + `entities/fx/pad_fx.gd` (their puffs), `world/space_geysers.gd`
  (`shape.vents_near` for any planet with vents, `plume_color`: yellow sulphur on Io, Europa's white vapour unchanged),
  `scenes/sandbox.gd` (`_space_geysers()` for any shape with vents), the natural-block lists (`bot_rules`,
  `surprise_rules`, `capture_rules`, `gather_rules`, `chat_commands`, `secret_rules.is_fake_wall`),
  `ui/universe/universe_art.gd` (Io's card: the Volcano Lander on yellow sulphur by a glowing lava pool, giant banded
  Jupiter, little Europa, a far volcano's umbrella plume), `core/rules/loading_hints.gd` (seven Io hints),
  `tools/make_space_atlas.gd` (page 21; `-- io`), `tools/make_space_realistic.py` (`io`), `tools/bench_generator.gd`
  (`BENCH_IO_<REGION>`), `assets/CREDITS.md`, `docs/DEVELOPMENT.md`, spec §21b.2 ("As built").
- **Not touched:** the School, the Science Lab, `ui/space/*` (the Star Map UI), `StarMap`, `WonderData`, the other
  worlds' files (Europa's `SpaceGeysers` and sandbox line generalised, its behaviour and tests unchanged).
- **Shared tests updated for world 21 and COUNT 400:** `test_space_rules` (WORLDS), `test_space_registry` (warm_space,
  space_available), `test_planet_universes` (space_available), `test_realistic_pack` (IoBlocks.FILES),
  `test_block_pages` (its test page moved from 21 to 99; page 21's range now says it is Io's). The shared planet tests
  (`test_space_shape`, `test_space_secrets`, `test_space_generator`) now also run for Io (it is in `SpaceShape.PLANETS`).

## Rulings (decided on the owner's behalf; cost if wrong)

1. **Io is a planet kind of `SpaceShape`, its regions in `IoTerrain`** (Mars's and Europa's ruling 1): every column is a
   plain column (no overhangs, no carving), so the generator writes whole columns. *Cost:* none new.
2. **Hot lava never hurts and never traps** (spec §3c, the brief: "never hurt or stuck by it without warning"):
   - `HOT_LAVA` is a `PadRules` pad at `LAVA_SPEED` 8 m/s: a warm bounce ~7.4 blocks up on Io (1.3 at home), ~3.7 s in
     the air, keeping the way the child was going; gentler than a jump there (9.4). No damage anywhere (the smoke checks
     the hearts). Standing still on it bounces in place, like a jump pad, until the child steers (never stuck).
   - Hot lava is only a band **two blocks wide** (the big lake's moat; `test_a_narrow_moat…` checks every cell of it is
     within 2 of other ground), one under the crust, five under the rim; a bounce clears the rim.
   - Warnings: it glows bright orange-yellow; the rim of black rock fences it (a visual fence: a jump climbs it); the
     lake's fact fires on the rim, before the moat; a loading hint says "Hot lava bounces you out. The dark crust is
     safe!"; four causeways cross the moat without touching it.
   - The **lava crust** (`LAVA_CRUST`: black with glowing cracks) is solid safe ground; the small lava lakes are crust
     only (cooled: no hot lava).
   *Cost:* `LAVA_SPEED` is one constant; a push away from the lake (not only up) would need the lake's shape in the pads.
3. **One big lava lake with hot lava** (~180-230 from the pad; the real Loki is ~200 km across), the small ones cooled
   crust. The lake's fact talks about Io's biggest lake, so it fits the first lava lake a child finds, big or small.
   *Cost:* constants in `IoTerrain`.
4. **A volcano's vent is a pad** at `GEYSER_SPEED` (Europa's plumes, the jump pad's 16 m/s: ~30 blocks up on Io, ~7 s
   of float). `SpaceGeysers` now serves any planet with vents (`SpaceShape.vents_near`, `has_vents`); Io's puffs are
   yellow sulphur (`plume_color`). A vent given with `/give` works anywhere. *Cost:* none new.
5. **The volcanoes are low stepped cones** (6 high, a crater 3 deep): real Io volcanoes are mostly paterae (flat-floored
   calderas, the small lava lakes here) and low shields; a cone says "volcano" to a child at a glance. Red rings (Pele's)
   11-16 blocks from the vent. *Cost:* constants.
6. **The mountain is a tilted block of crust**, 40 over the plains (real: up to ~17.5 km), a gentle side (a block per
   block) and steep sides (3 per block, a jump each); its white top is frost (no fact is said for the frost). *Cost:*
   constants (`MOUNT_A`, `MOUNT_B`, `PEAK_H`, `RAMP`, `SIDE`).
7. **Heights and steps:** the plains ~48 (±3), `MAX_STEP` 8 (a jump at 0.18 reaches 9.4). *Cost:* constants.
8. **Sky:** space's black sky all day (`space_sky` 1: Io's air is a trace of sulphur dioxide), `photo_sky` false; Jupiter
   136 across at the sky's radius (~33°; the real one is ~19° from Io: exaggerated as over Europa, and bigger than
   Europa's 104 because Io is closer), fixed in the sky (tidally locked); Europa and Ganymede (12 and 10 across; real
   ≤ ~0.7°) as `moons`; `own_moons`. A warm amber glow at the horizon and fog. *Cost:* numbers in the descriptor.
9. **Sounds:** no new audio: the chimes loop by day and night (almost no air), Figaro (a day piece) and the Moonlight
   Sonata (a night piece) as favourites. "In the Hall of the Mountain King" fits volcanoes but is a BOSS-mood piece: it
   would never play on an ordinary day (a test checks the favourites are not boss pieces). The vents' whoosh, the lava's
   soft boing. *Cost:* a `MusicPieces` entry.
10. **No mission names** (spec §21b.2): "a spacecraft" (Voyager 1's 1979 discovery), "heat camera" (the Volcano Lander is
    made up). A test checks for Galileo, Juno, Voyager, Pioneer, Hubble, New Horizons, NASA, ESA and JPL.
11. **Where things are:** the lake 170-230 blocks from the world's middle in a seeded direction, the mountain 210-260 on
    the far side (150-210° round); the pad near the middle ≥ 120 from the lake, ≥ 80 beyond the mountain's foot, ≥ 80
    from any vent, ≥ 64 from any small lava lake (so the Volcano Lander, 44-56 away, stands clear of them all).
12. **Fewer crystals and boulders than the first try:** the pictures showed a field of posts round the pad: sulphur
    crystals 8 per mille of plains columns, lava boulders 2. *Cost:* two constants.
13. **The block pages' test page moved to 99** (`test_block_pages.gd` registered and unregistered page 21 for its own
    tests: it would have taken Io's page away from every later test). *Cost:* none.
14. **Next (the game never ends):** a lava fountain curtain along a fissure (Tvashtar-like), Loki's island in the big
    lake and its crust overturning in slow waves (animated), plumes' umbrella deposits falling as sulphur snow,
    Jupiter's shadow eclipsing the sun every Io day, green sulphur patches, a Planet Book page for Io.

## The facts (every Io fact in the game, and its check)

| Where | Words | Check |
|---|---|---|
| gravity | 0.18 | "1.796 m/s² (18.3% g)" ([Wikipedia: Io](https://en.wikipedia.org/wiki/Io_(moon))); 1.796 ÷ 9.81 = 0.183 |
| landing | "You landed on Io! Watch the volcanoes and look up at Jupiter!" | "Io rotates synchronously … keeping one face nearly pointed toward Jupiter" (Wikipedia) |
| treasure | "Io is a little bigger than our Moon." | "A bit larger than Earth's Moon" ([NASA: Io facts](https://science.nasa.gov/jupiter/jupiter-moons/io/facts/)) |
| hidden room | "Jupiter's pull squeezes Io and heats up its inside." | "a tug-of-war between Jupiter's powerful gravity and … Europa and Ganymede … causes Io to flex … and generate heat by friction" ([NASA: Underground magma ocean…](https://www.nasa.gov/missions/underground-magma-ocean-could-explain-ios-misplaced-volcanoes/)); "The flexing from gravity causes tidal heating" ([JPL](https://www.jpl.nasa.gov/news/scientists-to-io-volcanoes-are-in-the-wrong-spot/)) |
| station | "A day on Io lasts about 42 hours." | "It takes Io about 42.5 hours (1.77 days) to complete one orbit around Jupiter" and it rotates synchronously (Wikipedia) |
| Volcano Lander | "A spacecraft first saw a volcano erupting on Io in 1979." | "Volcanic activity there wasn't discovered until 1979, when imaging scientist Linda Morabito … first identified a volcanic plume in an image from … Voyager 1" ([JPL: Juno uncovers heart of Io's volcanic rage](https://www.jpl.nasa.gov/news/nasas-juno-mission-uncovers-heart-of-jovian-moons-volcanic-rage/)) |
| geode | "Sulphur paints Io yellow, orange and red." | "Sulfur … forming yellow to yellow-green regions"; red deposits from "sulfur (generally 3- and 4-chain molecular sulfur)" (Wikipedia); the Star Map's own card: "Its yellow and orange colours come from sulphur." |
| lava lake | "Io's biggest is about 200 km across. Its crust sinks in slow waves." | Loki Patera "is about 200 kilometers across"; its lake overturns as "the cooling surface crust … sinks, pulling nearby crust with it in a wave that propagates across the surface" ([UC Berkeley 2017](https://vcresearch.berkeley.edu/news/waves-lava-seen-ios-largest-volcanic-crater); de Kleer et al., Nature 2017); Wikipedia: 202 km |
| mountain | "The tallest is about twice as high as Mount Everest." | South Boösaule Montes "17.5 ± 1.5 km" (Wikipedia, from Schenk et al. 2001); Everest 8.85 km: 1.8-2.1 times |
| volcano | "Io's plumes shoot up to about 400 km high." | "some erupting lava fountains up to 250 miles high (about 400 kilometers)" (JPL, above); Wikipedia: "plumes … as high as 500 km" |
| red ring | "Some plumes drop red sulphur in rings over 1,000 km wide." | Pele: "red rings more than 1,000 km (620 mi) in diameter" of short-chain sulphur (Wikipedia) |
| hint | "On Io you jump over 5 times as high!" | 1 ÷ 0.183 = 5.5 |
| hint | "Io has about 400 volcanoes: more than anywhere else!" | "The moon is home to an estimated 400 volcanoes" (JPL, Juno); "the most volcanically active world in the solar system" (NASA) |
| hint | "Jupiter never moves in Io's sky!" | synchronous rotation (above); true where Jupiter is seen at all (the far side never sees it; the game shows it everywhere) |
| hint | "Hot lava bounces you out. The dark crust is safe!" | the game's own rule (ruling 2) |
| terrain | white frost | "Sulfur dioxide frost is ubiquitous across the surface of Io, forming large regions covered in white or grey materials" (Wikipedia) |
| terrain | no water, no rivers | "It has no water to speak of" (NASA facts) |
| sky | Jupiter, Europa, Ganymede | Jupiter (139,820 km at 421,700 km) ~19° across; Europa (3,122 km at ≥ ~250,000 km) ≤ ~0.7°, Ganymede ≤ ~0.5°; the game makes them bigger |

(The Star Map's own three Io facts are the lead's, in `core/rules/star_map.gd`; unchanged.)

## Tests (RED → GREEN)

| Test file | Tests | RED (why it failed first) |
|---|---|---|
| `tests/unit/test_io_blocks.gd` | 10 | ids not declared (`BlockIds.SULPHUR`, `IoBlocks`, `IoTerrain`) — run and seen |
| `tests/unit/test_io_shape.gd` | 16 | written before `IoTerrain` / `SpaceShape.IO`; then the causeway test's sampling along a rounded ray (2-block jumps; the cell-to-cell walk is 1) and a risky hot-lava test (no sample hit the moat) were fixed |
| `tests/unit/test_io_universe.gd` | 11 | `SpaceRules.WORLDS` without 21, no `io.gd` (null descriptor, Moon Base as the landmark) — run and seen |
| `tests/unit/test_io_secrets.gd` | 7 | Moon rock in Io's temples (no palette) — run and seen; the legs test then counted the camera's mast too |
| `tests/unit/test_io_generator.gd` | 7 | the generic column writer disagreed with the reference (plains layers everywhere) — run and seen |
| `tests/integration/test_io_world.gd` | 3 | written with the descriptor |
| `tests/integration/test_io_sky.gd` | 2 | written with the descriptor |
| `tests/integration/test_io_sights.gd` | 5 | `SpaceGeysers.plume_color` not found — run and seen |
| shared (see above) | | WORLDS, warm_space and space_available lists, the realistic pack's pages, the block pages' test page |

## Measurements

Generator bench (`bench_generator.gd -- --space moon europa io`, 640 chunks per planet alternating with Green Meadows;
the PC's load 5-8 on 24 cores; the second run after the patera speed-up):

| chunks | Meadows avg ms | Moon | Europa | Io |
|---|---|---|---|---|
| surface, warm (stacks cached) | 1.48-1.50 | 1.30 | 0.45 | **0.75** |
| surface, cold (fresh generators, a stack's chunks in a row) | 1.62-1.63 | 1.82-1.87 | 0.71 | **1.17** (1.43 before the speed-up) |
| underground | 1.07-1.10 | 0.27-0.28 | 0.26 | **0.27** |
| sky (y 80+) | 0.75-0.78 | 0.01 | 0.01 | **0.01** |
| all, cold | 1.33-1.35 | 1.02-1.04 | 0.46 | **0.70** |
| a new area's secrets (once, then cached) | — | 0.57-0.68 (worst 2.0) | 0.32 (worst 0.68) | **0.37 (worst 0.73)** |

Io's regions (`BENCH_IO_<REGION>`, fresh generators over 4 × 4 whole chunk stacks, y -64..159, against the meadows on the
same chunks): the lava lake 0.42 ms vs 0.84 (worst 1.97), the mountain's steep side 0.63 vs 1.18 (worst 2.83), a volcano
0.65 vs 1.15 (worst 3.48; 5.90 before the speed-up); underground 0.28 vs 1.11-1.19. `IoTerrain.column` costs ~5 µs
(the swell, two patch noises, the cells of a vent and a small lava lake).

Geography (`SpaceShape`/`IoTerrain`, printed by a scratch script; kinds over 20,000 columns in ±1000):

| seed | pad (ground) | lava lake (from the pad) | mountain top (from the pad, its top) | nearest volcano | Volcano Lander | plains / orange / frost / red / small lakes |
|---|---|---|---|---|---|---|
| 12345 | (-28, 16) at 49 | (195, 60), 227 | (-259, -29), 235, 88 | (-105, 87), 105 | (-56, 48, -32) | 68.9 / 17.4 / 10.5 / 0.9 / 0.9 % |
| 77 | (16, 0) at 48 | (-201, -32), 219 | (212, -81), 212, 88 | (-64, 38), 89 | (-37, 49, -16) | 70.1 / 16.7 / 9.6 / 0.9 / 1.2 % |
| 777 | (0, 0) at 48 | (163, 158), 227 | (-104, -193), 219, 88 | (-108, 82), 136 | (-24, 49, 39) | 70.3 / 16.7 / 10.2 / 0.8 / 0.8 % |
| 42 | (64, 0) at 48 | (122, -174), 183 | (-230, 144), 327, 87 | (35, -76), 81 | (81, 47, -43) | 72.3 / 15.8 / 8.9 / 0.9 / 0.8 % |

## Smoke runs

- `tools/io_smoke.gd` (a private `XDG_DATA_HOME` with "smoke" in its path and a copy of `profile.json`): **36 checks, 0
  fails** (exit 0; three times, the last after the final changes; each landing makes a new Io, so three seeds): a new Green
  Meadows Sandbox world; the Star Map; Io's card (3 facts, LAND); Io's own world `sandbox_21`, its terrain, gravity 0.18,
  space's black sky, giant Jupiter, Europa and Ganymede, on the landing pad, peaceful, no animals, MY MAP's pad and three
  sights, the Space Book's LANDED mark, the sights and the volcanoes watched; the portal home by the pad; a slow fall
  (1.30 m/s after 0.32 s); the Volcano Lander is the landmark and is found on its deck, then shown on MY MAP; a volcano's
  cone says its fact; its vent throws the child up (12+ blocks within a second); the lava lake's rim says its fact; the
  moat is hot lava; stepping into it bounces the child up 4+ blocks at once, hearts unchanged (20); the mountain's top
  says its fact (height 89); through the portal home: Green Meadows `sandbox_1`, on the take-off column, home gravity.
- After this work's shared changes: `tools/europa_smoke.gd` **0 fails**; `tools/space_smoke.gd` (the Moon and Planet
  Boing) **0 fails**; `tools/mars_smoke.gd` **29 checks, 0 fails** (a first run while the full suite ran at load 16 failed
  5: the rover's deck not found within 10 s, then the steps after it; a rerun passed every check).

## Pictures (`tools/space_shots.gd -- --universe=21 --sights`, windowed, both styles)

Seen: from over the pad, a black starry sky with huge banded Jupiter (cream zones, brown-orange belts, the red spot)
filling the upper corner; bright yellow plains to the horizon with big orange patches and white frost fields, contour
lines where the ground steps, a small lava lake (a black ring with a glowing edge), the explorers' station (sulphur
bricks), the Volcano Lander's white body near the pad; at sunset the plains turn olive and the frost blue-grey; at night
Jupiter and a tiny Europa among the stars. The lava lake from over its rim: a dark rim wall, a bright orange ring of hot
lava inside it, a crust of black plates with glowing cracks filling the middle. A volcano: a black stepped cone ringed
with a wide red sulphur ring on the yellow plains. The mountain from its steep side: grey-brown rock in layers under a
white frosty top. The first pictures showed a field of pale crystals and black boulders round the pad (thinned: ruling
12); the realistic sulphur was a flat yellow (now it keeps its texture's grain). REALISTIC looks close to BLOCKY at
640 × 360 (the rock and the crust are smoother). A "Theater" building stood near the pad (the places system's, not Io's).

## Full suite

`tests/run_tests.sh` (2026-09-29 ~17:07-17:50, load 5-19, on the final code of commit b5457fa8): **796 scripts, 7317
tests, 7315 passing, 0 failing, 2 risky** (`test_meadows_biome_generator.gd`'s two that never assert, as before this
work), no script errors.

## The lead's checklist (emulator, both styles)

1. Sandbox, Green Meadows: fly up; on the Star Map tap Io: LAND. The loading card shows Io's picture (the Volcano Lander
   on yellow sulphur by a glowing lava pool, giant Jupiter, a far plume) and an Io hint.
2. On Io: the black sky and giant Jupiter (too big?), the yellow plains' brightness (glare on a phone?), the glowing
   crust and hot lava in BLOCKY and REALISTIC.
3. Jump: ~9 blocks, a ~4 s float. Walk over the plains' steps.
4. MAP → Volcano: walk up the cone, see the sulphur puffs, step into the crater: the throw (~30 blocks) and the float.
5. MAP → Lava Lake: the rim, a causeway down onto the crust; step into the moat: the warm bounce (is it clear what
   happened? would a hiss or a short toast help?); walking along the moat, standing still in it.
6. MAP → Tall Mountain: up the gentle side, down the steep one.
7. The Volcano Lander (the steps or a jump to the deck), the station's puzzle, a sulphur geode (dig), the warm room.
8. Survivor: the bag goes to Io and home; Tilly's Io things.
9. Page 21's first frames compile its materials (like any new universe). Performance at the lava lake (≥ 30 FPS, no frame
   over 100 ms): the autopilot with `--universe=21`.
10. The id plan for the next planet (page 29, ids 512+; see Allocations).
