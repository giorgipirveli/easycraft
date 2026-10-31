# VR on the Meta Quest, P0-P1: the VR-RIG side (owner #101)

The owner (2026-10-15): "we have to start in parallel working on VR mode, I have meta quest and we have to adapt the game
for VR, this is now N1 priority". The plan: `docs/superpowers/plans/2026-10-15-vr-quest.md`; the research (the platform,
the adaptation map, comfort, the budget, the split): `docs/devlog/parts/vr-research.md`; the brief:
`docs/superpowers/plans/2026-10-15-vr-agents-brief.md`. This agent is **VR-RIG** (the world side), in its own worktree
(branch `worktree-agent-af972211a2b1e38dd`, started from `lead-merge` bcaa3d89, the lead's contract `29070825`), at the
same time as VR-UI (the panels) and the rocket agent (#98). No editor, no emulator, no adb, no download.

## What was built

| File | What |
|---|---|
| `autoloads/vr.gd` | The body of the lead's frozen `Vr` (the contract's names unchanged; `ui_viewport` / `ui_wants_pointer` left as they were for VR-UI). `start(&"openxr")` (the Quest APK; also by itself at launch when the build has the `quest` feature: `PlatformRules.starts_vr`) and `start(&"webxr")` (the Quest's browser: initialize() from a tap, the session a moment later). `simulate(on)` with fake head and hand trackers on the XRServer. The anchor, the fades, the safety net's blink, the desktop preview, the VR_BENCH lines. |
| `entities/vr/vr_rig.gd` | `VrRig` (XROrigin3D): the head (XRCamera3D, near 0.05, far 300), two hands (XRController3D, pose `aim`), the comfort sphere. The anchor's eye, interpolation between ticks, turning round the head, room scale's bookkeeping, the auto-step's head spring. |
| `entities/vr/vr_comfort.gd` | `VrComfort`: one inside-out sphere on the head, drawn over everything (render priority 100): the vignette, the black fade, a head in a wall, Feel's red tint. Hidden while all are clear. |
| `entities/vr/vr_input.gd` | `VrInput`: the two Touch controllers as one game pad (device 12, "Meta Quest Touch"), snap turn, TAP/HOLD on the trigger, haptics. |
| `entities/vr/vr_hand.gd` | `VrHand`: the pointing hand's laser into the world (a beam to the block the trigger acts on, a dot there). |
| `entities/vr/vr_bench.gd` | `VrBench`: a `VR_BENCH` line every 10 s in a headset session (logcat) and in the preview. |
| `core/vr/vr_rules.gd` | Added below the lead's part: snap and smooth turn, the vignette curve, the head-in-a-wall fade, `turn_about`, `yaw_of` / `pitch_of`, the head's step spring, the fades' steps, the eye height's fade, walking by head or hand, the trigger's hysteresis, the buzzes, the tint's cap. |
| `core/platform/platform_rules.gd` | `QUEST` and `WEBXR` feature tags; `vr_build`, `starts_vr`; a headset build is no touch device, captures no mouse, is not keyboard-first (the 1280 × 720 canvas), never buzzes a phone motor, reads no safe area. |
| `core/platform/gamepad_rules.gd` | The `QUEST` family only: `QUEST_BUTTONS` (each Quest control → the pad input it sends), `QUEST_FLYING`, the words. |
| `core/rules/graphics_preset.gd` | The `vr` preset; `vr_session` (every phone preset reads as `vr` while a session runs); `style_in_use`, `sky_interval`, `mesh_block_size`. |
| `entities/player/player.gd` | `aim_ray(screen_pos)`; the camera only current off VR; the local player anchors the headset at its feet; room scale (`_vr_room_scale`); black during a spawn; no knockback in VR; no Simple-controls follow in VR; the avatar faces the head; `_walk_yaw` (head or hand). |
| `entities/player/camera_rig.gd` | The VR mode: first person, the head's yaw and pitch, no spring arm, no shake, no look, no CAM; a yaw the game writes turns the origin; `snap_to_target` blinks; the eye height for the rig (crouch, size) with a blink on a big change. |
| `entities/player/block_interactor.gd`, `weapon_user.gd`, `gadget_user.gd`, `entities/interactables/secret_taps.gd`, `world/trade_director.gd` | The aim seam: the 24 screen-point ray call sites go through `Player.aim_ray`. |
| `autoloads/feel.gd` | In VR: no shake, `motion_allowed()` false, a buzz is both controllers', the flash a capped red tint. |
| `world/world_service.gd`, `world/sky_cycle.gd` | In a session: the blocky style (glow off), 32-cube terrain meshes, the sky every 2 s. |
| `openxr_action_map.tres`, `tools/vr_action_map.gd` | The OpenXR action map (Godot's default action set; Touch, Touch Plus (both forms), generic and simple controller bindings). |
| `export_presets.cfg` | preset.14 "Quest" and preset.15 "Quest GL" (see "The Quest APK"). |
| `project.godot` | `[xr]`: `openxr/enabled.quest=true`, `shaders/enabled.quest=true`, `openxr/foveation_level=3`, `openxr/foveation_dynamic=true` (phones, the web and the desktop: OpenXR and multiview stay off). |
| `tools/vr_bench.gd` | Green Meadows through the rig on the desktop (the preview), VR_BENCH lines and a summary. |
| Tests | `tests/unit/test_vr_rig_rules.gd` (11), `tests/unit/test_vr_rig_platform.gd` (11), `tests/integration/test_vr_rig_session.gd` (18), `test_vr_rig_player.gd` (15), `test_vr_rig_input.gd` (10): 65 tests; with the lead's contract test, 72. |

## How it works

**The rig.** `Vr` makes the `VrRig` at the start of a session and frees it at the end; it is a child of the autoload, so
it lives across scene changes (`Game.change_scene` frees everything else). `Vr` and the rig run `PROCESS_MODE_ALWAYS`
(a paused tree never freezes the head). The head is the view: `Vr.step` makes it current again whenever another camera
took it (the menu's, a photo's, a rocket's), and the camera that was current before the session comes back after it.

**The anchor.** The origin is placed so the tracked head sits at the anchor's eye: a player's feet plus the avatar's eye
(`CameraRig.HEAD_HEIGHT` × size × crouch: "game height", the plan's default: a seated or a small child sees the world
the phone shows), or (VR COMFORT "real") on the feet; a menu spot or a seat puts the eye on the node. Each physics tick
(`Vr` ticks after the player: `process_physics_priority` 100) records where the origin goes; each drawn frame
interpolates between the last two ticks (the body moves at 60 ticks, a Quest draws 72). Physics stays at 60 (the
research's ruling; 72 ticks cost about 20 % more physics). A recentre (the Quest's own, `Vr.recenter()`) puts the head
over the anchor again and keeps where it faces. A new anchor remembers the one before it: when a friend's showcase
visit ends (its own player is freed), the headset is back at the world's player, behind a blink.

**Turning.** Only round the head (`VrRules.turn_about`): snap 45° (30, or smooth, by the `vr_turn` setting) from the
turning stick; `CameraRig.yaw` writes from the game (a portal's arrival, a world's saved facing) are seen as a change
and turn the origin the same way. At the first VR frame the head turns to where the player was looking (`Vr.face`).

**Room scale.** A child who steps in the room moves the head off the feet: the player's tick walks the body after the
head (`move_and_slide`, so walls still stop it) and the rig takes that step out of its offset, so the view never moves.
A head the body can't follow (leaning into a wall) fades the view to black from 0.25 m to 0.4 m past the body; a head
inside a solid block is black at once (no x-ray through hills, nor into a hiding spot). Only in the plain walking tick:
a rider, a sleeper, a hidden or knocked-out child's body holds still (the offset waits).

**The view never moves by itself** (the plan's ruling 3). No shake (CameraRig and Feel), no knockback on a VR body (the
hit is a buzz and a tint), no mouse, finger or pad look, no Simple-controls follow, no CAM (first person only), the
menu's orbit holds still (Feel.motion_allowed() is false in VR, so every "calm way" branch is taken). Every jump in
place is black: a spawn holds black from `_begin_spawn` until the body stands, then `snap_to_target`'s blink fades in
(0.25 s); a rescue, home, a portal blink; the safety net blinks when the origin would jump more than 2 m in one tick,
and never glides across the jump. A crouch or a size change of the eye height by more than 0.3 m blinks. The auto-step's
hop (7.6 m/s up a block) is eased for the head (a spring of 0.08 s, rises up to 1.2 m, only while walking); a fall is
never eased.

**The comfort vignette** darkens the view's edges with the body's speed (from 1 to 6 m/s; `light` by default, `strong`,
`off`) and fully while turning smoothly. Feel's flash is a red tint over the view capped at alpha 0.25.

**The controllers as a pad.** `VrInput` reads each tracker's inputs (the action map's names first: `primary`,
`primary_click`, `trigger`, `grip_click`, `ax_button`, `by_button`, `menu_button`; WebXR's after: `thumbstick`,
`thumbstick_click`) and sends what the game already knows as the pad input of the one table:

| Quest | Sends | Plays |
|---|---|---|
| walking stick (left; right for a left-handed child) | the left stick's axes | walk |
| turning stick (right) | nothing to the game | snap turn 45° (never the pad's look) |
| A | Cross / A | jump (twice quickly: fly) |
| B | Circle / B (flying, no menu: D-pad down) | crouch (flying: down) |
| X | D-pad right | MORE |
| Y | D-pad left | BLOCKS |
| left / right grip | L1 / R1 | the hotbar's slot before / after |
| menu button (left) | Options / Menu | pause |
| click the walking stick | L3 | size magic |
| click the turning stick | Triangle / Y | walk, fly or ghost |
| the other trigger | Square / X | attack |
| the pointing trigger | nothing to the game | TAP: place, open, talk, use; HOLD 0.25 s: break (the break ring fills) |

Each event goes first into `Vr.ui_viewport()` (when VR-UI has made it; a press a menu there handles never reaches the
world) and then to the game (`Input.parse_input_event`, which moves the actions `Input.get_vector` reads). The pointing
trigger acts in the world only while a player stands there, the laser is not on a panel (`Vr.ui_wants_pointer()`), no
menu has the pad (`PadFocus.menu_has_pad()`) and the game is not paused. A place, a break and a snap turn buzz the hand
(`Vr.haptic`); Feel's vibrate buzzes both. The end of a session lets go of every button and stick.

**The aim seam.** `Player.aim_ray(screen_pos)` is every world tap's ray: off VR the camera's ray through the point,
exactly as before (the reach is measured from its origin, which is the camera's place); in VR the pointing hand's aim
pose (the screen point means nothing there). The 24 call sites (17 in the BlockInteractor, the weapons' aim point, the
hook, the secret taps, the name tags) were replaced one for one; the sandbox's seam already puts the interactor in
crosshair mode in VR. The laser (`VrHand`) shows where the trigger acts.

**The `vr` preset** (the plan's ruling 2: Quest 2 is the floor): LOW's (no shadows, a 64-block view, half the particles,
simple water, no sway, 6 monsters near) with 8 animals near, MSAA 2x, full resolution (OpenXR's render target; `scale_3d`
under 1 would move tonemapping into a later pass), and VR's own keys: no glow, the blocky style, 32-cube terrain meshes,
the sky every 2 s. A real session (and the preview) sets `GraphicsPreset.vr_session` and re-applies the settings, so the
world, the monsters and the animals all read it; the tests' simulated session never does.

**A real session** also turns V-Sync off (the headset paces the frames), asks for the refresh rate nearest 72 Hz, the
CPU and GPU levels sustained-high (OpenXR), foveation (VRS_XR on the Mobile renderer; OpenXR's level 3, dynamic, on
Compatibility), and says `focus_changed(false)` when the Quest's menu opens, the headset comes off or the session stops
(`focus_changed(true)` back). OpenXR and WebXR classes are reached by name only (the web build has no OpenXR classes and
the others no WebXR ones: a typed reference would not parse there).

**Checked in a real renderer** (a 320 × 240 window, 2026-10-15): the comfort sphere's shader compiles and draws in both
the Mobile and the Compatibility renderer (no SHADER ERROR; the same check with a broken shader prints one).

## Rulings (with what they cost if wrong)

1. **The XR camera is always the view in VR**, whatever camera asks (the rocket's, a photo's, the menu's). [P3's seated
   rocket must anchor `&"seat"` instead of making its own camera current; until then a flight shows the player's spot.]
2. **`hand_ray(side)` is the physical hand**; the hand that points is `Vr.pointing_hand()` / `Vr.pointer_ray()` (the
   left-handed setting). [If VR-UI read the contract's "the left-handed setting swaps" as hand_ray(&"right") meaning
   "the pointing hand", a left-handed child's UI laser comes from the other hand: one line in VR-UI.]
3. **Buttons stay where Quest prints them** for a left-handed child (A, B on the right; X, Y on the left); only the
   sticks and the triggers swap. [A left-handed child may want jump on the left: a later setting.]
4. **Physics stays at 60 ticks**; the origin is interpolated. [A judder on the headset: `physics_ticks_per_second.quest=72`
   in project.godot, about +20 % physics.]
5. **The auto-step and jumps are eased for the head while walking** (0.08 s spring, rises up to 1.2 m). [The head lags a
   jump by up to 0.7 m at its fastest; if it feels floaty, ease only rises under 1.1 m that last under 0.2 s.]
6. **A head inside a solid block, or 0.4 m past where the body could go, is black** (from 0.25 m it fades). [A child
   leaning to look at a wall sees it fade: raise HEAD_FADE_FROM.]
7. **The snap turn is instant**, no blink (the common comfort choice). [A child feels it: a 0.1 s blink in `VrInput._turn`.]
8. **The two Quest presets share the package** `com.giorgi.easycraft.quest` (and the name EasyCraft: every Android preset
   is called EasyCraft, `test_identity_words`); installing one replaces the other for the renderer A/B. [Two packages if
   the owner wants both in the library at once: `com.giorgi.easycraft.quest.gl`.]
9. **A simulated session never changes the graphics** (only a real one and the preview set `vr_session`), so the suite
   stays what it was. [None.]
10. **No hand-made Meta manifest** (the `com.oculus.intent.category.VR` category, `com.oculus.supportedDevices`,
    focus-aware): those come with the Godot OpenXR Vendors plugin, a download that waits for the owner's yes (ruling 5).
    Godot core writes the Khronos `IMMERSIVE_HMD` category and the head-tracking feature itself. [If the Quest opens a
    Khronos-only APK as a flat window, the vendors plugin is needed before the first headset run, or a 20-line
    EditorExportPlugin of our own that adds the three Meta entries for the `quest` feature.]
11. **`Feel.motion_allowed()` is false in VR**, so every place that asks takes its calm way (the menu still, no camera
    bob, softer captions). [Something that only animates when motion is allowed looks still in VR: by design.]
12. **The fake pad is device 12** ("Meta Quest Touch"; Godot knows 16 pads, real ones count up from 0). [A 13th real pad
    would share its number: never on a Quest.]

## The Quest APK

`build/android/EasyCraft-quest.apk` from preset "Quest" (Gradle, OpenXR, arm64 only, min SDK 32, target SDK 34, package
`com.giorgi.easycraft.quest`, the Mobile renderer, feature tag `quest`); "Quest GL" is its twin with
`command_line/extra_args="--rendering-method gl_compatibility"` (`build/android/EasyCraft-quest-gl.apk`).

**It could not be built here without a download.** The build got to Gradle's dependency check with everything else
from this PC's Gradle cache, and stopped at the one thing the cache does not have: Godot 4.7.2's OpenXR export adds the
Khronos loader, `org.khronos.openxr:openxr_loader_for_android:1.1.54` (Maven Central, Apache-2.0, the loader Godot's
docs mean by "the Khronos loader Godot adds by itself"; the research's 1.1.53 is the template's config, the export asks
for 1.1.54). The build ran in a network-less namespace on purpose, so nothing was fetched. **Request for the lead:** the
owner's yes for that one Maven download (Gradle fetches it by itself on the first online export; about 2 MB), then:
```bash
JAVA_HOME=$HOME/.local/jdk17 ANDROID_HOME=$HOME/android-sdk nice godot --headless --path . \
  --install-android-build-template --export-debug "Quest" build/android/EasyCraft-quest.apk
```
**The rest of the pipeline is proven, and the size:** the same preset with XR mode off (a one-off, the presets file put
back after) built offline from the cache: a debug APK of **178.8 MB** (178,804,025 bytes; package
`com.giorgi.easycraft.quest` 1.0.4 code 14, minSdk 32, targetSdk 34, arm64-v8a only: `libgodot_android.so` 76 MB, the
debug `libvoxel.android.editor.arm64.so` 9 MB). The OpenXR APK adds the loader's `libopenxr_loader.so` (a few MB). That
stand-in APK was deleted (it would run flat on a Quest). `android/build/` (the Gradle template) is installed in this
worktree (git-ignored).

## Seams for the lead (lead's files)

- `project.godot`: the `[xr]` section above (4 lines), nothing else; the autoload is the lead's.
- `export_presets.cfg`: preset.14 and preset.15 appended (VR-UI appends preset.16 "Web VR": the same place, a merge to
  join by hand).
- `scenes/sandbox.gd`, `scenes/main.gd`: **no change needed** from this side. Wanted when the lead has a moment, one
  line each:
  - the pause menu on focus loss: `Vr.focus_changed.connect(func(f: bool) -> void: if not f and not pause_menu.visible: pause_menu.open())`
    in the sandbox's `_ready` (the Quest's menu button opens the system menu: the game should pause behind it).
  - nothing else: the HUD layer and the crosshair seams are the lead's contract lines already.
- `tests/unit/test_shader_warmup_sources.gd`: two COVERED lines (`entities/vr/vr_comfort.gd`, `vr_hand.gd`); VR-UI's
  panel materials will want lines in the same list (a merge to join by hand).
- `addons/easycraft_webview/plugin.gd` adds the Theater's WebView AAR to every Gradle Android build, the Quest's too
  (harmless: VR-UI's TV sign shows instead); leave it out for the `quest` feature when convenient.

## Added to the contract (names noted for the lead; the frozen ones are unchanged)

`Vr.rig`, `Vr.input`, `Vr.hand`, `Vr.bench`; `pointing_hand()`, `pointer_ray()`, `head_transform()`, `turn(radians)`,
`face(yaw)`, `recenter()`, `blink()`, `fade_amount()`, `tint(color)`, `vignette_amount()`, `set_head_blocked(amount)`,
`haptic(side, amplitude, seconds)`, `setting(key)`, `local_player()`, `anchor_node()`, `stop()`, `step(delta)` /
`step_physics()` (tests), `preview(on)`, `sim_head` / `sim_hand` / `sim_input` (tests), `haptics` (a count), constants
`SIM`, `PREVIEW`, `PREVIEW_ARG`, `REFRESH_RATE`. `VrInput.DEVICE`, `VrInput.JOY_NAME`, `VrInput.read(side, control)`.

## For VR-UI (the same session; nothing of theirs was edited)

- **Draw panels over the fade:** `VrComfort` draws at render priority 100 without depth test; the eye panel, the
  loading room and the loading card need priority 127 without depth test to show over a black fade (a spawn holds black
  until the child stands).
- **The trigger for the UI laser:** `VrInput.read(side, "trigger")` (0..1, or a bool on WebXR's `trigger_click`), or
  the tracker directly. The world's trigger already waits while `Vr.ui_wants_pointer()` is true, and the world laser
  (`VrHand`) hides then, so VR-UI's beam is the only one on a panel.
- **Pad events go into `Vr.ui_viewport()` first** (`push_input`): PadFocus there sees A, B, the D-pad (X and Y are D-pad
  right and left), the grips (L1/R1) and the walking stick; a press it handles is not passed to the world.
- **The CONTROLLER card's words:** `GamepadRules.family(VrInput.JOY_NAME)` is `QUEST`, but PadFocus asks
  `Input.get_joy_name(device)`, which is empty for the fake pad. One line in `PadFocus._set_pad` / `_input`:
  `set_pad_name(VrInput.JOY_NAME if device == VrInput.DEVICE else Input.get_joy_name(device))`. Then `button_word` /
  `axis_word` give "A", "Y", "Menu button", "Trigger (tap)", "Trigger (hold)", "Turning stick".
- `hand_ray(side)` is the physical hand; the pointing one is `Vr.pointing_hand()` (ruling 2).
- The menu: anchor the origin with `Vr.anchor(spot, &"menu")` (the eye on the spot, facing its way).

## What only the headset can check, and how the lead checks it

On the owner's Quest (adb with the Quest's own serial on port 5038; never emulator-5556):
1. The APK starts immersive (ruling 10). If it opens as a flat window: the vendors plugin.
2. Head tracking at the headset's rate; `adb logcat -s godot:V | grep VR_BENCH` every 10 s: Green Meadows blocky,
   fps ≥ 72, over28=0 after the first 5 s, draws ≤ 150 (P1's acceptance). Both APKs (Quest, Quest GL), the model recorded.
3. The controllers bind (the action map's Touch / Touch Plus profiles; `VrInput` reads `primary`, `trigger`, ...): walk
   100 m with the left stick, snap-turn round with the right, A jumps, B crouches, the grips step the hotbar, Y opens the
   blocks, X opens MORE, the menu button pauses.
4. The laser: 10 blocks broken (HOLD, the ring fills), 10 placed (TAP), a buzz each.
5. Comfort: no camera move the child did not make; a spawn and a respawn fade from black; leaning into a wall fades;
   the vignette while walking; standing on a ledge's auto-step feels soft. Game height: the eye at the avatar's height
   seated and standing.
6. The Quest's own recenter (hold the Meta button) puts the view back over the feet.
7. WebXR: the same in the Quest's browser at `/vr/` (VR-UI's export), its stick's y sign (WebXR's `thumbstick`
   is assumed up-positive like OpenXR's: if walking goes backwards, flip it in `VrInput.step`), and whether its
   menu button reaches the game at all (UNCONFIRMED: pause from the tray's button otherwise).

## The desktop preview and the bench

`godot --path . -- --vr-preview`: the session runs on fake trackers and the window shows the head's view, flat. Click
the world (the mouse is captured as usual) and the mouse turns the head; Q and E snap-turn; the game's keys walk; the
mouse buttons place and break along the fake right hand (it points where the head looks). The `vr` preset is on.
`tools/vr_bench.gd` (a window; see DEVELOPMENT.md) starts Green Meadows that way and prints VR_BENCH lines.
`--flat` runs the same without the rig, for a comparison.

**Measured 2026-10-15 (this PC):** headless (`--headless`, no draws: the flow only) the whole run works: the preview
starts, Green Meadows loads, the child stands, the origin turns 90° twice, the lines print (`process_ms` 1.2-2.1, the
`vr` preset on). Windowed (`--resolution 1440x1584 --rendering-method mobile`, one eye of a Quest 2 at full render scale)
the desktop drew only about one frame a second **with the rig and without it alike** (`--flat`: 7.5 "fps" from the engine's
capped delta, `process_ms` 991, a frame a second of wall time): the compositor did not present the window (a locked or
hidden screen), so the draw counts it printed (168-249 at the spawn, five frames after the load) are of a half-meshed
world and say nothing yet. The lead runs it again with the window in front, before the first headset run; the Quest's
own VR_BENCH lines are the real ones.

## The full suite of round 1 (2026-10-15)

The lead found the three failures that run reported (`test_girl_avatars`, `test_m3_review_plurals`, `test_short_quality`)
were the rocket agent's: both agents wrote the same scratch log name in the shared scratchpad, so that log mixed two
runs. From round 2 this side's logs are named `vrrig_*` (the full suite: `vrrig_full.log`). The shader warm-up list's two
lines were this side's and stay.

# Round 2: P3 on the rig side (owner #101; the lead's brief of 2026-10-15 evening)

Same branch, on top of P0-P1 (accepted by the lead). Asked: the teleport, the vignette for rides and gadgets, knockback
0 and the eased head (both done in P1), a guest's mount predicted, the rocket in VR, PHOTO as a held camera, Size Magic
through `world_scale`, the knock-out's dim and the sleep fade.

## What was built (P3)

| File | What |
|---|---|
| `core/vr/teleport_rules.gd` | `TeleportRules` (pure): the arc (thrown at 7 m/s, gravity 9.8, a point every 0.04 s), where it first lands on a block's top, and `check`: 1-6 m from the feet, at most 1 block up, solid under the feet, room for the body (StepRules, the size's clearance), never on or into a hiding spot, in sight of the eyes, a game's `refuse(at)` last. Reasons: NOWHERE, NEAR, FAR, UP, STAND, ROOM, SPOT, SIGHT, AREA. |
| `entities/vr/vr_teleport.gd` | `VrTeleport`: the turning stick pushed away aims (past 0.7; back under 0.3 goes); the arc's dots (one MultiMesh: one draw) and a ring, green where the child may go, grey where not; let go: `Player.vr_teleport` (black 0.15 s, the body moved, the snap's 0.25 s fade in). |
| `core/vr/vr_rules.gd` | `vignette_motion` (speed; falls from 4 m/s; for motion the child did not make its acceleration from 1 m/s², ×1.5), `ease_vignette` (closes in 0.08 s, opens in 0.4 s), `teleport_step`, `turn_toward` (the seat's cap), `alpha_beta` (the guest's mount); SEAT_TURN_DEGREES 15, KNOCKOUT_DIM 0.6, SLEEP_FADE 1 s. |
| `entities/vr/vr_rig.gd` | Seats (`place_seat`, `recenter_seat`, `turn_in_seat`: the seat's whole transform is the child's frame), `predict` (the mount's place through the filter), `eye_override` (a hiding spot), the origin's `velocity` and `accel`, `head_local()` (read from the tracker: a new world scale counts at once). |
| `entities/vr/vr_comfort.gd` | `dim` (the knock-out's). |
| `autoloads/vr.gd` | `sit(seat)`, `release(node)`, `seated()`, `follow_now()`, `freeze(on)`, `snap_origin()`, `set_dim`, `set_world_scale` (1 again at the end), `hold_fade`, `trigger(side)`, `view_like(camera)` / `view_default()`, the motion vignette, the mount's prediction while this game's child rides as a guest, `teleport`; anchors followed only while inside the tree (VR-UI's note about a scene change's frame). |
| `entities/vr/vr_input.gd` | The turning stick's push away feeds the teleport (no snap turn while it is up); seated, the pointing trigger is the pad's right trigger (the throttle) instead of TAP/HOLD. |
| `entities/vr/vr_capsule.gd` | `VrCapsule`: a dark round room (radius 1.25 m) round the seated child, a window ahead with a warm rim (its shader cuts it out), and the `Dashboard` node. |
| `entities/flight/rocket_flight.gd` | In VR: `VrSeat` (the inside camera's place, a seat each in a crew flight) with the capsule on it; `Vr.sit` at the start (a fade cut, never the boarding's glide); INSIDE only (VIEW does nothing); the seat's turn follows the steering at most 15°/s, never the scripted look_pitch nor the shake; the head draws the flight camera's layers, space's sky and far plane, the world again after; the last step's fade held on the head; `_info().vr`; the cockpit's own layer through `UiLayers.route`; `vr_dashboard()`. |
| `entities/flight/flight_shots.gd` | `vr_pose`: no shake, the flash halved, the clouds' white-out at 0.6, no look_pitch. |
| `entities/vr/vr_photo_camera.gd`, `ui/photo/photo_mode.gd` | PHOTO in VR: `VrPhotoCamera` in the pointing hand (a SubViewport over the same world, 800 × 600, a Camera3D on the hand's aim, a 24 × 18 cm screen above the hand facing the eyes); a new squeeze of the trigger takes the picture from it; the filter and the frame drawn into its viewport; the avatar on `SELF_LAYER` (1 << 17) and the head without it while open (a selfie, never from inside the head); a team photo's view for the lens. |
| `entities/player/player.gd` | `vr_passive_motion()`, `vr_may_teleport()`, `vr_teleport(at)`, `vr_teleport_refuse`, the knock-out's dim, `_vr_sleep_fade`, the pad's throw counted 1.5 s. |
| `entities/player/camera_rig.gd` | Size Magic → `Vr.set_world_scale` (also at the first VR frame); a hiding spot's peek → `eye_override` (a blink in and out, never black inside). |
| Tests | `tests/unit/test_vr_rig_p3_rules.gd` (11), `tests/integration/test_vr_rig_p3_player.gd` (10), `test_vr_rig_rocket.gd` (7), `test_vr_rig_photo.gd` (7): 35 more. Three behaviours broken on purpose (the sleep's freeze, the knock-out's dim, the seat's cap) made three tests fail. The capsule's shader compiles and draws in both renderers (a 320 × 240 window). |

## How it works (P3)

**Teleport.** Push the turning stick away: dots arc from the pointing hand and fall; where they first touch a block's top
a ring shows, green where the child may go. Let go: black (0.15 s), the body is there, the view fades in (0.25 s). A spot
is good when walking could have got there: ground with room for the body at the child's size, a block up at most (no wall
climbing), 6 m at most (no gaps), 1 m at least, in sight of the eyes, never on a barrel or into a closet, never where a
game refuses (`Player.vr_teleport_refuse`: nobody sets it yet). Only while walking in the world (never riding, asleep,
knocked out, hidden, gliding or hooked) and while VR COMFORT's teleport is on. The stick pushed up never snap-turns.

**The vignette** reads the origin's own speed and acceleration (the child's steps in the room never move the origin):
walking by stick darkens with speed as in P1; a fall faster than 4 m/s darkens it fully by 12 m/s; motion the child did
not make (`vr_passive_motion`: a buddy, the dragon or any flyer, a horse, the glider, the hook's pull, a zipline, zero-G,
a pad's throw, a kite) adds its acceleration and is half again as strong. It closes in 0.08 s and opens in 0.4 s.

**A guest's mount.** On a guest the mount's place arrives 10-20 times a second (RemoteSmoother shows it between the
syncs, a little behind); while this game's child rides there, the origin follows it through an alpha-beta filter (it
learns the mount's speed: a steady ride has no lag, and the place glides between syncs instead of stepping). The host's
ride is simulated where the child is: nothing changes there.

**Knock-out and sleep.** A knock-out dims the view to 40 % (the HELP UP words are VR-UI's panel); the head stays at the
eye's height, never laid down. Falling asleep the origin holds where the child stood while the view fades to black over a
second (the body goes onto the bed behind it), then waits at the bed; waking, the body steps off the bed behind the black
and the view fades back in over a second. Never lying flat.

**Size Magic** is the play space's scale (`world_scale` = SizeMagic's 0.25 / 1 / 3): a giant's real step moves 3 m and
its eyes are 3× apart (the world looks small), behind a blink, the head back over the feet at the giant's eye height; a
child already giant when the headset starts gets it at the first VR frame; 1 again at the end of the session.

**A hiding spot** puts the eye inside it (the barrel's inside as a little cockpit, looking out), behind a blink in and out.

**The rocket.** The child sits in the capsule from the first frame (a fade cut; the flat boarding glide never plays in
VR). The seat is the inside camera's place (a seat each in a crew flight); its frame turns with the child's steering and
the drift at most 15° a second, never with the scripted look_pitch, never shakes; the head looks round freely. Round
them, `VrCapsule`: dark walls, a window ahead, a warm rim, a still frame while space streams past. The head draws what
the flight's camera would (the rocket's body hidden inside, space's black sky and stars, the far plane of 100 km) and the
world again after. Seated, the pointing trigger is the throttle (`rocket_throttle`), the walking stick steers
(`rocket_steer_*`), A is the action. The last step's fade darkens the head too; the new world's spawn holds black until
the child stands.

**The dashboard's anchor (agreed in both notes):** `RocketFlight/VrSeat/VrCapsule/Dashboard` (`RocketFlight.vr_dashboard()`,
null off VR): 0.55 m ahead of the eyes and 0.32 m below them, tilted 35° to face them; its +Z faces the child, so a
QuadMesh child at its origin is the dashboard's screen. VR-UI's FlightCockpit in its dashboard mode puts its quad there.

**PHOTO** in VR is a camera in the pointing hand: its screen above the hand shows what it sees (with the filter and the
frame); a new squeeze of the trigger takes the picture (a squeeze held when PHOTO opened never shoots); the head is the
view all along (no orbit). The avatar is on its own layer while PHOTO is open: the held camera sees it (a selfie), the
head never does. The buttons stay on VR-UI's panel. A team photo after a boss puts the lens at the line-up's view.

## Rulings (P3, with what they cost if wrong)

13. **The arc is thrown at 7 m/s** (a natural throw lands 4-6 m away; higher goes past 6 m and turns grey). [Children aim
    badly: 8 m/s, or a longer arc on flat ground only.]
14. **The teleport goes 1-6 m**, a block up at most, in sight. [A ledge walking reaches is refused: MAX_UP 1.2.]
15. **Teleport only while walking**, and games may refuse it (`vr_teleport_refuse`; nobody does yet). [Survivor races
    skipped by teleports until the directors set it.]
16. **The vignette counts the origin's motion**, not the body's, and a ride's acceleration only when the child did not
    make it. [A ride feels fine and the vignette annoys: lower VIGNETTE_PASSIVE.]
17. **The guest's mount is filtered, not simulated** (alpha 0.3, beta 0.04). [A guest's ride still judders: run the
    mount's RideRules locally from the child's own stick.]
18. **The seated frame turns with the steering at 15°/s at most**, never with the scripted look_pitch or the rocket's
    pitch-over (the flat inside camera never followed those either). [The child misses the lean: let the frame lean too,
    still capped.]
19. **The capsule is a dark sphere with a window**, no modelled cockpit (no new art, no download). [Plain: a modelled
    interior later, CC0 or our own.]
20. **PHOTO's selfie layer is 1 << 17** (free; the flight uses 1 << 18 and 1 << 19). [A future use of it: pick another.]
21. **A knock-out dims to 40 %; sleep fades over 1 s each way.** [Too dark or too slow: KNOCKOUT_DIM, SLEEP_FADE.]
22. **Size Magic scales the play space by the size** (3: a giant), the research's open question settled by Godot's
    docs ("the scale of the game world compared to the real world"). [The other way round on the headset:
    `set_world_scale(1.0 / s)`, one line.]

## Seams for the lead (round 2)

- `tests/unit/test_shader_warmup_sources.gd`: three more COVERED lines (`vr_teleport.gd`, `vr_capsule.gd`,
  `vr_photo_camera.gd`).
- `Player.vr_teleport_refuse` for directors that should refuse a teleport (CourseDirector, races, the Gold Farm's
  games): `player.vr_teleport_refuse = func(at: Vector3) -> bool: return <inside my area>`.
- Nothing in `scenes/sandbox.gd`, `scenes/main.gd` or `project.godot` this round.

## Added names (round 2, for the lead to freeze)

`Vr.sit`, `release`, `seated`, `follow_now`, `freeze`, `frozen`, `snap_origin`, `set_dim`, `set_world_scale`,
`world_scale`, `hold_fade`, `trigger(side) -> float` (VR-UI proposed a bool `trigger(side)` with the same rule: the lead
picks one), `view_like`, `view_default`, `teleport`; `VrRig.SEAT`, `place_seat`, `recenter_seat`, `turn_in_seat`,
`predict`, `eye_override`, `velocity`, `accel`, `head_local`; `RocketFlight.vr_dashboard()`; `PhotoMode.held_camera()`;
`Player.vr_passive_motion`, `vr_may_teleport`, `vr_teleport`, `vr_teleport_refuse`; `VrPhotoCamera.SELF_LAYER`.

## For VR-UI (round 2)

- **The dashboard quad:** a child of `RocketFlight.vr_dashboard()` (the path above), facing +Z, on the flight's
  `RocketFlight.LAYER` (1 << 19) so the head sees it in space too (the head draws the flight camera's layers then). The
  capsule is depth-tested at the default priority; the quad (0.55 m away) is inside it.
- PHOTO's buttons stay in the routed PhotoMode Control; its filter and frame Controls move into the held camera's
  SubViewport while it is open, and back on close.
- Seated, the pointing trigger is the pad's right trigger (`rocket_throttle`), never TAP/HOLD.

## What only the headset can check (P3), and how the lead checks it

1. **Teleport** on Green Meadows: the dots fall from the hand, the ring green on open ground, grey on a 2-block wall, on a
   barrel, past 6 m; let go: a short black and there (ruling 13: the children's aim).
2. **A Moon flight seated**, LIFT-OFF to landing: the window ahead, no shake, the steering's turns gentle, the flash and
   the clouds softer; the right trigger holds the throttle, A stages and puts the legs out; `VR_BENCH` in the capsule
   (72 FPS is P3's acceptance); the destination comes up from black.
3. **Rides:** a flying buddy and a horse: the vignette darkens as the ride speeds up; as a LAN or online guest the ride
   glides (ruling 17).
4. **Size Magic:** GIANT and TINY: the world small, then huge, behind a blink; which way round (ruling 22).
5. **PHOTO:** the held camera's screen readable in the hand; the gallery's picture is the held camera's (filters,
   frames); a selfie shows the avatar.
6. **Knock-out, sleep, hiding:** the dim, the slow black and back, the barrel's inside looking out.

## Not done here (next)

- 3D danger arrows and sound captions (VR-UI's HUD files) and the cockpit's dashboard mode (VR-UI's FlightCockpit).
- P4: hands in the avatar's colours, the held item on the hand, swings, `vr_pose` for friends.
- P5: VR_BENCH in every world, the CPU caps, `vr_plus` for Quest 3, Space Warp (the vendors plugin).
- The Meta manifest entries (ruling 10) and the Khronos loader download (round 1).

# Round 3: P4 on the rig side (owner #101; the lead's brief after round 2's merge, cc821392)

Started with `git merge lead-merge` (313abc17: VR-UI's P1, both P3s, the lead's focus → pause in
`ui/menus/pause_menu.gd`). Asked: hands in the avatar's colours with grip and point poses, the held item on the hand,
opt-in swing attacks from the hand (off by default), the bow drawn with two hands, `vr_pose` replicated (head and two
hands, about 30 bytes, 20 Hz) with remote VR bodies and a VR mark on the name tag, an optional mirror,
`Player.vr_teleport_refuse` where a teleport could skip a rule, the net test with a VR side; and the frozen
`Vr.trigger_pressed(side) -> bool` (done first: VrRules.trigger_down per hand).

## The multiplayer files this round touches

Listed before the field was added (the lead's rule) as a synced Player property; the old-peer net test then broke it
(below), so it is an RPC on a child node instead. As built:

- `entities/vr/vr_pose_link.gd` (new): `VrPoseLink`, a child "VrPoseLink" of every Player on every game, its authority
  the player's peer. A game that shows the player calls `_listen` on the player's own game once (reliable); that game
  sends `_pose(bytes)` to those who asked (unreliable ordered), 20 times a second while the pose changes and a keepalive
  each second; the headset off is one 0 byte (an empty PackedByteArray arrived as no argument at all: "expected 1
  argument(s), but called with 0"). Listeners that left are dropped; more than 64 bytes are ignored.
- `entities/player/player.gd`: `vr_pose` is a plain variable (never in the SceneReplicationConfig), written by the
  player's own game while in VR (`Vr.pose_bytes`); `_add_vr_pose_link()` adds the link on every game's copy;
  `--vr-old-peer` (`Player.OLD_PEER_ARG`) leaves it out (a build from before P4, for the net test).
- `entities/player/name_tag.gd`: reads `vr_pose` (non-empty: the VR mark); nothing sent.
- `tools/net_test.gd`, `tools/net_test.sh`: `--vr=host|guest` (that game in the preview with `--vr-wave`; the other
  must decode its pose and show its VR body) and `--old=host|guest` (that game without the link: it plays as before
  and never hears a pose).
- Not touched: the Player's SceneReplicationConfig and every `_sync_*`, `net/session.gd`, `net/remote_smoother.gd`
  (the pose is eased by VrBody itself), `core/net/sync_pace.gd`, `net/nakama_link.gd` (the relay carries the RPCs as
  it carries every other), the spawner (`scenes/sandbox.gd`).

**Why not the sync (the finding):** with `vr_pose` appended last to the Player's sync config, the `--old` run failed:
every packet the older game sent the newer one was refused ("Invalid packet received. Size too small"), so an older
build's players froze on the newer game. A synchronizer's packet has to match its config on both sides; appending is
not safe. With the RPC an older game (no link) gets one "node not found" error when a newer one first asks, and nothing
after (nobody sends it a pose, since it never asks). The four LAN runs pass: `--vr=host`, `--vr=guest`, `--vr=host
--old=guest`, `--vr=guest --old=host`; a VR player adds about 200-400 B/s to each game that shows it.

## What was built (P4)

| File | What |
|---|---|
| `core/vr/vr_pose_rules.gd` | `VrPoseRules` (pure): the head (Euler int8s, its place ±0.5 m) and both hands (place ±1.27 m, a quaternion's x/y/z, grip and trigger 4 bits each) in 21 bytes, VERSION 1, in the body's space divided by the size (a giant fits); empty, short or another version decodes to `{}`. |
| `entities/vr/vr_pose_link.gd` | `VrPoseLink` (above). |
| `entities/vr/vr_hand_model.gd` | `VrHandModel`: a mitten in the avatar's colours (blocky boxes or the realistic person's rounded), a cuff in the sleeve's colour; the grip curls a fist, the trigger the index finger (the grip alone points); `item_anchor()` for held items. |
| `entities/vr/vr_body.gd`, `vr_body_modifier.gd` | `VrBody`: another player in a headset as this game shows it: the avatar's head turned, two hands floating where the controllers are, the arms folded (blocky: hidden; realistic: `VrBodyModifier` scales the upper arms to nothing), eased (14/s); gone when the pose stops. In the mirror the child's own avatar gets one with no hands (the rig's hands are seen). |
| `entities/vr/vr_mirror.gd` | `VrMirror`: a framed glass 1.6 m ahead, world-fixed; a camera on the eye mirrored through the glass with an off-axis frustum exactly the glass, the picture flipped by the glass's UVs. |
| `autoloads/vr.gd` | `trigger_pressed(side)` (the lead's frozen name), `hand_grip`, `item_anchor(item)`, `pose_bytes(player)`, `show_self(on, who)` / `self_seen()` (the selfie and the mirror share `SELF_LAYER`), `set_mirror` / `toggle_mirror` / `mirror_shown`, the hands each frame, `--vr-wave` (the preview nods and waves). |
| `entities/vr/vr_input.gd` | Each hand's press; a bow in the other hand drawn with two hands; opt-in swings. |
| `core/vr/vr_rules.gd` | `SWING` ("vr_swing", off by default), `SWING_FROM` 2.2 m/s, `SWING_REST` 1 m/s, `swing_step`; `BOW_GRAB` 0.22 m, `BOW_NOCK` 0.12 m, `BOW_FULL_DRAW` 0.6 m, `bow_grabs`, `bow_power`. |
| `entities/player/player.gd` | `vr_pose`, the link, the VR body, the held item on the VR hand (a remote VR player's in its right hand), `TELEPORT_RULES` and `vr_teleport_refused(at)`. |
| `entities/player/blocky_avatar.gd`, `name_tag.gd` | `arms()`; `NameTag.vr_marked` ("  [VR]" after the name). |
| `world/course_director.gd`, `world/games/games_director.gd` | `refuses_teleport`: while this child races; while a round runs. |
| `ui/photo/photo_mode.gd` | The selfie through `Vr.show_self(on, &"photo")`. |
| Tests | `tests/unit/test_vr_rig_pose_rules.gd` (7), `tests/integration/test_vr_rig_p4.gd` (10), the press in `test_vr_rig_input.gd`; after the stop: `test_vr_rig_link.gd` (7), `test_vr_rig_mirror.gd` (4). |

## How it works (P4)

**Hands.** The child sees two hands in its avatar's colours on the controllers (a fist on the grip, the index finger
curled by the trigger, a point with the grip alone). What it holds hangs on the pointing hand; a bow hangs in the other
hand and is drawn with two: squeeze the trigger with the pointing hand near the bow (22 cm) to take the string, pull back
(full power at 60 cm) and let go to shoot along the string; a squeeze away from the bow is the trigger's usual tap.
**Swings** attack only when VR COMFORT's swing setting is on (real walls and furniture round an excited child): the
pointing hand faster than 2.2 m/s (in the play space: walking never counts) attacks once with the melee weapon ready,
again after slowing under 1 m/s; WeaponUser's cooldown and the host's reach decide, as for the ATTACK button.

**Friends.** A VR player's head and hands go to the games that show it (VrPoseLink); there its head nods and looks round,
its hands float and wave where its controllers are, its arms fold away, its name tag says "[VR]", and what it holds is
in its right hand. Taking the headset off sends "no pose": its body is the usual one again.

**The mirror** (optional; `Vr.toggle_mirror()`, nobody calls it yet): a framed glass 1.6 m ahead where the child looks;
the child's avatar shows only in it (never from inside the head), its head turning as the child's does.

**Teleports refused** while this child races (CourseDirector) and while a Gold Farm game's round runs (GamesDirector):
the ring is grey there.

## Rulings (P4, with what they cost if wrong)

23. **The pose goes by RPC to the games that ask**, never the Player's sync (the finding above). [A game that missed its
    one reliable ask never shows the VR body: ask again when the pose is empty for long.]
24. **21 bytes, int8s** (the head's place to 4 mm, the hands' to 1 cm and their turn to about 1°), 20 a second. [Hands
    that judder in a friend's game: 16 bits for the hands, 27 bytes.]
25. **Swings are off by default.** [Children miss hitting by swinging: on by default with a strong guardian warning.]
26. **The bow takes two hands in VR**; a tap away from the bow still shoots at the laser's point. [Too hard for small
    children: one-handed draw on the trigger's hold.]
27. **The mirror is optional and world-fixed** (no button of its own yet). [Nobody finds it: a MIRROR button on VR
    COMFORT or the pause menu (VR-UI).]

## Round 3, after the stop (2026-10-16, owner #108 "continue and finish vr")

Started with `git merge lead-merge` (754331e9: the accounts #104/#105, the Moon landing #106, release 1.0.5; the only
conflict was `tools/net_test.sh`'s arguments: both sides' kept). The lead's list: VrPoseLink in the notes and
DEVELOPMENT.md, its tests and the mirror's, the mutation check of the P4 tests; and new: **the Moon descent (#106) in
VR**, flown by the child, and a crash's way home with fade cuts and never a shake.

**The descent in VR** (`tests/integration/test_vr_rig_descent.gd`, 11 tests, the whole trip a frame at a time, the
controllers only): the trigger through VrInput, the Input map and the cockpit (never the cockpit's throttle set by
hand). A child who squeezes all the way while it falls faster than a safe glide (1 m/s at the ground) and lets go
otherwise lands the Moon descent at 0.98 m/s with 11.7 of its 20 s of fuel left, in 16.5 s; nobody squeezing crashes
(no autopilot in VR either); A is GO on the first try's card; the whole trip (lift-off, burns, stages by A, the
descent) lands by the controllers alone. A simulation of the descent's own sums (the Moon, Mars, the lowest pull; the
easy first try too) for children who react 0-0.5 s late: the trigger as it was (climbing to full at 4/s) and an instant
one both land them on every world with a safe glide; so the change below is for the feel, not because it could not land.

**What changed:**
- **The trigger is the lever** (`FlightCockpit.analog_throttle`, set by RocketFlight in VR): the throttle is as far as
  the trigger is squeezed (past its 0.2 dead zone), at once; squeezed less or let go, it falls back at the lever's
  spring (3/s). The phone's lever works the same way; off VR keys and pads climb to full as before.
- **A crash never tips the seated child:** `FlightShots.vr_pose` zeroes `tilt` (the lander's tip moved the seat up to
  half a metre a frame sideways; from inside nothing else of the tip shows). The touchdown, the crash and the rocket
  hitting the ground buzz both hands (`VrRules.HAPTIC_TOUCHDOWN`, `HAPTIC_CRASH`, `HAPTIC_WRECK`).
- **The way home is fade cuts, never one long black** (it was 8.2 s of black: the jump to the rocket's fall, then WRECK
  and HOME held black; the research's rule is never black for more than about 3 s). Now, in VR: the crash dims to black
  (as before), the capsule heading home fades in and is seen from the seat (the Earth growing ahead, the fact read
  aloud), it dips to black at its end (the rocket turns round at once there: the seat jumped 12.9 m), the re-entry fades
  in (the heat's glow, no shake) and dips at its end, and the parachute, the rocket's fall and HOME are watched from a
  still spot on the ground by the pad (`RocketFlight._vr_spot`: where the flat game's still shot looks from, 1.6 m over
  the ground, level, facing the pad; the capsule's round room not drawn there, its dashboard's words still ahead). Seen
  from there the capsule comes down within 23° of ahead and the rocket falls within 28°. The longest black is 0.17 s;
  the way home takes as long as the flat one. Every step of it is seen (over 90 % clear at some point).
- **The clouds' thickest dips to black** (`VR_CLOUD_DARK` 0.75 of the white-out up): the world and the space set change
  places there; the flat game hides it in a full white-out, VR's white-out is 0.6 (photosensitivity), so the head saw
  the change (a 59.7 km jump of the seat's place) through it. Now it is black at that frame and fades back as the cloud
  thins.
- **A practice's next try is a dip to black** (the lander back at the top is a jump): black over the 1.5 s on the ground,
  then in.
- **The climb goes on at the lift-off's speed** (`FlightShots.ASCENT_CARRY`): the lift-off ends at 13.3 m/s and the
  climb used to start from standing (40 m, then speeding up again): a seated head felt it stop dead. The flat game's
  climb is the same height at the same times, only smoother at its start.
- `tests/integration/test_landing_flight.gd`'s VR test (the lead's) now asks for fade cuts (no black over 3 s, the
  parachute and the fall seen) instead of a black way home.

**Not changed, for the lead:** (1) where two flight steps meet, the run starts the next step at its 0 and drops the
frame's leftover time, so the rocket stalls for one frame (0.44 m at the climb's start at 30 frames a second, also in
the flat game): carrying the leftover over in `FlightRun.tick` would smooth every step change. (2) The descent's GREEN
ends at exactly the crash speed (3 m/s at the ground): a child who only keeps the dial green touches down at about
3.0 m/s and crashes about half the time (the simulation: 0-0.3 s late, on the Moon 0 of 3 to 2 of 3 land, on every
world). The green line ending at 2.5 m/s lands nearly all of them and keeps `test_the_colours_say_what_to_do`; that is
#106's own rule, on every platform, so it is not changed here.

**The mutation check** (the P4 code came before its tests; and this round's fixes): 30 behaviours broken one at a time
(a script in the session's scratchpad: apply, run the test file, put it back). Each made its tests fail but three: the
round's teleport refusal (GamesDirector) had no test with a round on (now it has: hide and seek's seeking and counting,
and that mutation fails it), the clouds' dip (the trip's test looked for jumps only on frames with something near in
view, and the jump into space is the frame after the world: now either frame counts, and it fails), and the parachute's
own cut-in, which the clouds' dip covers too (the capsule comes down out of the cloud: both hold the black).
Broken and caught: the pose's ask once, its 20 a second, the keepalive, the 0 byte for "no pose", the 64-byte limit,
dropping a listener that left; the mirror's off-axis frustum, its mirrored eye, its flip, the eye behind the glass;
swings off by default and once a swing, the bow's grab and power, the pose's nod, VERSION and clamp, the arms folded,
the VR mark, the race's refusal, the selfie's layer; the crash's tip, the clouds' dip, the analog lever, the spot, the
practice's dip, the climb's speed, the crash's buzz.

**Seams (round 3, the lead's files):** `core/save/profile_data.gd` (`VrRules.SWING` in the default settings) and
`core/save/profile_backup.gd` (in `DEVICE_ONLY_SETTINGS`: a phone's backup never turns a headset's swings on or off);
`tests/unit/test_shader_warmup_sources.gd` (a COVERED line for `vr_mirror.gd`); `ui/flight/flight_cockpit.gd`
(`analog_throttle`, one branch); `tests/integration/test_landing_flight.gd` (the VR way-home test, above). Nobody calls
`Vr.toggle_mirror()` yet: a MIRROR button for VR-UI (ruling 27). VR-UI's dashboard quad is not under
`vr_dashboard()` in lead-merge yet; the spot by the pad keeps the Dashboard node ahead of the eyes for it.

**The full suite of round 3** (2026-10-16, `vrrig3_full.log`, 3,749 s): 10,152 tests, 10,147 passing, 3 failing, 12
risky/pending (the Nakama scripts skipped: no local server). The three were P4's, from before the stop, and are
fixed: `vr_swing` was in `VrRules.DEFAULTS` but not in the profile's defaults nor the device-only list
(`test_vr_ui_screens.gd`, two), and the mirror's material was not in the warm-up census' COVERED list. Their files
pass again alone (`test_vr_ui_screens` 9, `test_shader_warmup_sources` 3, `test_profile_data` 19,
`test_profile_backup` 23, `test_profile_sync` 14, `test_settings_panel` 10, `test_vr_rig_p4` 10).

**Owner stop of 2026-10-15 22:25** ("stop all works"): round 3 resumed from the WIP commit 56bf7ea3 on 2026-10-16.
