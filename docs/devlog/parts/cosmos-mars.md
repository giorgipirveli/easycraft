# Cosmos: Mars, world 19 (spec §21b.2)

The owner: "add cosmos, stars and planets where is planet is different universe" (#72) and "make the universies closer to
real worlds so player start learning real things" (#74). Brief: `docs/superpowers/plans/2026-09-29-cosmos-mars-brief.md`.
Built by a worker agent in its own worktree (branch `worktree-agent-a284c2971c511759c`, reset to `lead-merge` 2548679
first: it has the Star Map, the Space Book and `SpaceRules.MARS = 19`), without the editor, the emulator or adb.

## Allocations (used; nothing else touched)

| What | Allocated | Used | Free |
|---|---|---|---|
| World number | 19 (`SpaceRules.MARS`) | Mars | |
| Block ids, page 18 (`MarsBlocks`) | 336-351 | 336-349 | 350-351 |
| `BlockIds.COUNT` | 331 → 352 (331-335 stay Rainbow Planet's) | | |
| Atlas page | 18 (`data/blocks/pages/mars*.png`) | rows 0-2 | rows 3-7 |
| Item ids, animals, HUD spots | none | | |

## What a child sees on Mars

1. **Getting there:** fly up above any world; the Star Map opens; Mars's card (its three facts) now says **LAND**.
2. **Landing:** "You landed on Mars! Jump: you are lighter here!" on the landing pad (the Moon's teal pad with the star),
   the golden portal home three steps away. The first landing marks Mars in the Space Book (`WonderData.land_on_world(19)`
   in the sandbox's `_space_landed`, unchanged; the smoke checks it).
3. **Around the pad:** wide plains of rust-red dust with wind ripples, dark basalt boulders, craters with raised rims, dry
   river valleys winding across them with pale beds and glowing gypsum crystals; a butterscotch-pink sky, paler at the
   horizon, a dusty haze; two small lumpy moons, Phobos and the smaller Deimos, day and night (no big round moon at
   night); at sunrise and sunset the horizon glows blue. A soft wind; the calm Goldberg Aria and Air on the G String first.
   No animals ("Mars has no life we know of"); no monsters come by themselves.
4. **Jumping:** gravity 0.38 (real): a jump reaches ~4.4 blocks (1.7 at home), a fall is slow. Every step Mars's terrain
   makes is 4 blocks or less, so a child can climb everything by jumping.
5. **The rover** (~50 blocks from the pad, facing it, tracks behind it in the dust): six wheels, rocker arms, a white
   body, a deck of blue solar panels with a golden chest, a camera mast with two glowing eyes, an antenna. Climb up the
   wheels onto the deck: "You found the Mars Rover! Real Mars rovers roll on six wheels and get their orders from Earth."
6. **MY MAP** shows the landing pad and, from the landing, **Giant Volcano**, **Great Canyon**, **North Ice Cap** and
   **South Ice Cap** (and the rover once found, a river bed where one was found).
7. **The giant volcano** (seed 12345: ~330 blocks north-west): a two-step cliff at its foot (4 + 4), long gentle flanks of
   dusty then bare dark lava rock up ~70 blocks above the plains (the tallest thing anywhere), a caldera 12 deep on top
   with terraced walls. Standing on the summit: "You reached the top of the giant volcano! Mars's Olympus Mons is the
   tallest volcano in the solar system."
8. **The canyon** (~125 blocks south, running east-west for ~2,400 blocks): terraced walls (3-block steps) down ~25
   blocks to a flat dusty floor, pale layers in the walls. On its floor: "You found the great canyon! Mars's Valles
   Marineris is over 4,000 km long and up to 7 km deep."
9. **The ice caps** (~600 north, ~730 south): frost patches on the dust first, then a cap of white water ice rising
   gently (1 block per 3) to a plateau 14 high, dust layers inside, troughs cut by the wind. North: "You found the ice
   cap! Mars's poles hold frozen water and frozen carbon dioxide." South (dry ice on top): "You found the south ice cap!
   It is topped with dry ice: frozen carbon dioxide."
10. **A dry river bed:** "You found a dry river bed! Long ago, water flowed on Mars."
11. **Secrets** (the Secret Book counts them): buried treasure under an X of gypsum crystals, a hidden explorers' room of
    basalt behind a fake basalt door (lit by rover lights, a panel floor), an old lander's puzzle (the puzzle temple in
    gold foil and white panels, star gold on top: friendly and made up), gypsum geodes. Each banner is a find, then a
    fact (below).
12. **Tilly** (Survivor) sells Mars's blocks and the landing pad at home prices, never star gold or the fake basalt.
13. **Home:** walk into the portal or fly up and tap HOME: back on the take-off column.

## How it plugs in (the Moon's pattern)

- **New files:** `world/universes/mars.gd` (the descriptor), `world/universes/mars_blocks.gd` (page 18),
  `world/generators/mars_terrain.gd` (`MarsTerrain`: the regions as pure rules), `world/space_sights.gd`
  (`SpaceSights`: the sights' watcher), `data/blocks/pages/mars{,_albedo,_normal}.png` (+ imports),
  `tools/mars_smoke.gd`, `tools/mars_smoke_steps.gd`, tests (below).
- **Shared, small and additive:** `data/blocks/block_ids.gd` (ids, names, `SPACE_GROUND`, `COUNT` 352),
  `world/block_library.gd` (one register line), `world/generators/space_shape.gd` (planet `MARS`: arms per method, the
  craters take a per-planet cell size, `mars_columns`, `mars_kind`, `sight_at`, `sights`, `_mars_calm`),
  `world/generators/space_generator.gd` (a Mars column writer, the stack's kinds, the shared rock in whole-chunk layer
  fills), `world/generators/space_secret_rules.gd` (Mars's palette, `_mars_rover`), `world/universes/universe_registry.gd`
  (`SPACE[19]`, `lifeless`, `sights`, `animals` empty when lifeless), `core/rules/space_rules.gd` (`WORLDS` has 19),
  `world/sky_cycle.gd` (a palette's `sunset`; `sky_planet`'s `lumpy`, `own_moons`, `moons`; `moons()`),
  `scenes/sandbox.gd` (`_space_sights()` in `_space_local`, a section at the end; the AnimalDirector off when lifeless),
  the natural-block lists (`bot_rules`, `surprise_rules`, `capture_rules`, `gather_rules`, `chat_commands`,
  `secret_rules.is_fake_wall`), `ui/universe/universe_art.gd` (Mars's card: the rover on red dust, its two moons),
  `core/rules/loading_hints.gd` (four Mars hints), `tools/make_space_atlas.gd` (page 18; `-- mars` draws only it),
  `tools/make_space_realistic.py` (`mars`), `tools/bench_generator.gd` (`-- --space moon mars`, the Mars regions bench),
  `assets/CREDITS.md`, `docs/DEVELOPMENT.md`, spec §21b.2 ("As built").
- **Not touched:** the School, `ui/space/*` (the Star Map UI), the other universes' files, `WonderData`, `StarMap`.
- **Shared tests updated for world 19 and COUNT 352:** `test_space_rules` (WORLDS), `test_space_registry` (warm_space,
  space_available with 19 stood in for), `test_planet_universes` (space_available), `test_planet_blocks` (COUNT ≥ 331),
  `test_realistic_pack` (MarsBlocks.FILES). The shared planet tests (`test_space_shape`, `test_space_secrets`,
  `test_space_generator`) now also run for Mars (it is in `SpaceShape.PLANETS`).

## Rulings (decided on the owner's behalf; cost if wrong)

1. **Mars is a planet kind of `SpaceShape`, its regions in `MarsTerrain`** (not a `MarsShape` subclass): the shared
   planet tests (dry land, the pad, the generator equal to its reference, the secrets' kinds, the landmark) cover Mars
   for free, and `SpaceShape.new(seed, MARS)` is Mars. *Cost:* the next planet with rich terrain adds its own helper
   the same way.
2. **Scale, not size:** the volcano rises ~70 blocks over ~160 (a slope of ~0.42; the real Olympus Mons averages ~5°
   over 600 km), the canyon is ~25 deep and ~2,400 long, the caps start ~600 and ~730 blocks from the pad. A child
   reaches each in a minute or two of flying and every step is one Mars jump. *Cost:* constants in `MarsTerrain`.
3. **The canyon runs east-west, the volcano is north-west, the caps north and south** (like the real map: Valles
   Marineris along the equator east of Tharsis, Olympus Mons north-west of it; north is -z as on MY MAP). Positions vary a
   little by seed; the landing pad avoids them all (`_mars_calm`: 250+ blocks from the volcano's middle, 90 from the
   canyon's middle line, no river or crater on it). *Cost:* constants.
4. **No caves, no water;** the rock is basalt with 2 pale layers in every 7 (the canyon's and craters' walls show them);
   ores (coal to diamond) only in the basalt. *Cost:* caves later cost a generator pass (bench it).
5. **The landing pad and star gold are the Moon's** (every space world's pad looks the same: a child knows it). *Cost:*
   a pad of Mars's own is one tile and one block id (350-351 are free).
6. **Sights are a new small system** (`SpaceSights`), not Secret Book kinds: the Secret Book's kinds and counts stay as
   they are; a sight says its fact once per world (kept in the world's secrets as "sight:<id>", never counted: the Secret
   Book counts ids "<kind>_<ax>_<az>_<n>"). The four big sights are on MY MAP from the landing (where Mars's famous
   places are is itself a thing to learn); a river bed only where it was found, and not again after a reload (its fact
   was kept, its spot was not). *Cost:* a sight kind in the Secret Book later is a `SecretRules.is_kind` change.
7. **No animals** (`lifeless`): the AnimalDirector is switched off (`PROCESS_MODE_DISABLED`); `UniverseRegistry.animals`
   is empty only for a lifeless world (a universe that names none still gets Green Meadows'). The Sandbox Totem and
   `/summon` still work, as on every space world. *Cost:* Mars robots or friendly rovers later: a new animal kind.
8. **The sky:** a butterscotch palette by day; the blue sunset is the palette's `sunset` colour taking the horizon (and
   half the fog) as the sun sets and rises: the blocky sky has one horizon colour all round, so the whole horizon glows
   blue, not only round the sun. Phobos is `sky_planet` (lumpy, 22 across), Deimos its `moons` entry (11 across);
   `own_moons` hides home's moon disc at night. The REALISTIC style's photo sky stays the game's one HDRI (as in every
   universe); only its fog and light take Mars's colours. *Cost:* a Mars photo sky is a CC0 HDRI and a per-world
   panorama in `WorldService`.
9. **Music:** no new audio (Holst's "Mars" is not in the game and no recording is added): the Goldberg Aria and Air on
   the G String first; the ambience is the game's wind loop by day and night. *Cost:* a CC0/public-domain recording
   later is a `MusicPieces` entry.
10. **The rover's words say "the Mars Rover"** (a generic name, never a mission's); the lander is "the old lander". The
    facts say what real rovers found in general words (spec §21b.2: no real brands or mission names).
11. **Dust devils and dust storms are next**, not now: a storm needs a third style in `SandstormRules` (its words mention
    monsters and sand) and dust devils a small effect near the player. *Cost:* none yet.

## The facts (every Mars fact in the game, and its check)

| Where | Words | Check |
|---|---|---|
| gravity | 0.38 | 3.71 m/s² ÷ 9.81 = 0.378 (NASA Mars fact sheet) |
| landing | "You landed on Mars! Jump: you are lighter here!" | the brief's words |
| treasure | "Mars is red because its dust has rust in it." | iron oxide in the dust (NASA) |
| hidden room | "Mars's dark rock is basalt, made by old lava." | Mars's crust is mostly basalt (volcanic rock) |
| old lander | "Landers from Earth have visited Mars since the 1970s." | Mars 3 (1971), Viking 1 and 2 (1976) |
| rover | "Real Mars rovers roll on six wheels and get their orders from Earth." | Sojourner, Spirit, Opportunity, Curiosity, Perseverance and Zhurong all have six wheels (rocker-bogie); they are commanded from Earth ([Wikipedia: Mars rover](https://en.wikipedia.org/wiki/Mars_rover), [Science News](https://www.sciencenews.org/article/mars-rover-robot-red-planet-history-nasa-china)) |
| geode | "Rovers found gypsum on Mars: it forms in water." | Opportunity's "Homestake" vein, 2011: gypsum deposited by water ([NASA JPL](https://www.jpl.nasa.gov/news/nasa-mars-rover-finds-mineral-vein-deposited-by-water/)) |
| volcano | "Mars's Olympus Mons is the tallest volcano in the solar system." | [NASA APOD 2023-04-04](https://apod.nasa.gov/apod/ap230404.html), [Space.com](https://www.space.com/20133-olympus-mons-giant-mountain-of-mars.html) |
| canyon | "Mars's Valles Marineris is over 4,000 km long and up to 7 km deep." | [NASA Science](https://science.nasa.gov/resource/valles-marineris-the-grand-canyon-of-mars/), [USGS](https://www.usgs.gov/centers/astrogeology-science-center/science/valles-marineris-grand-canyon-mars) |
| north cap | "Mars's poles hold frozen water and frozen carbon dioxide." | the brief's words; water-ice caps with seasonal and residual CO2 ice |
| south cap | "It is topped with dry ice: frozen carbon dioxide." | the south residual cap's surface is mostly CO2 ice over water ice ([NASA JPL PIA00301](https://www.jpl.nasa.gov/images/pia00301-south-polar-residual-ice-cap/), [JPL PIA22870](https://www.jpl.nasa.gov/images/pia22870-the-changing-ice-cap-of-mars/)) |
| river bed | "Long ago, water flowed on Mars." | valley networks and deltas (e.g. Jezero crater's) |
| hint | "On Mars you jump more than twice as high!" | 1 ÷ 0.38 = 2.6 |
| sky | blue sunsets | fine dust lets blue light through and keeps it near the sun ([NASA Science](https://science.nasa.gov/solar-system/planets/mars/what-does-a-sunrise-sunset-look-like-on-mars/)) |
| sky | Phobos bigger than Deimos, both dark and lumpy | ~22 km and ~12 km across, irregular |

(The Star Map's own three Mars facts are the lead's, in `core/rules/star_map.gd`; unchanged.)

## Tests (RED → GREEN)

| Test file | Tests | RED (why it failed first) |
|---|---|---|
| `tests/unit/test_mars_blocks.gd` | 7 | ids not declared (`BlockIds.GYPSUM`, `MarsBlocks`) — run and seen |
| `tests/unit/test_mars_universe.gd` | 10 | `MarsBlocks`/ids not declared — run and seen; `test_space_rules` failed on WORLDS [16, 17, 18] — run and seen |
| `tests/unit/test_mars_shape.gd` | 19 | written before `MarsTerrain` / `SpaceShape.MARS` existed (not declared) |
| `tests/unit/test_mars_generator.gd` | 6 | written before the Mars generator path |
| `tests/unit/test_mars_secrets.gd` | 7 | written before Mars's palette and the rover |
| `tests/integration/test_mars_world.gd` | 3 | written before `mars.gd` |
| `tests/integration/test_mars_sky.gd` | 3 | written before `SkyCycle.moons()`, `sunset`, `lumpy` |
| `tests/integration/test_mars_sights.gd` | 5 | written before `SpaceSights` |
| shared (see above) | | WORLDS, warm_space and space_available lists, COUNT, the realistic pack's pages |

On the way: a loading hint was 11 words (the house limit is 10: shortened); `test_space_registry` needed Mars stood in
for as missing; one untyped loop variable in a test.

## Measurements

Generator bench (`bench_generator.gd -- --space moon mars`, 640 chunks per planet alternating with Green Meadows, the
PC's load ~3-8 on 24 cores). Before the whole-chunk layer fills Mars's surface chunks were the slowest (1.62 ms warm,
1.91 cold: ~5 layer fills per column); after:

| chunks | Meadows avg ms | Moon | Mars |
|---|---|---|---|
| surface, warm (stacks cached) | 1.48-1.54 | 1.16 | **1.04-1.11** |
| surface, cold (fresh generators, a stack's chunks in a row) | 1.61-1.64 | 1.64-1.67 | **1.39-1.42** |
| underground | 1.08-1.13 | 0.24-0.26 | 0.24-0.26 |
| sky (y 80+) | 0.75-0.77 | 0.01 | 0.01 |
| all, cold | 1.33-1.36 | 0.92-0.94 | **0.79-0.81** |
| a new area's secrets (once, then cached) | — | 0.57-0.64 (worst 1.9) | 0.53 (worst 1.1) |

Mars's regions (`BENCH_MARS_<REGION>`, fresh generators over 4 × 4 whole chunk stacks, y -64..159, against the meadows
on the same chunks): volcano flank 0.95 ms vs 1.04, volcano top 1.04 vs 1.16, canyon 0.92 vs 1.18, north cap 0.78 vs
0.84 (0.93 before the cap's ice was filled in runs); underground 0.25-0.29 vs 1.09-1.28. Worst single chunks: Mars
5-7 ms, the Moon 14-17 ms, the meadows 3-8 ms. Every `--script` bench run prints the same 33 autoload compile errors as
before this work (scripts that use autoloads, loaded without them); the numbers are unaffected.

Geography for three seeds (`SpaceShape`/`MarsTerrain`, printed by a scratch script):

| seed | pad (ground) | volcano middle (from the pad) | rim / caldera floor | canyon line at the pad's x | caps' edges (z) | rover |
|---|---|---|---|---|---|---|
| 12345 | (0, 32) at 55 | (-206, -229), 333 | 126 / 113 | z 158 (floor 30) | -562 / 762 | (-33, 55, 69) |
| 77 | (32, 0) at 57 | (-188, -240), 326 | 126 / 116 | z 208 | -577 / 786 | (25, 56, -47) |
| 777 | (32, 0) at 55 | (-234, -183), 323 | 128 / 113 | z 137 | -579 / 764 | (-16, 56, -27) |

## Smoke runs

- `tools/mars_smoke.gd` (seed 12345, a private `XDG_DATA_HOME` with "smoke" in its path and a copy of `profile.json`):
  **29 checks, 0 fails** (exit 0): a new Green Meadows Sandbox world; the Star Map; Mars's card (3 facts, LAND); Mars's
  own world `sandbox_19`, its terrain, gravity 0.38, the butterscotch sky with a sunset colour, Phobos and Deimos
  showing, on the landing pad, peaceful, no animals, MY MAP's pad and four sights, the Space Book's LANDED mark, the
  sights watched; the portal home by the pad; a slow fall (2.58 m/s after 0.31 s); the rover is the landmark and is
  found by climbing onto its deck, then shown on MY MAP; the volcano's summit says its fact (height 113); through the
  portal home: Green Meadows `sandbox_1`, on the take-off column, home gravity.
- `tools/space_smoke.gd` (the Moon and Planet Boing, unchanged): **36 checks, 0 fails**.

## Full suite

`tests/run_tests.sh` (2026-09-29 ~12:40-13:10, load 3-14): **750 scripts, 6891 passing, 1 failing, 2 risky**, no script
errors. The failure was this work's own test: `test_mars_world` read a block 9 under the landing pad before the chunk
under the pad's had streamed in (it passed alone; the busy suite streamed that chunk later). The test now waits for
that cell too; it passed 3 runs in a row afterwards (with `test_moon_world`). The 2 risky tests are
`test_meadows_biome_generator.gd`'s two that never assert (as before this work).

## The lead's checklist (emulator, both styles)

1. Sandbox, Green Meadows: fly up; on the Star Map tap Mars: LAND. The loading card shows Mars's picture (the rover on
   red dust, two small moons) and a Mars hint.
2. On Mars: the butterscotch sky in BLOCKY (pleasant? too orange?); the REALISTIC photo sky is the game's one HDRI with
   Mars's haze (acceptable, or does Mars need its own photo sky?). Phobos and Deimos visible and small; at night no big
   moon. Wait for sunset (or `/time`): the horizon should glow blue.
3. Jump: ~4.4 blocks, slow fall. Walk to the rover (MY MAP), climb its wheels onto the deck: the chest and the banner.
4. MAP → Giant Volcano: fly there, walk up (the cliff's two 4-steps at its foot, then the gentle climb), stand in the
   caldera: the banner. Performance while flying over the volcano and the canyon (≥ 30 FPS, no frame over 100 ms): the
   autopilot with `--universe=19`.
5. The canyon's terraces (3-block steps) down and up; the ice caps (frost, the ice rising, dust layers where dug).
6. Survivor: the bag goes to Mars and home; Tilly's Mars things.
7. Page 18's first frames compile its materials (like any new universe).

## Next (the game never ends)

Dust devils (small spinning dust columns near the child) and dust storms (a Mars style for the sandstorm code, its own
words), the three Tharsis volcanoes in a row, a Planet Book page for Mars's facts (the Space Book collects landings
today), Mars's own music, a Mars photo sky for REALISTIC; then Europa (world 20).
