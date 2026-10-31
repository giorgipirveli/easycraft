# M3 Task 4: the Candy Kingdom, universe 4

Spec §14.1 ("Candy Kingdom"), §5.1, §5.2 (the sneaker behaviour), §5.3, §5.9 (the cosmic outfit), §12.16 (secrets,
adapted), §6 (fair fun); plan Task 4. Built in an isolated worktree cut from `m2-survive-the-night` (`13b77f4`),
without the editor or the emulator; after the 20:08 pause the branch was merged with `m2-survive-the-night`
(`5a9771a`: M3 Tasks 7 and 12) before the work went on, and at the end with `500b45e` (Frostpeak, M3 Task 3, the
owner's bug fixes, release 0.3.1; see "Merge notes" below). A sibling of the Sandstorm Desert (M3 Task 2): the same
descriptor interface, the same kind of shape, generator, secret rules, monster and boss hooks.

## What was built

### 1. Block atlas page 8: the kingdom's blocks (ids 176-191, both styles)

| id | block | notes |
|---|---|---|
| 176 | FROSTING | the ground's pink icing (top), dripping over cake on its sides |
| 177 | CAKE | sponge with air holes |
| 178 | CHOCOLATE | a chocolate bar: river beds and banks, a layer under the cake |
| 179 | CANDY_CANE | red and white stripes, a spiral on its ends: candy canes and lollipop sticks (the kingdom's logs) |
| 180 | LOLLIPOP | a swirl: a lollipop tree's top (its leaves; opaque) |
| 181, 182 | GUMDROP ("Green Gumdrop"), RED_GUMDROP | sugar-coated jelly: gumdrop hills; **bouncy to land on** |
| 183, 184 | CREAM, JAM | a cake mountain's layers |
| 185 | SUGAR_GLASS | cutout, transparency index 5 |
| 186 | GINGERBREAD | icing zigzags and buttons: gingerbread houses |
| 187 | CANDY_LAMP | glows |
| 188 | COTTON_CANDY | cutout, walk-through (a pink bush) |
| 189 | SPRINKLES | frosting with rainbow sprinkles: cake tops, the treasure's X |
| 190 | GOLDEN_CANDY | glows; only in secrets (the gingerbread house's tip, the floating cake's side) |
| 191 | FAKE_CHOCOLATE (named "Chocolate") | the kingdom's fake wall: a tap knocks it open |

- `world/universes/candy_blocks.gd` (`CandyBlocks`), registered by `BlockLibrary._static_init` like the desert's.
- Pixel page `data/blocks/pages/candy.png` by `tools/make_candy_atlas.gd` (own RNG seed 20260925, original work).
  Realistic twin `candy_albedo.png` / `candy_normal.png` by `tools/make_candy_realistic.py` (the helpers of
  `make_realistic_atlas.py`) from CC0 ambientCG Snow004, Snow005, Snow003, Plastic013A, Ground103, Ground079L,
  Metal034 (credited in `assets/CREDITS.md`).
- `BlockIds.CANDY_GROUND` (frosting, cake, chocolate, both gumdrops, cream, jam, sprinkles), like the lead's
  `DESERT_GROUND`: `BotRules.GROUND`/`NATURAL` (+ candy cane, lollipop, cotton candy), `SurpriseRules.METEOR_REPLACES`
  (+ cotton candy), `ToolPowers.GROUND` (frosting, cake, sprinkles) and `LEAVES_OF` (candy cane → lollipop: the axe
  fells a lollipop tree), `CaptureRules.GROUND` (+ fake chocolate: the wand never wakes the kingdom's ground).
- COTTON_CANDY is in `NON_SOLID`; FAKE_CHOCOLATE drops chocolate; `/give` never hands out golden candy or fake
  chocolate (`ChatCommands.NEVER_GIVEN`); none is in the Sandbox palette (like the desert: universe 1 only).

### 2. The terrain (`world/generators/candy_shape.gd`, `candy_generator.gd`)

`CandyShape extends MeadowsShape` (every system typed `MeadowsShape` takes it); `column(x, z)` gives (height,
kind, floor) in one call; every rule is a function of (x, z) and the seed:
- **frosting plains** at 34 ± 5 (one octave); layers: frosting, cake 4 deep, chocolate to 10 deep, then stone;
- **chocolate rivers**: a river noise (2 octaves, 0.0022) carves winding channels 1-4 blocks deep under the sea
  level (the same water as everywhere: chocolate here, below), chocolate banks beside them (`BANK`), the plains
  sloping down to them; nothing else goes below the water line (tested: no accidental lakes);
- **gumdrop hills**: at most one per 64-block cell (52 %), a dome of radius 7-13 rising 0.8 × its radius, all
  jelly, green or red (by its centre);
- **cake mountains**: at most one per 224-block cell (48 %), three round tiers (radius 22-32, then 64 % and 33 %
  of it) each 12 high, gently wavy edges; the sides striped sponge / jam / sponge / cream / sponge per tier,
  cream icing on a lower tier's top, sprinkles on the top one; a cake's floor is flat (the plains at its middle);
- **plants** (on the plains only): candy-cane forests (a forest noise; canes 1.8 %, lollipop trees 1.3 % inside,
  0.2 % / 0.3 % outside), cotton candy bushes 0.6 %. A candy cane is a pole 4-7 high with a hook bending over; a
  lollipop tree a striped stick with a round lollipop 5 across on top, facing one way. They count as trees
  (secrets and spawns keep off);
- the spawn: open, gentle plains near the origin.

`CandyGenerator extends MeadowsGenerator` works each column out once per chunk and fills its layers in runs;
**a chunk's gumdrop hills and cakes are looked up once** (`features_in` + `column_among`: the per-column cell
hashes cost more than the noise in GDScript, found by profiling). Caves, ores and crystals are Green Meadows'.

### 3. Secrets (§12.16 adapted): five kinds (`world/generators/candy_secret_rules.gd`)

The same kinds, ids and dictionaries as Green Meadows' (the SecretDirector plays them unchanged):
- **buried treasure** (TREASURE): an X of sprinkles on the frosting, the chest 2-4 blocks under it;
- **a hidden room in a cake** (ROOM): a cream room with candy lamps inside a cake mountain's bottom tier, level
  with the frosting outside; a 1 × 2 tunnel to a **fake chocolate** door in the cake's side (a dark door in the
  striped sponge: a fair clue); `SecretRules.is_fake_wall` knows it;
- **a gingerbread house** (TEMPLE, the puzzle temple): 11 × 11 gingerbread walls with sugar-glass windows, a
  chocolate floor, a stepped roof of cream and sprinkles with gumdrops at its corners and a golden candy on top;
  inside the three pressure plates, the note and the golden door to the vault;
- **a floating cake** (ISLAND): a round layer cake in the sky (sprinkles, cream, sponge, jam, chocolate) with
  golden candy in its side and the golden chest on top;
- **a rock-candy geode** (GEODE): Green Meadows' crystal geode.

### 4. Monsters: the gummy bear and the candy sneaker

`MonsterRules` (kinds `GUMMY`, `SNEAKER`, `CANDY_KINDS`, behaviour `SNEAKS`; section "M3 Task 4": `hop_up`,
`wall_bounce`, `sneaker_dark`, `sneaker_look`) and `Monster` (section "M3 Task 4" plus one-line hooks):

| | HP (l = 1…5) | Hit | Gold | Speed | Attack |
|---|---|---|---|---|---|
| Gummy bear (jumper) | 5 + 3(l−1) | 1 + l/2 (a nip) | 2l | 3.2 + 0.2(l−1) | hops at 8 m/s up (a slime 6.5), nips on landing |
| Candy sneaker (sneaker) | 6 + 3(l−1) | 2 + (l−1) | 4l | 3.0 + 0.2(l−1) | a lollipop, wound up 1.0 s (a goblin 0.8) |

- **The bounce** (a pure rule, `MonsterRules.wall_bounce`): a gummy bear flying into a wall comes back off it —
  its speed into the wall turns round (0.8 of it), the part along the wall stays, a hop up of at least 2.5 m/s,
  never faster than 8; floors, slopes and walls it moves away from change nothing. `Monster._physics_process`
  keeps the velocity from before `move_and_slide` and hands it to `_bounce_off_walls`.
- **The sneaker**: the host measures the light where it stands once a second, at its looks (`light_at`: the
  sandbox's `_sneaker_light`, `StealthDirector.light_at` (now its own function) with the lanterns from the
  DefenseDirector's lantern index, so no box is copied per look: DEVELOPMENT.md §8); below 0.5 it is `dark` (synced
  on change: night outdoors 0.45, caves 0.3, a lantern 1.0). Every screen then hides its body and shows only a **shimmer** (its glowing eyes and
  sparkles, one shared mesh per level) within **6 blocks** of that screen's player — and always while it winds
  up, with a **jingle** (`sneaker_jingle.wav`) as every wind-up starts: a shimmer and a sound before every attack.
- Night spawns and Totem waves take the kingdom's kinds (gummy bears three in five); `/summon gummy 3`,
  `/summon sneaker`; the monster minds' hints name them.
- Looks: a gummy bear in its level colour (jelly, a lighter belly and top, round ears, a snout; the level in sugar
  crystals on its head); a sneaker is a wrapped licorice sweet on thin legs, its wrapper twisted out at its sides,
  a sash of its level colour, pink eyes, a lollipop.

### 5. The boss: the Cake Monster (`core/rules/cake_rules.gd`, `entities/monsters/cake_monster.gd`)

A `StoneGolem` subclass (like the Sand Serpent: the BossDirector's fight, bar, honest help, gold and loss work
unchanged), a walking three-tier cake with a face, cream arms and a cherry. Every attack is signalled:

| Tiers | Wind-up | Attack |
|---|---|---|
| 3 | arms up, it squishes down (1.3 s) | a **frosting wave** along the ground: 4 HP within 6.5, a jump clears it |
| 2 | the cherry on top glows and grows (1.1 s) | three **cherries**: at the child and 2.5 to each side, 3 HP each (step between them) |
| 1 | it leans back and whirrs (1.2 s) | it **spins** straight at the child 12 blocks at 9 m/s: 5 HP on its path, stops at a wall |

- After every attack it is **dizzy** 2.2 s (stars; double damage). A walk (2 s) comes between.
- **Layers fall off** at two thirds and a third of its health (`CakeRules.layers_left`): a 1.5 s pause
  (`LAYER_DROP`: no hits, no attacks), a pop, and a line on every screen that says what comes next ("A layer fell
  off! Now it throws cherries: keep moving!"). **A hit never takes two tiers** (`after_hit` stops at the line), so
  every attack gets its turn. Every screen shows the fallen tier tumble off and burst into crumbs, from the synced
  health alone; the collision box shrinks with it.
- Health 420 × (1 + 0.5 per extra player or bot friend), a tired one 75 % (the Golem's rules); it stays near its
  spot; it never changes a block (tested with a world that counts edits, and a source scan).
- `BossRules.CAKE`, `words(CAKE)`, `max_hp_of(CAKE)`; the bar draws its face; `/summon cake` in Sandbox.

### 6. The last universe: a rainbow portal to the hub, a grand celebration, the cosmic outfit

- `UniverseRules.HUB` (0) and `boss_portal_target(u, ladder_size)`: the boss portal of the ladder's last universe
  leads to the hub. `DesertPortal` takes target 0 ("Walk in: every universe you opened!", the swirl), walking in
  emits `entered(HUB)` and `UniverseHub.portal_entered` opens the hub panel (nothing travels by itself).
- The win: sponge and pink bits, a pop, "Every universe is yours! A rainbow portal opened by the Totem!" and three
  rounds of fireworks with a fanfare over the Totem on every screen (`BossDirector._grand_celebration`), plus the
  usual dance (`Session.celebrate_all`).
- **Cosmic outfit**: in Survivor, `BossDirector._earn_boss_items` → `Session.boss_earn(EARN_CAKE_MONSTER)` (new
  section "M3 Task 4" at the end of `session.gd`): every player's game adds it to its own profile
  (`AvatarUnlocks.earn`, never twice), says "You got a new look: Cosmic! Try it on in the avatar editor.", a guest
  saves at once. Never in Sandbox (§5.9).
- The profile still records universe 5 as unlocked (`Session.boss_unlock(next)`, unchanged), so a future Glow Caves
  update opens for a child who already beat the Cake Monster; the hub lists only the ladder's four.

### 7. The kingdom's world: chocolate water, bouncy gumdrops, sprinkles at night, music

- **Chocolate rivers are WATER** (ruling 1): `BlockLibrary.set_liquid(&"chocolate")` sets one uniform on the one
  shared water material (`shaders/water.gdshader`: `chocolate`, `chocolate_color`; both styles), every world sets
  it (so the next world's water is water again); `Ambience.chocolate` turns the underwater view brown
  (`CandyRules.chocolate_mood`). They flow and swim exactly like water (M2 Task 14).
- **Gumdrops bounce** (`CandyRules.gumdrop_bounce`): landing on one from a fall faster than 5 m/s throws the player
  back up with 0.75 of the landing speed (at most a jump pad's 16); walking over them never bounces; each bounce is
  lower, so it settles. One hook in `Player._lab_move_and_slide` (the fall speed before the move).
- **Sprinkles** (`world/candy_sprinkles.gd`, `CandySprinkles`, node `Sprinkles`, every screen for its own player):
  one `CPUParticles3D` of 140 tiny sticks with the shared Fx material and a stepped colour ramp, in world space
  over a 28 × 28 box 9 blocks above the player, at night under the open sky (`CandyRules.sprinkles_on`), looked at
  four times a second.
- **Music**: an original music-box waltz, "Candy Waltz" (day, 138 bpm, 41.7 s, 250 KB) and its lullaby "Sugar
  Lullaby" (night, 92 bpm, 31.3 s, 125 KB), composed and synthesised note by note by `tools/make_candy_music.py`
  (celesta-like bells, a plucked bass, oom-pah-pah chords; the loop's tail wraps onto its start: no seam). The
  descriptor's `classical` names the Nutcracker pieces that fit for the audio pass (below).
- Sounds (`tools/make_candy_sounds.py`, original): gummy squeak, sneaker jingle, cake roar, slam, throw, cherry
  splat, layer pop, fanfare (`Audio` keys `gummy`, `jingle`, `cake_roar`, `cake_slam`, `cake_throw`,
  `cherry_splat`, `layer_pop`, `fanfare`). `GolemRock.crash` lets a cherry splat instead of a rock's crash.

### 8. The descriptor and the glue

`world/universes/candy.gd`: `name` `&"candy"`, `display_name` "Candy Kingdom", `index` 4, `generator_shape`,
`generator`, `monster_kinds` (gummy, sneaker), `boss_kind` `&"cake"`, `music` {day, night} (the boss keeps Green
Meadows' loop), `classical` {day: Waltz of the Flowers, night: Dance of the Sugar Plum Fairy, boss: Russian Dance
(Trepak)}, `sky` (a candy-pink top over a strawberry-milk horizon), `trader_stock` (14 candy blocks at 1-5 Meadows
gold, × 8 in universe 4; Tilly buys none back), `weather` `&"sprinkles"`, `liquid` `&"chocolate"`, `secret_words`,
`secret_rules`. The M3 Task 2 glue in `scenes/sandbox.gd` already hands the directors the kinds, the boss and the
secrets; new lines: the host's `_monsters.light_at` (in `_start_universe_host`), `_candy_local()` (end of
`_universe_hud`), `_apply_liquid()` (end of `_apply_universe_look`), and the section "M3 Task 4".
`--universe=4` is M3 Task 5's argument (tested).

## Tests (RED → GREEN)

Suite (`tests/run_tests.sh`, exit 0 before every commit, run on a snapshot of the staged index): **3087 of 3087** at
the start (after merging `m2-survive-the-night` with M3 Tasks 7 and 12) → **3127** (blocks, terrain, secrets:
`a454ae0`) → **3190** (monsters, the Cake Monster, the kingdom's world, the descriptor) → **3338 of 3338** after merging
`500b45e` (Frostpeak and the rest of release 0.3.1; the merge commit `0c1a82b`).

| Test file | Tests | RED (why it failed first) |
|---|---|---|
| `tests/unit/test_candy_blocks.gd` | 14 | written before `CandyBlocks` and the ids; first run with them in place: its own sample point missed the sugar glass's clear middle (it now also looks at the frame) |
| `tests/unit/test_candy_shape.gd` | 12 | written before `CandyShape`; first run with it: its plains-layer check was one block off (the test's); the fast-path test was added with `features_in`/`column_among` |
| `tests/unit/test_candy_generator.gd` | 7 | written before `CandyGenerator`; green at its first run (the reference and seam tests are the desert's) |
| `tests/unit/test_candy_secrets.gd` | 8 | written before `CandySecretRules`; green at its first run |
| `tests/unit/test_candy_monster_rules.gd` | 7 | `MonsterRules.GUMMY`, `SNEAKER`, `CANDY_KINDS`, `wall_bounce`, `sneaker_look` … not found; then the test's own slanted-wall expectation (the physics was right) |
| `tests/unit/test_cake_rules.gd` | 9 | `BossRules.CAKE` not found (CakeRules was written with it) |
| `tests/unit/test_candy_rules.gd` | 4 | `CandyRules` not declared; then an exact colour compare after a lerp (now approximate) |
| `tests/unit/test_candy_universe.gd` | 8 | the descriptor file missing (null) |
| `tests/integration/test_candy_monsters.gd` | 10 | written with the entity code; mutation-checked: without `_bounce_off_walls` the gummy bear slides down the wall (vx 0.00), without `_measure_dark` the sneaker is never dark. The full suite then caught a race (the engine's own `_process` ran the looks between the test's steps): the test now steps the looks by hand only |
| `tests/integration/test_cake_monster.gd` | 10 | `CakeMonster` not declared; then the physics tests lacked a floor (the cake fell away from its wave) |
| `tests/integration/test_candy_boss.gd` | 7 | `UniverseRules.HUB`, `HUB_WORDS`, `CakeRules.GRAND_WIN` not found |
| `tests/integration/test_candy_world.gd` | 7 | `CandySprinkles` not declared; the bounce test first dropped the player through `spawn_at` (which puts it on the ground: a 1-block fall, no bounce); mutation-checked: without the player's hook, no bounce |

Changed M2/M3 tests (the new kinds broke their assumptions): `test_monster.gd` (a sneaker's shimmer is a third mesh:
left out of the "one or two meshes" count), `test_monster_defenses.gd` (twelve monsters in one row stood out of
sight: now two columns of eight), and the two sneaker hints were shortened to the 60-character limit
(`test_monster_mind.gd`).

## Generator cost (the brief: ≤ Green Meadows' per chunk)

`godot --headless --path . --script res://tools/bench_generator.gd -- --candy`: the same 640 chunks (8 × 8 columns
of chunks, y −64…95) with both generators alternating chunk by chunk, the second round timed (secret areas cached).
The first version was 29 % dearer on the surface (5.62 ms against 4.35): the per-column cell hashes of the hills
and cakes cost more than the noise in GDScript (a column 5.2 µs against Meadows' 3.2). With a chunk's hills and
cakes looked up once (`features_in` + `column_among`, tested equal to `column`), at load ~44:

| chunks | Meadows avg ms | Candy avg ms |
|---|---|---|
| surface (y 0…79) | 3.81 | 3.66 |
| underground | 2.41 | 2.30 |
| sky (y ≥ 80) | 1.68 | 0.75 |
| all | 3.04 | 2.82 |

A kingdom area's secrets take 1.51 ms on average to place (worst 10.6 ms, once per area on a generator thread,
then cached; the desert's 0.30: the cake rooms probe up to nine spots along a cake).

## Smoke run on real terrain

`XDG_DATA_HOME=<private "smoke" dir> godot --headless --path . --script res://tools/candy_smoke.gd` (seed
1622835203, load ~55): **all 48 checks passed** — a kingdom world (universe 4) standing on frosting, the kingdom's
directors, chocolate water and the chocolate view; 4 night monsters (gummy bears and a sneaker, universe 4) after
1.4 s and the sprinkles falling; a summoned gummy bear hopped over and nipped the player (20 → 16: Cozy halves 8); a
sneaker dark at night (light 0.45), only its shimmer showing 2.9 blocks away, a jingle, then its lollipop (16 → 8);
no sprinkles by day; swimming in a chocolate river (state 2); standing on a gumdrop hill and bouncing 2.39 blocks
after a 4-block drop; the Cake Monster rose and went RISE, WALK, WAVE_WARN, DIZZY with its bar and face, lost a
layer and said so, was beaten: its portal leads to the hub, "You beat the Cake Monster!", the grand celebration, the
cosmic outfit earned; the nearest gingerbread house's golden candy and plates, found by walking in.
Cost window (20 candy monsters, headless desktop at load ~55: only a hint): physics 20.0 ms average (22.3 quiet),
process 20.7 (43.7 quiet, while the world still streamed after the teleports).

**After the Frostpeak merge** (`0c1a82b`, seed 2477243150, load 26-38 from the other agents): **0 fails**, 47 checks
(one fewer "night monster" line: that night's first spawn was 3 monsters, sneakers only), the river swim at the
spawn's own river, the same boss, portal, outfit and house checks. Cost window: physics 11.8 ms average (worst
45.9), process 13.1 (one 108.7 ms frame while 20 monsters spawned and chunks streamed on a loaded desktop: only a
hint; the emulator's autopilot is the measure).

The first run (seed 1448447432) failed 11 checks, all of the run's own making: the far teleport to the gumdrop hill
landed before the collision there was built (the player fell through, the desert's lesson), and the Cake Monster
then rose next to a player who was down (the fight is lost at once when every player is knocked out). The run now
teleports again until the player stands on the hill, and heals the player before the boss.

## Rulings (decided on the owner's behalf; cost if wrong)

1. **Chocolate rivers are WATER blocks shown as chocolate in this universe** (the brief's choice "a CHOCOLATE
   liquid block that flows and swims like WATER, or WATER tinted by biome: decide by cost"). A new liquid would
   touch ~30 checks of `BlockIds.WATER` in shared files (swimming, flowing, spawns, monsters, bots, stealth, the
   view, gathering, the shop); the tint is one shader uniform. *Cost if wrong:* every water in a candy world is
   chocolate (flooded caves, a bucket a child pours); a real block later means those 30 checks.
2. **Gumdrops are bouncy to land on, not to walk on**: a fall faster than 5 m/s bounces back 0.75 of it. *Cost if
   wrong:* one constant (`BOUNCE_FROM`); hills that bounce on every step would be tiring.
3. **The sneaker's ? and ! marks and its health bar still show in the dark** (fairness first; the danger arrows too).
   *Cost if wrong:* one line hides the marks while it is hidden.
4. **"Dark" is the stealth light below 0.5** (night outdoors, caves; a lantern or daylight shows it), measured once
   a second with the lantern index (light blocks are not in that index: a sneaker by a light block still counts as
   dark). *Cost if wrong:* one constant (`SNEAK_DARK`); light blocks would need the index to hold them too.
5. **The Cake Monster's attacks follow its tiers** (wave, cherries, spin) and **a hit never takes two tiers**; 420
   base health (the ladder's biggest), the Golem's hit sizes (4, 3, 5). *Cost if wrong:* constants in CakeRules.
6. **Universe 4's boss opens a portal to the hub** (every universe the child opened) with a grand celebration; the
   profile still records universe 5 for a future update. *Cost if wrong:* `boss_portal_target` and one line.
7. **The cosmic outfit is earned by every player in the fight's world, Survivor only** (like the next universe).
   Every boss still also gives the Rock Helmet (M3 Task 9's hook in `boss_apply_unlock`, unchanged).
8. **Candy blocks stay out of the Sandbox palette** (the desert's ruling 1); Tilly sells 14 of them in the kingdom
   and buys none back.
9. **The natural ground** (the wand, bots, meteors, the axe) is frosting, cake, chocolate, gumdrops, cream, jam
   and sprinkles: a gumdrop or chocolate statue cannot come alive with the wand. Candy canes, lollipops,
   gingerbread, sugar glass and lamps can. *Cost if wrong:* one list.
10. **The music is an original waltz** (CC0, synthesised), named `candy_day`/`candy_night` so the audio pass can
    replace either with a public-domain classical piece; the descriptor's `classical` names the Nutcracker's
    Land of Sweets pieces. The boss keeps Green Meadows' loop (like the desert).
11. **Sprinkles are one CPUParticles3D per screen** (140 particles, the shared Fx material), not GPU particles (a
    process material would compile a new shader; the emulator runs Compatibility). *Cost if wrong:* a denser
    look needs a higher `AMOUNT`.

12. **Owner feedback #44 (21:07, the lead's heads-up)**: the Totem's waves and the boss move into a new MONSTER WAVE
    mode (another agent). The Cake Monster and the candy monsters go only through the shared `BossDirector`,
    `MonsterDirector` and `WaveDirector` kinds (the descriptor's `monster_kinds` and `boss_kind`), like the desert
    and Frostpeak; nothing here is Totem-specific (the hub portal and the cosmic outfit follow any win of the
    Cake Monster through `BossDirector`).

## Tried and rejected (the godot-prompter skills)

- **procedural-generation**: seeded noise per column with hash-drawn cell features (hills and cakes one per cell,
  looked up once per chunk) — chosen; cellular automata or WFC for hills and cakes — rejected (per-chunk state,
  seams, cost).
- **ai-navigation**: the monsters' own 10 Hz steering with a pure bounce rule on the physics' wall normal —
  chosen; NavigationAgent3D / navmesh baking — rejected (a streamed, editable voxel world).
- **particles-vfx**: one world-space CPUParticles3D following the player with the shared Fx material — chosen;
  GPUParticles3D with a ParticleProcessMaterial — rejected (a new shader to compile: a 100+ ms frame on the
  emulator's GL renderer, DEVELOPMENT.md §8), per-sprinkle nodes — rejected.

## What the lead should check on the emulator

1. **Open a kingdom world**: `--universe=4` on the desktop (a private `XDG_DATA_HOME`), or the WORLD toggle /
   the hub once universe 4 is unlocked. Pink sky, frosting plains, chocolate rivers, green and red gumdrop hills,
   tiered cakes, candy-cane forests and lollipop trees, cotton candy; both styles (page 8), no shader hitch when the
   first chunk appears.
2. **Chocolate water** in both styles (brown, a little glossy in REALISTIC); swim in a river; the view under it is
   brown, not blue; back in Green Meadows the water is blue again.
3. **Gumdrops**: jump onto a gumdrop hill from a ledge: a boing and a bounce that settles; walking up and down the
   hill does not bounce.
4. **Night**: sprinkles falling round the player (not in caves); gummy bears hopping (and bouncing off walls);
   candy sneakers invisible at a distance, a sparkly shimmer and pink eyes within 6 blocks, a jingle and a raised
   lollipop before every swing. Is the shimmer readable on a phone?
5. **The Cake Monster** after wave 5: the frosting wave (jump it), a layer falling off with its line, the cherries
   (three, spread), the spin; the bar's cake face; the win's fireworks and fanfare, the rainbow portal (walk in: the
   hub opens), "You got a new look: Cosmic!" and the outfit in the avatar editor.
6. **Secrets**: an X of sprinkles, a gingerbread house (its plates and golden door), a chocolate door in a cake's
   side, a floating cake.
7. **Performance**: the autopilot's play phase and flight in the kingdom, both styles (the generator is at or under
   Meadows' cost on the desktop; cakes are taller than Meadows' hills).

## Notes for the audio pass (owner feedback #31)

The kingdom's tracks are `assets/music/candy_day.ogg` and `candy_night.ogg` (Music plays them through the
descriptor's `music`). `world/universes/candy.gd` names the classical pieces that fit (`classical`): day "Waltz of
the Flowers", night "Dance of the Sugar Plum Fairy", boss "Russian Dance (Trepak)", all from Tchaikovsky's The
Nutcracker (the Land of Sweets). Render or fetch a public-domain one into those paths (or add a `boss` track to
`music`); nothing else changes.

## Merge notes (what will conflict)

- `data/blocks/block_ids.gd` (the constants after BOUNCE, `CANDY_GROUND`, `NON_SOLID`, `_NAMES`), `world/block_library.gd`
  (`_static_init`, the section at the end), `core/rules/monster_rules.gd` (KINDS, the KIND/HP/GOLD tables, `hit`,
  `windup`, the section at the end), `entities/monsters/monster.gd` (hooks in `_build`, `_look`, `_physics_process`,
  `_hop_step`, `_safe_ahead`, `_lookahead`, `_go_to`, `_process`, the section at the end),
  `entities/monsters/monster_models.gd`, `core/mind/species/monster_species.gd` (HINTS), `core/rules/boss_rules.gd`,
  `world/boss_director.gd` (`_make_golem`, `_on_defeated`, `_spawn_portal`, `_rpc_won`, the section),
  `ui/hud/boss_bar.gd`, `core/rules/chat_commands.gd` (MONSTERS, BOSSES, NEVER_GIVEN), the natural-block lists,
  `world/stealth_director.gd` (`light_at` taken out of `refresh`), `scenes/sandbox.gd` (3 lines + section),
  `autoloads/session.gd` (section), `autoloads/audio.gd`, `entities/player/player.gd` (2 lines + section),
  `world/ambience.gd`, `shaders/water.gdshader`, `entities/portal/desert_portal.gd`, `world/universes/universe_hub.gd`,
  `core/rules/universe_rules.gd`. Frostpeak (M3 Task 3) touches many of the same lists and hooks.
- **Frostpeak is already merged in** (`500b45e`): 21 files conflicted line by line and both sides were kept
  (`KINDS` ends `…, YETI, ICE_BAT, GUMMY, SNEAKER`; `BOSSES` ends `giant, cake`; the natural-block lists, the fake
  walls, `LEAVES_OF`, `NON_SOLID`, the atlas pages 7 and 8, `BossDirector._new_boss`/`_win_look`, the boss bar's
  faces, the ambience's `storm_snow` next to `chocolate`). Two things were unified rather than doubled:
  `GolemRock.sound` is Frostpeak's (the cherries set `&"cherry_splat"`), and the generator bench's `--candy` uses
  Frostpeak's `_bench_universe`. `UniverseRegistry.size()` is now 4, so the Candy Kingdom (index 4) is the last
  universe: its boss's portal leads to the hub; Frostpeak's giant opens the portal to the kingdom.
