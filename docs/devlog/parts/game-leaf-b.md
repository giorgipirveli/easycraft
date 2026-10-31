# Size Magic Voyages: Inside a Leaf, phase B (owner #133, #134)

The brief: `docs/superpowers/plans/2026-10-18-game-leaf-b1-brief.md` (B1, "the leaf works"); the design:
`docs/design/games/leaf-voyage.md` (approved by the lead's review, which decides its open questions); the authority:
`docs/design/future-lessons.md` (the five tests). Built by the game agent on the worktree branch
`worktree-agent-a147de3715f361265`, cut from lead-merge at `c75af5b3`. No editor, no emulator, no adb, no downloads, no
agents, no server change.

## 1. Reported before building: the pattern for the places

**Picked: merged meshes plus MultiMeshes on the census's vertex-colour materials, in places that are `LifeRoom`s whose
geometry comes from one pure layout.**

- `LeafKit` (over `LifeRoomKit`, in `entities/play/leaf/`) builds every place from pieces and draws them as:
  - **merged meshes, one per material**, for everything that does not move by itself (the roof's frame, the floor's
    paving, the vein's sheath and pipes, the pot, the terrace, the fence, the far haze, the sky dome), in vertex colours
    on materials the warm-up already holds (`data/shader_warmup.json`): the Theater building's lit vertex-colour material
    (`vertex_color_use_as_albedo`, `vertex_color_is_srgb`), the launch site blinker's unshaded twin for what glows (the
    sky, the Sun, the pipes' mouths), and the rainbow arch's see-through twin (unshaded, alpha, two-sided) for glass and
    the light's rays;
  - **one MultiMesh per shape** for everything a voyage moves or recolours (the round cells plump and thirsty, the tall
    columns, the doors' guard cells and their slits, the green workshops, the air puffs, the sugars, the water drops, the
    cactus's jars), on the two instanced vertex-colour materials the census holds (the hub circle's and the butterflies'
    lit one, the fireflies' unshaded one): the simulation's state shows through per-instance transforms and colours (a
    cell's plumpness, a workshop's glow, a door opening like lips), with no mesh rebuilt while it plays;
  - **CPU particles** for the mist and the light's sparks (Fx's and the fireflies' way), one system each, their emission
    points moved to the open doors.
- `LeafPlace` (the leaf's inside, and the cactus stem with `CactusDressing`) and `LeafGarden` (the terrace, with
  `SunflowerModel`) are **`LifeRoom` subclasses**, like G0's `PlayArena`: targets with forgiving radii, flat views and VR
  stands, the glow, `env`, so B2's host gets G0's input contract and the tests G0 already runs (the free band, the reach,
  warmed shaders, no shadows, one light).
- **One pure layout**: `LeafSpace` (`core/play/leaf/`) computes where every cell, column, door, pipe and sugar spot is,
  from the setting and a seed; `LeafPlace` draws from it and the flyer is pushed out of the same shapes, so what a child
  sees is exactly what stops them.

**Rejected:**
1. *A node per thing with `LifeRoomKit`'s shapes* (each cell, column, door, workshop a `MeshInstance3D`): the leaf holds
   about 30 cells, 12 columns, 12 guard cells, 250+ workshops, 25 air puffs and a dozen sugars: hundreds of draws, where
   the Quest's budget is 100 a frame and the design aims at 45-55 with the HUD.
2. *A custom shader* for the cells (see-through skins, a wobble in the vertex shader, per-instance turgor uniforms): a
   new shader the warm-up does not hold (a census change in files that are not mine, and a first-sight compile hitch in
   every browser), for a look the kit's lit shapes and glowing parts already give.
3. *GPU particles* for the mist and the puffs: each compiles its own process shader (not in the census) and costs more
   on the Quest; CPU particles are what `Fx` and the fireflies use.
4. *One static mesh for everything, rebuilt when a cell plumps or a door opens*: a GDScript rebuild of thousands of
   vertices in the frames of an animation is too slow on a phone (3-5x this PC).
5. *Waiting for the rooms' look work* (`LifeRoomDecor`, on a paused branch, not in lead-merge): B1 cannot depend on
   unmerged code. `LeafKit`'s merge is small and its own, on the same census materials, so when that work lands the
   leaf's pieces can go through it with no change to the places.

**Why:** a whole place is about 25 draws however many pieces it holds (the HUD, Hoot and the avatar on top stay inside the
design's 45-55); the simulation's state is shown by cheap per-instance updates; only shaders the warm-up already holds
are used, so nothing changes in G0's, the census's or the lead's files; and the places speak `LifeRoom`'s language, which
G0's host, ghost and tests already understand.

*Cost if wrong:* the places' moving parts share one shape per MultiMesh (variety comes from each instance's scale, turn
and colour, not from different shapes); a new kind of moving thing is one more MultiMesh (one more draw).

## 2. The cheat test, as a test (B1)

`tests/unit/test_leaf_cheat_bots.gd`: bots (`tests/unit/leaf_bots.gd`, ported from the phase A models' `Child`) play the
production rules (`LeafSim`, `LeafWeather`, `LeafBeats`) for 1,000 seeded runs each, at the models' 0.1 s step; 5.1 is
Act 2 from the full leaf with its doors shut (as the model starts), mastery as `MasteryRules` counts it (5 of the 6
silent beats, the act 1 beat counted solved: the most a guesser could hope for).

| Bot | 5.1 flat | 5.1 VR | 5.T1 |
|---|---|---|---|
| knows the rule (reacts in about 1.5 s) | **100 %** | **100 %** | **100 %** (and wins: 6 sugars, never drooping) |
| knows the rule but slow (4 s, 0.8 s a door flat) | **100 %** | **100 %** | |
| random taps (one every 1.5 s) | 0.1 % | 0.0 % | 0.0 % |
| always open | 0 % | 0 % | 0 % |
| always shut | 0 % (3 of 6: the blazes) | 0 % | 0 % (4 of 6) |
| greedy ("more air, more sugar": all open in the light, shut only when it droops) | 0 % | 0 % | 0 % |
| open when it's bright | 0 % | 0 % | 0 % |
| the sunflower's habit (open in daylight) | | | **0 %** (never wins) |
| the sunflower's rule unchanged (open only in a cloud) | | | 0 % (4 of 6) |
| **watches the cells** (open while over 0.7, shut under 0.6) | **100 %** | | **0 %** |

At 1/30 s steps (a phone's frames): the rule 100 % in both voyages, random 0 % (100 runs each).

**Finding 1: the model's 72 % for the slow child was a floating-point artefact.** The phase A model steps time by
`t += 0.1`, which drifts and moves some segment edges by a step; stepped exactly (`t = i * 0.1`) the model's own slow child
masters 60-65 % flat over five ranges of 1,000 seeds and only 92 % in VR (under the brief's 95 %). It misses only one
thing: a cloud's "at least 2 sugars", a knife edge (reacting in 4.4 s builds 1.9-2.0 sugars a cloud and misses all three
clouds). Ruling 1 below lowers the bar to 1.6; contrast still decides, and every guesser stays at 0 %.

**Finding 2: watching the cells masters the sunflower, and the desert catches it.** A child who keeps the doors open while
the leaf is well above drooping and shuts them as soon as the cells start to drain masters 5.1 in every run. Inside 5.1 it
cannot be told apart from a slow child who knows the rule: the leaf's water is driven by the weather, so its doors follow
the weather a few seconds late. It is the plant's own feedback (real stomata close as a leaf loses water), and it needs
the unit's idea (doors let air in for sugar, and water out). In the desert it never wins: the dry sand and the blazing
day drain the stem faster than watching can save it, and a stem that isn't full never opens at night. So the transfer
voyage is what shows the weather idea; the test holds that (`test_watching_the_cells_is_caught_by_the_desert`). For the
lead: if 5.1's stars should need the weather idea by themselves, either the place must not show the cells draining before
the leaf droops (less of the world's answer: the design's §3.5 step 5 asks for the nearby cells to sag when a door opens in
the blaze), or ★★ for the unit could wait for 5.T1.

## 3. Rulings (each with its cost if wrong)

1. **A silent cloud needs at least 1.6 sugars built in it** (the design's starting 2.0; finding 1). *Cost:* a cloud
   passes with a little less building; the contrast (at least 0.4 more opening than the blaze before) still decides,
   and random, always open, always shut, greedy and open-when-bright stay at 0 %.
2. **"Greedy" is the design's "more air, more sugar"** (§3.9), made a little smarter since the brief lists it apart from
   always-open: every door open while there is light to build with, one shut only once the leaf visibly droops.
   *Cost:* none known; the stronger cheat (watching the cells) is tested on its own (finding 2).
3. **The bots run at the models' 0.1 s step**, checked at 1/30 s too; a bot that never uses its random stream (always
   open, always shut, greedy, watch) plays one run for all 1,000 seeds (two seeds are checked to be identical). *Cost:*
   the test file takes about 3 minutes (about 22 million simulated steps).
4. **`LeafSim` runs both models step for step**: C3 (the sunflower: air straight to the workshops) and CAM (the cactus:
   the night's air into jars, the jars first by day), each in its own model's order; the cactus uses its model's air use
   (2, not the sunflower's 4). *Cost:* two branches to keep in step with the science table.
5. **A missed beat is recorded as HELPED** (SkillShown has no "missed"; neither counts as right the first time), its note
   starting "missed:" so the leaf journal and the grown-ups' page can tell a miss from help. *Cost:* the grown-ups' page
   needs the note to tell them apart.
6. **Act 1 never dries the leaf below 0.4** (a teaching act waits for the child; the design starts it at 0.5), and once
   every door is shut the vein refills six times faster (the fill): B1 is judged as the leaf stands, L10 then L11, and
   the weather starts with the leaf at 0.9 (the design's Act 2 starts at 0.95). *Cost:* Act 1 can't be failed; a door
   reopened during the fill goes back to Act 1.
7. **The bud asks for another turn at the evening while the sugar delivered is short of it** (up to six turns); after the
   last one the voyage ends anyway and what waits goes up the gold pipe (the plant never fails). *Cost:* a child who never
   carries sugar still sees the bloom; the record and the stars stay honest.
8. **Help comes only after two misses of the same kind**, in both voyages (clouds, blazes; the desert's nights, days):
   6 s into the next such window with the doors still wrong Hoot says the voyage's hint for it (the sunflower's L15 or
   L18, the desert's D5 or D3), at 10 s the ghost does a door; that beat is helped, and the sunflower's next cloud lasts
   30 % longer (the design's ruling 25; the desert's days and nights are fixed). Help counts only when it is really
   given (a voyage without a hint line marks nothing; SHOW ME with nothing to show is no help). *Cost:* a child who
   misses one cloud and one blaze gets no help yet; a helped desert beat is HELPED, not NEW_SETTING (the transfer stays
   honest).
9. **"Too hot!" (L13) is said once, only in a turn that isn't judged** (the trap, the voiced blaze) and on the desert's
   first day (the design's §3.5b), never in a silent judged blaze. *Cost:* the desert's first day is a little voiced (the
   design's own D3 already says to keep the doors shut).
10. **Praise names the strategy** (open, shut, deliver, any), never twice in a row; "You waited for the cloud" and "The leaf
    is happy and full" only for the sunflower (no clouds in the desert; a cactus is a stem). *Cost:* fewer praise lines in
    the desert.
11. **The ghost carries a sugar to the gold pipe only in the voiced blaze** (if none waits there, it isn't shown). *Cost:* a
    child who carries everything first never sees it.
12. **The child stays inside during a voyage**: the floor (doors too) is solid to the flyer; the way in and out are the
    dive's glides. *Cost:* no flying out through an open door.
13. **The columns open into a skylight over the doors** (none over the work area, none nearer the child's side than
    z 3.4), so the light falls on the doors and the roof, the Sun and the bud show (simplified: a real palisade is
    continuous; for the honesty table). *Cost:* the leaf looks less packed than a real one.
14. **The cactus keeps the model's six doors, farther apart (at least 4 m), each in a pit drawn as a raised rim of skin**;
    its doors are in the floor like the leaf's (a real cactus's are in its sunlit skin: simplified). *Cost:* "fewer doors"
    is shown by spacing, not count.
15. **The cactus's jars are in its see-through water stores** (the vacuoles; they fill by themselves, nobody reaches for
    them). *Cost:* in VR they are looked at, not held (minute 30's "cupping the jars" is looking).
16. **The dive has three sets (x10, x100, x1,000); its last step (x85,000) is the place's own UNDER view.** *Cost:* B2
    cross-fades from the dive into the place.
17. **The watering can waits on a low stone by the pot** (1.1 m from a standing child's eyes: no kneeling in VR). *Cost:* a
    stone a real garden wouldn't need.
18. **Professor Hoot is LeafKit's own model** (the game's owl boxes and SchoolUi.teacher's square cap, wound the right way;
    one draw): BlockyAnimal's owl draws inside out (finding 3). *Cost:* two owl models until BlockyAnimal is fixed.
19. **Pick radii: doors 1.1 m, sugars 0.72 m, the pipes' mouths 0.8 m**, so from the work view (0, 4.3, 7.6) looking at
    (0, 1.3, -1.9) every target is at least a fingertip across (56 px) inside the free band. *Cost:* the far mouths' pick
    circles are bigger than the mouths.
20. **Thirsty cells and open doors are their own meshes** (a wrinkled ball; bowed beans), swapped half way with a pop or a
    squeeze. *Cost:* one more draw each; quick swaps, not smooth morphs.
21. **The weather tints the glowing far parts** (the haze, the roof, the vein's sheath, the floor's underside, the
    cactus's glass) by rebuilding their vertex colours in steps as the weather turns. *Cost:* about 6,000 vertices
    rebuilt a few times a weather change.
22. **The leaf's three material makers are listed in `tests/unit/test_shader_warmup_sources.gd`'s COVERED** (the
    full suite caught them; that test asks every new script that makes a material or particles to say how they are
    warmed): a line each for `leaf_kit.gd`, `leaf_place.gd`, `leaf_dive.gd`, outside B1's own files. *Cost:* one shared
    file touched; at most a one-hunk merge beside other wings' lines.
23. **The leaf under the rooms' look** (merged after the full suite: `LifeRoom` now dresses every room once it is built,
    with a default sky dome, its own sun and a daylight tone): the leaf's Sun is the room's own `LifeRoomSun`
    (`LeafKit.sun` asks `LifeRoom.sun`; the dive, not a room, makes one of its own), so it is the only light while a leaf
    place shows and the world's suns are put away and given back (finding 4, solved); `LeafRoom` hides the default dome
    (the leaf draws its own sky, tinted by its weather) and gives back its filmic tone and ambient colour
    (`LeafKit.own_tone`); the places' members `sun` and `_sky` became `key_light` and `_sky_dome` (LifeRoom has its own
    now: they no longer parsed). *Cost:* `LeafRoom` leans on the rooms' look's `Decor/Sky` and its tone (a test holds
    both); the leaf doesn't share the rooms' ACES tone (its pictures were made in filmic; B3 could try it).

## 4. What works (B1)

- **The pure rules** (`core/play/leaf/`, data `data/play/leaf/voyages.json`, `lines.json`): `LeafVoyages` (the ladder,
  the weathers, 5.1 and 5.T1, the 49 lines), `LeafSim` (C3 and CAM), `LeafWeather` (the scripts, the dawn, longer
  windows, extra turns), `LeafBeats` (the evidence model), `LeafRun` (one voyage inside the plant with its help and its
  cues: B2's host steps it), `LeafProgress` (the garden on the device), `LeafSwimRules` (VR swimming and the grapple),
  `LeafSpace` (the one layout and the flyer's push-out). The API is the design's §4.3, plus `LeafRun` (the flow both
  the bots and the host need) and `LeafRoom` (the places' common contract).
- **The places** (`entities/play/leaf/`): `LeafKit`, `LeafRoom`, `LeafPlace` (with `CactusDressing`), `LeafGarden` with
  `SunflowerModel`, `LeafDive`. Not yet: `LeafVoyageHost` (input, camera, VR, demonstrations, the HUD, the record: B2),
  sounds, music and juice (B3).
- **The tests:** 88 in 11 files, all passing: `test_leaf_voyages` 8, `test_leaf_sim` 14, `test_leaf_weather` 6,
  `test_leaf_beats` 10, `test_leaf_cheat_bots` 7 (about 3 minutes), `test_leaf_run` 15, `test_leaf_progress` 7,
  `test_leaf_swim_rules` 5, `test_leaf_space` 8, `test_leaf_place` 5, `test_leaf_budget` 3.

## 5. The pictures, and what changed after looking

`tools/leaf_shots.gd` in a real window (the Vulkan Mobile renderer on the PC's Intel UHD, 1280 x 720), under nice, one
at a time; the final set is in `docs/devlog/parts/game-leaf-b/` (01 the garden's hook, 02 the bloom, 03-05 the dive, 06
under the leaf, 07 Act 1, 08 a cloud, 09 the blaze, 10 looking up, 11 the desert's day, 12 its night, 13 its stars). The
child and Hoot in the inside pictures are picture props for scale (B2 brings the avatar).

- **First look:** the garden bulged like a planet (too close for the 72° lens), the drooping head faced forward with its
  yellow petals dangling, the can didn't read as a can, the grass tufts were black thorns, Hoot was a black silhouette;
  inside, the near columns hung as dark blobs across the top, the thirsty cells were mouldy potatoes, the floor was the
  brightest thing (tiles), the guard cells didn't close, no mist showed, the rays were faint; looking up was an
  oppressive forest of dark tubes with rays like glass panes; under the leaf was an empty dark ceiling; the desert night
  was daytime-green; the dive was a flat lime field with pipes for veins and a ladybird seen from behind, hairs like
  spotlights, skin like tiles.
- **Changed:** a skylight in the columns over the doors (and none over the way in); brighter, deeper-green columns with
  glowing tops; the floor as irregular skin cells over continuous dark grooves, with its own underside (a glowing mesh
  seen only from below); guard cells as shut and bowed beans closed into an oval, reaching below the floor; the mist as
  streams drawn into the open doors and plumes pouring out below (its gravity had defaulted to 9.8 and dropped it through
  the floor, and setting `emitting` every frame restarted it); soft beams (three crossed panes fading to their edges);
  the far parts tinted by the weather (a real night); a stronger fill light; paler, saggier thirsty cells; workshops dark
  in the dark and lime-gold when building; puffs squeezing up at shut doors' seams and waiting below them; the bud far
  above as a sunflower head seen from below whose gold lens grows; soft glow discs for the Sun and the moon (the
  billboard was a square); the cactus's own pale smooth bud (the spiky one looked like a sea mine at night), raised rims
  round its doors, jars glowing mint in dim glass; the garden's camera and a bigger lawn, a real watering can, no tufts,
  a closed bud as a solid green bulb (the first one read as a toothy mouth: ruling 4), leaves to the sides, the bloom
  facing the child; Professor Hoot; the dive's veins raised in the leaf's own surface, the ladybird close and turned to
  us, glassy segmented hairs, jigsaw skin cells. Six passes in all.
- **Still for B2 and B3:** the dive's moves between its sets, the cloud's shadow sweeping over the roof, heat shimmer, the
  bloom's petal-by-petal opening and the bee's flight (the poses exist), richer leaves in the garden.

## 6. The draws

The tests' count (each visible mesh, MultiMesh or particle system one draw, as `test_play_budget.gd`), at the heaviest
moment (every door open, the mist pouring, a sugar at every spot, puffs and drops on their way): **inside 26 (the
sunflower by day), 22 (by night), 28 (the cactus, day or night); the garden 13 (the hook), 14 (the bloom); the dive 3,
3, 4.** With the HUD's 10-20, Hoot's 1 and the avatar's 8 on top, inside is 41-57 (the design's estimate 45-55; the
Quest's budget 100, aim 70); the garden about 30 (the estimate 35). A real frame's draw calls in the window
(`RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME`): inside 20-26, the garden 14, the dive 3-4; 150-340 fps on this PC's
integrated GPU (not the emulator's check: B2's bench and the lead's emulator and Quest runs are).

## 7. Findings for the lead

1. **The slow child** (section 2): the phase A model's 72 % was a floating-point artefact; ruling 1 restores fairness.
2. **Watching the cells masters 5.1; the desert catches it** (section 2): a design question for the lead.
3. **BlockyAnimal draws inside out in Godot 4.7.** Its `_box` winds each face counter-clockwise seen from outside; a
   window probe (two quads, then the owl beside a LeafKit box of its colour, lit from the camera's side) shows Godot culls
   that winding: the owl showed its inside walls. Every `BlockyAnimal._build` mesh is affected (the animals, the hub
   circle's stones, anything built from its boxes). The fix is one line (the index order in `_box`), in files that are not
   B1's; worth a look on the emulator first.
4. **The world's sun lit the voyage too** (a place 1.5 km above a world is also lit by that world's sun: the leaf lit twice,
   a night not dark). Solved by ruling 23: the leaf's Sun is now the rooms' `LifeRoomSun`, which puts the world's suns
   away while it shows (`test_each_place_s_own_sun_is_the_only_light_while_it_shows_and_its_weather_drives_it`).
5. **The census's tiers:** the leaf uses only warmed materials, some warmed late (the rainbow arch's see-through vertex
   colours, the fireflies' instanced glow); a voyage opened right after the start in a browser could compile them at first
   sight. A census phase through the leaf (`tools/shader_probe_steps.gd`) would mark them as shown.

## 8. What B2 needs from the lead

The design's §4.7 hooks, approved by the lead's review: (1) `data/play/mechanics.json`'s `"signature": {"leaf_voyage":
{"name": "Size Magic Voyages: Inside a Leaf", "host": "res://entities/play/leaf/leaf_voyage_host.gd"}}` and
`SchoolScreen`'s PLAY opening a host when a unit's `play.game` names one; (2) `g5.science.plants_air_water`'s play block
`{"game": "leaf_voyage", "params": {"voyage": "5.1"}}`; (3) Back and the pause key to the voyage (`LeafVoyageHost.any_open`
beside `PlayHost.any_open` in `menu.gd`, W1's `room_open` / `close`). And from B1: (4) a census phase through the leaf
(finding 5); (5) the lead's call on findings 2 and 3. (The world's sun needs nothing more: finding 4.)

## 9. The full suite

Right before it, lead-merge was merged into the branch (`a474da6e`: Balance Altar's phase A, W1's academy strip and the
rest); `tests/run_tests.sh` ran once on that tree (`d37af9e6`) under the PC-wide slots, uncut: **12,075 tests, 12,070
passing, 2 failing, 3 risky or pending** (the known ones: the voxel column cache's two tests don't assert, the Nakama move
is off), 5,441 s, no script errors. An earlier start was stopped by me before it ran a script (a review of `LeafRun`
found the help bugs fixed in `d37af9e6`), not by the memory guard.

- `test_shader_warmup_sources.gd::test_every_script_that_makes_a_shader_is_warmed_or_explained`: the leaf's three
  material makers weren't in its COVERED list. Mine: listed (ruling 22); the file reruns green.
- `test_flight_cockpit.gd::test_a_drag_steers` ("dragged a full reach left": 0.0 for -1.0): the known flake under the
  full suite's load (W1's and the crew flights' notes); B1 touches nothing of the cockpit; passes alone on the same tree.

Both files rerun together: 10 of 10. In the run, all 86 leaf tests passed, and the cheat bots' numbers are section 2's.

**After the run, lead-merge had moved on** (the rooms' look, the Glow Caves, 1.0.7, Fraction Bakery's design), so it was
merged in again (`180b55b1`, no conflicts). That tree didn't parse the leaf: the rooms' look gave `LifeRoom` a `sun()`
and a `_sky` of its own, and its default sun would have hidden the leaf's and lit every weather the same. Fixed test first
(ruling 23; the place tests failed for the right reasons first: two lights, the night not reaching the light that shows,
a second sky dome, the rooms' tone). On that tree the leaf's 11 files, the warm-up sources, and the inner-class,
assets-pack and updater class scans: **110 of 110**; the draws unchanged; four pictures taken again (the garden, Act 1,
the desert's night, the dive) and unchanged. The full suite was not run again on it (the brief's one run is the one
above).

## The lead's review of B1 (2026-10-18 07:45)
**B1 passes.** The rules, the cheat bots as tests (every no-rule bot at most 0.1 %, the rule 100 % flat, VR and at 1/30 s;
the desert's habit never wins), the places and thirteen pictures (looked at: the garden's droop and bloom, the dive, the
cells, the blaze, the desert night; lovely and readable), the draws (inside 41-57 with the HUD and the avatar, under
the Quest's 100), the late fix for the rooms' own sun (`b631f5f9`). Merged into the lead's branch `lead-w1b` with 171/171
on the leaf's and the neighbours' files and 224/224 on the class scan, play and warm-up files.
- **Finding 2, watching the cells:** accepted, a ruling. A child who shuts the doors as the cells drain and opens them
  when they are full is doing what real guard cells do (they close as the leaf loses water), so the sunflower records
  the water-and-air balance by feedback; the weather idea (anticipating sun and cloud) is what the desert night tests,
  as NEW_SETTING evidence. Cost if wrong: the sunflower's star alone does not prove the weather idea; the desert does.
- **Finding 3, BlockyAnimal inside out:** fixed by the lead (`99f33b97`, `test_mesh_winding.gd` against Godot's own
  BoxMesh; before and after in `docs/devlog/2026-10-18-animals-winding.jpg`): every animal, the golems and the hub
  tree's stones were lit from inside. B2 can use one owl model.
- **What B2 needs:** granted in the B2 brief (`docs/superpowers/plans/2026-10-18-game-leaf-b2-brief.md`).

---

# Phase B2: the voyage plays

The brief: `docs/superpowers/plans/2026-10-18-game-leaf-b2-brief.md` (the lead, 2026-10-18, on `lead-w1b` at `647e296a`):
5.1 and 5.T1 played from start to end, flat and in VR, opened from the School, DISCOVER and the Academy, the record in
the child's progress; the registry for every deep game's own host. The branch fast-forwarded to `lead-w1b` (`ec234ebf`).

## B2.1 Reported before building: the registry's pattern and the host's

**Picked: a deep game's host is a `PlayHost` subclass, made through one pure registry, `PlaySignature`.**
`data/play/mechanics.json`'s `"signature"` table gains entries with a `"host"` (a script path) beside G0's station games
(a `"script"`). `PlaySignature` (`core/play/play_signature.gd`, static, no state) reads it: `host_for(content)` is the host
script the unit's play block names ("" for none), `make_host(content)` returns a host to open: the deep game's own when
its play block names one, else a plain `PlayHost` (no block, `"generic"`, a station game); an unknown name or a host
that is missing, broken or not a `PlayHost` falls back to `PlayHost` with a warning, never a crash. The contract is
`PlayHost`'s own public face, which every caller already uses: `setup(unit, content, seed, stars, outline, count)`,
`first_try_gold`, `open(parent)`, `close()`, the `finished(outcome)` and `stopped(outcome)` signals, `closed`,
`PlayHost.any_open(tree)`; the outcome is a round's (`right_first`, `total`, `world_task`, `shown`). A deep game reads its
own params from the unit's play block (`play.params.voyage` for the leaf). The callers change only where a host is made:
`SchoolScreen.show_play` and `DiscoveryDirector._open_place` call `PlaySignature.make_host` instead of `PlayHost.new()`
(and skip the exercise loop's empty check for a host with no loop). `LeafVoyageHost` is the first such host.

**Rejected: a second host type beside `PlayHost` (a duck-typed contract or its own base class).** Everything that keeps
the world calm while a game shows already keys on `PlayHost`: W1's `DiscoverPanel.room_open` (`is PlayHost`: Back stays
the game's instead of closing DISCOVER's School under it), the director's `place: PlayHost`, `place_open()` and
`_hold_while_open` (the avatar held still, `take_over`, `keep_safe`), the School's `play_host: PlayHost` and `menu.gd`'s
`PlayHost.any_open` (Back belongs to the game). The brief grants only the places a host is made, so a second type would
leave the world moving and Back closing the School under a voyage; a subclass is treated exactly as a round everywhere,
with no new code path. Also rejected: a `match` on the game in every caller (three files to edit for each new game) and
an autoload service locator (global state for what is a data lookup).
*Cost:* a deep game's host inherits the exercise loop's members it never uses (`loop`, `arena` stay null; `count`, a
crystal's short round, means nothing to a voyage); a caller that reads `host.loop` must check it.

**The host (`LeafVoyageHost`):** a continuous simulation driven by B1's `LeafRun`, in stages: the garden's hook, the dive,
the place (act 1, the weather), the return and the world's answer, the end card. Flat: a third-person camera that glides
with the avatar to the thing tapped (the target's own view from B1, about 3 m behind and 2.6 m above) and back to the
overview where every target is in the free band (B1's tested view); the camera button gives the avatar's eyes. Its HUD
(`LeafHud`, `ui/play/leaf/`) is a `PlayHud` (the ear, the eye, the break, STOP FOR NOW, Back's leave card, the panel in
VR) with no words while the voice is on, plus the camera button, the end card and the voyage board in pictures. VR: B1's
stands, `LeafSwimRules` moving the stand the rig follows, the laser grapple, the two-hand squeeze, the hands carrying
sugar. *Rejected:* a free orbit camera (targets would leave the free band) and a fixed room camera (no third person).

## B2.2 What works (B2)

- **The registry** (`core/play/play_signature.gd`, data `data/play/mechanics.json`'s `"signature"`): every caller makes
  a unit's host through it. The School's PLAY on `g5.science.plants_air_water`, Hoot's pick, a discovery crystal and
  the Academy's Science door all open the voyage; a unit naming no game, `"generic"` or a station game opens G0's
  `PlayHost` as before; an unknown game or a broken host falls back to it with a warning. The end is recorded exactly as
  a round's (the School's `_record_round`, DISCOVER's `SkillShown.record`: MasteryRules, the unit's gold once,
  EarnRules for each solved beat as it is judged). Back stays the game's in the menu, in DISCOVER's School and in the
  world (a host is a `PlayHost`: `PlayHost.any_open`, W1's `room_open`, the director's `place`).
- **`LeafVoyageHost`** (`entities/play/leaf/leaf_voyage_host.gd`) plays `LeafJourney` (`core/play/leaf/leaf_journey.gd`,
  pure: the garden's hook, the ghost after 6 s, the dive, under the leaf, inside with B1's `LeafRun`, the return, the
  world's answer line by line, the end) in B1's places:
  - **flat:** in the garden a tap on the can pours it by itself and a tap on the leaf dives (Size Magic's three steps,
    the camera rushing down); inside, the child's own blocky avatar (tiny, Hoot at its shoulder): one tap glides it
    to a door, a sugar or a pipe (at most 1.2 s, quick taps queue) and acts there, the camera gliding to the thing's
    own view and back to the overview after 1.4 s; a drag looks; the camera button (V, a controller's right-stick click) gives the
    avatar's eyes; WASD and the arrows, Space and E up, C and Q down, and a game controller's sticks fly it (never into
    a cell: `LeafSpace.push_out`), its A acting on the thing in the middle;
  - **VR** (`LeafVrHands`): the child stands at the garden's spot; the can lifted and tilted over the soil pours; a
    hand on the leaf grows the garden round the feet (nine times, the head never moving), then under the leaf behind a
    blink; inside, swimming (a pulled grip, the body the other way, at most 2.5 m/s, stopped by thick air), the laser
    grapple (a 0.6 s glide to a door's, a pipe's or a sugar's stand; a blink for the strong-vignette comfort choice),
    a door shut by squeezing its two guard cells together and opened by pulling them apart (or one hand's trigger), a
    sugar carried by hand to the gold pipe's mouth; Hoot flies at the shoulder; the HUD is the forearm's panel;
  - **the voice and the record:** every line through `LeafHud`'s bar (PlayVoice: spoken by itself, the ear says it
    again; no words on the screen with the voice on), the ghost finger or hands for each first step, SHOW ME (one step,
    helped), the break and STOP FOR NOW (nothing recorded, the bud's fill kept), Android Back's leave card; each event's
    note names what the voyage shows (the lead's ruling on finding 2); the end card (the plant, the stars, the gold) and
    the voyage board (5.1 always, 5.T1 once 5.1 is done) in pictures; `LeafProgress` keeps the garden on the device;
  - **for developers:** `--leaf-voyage=5.1|5.T1` (the School's PLAY opens that voyage; `tools/leaf_voyage.gd` opens it
    at once in a window, `--vr-preview` through the desktop's VR preview).
- **The warm-up:** a census phase through the leaf (`tools/shader_probe_steps.gd`'s `leaf`, counted in the menu's
  phase): everything a voyage draws is FIRST, warmed before the menu shows (finding 5, solved).
- **The tests:** 142 in 17 files, all passing: B1's 88 (`test_leaf_place` 6 now, `test_leaf_budget` 4), `test_leaf_journey`
  6, `test_leaf_host` 15, `test_leaf_host_vr` 10, `test_leaf_voice` 4, `test_play_signature` 6,
  `test_play_signature_callers` 11 (with a stand-in host, `tests/integration/play_signature_host.gd`). `tools/leaf_smoke.gd`:
  both voyages, flat and in a simulated headset, `LEAF_SMOKE done ok` (the rule masters each: 7 of 7, and 6 of 6 as
  NEW_SETTING), about 2 s each.

## B2.3 The registry's API, for the next deep games (Balance Altar, Fraction Bakery)

1. Write the game's host as a **`PlayHost` subclass** (its public face is the contract every caller uses):
   `setup(unit_id, content, seed, stars, outline, count)` (read your own params from the unit's play block:
   `PlayBlock.params(content)`; `count` is a crystal's short round, yours to honour or not), `open(parent)` (join
   `PlayHost.GROUP`, add yourself under `parent`, `_hide_screen(parent)`, your own camera; in VR `Vr.anchor` a stand),
   `close()` (call `super()`), `closed`, and the signals `finished(outcome)` and `stopped(outcome)`. Call
   `first_try_gold` for each challenge solved with no help as it is judged. The outcome is a round's:
   `{right_first, total, world_task, shown}` (`shown`: your `SkillShown` with an event per challenge), plus `then` when
   the child asks for more of the game (`{}` for none: the caller opens the unit again with these params after
   recording: an "again", another level, a voyage board).
2. Register it: `data/play/mechanics.json`'s `"signature": {"your_game": {"name": "...", "host": "res://...gd"}}`; a unit
   plays it with `"play": {"game": "your_game", "params": {...}}` (P1).
3. Nothing else changes: `SchoolScreen.show_play`, `DiscoveryDirector._open_place` (Hoot's pick, crystals, the Academy's
   doors) and `menu.gd`'s Back already open and respect it (`PlaySignature.make_host`, `PlayHost.any_open`).
4. Copy `tests/integration/test_play_signature_callers.gd`'s pattern for your own game (the School, Hoot's pick, a
   crystal, a door, the end recorded like a round, `then`, Back), and `tests/unit/test_play_signature.gd` holds the
   registry itself.

## B2.4 Rulings (each with its cost if wrong)

1. **The contract is `PlayHost`'s own face; a deep game's host is a subclass** (section B2.1). *Cost:* it inherits the
   exercise loop's members (`loop`, `arena` stay null; a caller reading `loop` must check it); `setup`'s sixth argument
   is a crystal's `count`, which a voyage ignores (it is always whole), and the voyage comes from the play block's
   params, not a setup argument (the brief's example named `params` there).
2. **Two of G0's test assertions changed** (outside B1's and B2's files): `test_play_audit` counted "P1 0, no deep game
   yet" and `test_play_mechanics` "G0 builds no signature game"; the granted hooks end both, so they now count the
   registry (P1 = the units a deep game plays) and check each game names a script that exists. *Cost:* two G0 files
   touched, by one hunk each.
3. **`g5.science.plants_air_water` is P1 from now** (G0's rule: a unit naming a built deep game is P1). The lead's review
   planned P1 for when a game teaches the whole unit (phase C; 5.2's soil idea is not built yet). *Cost:* the audit
   counts it covered a phase early; the lead may prefer to keep the play block until 5.2 (then the School's PLAY opens
   G0's round: the voyage still opens with `--leaf-voyage`).
4. **`finished` comes when the child leaves the end card**, not when the world's answer begins: the card's stars and gold
   are a preview by MasteryRules' own rule (from the stars the caller gave `setup`), and its "again" and the board's
   voyages come back through the caller as `then` (recorded first, then opened again). STOP FOR NOW or Back's LEAVE
   after the voyage has ended is the card's door: a finished voyage is never lost. *Cost:* a child who closes the app
   on the end card loses the record of that voyage (the plant keeps it: LeafProgress saved at the return).
5. **The flat camera is a third person that glides with the avatar to the thing tapped** (that thing's own view from
   B1, about 3 m behind and 2.6 m above) and back to the overview after 1.4 s (where B1 tested every target is in the
   free band); the camera button gives the avatar's eyes (its body hidden). *Cost:* the camera moves after each act;
   a child who wants to stay close uses the eyes.
6. **In the garden the camera is the child's own eyes** (normal size: no avatar there); the avatar appears tiny inside.
   *Cost:* none known.
7. **Taps queue up to three acts**, each glided to in turn. *Cost:* a tap meant to cancel the last does not.
8. **A thing says its name the first time it is touched in a voyage** ("A door", "Sugar", "The gold pipe", "The blue
   pipe"), never again, so names never cut Hoot's lines over and over. *Cost:* a child who missed it hears it no more.
9. **A child who taps the leaf at once never hears "Touch the leaf"** (L3 is said only while it waits). *Cost:* none.
10. **VR: the stand moves (swimming, the grapple) and the rig follows it; a swim's pull is measured in the body's own
    space** (the rig's), so a moving body never pulls itself. *Cost:* none known.
11. **VR's comfort choice is the existing VR COMFORT's strong vignette**: such a child's grapple blinks instead of
    gliding (the lead's "blink teleport as the comfort choice"; the stick's teleport arc does not work inside a leaf).
    *Cost:* no teleport arc inside; swimming stays (the voyage's way of moving, the lead's review 5).
12. **VR doors:** both hands on a door's guard cells: 6 cm closer shuts it, 15 cm further apart opens it; one hand's
    trigger on a door toggles it. A sugar let go away from a pipe stays carried (a grip at a pipe takes it back).
    *Cost:* the numbers want the Quest's check.
13. **VR hands act wherever they are** (no reach check: the grapple brings the child to things). *Cost:* none in play.
14. **Hoot's voice is not placed at his shoulder**: the system's text-to-speech is not positional. *Cost:* the design's
    "his voice placed there" waits for recorded lines.
15. **The leaf's draws are counted in the menu's census phase** (FIRST: warmed before the menu shows). *Cost:* the menu's
    warm-up compiles a few more programs at the start (none new: they were LATER or WORLD).
16. **The leaf's place and the dive are built a step a frame while the child is in the garden** (`staged`,
    `build_step`); a child who dives at once waits for what is left. *Cost:* a few longer frames in the garden (the
    worst step 18-35 ms here, see B2.6).
17. **One look for both graphics styles** (the design's ruling 15): the blocky avatar always. *Cost:* a realistic child
    sees their blocky self inside the leaf.
18. **The desert's hook in B2 is the garden terrace with a cactus in a pot of sand**, its answer the white flower in the
    garden's evening light (the dune and the desert night's sky are B3's dressing). *Cost:* 5.T1's hook is less
    desert-like until B3.
19. **`menu.gd` is unchanged** (`PlayHost.any_open` already sees a voyage); the pause key: `LeafHud` takes Escape and a
    controller's Start for the break. *Cost:* none.
20. **A crystal's short round opens a whole voyage** (`count` ignored); its end logs the crystal as W1's code does.
    *Cost:* a crystal's "minute" becomes a voyage of a few minutes.

## B2.5 The pictures, and what changed after looking

`tools/leaf_shots.gd`'s `host_` shots, the voyage itself in a real window (the Vulkan Mobile renderer, the PC's Intel
UHD, 1280 x 720): `docs/devlog/parts/game-leaf-b/` 14 the garden's hook (the HUD), 15 inside, the overview (the avatar
and Hoot), 16 a door glided to, 17 the avatar's eyes, 18 the desert's night, 19 the end card over the bloom, 20 the
voyage board; 04 (the dive's hairs) again, its cells now one MultiMesh.
- **First look:** the coach's bar was a wide, empty dark band over the sky (the voice on, nothing to read); the camera
  button showed in the garden and on the end card, where it does nothing; the avatar's eyes looked at the back of its
  own head; Hoot at its shoulder was a speck; the end card covered the bloom it celebrates (and once lowered, cut its
  buttons off); the leaf's inside looked paler than B1's pictures (Act 1's thirsty cells: right, B1's shot held the
  leaf at exactly half full).
- **Changed:** the bar holds only Hoot and the ear (the whole bar comes back for a reader); the camera button only
  inside; the avatar's body hides in first person; Hoot 0.7 tall at the shoulder; the end card low, whole, the open
  sunflower above it.

## B2.6 The draws and the bench

- **The tests' count** (each mesh, MultiMesh or particle system one draw, the HUD's drawn Controls one each with no
  batching: a ceiling): the host's whole frame at its heaviest inside, **5.1 52 (3D 43, HUD 9), 5.T1 54 (45, 9)**; the
  places alone as in B1 (inside 22-28, the garden 15-16 with the game's owl, the dive 3-4).
- **A real frame's draw calls** (`tools/leaf_bench.gd`, a window, this PC under load): the garden 35, the dive 25-40,
  inside 5.1 at its heaviest 66 (at most 74), the desert's night 66, the end card 77-84; 220-950 fps. The HUD's canvas is
  about 20 of them; in VR the HUD is the forearm's panel and there is no flat avatar, so inside should be about 40 (the
  Quest's check).
- **Building** (`leaf_bench`'s `build` lines): at once, the garden 21 ms, the dive 38 ms (it was 145: its 600 skin
  cells are one MultiMesh now), the leaf's place 44-66 ms (the cactus's 63-110); built a step a frame in the garden,
  the worst step 18-35 ms (the dive's leaf surface, the cactus's dressing). The first PLAY of a session loads the
  voyage's scripts and builds the garden and the HUD in one frame: 360-720 ms here (finding B2-2).

## B2.7 Findings for the lead

1. **VR's vignette while swimming:** `Vr` eases its vignette by the rig's motion only when a player is spawned (the
   world), so a voyage opened from the menu's School swims without it (one condition in `autoloads/vr.gd`, not mine:
   the rig's velocity while anchored to a `&"life"` stand too).
2. **The first PLAY's load:** the voyage's scripts, the garden and the HUD are made in the frame PLAY is pressed
   (360-720 ms on this PC, 1-2 s on a phone, the School's page frozen meanwhile). A loading card or a deferred `open` in
   `SchoolScreen.show_play` would hide it (G0's file; PlayHost has the same, smaller).
3. **P1 one phase early** (ruling B2-3): the lead's call.
4. **The census marks** (ruling B2-15): worth a look at the menu's warm-up time on the web.
5. **The emulator and the Quest:** the frames over 100 ms and the swimming's comfort are theirs to see (B2.8).

## B2.8 What B3 and the lead's emulator and Quest check need

- **B3 ("the voyage sings"):** the desert's full dressing (the dune at noon, the night sky, the moth, the white flower
  under the moon), sounds (`tools/make_leaf_sfx.py`: the doors' squeak and sigh, the cells' bloop, the gold pipe's
  whoosh, cicadas, crickets; Hoot's owl call), music (Bach's *Air* inside, the *Waltz of the Flowers* for the bloom,
  *Moonlight* for the desert), juice (the bloom petal by petal, the bee's flight, the leaf's lift, the cloud's shadow
  over the roof, heat shimmer, the dive's chimes and sparkle, the gold pipe's whoosh).
- **The emulator** (the brief's budget: 30 fps, no frame over 100 ms): open the unit's PLAY (the first load, finding
  2), the garden while the leaf builds a step a frame, the dive, Act 1, a cloud and a blaze, the end card; both
  voyages.
- **The Quest** (72 Hz, at most 100 draws): the garden at the anchor, the can, the dive's growing garden, swimming and
  its comfort (the vignette: finding 1), the grapple, the two-hand squeeze's numbers (ruling B2-12), carrying sugar,
  the forearm panel, Hoot at the shoulder.

## B2.9 The full suite

Right before it, `lead-w1b` was merged again ("Already up to date": the branch holds it at `ec234ebf`), the project
imported; `tests/run_tests.sh` ran once on that tree (`590c9ead`) under the PC-wide slots, uncut (the lead's own suite
ran beside it): **1,331 scripts, 12,294 tests, 12,291 passing, 0 failing, 3 risky or pending** (the known ones: the
voxel column cache's two tests don't assert, the Nakama move is off), 5,637 s, no script error.

**After the run, `lead-w1b` had moved on** (36 commits: the rooms' look for every room, Word Magic's and Balance Altar's
briefs, 1.0.8), so it was merged in again (`d8fc5a46`, no conflicts; its code changes are the rooms', the Life and
Success rooms' and the release test's). On that tree the rooms' look's three files, the leaf's host, VR, voice, place
and budget files, the registry's two, the warm-up's, G0's audit and mechanics, the class scan and the winding test:
**139 of 139**. The full suite was not run again on it (the brief's one run is the one above).

## The lead's review of B2 (2026-10-18 10:55)
**B2 passes.** Both voyages play from start to end, flat and in a simulated headset, opened from the School's PLAY,
Hoot's pick, a crystal and the Academy's Science door; the record lands with each note saying what it shows (the
lead's ruling on finding 2). **The registry** (`PlaySignature`: a deep game's host is a `PlayHost` subclass registered in
`mechanics.json`'s `signature` table; `make_host(content)` everywhere; unknown or broken names fall back to G0's
`PlayHost` with a warning; the outcome's optional `then` reopens the unit with new params) is the one Balance Altar and
Fraction Bakery adopt. Pictures 14-20 looked at: no words on the screen while a voyage plays. Merged into `lead-w1b`
(the rooms' look and 1.0.8 already in it): 797/797 on the leaf, registry, play, discovery, School, menu, warm-up, winding
and look files. Decisions:
- **The plants unit as P1 now:** accepted. It is played by its own game, whose 5.1 teaches most of it; the 5.2 voyage
  completes it in phase C. Cost: the audit and the grown-ups' page show it covered a phase early.
- **The VR vignette in a voyage opened from the menu's School:** the lead fixes it in `autoloads/vr.gd` (test first):
  a swim must never run without the comfort vignette.
- **The first PLAY's load (360-720 ms here, about 1-2 s on a phone, the page frozen):** B3 adds a loading moment (a
  picture card and Hoot's line, the host built a step a frame), granted in `show_play` and `_open_place`.
