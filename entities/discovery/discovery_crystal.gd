class_name DiscoveryCrystal
extends Node3D
## Owner #132 (W1), stage 2: the discovery crystal in the world (DiscoveryDirector makes it; this device's own, never
## sent). A tall glowing crystal with a "?" floats a little above the ground, turning slowly; it rises out of the ground
## with a chime. While its play runs it shows the number to make above it (or the order line, "−7 < ? < ? < ?") and the
## number it holds just over it, and gems with numbers float in two rows beside it, facing the child (MAKE's
## from the biggest place on the left to the ones on the right, as digits are written). The world answers each move: a
## gem flies into the crystal (MAKE: it pops back at its place), or shakes and
## bounces off; the helpful gem pulses after two misses; a solved challenge flashes the crystal and sparkles. Numbers and
## signs only (owner #133).
## Cheap: one unshaded vertex-colour material for every mesh (AvatarParts.part_glow_material, warmed), billboard labels
## like the animals' tags (warmed), no light, no shadow, no physics body (the child walks through it).
## The learning places' look (2026-10-18, docs/devlog/parts/academy-look.md): a cluster (the tall crystal with four small
## ones leaning out at its foot and motes of light turning round it, one glowing mesh), a soft see-through halo that
## breathes in and out (the mirror wall's warmed see-through settings) and a ring of stones on the ground (the rooms'
## warmed lit material); the first touch sparkles with a soft chime.

const WAITING := &"waiting"
const PLAYING := &"playing"
const GOING := &"going"

## The crystal's size and float (metres), its turn (radians a second) and bob.
const HEIGHT := 1.8
const RADIUS := 0.5
const LIFT := 0.35
const TURN := 0.6
const BOB := 0.06
## The gems in two rows beside the crystal, facing the child: the gap beside the crystal, the step between gems, how
## far beyond the crystal they float (never in front of it), their heights (the bottom row, the top row).
const GEM_GAP := 1.1
const GEM_STEP := 1.0
const GEM_DEPTH := 0.5
const GEM_HEIGHTS: Array[float] = [1.0, 1.9]
const GEM_SIZE := 0.32
## How near a ray or a hand must pass to touch a gem or the crystal.
const GEM_HIT := 0.45
const BODY_HIT := 0.7

const HALO := Color(0.62, 0.95, 1.0, 0.16)
## The halo's breath: how much it swells, and how fast (radians a second).
const BREATH := 0.07
const BREATH_RATE := 2.1
const TOP := Color(0.75, 1.0, 1.0)
const MIDDLE := Color(0.3, 0.8, 1.0)
const BOTTOM := Color(0.5, 0.35, 1.0)
## The gems' colours: the biggest value first (MAKE), or one each (ORDER); negatives are cool.
const WARM: Array[Color] = [Color("ffcf3a"), Color("ff8a3d"), Color("ff5d8f"), Color("b67dff"), Color("4fd1ff"),
	Color("5fe08a")]
const COOL: Array[Color] = [Color("3a7bff"), Color("6a5cff")]

var phase := WAITING
## The gem that pulses (the helpful one after two misses); -1 for none.
var glowing := -1
var body: MeshInstance3D
## The halo that breathes round the crystal, and the stones at its foot.
var halo: MeshInstance3D
var stones: MeshInstance3D
## How many times it has sparkled at a touch.
var sparkles := 0
var count: Label3D
var goal: Label3D

var _lift := Node3D.new()
var _gems: Array[Node3D] = []
var _homes: Array[Vector3] = []   # each gem's place (local)
var _t := 0.0
var _glow_tween: Tween

static var _mesh_cache := {}


func _init() -> void:
	name = "DiscoveryCrystal"
	_lift.name = "Lift"
	add_child(_lift)
	body = MeshInstance3D.new()
	body.name = "Body"
	body.mesh = _crystal_mesh()
	body.material_override = AvatarParts.part_glow_material()
	body.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_lift.add_child(body)
	halo = MeshInstance3D.new()
	halo.name = "Halo"
	halo.mesh = _halo_mesh()
	halo.material_override = LifeRoomKit.material(HALO)
	halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_lift.add_child(halo)
	stones = MeshInstance3D.new()
	stones.name = "Stones"
	stones.mesh = _stones_mesh()
	stones.material_override = LifeRoomDecor.lit_material()
	stones.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(stones)   # on the ground: the crystal rises out of their ring and floats over it
	count = _label(120, Color.WHITE)   # a big "?" while it waits; the number it holds is smaller (show_challenge)
	count.name = "Count"
	count.text = "?"
	count.position = Vector3(0, HEIGHT + 0.45, 0)   # over the crystal: inside it the crystal would hide it
	_lift.add_child(count)
	goal = _label(84, Color("ffe066"))
	goal.name = "Goal"
	goal.position = Vector3(0, HEIGHT + 1.4, 0)
	goal.visible = false
	add_child(goal)


## Rises out of the ground (a chime where it stands).
func rise() -> void:
	_lift.position.y = -HEIGHT - 0.4
	_lift.scale = Vector3.ONE * 0.4
	var tw := create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_lift, "position:y", LIFT, 1.1)
	tw.tween_property(_lift, "scale", Vector3.ONE, 1.1)
	Audio.play(&"chime", global_position + Vector3.UP)


func _process(delta: float) -> void:
	_t += delta
	body.rotation.y += TURN * delta
	halo.scale = Vector3.ONE * (1.0 + BREATH * sin(_t * BREATH_RATE))   # a slow glow in and out
	if phase != GOING and _lift.position.y >= LIFT - 0.01:
		_lift.position.y = LIFT + sin(_t * 1.6) * BOB
	for i in _gems.size():
		if i != glowing:
			_gems[i].position.y = _homes[i].y + sin(_t * 2.0 + i) * 0.04


# --- The play ------------------------------------------------------------------------------------------------------

## Shows challenge `c` (DiscoveryPlays' shape) with its gems in two rows beside the crystal, facing `child` (a world
## position), on the side away from the middle of the child's view (`view_right`: the camera's right; zero: the left), so
## a camera behind the child's avatar sees them all; `held`: the number the crystal holds now (MAKE).
func show_challenge(c: Dictionary, child: Vector3, held: String, view_right: Vector3 = Vector3.ZERO) -> void:
	if phase == WAITING:
		_sparkle()   # the first touch
	phase = PLAYING
	glow(-1)
	for g in _gems:
		g.queue_free()
	_gems.clear()
	_homes.clear()
	var away := global_position - child
	away.y = 0.0
	if away.length() < 0.01:
		away = Vector3.FORWARD
	away = away.normalized()
	var right := away.cross(Vector3.UP)   # the child's right as they face the crystal
	var side := -1.0
	if view_right != Vector3.ZERO and view_right.dot(global_position - child) > 0.0:
		side = 1.0   # the crystal is right of the view's middle: its gems go further right
	var labels: Array = c.labels
	var n := labels.size()
	var cols := ceili(n / 2.0)
	for i in n:
		var row := i / cols   # the first row on top: read like writing, left to right, top to bottom
		var col := i % cols
		var x := GEM_GAP + (col if side > 0.0 else cols - 1 - col) * GEM_STEP
		var home := right * x * side + away * GEM_DEPTH + Vector3.UP * GEM_HEIGHTS[1 - mini(row, 1)]
		var gem := _gem(str(labels[i]), _gem_colour(c, i))
		gem.position = home
		add_child(gem)
		_gems.append(gem)
		_homes.append(home)
	goal.visible = true
	count.font_size = 64
	if str(c.kind) == "make":
		goal.text = str(c.shown)
		count.text = held
	else:
		count.text = ""
		order_line(c, [])


## ORDER's line over the crystal: the gems taken so far, then a "?" for each left ("−7 < 0 < ? < ?").
func order_line(c: Dictionary, taken: Array[int]) -> void:
	var parts: Array[String] = []
	for i: int in taken:
		parts.append(str((c.labels as Array)[i]))
	for k in (c.labels as Array).size() - taken.size():
		parts.append("?")
	goal.text = " < ".join(parts)


func gem_count() -> int:
	return _gems.size()


## Where gem `i` floats (its place, not where a flight has it now).
func gem_position(i: int) -> Vector3:
	return to_global(_homes[i]) if i >= 0 and i < _homes.size() else Vector3.INF


## Every number shown (the labels' texts): the word-budget check reads it.
func words() -> String:
	var out: Array[String] = [count.text, goal.text if goal.visible else ""]
	for g in _gems:
		out.append((g.get_node("Label") as Label3D).text)
	return " ".join(out)


## The gem nearest the ray (origin, dir) within GEM_HIT of it, -1 for none.
func gem_hit(origin: Vector3, dir: Vector3) -> int:
	var best := -1
	var best_t := INF
	for i in _gems.size():
		if not _gems[i].visible:
			continue
		var p := gem_position(i)
		var t := (p - origin).dot(dir)
		if t <= 0.0:
			continue
		if (origin + dir * t).distance_to(p) <= GEM_HIT and t < best_t:
			best = i
			best_t = t
	return best


## The ray (origin, dir) passes through the crystal.
func body_hit(origin: Vector3, dir: Vector3) -> bool:
	var p := global_position + Vector3.UP * (LIFT + HEIGHT * 0.5)
	var t := (p - origin).dot(dir)
	return t > 0.0 and (origin + dir * t).distance_to(p) <= BODY_HIT


## A gem within `reach` of `point` (a hand), -1 for none.
func gem_near(point: Vector3, reach: float) -> int:
	for i in _gems.size():
		if _gems[i].visible and gem_position(i).distance_to(point) <= reach:
			return i
	return -1


## `point` (a hand) touches the crystal.
func body_near(point: Vector3, reach: float) -> bool:
	var base := global_position + Vector3.UP * LIFT
	var top := base + Vector3.UP * HEIGHT
	var t := clampf((point - base).dot(Vector3.UP), 0.0, HEIGHT)
	return point.distance_to(base.lerp(top, t / HEIGHT)) <= RADIUS + reach


## A gem flew in: MAKE's number changes (`held`) and the gem pops back at its place; ORDER's stays taken.
func on_taken(i: int, c: Dictionary, held: String, taken: Array[int]) -> void:
	glow(-1)
	var gem := _gems[i]
	var tw := gem.create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(gem, "position", Vector3(0, LIFT + HEIGHT * 0.5, 0), 0.22)
	tw.parallel().tween_property(gem, "scale", Vector3.ONE * 0.3, 0.22)
	if str(c.kind) == "make":
		tw.tween_callback(func() -> void:
			count.text = held
			gem.position = _homes[i]
			gem.scale = Vector3.ONE * 0.01)
		tw.tween_property(gem, "scale", Vector3.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	else:
		tw.tween_callback(func() -> void: gem.visible = false)
		order_line(c, taken)
	_pulse(1.12)
	Audio.play(&"sparkle", gem_position(i))


## A gem bounced off (a miss: nothing changes); `hint` glows when it is shown (-1: none yet).
func on_bounced(i: int, hint: int) -> void:
	var gem := _gems[i]
	var home := _homes[i]
	var push := (home - Vector3(0, home.y, 0)).normalized() * 0.35
	var tw := gem.create_tween().set_trans(Tween.TRANS_SINE)
	tw.tween_property(gem, "position", home + push, 0.12)
	tw.tween_property(gem, "position", home - push * 0.4, 0.1)
	tw.tween_property(gem, "position", home, 0.12)
	Audio.play(&"boing", gem_position(i))
	if hint >= 0:
		glow(hint)


## Gem `i` pulses (the helpful one); -1 stops it.
func glow(i: int) -> void:
	if _glow_tween and _glow_tween.is_valid():
		_glow_tween.kill()
	if glowing >= 0 and glowing < _gems.size():
		_gems[glowing].scale = Vector3.ONE
	glowing = i
	if i < 0 or i >= _gems.size():
		glowing = -1
		return
	_glow_tween = _gems[i].create_tween().set_loops()
	_glow_tween.tween_property(_gems[i], "scale", Vector3.ONE * 1.45, 0.35).set_trans(Tween.TRANS_SINE)
	_glow_tween.tween_property(_gems[i], "scale", Vector3.ONE, 0.35).set_trans(Tween.TRANS_SINE)


## A challenge solved: the crystal flashes and sparkles.
func on_made() -> void:
	glow(-1)
	_pulse(1.35)
	if is_inside_tree():
		Fx.burst(get_parent(), global_position + Vector3.UP * (LIFT + HEIGHT * 0.6), MIDDLE.lightened(0.3), 18, 4.0)
		Audio.play(&"jingle_goal", global_position + Vector3.UP)


## Goes: sinks and shrinks away (`celebrate`: with confetti first, the whole play done), then frees itself.
func go(celebrate: bool) -> void:
	if phase == GOING:
		return
	phase = GOING
	glow(-1)
	if celebrate and is_inside_tree():
		Fx.confetti(get_parent(), global_position + Vector3.UP * (LIFT + HEIGHT), [TOP, MIDDLE, BOTTOM, WARM[0]], 28)
		Audio.play(&"jingle_badge", global_position + Vector3.UP)
	if not is_inside_tree():
		queue_free()
		return
	var tw := create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw.tween_property(self, "scale", Vector3.ONE * 0.05, 0.8).set_delay(0.4 if celebrate else 0.0)
	tw.tween_property(_lift, "position:y", -0.6, 0.8).set_delay(0.4 if celebrate else 0.0)
	tw.chain().tween_callback(queue_free)


## A touch: a sparkle round the crystal and a soft chime.
func _sparkle() -> void:
	sparkles += 1
	_pulse(1.08)
	if is_inside_tree():
		Fx.burst(get_parent(), global_position + Vector3.UP * (LIFT + HEIGHT * 0.5), TOP, 12, 2.2)
		Audio.play(&"sparkle", global_position + Vector3.UP)


func _pulse(to: float) -> void:
	var tw := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(body, "scale", Vector3.ONE * to, 0.12)
	tw.tween_property(body, "scale", Vector3.ONE, 0.3)


# --- Pieces --------------------------------------------------------------------------------------------------------

## A billboard label like the animals' tags (the warm-up holds its shader).
static func _label(size: int, colour: Color) -> Label3D:
	var l := Label3D.new()
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.font_size = size
	l.outline_size = 12
	l.pixel_size = 0.01
	l.modulate = colour
	return l


func _gem(text: String, colour: Color) -> Node3D:
	var gem := Node3D.new()
	gem.name = "Gem"
	var m := MeshInstance3D.new()
	m.mesh = _gem_mesh(colour)
	m.material_override = AvatarParts.part_glow_material()
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	gem.add_child(m)
	var l := _label(40, Color.WHITE)
	l.pixel_size = 0.008   # "100,000" stays narrower than the gaps between the gems
	l.name = "Label"
	l.text = text
	l.position = Vector3(0, GEM_SIZE + 0.26, 0)
	gem.add_child(l)
	return gem


func _gem_colour(c: Dictionary, i: int) -> Color:
	if str(c.kind) == "make":
		var v := int((c.gems as Array)[i])
		if v < 0:
			return COOL[i % COOL.size()]
		return WARM[i % WARM.size()]
	return WARM[i % WARM.size()]


## The cluster: a tall hexagonal bipyramid light at the top and violet at the foot, four small ones leaning out round
## its foot, and motes of light round it (vertex colours, one mesh).
static func _crystal_mesh() -> ArrayMesh:
	if _mesh_cache.has("crystal"):
		return _mesh_cache["crystal"]
	var verts := PackedVector3Array()
	var colours := PackedColorArray()
	_add_bipyramid(verts, colours, Transform3D.IDENTITY, 6, RADIUS, HEIGHT * 0.42, HEIGHT * 0.58, TOP, MIDDLE, BOTTOM)
	var small := [[0.5, 0.62, Color(0.85, 0.75, 1.0), Color(0.62, 0.48, 1.0)], [2.1, 0.5, Color(0.7, 1.0, 1.0), Color(0.3, 0.75, 1.0)],
		[3.7, 0.7, Color(0.95, 0.8, 1.0), Color(0.75, 0.5, 1.0)], [5.2, 0.45, Color(0.75, 1.0, 0.95), Color(0.35, 0.85, 0.95)]]
	for k: Array in small:
		var a: float = k[0]
		var tall: float = k[1]
		var out := Vector3(cos(a), 0.0, sin(a))
		var xf := Transform3D(Basis(out.cross(Vector3.UP).normalized(), -0.5), out * (RADIUS * 0.85) + Vector3(0, 0.05, 0))
		_add_bipyramid(verts, colours, xf, 5, RADIUS * 0.34, tall * 0.35, tall * 0.65, k[2], k[3], BOTTOM)
	for i in 7:   # motes of light, turning with it
		var a := TAU * i / 7.0 + 0.3
		var at := Vector3(cos(a) * (RADIUS + 0.38 + 0.08 * (i % 3)), 0.35 + HEIGHT * 0.85 * float(i) / 7.0, sin(a) * (RADIUS + 0.38))
		_add_bipyramid(verts, colours, Transform3D(Basis(), at), 4, 0.045, 0.045, 0.05, Color.WHITE, TOP, MIDDLE)
	var m := _to_mesh(verts, colours)
	_mesh_cache["crystal"] = m
	return m


## The halo: a wider, taller bipyramid round the crystal (seen through).
static func _halo_mesh() -> ArrayMesh:
	if not _mesh_cache.has("halo"):
		var verts := PackedVector3Array()
		var colours := PackedColorArray()
		_add_bipyramid(verts, colours, Transform3D(Basis(), Vector3(0, -0.12, 0)), 8, RADIUS * 1.35, HEIGHT * 0.45,
			HEIGHT * 0.66, Color.WHITE, Color.WHITE, Color.WHITE)
		_mesh_cache["halo"] = _to_mesh(verts, colours)
	return _mesh_cache["halo"]


## A ring of grey stones on the ground round it (lit).
static func _stones_mesh() -> ArrayMesh:
	if not _mesh_cache.has("stones"):
		var boxes := []
		for i in 9:
			var a := TAU * i / 9.0 + 0.2
			var r := RADIUS + 0.55 + 0.1 * float(i % 2)
			var size := Vector3(0.28 + 0.06 * float(i % 3), 0.14 + 0.05 * float(i % 2), 0.22 + 0.05 * float((i + 1) % 3))
			boxes.append([Vector3(cos(a) * r, size.y * 0.5, sin(a) * r), size, Color("9aa3ad").lightened(0.06 * float(i % 3)),
				Basis(Vector3.UP, a * 1.7)])
		_mesh_cache["stones"] = LifeRoomDecor.boxes_mesh(boxes)
	return _mesh_cache["stones"]


static func _gem_mesh(colour: Color) -> ArrayMesh:
	var key := "gem_" + colour.to_html()
	if not _mesh_cache.has(key):
		_mesh_cache[key] = _bipyramid(4, GEM_SIZE, GEM_SIZE * 0.9, GEM_SIZE * 1.1, colour.lightened(0.45), colour,
			colour.darkened(0.25), -GEM_SIZE * 0.9)
	return _mesh_cache[key]


## A bipyramid of `sides`: its foot `below` under the ring, its tip `above` over it (from y `base`).
static func _bipyramid(sides: int, r: float, below: float, above: float, top: Color, ring: Color, foot: Color,
		base: float = 0.0) -> ArrayMesh:
	var verts := PackedVector3Array()
	var colours := PackedColorArray()
	_add_bipyramid(verts, colours, Transform3D(Basis(), Vector3(0, base, 0)), sides, r, below, above, top, ring, foot)
	return _to_mesh(verts, colours)


## A bipyramid's triangles into `verts` and `colours`, placed by `xf` (its foot at the frame's origin).
static func _add_bipyramid(verts: PackedVector3Array, colours: PackedColorArray, xf: Transform3D, sides: int, r: float,
		below: float, above: float, top: Color, ring: Color, foot: Color) -> void:
	var low := Vector3(0, 0, 0)
	var base := 0.0
	var mid := base + below
	var tip := Vector3(0, mid + above, 0)
	for i in sides:
		var a0 := TAU * i / sides
		var a1 := TAU * (i + 1) / sides
		var p0 := Vector3(cos(a0) * r, mid, sin(a0) * r)
		var p1 := Vector3(cos(a1) * r, mid, sin(a1) * r)
		var shade := 0.85 + 0.15 * cos(a0 * 2.0)   # facets catch the light differently (unshaded: painted in)
		var lit := Color(ring.r * shade, ring.g * shade, ring.b * shade)
		# both windings: the shared material culls back faces, so every facet shows from outside whichever way round
		for tri: Array in [[tip, p1, p0], [tip, p0, p1], [low, p0, p1], [low, p1, p0]]:
			verts.append_array([xf * (tri[0] as Vector3), xf * (tri[1] as Vector3), xf * (tri[2] as Vector3)])
			colours.append_array([top if tri[0] == tip else foot, lit, lit])


static func _to_mesh(verts: PackedVector3Array, colours: PackedColorArray) -> ArrayMesh:
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_COLOR] = colours
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh
