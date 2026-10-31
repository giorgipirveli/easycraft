# Cosmos: Ganymede, world 28 (spec §21b.2)

The owner: "add cosmos, stars and planets where is planet is different universe" (#72) and "make the universies closer to
real worlds so player start learning real things" (#74). Brief: `docs/superpowers/plans/2026-09-29-cosmos-planet-brief.md`
with BODY = Ganymede (Jupiter's largest moon, the largest moon in the solar system, bigger than Mercury), WORLD = 28,
PAGE = 43, IDS = 736-751. The lead's ideas (NASA/JPL, Galileo, Juno's 2021 flyby, ESA's JUICE on its way): the only moon
with its own magnetic field, so it has auroras (glowing belts near its poles: a gentle night show), old dark regions
(Galileo Regio) and younger bright grooved terrain (long parallel ridges and grooves), bright ray craters, frost at the
poles, an ocean of salty water deep under the ice (more water than Earth's oceans, they think), Jupiter huge and banded in
the sky (always in the same place: tidally locked), Io and Europa passing as bright dots, the Sun small (about 5 × Earth's
distance), gravity about 0.15, no air; a landing place, a robot helper and the space creatures, a mission row (JUICE takes
about 8 years with flybys: rule how the game makes it reachable), sights with real facts on MY MAP, secrets, the Star Map's
LAND/MISSION, the census's `"ganymede": 28`; the aurora may reuse the Northern Lights' or the sky's materials; cheap.
Ganymede was not yet in spec §21b.2's table: its row was added first (the rule: features go into the spec before they
are built). Built by a worker agent in its own worktree (branch `worktree-agent-a1926aaadcc0732ee`, reset to `lead-merge`
c9ec7635 first), without the editor, the emulator or adb (two windowed runs of `tools/space_shots.gd` for pictures).

## Allocations (used; nothing else touched)

| What | Allocated | Used | Free |
|---|---|---|---|
| World number | 28 (`SpaceRules.GANYMEDE`, new; the Star Map's Ganymede had `"world": 0`, now 28) | Ganymede | |
| Block ids, page 43 (`GanymedeBlocks`) | 736-751 | 736-747 | 748-751 |
| `BlockIds.COUNT` | 736 → 752 | | |
| `BlockIds.NEXT_PAGE_FIRST_ID` | 736 → 752 (page 44 is the next) | | |
| Atlas page | 43 (`data/blocks/pages/ganymede*.png`) | rows 0-2 | rows 3-7 |
| Item ids, animals, HUD spots | none | | |
| Server module | unchanged (0.2.15 already lets blocks up to 1023 travel in gifts) | | |

## What a child sees on Ganymede

1. **Getting there:** fly up above any world (or fly the Mission to Ganymede); the Star Map opens; Ganymede's card (its
   three facts: the biggest moon of all, bigger than Mercury; the only moon with its own magnetic field; rock and ice with
   a salty ocean deep inside) says **LAND** once the mission is flown (or Ganymede was landed on before), else **MISSION**.
   Jupiter's own card still says there is no ground.
2. **Landing:** "You landed on Ganymede, the biggest moon of all! Jupiter hangs big in the sky to the east." on the pad in
   a smooth plain of pale bright ice (gentle swells), the golden portal home three steps away, Compass the helper robot,
   the rover and the drone, the aliens' camp (Lumo the explorer, Ridgy the trader) a short walk away on the plain; the
   Space Book marks Ganymede.
3. **The sky:** almost no air: space's black sky with stars all day; the **Sun small** (0.19 × home's: Jupiter is 5.2
   times farther out); **Jupiter big and banded** (its cream zones, brown belts and Great Red Spot) up over the eastern
   horizon, **never moving** (Ganymede always shows it the same face); **Io (yellow) and Europa (white) as bright dots
   swinging back and forth past Jupiter**: Io out to 23° and back every ~6.5 minutes, Europa out to 39° and back every
   ~20 minutes, in front of Jupiter half the time and hidden behind it now and then. Soft icy chimes; Mozart's Eine kleine
   Nachtmusik by day, Bach's Air at night. No animals, no monsters.
4. **The auroras (the night show):** at night two belts of light glow, green low down and pink higher up, swaying and
   brightening slowly: from the pad the northern belt hangs low over the northern horizon and the southern one over the
   southern horizon; walk north to the frost and the northern belt is overhead. The belts rock gently to and fro (every
   2.5 minutes). By day they cannot be seen.
5. **The Jupiter Lookout** (12 east, 3 north of the pad, towards Jupiter): a round floor of groove bricks, a brass
   telescope on a stand looking east and up at Jupiter, a globe of Jupiter on a post, a green aurora lamp. Standing on it:
   "You found the Jupiter Lookout! Ganymede always shows Jupiter the same face, so Jupiter never moves here."
6. **Jumping:** gravity 0.146 (real: 1.428 m/s²): a jump floats ~11.6 blocks up (measured in the smoke) and lasts ~5 s;
   a one-block step is the Moon's gentle hop. The plain steps one block at most; every other step is two at most.
7. **The grooved terrain** (from ~65-80 blocks out, all round the plain): lanes ~84 blocks across, each with long parallel
   ridges of pale ice and blue-grey grooves between them (a ridge every 7-11 blocks, up to 2.5 high), each lane running
   its own way, flat seams where lanes meet. There: "You found the grooved terrain! Its long ridges, some 700 m high,
   formed as the icy crust stretched."
8. **The dark terrain** (from ~90-125 blocks west, and on west for ever): old brownish-grey dark ice, 3 blocks higher,
   crossed by long curved furrows (arcs round one middle far to the west) and pocked with old softened craters. On it:
   "You reached the dark terrain! It is about 4 billion years old and full of old craters."
9. **The bright ray crater** (~120-150 blocks east): a bowl of fresh ice 26-32 across with a low rim and **a pit in its
   middle** (glowing aurora crystals in it), and 10-13 long **rays of brilliant fresh ice** running 60-100 blocks out across
   the grooves, narrowing and breaking up at their ends. In it or on a ray: "You found a bright ray crater! A crash threw
   fresh ice out across the ground in long, bright rays."
10. **The polar frost** (from ~215-255 blocks north and ~255-300 south, on for ever): white frost with a violet tint over
    the grooves and the dark terrain, its edge patchy, glowing aurora crystals here and there. On it: "You reached the
    polar frost! Ganymede's magnetic field steers Jupiter's particles here: they brighten the ice."
11. **The Aurora Watch** (on the northern frost, 16 inside its edge, 12 east of straight north of the pad): a round floor,
    a mast with a green aurora lamp on top, a long boom with the **magnetometer** at its tip (real ones sit far out on
    booms), aurora crystals round its foot; at night the northern auroras are right overhead. Standing on it: "You found
    the Aurora Watch! Ganymede's magnetic field makes auroras: look up at night for glowing belts!"
12. **The ocean drill** (~80-100 blocks south-west): a 7 × 7 brick floor round a shaft 3 × 3 and 8 deep, lined with deep
    blue ice, the drill's light glowing blue at its bottom; a tower of trusses on four legs over it with the drill's motor
    and two lamps. A child who drops in jumps straight out (a Ganymede jump: 3.6 blocks to spare). On its floor: "You
    found the ocean drill! Ganymede's salty ocean lies about 150 km down: deeper than any drill."
13. **The Solar Wing Lander** (the landmark, a short walk from the pad, facing it): four truss legs, a body in gold foil,
    a white deck with a lamp on each corner and the golden chest, **two giant solar wings** out to both sides on trusses, a
    magnetometer far out on a boom at its back, a radio dish on a mast, two steps up its front. On its deck: "You found the
    Solar Wing Lander! Sunlight here is about 25 times weaker than on Earth: big wings help."
14. **Secrets** (the Secret Book counts them): buried treasure under an X of glowing aurora crystals, a hidden grooved-ice
    room behind a fake grooved-ice door lit by aurora crystals, the explorers' station (the puzzle temple in groove bricks
    with aurora lamps: friendly and made up), aurora crystal geodes in the water ice. None on the ray crater or a built part.
15. **Compass** (the helper robot): "Ganymede is the only moon with its own magnetic field: its iron core makes it, as
    Earth's does." Its sample: Ganymede's water ice (a crust about 150 km thick); its quest: what Ganymede has that no other
    moon has, Ganymede or Mercury (which is bigger), where its salty ocean is.
16. **Tilly** (Survivor) sells the grooved, trough, dark, old and ray ice, polar frost, water ice, aurora crystals, a
    Jupiter globe, aurora lamps, a magnetometer, groove bricks, a telescope and the landing pad at home prices; never star
    gold or the fake door.
17. **Nothing hurts:** the cold (about −160 °C) is a fact, never a danger; the shaft is a jump deep; no word says anything
    hurts, freezes or is scary (`test_the_cold_is_never_a_danger`); the smoke checks the hearts after the shaft.
18. **Home:** walk into the portal or fly up and tap HOME: back on the take-off column.

## How it plugs in

- **New files:** `world/universes/ganymede.gd` (the descriptor), `world/universes/ganymede_blocks.gd` (page 43),
  `world/generators/ganymede_terrain.gd` (`GanymedeTerrain`: the regions as pure rules, the built parts' boxes),
  `world/ganymede_sky.gd` (`GanymedeSky`: the auroras, Io and Europa), `data/blocks/pages/ganymede{,_albedo,_normal}.png`
  (+ imports with the pages' import settings), `tools/ganymede_smoke.gd`, `tools/ganymede_smoke_steps.gd`, tests (below).
- **Shared, small and additive:** `data/blocks/block_ids.gd` (ids, names, `SPACE_GROUND`, `COUNT` 752,
  `NEXT_PAGE_FIRST_ID` 752), `world/block_library.gd` (one register line), `world/generators/space_shape.gd` (planet
  `GANYMEDE`: a branch per method, `ganymede_columns`, `ganymede_kind`, `_ganymede_block_at`, `_ganymede_calm`, the parts
  placed after the pad, the part sights before the spawn's clearing, `sights`, boulders and aurora crystals as features),
  `world/generators/space_generator.gd` (Ganymede's stack, `_write_ganymede_column`, the parts in `_place_colony` and
  `reference_block`), `world/generators/space_secret_rules.gd` (Ganymede's palette, `_solar_wing_lander`, `_fits` through
  `steep_near`), `world/generators/secret_rules.gd` (`is_fake_wall`), `world/universes/universe_registry.gd`
  (`SPACE[28]`), `core/rules/space_rules.gd` (`GANYMEDE`, `WORLDS`), `core/rules/star_map.gd` (Ganymede's `"world": 28`),
  `core/rules/mission_rules.gd` (Ganymede's row), `entities/flight/flight_plan.gd` (`REAL_TRIP`, `_JUPITER`),
  `flight_dials.gd` (`DISTANCE`, `TRIP_HOURS`, `LOW_ORBIT`), `flight_shots.gd` (`RADIUS_KM`), `flight_looks.gd`
  (`SUN_SIZE`), `core/creatures/alien_rules.gd` (the smooth plain is the camp's ground), `core/creatures/creature_words.gd`
  (Compass, Lumo, Ridgy, three souvenirs), `core/magic/mini_rules.gd` (`alien_lumo`), the natural-block lists
  (`bot_rules`, `surprise_rules`, `capture_rules`, `gather_rules`, `chat_commands`), `ui/universe/universe_art.gd`
  (Ganymede's card), `core/rules/loading_hints.gd` (twelve hints), `scenes/sandbox.gd` (`_space_ganymede_sky`: 18 lines),
  `tools/make_space_atlas.gd` (`-- ganymede`), `tools/make_space_realistic.py` (`ganymede`), `tools/bench_generator.gd`
  (`BENCH_GANYMEDE_<REGION>`, `BENCH_GANYMEDE_SHAPE`), `tools/shader_probe_steps.gd` (the census's `"ganymede": 28`),
  `tools/space_shots_steps.gd` (Ganymede's aurora view from the frost), `docs/DEVELOPMENT.md`, spec §21b.2 (its row and
  "As built"), `docs/devlog/parts/missions.md` (Ganymede's row), `assets/CREDITS.md`.
- **Not touched:** the School, the Science Lab, `ui/space/*` (the Star Map UI), `SkyCycle` (the moons are moved from
  outside it), `NatureSky` (its colours and material maker are only called), the colonies, the server, the other worlds'
  files, the reels' and the visuals agents' files.
- **Shared tests updated:** `test_space_rules` (WORLDS), `test_space_registry` (warm_space, space_available),
  `test_planet_universes` (space_available), `test_realistic_pack` (GanymedeBlocks.FILES), `test_block_id_space` (752,
  page 44), `test_block_pages` (page 43 is 736), `test_robot_words` (the camps), `test_mission_rules` (the missions'
  order), `test_star_map` (Ganymede lands at 28), `test_robot_creatures` (+1: Ganymede's robot and camp), `test_page_sizes`
  (its comment: 68.3 of 70 MB). The shared planet tests (`test_space_shape`, `test_space_secrets`, `test_space_generator`,
  `test_alien_rules`) now also run for Ganymede (it is in `SpaceShape.PLANETS`); the census test
  (`test_every_world_s_landing_is_in_the_census_steps`) passes with its entry.

## Rulings (decided on the owner's behalf; cost if wrong)

1. **Ganymede is a planet kind of `SpaceShape`, its regions in `GanymedeTerrain`**; what it looks up (the plain, the dark
   line, the furrows' middle, the crater and its rays, the poles' lines, the built parts and their calm spots) is made in
   `_init` and `place_parts`, before any generator thread starts, and only read afterwards; the lanes, the old craters and
   the rays' specks come from hashes per cell (no table): no lock, no cache. *Cost:* none (0.67 ms to build a shape).
2. **The world is Ganymede in small, its parts where they really are relative to each other:** the bright grooved terrain
   (60 % of the real surface) all round, the old dark terrain (40 %) to one side, a bright ray crater, frost poleward at
   both ends, the pad on a smooth patch of bright terrain (real bright terrain has smooth plains too) so the pad, the camp
   and the landmark stand level. Scale: a real ridge is up to 700 m high and a few km apart (here up to 2.5 blocks every
   7-11); the dark terrain stands a little higher (the bright terrain's lanes are thought to be broad sunken troughs
   refilled with ice). *Cost:* constants in `GanymedeTerrain`.
3. **Under its ground Ganymede uses Pluto's water ice** (as hard as rock in the cold; its crust is mostly ice, ~150 km
   thick: NASA), so page 43 holds only Ganymede's own surface blocks; the ocean drill's shaft is lined with Europa's deep
   blue ice and lit by its glow ice. *Cost:* two blocks of its own on page 43 (ids 748-751 are free).
4. **The ocean is real but out of reach:** the real ocean lies under ~150 km of ice (Europa's ~15-25 km is reached by
   its ocean well in the game). Ganymede's ocean drill is a shaft 8 deep whose light glows at the bottom; its words say the
   ocean is far deeper than any drill. A child who drops in jumps out (11.6 blocks of jump, 8 of shaft: nothing hangs in
   it). *Cost:* a reachable ocean is a well like Europa's (`EuropaTerrain.well_block`).
5. **The auroras show at night only** (like the northern lights in world 41), as two belts of curtains over the poles'
   frost; they are really there day and night (seen in ultraviolet by a space telescope, and in red and green light from
   Earth's big telescopes while Jupiter's shadow darkened Ganymede), but a child sees glowing light best against the night.
   Colours: NatureSky's green foot fading to pink and violet (oxygen's green and red). *Cost:* `NIGHT_MIN`, a day-time
   glow would be one line.
6. **The belts follow the child east and west** (they run round the pole) and hang `BELT_IN` (60) inside each frost's
   line at y 150; farther than 200 they are drawn 200 away in their direction (inside the camera's far plane, 300), so
   from the pad they hang low over the northern and the southern horizon (~16-20° up) and from the frost overhead. They
   rock 8 blocks to and fro every 150 s (the real ones rock ~2° as Jupiter's tilted field sweeps by every ~10 hours; the
   ocean keeps it small). *Cost:* constants in `GanymedeSky`.
7. **No new shader:** the auroras' curtains are drawn with `NatureSky.star_material()` (the night sky's star material
   settings: the census has them) by `GanymedeSky.belt_mesh` (NatureSky's look, ends that dissolve); the script makes no
   material of its own, so the census's sources test does not list it. *Cost:* none.
8. **Io and Europa swing at their real angles** (out to 23.2° and 38.8° from Jupiter: asin of their orbits over
   Ganymede's), along the great circle through Jupiter and the east and west points (their orbits are in Jupiter's
   equator, which is Ganymede's), with Ganymede's day as the game's day (20 minutes): Io's swing takes 394 s (2.35 Earth
   days), Europa's 1,182 s (7.05 days). Only Jupiter is drawn bigger than real (80 across, ~20°; really ~7.6°, 15 times our
   Moon), like every world's sky planet. They are moved by `GanymedeSky` from outside `SkyCycle` (the visuals agent works
   on the sky now). *Cost:* constants.
9. **Jupiter low in the east** (dir (0.9, 0.33, -0.2): ~19° up): the first pictures (at ~30°) showed it at the day views'
   top edge. A sky planet's spot stays Jupiter's red. *Cost:* the descriptor's `dir`.
10. **The Sun `sun_size` 0.19** (Jupiter is 5.2 AU out), **its light stays home's** (like Europa's and Io's: real
    sunlight there is 1/27 of Earth's; the game stays bright and friendly, spec §3c). *Cost:* `sun_light` is one line.
11. **Gravity 0.146, the real one** (1.428 ÷ 9.81); the lead's "about 0.15". *Cost:* none.
12. **The Mission to Ganymede follows the real spacecraft on its way now:** launched 14 April 2023 with ~2.5 km/s past
    Earth's pull (3.5 km/s from a 200 km orbit, our arithmetic), swinging past the Moon and Earth, Venus, and Earth twice
    more to reach Jupiter in July 2031 (~8 years), slowing into orbit round Jupiter (~0.95 km/s), then past Jupiter's moons
    again and again (35 flybys) until it circles Ganymede from December 2034 (its whole budget ~2.7 km/s, the Ganymede
    phase 0.61 of it); the game's rocket then lands (~1.9 from a 500 km orbit: our estimate, its orbital speed there is
    1.78 km/s). 9.4 + 3.5 + 2.1 + 2.5 = 17.5 km/s, almost 12 years (4,260 crew-days: 22 service modules). The straight
    route (a Hohmann transfer like Europa's row, 2 years 9 months) would need ~21.9 (arriving ~5.5 km/s too fast for
    Ganymede, braked by engines: our patched-conic arithmetic). The board teaches the trade: the flybys save fuel but take
    years. A rocket of **209 parts** (~7,115 gold, 6 stages) passes the check
    (`test_a_rocket_a_child_can_build_reaches_ganymede`): cheaper than Triton's 266. No air: no heat shield, no parachute.
    *Cost:* the row's legs, `days`, the flight's `REAL_TRIP`.
13. **Names:** MY MAP's "Jupiter Lookout", "Grooved Terrain", "Dark Terrain", "Bright Ray Crater", "Polar Frost", "Aurora
    Watch", "Ocean Drill"; the IAU's names (Galileo Regio, Uruk and Nicholson Sulci, Tros, Osiris, Memphis Facula) are not
    used (spec §21b.2's general words); "The Solar Wing Lander" (a description), Compass, Lumo and Ridgy are made up. The
    astronomer Galileo Galilei is named with his whole name (the treasure's fact) and never alone (the spacecraft shares
    the name): a test reads every Ganymede word for that and for Voyager, NASA, ESA, JPL, Hubble, Juno, JUICE, Pioneer,
    Clipper, Keck and the place names.
14. **Steps:** the plain one block at most; everything else at most two (`MAX_STEP`; a jump reaches ~11.6): a groove's
    slope is at most 0.82 a block (`SLOPE`), lanes fade into flat seams, the dark terrain rises 3 over 14 blocks, the
    furrows' walls and the old craters' bowls are about one a block, the ray crater's bowl two at most near its rim.
    *Cost:* constants.
15. **Built parts:** the Jupiter Lookout 12 east and 3 north of the pad (just outside the pad's flat circle: at 11 east its
    ground's margin touched it), the Aurora Watch 16 inside the north frost's line, 12 east of straight north, the ocean
    drill 80-100 south-west; the watch's and the drill's ground is calm (no grooves within 9-18 blocks) so they stand level;
    all written with the colonies' flag; `tree_at` keeps their ground. *Cost:* constants.
16. **Sounds:** no new audio: chimes day and night (almost no air), Eine kleine Nachtmusik (by day) and the Air on the G
    String (by night, for the auroras). *Cost:* a `MusicPieces` entry for a CC0 recording.
17. **The realistic pages' budget stays 70 MB** (68.3 MB with page 43: room for one more page of three rows). *Cost:* the
    next page needs a new ruling (the APK grows ~1.6 MB a page).
18. **The bright terrain is a little grey** (cfd2d8, not white): the first pictures showed white ice everywhere, the rays'
    fresh ice and the frost hard to tell from it. *Cost:* colours in the atlas tools.

## The facts (every Ganymede fact in the game, and its check)

| Where | Words | Check |
|---|---|---|
| gravity | 0.146; hint "On Ganymede you jump about 7 times as high!" | 1.428 m/s² ([Wikipedia: Ganymede](https://en.wikipedia.org/wiki/Ganymede_(moon))); 1 ÷ 0.146 = 6.8 |
| landing, robot, hints, Star Map | "the biggest moon of all", "biggest moon in the solar system", "even bigger than the planet Mercury" | "Ganymede's diameter is about 3,270 miles (5,260 kilometers). It is the largest moon in our solar system. It's bigger than Mercury and Pluto." ([NASA: Ganymede facts](https://science.nasa.gov/jupiter/jupiter-moons/ganymede/facts/)) |
| robot, hints, quest | "the only moon with its own magnetic field: its iron core makes it, as Earth's does" | "the only moon known to have its own magnetic field"; "a metallic iron core that generates the moon's magnetic field" ([NASA: Ganymede](https://science.nasa.gov/jupiter/jupiter-moons/ganymede/)); found by a spacecraft's flyby on 27 June 1996 (Kivelson et al., Nature 1996; Wikipedia) |
| sight (Aurora Watch), hints | "Ganymede's magnetic field makes auroras: look up at night for glowing belts!" | "The magnetic field causes auroras, or bright ribbons of glowing gas, that circle the moon's poles." (NASA: Ganymede); "ribbons of glowing, hot electrified gas, in regions circling the north and south poles" ([NASA, 2015](https://www.nasa.gov/news-release/nasas-hubble-observations-suggest-underground-ocean-on-jupiters-largest-moon/)); seen in red and green oxygen light from Earth during an eclipse ([Astronomy: Ganymede's aurorae dancing during eclipse](https://www.astronomy.com/science/scientists-view-ganymedes-aurorae-dancing-during-eclipse/); [Milby et al. 2024](https://arxiv.org/abs/2409.06055)) |
| GanymedeSky | the belts rock | "This ocean fights Jupiter's magnetic field so strongly that it reduces the rocking of the aurorae to 2 degrees, instead of the 6 degrees, if the ocean was not present." (NASA, 2015) |
| sight (ocean drill), hints, robot's sample, Lumo | "Ganymede's salty ocean lies about 150 km down"; "A salty ocean hides deep under Ganymede's ice."; "a crust of ice about 150 km thick"; "may hold more water than Earth's seas" | "The ocean is estimated to be 60 miles (100 kilometers) thick ... buried under a 95-mile (150-kilometer) crust of mostly ice" (NASA, 2015; NASA: Ganymede facts); "an underground saltwater ocean that may hold more water than all the water on Earth's surface" (NASA: Ganymede) |
| hints | "Ice and ocean may lie in layers, like a sandwich!" | "might have ice and oceans stacked up in several layers like a club sandwich" ([NASA/JPL, 2014](https://www.jpl.nasa.gov/news/ganymede-may-harbor-club-sandwich-of-oceans-and-ice/)) |
| sight (lookout), hints | "Ganymede always shows Jupiter the same face, so Jupiter never moves here." | "Ganymede is tidally locked, meaning that like Earth's Moon, the same side of Ganymede always faces Jupiter." (NASA: Ganymede facts) |
| sight (grooves) | "Its long ridges, some 700 m high, formed as the icy crust stretched." | "Some of the groove ridges are as high as 2,000 feet (700 meters), and the grooves run for thousands of miles" ([JPL: Ganymede fact sheet](https://www2.jpl.nasa.gov/galileo/ganymede/fact.html)); grooves "probably formed when tectonic forces pulled apart the icy surface" ([NASA/JPL PIA01615](https://www.jpl.nasa.gov/images/pia01615-swaths-of-grooved-terrain-on-ganymede/)); 60 % bright grooved, 40 % dark (JPL fact sheet; NASA facts) |
| sight (dark) | "It is about 4 billion years old and full of old craters." | "The dark areas are the older, more heavily cratered regions" (NASA: Ganymede); the dark terrain is about four billion years old (Wikipedia: Ganymede); Galileo Regio ~3,200 km across (JPL fact sheet) |
| sight (crater) | "A crash threw fresh ice out across the ground in long, bright rays." | Tros: "excavated massive amounts of buried ice ... before scattering it in all directions which formed the rays ... most likely composed of pure and fresh water ice" ([Wikipedia: Tros](https://en.wikipedia.org/wiki/Tros_(crater))); "rayed craters have a central pit" (same); [NASA/JPL: Crater rays on Ganymede](https://www.jpl.nasa.gov/images/crater-rays-on-ganymede) |
| sight (frost) | "Ganymede's magnetic field steers Jupiter's particles here: they brighten the ice." | "Charged particles follow the moon's magnetic field lines to the poles, where they impact ... This establishes a clear link between plasma bombardment and polar cap brightening"; polar caps "likely composed of water frost" ([NASA/JPL: Juno's first images of Ganymede's north pole](https://www.nasa.gov/centers-and-facilities/jpl/nasa-juno-takes-first-images-of-jovian-moon-ganymedes-north-pole/)) |
| treasure | "Galileo Galilei discovered Ganymede on 7 January 1610." | "Ganymede was discovered by Italian astronomer Galileo Galilei on Jan. 7, 1610." (NASA: Ganymede facts) |
| hidden room | "Ganymede is bigger than Mercury, but only about half as heavy." | Ganymede 1.4819 × 10²³ kg, Mercury 3.3011 × 10²³ kg: 45 % (Wikipedia: Ganymede, Mercury) |
| temple | "While Ganymede circles Jupiter once, Europa goes twice and Io 4 times." | "Every time Ganymede orbits Jupiter once, Europa orbits twice, and Io orbits four times." (NASA: Ganymede facts) |
| Solar Wing Lander | "Sunlight here is about 25 times weaker than on Earth: big wings help." | "Solar radiation is 25 times weaker at Jupiter than at Earth"; the real spacecraft's arrays: 85 m² ([DLR: the JUICE spacecraft](https://www.dlr.de/en/research-and-transfer/projects-and-missions/juice/the-juice-spacecraft)); 1 ÷ 5.2² = 1/27 (our arithmetic) |
| geode | "Ganymede's ice is about −160 °C, far colder than any freezer." | "The average surface temperature on Ganymede is -163°C" (JPL fact sheet); 90-160 K by day (NASA facts) |
| hints | "Sunlight takes about 43 minutes to reach Ganymede." | "it takes sunlight 43 minutes to travel from the Sun to Jupiter" ([NASA: Jupiter facts](https://science.nasa.gov/jupiter/jupiter-facts/)) |
| hints, GanymedeSky | "Watch Io and Europa swing past Jupiter!" | orbits: Io 421,700 km, Europa 671,100 km, Ganymede 1,070,400 km from Jupiter (Wikipedia): asin(421.7 ÷ 1,070.4) = 23.2°, asin(671.1 ÷ 1,070.4) = 38.8°; periods 1.769, 3.551, 7.155 days: as seen from Ganymede 2.35 and 7.05 days (our arithmetic) |
| sky | the Sun 0.19 ×; Jupiter banded with its Great Red Spot | "Jupiter is 5.2 astronomical units away from the Sun" (NASA: Jupiter facts); Jupiter ~7.6° across from Ganymede: 2 atan(71,492 ÷ 1,070,400) (our arithmetic) |
| mission | "600 to 970 million km away", "almost 12 years", "A spacecraft launched in 2023 swings past Venus and Earth to save fuel. It will circle Ganymede in 2034!" | launched 14 April 2023; flybys: the Moon and Earth August 2024, Venus August 2025, Earth September 2026 and January 2029; Jupiter July 2031; Ganymede's orbit December 2034, "the first ... intended to orbit a moon other than Earth's Moon" ([ESA: Juice](https://www.esa.int/Science_Exploration/Space_Science/Juice); [Wikipedia: Jupiter Icy Moons Explorer](https://en.wikipedia.org/wiki/Jupiter_Icy_Moons_Explorer)) |
| mission | 9.4 + 3.5 + 2.1 + 2.5 km/s | the launch's "infinite velocity of up to 2.5 kilometers per second" ([NASASpaceflight](https://www.nasaspaceflight.com/2023/04/juice-launch/)): √(2.5² + 121.19) − 7.78 = 3.5 km/s from a 200 km orbit (our arithmetic); total spacecraft Δv "about 2,700 m/s" ([ESA: Juice spacecraft specs](https://www.esa.int/Science_Exploration/Space_Science/Juice/Juice_spacecraft_specs)), Jupiter orbit insertion ~900-952 m/s, the Ganymede phase 614 m/s (Wikipedia: JUICE); down from a 500 km orbit ~1.9 (Ganymede's GM 9,887 km³/s², radius 2,634 km: 1.78 km/s orbital speed; our estimate with losses) |

(The Star Map's own three Ganymede facts are the lead's, in `core/rules/star_map.gd`; unchanged.)

## Tests (RED → GREEN)

| Test file | Tests | RED (why it failed first) |
|---|---|---|
| `tests/unit/test_ganymede_blocks.gd` | 9 | `BlockIds.GROOVED_ICE` …, `GanymedeBlocks` not declared — run and seen |
| `tests/unit/test_ganymede_shape.gd` | 18 | `SpaceShape.GANYMEDE` not found; then too few old craters (55 → 75 of 100 cells) and a furrow test looking past the dark terrain's edge (fixed: arcs inside it) |
| `tests/unit/test_ganymede_generator.gd` | 7 | the generic path wrote plain grooved ice for every kind (`_write_ganymede_column` missing) — run and seen |
| `tests/unit/test_ganymede_secrets.gd` | 7 | the Moon's palette (Base Panel, Moon Rock) on Ganymede — run and seen |
| `tests/unit/test_ganymede_universe.gd` | 16 | `SpaceRules.GANYMEDE` not declared — run and seen |
| `tests/integration/test_ganymede_sky.gd` | 8 | written with `GanymedeSky` (the auroras, the swings, the dissolving ends after the pictures) |
| `tests/integration/test_ganymede_sights.gd` | 4 | written with the descriptor |
| `tests/integration/test_ganymede_world.gd` | 5 | written with the descriptor (the pad, the bright ice, the lookout's telescope in the real terrain; save, load, mesh) |
| `tests/integration/test_robot_creatures.gd` | +1 | Ganymede's robot by the pad, the camp on the smooth plain clear of the lookout |
| shared (see above) | | WORLDS, warm_space and space_available lists, COUNT and the next page, the realistic pack's pages, the camps, the missions, the Star Map; `test_space_shape`'s "nothing grows on the pad" found the lookout's ground margin on the pad's edge (moved 11 → 12 east) |

## Measurements

Generator bench (`bench_generator.gd -- --space moon triton ganymede`, 2026-10-01 13:18, the PC's load 14-18 with another
app and other agents running; ms a chunk):

| chunks | Moon | Triton | Ganymede | meadows beside Ganymede |
|---|---|---|---|---|
| warm: surface | 1.65 (worst 15.2) | 0.84 | **0.70** (worst 2.58) | 1.55 |
| warm: underground | 0.36 | 0.34 | **0.36** | 1.13 |
| warm: all | 0.97 | 0.56 | **0.49** | 1.31 |
| cold (fresh generators, a stack's chunks in a row): surface | 2.18 | 1.07 | **1.20** (worst 6.34) | 1.72 |
| cold: all | 1.44 | 0.67 | **0.74** | 1.47 |
| a new area's secrets (once, then cached) | 0.63 | 0.43 | **0.66** (worst 1.39) | — |

Ganymede's generator is cheaper than the Moon's and the meadows'. Its regions (`BENCH_GANYMEDE_<REGION>`, fresh generators
over 4 × 4 whole chunk stacks, y -64..159, against the meadows on the same chunks): the landing 0.60 ms a surface chunk vs
1.19, the grooves 0.94 vs 1.17 (worst 10.6 once, on the busy PC), the dark terrain 0.80 vs 1.10, the crater 0.70 vs 0.88,
the frost by the Aurora Watch 0.84 vs 1.09, the ocean drill 0.99 vs 1.25; underground 0.37-0.46 vs 1.14-1.76.
`GanymedeTerrain.column` costs 14.4 µs (the lanes' nine cells and the rays; Triton's 6.4): a chunk column's 256 columns
are worked out once for its whole stack. Building a Ganymede shape 0.67 ms (the parts' floors).

Geography (`SpaceShape`/`GanymedeTerrain`, printed by a scratch script; offsets from the pad, which is at (0, 0) on y 50 for
every seed):

| seed | lookout | Aurora Watch | ocean drill | ray crater, radius | dark line west | north frost | south frost | furrows' middle | Solar Wing Lander |
|---|---|---|---|---|---|---|---|---|---|
| 12345 | (12, -3) | (12, -250) | (-44, 67), 80 | (124, -31), 13 | 90 | 238 | 255 | (-697, -7) | (-34, 28), 44 |
| 77 | (12, -3) | (12, -262) | (-34, 88), 94 | (121, 4), 16 | 100 | 242 | 263 | (-654, -18) | (-26, -47), 54 |
| 777 | (12, -3) | (12, -248) | (-50, 69), 85 | (121, 35), 13 | 95 | 231 | 298 | (-651, 135) | (-24, 39), 46 |
| 42 | (12, -3) | (12, -229) | (-46, 86), 98 | (136, -39), 15 | 105 | 214 | 280 | (-738, -56) | (-26, -46), 53 |

Kinds over 600 × 600 blocks round the pad (seed 12345): grooved ridges 34.6 % and grooves 14.9 %, the dark terrain 21.9 %
(furrows 4.6 %, old craters 1.2 %), frost 16.6 %, the smooth plain 5.0 %, rays 0.9 %, the crater 0.2 %.

The rocket (a search over `RocketParts`' numbers with `RocketCheck`'s rules: stages from the top down, for each tank count
the fewest engines the push rules allow, the best speed per part count and mass; it finds Triton's 265-266 again): for the
Mission to Ganymede (17.5 km/s, 4,260 crew-days, no heat shield) **209 parts, 7,115 gold, 6 stages** (stage 1: 41 rocket
engines, 5 tanks, 3 fins; then 29 space engines and 62 tanks, 8 and 12, 4 and 6, 2 and 2, 1 and 2 with the capsule, 22
service modules, 3 legs, the solar array: 17.51 km/s); 4 stages need 230, 5 stages 210.

## Smoke run

- `tools/ganymede_smoke.gd` (through `tools/smoke_all.sh ganymede`: a private folder with "smoke" in its path and a copy of
  `profile.json`): **60 checks, 0 fails** (exit 0, 65 s; again after the drill lost its hanging pipe: 60, 0, 62 s): a new
  Green Meadows Sandbox world; the Star Map; Ganymede's card (3 facts, LAND); Ganymede's own world `sandbox_28`, its
  terrain, gravity 0.146, space_sky 1.0, the Sun 0.19, stars by day, never the photo sky, Jupiter big and up in the east,
  Io and Europa, never home's moon disc, on the landing pad, peaceful, no animals, MY MAP's pad and seven sights, the
  Space Book's LANDED mark, the sights watched, GanymedeSky there, no geysers, solid ground, Compass and the camp on the
  smooth plain; the portal home by the pad; the lookout's telescope and globe; a slow fall (1.05 m/s after 0.31 s); **a
  jump 11.6 blocks up (2.6 s to its top)**; the Solar Wing Lander is the landmark and standing on its deck finds it, then
  MY MAP shows it; the seven sights say their facts; **at midnight the auroras glow over both poles, the northern ones up
  in the north; Io moves past Jupiter**; at the bottom of the ocean drill's shaft on the drill's light, **a jump clears
  the shaft by 3.6 blocks**; nothing hurt the child (health unchanged); through the portal home: Green Meadows
  `sandbox_1`, on the take-off column, home gravity, home's own sky and Sun.

## Pictures (`tools/space_shots.gd -- --universe=28 --sights`, windowed, both styles)

Seen: from over the pad by day a starry black sky over pale ice, the smooth plain round the pad, the grooved terrain's long
parallel ridges in lanes all round it, the dark terrain as a brown band on the western horizon; the Solar Wing Lander (its
blue solar wings, gold body, white deck) and the camp near the pad, the places system's Theater. At the first run Jupiter
(at ~30°) sat on the day views' top edge: it went down to ~19° and the east and sunset views now show it, banded with its
red spot. At night from the pad: the northern auroras a wavy green belt with a pink top low over the horizon (the first
run's curtains ended in hard edges: their ends now dissolve); from the frost, the curtains overhead. The sights: the
grooves' lanes and seams; the dark terrain's brown ice with furrows; the ray crater's terraced bowl with its pit of glowing
crystals and the rays as brighter strips; the frost's violet-white with the Aurora Watch's mast and boom; the ocean
drill's dark tower. REALISTIC looks close to BLOCKY at 640 × 360. The ice read nearly white everywhere at first (it is a
little greyer now, ruling 18); the visuals agent's light and exposure work will change how bright it looks.

## Full suite

`tests/run_tests.sh` (2026-10-01 evening, on the code of commit 330be726) was **stopped at about 6,400 tests by the
owner's pause** (21:04: "please pause for the moment the works"): **it must be run again before the merge.** Until then it
had found one failure: `test_wonders_nature_blocks.gd` pinned `BlockIds.COUNT` and `NEXT_PAGE_FIRST_ID` at 736 ("page 43
stays free"); Ganymede took page 43 by its allocation, so the test now asks for at least 736 and that the third tour's ids
are page 37's (as Triton's work did for Pluto's test); it passes. Before the suite: every Ganymede test and the shared ones
it touches (134 tests, 0 failing), and the smokes `tools/smoke_all.sh ganymede triton europa mission`: **4 passed, 0
failed** (Ganymede 60 checks, 0 fails).

## The lead's checklist (emulator, both styles)

1. Sandbox, Green Meadows: fly up; on the Star Map tap Ganymede: MISSION until the Mission to Ganymede is flown (or LAND
   after a landing); Jupiter's card says there is no ground; the loading card shows Ganymede's picture (the Solar Wing
   Lander on bright ice, the dark terrain to the left, a ray, Jupiter with Io and Europa, the auroras' belts) and a
   Ganymede hint. The Mission Board lists the Mission to Ganymede (17.5 km/s, almost 12 years, no heat shield); the
   flight goes the Jupiter way (`_JUPITER`) and lands on its legs (airless).
2. **Performance** (≥ 30 FPS, no frame over 100 ms): the autopilot with `--universe=28`, both styles; the grooves are the
   busiest columns (the shape is built at the world's load in ~0.7 ms on the PC); at night the two aurora belts are six
   see-through curtains of 512 triangles each (64 segments × 4 rows × 2 triangles), large on the screen.
3. **The night show:** `/time night` (or wait): do the auroras read as auroras on a phone (brightness, the sway, the
   dissolving ends)? From the pad, low in the north and the south; walk to the Aurora Watch: overhead. Not drawn by day.
4. **Io and Europa:** watch for a few minutes: they move past Jupiter, hide behind it now and then (do the transits draw
   in front of Jupiter's picture?).
5. **The feel of 0.146 gravity:** jumps ~11.6 blocks, ~5 s; the grooves are a ridge every 7-11 blocks: a walk of small hops.
6. **The ocean drill:** drop in and jump out; the glow at the bottom; the tower.
7. The ray crater's rays (visible as bright strips?), the pit's crystals, the frost's colour against the grooves, the dark
   terrain's furrows from above.
8. The Jupiter Lookout, the Aurora Watch, the Solar Wing Lander (its wings, the boom, the deck and chest).
9. Compass by the pad, Lumo's and Ridgy's camp on the plain, the rover and the drone; Tilly and the Totem (Survivor).
10. Survivor: the bag goes to Ganymede and home; Tilly's Ganymede things; a gift or showcase holding a Ganymede block.
11. Page 43's first frames compile its materials (like any new universe). The realistic pages: 68.3 of 70 MB.
12. **The census** (`tools/shader_probe_steps.gd` now has `"ganymede": 28`): run it again after the merge so Ganymede's
    loading card warms page 43's materials and Jupiter's, the moons' and the Sun's looks (the auroras share the night
    sky's star material).

## Next (the game never ends)

The palimpsests (flat ghost craters), dark-floored craters and dome craters, more bright ray craters and their rays across
the dark terrain, the furrows' giant ring system, Jupiter eclipsing the Sun (Ganymede's day goes dark for a while each
orbit), the auroras by day as a faint glow and their colours changing with height, the poles' frost thinning toward the
equator in patches, Callisto as a world of its own (the Star Map's next Jupiter moon), a Planet Book page for Ganymede,
the real spacecraft's arrival in 2031 and its Ganymede orbit in 2034 as news on the Star Map.
