# Universe 6, the Glow Caves (spec §5.1; the forever roadmap §3, §4, §6)

The owner: "make the game such an interesting that to unlock new universies people will be ready to pay money later …
create amazing and best visuals" (#72), "closer to real worlds so the player starts learning real things … more secrets,
more excitements" (#74), and (#122, 2026-10-17) learning happens as play, never as lectures or slides. Brief:
`docs/superpowers/plans/2026-10-01-glow-caves-brief.md` (its 2026-10-17 section wins: page 45, ids 768-783, the pages'
budget, VR on the Quest 3). Built by a worker agent in its own worktree (branch `worktree-agent-a2b05101a5d67be92`, cut
from `lead-merge` 398fb283), without the editor, the emulator or adb.

## 0. Report before building: the pattern, the rejected alternative, and why

**The pattern: the Dragon Realm's universe pattern** (universe 5, owner #39): a descriptor `world/universes/glow.gd` on
the ladder (`UniverseRegistry.LADDER`'s sixth entry `&"glow"`), its pure terrain rules `GlowShape extends MeadowsShape`,
its generator `GlowGenerator extends MeadowsGenerator` (each chunk stack's columns worked out once, behind a mutex, and
filled in runs, as `DragonGenerator` does), its secrets `GlowSecretRules extends SecretRules` (the same five M2 kinds built
the caves' way, so the `SecretDirector` plays them unchanged), its block page `GlowBlocks` (page 45), its monsters in
`MonsterRules.GLOW_KINDS`, and its boss `BossRules.SPORE_MOTHER` as a `StoneGolem` to the `BossDirector` (the Cake
Monster's and the Sky Dragon's way). The caves are a **2.5-D layered cave**: for every column (x, z) three heights from
slow 2-D noises: the **cavern floor** (`height_at`: where every spawner, Tilly, the Totem, secrets, animals and monsters
find their ground), the **ceiling** (the floor plus a clearance of 5-22 blocks: big halls with high domed roofs, wide
passages between them, rock walls where the clearance runs out) and the **roof top** (a meadow of grass over the rock:
the surface, the way in and out). Daylight shafts open the roof to the sky and hold a spiral ramp up their wall (the way
out, every step one block); lakes are where the floor dips under the water line; glow moss, giant glowing mushrooms in
two colours, glow-worm ceilings, gypsum crystal beams, stalactites and stalagmites, flowstone and a waterfall are hash-
and noise-drawn features of the columns, so chunks meet without seams and a chunk costs no more than the Dragon Realm's.

**Rejected: a surface world with the meadows' 3-D noise caves under it** (Green Meadows' `CaveShape`, or 3-D density
noise). Every system that places things asks `height_at` for the ground: Tilly, the Totem and its boss, the stone circle,
animals, night monsters and secrets would all stand on the meadow on top, and the caves under it would be empty
side-rooms that a child might never find; the meadows' cave mood is near-black (`AmbienceRules.CAVE_FOG`); and a 3-D
density sample per voxel in GDScript costs several times the Dragon Realm's generator (the bench rule). Also rejected:
cellular-automaton caves (per-area state, seams between chunks, cost).

**How the caves' science becomes moves the child makes (owner #122, `docs/design/learning-is-play.md` §3).** Each real
fact is the move that wins a small play in the world (the Cave Wonders, one per 128 × 128 area, the first ring round the
spawn holding every kind; the generator builds their rock, a director runs the play for this game's player), and a fact
line comes only after the try (the "see why" step); the Cave Book (the Secret Book's Glow Caves page and the found
wonders) keeps what was found:
- **Bioluminescence (glow-worms):** in a Glow-worm Grotto the ceiling's lights dim while a child is bright or noisy and
  brighten while they are dark and still (crouch, put the light away: the stealth meters), and the brightest threads
  point the way to a hidden chest. The move that wins is being dark and quiet; the line after: glow-worms make cold
  light (almost no heat) to lure insects into sticky threads, and dim when disturbed.
- **How stalactites grow:** at a Drip Stone a drop falls from a stalactite every couple of seconds; a tap as a drop
  lands on the stalagmite under it adds its calcite; every few caught drops the stalagmite grows a block (a counter shows
  the hundreds of years it stands for) until it meets the stalactite: a column the child climbs to a ledge. The move is
  catching drip after drip (slow, drop by drop).
- **Echolocation:** at an Echo Fork three dark tunnels leave a chamber, two end soon; a tap on the bat roost's shell
  sends a click and each tunnel's echo comes back after its own delay (twice the distance over the speed of sound,
  slowed down so a child can hear it, rings drawn too); the latest echo is the long open tunnel. The move is comparing
  echo delays.
- **How caves form:** at a Rain Carver a daylight shaft drips rainwater into a basin; the child scoops rainwater (a weak
  acid) and pours it on walls: limestone fizzes and opens in a few pours, granite never does, and the passage to a
  hidden grotto is behind the limestone. The move is carrying acid rainwater to the right rock.
- **Why cave fish are blind:** at a Blind Fish Lake pale eyeless fish ignore a lamp held over the water but swim to
  ripples (a tap on the water); ripples lead them to the lake's cave pearl, which they nudge ashore. The move is making
  ripples, not light.
- **The Cave of Crystals and the longest cave:** facts at sights (a crystal hall's giant gypsum beams; the explored
  distance on the Cave Book's map page next to Mammoth Cave's mapped length).

The monsters teach it too: **spore puffs** see only light (they show and come when a child's light or a glowing block
is near: the visibility meter), **cave crawlers** are blind and hear only (a crouch-walk passes them: the noise meter).

## Rulings (each with what it costs if wrong)

(Written as they were made; see the sections below.)

1. **Universe 6's portal core is page 10's id 223** (tiles (6, 3), (7, 3), next to the Dragon Realm's 222), not on page
   45: every universe core stays on one page (`CrystalRules.CORES`) and page 45 keeps its 16 ids for the caves' blocks
   (a stalactite and a stalagmite both). Both portal tools draw it; every other tile stayed byte-identical (checked
   tile by tile). Cost if wrong: page 10's two pictures changed; a branch that also changes page 10 must re-run both tools.
2. **Selenite is a `glow` block** (opaque, unshaded), not a cut-out: a beam of many cut-out crystal blocks shows its
   inside faces (messy); unshaded blocks read as luminous crystal in the dark. Cost if wrong: crystals are not
   see-through; a cut-out twin would take another id.
3. **Page 45 keeps alpha** (the dripstone's crossed pictures are cut out), three rows: the realistic pages went from 68.9
   MB (with the music page) to **71.5 MB**, past the 70 MB budget, so the budget is **72 MB**. Growth, measured from the
   imported textures: the APK and each browser's realistic pack (S3TC for computers, ETC2 for phones; the game takes one)
   +2.6 MB (the albedo 2.1 MB, the half-size normal map 0.52 MB); the browser's first download +15 kB (the pixel page).
   `tools/export_web.sh` was not run (the .ctex files are what its packs hold). Cost if wrong: 0.5 MB left; the next
   page needs another raise or a page without alpha.
4. **Stalactites and stalagmites are walked through** (crossed pictures: no collision), like flowers. Cost if wrong: a
   child walks through a stone cone; the solid columns are flowstone blocks.
5. **The realistic twin uses only cached CC0 ambientCG materials** (`~/.cache/easycraft-textures`; the tool stops rather
   than download). Cost if wrong: none (the same licence and source as every other page).
6. **The caves' rock ends in bedrock at y -16** (nothing under it): chunks under it cost nothing, like the Dragon Realm's
   void; the meadows' ore veins fill the stone under the floors (coal, iron, gold down to -16); diamonds come from the
   selenite geodes and the treasure. Cost if wrong: no diamonds deep in the stone; a child digging down meets bedrock at
   -16 instead of -64.
7. **A wall column's `height_at` is the sea level (`NO_GROUND`)**, as the Dragon Realm's void: no dry-land or water
   spawner places anything in rock. A night monster drawn on a wall column stands on the roof's meadow (walls are about a
   tenth of the columns). Cost if wrong: now and then a monster on the meadow over the caves.
8. **The generator bar** ("no slower than the Dragon Realm's"): met on the bench's measure, warm chunks (every chunk of
   the 8 x 10 x 8 region, second round): **0.24 ms** a chunk against the realm's 0.28 (the meadows' 1.40). A fresh stack
   (the first time a world streams a column of chunks) costs about 5 ms against the realm's 1.5: the caves are rock where
   the realm is void (a third of the meadows', which has no stack cache). Cost if wrong: a new area streams in a few
   milliseconds slower on a worker thread.
9. **The caves' ambience**: no loop of its own (the drips loop is 14 dB over the birds, and the loudness rule keeps it as
   it is); under the roof every cavern is deep underground (`WorldService.sky_height` is the roof), so the existing rule
   plays the drips there and the music's underground pieces; the meadow on the roof has the birds and the crickets.
10. **Hits keep the ladder's scale** (× 2^(u-1) = 32 in universe 6, as the spec and the brief say): a level-1 nip is 32
   hearts (16 on Cozy) against a child's 20, so a nip knocks out unless a shield takes it (the Dragon Realm's is already 16).
   The bosses' hits are not scaled (the Spore Mother's spores 1 heart, her ring 2). Not changed here (it is every
   universe's rule); **the lead and the owner should look at it** (a cap on hits past universe 5 would be one line in
   `MonsterRules.hit`).
11. **No NavigationAgent for the sneakers**: the caves' monsters steer like every monster (grid checks on the voxel
   world, the stealth mind); the crawler walks to the noise it heard (the "?" clue). Cost if wrong: none new.
12. **The Spore Mother's slow is each game's own**: the host hurts (1 heart); every game sees where the clouds land and
   linger and slows its own player (`Player.slow_down`), so no new message crosses the network. Cost if wrong: a guest's
   slow follows its own screen's cloud positions (the same, from the host's RPC).
13. **Six universe cards**: a card is narrower when the ladder is longer (`UniverseCard.width_for`: 195 px for six) and
   Monster Wave's best line wraps (one line in `ui/menus/menu.gd`'s wave row; the School button, Play G0's, is not
   touched). Cost if wrong: names trimmed with an ellipsis on a narrow card.
14. **One Cave Wonder per 128 × 128 area, its kind in turn** (`GlowWonders`: `KINDS[(ax + 2 az) mod 5]`, so the nine
   areas round any spot hold every kind), placed before the secrets (`GlowSecretRules._fits` keeps every secret GAP
   blocks off its area's wonder), on open, dry, level floor under its ceiling (each box over open floor, under its own
   columns' ceiling: a stalactite hangs from a high dome while the wonder's edge stands under a lower part). 59 and 57
   of 64 areas hold one for two seeds (every kind 10-13), about 1 ms an area to place (desktop). Cost if wrong: an area
   without room has none.
15. **Nothing grows or hangs on a secret or a wonder**: each chunk stack looks up the footprints round it once
   (`GlowGenerator._kept_clear`) and grows no plant within its reach (a giant's cap: 3 blocks; a beam: cell by cell) and
   hangs no stalactite there. Cost if wrong: a hidden room or a mound has no glowshroom on it (before, a mound cut
   through a cap and left it floating).
16. **A wonder pays REWARD_GOLD × 2^(u−1)** (480 in universe 6) once per wonder and world (`SecretState.found`,
   "wonder:<id>"), as the wonders' quiz pays (Survivor through the host's wallet, the Sandbox into the profile); the
   two sights (the first crystal hall, the long walk) pay nothing: their fact is the find. Never random. Cost if wrong:
   a child who solves every wonder of a world earns 480 gold each (a chest's scale).
17. **A LAN guest plays its own wonders**: its director asks the host's (`_rpc_change`, checked against the wonder's own
   cells: a step, the plug, the door, the pearl) for every change to the world, but the gold is the host's game's only
   (`Session.gold_add` is the host's, as for the Wonders of the World's quiz). Cost if wrong: a guest earns no wonder
   gold.
18. **The plays are slowed and sped for a child, the facts say the real numbers**: a drop every 2.4 s stands for 40
   years of dripping (the counter) and the fact says about a centimetre a hundred years; the echoes are slowed 40 times
   (0.7 s, 1.4 s, 2.6 s for 3, 6 and 11 blocks) and the fact says real echoes take a split second; three pours open the
   limestone and the fact says thousands of years. Cost if wrong: a child keeps the game's numbers, not the fact's.
19. **The rain carver's door is the Great Pyramid's pale LIMESTONE** (it looks unlike the granite round it; the rule
   dissolves it, the caves' cave stone and its fake twin). Only the wonder's own blocks are plays (its tap spots): rain
   poured elsewhere does nothing. Cost if wrong: none (an existing block).
20. **The free peek is a picture, not the live world** (`UniversePeek`: the universe's own UniverseArt with its lights
   twinkling, three lines of what is inside, how it opens): a live look would load and stream a world in the menu
   (memory, seconds, a VR frame budget). PEEK sits on the locked card (the card stays no trip) and on the Star Map's
   card. No price, no timer shown, nothing hurries; it closes by itself after 10 s. Cost if wrong: the peek is a
   painting.
21. **The shader census: one world's run merged** (`tools/census_merge.py`) instead of the 25-minute session: the caves'
   landing saw 23 draws, every kind already in `data/shader_warmup.json` (the wonders' looks reuse
   `GolemModels.glow_material`), so the merge only marks them `glow`. Cost if wrong: the other phases' `shown` marks are
   the old run's (unchanged).
22. **The compass works out one new area a look** (`GlowWonders.known`): a fresh look 220 blocks round could place 25
   areas' wonders in one frame on the main thread. Cost if wrong: in a new place the compass finds the nearest wonder a
   few seconds later.
23. **Looks from the pictures**: the echo mound was a box with three white crystals in a row (a face; pale doorposts
   made it a face with teeth): now a rounded mound, mossy glowing first steps in each tunnel, each tap crystal on the
   ground in front of its mouth; the rain carver's granite cube is a rounded boulder; the roof's bare lawn has flower
   patches (and a few loose flowers; never over a shaft). Cost if wrong: none for play.
24. **The sights**: the first crystal hall stood in (feet within 4 of its floor) and a 400-block walk under the roof in
   one visit (a fall, a climb or a jump of over 12 blocks between two looks counts nothing; a shaft's open sky neither).
   Cost if wrong: a child who explores in short visits meets the longest-cave fact later.
25. **Heard, not read (owner #133/#134, Play G0's `PlayVoice`; after merging lead-merge 1c524bfb, 2026-10-18):** with
   the play's voice on (`PlayVoice.on`: the device has a voice and "Read to me" is on), the caves' hooks, the cheer and
   fact after a win, the sights' facts and the gentle hints are spoken (`PlayVoice.say`, through the director's
   `voice_on` / `speak`), and the screen keeps a few words: the wonder's name for its hook, the cheer for a win, the
   sight's name, two-word hints ("Splash!", "Listen again!", "Scoop first!", "No fizz.", "Ripples!"); the drip's count
   stays on the screen as a number ("400 years") and is never spoken at every drop. Without the voice the words show in
   full, as before. The peek speaks its lines when it opens. The Cave Book keeps its written page (the Secret Book's
   read-aloud button says it). Cost if wrong: a child without a device voice reads the full lines (as Play G0 rules).
26. **A closed door keeps every monster out, in a crowd too (2026-10-18; the lead found it):** the lead's crowd of the
   game's cap (`MonsterRules.MAX_TOTAL`, 20) at one single closed door got the level-5 spore puff to x 8.44 (the old
   all-kinds crowd failed at 8.1 in the full suite, first misread here as a timing failure). **Root cause (traced
   frame by frame): two gaps in the shared door check, `DefenseRules.door_in_way`, not the spore puff.** (1) A monster
   pressed against the wall beside a doorway looks along the wall a block and more to each side (`Monster._door_at_wall`,
   radius r + 1.0), but only three lines were sampled (the middle and the two edges): with the body centred at z −0.18
   they read the cells at z −1, 1 and −2 and skipped the door at z 0 right beside it, so its step-hop went up beside
   the door; (2) coming down it caught a sliver of the door's top and stood there, and both checks look at the feet's
   level only (now y 11: no door), so the next step-hop lifted it over the 2-high wall. **The spore puff was the first,
   not the only one:** 32 crowds of 20 with other ids (clean colliders each) let crawlers (levels 1 and 5), level-5
   yetis and level-5 spore puffs over in many of them, with or without the puffs (deepest 8.44 and 8.82). **Fix:**
   `door_in_way` reads every cell under the body's square (`body`, its own half-width) and every cell between its two
   sides ahead (lanes at most `_LANE` 0.5 apart), at the feet's level and the one under them; `_door_at_wall` passes
   the body's half-width and is worked out once a decision like `_door_ahead` (it is asked every tick while a monster
   presses a wall). After it the same 32 crowds stop at 4.82 (nobody onto the door). Tests: the lead's two
   (`test_no_monster_climbs_or_hops_over_a_single_closed_door` per kind, `test_a_crowd_at_the_games_cap_does_not_get_over_a_single_closed_door`),
   `test_crowds_with_other_random_choices_never_get_over_a_single_closed_door` (six crowds that got over before),
   `test_defense_rules`' `test_a_door_between_the_middle_and_the_side_counts` and `test_a_door_under_the_edge_of_the_feet_counts`.
   `test_no_monster_passes_a_closed_doorway_of_two_doors` now measures inside the house's span (z −4 to 5): with the
   new paths a gummy hopped along the house's outside south wall to x 5.10 (traced: z −4.24, no entry). Cost if wrong:
   near a door a monster never step-hops (a step right beside a door is climbed only from elsewhere).

## The Cave Wonders (owner #122): what a child sees and does, the fact, its source, the move that teaches it

Near a wonder (9 blocks) the world says its problem first (the hook), never its answer; the wonder's tap spots are
invisible boxes a little bigger than its blocks (`WonderThing`, the secret things' layer: a tap, a click or a VR hand's
ray reaches them before the block). A win says the world's cheer and the fact under it, pays fixed gold, opens the Cave
Book's page (the Secret Book's last page: name and "???" until found, then a one-line fact; account-wide in
`WonderData.caves`). The compass points to the nearest wonder not solved.

| Wonder | The hook (the problem) | The move that wins | The fact after the try | Source |
|---|---|---|---|---|
| Glow-worm Grotto | "Shh... the glow-worms are shy. Can you make them shine?" | stand in the dark round grotto still or crouch-walking, no lamp in hand, none near: the worms (72 lights under the plain rock ceiling) brighten over about 3 s; held bright for 1.5 s, their threads light the way to the nearest buried chest (the compass too). Walking about or a lamp dims them | Glow-worms make cold light (almost no heat) to lure insects into sticky threads, and dim when disturbed | New Zealand Department of Conservation, "Glow-worms" (Arachnocampa luminosa, Waitomo); NOAA Ocean Exploration, "What is bioluminescence?" (cold light) |
| Drip Stone | "Drip... drip... Tap the stone as each drop lands. Can you grow steps to the pearls?" | tap the flowstone stump as each drop lands (within 0.35 s); every 3 caught drops a flowstone step grows (3-5 steps) towards a pillar with cave pearls; a counter shows the years the drops stand for | Each drop leaves a thin ring of calcite; real stalactites grow about a centimetre in a hundred years | US National Park Service, Carlsbad Caverns and Mammoth Cave, "Cave formations" (soda straws grow ring by ring; about an inch a century or less); USGS, "Karst and caves" |
| Echo Fork | "Three dark tunnels. Only one goes all the way. Tap the bat roost and listen!" | tap the roost: a click, then each tunnel's echo returns after twice its length over the speed of sound (slowed 40 times) with a glint on its crystal; tap the crystal of the latest echo: the long tunnel's plug opens to a pocket of pearls under glow-worms | Bats click and listen: the later the echo, the farther the wall; real echoes take a split second | US National Park Service, "Bats: echolocation"; the speed of sound in air, 343 m/s at 20 °C (NIST, NOAA) |
| Rain Carver | "Rain seeps into this cave. Scoop some rainwater and find a way through the wall!" | tap the basin to scoop rainwater, tap the boulder to pour: the pale limestone door fizzes and dissolves after three pours (a pocket of pearls behind it); poured on granite it runs off, no fizz | Rainwater is a weak acid: over thousands of years it dissolves limestone and carves caves, not granite | USGS, "Karst" and "How do caves form?" (carbonic acid from the air's CO2 in rain dissolves limestone); US National Park Service, "Cave and karst systems" |
| Blind Fish Lake | "Pale fish guard a pearl in the dark water. How do you call fish that have no eyes?" | the lamp stone's light: the pale eyeless fish don't turn; taps on the ripple stone: ripples spread, the fish swim to them, and after three ripples they nudge the lake's pearl ashore | Cave fish live in total darkness, so eyes don't help; they feel the water move along their sides | National Geographic and the Smithsonian on the Mexican tetra cavefish (Astyanax mexicanus); US National Park Service, Mammoth Cave, "Kentucky cave fish" (the lateral line) |
| Crystal Hall (sight) | — | stand in a crystal hall among the selenite beams | Mexico's Cave of Crystals holds gypsum crystals up to 12 metres long, grown in warm water | National Geographic, "Giant Crystal Cave" (Naica, Mexico) |
| The Longest Cave (sight) | — | walk 400 blocks under the roof in one visit | Mammoth Cave is the longest cave known: more than 680 km of mapped passages | US National Park Service, Mammoth Cave National Park (more than 426 miles mapped) |

The monsters teach the same science by play: spore puffs see only light (they show and come when the child's light or
a glowing block is near: the visibility meter), cave crawlers are blind and hear only (a crouch-walk passes them: the
noise meter).

## What a child sees and does in the Glow Caves

A world of universe 6 starts in the home hall: a high blue-violet cavern lit by its own glow (moss carpets, giant pink and
blue glowshrooms, glow-worm ceilings), never black. Wide passages lead to other halls, crystal halls with slanting
selenite beams, underground lakes, stalactites and stalagmites; daylight shafts open to the sky with a spiral ramp up to
the meadow on the roof (flowers there; the way in and out). Spore puffs hide in the dark and come to light; blind cave
crawlers come to noise (crouch past them); both burst into coins and confetti, a golden puff into a pile of gold. Mira
the cave guide gives two quest stories. Secrets: pearl-X buried treasure, hidden rooms behind fake cave stone with riddle
notes, the flowstone puzzle temple, hidden grottos (the island kind's place), selenite geodes with cave gold and
diamonds, the treasure pack's places in the caves' blocks. A Cave Wonder in nearly every area (above), the compass to
the next. The Totem's boss is the Spore Mother: a smiling mushroom whose spores land on rings shown first, whose ring
rolls along the ground (a jump clears it), whose puff hides and moves her; her gills open after each attack (double
damage). Beating her opens the rainbow portal to the hub. While the caves are locked, PEEK on the hub's card and the
Star Map's card shows a moving picture of them for a few seconds.

## Bench, smoke, pictures, VR

- **Generator** (`godot --headless --path . --script res://tools/bench_generator.gd -- --glow`, 2026-10-17, a busy PC):
  warm chunks 0.27 ms against the Dragon Realm's 0.33 (the meadows' 1.57); a fresh stack 0.60 ms against 0.16; the
  secrets' and wonders' areas 2.65 ms an area against 0.74 (once per area, on a worker thread; the main thread's
  compass one area a look).
- **Smoke** (`XDG_DATA_HOME=/tmp/easycraft-glow-smoke godot --headless --path . --script res://tools/glow_smoke.gd`):
  **0 fails** (the home hall's floor and ceiling, the roof as the open sky's ground, the cave mood, the caves' secrets
  and wonders, a giant glowshroom, the Rain Carver solved through the real taps: its limestone door dissolved in the
  world, 480 gold once, the Cave Book's page; the Drip Stone's rock; the flat arena). Cost windows back at the spawn
  once the land has streamed in: process 2.29 ms, physics 2.40 (the wonders' director 0.14 of it; the Dragon Realm's
  smoke: 4.40 and 2.76). Right after a 200-block teleport the new caves streaming in cost 23 ms a frame headless: the
  emulator's 2 km flight must check it.
- **Pictures** (a real window, under nice, both styles: `XDG_DATA_HOME=/tmp/easycraft-look-shots godot --path .
  --disable-vsync --resolution 1600x720 --script res://tools/look_shots.gd -- --universe=6`; views `hall`, `grove`,
  `crystal`, `lake`, `shaft`, `grotto`, `wonder_drip`, `wonder_echo`, `wonder_rain`, `wonder_lake`, `monsters`,
  `spore_mother`, `roof`): this run's are in the agent's scratchpad,
  `/tmp/claude-1000/-home-giorgi-Documents-game/39eee3cb-6bee-43a3-b86d-48d101218846/scratchpad/glow-shots/look_shots/`
  (`glow1` every view before the look fixes, `glow3`-`glow7` after; the sheets `glow_sheet1.jpg`-`glow_sheet7.jpg` in
  the scratchpad). Seen: calm blue-violet halls, glowing mushrooms, crystal beams, the shaft's spiral ramp, the grotto's
  worm lights, the cute smiling Spore Mother, small dark puffs and beetle-like crawlers; fixed: the echo mound's "face",
  the rain carver's cube, the bare roof (rule 23). The grotto's first blocky look had one 837 ms frame: the look tool
  starts a world without the menu's shader warm-up (the worms' material is in the census, shown at the caves'
  landing), so a first compile; the emulator should confirm no long frame there.
- **VR** (`tools/vr_bench.gd -- --world=6 --seconds=20 --turns=4`, the Quest platform's settings through the preview):
  103 draws a frame on average, 145 at most (3D 73 / 117, 2D 28 / 30), 68K triangles (104K at most), no frame over
  28 ms; the Dragon Realm's same run: 96 / 110, 55K / 75K. Inside "≤ 150 at the heaviest landings", 3 over the 100
  average (the 2D's 6 more: the compass to the nearest wonder).

- **The full suite** (once, 2026-10-18, on the branch merged with lead-merge 1c524bfb, `tests/run_tests.sh`, 84 min):
  12,033 tests, **12,025 passing, 5 failing**, 3 risky/pending. Four were tests that still said the old facts, now
  updated: `test_block_id_space` (the next page is 46 from id 784), `test_rewind_log` (its "id no block owns" was 223,
  now the Glow Portal Core: 239 instead), `test_secret_book_pages` (two: six pages with the Cave Book); on their own they
  pass. The fifth, `test_monster_defenses`' "no monster climbs or hops over a single closed door" (8.1 against ≤ 5),
  passed twice on its own and was first misread here as a timing failure; **the lead found it real** (a crowd at the
  game's cap gets one over, every time): fixed at its root in the shared door check (rule 26). Earlier,
  test_loading_hints' Mercury pictures failed in a 117-file batch and passed alone; in the full suite it passed.
- **The full suite after the door fix** (once, 2026-10-18, on the branch merged with lead-merge e729c3e2, 80 min):
  12,037 tests, **12,034 passing, 0 failing**, 3 risky/pending.
- **The smoke run on the merged tree:** 0 fails.

## What the lead must check on the emulator and the Quest 3

- **Emulator** (`Pixel_8_API_35`): a new Survivor world of universe 6 in both styles: the autopilot's 60 s play phase and
  its 2 km flight (≥ 30 FPS, no frame over 100 ms; new caves streaming after the flight's moves, rule 8's cold stack);
  the grotto's first sight after the menu's warm-up (no long frame); a wonder solved by touch (the drip's timing on a
  phone, the rain's scoop and pour, the echo's three crystals); PEEK on the hub's locked card (with five universes
  unlocked) and on the Star Map; the Cave Book's page; the hits' scale (rule 10).
- **Quest 3**: the caves' landing's draws in the headset's logcat (`VR_BENCH`, ≤ 150; the average was 103 here); the
  wonders' tap spots with the hand's ray (they sit a little in front of their blocks); the hooks and facts readable in
  the VR HUD; the peek over the VR panel (it opens in the panel's own viewport); the grotto's stillness rule with a
  headset (head movement is no noise; walking with the stick is).
