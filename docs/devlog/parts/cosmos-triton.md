# Cosmos: Triton, world 27 (spec §21b.2)

The owner: "add cosmos, stars and planets where is planet is different universe" (#72) and "make the universies closer to
real worlds so player start learning real things" (#74). Brief: `docs/superpowers/plans/2026-09-29-cosmos-planet-brief.md`
with BODY = Triton (Neptune's largest moon), WORLD = 27, PAGE = 42, IDS = 720-735. The spec's row: "27 | Triton
(Neptune's moon) | 0.08 | pink nitrogen ice, dark geyser streaks, Neptune deep blue in the sky". The lead's ideas, from
Voyager 2 (1989): the cantaloupe terrain, the pinkish south polar cap of nitrogen ice with dark streaks, geysers of
nitrogen gas and dust rising about 8 km and blown sideways by the thin wind, a young surface with few craters, about
−235 °C, Neptune huge and blue and always in the same place (tidally locked), the Sun a bright star (~30 × Earth's
distance, light ~4 hours), a backwards (retrograde) orbit, probably a captured Kuiper Belt object (Pluto's cousin),
gravity about 0.08; a landing place, a robot helper, the aliens, a mission row (Voyager 2 took 12 years and flew past:
rule how the game makes landing reachable), sights with real facts on MY MAP, secrets, the Star Map's LAND/MISSION, geysers
that are safe and fun (a child rides a gentle puff up), never scary; cheap; the census's `"triton": 27`. Built by a worker
agent in its own worktree (branch `worktree-agent-a15df8bba329a0384`, reset to `lead-merge` dcac026a first: the census
steps for the rings and Pluto), without the editor, the emulator or adb (three windowed runs of `tools/space_shots.gd`
for pictures).

## Allocations (used; nothing else touched)

| What | Allocated | Used | Free |
|---|---|---|---|
| World number | 27 (`SpaceRules.TRITON`, already in `SpaceRules`, the Star Map's Triton and the flight's tables) | Triton | |
| Block ids, page 42 (`TritonBlocks`) | 720-735 | 720-733 | 734-735 |
| `BlockIds.COUNT` | 720 → 736 | | |
| `BlockIds.NEXT_PAGE_FIRST_ID` | 720 → 736 (page 43 is the next) | | |
| Atlas page | 42 (`data/blocks/pages/triton*.png`) | rows 0-2 | rows 3-7 |
| Item ids, animals, HUD spots | none | | |
| Server module | unchanged (0.2.15 already lets blocks up to 1023 travel in gifts) | | |

## What a child sees on Triton

1. **Getting there:** fly up above any world (or fly the Mission to Triton); the Star Map opens; Triton's card (the lead's
   three facts: it goes round Neptune backwards, its geysers blow nitrogen ~8 km high, about −235 °C) says **LAND** once
   the mission is flown (or Triton was landed on before), else **MISSION**. Neptune's own card says there is no ground.
2. **Landing:** "You landed on Triton! Neptune hangs big and blue in the sky, and geysers puff to the south." on the pad
   in a bright band of fresh nitrogen frost (bluish white, gentle swells, water-ice boulders), the golden portal home
   three steps away, Spout the helper robot, the rover and the drone, the aliens' camp (Puffle the explorer, Glim the
   trader) a short walk away on the frost; the Space Book marks Triton.
3. **The sky:** a very thin nitrogen air: black and starry by day, a faint cold haze low down; the **Sun a tiny, very bright
   star** (1/30 as wide as at home); **Neptune big and deep blue low over the north-east horizon**, faint paler bands,
   its great dark spot and a white cloud, **never moving** (day and night in the same place: Triton always shows it the
   same face); two of its small moons as points. Soft icy chimes; Debussy's The Snow Is Dancing by day, the Moonlight
   Sonata at night. No animals, no monsters.
4. **The Neptune Lookout** (~13 blocks north-east of the pad, towards Neptune): a round floor of pale pink cap bricks, a
   brass telescope on a truss looking north-east and up at Neptune, a globe of Neptune (deep blue, its dark spot) on a
   post, a glowing blue beacon. Standing on it: "You found the Neptune Lookout! Triton always shows Neptune the same face,
   so Neptune never moves here."
5. **Jumping:** gravity 0.079 (real: 0.779 m/s²): a jump floats ~21 blocks up and lasts ~10 s (measured 21.4 blocks,
   4.8 s up); a one-block step is the Moon's gentle hop. The band, the cap, the cantaloupe terrain and the lake step one
   block at most; the crater's bowl two.
6. **The pink polar cap** (from ~60-110 blocks south of the pad, and on south for ever): pink nitrogen ice, a little
   higher than the band, mottled with darker patches, glowing nitrogen crystals here and there. On it: "You reached the
   south polar cap! Sunlight turns a little methane in its nitrogen ice pink."
7. **The geysers** (on the cap, at most one per 96 × 96 blocks; the first ~125-150 blocks south of the pad, alone within
   100): a dark vent (five blocks in a plus) in a ring of dark dust, flush with the ice. Every ~9 s each vent near the
   child erupts for 3 s: puffs of dark dust and a little white frost rise and drift away north-east on the wind. **Step on
   a vent: a gentle puff carries the child up about 32 blocks, and Triton's thin wind drifts it north-east** (~28 blocks
   in the smoke) while it floats down for ~11 s; the child can steer across the wind; landing ends the ride. Nothing
   hurts. At a geyser: "You found a geyser! It blows nitrogen gas and dark dust about 8 km high. Step on it for a ride!"
8. **Dark streaks:** from each vent a streak of dark dust runs 40-72 blocks north-east across the pink ice, narrowing and
   breaking into specks at its end (the first geyser's is 44). On one: "You found a trail of geyser dust! The thin wind
   blew it as far as 150 km across the ice." (The sight's id is `trail`: the game keeps the word "streak" out of its
   text, `test_no_guilt_words`; MY MAP says "Dark Streaks".)
9. **The cantaloupe terrain** (~105-150 blocks north-west, and on for ever): greyish-green ice in dimples ~26 blocks
   across, each sunk in its middle, with pale ridges between them (a pattern like a melon's rind); far to the west it fades
   back into the band by the cap's edge. There: "You found the cantaloupe terrain! Its dimples and ridges look like the
   skin of a melon."
10. **The frozen lake** (~150-190 blocks north-east): a walled plain, a flat floor of pale blue-grey ice lava ~76 blocks
    across, 4 under the band, its walls six terraces of one block up to a flat rim. On its floor: "You found a frozen
    lake! Icy lava of water probably flooded this plain, then froze flat."
11. **The lone crater** (~115-140 blocks east): a bowl ~20-26 across dug through the frost into cream nitrogen ice, a low
    rim; it is the only one (Triton's ground is young). In it: "You found one of Triton's few craters! Its ground is
    young: new ice keeps covering old craters."
12. **The Hopper Lander** (the landmark, a short walk from the pad, facing it): four truss legs, a body in gold foil with a
    rocket nozzle under it, a white deck with a lamp on each corner and the golden chest, a big white tank of nitrogen in
    its middle, a scoop arm down to a heap of frost at its side, a glowing power pack on an arm at its back (its heater), a
    radio dish on a mast, two steps up its front, and the two scorched rings of its last hops on the ground behind it. On
    its deck: "You found the Hopper Lander! Scientists have planned a lander that hops, using Triton's ice as rocket
    fuel."
13. **Secrets** (the Secret Book counts them): buried treasure under an X of glowing nitrogen crystals, a hidden pink-ice
    room behind a fake pink-ice door lit by nitrogen crystals, the explorers' station (the puzzle temple in cap bricks
    with blue beacons: friendly and made up), nitrogen crystal geodes in the water ice. None on the lake, the crater or a
    geyser.
14. **Spout** (the helper robot): "Triton goes round Neptune backwards: it is the only big moon in the solar system that
    does." Its sample: pink nitrogen ice; its quest: which way Triton goes round, what the geysers blow, why Neptune never
    moves. The hints say Neptune probably caught Triton from the Kuiper Belt, and that Triton and Pluto are icy cousins.
15. **Tilly** (Survivor) sells Triton's frost and ices, geyser dust, the cantaloupe terrain's ice and ridges, ice lava,
    nitrogen and water ice, nitrogen crystals, the nitrogen tank, a Neptune globe, blue beacons, cap bricks, a telescope and
    the landing pad at home prices; never star gold, the fake door or a geyser.
16. **Nothing hurts:** the cold (about −235 °C) is a fact, never a danger; the geysers are a ride; no word says anything
    hurts, freezes, explodes or is scary (`test_the_cold_and_the_geysers_are_never_a_danger`); the smoke checks the hearts
    after the ride.
17. **Home:** walk into the portal or fly up and tap HOME: back on the take-off column.

## How it plugs in

- **New files:** `world/universes/triton.gd` (the descriptor), `world/universes/triton_blocks.gd` (page 42),
  `world/generators/triton_terrain.gd` (`TritonTerrain`: the regions as pure rules, the Neptune Lookout's boxes),
  `data/blocks/pages/triton{,_albedo,_normal}.png` (+ imports with the pages' import settings), `tools/triton_smoke.gd`,
  `tools/triton_smoke_steps.gd`, tests (below).
- **Shared, small and additive:** `data/blocks/block_ids.gd` (ids, names, `SPACE_GROUND`, `COUNT` 736,
  `NEXT_PAGE_FIRST_ID` 736), `world/block_library.gd` (one register line), `world/generators/space_shape.gd` (planet
  `TRITON`: a branch per method, `triton_columns`, `triton_kind`, `_triton_block_at`, `_triton_calm`, the lookout placed
  after the pad, `_by_lookout` for both lookouts, `sight_at` / `sights`, `vents_near` / `has_vents`, boulders and nitrogen
  crystals as features), `world/generators/space_generator.gd` (Triton's stack, `_write_triton_column`, the lookout in
  `_place_colony` and `reference_block`), `world/generators/space_secret_rules.gd` (Triton's palette, `_hopper_lander`,
  `_fits` through `steep_near`), `world/generators/secret_rules.gd` (`is_fake_wall`), `world/universes/universe_registry.gd`
  (`SPACE[27]`), `world/sky_cycle.gd` (a sky planet's `spot_color`), `world/space_geysers.gd` (Triton's dark dust and
  frost, `plume_wind`), `core/rules/pad_rules.gd` (the nitrogen geyser: `PUFF_SPEED`, `WIND`, the drift),
  `entities/fx/pad_fx.gd` (the ride's puff), `core/rules/space_rules.gd` (`WORLDS` has 27), `core/rules/mission_rules.gd`
  (Triton's row, a mission's `skim`, the board's heat-shield line), `core/rules/rocket_check.gd` (`skim`: a heat shield,
  never a parachute), `core/creatures/alien_rules.gd` (the band of frost is the camp's ground),
  `core/creatures/creature_words.gd` (Spout, Puffle, Glim, three souvenirs), `core/magic/mini_rules.gd` (`alien_puffle`),
  `entities/flight/flight_looks.gd` (`SUN_SIZE`), the natural-block lists (`bot_rules`, `surprise_rules`, `capture_rules`,
  `gather_rules`, `chat_commands`), `ui/universe/universe_art.gd` (Triton's card), `core/rules/loading_hints.gd` (eleven
  hints), `tools/make_space_atlas.gd` (`-- triton`), `tools/make_space_realistic.py` (`triton`), `tools/bench_generator.gd`
  (`BENCH_TRITON_<REGION>`, `BENCH_TRITON_SHAPE`), `tools/shader_probe_steps.gd` (the census's `"triton": 27`),
  `docs/DEVELOPMENT.md`, spec §21b.2 ("As built"), `docs/devlog/parts/missions.md` (Triton's row), `assets/CREDITS.md`.
- **Not touched:** the School, the Science Lab, `ui/space/*` (the Star Map UI), `StarMap` (Triton's card already had
  world 27 and its facts), `FlightPlan` (its "about 12 years" was Triton's already), the colonies, the server, the other
  worlds' files, the grade 7 agents' files.
- **Shared tests updated:** `test_space_rules` (WORLDS), `test_space_registry` (warm_space, space_available),
  `test_planet_universes` (space_available), `test_realistic_pack` (TritonBlocks.FILES), `test_block_id_space` (736, page
  43), `test_block_pages` (page 42 is 720), `test_robot_words` (the camps), `test_mission_rules` (the missions' order),
  `test_robot_creatures` (+1: Triton's robot and camp), `test_pluto_blocks` (`COUNT` and the next page `>=` 720, as the
  rings' test does), `test_page_sizes` (the 70 MB budget). The shared planet tests (`test_space_shape`,
  `test_space_secrets`, `test_space_generator`, `test_alien_rules`) now also run for Triton (it is in
  `SpaceShape.PLANETS`); the census test (`test_every_world_s_landing_is_in_the_census_steps`) passes with its entry.

## Rulings (decided on the owner's behalf; cost if wrong)

1. **Triton is a planet kind of `SpaceShape`, its regions in `TritonTerrain`**, and what it looks up (the cap's line, the
   first geyser, the lake, the crater, the cantaloupe terrain's line, the streaks' directions) is built in `_init`, before
   any generator thread starts, and only read afterwards; the other geysers, streaks and dimples come from hashes per cell
   (no table): no lock, no cache. *Cost:* none (0.18 ms to build a shape).
2. **The world is Triton in small, its parts where Voyager 2 saw them relative to each other:** the pink cap to the south
   (it was southern summer in 1989), the cantaloupe terrain to the north-west (the west of the imaged hemisphere), the
   smooth walled plains north-east of it, a bright band of fresh frost between them (the "bluish-green band" round the
   equator), a lone crater. Scale: the real dimples are ~30 km across (26 blocks), a walled plain ~200 km (~100 blocks),
   the streaks up to ~150 km (40-72 blocks). *Cost:* constants in `TritonTerrain`.
3. **Under the frost Triton uses Pluto's nitrogen ice and water ice** (NASA: "a crust of frozen nitrogen over an icy
   mantle"; Pluto is its cousin), so page 42 holds only Triton's own surface blocks. *Cost:* two blocks of its own on page
   42 (ids 734-735 are free).
4. **The geysers are a ride, safe and fun:** a vent is a pad at any time (not only while its plume erupts): a gentle puff
   (`PUFF_SPEED` 11 m/s: ~32 blocks up at 0.079, ~11 s in the air; Europa's plumes throw at 16) and a drift north-east at
   2.5 m/s for up to 12 s, easing out; landing ends it; the child steers across it. There is no fall damage. *Cost:*
   constants in `PadRules`.
5. **The wind blows north-east** (east +x, north −z): the direction the dark deposits run from most vents on the south
   polar cap ("southwesterly winds then transported the erupted particles, which formed gradually thinning deposits to
   the northeast of most vents": NASA/JPL). The winds really change with height (the plumes rise ~8 km first). *Cost:*
   `PadRules.WIND`.
6. **The first geyser stands alone** (no other within 100 blocks) ~125-150 blocks south of the pad, its streak exactly
   north-east and 44 long (so a child finds a clear one); the others at most one per 96 × 96 cell (70 %), deep in the cap.
   Voyager 2 saw 4 active plumes and ~50 streaks over a far bigger cap. *Cost:* constants.
7. **Neptune is 100 across, low in the north-east** (~13° up: the day views at the pad show it over the horizon; at 33° it
   was above them), not its real ~8° (16 times our Moon's width, our arithmetic): the game's sky is not to scale, like
   every world's. It shows the Great Dark Spot Voyager 2 saw in 1989 (gone since; new ones have appeared: NASA) with a
   sky planet's new `spot_color` (Jupiter's spot stays red without one). *Cost:* numbers in the descriptor.
8. **The Sun `sun_size` 0.033** (Neptune is ~30 AU out: 1/30), **the usual day**: Triton turns once per orbit (5.9 days),
   backwards, on a tilted orbit, and its poles have seasons lasting decades; the game keeps its usual day and says nothing
   of where Triton's Sun rises (no source found for a child's sentence). *Cost:* `sun_rises_west` is one line.
9. **The sky is 80 % space's** (`space_sky` 0.8) with a faint cold haze low down: the real air is ~14 microbars (~1.4 Pa,
   about 70,000 times thinner than Earth's; Voyager 2 saw thin hazes in it). *Cost:* numbers.
10. **Gravity 0.079, the real one** (0.779 ÷ 9.81), the spec's "0.08" rounded. *Cost:* none.
11. **The Mission to Triton stays by skimming Triton's thin air:** 9.4 + 7.4 + 0.3 + 1.4 = 18.5 km/s, a mission's new
    `skim` (not `air`): the check wants a heat shield (to skim) and never a parachute (Triton's air is far too thin to land
    with: the lander comes down on its engines). The real spacecraft took 12 years (swinging past Jupiter, Saturn and
    Uranus) and flew on; a 12-year trip with one swing past Jupiter from a 200 km orbit needs ~7.4 km/s and arrives ~10.1
    km/s too fast (our patched-conic arithmetic: circular orbits in one plane, a Lambert search over the legs' times and
    angles; C3 ≈ 110 km²/s²); braking that and matching Triton by engines would be ~7.5 more (25.7 in all: no rocket of up
    to 7 stages the pad holds, the search below). A study (Brisby and Lyne, 2023, from their group's 2004 work) captures a
    probe into orbit round Neptune by an "aerogravity assist" through Triton's thin air behind NASA's flight-proven blow-up
    heat shield (LOFTID, flown in 2022), at entry speeds of 3-14 km/s: the game's heat shield stands for it; the 0.3 for the
    trims and Triton passes after it is our estimate; down onto the ice ~1.4 (Triton's escape speed is 1.455 km/s). A
    rocket of 266 parts (~9,125 gold) passes the check (`test_a_rocket_a_child_can_build_reaches_triton`): more than
    Pluto's 239 (8,200) for its longer trip (4,380 crew-days: 22 service modules). `FlightPlan.has_air` stays false: the
    flight lands on its legs. *Cost:* `skim` is two branches (the check and the board); Pluto's rule (a heat shield and a
    parachute) is `"air": true`.
12. **`InventionRules.air(TRITON)` stays NO_AIR** ("There is no air here …"), like Pluto's: its air is far too thin for
    wings or a kite. *Cost:* a Triton line in the inventions' words.
13. **Names:** MY MAP's "Neptune Lookout", "Geyser", "Dark Streaks", "Pink Polar Cap", "Cantaloupe Terrain" (NASA's own
    everyday words), "Frozen Lake", "Lone Crater"; the IAU's names of its places (Uhlanga Regio, Bubembe Regio, Ruach and
    Tuonela Planitiae, Hili, Mahilani, Mazomba, Leviathan Patera) are not used (long names from myths; spec §21b.2's
    general words); "The Hopper Lander" (a description, not the study's name), Spout, Puffle and Glim are made up. A test
    reads every Triton word for Voyager, NASA, ESA, JPL, Hubble, NIAC, Trident, Neptune Odyssey, LOFTID, "Triton Hopper"
    and those place names.
14. **Steps:** the band, the cap (its rise 2 over 14 blocks), the cantaloupe terrain (dimples 2.5 deep over ~10 blocks,
    ridges 1 high over 4) and the lake (terraces of one block, two wide) step one block at most; the crater two
    (`MAX_STEP` 2; a jump reaches ~21). Far west, where the cantaloupe terrain meets the cap, it fades back to the band by
    the cap's edge (the first test run found a 3-block step there). *Cost:* constants.
15. **The Neptune Lookout is a built part** (`TritonTerrain.place_lookout`, called once by `SpaceShape._init` after the
    pad), 9 east and 9 north of the pad (just outside the pad's flat circle); written with the colonies' flag;
    `tree_at` keeps its ground. *Cost:* none.
16. **Few craters, one crater:** a single crater ~115-140 blocks east (radius 10-13) and no others, for "extremely young
    and sparsely cratered" (NASA). *Cost:* a rare crater per cell is a few lines.
17. **The frozen lake's words say "probably"**: NASA calls the two big walled plains "of unknown origin", while the smooth
    plains round them are "formed by icy lavas" of "water and other ices"; they are thought to be frozen lakes of icy lava.
    *Cost:* none.
18. **Sounds:** no new audio: chimes day and night (the air is far too thin to carry wind), Debussy's The Snow Is Dancing
    (by day) and the Moonlight Sonata (by night). *Cost:* a `MusicPieces` entry for a CC0 recording.
19. **The realistic pages' budget went from 64 to 70 MB** (63.8 MB with page 42; a page of three rows adds ~1.6 MB: room
    for about four more). *Cost:* the APK grows ~1.6 MB a page.

## The facts (every Triton fact in the game, and its check)

| Where | Words | Check |
|---|---|---|
| gravity | 0.079; hint "On Triton you jump about 12 times as high!" | 0.779 m/s² (0.0794 g) ([Wikipedia: Triton](https://en.wikipedia.org/wiki/Triton_(moon))); 1 ÷ 0.079 = 12.7 |
| robot, hints | "Triton goes round Neptune backwards: it is the only big moon in the solar system that does." | "the only large moon in our solar system that orbits in the opposite direction of its planet's rotation―a retrograde orbit" ([NASA: Triton](https://science.nasa.gov/neptune/moons/triton/)) |
| hints | "Neptune probably caught Triton from the Kuiper Belt." | "Scientists think Triton is a Kuiper Belt Object captured by Neptune's gravity millions of years ago." (NASA: Triton) |
| hints | "Triton and Pluto are icy cousins!" | "It shares many similarities with Pluto, the best known world of the Kuiper Belt." ([NASA: Triton](https://science.nasa.gov/neptune/neptune-moons/triton/)) |
| hints, sight | "Triton's geysers blow nitrogen gas 8 km high." / "It blows nitrogen gas and dark dust about 8 km high." | "an eight kilometer- (five mile-) tall cloud of fine, dark particles … the pressurized gas then escapes through vents, carrying aloft with it dark, powdery particles" (sunlight warms nitrogen ice: [NASA/JPL PIA14449](https://www.jpl.nasa.gov/images/pia14449-tritons-volcanic-plumes/)); "geysers … eject icy material upward more than 5 miles (8 kilometers)" ([NASA: Neptune facts](https://science.nasa.gov/neptune/facts/)); "eruptions of nitrogen gas" (Wikipedia) |
| sight | "You found a trail of geyser dust! The thin wind blew it as far as 150 km across the ice." | "drifting downwind … for a distance of roughly 150 kilometers" (PIA14449); "about 50 dark plumes or 'wind streaks' … some are more than 100 miles long … Southwesterly winds then transported the erupted particles … deposits to the northeast of most vents" ([NASA/JPL PIA00059](https://www.jpl.nasa.gov/images/pia00059-triton-south-polar-terrain/)) |
| sight, robot's sample | "Sunlight turns a little methane in its nitrogen ice pink." | "The pinkish deposits constitute a vast south polar cap believed to contain methane ice, which would have reacted under sunlight to form pink or red compounds. The dark streaks overlying these pink ices are … deposited from huge geyser-like plumes" ([NASA/JPL PIA00317](https://www.jpl.nasa.gov/images/pia00317-global-color-mosaic-of-triton/)) |
| sight | "Its dimples and ridges look like the skin of a melon." | "Part of its surface resembles the rind of a cantaloupe." ([NASA: Neptune's moons](https://science.nasa.gov/neptune/moons/facts/)); "a strange series of fissures and depressions … resembles the skin of a cantaloupe melon" (Wikipedia) |
| sight | "Icy lava of water probably flooded this plain, then froze flat." | "The lavas on Triton are water and other ices that erupted onto the surface"; "two large walled smooth plains of unknown origin … roughly 200 kilometers across" ([NASA: Triton's volcanic plains](https://science.nasa.gov/resource/tritons-volcanic-plains/)); Ruach and Tuonela Planitiae are thought to be cryovolcanic lakes (Wikipedia) |
| sight | "Its ground is young: new ice keeps covering old craters." | "the surface is also extremely young and sparsely cratered, and could be geologically active today" ([NASA: Triton's "cantaloupe" terrain](https://science.nasa.gov/resource/tritons-cantaloupe-terrain/)); surface ages estimated 6-50 million years (Wikipedia) |
| sight, hints | "Triton always shows Neptune the same face, so Neptune never moves here." / "Neptune never moves in Triton's sky." | "Like our own moon, Triton is locked in synchronous rotation with Neptune―one side faces the planet at all times." (NASA: Triton); its orbit is almost exactly round (eccentricity ~0.000016, Wikipedia) |
| treasure | "Triton was found in 1846, just 17 days after Neptune." | "Triton was discovered on Oct. 10, 1846 by British astronomer William Lassell, just 17 days after Neptune itself was discovered." (NASA: Triton) |
| hidden room | "Triton's ice reflects about 70 % of the sunlight that reaches it." | "its surface an icy sheen that reflects 70 percent of the sunlight that hits it" (NASA: Triton) |
| temple | "Triton is Neptune's biggest moon, a little bigger than Pluto." | "the largest of Neptune's 13 moons … a diameter of 1,680 miles (2,700 kilometers)" (NASA: Triton); Pluto 2,377 km ([NASA: Pluto facts](https://science.nasa.gov/dwarf-planets/pluto/facts/)) |
| Hopper Lander | "Scientists have planned a lander that hops, using Triton's ice as rocket fuel." | NASA NIAC "Triton Hopper" (Phase I 2015, Phase II 2018, S. Oleson, NASA Glenn): "repeatedly fly across the surface of Triton, utilizing the volatile surface ices (primarily nitrogen) as propellant for a radioisotope-heated thermal rocket engine", hops up to ~1 km high and 5 km long ([NASA](https://www.nasa.gov/directorates/spacetech/niac/2018_Phase_I_Phase_II/Triton_Hopper), [Wikipedia](https://en.wikipedia.org/wiki/Triton_Hopper)) |
| geode | "At about −235 °C, Triton is one of the coldest places known." | "surface temperatures of -391 degrees Fahrenheit (-235 degrees Celsius)" (NASA: Triton); "the coldest surface known anywhere in the Solar System (38 K)" (PIA00317, 1989); "one of the coldest objects in the solar system" (NASA: Neptune's moons) |
| Puffle's science | "Where there is water, scientists look for life. There may be an ocean deep under Triton's ice." | Triton is a candidate ocean world: a subsurface ocean is possible but unconfirmed ([NASA: Ocean Worlds: Triton](https://science.nasa.gov/resource/ocean-worlds-triton/), the NASA Roadmap to Ocean Worlds, Hendrix et al. 2019); always with CreatureWords.HONEST |
| hints | "Sunlight takes about 4 hours to reach Triton." | "4 hours to travel from the Sun to Neptune" (NASA: Neptune facts) |
| hints | "Far in the future, Triton may turn into rings!" | "Millions of years from now, Triton will come close enough for gravitational forces to break it apart – possibly forming a ring around Neptune" (NASA: Neptune's moons); in ~3.6 billion years it passes Neptune's Roche limit (Chyba et al. 1989; Wikipedia) |
| sky | the Sun 0.033 ×; Neptune deep blue with bands, a dark spot and a white cloud; two small moons | Neptune 30 AU out (NASA): 1 ÷ 30 = 0.033; the Great Dark Spot of 1989, "large enough to contain the entire Earth … has since disappeared, though new ones have appeared"; methane makes Neptune blue (NASA: Neptune facts); Neptune ~8° across from Triton: 2 atan(24,764 ÷ 354,759) (our arithmetic), 16 × our Moon's 0.5° |
| sky | black by day, a faint haze low down | surface pressure ~1.4 Pa (14 microbars), mostly nitrogen with a little methane (Wikipedia; NASA: Triton): ~70,000 times thinner than Earth's (our arithmetic) |
| mission | "4.3 to 4.7 billion km away", "about 12 years", "A spacecraft flew past Triton in 1989, 12 years after launch. To stay, skim its air behind a heat shield!" | Neptune 4.47-4.56 billion km from the Sun (NASA's fact sheet) ± 1 AU for Earth: 4.3-4.7; Voyager 2 launched 20 August 1977, past Neptune and Triton 25 August 1989 ([NASA: Voyager](https://science.nasa.gov/mission/voyager/mission-overview/)) |
| mission | 9.4 + 7.4 + 0.3 + 1.4 km/s | see ruling 11: our patched-conic search (below); the aerogravity assist at Triton: [Brisby and Lyne, "Triton Aerogravity Assist Using a Flight-Proven, Inflatable Aerobrake for Neptune Orbit Capture" (2023)](https://arxiv.org/abs/2309.15335); Triton's escape speed 1.455 km/s (Wikipedia) |

(The Star Map's own three Triton facts are the lead's, in `core/rules/star_map.gd`; unchanged.)

## Tests (RED → GREEN)

| Test file | Tests | RED (why it failed first) |
|---|---|---|
| `tests/unit/test_triton_blocks.gd` | 10 | `BlockIds.TRITON_FROST` …, `TritonBlocks` not declared — run and seen |
| `tests/unit/test_triton_geyser_pads.gd` | 4 | written with the blocks: `PadRules.PUFF_SPEED`, `WIND`, `DRIFT_*` not declared |
| `tests/unit/test_triton_shape.gd` | 16 | `SpaceShape.TRITON` not found; then a 3-block step far west where the cantaloupe terrain met the cap (it now fades out by the cap's edge) |
| `tests/unit/test_triton_generator.gd` | 7 | written with the generator's branch (`_write_triton_column`) |
| `tests/unit/test_triton_secrets.gd` | 7 | the Moon's palette on Triton; then its own list asked for water ice the secrets never use (nitrogen ice instead) |
| `tests/unit/test_triton_universe.gd` | 18 | no `triton.gd` (gravity 1.0, no sights, no hints, not in WORLDS, no mission, no `skim`) |
| `tests/integration/test_triton_sky.gd` | 4 | a sky planet's `spot_color` (Neptune's spot drawn red, Jupiter's) |
| `tests/integration/test_triton_sights.gd` | 7 | written with the descriptor; `SpaceGeysers.plume_wind` not declared |
| `tests/integration/test_triton_world.gd` | 5 | written with the descriptor (the pad, the frost, the lookout's telescope in the real terrain; save, load, mesh); a first run read a chunk not yet loaded (it now waits for it) |
| `tests/integration/test_robot_creatures.gd` | +1 | Triton's robot by the pad, the camp on the frost clear of the lookout |
| shared (see above) | | WORLDS, warm_space and space_available lists, COUNT and the next page, the realistic pack's pages, the camps, the missions, the budget |

## Measurements

Generator bench (`bench_generator.gd -- --space moon pluto triton`, 2026-09-30 19:40-19:50, the PC's load 10-12 with
another app and suites running; ms a chunk):

| chunks | Moon | Pluto | Triton | meadows beside Triton |
|---|---|---|---|---|
| warm: surface | 1.49 (worst 12.1) | 1.02 | **0.81** (worst 2.60) | 1.52 |
| warm: underground | 0.33 | 0.38 | **0.33** | 1.10 |
| warm: all | 0.88 | 0.66 | **0.54** | 1.28 |
| cold (fresh generators, a stack's chunks in a row): surface | 2.65 | 1.27 | **1.07** (worst 2.75) | 1.65 |
| cold: all | 1.70 | 0.77 | **0.67** | 1.41 |
| a new area's secrets (once, then cached) | 0.60 | 0.41 | **0.43** (worst 0.96) | — |

Triton's generator is cheaper than the Moon's (the Moon's own numbers move with the PC's load: Pluto's notes had it at
1.36-1.50 warm surface and 1.29-1.50 cold all on `lead-merge` 399beae0; this work changes nothing of it). Triton's
regions (`BENCH_TRITON_<REGION>`, fresh generators over 4 × 4 whole chunk stacks, y -64..159, against the meadows on the
same chunks): the landing 0.55 ms a surface chunk vs 1.06, the first geyser 0.71 vs 1.14 (worst 4.36), the cap 0.73 vs
1.17, the cantaloupe terrain 0.74 vs 1.15, the lake's walls 0.63 vs 0.87, the crater 0.56 vs 0.94; underground 0.35-0.38
vs 1.20-1.56. `TritonTerrain.column` costs 6.4 µs (the cap's streak look-ups and the dimples' nine cells; Pluto's 4.4);
building a Triton shape 0.18 ms.

Geography (`SpaceShape`/`TritonTerrain`, printed by a scratch script):

| seed | pad | lookout | cap's edge south of the pad | first geyser (from the pad) | frozen lake (from the pad) | crater, radius (from the pad) | cantaloupe terrain (from the pad) | geysers within 250 |
|---|---|---|---|---|---|---|---|---|
| 12345 | (0, 0) at 50 | (9, -9) | 92 | (4, 147), 147 | (114, -106), 156 | (134, 7), 11, 134 | (-92, -92), 130 | 2 |
| 77 | (0, 0) at 50 | (9, -9) | 75 | (-18, 126), 127 | (116, -108), 158 | (139, 0), 10, 139 | (-82, -82), 116 | 1 |
| 777 | (0, 0) at 50 | (9, -9) | 83 | (8, 140), 140 | (96, -138), 168 | (117, 8), 10, 117 | (-75, -75), 106 | 5 |
| 42 | (0, 0) at 50 | (9, -9) | 90 | (-6, 144), 144 | (123, -132), 180 | (132, 28), 12, 135 | (-93, -93), 132 | 2 |

Kinds over 600 × 600 blocks round the pad (seed 12345): the band's frost 39.7 %, the cap 29.7 % (mottled patches 3.7 %,
streaks 0.4 %, the vents' rings 0.1 %), the cantaloupe terrain's dimples 19.3 % and ridges 4.9 %, the lake 1.3 % and its
terraces 0.9 %, the crater 0.1 %.

The trip (a patched-conic search, circular orbits in one plane: Earth → a swing past Jupiter (periapsis ≥ 4 Jupiter
radii) → Neptune, a Lambert solve per leg over its time and angle, then matching Triton's orbit, 354,759 km from Neptune at
4.39 km/s): a Hohmann transfer takes 30.6 years (8.25 km/s from a 200 km orbit, 4.05 km/s over Neptune's speed on
arrival); in 10 years 7.86 + 9.81 to Triton's orbit (arriving 12.8 km/s fast), **in 12 years 7.42 + 7.46 (C3 110 km²/s²,
arriving 10.1 km/s fast)**, in 14 years 6.95 + 6.12, in 16 years 6.56 + 5.27. The rocket (a search over `RocketParts`'
numbers with `RocketCheck`'s rules, a Pareto front stage by stage, the same that finds Pluto's 233-239): with the skim
(18.5 km/s, 4,380 crew-days, a heat shield) 266 parts, 9,125 gold, 6 stages (stage 1: 54 rocket engines, 1 tank, 3 fins;
then 40 space engines and 82 tanks, 12 and 24, 4 and 6, 2 and 3, 1 and 1 with the capsule, 22 service modules, the heat
shield, 3 legs, the solar array); without it (25.7 km/s) none within 7 stages.

## Smoke run

- `tools/triton_smoke.gd` (through `tools/smoke_all.sh triton`: a private folder with "smoke" in its path and a copy of
  `profile.json`): **55 checks, 0 fails** (exit 0, 69 s; again after the trail's rename: 55, 0, 66 s): a new Green Meadows Sandbox world; the Star Map; Triton's card
  (3 facts, LAND); Triton's own world `sandbox_27`, its terrain, gravity 0.079, space_sky 0.8, the Sun 0.033, stars by day,
  never the photo sky, Neptune huge in the north-east, never home's moon disc, on the landing pad, peaceful, no animals,
  MY MAP's pad and seven sights, the Space Book's LANDED mark, the sights watched, the geysers watched, solid ground (no
  void), Spout and the camp on the frost; the portal home by the pad; the lookout's telescope and globe; a slow fall
  (0.54 m/s after 0.3 s); **a jump 21.4 blocks up (4.8 s to its top)**; the Hopper Lander is the landmark and standing on
  its deck finds it, then MY MAP shows it; the seven sights say their facts; **a geyser's puff carried the child 32.0
  blocks up and the wind drifted it (19.8, 0, −19.8): ~28 blocks north-east in 11.6 s**; nothing hurt the child (health
  20); through the portal home: Green Meadows `sandbox_1`, on the take-off column, home gravity, home's own sky and Sun.

## Pictures (`tools/space_shots.gd -- --universe=27 --sights`, windowed, both styles)

Seen: from over the pad by day, a starry black sky with a faint dark-blue glow at the horizon over a bright white band of
frost with soft one-block contour lines and scattered blue-grey boulders; the Hopper Lander (white tank, gold body) and the
camp nearby; the pink cap's edge far to the south. At the first run Neptune (at 33° up) was above every day view (only the
night view, looking up, showed it: deep blue, paler bands, the dark spot): it went down to ~13°, and the north and east
views now show it big and blue over the north-east horizon. The sights: the pink cap with darker mottled patches and a
long dark streak running north-east from a vent, a puff of dust rising from it; the cantaloupe terrain's greyish-green
dimples with pale ridges (a honeycomb of cells from above); the frozen lake's flat pale floor inside its ring of
terraces; the lone crater's terraced bowl in the frost. Sunset dims the frost to blue-grey under a purple sky; night is
black and starry with Neptune in it. REALISTIC looks close to BLOCKY at 640 × 360. Stars show through Neptune's disc (the
sky's star layer is drawn over sky planets: Europa's Jupiter too). A "Theater" stands near the pad (the places system's,
not Triton's).

## Full suite

`tests/run_tests.sh` (2026-09-30 19:59-20:52, the PC's load 10-17, on the code of commit 45a6b564): **998 scripts, 9096
tests, 9093 passing, 1 failing, 2 risky** (`test_meadows_biome_generator.gd`'s two that never assert, as before this
work), no script errors (3128 s). The failure: `test_no_guilt_words` found the word "streak" in the sight's id and its
words (the game keeps that word out of its text: no streak mechanics); the sight became `trail` ("You found a trail of
geyser dust! …", MY MAP still says "Dark Streaks"), and that test, the Triton tests it touched (shape, universe, sights,
generator: 49) and the smoke (55 checks, 0 fails) passed again. The neighbours' smokes after this work's shared changes
(`tools/smoke_all.sh pluto europa io mission`: Pluto's lookout helper, Europa's and Io's geysers and pads, the missions'
check): **4 passed, 0 failed**. After it, the card's plume was drawn a little tighter (art only).

## The lead's checklist (emulator, both styles)

1. Sandbox, Green Meadows: fly up; on the Star Map tap Triton: MISSION until the Mission to Triton is flown (or LAND after
   a landing); Neptune's card says there is no ground; the loading card shows Triton's picture (the Hopper Lander on the
   frost, the pink cap with a dark streak and a vent, the geyser's dark plume drifting right, huge blue Neptune with its
   dark spot, the tiny Sun) and a Triton hint. The Mission Board lists the Mission to Triton (18.5 km/s, about 12 years,
   "A heat shield to skim its thin air", no parachute); the check with a heat shield and no parachute passes; the flight
   lands on its legs (airless).
2. **Performance** (≥ 30 FPS, no frame over 100 ms): the autopilot with `--universe=27`, both styles; the cap's streaks
   and the cantaloupe terrain's dimples are the busiest columns (the shape is built at the world's load in ~0.2 ms on the
   PC). A geyser erupting near the child puffs 12 particles every 0.3 s for 3 s of every 9 (Fx's particle scale applies).
3. **The geyser ride** (the first geyser ~125-150 blocks south of the pad, on MY MAP): step on the dark vent: up ~32
   blocks in ~6 s, then a slow float north-east (~28 blocks) for ~6 s more; fun or too long? (`PadRules.PUFF_SPEED`,
   `DRIFT_SPEED`, `DRIFT_TIME`; ruling 4). Does the camera follow nicely? Can a child steer back to the vent?
4. **The feel of 0.079 gravity:** jumps ~21 blocks and ~10 s; a one-block step is a floaty hop.
5. **The sky on a phone:** Neptune's size and place over the north-east horizon (ruling 7), the stars over its disc, the
   black sky with the faint haze (reads as day? the ground is brightly lit), the Sun as a tiny bright star.
6. The pink cap's colour against the band's white frost; the dark streaks (visible from a distance?); the cantaloupe
   terrain's dimples and ridges (read as a melon's rind?); the frozen lake's terraces; the crater.
7. The Neptune Lookout (the telescope pointing at Neptune), the Hopper Lander (its tank, deck, chest, scoop, the scorched
   rings behind it).
8. Spout by the pad, Puffle's and Glim's camp on the frost, the rover and the drone; Tilly and the Totem (Survivor).
9. Survivor: the bag goes to Triton and home; Tilly's Triton things; a gift or showcase holding a Triton block.
10. Page 42's first frames compile its materials (like any new universe). The realistic pages: 63.8 of 70 MB.
11. **The census** (`tools/shader_probe_steps.gd` now has `"triton": 27`): run it again after the merge so Triton's loading
    card warms page 42's materials and Neptune's and the Sun's looks (the geysers' puffs are Fx bursts like Europa's).

## Next (the game never ends)

Ice volcanoes (Leviathan Patera's caldera and its dark flows), the long double ridges (sulci) crossing the cantaloupe
terrain, more walled plains and the smooth plains' pits and chains of mounds, Triton's seasons (its south pole in a summer
lasting decades: the cap shrinking and growing), the geysers' plumes tall enough to see from the pad, Neptune's faint rings
and its arcs, Proteus and Nereid named in the sky, the Great Dark Spot's successors, Neptune as a world of its own (no
ground: a cloud-top station like Venus's?), a drag-free landing on its engines in the flight, a Planet Book page for
Triton.
