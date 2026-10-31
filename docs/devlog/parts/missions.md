# Missions: build a rocket to reach a planet (owner #78, #79; spec §21d, §25.3)

Brief: `docs/superpowers/plans/2026-09-29-missions-brief.md`. Branch `worktree-agent-a60a08880c24d11b9`, cut from
`lead-merge` at `a76dc64e` ("test(platform): owner #84 …"). No editor, no emulator, no adb. Built test-first; the
numbers of every check are worked out by hand in `tests/unit/test_rocket_check.gd`.

## What a child sees and does
1. **A Launch Site near home.** Every home world (Sandbox and Survivor, never Monster Wave's arena, never a space world)
   has one about 36 blocks from the spawn, never in the Theater's direction: a concrete plaza with the **launch pad** (a
   9 × 9 build square in a ring of yellow-and-black stripes, real voxel blocks), an orange-and-white **service tower**
   with two short arms over the stripes, and **Mission Control** (a white building with a teal roof, a window band and a
   dish) with the **Mission Board** in front of it, facing the spawn ("MISSION BOARD", "Walk up to me!").
2. **The Mission Board** opens by walking up to it (X, Esc or Android Back close it; after X it stays closed until the
   child walks away and back). Three big tabs, read aloud by the speaker button:
   - **MISSIONS**: the Moon, Mars, Europa, Io, Titan, Mercury, Venus (each built planet world), each card with the planet, how
     far it is, how long the real trip takes, one real fact, what its rocket needs (the speed in km/s by legs, a seat,
     air and water for N days, 3 landing legs and a solar array, a heat shield and a parachute where there is air) and
     whether it is on the child's route. CHOOSE picks the mission; OPEN THE STAR MAP appears once a planet is reached.
   - **MY ROCKET** (the rocket science panel): the bar from the ground to the planet (Earth orbit, on to it, braking and
     landing, each as long as its speed change) with "Your rocket: 15.6 km/s" on it, each stage's parts and numbers
     ("Stage 1: 8 Rocket Engine, 10 Fuel Tank, … Push 2,000 t, 1,035 t full, 95 t empty: +2.7 km/s"), then green ticks
     and kind "not yet" lines, each with what real rockets do, then CHECK AGAIN and **LAUNCH** (only when every line
     passes) and one line of rocket science (the rocket equation in words).
   - **PARTS** (the Launch Site's shop): the 12 parts with their pictures, what each does, its numbers, what real ones are
     made of, its price and "you have N"; BUY; in the Sandbox **BUY WHAT MY ROCKET STILL NEEDS: N gold**; in Survivor
     how to make the simple ones ("Make 2 at a Workbench: 1 Iron.").
3. **Building**: parts are ordinary blocks: the Sandbox palette's SMART page has a **SPACE** row (every part, free to
   place: building is free), Survivor places them from the bag. Friends in a shared world build on the same pad.
4. **Launch**: LAUNCH hands the rocket over (`fly`); until the flight is merged the child lands on the planet at
   once: "Mission complete! You landed on the Moon! Jump: you float!". The rocket stays on the pad at home (a copy
   flies).
5. **The route**: a planet reached once (a mission, or a landing before missions: the Space Book) is on the route: the
   Star Map's LAND works for it. One not reached says **"Mission needed: build a rocket at the Launch Site"** (its card
   and facts still free); flying there is refused with the same words. Planet Boing and Rainbow Planet stay reachable by
   flying up.

## The numbers (RocketParts, MissionRules; real-ish, rounded for children)
A block is a big module: a fuel tank holds 94 tonnes, an engine pushes 250. The rocket equation is the real one,
Δv = Isp × g₀ × ln(full ÷ empty) per stage (g₀ 9.80665 m/s²), each stage carrying the full stages above it.

| Part | Full t | Empty t | Push t | Isp s | Gives | Gold | Real reference (rounded) |
|---|---|---|---|---|---|---|---|
| Rocket Engine | 4 | 4 | 250 | 300 | | 50 | kerosene engines: 282-311 s (small, 86 t) to 263-304 s (the biggest, 690 t); a big one ~250 t |
| Space Engine | 3 | 3 | 150 | 450 | never stage 1 | 60 | hydrogen upper-stage engines: 420-465 s in vacuum, 10-190 t |
| Fuel Tank | 100 | 6 | | | 94 t of fuel | 15 | a modern stage's dry mass is 4-8 % of its full mass |
| Nose Cone | 1 | 1 | | | pointed top | 10 | |
| Crew Capsule | 5 | 5 | | | 1 seat | 80 | the 1960s Moon capsule: about 5.8 t for 3 people |
| Service Module | 4 | 4 | | | 200 crew-days | 40 | a person needs ~0.8 kg oxygen, ~3.5 kg water, ~1.8 kg food a day; the space station reuses ~98 % of its water |
| Heat Shield | 2 | 2 | | | air worlds | 40 | ceramic tiles or a charring resin |
| Landing Legs | 1 | 1 | | | 3 needed | 15 | landers stand on 3 or 4 legs |
| Rocket Fins | 0.5 | 0.5 | | | 3 needed on stage 1 | 5 | (big rockets also steer by tilting engines: the words say so) |
| Stage Separator | 1 | 1 | | | splits stages | 10 | |
| Solar Array | 0.5 | 0.5 | | | power | 20 | |
| Parachute Pack | 1 | 1 | | | air worlds | 30 | landers on Mars and Titan used parachutes |

Rules (RocketCheck): lift-off needs the first stage's push ≥ 1.1 × the whole weight (real rockets lift off at 1.15-1.5);
an upper stage pushes ≥ half of what it carries (stages that finish the climb run at 0.5-1.0); an engine pushes only
with room for its flame (nothing of its own stage under it); space engines never count in stage 1; the crew rides the
last stage: seats ≥ crew, air and water ≥ crew × the trip's days, 3 legs, a solar array, an engine and a tank to land,
a heat shield and a parachute where there is air; 3 fins on stage 1; the very top is a nose cone or a capsule; in the
Sandbox every part on the pad bought.

| Mission (world) | Legs, km/s (from the ground) | Need | Trip (crew days) | Air | Sources, rounded |
|---|---|---|---|---|---|
| The Moon (16) | Earth orbit 9.4, to the Moon 3.3, into orbit round it and down 2.6 | 15.3 | about 3 days (3) | no | surface→low Earth orbit ~9.4 (7.8 orbital + losses); low orbit→lunar surface ~5.9 (trans-lunar injection ~3.2, capture ~0.8, descent ~1.8): the Delta-v budget tables and the solar system delta-v map |
| Mars (19) | 9.4, to Mars 3.6, into orbit round Mars 2.1, down through its air 1.0 | 16.1 | about 7 months (210) | yes | trans-Mars injection ~3.6; capture ~0.7 + to low orbit ~1.4; with a heat shield and parachute the engines do only the last ~1 of the ~4 km/s a landing without air would need; a rover's cruise took 203 days; windows every 26 months |
| Europa (20) | 9.4, to Jupiter 6.3, past Jupiter's moons and down 3.5 | 19.2 | about 2 years 9 months (1000) | no | to Jupiter ~6.3 from low orbit (the simple Hohmann route: ~2.7 years); the last leg is an estimate with flybys of the moons (direct it is ~6.8); real probes took 5-6 years |
| Io (21) | 9.4, 6.3, deep into Jupiter's pull and down 4.0 | 19.7 | 1000 | no | as Europa, deeper in Jupiter's pull (an estimate) |
| Titan (22) | 9.4, to Saturn 7.3, into orbit and down through the air 0.8 | 17.5 | about 6 years (2200) | yes | to Saturn ~7.3 (Hohmann ~6 years); a probe landed on Titan in January 2005 under parachutes |
| Mercury (23) | 9.4, to Mercury 5.5, braking against the Sun's pull and down 9.4 | 24.3 | about 4 months (105) | no | to Mercury ~5.5; arriving ~9.6 km/s fast, braking to land ~9.4 (the fastest, direct way); real probes took 6.5-7 years of flybys to save fuel |
| Venus's cloud city (24) | 9.4, to Venus 3.5, down through its thick air to the cloud city 0.5 | 13.4 | about 5 months (146) | yes | LEO → Venus Hohmann ~3.5 km/s, 4.8 months (Wikipedia: Delta-v budget); its thick air brakes a heat shield and a parachute (a cloud-city study's aerocapture and entry, a small clean-up burn); the last 0.5 our estimate; real probes took 3½-5 months (added by Venus's agent, `docs/devlog/parts/cosmos-venus.md`) |
| Saturn's rings (25) | 9.4, to Saturn 7.3, into orbit round Saturn 0.6, braking in Saturn's thin upper air, then keeping up with the chunks 2.7 | 20.0 | about 6 years (2200) | no | to Saturn ~7.3 (as Titan's); a real capture burn at Saturn took 0.626 km/s (2004); dips through Saturn's thin upper air (aerobraking: first done at Venus in 1993, then at Mars) lower the far end of the orbit to the rings for no fuel, then a burn there matches the chunks (~19 km/s round Saturn in the B ring): 2.7, our estimate (orbital mechanics, in `docs/devlog/parts/cosmos-rings.md`); without the dips, ~6.8 (a rocket of ~1,000 parts); no air in the rings: no heat shield or parachute (added by the rings' agent) |
| Pluto (26) | 9.4, to Pluto, swinging past Jupiter 8.9, slowing in Pluto's thin air under a giant balloon, then down 0.3 | 18.6 | about 9 and a half years (3470) | yes | New Horizons: launched 19 January 2006 with C3 = 157.75 km²/s² (from a 200 km orbit √(157.75 + 121.19) − 7.78 = 8.9 km/s, our arithmetic), a Jupiter swing-by in February 2007 (+4 km/s, three years saved), past Pluto on 14 July 2015 (9.5 years) at ~14 km/s: stopping by engines would add ~14 (about 32 in all: no rocket of the pad's parts reaches it); a NASA NIAC study (Pluto Hop, Skip, and Jump, 2017-2021) slows a lander from its fast trip in Pluto's thin, tall air under a large, light drag envelope to ~120 m/s at the surface with a few kg of propellant: the game's heat shield and parachute stand for it, the last 0.3 our estimate; a rocket of 239 parts, ~8,200 gold, passes the check (`test_a_rocket_a_child_can_build_reaches_pluto`; added by Pluto's agent, `docs/devlog/parts/cosmos-pluto.md`) |
| Triton (27) | 9.4, to Neptune, swinging past Jupiter 7.4, skimming Triton's thin air behind a blow-up heat shield, to stay 0.3, down onto Triton's ice on the engines 1.4 | 18.5 | about 12 years (4380) | no (`skim`: a heat shield, no parachute) | Voyager 2: launched 20 August 1977, past Neptune and Triton 25 August 1989 (12 years, swinging past Jupiter, Saturn and Uranus), and it flew on; a 12-year trip with one swing past Jupiter from a 200 km orbit needs ~7.4 km/s (C3 ≈ 110 km²/s²) and arrives ~10.1 km/s too fast (our patched-conic arithmetic, circular orbits in one plane); braking that and matching Triton's orbit by engines is ~7.5 more (25.7 in all: no rocket of up to 7 stages the pad holds); a study (Brisby and Lyne, 2023) captures a probe into orbit round Neptune by an aerogravity assist through Triton's thin air behind a flight-proven blow-up heat shield (NASA's LOFTID): the game's heat shield stands for it, 0.3 our estimate for the trims; Triton's escape speed 1.455 km/s: ~1.4 down on the engines (its air is far too thin for a parachute); a rocket of 266 parts, ~9,125 gold, passes the check (`test_a_rocket_a_child_can_build_reaches_triton`; added by Triton's agent, `docs/devlog/parts/cosmos-triton.md`) |
| Ganymede (28) | 9.4, to Jupiter, swinging past the Moon, Venus and Earth 3.5, into orbit round Jupiter, then past its moons again and again to slow down 2.1, into orbit round Ganymede and down onto its ice 2.5 | 17.5 | almost 12 years (4260) | no | the real spacecraft on its way: launched 14 April 2023 with ~2.5 km/s past Earth's pull (from a 200 km orbit √(2.5² + 121.19) − 7.78 = 3.5 km/s, our arithmetic), flybys of the Moon and Earth (August 2024), Venus (August 2025) and Earth (September 2026, January 2029), Jupiter in July 2031 (orbit insertion ~0.95 km/s), 35 flybys of Jupiter's moons, Ganymede's orbit in December 2034 (its whole budget ~2.7 km/s, the Ganymede phase 0.61): 2.1 + 0.6; down from a 500 km orbit ~1.9 (our estimate); the straight route (Hohmann, like Europa's row) would need ~21.9; a rocket of 209 parts, ~7,115 gold, passes the check (`test_a_rocket_a_child_can_build_reaches_ganymede`; added by Ganymede's agent, `docs/devlog/parts/cosmos-ganymede.md`) |

What the rockets come to (the cheapest designs a search of the table found; `tests/unit/test_rocket_check.gd` has the
Moon's by hand): **the Moon ~39 parts, ~1,040 gold** (3 stages: 8 engines, 10 tanks, 4 fins; 2 space engines, 4 tanks;
1 space engine, 1 tank, the service module, the capsule, the nose, 3 legs, a solar array: 15.57 km/s); **Mars ~50-55
parts, ~1,450-1,500 gold** (4 stages; 2 service modules, the heat shield and the parachute); Europa and Io ~120-130 parts
(5 stages, ~3,500-4,000 gold); Titan ~140 (11 service modules for 6 years); Mercury ~230 (6 stages, ~7,000 gold): the
hardest landing in the solar system, which is true.

## Rulings (the owner's rule: decide and write down; cost if wrong)
1. **A mission's rocket flies there and lands; the way home is the lander at the planet's pad** (the portal home of
   §21.1, and §21d.4's lander): so the Moon needs 15.3 km/s (the spec's "about 6 more" is the one-way landing's 5.9) and
   Mars's words say real plans make fuel for the way home there. *Cost:* a "home" leg per mission (the Moon +2.7, with a
   heat shield) is data in `MissionRules.MISSIONS` and one line in the check; the rockets roughly double.
2. **The route is `MissionData.flown` ∪ the Space Book's LANDED** (a planet landed on before missions counts, §21d.5);
   the Star Map gets `StarMap.MISSION`; `StarMap.states(…, route)` with no route (null) keeps the old behaviour for tools
   and tests of the map alone. *Cost:* one function (`MissionRules.route`).
3. **Parts cost gold in every mode, two ways.** Survivor: bought through the host's wallet (`Session.gold_spend`) into
   the bag, placed and broken like any block (a LAN guest's bag is the host's: a guest buys in its own world). Sandbox:
   bought with the child's gold (the School's) and kept by the profile (`MissionData.parts`, backed up, merged by the
   bigger count); building on the pad stays free (the SPACE row), and LAUNCH needs every part on the pad bought ("Buy
   the parts you don't have yet: …"). Owned parts serve every Sandbox rocket (a copy flies; the rocket stays). *Cost:*
   if the owner wants a Sandbox part used up when placed, a Sandbox ledger for page-32 ids in `Session.gather_ledger`.
4. **Gold in the Sandbox is spent from `Profile.data.survivor_gold` directly, like the School pays it** (no
   `gold_changed`: the Sandbox HUD shows ∞; the board shows the real gold). *Cost:* when the Gold Shop's SpendRules is
   merged its spend should replace `sandbox.buy_rocket_part`'s two branches (and the online wallet ledger hears it).
5. **Prices** (one table, `RocketParts.PRICES`): the Moon's rocket ~1,040 gold, Mars's ~1,500. The physics makes Mars
   only ~1.4× the Moon (its trip is one way and its air brakes it), not the spec's "a few weeks" against "a few days".
   *Cost:* one table; EarnRules' daily cap sets the days. At ~250 gold a day of learning: the Moon 4 days, Mars 6.
6. **The check's parts rules** (3 fins, 3 legs, a solar array, a pointed top, an engine and fuel on the crew's stage,
   space engines not in stage 1, upper stages push ≥ half): each is one constant or one line. *Cost:* small.
7. **The rocket is the biggest piece of parts standing on the pad** (touching side to side; blocks that are not parts,
   parts off the square or floating stay behind); **a layer holding a separator ends a stage** (its other parts drop
   with it). *Cost:* `RocketCheck.find_rocket` / `stages_of`.
8. **The site** (LaunchSite): a 23 × 13 plaza, flat open ground first (steps ≤ 2, no tree within 2), else steeper
   ground (≤ 4, then ≤ 6: the concrete plinth fills it) with its trees and plants cleared; 36 blocks out is typical
   (radii 32-46, the nearest cell ≥ 24 from the spawn, the farthest ≤ 58: the ring generated places keep free),
   ≥ 30° from the Theater seen from the spawn, ≥ 8 from its walls. Measured over 25 seeds: 25 sites, 104-259 ms each on
   this PC with the Theater's own search (a worker thread). Flat-and-treeless only found 1 of 25 (the meadows are hilly
   and wooded). *Cost:* the tiers are one table (`TIERS`).
9. **The pad is stamped only over the world's own ground** (`LaunchSite.natural`: ground, ores, trees, plants and air in
   the plaza, 3 round it and 16 over it): a world made before missions never gets concrete over a child's build; such a
   site is passed over (sites within 30 of it too) and another searched. A stamp cut short goes on (the pad's own blocks
   count as ground). *Cost:* none known; a seed with one good spot (12345) and a build on it has no Launch Site.
10. **A LAN guest finds the site from the seed** (like the Theater); if the host passed over a site for a child's build,
    the guest's buildings stand at the first site. *Cost:* an RPC with the saved site.
11. **Friends, phase 1** (§21d.6): everyone builds on the pad and sees the check; the **world's owner (the host)
    launches**: everyone is told in the chat ("NAME launched to the Moon!") and the shared game ends as with any host
    travel; a guest's LAUNCH says "This pad is your friend's: they launch from here. Build one at your own Launch Site
    to fly it yourself!". *Cost:* phase 2 (the crew flies together) is the flight agent's and the lead's.
12. **Survivor also makes five simple parts** from real materials: nose cone (2 iron), fins (1 iron → 2), landing legs
    (3 iron), stage separator (2 iron) at a Workbench; the heat shield (3 sand, 1 stone) baked in the Clay Oven
    (ceramic). Engines, tanks, the capsule, the service module, the solar array and the parachute are bought. *Cost:*
    rows in `Recipes.LIST`.
13. **The pad's blocks are ordinary** (breakable, drop themselves); the wand never wakes them (`CaptureRules.GROUND`);
    no part is ever painted (`PaintRules.JOB_PAGES` has page 32). *Cost:* making the pad unbreakable is one line, but a
    `/give`-placed pad block could then never be removed.
14. **Mission Control is a solid model** (no room inside); the board stands in front of it. *Cost:* a room is a model.
15. **The board never holds the game still** (friends keep building). The Star Map button closes the board and opens
    the map where it is (on the ground: LAND works for route planets, STAY HERE does nothing).
16. **Other tools**: the planet smokes (space, Mars, Europa, Io, Titan, Mercury) and `shader_probe`, `frame_probe`,
    `frame_trip` put their planet on the route in their first line (`Profile.data.missions.fly(…)`): they test landing,
    not missions. *Cost:* none; on a real profile those three probes leave the Moon on its route.

## Files
- **New:** `core/rules/rocket_parts.gd`, `core/rules/rocket_check.gd`, `core/rules/mission_rules.gd`,
  `core/rules/mission_data.gd`, `core/rules/launch_site.gd`, `data/blocks/rocket_page.gd`,
  `data/blocks/pages/rockets.png` (+ `_albedo`, `_normal`, their `.import`), `entities/launch/launch_director.gd`,
  `entities/launch/launch_buildings.gd`, `ui/missions/mission_board.gd`, `ui/missions/rocket_bar.gd`,
  `tools/make_rocket_page.gd`, `tools/make_rocket_realistic.py`, `tools/mission_smoke.gd` (+ `_steps`),
  `tools/launch_shots.gd` (+ `_steps`); tests `tests/unit/test_rocket_parts.gd`, `test_rocket_check.gd`,
  `test_rocket_blocks.gd`, `test_mission_rules.gd`, `test_mission_star_map.gd`, `test_launch_site.gd`,
  `tests/integration/test_mission_board.gd`, `test_launch_director.gd`.
- **Shared, small:** `data/blocks/block_ids.gd` (ids 560-573, names, `COUNT` and `NEXT_PAGE_FIRST_ID` 576),
  `world/block_library.gd` (one register line), `core/rules/star_map.gd` (MISSION, the route), `ui/space/space_panel.gd`
  and `world/space_director.gd` (the route passed on), `world/world_meta.gd` (`launch_site`), `core/save/profile_data.gd`
  and `profile_backup.gd` (`missions`), `scenes/sandbox.gd` (its section "Spec §21d", the route in `travel_to_space`,
  the landing words, Back, the tutorial's avoid list), `ui/hud/block_palette.gd` (the SPACE row),
  `core/crafting/recipes.gd`, `core/building/paint_rules.gd`, `core/magic/capture_rules.gd`; tests counting ids, pages
  and palette buttons (`test_block_id_space`, `test_block_pages`, `test_mercury_blocks`, `test_titan_blocks`,
  `test_realistic_pack`, `test_recipes`, `test_block_palette`, `test_palette_smart`, `test_counted_hotbar`); the planet
  smokes' first lines.
- **Textures:** only CC0 ambientCG sets the other pages already use and credit (Plastic013A, Metal034, Fabric004,
  Ground037, Plaster001); the shapes are drawn by the tools. The realistic pages' budget: 44.4 MB of 48.
- **No server change** (gifts carry blocks up to 1023 already: module 0.2.15).

## Seen in a window (tools/launch_shots.gd, this PC, 1280 × 720, both styles)
Seed 12345's site stands 36 blocks from the spawn at (-35, 29, -9), on a slope in a wood (tier 3: its trees cleared,
a concrete plinth on the low side), the Theater on the hill beside it (clear of it). The Moon rocket of the smoke on the
pad reads as a rocket: four red-and-white fins round a block of engines, white tanks with the teal band, golden
space-engine bells at each stage, yellow-and-black separators, the legs splayed round the top stage, the blue solar
array, the capsule's window and the red nose; the orange-and-white tower beside it, Mission Control with its teal roof
and the board's "MISSION BOARD". The realistic style: metal, painted and concrete textures, the same shapes. The board
at 1280 × 720: the missions' cards (planet, distance, trip, fact, needs, CHOSEN / CHOOSE), the rocket page (the bar
with "Your rocket: 15.6 km/s", three stage lines, green ticks), the parts' shelf (icons, words, numbers, made of,
prices, "you have"). Fixed after looking: the bar's leg names now give way to their numbers in a short segment; the
"LAUNCH PAD" words moved off the stripes; the PC's KEYS card is marked seen in the tool. Esc: the board sits last in
the UI layer, so a PC's Esc closes it without opening the pause menu (the pause menu closes the board when it opens).

## For the lead
- **The Gold Shop's rocket shelf**: its items are `RocketParts.ORDER` at `RocketParts.PRICES`; a purchase calls the
  sandbox's `buy_rocket_part(id, n)` (Survivor: the bag; Sandbox: the profile's parts), or move its body into SpendRules
  and point `MissionBoard.buy` at it. The welcome gift's "starter rocket part" is `Profile.data.missions.add_part(id)` in
  the Sandbox or a bag's `add(id, 1)` in Survivor.
- **The flight**: `sandbox.fly = func(r: Dictionary) -> void: flight.start(r, Game.universe)` and
  `flight.landed.connect(sandbox.mission_arrive)` (it marks the mission flown, sets "Mission complete!" and loads the
  planet). The rocket is `{destination, cells ({Vector3i relative to the pad's corner, y up: id}), stages ([[Vector3i]],
  bottom first), seats}`.
- **InviteRules.friend_landed**: call it in `mission_arrive` when `Profile.data.missions.fly(u)` returns true for the Moon.
- **Page 31** (544-559) stays empty for the colony domes; `COUNT` is 576 either way. Merges touch `block_ids.gd`,
  `block_library.gd`, `profile_data.gd`, `profile_backup.gd`, `sandbox.gd` and the tests counting pages and palette
  buttons.
- **lead-merge moved on** while this was built (owner #87-#91: the planet guide, the moving Star Map): a trial merge
  (`git merge-tree` against `e7096caf`) is clean; the files both touched are `core/rules/star_map.gd` (`states`' route
  and MISSION), `ui/space/space_panel.gd` (`open`'s route) and `scenes/sandbox.gd` (`_space_landed`'s "Mission
  complete!"). Run the mission smoke and the planet smokes after the merge.

## What the lead must check on the emulator
1. A new Green Meadows world (Sandbox and Survivor): the plaza, pad, tower and Mission Control in both styles; where it
   stands from the spawn and from the Theater; the frame time while the pad is stamped (48 cells a frame, about 10-30
   frames; the check on a worker) and when the board opens.
2. An old world (made before this): the site is placed on its first load, never over the child's builds.
3. Walking up to the board; its three pages at the phone's size (the panel scales down on a low screen); the speaker;
   X, Android Back, and Esc on a PC.
4. The SPACE row in the Sandbox palette; building the Moon rocket; the check's lines; BUY WHAT MY ROCKET STILL NEEDS;
   LAUNCH → the Moon ("Mission complete!"); home again, the Moon on the Star Map says LAND, Mars says MISSION.
5. CHECK reads 9 × 64 × 9 cells (about 5,000): its time on a phone.
6. Survivor: buying into the bag, the five recipes in the Craft Book, placing parts from the bag.

## Tests
| Test | Tests | Red first |
|---|---|---|
| `tests/unit/test_rocket_parts.gd` | 6 | RocketParts not declared; the made-of and recipe test before `made_of`, `craft_words` and the recipes |
| `tests/unit/test_rocket_check.gd` | 14 | RocketCheck not declared (the numbers by hand) |
| `tests/unit/test_mission_rules.gd` | 6 | MissionRules, MissionData, ProfileData.missions not declared |
| `tests/unit/test_mission_star_map.gd` | 5 | StarMap.MISSION, states' route, SpacePanel.open's route, SpaceDirector.route |
| `tests/unit/test_launch_site.gd` | 10 | LaunchSite not declared; `natural`, `clear_changes`, `CLEAR_MARGIN` before they existed |
| `tests/unit/test_rocket_blocks.gd` | 7 | RocketPage not declared |
| `tests/integration/test_mission_board.gd` | 9 | MissionBoard not declared |
| `tests/integration/test_launch_director.gd` | 6 | LaunchDirector not declared; then no site on real terrain (the tiers), then no second site after a build (the rejected circle) |

**Results (2026-09-30, this PC):** the full suite (`tests/run_tests.sh`): 7,707 passing, 2 risky as before
(`test_chunks_meet_without_seams` and one more that never asserts), 1 failing: `test_shader_warmup_sources`, which asks
every new script that makes a material or a 3D label to say how its shaders are warmed; `LaunchBuildings` now uses the
Theater's material exactly (vertex colours, roughness 0.9) and is listed as "shares"; that file then passed alone, with
the 64 other tests of this work. Smokes (`tools/smoke_all.sh`, private folders): `mission` PASS (0 fails, 31 s);
`space`, `mars`, `europa`, `io`, `titan`, `mercury` PASS with their route line.
