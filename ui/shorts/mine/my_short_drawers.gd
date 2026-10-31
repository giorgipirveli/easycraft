class_name MyShortDrawers
extends RefCounted
## MAKE MY SHORT (spec §5.12b "As built (My Shorts)"): the drawers of the actor kinds a child's Short brings (their
## checks: MyShortRules.kind_problem; both registered with the Shorts' pluggable kinds, ShortKinds and ShortDrawers):
## - photo: a photo of the album in a white frame with a soft shadow, cropped to fill its box; it loads off the main
##   thread (MyShortAlbum.texture): until then (or if the photo is gone) the frame shows a camera;
## - me: the child's avatar (their own look, AvatarIcon's blocky figure) doing an emote again and again (EmotePoses);
## - wonder: a wonder's stamp (WonderStamp, the Wonders Passport's);
## - build: a build's blocks seen from above its front right corner, with the game's own block pictures, its first
##   `value` layers shown and the next one dropping in as the value grows (a Step by step).
## Drawn with UI draw calls and the game's own pictures only.

## () -> AvatarLook: whose look `me` shows (the profile's; tests and tools set one).
static var look_source := Callable()

const FRAME := 8.0
const PAPER := Color("fdf6e3")
const SHADOW := Color(0, 0, 0, 0.28)
const EMPTY := Color("9fb3c8")
const EMOTE_REST := 0.7


static func drawer(kind: String) -> ShortDrawer:
	match kind:
		"photo":
			return PhotoDrawer.new()
		"me":
			return MeDrawer.new()
		"wonder":
			return WonderDrawer.new()
		"build":
			return BuildDrawer.new()
	return ShortDrawer.new()


static func look() -> AvatarLook:
	if look_source.is_valid():
		var v: Variant = look_source.call()
		if v is AvatarLook:
			return v
	var main := Engine.get_main_loop() as SceneTree
	var profile: Node = main.root.get_node_or_null("Profile") if main else null
	if profile != null and profile.get("data") is ProfileData:
		return (profile.data as ProfileData).avatar
	return AvatarLook.new()


## A camera (the photo's place while it loads, or when it is gone).
static func draw_camera(ci: CanvasItem, r: Rect2, colour: Color) -> void:
	var u := minf(r.size.x, r.size.y) * 0.4
	var c := r.get_center()
	var body := Rect2(c - Vector2(u, u * 0.62), Vector2(u * 2.0, u * 1.3))
	var box := StyleBoxFlat.new()
	box.bg_color = colour
	box.set_corner_radius_all(int(u * 0.2))
	ci.draw_style_box(box, body)
	ci.draw_rect(Rect2(c + Vector2(-u * 0.5, -u * 0.86), Vector2(u * 0.6, u * 0.3)), colour)
	ci.draw_circle(c + Vector2(0, u * 0.04), u * 0.42, Color(1, 1, 1, 0.9))
	ci.draw_circle(c + Vector2(0, u * 0.04), u * 0.28, colour)


## `tex` drawn to fill `dest`, cropped round its middle (no stretching).
static func draw_cover(ci: CanvasItem, tex: Texture2D, dest: Rect2) -> void:
	var ts := Vector2(tex.get_width(), tex.get_height())
	if ts.x <= 0.0 or ts.y <= 0.0:
		return
	var want := dest.size.x / dest.size.y
	var src := Rect2(Vector2.ZERO, ts)
	if ts.x / ts.y > want:
		src.size.x = ts.y * want
		src.position.x = (ts.x - src.size.x) * 0.5
	else:
		src.size.y = ts.x / want
		src.position.y = (ts.y - src.size.y) * 0.5
	ci.draw_texture_rect_region(tex, dest, src)


## A photo of the album in its white frame.
class PhotoDrawer:
	extends ShortDrawer

	func setup(actor: ShortActor) -> void:
		var box := Vector2(StudioRules.num(actor.data, "w", 296.0), StudioRules.num(actor.data, "h", 166.0))
		actor.size = box + Vector2.ONE * MyShortDrawers.FRAME * 2.0
		var path := MyShortAlbum.photo_path(str(actor.data.get("file", "")))
		var ref: WeakRef = weakref(actor)
		var tex := MyShortAlbum.texture(path, func(t: Texture2D) -> void:
			var a: ShortActor = ref.get_ref()
			if a != null:
				a.set_meta(&"photo", t)
				a.queue_redraw())
		if tex != null:
			actor.set_meta(&"photo", tex)

	func draw(actor: ShortActor) -> void:
		var s := actor.size
		actor.draw_rect(Rect2(Vector2(4, 6), s), MyShortDrawers.SHADOW)
		actor.draw_rect(Rect2(Vector2.ZERO, s), MyShortDrawers.PAPER)
		var dest := Rect2(Vector2.ONE * MyShortDrawers.FRAME, s - Vector2.ONE * MyShortDrawers.FRAME * 2.0)
		var tex: Variant = actor.get_meta(&"photo") if actor.has_meta(&"photo") else null
		if tex is Texture2D:
			MyShortDrawers.draw_cover(actor, tex, dest)
		else:
			actor.draw_rect(dest, MyShortDrawers.EMPTY)
			MyShortDrawers.draw_camera(actor, dest, Color(1, 1, 1, 0.8))


## The child's avatar doing an emote, again and again with a little rest between.
class MeDrawer:
	extends ShortDrawer

	func setup(actor: ShortActor) -> void:
		var side := StudioRules.num(actor.data, "size", 120.0)
		actor.size = Vector2(side, side)
		actor.animated = str(actor.data.get("emote", "")) != ""
		actor.set_meta(&"look", MyShortDrawers.look().resolve())

	func draw(actor: ShortActor) -> void:
		var emote := StringName(str(actor.data.get("emote", "")))
		var pose := EmotePoses.rest()
		if EmotePoses.has(emote):
			var d := EmotePoses.duration(emote)
			var period := d + MyShortDrawers.EMOTE_REST
			var t := fposmod(actor.time, period) if is_finite(d) else actor.time
			if t < d or not is_finite(d):
				pose = EmotePoses.sample(emote, t)
		AvatarIcon.figure(actor, Rect2(Vector2.ZERO, actor.size), actor.get_meta(&"look"), pose)

	func update(actor: ShortActor, _state: Dictionary, _t: float) -> void:
		actor.queue_redraw()


## A wonder's stamp from the Wonders Passport.
class WonderDrawer:
	extends ShortDrawer

	func setup(actor: ShortActor) -> void:
		var side := StudioRules.num(actor.data, "size", 160.0)
		var stamp := WonderStamp.new(StringName(str(actor.data.get("id", ""))), true, side)
		stamp.size = Vector2(side, side)
		actor.add_child(stamp)
		actor.size = Vector2(side, side)


## A build seen from above its front right corner, layer by layer (`value`: the layers shown).
class BuildDrawer:
	extends ShortDrawer

	func setup(actor: ShortActor) -> void:
		var side := StudioRules.num(actor.data, "size", 260.0)
		actor.size = Vector2(side, side)
		actor.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		if actor.data.has("blueprint"):
			var id := str(actor.data.blueprint)
			actor.set_meta(&"build", IsoBuild.cached("bp:" + id, func() -> Dictionary:
				return Blueprints.local(int(MyShortRules.BLUEPRINTS.get(id, 0)))))
		else:
			var file := str(actor.data.get("file", ""))
			actor.set_meta(&"build", IsoBuild.cached("file:" + file, func() -> Dictionary: return MyShortAlbum.read_build(file)))

	func draw(actor: ShortActor) -> void:
		var pic: IsoBuild = actor.get_meta(&"build")
		pic.paint(actor, Rect2(Vector2.ZERO, actor.size), actor.value)

	func update(actor: ShortActor, _state: Dictionary, _t: float) -> void:
		actor.queue_redraw()


## A build's blocks ready to paint, made once (and kept: `cached`): for each layer (0 the lowest), the faces that show
## as meshes of the game's block pictures (the top lit, the sides shaded), farthest first; the tops a block above will
## cover are a mesh of their own, drawn while that layer is not all shown yet. A whole build is a few draw calls a frame
## (a tower of 240 blocks: two a layer), whatever its size.
class IsoBuild:
	extends RefCounted
	const A := 0.866   # cos 30°
	const TOP := Color(1, 1, 1)
	const LEFT := Color(0.84, 0.84, 0.9)
	const RIGHT := Color(0.66, 0.66, 0.74)
	const PLAIN := Color(0.62, 0.6, 0.56)
	const KEEP := 16

	static var _cache := {}
	static var _order: Array[String] = []

	var layers := 0
	var blocks_count := 0
	var _lo := Vector2.ZERO
	var _hi := Vector2.ZERO
	var _base: Array = []      # per layer: [[texture or null, ArrayMesh], ...] in the order to draw
	var _covered: Array = []   # per layer: the same, for the tops the next layer covers

	## The build kept under `key` (made from make_blocks() the first time).
	static func cached(key: String, make_blocks: Callable) -> IsoBuild:
		if not _cache.has(key):
			_cache[key] = IsoBuild.new(make_blocks.call())
			_order.append(key)
			while _order.size() > KEEP:
				_cache.erase(_order.pop_front())
		return _cache[key]

	func _init(blocks: Dictionary) -> void:
		var ys := {}
		for p: Vector3i in blocks:
			if int(blocks[p]) != BlockIds.AIR:
				ys[p.y] = true
		var heights: Array = ys.keys()
		heights.sort()
		layers = heights.size()
		var layer_of := {}
		for i in heights.size():
			layer_of[heights[i]] = i
		var cells := {}            # cell (x, y, w) -> id
		for p: Vector3i in blocks:
			if int(blocks[p]) != BlockIds.AIR:
				cells[Vector3i(p.x, p.y, -p.z - 1)] = int(blocks[p])   # the front (z towards the child) faces the camera
		blocks_count = cells.size()
		var per_layer: Array = []
		for i in layers:
			per_layer.append([])
		var first := true
		for cell: Vector3i in cells:
			per_layer[int(layer_of[cell.y])].append(cell)
			for corner: Vector3i in [Vector3i(0, 0, 0), Vector3i(1, 1, 1), Vector3i(1, 0, 0), Vector3i(0, 1, 1),
					Vector3i(0, 0, 1), Vector3i(1, 1, 0)]:
				var q := _project(Vector3(cell + corner))
				_lo = q if first else Vector2(minf(_lo.x, q.x), minf(_lo.y, q.y))
				_hi = q if first else Vector2(maxf(_hi.x, q.x), maxf(_hi.y, q.y))
				first = false
		for L in layers:
			var list: Array = per_layer[L]
			list.sort_custom(func(a: Vector3i, b: Vector3i) -> bool: return a.x + a.z < b.x + b.z or (a.x + a.z == b.x + b.z and a.x < b.x))
			var base := _Runs.new()
			var covered := _Runs.new()
			for cell: Vector3i in list:
				var id: int = cells[cell]
				var tiles: Array = BlockLibrary.tiles_of(id)
				var atlas: Texture2D = BlockLibrary.pixel_atlas_of(id) if not tiles.is_empty() else null
				var p := Vector3(cell)
				var top := [p + Vector3(0, 1, 0), p + Vector3(1, 1, 0), p + Vector3(1, 1, 1), p + Vector3(0, 1, 1)]
				if cells.has(cell + Vector3i(0, 1, 0)):
					covered.quad(atlas, tiles, 0, top, TOP)
				else:
					base.quad(atlas, tiles, 0, top, TOP)
				if not cells.has(cell + Vector3i(0, 0, 1)):
					base.quad(atlas, tiles, 1, [p + Vector3(0, 1, 1), p + Vector3(1, 1, 1), p + Vector3(1, 0, 1), p + Vector3(0, 0, 1)], LEFT)
				if not cells.has(cell + Vector3i(1, 0, 0)):
					base.quad(atlas, tiles, 1, [p + Vector3(1, 1, 1), p + Vector3(1, 1, 0), p + Vector3(1, 0, 0), p + Vector3(1, 0, 1)], RIGHT)
			_base.append(base.meshes())
			_covered.append(covered.meshes())

	static func _project(p: Vector3) -> Vector2:
		return Vector2((p.x - p.z) * A, (p.x + p.z) * 0.5 - p.y)

	## Draws it inside `rect` (kept in its shape), its first `shown` layers (the next one falling in by its fraction).
	func paint(ci: CanvasItem, rect: Rect2, shown: float) -> void:
		if layers == 0:
			return
		var span := _hi - _lo
		var k := minf(rect.size.x / maxf(span.x, 0.01), rect.size.y / maxf(span.y, 0.01)) * 0.94
		var origin := rect.get_center() - (_lo + span * 0.5) * k
		var full := floori(shown)
		var part := shown - full
		for L in mini(layers, full + 1):
			var alpha := 1.0
			var drop := 0.0
			if L == full:
				if part <= 0.0:
					break
				alpha = clampf(part * 1.6, 0.0, 1.0)
				drop = (1.0 - ShortTimeline.ease_value("out", part)) * 1.6 * k
			var xf := Transform2D(0.0, Vector2(k, k), 0.0, origin - Vector2(0, drop))
			var mod := Color(1, 1, 1, alpha)
			for run: Array in _base[L]:
				ci.draw_mesh(run[1], run[0], xf, mod)
			if L + 1 >= full:   # the layer above is not all shown yet: these tops still show
				for run: Array in _covered[L]:
					ci.draw_mesh(run[1], run[0], xf, mod)


## Quads gathered into meshes, one a run of the same picture sheet (so the order they are drawn in is kept).
class _Runs:
	extends RefCounted
	var _runs: Array = []   # [texture or null, verts, uvs, colours, indices]

	func quad(atlas: Texture2D, tiles: Array, which: int, corners: Array, shade: Color) -> void:
		if _runs.is_empty() or _runs.back()[0] != atlas:
			_runs.append([atlas, PackedVector2Array(), PackedVector2Array(), PackedColorArray(), PackedInt32Array()])
		var run: Array = _runs.back()
		var verts: PackedVector2Array = run[1]
		var start := verts.size()
		for v: Vector3 in corners:
			verts.append(IsoBuild._project(v))
		run[1] = verts
		var uvs: PackedVector2Array = run[2]
		var colours: PackedColorArray = run[3]
		if atlas != null:
			var tile: Vector2i = tiles[mini(which, tiles.size() - 1)]
			var size := Vector2(atlas.get_width(), atlas.get_height())
			var r := Rect2(Vector2(tile) * 16.0 / size, Vector2(16, 16) / size)
			uvs.append_array([r.position, r.position + Vector2(r.size.x, 0), r.end, r.position + Vector2(0, r.size.y)])
			for i in 4:
				colours.append(shade)
		else:
			for i in 4:
				uvs.append(Vector2.ZERO)
				colours.append(IsoBuild.PLAIN * shade)
		run[2] = uvs
		run[3] = colours
		var idx: PackedInt32Array = run[4]
		idx.append_array([start, start + 1, start + 2, start, start + 2, start + 3])
		run[4] = idx

	func meshes() -> Array:
		var out: Array = []
		for run: Array in _runs:
			var arrays := []
			arrays.resize(Mesh.ARRAY_MAX)
			arrays[Mesh.ARRAY_VERTEX] = run[1]
			arrays[Mesh.ARRAY_TEX_UV] = run[2]
			arrays[Mesh.ARRAY_COLOR] = run[3]
			arrays[Mesh.ARRAY_INDEX] = run[4]
			var mesh := ArrayMesh.new()
			mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
			out.append([run[0], mesh])
		return out
