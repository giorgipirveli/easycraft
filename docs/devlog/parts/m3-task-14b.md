# M3 Task 14b: Action kit — blasters, surprise drops and build-fight practice

Spec §13.4 (blasters), §13.5 (surprise drops), §13.7 (build-fight practice), §14.13; plan Task 14 (second
half); the owner (20:39): "dont forget to add modern weapons in sandbox mode, weapons like in forinite" —
**cartoon toy blasters, never real-world guns**, free in the Sandbox's ARMORY page. Built in an isolated
worktree, no editor or emulator use. Base: `ec8c65c` (the lead's merge of M3 Task 3, Frostpeak, on top of
`m2-survive-the-night` `e56a322`): the branch had no commits yet, so it was moved there to build the archer
on the Frostpeak monster code (fewer conflicts in `monster.gd`, and the yeti's snowball could be aligned).

## What was built

### Blasters (items 415–424; 425–429 stay free)

| Blaster (id) | Rarity | Damage | Rate | Magazine / reload | Flight | What a hit does | Ammo (id), Tilly's pack |
|---|---|---|---|---|---|---|---|
| Foam Blaster (415) | common | 1 | 0.16 s | 8 / 1.2 s | 30 m/s, nearly straight | a dart; a small push | Foam Darts (420), 20 for 5 gold |
| Snowball Launcher (416) | uncommon | 2 | 0.45 s | 5 / 1.4 s | 17 m/s, arcs (gravity 14) | a small push (4.5, under a sword's 6) | Snowballs (421), 10 for 5 |
| Paint Splatter (417) | rare | 2 | 0.35 s | 6 / 1.5 s | 22 m/s, a little arc | 30 % slower for 5 s, a paint mark over its head | Paint Blobs (422), 10 for 8 |
| Bubble Cannon (418) | epic | 1 | 0.7 s | 3 / 1.8 s | 11 m/s, floats up a little | level ≤ 2: floats in a bubble for 4 s (no moving, no attacking); bigger: half speed for 4 s | Bubble Soap (423), 6 for 8 |
| Confetti Rocket (419) | legendary | 3 | — | 1 / 3.0 s | 20 m/s | everything within 4 blocks it can see: pushed away (9 m/s + up), monsters take the damage; a confetti burst | Party Rockets (424), 2 for 12 |

Blasters cost 20 / 45 / 90 / 180 / 350 gold (by rarity; × 2^(u−1) like everything Tilly sells), one of each
(`ShopRules.is_tool_item`); Tilly never buys them back. Numbers: `BlasterRules.BLASTERS`.

| Piece | File | What it does |
|---|---|---|
| Rules (pure) | `core/rules/blaster_rules.gd` | The table, `Magazine` (rate, reload; resting reloads it; the host's slack 0.8), hits (`bubble_traps`, `push`, `area_hits`, `area_push`), `ammo_refusal`, Tilly's prices and packs |
| Looks | `entities/weapons/blaster_models.gd` | Held models (bright toy colours, an orange tip, rarity + 1 bands; `WeaponModels.material()`), shot meshes (dart, snowball, paint blob, see-through bubble, rocket, the goblin's arrow), the bubble and paint marks |
| Icons | `ui/hud/blaster_icons.gd` | 16 px pictures drawn in code, framed like the tier icons (rarity rim, 32 px, 1–5 pips) |
| Pool | `entities/projectiles/shot_pool.gd` | 40 mesh slots made once; every game flies the same shots (`WeaponRules.arrow_step`); a block stops a shot (a dart or an arrow sticks a moment, the rest burst); the host's `hit_check` ends a shot that met something |
| Director | `world/blaster_director.gd` | Node `Blasters` on every peer: the host spawns checked shots for everyone (`_rpc_shot`), checks hits, applies them, ends them everywhere (`_rpc_end`); pooled bursts (10 + 3 confetti emitters) and marks (8 bubbles, 8 paint splats); `prewarm(camera)` |
| Controls | `entities/player/blaster_user.gd` | Child of the `WeaponUser`, asked first: ATTACK fires (and keeps firing at the rate while held), a tap fires where it points, the mouse too; arcing blasters lob onto the aim; aim assist like the bow's |
| Session | `autoloads/session.gd`, section "M3 Task 14b" | `request_blast`, `accept_blast`, `blaster_reset`, signal `blast_requested` |
| Monster hooks | `entities/monsters/monster.gd`, section "M3 Task 14b: blaster hits" | `blast_bubble`, `blast_slow`, `blast_paint`, `bubbled()`, `painted()`, `blast_speed()`; `_blast_tick` in the physics step; `_move_speed` × `blast_speed()` |
| Sandbox palette | `ui/hud/block_palette.gd` | The ARMORY page is a row: the tier grid, then a BLASTERS column (common at the top), rims in the rarity colours |
| Tilly | `core/economy/shop_rules.gd` | Blasters and ammo at the end of the TOOLS section |
| Sounds | `tools/make_blaster_sfx.py` | Original, synthesised: foam_pop, paint_shot, bubble_shot, bubble_pop, rocket_whoosh, confetti_boom, party_horn, pinata_burst |

### Goblin archers

`MonsterRules.ARCHER` (`&"archer"`, behaviour `SHOOTER`): hp 5 + 3(l−1) (a goblin's is 6 + 4(l−1)), hits like a
slime (1 + l/2, × 2^(u−1)), gold 3l, speed 3.2 + 0.2(l−1), a 1.0 s wind-up. Pure rules: `core/rules/archer_rules.gd`.
Looks: the goblin in a green hood with a quiver and a bow (`MonsterModels._archer`); its arm comes up level
while it aims and the nocked arrow's tip glows (a second shared arm mesh, like the yeti's snowball).

While it chases a child it sees (Monster section "M3 Task 14b: the goblin archer"), at 10 Hz:
- **Range:** under 10 blocks it backs off (a brave child can chase it); over 19 it walks up; 10–20 it shoots.
- **Spots:** two candidates a decision from two rings (2 and 4 blocks, 8 directions; a round of 16 plus
  where it stands, a new round every 2.5 s). A spot scores +1 per block above the child (high ground),
  +3 with **cover** (a block between its eyes and the child's chest, with a free **peek** step beside it
  from where the shot is clear), −0.2 per block from 14, −0.15 per block to walk. A spot with no clear shot
  from it or its peek does not count. Spots higher than a hop can reach are skipped; a spot it can't reach
  in 6 s is dropped.
- **Shooting:** it waits in cover (1.4 s, and until its 2.6 s cooldown is over), steps out to the peek,
  draws its bow for 1.0 s (synced `winding`: everyone sees the arm and the glowing arrow), then shoots a
  slow arrow (12 m/s, gravity 6, big and bright) lobbed onto where the child stands (no lead). If the flight
  would end in a block (the child ducked behind a wall during the wind-up) it doesn't shoot at all.
- **Arrows** fly in the BlasterDirector's pool (`Monster.shoot_arrow` = `BlasterDirector.monster_arrow`);
  every game flies the same arrow and the host checks it against players (not knocked out, not hiding) and
  bot friends; a block always stops it. A hit hurts through `Session.hurt_player` (a shield in front blocks
  its share; Cozy halves it) from 2 blocks back along the arrow.
- **Where they come from:** at night 2 in 5 goblins of level ≥ 2 carry a bow (`ArcherRules.night_kind`; the
  roll comes from the monster's id, so the director's random numbers are unchanged); waves from wave 4 turn
  every other goblin into an archer (`ArcherRules.wave_roster`, always the same ones); `/summon archer 1-5`.
  Only where goblins live (Green Meadows): the desert and Frostpeak already have their ranged monsters.
- **Never changes a block:** it only reads the world (`block_at`); tested by a scene run and a source scan.

### Surprise drops

| Piece | File | What it does |
|---|---|---|
| Rules (pure) | `core/rules/drop_rules.gd` | The piñata clock (600 s + up to 300 s from the seed and count), its spot (8–30 blocks from a player), its fall (1.6 m/s, a little sway), hits (3; 0.25 s apart), its supplies; balloons (Survivor waves ≥ 3, 8 s in; a path from 16 blocks out, 8 high, over the Totem in 14 s, settling 3 blocks beside it 1.4 high in 5 s), their supplies; `clean_save` |
| The drop | `entities/interactables/party_pinata.gd` | `PartyPinata` (a StaticBody3D on layer 8, mask 0; groups `monsters` and `drops`; `take_hit`, `hit_center`, `hit_radius`, `size`): a striped paper donkey with a parachute, or a red balloon with a supply crate; the host moves it, its place and `landed` are synced |
| Director | `world/drop_director.gd` | Node `Drops` on every peer (spawner, the swing and burst RPCs); the host's clocks, spawns, hit counting, bursting, supplies (`give`), floating away |
| Save | `world/world_meta.gd` | `drops`: `{clock, count}` |

Supplies: a piñata gives its LootRules "pinata" blocks (M2 Task 16's hook: planks, glass or toy colours),
always one potion and two kinds of ammo; a balloon one potion and one kind of ammo. Fixed by the world's
seed and the drop's number (never random for money; never gold). Everyone within 12 blocks of a piñata
(16 of a balloon) gets the same; Sandbox: "Party Piñata! Hooray!" and the fun only.

## Godot skills (house rule)

- `godot-prompter:godot-optimization` for the shots. **Chosen:** a fixed object pool made once (40
  `MeshInstance3D` slots, the oldest recycled when full) with packed arrays for the flight state, and small
  pools of `CPUParticles3D` bursts re-used with `restart()`. **Rejected:** a node per shot through a
  `MultiplayerSpawner` (like the M1b arrows: a node and a spawn packet per dart at 6 shots a second), and a
  `MultiMeshInstance3D` per shot look (fewer draw calls, but six looks and rarely more than ten shots in
  view; not worth the complexity).
- `godot-prompter:ai-navigation` for the archer. **Chosen:** steering at 10 Hz like every monster, with a
  small state machine (back off / approach / hide / peek / wind-up) and an incremental cover search (grid rays,
  two candidates a decision). **Rejected:** `NavigationRegion3D` baking (the voxel world changes under the
  children's hands; rebaking costs), and a behaviour tree (five states don't need one).

## Tests (RED → GREEN)

| Test file | Tests | RED (why it failed first) |
|---|---|---|
| `tests/unit/test_blaster_rules.gd` | 20 | `BlasterRules` not declared; then the rocket's "slow reload" read 0: `BlasterRules.reload(id)` called `Script.reload()` (renamed `reload_time`) |
| `tests/unit/test_blaster_hooks.gd` | 4 | written with the hooks (monsters see a blaster as ranged, item rarity, `/give`, sounds) |
| `tests/unit/test_blaster_shop.gd` | 3 | Tilly had no price for them (0) |
| `tests/unit/test_archer_rules.gd` | 12 | `ArcherRules` / `MonsterRules.ARCHER` missing; then the ring candidates rounded the diagonals to 1 block (grid directions now) |
| `tests/unit/test_drop_rules.gd` | 10 | `DropRules` not declared |
| `tests/integration/test_blaster_looks.gd` | 5 | written with the models |
| `tests/integration/test_blaster_shots.gd` | 15 | `BlasterDirector` / `Session.accept_blast` missing; then the 200-shot test counted the player's held item appearing (the test now waits for it) |
| `tests/integration/test_blaster_user.gd` | 8 | `BlasterUser` missing |
| `tests/integration/test_goblin_archer.gd` | 6 | the archer section missing |
| `tests/integration/test_archer_spawns.gd` | 4 | no archers at night or in waves |
| `tests/integration/test_surprise_drops.gd` | 12 | `DropDirector` missing; then `WorldMeta.drops` missing |
| `tests/integration/test_palette_armory.gd` (+2, 1 changed) | | no BLASTERS column |

Changed tests (items and palettes grew): `test_item_ids` (the palette rows cover BLASTERS; ammo has no palette
row), `test_block_palette` and `test_counted_hotbar` (ammo is not in the Sandbox palette),
`test_palette_armory` (the ARMORY page also holds the five blasters).

Mutation checks (each made its test fail, then restored): the rocket's blast without the wall check
(`test_a_shot_never_goes_through_a_wall`); the archer without the cover bonus
(`test_an_archer_hides_behind_a_block_and_steps_out_to_shoot`: it never waited in cover).

Suite (`tests/run_tests.sh`, niced, in a snapshot of the staged tree): baseline on `ec8c65c` 3193 tests with
one failure, `test_bot_minds.test_a_fighter_guards_the_side_monsters_come_from` (it passed in every later
run: a known timing flake, not from this task) → **3250 / 3250** after the blasters → **3272** after the
archers (one failure: M2 Task 8's lantern test expected every weak monster to come within 9 blocks of a
lantern by the child, but an archer keeps 10–20 blocks away by design; that one assertion now skips
archers, and the 6-block rule still holds for them) → **3294 / 3294** after the drops (exit 0).

## Smoke run on real terrain

`XDG_DATA_HOME=<private "smoke" folder> godot --headless --path . --script res://tools/action_kit_smoke.gd`
(seed 184420981, load average ~35): every check passed — 6 foam darts defeat a level 1 goblin in 1.0 s
(6 darts used from the bag); a bubble traps a level 2 goblin (0.2 s); a summoned archer backed off from
4 to 10.8 blocks, drew its bow and hit the player standing still after 15.9 s (Cozy: 20 → 19); a piñata came
27.7 blocks away, landed after 13.8 s, burst after 3 hits (9 → 12 kinds in the bag, ammo among them); a
supply balloon came in "wave 3" and settled beside the Totem; popping it gave a potion. Cost window (foam
darts at 8 summoned monsters for 5 s, the whole game's frame including the world): physics 6.1 ms average,
9.1 worst; process 3.4 average, 5.9 worst (desktop, busy PC: not the emulator's numbers). A second world
(`--smoke-seed=777`, the final code, with a full test suite running beside it) passed every check too: the
archer backed off to 12.2 blocks and hit after 5.7 s; the piñata came 22.0 blocks away; cost window physics
7.0 ms average (8.8 worst), process 5.1 (11.3 worst).

## Rulings (decided on the owner's behalf; cost if wrong)

1. **One blaster per rarity** (common … legendary) instead of five tiers of each: the allocation (415–429)
   holds 15 ids, and 25 tiered blasters plus ammo don't fit; Fortnite-like weapons come in rarities too.
   Rarity shows on the icon (rim, 1–5 pips), the model (1–5 bands) and the palette/shop rims. *Cost if
   wrong:* more ids from the lead (a tier table like `WeaponRules.TIERS`).
2. **Each blaster has its own ammo** (5 kinds), counted items in Survivor; a shot takes one. *Cost if
   wrong:* one generic ammo is simpler for small children; one table (`BlasterRules.BLASTERS.ammo`).
3. **No friendly fire:** shots fly through players, bot friends and buddies (§13.7: no player-vs-player for
   under-13s; no griefing on LAN), and the rocket's blast never pushes players. *Cost if wrong:* a "tag"
   mode would need it back, host-checked.
4. **Blasters never hurt animals** (a toy: they are pushed), even though owner feedback #26 lets weapons
   defeat animals (being fixed by another agent in `CombatDirector.apply_hit`). *Cost if wrong:* one line in
   `BlasterDirector._hit`.
5. **Blasters stay out of `WeaponRules.WEAPONS`** (their own path: `BlasterUser` → `Session.request_blast`
   → `BlasterDirector`); only `WeaponRules.is_holdable`, `WeaponModels.mesh_for`, `HeldItem.swing_name`,
   `ItemRarity.of_item` and `MonsterSpecies.weapon_class` know them. So the owner-bugs agent's new
   `attack_pressed` ("ATTACK always attacks": held weapon → best weapon in the hotbar → fists) doesn't pick a
   blaster as "the best weapon" by accident. **Merge note:** keep `if blasters.pressed(): return` as the first
   line of `attack_pressed` and `blasters.released()` first in `attack_released`. *Cost if wrong:* a child
   holding a sword and a blaster gets the sword from the "best weapon" rule; the lead may add blasters to it.
6. **ATTACK held keeps firing** at the blaster's rate (a magazine, then the reload; resting reloads a half
   magazine) — children don't tap fast. No HUD (the brief): the reload shows as a pause, the kick and sound
   show each shot. *Cost if wrong:* a reload ring on the ATTACK button (M5 polish).
7. **The host starts every shot from its own copy of the shooter's eyes** (like arrows), so a guest can't
   shoot from somewhere else; its reach is the shot's flight (speed × life, 24–36 m). Rate and reload are the
   host's own `Magazine` per player and blaster with 0.8 slack. *Cost if wrong:* a guest running fast sees
   its dart leave a little behind it.
8. **The paint mark** is a splat over the monster's head in an unshaded, fog-free material (one cached
   material, compiled at world start by `BlasterDirector.prewarm`), seen by everyone (co-op: everyone is the
   team). The monster's own body stays fogged. *Cost if wrong:* a first paint hit before the prewarm could
   cost a shader compile (a 100 ms frame on the emulator) — check.
9. **The bubble's and the bubble shot's see-through look reuse the invisibility potion's material**
   (`Player.ghost_material()`): no new shader. *Cost if wrong:* bubbles look like ghosts (pale blue, 28 %
   opaque); a tint later is one uniform.
10. **The piñata and the balloon are in the group `monsters`** (with the Monster contract: `take_hit`,
    `hit_center`, `hit_radius`, `size`) so swords, arrows, spears, boomerangs, blasters, the owner-bugs
    agent's fists, spike traps and **bot friends** all hit them, and a tap aims at them. *Cost if wrong:* bot
    friends wander off to beat a piñata (cute) and remember "a monster came from there"; a separate group
    would need hooks in `CombatDirector.hittables` and `BlockInteractor.hittable_at`.
11. **Hits count at most every 0.25 s** (a rocket's hit and its blast are one), 3 for a piñata, 1 for a
    balloon.
12. **Supplies go to every player near the burst** (12 blocks, a balloon 16), the same for all (co-op, no
    competition), never gold (§6, the brief); the piñata always has a potion (LootRules' table gave one 60 %
    of the time). *Cost if wrong:* a child far away misses out.
13. **The piñata clock counts play time only while a player is in the world** and is saved
    (`WorldMeta.drops`); a piñata in the air is not saved (the clock just goes on). A piñata left 5 minutes on
    the ground floats away. The first one comes after 10–15 minutes of a new world. *Cost if wrong:* a child
    who plays 5 minutes a day sees one every few days.
14. **Sandbox piñatas are the fun only** (confetti, a toast): Sandbox has everything already. **Sandbox
    waves have no balloons** (the brief: "in Survivor waves").
15. **The balloon settles low beside the Totem** (1.4 blocks up) after drifting over it, so a child with only
    the starter sword can pop it; arrows and blasters get it on the way. It leaves with the wave.
16. **Goblin archers are Green Meadows monsters** (a goblin variant): 2 in 5 goblins of level ≥ 2 at night,
    every other goblin in waves from 4. The desert (scorpion spit) and Frostpeak (the yeti's snowballs)
    already have ranged monsters. *Cost if wrong:* `ArcherRules.night_kind` for other universes' kinds.
17. **Archer arrows hit like a slime** (1 + l/2) and don't lead the child (a sidestep dodges them): they are
    for learning to build walls and take high ground, not for knock-outs. *Cost if wrong:* tuning.
18. **The yeti's snowballs** (M3 Task 3) stay as they are: a thrown globe with a landing check. The Snowball
    Launcher reuses its sounds (`snow_throw`, `snow_splat`) and colour (`BlasterModels.SNOW`), but its shots
    are real projectiles in the pool (they hit what they meet on the way, like every blaster shot).
19. **Icons are drawn in code** (`BlasterIcons`), not in `data/items/item_icons.png`: no binary file for two
    parallel tasks (14a's gadgets) to fight over.
20. **`ChatCommands._LAST_ITEM_ID` is 450** (gadgets and blasters 400–429, Task 8's paint 435–450), so
    `/give foam blaster` works.

## What the lead should check on the emulator

1. Sandbox → palette → ARMORY: the BLASTERS column right of the tier grid, fits above the hotbar on the
   phone's aspect; icons and rims read at phone size.
2. Each blaster in the hand (BLOCKY and REALISTIC): points forward, orange tip visible, the kick on a shot;
   ATTACK held keeps firing (foam), the reload pause; a tap fires where it points; the snowball lands where
   aimed.
3. Monsters: bubble (see-through, the monster floats and stops), paint mark (bright at night and in a
   snowstorm, over the head), the rocket's confetti and push; **frame time of the first bubble and the first
   paint mark** (prewarmed at spawn: look for a spike anyway), and foam darts at 6 a second with many
   monsters (≥ 30 FPS, no frame over 100 ms).
4. `/summon archer 2` in Sandbox: it backs off, hides behind a tree or a block, steps out, the bow comes up
   with the glowing arrow for a second, a slow arrow; a quick wall stops it; high ground helps.
5. Survivor: Tilly's TOOLS section ends with the blasters and ammo packs; "Out of Foam Darts!" once; a
   piñata after 10–15 minutes (or run the smoke tool), its parachute, 3 hits, the supplies toast; a wave 3
   balloon beside the Totem.
6. LAN: a guest's shots and the host's are seen by both; bubbles and paint marks on both; the piñata falls
   smoothly on the guest (its place is synced at the creature rate).

## Merge notes (for the lead)

- **Expected small conflicts:** `data/items/item_ids.gd` (`ALL`, names — 14a adds 400–414 at the same
  places), `ui/hud/block_palette.gd` (`_armory_page`: the page is a `BoxContainer` row now; 14a may add a
  gadgets row/column), `core/economy/shop_rules.gd` (catalog TOOLS), `entities/player/weapon_user.gd`
  (the owner-bugs agent rewrites `attack_pressed`: keep my first line), `entities/monsters/monster.gd`
  (sections at the end; hooks in `_physics_process`, `_decide`, `_strike`, `_move_speed`,
  `_animate_goblin`), `core/rules/monster_rules.gd` (`KINDS`, tables), `core/rules/chat_commands.gd`
  (`MONSTERS`, `_LAST_ITEM_ID`), `autoloads/session.gd` and `scenes/sandbox.gd` (sections at the end),
  `world/world_meta.gd` (`drops`), `autoloads/audio.gd`, `assets/CREDITS.md`, `docs/DEVELOPMENT.md`.
- Tests that loop over `MonsterRules.KINDS` (doors, lanterns, minds, meshes, sounds) now include the archer.
- `tools/action_kit_smoke.gd` can become a tour check.
