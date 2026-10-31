# Cosmos: Europa, world 20 (spec §21b.2)

The owner: "add cosmos, stars and planets where is planet is different universe" (#72) and "make the universies closer to
real worlds so player start learning real things" (#74). Brief: `docs/superpowers/plans/2026-09-29-cosmos-planet-brief.md`
with BODY = Europa, WORLD = 20, PAGE = 20, IDS = 368-383. Built by a worker agent in its own worktree (branch
`worktree-agent-a8b2783ab02e2fec4`, reset to `lead-merge` 583c73ab first), without the editor, the emulator or adb (one
windowed run of `tools/space_shots.gd` for pictures).

## Allocations (used; nothing else touched)

| What | Allocated | Used | Free |
|---|---|---|---|
| World number | 20 (`SpaceRules.EUROPA`, already in `SpaceRules` and the Star Map) | Europa | |
| Block ids, page 20 (`EuropaBlocks`) | 368-383 | 368-380 | 381-383 |
| `BlockIds.COUNT` | 352 → 384 (352-367, page 19, stay the Science Lab's: its bench takes 352 on its branch) | | |
| Atlas page | 20 (`data/blocks/pages/europa*.png`; page 19 is the Science Lab's, 21 a test's) | rows 0-2 | rows 3-7 |
| Item ids, animals, HUD spots | none | | |

Merge note for the lead: `BlockIds.COUNT` is 384 here; the Science Lab's branch moves it past 352 too: keep 384. Both
branches add a line after `ROVER_LIGHT` in `block_ids.gd`.

## What a child sees on Europa

1. **Getting there:** fly up above any world; the Star Map opens; Europa's card (Jupiter's moon, its three facts: the
   lead's in `StarMap`) now says **LAND**.
2. **Landing:** "You landed on Europa! Jump high and look up at Jupiter!" on the landing pad (every space world's pad),
   the golden portal home three steps away; the Space Book marks Europa landed on.
3. **Around the pad:** a smooth white plain of ice, brighter than snow, a step up or down only now and then (Europa is
   one of the smoothest bodies in the solar system); black space overhead with stars by day (almost no air); **giant
   Jupiter** hanging still in the sky, cream with brown-orange cloud bands and its Great Red Spot, with little yellow Io
   and grey Ganymede elsewhere in the sky, day and night (no moon disc of home). Soft icy chimes; "The Snow Is Dancing"
   and Gymnopédie first. No animals, no monsters.
4. **Jumping:** gravity 0.13 (real: 1.31 m/s²): a jump reaches ~13 blocks (1.7 at home) and floats for ~6 s. Walking
   into a 1-block step hops as high as on the Moon (3.4 blocks), not 9 (see ruling 7).
5. **Long reddish cracks** (lineae) cross the ice in three directions, hundreds of blocks long: a trough of reddish-brown
   ice with a ridge of pale stained ice on each side (Europa's double ridges), glowing salt crystals in them. Standing in
   one: "You found a long crack! Its reddish colour may come from salts and sulphur in the ice." (MY MAP marks it there.)
6. **Ice blades:** here and there fields of white ice spikes 2-4 blocks tall (penitentes: scientists think such blades
   may stand on Europa; no fact is said for them).
7. **The Ice Lander** (~45-55 blocks from the pad, facing it): four metal legs, a white body with a blue stripe, lights on
   the deck's corners, an antenna, two steps up its front, a golden chest on the deck, and under it the melt probe going
   down into a hole in the ice that glows blue. On the deck: "You found the Ice Lander! Scientists design probes to melt
   through the ice to the ocean."
8. **Water plumes** (about one per 200 × 200 blocks; MY MAP shows the one nearest the pad, "Water Plume"): a low mound of
   glowing salt with a 3 × 3 hole, the geyser vent at its bottom. The plumes near the child erupt now and then (each on
   its own beat: 3 s of every 9), a column of white vapour puffing up. On the mound: "You found a water plume! A space
   telescope saw one shoot about 100 km up from Europa." Step down onto the vent: **whoosh**, the plume throws the child
   ~41 blocks up and they float down for ~10 s.
9. **The ice cliffs** (MY MAP "Ice Cliffs", ~150-220 blocks from the pad): a plateau ~110 across with two cliffs of 8
   blocks and a terrace between (one Europa jump each), the faces showing blue deep ice with white bands, smooth on top.
   On top: "You climbed the ice cliffs! Europa's shell of ice is about 15 to 25 km thick."
10. **The ocean under the ice** (MY MAP "Ocean Under the Ice", ~200-265 blocks from the pad): a round well 23 blocks
    across through the ice, a flat rim round it, open to the sky (bright all the way down). A ramp of white ice winds down
    its wall (steps of 1-2, a glowing blue edge) from the rim to a shelf just over the water ~45 blocks down; rings of
    glowing blue ice on the blue-and-white banded walls; at the bottom dark blue water (8 deep, the rocky seafloor under
    it) that reaches on under the ice beyond the shaft. Reaching the water: "You reached the ocean under the ice! It may
    hold twice as much water as all of Earth's oceans." The pictures (below) show a spiral staircase of ice down a blue
    well to a round blue pool.
11. **Secrets** (the Secret Book counts them): buried treasure under an X of salt crystals, a hidden room of deep ice
    behind a fake deep-ice door (glowing ice lamps, an ice-brick floor), the explorers' ice station (the puzzle temple in
    ice bricks, lander lights, star gold on top: friendly and made up), salt crystal geodes deep in the seafloor rock. No
    secret is built into the well or onto a vent. Each banner: a find, then a fact (below).
12. **Tilly** (Survivor) sells Europa's ice, reddish and stained ice, deep ice, seafloor rock, glow ice, salt, ice bricks,
    the lander's panel, probe and light, and the landing pad at home prices; never star gold or the fake door.
13. **Home:** walk into the portal or fly up and tap HOME: back on the take-off column.

## How it plugs in (the Moon's and Mars's pattern)

- **New files:** `world/universes/europa.gd` (the descriptor), `world/universes/europa_blocks.gd` (page 20),
  `world/generators/europa_terrain.gd` (`EuropaTerrain`: the regions and the well as pure rules), `world/space_geysers.gd`
  (`SpaceGeysers`), `data/blocks/pages/europa{,_albedo,_normal}.png` (+ imports), `tools/europa_smoke.gd`,
  `tools/europa_smoke_steps.gd`, tests (below).
- **Shared, small and additive:** `data/blocks/block_ids.gd` (ids, names, `SPACE_GROUND`, `COUNT` 384),
  `world/block_library.gd` (one register line), `world/generators/space_shape.gd` (planet `EUROPA`: a branch per method,
  `europa_columns`, `europa_kind`, `_europa_top`, `_europa_block_at`, `_europa_calm`, `sight_at`/`sights` for Europa),
  `world/generators/space_generator.gd` (Europa's stack, `_fill_europa_layers`, `_write_europa_column`,
  `_carve_europa_well`), `world/generators/space_secret_rules.gd` (Europa's palette, `_ice_lander`, `_fits`),
  `world/universes/universe_registry.gd` (`SPACE[20]`), `core/rules/space_rules.gd` (`WORLDS` has 20),
  `world/sky_cycle.gd` (a sky planet's `bands` and `spot`), `core/rules/pad_rules.gd` + `entities/fx/pad_fx.gd` (the
  geyser vent is a pad), `core/rules/lab_rules.gd` + `entities/player/player.gd` (the gentle hop, one line),
  `scenes/sandbox.gd` (`_space_geysers()` after `_space_sights()`), the natural-block lists (`bot_rules`,
  `surprise_rules`, `capture_rules`, `gather_rules`, `chat_commands`, `secret_rules.is_fake_wall`),
  `ui/universe/universe_art.gd` (Europa's card: the Ice Lander on white ice by a reddish crack, giant banded Jupiter and
  Io in the black sky), `core/rules/loading_hints.gd` (six Europa hints), `tools/make_space_atlas.gd` (page 20;
  `-- europa`), `tools/make_space_realistic.py` (`europa`), `tools/bench_generator.gd` (`BENCH_EUROPA_<REGION>`),
  `tools/space_shots.gd` (`--sights`), `assets/CREDITS.md`, `docs/DEVELOPMENT.md`, spec §21b.2 ("As built").
- **Not touched:** the School, the Science Lab, `ui/space/*` (the Star Map UI), `StarMap`, `WonderData`, the other
  worlds' files (Mars's tests only for the new `WORLDS` and `COUNT`).
- **Shared tests updated for world 20 and COUNT 384:** `test_space_rules` (WORLDS), `test_space_registry` (warm_space,
  space_available), `test_planet_universes` (space_available), `test_mars_universe` (WORLDS starts with Mars's four),
  `test_mars_blocks` (COUNT ≥ 352), `test_realistic_pack` (EuropaBlocks.FILES), `test_space_shape` (the dry-land test
  skips Europa's well: the one place with water). The shared planet tests (`test_space_shape`, `test_space_secrets`,
  `test_space_generator`) now also run for Europa (it is in `SpaceShape.PLANETS`).

## Rulings (decided on the owner's behalf; cost if wrong)

1. **Europa is a planet kind of `SpaceShape`, its regions in `EuropaTerrain`** (Mars's ruling 1): the shared planet tests
   cover it for free. *Cost:* none new.
2. **The ocean is a well, open to the sky** (the spec's "a deep ice cave down to dark water"): a vertical shaft with a
   ramp, not a roofed cave, because the game's cave mood darkens anything under a ceiling (`AmbienceRules`: dark with a
   lantern), and §3c says never dark and scary. Only the ring where the water reaches under the ice (3 blocks beyond the
   shaft) is under a roof. No global ocean layer under the whole crust: a second surface under every column would double
   the meshing everywhere (the budget, §7.5). *Cost:* a roofed grotto later is `well_block` rules; a real ocean layer is a
   performance question first.
3. **Heights:** the crust's top ~52, the water's surface at y 6 (the first air), its bottom at y -2 over the seafloor
   rock (ice from y 0 up, rock under it: a cut through the crust shows ice over ocean over rock, like the real moon's
   layers; the real shell is 15-25 km, the ocean 60-150 km deep). *Cost:* constants in `EuropaTerrain`.
4. **The ramp is one turn of pillars** (each wall column solid from the water up to its ramp height, water under it):
   a column holds one ramp height, so a ramp of several turns is impossible without a 3D rule; one turn of 0.85 with 1-2
   block steps, then a shelf, is gentle enough in 13-block jumps. The seam where the ramp's top meets the shelf is a
   45-block drop into water (floaty, harmless). *Cost:* `ramp_top`.
5. **Where things are:** the well 190-240 blocks from the world's middle in a seeded direction, the cliffs 180-220 on the
   far side (150-210° round), the pad near the middle ≥ 120 from the well, ≥ 145 from the cliffs' middle, ≥ 80 from any
   vent, no crack on it. *Cost:* constants.
6. **A geyser vent is a pad** (`PadRules.GEYSER_SPEED` = the jump pad's 16 m/s, ~41 blocks up in 0.13 gravity): the
   plume "throws you up" through the player's own pad code (cooldown, every game's puff via `PadFx`). A child standing on
   it is thrown up again after each landing, like a jump pad; they steer off it in the air. A vent given with `/give`
   works anywhere (a jump pad that looks like a vent). *Cost:* one branch in `PadRules`.
7. **The auto-step hop in very low gravity:** the player's hop onto a 1-block ledge (7.6 m/s) flew a child ~9 blocks up
   on Europa for ~5 s per step. `LabRules.step_velocity` keeps the hop's height the Moon's (3.4 blocks) whenever the
   total gravity is under the Moon's 0.35; the Moon, Mars and every universe are unchanged; the Physics Lab's Moon mode
   on the Moon or Mars (0.12-0.13) gets the gentler hop too. *Cost:* one line in `player.gd`; the lead should feel it on
   the emulator.
8. **Sky:** space's black sky all day (`space_sky` 1, like the Moon: Europa's air is a trace of oxygen), `photo_sky`
   false; Jupiter 104 across at the sky's radius (~25°; the real one is ~12° from Europa: exaggerated as Earth over the
   Moon is), fixed in the sky (Europa is tidally locked), Io and Ganymede (13 and 11 across: bigger than the real ~0.8°)
   as `moons`; `own_moons` so home's moon disc never shows. *Cost:* numbers in the descriptor.
9. **Sounds:** no new audio: the chimes loop by day and night (no air, no wind), The Snow Is Dancing (Frostpeak's own
   piece, allowed as a favourite) and Gymnopédie, the whoosh for the plumes. *Cost:* a CC0 recording later is a
   `MusicPieces` entry.
10. **No mission names** (spec §21b.2): the facts say "a space telescope" (Hubble), "scientists" (the cryobot concepts),
    and the lander is "the Ice Lander", made up (a lander concept exists; no mission is named). A test checks the words
    for Hubble, Galileo, Clipper, JUICE, Juno, Voyager, NASA, ESA and JPL.
11. **Craters, chaos terrain (the jumbled ice rafts of Conamara Chaos), the plumes' frost falling back, a Planet Book
    page:** next, not now. *Cost:* none yet.
12. **Ice blades are rarer than the first try:** the pictures showed a forest of white posts round the pad; the fields
    now take ~5 % of their area (`BLADE_PER_MILLE` 70) over fewer fields (`FIELD` 0.5). *Cost:* two constants.

## The facts (every Europa fact in the game, and its check)

| Where | Words | Check |
|---|---|---|
| gravity | 0.13 | 1.315 m/s² ÷ 9.81 = 0.134 (NASA) |
| landing | "You landed on Europa! Jump high and look up at Jupiter!" | Jupiter always hangs in the sky of Europa's near side |
| treasure | "Europa is a little smaller than our Moon." | "about 90% the size of Earth's Moon" ([NASA Europa facts](https://science.nasa.gov/jupiter/jupiter-moons/europa/europa-facts/)) |
| hidden room | "Europa's ice is about −160 °C, colder than any freezer." | the surface averages about 110 K (−260 °F, −160 °C) at the equator ([NASA: daytime temperatures on Europa](https://science.nasa.gov/missions/europa-clipper/europa-clipper-resources/daytime-temperatures-on-europa/), [Europa Clipper FAQ](https://europa.nasa.gov/mission/faq/)) |
| ice station | "A day on Europa lasts about 3.5 Earth days." | "Europa orbits Jupiter every 3.5 days and is locked by gravity to Jupiter" (NASA Europa facts) |
| Ice Lander | "Scientists design probes to melt through the ice to the ocean." | cryobot concepts (JPL's PRIME, NASA's SESAME programme): a lander on the ice, a probe melting down to the ocean ([JPL PIA25314](https://www.jpl.nasa.gov/images/pia25314-cryobot-for-ocean-worlds-exploration-illustration/)) |
| geode | "A space telescope found table salt on Europa's ice." | 2019: Hubble's spectra showed sodium chloride in Tara Regio ([NASA](https://science.nasa.gov/missions/hubble/table-salt-compound-spotted-on-europa/)) |
| ocean | "It may hold twice as much water as all of Earth's oceans." | "its ocean may contain twice as much water as Earth's global ocean" (NASA Europa facts) |
| cliffs | "Europa's shell of ice is about 15 to 25 km thick." | "Scientists think Europa's ice shell is 10 to 15 miles (15 to 25 kilometers) thick" (NASA Europa facts) |
| plume | "A space telescope saw one shoot about 100 km up from Europa." | Hubble, 22 Feb 2016: a plume rising about 100 km (62 miles) ([JPL PIA21443](https://www.jpl.nasa.gov/images/pia21443-hubble-sees-recurring-plume-erupting-from-europa/)); Galileo's 1997 data re-analysed in 2018 back it up ([NASA](https://www.nasa.gov/news-release/old-data-reveal-new-evidence-of-europa-plumes/)) |
| crack | "Its reddish colour may come from salts and sulphur in the ice." | "a reddish-brown material ... likely contains salts and sulfur compounds that have been mixed with the water ice and modified by radiation" (NASA Europa facts) |
| hint | "On Europa you jump over 7 times as high!" | 1 ÷ 0.134 = 7.5 |
| hint | "Jupiter never moves in Europa's sky!" | tidally locked: "the same hemisphere of the moon always faces the planet" (NASA); true where Jupiter is seen at all (the far side never sees it; the game shows it everywhere) |
| hint | "A salty ocean hides under the ice. Find the well!" | Galileo's magnetometer (2000) measured the magnetic signature of a salty, conducting ocean ([JPL](https://www.jpl.nasa.gov/news/galileo-evidence-points-to-possible-water-world-under-europas-icy-crust/)) |
| terrain | a smooth crust | "Europa has a very smooth surface, relative to the other icy moons" (NASA Europa facts) |
| terrain | ice blades (no words) | penitentes up to ~15 m were predicted near Europa's equator (Hobley et al., Nature Geoscience 2018): a hypothesis, so the game says nothing about them |
| sky | Jupiter, Io, Ganymede | Jupiter ~12° across from Europa; Io (3,643 km at ≥ 250,000 km) and Ganymede (5,268 km at ≥ 400,000 km) up to ~0.8° (our full Moon: 0.5°); the game makes them bigger |

(The Star Map's own three Europa facts are the lead's, in `core/rules/star_map.gd`; unchanged.)

## Tests (RED → GREEN)

| Test file | Tests | RED (why it failed first) |
|---|---|---|
| `tests/unit/test_europa_blocks.gd` | 8 | ids not declared (`BlockIds.GLOW_ICE`, `EuropaBlocks`) — run and seen |
| `tests/unit/test_europa_universe.gd` | 11 | written before `europa.gd`, `EuropaTerrain` (not declared); `test_space_rules` failed on WORLDS [16..19] — run and seen |
| `tests/unit/test_europa_shape.gd` | 19 | written before `EuropaTerrain` / `SpaceShape.EUROPA` existed |
| `tests/unit/test_europa_generator.gd` | 7 | written before the Europa generator path and the well's carving |
| `tests/unit/test_europa_secrets.gd` | 7 | written before Europa's palette, the Ice Lander and `_fits` |
| `tests/unit/test_low_gravity_step.gd` | 3 | written before `LabRules.step_velocity` |
| `tests/integration/test_europa_world.gd` | 3 | written before `europa.gd` |
| `tests/integration/test_europa_sky.gd` | 3 | written before a sky planet's `bands` and `spot` |
| `tests/integration/test_europa_sights.gd` | 5 | written before Europa's sights and `SpaceGeysers` |
| shared (see above) | | WORLDS, warm_space and space_available lists, COUNT, the realistic pack's pages, the dry-land test |

On the way: the ramp test sampled across the ramp's seam (the shelf's column next to the rim's) and was moved clear of it;
the geysers test moved its child with a local variable a lambda had copied (GDScript lambdas capture locals by value), so
it now uses a member, and waits for the once-a-second look for vents before counting.

## Measurements

Generator bench (`bench_generator.gd -- --space moon mars europa`, 640 chunks per planet alternating with Green Meadows;
the PC's load was **22** on 24 cores, so every number is slow, the ratios are what count):

| chunks | Meadows avg ms | Moon | Mars | Europa |
|---|---|---|---|---|
| surface, warm (stacks cached) | 1.58-2.90 | 2.69 | 1.41 | **0.50** |
| surface, cold (fresh generators, a stack's chunks in a row) | 1.73-3.07 | 3.51 | 1.91 | **0.75** |
| underground | 1.15-2.30 | 0.50-0.56 | 0.33-0.34 | **0.27-0.28** |
| sky (y 80+) | 0.80-1.45 | 0.01-0.02 | 0.01 | **0.01** |
| all, cold | 1.42-2.60 | 1.96 | 1.09 | **0.49** |
| a new area's secrets (once, then cached) | — | 1.19 (worst 2.6) | 0.71 (worst 1.5) | **0.33 (worst 0.76)** |

(Each planet's own row alternated with its own Meadows run, so each column's Meadows number is that planet's partner.)
Europa's regions (`BENCH_EUROPA_<REGION>`, fresh generators over 4 × 4 whole chunk stacks, y -64..159, against the meadows
on the same chunks): the ocean well 0.50 ms vs 0.90 (worst chunk 3.24 ms: the well's carving), the ice cliffs 0.39 vs
1.30, a plume's vent 0.36 vs 0.91; underground 0.28-0.29 vs 1.04-1.31. `EuropaTerrain.column` costs ~7 µs (3 crack
noises, the swell, the mask). Every `--script` bench run prints the usual autoload compile errors (scripts that use
autoloads, loaded without them); the numbers are unaffected.

Geography (`SpaceShape`/`EuropaTerrain`, printed by a scratch script; kinds over 20,000 columns in ±1000):

| seed | pad (ground) | well (from the pad) | cliffs (from the pad) | nearest vent | Ice Lander | cracks + ridges |
|---|---|---|---|---|---|---|
| 12345 | (24, -42) at 52 | (68, 210), 256 | (-75, -178), 168 | (-103, 41), 152 | (-17, 54, -15) | 5.1 % + 10.1 % |
| 77 | (8, 47) at 51 | (-191, 17), 201 | (207, 63), 200 | (-102, 118), 131 | (-41, 52, 55) | 5.8 % + 10.2 % |
| 777 | (-8, 47) at 52 | (167, 145), 201 | (-191, -69), 217 | (-118, 72), 113 | (35, 55, 14) | 6.0 % + 9.8 % |
| 42 | (-32, 55) at 52 | (18, -200), 260 | (69, 200), 177 | (-76, 131), 88 | (-53, 53, 94) | 6.5 % + 11.2 % |

## Smoke runs

- `tools/europa_smoke.gd` (seed 12345, a private `XDG_DATA_HOME` with "smoke" in its path and a copy of `profile.json`):
  **34 checks, 0 fails** (exit 0; twice, the second after the last changes): a new Green Meadows Sandbox world; the Star Map; Europa's card (3 facts, LAND);
  Europa's own world `sandbox_20`, its terrain, gravity 0.13, space's black sky, giant Jupiter, Io and Ganymede, on the
  landing pad, peaceful, no animals, MY MAP's pad and three sights, the Space Book's LANDED mark, the sights and the
  plumes watched; the portal home by the pad; a slow fall (0.88 m/s after 0.3 s); the Ice Lander is the landmark and is
  found on its deck, then shown on MY MAP; a plume's mound says its fact; its vent throws the child up (12+ blocks within
  a second); the ice cliffs' top says its fact (height 67); the shelf at the bottom of the well says the ocean's fact,
  water under it; through the portal home: Green Meadows `sandbox_1`, on the take-off column, home gravity.

## Pictures (`tools/space_shots.gd -- --universe=20 --sights`, windowed, both styles)

Seen: from over the pad, a black starry sky with Jupiter big in the north-east (cream, brown-orange bands, the red spot),
little yellow Io; the ice dazzling white to the horizon, cracks as reddish-brown bands between pale tan ridges with
glowing salt crystals, the ice cliffs' blue-and-white banded faces in the distance, the explorers' ice station (ice
bricks, star gold on top) near the pad, the Ice Lander on its legs; at sunset the ice turns a soft blue-grey; at night
Jupiter and Io bright among the stars. Over the well: a spiral staircase of white ice down blue banded walls with pale
glowing rings to a round pool (light blue in BLOCKY, a deep dark blue in REALISTIC). A plume's mound of pale salt with
white vapour puffs rising from it. The REALISTIC style looks close to BLOCKY at 640 × 360 (white ice both ways); the
cracks are smoother and browner. A first try had a forest of white ice blades round the pad (thinned: ruling 12). A
"Theater" building stood near the pad (the places system's, not Europa's).

- `tools/mars_smoke.gd` (Mars, after this work's shared changes): **29 checks, 0 fails**; `tools/space_smoke.gd` (the
  Moon and Planet Boing): **36 checks, 0 fails**.

## Full suite

`tests/run_tests.sh` (2026-09-29 ~15:05-15:40, load 8-22): **774 scripts, 7128 tests, 7126 passing, 0 failing, 2
risky** (`test_meadows_biome_generator.gd`'s two that never assert, as before this work), no script errors. Two words
changed after it (the geode's fact now says "a space telescope"; the Jupiter hint's picture); their tests
(`test_europa_universe`, `test_loading_hints`) passed again, and the Europa smoke again.

## The lead's checklist (emulator, both styles)

1. Sandbox, Green Meadows: fly up; on the Star Map tap Europa: LAND. The loading card shows Europa's picture (the Ice
   Lander on white ice, a reddish crack, banded Jupiter and Io in the black sky) and a Europa hint.
2. On Europa: the black sky and giant Jupiter (too big? too small?), Io and Ganymede; the ice's brightness in BLOCKY and
   REALISTIC (glare on a phone?).
3. Jump: ~13 blocks, a ~6 s float. Walk over a crack's ridges: the 1-block hop should now be gentle (ruling 7): is it
   comfortable? Is the hop on the Moon unchanged?
4. MAP → Water Plume: walk onto the mound, see the vapour, step into the hole: the throw (~41 blocks) and the float down.
5. MAP → Ocean Under the Ice: walk down the ramp (or jump in), the glowing rings, swim in the ocean and under the ice's
   edge (a small cave mood there: acceptable?). Performance while standing at the rim and at the bottom (≥ 30 FPS, no
   frame over 100 ms): the autopilot with `--universe=20`.
6. MAP → Ice Cliffs: two cliffs of 8, one jump each.
7. The Ice Lander (climb the steps or jump to the deck), the ice station's puzzle, a salt geode (dig).
8. Survivor: the bag goes to Europa and home; Tilly's Europa things.
9. Page 20's first frames compile its materials (like any new universe).

## Next (the game never ends)

Chaos terrain (the jumbled, tilted ice rafts of Conamara Chaos, with its fact), a few craters (Pwyll with its bright rays),
the plumes' vapour freezing and falling back as frost, a roofed grotto of glowing ice at the bottom of the well (with the
cave mood made bright for it), the far side where Jupiter is never seen, a Planet Book page for Europa's facts, Europa's
own music; then Io (world 21).
