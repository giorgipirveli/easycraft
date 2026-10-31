extends Node
## The steps of tools/world_shots.gd (owner feedback #45b): flies to each view of the wild meadows of seed 12345
## (the places nearest the spawn, the biomes, a mushroom cave), waits until the terrain there is meshed, looks at it
## and saves a small JPEG; then the world map with a few places found. Every view twice: blocky, then realistic.

const SEED := 12345
const SETTLE := 1.5               # seconds after the view's middle is meshed
const MAX_WAIT := 12.0            # ... or at most this long
const TIMEOUT := 900.0
const SHOT_SIZE := Vector2i(640, 360)

var _views: Array[Dictionary] = []
var _i := 0
var _phase := 0
var _wait := 0.0
var _waited := 0.0
var _t := 0.0
var _out := ""
var _found: Array = []
var _cave_look := Vector3.ZERO


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Game.mode = ModeRules.SANDBOX
	Game.start_new_world = true
	Game.new_world_seed = SEED
	_out = OS.get_environment("XDG_DATA_HOME").path_join("world_shots")
	DirAccess.make_dir_recursive_absolute(_out)
	get_tree().change_scene_to_file(Game.SANDBOX_SCENE)


func _process(delta: float) -> void:
	_t += delta
	if _t > TIMEOUT:
		print("WORLD_SHOT timeout at view %d" % _i)
		get_tree().quit(1)
		return
	var sandbox := get_tree().current_scene
	if sandbox == null or sandbox.get("player") == null or not (sandbox.player as Player).is_spawned():
		return
	var p: Player = sandbox.player
	if _views.is_empty():
		_plan(sandbox, p)
		if not p.rig.first_person:
			p.toggle_camera()
		p.set_physics_mode(PhysicsMode.Mode.FLY)
	if _wait > 0.0:
		_wait -= delta
		return
	if _i >= _views.size():
		print("WORLD_SHOT done views=%d" % _views.size())
		get_tree().quit(0)
		return
	var v := _views[_i]
	var hud: Hud = sandbox.get("hud")
	match _phase:
		0:
			p.world.apply_style(v.style)
			hud.visible = v.get("hud", false)
			p.spawn_at(v.stand)
			p.velocity = Vector3.ZERO
			_waited = 0.0
			_phase = 1
			_wait = 0.3
		1:
			p.global_position = v.stand
			p.velocity = Vector3.ZERO
			_aim(p, v.look)
			_waited += delta
			if p.world.is_area_ready(v.look) or _waited > MAX_WAIT:
				_phase = 2
				_wait = SETTLE
		2:
			p.global_position = v.stand
			if v.has("before"):
				(v.before as Callable).call(sandbox)
			_aim(p, v.look)
			_phase = 3
			_wait = 0.4
		3:
			var img := get_viewport().get_texture().get_image()
			img.resize(SHOT_SIZE.x, SHOT_SIZE.y, Image.INTERPOLATE_LANCZOS)
			var path := _out.path_join("%02d_%s_%s.jpg" % [_i, v.name, v.style])
			img.save_jpg(path, 0.82)
			print("WORLD_SHOT %s %s %s" % [v.name, v.style, path])
			if v.has("after"):
				(v.after as Callable).call(sandbox)
			_i += 1
			_phase = 0


func _aim(p: Player, target: Vector3) -> void:
	var eye := p.eye_position()
	var d := target - eye
	p.rig.yaw = atan2(-d.x, -d.z)
	p.rig.pitch = clampf(atan2(d.y, Vector2(d.x, d.z).length()), CameraRig.PITCH_MIN, CameraRig.PITCH_MAX)


func _plan(sandbox: Node, p: Player) -> void:
	var director: PlacesDirector = sandbox.get("places_director")
	var shape := p.world.generator_shape() as MeadowsBiomeShape
	var home := p.world.spawn_column()
	var from := Vector3(home.x, 40, home.y)
	var list: Array[Dictionary] = []
	for kind: StringName in MeadowsPlaces.KINDS:
		var place := director.places.nearest(from, kind, 12)
		if place.is_empty():
			print("WORLD_SHOT none %s" % kind)
			continue
		_found.append(place.id)
		list.append(_place_view(place))
	for b: Array in [[MeadowsBiomeShape.BIRCH, "birch_forest"], [MeadowsBiomeShape.DARK, "dark_forest"],
			[MeadowsBiomeShape.FLOWERS, "flower_field"]]:
		var c := _find(shape, home, func(q: Vector2i) -> bool: return shape.column(q.x, q.y).y == b[0] \
			and _all_around(shape, q, 10, b[0]))
		if c != Vector2i.MAX:
			var h := shape.height_at(c.x, c.y)
			list.append({"name": b[1], "stand": Vector3(c.x - 14.5, h + 16, c.y + 0.5), "look": Vector3(c.x + 8, h + 2, c.y)})
	var lily := _find(shape, home, func(q: Vector2i) -> bool: return shape.column(q.x, q.y).z & MeadowsBiomeShape.F_LILY != 0)
	if lily != Vector2i.MAX:
		list.append({"name": "swamp", "stand": Vector3(lily.x - 9.5, MeadowsShape.SEA_LEVEL + 6, lily.y + 5.5),
			"look": Vector3(lily.x + 2, MeadowsShape.SEA_LEVEL, lily.y)})
	var peak := _find(shape, home, func(q: Vector2i) -> bool: return shape.height_at(q.x, q.y) >= MeadowsBiomeShape.SNOW_LINE + 6)
	if peak != Vector2i.MAX:
		var h := shape.height_at(peak.x, peak.y)
		list.append({"name": "snowy_mountain", "stand": Vector3(peak.x - 45.5, h + 6, peak.y + 20.5), "look": Vector3(peak.x, h - 6, peak.y)})
	var isle := _find(shape, home, func(q: Vector2i) -> bool: return shape.column(q.x, q.y).y == MeadowsBiomeShape.ISLAND)
	if isle != Vector2i.MAX:
		list.append({"name": "island", "stand": Vector3(isle.x - 40.5, MeadowsShape.SEA_LEVEL + 14, isle.y + 30.5),
			"look": Vector3(isle.x, MeadowsShape.SEA_LEVEL + 3, isle.y)})
	var mouth := _find(shape, home, func(q: Vector2i) -> bool: return shape.is_river(q.x, q.y) and shape.coast_share(q.x, q.y) < 0.35)
	if mouth != Vector2i.MAX:
		list.append({"name": "river_to_the_sea", "stand": Vector3(mouth.x - 30.5, MeadowsShape.SEA_LEVEL + 30, mouth.y + 30.5),
			"look": Vector3(mouth.x, MeadowsShape.SEA_LEVEL, mouth.y)})
	var cave := _mushroom_cave(sandbox, shape, home)
	if cave != Vector3.INF:
		list.append({"name": "mushroom_cave", "stand": cave, "look": _cave_look})
	list.append({"name": "world_map", "stand": Vector3(home.x + 0.5, shape.height_at(home.x, home.y) + 2, home.y + 0.5),
		"look": Vector3(home.x + 10, shape.height_at(home.x, home.y) + 2, home.y), "hud": true,
		"before": func(sb: Node) -> void:
			var d: PlacesDirector = sb.get("places_director")
			for id: String in _found:
				d._add_found(id, 0)
			(sb.get("world_map") as WorldMapPanel).open(),
		"after": func(sb: Node) -> void: (sb.get("world_map") as WorldMapPanel).close()})
	for style: String in ["blocky", "realistic"]:
		for v: Dictionary in list:
			var copy := v.duplicate()
			copy.style = style
			_views.append(copy)


## A view of a place: from its front (out of its door), up high enough to see it whole.
func _place_view(place: Dictionary) -> Dictionary:
	var a: Vector3i = place.anchor
	var centre := Vector3(a.x + 0.5, a.y, a.z + 0.5)
	var dir := Vector3(0.7, 0, 0.7)
	var doors: Array = place.get("doors", [])
	if not doors.is_empty():
		var d: Vector3i = (doors[0][1] as Vector3i) - (doors[0][0] as Vector3i)
		if d != Vector3i.ZERO:
			dir = Vector3(d).normalized()
	var side := Vector3(-dir.z, 0, dir.x)
	match place.kind:
		MeadowsPlaces.VILLAGE:
			return {"name": "village", "stand": centre + Vector3(20, 16, 20), "look": centre}
		MeadowsPlaces.TOWN:
			return {"name": "town", "stand": centre + Vector3(34, 26, 34), "look": centre}
		MeadowsPlaces.CASTLE:
			return {"name": "castle", "stand": centre + dir * 26 + side * 8 + Vector3(0, 14, 0), "look": centre}
		MeadowsPlaces.SHIP:
			var pier: Array = place.pier
			var land: Vector3i = pier[1]
			var out := (Vector3(land) - centre).normalized()
			return {"name": "ship", "stand": centre - out * 20 + Vector3(-out.z, 0, out.x) * 8 + Vector3(0, 8, 0),
				"look": centre + Vector3(0, 3, 0)}
		MeadowsPlaces.LIGHTHOUSE:
			return {"name": "lighthouse", "stand": centre + dir * 20 + side * 6 + Vector3(0, 6, 0), "look": centre + Vector3(0, 9, 0)}
		MeadowsPlaces.TOWER:
			return {"name": "tower", "stand": centre + dir * 16 + side * 6 + Vector3(0, 5, 0), "look": centre + Vector3(0, 8, 0)}
	return {"name": String(place.kind), "stand": centre + dir * 18 + side * 6 + Vector3(0, 9, 0), "look": centre + Vector3(0, 6, 0)}


## The nearest column (on rings round the spawn) that `ok` takes, or Vector2i.MAX.
func _find(shape: MeadowsBiomeShape, home: Vector2i, ok: Callable) -> Vector2i:
	for r in range(96, 3200, 16):
		for a in 32:
			var q := home + Vector2i(roundi(cos(TAU * a / 32.0) * r), roundi(sin(TAU * a / 32.0) * r))
			if ok.call(q):
				return q
	return Vector2i.MAX


func _all_around(shape: MeadowsBiomeShape, q: Vector2i, r: int, biome: int) -> bool:
	for d: Vector2i in [Vector2i(r, 0), Vector2i(-r, 0), Vector2i(0, r), Vector2i(0, -r)]:
		if shape.column(q.x + d.x, q.y + d.y).y != biome:
			return false
	return true


## A spot in a glowing mushroom cave near the spawn: a dry floor cell of a mushroom region (from the generator's
## reference), or INF.
func _mushroom_cave(sandbox: Node, shape: MeadowsBiomeShape, home: Vector2i) -> Vector3:
	var gen := MeadowsBiomeGenerator.new()
	gen.world_seed = shape.seed
	for r in range(0, 12):
		for rx in range(-r, r + 1):
			for rz in range(-r, r + 1):
				if maxi(absi(rx), absi(rz)) != r:
					continue
				var corner := Vector2i(floori(home.x / 128.0) + rx, floori(home.y / 128.0) + rz) * MeadowsBiomeShape.CAVE_REGION
				if shape.cave_region(corner.x, corner.y) != MeadowsBiomeShape.MUSHROOM_CAVES:
					continue
				for i in 48:
					var x := corner.x + 8 + (i * 37) % 112
					var z := corner.y + 8 + (i * 53) % 112
					for y in range(-24, -60, -1):
						if gen.reference_block(x, y, z) == BlockIds.MUD and gen.reference_block(x, y + 1, z) == BlockIds.AIR \
								and gen.reference_block(x, y + 2, z) == BlockIds.AIR:
							var best := Vector3i.ZERO
							var best_n := 0
							for d: Vector3i in [Vector3i(1, 0, 0), Vector3i(-1, 0, 0), Vector3i(0, 0, 1), Vector3i(0, 0, -1),
									Vector3i(1, 0, 1), Vector3i(-1, 0, 1), Vector3i(1, 0, -1), Vector3i(-1, 0, -1)]:
								var n := 0
								while n < 12 and gen.reference_block(x + d.x * (n + 1), y + 2, z + d.z * (n + 1)) == BlockIds.AIR:
									n += 1
								if n > best_n:
									best_n = n
									best = d
							if best_n >= 7:
								print("WORLD_SHOT info mushroom cave at %s, open %d blocks" % [Vector3i(x, y + 1, z), best_n])
								_cave_look = Vector3(x + 0.5 + best.x * 8, y + 1.2, z + 0.5 + best.z * 8)
								return Vector3(x + 0.5, y + 1.05, z + 0.5)
	return Vector3.INF
