# Cosmos: Mercury, world 23 (spec §21b.2)

The owner: "add cosmos, stars and planets where is planet is different universe" (#72) and "make the universies closer to
real worlds so player start learning real things" (#74). Brief: `docs/superpowers/plans/2026-09-29-cosmos-planet-brief.md`
with BODY = Mercury, WORLD = 23, PAGE = 30, IDS = 528-543. The lead's ideas: the Sun huge and white in a black sky (almost
no air), long cliffs that formed as the planet cooled and shrank, a thermometer (about 430 °C by day, about −180 °C at
night), ice in the shadowed craters near a pole, a landmark in the Mars and Titan pattern (a sunshade lander), everything
friendly and the heat a fact, never a danger. Built by a worker agent in its own worktree (branch
`worktree-agent-abaa4ef6186c50bef`, reset to `lead-merge` 9aea936b first: the merge of Titan), without the editor, the
emulator or adb (two windowed runs of `tools/space_shots.gd` for pictures).

## Allocations (used; nothing else touched)

| What | Allocated | Used | Free |
|---|---|---|---|
| World number | 23 (`SpaceRules.MERCURY`, already in `SpaceRules` and the Star Map) | Mercury | |
| Block ids, page 30 (`MercuryBlocks`) | 528-543 | 528-541 | 542-543 |
| `BlockIds.COUNT` | 528 → 544 | | |
| `BlockIds.NEXT_PAGE_FIRST_ID` | 528 → 544 (page 31 is the next) | | |
| Atlas page | 30 (`data/blocks/pages/mercury*.png`) | rows 0-2 | rows 3-7 |
| Item ids, animals, HUD spots | none | | |
| Server module | unchanged (0.2.15 already lets blocks up to 1023 travel in gifts) | | |

## What a child sees on Mercury

1. **Getting there:** fly up above any world; the Star Map opens; Mercury's card (the lead's three facts: the smallest
   planet and the closest to the Sun, 176 Earth days from sunrise to sunrise, 430 °C days and −180 °C nights) now says
   **LAND**.
2. **Landing:** "You landed on Mercury! The Sun looks three times as big here!" on the landing pad, the golden portal home
   three steps away; the Space Book marks Mercury landed on.
3. **The sky:** space's black with stars even at noon (almost no air), and **the Sun three times as big as at home**: a big
   white disc with a soft glow round it (the painted sky's own sun, `sun_size` 3), in both styles. Venus is a tiny bright
   point, Earth and our Moon two tiny points close together elsewhere in the sky; no moon of Mercury's own (it has none). At
   night the usual moonlit night (never pitch black). Soft chimes (no air: no wind); Ode to Joy by day, Gymnopédie at night.
   No animals, no monsters.
4. **Around the pad:** grey dust plains (a darker, warmer grey than the Moon's silver) with patches of darker blue-grey
   dust, small craters everywhere with raised rims, and young ones that are bright white with long bright rays streaking out
   round them. Rock boulders here and there.
5. **Jumping:** gravity 0.38 (real: 3.70 m/s²): a jump reaches ~4.4 blocks (1.7 at home), a fall is slow. Every step
   Mercury's terrain makes is 4 or less; the cliffs and crater walls are terraces 3 high.
6. **The thermometer** (11 blocks from the pad's middle, seen from the pad): a white board with a glass tube and its red
   line and marks on a little plinth, a glowing red bulb at its foot. Standing by it: "You found the thermometer! Mercury's
   days reach about 430 °C and its nights about −180 °C." (MY MAP "Thermometer".)
7. **The Sunshade Lander** (~45-55 blocks from the pad, facing it): four legs, a body in a silvery heat blanket, mirror
   panels out to both sides, a lamp on each corner of its deck and one on a little mast, a golden chest on its deck (two
   steps up its front), and its big white sunshade (11 wide, 9 tall, a little curved) held on two struts on its sunny side,
   the south, where the Sun is at noon. On its deck: "You found the Sunshade Lander! Spacecraft visiting Mercury hide behind
   big sunshades to keep cool."
8. **The long cliff** (MY MAP "Long Cliff", its face ~145-185 blocks from the pad): a curved wall of rock terraces 18 high
   running on for ~300 blocks, a gentle slope down its back, its ends fading into the plains; more long cliffs all over
   Mercury (12-18 high). On its face or its crest: "You found a long cliff! Mercury shrank as it cooled, and its crust pushed
   up cliffs like this."
9. **Big craters** (MY MAP "Big Crater": the nearest one, ~115-150 blocks from the pad; about one per 220 × 220 blocks):
   radius 20-28, terraced rock walls down to a flat floor 9 under the plains, a central peak, a raised rim. On its floor or
   peak: "You found a big crater! Mercury's craters are named after famous artists, writers and musicians."
10. **The ice crater** (MY MAP "Ice Crater", ~370-550 blocks north of the pad): a big crater whose floor is pale shadow ice
    with glowing ice crystals on it. On its ice: "You found ice! Sunlight never reaches the floors of some craters near
    Mercury's poles." Every big crater more than 360 blocks north or south holds ice too.
11. **Secrets** (the Secret Book counts them): buried treasure under an X of ice crystals, a hidden rock room behind a fake
    rock door, the explorers' station (the puzzle temple in explorer bricks with explorer lamps, star gold on top: friendly
    and made up), ice crystal geodes in the rock. None is built on a cliff's face or into a big crater. Each banner: a find,
    then a fact (below).
12. **Tilly** (Survivor) sells Mercury's dusts, rock, shadow ice, ice crystals, the sunshade, heat blanket, mirror panels,
    lamps, the thermometer's tube and bulb, explorer bricks and the landing pad at home prices; never star gold or the fake
    door.
13. **Nothing hurts:** the heat and the cold are facts to learn; no block, sight or word hurts or scares (a test reads every
    word the world says for "hurt", "burn", "danger", "scary", "careful", "too hot", "die").
14. **Home:** walk into the portal or fly up and tap HOME: back on the take-off column, home's Sun again.

## How it plugs in (the Moon's, Mars's, Europa's, Io's and Titan's pattern)

- **New files:** `world/universes/mercury.gd` (the descriptor), `world/universes/mercury_blocks.gd` (page 30),
  `world/generators/mercury_terrain.gd` (`MercuryTerrain`: the regions as pure rules), `data/blocks/pages/mercury{,_albedo,
  _normal}.png` (+ imports, the pages' import settings), `tools/mercury_smoke.gd`, `tools/mercury_smoke_steps.gd`, tests
  (below).
- **Shared, small and additive:** `data/blocks/block_ids.gd` (ids, names, `SPACE_GROUND`, `COUNT` 544,
  `NEXT_PAGE_FIRST_ID` 544), `world/block_library.gd` (one register line), `world/generators/space_shape.gd` (planet
  `MERCURY`: a branch per method, `mercury_columns`, `mercury_kind`, `thermometer_column`, `_mercury_block_at`,
  `_mercury_calm`, `sight_at` / `sights`, the thermometer, boulders and ice crystals as features),
  `world/generators/space_generator.gd` (Mercury's stack, `_write_mercury_column`), `world/generators/space_secret_rules.gd`
  (Mercury's palette, `_sunshade_lander`, `SUNNY`, `_fits` off the steep ground), `world/universes/universe_registry.gd`
  (`SPACE[23]`, `sun_size`, `MIN_SUN`/`MAX_SUN`), `world/sky_cycle.gd` (`sun_size`: two lines in `refresh`),
  `scenes/sandbox.gd` (one line in `_space_local`), `core/rules/space_rules.gd` (`WORLDS` has 23), the natural-block lists
  (`bot_rules`, `surprise_rules`, `capture_rules`, `gather_rules`, `chat_commands`, `secret_rules.is_fake_wall`),
  `ui/universe/universe_art.gd` (Mercury's card: the Sunshade Lander and the thermometer on grey dust by a bright young
  crater, the huge white Sun in a black sky), `core/rules/loading_hints.gd` (seven Mercury hints), `tools/make_space_atlas.gd`
  (page 30; `-- mercury`), `tools/make_space_realistic.py` (`mercury`), `tools/bench_generator.gd`
  (`BENCH_MERCURY_<CLIFF|CRATER|ICE>`), `assets/CREDITS.md`, `docs/DEVELOPMENT.md`, spec §21b.2 ("As built").
- **Not touched:** the School, the Science Lab, `ui/space/*` (the Star Map UI), `StarMap`, `WonderData`, the server, the
  other worlds' files.
- **Shared tests updated:** `test_space_rules` (WORLDS), `test_space_registry` (warm_space, space_available),
  `test_planet_universes` (space_available), `test_realistic_pack` (MercuryBlocks.FILES), `test_titan_blocks` (COUNT and
  the next page are past Titan's now; Mercury's page is its neighbour), `test_block_id_space` (NEXT_PAGE_FIRST_ID 544),
  `test_block_pages` (page 30 is 528), `test_page_sizes` (the budget, ruling 13). The shared planet tests
  (`test_space_shape`, `test_space_secrets`, `test_space_generator`) now also run for Mercury (it is in
  `SpaceShape.PLANETS`).

## Rulings (decided on the owner's behalf; cost if wrong)

1. **Mercury is a planet kind of `SpaceShape`, its regions in `MercuryTerrain`** (Mars's, Europa's, Io's and Titan's ruling
   1). Unlike theirs, its features (arcs, big and small craters) are drawn cell by cell into caches behind a mutex (the
   generator's threads share the shape), so the filters between them cost once per cell. *Cost:* none new.
2. **The Sun three times as big is the sky's own sun, scaled:** a descriptor's `sun_size` (`UniverseRegistry.sun_size`,
   0.25-4, 1 without one) multiplies the painted sky's sun glow (`ProceduralSkyMaterial.sun_angle_max`, whose bright core
   is the sun's disc) by day; never the night's light. Not the light's angular size (`light_angular_distance` turns on
   soft shadows, a real cost on phones) and not its energy (the real sunlight is up to seven times as bright: it would wash
   out a child's screen). "Three times": NASA says "more than three times as large" (2.6 × on average, 3.2 × when closest).
   *Cost:* one number; a crisper disc later is a sun billboard in `SkyCycle`.
3. **The sky:** space's black by day (`space_sky` 1: almost no air), stars at noon, `photo_sky` false (so the big Sun
   shows in the realistic style too). Venus as the sky's planet (6 across at 230 m: a tiny bright point) and Earth (5) with
   our Moon (2.5) close together elsewhere: the real ones are points of light, far smaller than even this; the game names
   only Earth and our Moon (a hint) and never Venus. `own_moons`: no moon disc (Mercury has no moon). *Cost:* numbers in
   the descriptor.
4. **The thermometer is a terrain feature by the pad, not a secret:** `SpaceShape.THERMOMETER_DISTANCE` 11 from the pad's
   middle in a direction drawn from the seed (outside the flat pad, 8; inside the blend, 16, where nothing else grows;
   Tilly's stall and the Theater keep off features; the portal home is built 3 from the child's feet at the pad's middle),
   7 tall (a plinth of explorer brick, the glowing red bulb, 5 blocks of tube). Standing within 2 of it is its sight. It
   says both numbers at once (a child finds it once; the Star Map card says them too). *Cost:* a reading that changes with
   the game's day (430 °C by day, −180 °C at night) is a sight that speaks by `DayCycle.is_night` (next).
5. **The heat is a fact, never a danger:** no damage anywhere on Mercury, and no word says anything hurts, burns, is
   dangerous or too hot (`test_the_heat_is_a_fact_never_a_danger`); the smoke checks the hearts after the whole visit. No
   hint says "it can't hurt you" either (that would put the idea there). *Cost:* none.
6. **Long cliffs are arcs** (lobate: their face bulges a little, `LOBE`), the inside a raised slab (`SCARP_H` 12-18,
   the great one 18) whose back slopes down over `BACK` 48 and whose face is terraces `STEP` 3 high and `LEDGE` 2 deep (a
   slope of 1.5: a cliff to look at, one jump a step), the ends fading over `TAPER` 60 (so no step grows past 4);
   overlapping cliffs keep the higher. The great cliff's face lies 110-150 blocks from the world's middle and faces it
   (the pad is always nearer its face than its back). Scale: the real ones are up to ~1.5-3 km high (NASA: "up to a mile
   high") and hundreds of km long. *Cost:* constants in `MercuryTerrain`.
7. **One owner per column:** a small crater touching a big crater or a cliff is dropped, a big crater touching a cliff or
   the ice crater is dropped, a cliff crossing the ice crater is dropped. So every column is a big crater's, a cliff's or
   the plains' (with small craters), and every step between two columns is at most 4 (tested over 120 × 120 blocks round
   the cliffs, the craters and the pad for 4 seeds). The real Mercury has cliffs cutting through craters (a famous sight):
   *cost:* that needs a combined profile and the step tests again.
8. **Polar ice:** the ice crater (no central peak; radius 26) 400-460 blocks north of the world's middle (±80 east-west)
   and every big crater beyond 360 north or south have floors of shadow ice (2 deep) with glowing ice crystals; their peaks
   stay rock (they stick up into the sunlight). The game's sun still lights the floor (no permanent shadow in a game whose
   sun goes round, and never dark, spec §3c); the words say sunlight never reaches the *real* floors. *Cost:* a shade
   effect over the ice later.
9. **The pad:** at least 90 blocks from any cliff's slab or face, 70 from any big crater's rim, no small crater on it or
   round it (`_mercury_calm`), rings outward from the world's middle. *Cost:* constants.
10. **Rock:** grey rock all the way down (ores in it), 2 of dust under a dust top, bare rock on walls, faces and peaks; no
    layers, no caves (§21.4). *Cost:* none.
11. **Sounds:** no new audio. Chimes by day and night (no air: no wind, the Moon's and Io's choice), Ode to Joy by day (the
    big Sun), Gymnopédie at night. *Cost:* a `MusicPieces` entry for a CC0 recording later.
12. **No mission names** (spec §21b.2): "spacecraft", "scientists"; "the Sunshade Lander" is made up (no spacecraft has
    landed on Mercury; one circled it from 2011 to 2015 and mapped all of it, another is on its way). A test checks the
    words for MESSENGER, Mariner, BepiColombo, NASA, ESA, JAXA, JPL and Hubble.
13. **The realistic pages' budget rose from 40 to 48 MB** (`test_page_sizes.gd`): the pages reached 39.3 MB with Titan's,
    and a page of three rows without alpha adds 1.6 MB (Mercury's albedo 1.0 MB, its half-size normal map 0.5 MB): 40.9 MB
    now, room for about five more planets. *Cost:* the APK grows ~1.6 MB a planet; the lead may prefer a smaller realistic
    page (two rows, or a half-size albedo) for the later planets.
14. **A clearly grey Mercury:** the first pictures showed the plains near-white under the Sun, too like the Moon's silver;
    the dust went from `a7a39d` to `8e8a85`, the rock and the darker dust down with it (the rays stay bright, so they stand
    out more). *Cost:* colours.
15. **The sunshade faces the noon Sun** (`SpaceSecretRules.SUNNY`, the +z side: `DayCycle` leans the Sun's path 30° toward
    +z), held on struts 9 out past the mirror panels (which point along the lander's sides), whichever way the lander faces
    the pad; from a pad to the south a child meets the shade's white face first and walks round it. *Cost:* a constant.
16. **Small words:** "about 430 °C" and "about −180 °C" (NASA's numbers, rounded by NASA), "85 %" (NASA: "about 85% of the
    planet's radius": a core that wide is 85 % as wide as the planet), "probably" for the comets (JPL: "likely").

## The facts (every Mercury fact in the game, and its check)

| Where | Words | Check |
|---|---|---|
| gravity | 0.38 | 3.70 m/s² ÷ 9.81 = 0.377 ([NASA NSSDC: Mercury fact sheet](https://nssdc.gsfc.nasa.gov/planetary/factsheet/mercuryfact.html)) |
| landing, hint | "The Sun looks three times as big here!", "From Mercury the Sun looks three times as big!" | "the Sun would appear more than three times as large as it does when viewed from Earth" ([NASA: Mercury facts](https://science.nasa.gov/mercury/facts/)) |
| treasure | "A year on Mercury lasts only 88 Earth days." | "It speeds around the Sun every 88 days" (NASA Mercury facts) |
| hidden room | "Mercury's metal core is 85 % as wide as the whole planet." | "a large metallic core with a radius of about 2,074 km, about 85% of the planet's radius" (NASA Mercury facts) |
| station | "Mercury has almost no air, so its sky is black by day." | "Instead of an atmosphere, Mercury possesses a thin exosphere" (NASA Mercury facts); no air to scatter sunlight, as on the Moon |
| Sunshade Lander | "Spacecraft visiting Mercury hide behind big sunshades to keep cool." | "A ceramic-fabric sunshade, heat radiators, and a mission design … protected MESSENGER"; "the roughly 8-foot by 6-foot sunshade" ([JHU APL: MESSENGER](https://www.jhuapl.edu/destinations/missions/messenger)) |
| geode | "Comets and asteroids probably brought Mercury its water." | "the impacts of comets and volatile-rich asteroids, the same objects that likely delivered water to the innermost planet" ([NASA JPL, 2012](https://www.jpl.nasa.gov/news/nasa-spacecraft-finds-new-mercury-water-ice-evidence/)) |
| thermometer | "Mercury's days reach about 430 °C and its nights about −180 °C." | "day temperatures can reach highs of 800°F (430°C)", "temperatures can dip as low as -290°F (-180°C)" (NASA Mercury facts) |
| long cliff | "Mercury shrank as it cooled, and its crust pushed up cliffs like this." | "cliffs, some hundreds of miles long and soaring up to a mile high. They rose as the planet's interior cooled and contracted" (NASA Mercury facts) |
| big crater | "Mercury's craters are named after famous artists, writers and musicians." | "Craters and features on Mercury are named after famous deceased artists, musicians, or authors" (NASA Mercury facts) |
| ice crater | "Sunlight never reaches the floors of some craters near Mercury's poles." | "water ice at its north and south poles inside deep craters, but only in regions in permanent shadows" (NASA Mercury facts); "craters near the poles can remain in year-round shadow" (JPL, 2012) |
| hint | "On Mercury you jump more than twice as high!" | 1 ÷ 0.38 = 2.6 |
| hint | "Mercury has no moons at all." | "Mercury doesn't have moons" (NASA Mercury facts) |
| hint | "Earth and our Moon look like two tiny stars here." | a spacecraft's photo from Mercury's orbit, 2013: "The pair of bright star-like features … are not stars at all, but the Earth and Moon" ([NASA Photojournal: Looking back at us](https://science.nasa.gov/photojournal/looking-back-at-us)) |
| hint | "Look for ice in the craters far to the north!" | the game's map (ruling 8) |
| sky | Venus the brightest point | from Mercury, Venus is brighter than from Earth, the brightest body after the Sun ([Wikipedia: Astronomy on Mercury](https://en.wikipedia.org/wiki/Astronomy_on_Mercury)); never said in the game |
| terrain | young craters' bright rays, big craters' central peaks and terraced walls, darker patches | what the spacecraft's pictures show (rayed craters, complex craters, low-reflectance material); no words |

(The Star Map's own three Mercury facts are the lead's, in `core/rules/star_map.gd`; unchanged. A 2023 study questions how
much graphite colours Mercury's dark rock, so no word says so.)

## Tests (RED → GREEN)

| Test file | Tests | RED (why it failed first) |
|---|---|---|
| `tests/unit/test_mercury_blocks.gd` | 9 | `BlockIds.ICE_CRYSTAL` …, `MercuryBlocks` not declared — run and seen; then the page budget (40.9 MB over 40: ruling 13) |
| `tests/unit/test_mercury_shape.gd` | 14 | written before `MercuryTerrain` (not declared); first run after the terrain was written (a typing fix in the test, then all green) |
| `tests/unit/test_mercury_generator.gd` | 6 | the generic column writer: dust everywhere instead of the rays, the rocky faces and walls, the ice — run and seen |
| `tests/unit/test_mercury_secrets.gd` | 7 | the Moon's palette and the Moon Base on Mercury — run and seen |
| `tests/unit/test_mercury_universe.gd` | 12 | `UniverseRegistry.sun_size` not found — run and seen; then its own word test's capital "Comets" |
| `tests/integration/test_mercury_sky.gd` | 5 | `SkyCycle.sun_size`, `UniverseRegistry.sun_size` not found — run and seen |
| `tests/integration/test_mercury_sights.gd` | 4 | written with the descriptor |
| `tests/integration/test_mercury_world.gd` | 5 | written with the descriptor (the pad, the dust, the thermometer's bulb in the real terrain; save, load, mesh) |
| shared (see above) | | WORLDS, warm_space and space_available lists, COUNT and the next page, the realistic pack's pages, the budget |

## Measurements

Generator bench (`bench_generator.gd -- --space moon mercury`, 640 chunks per planet alternating with Green Meadows; the
PC's load 11-12 on 24 cores):

| chunks | Meadows avg ms | Moon | Mercury |
|---|---|---|---|
| surface, warm (stacks cached) | 1.51-1.72 | 1.74 | **0.64** (worst 1.54) |
| surface, cold (fresh generators, a stack's chunks in a row) | 1.63-2.34 | 2.98 | **0.95** (worst 2.76) |
| underground | 1.10-1.27 | 0.33 | **0.29** |
| sky (y 80+) | 0.76-0.86 | 0.01 | **0.01** |
| all, cold | 1.34-1.97 | 1.67 | **0.60** |
| a new area's secrets (once, then cached) | — | 0.60 (worst 1.38) | 0.96 (worst 1.88) |

Mercury's regions (`BENCH_MERCURY_<REGION>`, fresh generators over 4 × 4 whole chunk stacks, y -64..159, against the
meadows on the same chunks): across the great cliff's face 0.54 ms vs 0.82 (worst 2.87), over a big crater 0.45 vs 1.02
(worst 2.51), over the ice crater 0.46 vs 0.97 (worst 2.67); underground 0.29-0.35 vs 1.07-1.14. A new area's secrets
cost more than the Moon's (0.96 ms against 0.60, once per 128 × 128 area): the steep-ground check of each secret's box.
`MercuryTerrain.column` (the reference, one column: its features gathered each time) costs ~32 µs; `columns` for a chunk
stack's 16 × 16 ~0.53 ms.

Geography (`SpaceShape`/`MercuryTerrain`, printed by a scratch script; kinds over 20,000 columns in ±1000):

| seed | pad (ground) | thermometer | great cliff's face (from the pad) | nearest big crater | ice crater | Sunshade Lander | plains / dark / rays / walls / floors / peaks / ice / cliff faces |
|---|---|---|---|---|---|---|---|
| 12345 | (0, -32) at 52 | (-11, -32), 11 | (-74, 104), 155 | (58, 66), 114 | (-51, -402), 373 | (-45, -20), 47 | 75.5 / 16.7 / 6.0 / 0.8 / 0.1 / 0.2 / 0.2 / 0.5 % |
| 77 | (16, 0) at 52 | (22, 9), 11 | (134, -85), 145 | (114, 80), 127 | (16, -436), 436 | (-37, -16), 55 | 75.8 / 17.1 / 5.2 / 1.1 / 0.1 / 0.1 / 0.1 / 0.4 % |
| 777 | (-17, 95) at 52 | (-18, 106), 11 | (-151, 12), 158 | (133, 119), 152 | (80, -418), 522 | (-59, 110), 45 | 73.8 / 16.6 / 7.3 / 1.2 / 0.1 / 0.1 / 0.1 / 0.8 % |
| 42 | (33, 124) at 51 | (35, 135), 11 | (137, -26), 183 | (-111, 148), 146 | (-1, -421), 546 | (17, 81), 46 | 76.2 / 16.5 / 6.0 / 1.1 / 0.1 / 0.0 / 0.0 / 0.2 % |

Per seed: about 20 long cliffs in 2400 × 2400 blocks, 34-41 big craters in 2200 × 2200, ~1,700 small craters in 2016 ×
2016 (~400 of them young, with rays).

## Smoke runs

- `tools/mercury_smoke.gd` (seed 12345, a private `XDG_DATA_HOME` with "smoke" in its path and a copy of `profile.json`):
  **43 checks, 0 fails** (exit 0; twice): a new Green Meadows Sandbox world with home's Sun; the Star Map; Mercury's card
  (3 facts, LAND); Mercury's own world `sandbox_23`, its terrain, gravity 0.38, space's black sky, the Sun three times as
  big (`sun_size` 3, the sky's sun 60° of glow at noon), never the photo sky, Venus a tiny point, Earth and our Moon two
  tiny points, on the landing pad, peaceful, no animals, MY MAP's pad and four sights, the Space Book's LANDED mark, the
  sights watched, no geysers; the portal home by the pad; the thermometer's bulb by the pad; a slow fall (2.58 m/s after
  0.31 s); the Sunshade Lander is the landmark and is found on its deck, then shown on MY MAP; the thermometer, the long
  cliff's face (standing on Mercury rock), a big crater's peak and the ice crater (standing on shadow ice) say their facts;
  nothing hurt the child (health 20 all along); through the portal home: Green Meadows `sandbox_1`, on the take-off column,
  home gravity, home's Sun again.
- After this work's shared changes (`tools/smoke_all.sh mercury space mars europa io titan`): **6 passed, 0 failed**
  (`space` 36 checks, `mars` 29, `europa` 34, `io` 36, `titan` 43, all 0 fails).

## Pictures (`tools/space_shots.gd -- --universe=23 --sights`, windowed, both styles)

Seen: from over the pad, a black sky full of stars over grey plains to the horizon, small craters with terraced rings,
young craters bright white with long white rays streaking out, blue-grey patches of darker dust, the dark curved lines of
the long cliffs' faces far away, a few boulders; looking south at noon the Sun is a big white disc in a soft glow, far
bigger than at home. The thermometer: a white tube with its red bulb beside the teal landing pad, the Sunshade Lander's
white shade and body behind it. The long cliff: a wall of rock terraces curving away across the view. A big crater: rings
of terraces down to a floor with a stepped central peak. The ice crater: terraced walls down to a pale blue-white floor
of ice with glowing crystals. Sunset dims the plains; night is the usual blue moonlit night. REALISTIC looks close to
BLOCKY at 640 × 360. The first pictures showed near-white plains (ruling 14). A "Theater" stands near the pad (the
places system's, not Mercury's).

## Full suite

`tests/run_tests.sh` (2026-09-29 ~20:54-21:30, load 4-12, on the code of commit 33596c54): **830 scripts, 7632 tests, 7630
passing, 0 failing, 2 risky** (`test_meadows_biome_generator.gd`'s two that never assert, as before this work), no script
errors, exit 0 (2113 s). After it only these notes changed.

The branch is based on `lead-merge` 9aea936b (Titan's merge); `lead-merge` has moved on since (the School's "label the
diagram", grade 5 docs, a deploy note). Those touch `docs/DEVELOPMENT.md` and the spec in other sections than this work's.

## The lead's checklist (emulator, both styles)

1. Sandbox, Green Meadows: fly up; on the Star Map tap Mercury: LAND. The loading card shows Mercury's picture (the
   Sunshade Lander and the thermometer on grey dust, the huge white Sun in a black sky) and a Mercury hint.
2. On Mercury: the Sun at noon (look south): big enough, too big, too washed out on a phone? It is the sky's own sun glow ×
   3 (`sun_size`); the light on the ground is home's. The grey plains (grey enough? friendly enough?), the rays, the dark
   patches. Venus, Earth and our Moon as tiny points (visible on a phone?).
3. Jump: ~4.4 blocks, a slow fall. Walk over the plains' craters (the rims step a block).
4. The thermometer by the pad (seen from the pad?): stand by it, its words.
5. The Sunshade Lander (the two steps up its front, one jump each; the shade on its south side), its chest.
6. MAP → Long Cliff: climb its terraces (3 high, 2 deep: one jump each; is the ledge wide enough on a phone?), walk its
   crest, the gentle slope down its back.
7. MAP → Big Crater: down its terraced walls to the floor and up the central peak. MAP → Ice Crater (a flight north): its
   ice and crystals, bright enough (never dark?).
8. Survivor: the bag goes to Mercury and home; Tilly's Mercury things; a gift or showcase holding a Mercury block (the
   server module 0.2.15 already takes ids up to 1023).
9. Page 30's first frames compile its materials (like any new universe). Performance (≥ 30 FPS, no frame over 100 ms): the
   autopilot with `--universe=23`.
10. The realistic pages' budget (ruling 13): 48 MB is a choice for the lead.

## Next (the game never ends)

The thermometer's reading following the game's day (430 °C by day, −180 °C at night); bright blue "hollows" in crater
floors (found by a spacecraft: pits where something in the rock seems to turn to gas); a giant basin like Caloris with
its ring of mountains; long cliffs cutting through craters (ruling 7); the double sunrise some places on Mercury see; the
Sun rising slowly (a day there is 176 Earth days); a shade over the ice craters; Mercury's own music; a Planet Book page
for Mercury.
