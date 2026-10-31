class_name AcceptanceTour
extends Node
## Developer "AUTOPILOT TOUR" for the M1b acceptance (plan Task 14; dev menu or --tour). Walks
## through the M1b features in the real game, one check after another, as the host (solo play is
## the host), through the real systems: Session requests, WorldService, the sandbox's hooks, the
## ChatCommandRunner and the animal, sleep and combat directors.
## Prints "TOUR <name> PASS|FAIL|SKIP <detail>" per check (logcat tag "godot" on Android),
## "TOUR_SHOT <name>" before holding still for SHOT_HOLD seconds (time for adb screencap), and
## "TOUR done passed=<n> failed=<m>" at the end.
## Never hangs: every check has a time limit. When it runs out, the check fails and the tour goes
## on; the abandoned check's waits (all of them go through frame/wait_seconds/wait_until_true)
## return false at once, and its late result is ignored.

const WARMUP := 3.0
const SHOT_HOLD := 3.0
## [name, time limit in seconds]; each runs as the method _check_<name>(gen) -> [ok, detail]
## (ok = null: skipped).
const CHECKS := [
	[&"bedrock", 180.0], [&"cave", 90.0], [&"water", 90.0], [&"underwater", 60.0], [&"settings", 20.0],
	[&"animals", 75.0], [&"bed", 60.0], [&"weapons", 60.0], [&"chat", 45.0], [&"avatar", 45.0],
	[&"buddies", 5.0], [&"peak", 120.0],
]
const DIG_PER_FRAME := 4
const CAVE_RADIUS := 128
const WATER_RADIUS := 400
const PEAK_RADIUS := 300
const ORE_SCAN := 10
const ORES: Array[int] = [BlockIds.COAL, BlockIds.IRON, BlockIds.GOLD, BlockIds.DIAMOND, BlockIds.CRYSTAL]
const MOVE_ACTIONS: Array[StringName] = [&"move_forward", &"move_back", &"move_left", &"move_right", &"jump", &"fly_up", &"fly_down"]

## scenes/sandbox.gd (null in tests: the checks below need it, fake checks don't).
var sandbox: Node
## Tests replace the real tour: [{"name", "limit", "run": Callable(gen: int) -> [ok, detail]}].
var checks: Array[Dictionary] = []
var warmup := WARMUP
var shot_hold := SHOT_HOLD
## Called with (passed, failed) at the end. Default: quit the app (--tour) or back to the menu.
var on_done: Callable
## Every TOUR and TOUR_SHOT line, in order.
var lines: Array[String] = []
static var results: Array[String] = []   # the same, for tools that cannot read stdout (godot-mcp exec)

var _gen := 0              # the running check; bumped when it ends, which abandons its waits
var _index := -1
var _t := 0.0
var _deadline := 0.0
var _result: Array = []
var _step := ""
var _passed := 0
var _failed := 0
var _done := false
var _feedback: Array[String] = []
var _chat_errors: Array[String] = []
var _frames := 0           # frame rate while the running check runs (TOUR_FPS lines)
var _seconds := 0.0
var _worst := 0.0
var _scout_cache: TourScout
var _level := TourScout.NO_COLUMN
var _panel_layer: CanvasLayer
var _settings := {}        # the player's settings before the tour, restored at the end


## The tour for a world of `mode`: Survivor worlds get the M2 tour (tools/tour_survivor.gd).
static func script_for(mode: StringName) -> String:
	return "res://tools/tour_survivor.gd" if mode == ModeRules.SURVIVOR else "res://tools/tour.gd"


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if checks.is_empty():
		var only := _only_checks(OS.get_cmdline_user_args())
		for c: Array in CHECKS:
			if only.is_empty() or only.has(String(c[0])):
				checks.append({"name": c[0], "limit": c[1], "run": Callable(self, "_check_" + String(c[0]))})
	if not on_done.is_valid():
		on_done = _default_done
	Session.magic_feedback.connect(_on_feedback)
	Session.chat_received.connect(_on_chat)


func _process(delta: float) -> void:
	if _done:
		return
	if _index < 0:
		if sandbox and not (_player() and _player().is_spawned()):
			return
		_t += delta
		if _t >= warmup:
			_begin()
		return
	_frames += 1
	_seconds += delta
	_worst = maxf(_worst, delta)
	if not _result.is_empty():
		_end_check(_result[0], str(_result[1]))
	elif _now() > _deadline:
		_end_check(false, "timeout after %s s%s" % [checks[_index].limit, " at: " + _step if _step != "" else ""])


# --- Runner -------------------------------------------------------------------------------------

## The checks named by a developer user arg --tour-only=a,b (all when absent).
static func _only_checks(args: PackedStringArray) -> PackedStringArray:
	for a in args:
		if a.begins_with("--tour-only="):
			return a.trim_prefix("--tour-only=").split(",", false)
	return PackedStringArray()


func _begin() -> void:
	if sandbox:
		var s: Dictionary = Profile.data.settings
		_settings = {"style": s.style, "max_jumps": s.max_jumps}
		print("TOUR begin seed=%d style=%s renderer=%s version=%s" % [sandbox.meta.seed, s.style,
			RenderingServer.get_current_rendering_method(), ProjectSettings.get_setting("application/config/version", "")])
	_start(0)


func _start(index: int) -> void:
	_index = index
	_gen += 1
	_result = []
	_step = ""
	_feedback.clear()
	_chat_errors.clear()
	_frames = 0
	_seconds = 0.0
	_worst = 0.0
	_deadline = _now() + float(checks[index].limit)
	_run(checks[index], _gen)


func _run(check: Dictionary, gen: int) -> void:
	var r: Variant = await (check.run as Callable).call(gen)
	if gen == _gen and _result.is_empty():
		_result = r if r is Array and (r as Array).size() == 2 else [false, "bad result %s" % [r]]


func _end_check(ok: Variant, detail: String) -> void:
	var check_name := String(checks[_index].name)
	if ok == null:
		_log("TOUR %s SKIP %s" % [check_name, detail])
	elif ok:
		_passed += 1
		_log("TOUR %s PASS %s" % [check_name, detail])
	else:
		_failed += 1
		_log("TOUR %s FAIL %s" % [check_name, detail])
	# Not one of the checked lines: slow frames explain many a timeout.
	print("TOUR_FPS %s avg=%.0f worst_ms=%.0f seconds=%.1f" % [check_name, _frames / maxf(_seconds, 0.001), _worst * 1000.0, _seconds])
	_gen += 1   # a timed-out check's waits end now
	_cleanup()
	if _index + 1 < checks.size():
		_start(_index + 1)
		return
	_done = true
	_restore_settings()
	_log("TOUR done passed=%d failed=%d" % [_passed, _failed])
	on_done.call(_passed, _failed)


func _on_feedback(text: String) -> void:
	_feedback.append(text)


func _on_chat(_from: String, text: String, kind: StringName) -> void:
	if kind == &"error":
		_chat_errors.append(text)


func _log(line: String) -> void:
	print(line)
	lines.append(line)
	results.append(line)


func _default_done(_passed_count: int, failed_count: int) -> void:
	if OS.get_cmdline_user_args().has("--tour"):
		get_tree().quit(0 if failed_count == 0 else 1)
	else:
		Game.quit_to_menu.call_deferred()


## Undoes what a check may leave behind (also after a timeout).
func _cleanup() -> void:
	for a in MOVE_ACTIONS:
		Input.action_release(a)
	if _panel_layer:
		_panel_layer.queue_free()
		_panel_layer = null
	var p := _player()
	if p == null:
		return
	if p.rig.first_person:
		p.toggle_camera()
	if p.sleeping:
		Session.request_bed_wake()


# --- Waiting (every wait of a check goes through these) ----------------------------------------

## What the running check is doing now (named in its timeout line).
func note(step: String) -> void:
	_step = step


## Waits one frame; false once the check `gen` has been abandoned.
func frame(gen: int) -> bool:
	await get_tree().process_frame
	return gen == _gen


func wait_seconds(seconds: float, gen: int) -> bool:
	var end := _now() + seconds
	while _now() < end:
		if not await frame(gen):
			return false
	return gen == _gen


## A wait gives up only after its time and this many frames: on a crowded emulator one frame can
## take longer than a wait's whole budget (a shader compile, chunk meshing), and a check that saw one
## frame said nothing about the game (the M1b tour at load 30, devlog M2 16:30).
const MIN_WAIT_FRAMES := 10


## Waits until cond() is true (true) or `timeout` seconds pass or the check is abandoned (false).
func wait_until_true(cond: Callable, timeout: float, gen: int) -> bool:
	var end := _now() + timeout
	var frames := 0
	while not cond.call():
		if (_now() >= end and frames >= MIN_WAIT_FRAMES) or not await frame(gen):
			return false
		frames += 1
	return gen == _gen


## A moment worth a screenshot: announce it, then hold still for shot_hold seconds.
func shot(shot_name: String, gen: int) -> bool:
	if gen != _gen:
		return false
	_log("TOUR_SHOT " + shot_name)
	return await wait_seconds(shot_hold, gen)


func _now() -> float:
	return Time.get_ticks_msec() / 1000.0


static func _abandoned() -> Array:
	return [false, "abandoned"]


# --- The game -----------------------------------------------------------------------------------

func _player() -> Player:
	return sandbox.get("player") as Player if sandbox else null


func _world() -> WorldService:
	return sandbox.get("world") as WorldService if sandbox else null


func _interactor() -> BlockInteractor:
	return _player().get_node("BlockInteractor") as BlockInteractor


func _scout() -> TourScout:
	if _scout_cache == null:
		_scout_cache = TourScout.new(int(sandbox.meta.seed), sandbox.meta.terrain)   # owner #45b: the world's terrain
	return _scout_cache


## The world spawn column (a fresh world: where the player started).
func _home() -> Vector2i:
	return _world().spawn_column()


## Level, dry ground near the spawn (the spawn itself when there is none): animals are called,
## beds and targets placed there. On a slope a summoned animal can start inside the hill and
## fall through the world (found by this tour; see docs/devlog/parts/tour.md).
func _level_ground() -> Vector2i:
	if _level == TourScout.NO_COLUMN:
		_level = _scout().flat(_home(), 64)
		if _level == TourScout.NO_COLUMN:
			_level = _home()
	return _level


## Puts the player's feet at `pos` in physics `mode` the way /tp does, then waits until the
## terrain there is loaded.
func _go(pos: Vector3, mode: int, gen: int, timeout: float = 30.0) -> bool:
	var p := _player()
	p.set_physics_mode(mode)
	p.spawn_at(pos)
	if not await wait_until_true(p.is_spawned, timeout, gen):
		return false
	return await wait_until_true(func() -> bool: return _world().is_area_ready(pos), timeout, gen)


## Stands the player on the ground of column c in walking mode, the way /spawn does.
func _go_surface(c: Vector2i, gen: int, timeout: float = 30.0) -> bool:
	var p := _player()
	p.set_physics_mode(PhysicsMode.Mode.NORMAL)
	p.spawn_on_surface(c.x, c.y)
	if not await wait_until_true(p.is_spawned, timeout, gen):
		return false
	return await wait_until_true(p.is_on_floor, 5.0, gen)


## Turns the camera (and the avatar) towards the flat part of `dir`, looking down by -pitch.
func _face(dir: Vector3, pitch: float = -0.35) -> void:
	var p := _player()
	if Vector2(dir.x, dir.z).length() > 0.001:
		p.rig.yaw = atan2(-dir.x, -dir.z)
		p.avatar.rotation.y = p.rig.yaw
	p.rig.pitch = clampf(pitch, CameraRig.PITCH_MIN, CameraRig.PITCH_MAX)


## Of 8 flat directions, the one with the most even dry ground over the next `length` blocks.
func _walk_direction(length: int) -> Vector3:
	var shape := _world().generator_shape()
	var from := _player().global_position
	var h0 := shape.height_at(floori(from.x), floori(from.z))
	var best := Vector3.FORWARD
	var best_cost := INF
	for i in 8:
		var d := Vector3(cos(TAU * i / 8.0), 0.0, sin(TAU * i / 8.0))
		var cost := 0.0
		for s in range(1, length + 1):
			var x := floori(from.x + d.x * s)
			var z := floori(from.z + d.z * s)
			var h := shape.height_at(x, z)
			cost += absf(h - h0)
			if h <= MeadowsShape.SEA_LEVEL + 1 or shape.is_river(x, z):
				cost += 100.0
			if shape.tree_at(x, z):
				cost += 10.0
		if cost < best_cost:
			best = d
			best_cost = cost
	return best


## True when the `rows` cells above `cell` are empty.
func _open_above(cell: Vector3i, rows: int) -> bool:
	for dy in range(1, rows + 1):
		if _world().get_block(cell + Vector3i(0, dy, 0)) != BlockIds.AIR:
			return false
	return true


## A cell `dist` blocks from the player along `dir` (a step up or down allowed) where a practice
## target or a bed fits: air with air above, on solid ground. TourScout.NOT_FOUND if none.
func _spot_ahead(dir: Vector3, dist: float) -> Vector3i:
	var base := Vector3i((_player().global_position + dir.normalized() * dist).floor())
	for dy in [0, 1, -1, 2, -2]:
		var c: Vector3i = base + Vector3i(0, dy, 0)
		if WeaponRules.target_spot_ok(c, _world().get_block):
			return c
	return TourScout.NOT_FOUND


func _last_feedback() -> String:
	return _feedback.back() if not _feedback.is_empty() else ""


func _animals() -> Array[Animal]:
	var list: Array[Animal] = []
	for n in get_tree().get_nodes_in_group(&"animals"):
		if n is Animal and not n.is_queued_for_deletion():
			list.append(n)
	return list


func _count_species(species: StringName) -> int:
	return _animals().filter(func(a: Animal) -> bool: return a.species == species).size()


## Same as the settings panel: saved in the profile and applied at once.
func _store_setting(key: String, value: Variant) -> void:
	Profile.data.settings[key] = value
	Profile.save()
	Game.apply_settings()


## The value of a setting in the saved profile file (not the copy in memory).
static func _saved_setting(key: String) -> Variant:
	return ProfileData.from_json(JsonStore.read_text(Profile.PATH)).settings.get(key)


func _restore_settings() -> void:
	for key: String in _settings:
		if Profile.data.settings.get(key) != _settings[key]:
			_store_setting(key, _settings[key])


# --- 1. Dig to bedrock; bedrock can't be broken -------------------------------------------------

func _check_bedrock(gen: int) -> Array:
	var p := _player()
	var w := _world()
	var col := _home() + Vector2i(6, 0)   # beside the spawn: walking checks come back to it
	var cell := Vector3i(col.x, w.surface_height(col.x, col.y) - 1, col.y)
	var top := cell.y
	var top_id := w.get_block(cell)
	var dug := 0
	var steps := 0
	var t0 := _now()
	p.set_physics_mode(PhysicsMode.Mode.GHOST)
	while cell.y >= MeadowsShape.WORLD_BOTTOM:
		p.global_position = Vector3(col.x + 0.5, cell.y + 1.05, col.y + 0.5)   # stands in the shaft
		note("digging at y=%d, %d blocks dug" % [cell.y, dug])
		steps += 1
		if not w.is_editable(cell):
			if not await frame(gen):
				return _abandoned()
			continue
		var id := w.get_block(cell)
		if id == BlockIds.BEDROCK:
			break
		if id != BlockIds.AIR and not Session.request_set_block(cell, BlockIds.AIR):
			return [false, "the host refused to dig %s at %s: %s" % [BlockIds.display_name(id), cell, _last_feedback()]]
		if id != BlockIds.AIR:
			dug += 1
		cell.y -= 1
		if steps % DIG_PER_FRAME == 0 and not await frame(gen):
			return _abandoned()
	if w.get_block(cell) != BlockIds.BEDROCK:
		return [false, "no bedrock down to y=%d" % cell.y]
	_feedback.clear()
	var broke := Session.request_set_block(cell, BlockIds.AIR)
	if not await wait_seconds(0.3, gen):
		return _abandoned()
	var now_id := w.get_block(cell)
	var said := _last_feedback()
	# Close the shaft again at the top (a player would), so no later walk falls 90 blocks down it.
	var lid := Vector3i(col.x, top, col.y)
	p.global_position = Vector3(col.x + 0.5, top + 2.05, col.y + 0.5)
	await wait_until_true(func() -> bool: return w.is_editable(lid), 5.0, gen)
	var closed := top_id == BlockIds.AIR or Session.request_set_block(lid, top_id)
	return [dug > 0 and not broke and now_id == BlockIds.BEDROCK,
		"dug %d blocks at x=%d z=%d from y=%d down to bedrock at y=%d in %.1f s; breaking the bedrock was %s (\"%s\"), it is %s; shaft closed again: %s" % [
		dug, col.x, col.y, top, cell.y, _now() - t0, "ACCEPTED" if broke else "refused", said, BlockIds.display_name(now_id),
		"yes" if closed else "NO"]]


# --- 2. A cave: dark, lantern, ores and crystals -------------------------------------------------

func _check_cave(gen: int) -> Array:
	var p := _player()
	var w := _world()
	note("looking for a cave")
	var spot := _scout().cave(_home(), CAVE_RADIUS, -38, -22)   # deep and dry: where crystals grow
	if spot == TourScout.NOT_FOUND:
		spot = _scout().cave(_home(), CAVE_RADIUS, -38, MeadowsShape.SEA_LEVEL)
	if spot == TourScout.NOT_FOUND:
		return [false, "no dry cave within %d blocks of the spawn" % CAVE_RADIUS]
	note("going into the cave at %s" % spot)
	if not await _go(Vector3(spot) + Vector3(0.5, 0.05, 0.5), PhysicsMode.Mode.GHOST, gen):
		return [false, "the cave at %s did not load" % spot]
	var here := w.get_block(spot)
	var amb := sandbox.get_node("Ambience") as Ambience
	var dark := await wait_until_true(func() -> bool: return amb.underground >= 0.99, 6.0, gen)
	if not await wait_seconds(1.0, gen):   # the mood settles; more of the cave streams in
		return _abandoned()
	var base: Dictionary = w.ambience_base
	var sun := w.sun().light_energy
	var ambient := w.environment().ambient_light_energy
	var darker := sun < float(base.sun) * 0.5 and ambient < float(base.ambient) * 0.5
	var lantern := p.get_node_or_null("Lantern") as OmniLight3D
	var lit := lantern != null and lantern.visible and lantern.light_energy > 0.5
	var counts := {}
	var total := 0
	var nearest := Vector3i.ZERO
	var nearest_d := INF
	for dz in range(-ORE_SCAN, ORE_SCAN + 1):
		for dy in range(-ORE_SCAN, ORE_SCAN + 1):
			for dx in range(-ORE_SCAN, ORE_SCAN + 1):
				var c := spot + Vector3i(dx, dy, dz)
				var id := w.get_block(c)
				if not ORES.has(id):
					continue
				counts[BlockIds.display_name(id)] = int(counts.get(BlockIds.display_name(id), 0)) + 1
				total += 1
				var d := Vector3(c - spot).length()
				if d < nearest_d:
					nearest_d = d
					nearest = c
	if total > 0:
		_face(Vector3(nearest) + Vector3(0.5, 0.5, 0.5) - p.eye_position(), -0.2)
	if not await shot("cave", gen):
		return _abandoned()
	var home := _home()
	return [here == BlockIds.AIR and dark and darker and lit and total > 0,
		"cave at %s, %d blocks from the spawn (%s): underground=%.2f, sun %.2f (open air %.2f), ambient %.2f (open air %.2f), lantern %s; ores and crystals within %d blocks: %d %s" % [
		spot, roundi(Vector2(spot.x - home.x, spot.z - home.y).length()), "air" if here == BlockIds.AIR else BlockIds.display_name(here), amb.underground,
		sun, float(base.sun), ambient, float(base.ambient), "on" if lit else "OFF", ORE_SCAN, total, counts]]


# --- 3. Water near the spawn; water flows into a dug hole ----------------------------------------

func _check_water(gen: int) -> Array:
	var p := _player()
	var w := _world()
	var shape := w.generator_shape()
	var home := _home()
	note("looking for water")
	var river := _scout().water(home, WATER_RADIUS, 1, TourScout.RIVER)
	var sea := _scout().water(home, WATER_RADIUS, 1, TourScout.SEA)
	var seen := "river %s, sea or lake %s" % [_distance_text(river, home), _distance_text(sea, home)]
	var s := _scout().shore(home, WATER_RADIUS)
	if s.is_empty():
		return [false, "no water within %d blocks of the spawn (%s)" % [WATER_RADIUS, seen]]
	var land: Vector2i = s.land
	var water: Vector2i = s.water
	var line := MeadowsShape.SEA_LEVEL - 1
	var hole := Vector3i(land.x, line, land.y)
	var wet := Vector3i(water.x, line, water.y)
	# Hover a block inland (over the bank itself if that is a cliff), looking at the water.
	var stand := land + (land - water)
	if shape.height_at(stand.x, stand.y) > shape.height_at(land.x, land.y) + 3:
		stand = land
	var y := maxi(maxi(shape.height_at(stand.x, stand.y), shape.height_at(land.x, land.y)), MeadowsShape.SEA_LEVEL) + 2
	note("going to the shore at %s" % hole)
	if not await _go(Vector3(stand.x + 0.5, y + 0.05, stand.y + 0.5), PhysicsMode.Mode.GHOST, gen):
		return [false, "the shore at %s did not load (%s)" % [hole, seen]]
	if not await wait_until_true(func() -> bool: return w.is_editable(hole) and w.is_editable(wet), 10.0, gen):
		return [false, "the shore at %s is not editable" % hole]
	if w.get_block(wet) != BlockIds.WATER:
		return [false, "no water at %s in the loaded world (%s)" % [wet, BlockIds.display_name(w.get_block(wet))]]
	_face(Vector3(wet) - p.eye_position(), -0.6)
	# An open hole from the top of the bank down to the waterline, beside the water.
	var top := maxi(shape.height_at(land.x, land.y) - 1, line)
	for dig_y in range(top, line - 1, -1):
		var c := Vector3i(land.x, dig_y, land.y)
		if w.get_block(c) != BlockIds.AIR and not Session.request_set_block(c, BlockIds.AIR):
			return [false, "the host refused to dig %s: %s" % [c, _last_feedback()]]
	var t0 := _now()
	var filled := await wait_until_true(func() -> bool: return w.get_block(hole) == BlockIds.WATER, 10.0, gen)
	var took := _now() - t0
	if not await shot("water", gen):
		return _abandoned()
	return [filled, "%s; dug a hole at %s beside the water at %s (%s): %s" % [seen, hole, wet,
		"river" if shape.is_river(water.x, water.y) else "sea or lake",
		"water flowed in after %.1f s" % took if filled else "still %s after 10 s" % BlockIds.display_name(w.get_block(hole))]]


func _distance_text(c: Vector2i, home: Vector2i) -> String:
	if c == TourScout.NO_COLUMN:
		return "none within %d blocks" % WATER_RADIUS
	return "%d blocks away at (%d, %d)" % [roundi(Vector2(c - home).length()), c.x, c.y]


# --- 4. Under water: blue tint and fog; building and digging work --------------------------------

func _check_underwater(gen: int) -> Array:
	var p := _player()
	var w := _world()
	var shape := w.generator_shape()
	var col := _scout().water(_home(), WATER_RADIUS, 3)
	if col == TourScout.NO_COLUMN:
		return [false, "no water 3 deep within %d blocks of the spawn" % WATER_RADIUS]
	var ground := shape.height_at(col.x, col.y)
	var feet := Vector3i(col.x, ground, col.y)
	note("diving at %s" % feet)
	if not await _go(Vector3(feet) + Vector3(0.5, 0.05, 0.5), PhysicsMode.Mode.GHOST, gen):
		return [false, "the water at %s did not load" % feet]
	p.toggle_camera()   # first person: the camera is in the water too
	var cell := TourScout.NOT_FOUND
	for side: Vector3i in [Vector3i.RIGHT, Vector3i.LEFT, Vector3i.FORWARD, Vector3i.BACK]:
		if w.get_block(feet + side) == BlockIds.WATER:
			cell = feet + side
			break
	if cell != TourScout.NOT_FOUND:
		_face(Vector3(cell - feet), -0.15)
	var amb := sandbox.get_node("Ambience") as Ambience
	var under := await wait_until_true(func() -> bool: return amb.underwater >= 1.0, 5.0, gen)
	var tint := amb.get("_tint") as ColorRect
	var env := w.environment()
	var fog := env.fog_light_color
	var foggy := env.fog_depth_end <= AmbienceRules.WATER_FOG_END + 0.5 \
		and Vector3(fog.r - AmbienceRules.WATER_FOG.r, fog.g - AmbienceRules.WATER_FOG.g, fog.b - AmbienceRules.WATER_FOG.b).length() < 0.03
	var tinted := tint != null and tint.visible
	if cell == TourScout.NOT_FOUND:
		return [false, "no water beside %s to build in" % feet]
	var placed := Session.request_set_block(cell, BlockIds.STONE) and w.get_block(cell) == BlockIds.STONE
	if not await shot("underwater", gen):
		return _abandoned()
	var dug := Session.request_set_block(cell, BlockIds.AIR) and w.get_block(cell) != BlockIds.STONE
	var refilled := await wait_until_true(func() -> bool: return w.get_block(cell) == BlockIds.WATER, 3.0, gen)
	return [under and tinted and foggy and placed and dug,
		"%d deep at %s: underwater=%.2f, tint %s, fog %s (ends at %.0f); placed STONE in the water at %s: %s; dug it out: %s (water flowed back: %s)" % [
		MeadowsShape.SEA_LEVEL - ground, feet, amb.underwater, "on" if tinted else "OFF", "blue" if foggy else "NOT BLUE (%s)" % fog.to_html(false),
		env.fog_depth_end, cell, "yes" if placed else "NO", "yes" if dug else "NO", "yes" if refilled else "no"]]


# --- 5. Settings: jumps and style switch at once and are saved -----------------------------------

func _check_settings(gen: int) -> Array:
	var p := _player()
	var orig_jumps := int(Profile.data.settings.max_jumps)
	var orig_style := str(Profile.data.settings.style)
	_panel_layer = CanvasLayer.new()
	_panel_layer.layer = 5
	add_child(_panel_layer)
	var panel := SettingsPanel.new()   # the real settings panel (the pause menu shows the same)
	_panel_layer.add_child(panel)
	if not await frame(gen):
		return _abandoned()
	var steps := [
		["TRIPLE", "max_jumps", 3, func() -> bool: return p._jumps.max_jumps == 3],
		["DOUBLE", "max_jumps", 2, func() -> bool: return p._jumps.max_jumps == 2],
		["REALISTIC", "style", "realistic", func() -> bool: return BlockLibrary.style == "realistic" and p.avatar is RealisticAvatar],
		["BLOCKY", "style", "blocky", func() -> bool: return BlockLibrary.style == "blocky" and p.avatar is BlockyAvatar],
	]
	var ok := true
	var said: Array[String] = []
	for s: Array in steps:
		var button := _button(panel, s[0])
		if button == null:
			return [false, "no %s button in the settings" % s[0]]
		button.pressed.emit()
		var at_once: bool = (s[3] as Callable).call()   # same frame: no waiting
		var saved: bool = _saved_setting(s[1]) == s[2]
		ok = ok and at_once and saved
		said.append("%s %s%s" % [s[0], "at once" if at_once else "NOT APPLIED", ", saved" if saved else ", NOT SAVED"])
	var jumps_button := _button(panel, "TRIPLE" if orig_jumps == 3 else "DOUBLE")
	var style_button := _button(panel, orig_style.to_upper())
	if jumps_button:
		jumps_button.pressed.emit()
	if style_button:
		style_button.pressed.emit()
	var restored: bool = _saved_setting("max_jumps") == orig_jumps and _saved_setting("style") == orig_style
	return [ok and restored, "%s; restored %s jumps and %s style: %s" % [", ".join(said), orig_jumps, orig_style,
		"yes" if restored else "NO"]]


static func _button(root: Node, text: String) -> Button:
	for b in root.find_children("*", "Button", true, false):
		if (b as Button).text == text:
			return b
	return null


# --- 6. Animals near the spawn; tame a dog: it follows and sits ----------------------------------

func _check_animals(gen: int) -> Array:
	var p := _player()
	note("going to level ground near the spawn")
	if not await _go_surface(_level_ground(), gen):
		return [false, "could not stand on level ground at %s" % _level_ground()]
	var near := func() -> Array:
		return _animals().filter(func(a: Animal) -> bool:
			return Vector2(a.global_position.x - p.global_position.x, a.global_position.z - p.global_position.z).length() \
				<= AnimalRules.SPAWN_RADIUS * 1.5)
	note("waiting for animals")
	var appeared := await wait_until_true(func() -> bool: return not (near.call() as Array).is_empty(), 20.0, gen)
	var kinds := {}
	var seen: Array = near.call()
	for a: Animal in seen:
		kinds[String(a.species)] = int(kinds.get(String(a.species), 0)) + 1
	# A dog comes when called (the sandbox hook /summon uses) right next to the player, who then walks
	# away from it over even ground.
	var dir := _walk_direction(12)
	_face(dir)
	var before := _animals()
	var why: String = sandbox.summon_animal(&"dog", p.global_position)   # as /summon dog does
	if why != "":
		return [false, "%d animals around the player %s; no dog came: %s" % [seen.size(), kinds, why]]
	var dog: Animal = null
	for a in _animals():
		if not before.has(a) and a.species == &"dog":
			dog = a
	if dog == null:
		return [false, "the summoned dog is missing"]
	if not await wait_seconds(0.6, gen):
		return _abandoned()
	note("petting %s" % dog.name)
	for i in AnimalRules.TAME_TAPS:   # three quick pets, like three taps on it
		if not is_instance_valid(dog):
			return [false, "the dog vanished"]
		Session.request_pet(dog.name)
		dog.cheer()
		if not await wait_seconds(0.3, gen):
			return _abandoned()
	if not is_instance_valid(dog):
		return [false, "the dog vanished while being petted (fell out of the world?)"]
	var tamed := dog.is_pet() and dog.owner_peer == p.peer_id and dog.pet_name != ""
	var pet_name := dog.pet_name
	if not await frame(gen):
		return _abandoned()
	if not is_instance_valid(dog):
		return [false, "the dog vanished right after taming"]
	var collar := dog.find_child("Collar", true, false) != null
	# Walk on; the pet follows.
	Input.action_press(&"move_forward")
	var walked := await wait_seconds(1.6, gen)
	Input.action_release(&"move_forward")
	if not walked:
		return _abandoned()
	var flat := func() -> float:
		return Vector2(dog.global_position.x - p.global_position.x, dog.global_position.z - p.global_position.z).length() \
			if is_instance_valid(dog) else INF
	var from: float = flat.call()
	note("waiting for %s to follow" % pet_name)
	var followed := await wait_until_true(func() -> bool: return flat.call() <= Animal.FOLLOW_DISTANCE + 1.5, 10.0, gen)
	var to: float = flat.call()
	# The owner's tap: sit.
	if not is_instance_valid(dog):
		return [false, "%s vanished while following (fell out of the world?)" % pet_name]
	Session.request_pet(dog.name)
	var sat := await wait_until_true(func() -> bool: return is_instance_valid(dog) and dog.sitting, 1.0, gen)
	if is_instance_valid(dog):
		_face(dog.global_position - p.global_position, -0.45)
	if not await shot("animals", gen):
		return _abandoned()
	return [appeared and tamed and collar and followed and sat,
		"%d animals around the player %s; dog %s tamed with 3 pets: %s (\"%s\"), collar: %s, followed from %.1f to %.1f blocks: %s, a tap makes it sit: %s" % [
		seen.size(), kinds, pet_name, "yes" if tamed else "NO", _feedback[0] if not _feedback.is_empty() else "",
		"yes" if collar else "NO", from, to, "yes" if followed else "NO", "yes" if sat else "NO"]]


# --- 7. A bed: sleep through the night; falling out of the world returns home -------------------

func _check_bed(gen: int) -> Array:
	var p := _player()
	var sky := sandbox.get("sky") as SkyCycle
	if not await _go_surface(_level_ground(), gen):
		return [false, "could not stand on level ground at %s" % _level_ground()]
	var bed := TourScout.NOT_FOUND
	for i in 8:
		bed = _spot_ahead(Vector3.FORWARD.rotated(Vector3.UP, TAU * i / 8.0), 2.0)
		if bed != TourScout.NOT_FOUND and BedRules.lie_position(bed).distance_to(p.global_position) <= BedRules.REACH \
				and _open_above(bed, 3):   # going home stands the player on the bed
			break
		bed = TourScout.NOT_FOUND
	if bed == TourScout.NOT_FOUND:
		return [false, "no room for a bed around %s" % p.global_position.floor()]
	if not Session.request_set_block(bed, BlockIds.BED):
		return [false, "the host refused the bed at %s: %s" % [bed, _last_feedback()]]
	sandbox.set_time_of_day(DayCycle.MIDNIGHT)   # the host's clock hook (/time uses it)
	var night := sky.time
	note("sleeping in the bed at %s" % bed)
	Session.request_bed_sleep(bed)   # the SLEEP button's request
	var slept := await wait_until_true(func() -> bool: return p.sleeping, 3.0, gen)
	var is_home := p.has_home and p.home_bed == bed
	var woke := false
	if slept:
		woke = await wait_until_true(func() -> bool: return not p.sleeping, SleepDirector.SKIP_DELAY + 5.0, gen)
	var morning := sky.time
	var sunrise := absf(morning - DayCycle.SUNRISE) < 0.01
	# Far from the bed, fall out of the world.
	var away := Vector2i(bed.x + 24, bed.z)
	note("walking away from the bed")
	if not await _go_surface(away, gen):
		return [false, "could not go 24 blocks away from the bed"]
	var target := BedRules.home_position(bed)
	var fell_from := p.global_position.distance_to(target)
	p.global_position.y = SpawnRules.FALL_LIMIT_Y - 6.0
	note("falling out of the world")
	var back := await wait_until_true(func() -> bool:
		return p.is_spawned() and p.global_position.distance_to(target) < 1.5, 20.0, gen)
	return [slept and is_home and woke and sunrise and back,
		"bed at %s; at night (%.2f) the player sleeps: %s, it is home: %s, woke up: %s at %.3f (sunrise %.2f): %s; fell out of the world %.0f blocks from home, back on the bed: %s (at %s)" % [
		bed, night, "yes" if slept else "NO", "yes" if is_home else "NO", "yes" if woke else "NO", morning, DayCycle.SUNRISE,
		"yes" if sunrise else "NO", fell_from, "yes" if back else "NO", p.global_position.snapped(Vector3.ONE * 0.1)]]


# --- 8. Weapons: sword on a dummy, an arrow in a bullseye, the axe fells a tree ------------------

func _check_weapons(gen: int) -> Array:
	var p := _player()
	var w := _world()
	var it := _interactor()
	if not await _go_surface(_level_ground(), gen):
		return [false, "could not stand on level ground at %s" % _level_ground()]
	var avoid: Array[Vector3i] = []
	if p.has_home:
		avoid.append(p.home_bed)
	var spots := _target_spots(avoid)
	if spots.is_empty():
		return [false, "no flat ground for the targets around %s" % p.global_position.floor()]
	var dummy_cell := spots[0]
	var eye_cell := spots[1]
	_face(Vector3(dummy_cell - Vector3i(p.global_position.floor())))
	it.set_slot_block(0, ItemIds.SWORD)
	var dummy: PracticeTarget = await _place_target(ItemIds.DUMMY, dummy_cell, gen)
	var eye_target: PracticeTarget = await _place_target(ItemIds.BULLSEYE, eye_cell, gen)
	var eye := eye_target as Bullseye
	if dummy == null or eye == null:
		return [false, "targets not placed (dummy %s, bullseye %s): %s" % [dummy != null, eye != null, _last_feedback()]]
	var swung := it.weapons.attack_towards(ItemIds.SWORD, dummy.center(), 1.0)
	var hit := await wait_until_true(func() -> bool: return dummy.hits_taken >= 1, 1.5, gen)
	it.set_slot_block(0, ItemIds.BOW)
	if not await wait_seconds(0.8, gen):   # the sword's cooldown
		return _abandoned()
	_face(eye.center() - p.eye_position(), -0.1)
	var shot_off := it.weapons.attack_towards(ItemIds.BOW, eye.center(), 1.0)
	var scored := await wait_until_true(func() -> bool: return eye.last_score > 0, 3.0, gen)
	if not await shot("weapons", gen):
		return _abandoned()
	# The axe: a real tree nearby comes down in one blow (the same edits a tap with the axe makes).
	note("looking for a tree")
	var log_cell := _find_log(40)
	var felled := false
	var tree_size := 0
	if log_cell != TourScout.NOT_FOUND:
		var edits := ToolPowers.for_tool(ItemIds.AXE, log_cell, Vector3i.UP, 0, w.get_block)
		tree_size = edits.size()
		it.set_slot_block(0, ItemIds.AXE)
		if p.eye_position().distance_to(Vector3(log_cell)) > PlacementRules.BATCH_REACH - 4.0:
			p.set_physics_mode(PhysicsMode.Mode.GHOST)
			p.global_position = Vector3(log_cell) + Vector3(2.5, 0.0, 0.5)
		if tree_size > 0 and it.apply_edits(edits, false):
			felled = await wait_until_true(func() -> bool: return _all_applied(edits), 2.0, gen)
		p.set_physics_mode(PhysicsMode.Mode.NORMAL)
	return [swung and hit and shot_off and scored and felled,
		"sword on the dummy: %s (%d damage); arrow in the bullseye: %s (scored %d); the axe fells the tree at %s: %s (%d blocks)" % [
		"hit" if hit else "MISSED", dummy.last_damage, "yes" if scored else "NO", eye.last_score,
		log_cell if log_cell != TourScout.NOT_FOUND else "(none within 40)", "yes" if felled else "NO", tree_size]]


## A spot for the practice dummy 2 blocks away (in the sword's reach) and one for the bullseye 4 to
## 6 blocks away, at least a quarter turn from the dummy and with a clear line of flight from the
## eye; neither next to a cell in `avoid` (the bed). [] when there are none.
func _target_spots(avoid: Array[Vector3i]) -> Array[Vector3i]:
	var p := _player()
	for i in 16:
		var a := TAU * i / 16.0
		var dummy := _spot_ahead(Vector3(cos(a), 0.0, sin(a)), 2.0)
		if dummy == TourScout.NOT_FOUND or _next_to(dummy, avoid):
			continue
		for j in range(4, 13):
			var b := a + TAU * j / 16.0
			for dist: float in [5.0, 4.0, 6.0]:
				var eye := _spot_ahead(Vector3(cos(b), 0.0, sin(b)), dist)
				if eye == TourScout.NOT_FOUND or _next_to(eye, avoid) or _next_to(eye, [dummy]):
					continue
				if _clear_line(p.eye_position(), Vector3(eye) + Vector3(0.5, 1.0, 0.5)):
					var found: Array[Vector3i] = [dummy, eye]
					return found
	var none: Array[Vector3i] = []
	return none


func _next_to(cell: Vector3i, others: Array) -> bool:
	for o: Vector3i in others:
		if absi(o.x - cell.x) <= 1 and absi(o.z - cell.z) <= 1 and absi(o.y - cell.y) <= 2:
			return true
	return false


## No solid block on the straight line between two points (sampled every quarter block).
func _clear_line(from: Vector3, to: Vector3) -> bool:
	var steps := ceili(from.distance_to(to) * 4.0)
	for k in range(1, steps):
		if BlockIds.is_solid(_world().get_block(Vector3i(from.lerp(to, float(k) / steps).floor()))):
			return false
	return true


## True when every edit [[pos, id], ...] is in the world.
func _all_applied(edits: Array) -> bool:
	for e: Array in edits:
		if _world().get_block(e[0]) != e[1]:
			return false
	return true


## Asks the host for a practice target (like a tap with it) and waits for it to stand there.
func _place_target(item: int, cell: Vector3i, gen: int) -> PracticeTarget:
	var p := _player()
	var to_player := p.global_position - (Vector3(cell) + Vector3(0.5, 0.0, 0.5))
	Session.request_place_target(item, cell, atan2(-to_player.x, -to_player.z))   # it faces the player
	var combat := sandbox.get_node("Combat") as CombatDirector
	var found: Array[PracticeTarget] = []
	var ok := await wait_until_true(func() -> bool:
		for t in combat.targets():
			if t.item_id == item and t.cell() == cell:
				found.append(t)
				return true
		return false, 2.0, gen)
	return found[0] if ok else null


## A log of a natural tree within `radius` blocks of the player (nearest ring first).
func _find_log(radius: int) -> Vector3i:
	var w := _world()
	var feet := Vector3i(_player().global_position.floor())
	for r in range(1, radius):
		for dx in range(-r, r + 1):
			for dz in [-r, r]:
				for pos: Vector3i in [Vector3i(dx, 0, dz), Vector3i(dz, 0, dx)]:
					for dy in range(-6, 10):
						var c := feet + pos + Vector3i(0, dy, 0)
						if w.get_block(c) == BlockIds.LOG and not ToolPowers.fell_tree(c, w.get_block).is_empty():
							return c
	return TourScout.NOT_FOUND


# --- 9. Chat commands -----------------------------------------------------------------------------

func _check_chat(gen: int) -> Array:
	var p := _player()
	var sky := sandbox.get("sky") as SkyCycle
	var runner := sandbox.get_node("ChatCommands") as ChatCommandRunner
	var said: Array[String] = []
	runner.run("/time night")
	var night := await wait_until_true(func() -> bool: return absf(sky.time - ChatCommands.TIME_NIGHT) < 0.01, 2.0, gen)
	said.append("/time night: %s (%.3f)" % ["yes" if night else "NO", sky.time])
	var y0 := p.global_position.y
	var landed: Array[float] = []
	p.spawned.connect(func() -> void: landed.append(p.global_position.y), CONNECT_ONE_SHOT)
	runner.run("/tp ~ ~20 ~")
	var arrived := await wait_until_true(func() -> bool: return not landed.is_empty(), 10.0, gen)
	var tp := arrived and absf(landed[0] - (y0 + 20.0)) < 1.0
	said.append("/tp ~ ~20 ~: %s (y %.1f -> %s)" % ["yes" if tp else "NO", y0, "%.1f" % landed[0] if arrived else "?"])
	runner.run("/give diamond")
	var gave := _interactor().selected_block() == BlockIds.DIAMOND
	said.append("/give diamond: %s" % ("yes" if gave else "NO"))
	await wait_until_true(p.is_on_floor, 5.0, gen)   # back on the ground (no matter if not)
	var dogs := _count_species(&"dog")
	runner.run("/summon dog")
	var summoned := await wait_until_true(func() -> bool: return _count_species(&"dog") > dogs, 3.0, gen)
	said.append("/summon dog: %s (%d -> %d dogs)" % ["yes" if summoned else "NO", dogs, _count_species(&"dog")])
	runner.run("/time day")   # daylight again for the pictures still to come
	var day := await wait_until_true(func() -> bool: return absf(sky.time - ChatCommands.TIME_DAY) < 0.01, 2.0, gen)
	said.append("/time day: %s" % ("yes" if day else "NO"))
	if not _chat_errors.is_empty():
		said.append("errors: %s" % [_chat_errors])
	return [night and tp and gave and summoned and day, "; ".join(said)]


# --- 10. The realistic avatar walks and holds a weapon -------------------------------------------

func _check_avatar(gen: int) -> Array:
	var p := _player()
	var it := _interactor()
	if not await _go_surface(_level_ground(), gen):
		return [false, "could not stand on level ground at %s" % _level_ground()]
	var orig := str(Profile.data.settings.style)
	_store_setting("style", "realistic")
	var person := p.avatar as RealisticAvatar
	if person == null:
		return [false, "the avatar is %s in the realistic style" % p.avatar.get_script().resource_path.get_file()]
	it.set_slot_block(0, ItemIds.SWORD)
	# Wait for it, not a fixed time: the style switch makes one long frame.
	var holds := await wait_until_true(func() -> bool:
		for n in person.hand().get_children():
			if n is HeldItem and (n as HeldItem).visible and (n as HeldItem).item_id == ItemIds.SWORD:
				return true
		return false, 2.0, gen)
	var in_hand: Array[String] = []
	for n in person.hand().get_children():
		in_hand.append("%s(item %d, visible %s)" % [n.get_class(), n.get("item_id"), n.get("visible")])
	var dir := _walk_direction(12)
	_face(dir, -0.3)
	var start := p.global_position
	var clips := {}   # clip -> frames it played while walking
	var frames := 0   # of them on the ground
	var striding := 0
	Input.action_press(&"move_forward")
	var walk_end := _now() + 1.5
	while _now() < walk_end:
		if not await frame(gen):
			return _abandoned()
		if _now() < walk_end - 1.3:
			continue   # getting up to speed
		var clip := String(person.animation_player().current_animation) if person.animation_player().is_playing() else "(none)"
		clips[clip] = int(clips.get(clip, 0)) + 1
		if p.is_on_floor():   # hops up 1-block steps rightly play the air pose
			frames += 1
			if clip == "walk" or clip == "run":
				striding += 1
	Input.action_release(&"move_forward")
	var walked := Vector2(p.global_position.x - start.x, p.global_position.z - start.z).length()
	await wait_until_true(func() -> bool: return Vector2(p.velocity.x, p.velocity.z).length() < 0.2, 2.0, gen)
	p.rig.yaw = person.rotation.y + PI   # the camera in front, looking at the face
	p.rig.pitch = -0.2
	if not await shot("avatar", gen):
		return _abandoned()
	var still := person.animation_player().current_animation
	if orig != "realistic":
		_store_setting("style", orig)
	var walking := walked > 2.0 and frames >= 5 and striding * 10 >= frames * 7
	return [holds and walking,
		"realistic person (skin %d); walking %.1f blocks played %s, walk or run in %d of %d frames on the ground; standing plays \"%s\"; sword in the hand: %s (held_item %d, hand holds %s)" % [
		person.skin_index, walked, clips, striding, frames, still, "yes" if holds else "NO", p.held_item, in_hand]]


# --- 11. Ten big buddies: measured separately -----------------------------------------------------

func _check_buddies(_gen: int) -> Array:
	return [null, "measured separately (developer menu: AUTOPILOT 10 BUDDIES)"]


# --- 12. On a peak the valley and the sea stay loaded (review I2) --------------------------------

func _check_peak(gen: int) -> Array:
	var p := _player()
	var w := _world()
	var shape := w.generator_shape()
	var home := _home()
	note("looking for the highest peak")
	var peak := _scout().peak(home, PEAK_RADIUS)
	note("going to the peak at %s" % peak)
	if not await _go_surface(Vector2i(peak.x, peak.z), gen, 45.0):
		return [false, "could not stand on the peak at %s" % peak]
	var probes: Array[Vector3] = []
	var low_dir := Vector3.FORWARD
	var low_h := 1 << 30
	for i in 8:
		var d := Vector3(cos(TAU * i / 8.0), 0.0, sin(TAU * i / 8.0))
		for dist: float in [40.0, 60.0]:
			probes.append(Vector3(peak.x + d.x * dist, MeadowsShape.SEA_LEVEL, peak.z + d.z * dist))
		var h := shape.height_at(floori(peak.x + d.x * 50.0), floori(peak.z + d.z * 50.0))
		if h < low_h:
			low_h = h
			low_dir = d
	var ready_count := func() -> int:
		return probes.filter(func(v: Vector3) -> bool: return w.is_area_ready(v)).size()
	var t0 := _now()
	note("waiting for the valley and the sea to stream in")
	var loaded := await wait_until_true(func() -> bool: return ready_count.call() == probes.size(), 60.0, gen)
	var took := _now() - t0
	_face(low_dir, -0.5)   # look down into the valley
	if not await shot("peak", gen):
		return _abandoned()
	return [loaded,
		"peak at %s, %d blocks from the spawn; standing at y=%.1f; %d/%d sea-level cells 40-60 blocks away loaded after %.1f s; lowest ground 50 blocks away: y=%d" % [
		peak, roundi(Vector2(peak.x - home.x, peak.z - home.y).length()), p.global_position.y,
		ready_count.call(), probes.size(), took, low_h]]
