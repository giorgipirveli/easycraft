# M1b Task 11: Sword, weapons and tools

Owner request (2026-09-23 22:45): "player should have a sword and different weapons". Spec §3b "Sword and
weapons", plan Task 11. Built in an isolated worktree from `6afe171` (branch `m1b-underground`).

## What was built

- **Six weapons in one table** (`core/rules/weapon_rules.gd`, `WeaponRules.WEAPONS`), which M2 monsters
  will reuse. Each has damage, reach, cooldown, knockback, swing arc, max hits, block power and sound.

  | Weapon | Damage | Reach | Cooldown | Knockback | Arc | Max hits | Block power |
  |---|---|---|---|---|---|---|---|
  | Sword | 4 | 3.0 m | 0.35 s | 6 | 55° | 3 | — (3-swing combo; the 3rd spins: all around, ×1.5) |
  | Bow | 5 × draw | 48 m | 0.45 s | 4 | — | 1 | — (hold to draw 0.7 s; arrows arc and stick) |
  | Boomerang | 3 | 14 m | 0.6 s | 5 | — | 4 per throw | — (out and back; one in the air per player) |
  | Hammer | 6 | 3.2 m | 1.1 s | 14 | 70° | 5 | ground smash 3×3 |
  | Axe | 3 | 2.8 m | 0.5 s | 4 | 30° | 1 | fells a whole natural tree |
  | Pickaxe | 2 | 2.8 m | 0.4 s | 3 | 30° | 1 | player-sized 1×2 tunnel step |

- **Tool powers** (`core/rules/tool_powers.gd`) return EditBatch input and go through the existing host
  edit path: `BlockInteractor._apply_edits` → `Session.request_set_blocks` → `EditBatch.sanitize` →
  `PlacementRules.validate_edit` with `BATCH_REACH`. They are undoable like stamps. Air, water and bedrock
  are never included, and the host rejects bedrock anyway.
  - Axe: the LOG blocks connected to the tapped log, plus that tree's LEAVES. A tree must stand on
    grass, dirt or sand and have leaves; a leafless log pillar (a house corner) is not a tree. Leaves nearer
    to another trunk stay with that tree. Never planks. Capped at 400 blocks, logs first. On anything that
    is not a tree, the axe chops just that one block.
  - Pickaxe: tapped at the feet or head, a 1×2 step lined up with the feet. Tapped on the floor, a 2-deep
    hole. Tapped on a ceiling, 2 up.
  - Hammer: the 3×3 patch on the tapped block's level. It also sends a hammer attack, so things standing
    near get pushed.
- **Practice targets** (items DUMMY and BULLSEYE). Place one by tapping a block. Hold on a target to
  remove it. The host spawns targets for everyone and saves them in `WorldMeta.targets` (max 16).
  - Dummy: wobbles away from the hit and shows a floating damage number.
  - Bullseye: arrows score rings 1–10 on its face (gold 9–10 dings). It faces the player who placed it.
  - A target whose ground is dug away pops (the host checks once a second, only where terrain is loaded).
- **Hits** are resolved by the host with its own positions (`world/combat_director.gd`, node `Combat` on
  every peer).
  - Only dummies (and M2 monsters) take damage.
  - Animals (group `animals`) get `knockback(impulse)`.
  - Players get a knockback RPC to their own game.
  - Buddies cheer.
  - Nobody is hurt.
  - Arrows stick into blocks and targets. On an animal, a buddy or a player they only bonk (push) and
    vanish: no arrows sticking out of pets.
- **Held items**: one merged vertex-coloured mesh per weapon (`entities/weapons/weapon_models.gd`).
  - The mesh hangs under `avatar.hand()` (`entities/player/held_item.gd`), and every peer sees it
    (`Player.held_item` is synced).
  - Attack animations move the item around the hand, so they work on any avatar. The blocky avatar also
    swings its arm (optional `play_attack` / `set_aiming`): slash / sweep / spin, overhead smash, chop,
    pick, throw, and bow draw with both arms forward.
- **Controls**
  - Tap: a tool uses its power on a block; a weapon attacks towards the tapped point (an arrow is lobbed
    to land there); a target item places the target.
  - ATTACK touch button: anchor (1,1), offset (−390,−330), size 130. It shows only while a weapon or tool
    is selected on touch screens. Tap it to attack straight ahead, hold it to draw the bow, and a
    crosshair shows while drawing.
  - R key (`attack` action, in `project.godot` and `tools/setup_input_map.gd`).
  - With a captured mouse: the left button attacks (hold to draw), and both buttons use tool powers.
- **Aim assist (light)**: the host pulls melee swings onto a target within 35°. That only helps the
  narrow-arc axe and pickaxe (30°). The thrower's game pulls bow and boomerang aim onto a target within
  8° of the crosshair.
- **Palette**: a TOOLS row below MAGIC (label plus 8 buttons at 80 px, the same width as the block grid).
  The panel grows by one row: top 50, bottom 590 on 1280×720, clear of the hotbar at 642.
- **Icons**: atlas row 5, drawn without the RNG. A pixel diff showed only row 5 changed, in
  `atlas.png` and in `realistic_albedo.png`. `realistic_normal.png` and `water_waves.png` are
  byte-identical.
- **Sounds** (original, `tools/make_weapon_sfx.py`, credited): swing, bow, hit, thud, smash, whirr,
  ding. They are small mono 22 kHz WAVs, about 175 KB in total.

## Files

New:
- `core/rules/weapon_rules.gd`, `core/rules/tool_powers.gd`
- `entities/weapons/weapon_models.gd`, `entities/player/held_item.gd`, `entities/player/weapon_user.gd`
- `entities/targets/practice_target.gd`, `practice_dummy.gd`, `bullseye.gd`
- `entities/projectiles/arrow.gd`, `boomerang.gd`
- `world/combat_director.gd`
- `tools/make_weapon_sfx.py`, `tools/weapons_smoke.gd`, `tools/weapons_smoke_steps.gd`
- `assets/audio/sfx/{swing_1,swing_2,bow,hit_1,hit_2,thud,smash,whirr,ding}.wav`

Changed:
- `data/items/item_ids.gd`: ids 110–117; lists `MAGIC`, `TOOLS`, `TARGETS`; `ALL` now includes the new
  ids; `is_target`.
- `ui/hud/block_icons.gd`, `ui/hud/block_palette.gd`, `ui/hud/hud.gd`
- `tools/make_atlas.gd`, `tools/make_realistic_atlas.py`, `data/blocks/atlas.png`, `realistic_albedo.png`
- `autoloads/session.gd` (weapons section at the end), `autoloads/audio.gd`
- `entities/player/player.gd`, `blocky_avatar.gd`, `block_interactor.gd`
- `entities/buddy/buddy.gd` (group `buddies`)
- `world/world_meta.gd` (`targets`), `scenes/sandbox.gd`
- `project.godot` (`attack` = R), `tools/setup_input_map.gd`
- `assets/CREDITS.md`, `docs/DEVELOPMENT.md`

## Tests

The full suite has **334 passing**, up from 264 at the base. New tests:

- `tests/unit/test_weapon_rules.gd` (24 tests):
  - `test_weapon_table_is_complete_and_sane`, `test_hammer_is_slow_and_hits_hardest`,
    `test_tools_have_their_block_powers`
  - `test_melee_cone_hits_in_front_within_reach`, `test_melee_hits_the_closest_targets_up_to_the_weapon_limit`,
    `test_sword_finisher_spins_and_hits_all_around`
  - `test_aim_assist_snaps_within_the_assist_angle_only`, `test_aim_assist_turns_a_near_miss_into_a_hit`
  - `test_host_rejects_hits_beyond_reach`, `test_host_rejects_attacks_faster_than_the_cooldown`
  - `test_animals_players_and_buddies_get_knockback_but_no_damage`,
    `test_sword_combo_counts_up_within_the_window_and_the_finisher_hits_harder`
  - `test_arrow_falls_under_gravity`, `test_arrow_stops_at_the_first_solid_block`,
    `test_arrow_sticks_into_the_ground`, `test_draw_power_sets_the_arrow_speed`,
    `test_launch_direction_lobs_the_arrow_onto_the_aim_point`
  - `test_boomerang_flies_out_and_returns_to_the_thrower`, `test_boomerang_finds_a_thrower_who_walked_away`,
    `test_boomerang_turns_back_at_a_wall`
  - `test_bullseye_scores_rings_from_10_to_1`, `test_segment_hits_a_disc_facing_it`,
    `test_segment_hits_a_body`, `test_targets_stand_on_solid_ground_with_room_above`
- `tests/unit/test_tool_powers.gd` (13 tests):
  - `test_axe_fells_exactly_the_logs_and_leaves_of_one_tree`, `test_axe_leaves_the_neighbouring_tree_standing`,
    `test_axe_never_takes_the_players_planks`, `test_a_log_pillar_in_a_build_is_not_a_tree`,
    `test_axe_needs_a_log_to_start`, `test_felling_is_capped_and_keeps_the_trunk`
  - `test_pickaxe_digs_a_1x2_step_in_the_facing_direction`, `test_pickaxe_skips_air_and_water`
  - `test_hammer_smash_breaks_a_3x3_patch`, `test_smash_skips_empty_cells`
  - `test_each_tool_uses_its_own_power`, `test_the_axe_chops_one_block_that_is_not_a_tree`
  - `test_tool_powers_never_include_bedrock`
- `tests/unit/test_item_ids.gd` (+4): ids allocated, MAGIC + TOOLS cover ALL, targets, icons drawn in row 5.
- `tests/unit/test_weapon_assets.gd` (3): the sounds are registered and load; attack = R in
  `project.godot` and in the input tool.
- `tests/unit/test_world_meta_targets.gd` (3): round trip, old saves, broken entries dropped and capped.
- `tests/integration/test_block_palette.gd` (3): every block and item once, the TOOLS row below MAGIC,
  the panel fits 1280×720 above the hotbar.
- `tests/integration/test_hud_attack_button.gd` (2): no overlap with JUMP, DOWN, the right-side buttons
  or the hotbar; under the palette overlay; hidden at start.
- `tests/integration/test_weapons_in_world.gd` (18):
  - Models: `test_every_weapon_and_target_is_one_cheap_mesh`, `test_every_model_faces_outwards`
    (clockwise winding, checked against Godot's own BoxMesh), `test_the_arrow_tip_leads`
  - Held item and avatar: `test_the_held_weapon_hangs_in_the_avatars_hand`,
    `test_an_attack_swings_the_arm_and_the_item_then_rests`, `test_drawing_the_bow_raises_both_arms`,
    `test_players_sync_what_they_hold`
  - Targets and melee: `test_a_dummy_is_cheap_and_wobbles_with_a_hit_number`,
    `test_melee_hits_a_dummy_in_front_but_not_one_out_of_reach`, `test_animals_are_pushed_back_but_never_hurt`,
    `test_a_far_animal_is_out_of_reach`, `test_targets_are_saved_and_restored`
  - Projectiles: `test_an_arrow_in_the_gold_scores_10`, `test_an_arrow_sticks_into_the_ground`,
    `test_an_arrow_bonks_an_animal_and_is_gone`, `test_the_boomerang_hits_a_dummy_once_and_comes_back`
  - Host checks: `test_host_rejects_attacks_faster_than_the_cooldown`,
    `test_only_accepted_attacks_reach_the_director`
- **Headless end-to-end run** in the real sandbox: `tools/weapons_smoke.gd`, with a private
  `XDG_DATA_HOME`. It passed 19/19 checks with no script errors: sword in the hand, dummy placed, sword
  hit for 4, arrow hit, boomerang out and back (one hit), the axe felled a generated tree (60 blocks),
  smash 9, pickaxe 2, dummy saved.

## Rulings (decided on the owner's behalf)

| Ruling | Cost if wrong |
|---|---|
| Practice targets **are saved** with the world (`WorldMeta.targets`, max 16). A placed thing that vanished on reload would look like a bug. | A few lines in WorldMeta; remove the save/restore calls in `sandbox.gd` to drop it. |
| **Players are pushed** by other players' hits (host → owner RPC, capped at 30 m/s), never hurt. | If friends find pushing annoying in LAN, skip the PLAYER branch in `CombatDirector.apply_hit`. |
| Arrows on animals, buddies and players **bonk and vanish** instead of sticking (kid-friendly). They stick in blocks, dummies and the bullseye. | Cosmetic. |
| The boomerang flies **through blocks on the way back**, so it always comes home. On the way out a block turns it back. | Looks odd when a wall stands between you and it; there is no stuck or lost boomerang. |
| The axe's "natural tree" is logs on grass, dirt or sand **with leaves**. A stamped Big Tree also counts: its logs and leaves fall, and its glowing fruit (LIGHT) stays in the air. | A few floating light blocks after felling a stamped tree; hold to break them. |
| A felled tree is **not mirrored** in Mirror mode (its mirror image is random ground). Pickaxe and hammer are mirrored like any break. | Mirror users can't fell two trees at once. |
| **Hold on a target removes it** (with any item), the same gesture as breaking a block. | A child holding a finger on the dummy to "punch" it removes it. The poof and sound make it clear, and it can be placed again. |
| The host checks cooldown per player across all weapons, with 20% jitter slack, and reach per hit. It does **not** check that the attacker really holds that weapon: `held_item` sync may arrive after the attack RPC. | A modified client could swing a hammer while showing a sword: same reach and no damage to anyone real. |
| Tool powers use the normal batch rules (reach 32, 1600 cap), the same as stamps. There is no extra host cooldown for them, only the local one. | A modified client can dig faster, just as it can already stamp faster. |
| Melee aim assist 35° is applied on the host; ranged assist 8° on the thrower's game. The ATTACK button aims straight ahead (the screen centre). | Tuning only (`WeaponRules.ASSIST_ANGLE`, `RANGED_ASSIST_ANGLE`). |
| Tap shots with the bow are full power, lobbed onto the tapped point. Hold-to-draw (0.3 → 1.0 over 0.7 s) is for the ATTACK button, R and the mouse. | If the owner wants taps to need a draw, set `WeaponUser.TAP_POWER`. |
| **The default hotbar is unchanged.** The spec lists it (grass, stone, …, wand, house); weapons are in the palette's TOOLS row. | Kids must open the palette to find the sword. Suggest putting SWORD in slot 7 (instead of BLUE) for new worlds, via a spec edit. |
| **First person shows no held weapon** (the whole avatar is hidden in first person). The swing still plays its sound and hit effects. | FP players can't see their sword. A view-model can come later. |
| Giants and tiny players keep the normal reach (only the swing origin scales with size). | Giants can't reach animals at their feet. Minor. |

## What the lead must verify visually (editor or emulator)

1. Held items in the hand, in both avatars: the blade points forward, the idle bow hangs along the arm and
   stands upright when drawn, the hammer head strikes downward, the axe edge cuts downward.
2. Swing animations: sword combo (slash, sweep, and the 3rd swing spins the body), hammer overhead smash,
   axe chop, pickaxe, boomerang throw (the hand is empty while it flies), bow draw and shot.
3. ATTACK button on the emulator: right place (above-left of JUMP, clear of DOWN while flying), only with
   a weapon selected, hold draws the bow, and the crosshair appears while drawing.
4. Palette: the TOOLS row fits and the icons read well (also on a wide phone aspect).
5. Dummy: the look, the lean away from the hit, and a readable floating number. Bullseye: ring colours,
   it faces the placer, the score pops up, gold dings.
6. Arrows fly tip first, stick at a sensible angle, and pop out when their block is broken. Boomerang
   spin and return.
7. The axe on a natural tree in both styles; the pickaxe step lets you walk in; the hammer's dust ring.
8. Sounds: levels are OK next to the Kenney sounds.
9. LAN: the other player sees your held item, your swings, and the dummy numbers, and gets pushed by your
   hammer.
10. FPS with a dozen targets and many stuck arrows. Each is one mesh; targets are static bodies with
    mask 0; at most 24 projectiles.

## Integration notes (for the merge)

- **Avatar**, per the lead's note: held items attach to `avatar.hand()`, a Node3D at the right fist; the
  item points along its −Z and −Y runs along the arm. The blocky avatar creates `Hand` under `_right_arm`
  in `_ready`. The optional `play_attack(weapon_id, combo)` and `set_aiming(on)` are called through
  `has_method`, so the realistic avatar only needs `hand()`: `HeldItem` animates itself relative to
  the hand. `Player` re-parents the held item if `hand()` changes, for example on a style switch.
- **Animals**: any node in group `animals` with `knockback(impulse: Vector3)` gets pushed. The assumed
  body centre is +0.4 m with a 0.5 m radius (`CombatDirector.ANIMAL_CENTER` / `ANIMAL_RADIUS`). Tap
  targeting casts a physics ray on layer 8.
- **Chat `/give`**: display names are "Sword", "Bow", "Boomerang", "Hammer", "Axe", "Pickaxe",
  "Practice Dummy", "Bullseye". Consider accepting "dummy" as an alias.
  `ItemIds.is_hotbar_valid` accepts all eight.
- `ItemIds.ALL` now contains the weapons too. The old magic-only list is `ItemIds.MAGIC`; the palette's
  MAGIC row uses it.
- `Session` gained (in a section at the end of the file):
  - `request_attack(weapon_id, dir, power)`, `accept_attack(…)`
  - `request_place_target`, `request_remove_target`, `send_knockback`
  - signals `attack_requested`, `target_requested`, `target_removal_requested`, `knocked_back`
- `Player` gained `held_item` (added to its synchronizer in code, in `_enter_tree`, so `player.tscn` is
  unchanged), `play_attack`, `set_aiming` and `knockback`.
- `BlockInteractor` gained:
  - `weapons` (a `WeaponUser` child), `ray_at`, `apply_edits(edits, mirrored)` and `hittable_at`
  - `_apply_edits` takes an optional `mirrored` flag
  - a hook at the top of `place_at_screen` and `break_at_screen`, and one in `_unhandled_input`
- Physics layer value 16 is practice targets.
- The palette panel is now 540 px tall for 22 blocks. `test_block_palette` fails if more blocks push it
  onto the hotbar (more than 24 placeable blocks adds a grid row).
- After merging, regenerate the atlases in order (`make_atlas.gd`, then `make_realistic_atlas.py`, then
  `--import`). My row-5 code uses no RNG, so its position in `_init` does not matter.
- Expect small textual conflicts where several tasks append:
  - end of `autoloads/session.gd`, `autoloads/audio.gd` SOUNDS, `project.godot` [input]
  - `data/items/item_ids.gd`, `world/world_meta.gd`, `scenes/sandbox.gd`, `ui/hud/hud.gd`
  - `entities/player/*.gd`, end of `tools/make_atlas.gd`, `tools/make_realistic_atlas.py`,
    `docs/DEVELOPMENT.md`
