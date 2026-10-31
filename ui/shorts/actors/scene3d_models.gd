class_name Scene3DModels
extends RefCounted
## The Reel Studio (owner #96, spec §5.12b): a 3D stage's models, built from the game's own looks and nothing new:
## - rocket: StudioRockets' real parts meshed like the world's blocks (the voxel mesher with the world's block library:
##   its materials, its shading in the corners), one mesh per stage (and per build group), stages letting go and falling
##   away (StudioMotion.dropped);
## - planet: the flight's sphere and planet shader (FlightLooks: the Earth's clouds, the Moon's and Mars's real maps; the
##   gas giants painted in bands of their Star Map colours), lit from the stage's Sun;
## - sun: the planet shader in the Sun's colours, fully lit, and the flight's glow behind it;
## - rings: Saturn's rings (the C, B, A and F rings and the Cassini gap) in the night sky's see-through vertex colours;
## - orbit_line: a thin ring in the same look; ground: the flight's landing ground (its dust, tinted, its boulders);
## - pad: the flight's landing pad (the brand's teal ring and golden star); blocks: a named build (StudioBuilds: the
##   Launch Site's pad and tower, a world's region from its own generator) or listed cells;
## - avatar: the game's blocky person in a look, posed by EmotePoses at the stage's time; clouds: soft puffs.
## Every model is a Built: its nodes and pose(t), a pure function of the time (so a seek shows the frame playing does).

const PAD_OFFSET := Vector3(-0.5, 0.0, -0.5)   # a cell's corner to its middle: the pad's middle cell's centre is 0
const BAND_SIZE := Vector2i(256, 128)
## Where the blocky mesher puts the buffer's first voxel past its padding (measured: test_scene3d_view.gd).
const MESHER_SHIFT := Vector3.ZERO

## Round 2: mesh every blocks model at once (the reel tools: a frame sheet or a video never shows an island missing).
static var sync_blocks := false
static var _bands := {}
static var _sources := {}
static var _band_images := {}
static var _band_task := -1
static var _rings := {}
const GIANTS: Array[StringName] = [&"jupiter", &"saturn", &"uranus", &"neptune"]


## What a Short's stage needs first, made before it is needed (ShortsView.open): the world's block library, the Earth's
## and the Moon's maps on the flight's worker thread, the gas giants' band pictures on a worker thread of their own.
static func warm() -> void:
	WorldService.library()
	FlightLooks.earth_material()
	FlightLooks.planet_material(SpaceRules.MOON)
	if _band_task < 0 and _band_images.is_empty():
		var colours := {}
		for body in GIANTS:
			var b := StarMap.body(body)
			colours[body] = [b.get("color", Color.WHITE), b.get("color2", Color.GRAY)]
		_band_task = WorkerThreadPool.add_task(func() -> void:
			var made := {}
			for body: StringName in colours:
				made[body] = band_image(body, colours[body][0], colours[body][1])
			_band_images.merge(made), false, "Reel Studio bands")
		_reap_bands()


## The band pictures' task is waited for once it is done (a frame's look; the pool wants every task waited).
static func _reap_bands() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or _band_task < 0:
		return
	tree.process_frame.connect(func() -> void:
		if _band_task >= 0 and WorkerThreadPool.is_task_completed(_band_task):
			WorkerThreadPool.wait_for_task_completion(_band_task)
			_band_task = -1
		elif _band_task >= 0:
			_reap_bands(), CONNECT_ONE_SHOT)


## Builds `data` (a StudioRules model) under `parent`, for `view`.
static func build(data: Dictionary, parent: Node3D, view: Node) -> Built:
	var b: Built
	match str(data.get("model", "")):
		"rocket":
			b = RocketBuilt.new()
		"planet", "sun":
			b = PlanetBuilt.new()
		"avatar":
			b = AvatarBuilt.new()
		"ring_bits":
			b = RingBitsBuilt.new()
		"rope":
			b = RopeBuilt.new()
		"blocks":
			b = BlocksBuilt.new() if not data.has("build") else Built.new()
		_:
			b = Built.new()
	b.data = data
	b.view = view
	b.root = Node3D.new()
	b.root.name = "Model_" + str(data.get("id", ""))
	parent.add_child(b.root)
	b.make(parent)
	return b


## A built model: its root node (placed where StudioMotion says) and whatever else it keeps.
class Built:
	extends RefCounted
	var data: Dictionary
	var view: Node
	var root: Node3D
	var size := 1.0

	func make(_parent: Node3D) -> void:
		size = StudioRules.num(data, "size", 1.0)
		var kind := str(data.get("model", ""))
		match kind:
			"rings":
				_mesh(root, Scene3DModels.rings_mesh(size, ShortRules.colour(data.get("color"), Color("e8d8b0"))))
			"orbit_line":
				_mesh(root, Scene3DModels.ring_line(StudioRules.num(data, "radius", 10.0),
					StudioRules.num(data, "width", 0.15), ShortRules.colour(data.get("color"), Color(1, 1, 1, 0.45))))
				size = 1.0
			"ground":
				var look := str(data.get("look", "moon"))   # boulders on the Moon and Mars only (grass has none)
				var rocks := StudioRules.num(data, "rocks", 1.0 if look in ["moon", "mars"] else 0.0)
				Scene3DModels.ground(root, look, size, rocks > 0.0)
				size = 1.0
			"pad":
				_mesh(root, Scene3DModels.pad_mesh())
			"blocks":
				for m: Mesh in Scene3DBuilds.meshes(data):
					_mesh(root, m)
			"clouds":
				Scene3DModels.clouds(root, data)
				size = 1.0
			"mark":
				pass   # round 2: nothing to see; a point a camera rides with or aims at, or an effect comes from

	func pose(t: float) -> void:
		var s := StudioMotion.state(data, t)
		root.visible = bool(s.visible) and (not data.has("on") or _shown(data, t))
		if root.visible:
			root.transform = frame(t) * Transform3D(StudioMotion.basis_of(s, size), s.pos)

	## Where an effect on this model comes from at `t` (its origin; a rocket's engines).
	func anchor(t: float) -> Transform3D:
		return frame(t) * StudioMotion.transform(data, t)

	## The space this model's own place is in at `t` (round 2: the model it rides on, `on`; else the stage's), worked
	## out once a pose by the view.
	func frame(t: float) -> Transform3D:
		if not data.has("on"):
			return Transform3D.IDENTITY
		if view != null and view.has_method(&"frame_of"):
			return view.call(&"frame_of", data, t)
		return StudioMotion.frame(stage(), data, t)

	func _shown(m: Dictionary, t: float) -> bool:
		if view != null and view.has_method(&"shown_of"):
			return view.call(&"shown_of", m, t)
		return StudioMotion.shown(stage(), m, t)

	func _world(m: Dictionary, t: float) -> Transform3D:
		if view != null and view.has_method(&"world_of"):
			return view.call(&"world_of", m, t)
		return StudioMotion.world(stage(), m, t)

	func _model(id: String) -> Dictionary:
		if view != null and view.has_method(&"model_data"):
			return view.call(&"model_data", id)
		return StudioRules.model(stage(), id)

	## The stage this model is part of ({} outside a view).
	func stage() -> Dictionary:
		return view.get(&"stage") if view != null and view.get(&"stage") is Dictionary else {}

	func _mesh(parent: Node3D, m: Mesh) -> MeshInstance3D:
		var mi := MeshInstance3D.new()
		mi.mesh = m
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		parent.add_child(mi)
		return mi


## A rocket: one mesh per stage (and per build group), each placed on its own so a stage can let go.
class RocketBuilt:
	extends Built
	var rocket := {}
	var pivot := Vector3.ZERO
	var parts: Array = []        # [[MeshInstance3D, stage, group (-1: none), group's moment]]
	var nozzles: Array[Vector3] = []   # per stages dropped: where the flame starts (rocket space)

	func make(parent: Node3D) -> void:
		size = StudioRules.num(data, "size", 1.0)
		rocket = StudioRockets.rocket(str(data.get("rocket", "moon")))
		pivot = RocketStages.pivot(rocket.cells)
		var groups: Array = data.get("build", []) if data.get("build") is Array else []
		for i in RocketStages.stage_count(rocket):
			var cells := RocketStages.stage_cells(rocket, i)
			if groups.is_empty():
				parts.append([_part(parent, cells, "Stage%d" % i), i, -1, 0.0])
				continue
			var left := cells.duplicate()
			for g in groups.size():
				if groups[g].has("stage") and int(groups[g].stage) != i:
					continue
				var ids: Array = []
				for b: Variant in groups[g].blocks:
					ids.append(ShortCheck.block_id(b))
				var mine := {}
				for c: Vector3i in cells:
					if ids.has(cells[c]) and left.has(c):
						mine[c] = cells[c]
						left.erase(c)
				if not mine.is_empty():
					parts.append([_part(parent, mine, "Stage%dGroup%d" % [i, g]), i, g, float(groups[g].at)])
			if not left.is_empty():
				parts.append([_part(parent, left, "Stage%dRest" % i), i, -1, 0.0])
		for d in RocketStages.stage_count(rocket):
			nozzles.append(_nozzle(d))

	func _part(parent: Node3D, cells: Dictionary, part_name: String) -> MeshInstance3D:
		var mi := _mesh(parent, Scene3DModels.cells_mesh(cells, pivot))
		mi.name = "%s_%s" % [root.name, part_name]
		return mi

	func _nozzle(dropped: int) -> Vector3:
		var list := RocketStages.nozzles(rocket, dropped)
		var lo := Vector3(INF, INF, INF)
		var hi := -lo
		for c: Vector3i in list:
			lo = lo.min(Vector3(c))
			hi = hi.max(Vector3(c) + Vector3.ONE)
		if list.is_empty():
			return Vector3.ZERO
		var mid := (lo + hi) * 0.5 - pivot
		return Vector3(mid.x, lo.y - pivot.y - 0.15, mid.z)

	func pose(t: float) -> void:
		var s := StudioMotion.state(data, t)
		var shows := bool(s.visible)
		var here := _scaled(frame(t) * StudioMotion.transform(data, t))
		var dropped := StudioMotion.stages_dropped(data, t)
		var groups: Array = data.get("build", []) if data.get("build") is Array else []
		for p: Array in parts:
			var mi: MeshInstance3D = p[0]
			var stage := int(p[1])
			var xf := here
			var on := shows
			if stage < dropped:
				on = shows and StudioMotion.dropped_shows(data, stage, t)
				xf = _scaled(StudioMotion.dropped(data, stage, t))
			elif int(p[2]) >= 0:
				var g: Dictionary = groups[int(p[2])]
				var drop := StudioRules.num(g, "dur", 0.9)
				var since := t - float(p[3])
				on = on and since >= 0.0
				if since >= 0.0 and since < drop:
					var e := ShortTimeline.ease_value("bounce", since / drop)
					xf = xf.translated(Vector3(0, StudioRules.num(g, "height", 8.0) * (1.0 - e), 0))
			mi.visible = on
			if on:
				mi.transform = xf
		root.visible = false

	func _scaled(xf: Transform3D) -> Transform3D:
		return Transform3D(xf.basis.scaled(Vector3.ONE * size), xf.origin)

	## The flame comes from the lowest stage still attached, at its engines' bells.
	func anchor(t: float) -> Transform3D:
		var d := clampi(StudioMotion.stages_dropped(data, t), 0, maxi(nozzles.size() - 1, 0))
		var xf := _scaled(frame(t) * StudioMotion.transform(data, t))
		return xf * Transform3D(Basis.IDENTITY, nozzles[d] if d < nozzles.size() else Vector3.ZERO)


## A planet or the Sun: the flight's sphere and planet shader (a copy of its material: the stage lights it itself).
class PlanetBuilt:
	extends Built
	var sphere: MeshInstance3D
	var material: ShaderMaterial
	var glow: MeshInstance3D
	## The flight's own material this one copies, while its map still loads on a worker thread (a live Short never
	## waits for a picture: the sphere shows when its map is in; a rendered reel waits).
	var loading: ShaderMaterial

	func make(_parent: Node3D) -> void:
		size = StudioRules.num(data, "size", 5.0)
		sphere = _mesh(root, FlightLooks.sphere())
		var sun := str(data.get("model")) == "sun"
		var source := Scene3DModels.planet_source(&"sun" if sun else StringName(str(data.get("body", "moon"))))
		if not FlightLooks.has_map(source):
			if view.get(&"quality") == StudioRules.RENDER:
				FlightLooks.need(source)
			else:
				loading = source
		material = source.duplicate() as ShaderMaterial
		sphere.material_override = material
		if data.has("night"):   # round 2: a darker night side, so a phase or a sunset line reads on a phone
			material.set_shader_parameter(&"night", StudioRules.num(data, "night", 0.12))
		if sun:
			material.set_shader_parameter(&"night", 1.0)
			glow = MeshInstance3D.new()
			var quad := QuadMesh.new()
			quad.size = Vector2.ONE * 5.2
			quad.material = FlightLooks.sun_material()
			glow.mesh = quad
			glow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			root.add_child(glow)

	func pose(t: float) -> void:
		super.pose(t)
		if loading != null:
			FlightLooks.poll()
			if FlightLooks.has_map(loading):
				material.set_shader_parameter(&"surface", loading.get_shader_parameter(&"surface"))
				loading = null
		sphere.visible = loading == null
		if root.visible and str(data.get("model")) != "sun":
			material.set_shader_parameter(&"sun_dir", view.call(&"sun_toward", root.position))   # models sit in the stage's space


## The game's blocky person in a look, posed by EmotePoses at the stage's time (a wave, a cheer).
class AvatarBuilt:
	extends Built
	var body: BlockyAvatar

	func make(_parent: Node3D) -> void:
		size = StudioRules.num(data, "size", 1.0)
		body = BlockyAvatar.new()
		root.add_child(body)
		body.apply_look(Scene3DModels.look(str(data.get("look", "astronaut"))))
		body.set_process(false)
		body.set_physics_process(false)

	func pose(t: float) -> void:
		super.pose(t)
		if not root.visible:
			return
		var s := StudioMotion.state(data, t)
		var e: Dictionary = s.emote
		if not e.is_empty():
			body._show_emote(EmotePoses.sample(e.name, float(e.t)), 1.0)
		else:   # round 2: walking (legs and arms swing, or pulling a rope), else standing at rest
			body._show_emote(StudioMotion.walk_pose(s.walk), 1.0)


## Round 2: a blocks model of its own cells and shapes (StudioShapes), meshed like the world's blocks. A live stage
## fills its voxel buffer on a worker thread and meshes it on the main thread a frame later (the build of the next reel
## in the feed stays light; the Godot mesh is made on the main thread: a worker's made the headless renderer lose its
## meshes), and shows it the frame it is in; a rendered reel (and the tools, sync_blocks) meshes it at once. The same
## shapes again come from Scene3DBuilds' keep.
class BlocksBuilt:
	extends Built
	var key := 0
	var task := -1
	var made := {}

	func make(_parent: Node3D) -> void:
		size = StudioRules.num(data, "size", 1.0)
		key = Scene3DBuilds.shape_key(data)
		var have := Scene3DBuilds.kept(key)
		if not have.is_empty():
			_show(have)
			return
		Scene3DModels.mesher()   # made here, on the main thread
		if view.get(&"quality") == StudioRules.RENDER or Scene3DModels.sync_blocks:
			have = Scene3DBuilds.shape_mesh(data)
			Scene3DBuilds.keep(key, have)
			_show(have)
			return
		var copy := data.duplicate(true)
		var out := made
		task = WorkerThreadPool.add_task(func() -> void: out.merge(StudioShapes.buffer(copy)), false, "Reel Studio blocks")

	## True while its mesh is still being made.
	func building() -> bool:
		return task >= 0

	## True when its mesh has just come in (shown now).
	func poll() -> bool:
		if task < 0 or not WorkerThreadPool.is_task_completed(task):
			return false
		finish()
		return true

	## Waits for its buffer (the tools, a test), meshes it and shows it.
	func finish() -> void:
		if task < 0:
			return
		WorkerThreadPool.wait_for_task_completion(task)
		task = -1
		var have := Scene3DBuilds.mesh_of(made)
		Scene3DBuilds.keep(key, have)
		_show(have)

	## The stage went away first: the task is waited for when it is done.
	func abandon() -> void:
		if task >= 0:
			Scene3DBuilds.reap(task)
			task = -1

	func _show(m: Dictionary) -> void:
		if m.is_empty() or not is_instance_valid(root):
			return
		var mi := _mesh(root, m.mesh)
		mi.position = m.offset


## Round 2: a rope, a thin line from its `from` model to its `to` model wherever they go (StudioMotion.rope): one block
## of its `block`'s look (the world's own block material), stretched from end to end and `width` thick.
class RopeBuilt:
	extends Built
	var width := 0.06

	func make(_parent: Node3D) -> void:
		width = StudioRules.num(data, "width", 0.06)
		var id := ShortCheck.block_id(data.get("block", "PLANKS"))
		_mesh(root, Scene3DModels.cells_mesh({Vector3i.ZERO: id if id > 0 else BlockIds.PLANKS}, Vector3(0.5, 0.0, 0.5)))

	func pose(t: float) -> void:
		var a := _model(str(data.get("from", "")))
		var b := _model(str(data.get("to", "")))
		root.visible = bool(StudioMotion.state(data, t).visible) and not a.is_empty() and not b.is_empty() \
			and _shown(a, t) and _shown(b, t)
		if not root.visible:
			return
		# StudioMotion.rope, with the ends' places from the view's once-a-pose memo
		var from := _world(a, t) * StudioRules.vec(data.get("from_at"))
		var d := _world(b, t) * StudioRules.vec(data.get("to_at")) - from
		var y := d.normalized() if d.length() > 0.0001 else Vector3.UP
		var x := y.cross(Vector3.FORWARD if absf(y.dot(Vector3.FORWARD)) < 0.9 else Vector3.RIGHT).normalized()
		var z := x.cross(y).normalized()
		root.transform = Transform3D(Basis(x * width, y * maxf(d.length(), 0.0001), z * width), from)


## Saturn's rings up close: chunks of ice and rock (Fx's lit particle boxes in ice colours, one multimesh), from dust to
## boulders, in a thin band round the planet, each going round at its own speed (Kepler: the nearer, the faster), only
## in the `arc` a camera flies through. {size: the planet's radius (m), inner, outer (in radii), count, arc: [from, to]
## degrees, thick (radii), period: seconds a turn at the inner edge}.
class RingBitsBuilt:
	extends Built
	var bits: MultiMeshInstance3D
	var radius := PackedFloat32Array()
	var angle := PackedFloat32Array()
	var height := PackedFloat32Array()
	var scale_of := PackedFloat32Array()
	var colours: Array[Color] = []
	var turns: Array[Basis] = []
	var inner := 1.6
	var period := 60.0
	var _buf := PackedFloat32Array()

	func make(_parent: Node3D) -> void:
		var planet := StudioRules.num(data, "size", 60.0)
		size = 1.0
		inner = StudioRules.num(data, "inner", 1.6)
		var outer := StudioRules.num(data, "outer", 2.2)
		var thick := StudioRules.num(data, "thick", 0.015) * planet
		period = StudioRules.num(data, "period", 60.0)
		var arc: Array = data.get("arc", [0, 360]) if data.get("arc") is Array else [0, 360]
		var count := clampi(int(StudioRules.num(data, "count", 800.0)), 1, 3000)
		var rng := RandomNumberGenerator.new()
		rng.seed = 2004   # the year a spacecraft first went round Saturn and flew through the gap in its rings
		var ice: Array[Color] = [Color("f4f1ea"), Color("e6ddcc"), Color("d9cdb8"), Color("c8b9a2"), Color("fbfaf6")]
		for i in count:
			radius.append(lerpf(inner, outer, rng.randf()) * planet)
			angle.append(deg_to_rad(lerpf(float(arc[0]), float(arc[1]), rng.randf())))
			height.append(rng.randf_range(-0.5, 0.5) * thick)
			var r := rng.randf()
			scale_of.append(lerpf(0.06, 0.35, r) if r < 0.85 else lerpf(0.6, 1.8, (r - 0.85) / 0.15))   # most small
			colours.append(ice[rng.randi() % ice.size()].darkened(rng.randf() * 0.25))
			turns.append(Basis.from_euler(Vector3(rng.randf() * TAU, rng.randf() * TAU, rng.randf() * TAU)))
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_colors = true
		mm.use_custom_data = true   # CPUParticles3D's layout: Fx's instanced draw, no new shader
		mm.mesh = Scene3DEffects.unit_box(false)
		mm.instance_count = count
		mm.custom_aabb = AABB(-Vector3.ONE * outer * planet * 1.1, Vector3.ONE * outer * planet * 2.2)
		bits = MultiMeshInstance3D.new()
		bits.multimesh = mm
		bits.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(bits)
		_buf.resize(count * StudioParticles.STRIDE)

	func pose(t: float) -> void:
		super.pose(t)
		if not root.visible:
			return
		var planet := StudioRules.num(data, "size", 60.0)
		for i in radius.size():
			var w := TAU / period * pow(radius[i] / (inner * planet), -1.5)
			var a := angle[i] + w * t
			var s := scale_of[i]
			var b: Basis = turns[i]
			var o := i * StudioParticles.STRIDE
			var c: Color = colours[i]
			_buf[o] = b.x.x * s
			_buf[o + 1] = b.y.x * s
			_buf[o + 2] = b.z.x * s
			_buf[o + 3] = cos(a) * radius[i]
			_buf[o + 4] = b.x.y * s
			_buf[o + 5] = b.y.y * s
			_buf[o + 6] = b.z.y * s
			_buf[o + 7] = height[i]
			_buf[o + 8] = b.x.z * s
			_buf[o + 9] = b.y.z * s
			_buf[o + 10] = b.z.z * s
			_buf[o + 11] = -sin(a) * radius[i]
			_buf[o + 12] = c.r
			_buf[o + 13] = c.g
			_buf[o + 14] = c.b
			_buf[o + 15] = 1.0
		bits.multimesh.buffer = _buf


# --- Looks -----------------------------------------------------------------------------------------------------------

## A body's sphere material (a copy: the stage turns its day side to its own Sun). The Earth, the Moon, Mars and Mercury
## wear the flight's real maps; the gas giants bands of their colours; any other world the flight's painted look.
static func planet_material(body: StringName) -> ShaderMaterial:
	var m := planet_source(body)
	FlightLooks.need(m)
	return m.duplicate() as ShaderMaterial


## The material a body's copy is made from (kept: the flight's own, or the studio's for the Sun and the gas giants),
## its map perhaps still loading on a worker thread (FlightLooks.has_map).
static func planet_source(body: StringName) -> ShaderMaterial:
	if _sources.has(body):
		return _sources[body]
	var b := StarMap.body(body)
	var m: ShaderMaterial
	if body == &"earth":
		m = FlightLooks.earth_material()
	elif body == &"sun":
		m = FlightLooks._planet({"mode": 3, "map": FlightLooks.NOISE_MAP, "tint": Color("ffe27a"), "tint2": Color("ff9a2a"),
			"rim": Color(1.0, 0.85, 0.4, 0.9)})
	elif body in [&"jupiter", &"saturn", &"uranus", &"neptune"]:
		var c1: Color = b.get("color", Color.WHITE)
		var c2: Color = b.get("color2", c1.darkened(0.3))
		m = FlightLooks._planet({"mode": 3, "map": FlightLooks.NOISE_MAP, "tint": c1, "tint2": c2,
			"rim": Color(c1.lightened(0.35), 0.55)})
		m.set_shader_parameter(&"surface", bands(body, c1, c2))
		m.set_shader_parameter(&"mode", 2)
	elif int(b.get("world", 0)) > 0:
		m = FlightLooks.planet_material(int(b.world))
	else:
		var c1: Color = b.get("color", Color("a0a0a8"))
		m = FlightLooks._planet({"mode": 3, "map": FlightLooks.NOISE_MAP, "tint": c1, "tint2": b.get("color2", c1.darkened(0.3)),
			"rim": Color(c1.lightened(0.3), 0.0)})
	_sources[body] = m
	return m


## A gas giant's map: bands of its two colours across its latitudes, wavy and soft (Jupiter's Great Red Spot too):
## our own picture, made once.
static func bands(body: StringName, c1: Color, c2: Color) -> ImageTexture:
	if _bands.has(body):
		return _bands[body]
	if _band_task >= 0:
		WorkerThreadPool.wait_for_task_completion(_band_task)   # made since the Shorts opened: done by now
		_band_task = -1
	var img: Image = _band_images.get(body) if _band_images.has(body) else band_image(body, c1, c2)
	var tex := ImageTexture.create_from_image(img)
	_bands[body] = tex
	return tex


## The band picture itself (any thread: an Image only).
static func band_image(body: StringName, c1: Color, c2: Color) -> Image:
	var img := Image.create(BAND_SIZE.x, BAND_SIZE.y, false, Image.FORMAT_RGBA8)
	var noise := FastNoiseLite.new()
	noise.seed = hash(body)
	noise.frequency = 0.03
	var stripes := 9.0 if body == &"jupiter" else (7.0 if body == &"saturn" else 3.0)
	for y in BAND_SIZE.y:
		for x in BAND_SIZE.x:
			var lat := float(y) / BAND_SIZE.y
			var wave := noise.get_noise_2d(x * 1.0, y * 3.0) * 0.08
			var band := 0.5 + 0.5 * sin((lat + wave) * PI * stripes * 2.0)
			var c := c1.lerp(c2, band * (0.8 if body == &"jupiter" else 0.55))
			c = c.lerp(Color.WHITE, 0.06 * noise.get_noise_2d(x * 4.0, y * 4.0))
			if body == &"jupiter":
				var spot := Vector2((x - BAND_SIZE.x * 0.62) / 14.0, (y - BAND_SIZE.y * 0.64) / 7.0)
				if spot.length() < 1.0:
					c = c.lerp(Color("c0502e"), 1.0 - spot.length_squared())
			img.set_pixel(x, y, Color(c.r, c.g, c.b, 1.0))
	img.generate_mipmaps()
	return img


## Saturn's rings round a planet of radius 1 (scaled by the model's size): the faint C ring, the bright B ring, the
## Cassini gap, the A ring and the thin F ring (radii in Saturn's radii, NASA's Saturn fact sheet), see-through.
static func rings_mesh(_radius: float, tint: Color) -> ArrayMesh:
	var key := tint.to_html()
	if _rings.has(key):
		return _rings[key]
	var bands_list := [[1.24, 1.53, 0.35], [1.53, 1.95, 0.95], [1.95, 2.03, 0.08], [2.03, 2.27, 0.7], [2.32, 2.34, 0.5]]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := 128
	for band: Array in bands_list:
		var steps := 6 if float(band[1]) - float(band[0]) > 0.1 else 1
		for k in steps:
			var r0 := lerpf(band[0], band[1], float(k) / steps)
			var r1 := lerpf(band[0], band[1], float(k + 1) / steps)
			var a := float(band[2]) * (0.8 + 0.2 * sin(float(k) * 2.3 + r0 * 11.0))
			var c := tint.darkened(0.25 * (1.0 - float(band[2])))
			c.a = a
			for i in n:
				var t0 := TAU * i / n
				var t1 := TAU * (i + 1) / n
				var p := [Vector3(cos(t0) * r0, 0, sin(t0) * r0), Vector3(cos(t0) * r1, 0, sin(t0) * r1),
					Vector3(cos(t1) * r1, 0, sin(t1) * r1), Vector3(cos(t1) * r0, 0, sin(t1) * r0)]
				for v: Vector3 in [p[0], p[1], p[2], p[0], p[2], p[3]]:
					st.set_color(c)
					st.set_normal(Vector3.UP)
					st.add_vertex(v)
	st.set_material(FlightLooks.night_material())
	_rings[key] = st.commit()
	return _rings[key]


## A thin flat ring (an orbit) of `radius` and `width`.
static func ring_line(radius: float, width: float, c: Color) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := 160
	for i in n:
		var t0 := TAU * i / n
		var t1 := TAU * (i + 1) / n
		var r0 := radius - width * 0.5
		var r1 := radius + width * 0.5
		var p := [Vector3(cos(t0) * r0, 0, sin(t0) * r0), Vector3(cos(t0) * r1, 0, sin(t0) * r1),
			Vector3(cos(t1) * r1, 0, sin(t1) * r1), Vector3(cos(t1) * r0, 0, sin(t1) * r0)]
		for v: Vector3 in [p[0], p[1], p[2], p[0], p[2], p[3]]:
			st.set_color(c)
			st.set_normal(Vector3.UP)
			st.add_vertex(v)
	st.set_material(FlightLooks.night_material())
	return st.commit()


## The flight's landing ground under `root`: a wide disc of the dust tile tinted per world, and its boulders.
static func ground(root: Node3D, look: String, radius: float, rocks: bool) -> void:
	var tint: Color = {"moon": Color(0.86, 0.86, 0.88), "mars": Color(1.0, 0.58, 0.36), "grass": Color(0.34, 0.6, 0.27),
		"sand": Color(0.95, 0.82, 0.55), "concrete": Color(0.78, 0.78, 0.8)}.get(look, Color.WHITE)
	var r := maxf(radius, 10.0)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := 64
	var tile := 6.0
	for i in n:
		var a0 := TAU * i / n
		var a1 := TAU * (i + 1) / n
		for p: Vector3 in [Vector3.ZERO, Vector3(cos(a0), 0, sin(a0)) * r, Vector3(cos(a1), 0, sin(a1)) * r]:
			st.set_color(tint)
			st.set_normal(Vector3.UP)
			st.set_uv(Vector2(p.x, p.z) / tile)
			st.add_vertex(p)
	st.set_material(FlightLooks.ground_material())
	var disc := MeshInstance3D.new()
	disc.name = "Dust"
	disc.mesh = st.commit()
	disc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(disc)
	if rocks:
		var boulders := MeshInstance3D.new()
		boulders.name = "Rocks"
		boulders.mesh = FlightSet._rocks_mesh(tint)
		boulders.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(boulders)


## The flight's landing pad (its teal ring and golden star).
static func pad_mesh() -> ArrayMesh:
	var set := FlightSet.new()
	var m := set._pad_mesh()
	set.free()
	return m


## Soft cloud puffs (the flight's nebula puffs: its cloud picture on billboards) in a flat field round the middle.
static func clouds(root: Node3D, data: Dictionary) -> void:
	var colour := ShortRules.colour(data.get("color"), Color("fbe3a0"))
	var radius := StudioRules.num(data, "size", 200.0)
	var count := int(StudioRules.num(data, "count", 60.0))
	var rng := RandomNumberGenerator.new()
	rng.seed = 5150
	var mat := FlightLooks.puff_material(colour)
	for i in count:
		var a := rng.randf() * TAU
		var d := sqrt(rng.randf()) * radius
		var q := QuadMesh.new()
		var s := rng.randf_range(0.18, 0.34) * radius
		q.size = Vector2(s * 1.6, s)
		q.material = mat
		var mi := MeshInstance3D.new()
		mi.mesh = q
		mi.position = Vector3(cos(a) * d, rng.randf_range(-0.04, 0.04) * radius, sin(a) * d)
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(mi)


## `cells` ({Vector3i: block id}) meshed like the world's blocks (the voxel mesher with the world's own block library:
## its materials and its shade in the corners), moved so `origin` (cell space) is the mesh's 0.
static func cells_mesh(cells: Dictionary, origin: Vector3 = Vector3.ZERO) -> Mesh:
	if cells.is_empty():
		return ArrayMesh.new()
	var lo := Vector3i(1 << 30, 1 << 30, 1 << 30)
	var hi := -lo
	for c: Vector3i in cells:
		lo = lo.min(c)
		hi = hi.max(c)
	var buf := VoxelBuffer.new()
	var size := hi - lo + Vector3i(3, 3, 3)
	buf.create(size.x, size.y, size.z)
	for c: Vector3i in cells:
		var p := c - lo + Vector3i.ONE
		buf.set_voxel(int(cells[c]), p.x, p.y, p.z, VoxelBuffer.CHANNEL_TYPE)
	var mesh := mesher().build_mesh(buf, [], {})
	if mesh == null:
		return ArrayMesh.new()
	return _moved(mesh, Vector3(lo) - origin + MESHER_SHIFT)


static var _mesher: VoxelMesherBlocky


## The world's blocky mesher (its library, its corner shade).
static func mesher() -> VoxelMesherBlocky:
	if _mesher == null:
		_mesher = VoxelMesherBlocky.new()
		_mesher.library = WorldService.library()
		_mesher.occlusion_darkness = 0.75
	return _mesher


## `mesh` with every vertex moved by `by` (the mesher's buffer starts at its padding).
static func _moved(mesh: Mesh, by: Vector3) -> ArrayMesh:
	var out := ArrayMesh.new()
	for s in mesh.get_surface_count():
		var arrays := mesh.surface_get_arrays(s)
		var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		for i in verts.size():
			verts[i] += by
		arrays[Mesh.ARRAY_VERTEX] = verts
		out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		out.surface_set_material(out.get_surface_count() - 1, mesh.surface_get_material(s))
	return out


## An avatar's look for a reel: an astronaut (the catalogue's suit), an explorer, or the child's first look.
static func look(name: String) -> AvatarLook:
	var l := AvatarLook.new()
	match name:
		"astronaut":
			l.outfit = &"astronaut"
		"explorer":
			l.hat = &"explorer"
			l.shirt = &"green"
	return l
