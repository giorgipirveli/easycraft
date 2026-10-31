# Owner bugs #26, #29 and #30 (2026-09-24, bug-fix agent)

Three bugs the owner reported on the 0.3.0 build, fixed test-first on a branch cut from
`m2-survive-the-night` (worktree agent). Each was reproduced in a failing automated test with the real
classes before the fix; the root cause is written next to it.

| # | Owner's words | Root cause | Fix | Tests (RED → GREEN) |
|---|---|---|---|---|
| 29 | "monsters we cannt kill i think and this is bug" | Two layers. `WeaponUser.attack_pressed` returned at once unless the **selected** hotbar slot held a weapon, and on a phone the HUD **hid the ATTACK button** unless a weapon was selected (`Hud._update_attack_button`). The Sandbox's default hotbar has no weapon (`WorldMeta._default_hotbar`), and in Survivor the selected slot moves to blocks while building. Monsters themselves die fine (a sword hit takes its damage). | **ATTACK always attacks**, and the button always shows on touch screens: the weapon in the hand; else the best melee weapon in the hotbar, whose slot is selected and put in the hand at once (so the child sees it come to hand and this swing shows it); else **fists** (`WeaponRules.FISTS`, a punch through the same host-checked attack path; every player owns fists, Survivor too). | `tests/integration/test_attack_always_attacks.gd`: `test_attack_holding_planks_swings_the_best_weapon_in_the_hotbar`, `test_attack_with_no_weapon_at_all_punches`, `test_survivor_building_with_planks_still_attacks_with_the_owned_sword`, `test_survivor_punches_without_owning_anything_but_swings_only_owned_weapons`, `test_the_attack_button_shows_on_a_phone_whatever_is_in_the_hand`, `test_a_tap_on_attack_with_blocks_in_the_hand_punches` (a real touch pushed into the HUD), `test_best_melee_slot_prefers_the_strongest_hitter_per_second`, plus guards (`test_a_weapon_in_the_hand_is_used_as_before`, `test_a_bow_is_never_picked_for_a_quick_attack`, `test_fists_are_quick_short_and_weak`) |
| 26 | "we have a bug in the game, we cannt kills animals, we should be able to kill them" | By design since M1b: `WeaponRules._DAMAGEABLE` held only dummies and monsters, and `CombatDirector.apply_hit` only called an animal's `knockback`. The owner overrules that ruling. | Animals have **health by kind** (`AnimalRules.HEALTH`: chicken, rabbit, fish 3; pig, sheep, dog, cat 6; cow 9) and take damage from weapons, fists, arrows, boomerangs and thrown spears (`Animal.take_hit`, host). A hit still pushes them and they run; their minds still learn fear of the one who hit them (M2 Task 18). Every peer sees a hit: a squash, a few white stars and the animal's cry, when the synced `hp` drops. At 0 they **puff away in the monsters' cartoon cloud** (`CombatDirector._rpc_animal_puff`, `MonsterDirector.PUFF_COLOR`), and in Survivor the one who defeated them gets a little in the bag with a toast ("You got 2 Blue!"). Pets and golden animals are only pushed. A defeated herd animal's spot stays empty for `AnimalRules.REFILL_TIME` (3 minutes), then it comes back. | `tests/integration/test_animals_can_be_defeated.gd` (12): `test_every_kind_has_health_by_its_size`, `test_a_sword_hurts_an_animal_and_it_runs_away`, `test_every_peer_sees_the_hurt_squash`, `test_a_defeated_animal_puffs_away_and_the_host_says_so`, `test_fists_hurt_a_little_and_many_punches_defeat_a_pig`, `test_an_arrow_hurts_an_animal`, `test_survivor_leaves_the_hitter_a_little_never_gold`, `test_the_sandbox_drops_nothing`, `test_a_pet_is_never_hurt_only_pushed`, `test_a_golden_animal_is_never_hurt_and_still_flees`, `test_a_hit_animal_learns_fear`, `test_a_defeated_herd_animal_comes_back_only_after_a_while`; `tests/unit/test_animal_rules.gd`: `test_drops_are_a_little_building_and_never_gold_or_anything_tilly_buys`, `test_a_sheep_always_gives_its_own_colour`, `test_the_drop_message_is_plain_and_kind`, `test_pets_and_golden_animals_are_never_hurt`, `test_herds_refill_slowly` |
| 30 | "i cannt get from water without filying" | The climb-out of M2 Task 14 works with the view level, but a push forward with the view tilted down past the dive dead zone (third-person pitch below −0.5, easy with a thumb on a phone) **dives**. Every river bank in Green Meadows is 1 block above the water with water only **2 deep** at the bank (a scan of 5 seeds, 400 blocks around each spawn: 13 330 bank edges, all 1 block high, all 2 deep). So the swimmer sank to the river's bottom (feet 2.0 under the surface) pressed against the bank, where the climb (feet at most 1.85 under) never started, and stayed there pushing. Reproduced on a fake river and on the **real terrain** (seed 42, the river bank nearest the spawn). Also UP next to a bank only bobbed. | A push against a bank never dives: a bank is felt from `SwimRules.BANK_DEPTH` (3) under the surface, and then the look's dive is dropped, so the body floats up to the bank and climbs out whatever the view's tilt. **UP alone** next to a bank climbs it (the bank the view faces, else one right beside the body). **UP + a push** also climbs a wall **2 blocks** above the water. A climb once started finishes (a quick tap of UP is enough); only pushing away drops back. DOWN never climbs. (`SwimRules.climb_out`, `climb_target(…, up, max_depth)`, `Player._swim` / `_climb`) | `tests/integration/test_swim_climb_out.gd` (9, real Player, Jolt): `test_swimming_into_the_bank_with_the_view_tilted_down_still_climbs_out`, `test_looking_straight_down_at_the_bank_climbs_out_too`, `test_up_next_to_a_bank_climbs_out_without_pushing`, `test_up_and_forward_climb_a_wall_two_blocks_above_the_water`, `test_a_real_river_bank_is_climbed_with_the_view_tilted_down` (real terrain), and guards `test_up_in_open_water_only_swims_up`, `test_a_push_alone_never_climbs_a_two_block_wall`, `test_a_wall_three_blocks_above_the_water_is_never_climbed`, `test_down_held_at_the_bank_dives_and_never_climbs`; `tests/unit/test_swim_rules.gd`: `test_up_and_a_push_climb_a_two_block_wall_but_never_a_three_block_one`, `test_a_bank_is_felt_from_the_bottom_of_a_river_but_the_climb_starts_near_the_surface`, `test_climb_out_follows_the_push_or_with_up_alone_the_view_or_any_side` |

**The spear throw from the ATTACK button** (the lead could not see a throw on the emulator): it works
with real touches through the HUD. `test_holding_the_attack_button_and_lifting_the_finger_throws_the_spear`
(a finger held on ATTACK for 0.45 s, then lifted: `spear_throw_requested`, the spear flies) and
`test_a_quick_tap_on_the_attack_button_thrusts_the_spear` passed before any change, so the throw path
itself is sound. What the child sees: the hold must be longer than 0.3 s (`WeaponRules.SPEAR_THROW_HOLD`),
and a thrown spear lies where it lands until its thrower walks up to it (or it comes back by itself after
20 s); while it is out, ATTACK says "Walk to your spear to pick it up!". If the emulator still shows no
throw, check that the spear was the selected slot (before #29 a non-weapon slot did nothing at all).

## Reproductions (before the fixes)

- **#29**: a Player holding planks (the Sandbox hotbar) presses ATTACK next to a level-3 goblin: no
  `attack_requested`, the goblin keeps 14 of 14 HP; on the phone HUD (`hud.setup(p, "Kid", true, …)`)
  `attack_button.visible` is false with planks or the wand in the hand; in Survivor `accept_attack`
  refuses FISTS.
- **#26**: a real Animal (cow) in front of a sword swing keeps its health (only pushed); a chicken is never
  defeated; the herd spawner put a missing id back at the next tick (1 s).
- **#30** (scratch runs, then the tests above): fake river 2 deep with a 1-block bank; pitch −0.35: out in
  about 1 s; pitch −0.7: `(19.70, 22.00)` DIVING for 3 s, against the bank on the river bed. The real
  river at seed 42 (the bank at x 8, z −5): the same, `(7.70, 22.00)`. With the view level both climb.

## Rulings (decided without asking, per the owner's rule 1)

1. **"Best" weapon for ATTACK = the most damage per second** (damage ÷ cooldown), melee only; ties go to
   the first slot. A wooden sword (11.4/s) beats the hammer (5.5/s); a cosmic mace (30/s) beats a wooden
   sword. Bows and boomerangs are never picked by a quick ATTACK (they need aiming). *Cost if wrong:* a
   child with only a bow punches until they select the bow; one line in `WeaponRules.best_melee_slot`.
2. **Fists**: 1 damage, 2.2 m reach, 0.3 s, a little push, one thing per punch, the arm punches forward
   (blocky avatar; the realistic avatar has no arm poses, so only the sound and the hit sparks show).
   `FISTS` is −1: not an item, never in a hotbar, bag or shop, and owned by everybody. A level-1 slime
   takes 4 punches. *Cost if wrong:* numbers in one table row.
3. **Taps are unchanged**: a tap still builds, pets an animal or uses the held weapon where it points; only
   ATTACK (button, R, the left mouse button with a captured mouse) always attacks. A tap on an animal must
   stay petting (taming dogs and cats, treats). *Cost if wrong:* a child tapping a monster with blocks in
   hand places a block; ATTACK is on screen right above JUMP.
4. **ATTACK is always on the phone's HUD** (it was shown only with a weapon selected). *Cost if wrong:*
   one more big button while building; the M2 Task 17 layout already reserved its spot (no overlaps,
   `test_hud_layout.gd`).
5. **Nobody can hurt a tamed pet** — not its owner, the owner's friends, nor any other player in the world
   (the lead offered "its owner and the owner's friends"; everybody in a world is the family's guest, and
   a child losing a pet to another child's sword is the loss §6 forbids). A hit still pushes it. *Cost if
   wrong:* one condition in `AnimalRules.can_be_hurt`.
6. **Golden animals are never hurt** either: they are caught with a tap for their reward; a hit pushes
   them and they flee as before. *Cost if wrong:* a child who hits a golden pig does not defeat it.
7. **Drops (Survivor only, into the defeater's bag, never gold nor anything Tilly buys)**: chicken 1
   Yellow, rabbit 1 Grass, fish 1 Blue, pig 2 Dirt, sheep 2 "wool" (a colour block of its own: red, yellow,
   green, blue or purple, fixed per sheep), cow 1 Bed (craft-like: what wool and hides make in Minecraft),
   dog and cat nothing (they are the pets-to-be; nothing to hunt them for). Nothing is sellable, so herds
   that refill are never a gold farm. The Sandbox drops nothing (blocks are unlimited there). *Cost if
   wrong:* one table (`AnimalRules.DROPS`); when crafting (#34) brings wool and hides, sheep and cows can
   drop those instead.
8. **Health by kind**: 3 / 6 / 9 (a wooden sword: chicken 1 hit, pig 2, cow 3; fists 3 / 6 / 9 punches).
   *Cost if wrong:* one table (`AnimalRules.HEALTH`).
9. **Herds refill after 3 minutes per animal** (`AnimalRules.REFILL_TIME`), counted by the host's clock and
   not saved: a reload refills the world. *Cost if wrong:* one number; a reload brings a hunted herd back
   early.
10. **The hurt "flash" is a squash, white stars and the animal's own voice**, not a colour flash: a new
    flash material would compile its shader on the first hit (the 100+ ms emulator frame M1b fixed); the
    stars use the shared prewarmed `Fx` material. `Animal.hurt_sound()` is the sound hook (the audio pass
    can give each kind a yelp). *Cost if wrong:* a real flash later needs a prewarmed shared material.
11. **The defeat cloud is the monsters' puff** (`MonsterDirector.PUFF_COLOR`, same burst and `poof`
    sound), sent by the CombatDirector (it exists on every peer; an RPC on the animal itself could arrive
    after the host freed it). *Cost if wrong:* none known.
12. **Water: UP + a push climbs a wall 2 blocks above the water** (the lead suggested "≤ 1 block above
    the swimming head"; a lifted swimmer's head top is 0.7 above the water, so that rule would still
    leave a 2-block wall unclimbable, and a child in a dug pool with 2-high walls would be trapped
    without flying). A push alone climbs 1 block, as before; 3 blocks is never climbed. *Cost if wrong:*
    `SwimRules.CLIMB_UP_ROWS`.
13. **A bank is felt 3 blocks down** (`BANK_DEPTH`): a diver pushing into a bank that deep floats up to it
    instead of diving further (DOWN still dives). Deeper divers swim as before. *Cost if wrong:* exploring
    a wall under water while pushing into it rises instead; DOWN still dives.
14. **A climb, once started, finishes**; letting go of the stick no longer drops the swimmer back (M2
    Task 14 did), only pushing away from the bank. A child's quick tap of UP is enough. *Cost if wrong:*
    a child who starts a climb by accident ends on the bank.
15. **UP alone** climbs the bank the view faces, else one within 0.6 of the body's side
    (`CLIMB_REACH_UP`). *Cost if wrong:* UP beside a wall climbs when the child only wanted to bob.

## For the lead: check on the emulator

- **#29**: a new Sandbox world (planks in hand): the ATTACK button shows; ATTACK near a slime punches it
  (the arm punches in blocky style; sparks and the swing sound in realistic style). Put a sword in the
  hotbar, select planks, press ATTACK: the sword comes to hand and swings. Survivor: build with planks,
  then ATTACK at a night monster: the starter sword comes to hand.
- **#26**: Sandbox: hit a cow with the sword three times: it squashes and cries, runs, and puffs away in
  a white cloud (no drop). Survivor: defeat a sheep: a toast "You got 2 …!" and the blocks in the bag;
  no gold. Your pet dog: hit it: pushed, never hurt. A golden animal: pushed, still catchable. Walk back
  to a hunted herd after 3 minutes: it is back.
- **#30**: at the river by the spawn, swim to the bank with the view tilted down (drag the view down):
  the child floats up and climbs out. Tread water beside the bank and tap UP once: out. Dig a pool with
  2-block walls, fill it (or find one): UP + forward climbs out.
- **Spear**: hold ATTACK with the spear selected for about half a second and let go: it flies.

## Files

`core/rules/weapon_rules.gd` (FISTS, `best_melee_slot`, animals damageable), `entities/player/weapon_user.gd`
(`ready_weapon`), `autoloads/session.gd` (`owns_weapon`: fists), `ui/hud/hud.gd` (ATTACK always on touch),
`entities/player/held_item.gd` and `blocky_avatar.gd` (the punch), `core/rules/animal_rules.gd` (health,
drops, guards, refill), `entities/animal/animal.gd` (`hp` synced, `take_hit`, the hurt squash),
`world/combat_director.gd` (animal hits, the puff, drops, `animal_defeated`, the attacker's peer for every
hit), `world/animal_director.gd` (`note_defeated`, refill), `scenes/sandbox.gd` (one connection),
`core/rules/swim_rules.gd` (`climb_out`, `climb_target` up/depth), `entities/player/player.gd` (`_swim`,
`_climb`).

## Merge notes (what may conflict)

- `world/combat_director.gd`: `apply_hit` gained a last parameter `by_peer` (every caller passes it);
  a new section before `_hit_color`.
- `entities/animal/animal.gd`: the sync list (".:hp"), one line in `setup` and `_process`, a new section at
  the end. The audio pass may want `hurt_sound()`.
- `entities/player/player.gd`: the end of `_swim` and all of `_climb`; one new var (`_climb_dir`).
- `ui/hud/hud.gd`: `_update_attack_button` (one line) and its doc comment.
- Tests that encoded the old rulings were updated: `test_weapons_in_world.gd`
  (`test_animals_are_pushed_back`), `test_weapon_rules.gd`
  (`test_players_and_buddies_get_knockback_but_no_damage`), `test_hud_attack_button.gd` (doc only).
