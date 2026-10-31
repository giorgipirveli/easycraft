# Cosmos: Venus's cloud city, world 24 (spec §21b.2)

The owner: "add cosmos, stars and planets where is planet is different universe" (#72) and "make the universies closer to
real worlds so player start learning real things" (#74). Brief: `docs/superpowers/plans/2026-09-29-cosmos-planet-brief.md`
with BODY = Venus's cloud city, WORLD = 24, PAGE = 38, IDS = 656-671. The lead's ideas: Venus's surface is hotter than an
oven (465 °C) and crushed by its air, but about 50 km up the air is Earth-like: a floating cloud city over yellow clouds
(a real scientists' idea), lightning far below; floating platforms joined by bridges with gardens and homes, a balloon
or airship dock, yellow sulfuric-acid clouds far below that a child can never fall into (a kind net or a gentle lift),
the Sun rising in the west and a day longer than a year, facts at sights, a landmark (a research blimp, no mission
names); gravity 0.9, every step climbable; the acid clouds a fact, never a danger; robots and aliens through the same
registry; a mission to Venus. Built by a worker agent in its own worktree (branch `worktree-agent-afd7e770d8aeb8226`,
reset to `lead-merge` 1d4ff0af first), without the editor, the emulator or adb (two windowed runs of
`tools/space_shots.gd` for pictures).

## Allocations (used; nothing else touched)

| What | Allocated | Used | Free |
|---|---|---|---|
| World number | 24 (`SpaceRules.VENUS`, already in `SpaceRules` and the Star Map) | Venus's cloud city | |
| Block ids, page 38 (`VenusBlocks`) | 656-671 | 656-671 (all 16) | none |
| `BlockIds.COUNT` | 624 → 672 (624-655 are the New Seven Wonders' pages 36-37, another agent's) | | |
| `BlockIds.NEXT_PAGE_FIRST_ID` | 624 → 672 (page 39 is the next) | | |
| Atlas page | 38 (`data/blocks/pages/venus*.png`) | rows 0-2 | rows 3-7 |
| Item ids, animals, HUD spots | none | | |
| Server module | unchanged (0.2.15 already lets blocks up to 1023 travel in gifts) | | |

## What a child sees on Venus

1. **Getting there:** fly up above any world (or fly the Mission to Venus); the Star Map opens; Venus's card (the lead's
   three facts: the hottest planet, about 465 °C; thick yellow clouds of acid; it spins backwards) says **LAND** once the
   mission is flown (or Venus was landed on before), else **MISSION**.
2. **Landing:** "You landed on Venus's cloud city! Far below, the clouds hide ground hotter than an oven." on the landing
   pad in the middle of a wide cream deck (radius 20) with white lamp posts on its rim; the golden portal home three
   steps away; Nimbus the helper robot, the rover and the drone by the pad; the Space Book marks Venus landed on.
3. **The sky:** a hazy golden sky of its own (thick air: never space's black, never Earth's photo sky, in both styles)
   fading to a pale horizon, a warm yellow haze far away, a peach glow at sunrise and sunset; the Sun a little bigger
   than at home (1.4 ×) and **rising in the west**, setting in the east (the lookout's telescope looks at the sunrise);
   Earth and our Moon as two tiny points, no moon disc at night (Venus has none); stars at night. A gentle wind by day,
   chimes at night; Für Elise by day, Air on the G String at night. No animals, no monsters.
4. **The city:** round platforms all at one deck height, each on a big silvery **float hull** (a round underside, deepest
   in its middle: the platforms float because they are full of the air we breathe), a white frame rim, joined by
   **bridges** of honey planks on a white keel with lamp posts along their edges. Round the landing deck, a ring of seven:
   the **airship dock** (north, or south in a mirrored city) with its mooring mast and the Research Blimp beside it; the
   **aliens' camp deck** (Nubi the explorer, Brezz the trader and their little ship); the **show deck** (the Shorts
   Theater); the **cloud homes** (four little domed homes with peach walls, round windows of glass and teal, pink, sky
   and yellow domes with a lamp on top, their doors toward a square); the **sky garden** (green turf, flowers, little
   trees from Earth, a pond with a lamp fountain); the **west lookout** (a brass telescope at its west edge) and the
   **orchard** (turf and trees). A promenade of bridges joins the ring's neighbours (the south stays open: the view of the
   cloud sea and the Sun at noon). Further out, eight groves and plazas (~100 blocks) joined round and to the ring; far
   out, isles every ~96 blocks joined by bridges to their neighbours.
5. **The clouds far below:** 40-50 blocks under the decks, a sea of lumpy pale-yellow cloud tops over deeper ochre
   clouds, fading into the haze. **Soft lightning** now and then deep in them, 26-70 blocks away: a silent zig-zag bolt,
   a flicker, gone.
6. **Stepping off:** walk off a deck or a bridge and the child falls ~24 blocks, then "Whoosh! A warm breeze lifted you
   back up to the city." and stands where it last stood; never down into the clouds, never hurt, nothing lost. The rover
   never drives down into the clouds.
7. **Jumping:** gravity 0.9 (real: 8.87 m/s²): a jump reaches ~1.9 blocks (1.7 at home); every deck, bridge and gangway is
   at one height, the homes' doors and the dock's plinth one step.
8. **The Research Blimp** (the landmark, ~64 blocks from the pad, beyond the dock): a gangway of bridge planks from the
   dock's rim to its gondola (white walls with round blue windows, lamps at its roof's corners and in its ceiling, the
   golden chest inside), two struts up to its long white envelope (25 long, a teal stripe along each side, solar film
   along its back, a lamp on its nose, teal tail fins). Walking into the gondola: "You found the Research Blimp! In 1985
   two robot balloons floated in Venus's clouds for two days."
9. **Sights** (MY MAP shows all five from the landing; the planet guide's checklist lists them; Nimbus points at them):
   the **cloud scope** at the landing deck's rim (18 from the pad, the open side), the **airship dock** (by the mooring
   mast), the **sky garden** (round its pond), the **cloud homes** (their square), the **west lookout** (its telescope).
10. **Secrets** (the Secret Book counts them): buried treasure under an X of glowing cloud crystals in a deck, a hidden
    room in a float hull behind a fake hull door (stairs up through the hull to the deck), the explorers' station (the
    puzzle temple in home panels with cloud lamps and star gold: friendly and made up), cloud crystal geodes inside the
    hulls. Every one on a platform (never a bridge or the clouds, never the camp or show deck, clear of the built parts).
11. **Tilly** (Survivor) sells the city's decks, hulls, turf, bridge planks, lamps, frames, home panels, the blimp's skin,
    stripe, gondola and solar film, cloud crystals, telescopes, the clouds and the landing pad at home prices; never star
    gold or the fake door.
12. **Nothing hurts:** the acid clouds and the heat far below are facts to learn; no word says anything hurts, burns, is
    dangerous or scary (`test_the_clouds_and_the_heat_are_facts_never_a_danger`); the smoke checks the hearts.
13. **Home:** walk into the portal or fly up and tap HOME: back on the take-off column, home's Sun rising in the east.

## How it plugs in

- **New files:** `world/universes/venus.gd` (the descriptor), `world/universes/venus_blocks.gd` (page 38),
  `world/generators/venus_terrain.gd` (`VenusTerrain`: the city as pure rules), `world/venus_lightning.gd`
  (`VenusLightning`), `data/blocks/pages/venus{,_albedo,_normal}.png` (+ imports), `tools/venus_smoke.gd`,
  `tools/venus_smoke_steps.gd`, tests (below).
- **Shared, small and additive:** `data/blocks/block_ids.gd` (ids, names, `SPACE_GROUND`, `COUNT` 672,
  `NEXT_PAGE_FIRST_ID` 672), `world/block_library.gd` (one register line), `world/generators/space_shape.gd` (planet
  `VENUS`: a branch per method, `venus_columns`, `venus_kind`; `is_river` true over the clouds and on bridges),
  `world/generators/space_generator.gd` (`_venus_stack`, `_generate_venus`, `_place_venus_features`; the city's built parts
  in the reference; no ores without rock), `world/generators/space_secret_rules.gd` (Venus's palette, `ATTEMPTS_VENUS`,
  `_hull_room`, `_cloud_geode`, `_research_blimp`, `_fits` through `VenusTerrain.holds`), `core/rules/dragon_rules.gd`
  (`rescue_y`, `carried_back_words`, a line for `fell_into_void`, `is_safe_spot`, `SafeSpot.note`),
  `entities/player/player.gd` (`_void_line`), `world/void_watch.gd` (`line`), `scenes/sandbox.gd` (the void's line and
  words, `sky.sun_west`, `_space_lightning`), `world/sky_cycle.gd` (`sun_west`; the low Sun's disc, ruling 16),
  `core/rules/day_cycle.gd` (`backwards`), `world/universes/universe_registry.gd` (`SPACE[24]`, `sun_rises_west`),
  `core/rules/space_rules.gd` (`WORLDS` has 24), `core/creatures/alien_rules.gd` (the camp deck; `_good` looks at the
  cheaper things first), `core/creatures/creature_words.gd` (Nimbus, Nubi, Brezz, three souvenirs),
  `core/magic/mini_rules.gd` (`alien_nubi`), `entities/robot/space_creatures.gd` (the rover's ground),
  `core/rules/theater_site.gd` (the show deck), `core/rules/mission_rules.gd` (the Venus row),
  `entities/flight/flight_plan.gd` (Venus's trip: about 5 months), `entities/flight/flight_looks.gd` (`SUN_SIZE`),
  the natural-block lists (`bot_rules`, `surprise_rules`, `capture_rules`, `gather_rules`, `chat_commands`,
  `secret_rules.is_fake_wall`), `ui/universe/universe_art.gd` (Venus's card), `core/rules/loading_hints.gd` (seven Venus
  hints), `tools/make_space_atlas.gd` (`-- venus`), `tools/make_space_realistic.py` (`venus`), `tools/bench_generator.gd`
  (`BENCH_VENUS_<LANDING|HOMES|GARDEN|ISLE|OPEN>`), `docs/DEVELOPMENT.md`, spec §21b.2 ("As built"),
  `docs/devlog/parts/missions.md` (the Venus row), `assets/CREDITS.md`.
- **Not touched:** the School, the Science Lab, `ui/space/*` (the Star Map UI), `StarMap`, the colonies, the server, the
  other worlds' files.
- **Shared tests updated:** `test_space_rules` (WORLDS), `test_space_registry` (warm_space, space_available),
  `test_planet_universes` (space_available), `test_realistic_pack` (VenusBlocks.FILES), `test_block_id_space` (672, page
  39), `test_block_pages` (page 38 is 656), `test_prospect_blocks` (COUNT past the riches' page, no longer equal),
  `test_page_sizes` (the budget, ruling 14), `test_space_shape` (Venus's clouds and bridges are no dry land),
  `test_robot_words` (the camps), `test_mission_rules` (the missions' order), `test_shader_warmup_sources` (COVERED:
  `world/venus_lightning.gd`), `test_dragon_rules` (+1: a world's own line), `test_robot_creatures` (+1: Venus's robots
  and camp). The shared planet tests (`test_space_shape`, `test_space_secrets`, `test_space_generator`, `test_alien_rules`)
  now also run for Venus (it is in `SpaceShape.PLANETS`).

## Rulings (decided on the owner's behalf; cost if wrong)

1. **The city is a planet kind of `SpaceShape`, laid out by `VenusTerrain`** (the other planets' ruling 1): a fixed city
   (the landing deck, a ring of seven, an outer ring of eight) mirrored north-south by the seed, and isles drawn per
   96-block cell far out. Every city is the same city (the seed moves the outer ring and the isles a little and mirrors
   it). *Cost:* a seeded layout of the ring is a table in `VenusTerrain.RING`.
2. **Every deck and bridge is at one height (`DECK_Y` 80):** never a step between two platforms, so a walk anywhere is
   level (gravity 0.9 climbs one block, but a child never needs to); the height comes from the hulls, the homes, the
   mast and the blimp. *Cost:* stepped bridges between decks at different heights need a stair rule and the step tests.
3. **"Never fall into the clouds" is a warm breeze, not a net:** the Dragon Realm's void (owner #39: a faller is carried
   back to the last spot it stood on; no damage, nothing lost) with a line of its own (`void_y` = `LIFT_Y` 56, far over the
   clouds' tops, which never reach 42, and 24 under the decks: a real fall, then the breeze) and words of its own. A net
   over the whole world would be a grid over the clouds everywhere; the breeze keeps the cloud sea clear. The clouds are
   solid blocks (never reached). *Cost:* a net is one more block layer over the clouds and the same line.
4. **The clouds and the bridges are "no dry land" for spawners (`is_river`):** Tilly, the Totem, the Theater, secrets and
   the aliens keep to the platforms (the Titan precedent). *Cost:* none.
5. **The aliens camp on their own deck and the Theater stands on its own deck** (`AlienRules.safe_ground`,
   `TheaterSite.on_colony`): the ring leaves room for both, so neither lands on the homes or the gardens. *Cost:* two lines.
6. **The decks, hulls and turf are the world's ground** for the natural lists (bots build on them, a meteor may land on
   them, the wand never wakes them); the built blocks (bridges, lamps, frames, homes, the blimp, telescopes) are not.
   *Cost:* one list line.
7. **No ores:** the clouds hold no rock (`rock_ids` empty; `_place_space_ores` returns at once). *Cost:* ores in the hulls
   would be one list.
8. **Secrets are drawn onto the platforms** (`secret_spot`: a platform whose middle is in the area) and held by them
   (`holds`: every box over a deck, a hull reaching under what goes into a deck, clear of the built parts); the big ones
   first (`ATTEMPTS_VENUS`); a hidden room is 6 under the deck (a hull is not as deep as a hill: `_hull_room`) and a geode
   sits in a hull under the deck (never deep down: nothing to dig through but clouds). *Cost:* constants.
9. **The Research Blimp is moored at the dock** (not placed like the other landmarks, 44-56 from the pad in a drawn
   direction): its gondola's floor at deck height beyond the dock's rim, the gangway level; the city's spawn (40, 88) or
   (40, 40) keeps the whole blimp inside one secrets area. *Cost:* the landmark's place is the dock's.
10. **The Sun rises in the west but the game's day keeps its length:** a real Venus day (117 Earth days from sunrise to
    sunrise) would be all day or all night for a child's visit; the words say how long it really is (243 days to spin
    once, longer than its 225-day year). `DayCycle.backwards` mirrors the Sun's and the Moon's paths east-west (the
    noon Sun still leans south). *Cost:* a slower day is one `SurvivorGames.clock_speed`-like factor.
11. **Its sky:** thick air: a sky of its own (`space_sky` 0, `photo_sky` false) in golden haze; the Sun 1.4 × (1 ÷ 0.72
    AU); Earth and our Moon as tiny points and no moon disc (Venus has none); stars at night (the upper haze would hide
    them: *cost*: a `stars` field in `SkyCycle`). About 50-55 km up the city is inside Venus's cloud layers: the game
    shows the lower clouds below and a haze above.
12. **Lightning is a sight to wonder at, never a danger:** silent (no thunder: scary for the youngest), far (26-70
    blocks), deep in the clouds, never under a deck; drawn with the stars' material settings (no new shader). Real
    spacecraft recorded radio bursts that may come from lightning in Venus's clouds; later measurements question
    it, so no word in the game says there is lightning for sure. *Cost:* a soft rumble is one `Audio.play`.
13. **The Mission to Venus: 9.4 + 3.5 + 0.5 = 13.4 km/s** (the cheapest mission: Venus's thick air does the braking with a
    heat shield and a parachute; the last 0.5 is an estimate for the clean-up burns and the gentle arrival at the floating
    pad), about 5 months (146 days: the Hohmann trip), `air` true. The flight's trip words say the same (they said "about
    4 months": real probes took 3½-5 months). *Cost:* data.
14. **The realistic pages' budget rose from 54 to 60 MB** (`test_page_sizes.gd`): Venus's page brought them to 54.9 MB,
    and the New Seven Wonders' pages 36-37 are coming (another agent). *Cost:* the APK grows ~1.6 MB a page.
15. **The rover keeps its height over a gap** (its ground is NAN over the clouds: `SpaceCreatures._rover_ground`): it never
    drives down into the clouds between two decks. *Cost:* none.
16. **The low Sun's disc stays out of the painted sky** (every world): the procedural sky draws the Sun's disc in its
    light's colour × energy, and near the horizon that light fades to nothing, so at dawn and dusk the disc was a dark blot
    on the twilight sky (never seen before: the pictures' sunset looks east, away from the Sun at home; on Venus the Sun
    sets in the east). The disc is drawn only while the light is full (`sun.sky_mode`). *Cost:* the disc pops in at
    ~14° over the horizon; a fading disc would need its own sky shader.
17. **Names:** "the Research Blimp" (made up, named by no mission), Nimbus (the helper robot), Nubi and Brezz (the aliens);
    no mission names: "robot balloons", "spacecraft", "scientists". A test reads every Venus word for HAVOC, Vega, Venera,
    Magellan, Pioneer, Mariner, Akatsuki, Venus Express, DAVINCI, VERITAS, EnVision, NASA, ESA, JAXA, JPL and Parker.
18. **Sounds:** no new audio. The wind by day (the city rides Venus's winds), chimes at night; Für Elise and Air on the G
    String. *Cost:* a `MusicPieces` entry for a CC0 recording later.
19. **Friendly words:** "hotter than an oven" and "sulfuric acid" are facts; no word says anything hurts, burns, is
    dangerous or scary, and no hint says "it can't hurt you" (that would put the idea there).

## The facts (every Venus fact in the game, and its check)

| Where | Words | Check |
|---|---|---|
| gravity | 0.9 | 8.87 m/s² ÷ 9.81 = 0.903 ([NASA NSSDC: Venus fact sheet](https://nssdc.gsfc.nasa.gov/planetary/factsheet/venusfact.html)) |
| landing, room | "hotter than an oven", "about 465 °C" | mean 464 °C (NSSDC); "about 872 degrees Fahrenheit (467 Celsius)" ([NASA: Venus facts](https://science.nasa.gov/venus/venus-facts/)); the Star Map's card says 465; a kitchen oven reaches ~250-290 °C |
| treasure | "Venus is almost as big as Earth: it is called Earth's twin." | "nearly as big around as Earth ... 12,104 kilometers ... versus 12,756 kilometers for Earth" (NASA Venus facts); "Venus: Earth's Cloudy Twin" ([NASA APOD](https://science.nasa.gov/image-article/apod-1996-september-23-venus-earths-cloudy-twin/)) |
| station | "Venus is the hottest planet, though Mercury is closer to the Sun." | "Venus – not Mercury – is the hottest planet in our solar system" ([NASA: Temperatures across our solar system](https://science.nasa.gov/solar-system/temperatures-across-our-solar-system/)) |
| Research Blimp | "In 1985 two robot balloons floated in Venus's clouds for two days." | two balloons floated for about 46-48 hours at about 54 km in 1985 ([JPL: Venus balloons overview](https://www2.jpl.nasa.gov/adv_tech/balloons/venus_overview.htm)) |
| geode | "Venus's cloud tops race round the planet in about 4 Earth days." | the cloud tops circle Venus every four Earth days (Venus Express; [Wikipedia: atmospheric super-rotation](https://en.wikipedia.org/wiki/Atmospheric_super-rotation)) |
| cloud scope | "The yellow clouds far below are made of tiny drops of sulfuric acid." | "clouds of sulfuric acid" (NASA Venus facts) |
| airship dock | "Here a balloon full of the air we breathe floats: Venus's air is heavier." | "above the haze layer, where breathable air (20% oxygen, 70% nitrogen) is a lifting gas" ([NASA Langley: HAVOC proofs of concept, NTRS 20160006580](https://ntrs.nasa.gov/api/citations/20160006580/downloads/20160006580.pdf)); Venus's air is 96.5 % carbon dioxide (NSSDC) |
| sky garden | "About 50 km up, Venus's air presses as gently as the air at home." | 106,679 Pa (1.05 atm) at 50 km (HAVOC; [IEEE Spectrum](https://spectrum.ieee.org/nasa-study-proposes-airships-cloud-cities-for-venus-exploration)); "the pressure is similar to Earth's surface" ([NASA Astrobiology](https://astrobiology.nasa.gov/news/could-dark-streaks-in-venus-clouds-be-microbial-life/)) |
| cloud homes | "A day on Venus lasts longer than its year: 243 Earth days, not 225." | "243 Earth days long — longer even than a Venus year ... 225 Earth days" (NASA Venus facts) |
| west lookout, hint | "Venus spins backwards, so here the Sun rises in the west." | "the Sun would rise in the west and set in the east, because Venus spins backward" (NASA Venus facts) |
| hint | "On Venus you weigh almost what you weigh at home." | 0.9 (NSSDC) |
| hint | "Venus has no moon at all." | "one of only two planets in our solar system that doesn't have a moon" (NASA Venus facts) |
| robot | "Our city floats about 50 km up in Venus's sky!" | the cloud-city idea floats airships at about 50 km (HAVOC) |
| robot's sample | "a jar of Venus air! It is mostly carbon dioxide, much heavier than the air we breathe." | 96.5 % carbon dioxide (NSSDC); carbon dioxide weighs 44 g a mole, our air ~29 |
| robot's questions | the Sun rises in the west; the clouds are tiny drops of sulfuric acid; the air we breathe floats in Venus's heavy air | as above |
| Nubi's science | "Some scientists wonder if tiny living things could float in Venus's clouds, high up where it is cooler." | "In a region beginning around 50 kilometers in altitude ... the temperature ranges between 30ºC and 70ºC ... Life could potentially survive in this zone" (NASA Astrobiology); always with CreatureWords.HONEST |
| mission | "38 to 261 million km away", "Venus comes closer to Earth than any other planet" | nearest ~38 million km, farthest ~261 million km, "the closest that any planet comes to Earth" ([Space.com: how far away is Venus](https://www.space.com/18529-distance-to-venus.html)) |
| mission | 9.4 + 3.5 + 0.5 km/s, "about 5 months" (146 days) | LEO → Venus Hohmann transfer Δv 3.5 km/s, 4.8 months ([Wikipedia: Delta-v budget](https://en.wikipedia.org/wiki/Delta-v_budget)); surface → low Earth orbit ~9.4 as the other missions; aerocapture and entry with a heat shield and a parachute, a small clean-up burn (HAVOC); the last 0.5 is our estimate |
| sky | the Sun 1.4 times as big | Venus at 0.72 AU (NASA Venus facts): 1 ÷ 0.723 = 1.38 |
| lightning (no words) | soft flashes far below | radio "whistler" bursts in Venus's ionosphere read as lightning ([Nature, 2007](https://www.nature.com/articles/nature05930); [ESA](https://www.esa.int/ESA_Multimedia/Images/2007/11/Venus_Express_detects_evidence_of_lightning)); a later measurement questions one of them ([Eos](https://eos.org/articles/lightning-struck-down-as-source-of-a-venus-whistler)): no word in the game claims it |

(The Star Map's own three Venus facts are the lead's, in `core/rules/star_map.gd`; unchanged.)

## Tests (RED → GREEN)

| Test file | Tests | RED (why it failed first) |
|---|---|---|
| `tests/unit/test_venus_blocks.gd` | 9 | `BlockIds.CLOUD_LAMP` …, `VenusBlocks` not declared — run and seen; then the page budget (54.9 MB over 54: ruling 14), the riches' page's exact COUNT |
| `tests/unit/test_venus_shape.gd` | 16 | written with `VenusTerrain`; first run: the cloud scope's tube not over the rim (moved to 19), a type in the test |
| `tests/unit/test_venus_generator.gd` | 6 | a lamp missing in the fast path (a feature looked only at the bridges touching its own column: `FEATURE_LOOK`), a landing hull reaching under y 64 (the test's open air moved to the open side) |
| `tests/unit/test_venus_secrets.gd` | 9 | no rooms (a hill's room is 9 deep: `_hull_room`), few temples and geodes (`ATTEMPTS_VENUS`, the spots nearer a hull's middle); the test's own box check (per box, not the bounds) |
| `tests/unit/test_venus_universe.gd` | 15 | `UniverseRegistry.sun_rises_west` not found — run and seen |
| `tests/unit/test_venus_lightning.gd` | 4 | written with `VenusLightning` |
| `tests/integration/test_venus_sky.gd` | 6 | the helper's light direction (the light shines along its −z); the low Sun's dark disc (ruling 16) |
| `tests/integration/test_venus_sights.gd` | 5 | written with the descriptor |
| `tests/integration/test_venus_world.gd` | 6 | written with the descriptor (the pad, the deck, the hull, the clouds, the scope; save, load, mesh; a real fall caught by the breeze) |
| `tests/unit/test_dragon_rules.gd` | +1 | `DragonRules.rescue_y` not found — run and seen |
| `tests/integration/test_robot_creatures.gd` | +1 | the aliens' site search took 600-680 ms on Venus (`_good` looked at every feature first; the camp deck first now: ~20 ms) |
| shared (see above) | | WORLDS, warm_space and space_available lists, COUNT and the next page, the pages' budget, the camps, the missions |

## Measurements

Generator bench (`bench_generator.gd -- --space moon venus`, 640 chunks per planet alternating with Green Meadows; the
PC's load 5-7 on 24 cores):

| chunks | Meadows avg ms | Moon | Venus |
|---|---|---|---|
| cold (fresh generators, a stack's chunks in a row): surface | 1.66-1.74 | 1.94 (worst 20.1) | **0.55** (worst 3.9) |
| cold: underground | 1.28-1.43 | 0.31 | **0.26** |
| cold: sky | 0.80-0.82 | 0.01 | **0.04** |
| cold: all | 1.42-1.53 | 1.10 | **0.38** |
| warm (stacks cached): all | 1.30-1.32 | 0.79 | **0.14** |
| a new area's secrets (once, then cached) | — | 0.63 (worst 1.49) | **0.87 (worst 2.34)** |

Venus's parts (`BENCH_VENUS_<PART>`, fresh generators over 4 × 4 whole chunk stacks, y -64..159, against the meadows on
the same chunks): the landing deck 0.73 ms a surface chunk vs 1.77 (worst 4.2), the cloud homes 0.57 vs 1.68, the sky
garden 0.61 vs 1.62, an isle 0.45 vs 1.28, the open clouds 0.44 vs 1.80; the features and built parts' chunks (y 80 up)
0.01-0.02; underground 0.27-0.39 vs 1.11-1.63. A new secrets area costs a little more than the Moon's (0.87 ms against
0.63, once per 128 × 128 area: each secret's boxes are checked column by column against the hulls): the city's
platforms and bridges are looked up in 32-block buckets and the isles by the box's own cells (`_near`: 49 → 15 µs; the
first version's areas took 1.98 ms, worst 5.3). The aliens' site search: ~20-25 ms at a world's load (the test's limit
250).

Geography (`VenusTerrain`, printed by a scratch script):

| seed | mirrored | pad | dock (the blimp's anchor) | camp site | Theater | Tilly | Totem |
|---|---|---|---|---|---|---|---|
| 12345 | no | (40, 88) | (40, 42) (40, 24): 64 | (67.5, 61.5): 38 | (78, 88) | (48.5, 80.5) | (53.5, 101.5) |
| 77 | yes | (40, 40) | (40, 86) (40, 104): 64 | (67.5, 67.5): 39 | (78, 40) | (28.5, 43.5) | (56.5, 49.5) |
| 777 | yes | (40, 40) | (40, 86) (40, 104): 64 | (67.5, 67.5): 39 | (78, 40) | (48.5, 32.5) | (58.5, 45.5) |
| 42 | no | (40, 88) | (40, 42) (40, 24): 64 | (67.5, 61.5): 38 | (78, 88) | (38.5, 100.5) | (53.5, 101.5) |

The ring: the dock 46 from the pad (r 11), the camp deck 42 (r 12), the show deck 42 (r 12), the cloud homes 48 (r 14), the
sky garden 48 (r 14), the west lookout 46 (r 11), the orchard 45 (r 12); the outer ring 94-106 (r 10-14); 34-36 city
bridges; 99-122 isles in 14 × 14 cells (1344 blocks square). Sights: the cloud scope 18 from the pad, the others 47-53.
Over 1200 × 1200 blocks round the pad: open clouds 95 %, decks 3 %, bridges 1.5 %, gardens 1 %, rims 0.5 %. Secrets in
10 × 10 areas: 28-37 treasures, 15-19 hidden rooms, 18-30 stations, 4-8 geodes, one Research Blimp. Every seed's blimp
lies inside area (0, 0).

## Smoke runs

- `tools/venus_smoke.gd` (through `tools/smoke_all.sh venus`: a private folder with "smoke" in its path and a copy of
  `profile.json`): **51 checks, 0 fails** (exit 0, 47 s): a new Green Meadows Sandbox world with home's Sun rising in the
  east; the Star Map; Venus's card (3 facts, LAND); Venus's own world `sandbox_24`, its terrain, gravity 0.9, a sky of its
  own, the Sun 1.4 × and rising in the west (this morning it stood in the west), a golden sky, never the photo sky, Earth
  a tiny point, on the landing pad, peaceful, no animals, MY MAP's pad and five sights, the Space Book's LANDED mark, the
  sights watched, no geysers, the lightning, a void world, the robots and the aliens' camp on its own deck; the portal
  home by the pad; the cloud scope by the pad; a real fall off the landing deck (down to y 56.5) caught by the warm breeze,
  back on the deck where it stood, "Whoosh! A warm breeze lifted you back up to the city."; the Research Blimp is the
  landmark and walking into its gondola finds it, then MY MAP shows it; the five sights say their facts; nothing hurt the
  child (health 20 all along); through the portal home: Green Meadows `sandbox_1`, on the take-off column, home gravity,
  home's Sun rising in the east again.

## Pictures (`tools/space_shots.gd -- --universe=24 --sights`, windowed, both styles)

Seen: from over the pad, a hazy golden sky over a sea of pale yellow cloud tops far below, fading into a warm haze;
round white platforms on silvery bowl-shaped hulls floating at one height, joined by honey-coloured bridges with white
lamp posts, the landing pad's teal-and-gold star on the landing deck. North: the dock with the white Research Blimp and
its teal fins beside it, the orchard's trees. East: the Theater on the show deck, the four cloud homes with teal, pink,
sky and yellow domes. South and west: the sky garden's green turf, trees and its pond, the outer ring's groves and
plazas far away. By day facing west (morning) the bright glow of the Sun rising in the west. Sunset (facing east, where
the Sun sets on Venus): the first pictures showed the Sun's disc as a dark blot low over the bright horizon (ruling 16);
after the fix the twilight glow only. Night: a dark blue starry sky. REALISTIC looks close to BLOCKY at 640 × 360
(textured decks, planks and turf).

- After the full suite (`tools/smoke_all.sh venus dragon space mercury mars titan`): **6 passed, 0 failed** (`venus` 51
  checks, `dragon` 28 (the realm's void keeps its line and its wind), `space` 36, `mercury` 43, `mars` 29, `titan` 43, all 0
  fails).

## Full suite

`tests/run_tests.sh` (2026-09-30 10:46-11:33, load 5-8, on the code of commit 9d23ff52): **942 scripts, 8535 tests, 8531
passing, 2 failing, 2 risky** (`test_meadows_biome_generator.gd`'s two that never assert, as before this work), no script
errors (2771 s). The two failing:
- `test_wonders_blocks.gd` `test_every_block_is_on_its_page_with_a_name`: `BlockIds.COUNT` must equal 624 (prospecting's page the
  last): Venus's page moved it to 672. Fixed after the run (`assert_gte`, like `test_prospect_blocks`'s), then the file
  and the Venus tests run again: 53 passing.
- `test_prospect_blocks.gd` `test_the_held_page_stays_empty_for_the_domes`: it expects ids 544-559 empty, but the colony
  domes' page 31 was merged into `lead-merge` before this work (it fails on `lead-merge` 1d4ff0af too: not this work's;
  left for the lead, whose page it is).

## The lead's checklist (emulator, both styles)

1. Sandbox, Green Meadows: fly up; on the Star Map tap Venus: MISSION until the Mission to Venus is flown (or LAND after
   a landing); the loading card shows Venus's picture (the Research Blimp over a deck, the hazy Sun, lightning in the
   clouds) and a Venus hint. The Mission Board lists the Mission to Venus (13.4 km/s, about 5 months, a heat shield and a
   parachute); the flight lands on the city's pad (the lander stands 7 blocks to the left, on the landing deck).
2. On Venus: the golden sky (too yellow? friendly?), the haze far away, the clouds far below (do they read as clouds from
   the deck on a phone?), the platforms' hulls, the bridges; the Sun rising in the west at dawn (the west lookout).
3. Walk off a bridge: the fall (~24 blocks, ~1.5 s) and the breeze's words; is the fall fun or too long? (`LIFT_Y`).
4. The Research Blimp: the gangway, the gondola's door (1 wide), the chest; its look from the dock and from far away.
5. The cloud homes (their doors, windows, domes), the sky garden's pond and trees, the telescopes (the scope and the
   west lookout), the mooring mast.
6. Lightning: visible on a phone at LOW and HIGH? (distance 26-70, in the haze; the bolt ignores fog).
7. The aliens' camp on its deck (its ship), Nimbus by the pad, the rover following over bridges (it keeps its height
   over a gap), the Theater on the show deck, Tilly and the Totem on the landing deck (Survivor).
8. Survivor: the bag goes to Venus and home; Tilly's city things; a gift or showcase holding a Venus block.
9. Page 38's first frames compile its materials (like any new universe). Performance (≥ 30 FPS, no frame over 100 ms): the
   autopilot with `--universe=24`; the cloud sea is terrain everywhere (a surface chunk per column).
10. The pages' budget (ruling 14): 60 MB is a choice for the lead. The low Sun's disc (ruling 16) changes every world's
    dawn and dusk a little.

## Next (the game never ends)

Airships that sail between the platforms (a ride), a balloon to fly in Survivor from the dock, the city riding the winds
(the whole sky turning round in about 4 days), a slower day (a Venus day is 117 Earth days from sunrise to sunrise), the
upper haze hiding the stars at night, Venus's ground far below as its own world (a lander for a peek: the 1980s landers
lasted about two hours), a telescope that looks down at the volcanoes by radar, a Planet Book page for Venus, Venus's own
music.
