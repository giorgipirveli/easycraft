# M1 "First Steps" Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.
>
> **Execution note:** the owner asked for no questions and a playable game quickly, so this plan is executed **natively** by its author in one session (godot-mcp allows one editor client, and the emulator is shared, so parallel subagents would collide). The plan pins **contracts** (files, interfaces, test code, acceptance checks). Engine-glue code is written directly into the repo against the Voxel Tools API verified in Task 2.

**Goal:** A smooth, playable Sandbox on the Android emulator — endless block world, blocky avatar, touch controls, triple jump, build/break/undo, physics switch, saving, first-launch flow — built on a multiplayer-ready core.

**Architecture:** Five layers (rules → world → entities → UI → net). Pure rules in `core/` are unit-tested with GUT. The world wraps Voxel Tools behind `WorldService`. Every world edit goes request → host validates → apply, even in solo play (the local game is the host through `OfflineMultiplayerPeer`).

**Tech Stack:** Godot 4.7.2 (GDScript, typed), Voxel Tools 1.7 GDExtension, GUT 9.7.1, godot-mcp 4.1.11, Android emulator `Pixel_8_API_35`.

**Spec:** `docs/superpowers/specs/2026-09-23-realm-hoppers-design.md` (section 9 is M1).

## Global Constraints

- Godot 4.7.2; GDScript with static types everywhere.
- Landscape only (`display/window/handheld/orientation` = landscape).
- Android export: arm64-v8a + x86_64; test device is the emulator `Pixel_8_API_35` (OpenGL fallback).
- 16 placeable blocks: grass, dirt, stone, sand, wood log, planks, leaves, glass, brick, light, water, red, yellow, green, blue, purple.
- Triple jump = 3 jumps total (1 ground + 2 air); coyote time 0.1 s; jump buffer 0.1 s.
- Reach 10 blocks; undo depth 20; hold-to-break 0.25 s; drag threshold 12 px.
- Username: 3–16 chars, `[A-Za-z0-9_]`, starts with a letter, bad-word and personal-info filter.
- Age: store only the band `under_13` / `13_plus`, never the birth year.
- Autosave every 60 s and on pause, quit and app switch.
- Performance: ≥30 FPS average on Medium on the emulator; no frame >100 ms after initial load while travelling 2 km.
- Placeholder art/audio: CC0 only.

## Review Focus

1. **Profile file corrupted by a kill mid-write** → the game must start with defaults, never crash. Pinned in Task 3 (`test_from_json_truncated_returns_defaults`) and Task 9 (atomic write via temp file + rename).
2. **Placing a block inside the player's own body** → rejected, so the player can never trap themselves. Pinned in Task 7 (`test_rejects_place_overlapping_player`).
3. **Spawning or falling into unloaded or empty terrain** → spawn waits for the area to be meshed and lands on the surface; falling below y = −64 teleports back to the surface. Pinned in Task 6 (`test_spawn_height_is_above_surface`) and the fall-guard check.
4. **Usernames made of spaces, emoji, look-alike Unicode, or digits hiding a phone number** → rejected with a clear message. Pinned in Task 3 username tests.
5. **Multi-touch: joystick thumb plus build finger at the same time** → the joystick touch never triggers look/place/break. Pinned in Task 3 (`test_ignores_touch_indices_it_does_not_own`).

---

### Task 1: Baseline, tooling, landscape

**Files:**
- Modify: `project.godot` (landscape, 1280×720 viewport, desktop window 960×540, input actions)
- Create: `addons/gut/` (GUT 9.7.1), `tests/run_tests.sh`, `tests/unit/test_sanity.gd`
- Create: `.gutconfig.json`

**Interfaces:**
- Produces: `tests/run_tests.sh` → runs every `tests/unit/test_*.gd` headless and exits non-zero on failure.

- [ ] **Step 1:** Commit the scaffold and spec on `main` ("chore: project scaffold and design spec"); create branch `m1-first-steps`.
- [ ] **Step 2:** Download GUT 9.7.1 from GitHub, copy `addons/gut` into the project.
- [ ] **Step 3:** Write the sanity test:

```gdscript
extends GutTest

func test_gut_runs() -> void:
	assert_eq(1 + 1, 2)
```

- [ ] **Step 4:** Write `tests/run_tests.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests/unit -ginclude_subdirs -gexit
```

- [ ] **Step 5:** Run `tests/run_tests.sh` → expected: 1 passing test, exit 0.
- [ ] **Step 6:** Switch `project.godot` to landscape: `window/handheld/orientation=4` (sensor landscape), viewport 1280×720, window override 960×540.
- [ ] **Step 7:** Commit ("chore: GUT test runner and landscape setup").

### Task 2: Voxel Tools feasibility check (go/no-go)

**Files:**
- Create: `addons/zylann.voxel/` (GDExtension 1.7x)
- Create: `spikes/voxel_spike.tscn`, `spikes/voxel_spike.gd` (throwaway; excluded from export)
- Create: `docs/superpowers/notes/2026-09-23-voxel-spike.md` (results)

**Interfaces:**
- Produces: a verified list of the exact Voxel Tools API used by Tasks 4–5 and 11, recorded in the notes file.

- [ ] **Step 1:** Download `GodotVoxelExtension.zip` (release `v1.7x`), extract `addons/zylann.voxel` into the project, restart the editor, confirm there are no load errors in the editor log.
- [ ] **Step 2:** Build the spike scene: `VoxelTerrain` (mesher `VoxelMesherBlocky` with a 3-model `VoxelBlockyLibrary`: air, grass, stone), a script generator (flat noise heightmap), `VoxelStreamSQLite` at `user://spike/voxels.sqlite`, a `Camera3D` with a `VoxelViewer` flying forward at 8 m/s.
- [ ] **Step 3:** The spike script sets `Vector3i(0, 40, 0)` to stone after 3 s, calls `save_modified_blocks()`, and prints `SPIKE get_voxel=<id>` plus average FPS every 5 s, and `SPIKE persisted=<id>` at startup.
- [ ] **Step 4:** Run on desktop through godot-mcp → terrain visible, `get_voxel=3`.
- [ ] **Step 5:** Export to the emulator (spike as main scene in a temporary preset), run, read logcat: terrain renders, FPS printed; force-stop and relaunch → `SPIKE persisted=3`.
- [ ] **Step 6:** Check `ClassDB.class_exists("VoxelTerrainMultiplayerSynchronizer")`.
- [ ] **Step 7:** Write results and go/no-go into the notes file. **No-go** (terrain missing, edits lost, crash, or FPS < 20) → stop and re-plan with a custom engine.
- [ ] **Step 8:** Commit ("spike: verify Voxel Tools 1.7 on Android emulator").

### Task 3: Core rules (TDD)

**Files:**
- Create: `core/rules/jump_counter.gd`, `core/rules/physics_mode.gd`
- Create: `core/validation/username_rules.gd`, `core/validation/age_band.gd`
- Create: `core/building/undo_stack.gd`, `core/input/touch_classifier.gd`
- Create: `core/save/profile_data.gd`
- Test: `tests/unit/test_jump_counter.gd`, `test_physics_mode.gd`, `test_username_rules.gd`, `test_age_band.gd`, `test_undo_stack.gd`, `test_touch_classifier.gd`, `test_profile_data.gd`

**Interfaces (produced):**

```gdscript
class_name JumpCounter extends RefCounted
const MAX_JUMPS := 3
const COYOTE_TIME := 0.1
const BUFFER_TIME := 0.1
var jumps_used: int
func press_jump() -> void            # records a buffered press
func tick(delta: float, on_floor: bool) -> bool   # returns true when a jump must happen this frame
func reset() -> void

class_name PhysicsMode extends RefCounted
enum Mode { NORMAL, FLY, GHOST }
static func next(mode: int) -> int
static func has_gravity(mode: int) -> bool
static func has_collision(mode: int) -> bool
static func display_name(mode: int) -> String

class_name UsernameRules extends RefCounted
const MIN_LEN := 3
const MAX_LEN := 16
static func validate(name: String) -> String   # "" when valid, else an error code
static func message(code: String) -> String

class_name AgeBand extends RefCounted
const UNDER_13 := &"under_13"
const TEEN_PLUS := &"13_plus"
static func from_birth_year(birth_year: int, current_year: int) -> StringName

class_name UndoStack extends RefCounted
func _init(capacity: int = 20) -> void
func push(pos: Vector3i, old_id: int, new_id: int) -> void
func pop() -> Dictionary    # {} when empty, else {pos, old_id, new_id}
func size() -> int
func clear() -> void

class_name TouchClassifier extends RefCounted
enum Gesture { NONE, TAP, HOLD, DRAG }
const DRAG_THRESHOLD_PX := 12.0
const HOLD_TIME := 0.25
func down(index: int, pos: Vector2, time: float) -> void
func move(index: int, pos: Vector2, time: float) -> int   # DRAG once the threshold is crossed, else NONE
func update(time: float) -> int                          # HOLD once when held still for HOLD_TIME
func up(index: int, pos: Vector2, time: float) -> int     # TAP if released quickly without dragging
func owns(index: int) -> bool

class_name ProfileData extends RefCounted
const VERSION := 1
var username: String
var age_band: StringName
var settings: Dictionary   # graphics:"medium", view_distance:128, volume:0.8, show_fps:false
static func from_json(text: String) -> ProfileData   # never fails; bad input → defaults
func to_json() -> String
func is_onboarded() -> bool
```

- [ ] **Step 1: Write the failing tests** (all seven files). Key cases:

```gdscript
# tests/unit/test_jump_counter.gd
extends GutTest
var jc: JumpCounter
func before_each() -> void: jc = JumpCounter.new()

func test_three_jumps_then_no_fourth() -> void:
	jc.tick(0.016, true)
	jc.press_jump(); assert_true(jc.tick(0.016, true), "ground jump")
	jc.press_jump(); assert_true(jc.tick(0.016, false), "air jump 1")
	jc.press_jump(); assert_true(jc.tick(0.016, false), "air jump 2")
	jc.press_jump(); assert_false(jc.tick(0.016, false), "no 4th jump")

func test_landing_resets() -> void:
	for i in 3:
		jc.press_jump(); jc.tick(0.016, i == 0)
	jc.tick(0.016, true)
	jc.press_jump(); assert_true(jc.tick(0.016, true))

func test_coyote_time_allows_ground_jump_after_leaving_edge() -> void:
	jc.tick(0.016, true)
	jc.tick(0.05, false)
	jc.press_jump(); assert_true(jc.tick(0.016, false))
	assert_eq(jc.jumps_used, 1, "coyote jump counts as the ground jump")

func test_buffered_press_fires_on_landing() -> void:
	jc.tick(0.016, true); jc.press_jump(); jc.tick(0.016, true)   # jump 1
	jc.press_jump(); jc.tick(0.016, false)                         # jump 2
	jc.press_jump(); jc.tick(0.016, false)                         # jump 3
	jc.press_jump(); assert_false(jc.tick(0.05, false))            # buffered, no jumps left
	assert_true(jc.tick(0.016, true), "buffered press fires on landing")

func test_stale_buffer_expires() -> void:
	jc.tick(0.016, true); jc.press_jump(); jc.tick(0.016, true)
	jc.press_jump(); jc.tick(0.016, false); jc.press_jump(); jc.tick(0.016, false)
	jc.press_jump(); jc.tick(0.2, false)
	assert_false(jc.tick(0.016, true), "press older than 0.1 s is dropped")
```

```gdscript
# tests/unit/test_username_rules.gd
extends GutTest
func test_valid() -> void: assert_eq(UsernameRules.validate("Hopper_7"), "")
func test_too_short() -> void: assert_eq(UsernameRules.validate("ab"), "too_short")
func test_too_long() -> void: assert_eq(UsernameRules.validate("abcdefghijklmnopq"), "too_long")
func test_must_start_with_letter() -> void: assert_eq(UsernameRules.validate("7hopper"), "must_start_with_letter")
func test_spaces_rejected() -> void: assert_eq(UsernameRules.validate("   "), "too_short")
func test_inner_space_rejected() -> void: assert_eq(UsernameRules.validate("hop per"), "bad_chars")
func test_emoji_rejected() -> void: assert_eq(UsernameRules.validate("hop😀er"), "bad_chars")
func test_cyrillic_lookalike_rejected() -> void: assert_eq(UsernameRules.validate("hоpper"), "bad_chars")
func test_phone_number_rejected() -> void: assert_eq(UsernameRules.validate("call5551234567"), "personal_info")
func test_bad_word_rejected() -> void: assert_eq(UsernameRules.validate("xxStupidxx"), "blocked_word")
func test_every_code_has_message() -> void:
	for code in ["too_short", "too_long", "must_start_with_letter", "bad_chars", "personal_info", "blocked_word"]:
		assert_ne(UsernameRules.message(code), "")
```

```gdscript
# tests/unit/test_age_band.gd
extends GutTest
func test_clearly_under_13() -> void: assert_eq(AgeBand.from_birth_year(2018, 2026), AgeBand.UNDER_13)
func test_boundary_is_conservative() -> void: assert_eq(AgeBand.from_birth_year(2013, 2026), AgeBand.UNDER_13)
func test_clearly_13_plus() -> void: assert_eq(AgeBand.from_birth_year(2012, 2026), AgeBand.TEEN_PLUS)
func test_future_year_is_under_13() -> void: assert_eq(AgeBand.from_birth_year(2030, 2026), AgeBand.UNDER_13)
```

```gdscript
# tests/unit/test_undo_stack.gd
extends GutTest
func test_lifo() -> void:
	var u := UndoStack.new()
	u.push(Vector3i(1, 0, 0), 0, 3); u.push(Vector3i(2, 0, 0), 0, 4)
	assert_eq(u.pop().pos, Vector3i(2, 0, 0))
	assert_eq(u.pop().pos, Vector3i(1, 0, 0))
	assert_eq(u.pop(), {})
func test_capacity_drops_oldest() -> void:
	var u := UndoStack.new(20)
	for i in 25: u.push(Vector3i(i, 0, 0), 0, 1)
	assert_eq(u.size(), 20)
	var last := {}
	while u.size() > 0: last = u.pop()
	assert_eq(last.pos, Vector3i(5, 0, 0))
```

```gdscript
# tests/unit/test_touch_classifier.gd
extends GutTest
var tc: TouchClassifier
func before_each() -> void: tc = TouchClassifier.new()
func test_quick_release_is_tap() -> void:
	tc.down(1, Vector2(100, 100), 0.0)
	assert_eq(tc.up(1, Vector2(102, 101), 0.1), TouchClassifier.Gesture.TAP)
func test_hold_fires_once() -> void:
	tc.down(1, Vector2(100, 100), 0.0)
	assert_eq(tc.update(0.3), TouchClassifier.Gesture.HOLD)
	assert_eq(tc.update(0.5), TouchClassifier.Gesture.NONE)
	assert_eq(tc.up(1, Vector2(100, 100), 0.6), TouchClassifier.Gesture.NONE)
func test_drag_beats_tap() -> void:
	tc.down(1, Vector2(100, 100), 0.0)
	assert_eq(tc.move(1, Vector2(130, 100), 0.05), TouchClassifier.Gesture.DRAG)
	assert_eq(tc.up(1, Vector2(130, 100), 0.1), TouchClassifier.Gesture.NONE)
	assert_eq(tc.update(0.5), TouchClassifier.Gesture.NONE, "dragging never becomes hold")
func test_ignores_touch_indices_it_does_not_own() -> void:
	tc.down(1, Vector2(100, 100), 0.0)
	assert_false(tc.owns(0))
	assert_eq(tc.up(0, Vector2(100, 100), 0.05), TouchClassifier.Gesture.NONE)
	assert_eq(tc.up(1, Vector2(100, 100), 0.05), TouchClassifier.Gesture.TAP)
```

```gdscript
# tests/unit/test_profile_data.gd
extends GutTest
func test_round_trip() -> void:
	var p := ProfileData.new(); p.username = "Hopper"; p.age_band = AgeBand.TEEN_PLUS
	var q := ProfileData.from_json(p.to_json())
	assert_eq(q.username, "Hopper"); assert_eq(q.age_band, AgeBand.TEEN_PLUS)
func test_from_json_truncated_returns_defaults() -> void:
	var q := ProfileData.from_json('{"version":1,"username":"Hop')
	assert_eq(q.username, ""); assert_false(q.is_onboarded())
func test_missing_settings_get_defaults() -> void:
	var q := ProfileData.from_json('{"version":1,"username":"Hop","age_band":"13_plus"}')
	assert_eq(q.settings.graphics, "medium"); assert_eq(q.settings.view_distance, 128)
func test_onboarded_requires_name_and_age() -> void:
	var q := ProfileData.from_json('{"version":1,"username":"Hop"}')
	assert_false(q.is_onboarded())
```

`test_physics_mode.gd`: `next()` cycles NORMAL→FLY→GHOST→NORMAL; gravity only in NORMAL; collision in NORMAL and FLY only.

- [ ] **Step 2:** Run `tests/run_tests.sh` → all new tests FAIL (classes missing).
- [ ] **Step 3:** Implement the seven classes to the interfaces above.
- [ ] **Step 4:** Run `tests/run_tests.sh` → all PASS.
- [ ] **Step 5:** Commit ("feat(core): jump, physics mode, username, age, undo, touch, profile rules").

### Task 4: Blocks, atlas, Meadows generator

**Files:**
- Create: `data/blocks/block_ids.gd` (`class_name BlockIds`), `data/blocks/atlas.png`, `tools/make_atlas.gd`
- Create: `world/block_library.gd` (`class_name BlockLibrary`), `world/generators/meadows_shape.gd` (`class_name MeadowsShape`), `world/generators/meadows_generator.gd` (`extends VoxelGeneratorScript`)
- Test: `tests/unit/test_block_ids.gd`, `tests/unit/test_meadows_shape.gd`

**Interfaces:**
- Produces:
  - `BlockIds`: constants `AIR=0, GRASS=1, DIRT=2, STONE=3, SAND=4, LOG=5, PLANKS=6, LEAVES=7, GLASS=8, BRICK=9, LIGHT=10, WATER=11, RED=12, YELLOW=13, GREEN=14, BLUE=15, PURPLE=16`; `const PLACEABLE: Array[int]` (16 ids); `static func display_name(id) -> String`; `static func is_solid(id) -> bool` (false for AIR, WATER); `static func is_valid(id) -> bool`.
  - `BlockLibrary.build() -> VoxelBlockyLibrary` (model index == block id).
  - `MeadowsShape.new(seed)`: `height_at(x: int, z: int) -> int`, `SEA_LEVEL := 24`, `tree_at(x: int, z: int) -> bool`, `column_block(x, y, z, height) -> int`.
  - `MeadowsGenerator` (`VoxelGeneratorScript`) with `seed: int`, uses `MeadowsShape`.

- [ ] **Step 1:** Failing tests: `BlockIds.PLACEABLE.size() == 16`, no AIR in it, every id has a non-empty name, water is not solid; `MeadowsShape` is deterministic for the same seed, heights stay within `[4, 120]`, different seeds differ somewhere in a 64×64 area, trees never grow in water (`height_at <= SEA_LEVEL` → `tree_at == false`), and at least one tree exists in a 64×64 area.
- [ ] **Step 2:** Run → FAIL.
- [ ] **Step 3:** Implement. Atlas: 4×4 tiles of 64 px, generated by `tools/make_atlas.gd` (bright colors with subtle noise and a darker edge so blocks read clearly). Library: `VoxelBlockyModelEmpty` for AIR, `VoxelBlockyModelCube` for the rest with tile coords; three materials (opaque with vertex-color AO, alpha-scissor for leaves and glass, alpha blend for water with a higher `transparency_index`); water has no collision AABB; LIGHT is unshaded (emissive look).
- [ ] **Step 4:** Run → PASS.
- [ ] **Step 5:** Commit ("feat(world): block ids, atlas, library, Meadows generator").

### Task 5: World scene and WorldService

**Files:**
- Create: `world/world.tscn`, `world/world_service.gd` (`class_name WorldService`), `world/world_meta.gd` (`class_name WorldMeta`)
- Test: `tests/unit/test_world_meta.gd`

**Interfaces:**
- Produces:

```gdscript
class_name WorldService extends Node3D
signal block_changed(pos: Vector3i, old_id: int, new_id: int)
func setup(world_dir: String, seed: int) -> void   # before entering the tree's _ready of the terrain
func get_block(pos: Vector3i) -> int
func set_block(pos: Vector3i, id: int) -> void      # host-only; emits block_changed
func raycast(origin: Vector3, dir: Vector3, max_dist: float) -> VoxelRaycastResult
func surface_height(x: int, z: int) -> int          # generator shape height (for spawn)
func is_area_ready(center: Vector3) -> bool         # meshed around center
func save() -> void
func terrain() -> VoxelTerrain

class_name WorldMeta extends RefCounted
var seed: int
var player_pos: Vector3
var player_yaw: float
var physics_mode: int
var hotbar: Array[int]
var selected_slot: int
static func from_json(text: String) -> WorldMeta   # bad input → defaults with a random seed
func to_json() -> String
```

- [ ] **Step 1:** Failing `test_world_meta.gd`: round trip; truncated JSON → defaults; hotbar defaults to the first 9 placeable blocks.
- [ ] **Step 2:** Run → FAIL. **Step 3:** Implement `WorldMeta`, the world scene (VoxelTerrain + WorldEnvironment with sky and fog + DirectionalLight3D) and `WorldService`. **Step 4:** Run → PASS.
- [ ] **Step 5:** Integration check via godot-mcp: run a scene that calls `set_block`/`get_block` at a loaded position → same id back.
- [ ] **Step 6:** Commit ("feat(world): world scene, WorldService, WorldMeta").

### Task 6: Player, avatar, camera

**Files:**
- Create: `entities/player/player.tscn`, `player.gd`, `blocky_avatar.gd`, `camera_rig.gd`, `core/rules/spawn_rules.gd` (`class_name SpawnRules`)
- Test: `tests/unit/test_spawn_rules.gd`

**Interfaces:**
- Consumes: `JumpCounter`, `PhysicsMode`, `WorldService`, `BlockIds`.
- Produces: `Player` (`CharacterBody3D`) with `physics_mode: int`, `func set_physics_mode(mode: int)`, `func camera() -> Camera3D`, `func look_delta(delta: Vector2)`, `func toggle_camera()`, signal `jumped(index: int)`; `SpawnRules.spawn_y(surface_height: int) -> float` (= surface + 1.05); `SpawnRules.FALL_LIMIT_Y := -64.0`.

- [ ] **Step 1:** Failing `test_spawn_rules.gd`: `test_spawn_height_is_above_surface` (spawn_y(40) > 41.0 and < 42.0).
- [ ] **Step 2–4:** Implement; run → PASS. Movement is camera-relative and analog; gravity 24 m/s², jump velocity 9 m/s; fly speed 12 m/s with up/down; ghost sets `collision_mask = 0`; returning to NORMAL inside a solid block moves the player up to the first free 2-block-tall space; in water: half speed, gentle rise when holding jump; below `FALL_LIMIT_Y` → teleport to the surface.
- [ ] **Step 5:** Playtest via godot-mcp (frozen run + input injection): press jump 4 times in the air → exactly 3 `jumped` signals; switch to GHOST, fly into the ground, switch to NORMAL → the player ends up standing on the surface.
- [ ] **Step 6:** Commit ("feat(player): movement, triple jump, physics modes, blocky avatar, camera").

### Task 7: Building interaction

**Files:**
- Create: `entities/player/block_interactor.gd` (`class_name BlockInteractor`), `entities/player/target_highlight.gd`, `core/building/placement_rules.gd` (`class_name PlacementRules`)
- Test: `tests/unit/test_placement_rules.gd`

**Interfaces:**
- Consumes: `WorldService`, `UndoStack`, `BlockIds`, `Session.request_set_block`.
- Produces: `PlacementRules.can_place(block_pos: Vector3i, player_aabbs: Array[AABB], id: int) -> bool`; `PlacementRules.REACH := 10.0`; `BlockInteractor.place_at_screen(screen_pos: Vector2)`, `break_at_screen(screen_pos: Vector2)`, `place_crosshair()`, `break_crosshair()`, `undo()`, `select_slot(i: int)`, `selected_block() -> int`.

- [ ] **Step 1:** Failing tests: `test_rejects_place_overlapping_player` (block at the player's feet → false), `test_allows_place_next_to_player`, `test_rejects_air_and_invalid_ids`, `test_allows_water_inside_player` is false too (no placing any block in the player's body).
- [ ] **Step 2–4:** Implement; run → PASS. Place = raycast → `previous_position`; break = `position`; each action records undo `(pos, old, new)`; undo re-applies `old` through the same request path. The highlight shows a wireframe cube on the targeted block.
- [ ] **Step 5:** godot-mcp check: place 3 blocks, break 1, undo 4 times → the world matches the start.
- [ ] **Step 6:** Commit ("feat(build): place, break, undo, targeting").

### Task 8: Input map and touch controls

**Files:**
- Modify: `project.godot` (input actions)
- Create: `ui/controls/touch_controls.tscn`, `touch_controls.gd`, `look_build_area.gd`, `ui/hud/hotbar.tscn`, `hotbar.gd`, `ui/hud/block_palette.tscn`, `block_palette.gd`

**Interfaces:**
- Input actions: `move_forward, move_back, move_left, move_right, jump, fly_up, fly_down, place, break, undo, physics_mode, camera_toggle, pause, hotbar_1 … hotbar_9`.
- `LookBuildArea` (right half) uses `TouchClassifier`: DRAG → `player.look_delta`, TAP → `interactor.place_at_screen`, HOLD → `interactor.break_at_screen`.
- The joystick is Godot 4.7's `VirtualJoystick` bound to the `move_*` actions.

- [ ] **Step 1:** Add the actions with keyboard/mouse bindings (WASD, Space, Shift/Ctrl for fly up/down, LMB break, RMB place, Z undo, F physics, V camera, Esc pause, 1–9 hotbar).
- [ ] **Step 2:** Build the touch layout for 1280×720: joystick bottom-left; Jump bottom-right (large); fly up/down above Jump (visible only in FLY/GHOST); Undo, Physics and Camera buttons on the right edge; pause top-left; hotbar bottom-centre with a palette button. Touch controls show when `DisplayServer.is_touchscreen_available()` or the debug setting is on.
- [ ] **Step 3:** godot-mcp check: inject `jump`, `move_forward`, `hotbar_3`, `place` → the player moves and places block 3.
- [ ] **Step 4:** Commit ("feat(input): input map, touch controls, hotbar, palette").

### Task 9: Profile, first-launch flow, menus, HUD, settings

**Files:**
- Create: `autoloads/profile.gd` (`Profile`), `autoloads/game.gd` (`Game`)
- Create: `ui/menus/title.tscn/.gd`, `age_gate.tscn/.gd`, `username_entry.tscn/.gd`, `main_menu.tscn/.gd`, `pause_menu.tscn/.gd`, `settings_menu.tscn/.gd`, `ui/hud/hud.tscn/.gd`, `ui/theme/game_theme.tres`
- Modify: `scenes/main.tscn` (boot router), `project.godot` (autoloads)

**Interfaces:**
- `Profile.data: ProfileData`, `Profile.save()` (writes `user://profile.json.tmp` then renames over `user://profile.json`), `Profile.load()`.
- `Game.goto(scene_path: String)`, `Game.start_sandbox(new_world: bool)`, `Game.quit_to_menu()`, `Game.apply_settings()` (graphics preset → shadows/MSAA/scale; view distance → VoxelViewer; volume → master bus).

- [ ] **Step 1:** Boot: not onboarded → title → age gate (year picker, no default that implies an age) → username entry (live validation message) → main menu. Onboarded → title → main menu.
- [ ] **Step 2:** Main menu: big Sandbox button (Continue / New world with a confirm dialog), Survivor button with a "coming soon" badge, Settings, a version label (triple-tap → developer menu, Task 11).
- [ ] **Step 3:** HUD: username top-right, physics-mode indicator, FPS label (setting).
- [ ] **Step 4:** Pause menu (Resume, Settings, Save & Quit) and settings (graphics Low/Medium/High, view distance 64–192, volume, FPS counter).
- [ ] **Step 5:** godot-mcp run: complete first launch with injected input; restart → goes straight to the main menu; the username is shown top-right in the world.
- [ ] **Step 6:** Commit ("feat(ui): first-launch flow, menus, HUD, settings, profile").

### Task 10: Saving and app lifecycle

**Files:**
- Create: `autoloads/world_saves.gd` (`WorldSaves`)
- Modify: `world/world_service.gd`, `autoloads/game.gd`

**Interfaces:**
- `WorldSaves.dir_for(slot: String) -> String` (`user://worlds/<slot>/`), `exists(slot) -> bool`, `delete(slot)`, `load_meta(slot) -> WorldMeta`, `save_meta(slot, meta)` (atomic write).

- [ ] **Step 1:** Autosave timer (60 s) → `WorldService.save()` + meta; also on pause menu, Save & Quit, `NOTIFICATION_APPLICATION_PAUSED`, `NOTIFICATION_WM_CLOSE_REQUEST`.
- [ ] **Step 2:** Continue restores position, yaw, physics mode, hotbar; New world deletes the slot and picks a new random seed.
- [ ] **Step 3:** Emulator check: place a tower, press Home (app paused → saved), `adb shell am force-stop`, relaunch, Continue → the tower is there and the player stands where they were.
- [ ] **Step 4:** Commit ("feat(save): autosave, lifecycle saves, continue/new world").

### Task 11: Session and developer LAN mode

**Files:**
- Create: `autoloads/session.gd` (`Session`), `net/player_spawner.gd`, `ui/menus/dev_menu.tscn/.gd`
- Modify: `world/world.tscn` (add `VoxelTerrainMultiplayerSynchronizer`, `MultiplayerSpawner`), `entities/player/player.tscn` (`MultiplayerSynchronizer` for transform, animation state and physics mode)

**Interfaces:**
- `Session.start_solo()`, `Session.host_lan(port := 24565) -> Error`, `Session.join_lan(address: String, port := 24565) -> Error`, `Session.is_host() -> bool`, `Session.request_set_block(pos: Vector3i, id: int)` — solo/host applies directly after validation; a client sends `rpc_id(1, "_rpc_request_set_block", pos, id)`; the host validates (`BlockIds.is_valid`, distance from the requesting player ≤ REACH + 2, `PlacementRules.can_place` against all players) then calls `WorldService.set_block`. Edits reach clients through `VoxelTerrainMultiplayerSynchronizer`.
- Clients: `automatic_loading_enabled = false` on their terrain; only the host saves.

- [ ] **Step 1:** Implement solo via `OfflineMultiplayerPeer` (default) and LAN via ENet; the host spawns a player per peer with a `VoxelViewer` (`network_peer_id`, `requires_data_block_notifications = true`, `requires_visuals = false` for remote players).
- [ ] **Step 2:** Developer menu (triple-tap version label): Host, Join 127.0.0.1, back.
- [ ] **Step 3:** Run two desktop instances (`godot --path . ` twice); host + join → both see each other move; blocks placed on either side appear on both.
- [ ] **Step 4:** Commit ("feat(net): session layer, host-validated edits, developer LAN mode").

### Task 12: Look and sound pass

**Files:**
- Create: `assets/audio/sfx/*.ogg` (CC0), `autoloads/audio.gd` (`Audio`), `assets/CREDITS.md`
- Modify: `world/world.tscn` (sky colors, fog, sun angle), graphics presets in `Game.apply_settings()`

**Interfaces:** `Audio.play(name: StringName, at: Vector3 = Vector3.INF)` for `place, break, jump, air_jump, step, ui_click`.

- [ ] **Step 1:** Fetch CC0 sounds (Kenney.nl packs), convert/trim, list sources in `assets/CREDITS.md`.
- [ ] **Step 2:** Hook sounds to events (place, break, jump/air jump, footsteps by distance walked, UI clicks); a small particle puff on air jumps.
- [ ] **Step 3:** Tune sky, fog (starts at 75 % of view distance) and presets (Low: no shadows, 0.75 render scale; Medium: shadows 40 m; High: shadows 80 m, MSAA 2×).
- [ ] **Step 4:** Commit ("feat(feel): sounds, particles, sky, fog, graphics presets").

### Task 12a: Size Magic (spec §3a)

**Files:** Create `core/rules/size_magic.gd` (`class_name SizeMagic`), `tests/unit/test_size_magic.gd`; modify `core/rules/spawn_rules.gd` (clearance parameter), `core/building/placement_rules.gd` (scaled body), `entities/player/*`, `ui/hud/hud.gd` (SIZE button).
**Interfaces:** `SizeMagic.Mode {NORMAL, TINY, GIANT}`, `scale(mode) -> float` (1.0 / 0.25 / 3.0), `next(mode)`, `clearance_blocks(mode) -> int`, `walk_speed_factor(mode)`, `jump_factor(mode)`, `label(mode)`; `SpawnRules.first_free_y(start, is_solid, max_y, clearance := 2)`; `PlacementRules.player_aabb(feet, scale := 1.0)`; `Player.set_size_mode(mode)`, signal `size_mode_changed(mode)`.
- [ ] Tests first (scales, cycle, clearance, speed/jump factors, tiny fits a 1-block gap, scaled AABB); implement; player applies scale to avatar, collision, camera, speed, jump; growing unstucks upward; HUD SIZE button; commit.

### Task 12b: Items, palette magic row, toasts

**Files:** Create `data/items/item_ids.gd` (`class_name ItemIds`), tests; modify `tools/make_atlas.gd` (item icons), `ui/hud/block_icons.gd`, `ui/hud/block_palette.gd`, `world/world_meta.gd` (default hotbar), `ui/hud/hud.gd` (`toast(text)`).
- [ ] Tests first (ids distinct from blocks, names, icons, new default hotbar); implement; commit.

### Task 12c: Mirror mode + batch undo

**Files:** Create `core/building/mirror_rules.gd`, tests; modify `core/building/undo_stack.gd` (`push_batch`), `autoloads/session.gd` (`request_set_blocks`), `entities/player/block_interactor.gd`, HUD MIRROR button + mirror plane visual.
- [ ] Tests first (mirror math for X/Z planes, self-mirror on plane, batch undo entry); implement; commit.

### Task 12d: Stamps

**Files:** Create `data/blueprints/blueprints.gd` (`class_name Blueprints`), tests; modify interactor (stamp placement, one batch undo).
- [ ] Tests first (each stamp non-empty, valid ids, bounded size, 4 rotations keep block count, rotation math); implement; commit.

### Task 12e: Magic Wand — living buddies

**Files:** Create `core/magic/capture_rules.gd`, `core/magic/buddy_traits.gd`, `core/magic/buddy_names.gd`, tests; `entities/buddy/buddy.gd`; modify `world/world_meta.gd` (buddies), `autoloads/session.gd` (`request_spark`, `request_sleep`), `scenes/sandbox.gd` (Buddies node + spawner + persistence), interactor (wand).
- [ ] Tests first (flood fill: connected only, terrain excluded, 200 cap, radius cap, start-on-terrain error; traits: speed by size, glow by light, float by glass; meta round trip with buddies); implement buddy node (mesh from captured blocks, googly eyes, name label, follow/hop, tap to cheer, wand to sleep); commit.

### Task 13: Android build and acceptance on the emulator

**Files:**
- Create: `tools/autopilot.gd` (developer-menu action), `docs/playtests/m1-template.md`, `docs/superpowers/notes/m1-acceptance.md`

**Interfaces:** Autopilot: flies or walks straight for a set distance at 6 m/s and logs `AUTOPILOT avg_fps=<n> max_frame_ms=<n> distance=<n>` to the log (logcat on Android).

- [ ] **Step 1:** Export the debug APK, install on the emulator, go through acceptance criteria 1–10 from spec §9.13 and record each result with evidence (logcat lines, screenshots) in `m1-acceptance.md`.
- [ ] **Step 2:** Fix any failure (each fix: failing check → fix → re-run), commit per fix.
- [ ] **Step 3:** `tests/run_tests.sh` passes.
- [ ] **Step 4:** Commit ("test: M1 acceptance on emulator").

### Task 14: Whole-branch review

- [ ] **Step 1:** Dispatch one reviewer (godot-prompter:godot-code-reviewer) over the whole `m1-first-steps` branch against the spec and this plan.
- [ ] **Step 2:** Fix confirmed findings (test first where applicable), re-run tests and the emulator smoke test.
- [ ] **Step 3:** Commit; leave the branch ready to merge into `main`.
