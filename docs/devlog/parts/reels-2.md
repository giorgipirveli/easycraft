# Learning reels, round 2: twelve live 3D lessons in the SHORTS feed (owner #94, #96)

The owner (#94, #96): "educational, like how to build a rocket, lessons explanations, learning animations … we must
keep reels high quality". The Reel Studio (`docs/devlog/parts/reel-studio.md`) made the tools and eight cinematic
reels; this round used them for **12 more learning reels**, each teaching one real idea a child of 8-13 can grasp in
50 s, spread over the School's subjects and the game's worlds. Built in the worktree branch
`worktree-agent-a72440daee69e4841`, reset to `lead-merge` (`47f35a8b`) first, while other agents improved the lessons
(round 2) and the Seven Natural Wonders. No editor, emulator or adb was used; pictures came from real windows
(`tools/reel_preview.gd` frame sheets, `tools/reel_render.gd` frames at 540 × 960).

## What a child sees

Twelve new reels in the Theater's SHORTS feed, each beside its topic's Shorts, each **live 3D** (drawn by the phone
as it plays: a few KB of data, offline, sharp at any size), under the same big captions, stickers, voice and sounds as
every Short, ending on a question to wonder about, and LEARN IT opening its School unit:

| Reel (topic, LEARN IT) | What happens on the stage |
|---|---|
| **How a volcano erupts** (science, g4 Volcanoes and earthquakes) | An island volcano; its front half sinks away to show the magma chamber and the pipe (stickers with arrows on both); the chamber swells and glows as gas bubbles build, magma climbs the pipe and the volcano erupts (a lava fountain, ash, the camera shaking); lava pours down the back slopes and cools into black rock with a puff of steam; then Jupiter's moon Io with a plume rising high in its weak pull, Jupiter behind it. |
| **The water cycle in 3D** (nature, g6 The water cycle) | An island: the sea, a beach, a river and a snowy mountain. Vapour rises off the whole sea (a sticker says it is really invisible: we drew it); it condenses into a cloud of the game's cloud blocks that drifts over the mountain, turns grey and rains (snow on the top); a glint follows a drop down the river to the sea. The four stages are the lesson's own words, numbered. |
| **Why we have seasons** (space, g5 Shadows, days and seasons) | Earth round the Sun with its axis tilted 23.4°; a camera that rides with Earth without turning shows the axis keeping its direction (to the North Star) while the sunlight goes round; June close up (the north leans toward the Sun: summer) and December (away: winter), the line between day and night crossing the poles; then the surprise: Earth is closest to the Sun in January (147 million km) and farthest in July (152). |
| **Why day turns to night** (space, g5 Shadows, days and seasons) | A child on a little island waves as the Sun rises in the east and climbs while the sky turns from dawn to day; out in space Earth spins once a day (24 hours), its night side dark; a little house on the turning Earth is carried from the day side across the line into the night (SUNSET HERE); back on the island it is night, the windows glow, the child yawns. |
| **How the pyramids were built** (history, g4 Ancient Egypt) | By the Nile, two haulers lean back on a rope dragging a limestone block on a wooden sledge while a third pours water on the sand ahead; course after course drops into place as a ramp grows up the south face, the count runs to 2.3 million blocks; the ramp goes, smooth white casing stone covers the steps and sparkles; a child at its foot at sunset. |
| **Levers and pulleys lift** (science, g5 Gears and pulleys) | A plank on a pivot with a 60 kg barrel 1 m from it: a 20 kg child hops onto the far end 3 m out and the barrel rises (60 × 1 = 20 × 3); a pulley: the puller walks back pulling the rope down and the barrel goes up, the wheel turning; a second pulley that rides up with the load: two ropes hold it, the pull is 30 kg, and 2 m of rope lifts it 1 m (counted); a building-site crane lifting a pallet of bricks. |
| **The Moon's phases in 3D** (space, g8 Moon phases, eclipses and seasons) | From above, sunlight from one side lights one half of the Moon as it goes round Earth (the four phases' places labelled); then from Earth itself, the camera keeping the Moon in the middle as it goes round: a new moon (the Sun behind it), a crescent, first quarter, gibbous, full; about 29½ days. |
| **How plants make food** (nature, g5 Plants grow from air and water) | A tree on soil cut open at the front: glowing drops go from the soil into the roots and up the trunk to the leaves; grey carbon dioxide comes in through tiny holes; sunlight sparkles on the leaves; golden sugar goes down to the roots; light blue oxygen comes out to a child who stretches and waves. |
| **How mountains grow** (science, g6 Plate tectonics) | A slice of Earth's crust: two plates of rock layers over hot soft rock; they creep together (arrows); where they push, the same layers fold up into a mountain range with a snowy top (dust); India and Asia, Everest 8,849 m; a child drops onto the top and cheers. |
| **Volume with blocks** (maths, g5 Volume with cubes) | One cube; a row of 4 drops in, then two more rows (4 × 3 = 12); a second layer (12 × 2 = 24; length, width and height labelled on the edges); a 3 × 3 × 3 cube builds in three coloured layers while the count steps 9, 18, 27; the puzzle: a 2 × 2 × 2 cube holds 8, double every side: how many? |
| **How gold is found** (science, g7 Earth's resources) | An old hill with a white quartz vein glinting in its cliff; rocks crumble into the river and a golden glint is washed downstream; at a bend, heavy gold flakes sink into the gravel bed (sparkling) while sand drifts on; a prospector swirls a pan, the water and sand splash out and gold sparkles; then walks upstream to the vein. The game's own prospecting: gold quartz and gold gravel blocks, the panning recipe's fact. |
| **Why things float or sink** (science, g5 Properties of materials) | A tank cut open at the front: a wooden block splashes in and floats half under; a stone the same size sinks; arrows for its weight and the water's push; ice floats with nine tenths under; an iron lump sinks but the same iron as a thin hollow boat floats, as deep as its weight says. |

## The tools this round added (the rigs)

| What | Where | Why (which reel) |
|---|---|---|
| **Riders** (`on: <model>`): a model goes and turns with another, in its space (its pop too, not its builder's size or stretch) | `StudioMotion.frame/world/shown`, `Built.frame` | a barrel and a child on a lever's plank, Earth on its tilted axis, a house on the turning Earth, a stone on a sledge, a pulley riding up with its load |
| **Stretch** (`stretch: [x, y, z]`) and a **grow along an axis** (`grow` with `axis`) | `StudioMotion.state/basis_of` | an axle rod, a sledge, the iron boat's plates, a ramp rising, magma climbing a pipe, a mountain range folding up |
| **Marks** (`model: mark`): nothing drawn, a point to ride with, aim at or come from | `Scene3DModels` | the camera standing on Earth, the hauler's hands, a drop following the river |
| **Ropes** (`model: rope`, `from`, `to`, `from_at`, `to_at`, `width`, `block`) | `StudioMotion.rope`, `RopeBuilt` | pulleys, haulers, the crane |
| **Walking** (`legs`: steps, arms swing / pull / push / up, lean) | `StudioMotion.walk_pose`, `AvatarBuilt` | haulers, pullers, the prospector |
| **The camera aims** (`aim: <model>`: the look follows it) | `StudioCamera` | the Moon kept in the middle |
| **Light and sun keys** (`light`, `sun`: keys that fade) and a **night** sky and light | `StudioRules.light_at`, `Scene3DView._set_light` | sunrise and night on the island, Io in space, the pyramid's sunset |
| **A planet's night side** (`night`: 0-1, the flight shader's own parameter) | `PlanetBuilt` | Earth's day and night line and the Moon's phases read on a phone |
| **Blocks from shapes** (`fill`: box, disc, cylinder, cone, ball; `AIR` carves; then `cells`) | `StudioShapes` | the volcano, islands, the pyramid's courses, mountains, tanks, a pan |
| **Rain** (upright streaks off a flat patch), a **lava** fountain, an effect's own **gravity** and **area** (born across a patch) | `StudioParticles` | rain and snow, the eruption, Io's plume in a weak pull, vapour off a whole sea |
| More of the game's emotes (yawn, stretch, look, laugh) | `StudioRules.EMOTES` | the night yawn, the morning stretch |
| The **reel checker** headless: `godot --headless --path . --script res://tools/reel_check.gd -- --short=<id>` (or `--all`) | `tools/reel_check.gd` | ShortCheck's and ReelCheck's findings while writing |
| The **learning reels' generator**: `python3 tools/make_learning_reels.py [ids]` writes each reel from its script in `tools/learning_reels/<id>.py` (the kit: `reelkit.py`: scenes, stickers kept inside the frame, arrows placed on 3D points by projecting them, shapes, moves, cameras) | `tools/make_learning_reels.py` | every reel here: tune a camera or a model and make it again |

Every rig is a pure function of the time (a seek shows the frame playing reaches); none adds a material or a shader:
the blocks are the world's library, the particles the golem's glow and Fx's boxes, ropes a block, the night side the
flight shader's own `night` parameter (`test_the_new_rigs_draw_only_the_game_s_own_looks`).

**Building is cheap (measured):** a blocks model's shapes are filled a row at a time into a VoxelBuffer (C++
`fill_area`) on a worker thread and meshed on the main thread a frame later (`Scene3DModels.BlocksBuilt`; a mesh made
on the worker lost its RIDs in the headless renderer, so only the buffer is); the same shapes again come from a small
keep (24 meshes). The first cut built the volcano in 66-360 ms (14,000 cells one by one, BlockIds' constant map read
for every shape, every vertex moved in GDScript); now every learning reel builds in 4-13 ms here, the buffer and mesh
of the volcano's island 3.6 + 4.7 ms. The reel tools (`sync_blocks`) mesh at once, so a sheet or a video never misses
an island. `test_a_voxel_buffer_of_the_shapes_holds_exactly_their_cells` proves the buffer holds exactly
`StudioShapes.cells`. Riders, ropes and the camera share a pose's places (`Scene3DView.frame_of/world_of`): the
lever's pose fell from 2.6 to 1.4 ms.

## The facts and their sources

Every number on the screen is worked out again by `tests/unit/test_reel_studio_learning.gd` from the game's tables or
the cited constants below, and the 3D is checked to show what the words say.

| Reel | Its facts | Checked against / sources |
|---|---|---|
| Volcano | Magma under the ground, lava once out; gas bubbles drive an eruption; lava often over 1,000 °C and cools into new rock; Io: about 400 volcanoes, Jupiter's pull squeezes it and keeps it hot. | The Star Map's Io facts (the test reads "about 400 volcanoes" and "Jupiter's pull squeezes Io"); USGS Volcano Hazards Program ("Magma is molten rock beneath the surface; erupted, it is lava"; basaltic lava erupts at about 1,100-1,200 °C; dissolved gases expanding as magma rises drive eruptions); NASA Science, "Io" (the most volcanically active world; tidal heating by Jupiter). The test also checks the chamber is deep and the magma reaches the crater. |
| Water cycle | 97 drops in every 100 are in the sea; evaporation, condensation, precipitation, collection; vapour is invisible. | USGS Water Science School, "How much water is there on Earth?" (96.5 % in the oceans, rounded to 97 in 100); the School's g6 water cycle lesson (the test reads its evaporation, condensation and precipitation); Met Office, "The water cycle". |
| Seasons | Tilt 23.4°; the axis points the same way (the North Star) all year; June: north toward the Sun; December: away; closest in January 147 million km, farthest in July 152. | NASA Earth Fact Sheet (obliquity 23.44°; perihelion 147.09, aphelion 152.10 million km); NASA Space Place, "What causes the seasons?". The test turns the axis model round the orbit: its north leans sin 23.4° toward the Sun in June's scene and away in December's, keeps one direction all year, and goes round anticlockwise seen from the north. |
| Day and night | The Sun seems to rise in the east; Earth spins once every 24 hours; the sunlit half has day; a home turning away from the Sun has sunset. | NASA Space Place, "What causes day and night?". The test checks the island's Sun rises in the east (+x, north is −z as on MY MAP) and climbs, one spin is the reel's day, and the home on Earth is in sunlight before SUNSET HERE, on the day-night line at it and in the night after. |
| Pyramids | About 4,500 years ago, for King Khufu; sledges on wet sand; about 2.3 million blocks; ramps; smooth white casing; 146 m tall; the tallest building for about 3,800 years. | WonderFacts (the game's Wonders tour; the test reads every one); Encyclopaedia Britannica, "Pyramids of Giza"; the wall painting in Djehutihotep's tomb (a worker pours water in front of a sledge) and Fall et al., *Physical Review Letters* 112, 175502 (2014): wet sand halves the pull. The test checks each course is one block smaller on every side. |
| Levers and pulleys | 60 kg at 1 m balances 20 kg at 3 m; a pulley turns a pull down into a lift up; a pulley moving with the load: two ropes share it, half the pull (30 kg), twice the rope (2 m for 1 m). | The law of the lever (Archimedes); BBC Bitesize KS3 Physics, "Simple machines"; the School's g5 gears and pulleys unit. The test reads the barrel's and the child's distances on the plank, counts the ropes holding the moving pulley (2), and checks the load's rise against the rope counted. Ideal pulleys (ruling 6). |
| Moon's phases | The Moon makes no light; half is always lit; new, crescent, first quarter, gibbous, full; about 29½ days new to new. | NASA Science, "Moon Phases" (synodic month 29.53 days). The test puts the Moon between Earth and the Sun at the start of the new-moon scene, a quarter round 10 s later and on the far side at full, anticlockwise from the north, and the camera on Earth aiming at it. |
| Plants | Roots drink water; tiny tubes carry it up; carbon dioxide in through tiny holes; chlorophyll catches sunlight and makes sugar; oxygen out; a big oak drinks over 100,000 litres a year. | BBC Bitesize KS3 Biology, "Photosynthesis" (stomata mostly under the leaf, xylem tubes); USGS Water Science School, "Evapotranspiration and the Water Cycle" (a large oak transpires about 40,000 US gallons, 151,000 litres, a year). The test checks every drop starts in the soil and ends in the leaves. |
| Mountains | Plates a few cm a year, as fast as fingernails grow; pushing plates fold rock layers into mountains; India into Asia made the Himalayas; Everest 8,849 m; still rising about 1 cm a year. | USGS, *This Dynamic Earth* ("The Himalayas: two continents collide"; still rising more than 1 cm a year); NOAA Ocean Service (plates move about as fast as fingernails grow); Everest 8,848.86 m (Nepal and China's survey, 2020). The test checks the plates move toward each other and the range is made of the plates' own layers. |
| Volume | 1 cube; 4 × 3 = 12; 12 × 2 = 24; volume = length × width × height; 3 × 3 × 3 = 27; 2 × 2 × 2 = 8; puzzle 4 × 4 × 4. | Arithmetic; the test counts the cubes the models really hold (24, 27, 8). The School's g5 volume unit. |
| Gold | Gold forms in white quartz veins in old hills; rain and rivers wash flakes downstream; gold is very heavy (19 times as heavy as water), so flakes sink into the gravel; panning: light sand washes out, gold stays; follow the flakes upstream to the vein. | DepositKinds.GOLD (the game's: "white quartz veins in old hills", its sign block GOLD_GRAVEL, its ore GOLD_QUARTZ: the test checks the reel's vein and gravel are those blocks) and RefiningRules' pan_gold fact; gold's density 19.32 g/cm³ (Encyclopaedia Britannica, "gold"); USGS, "Prospecting for Gold in the United States" (placer gold in river bends). |
| Float or sink | Wood floats about half under; stone sinks; water pushes up as hard as the water pushed aside weighs; ice floats with 9/10 under; a lump of iron sinks, the same iron as a hollow boat floats. | Archimedes' principle; densities (kg/m³): water 1,000, pine wood about 500 (Engineering ToolBox, "Wood species densities"), ice 917 (USGS), granite 2,700, iron 7,870 (Encyclopaedia Britannica). The test works out every floating depth from these (wood 0.5 under, ice 0.917, the boat's depth from its plates' iron) and checks the lump is the boat's iron in one piece. |

## What the frame-sheet reviews changed

Every reel went through four rounds of frame sheets (a picture every half second, the stage live), with pictures at
540 × 960 for the moments in doubt, and its **final sheet was read whole** (every second of it); what looked cheap or
wrong was fixed. One honest note: the first sheets of the volcano and the water cycle could not be read back here (the
review tool's picture limit), so their first changes came from the framing maths (`reelkit.project()`: where a 3D
point lands in the tall frame); every later round, and every final sheet, was looked at.

- **Volcano:** first from the maths: a wider, higher opening (the tall frame shows about 29° across), the front half
  sinking further and a wider cutaway shot, the lava flows lying on the slope's steps, the stickers' arrows placed by
  projecting the chamber and the pipe. On the sheets: Io's one long sticker ran off the frame (now IO and ABOUT 400
  VOLCANOES on two lines); "lava over 1,000 °C" overclaimed (now "often over": basalt's 1,100-1,200 °C). The final
  sheet: the island, the cutaway with MAGMA and PIPE on their parts, the magma climbing, the eruption shaking the
  camera, the flows turning to black rock with steam, Io's plume with Jupiter behind.
- **Water cycle:** first from the scripts: vapour off the whole sea (an effect's new `area`) instead of a few columns,
  a cloud of the game's cloud blocks instead of billboard puffs, a winding river from the mountain, more and longer
  rain. On the sheets: the "we drew it" sticker was too wide (smaller letters). The final sheet: the four numbered
  stages read in turn.
- **Seasons:** the first follow shot sat level with the orbit (raised above it); the day-night line was faint (a
  planet's darker night side: `night`); the January and July labels crowded the orbit (fixed places with arrows); on
  the final sheet the TILTED 23.4° sticker popped over a wide shot where the axis cannot be seen (the camera now flies
  in to Earth's sunlit side as it pops: checked at 540 × 960).
- **Day and night:** at 540 × 960 Earth looked lit all round (`night` 0.04: a clear night half, measured: the night
  side's brightness 0.16 against the day side's 0.62 before); the house on Earth was a speck (bigger); on the sheets
  the island's opening hid the rising Sun behind a tree and left the child at the frame's edge (the tree moved, the Sun
  rises in the middle of the east, the child waves in front of the house), and the night shot showed the child's legs
  only (a lower camera).
- **Pyramid:** the child at the end was a speck far behind it (now at its foot, for scale) and the last shot was too
  close (wider).
- **Levers and pulleys:** the child was first placed beside the plank (it now hops onto the far end: its weight is the
  push, and it rides the plank down upright); the puller walked sideways out of the tall frame (now walks back, away
  from the camera; the yard is longer); the quality test found PULL on LOAD (staggered); on the final sheet the counts
  read 1 m PULLED with 1 m UP halfway (now one decimal: 1.0 m pulled, 0.5 m up).
- **Moon's phases:** the Moon got the darker night side too (the new moon dark, the crescent reading: checked at 540 ×
  960); the camera first rode beside Earth (now in Earth itself, looking out); the quality test found the quarter
  labels on each other (staggered); the last shot lost its orbit line: a real bug in StudioMotion (a model coming back
  after an `out` stayed at size 0 under its `pop`: the Reel Studio's orrery lost its orbit lines the same way; fixed,
  test `test_a_model_that_leaves_and_comes_back_is_its_full_size_again`) and the shot was too close for the orbit
  (higher).
- **Plants:** the roots sat under the caption's band and the drops were too small to see (the roots higher, every bit
  bigger and glowing, each shot aimed at its step; the ROOTS sticker leaves before the camera climbs the trunk).
- **Mountains:** the slice filled only the top of the frame (framed to fill the middle band, the hot rock thinner,
  the arrows under the sticker); the last sticker was too long (two lines).
- **Volume:** the edge labels came near the frame's sides (kept inside); on the final sheet the row count ran ahead of
  the cubes (now it steps as each one lands) and the big cube's count steps 9, 18, 27 with its layers.
- **Gold:** at 540 × 960 the flakes were brown specks lost in deep water (glowing gold cubes, a shallow gravel bed, a
  sparkle where they land); the pan's splash covered the prospector (smaller).
- **Float or sink:** at 540 × 960 the glass panes drew a grid over everything (the tank is cut open at the front with
  a white back wall and 3 m of water); the quality test found the push and weight labels on the other stickers (they
  leave before the next pair).
- Every sticker is now placed by `reelkit.words()` inside the frame's safe sides and above the caption's band (the
  quality test, `test_short_quality`, found seven off the frame or on each other before).

## Sizes and the cost on a phone

All twelve are **live** (no video): 126,692 bytes of JSON together (6.6-15.3 KB each); the APK's videos stay at
19.6 MiB (under the 20 MiB the Reel Studio ruled). The bench (`tools/reel_render.gd -- --bench`, this PC's Intel iGPU,
the Shorts' player at a phone's 288 × 512 and 432 × 768; pose: the CPU's work to pose every model, particle and the
camera):

| Reel | Pixels | Stage GPU avg / p95 / max | Pose avg / max (CPU) | Draws | Triangles |
|---|---|---|---|---|---|
| Volcano | 288 × 512 / 432 × 768 | 1.03 / 1.57 / 2.19 · 1.25 / 1.75 / 7.28 ms | 0.86 / 3.18 · 0.88 / 3.58 ms | 9 | 12,568 |
| Water cycle | both | 1.28 / 1.96 / 4.13 · 1.56 / 2.11 / 4.72 | 0.94 / 4.68 · 0.94 / 4.47 | 9 | 14,738 |
| Seasons | both | 0.58 / 0.75 / 0.82 · 0.93 / 1.36 / 1.50 | 0.80 / 1.70 · 0.77 / 1.65 | 8 | 10,426 |
| Day and night | both | 0.83 / 1.53 / 2.29 · 1.49 / 2.31 / 4.66 | 0.80 / 2.17 · 1.06 / 2.18 | 18 | 7,540 |
| Pyramid | both | 1.67 / 2.07 / 3.87 · 2.67 / 3.36 / 6.76 | 1.32 / 3.19 · 2.43 / 5.33 | 51 | 25,906 |
| Levers and pulleys | both | 1.29 / 1.77 / 1.96 · 1.41 / 1.73 / 3.21 | 1.51 / 3.41 · 1.32 / 4.12 | 38 | 3,916 |
| Moon's phases | both | 0.59 / 0.67 / 0.69 · 1.10 / 1.23 / 1.34 | 0.66 / 1.36 · 0.73 / 1.57 | 7 | 14,570 |
| Plants | both | 2.03 / 2.91 / 6.30 · 2.34 / 2.90 / 4.28 | 1.15 / 2.43 · 1.10 / 2.65 | 24 | 7,572 |
| Mountains | both | 1.20 / 1.86 / 1.93 · 1.00 / 1.55 / 3.27 | 0.75 / 1.97 · 0.47 / 1.08 | 17 | 5,084 |
| Volume | both | 0.89 / 1.48 / 2.21 · 0.87 / 1.00 / 3.66 | 0.52 / 1.92 · 0.40 / 0.95 | 9 | 1,440 |
| Gold | both | 1.31 / 1.61 / 3.37 · 1.55 / 1.66 / 6.09 | 0.98 / 2.51 · 0.97 / 2.26 | 21 | 7,174 |
| Float or sink | both | 0.90 / 1.17 / 2.96 · 1.40 / 1.56 / 3.33 | 0.54 / 1.11 · 0.53 / 1.80 | 9 | 2,714 |

Like the Reel Studio's live reels (0.45-3.6 ms of GPU, about 1 ms of pose): on a phone about 2-8 ms of CPU a frame
and a few ms of GPU on top of the world's. Building one in the feed (a neighbour, a frame of its own): 4-13 ms here
(`test_shorts_view`'s bench, every hand-made Short: build max 21 ms, as before).

## Rulings (each with what it costs if wrong)

1. **All twelve live, no video.** The APK's videos are at 19.6 MiB of the Reel Studio's 20 MiB, and every learning
   reel is light (1,440-25,906 triangles, the bench above). *If wrong:* a reel too slow on a weak phone can be rendered
   (`"video"` and `tools/reel_render.sh`); it would then go only into the web's reels pack, or the APK's cap rises.
2. **New rigs instead of rendering** (riders, stretch, ropes, walking, marks, aim, light keys, a night side, shapes,
   rain, lava): teaching needs things that move together (a lever's load, a pulley's rope, Earth's tilted axis), and
   they keep the reels live. *If wrong:* none known: each is a few lines of data, checked (Scene3DKind) and tested.
3. **The reels are written by a generator** (`tools/make_learning_reels.py`, one script a reel in
   `tools/learning_reels/`): its JSON is generated; an edit by hand is lost on the next make. *If wrong:* move a hand
   edit into its script (the scripts are short and say what each number is).
4. **"Gold" is said in *How gold is found***: the metal, the game's prospecting, not a reward; `test_short_library`'s
   no-rewards test allows the word in that reel only (`GOLD_IS_THE_SUBJECT`). *If wrong:* a child may link the metal
   to the game's gold coins; the reel never mentions coins, prices or rewards.
5. **Not to scale** where it cannot be: the seasons' orbit (a sticker says so), the Moon's orbit, Earth with a house,
   the pyramid ("the model is smaller"), the mountains. Every number on the screen is the real one.
6. **Ideal pulleys** (no friction, weightless wheels): half the pull exactly, as the School teaches it at grade 5.
   *If wrong:* a real pulley needs a little more than half; the reel says "half the pull" as the lesson does.
7. **"97 drops in every 100"** rounds USGS's 96.5 % (many sources say about 97 %). *If wrong:* half a drop in 100.
8. **A live reel's blocks appear the frame their mesh is in** (a buffer filled on a worker, meshed a frame later): in
   the feed a neighbour is built seconds before it plays, so a child sees them at once; a reel opened from the list
   may show its island a frame or two late on a slow phone. The tools mesh at once. *If wrong:* `sync_blocks` makes
   it synchronous (4-13 ms here, about 3-5× on a phone).
9. **A planet's night side can be darker per reel** (`night`, the flight shader's own parameter, no new shader): the
   flight's 0.12 made Earth's night side and the Moon's phases hard to read on a phone. *If wrong:* none; other reels
   keep 0.12.
10. **The water's vapour, the Moon's lit half and the sugar are drawn** (the vapour sticker says it is really
    invisible). *If wrong:* none: the lesson says the same.
11. **Where each reel sits in the feed:** beside its topic's Shorts (seasons and day and night with the orbits, the 3D
    phases after the drawn phases, levers and pulleys after the lever, the 3D water cycle after the food chain,
    volume after place value, the pyramid before the Seven Wonders). *If wrong:* one list, `data/shorts/shorts.json`.
12. **Topics:** volcano, plates, gold, levers, floating: science; water cycle, plants: nature; seasons, day and night,
    Moon's phases: space; volume: maths; pyramids: history (the six topics the feed knows). *If wrong:* one field each.

## Frame sheets

The last sheets of every learning reel: `build/reel_render/sheets/<id>_sheet.png` in the worktree (git-ignored; made
again by `XDG_DATA_HOME=/tmp/easycraft-reels godot --path . --disable-vsync --script res://tools/reel_preview.gd --
--sheet --short=<id>`; a frame every half second, the stage live, the captions and stickers on).

## Tests

- `tests/unit/test_reel_studio_rigs.gd` (riders, stretch, walking, ropes and their points, the camera's aim, light
  keys, a night sky and light, shapes and their checks, a voxel buffer holding exactly the shapes' cells, rain, a lava
  fountain, an effect's gravity and area, every rig's checks), `tests/integration/test_reel_studio_rigs_view.gd` (a
  rider drawn where its model carries it, a mark drawing nothing, shapes meshed and carved, a rope between its ends,
  stretch, walking legs, a sunset's lights and the planets' day side following, a darker night side, blocks meshed on
  a worker and kept, a rendered reel meshing at once, only the game's own looks).
- `tests/unit/test_reel_studio_learning.gd`: every learning reel checks (ShortCheck, ReelCheck), plays live, is in the
  feed, lasts 40-55 s and links its School unit; every fact above.
- Small hooks in others' tests: `test_short_library.gd` (gold as the subject of one reel).
- **The full suite** (2026-10-01 08:41-09:39, at `9a8492d1`, `tests/run_tests.sh`): 1,043 scripts, 9,573 tests,
  **9,569 passing, 2 failing**, 2 risky (the generator's two assertion-free tests, as on lead-merge), no SCRIPT ERROR
  or Parse Error, 57 min. The failures: `test_nakama_account_key`'s wallet gold (the account-key flake the lead has
  open: "the account-key flake open", lead-merge's 02:55 note; nothing of mine touches accounts), and my own
  `test_a_blocks_model_is_meshed_on_a_worker_thread_and_shows_when_it_is_in`, which found its hill already kept by an
  earlier test in the whole run (an order dependence of the test, not of the game): it now meshes shapes no other test
  has, and passes with the view tests (`-gtest=test_scene3d_view.gd,test_reel_studio_rigs_view.gd`: 19 of 19).

## What the lead must check on the emulator

1. **The live reels' frame rate** in the Theater (FPS overlay): the pyramid (51 draws, 26,000 triangles) and the
   levers and pulleys (riders and ropes) above all; ≥ 30 FPS, no frame over 100 ms, the world rendering behind.
2. **Swiping into a reel with blocks** (the volcano, the pyramid, the water cycle): the island is there when the reel
   snaps in (meshed on a worker a frame after the build); a reel opened from the list shows it within a frame or two.
3. The **night sides** (seasons, day and night, the Moon's phases) read on the phone's screen: a clear crescent and a
   day-night line.
4. **Ropes** (the pyramid's haulers, the pulleys, the crane) are visible at the phone's scale (6-8 cm thick in the
   model).
5. The REALISTIC style: the blocks follow it (the islands, the pyramid); check the reels still read.

## Merge notes

- Shared files touched (small hooks): `core/shorts/studio/*` (StudioRules, StudioMotion, StudioCamera,
  StudioParticles, Scene3DKind; new StudioShapes), `ui/shorts/actors/scene3d_models.gd`, `scene3d_builds.gd`,
  `scene3d_view.gd`, `tools/reel_preview_steps.gd` and `tools/reel_render_steps.gd` (`sync_blocks`),
  `data/shorts/shorts.json` (the feed's order), `tests/unit/test_short_library.gd` (the no-rewards test), `.gitignore`
  (the generator's caches).
- New: `core/shorts/studio/studio_shapes.gd` (class StudioShapes: run `--import` after the merge),
  `data/shorts/cinematic/` twelve reels, `tools/make_learning_reels.py`, `tools/learning_reels/`, `tools/reel_check.gd`
  (+ `_steps.gd`), the tests above.
