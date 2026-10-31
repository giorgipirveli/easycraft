# M2 Task 14: Real water — swimming and water effects (owner feedback #17)

Owner, 2026-09-24: "the water in the game should be water, so player should swim not walk like on
ground, this aplies as top also undeground waters", then "add water effects, like swimming, splashing,
and etc". Spec §12.13.

Built in a worktree branch cut from `m2-survive-the-night`, without the editor or the emulator. The
lead still has to check it on the emulator (list at the end).

## What the player gets

- **Swimming in any water deep enough to reach the chest**: sea, rivers, lakes, flooded caves and
  placed water. The player never walks on the bottom. Shallower water (knee-deep) is **waded**: walking
  at half speed, with normal jumps and wet footsteps.
- **Floating**: a swimmer who does nothing rises and floats with the eyes 0.3 blocks above the surface,
  treading water upright. In a cave pool under a roof the head floats in the air pocket. In a fully
  flooded cave the body floats up against the roof, off the floor.
- **Moving**: 3.6 m/s at normal size (walking is 6), gliding (it speeds up and slows down gently).
  Pushing forward swims in the look direction. Looking down (more than 0.5 rad, so the resting
  third-person camera at −0.35 stays level) dives, and looking up rises, but never out of the water.
  JUMP swims up to the surface. It lifts the chest a little, never out of the water. DOWN (the fly
  DOWN button, Q/Shift, or `crouch` once Task 5 adds it) dives. Sideways swimming stays level.
- **Getting out**: at the surface, pushing against a bank whose top is at most 1 block above the water
  climbs out. It climbs up the side, a little above the top, and the push carries the body onto the bank.
  The same climb takes a swimmer onto a shelf under the surface or onto a beach level with the water.
  A 2-block wall is not climbed.
- **Pose, in both styles**: the body tips with the swim direction. It is upright treading water
  (arms sculling out to the sides, legs pedalling), flat along the surface with the head out while
  swimming along (crawl: the arms windmill, the legs flutter), and head first when diving.
- **Effects**:
  - A splash of drops and a ring on the water on the way in. It is bigger, higher and wider the faster
    the body came in: running in gives a small one, a 10 m fall the biggest. A splash sound (big or
    small) is louder for a harder entry.
  - Ripples on the surface around a swimmer (every 0.3 s while moving, every 1.1 s while floating) and
    around a wader who moves.
  - A few drops fly from each swim stroke at the surface, with a quiet stroke sound.
  - Bubbles rise from a diver's head (every 0.45 s), with a bubble sound every third time.
  - Drips fall off the body for 2 s after a swim.
  - Wet footsteps for 6 s after leaving the water, and while wading.
  - Every sound is muffled while the view is under water.
  - Animals that fall or are pushed into water make a small splash. Fish never do.
- **Touch HUD**: while swimming, JUMP reads UP and the DOWN button is shown, as while flying.
- **LAN**: every game shows another player's swim pose and effects.
- **No drowning** (M2 ruling 14).

## How it works

| File | What |
|---|---|
| `core/rules/swim_rules.gd` | `SwimRules` (pure). It has the state (`DRY`, `WADING`, `SWIMMING`, `DIVING` from the water at the feet, chest and eyes) and `surface_y`. Buoyancy is `vertical_target` / `vertical_velocity`: a spring to the float line, JUMP capped at the lift line, and drag on fast bodies. It also has `swim_velocity` / `swim_pitch` (the look direction with dead zones), `climb_target`, `splash_strength`, `swim_pose` and `body_tilt`. Every height scales with Size Magic. |
| `core/rules/swim_effects.gd` | `SwimEffects` (pure, one per body). Fed the state and velocity each frame, it returns `splash` (with a cooldown), `ripple`, `bubbles`, `drips` and `stroke`. It also has `wet_feet()`. |
| `entities/player/player.gd` | `water_state` (decided by the owner's game every physics frame; synced ON_CHANGE, added in code like `held_item`). `_swim`, `_climb` (a ladder-style climb to `_climb_to`), `_show_swim_pose` (on every game; emits `swimming_changed`), `_water_effects` (on every game, from the synced state and velocity). `_in_water` and the old `WaterRules` float are gone; `WATER_SPEED_FACTOR` is now wading. |
| `entities/player/avatar_model.gd` | `POSE_SWIM`, `swim(horizontal, vertical, delta)`, `swim_tilt` and `_tip()`: the shared body tilt and the rise to the surface (`SWIM_PIVOT_Y` 1.2) while flat. |
| `entities/player/blocky_avatar.gd` | `swim()`: the crawl windmill and flutter kick, blended with sculling and pedalling. |
| `entities/player/swim_strokes.gd` | `SwimStrokes`, a `SkeletonModifier3D` on the realistic avatar's skeleton. It turns the upper and lower arm and leg bones from their rest (T-pose) in the body's frame, with the same crawl and tread motions. `influence` fades it in over 0.25 s. It is inactive when not swimming. |
| `entities/player/realistic_avatar.gd` | `swim()`: the tilt, the idle clip underneath, and the strokes. `set_pose` switches the modifier. |
| `entities/fx/fx.gd` | `splash`, `ripple` (one shared 96-triangle torus plus shared curves and gradient), `bubbles` and `drips`, all on the one shared material. `burst` now takes `spread` and returns its node. |
| `autoloads/audio.gd` | The sounds `splash`, `splash_small`, `swim`, `bubbles` and `step_wet`, plus `set_muffled` / `is_muffled` (a low-pass at 900 Hz on the Master bus, added once). |
| `world/ambience.gd`, `core/rules/ambience_rules.gd` | `AmbienceRules.muffled(underwater)` (≥ 0.5). Ambience switches the muffle on a change and switches it off when it leaves the tree. |
| `ui/hud/hud.gd` | `set_swimming` and `_show_up_down` (UP/DOWN for flying or swimming). |
| `entities/animal/animal.gd` | `_check_water` (every game, 10 Hz, one block lookup): a small splash on entering water. |
| `tools/make_water_sfx.py` | Generates the 7 water WAVs (deterministic seed; original work, credited in `assets/CREDITS.md`). |

Numbers, at size 1 (in `SwimRules`):

| Constant | Value | Meaning |
|---|---|---|
| `CHEST` | 1.0 | Swims once water is this high up the body (a giant, 3.0, wades in 3-deep water; a tiny player swims in a puddle) |
| `EYES` | 1.55 | Eyes under water = diving (the same height as the camera) |
| `FLOAT_DEPTH` | 1.25 | Floating: the surface is this far above the feet |
| `LIFT_DEPTH` | 1.1 | JUMP held at the surface: the chest (1.0) stays in the water, so the body never bobs out |
| `SWIM_SPEED`, `SWIM_ACCEL` | 3.6 m/s, 10 m/s² | |
| `FLOAT_UP_SPEED`, `SWIM_UP_SPEED` (WaterRules), `DIVE_SPEED` | 2.0, 3.5, 3.0 m/s | |
| `SPRING`, `VERTICAL_ACCEL`, `DRAG` | 4 /s, 10 m/s², 5 /s | A jump in at 12 m/s sinks under 3 blocks; a 10 m fall (22 m/s) under 5 |
| `LOOK_DEAD_DOWN`, `LOOK_DEAD_UP`, `MAX_SWIM_PITCH` | 0.5, 0.3, 1.25 rad | |
| `CLIMB_SPEED`, `CLIMB_PUSH`, `CLIMB_OVER`, `CLIMB_TIMEOUT` | 4 m/s, 2 m/s, 0.4, 1.5 s | |
| `SPLASH_FULL_SPEED`, `SPLASH_MIN` | 16 m/s, 0.08 | Running in at 6 m/s gives 0.09 (small); slow wading gives none |

## Tests (TDD)

| File | Tests | RED was |
|---|---|---|
| `tests/unit/test_swim_rules.gd` | 24: states (dry, wading, swimming even on the bottom, diving; giant and tiny), the surface scan, floating up from the bottom with the head out, never popping the chest out, a jump in and a 10 m fall stop and float back up, JUMP faster than floating but never out, DOWN dives, speeds scale with size, look direction (the resting camera is level, down dives, up rises, sideways is level, yaw), look up stops at the surface, climbing (a 1-block bank, a shelf, a beach, not a 2-block wall, not without pushing, deep or without head room), splash strength, swim pose, body tilt | `Identifier "SwimRules" not declared` |
| `tests/unit/test_swim_effects.gd` | 8: one splash on the way in (size by speed), no splash wading in slowly, hopping in and out gives one splash (cooldown), ripples faster when moving (none from under water, some while wading, none in a calm puddle), bubbles only while diving, drips once after a swim (not after wading), wet feet, strokes | `Identifier "SwimEffects" not declared` |
| `tests/integration/test_fx.gd` (+5) | Water effects use the one shared material; a harder entry gives more, faster drops and a wider ring (drops fly up, not every way); ripples share one cheap flat ring and curves and spread; bubbles rise; drips follow the body and free themselves | `Static function "splash()" not found in base "Fx"` |
| `tests/unit/test_water_sounds.gd` | 4: sounds registered and loading, the generator and credits, the muffle is a low-pass on Master, `AmbienceRules.muffled` | `Static function "muffled()" not found` |
| `tests/integration/test_ambience.gd` (+1) | The muffle follows the view and ends with the world | (same run) |
| `tests/integration/test_avatar_models.gd` (+5) | Both styles: swimming along lies flat at the surface with arm strokes (the hand travels > 0.6 along the body); treading water is upright with the arms out; diving points the head down; standing again after a swim. Realistic: the strokes move the arm only while swimming | `Cannot find member "POSE_SWIM" in base "AvatarModel"` |
| `tests/integration/test_player_swim.gd` | 12, on a real Player with Jolt physics in a fake pool with collision boxes: an idle swimmer floats with the head out and never stands on the bottom; swim speed at the surface; a look down dives and letting go floats back; DOWN dives and JUMP swims up but not out; pushing against a 1-block bank climbs out (standing at y 14, dry, stand pose, drips); a 2-block wall is not climbed; a cave pool under a roof (head in the air pocket); a flooded cave (floats up off the floor); jumping in splashes (drops and a ring); a diver blows bubbles; knee-deep water is waded at half speed; `water_state` is synced ON_CHANGE with spawn | `Invalid access to property or key 'water_state'`; the old code floated the body at 12.3 and moved at 3.0 m/s |
| `tests/integration/test_remote_player.gd` (+2) | A remote swimmer swims, splashes and drips in this game too; a bad synced `water_state` (a LAN value out of range) is clamped, like the NaN guards there. The clamp's one-line guard was written just before its test | `Invalid assignment of property or key 'water_state'` (checked by running it against the old `player.gd`) |
| `tests/integration/test_hud_swim.gd` | 3: swimming shows UP and DOWN; flying keeps them after a swim; desktop has no touch buttons | `Invalid call. Nonexistent function 'set_swimming' in base 'Control (Hud)'` (checked by running it against the old `hud.gd`) |
| `tests/integration/test_animal.gd` (+2) | An animal that falls into water splashes once; fish never splash | `Cannot find member "WATER_CHECK" in base "Animal"` |

The suite went from 626 to 692 tests, with the existing water tests (`test_water_and_batches`,
`test_water_flow_rules`, `test_ambience*`) unchanged and green.

**Visual check** (desktop window with the Compatibility renderer, a scratch driver, no editor):
both avatars in the crawl (4 phases, from the side and from above), treading water (front, side) and
diving. The bodies lie flat along a see-through plane at the float line with the head out, and the arms
windmill through the crawl cycle. Treading water, they are upright with the arms sculling out and the
head above the plane. Diving, the head points down.

## Rulings (decided without asking, per the owner's rule 1)

1. **Swim when the water reaches the chest (1.0 × size above the feet); shallower water is waded**
   (half speed, normal jumps, wet footsteps). In knee-deep water there is nothing to swim in.
   *Cost if wrong:* the owner may want to swim in 1-deep water. That is one constant (`CHEST`), plus
   the wading tests.
2. **Getting out is a climb on pushing forward against a bank at most 1 block above the water**, not a
   jump: JUMP at the surface only lifts the chest (`LIFT_DEPTH`). Otherwise a body that jumps out and
   falls back bobs in and out of the water, splashing each time. *Cost if wrong:* a child who presses
   JUMP next to a bank without pushing forward stays in the water.
3. **A dead zone for diving by look**: pitch between −0.5 and +0.3 rad swims level, because the
   third-person camera rests at −0.35 (looking down at the player). *Cost if wrong:* diving by look
   needs a clear look down. DOWN always dives.
4. **DOWN is the existing `fly_down` action** (the touch DOWN button is shown while swimming, keyboard
   Q/Shift), plus `crouch` when the input map has it (Task 5 adds it). *Cost if wrong:* none known. If
   Task 5 puts CROUCH where DOWN sits, the lead decides which button shows in water (`Hud._show_up_down`).
5. **The realistic avatar's swim is procedural.** The Kenney pack has only idle, run and jump, with no
   swim clip, and no CC0 swim clip for this rig was found. A `SkeletonModifier3D` (`SwimStrokes`)
   poses the arms and legs over the idle clip, and the body pivot tips like the blocky one. A tilted
   run clip was rejected: the arms never go over the head, so it looks like running lying down.
   Mixamo was rejected: not CC0. *Cost if wrong:* straight-armed, simple strokes rather than mocap
   quality. A real swim clip can replace the modifier later without changing the interface.
6. **The water state is decided by the owner's game and synced** (`water_state`, ON_CHANGE, spawn).
   Pose and effects are derived from it and the synced velocity in every game, so no game needs the
   terrain around a remote player. *Cost if wrong:* one more synced int per player, which changes
   rarely.
7. **Ripples are an opaque shared ring that fades into the water's blue through a colour ramp**, not
   a transparent material. A second material would need its own prewarm, or it compiles on the first
   ripple, which is the 100+ ms frame the project fixed in M1b. *Cost if wrong:* on very dark or very
   light water the ring shows as a faint band before it vanishes.
8. **The muffle is a 900 Hz low-pass on the Master bus while the view is at least half under water**
   (the same camera test as the blue tint). *Cost if wrong:* menu clicks are muffled too while under
   water (the pause menu). Moving the effect to an SFX bus would need a bus layout.
9. **Animals only splash**: they still sink and walk out as before, because the host simulation is
   unchanged. Monsters don't exist on this branch: Task 3's monsters should do what
   `Animal._check_water` does. *Cost if wrong:* an animal pushed into deep water walks on the bottom
   until it gets out.
10. **Flying and ghosts** show no swim pose in water, but the effects still happen (a flyer diving into
    the sea splashes). *Cost if wrong:* none known.
11. **The sounds are generated** (`tools/make_water_sfx.py`: filtered noise and rising-pitch bubble
    tones). None of the Kenney packs used so far has water sounds. Generated sounds are original,
    reproducible and free of licence questions. *Cost if wrong:* they may sound synthetic. The WAVs can
    be swapped for recorded CC0 ones without code changes.
12. **Wading keeps normal jumps.** The old code made any water (at the feet + 0.6) a slow float with
    JUMP rising. *Cost if wrong:* none known.

## For the lead: check on the emulator

- **Both styles, at the default third-person camera:**
  - Swim along the sea (the crawl), stop (treading water, head out), dive with DOWN and by looking
    down, and come up with JUMP.
  - Climb out on a beach and on a 1-block bank.
  - Does the realistic crawl read well at phone size? Do the realistic hands clip the head in the
    crawl? The shots showed no clipping.
- **Effects:**
  - Jump in from a cliff (a big splash with sound), and run in from a beach (a small one).
  - Ripples around a floating swimmer, bubbles under water.
  - Drips and wet steps after climbing out.
  - Sounds are muffled under water and clear again after surfacing and after quitting to the menu.
- **An underground lake or flooded cave:** the swimmer floats in it and never stands on the floor.
- **Performance:** swim for about 30 s in the sea in both styles with the FPS counter (ripples 3/s,
  strokes, bubbles while diving). No frame should go over 100 ms at the first splash, since the
  ring uses the prewarmed material.
- **LAN:** a guest's swimmer shows the pose and splashes on the host.

## Merge notes (what may conflict)

- `entities/player/player.gd`: `_enter_tree` (one call), `_physics_process` (the water state line and
  the `_water_effects` call), `_move_normal` (the start, and the old water block removed), the step
  sound in `_update_avatar`, the avatar branch at the end of `_update_remote`, `set_physics_mode`
  (resets the climb), and a new section at the end.
- `ui/hud/hud.gd`: `_on_physics_mode_changed` now calls `_show_up_down()` (Task 5's CROUCH button
  touches the same place), and a new section at the end.
- `entities/fx/fx.gd`: `burst` gained `spread` (default 180) and returns its node; callers are unchanged.
- `autoloads/audio.gd`: new `SOUNDS` entries after the weapons, and the muffle.
- `entities/animal/animal.gd`: one call at the end of `_process`, and a new section at the end.
