extends Node
## The steps of tools/look_shots.gd: the title screen, or a NEW Sandbox world of one universe, then fixed views, each
## measured and photographed in both styles.

const SEED := 12345
const SETTLE := 2.0
const MAX_WAIT := 15.0
const SHOT_SIZE := Vector2i(1200, 540)

var _out := ""
var _frames := 90
var _shots := true
var _styles: Array[StringName] = [&"blocky", &"realistic"]
var _only: PackedStringArray = []   # --views=noon,ground: only these
var _env := {}   # --env=tonemap_mode:3,fog_depth_curve:1.0: the world's Environment settings to try (and fog_begin:0.5)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var u := 1
	var tag := "now"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--universe="):
			u = int(a.get_slice("=", 1))
		elif a.begins_with("--tag="):
			tag = a.get_slice("=", 1)
		elif a.begins_with("--frames="):
			_frames = maxi(1, int(a.get_slice("=", 1)))
		elif a.begins_with("--style="):
			_styles = [StringName(a.get_slice("=", 1))]
		elif a.begins_with("--env="):
			for pair in a.get_slice("=", 1).split(","):
				_env[pair.get_slice(":", 0)] = float(pair.get_slice(":", 1))
		elif a.begins_with("--views="):
			_only = a.get_slice("=", 1).split(",")
		elif a == "--no-shots":
			_shots = false
	_out = OS.get_environment("XDG_DATA_HOME").path_join("look_shots").path_join(tag).path_join(
		RenderingServer.get_current_rendering_method())
	DirAccess.make_dir_recursive_absolute(_out)
	RenderingServer.viewport_set_measure_render_time(get_viewport().get_viewport_rid(), true)
	print("LOOK_SHOT renderer=%s out=%s" % [RenderingServer.get_current_rendering_method(), _out])
	if OS.get_cmdline_user_args().has("--menu"):
		_menu.call_deferred()
	else:
		_world.call_deferred(u)


# --- The title screen ------------------------------------------------------------------------------------------

func _menu() -> void:
	Profile.data.settings.reduce_motion = false
	var menu: Node = load("res://ui/menus/menu.tscn").instantiate()
	add_child(menu)
	var waited := 0.0
	while not bool(menu.get("announced")) and waited < 120.0:   # the shader warm-up's first part (OpenGL)
		await get_tree().process_frame
		waited += get_process_delta_time()
	await get_tree().create_timer(4.0).timeout   # the backdrop world streams in
	menu.call("_show_main")
	var d := (menu.get("_cam") as Camera3D).find_children("*", "TitleDiorama", false, false)[0] as TitleDiorama
	for style: StringName in _styles:
		var settings: Dictionary = Profile.data.settings.duplicate()
		settings.style = String(style)
		menu.call("_restyle_backdrop", settings)
		d.set_process(false)
		d.step(5.1 - d.time())   # the buddy awake, waving
		menu.set_process(false)   # the orbit holds still
		await get_tree().create_timer(SETTLE).timeout   # a new sky bakes its light first
		await _view("menu", style)
		menu.set_process(true)
	print("LOOK_SHOT done")
	get_tree().quit(0)


# --- A world ---------------------------------------------------------------------------------------------------

func _world(u: int) -> void:
	Game.mode = ModeRules.SANDBOX
	Game.universe = u
	Game.start_new_world = true
	Game.new_world_seed = SEED
	get_tree().change_scene_to_file(Game.SANDBOX_SCENE)
	var t := 0.0
	while true:
		await get_tree().process_frame
		t += get_process_delta_time()
		var s := get_tree().current_scene
		if s != null and s.get("player") != null and (s.player as Player).is_spawned():
			break
		if t > 300.0:
			print("LOOK_SHOT timeout (spawn)")
			get_tree().quit(1)
			return
	var sandbox := get_tree().current_scene
	var p: Player = sandbox.player
	await get_tree().create_timer(1.0).timeout
	if not p.rig.first_person:
		p.toggle_camera()
	p.set_physics_mode(PhysicsMode.Mode.FLY)
	(sandbox.get("hud") as Control).visible = false
	for card_name: String in ["PlanetGuideCard", "KeysCard", "LoadingCard"]:
		var card := sandbox.find_child(card_name, true, false) as Control
		if card != null:
			card.visible = false
	var sky := sandbox.get("sky") as SkyCycle
	var views := _views_for(u, p, sky)
	if not _only.is_empty():
		var kept: Array[Dictionary] = []
		for v: Dictionary in views:
			if _only.has(String(v.name)):
				kept.append(v)
		views = kept
	for style: StringName in _styles:
		for v: Dictionary in views:
			p.world.apply_style(String(style))
			_try_env(p.world)
			sky.set_time(float(v.time))
			sky.running = false
			p.spawn_at(v.stand)
			if v.has("setup"):
				(v.setup as Callable).call(sandbox)
			await _place(p, v)
			await _view("u%d_%s" % [u, v.name], style, p, v)
			if v.has("teardown"):
				(v.teardown as Callable).call(sandbox)
	print("LOOK_SHOT done views=%d" % (views.size() * _styles.size()))
	get_tree().quit(0)


## The views of universe `u`: [{name, time, stand (the feet), look}].
func _views_for(u: int, p: Player, sky: SkyCycle) -> Array[Dictionary]:
	if p.world.generator_shape() is GlowShape:
		return _glow_views(p)
	var home := p.world.spawn_column()
	var feet := p.global_position
	var h := feet.y
	var up := Vector3(home.x + 0.5, h + 20.0, home.y + 0.5)
	var west := Vector3(1, 0, 0) if sky.sun_west else Vector3(-1, 0, 0)   # where the Sun sets
	var out: Array[Dictionary] = [
		{"name": "noon", "time": 0.5, "stand": up, "look": up + Vector3(0, -12, -80)},
		{"name": "sunset", "time": 0.835, "stand": up, "look": up + west * 80.0 + Vector3(0, -8, 0)},
		{"name": "night", "time": 0.0, "stand": up, "look": up + Vector3(0, 4, -80)},
	]
	if u != 1:
		return out
	out.insert(1, {"name": "morning", "time": 0.2, "stand": up, "look": up - west * 80.0 + Vector3(0, -14, 0)})
	out.append({"name": "ground", "time": 0.4, "stand": feet, "look": feet + Vector3(0, 0.6, -14)})
	var water := _find_water(p, home)
	if not water.is_empty():
		out.append({"name": "water", "time": 0.45, "stand": water[0], "look": water[1]})
	var cave := _find_cave(p, home, h)
	out.append({"name": "cave", "time": 0.45, "stand": cave[0], "look": cave[1], "cave": true})
	return out


## Universe 6, the Glow Caves: views under the roof (the sky's time only shows through a shaft and on the roof): the home
## hall across, a giant glowshroom, a selenite beam in a crystal hall, an underground lake, the home hall's daylight shaft
## looking up, the nearest Glow-worm Grotto's ceiling (its worms brighten for a still child: the shot's), the meadow on
## the roof at noon. A view whose place is not found near the spawn is left out.
func _glow_views(p: Player) -> Array[Dictionary]:
	var shape := p.world.generator_shape() as GlowShape
	var feet := p.global_position
	var eye := Vector3(0, 1.0, 0)
	var out: Array[Dictionary] = [
		{"name": "hall", "time": 0.5, "stand": feet + eye, "look": feet + Vector3(6, 5, -30), "cave": true}]
	var home := shape.spawn_column()
	var giant := Vector2i.MAX
	var beam := Vector2i.MAX
	var lake := Vector2i.MAX
	for r in range(10, 160, 2):
		for i in maxi(r * 3, 1):
			var a := TAU * i / maxi(r * 3, 1)
			var c := home + Vector2i(roundi(cos(a) * r), roundi(sin(a) * r))
			var kind := shape.plant_at(c.x, c.y)
			if giant == Vector2i.MAX and kind in [GlowShape.BLUE_GIANT, GlowShape.ROSE_GIANT] and r >= 14:
				giant = c
			if beam == Vector2i.MAX and kind == GlowShape.BEAM:
				beam = c
			var col := shape.column(c.x, c.y)
			if lake == Vector2i.MAX and col.x != col.y and col.x <= GlowShape.LAKE_LEVEL - 2 and col.y - col.x >= 9 \
					and not shape.in_shaft(c.x, c.y):
				lake = c
	if giant != Vector2i.MAX:
		var f := shape.height_at(giant.x, giant.y)
		var top := f + shape.plant_height(giant.x, giant.y)
		var from := _open_spot(shape, giant, 9)
		if from != Vector3.INF:
			out.append({"name": "grove", "time": 0.5, "stand": from + eye, "look": Vector3(giant.x + 0.5, top, giant.y + 0.5),
				"cave": true})
	if beam != Vector2i.MAX:
		var from := _open_spot(shape, beam, 7)
		if from != Vector3.INF:
			out.append({"name": "crystal", "time": 0.5, "stand": from + eye,
				"look": Vector3(beam.x + 0.5, shape.height_at(beam.x, beam.y) + 3.0, beam.y + 0.5), "cave": true})
	if lake != Vector2i.MAX:
		var from := _open_spot(shape, lake, 10, true)
		if from != Vector3.INF:
			out.append({"name": "lake", "time": 0.5, "stand": from + Vector3(0, 2.5, 0),
				"look": Vector3(lake.x + 0.5, GlowShape.LAKE_LEVEL, lake.y + 0.5), "cave": true})
	var shaft := shape.home_shaft()
	var base := shape.column(shaft.x, shaft.y)
	out.append({"name": "shaft", "time": 0.5, "stand": Vector3(shaft.x + 6.5, base.x + 2.0, shaft.y + 0.5),
		"look": Vector3(shaft.x + 0.5, base.x + 40.0, shaft.y + 0.5), "cave": true})
	var wonders := GlowWonders.new(shape.seed, shape)
	var seen := {}
	for w: Dictionary in wonders.wonders_near(feet, 300.0):   # the nearest of each Cave Wonder, from in front of it
		if seen.has(w.kind):
			continue
		seen[w.kind] = true
		var c: Vector3i = w.anchor
		if w.kind == GlowWonderRules.GROTTO:
			out.append({"name": "grotto", "time": 0.5, "stand": Vector3(c.x + 3.5, c.y + 0.0, c.z + 0.5),
				"look": Vector3(c.x - 2.5, int(w.ceiling), c.z + 0.5), "cave": true})
			continue
		var d := Vector3(w.dir as Vector3i)
		var side := Vector3(-d.z, 0, d.x)   # from a little to the side and in front (the drip stone: its steps' way too)
		var far := 1.4 if w.kind == GlowWonderRules.ECHO else 1.0
		var stand := Vector3.INF
		var offs: Array[Vector3] = [side * 5.0 - d * 4.0, -side * 5.0 - d * 4.0, -d * 6.0, side * 6.0, -side * 6.0, -d * 8.0]
		if w.kind == GlowWonderRules.ECHO:
			offs.push_front(-d * 7.0)   # its face straight on: three tunnel mouths
		for off: Vector3 in offs:
			var at := Vector3(c) + Vector3(0.5, 0.0, 0.5) + off * far
			var col := shape.column(floori(at.x), floori(at.z))
			if col.x != col.y and not shape.in_shaft(floori(at.x), floori(at.z)) and col.y - col.x >= 4 \
					and not _plant_by(shape, floori(at.x), floori(at.z)):
				stand = Vector3(at.x, mini(col.x + 2, col.y - 2), at.z)
				break
		if stand != Vector3.INF:
			out.append({"name": "wonder_" + String(w.kind), "time": 0.5, "stand": stand,
				"look": Vector3(c) + Vector3(0.5, 1.5, 0.5) + d * 2.0, "cave": true})
	# The caves' monsters held still in a row across the home hall (a spore puff and a cave crawler at levels 1 and 5, a
	# golden puff), and the Spore Mother: the shapes and colours a child meets, both styles.
	var row := feet + Vector3(0, 0, -4)
	out.append({"name": "monsters", "time": 0.5, "stand": feet + Vector3(0, 0.6, 0), "look": row + Vector3(0, 0.4, 0),
		"cave": true, "setup": func(sandbox: Node) -> void: _monster_row(sandbox, row),
		"teardown": func(sandbox: Node) -> void: (sandbox.get_node("Monsters") as MonsterDirector).puff_all()})
	var totem := feet + Vector3(0, 0, -6)
	var her := BossRules.golem_spot(totem)
	var toward := Vector3(feet.x - her.x, 0, feet.z - her.z).normalized()
	out.append({"name": "spore_mother", "time": 0.5, "stand": her + toward * 9.0 + Vector3(0, 2.5, 0),
		"look": her + Vector3(0, 2.5, 0), "cave": true,
		"setup": func(sandbox: Node) -> void: print("LOOK_SHOT boss: '%s'" % sandbox.call(&"summon_boss", totem, &"spore_mother"))})
	var roof := shape.roof_at(home.x + 40, home.y)
	out.append({"name": "roof", "time": 0.5, "stand": Vector3(home.x + 40.5, roof + 8.0, home.y + 0.5),
		"look": Vector3(home.x - 40.5, roof, home.y - 30.5)})
	return out


## The caves' monsters in a row at `at`, facing the camera, held still (their minds off).
func _monster_row(sandbox: Node, at: Vector3) -> void:
	var monsters := sandbox.get_node("Monsters") as MonsterDirector
	var row := [[MonsterRules.SPORE_PUFF, 1, false], [MonsterRules.SPORE_PUFF, 5, false], [MonsterRules.SPORE_PUFF, 1, true],
		[MonsterRules.CRAWLER, 1, false], [MonsterRules.CRAWLER, 5, false]]
	for i in row.size():
		var pos := at + Vector3((i - 2) * 2.2, 0.0, 0.0)
		pos.y = sandbox.world.find_standing_y(floori(pos.x), floori(pos.z))
		var m := monsters.spawn_monster({"kind": row[i][0], "level": row[i][1], "id": "look_%d" % i, "pos": pos, "yaw": 0.0,
			"wild": false, "universe": 6, "golden": row[i][2]})
		if m != null:
			m.process_mode = Node.PROCESS_MODE_DISABLED


## A plant right by (x, z), or a giant glowshroom's cap over it: it would hide the view.
func _plant_by(shape: GlowShape, x: int, z: int) -> bool:
	for dz in range(-3, 4):
		for dx in range(-3, 4):
			var p := shape.plant_at(x + dx, z + dz)
			if p in [GlowShape.BLUE_GIANT, GlowShape.ROSE_GIANT] or (p != GlowShape.NO_PLANT and absi(dx) <= 1 and absi(dz) <= 1):
				return true
	return false


## An open, dry floor spot `d` blocks from column `c` (its floor cell's centre), INF without one; `wet`: the spot may
## be anywhere dry round a lake (its floor over the water line).
func _open_spot(shape: GlowShape, c: Vector2i, d: int, wet: bool = false) -> Vector3:
	for i in 16:
		var a := TAU * i / 16.0
		var x := c.x + roundi(cos(a) * d)
		var z := c.y + roundi(sin(a) * d)
		var col := shape.column(x, z)
		if col.x == col.y or shape.in_shaft(x, z) or col.y - col.x < 5:
			continue
		if wet and col.x <= GlowShape.LAKE_LEVEL:
			continue
		if not wet and col.x <= GlowShape.LAKE_LEVEL + 1:
			continue
		return Vector3(x + 0.5, col.x, z + 0.5)
	return Vector3.INF


## `--env`: Environment settings to try (a whole number stays one: an enum), `fog_begin` the fog's start as a share of
## the view (it goes into the open-air look Ambience starts from).
func _try_env(world: WorldService) -> void:
	var env := world.environment()
	for k: String in _env:
		var v: float = _env[k]
		if k == "fog_begin":
			world.ambience_base.fog_begin = env.fog_depth_end * v
		elif typeof(env.get(k)) == TYPE_INT:
			env.set(k, int(v))
		else:
			env.set(k, v)


## Stands at the view, waits for the land it looks at (at most MAX_WAIT), then SETTLE (a cave's mood: longer).
func _place(p: Player, v: Dictionary) -> void:
	var waited := 0.0
	var settle := 0.0
	var need := SETTLE * (2.0 if v.get("cave", false) else 1.0)
	if OS.get_cmdline_user_args().has("--no-shadows"):   # the sun casts none (the shadow pass's cost)
		p.world.sun().shadow_enabled = false
	if OS.get_cmdline_user_args().has("--no-lantern"):   # the cave lantern lights nothing (a light's cost, alone)
		var lantern := p.find_child("Lantern", true, false) as OmniLight3D
		if lantern:
			lantern.light_cull_mask = 0
	while settle < need:
		p.global_position = v.stand
		p.velocity = Vector3.ZERO
		_aim(p, v.look)
		await get_tree().process_frame
		var dt := get_process_delta_time()
		waited += dt
		if p.world.is_area_ready(v.look) or waited > MAX_WAIT:
			settle += dt


## Measures `_frames` frames of the view as it is, then photographs it.
func _view(view_name: String, style: StringName, p: Player = null, v: Dictionary = {}) -> void:
	var rid := get_viewport().get_viewport_rid()
	var walls: Array[float] = []
	var gpu := 0.0
	var cpu := 0.0
	var draws := 0.0
	var prims := 0.0
	var last := Time.get_ticks_usec()
	for i in _frames:
		if p != null:
			p.global_position = v.stand
			_aim(p, v.look)
		await get_tree().process_frame
		var now := Time.get_ticks_usec()
		walls.append((now - last) / 1000.0)
		last = now
		gpu += RenderingServer.viewport_get_measured_render_time_gpu(rid)
		cpu += RenderingServer.viewport_get_measured_render_time_cpu(rid)
		draws += Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
		prims += Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)
	walls.remove_at(0)
	var total := 0.0
	var worst := 0.0
	for w in walls:
		total += w
		worst = maxf(worst, w)
	print("LOOK_BENCH view=%s style=%s frames=%d avg_ms=%.2f worst_ms=%.2f gpu_ms=%.2f render_cpu_ms=%.2f draws=%d prims=%d" % [
		view_name, style, walls.size(), total / walls.size(), worst, gpu / _frames, cpu / _frames, roundi(draws / _frames),
		roundi(prims / _frames)])
	if not _shots:
		return
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.resize(SHOT_SIZE.x, roundi(SHOT_SIZE.x * float(img.get_height()) / img.get_width()), Image.INTERPOLATE_LANCZOS)
	var path := _out.path_join("%s_%s.jpg" % [view_name, style])
	img.save_jpg(path, 0.88)
	print("LOOK_SHOT %s %s %s" % [view_name, style, path])


## The sea or a lake nearest the spawn: [stand (on its shore, 4 over the water), look (over it)]; [] without one.
func _find_water(p: Player, home: Vector2i) -> Array:
	var sea := MeadowsShape.SEA_LEVEL
	var best := Vector2i.ZERO
	var best_d := INF
	for r in range(8, 200, 4):
		for a in 32:
			var ang := TAU * a / 32.0
			var c := home + Vector2i(roundi(cos(ang) * r), roundi(sin(ang) * r))
			if p.world.surface_height(c.x, c.y) <= sea - 4 and p.world.surface_height(c.x + 6, c.y) <= sea - 3 \
					and p.world.surface_height(c.x, c.y + 6) <= sea - 3:
				var d := Vector2(c - home).length()
				if d < best_d:
					best_d = d
					best = c
		if best_d < INF:
			break
	if best_d == INF:
		return []
	var toward := Vector2(home - best).normalized()
	var shore := Vector2(best)
	for i in 80:   # back toward the spawn until dry land
		shore += toward
		if p.world.surface_height(roundi(shore.x), roundi(shore.y)) >= sea:
			break
	var stand := Vector3(shore.x + 0.5, sea + 4.0, shore.y + 0.5)
	var over := Vector2(best) - toward * 18.0
	return [stand, Vector3(over.x + 0.5, sea - 2.0, over.y + 0.5)]


## A cave near the spawn: [stand, look]. The widest air pocket at least 6 under the ground within 32 blocks (the
## streamed box reaches 24 under the feet); without one, a room dug 10 under the spawn.
func _find_cave(p: Player, home: Vector2i, h: float) -> Array:
	var origin := Vector3i(home.x - 32, int(h) - 26, home.y - 32)
	var size := Vector3i(64, 22, 64)
	var at: Callable = p.world.box_reader(origin, size)
	var best := Vector3i.ZERO
	var best_score := -1
	for x in range(2, size.x - 2, 2):
		for z in range(2, size.z - 2, 2):
			var wx := origin.x + x
			var wz := origin.z + z
			var ground := p.world.surface_height(wx, wz)
			for y in range(1, size.y - 3):
				var c := Vector3i(wx, origin.y + y, wz)
				if c.y > ground - 6 or at.call(c) != BlockIds.AIR or at.call(c + Vector3i.UP) != BlockIds.AIR \
						or not BlockIds.is_solid(at.call(c + Vector3i.DOWN)):
					continue
				var score := 0
				for dx in range(-3, 4):
					for dz in range(-3, 4):
						for dy in range(0, 3):
							if at.call(c + Vector3i(dx, dy, dz)) == BlockIds.AIR:
								score += 1
				score -= int(Vector2(wx - home.x, wz - home.y).length() / 4.0)
				if score > best_score:
					best_score = score
					best = c
	if best_score < 60:
		best = Vector3i(home.x, int(h) - 10, home.y)
		for x in range(-4, 5):
			for z in range(-8, 9):
				for y in range(0, 4):
					p.world.set_block(best + Vector3i(x, y, z), BlockIds.AIR)
		print("LOOK_SHOT cave: none found, a room dug at %s" % best)
	else:
		print("LOOK_SHOT cave at %s (air %d)" % [best, best_score])
	var stand := Vector3(best) + Vector3(0.5, 0.0, 0.5)
	var dir := Vector3(0, 0, -1)
	var longest := -1
	for a in 8:   # the way the pocket reaches farthest at eye level
		var d := Vector3(cos(TAU * a / 8.0), 0, sin(TAU * a / 8.0))
		var n := 0
		while n < 16 and not BlockIds.is_solid(p.world.get_block(Vector3i((stand + d * (n + 1) + Vector3.UP).floor()))):
			n += 1
		if n > longest:
			longest = n
			dir = d
	return [stand, stand + dir * 10.0 + Vector3(0, 0.6, 0)]


func _aim(p: Player, target: Vector3) -> void:
	var eye := p.eye_position()
	var d := target - eye
	p.rig.yaw = atan2(-d.x, -d.z)
	p.rig.pitch = clampf(atan2(d.y, Vector2(d.x, d.z).length()), CameraRig.PITCH_MIN, CameraRig.PITCH_MAX)
