# M1b Task 13: realistic avatar in the realistic style

Owner, 2026-09-24: "consider to make avatar real as well in realistic world". In the REALISTIC style
every player on this device now appears as a real-looking, textured and rigged person. In BLOCKY they
keep the Roblox-style box avatar. Each device shows everyone in its own chosen style.

## Asset chosen: Kenney "Animated Characters 3" (CC0)

- **Model:** `characterMedium.fbx`. One skinned mesh with 1604 triangles, one surface and one material,
  and 58 bones (Mixamo-style names: Hips, Spine, …, RightHand).
- **Clips:** `idle.fbx` (Idle, 1.07 s), `run.fbx` (Run, 0.67 s) and `jump.fbx` (Jump, 0.5 s, a looping
  airborne pose).
- **Skins:** `humanMaleA.png` and `humanFemaleA.png`, both 256². These are painted, "real" faces in a
  t-shirt and jeans or shorts. They are kid-friendly and not uncanny.
- **Source:** the Internet Archive mirror of the CC0 pack,
  <https://archive.org/download/kenney_animated-characters-3/kenney_animated-characters-3.zip>
  (sha256 `6c197462dc9976b522a07d11e0fb42b9caa7cf71d39abbc3ca708b69f13a40dd`). kenney.nl returns 404
  to curl.
  - The same `characterMedium.fbx` and clip files (byte-identical `run.fbx`) ship in Animated
    Characters 1 and 2 on OpenGameArt, which marks both CC0:
    <https://opengameart.org/content/animated-characters>,
    <https://opengameart.org/content/animated-characters-2>.
- **Licence proof:** the pack's own `License.txt` ("License: (Creative Commons Zero, CC0)
  http://creativecommons.org/publicdomain/zero/1.0/") is kept in
  `assets/characters/kenney_human/License.txt`. The archive.org item also lists CC0 1.0 Universal.
  The pack is credited in `assets/CREDITS.md`.

**Candidates rejected**

| Candidate | Why not |
|---|---|
| Quaternius Universal Base Characters | CC0, but the free Standard version has only two unclothed "Superhero" base bodies (not for a kids' game), averages 13k triangles and uses 2K textures plus normal and roughness maps. |
| Quaternius Modular Character Outfits | The Standard version is 280 MB and uses several meshes and materials. |
| Quaternius Universal Animation Library | Animations only (a mannequin); it would need retargeting that can't be checked headless. |
| KayKit characters | Chibi proportions, not human-proportioned. |
| Kenney's other skins | Zombie, survivor (dirty), criminal and cyborg are not kid-friendly or not "real". |

## Files

| File | What |
|---|---|
| `entities/player/avatar_model.gd` | `AvatarModel` interface: `animate(speed, on_floor, delta)`, `play_jump(index)`, `hand()`, `body_pivot()`, `set_pose(&"stand"/&"sleep")`, `pose` |
| `entities/player/blocky_avatar.gd` | `extends AvatarModel`. The appended block holds `hand()` (a "Hand" node at the end of the right arm), `body_pivot()` and `set_pose()` |
| `entities/player/realistic_avatar.gd` | `RealisticAvatar`, plus the pure `animation_for`, `playback_speed` and `skin_for`, and `load_model` |
| `entities/player/player.gd` | `avatar: AvatarModel`; `set_avatar_style(style)` is appended at the end |
| `scenes/sandbox.gd` | One hook in `_ready` (`_players.child_entered_tree`), one call in `_apply_settings`, handlers at the end |
| `assets/characters/kenney_human/*` | FBX files, skins, `.import` settings and the licence |
| `assets/CREDITS.md`, `.gitattributes` (`*.fbx binary`), `docs/DEVELOPMENT.md` (§4 "Player avatars") | Credits and docs |

Import settings:
- The clip FBX files use `importer="animation_library"`, with `settings/loop_mode = 1` on the clip.
- The skins are lossless with mipmaps.
- `characterMedium.fbx` has LODs off and animation import off.

## Tests (TDD: all written first; RED was "Identifier RealisticAvatar not declared")

- `tests/unit/test_avatar_animation.gd`:
  - `test_standing_still_is_idle`
  - `test_slow_is_walk_and_fast_is_run`
  - `test_in_the_air_is_fall_at_any_speed`
  - `test_the_stride_speeds_up_with_speed_and_slows_down_with_size`
  - `test_players_wear_different_skins`
- `tests/integration/test_avatar_models.gd`:
  - `test_both_avatars_implement_the_interface`
  - `test_hand_is_inside_the_avatar_at_the_right_hand`
  - `test_the_hand_follows_size_magic`
  - `test_the_realistic_body_matches_the_blocky_one` (feet at 0, 1.8 tall, toes to -Z, right hand +X)
  - `test_one_skinned_mesh_with_one_textured_material`
  - `test_the_animation_player_has_every_animation_and_it_drives_the_skeleton` (every track resolves
    to a real bone)
  - `test_animate_plays_the_animation_for_the_state`
  - `test_a_jump_plays_jump_until_landing`
  - `test_air_jumps_flip_and_come_back_upright`
  - `test_the_sleep_pose_lies_down_and_stand_gets_up`
- `tests/integration/test_player_avatar_style.gd`:
  - `test_a_player_starts_blocky`
  - `test_the_realistic_style_swaps_in_the_realistic_avatar_and_back`
  - `test_the_same_style_keeps_the_same_model`
  - `test_an_unknown_style_is_blocky`
  - `test_the_swap_keeps_visibility_facing_and_size`
  - `test_a_missing_asset_falls_back_to_the_blocky_avatar`
  - `test_a_realistic_remote_player_runs_with_its_synced_velocity`

The full suite has 297 passing tests with no script errors.

A headless numeric probe (not committed) sampled the animated pose:
- **Idle:** the feet are on the ground (toes at y 0.00), the head top is at 1.71, and the hands hang by
  the hips at x ±0.28, y 0.64.
- **Run:** the feet swing ±0.35 m forward and back, with the opposite arm forward.
- **Fall:** a crouched pose with the arms spread.
- **Hand frame:** −Y runs down the arm and −Z points forward, at the body's scale.

## Decisions (each with its cost if wrong)

1. **Kenney character, not a more detailed human.** It meets every constraint: CC0, one skinned
   mesh, one material, 1.6k triangles and a 256² texture. It is low-poly with painted realistic faces.
   *Cost if wrong:* it may look too "game-like" next to the photo textures. Swapping in another CC0
   character means changing `MODEL_PATH`, `CLIPS` and `SKINS` and re-running the tests (they check
   height, facing and hand side).
2. **Walk plays the run clip at 0.55–1× speed; fall holds the jump pose.** The pack has only idle,
   run and jump. Switching between walk and run (or jump and fall), which share a clip, keeps the
   stride phase.
   - Thresholds: idle below 0.4 m/s; walk from 0.4 to 3.5 m/s (half-tilted stick, wading at 3 m/s);
     run from 3.5 m/s (full stick is 6 m/s). The stride plays at normal speed at 4 m/s for a 1.8 m
     body, clamped to 0.55–2.0×.
   - *Cost if wrong:* a slow walk looks like a slow-motion jog. The fix is a CC0 walk clip, or
     retargeting Quaternius UAL onto this rig later.
3. **Air-time hysteresis.**
   - Going from ground to air takes 0.15 s, so stepping down a block keeps running.
   - Going from air to ground takes 0.06 s, so the one or two "on floor" frames at a remote player's
     jump apex (`|vy| < 0.5`) don't flash the run pose.
   - *Cost if wrong:* the landing pose ends about 4 frames late.
4. **Air jumps flip the whole body forward**, the same tween as the blocky avatar. There is no flip
   clip. *Cost if wrong:* none known.
5. **`hand()` is a node under a BoneAttachment3D on `RightHand`, in the palm.**
   - Its frame matches the blocky hand: −Y runs along the arm to the fingers and −Z points forward
     when the arm hangs.
   - It has the body's scale, so it cancels the rig's 100× unit scale and items grow with Size Magic.
   - *Cost if wrong:* held items may need a small per-avatar offset. The weapons code should attach
     to `avatar.hand()` and not to BlockyAvatar internals.
6. **Skins by peer id.** The host and solo player get `humanMaleA`; the first guest gets
   `humanFemaleA`; other guests get one by peer id parity. *Cost if wrong:* a child may want the other
   look. A later profile setting ("Look: A/B") would be one line in `set_avatar_style`.
7. **`set_pose(&"sleep")` on both avatars.** The body lies on its back, face up, with the head
   towards the avatar's +Z and the back 0.18 above the feet level. The realistic avatar plays idle
   while asleep. *Cost if wrong:* the sleep task may pose the body its own way. Both approaches
   coexist, but only one should be used after the merge.
8. **The asset gate is `ResourceLoader.exists` plus `load()` of the FBX scene.** A broken or missing
   model keeps the blocky avatar. A model without a skinned mesh logs a warning instead of crashing.
9. **The sRGB decode is forced on Compatibility**, the same as the block atlas (lossless PNG import).
   *Cost if wrong:* skin colours look too dark or washed out on the emulator only. See visual check 5.

## Merge notes for the lead

- `blocky_avatar.gd`: the weapons agent also adds held items on the right arm. My block at the end
  adds `var _hand`, `HAND_Y`, `hand()`, `body_pivot()`, `set_pose()` and `SLEEP_PIVOT_Y`. Keep one
  hand node, and mount their item on `hand()`.
- `player.gd`: `avatar` is now typed `AvatarModel`. Code that reaches BlockyAvatar-only members
  through `avatar` needs `avatar.hand()` or a cast. The sleep agent's pose can call
  `avatar.set_pose(AvatarModel.POSE_SLEEP)` / `POSE_STAND`. `set_avatar_style` carries the pose over.
- `sandbox.gd`: one line in `_ready`, one line in `_apply_settings`, and handlers appended at the end.
- `world/animal_director.gd.uid` shows up untracked after an import. It comes from Task 9 and is not
  committed here.

## Visual checks for the lead (editor or emulator; nothing here was seen, only measured)

1. **Walk, run and jump in REALISTIC:**
   - Standing still plays idle.
   - A half-tilted joystick gives a slow jog, and full stick or keyboard gives a run whose feet don't
     skate badly.
   - A jump shows the airborne pose. The 2nd and 3rd jumps do a forward flip and land upright.
   - Stepping down one block doesn't flash the fall pose.
2. **Scale against the blocks:** the person is 1.8 blocks tall, as tall as the blocky avatar and the
   capsule, with the feet on the ground (not sunk in or floating). Check it next to a 2-block wall.
3. **Facing:** the face and toes point where the player walks (−Z), in third person and when turning.
   Also check a remote player on the LAN.
4. **Hand attachment:** once weapons are merged, the held item sits in the right palm, swings with the
   run, and scales with Size Magic (tiny/giant).
5. **Both renderers:**
   - Skin colours are natural on the phone (Mobile/Vulkan) and on the emulator (Compatibility).
   - On Compatibility, if skins look too dark or saturated, drop `albedo_texture_force_srgb` in
     `RealisticAvatar._skin_material`.
6. **Style switch:** Settings → Style swaps every player at once, both ways, keeping the facing,
   Size Magic and first-person hiding (the avatar hides when the camera is inside it).
7. **LAN:** each device shows the others in its own style, and a guest wears the other skin.
8. **FPS:** the REALISTIC autopilot stays within budget. One or four skinned 1.6k-triangle meshes
   should be negligible, but measure on the emulator.
