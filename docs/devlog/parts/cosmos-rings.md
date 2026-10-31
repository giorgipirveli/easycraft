# Cosmos: Saturn's rings, world 25 (spec §21b.2)

The owner: "add cosmos, stars and planets where is planet is different universe" (#72) and "make the universies closer to
real worlds so player start learning real things" (#74). Brief: `docs/superpowers/plans/2026-09-29-cosmos-planet-brief.md`
with BODY = Saturn's rings, WORLD = 25, PAGE = 40, IDS = 688-703 (page 39, ids 672-687, held for another agent's work: the
mining on the Moon and Mars). The spec's row: "25 | Saturn's rings | gravity 0.05 | floating chunks of ice and rock in
bands, Saturn huge below, hopping from chunk to chunk". The lead's ideas: countless pieces of water ice from dust to
house-sized, in bands with gaps (the Cassini Division is real: say so), shepherd moons, Saturn's banded globe and its
shadow on the rings, the Sun small and far (about 10 × Earth's distance), Titan and other moons in the sky; very low
gravity (long, slow jumps); a child can never fall into Saturn (a fall caught kindly, like Venus's warm breeze); a
landing place (a pad on a big chunk, a small station), a robot helper and the aliens, a mission row, sights with real
facts on MY MAP, secrets, the Star Map's LAND/MISSION; cheap (a bench before/after). Built by a worker agent in its own
worktree (branch `worktree-agent-a7e5cc872974752cd`, reset to `lead-merge` 3ccc5e5b first), without the editor, the
emulator or adb (one windowed run of `tools/space_shots.gd` for pictures).

## Allocations (used; nothing else touched)

| What | Allocated | Used | Free |
|---|---|---|---|
| World number | 25 (`SpaceRules.RINGS`, already in `SpaceRules` and the Star Map's Saturn) | Saturn's rings | |
| Block ids, page 40 (`RingsBlocks`) | 688-703 | 688-703 (all 16) | none |
| Page 39 (ids 672-687) | another agent's | untouched (empty models in the library) | |
| `BlockIds.COUNT` | 672 → 704 | | |
| `BlockIds.NEXT_PAGE_FIRST_ID` | 672 → 704 (page 41 is the next) | | |
| Atlas page | 40 (`data/blocks/pages/rings*.png`) | rows 0-2 | rows 3-7 |
| Item ids, animals, HUD spots | none | | |
| Server module | unchanged (0.2.15 already lets blocks up to 1023 travel in gifts) | | |

## What a child sees in Saturn's rings

1. **Getting there:** fly up above any world (or fly the Mission to Saturn's rings); the Star Map opens; Saturn's card (the
   lead's three facts: rings of ice and rock from dust to chunks as big as houses; Saturn would float in a bath; a year of
   29 Earth years) says **Saturn's rings: LAND** once the mission is flown (or the rings were landed in before), else
   **MISSION**. Titan keeps its own card.
2. **Landing:** "You landed on Saturn's rings! Jump from chunk to chunk: you are very light here!" on the landing pad in
   the middle of a big flat chunk of frosty ice (radius 22), the golden portal home three steps away, Hoop the helper
   robot, the rover and the drone by the pad; the Space Book marks Saturn landed on.
3. **The sky:** no air: space's black sky with stars by day and night; **Saturn huge over the northern horizon** (about 77°
   across: from the B ring it really fills about 70°), its pale gold zones and tan belts, **its rings seen edge-on** (we
   stand in them) as a bright line across its middle and out past its edges, the rings' shadow a dark band on its clouds,
   **Saturn's shadow cutting the rings** just past its right edge; the Sun a small bright point (0.1 × home's: Saturn is
   9.5 times as far from it); Titan (orange), Enceladus (white) and Mimas in the sky, the F ring's shepherds Prometheus and
   Pandora two little lumps low in the south. Icy chimes; the Waltz of the Flowers by day, the Moonlight Sonata at night. No
   animals, no monsters.
4. **The rings:** a strip of Saturn's rings, endless east-west (the rings go all the way round Saturn), north towards
   Saturn. Chunks of ice float at slightly different heights (tops at 57-71) over open space: big flat-topped chunks with
   frosty tops, rough round undersides of clean ice (radius 6-13: house-sized and bigger), boulders and pebbles between
   them, some of dark rock. From north to south: the **C ring** (~150-290 blocks north of the pad: fewer, smaller chunks of
   darker, dustier ice, Saturn behind them), the bright, dense **B ring** (the landing chunk; ~20 % of the ground is big
   chunks), the **Cassini Division** (60 blocks: only a few small, darker lumps to hop on), the **A ring** (~150-360
   south) with the **Encke Gap** (56 blocks, ~270 south) where **Pan** floats (a round moonlet of pale ice with a ridge of
   ring dust round its middle: walnut-shaped, a teal beacon on its top) and the narrow **Keeler Gap**, then the thin
   **F ring** (~390 south: two wandering strands of little lumps that braid, a small chunk with a beacon), then space.
5. **Near the pad:** the **Ring Station** (east of the pad, or west in a mirrored world: white panels with a teal trim,
   round windows, a door towards the pad, a lamp inside, lamps on its roof, a radio dish on a truss, a glowing power pack),
   a **Saturn model** on a post (a banded ball with a ring of frost), the **Saturn scope** at the landing chunk's north rim
   looking at Saturn. A short hop away: the aliens' **camp chunk** (Frosi the explorer, Clink the trader and their little
   ship), the **show chunk** (the Shorts Theater), the **explorer's chunk** (the Ring Explorer) and, at the B ring's
   outer edge, the **edge chunk** with the Cassini Division's beacon.
6. **Jumping:** gravity 0.05 (the spec's): a jump floats ~34 blocks up and lasts ~15 s; a child steers across ~90 blocks
   (the Cassini Division in one hop). The chunks' tops are flat (no step on a chunk: see ruling 4).
7. **Falling between the chunks:** walk off a chunk and the child floats down slowly for ~5 s, then "Pfff! Your space
   suit's little jets flew you back to the ice." and stands where it last stood: never towards Saturn, never hurt, nothing
   lost. The rover never drops into open space (it keeps its height over a gap).
8. **The Ring Explorer** (the landmark, ~50 blocks from the pad on its own chunk): a body wrapped in gold foil with a white
   deck on top, a big white radio dish on a truss over it with a lamp on its feed, three glowing power packs on arms, a long
   boom out to one side with its sensor, four little feet; its door towards the pad, the golden chest inside. Walking in:
   "You found the Ring Explorer! In 2017 a spacecraft dived between Saturn and its rings 22 times."
9. **Sights** (MY MAP shows all six from the landing; the planet guide's checklist lists them; Hoop points at them): the
   **Saturn scope** (18 north of the pad), the **Ring Station** (its door), the **Cassini Division** (the edge chunk's
   beacon, ~100 south), the **C ring** (its chunk's beacon, ~220 north), the **F ring** (its chunk's beacon, ~390 south),
   **Pan** (its top, ~300 south).
10. **Secrets** (the Secret Book counts them): buried treasure under an X of glowing ring crystals in a chunk's top, a
    hidden room in a chunk's ice behind a fake ice door (stairs up through the chunk), the explorers' station (the puzzle
    temple in station panels and lamps: friendly and made up), ring crystal geodes inside the chunks. Every one on a big
    chunk (never over open space, a lump or Pan, never on the camp or show chunk, clear of the built parts).
11. **Tilly** (Survivor) sells the rings' ice, frost, dusty ice, rock, Pan's ice and ridge dust, ring crystals, the
    station's panels, windows and lamps, radio dishes, power packs, truss, beacons, Saturn bands, telescopes and the
    landing pad at home prices; never star gold or the fake door. Tilly and the Totem stand on the landing chunk.
12. **Nothing hurts:** falling is a slow float and a kind rescue; no word says anything hurts, crashes, is dangerous or
    scary, or that a child falls into Saturn (`test_falling_is_never_a_danger`); the smoke checks the hearts.
13. **Home:** walk into the portal or fly up and tap HOME: back on the take-off column.

## How it plugs in

- **New files:** `world/universes/rings.gd` (the descriptor), `world/universes/rings_blocks.gd` (page 40),
  `world/generators/rings_terrain.gd` (`RingsTerrain`: the rings as pure rules), `data/blocks/pages/rings{,_albedo,_normal}.png`
  (+ imports), `tools/rings_smoke.gd`, `tools/rings_smoke_steps.gd`, tests (below).
- **Shared, small and additive:** `data/blocks/block_ids.gd` (ids, names, `SPACE_GROUND`, `COUNT` 704,
  `NEXT_PAGE_FIRST_ID` 704), `world/block_library.gd` (one register line), `world/generators/space_shape.gd` (planet
  `RINGS`: a branch per method, `rings_columns`, `rings_kind`, `_rings_block_at`: no bedrock), `world/generators/space_generator.gd`
  (`_rings_stack`, `_generate_rings`; the built parts in the reference), `world/generators/space_secret_rules.gd` (the
  rings' palette, `ATTEMPTS_RINGS`, `RINGS_INNER`, `_ring_geode`, `_ring_explorer`; `_hull_room` reused; `_fits` through
  `RingsTerrain.holds`), `world/generators/secret_rules.gd` (`is_fake_wall`), `world/universes/universe_registry.gd`
  (`SPACE[25]`, `MIN_GRAVITY` 0.05, `MIN_SUN` 0.1), `world/sky_cycle.gd` (a sky planet's `dir`, `ring_edge`, `pixels`),
  `core/rules/space_rules.gd` (`WORLDS` has 25), `core/rules/star_map.gd` (Saturn's `land`: "Saturn's rings"),
  `core/rules/mission_rules.gd` (the rings' row), `core/creatures/alien_rules.gd` (the camp chunk), `core/creatures/creature_words.gd`
  (Hoop, Frosi, Clink, three souvenirs), `core/magic/mini_rules.gd` (`alien_frosi`), `entities/robot/space_creatures.gd`
  (the rover's ground over open space), `core/rules/theater_site.gd` (the show chunk), `entities/flight/flight_looks.gd`
  (`SUN_SIZE`), the natural-block lists (`bot_rules`, `surprise_rules`, `capture_rules`, `gather_rules`, `chat_commands`),
  `ui/universe/universe_art.gd` (the rings' card), `core/rules/loading_hints.gd` (eight hints), `tools/make_space_atlas.gd`
  (`-- rings`), `tools/make_space_realistic.py` (`rings`), `tools/bench_generator.gd`
  (`BENCH_RINGS_<LANDING|B_RING|C_RING|CASSINI|PAN|F_RING|OPEN>`), `docs/DEVELOPMENT.md`, spec §21b.2 ("As built"),
  `docs/devlog/parts/missions.md` (the rings' row), `assets/CREDITS.md`.
- **Not touched:** the School, the Science Lab, `ui/space/*` (the Star Map UI), the colonies, the server, the other
  worlds' files, page 39, the sandbox and the player (Venus's void line, sky planet and rover hooks were enough).
- **Shared tests updated:** `test_space_rules` (WORLDS), `test_space_registry` (warm_space, space_available),
  `test_planet_universes` (space_available), `test_realistic_pack` (RingsBlocks.FILES), `test_block_id_space` (704, page
  41), `test_block_pages` (page 40 is 688), `test_prospect_blocks` (COUNT past the riches' page), `test_page_sizes` (the
  budget, ruling 11), `test_space_shape` (the rings' open space and lumps are no dry land), `test_robot_words` (the camps;
  the Cassini Division's name, ruling 16), `test_mission_rules` (the missions' order), `test_robot_creatures` (+1: the
  rings' robots and camp). The shared planet tests (`test_space_shape`, `test_space_secrets`, `test_space_generator`,
  `test_alien_rules`) now also run for the rings (they are in `SpaceShape.PLANETS`).

## Rulings (decided on the owner's behalf; cost if wrong)

1. **The world is a strip of the ring plane:** bands by z (north, -z, towards Saturn), endless along x (the B ring is
   ~650,000 km round: its curve is invisible over a few thousand blocks). *Cost:* none; a round world is not a voxel world.
2. **Not to scale, in the real order:** the bands keep their order, their look (the C ring darker and sparser, the B ring
   brightest and densest, the Cassini Division nearly empty, gaps in the A ring, the thin F ring) and their proportions
   roughly; distances are for play (the Cassini Division 60 blocks, Pan ~300 south, the F ring ~390). *Cost:* constants in
   `RingsTerrain`.
3. **Gravity 0.05 is the spec's, a game number:** a real house-sized ice chunk (10 m, ~470 t) pulls about 1.3 × 10⁻⁶ m/s²,
   some ten million times less than Earth; its escape speed is a few millimetres a second: one hop would float away for
   ever. A loading hint says so ("On a real ring chunk, one hop floats you away!", like the Moon card's honesty).
   `UniverseRegistry.MIN_GRAVITY` went from 0.1 to 0.05 so the spec's number is not clamped. *Cost:* one number.
4. **Flat chunk tops, no step on a chunk:** at 0.05 gravity the auto-step hop (`LabRules.step_velocity`: the Moon's hop
   height) floats ~5 s for a one-block step, so a big chunk's top is one level (a first version rounded the rim one block
   down; removed). Their undersides are round and rough (±1 a column). Pan's dome has steps (a child hops onto it). *Cost:*
   a gentler hop rule for very low gravity (home's height: ~2.8 s) would change `LabRules` for the next worlds too.
5. **The rescue is the suit's little jets:** no air, so no breeze; spacewalkers really carry small jet packs to fly back to
   their ship. The Dragon Realm's void with the rings' own line (`LIFT_Y` 50: under every chunk's top, ≥ 57; lumps ≥ 59;
   Pan's ridge 61) and words: a fall floats ~5 s (measured 4.9 s), then back. *Cost:* one constant (a higher line: a
   shorter float).
6. **One span per column:** big chunks stay inside their own `BIG` cell (`m` = r + 1 from its edges), lumps inside their
   `SMALL` cell and never near a big chunk, a fixed chunk or Pan; the F ring's lumps may touch: the first in a fixed order
   wins (the same from `column()` and `columns()`). *Cost:* none.
7. **Saturn over the northern horizon, not under the ice:** the rings lie in Saturn's equator plane, so from inside them
   Saturn is centred on the rings' horizon, half above and half below it, ~70° across from the B ring (2 × asin(60,268 km ÷
   105,000 km)). The spec's "Saturn huge below" is that lower half. A floor of Saturn's clouds under the rings would teach
   the wrong picture. *Cost:* a cloud floor would be one terrain layer.
8. **The shadows are in Saturn's picture:** its shadow across the rings and the rings' shadow on its clouds are drawn by
   `SkyCycle.planet_image` (`ring_edge`); the chunks are not shadowed and night is the game's night (real ring chunks pass
   through Saturn's shadow once an orbit, every ~10 hours). *Cost:* a shadow sweeping the chunks would be a light change on a
   clock.
9. **The Sun is small, its light is not:** `sun_size` 0.1 (`MIN_SUN` went from 0.25 to 0.1); sunlight at Saturn is ~1/90
   as bright as at home (NSSDC), but the light stays friendly (spec §3c). *Cost:* a dimmer light is one factor.
10. **The mission brakes in Saturn's thin upper air first:** 9.4 + 7.3 + 0.6 + 2.7 = 20.0 km/s. Matching a ring chunk
    (~19 km/s round Saturn in the B ring) from an orbit reaching out to Titan would cost ~6.8 km/s by engines alone
    (24.1 in all: a rocket of ~1,000 parts, ~35,000 gold, out of any child's reach); dips through Saturn's thin upper air
    (aerobraking, first done at Venus in 1993 and then at Mars, with solar panels as the drag surfaces: no heat shield)
    lower the far end of the orbit to the rings for free, then a 2.7 km/s burn there matches the chunks. `air` stays false
    (no heat shield, no parachute). A rocket of ~270 parts (a search like the missions agent's: Mercury ~230-310, Titan
    ~140-150). *Cost:* data.
11. **The realistic pages' budget rose from 60 to 64 MB** (`test_page_sizes.gd`): the rings' page brought them to 58.5 MB,
    and page 39 comes next (another agent). *Cost:* the APK grows ~1.6 MB a page.
12. **Saturn's picture is bigger** (`pixels` 192 instead of 96: ~20 ms at a world's load on the PC, once) and its globe
    has room round it on the quad for the rings (`ring_edge` uses a ringed planet's 0.3 and 1.6 ×). *Cost:* a phone may
    take ~100 ms at a world's load.
13. **The Star Map's Saturn card says "Saturn's rings: LAND"** (`StarMap`'s `land`, like Earth's "Wonders of the World:
    LAND"): Saturn has no ground. One data line in `core/rules/star_map.gd` (the rules, not the Star Map UI). *Cost:* none.
14. **No features on the ice** (no crystals or boulders on the chunks' tops: obstacles at 0.05 gravity); the look comes
    from the chunks' sizes and heights, the rock lumps, the dusty C ring, the beacons. `tree_at` marks the built parts'
    ground only (Tilly and the Totem keep off the station). *Cost:* features would be one more rule in `RingsTerrain`.
15. **The aliens camp on their own chunk and the Theater stands on its own chunk** (`AlienRules.safe_ground`,
    `TheaterSite.on_colony`), as on Venus. *Cost:* two lines.
16. **The Cassini Division is a place, not the mission:** it is named for the astronomer who saw it in 1675; the words say
    "the Cassini Division" and "an astronomer called Cassini" and never name the spacecraft. `test_robot_words` reads
    "Cassini Division" as a place (the robot's question names it). *Cost:* one line in a test.
17. **Names:** "the Ring Explorer" (made up), Hoop (the helper robot), Frosi and Clink (the aliens); no mission names ("a
    spacecraft", "scientists"). A test reads every rings word for Cassini-Huygens, Voyager, Pioneer, Huygens, Grand
    Finale, Dragonfly, NASA, ESA, JPL.
18. **Sounds:** no new audio: chimes day and night (no air: no wind); the Waltz of the Flowers (the ice turning round
    Saturn) and the Moonlight Sonata. *Cost:* a `MusicPieces` entry for a CC0 recording later.
19. **Page 39 stays empty here** (another agent's); the library fills it with empty models, `COUNT` and the next page
    move past page 40. *Cost:* none (the merge takes both pages).

## The facts (every rings fact in the game, and its check)

| Where | Words | Check |
|---|---|---|
| gravity | 0.05 (the spec's); hint "On a real ring chunk, one hop floats you away!" | a 10 m ice chunk (~470 t) pulls G·M/r² ≈ 1.3 × 10⁻⁶ m/s²; escape speed √(2GM/r) ≈ 3.5 mm/s (our arithmetic) |
| treasure | "The rings are chunks of ice and rock, from dust to house-sized." | "billions of small chunks of ice and rock … from tiny, dust-sized icy grains to chunks as big as a house" ([NASA: Saturn facts](https://science.nasa.gov/saturn/facts/)) |
| room | "The main rings are only about 10 metres thick." | "the vertical height is typically about 30 feet (10 meters) in the main rings" (NASA: Saturn facts) |
| temple | "Saturn has more than 270 moons, more than any other planet." | "As of March 2025, Saturn had 274 confirmed moons … far more than any other planet" (NASA: Saturn facts) |
| Ring Explorer | "In 2017 a spacecraft dived between Saturn and its rings 22 times." | "a total of 22 dives between the rings and the planet", April 26 - September 15, 2017 ([NASA: the Grand Finale](https://science.nasa.gov/mission/cassini/grand-finale/overview/); [JPL](https://www.jpl.nasa.gov/news/nasa-spacecraft-dives-between-saturn-and-its-rings/)) |
| geode | "Bits of the rings slowly rain down into Saturn." | "ring rain" ([NASA 2018: Saturn is losing its rings at "worst-case-scenario" rate](https://www.nasa.gov/news-release/nasa-research-reveals-saturn-is-losing-its-rings-at-worst-case-scenario-rate)) |
| Saturn scope | "Saturn is so big that about 760 Earths could fit inside it." | volume ratio 763.59 ([NASA NSSDC: Saturn fact sheet](https://nssdc.gsfc.nasa.gov/planetary/factsheet/saturnfact.html)) |
| Ring Station | "Sunlight takes about 80 minutes to get here, and 8 to reach Earth." | "it takes sunlight 80 minutes to travel from the Sun to Saturn" (NASA: Saturn facts); about 8 minutes to Earth (the Star Map's Sun card; NASA) |
| Cassini Division | "This gap is 4,700 km wide. An astronomer called Cassini saw it in 1675." | "a gap measuring 2,920 miles (4,700 kilometers) in width called the Cassini Division that separates Rings A and B" (NASA: Saturn facts); discovered by Giovanni Domenico Cassini in 1675 ([NASA](https://science.nasa.gov/resource/jean-dominique-cassini/), [ESA](https://www.esa.int/ESA_Multimedia/Images/2002/01/Giovanni_Domenico_Cassini_1625-1712), [Britannica](https://www.britannica.com/science/Cassinis-Division)) |
| C ring | "Its chunks are darker and dustier than the bright B ring's." | albedo C ring 0.12-0.30, B ring 0.4-0.6, Cassini Division 0.2-0.4 ([NSSDC: Saturnian rings fact sheet](https://nssdc.gsfc.nasa.gov/planetary/factsheet/satringfact.html)) |
| F ring | "Two shepherd moons, Prometheus and Pandora, keep it thin and twisted." | "Pandora prevents the F ring from spreading outward and Prometheus prevents it from spreading inward"; Prometheus creates its streamer-channels ([NASA: Pandora](https://science.nasa.gov/saturn/moons/pandora/); [JPL: A pair of shepherds](https://www.jpl.nasa.gov/images/pia11589-a-pair-of-shepherds/)) |
| Pan | "This little moon, shaped like a walnut, sweeps the Encke Gap clean." | walnut-shaped (an equatorial ridge), it keeps the Encke Gap open ([NASA: Pan](https://solarsystem.nasa.gov/moons/saturn-moons/pan/in-depth.amp)) |
| robot | "Saturn's rings are billions of chunks of ice, and they go all the way round Saturn!" | NASA: Saturn facts |
| robot's sample | "almost all water ice, with a little dust and rock" | "made of … ice and rock coated with other materials such as dust" (NASA); the rings are over 95 % water ice ([NASA: Cassini, rings](https://science.nasa.gov/mission/cassini/science/rings/)) |
| robot's questions | ice and rock; the Cassini Division is a gap; Pan keeps the Encke Gap clear | as above |
| Frosi's science | "Saturn's moon Enceladus sprays water from an ocean under its ice. Scientists want to look for life there." | a global ocean under its crust, plumes of water spraying into space, "a promising lead in our search for worlds where life could exist" ([NASA: Enceladus](https://science.nasa.gov/mission/cassini/science/enceladus/)); always with CreatureWords.HONEST |
| hints | "Saturn's rings are mostly water ice." "The Cassini Division is a wide gap in the rings." "Look north: Saturn is huge from its rings!" | NASA as above; Saturn's size from the rings: 2 × asin(60,268 ÷ 105,000) ≈ 70° (our arithmetic, NSSDC's radius) |
| sky | the Sun 0.1 × | Saturn at 9.5 AU (NASA): 1 ÷ 9.54 = 0.105 |
| sky | Saturn's shadow on the rings, the rings' shadow on Saturn | NASA images ([Saturn's shadow upon the rings](https://www.jpl.nasa.gov/images/pia02285-saturns-shadow-upon-the-rings/); [Saturn's ring shadow](https://science.nasa.gov/resource/saturns-ring-shadow-then-and-now/)) |
| mission | "1.2 to 1.7 billion km away", "about 6 years" | as Titan's row (the same trip to Saturn: a Hohmann transfer ~6 years) |
| mission | 9.4 + 7.3 + 0.6 + 2.7 km/s | to Saturn ~7.3 (as Titan's); the capture burn at Saturn in 2004 was 626 m/s ([NASA: the week of 25 June 2004](https://science.nasa.gov/solar-system/significant-event-report-for-week-ending-6252004/)); aerobraking first done at Venus in 1993, then at Mars, with solar panels as drag surfaces ([JPL: the mission that proved aerobraking works](https://www.jpl.nasa.gov/images/slice-of-history-the-mission-that-proved-aerobraking-works/); [JPL: Mars Global Surveyor completes aerobraking](https://www.jpl.nasa.gov/news/mars-global-surveyor-successfully-completes-aerobraking/)); the last leg our orbital mechanics: GM = 37,931,187 km³/s², at r = 105,000 km v_circle = 19.0 km/s; an orbit from Saturn's upper air (61,500 km) up to the rings is 16.3 km/s there: 2.7; from an orbit reaching Titan (1,221,870 km) it would be 25.8 − 19.0 = 6.8 |
| mission | "The ring chunks race round Saturn at about 20 km every second" | C ring 23.6 km/s, A ring 16.3 km/s ([NASA Space Math: orbit speeds of Saturn's rings](https://spacemath.gsfc.nasa.gov/weekly/10Page28.pdf)); the B ring (92,000-117,500 km) 20.3-18.0 by √(GM/r) |

(The Star Map's own three Saturn facts are the lead's, in `core/rules/star_map.gd`; unchanged.)

## Tests (RED → GREEN)

| Test file | Tests | RED (why it failed first) |
|---|---|---|
| `tests/unit/test_rings_blocks.gd` | 9 | `BlockIds.RING_CRYSTAL` …, `RingsBlocks` not declared — run and seen |
| `tests/unit/test_rings_shape.gd` | 14 | `SpaceShape.RINGS` not found — run and seen; then: the B ring too sparse (13 % big chunks: cells 32 and a wobble only inwards, 20 %), a pairwise "hop" check that was wrong (the fixed chunks' hops now), the station's window in the test |
| `tests/unit/test_rings_generator.gd` | 6 | written with `_generate_rings` |
| `tests/unit/test_rings_secrets.gd` | 9 | written with the palette and the Ring Explorer |
| `tests/unit/test_rings_universe.gd` | 15 | the descriptor missing; then the mission's need (24.1 → 20.0, ruling 10), the honest hint |
| `tests/integration/test_rings_sky.gd` | 4 | the rings' line out past the globe read off the picture (the globe filled the quad: `ring_edge` now uses a ringed planet's 0.3) |
| `tests/integration/test_rings_sights.gd` | 5 | written with the descriptor |
| `tests/integration/test_rings_world.gd` | 6 | written with the descriptor (the pad, the chunk, open space under it, the scope; save, load, mesh; a real fall caught by the suit's jets: 4.9 s) |
| `tests/integration/test_robot_creatures.gd` | +1 | the rings' robots on the landing chunk, the camp on its chunk, the rover over open space |
| shared (see above) | | WORLDS, warm_space and space_available lists, COUNT and the next page, the pages' budget, the camps, the missions, the Cassini Division's name |

## Measurements

Generator bench (`bench_generator.gd -- --space moon venus rings`, the PC's load 12-15 on 24 cores: another suite and app):

| chunks | Meadows avg ms | Moon | Venus | Rings |
|---|---|---|---|---|
| cold (fresh generators, a stack's chunks in a row): surface | 1.67-1.87 | 1.99 (worst 20.3) | 0.62 (worst 6.9) | **0.20** (worst 1.6) |
| cold: underground | 1.29-1.47 | 0.33 | 0.28 | **0.03** |
| cold: sky | 0.81-0.94 | 0.01 | 0.05 | **0.01** |
| cold: all | 1.43-1.61 | 1.13 | 0.43 | **0.12** (9 × cheaper than the Moon's) |
| warm (stacks cached): all | 1.30-1.44 | 0.86 | 0.14 | **0.04** |
| a new area's secrets (once, then cached) | — | 0.61 (worst 1.41) | 0.84 (worst 2.65) | **0.87 (worst 2.82)** |

The rings' parts (`BENCH_RINGS_<PART>`, fresh generators over 4 × 4 whole chunk stacks, y -64..159, against the meadows on
the same chunks): the landing chunk 0.20 ms a surface chunk vs 1.64, the B ring 0.20 vs 1.32, the C ring 0.15 vs 1.26,
the Cassini Division 0.13 vs 1.67, Pan 0.16 vs 1.75, the F ring 0.23 vs 1.67, open space 0.04 vs 1.67; sky chunks
0.00-0.01; underground 0.01-0.10. Meshing is not benched here: floating chunks have more faces per block than a flat
ground (their undersides and sides), but 85 % of the columns are open space with nothing to mesh (the emulator check is
the lead's). Saturn's picture: 192 px in ~19 ms (once, at a world's load). The aliens' site search: 2.3-2.9 ms.

Geography (`RingsTerrain`, printed by a scratch test):

| seed | mirrored | pad | camp site | Theater | Tilly | Totem | Ring Explorer | Pan |
|---|---|---|---|---|---|---|---|---|
| 12345 | no | (40, 24) | (71.5, 37.5): 34 | (9, 37) | (45.5, 35.5) | (52.5, 40.5) | (46, 74): 50 | (58, 322) |
| 77 | no | (40, 24) | (71.5, 37.5): 34 | (9, 37) | (28.5, 27.5) | (52.5, 40.5) | (46, 74): 50 | (58, 322) |
| 777 | no | (40, 24) | (71.5, 37.5): 34 | (9, 37) | (45.5, 35.5) | (52.5, 40.5) | (46, 74): 50 | (58, 322) |
| 42 | yes | (40, 24) | (9.5, 37.5): 33 | (71, 37) | (38.5, 36.5) | (60.5, 27.5) | (34, 74): 50 | (22, 322) |

Over 1200 × 720 blocks from the C ring to the F ring: open space 85.3 %, big ice chunks 9.9 %, big dusty chunks 1.0 %,
ice lumps 2.2 %, dusty lumps 1.1 %, rock lumps 0.4 %, Pan and its ridge the rest. The bands' ground (solid, big chunks):
the B ring 23 % / 20 %, the A ring 21 % / 16 %, the C ring 12 % / 6 %, the Cassini Division 4 % / 0, the Encke Gap 0 (but
Pan), beyond the F ring and north of the C ring 0. 416 big chunks in 1280 × 832 blocks, mean radius 9.1. Secrets in the
10 × 10 areas round the spawn: 39-50 treasures, 8-19 hidden rooms, 8-10 stations, 16-24 geodes, one Ring Explorer.

## Smoke run

- `tools/rings_smoke.gd` (through `tools/smoke_all.sh rings`: a private folder with "smoke" in its path and a copy of
  `profile.json`): **53 checks, 0 fails** (exit 0, 51 s): a new Green Meadows Sandbox world; the Star Map; Saturn's card
  (3 facts, "Saturn's rings: LAND"); the rings' own world `sandbox_25`, its terrain, gravity 0.05, space's black sky, the
  Sun 0.1 ×, the Sun in the east, stars, never the photo sky, Saturn huge (608-block quad) over the northern horizon, on
  the landing pad, peaceful, no animals, MY MAP's pad and six sights, the Space Book's LANDED mark, the sights watched, no
  geysers, no lightning, a void world, the robots and the aliens' camp on its own chunk; the portal home by the pad; the
  Saturn scope by the pad; a real fall off the landing chunk into open space (a 4.9 s float down to y 50.0) caught by the
  suit's jets, back on the ice where it stood, "Pfff! Your space suit's little jets flew you back to the ice."; the Ring
  Explorer is the landmark and walking into it finds it, then MY MAP shows it; the six sights say their facts; nothing hurt
  the child (health 20 all along); through the portal home: Green Meadows `sandbox_1`, on the take-off column, home
  gravity, home's own sky. A first run found the card's hills too low for the picture's polygon ("triangulation failed"):
  the rings' card now has a band of far ice (0.18).

## Pictures (`tools/space_shots.gd -- --universe=25 --sights`, windowed, both styles)

Seen: from over the pad, a black starry sky; north, Saturn enormous over the horizon, pale gold with tan belts, the rings
a thin bright line across its middle with a dark band of their shadow under it and Saturn's shadow cutting the line just
past its right edge; the ring plane's chunks in front of it, near ones white and frosty, far ones dark silhouettes against
its globe. East, south and west: white chunks of every size floating at different heights to the horizon, rough round
undersides in shade, pebbles and brown rock lumps between them; the landing chunk with the pad (its teal and gold star),
the white Ring Station with its dish, the Saturn model; the Theater on the show chunk. The sights:
the Cassini Division's beacon on the edge chunk with the few darker lumps of the gap and the A ring beyond; the C ring's
tan dusty chunks with Saturn huge behind them; the F ring's two strands of little lumps; Pan, a round dome of pale ice with
its dusty ridge and a teal beacon, the Encke Gap clear round it. Night: the same with Saturn still glowing. REALISTIC looks
close to BLOCKY at 640 × 360 (textured ice and panels).

## Full suite

`tests/run_tests.sh` (2026-09-30 15:24-16:15, the PC's load 10-15 with another suite running, on the code of commit
34c5ebf1): **967 scripts, 8787 tests, 8784 passing, 1 failing, 2 risky** (`test_meadows_biome_generator.gd`'s two that
never assert, as before this work), no script errors (2986 s). The one failing:
- `tests/integration/test_world_sync.gd` `test_edits_from_an_earlier_session_reach_the_guest_by_a_diff` ("the save kept
  the house"): the known load flake of this file (the crew agent saw it 1 run in 4 on `lead-merge`, the New Seven's agent
  twice under load). Rerun alone under load it failed in some runs; once the load dropped it passed 4 of 4 alone and the
  whole file 10 of 10. The save itself takes ~10 ms at `BlockIds.COUNT` 704 or 672 (measured in a scratch test); on the
  base commit 3ccc5e5b it passed 7 of 7 alone at a lower load. Not this work's: the lead may watch it on `lead-merge`.

After the full suite, the neighbours' smokes (`tools/smoke_all.sh rings venus dragon space titan`): `rings` 53 checks, 0
fails; `venus`, `space`, `titan` PASS; `dragon` failed twice under load (the smoke's own race: "a far teleport landed
before its collision", the wind caught the child at the nest, and the push off the island then landed on the nest's
blocks), then PASSED on this branch (seed 3419418653) and on the base commit: not this work's.

## The lead's checklist (emulator, both styles)

1. Sandbox, Green Meadows: fly up; on the Star Map tap Saturn: MISSION until the Mission to Saturn's rings is flown (or
   "Saturn's rings: LAND" after a landing); the loading card shows the rings' picture (huge Saturn with its line, the far
   Sun, chunks, the buddy by the Ring Station) and a rings hint. The Mission Board lists the Mission to Saturn's rings
   (20.0 km/s, about 6 years, no heat shield or parachute); the flight lands on the landing chunk's pad.
2. **Performance** (≥ 30 FPS, no frame over 100 ms): the autopilot with `--universe=25`, both styles; the chunks are many
   floating blobs (their meshes' faces), and Saturn's 192 px picture is made at the world's load.
3. **The feel of 0.05 gravity:** jumps ~15 s long, a fall between the chunks a ~5 s float before the jets: fun or too slow?
   (`gravity` in `rings.gd`, `LIFT_Y` in `RingsTerrain`). Pan's dome's steps are slow hops (ruling 4).
4. **Saturn in the sky on a phone:** its size (~77°), its place (north, on the horizon), the rings' line and the shadows;
   at LOW view distance the far chunks.
5. The Ring Station, the Saturn model, the scope, the beacons; the Ring Explorer (its door, the chest, the dish).
6. The aliens' camp on its chunk, Hoop by the pad, the rover hovering over gaps, the Theater on the show chunk, Tilly and
   the Totem on the landing chunk (Survivor).
7. Survivor: the bag goes to the rings and home; Tilly's ring things; a gift or showcase holding a rings block.
8. Page 40's first frames compile its materials (like any new universe). The pages' budget (ruling 11): 64 MB is a choice
   for the lead.

## Next (the game never ends)

Ring dust glittering between the chunks (a cheap particle cloud round the child), Saturn's shadow sweeping over the chunks
at night, propellers (little moonlets' wakes in the A ring) and the B ring's spokes, the chunks drifting and bumping
slowly, ring rain falling towards Saturn, Enceladus's plumes as their own world, Mimas's giant crater, the Encke Gap's
wavy edges (Daphnis's waves in the Keeler Gap), a Planet Book page for Saturn, a gentler step hop in very low gravity.
