# VR on the Meta Quest, P5: 72 Hz everywhere, then what the Quest 3 adds (owner #101, #108)

The owner (2026-10-16 08:56, #108): "i have quest 3. download and make it rady" / "continue and finish vr". The brief:
`docs/superpowers/plans/2026-10-16-vr-p5-brief.md`; the plan `docs/superpowers/plans/2026-10-15-vr-quest.md` (rulings 1-7);
the research `docs/devlog/parts/vr-research.md` ("P5: Performance to 72 Hz everywhere"). This agent is **P5** (the
performance side), in the worktree branch `worktree-agent-a650850a8952691a1`, cut from `lead-merge` at `040a0be9`, while
VR-RIG (round 3, P4) and VR-UI (round 2, P2) finished their own. No editor, no emulator, no adb, no download.

## In short

- **Where the 230 draws came from:** not the world. Through the rig, every world's *scene* was 16-37 draws a frame (VR-RIG's
  32-cube terrain blocks, no shadows, view 64). The rest was the **HUD's canvas**: in VR it is drawn every frame into the
  tray's texture (VR-UI's `VrCanvas`, a 1280 × 720 SubViewport), and Godot 4's canvas renderer draws every polygon, circle
  and line of a picture drawn in code as a draw call of its own (only rects and text batch). The hearts row alone was 60
  draws, each HUD picture button 7-11, the hotbar 22, the coin 6, the stealth eye 9: **133 canvas draws in Green Meadows,
  152 on the cosmos worlds, 156 in world 41.** (The lead's 230 on Monado also had the desktop's HUD: 198 canvas draws; the
  bench now plays the Quest APK's platform, 165.)
- **The HUD cut:** in a headset session those pictures are one triangle list each (`CanvasBatch`): the canvas is now
  22 draws on the ladder's worlds, 23-39 on the cosmos worlds, 37 in world 41 (from 133-156).
- **The stutter:** a 32-cube terrain block's collision shape is built on the main thread in one go, 30-50 ms on this
  desktop for every block streaming in (at the landing, walking, flying). **Ruling P5-1: 16-cube blocks again in VR** (the
  phones'): walking 40 s has 1-8 frames of 32-38 ms left (31, up to 80 ms, before), standing none. It gives the terrain its draws back (+40-50 in a world
  of trees), which the HUD cut pays for.
- **The result:** every world 69-103 draws a frame on average, 126 at the most (the budget: 100; 150 at the heaviest
  landings, logged: Green Meadows 103, its Launch Site 100, Frostpeak's 126 at the most), ≤ 210K triangles (the Launch
  Site; 750K allowed). Standing, no frame of the game's own over 28 ms; walking a few of 32-38 ms (31 up to 80 ms with
  32-cube blocks); flying more (a lever: a 3 ms voxel budget, the lead's setting).
- **`vr_plus`** for the owner's Quest 3: 90 Hz with one step down when the frames keep missing it, an 80-block view (96
  drew 213), sun shadows to 24 m, MSAA 4x, the child's style (REALISTIC allowed, never glow); picked at the first start on
  a Quest 3 / 3S (a Quest 2 keeps `vr`), VR and VR PLUS on the settings page in a headset. Every real session prints
  `VR_BENCH device model=… preset=… refresh_hz=… offered=…` in logcat.
- Also: labels drawn over everything end at 32 m in VR (the research's P5 row), at most 16 particle bursts live in VR;
  SpaceWarp evaluated and left off; the browser's `/vr/` needs a multiview warm-up inside the session (the lead's).
  The bench measures any world, the menu, the Launch Site, a walk, a FLY cruise, splits the draws into the scene's and
  the canvases', says where they come from (`--blame`) and what each long frame spent its time on (`--long`).

## How it was measured

`tools/vr_bench.gd` (DEVELOPMENT.md §4 "The bench", §7 "VR on the Quest"): the desktop preview (`Vr.preview`: the rig on
fake trackers, `GraphicsPreset.vr_session`, the `vr` preset), a NEW Sandbox world of each world (seed 12345), the child
standing at the landing for 5 s, then 20 s with four snap turns of 90° (every way from the landing), a VR_BENCH line a
second and a summary; one process per world, a private user folder with a copy of this PC's profile (`graphics: medium`,
which a session reads as `vr`). 1440 × 1584 (a Quest 2 eye at full scale), the Mobile renderer, Xwayland without V-Sync
(the screen was locked: Wayland stops presenting a hidden window and draws once a second; Xwayland does not). **The
preview plays the Quest APK's platform** (`PlatformRules.simulated`: no touch HUD, the phone's 1280 × 720 canvas, no KEYS
card): the HUD the headset shows. The summary splits each frame's draws by viewport: `draws_3d` (every viewport's scene and
shadow draws) and `draws_2d` (the canvases': the VR canvas with the HUD); `--blame` hides each part of the scene (and of
the VR canvas) in turn and prints what that saves.

- **Draws and primitives** are the renderer's own counts: this PC's load does not change them (one eye's: multiview
  submits each draw once for both eyes, so a headset's count is about the same).
- **Frame times are this PC's** (an Intel iGPU, a shared i9 with other agents' suites: the load average beside each run,
  3-15 on 24 cores), never a Quest's; `cpu_ms` is the main thread's own CPU per frame (/proc), robust to the load. They
  say *what* is slow, not how slow a Quest is.
- "Before" ran from a copy of `040a0be9` (only the bench's new options added), the later runs from this branch, all on the
  same day: `/tmp/vrp5-base` and the worktree; the final run with a Quest-like voxel pool (`--voxel-threads=4`; the draws
  do not depend on it). Logs: the session scratchpad's `vrp5_before_*.log`, `vrp5_after_*.log` (the HUD cut, 32-cube
  blocks), `vrp5_after3_*.log` (final), the experiments' `vrp5_exp*`, `vrp5_pv_*`, `vrp5_wl_*`, `vrp5_mv_*`.
- **A quiet PC never came:** the load average was 3-35 on 24 cores all session (other agents' suites; the other app). The
  quietest windows (load 3-5, the cosmos worlds of the HUD-cut run) had no frame over 28 ms; every long frame is split by
  the main thread's own CPU (the game's) against its wait for a CPU (the PC's), which needs no quiet PC.

## Where the draws came from

The 3D side was never the problem: `--blame` in Green Meadows (30 scene draws) finds the animals (6: two meshes each), the
insects (2), the ambient life (1), the laser (1), and the rest is the terrain (32-cube blocks: a block is a draw per
material, opaque and cut-out) and the sky. World 41's square has 49 Label3D but 2 of them drawn (their own ranges); the
Launch Site's tower, Mission Control and board are one mesh. No shadow pass (`vr` has none).

The VR canvas (`Vr/VrUi/VrCanvas`) was 133 draws in Green Meadows, by `--blame`: **HeartsBar 60**, the Hotbar 20 (ten
slots, a frame and an icon texture each), the ChatPanel's button 11, three HUD TouchButtons 7, 9 and 9, StealthMeter 9,
GoldCounter 8 (its CoinIcon 6). In space +19: the space HUD's own +6 and the PlanetGuideCard 12 (its ReadAloud speaker 5).
Godot 4's canvas renderer batches rects and text of one texture; each `draw_colored_polygon`, `draw_circle`,
`draw_polyline` / `draw_arc` (an antialiased line is a polygon with its feather) is its own draw. On a phone the same HUD
costs the same draws, but there it is drawn into the screen once a frame among 33 ms; in a headset it is a separate
1280 × 720 render target every frame, and the budget is about 100 for everything at 72 Hz.

## The cuts (each VR-only, each with its test)

1. **`CanvasBatch`** (`ui/controls/canvas_batch.gd`, new): the CanvasItem drawing calls (`draw_colored_polygon`,
   `draw_circle`, `draw_line`, `draw_polyline`, `draw_arc`, `draw_rect`, `draw_set_transform`) into one triangle list with
   a colour per vertex, drawn by `flush` as one `RenderingServer.canvas_item_add_triangle_array`. Concave polygons are
   triangulated (`Geometry2D.triangulate_polygon`), circles are fans (a segment per 2.5 px of rim), lines are strips
   with Godot's own averaged-normal joints and, antialiased, a 1 px feather from the colour to clear. Tests:
   `tests/unit/test_vr_perf_canvas_batch.gd` (8).
2. **The HUD's drawn pictures through it in a real session** (`GraphicsPreset.vr_session`: a headset or the preview, never a
   test's simulated session, never a phone), each a few lines marked "P5" in VR-UI's area, because these four widgets were
   100 of the 133 canvas draws:
   - `ui/hud/hearts_bar.gd` (60 → 1): one heart's parts drawn once into a CanvasBatch and kept (`_vr`), the row's
     triangles fixed; a redraw (every frame while the hearts pulse) only moves and colours the cached heart ten times with
     native calls (`Transform2D * PackedVector2Array`, `PackedColorArray.fill`). `vr_mesh()` is the row's list (tests).
   - `ui/controls/touch_button.gd` (7-11 → 3 a picture button): the round frame and HudIcons' picture in one batch
     (`_draw_vr`), the word as before; only a plain TouchButton with a `symbol` (a subclass with its own picture, the emote
     button, and the hotbar's texture slots draw as before).
   - `ui/hud/hud_icons.gd`: `draw_into(batch, …)` beside `draw(ci, …)`; its `_Pen` takes an Object (a CanvasItem or a
     batch: the same calls).
   - `ui/hud/coin_icon.gd` (6 → 1), `ui/hud/stealth_meter.gd` (9 → 3: its eye; `draw_eye` takes an Object).
   Tests: `tests/integration/test_vr_perf_hud.gd` (7: the hearts' colours in their places, hollow and half hearts, one draw
   in VR and the phone's path off VR, every HudIcons symbol into a batch, the emote button and a hotbar slot unchanged).
   **Pictures:** the VR canvas before and after (`vr_bench --shot`, Green Meadows and the Moon; the session scratchpad's
   `vrp5_shots/`) look the same to the eye: the same hearts, eye, coin, buttons and hotbar.
   **Result:** the canvas 133 → 39 (Green Meadows), 152 → 58 (the cosmos), 156 → 62 (world 41); the frame's draws 165 →
   70, 173 → 79 (the Moon), 179 → 86 (world 41).
3. **Labels drawn over everything end at 32 m in VR** (`WorldService.VR_LABEL_FAR`; `world/world_service.gd`): while a
   world lives in a session, every `Label3D` with `no_depth_test` (a trader's sign, quest bubbles, the robot's mark: seen
   over the hills) gets `visibility_range_end` 32 (a nearer range stays), found once and as they are added (deferred: makers
   often set `no_depth_test` after `add_child`). Not a draw cut (labels cost at most 2 draws anywhere measured): the
   research's P5 row, the two eyes' depth fighting the hill in front. Test: `tests/integration/test_vr_perf_labels.gd` (3).
4. **At most 16 particle bursts alive in VR** (`Fx.max_live()`, the VR presets' `fx_live`; 32 off VR): each burst is a
   draw, and a night's defeats or a boss's fireworks were dozens. Test: `tests/integration/test_vr_perf_fx.gd` (2).
5. **The hotbar's frames in one draw, the read-aloud speaker in one** (`ui/hud/hotbar.gd`, `ui/controls/touch_button.gd`,
   `ui/progress/read_aloud.gd`, `CanvasBatch.draw_rounded_box`), after ruling P5-1 below gave the terrain its draws back:
   the Hotbar was the canvas's biggest part (ten slots and the palette button, a StyleBoxFlat frame and a picture each, 22
   draws); in a session the row draws every slot's frame in one batch under the slots (`TouchButton.frame_mesh`: the same
   colours and the slot's faded alpha, each look's triangles built once and kept; the slots skip theirs,
   `frame_drawn_by_parent`) and redraws on a press, a refresh and a layout: a redraw is 0.07 ms here (1 ms before the
   cache; the hearts row 0.05 ms, a picture button 0.18 ms, only when pressed). The speaker (on the PlanetGuideCard and
   every panel that reads aloud) drew a box, a cone and two waves: one batch. Tests: `test_vr_perf_hud.gd` (+3),
   `test_vr_perf_canvas_batch.gd` (+1).
6. **The menu's backdrop keeps 32-cube blocks in VR** (`GraphicsPreset.mesh_block_size(backdrop)`, `WorldService.setup`: a
   world without a save folder that is not a guest's, in the game only the menu's): ruling P5-1's 16-cube blocks made its
   96-block view 191 scene draws (209 in all); nothing walks there and its viewer builds no collisions (M7), so the
   stutter never comes. The menu: 70 draws before, 69 after (51 the backdrop and the title diorama, 18 the panel). Test:
   `test_vr_perf_world.gd` (+1).
7. **Not changed, measured:** the sky (re-tinted every 2 s; no draw of its own in the counts), the crowd caps (6 monsters,
   8 animals near: the animals are 6 draws at a landing), props as MultiMesh (no prop group costs more than 2 draws), the
   Launch Site (one mesh).

## The numbers, world by world (draws a frame: the average of 20 s, the most in brackets)

Standing at each world's landing (a NEW Sandbox world, seed 12345), four snap turns; "before" is `040a0be9`; "HUD cut" the
batched pictures with VR-RIG's 32-cube blocks; "final" this branch (16-cube blocks again, ruling P5-1, and every HUD cut).
| World | draws before (most) | HUD cut, 32-cube blocks | **final** (16-cube blocks) | final scene / canvas | final primitives (most) |
|---|---|---|---|---|---|
| Green Meadows | 165 (169) | 70 (75) | **103 (105)** | 81 / 22 | 157509 |
| Sandstorm Desert | 158 (163) | 64 (69) | **89 (101)** | 67 / 22 | 43515 |
| Frostpeak | 160 (166) | 66 (72) | **98 (126)** | 73 / 22 | 140207 |
| Candy Kingdom | 157 (165) | 63 (71) | **86 (107)** | 65 / 22 | 58941 |
| Dragon Realm | 162 (170) | 68 (76) | **90 (107)** | 68 / 22 | 75067 |
| The Moon | 173 (177) | 79 (83) | **82 (92)** | 42 / 39 | 32789 |
| Planet Boing | 155 (187) | 63 (93) | **69 (106)** | 47 / 23 | 38166 |
| Rainbow Planet | 157 (169) | 62 (75) | **71 (85)** | 48 / 23 | 28679 |
| Mars | 172 (192) | 78 (98) | **75 (94)** | 35 / 39 | 37532 |
| Europa | 170 (182) | 76 (88) | **74 (85)** | 35 / 39 | 30669 |
| Io | 171 (176) | 76 (82) | **87 (97)** | 47 / 39 | 26861 |
| Titan | 168 (174) | 74 (80) | **77 (83)** | 37 / 39 | 25290 |
| Mercury | 168 (170) | 74 (76) | **72 (77)** | 33 / 39 | 23769 |
| Venus | 174 (191) | 80 (97) | **86 (105)** | 46 / 39 | 37396 |
| Saturn's Rings | 175 (182) | 81 (88) | **80 (89)** | 40 / 39 | 30053 |
| Pluto | 168 (176) | 74 (82) | **77 (86)** | 37 / 39 | 23609 |
| Triton | 169 (176) | 75 (83) | **72 (79)** | 32 / 39 | 23283 |
| Ganymede | 169 (177) | 75 (83) | **71 (80)** | 31 / 39 | 23957 |
| Wonders (41) | 179 (184) | 86 (90) | **89 (93)** | 52 / 37 | 42623 |
| GM, FLY cruise | 139 (153) | 45 (59) | **38 (69)** | 16 / 22 | 114415 |
| Launch Site (GM) | 163 (170) | 69 (75) | **100 (115)** | 77 / 22 | 208701 |

## Long frames (over 28 ms after the spawn fade)

`--long` prints every frame over 28 ms in a measured window with the main thread's own CPU and run-queue time in it
(/proc), the voxel queue, the terrain's statistics and tools/frame_blame.gd's breakdown. On this shared PC most long
frames are **the PC's**: the main thread *waited* for a CPU (run queue 20-90 ms while other agents' suites ran, load
average 15-30). Counted as **the game's own** are those with 28 ms or more of main-thread CPU. With a Quest-like voxel pool
(`--voxel-threads=4`: Voxel Tools' ratio 0.5 of a Quest's 8 cores; this PC's default 12 slows the main thread's engine
calls, DEVELOPMENT.md §7) and 32-cube blocks:

| Run | the game's own long frames | worst (main-thread CPU) | what |
|---|---|---|---|
| Frostpeak, standing 20 s after the 5 s settle | 17-35 | 52 ms | all `VoxelEngineUpdater`, 31-37 ms each, in the window's first 1.5 s |
| Green Meadows, walking 40 s (56 m) | 31 | 80 ms | all `VoxelEngineUpdater` |
| Green Meadows, a FLY cruise 60 s | 200 | 155 ms | 76 `VoxelEngineUpdater`; the rest every script slowed at once while the terrain generates |
| Green Meadows, world 41, the rings, the Launch Site, standing | 0 | - | - |

`VoxelEngineUpdater` is Voxel Tools' main-thread step: it applies each block meshed on a worker, and **a block's collision
shape is built there in one go** (Jolt builds the triangle mesh's tree). Four experiments on copies of the project (logs
`vrp5_exp*`, `vrp5_wl_*`, `vrp5_mv_*`), Frostpeak standing and Green Meadows walking:

| Copy | the game's own long frames (Frostpeak / GM walking) | draws (GM walking: average, most) |
|---|---|---|
| 32-cube blocks (as VR-RIG set them) | 17 / 31 | 68, 85 |
| no terrain collisions (a test only: the child falls) | 1 / - | - |
| `voxel/threads/main/time_budget_ms` 3 (from 8) | 19 / - | - (one block's task is over any budget) |
| **16-cube blocks** | **0 / 1 (32 ms)** | **120, 142** (walking Frostpeak: 121, 166) |
| 32-cube blocks, physics on its own thread (`physics/3d/run_on_separate_thread`) | - / 0 | 69, 85 |

**Ruling (P5-1): the headset streams 16-cube blocks again** (the `vr` and `vr_plus` presets' `mesh_block` 16, Voxel Tools'
own and the phones'): a 32-cube block's collision is eight 16-cube blocks' in one frame, 30-50 ms on this desktop's main
thread for every block streaming in (several times that on a Quest's), at the spawn, walking and flying, felt by every
child in a headset; split eightfold it stays under the budget. It costs the terrain draws the 32-cube blocks had saved: +40-50
in a world of trees, which the HUD's cut more than pays for (the table above). [If wrong: a Quest that draws 120 is slower
than one that stutters; the physics thread below keeps 32-cube blocks without the stutter.]
**The physics thread** moved every collision build off the main thread with 32-cube blocks (0 long frames walking, the
32-cube draws), but it is the lead's project setting and it restricts the physics API to the physics step:
`BlockInteractor` and `SecretTaps` call `direct_space_state.intersect_ray` from taps (`_input`/`_process`), which a separate
physics thread refuses. A lever for later: those queries move into `_physics_process` (VR-RIG's files), then
`physics/3d/run_on_separate_thread.quest=true` and `mesh_block` 32 again (-45 draws), measured on the headset.

What is left after the cut: walking 40 s (the final run, a busy PC), Green Meadows 5 own frames over 28 ms (36 ms at the
worst; 1-2 in the earlier runs), Frostpeak 8 (38 ms), every one the updater applying several 16-cube blocks in a frame;
standing, none in any world. Walking draws 102 on average in Green Meadows (124 at the most), Frostpeak 101 (147). **Flying** (FLY, 11 m/s, a new row of blocks every 1.5 s) still makes the updater's
frames long: a 60 s cruise over Green Meadows, 57 own frames over 28 ms (59 ms at the worst; 200 and 155 ms with 32-cube
blocks). With `voxel/threads/main/time_budget_ms` 3 (Voxel Tools' default 8) the same cruise had 20 (50 ms): a lever for
the lead's `project.godot` (`voxel/threads/main/time_budget_ms.quest=3`), measured on the headset first, since a smaller
budget applies fewer blocks a frame (the land ahead fills in later on a slower CPU). The cruise's "everything slower at
once" frames (32-cube blocks) are the terrain generating on 4 threads beside the main thread (memory and engine locks
shared): this desktop only says it happens, the headset says how much.

**Behind a fade:** the spawn already is (the body stands in black, `Player._begin_spawn`, until the ground under it is
meshed). Nothing else needed a fade once the collision builds were split.

**Application SpaceWarp (ruling P5-2): evaluated, off, a fallback only.** The vendors plugin 5.1.0 has it
(`xr/openxr/extensions/meta/application_space_warp`, `OpenXRFbSpaceWarpExtension.set_space_warp_enabled`,
`skip_space_warp_frame` on a cut; Mobile renderer, motion vectors; 5.0.1 fixed its crash on Godot 4.7). It renders at half
the rate and makes up every other frame from motion vectors: smeared edges on the HUD's tray and the panels' words
(children read them), on particles and on the fades. Our long frames were main-thread spikes, which half-rate rendering
does not hide; the draws fit. Turn it on only if the headset's VR_BENCH lines show `gpu_ms` over the frame after these cuts
in a world that cannot be cut further (the lead's project setting and a `skip_space_warp_frame()` in `Vr.blink`).
[If wrong: a GPU-bound world judders on Quest 2 until it is turned on.]

## `vr_plus` for the owner's Quest 3

- **The preset** (`GraphicsPreset.PRESETS.vr_plus`): 90 Hz, an 80-block view, sun shadows to 24 m, MSAA 4x, the child's own
  style (REALISTIC allowed; glow never: not stereo-safe, and it turns 4.7's subsampled foveation off), the rest as `vr`
  (simple water, half the particles, 6 monsters and 8 animals near, 16 bursts, 16-cube blocks, the sky every 2 s).
- **Picked by itself** at the first start of the Quest APK on a Quest 3 / 3S (`Profile._read` → `GraphicsPreset.first_preset`,
  `vr_for_model(OS.get_model_name())`: "Quest 3", "Quest 3S"; a Quest 2 or a Quest Pro gets `vr`). A profile saved before
  (a phone preset in it) reads as the headset's own pick in a session (`GraphicsPreset.vr_preset`). The browser's `/vr/`
  cannot tell the headset: `vr`.
- **On the settings page in a headset:** the Graphics row shows VR and VR PLUS (a phone's LOW / MEDIUM / HIGH mean nothing
  there; off VR the row is as before). A pick is stored like any preset and applied at once (the world's style, shadows,
  view; the refresh rate).
- **The refresh rate** (`Vr._tune`, P5's lines): the VR preset's (`vr` 72, `vr_plus` 90), the nearest the headset offers,
  asked again when the child picks the other VR preset. **"90 Hz when there is headroom":** `GraphicsPreset.watch_refresh`
  steps down once to the next rate the headset offers (90 → 80 on a Quest 3) after two 5 s windows in a row under 93 % of
  the rate; a window with a frame over 100 ms (a load) or while the headset is unfocused (the Quest's menu) counts neither
  way; never below 72, never back up (no see-saw). Each ask prints `VR_BENCH device model=Quest_3 preset=vr_plus
  refresh_hz=90 offered=72,80,90,120 renderer=mobile` in logcat.
- **Measured here** (one Quest 2-sized eye, this iGPU, the Quest's own `.mobile` shadow defaults: a 2048 map, hard edges):
  | Run (16-cube blocks, the 80-block view unless said) | draws (most) | scene (shadow in it) / canvas | triangles (most) | GPU ms |
  |---|---|---|---|---|
  | Green Meadows REALISTIC, the research's 96-block view | 213 (241) | 179 (36 shadow) / 22 | 549K | 14.8 |
  | Green Meadows REALISTIC | 173 (188) | 150 (34 shadow) / 22 | 426K | 14.5 |
  | Green Meadows BLOCKY | 173 (188) | 150 / 22 | 426K | 11.8 |
  | The Moon REALISTIC | 115 (142) | 75 (13 shadow) / 39 | 75K | 3.4 |
  | World 41 REALISTIC | 135 (138) | 98 (20 shadow) / 37 | 81K | 4.9 |

  What the GPU time is made of (Green Meadows BLOCKY, the earlier 32-cube runs, this iGPU): 24 ms with the desktop's
  4096 soft shadow map, **14 ms with the Quest's 2048 hard one**, 9.4 ms without sun shadows; MSAA 4x → 2x and 2 splits or
  one (orthogonal) instead of 4 changed 1-3 ms; a 64-block view 2 ms. So the sun's shadows are vr_plus's biggest cost, a
  third of its GPU, and the first lever if the Quest 3 cannot hold 90 Hz. This iGPU against a Quest 3 (XR2 Gen 2, both
  eyes at 2064 × 2208, foveated, a tiler for which MSAA is nearly free): UNCONFIRMED, the headset's `gpu_ms` decides.
- **What the lead measures first on the Quest 3** (Developer Mode, the Quest APK; `adb logcat -s godot:V | grep VR_BENCH`):
  the device line (model, preset `vr_plus`, `refresh_hz=90`, the offered rates); Green Meadows in REALISTIC and BLOCKY, the
  Moon, world 41: `fps` ≥ 90 (or the step to 80 in the log), `worst_ms`, `over28`, `draws`, `gpu_ms` (≤ 11 at 90 Hz),
  `process_ms`; a walk of 100 m and a FLY of 1 km (the stutter of a block streaming in); then the same with VR (72 Hz).
  If `gpu_ms` is over 11 in Green Meadows: the shadows go first (`vr_plus.shadows` false: a third of its GPU here), then
  MSAA 2x.

## The web path: what a WebXR session costs

The Quest's browser runs `/vr/` on the Compatibility renderer (WebGL 2, multiview through `OVR_multiview2`, the
`xr/shaders/enabled.webxr` variants). A WebGL program is compiled the first time it is drawn, on the main thread (100-500 ms
each on a phone's browser: `docs/devlog/parts/m7-shader-warmup.md`); the game's warm-up (`ShaderWarmup`, the census
`data/shader_warmup.json`) draws into a **mono** SubViewport before the menu, which compiles the flat variants only. After
ENTER VR every material is drawn in **multiview** for the first time: a second compile each. From the census, what a child
sees first: the menu 3 programs, a new world 14 (Green Meadows) to 23 (with the creatures and features), the universes
16-17, the cosmos worlds 13-18, the way between worlds 27, plus the blocks' few and VR's own (the comfort sphere, the
laser, the ring, the panel, the hands): **about 20-30 compiles in the first seconds of each new world in VR, 2-15 s of
stalls on a phone-class browser.** Not measurable here: headless Chrome has no XR device (ENTER VR stays hidden), and the
Quest browser is the owner's. What was measured: `tools/web_check.py` against `tools/web_serve.py` serving lead-merge's
`build/web_vr` (the flat start before ENTER VR, headless Chrome on SwiftShader, a busy PC): MENU ready 11.9 s on the first
visit (9.4 s after a refresh, 0.00 MB fetched), the mono warm-up 82 draws in 50 s (32 of them a new world's): every one of
those is a program whose multiview twin compiles at first sight in a session.
**For the lead (`world/shader_warmup.gd`, not P5's):** a warm-up *inside* the session: after `Vr.started` in a `webxr` build,
while the loading room shows (or behind `Vr.fade_out`), draw the census's list for the world being entered (`ShaderWarmup.tier`
/ `world_part`) a few per frame in front of the XR camera, under VR's black (`VrComfort`, priority 100, no depth test),
so each multiview variant compiles before the child sees it. The same holds for the "Quest GL" APK (OpenGL ES on the
headset: `PlatformRules.needs_shader_warmup` is true there too). The Vulkan Quest APK needs none (pipelines compile in the
background).

## Rulings (each with what it costs if wrong)

1. **The budget counts every draw of a frame, the canvases' too** (VR_BENCH's `draws` is the renderer's total; the bench
   splits it). A canvas draw is cheaper than a scene's, but it is a draw call the Quest's CPU submits. [If wrong: none; the
   cut only helps.]
2. **16-cube terrain blocks in VR** (P5-1 above). [About 100 draws in the tree worlds where 32-cube blocks drew 66-70; the
   physics thread is the way back to 32.]
3. **SpaceWarp off** (P5-2 above). [A GPU-bound world judders on Quest 2 until it is turned on.]
4. **The HUD's batch only in a real session** (`GraphicsPreset.vr_session`: the headset and the desktop preview), never in
   a test's simulated session: the suite's VR tests see the phone's drawing, and a phone never runs the new path. The
   batched pictures are the same shapes and colours; an antialiased line's 1 px feather is the batch's own (Godot's is close),
   and the pulsing heart's outline grows with the pulse (+16 % at its top; the phone keeps 2 px). [A pixel's difference in a
   headset only.]
5. **`vr_plus` is the research's** (90 Hz, shadows 24 m, MSAA 4x, REALISTIC) **with an 80-block view, not 96**: with 16-cube
   blocks the 96-block view drew 213 a frame in Green Meadows (241 at the most), over a Quest 3's 200; 80 drew 173 (188).
   (Voxel Tools streams whole blocks: 72 loads what 80 does, the same 173; 64 is `vr`'s.)
   Validated on the Quest 3 first; its frame-rate step-down covers a world that cannot hold 90. [If the Quest 3 cannot
   hold 80 in Green Meadows: shadows off first (a third of vr_plus's GPU here), the lead's one-line change.]
6. **The model decides `vr_plus`** (`OS.get_model_name()` contains "Quest 3", underscores as spaces): the Quest Pro (XR2+
   Gen 1, a Quest 2's GPU class) and any unknown headset get `vr`. [A Quest Pro owner picks VR PLUS by hand.]
7. **The step-down** waits two clean 5 s windows under 93 % (a load's hitch, over 100 ms, and an unfocused headset count
   neither way), steps once, never below 72, never back up. [A world that only just misses 90 drops to 80 for the session;
   the child can pick VR PLUS again to retry.]
8. **The first start picks the VR preset only in the Quest APK** (`PlatformRules.starts_vr`); the browser's `/vr/` (it cannot
   tell the headset) reads a phone preset as `vr` in its session. [A Quest 3 in the browser plays `vr` unless the child
   picks VR PLUS.]
9. **Labels over everything end at 32 m in VR** (the research's P5 row): a trader's sign is no longer seen over a hill 100 m
   away in a headset. [A child looking for the trader from afar: the map and Pip's arrows still point.]
10. **At most 16 bursts in VR**: a 17th ends the oldest early (the newest, the child's own, always shows). [Fewer sparkles
   in a big fight.]
11. **The vr_plus shadow map is Godot's mobile default** (2048, hard edges: `.mobile` overrides the Quest APK gets), not
   changed; the bench sets the same on the desktop so its GPU numbers mean the headset's setting.

## For the lead (lead's files: nothing must change; levers)

- **`project.godot`:** nothing required. Levers, measured here: `voxel/threads/main/time_budget_ms.quest=3` (flying's long
  frames 57 → 20 in a minute; check on the headset that the land ahead still fills in), and
  `physics/3d/run_on_separate_thread.quest=true` (the collision builds off the main thread: 0 long frames walking even
  with 32-cube blocks; but a ray from `_process` then fails, "Space state is inaccessible right now" — measured: every
  `intersect_ray` of a probe in `_process` — so `BlockInteractor`'s and `SecretTaps`' rays move into `_physics_process`
  first, VR-RIG's files) and then `mesh_block` 32 again in the `vr` presets (-45 draws); ASW stays off.
- **`export_presets.cfg`, `scenes/sandbox.gd`, `scenes/main.gd`:** nothing.
- **For VR-RIG (`entities/vr/vr_bench.gd`):** the periodic line's `vr_preset=` prints a bool (`GraphicsPreset.vr_session`):
  `GraphicsPreset.vr_preset(str(Profile.data.settings.graphics))` instead, and the split (`draws_3d`, `draws_2d`:
  `tools/vr_bench_steps.gd`'s `draw_split`, three render-info reads per viewport) beside `draws`. The headset's device line
  (model, preset, refresh) already prints from `Vr._tune`.
- **For VR-UI (P5 touched their area, VR-only, marked "P5", each because it was a top line of `--blame`'s canvas
  list):** `ui/hud/hearts_bar.gd` (60 draws), `ui/controls/touch_button.gd` (7-11 a picture button; the hotbar's frames),
  `ui/hud/hotbar.gd` (22), `ui/hud/hud_icons.gd` (the buttons' pictures into a batch), `ui/hud/coin_icon.gd` (6),
  `ui/hud/stealth_meter.gd` (9), `ui/progress/read_aloud.gd` (the speaker, 4), `ui/menus/settings_panel.gd` (VR and VR
  PLUS). A new HUD picture drawn in code: through `CanvasBatch` in a session. A lever left: the menu's backdrop viewer
  sees 96 blocks (`ui/menus/menu.gd`: 51 of the menu's 69 draws; `GraphicsPreset.view_distance` in VR would make it 64).
- **For whoever owns `world/shader_warmup.gd`:** the in-session warm-up for the browser's `/vr/` and "Quest GL" (the web
  path above).
- **The ad-hoc test subset's six order-dependent failures** (`test_hud_layout`, `test_vr_rig_player`, `test_vr_rig_photo`,
  `test_vr_rig_p3_player`, `test_online_menus`, `test_hud_stealth`, run together after `test_log_out`): the same six fail on
  `040a0be9` in that order; each passes alone. Not P5's; the full suite's order is the one that counts (below).

## Files

| File | What |
|---|---|
| `tools/vr_bench_steps.gd` | Any world, the menu, the Launch Site, a walk, a cruise, the Quest's platform and shadow defaults, `--blame`, `--long`, `--voxel-threads`; the draws split; the device line |
| `tools/frame_blame.gd` | No panel lookup while the tree is taken down at the quit |
| `ui/controls/canvas_batch.gd` (new) | `CanvasBatch` |
| `ui/hud/hearts_bar.gd`, `ui/controls/touch_button.gd`, `ui/hud/hud_icons.gd`, `ui/hud/coin_icon.gd`, `ui/hud/stealth_meter.gd`, `ui/hud/hotbar.gd`, `ui/progress/read_aloud.gd` | The VR-only one-draw paths (P5) |
| `core/rules/graphics_preset.gd` | `vr_plus`, the headset's pick, refresh rates and the step-down, the device line, the settings' choices, the first start, `fx_live`, `mesh_block` 16 |
| `autoloads/vr.gd` | P5's refresh-rate lines in `_tune` and `_process` |
| `autoloads/profile.gd` | P5: the Quest APK's first start stores its VR preset |
| `ui/menus/settings_panel.gd` | P5: VR and VR PLUS in a headset |
| `world/world_service.gd` | The VR preset's style, no glow in a session, labels over everything to 32 m, the backdrop's blocks |
| `entities/fx/fx.gd` | `Fx.max_live()` |
| `tests/unit/test_vr_perf_presets.gd`, `test_vr_perf_canvas_batch.gd`; `tests/integration/test_vr_perf_hud.gd`, `_world`, `_settings`, `_first_start`, `_refresh`, `_labels`, `_fx` | 55 tests |
| `tests/unit/test_vr_rig_platform.gd` | Its two `mesh_block` asserts follow ruling 2 |

## The full suite (once, at the end, on this branch with lead-merge merged in at `aa988297`)

`tests/run_tests.sh` (2026-10-16 13:47-14:47, a busy PC, one PC-wide slot): **1128 scripts, 10288 tests, 10285 passing,
0 failing**, 3 risky or pending (`test_the_column_cache_changes_nothing` and `test_chunks_meet_without_seams` assert
nothing; the online move test is pending by design), no `SCRIPT ERROR`, exit 0. Every `test_vr_*.gd` (39 files, 299 tests)
passed on the merged tree before it as well.
