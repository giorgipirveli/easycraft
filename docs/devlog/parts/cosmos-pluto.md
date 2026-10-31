# Cosmos: Pluto, world 26 (spec §21b.2)

The owner: "add cosmos, stars and planets where is planet is different universe" (#72) and "make the universies closer to
real worlds so player start learning real things" (#74). Brief: `docs/superpowers/plans/2026-09-29-cosmos-planet-brief.md`
with BODY = Pluto, WORLD = 26, PAGE = 41, IDS = 704-719. The spec's row: "26 | Pluto | 0.06 | the heart-shaped plain of
nitrogen ice, water-ice mountains, a hazy blue sky, Charon big in the sky". The lead's ideas, from New Horizons (2015):
the heart (Tombaugh Regio) and its left lobe Sputnik Planitia, a vast plain of nitrogen ice in slowly churning cells,
water-ice mountains (the Norgay/Tenzing and Hillary Montes) floating like icebergs on it, the red-brown tholins, blue hazes
in layers, a thin nitrogen air, about -230 °C, the Sun a bright star (about 40 × Earth's distance, light ~5.5 hours),
Charon big and always in the same place (tidally locked), gravity about 0.06 (long jumps); a dwarf planet, said kindly,
and why (2006); a landing place, a robot helper, the aliens, a mission row (New Horizons took 9.5 years and flew past;
landing needs far more: rule how the game makes it reachable), sights with real facts on MY MAP, secrets, the Star Map's
LAND/MISSION; cheap (a bench before and after), the generator's shared state built before the threads start. Built by a
worker agent in its own worktree (branch `worktree-agent-aeff2b505faea8079`, reset to `lead-merge` 399beae0 first: the
rings' merge), without the editor, the emulator or adb (two windowed runs of `tools/space_shots.gd` for pictures).

## Allocations (used; nothing else touched)

| What | Allocated | Used | Free |
|---|---|---|---|
| World number | 26 (`SpaceRules.PLUTO`, already in `SpaceRules`, the Star Map's Pluto and the flight's tables) | Pluto | |
| Block ids, page 41 (`PlutoBlocks`) | 704-719 | 704-716 | 717-719 |
| `BlockIds.COUNT` | 704 → 720 | | |
| `BlockIds.NEXT_PAGE_FIRST_ID` | 704 → 720 (page 42 is the next) | | |
| Atlas page | 41 (`data/blocks/pages/pluto*.png`) | rows 0-2 | rows 3-7 |
| Item ids, animals, HUD spots | none | | |
| Server module | unchanged (0.2.15 already lets blocks up to 1023 travel in gifts) | | |

## What a child sees on Pluto

1. **Getting there:** fly up above any world (or fly the Mission to Pluto); the Star Map opens; Pluto's card (the lead's
   three facts: a dwarf planet smaller than our Moon, a giant heart-shaped plain of frozen nitrogen, a year of 248 Earth
   years) says **LAND** once the mission is flown (or Pluto was landed on before), else **MISSION**.
2. **Landing:** "You landed on Pluto! Its heart of ice lies to the east, and Charon hangs still in the west." on the pad
   among peach-tan uplands of frost, the golden portal home three steps away, Nixie the helper robot, the rover and the
   drone, the aliens' camp (Wisp the explorer, Tumble the trader) a short walk away; the Space Book marks Pluto.
3. **The sky:** a thin nitrogen air: black and starry overhead even by day, a **blue haze** glowing along the horizon and
   over the far ground; the **Sun a tiny, very bright star** (1/40 as wide as at home) that **rises in the west** (Pluto
   spins backwards, like Venus); **Charon big and grey with its red
   cap, low in the west, never moving** (day and night in the same place: Pluto and Charon always face each other); Nix
   and Hydra two tiny points. Soft icy chimes; Vivaldi's Winter by day, the Moonlight Sonata under Charon at night. No
   animals, no monsters.
4. **The Charon Lookout** (12 blocks west of the pad, towards Charon): a round floor of frost bricks, a brass telescope on
   a truss looking west and up at Charon, a globe of Charon (grey, its red cap) on a post, a glowing pink heart. Standing on
   it: "You found the Charon Lookout! Pluto and Charon always face each other, so Charon never moves in this sky."
5. **Jumping:** gravity 0.063 (real: 0.62 m/s²): a jump floats ~27 blocks up and lasts ~12 s (measured 26.9 blocks, 6 s
   up); a one-block step is the Moon's gentle hop (a ~4 s float). The plain, its rim and the uplands step one block at most,
   the red-brown lands two, the mountains' blocks up to 16 (one jump).
6. **The heart** (~80-95 blocks east of the pad, ~400 blocks wide, its point to the south): its west half is the **Heart
   Plain**, a flat plain of pale cream nitrogen ice sunk a few blocks under the uplands, cut into cells ~40 blocks across by
   darker edges (a pattern like a giant tiled floor); a gentle rim of one-block steps leads down to it. On its ice: "You
   found Pluto's heart! Its plain of frozen nitrogen slowly churns in giant cells, like a lava lamp."
7. **Floating hills** (in the plain's western part, on the cells' edges, 8-18 of them): small domes of blue-grey water ice
   3-5 high; dig down and the iceberg's ice goes on under the plain, nitrogen ice round it. On one: "You found a floating
   hill! Water ice is lighter than nitrogen ice, so it floats like an iceberg."
8. **The Ice Mountains** (along the plain's south-west side, ~200-300 blocks south-east of the pad): a range of jumbled
   giant blocks of blue-grey water ice, each flat on top, up to 24 over the ground, the highest capped with white methane
   snow, rising right out of the plain's shore. On the top: "You climbed Pluto's ice mountains! They are named after
   Tenzing Norgay and Edmund Hillary, who first climbed Everest."
9. **The Red-Brown Lands** (~110-130 blocks west of the pad, and on west for ever): dark red-brown tholin dust over
   red-stained ice, rolling hills whose tops are frosted white with methane, old craters with frosty rims and red-ice
   floors. There: "You found the red-brown lands! Sunlight turns gas high in Pluto's air into this reddish dust: tholins."
10. **The Bright Side** (the heart's east half, ~370-380 blocks east): bright white methane snow with glowing frost
    crystals. There: "You found the heart's bright side! Nitrogen drifts here through the air from the plain and settles
    as frost."
11. **The Balloon Lander** (the landmark, 44-56 blocks from the pad, facing it): four truss legs, a body wrapped in gold
    foil, a white deck with a lamp on each corner and the golden chest, a glowing power pack on an arm at its back, a radio
    dish on a mast, two steps up its front, and its silvery drag balloon spread out and crumpled on the ground behind it,
    tethered to the body. On its deck: "You found the Balloon Lander! Scientists have studied landing on Pluto with a giant
    balloon."
12. **Secrets** (the Secret Book counts them): buried treasure under an X of glowing frost crystals, a hidden water-ice room
    behind a fake water-ice door lit by frost crystals, the explorers' station (the puzzle temple in frost bricks and warm
    lamps: friendly and made up), frost crystal geodes in the water ice. None on the mountains or among the floating hills.
13. **Nixie** (the helper robot): "Pluto is a dwarf planet. Since 2006, a planet must clear its path round the Sun, and
    Pluto shares its path with many icy worlds." Its sample: nitrogen ice; its quest: why a dwarf planet, what the heart
    is made of, why Charon never moves. The hints say it too, kindly: "Pluto is a dwarf planet, and full of wonders!"
14. **Tilly** (Survivor) sells Pluto's ices, frost, tholin dust, red ice, methane snow, frost crystals, the drag balloon, a
    Charon globe, heart beacons, frost bricks, a telescope and the landing pad at home prices; never star gold or the fake
    door.
15. **Nothing hurts:** the cold (about -230 °C) is a fact, never a danger; no word says anything hurts, freezes a child or
    is scary (`test_the_cold_is_a_fact_never_a_danger`); the smoke checks the hearts.
16. **Home:** walk into the portal or fly up and tap HOME: back on the take-off column.

## How it plugs in

- **New files:** `world/universes/pluto.gd` (the descriptor), `world/universes/pluto_blocks.gd` (page 41),
  `world/generators/pluto_terrain.gd` (`PlutoTerrain`: the regions as pure rules, the Charon Lookout's boxes),
  `data/blocks/pages/pluto{,_albedo,_normal}.png` (+ imports, the pages' import settings), `tools/pluto_smoke.gd`,
  `tools/pluto_smoke_steps.gd`, tests (below).
- **Shared, small and additive:** `data/blocks/block_ids.gd` (ids, names, `SPACE_GROUND`, `COUNT` 720,
  `NEXT_PAGE_FIRST_ID` 720), `world/block_library.gd` (one register line), `world/generators/space_shape.gd` (planet
  `PLUTO`: a branch per method, `pluto_columns`, `pluto_kind`, `_pluto_block_at`, `_pluto_calm`, the lookout placed after
  the pad, `_by_lookout`, `sight_at` / `sights`, boulders and frost crystals as features), `world/generators/space_generator.gd`
  (Pluto's stack, `_write_pluto_column`, the lookout written in `_place_colony` and `reference_block`),
  `world/generators/space_secret_rules.gd` (Pluto's palette, `_balloon_lander`, `_fits` through `steep_near`),
  `world/generators/secret_rules.gd` (`is_fake_wall`), `world/universes/universe_registry.gd` (`SPACE[26]`, `MIN_SUN`
  0.025), `world/sky_cycle.gd` (a sky planet's `cap`: Charon's red cap), `core/rules/space_rules.gd` (`WORLDS` has 26),
  `core/rules/mission_rules.gd` (Pluto's row), `core/creatures/alien_rules.gd` (the uplands are the camp's ground),
  `core/creatures/creature_words.gd` (Nixie, Wisp, Tumble, three souvenirs), `core/magic/mini_rules.gd` (`alien_wisp`),
  `entities/flight/flight_looks.gd` (`SUN_SIZE`), `entities/flight/flight_plan.gd` (`REAL_TRIP`: "about 9 and a half
  years"), the natural-block lists (`bot_rules`, `surprise_rules`, `capture_rules`, `gather_rules`, `chat_commands`),
  `ui/universe/universe_art.gd` (Pluto's card), `core/rules/loading_hints.gd` (ten hints), `tools/make_space_atlas.gd`
  (`-- pluto`), `tools/make_space_realistic.py` (`pluto`), `tools/bench_generator.gd` (`BENCH_PLUTO_<REGION>`,
  `BENCH_PLUTO_SHAPE`), `docs/DEVELOPMENT.md`, spec §21b.2 ("As built"), `docs/devlog/parts/missions.md` (Pluto's row),
  `assets/CREDITS.md`.
- **Not touched:** the School, the Science Lab, `ui/space/*` (the Star Map UI), `StarMap` (Pluto's card already had world
  26 and its facts), the colonies, the server, the other worlds' files, the frame-spike and School agents' files.
- **Shared tests updated:** `test_space_rules` (WORLDS), `test_space_registry` (warm_space, space_available),
  `test_planet_universes` (space_available), `test_realistic_pack` (PlutoBlocks.FILES), `test_block_id_space` (720, page
  42), `test_block_pages` (page 41 is 704), `test_robot_words` (the camps), `test_mission_rules` (the missions' order),
  `test_robot_creatures` (+1: Pluto's robot and camp). The shared planet tests (`test_space_shape`, `test_space_secrets`,
  `test_space_generator`, `test_alien_rules`) now also run for Pluto (it is in `SpaceShape.PLANETS`).

## Rulings (decided on the owner's behalf; cost if wrong)

1. **Pluto is a planet kind of `SpaceShape`, its regions in `PlutoTerrain`**, and everything it looks up (the plain's
   cells and floating hills, the mountains' blocks with their tops, the peak, the lookout's boxes) is built in `_init`,
   before any generator thread starts, and only read afterwards: no lock, no cache. *Cost:* ~3 ms per shape at a world's
   load on the PC (`BENCH_PLUTO_SHAPE`); a phone ~10-15 ms, a few shapes per load.
2. **The world is Pluto in small:** the heart (an exact heart shape, `sd_heart`, ~400 × 365 blocks: the real Tombaugh
   Regio is ~1,600 km across), the mountains, the red-brown lands and the bright side within a walk of the pad, in their
   real places round the plain (the mountains on its south-west border, the dark lands to its west, the bright lobe to
   its east). *Cost:* constants in `PlutoTerrain`.
3. **The plain is flat; the cells' edges are darker ice, not ridges:** the real cells are tens of km across and their
   middles only tens of metres higher (flat at the game's scale), and at 0.063 gravity every one-block step is a ~4 s
   floaty hop: a ridge every 40 blocks would bounce a child along. NASA's own words call the edges "ridges" and "troughs":
   the game says "cells". *Cost:* a one-block ridge per edge is one line in `column()`.
4. **Charon hangs over the pad in the west, though the real heart faces away from it:** Sputnik Planitia lies near the
   point on Pluto farthest from Charon, so from the heart itself Charon is never seen (it hovers over the other side).
   The game's slice sits at the heart's western edge and shows Charon there; no word says Charon is seen from the heart.
   *Cost:* a sky planet shown only west of a line needs a per-frame hook in the sandbox (next: "walk east onto the heart
   and Charon sets for good" would be a lovely true lesson).
5. **Charon is 64 across (about 16°), not its real 3.5°:** the game's sky is not to scale (home's moon is 6.5° against the
   real 0.5°, Europa's Jupiter about twice its real size); the words keep the real ratio ("7 times our Moon's width" is
   in the descriptor's comment, not said). *Cost:* one number.
6. **The Sun is a bright star:** `sun_size` 0.025 (Pluto is 39 AU out: 1/39.5), `UniverseRegistry.MIN_SUN` 0.1 → 0.025
   (the painted sky's glow is 0.5°: a tiny bright point). The light stays friendly (spec §3c); a hint says real noon on
   Pluto is as dim as dusk here (NASA's "Pluto Time"). *Cost:* a dimmer light is one factor.
7. **The sky is 55 % space's** (`space_sky` 0.55): black and starry overhead by day, a blue haze palette along the horizon
   and over the far ground (`fog`), the haze under the horizon too (no dark band). The real air is ~100,000 times thinner
   than Earth's: from the ground the sky would look black, the haze a faint blue glow low down (New Horizons saw it blue,
   in many thin layers, at Pluto's edge). *Cost:* numbers in the descriptor.
8. **Gravity 0.063, the real one** (0.62 ÷ 9.81), the spec's "0.06" rounded. *Cost:* none.
9. **The Mission to Pluto lands with a giant drag balloon:** 9.4 + 8.9 + 0.3 = 18.6 km/s, `air` true (a heat shield and a
   parachute on the rocket). The real spacecraft (2006-2015) needed 8.9 km/s from a low orbit (C3 157.75 km²/s²) and a
   Jupiter swing-by, and flew past at ~14 km/s; braking that by engines makes ~32 km/s in all: no rocket of up to 7 stages
   the pad holds reaches it (the search in the notes). A NASA study (2017-2021) slows a lander from that fast trip in
   Pluto's thin, very tall air under a huge, light drag envelope (tens of metres across) to ~120 m/s at the surface, with
   a few kg of fuel and no heavy heat shield: the game's heat shield and parachute stand for it; the last 0.3 is our
   estimate. A rocket of 239 parts (~8,200 gold) passes the check (`test_a_rocket_a_child_can_build_reaches_pluto`),
   like the rings' (~210) and Mercury's (~230). The crew needs air and water for 3,470 days (18 service modules).
   *Cost:* a "drag balloon" rocket part and a balloon descent in the flight (`FlightPlan.has_air` stays false: the
   flight's landing is the flight agent's) are next.
10. **`FlightPlan.REAL_TRIP[PLUTO]` "about 9 years" → "about 9 and a half years"** (launch 19 January 2006, flyby 14 July
    2015: 9.48 years), so the flight says the board's trip. *Cost:* none.
11. **`InventionRules.air(PLUTO)` stays NO_AIR** ("There is no air here …"): its THIN_AIR words are Mars's (a helicopter
    flew there); Pluto's air is 100,000 times thinner than Earth's, far too thin for wings. *Cost:* a Pluto line in the
    inventions' words.
12. **Names:** MY MAP's "Heart Plain" (Sputnik Planitia is named after a satellite: a mission name, spec §21b.2), "Red-Brown
    Lands" (Cthulhu is a monster's name: never scary, §3c), "Ice Mountains" whose fact names Tenzing Norgay and Edmund
    Hillary (people, not missions, as the rings named the astronomer Cassini), "Bright Side"; Charon's red cap is not
    called Mordor; the 11-year-old who named Pluto (Venetia Burney) and the heart's namesake (Clyde Tombaugh) are not named.
    "The Balloon Lander", Nixie, Wisp and Tumble are made up. A test reads every Pluto word for New Horizons, NASA, ESA, JPL,
    Hubble, Voyager, Pioneer, NIAC, "Hop, Skip", Global Aerospace, Sputnik, Cthulhu and Mordor.
13. **No mountain height is said:** New Horizons' first estimate was ~3.5 km (2015), later maps give the Tenzing Montes
    ~6 km; the words tell whom they are named after instead. *Cost:* none.
14. **Steps:** the plain, its rim and the uplands step one block (gentle swells: `SWELL` 2); the red-brown lands two (their
    craters' bowls rise smoothly into their rims: no sharp crest); the mountains' blocks up to 16 (`MAX_STEP`; a jump
    reaches ~27). A one-block step is the Moon's hop (`LabRules.step_velocity`), a ~4 s float at 0.063. *Cost:* a gentler
    hop in very low gravity changes `LabRules` for every low world (the rings' ruling 4 said the same).
15. **The Charon Lookout is a built part** (`PlutoTerrain.place_lookout`, called once by `SpaceShape._init` after the pad;
    written with the colonies' flag, `SpaceGenerator._place_colony`), 12 blocks west of the pad (just outside the pad's
    flat circle); `tree_at` marks its ground so Tilly, the Totem, the Theater and the camp keep off. *Cost:* none.
16. **Floating hills** only on the cells' east and south edges' midpoints (34 of 100), within the plain's western 110
    blocks and never within 10 of its shore or near the mountains, radius 3-5, 3-5 high; the iceberg's water ice reaches
    twice its height down into the plain (a child who digs sees it). *Cost:* constants.
17. **The bright side's fact** is the nitrogen cycle (frost carried through the air from the plain settles on the east
    lobe's uplands); its snow is methane snow in the game (the lobe's ground is really nitrogen and methane ices).
    *Cost:* none.
18. **The Sun rises in the west** (`sun_rises_west`, Venus's `SkyCycle.sun_west`): Pluto spins backwards, "from east to
    west like Venus and Uranus" (NASA). Its tilt (about 120°) makes its real seasons strange (decades of day and of night
    near its poles); the game keeps its usual day. Added after the full suite (a descriptor line, a hint, a test line and
    a smoke check; the Pluto tests, Venus's sky test and the smoke ran again). *Cost:* none.
19. **Sounds:** no new audio: chimes day and night (the air is far too thin to carry wind), Vivaldi's Winter (Frostpeak's
    own piece, a far cold world) and the Moonlight Sonata (under Charon). *Cost:* a `MusicPieces` entry for a CC0 recording.
20. **The realistic pages' budget holds at 64 MB** with 62.2 MB (page 41 added ~1.6 MB): the next page needs it raised.
    *Cost:* the APK grows ~1.6 MB a page.

## The facts (every Pluto fact in the game, and its check)

| Where | Words | Check |
|---|---|---|
| gravity | 0.063; hint "On Pluto you jump about 16 times as high!" | "about 6% of Earth's" ([NASA: Pluto facts](https://science.nasa.gov/dwarf-planets/pluto/facts/)); 0.62 m/s² ÷ 9.81 = 0.063; 1 ÷ 0.063 = 15.9 |
| robot, hints | "Pluto is a dwarf planet. Since 2006, a planet must clear its path round the Sun, and Pluto shares its path with many icy worlds." | "In 2006, the International Astronomical Union (IAU) … reclassified Pluto as a dwarf planet … a dwarf planet … has not been able to clear its orbit of debris … the Trans-Neptunian region (beyond Neptune) where other objects might cross Pluto's orbital path" (NASA: Pluto facts) |
| treasure | "An 11-year-old girl gave Pluto its name in 1930." | "named by Venetia Burney, an 11-year-old girl from Oxford, England" on 14 March 1930 (NASA: Pluto facts) |
| hidden room | "On Pluto, water ice is frozen as hard as rock." | "Water ice is Pluto's crustal 'bedrock'" ([NASA: Pluto's widespread water ice](https://science.nasa.gov/photojournal/plutos-widespread-water-ice/)); methane and nitrogen ice "are not strong enough to build the mountains" ([NASA: the icy mountains of Pluto](https://science.nasa.gov/photojournal/the-icy-mountains-of-pluto/)) |
| temple | "Pluto has five moons: Charon, Nix, Hydra, Kerberos and Styx." | "five known moons: Charon, Nix, Hydra, Kerberos, and Styx" (NASA: Pluto facts) |
| Balloon Lander | "Scientists have studied landing on Pluto with a giant balloon." | NASA NIAC "Pluto Hop, Skip, and Jump" (2017, phase II 2021): a large, lightweight inflatable drag device, "tens of meters in diameter", uses "Pluto's thin extended atmosphere to reduce vehicle speed at the surface to about 120 m/s" ([NASA](https://www.nasa.gov/general/pluto-hop-skip-and-jump/)) |
| geode | "At about −230 °C, even the nitrogen of Pluto's air freezes." | "-387°F (-232°C)" on average, "-226 to -240 degrees Celsius" (NASA: Pluto facts); nitrogen freezes at −210 °C (63 K); the air is "mostly nitrogen, methane, and carbon monoxide" (NASA) |
| Charon Lookout | "Pluto and Charon always face each other, so Charon never moves in this sky." | "The same surfaces of Charon and Pluto always face each other … Charon neither rises nor sets, but hovers over the same spot on Pluto's surface" ([NASA: Charon](https://science.nasa.gov/dwarf-planets/pluto/moons/charon/)) |
| Heart Plain | "Its plain of frozen nitrogen slowly churns in giant cells, like a lava lamp." | "churning ice 'cells' … 10 to 30 miles (16 to 48 kilometers) across … the solid nitrogen is warmed by Pluto's modest internal heat, becomes buoyant and rises up in great blobs – like a lava lamp" ([NASA: Pluto's heart like a cosmic lava lamp, 2016](https://www.nasa.gov/solar-system/plutos-heart-like-a-cosmic-lava-lamp/)) |
| Floating Hills | "Water ice is lighter than nitrogen ice, so it floats like an iceberg." | "water ice is less dense than nitrogen-dominated ice … hills … floating in a sea of frozen nitrogen … like icebergs"; pushed "to the edges of the cells, where the hills cluster" ([NASA: Pluto's mysterious floating hills](https://science.nasa.gov/photojournal/plutos-mysterious-floating-hills/)) |
| Ice Mountains | "They are named after Tenzing Norgay and Edmund Hillary, who first climbed Everest." | the IAU's Tenzing Montes and Hillary Montes, on Sputnik Planitia's south-west border, after the first climbers of Everest (29 May 1953) ([Wikipedia: Tenzing Montes](https://en.wikipedia.org/wiki/Tenzing_Montes), [Hillary Montes](https://en.wikipedia.org/wiki/Hillary_Montes)); "water-ice mountains" (NASA); the hills are "miniature versions of the larger, jumbled mountains on Sputnik Planum's western border" (NASA: floating hills) |
| Red-Brown Lands | "Sunlight turns gas high in Pluto's air into this reddish dust: tholins." | "sunlight-initiated chemical reactions of nitrogen and methane, leading to relatively small, soot-like particles (called tholins) that grow as they settle toward the surface" ([JPL: Pluto's blue sky](https://www.jpl.nasa.gov/images/pia19964-plutos-blue-sky/)); "reddish organic materials called tholins" ([NASA: Pluto paints its largest moon red](https://www.nasa.gov/missions/pluto-paints-its-largest-moon-red/)) |
| terrain | the red-brown lands' frosted hilltops and crater rims | "bright frost containing methane coats crater rims, walls, and mountain tops" in Cthulhu (Bertrand et al., Nature Communications 2020; [NASA/JPL: methane snow on Pluto's peaks](https://www.jpl.nasa.gov/images/pia20477-methane-snow-on-plutos-peaks/)) |
| Bright Side | "Nitrogen drifts here through the air from the plain and settles as frost." | the eastern lobe: "high-albedo uplands thought to be coated by nitrogen transported through the atmosphere from Sputnik Planitia, and then deposited as ice" ([Wikipedia: Tombaugh Regio](https://en.wikipedia.org/wiki/Tombaugh_Regio), from New Horizons' papers) |
| robot's sample | "nitrogen ice! On Earth nitrogen is a gas in the air we breathe." | Earth's air is 78 % nitrogen; Pluto's plain is nitrogen ice (NASA, above) |
| robot's questions | why a dwarf planet; the heart's plain is frozen nitrogen; Charon never moves | as above |
| Wisp's science | "Where there is water, scientists look for life. They think an ocean may hide deep under Pluto's icy heart." | "Pluto may have a subsurface ocean" under Sputnik Planitia ([NASA: 10 things we learned about Pluto](https://www.nasa.gov/solar-system/five-years-after-new-horizons-historic-flyby-here-are-10-cool-things-we-learned-about-pluto/)); always with CreatureWords.HONEST |
| hints | "Pluto's thin haze glows blue, like Earth's sky!" | "the hazes are blue" ([NASA: New Horizons finds blue skies](https://www.nasa.gov/missions/new-horizons-finds-blue-skies-and-water-ice-on-pluto)) |
| hints | "Sunlight takes 5.5 hours to reach Pluto." (the flight's dials: 5.9 billion km) | "5.5 hours to travel from the Sun to Pluto" (NASA: Pluto facts) |
| hints | "Real noon on Pluto is as dim as dusk here." | NASA's "Pluto Time": the light at noon on Pluto matches Earth's a little before sunrise or after sunset ([NASA](https://science.nasa.gov/dwarf-planets/pluto/plutotime)); the Sun "1/900 the brightness it is here on Earth, or about 300 times as bright as our full moon" (NASA: Pluto facts) |
| hints | "Charon never moves in Pluto's sky: they face each other." | NASA: Charon |
| hints, sky | "Pluto spins backwards: its Sun rises in the west!" | "Pluto also exhibits a retrograde rotation; spinning from east to west like Venus and Uranus" (NASA: Pluto facts) |
| sky | the Sun 0.025 ×, Charon grey with a red cap, Nix and Hydra points | Pluto 39 AU out on average (NASA): 1 ÷ 39.5 = 0.025; "the reddish north (top) polar region" (NASA: Charon); Charon 3.5° across (2 atan(606 ÷ 19,596), our arithmetic): about 7 × our Moon's 0.52° |
| sky | black overhead, a blue haze at the horizon | surface pressure ~10 microbars, 100,000 times less than Earth's (New Horizons' radio occultation, [Stern et al., Science 2015](https://www.science.org/doi/10.1126/science.aad1815)) |
| mission | "4.3 to 7.5 billion km away", "about 9 and a half years", "A spacecraft reached Pluto in 2015 after 9 and a half years and flew past. To land, a giant balloon slows you!" | Pluto 30-49.3 AU from the Sun (NASA) ± 1 AU for Earth: 29-50.3 AU = 4.3-7.5 billion km; launched 19 January 2006, past Pluto 14 July 2015 ([Wikipedia: New Horizons](https://en.wikipedia.org/wiki/New_Horizons)) |
| mission | 9.4 + 8.9 + 0.3 km/s | C3 157.75 km²/s² ([ScienceDirect: high-speed launches, 2024](https://www.sciencedirect.com/science/article/pii/S0094576524000304)): from a 200 km orbit √(157.75 + 121.19) − 7.78 = 8.9 km/s (our arithmetic); the Jupiter swing-by added 4 km/s and saved three years (Wikipedia: New Horizons); the balloon: NASA NIAC (above); the last 0.3 our estimate |

(The Star Map's own three Pluto facts are the lead's, in `core/rules/star_map.gd`; unchanged. "It has a giant
heart-shaped plain of frozen nitrogen" is the heart's west half, strictly.)

## Tests (RED → GREEN)

| Test file | Tests | RED (why it failed first) |
|---|---|---|
| `tests/unit/test_pluto_blocks.gd` | 9 | `BlockIds.NITROGEN_ICE` …, `PlutoBlocks` not declared — run and seen |
| `tests/unit/test_pluto_shape.gd` | 14 | `SpaceShape.PLUTO` not found — run and seen; then 3-block steps at the red-brown lands' crater rims (a sharp crest: the bowl now rises smoothly into the rim), the lookout within the pad's flat circle (`test_space_shape`: moved 11 → 12), a sampler that visited only 1,800 columns |
| `tests/unit/test_pluto_generator.gd` | 7 | the generic column writer: frost everywhere instead of red ice, tholins, nitrogen — run and seen |
| `tests/unit/test_pluto_secrets.gd` | 7 | the Moon's palette and the Moon Base on Pluto — run and seen |
| `tests/unit/test_pluto_universe.gd` | 16 | no `pluto.gd` (gravity 1.0, no sights, no hints, not in WORLDS) — run and seen; then "die" inside "studied" (the word check now whole words); the rocket test written after the search found the design |
| `tests/integration/test_pluto_sky.gd` | 4 | a typed `fog`; written with the descriptor and the `cap` (its picture checked with and without one) |
| `tests/integration/test_pluto_sights.gd` | 5 | written with the descriptor |
| `tests/integration/test_pluto_world.gd` | 5 | written with the descriptor (the pad, the frost, the lookout's telescope in the real terrain; save, load, mesh) |
| `tests/integration/test_robot_creatures.gd` | +1 | Pluto's robot by the pad, the camp on the uplands clear of the lookout |
| shared (see above) | | WORLDS, warm_space and space_available lists, COUNT and the next page, the realistic pack's pages, the camps, the missions |

## Measurements

Generator bench (`bench_generator.gd -- --space moon titan mercury pluto`, before: `-- --space moon titan mercury` on
`lead-merge` 399beae0; the PC's load 6-10 on 24 cores, another suite and app running):

| chunks | before: Moon | after: Moon | Titan | Mercury | Pluto (first cut) | Pluto (after the speed-ups) | Meadows alongside Pluto |
|---|---|---|---|---|---|---|---|
| warm: surface | 1.36 | 1.44-1.50 | 0.62 | 0.65 | 1.55 | **1.39** (worst 4.5) | 2.19 |
| warm: all | 0.80 | 0.85-0.89 | 0.42 | 0.44 | 0.99 | **0.89** | 1.88 |
| cold (fresh generators, a stack's chunks in a row): surface | 1.91 | 2.02-2.18 | 1.08 | 1.01 | 2.49 | **1.25** (worst 3.05) | 1.63 |
| cold: underground | 0.82 | 0.83-1.02 | 0.33 | 0.32 | 0.61 | **0.32** | 1.25 |
| cold: all | 1.29 | 1.34-1.50 | 0.67 | 0.64 | 1.49 | **0.75** (half the Moon's) | 1.39 |
| a new area's secrets (once, then cached) | 0.62 | 0.60-1.22 | 0.45 | 0.95 | 0.88 | **0.40** (worst 1.00) | — |

The other planets are unchanged by this work (their numbers move with the PC's load: the Moon's own before/after pairs
differ as much). Pluto's regions (`BENCH_PLUTO_<REGION>`, fresh generators over 4 × 4 whole chunk stacks, y -64..159,
against the meadows on the same chunks): the landing 0.66 ms a surface chunk vs 1.06 (worst 3.13), the plain 0.54 vs 0.84,
the floating hills 0.59 vs 0.83, the mountains 0.63 vs 0.91 (worst 3.72), the red-brown lands 0.91 vs 1.08 (worst 4.83:
their craters), the bright side 0.65 vs 0.86; underground 0.34-0.37 vs 1.14-2.00. `PlutoTerrain.column` costs 4.5 µs
(11.4 before the speed-ups: noise far from the heart's edge and the red-brown lands' edge is skipped, the mountain blocks
keep their tops); building a Pluto shape 3.1 ms (its cells, hills and blocks, the spawn and the lookout).

Geography (`SpaceShape`/`PlutoTerrain`, printed by a scratch script; kinds over 1400 × 1200 blocks round the pad):

| seed | pad | lookout | Balloon Lander (from the pad) | heart's shore | nearest hill (hills) | peak (rise) | red-brown lands | bright side |
|---|---|---|---|---|---|---|---|---|
| 12345 | (0, 0) at 49 | (-12, 0) | (-34, 28), 44 | (89, 4), 89 | (120, -56), 132 (8) | (220, 197), 295 (+23) | (-130, 0), 130 | (382, 14), 382 |
| 77 | (0, 0) at 49 | (-12, 0) | (-26, -47), 54 | (85, -37), 93 | (94, -41), 103 (18) | (221, 157), 271 (+21) | (-118, 0), 118 | (377, -27), 378 |
| 777 | (0, 0) at 49 | (-12, 0) | (-24, 39), 46 | (81, -17), 83 | (94, -29), 98 (17) | (165, 134), 213 (+24) | (-111, 0), 111 | (369, -6), 369 |
| 42 | (0, 0) at 49 | (-12, 0) | (-26, -46), 53 | (91, 17), 93 | (122, 27), 125 (13) | (206, 201), 288 (+24) | (-125, 0), 125 | (379, 26), 380 |

Kinds (seed 12345): uplands 59.7 %, red-brown lands 32.5 % (snowy tops 0.6 %, craters 0.8 %), the plain 2.7 % (its
edges 0.4 %), the bright side 2.8 %, the rim 0.4 %, the mountains 0.4 %.

The rocket (a search over `RocketParts`' numbers with `RocketCheck`'s rules, a Pareto front stage by stage): with the
balloon (18.6 km/s, 3,470 crew-days, air) 233-239 parts, 8,040-8,200 gold, 6 stages (stage 1: 48 rocket engines, 5
tanks, 3 fins; then 34 space engines and 65 tanks, 12 and 21, 5 and 8, 2 and 3, 1 and 2 with the capsule, 18 service
modules, the heat shield, the parachute, 3 legs, the solar array); without it (~32.2 km/s) none within 7 stages.

## Smoke run

- `tools/pluto_smoke.gd` (through `tools/smoke_all.sh pluto`: a private folder with "smoke" in its path and a copy of
  `profile.json`): **53 checks, 0 fails** (exit 0, 56 s; 52 before the Sun rose in the west): a new Green Meadows
  Sandbox world; the Star Map; Pluto's card (3 facts, LAND); Pluto's own world `sandbox_26`, its terrain, gravity 0.063,
  space_sky 0.55, the blue haze, the Sun 0.025 rising in the west, stars by day, never the photo sky, Charon big in the west, never home's moon disc, on the landing pad, peaceful, no
  animals, MY MAP's pad and six sights, the Space Book's LANDED mark, the sights watched, no geysers, solid ground (no
  void), Nixie and the camp on the uplands; the portal home by the pad; the lookout's telescope and globe; a slow fall
  (0.43 m/s after 0.3 s); **a jump 26.9 blocks up (6.0 s to its top)**; the Balloon Lander is the landmark and standing on
  its deck finds it, then MY MAP shows it; the six sights say their facts; nothing hurt the child (health 20 all along);
  through the portal home: Green Meadows `sandbox_1`, on the take-off column, home gravity, home's own sky and Sun.

## Pictures (`tools/space_shots.gd -- --universe=26 --sights`, windowed, both styles)

Seen: from over the pad by day, a starry sky, dark navy overhead fading to a soft blue haze along the horizon; peach-tan
uplands to the horizon with contour lines where they step and a few blue-grey water-ice boulders; the Balloon Lander
(gold-foil body, white deck) and the Charon Lookout by the pad; looking west, Charon big and grey with its red-brown cap
over the horizon. The heart's plain from its shore: cream-white nitrogen ice cut into big cells by tan edges, the rim
stepping down to it; a floating hill, a blue-grey dome on a cell's edge; the ice mountains, jumbled blocks of blue-grey
ice with white snowy tops; the red-brown lands, dark rust-brown hills with grey boulders; the bright side, white snow
with glowing frost crystals. Sunset dims the plains under a purple-grey sky; night is black and full of stars. REALISTIC
looks close to BLOCKY at 640 × 360. The first pictures showed the uplands as pale as the plain, a dark band between the
far ground and the haze, Charon at the view's top edge and snow on most mountain blocks: the frost went peach-tan
(`d6a888`), the haze colour went under the horizon too, Charon lower (y 0.26), snow only on the highest blocks
(`PEAK_FROM` 0.85). A "Theater" stands near the pad (the places system's, not Pluto's).

## Full suite

`tests/run_tests.sh` (2026-09-30 17:56-18:45, the PC's load 3-9, on the code of commit e27ce0e9): **984 scripts, 8941
tests, 8939 passing, 0 failing, 2 risky** (`test_meadows_biome_generator.gd`'s two that never assert, as before this work),
no script errors, exit 0 (2936 s). After it: the Sun rising in the west (ruling 18) and a comment; the Pluto tests (78),
Venus's sky test and `test_loading_hints` passed again, and the smoke (53 checks, 0 fails). The neighbours' smokes after
this work's shared changes (`tools/smoke_all.sh rings titan mercury space mission`): **5 passed, 0 failed**.

The branch is based on `lead-merge` 399beae0 (the rings' merge); `lead-merge` has moved on since (the frame spikes: the
shader census plays each world's landing in a phase named after it, `ShaderWarmup.world_phases`; grade 6's core units).
Pluto has no census phase yet: its loading card waits only for the blocks and what every world shows until the lead's
census runs again with Pluto's landing (checklist 10).

## The lead's checklist (emulator, both styles)

1. Sandbox, Green Meadows: fly up; on the Star Map tap Pluto: MISSION until the Mission to Pluto is flown (or LAND after a
   landing); the loading card shows Pluto's picture (the Balloon Lander on the heart's ice, big Charon with its red cap,
   the tiny Sun, the blue haze) and a Pluto hint. The Mission Board lists the Mission to Pluto (18.6 km/s, about 9 and a
   half years, a heat shield and a parachute); the flight lands on the pad (its landing is an airless one: ruling 9).
2. **Performance** (≥ 30 FPS, no frame over 100 ms): the autopilot with `--universe=26`, both styles; the flat plain is
   cheap to mesh, the mountains' blocks and the red-brown hills the busiest; the shape is built at the world's load (~3 ms
   on the PC).
3. **The feel of 0.063 gravity:** jumps ~27 blocks and ~12 s; a one-block step is a ~4 s floaty hop (the rim down to the
   plain, the uplands' swells): fun or too slow? (`gravity` in `pluto.gd`; ruling 14.)
4. **The sky on a phone:** the black top with the blue haze (reads as day? the ground is brightly lit), the Sun as a tiny
   bright star (visible?), Charon's size and place in the west (ruling 5), Nix and Hydra (visible at all?).
5. The heart's plain and its cells from the rim (the edges read as a pattern?); walking onto it; a floating hill; the
   mountains' blocks (one jump each); the red-brown lands and their snowy tops; the bright side far east.
6. The Charon Lookout (the telescope pointing at Charon), the Balloon Lander (its deck, the chest, the balloon behind it).
7. Nixie by the pad, Wisp's and Tumble's camp on the uplands, the rover and the drone; Tilly and the Totem (Survivor).
8. Survivor: the bag goes to Pluto and home; Tilly's Pluto things; a gift or showcase holding a Pluto block.
9. Page 41's first frames compile its materials (like any new universe). The realistic pages' budget: 62.2 of 64 MB.
10. After the merge with the frame spikes' `lead-merge`: the shader census (`tools/shader_probe_steps.gd`) should play
    Pluto's landing (phase "pluto") so its loading card warms page 41's materials and Charon's and the Sun's looks; a
    trial merge of `sky_cycle.gd` (their `_decor.add_to_group(ShaderWarmup.SKY)`, this work's `cap`) touches other lines.
11. The Sun rising in the west over Charon at dawn (both in the west): pretty, or confusing?

## Next (the game never ends)

Charon seen only from its own side (walk east onto the heart and it sets for good: ruling 4); Wright Mons (a huge mountain
with a hole on top: maybe an ice volcano); the bladed terrain (skyscraper-tall blades of methane ice) east of the heart;
nitrogen glaciers flowing from the bright side into the plain; the blue haze in thin layers at sunrise and sunset; a slow
day (6.4 Earth days) and a sky where Charon waxes and wanes; Pluto's strange seasons (its tilt: decades of day and night
near its poles); Charon as
its own world (its canyons, its red cap); a drag-balloon descent in the rocket flight and a balloon rocket part; Pluto's
own music; a Planet Book page for Pluto.
