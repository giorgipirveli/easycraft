class_name LifeRoomDecor
extends RefCounted
## The rooms' look brief (2026-10-17, owner #122 "learning happens as play in places a child wants to be";
## docs/devlog/parts/rooms-look.md): the practice rooms' shared look. A room's floors, walls, windows, plants, shelves,
## fences, trees and sky are pieces added to one of these, then `commit` draws them as a handful of meshes: every lit
## piece in its own colour in ONE mesh (the Theater building's vertex-colour material), every floor or wall in the game's
## own block pictures in ONE mesh (the blocks' own material: blocky or realistic, as the world's style), every glowing
## piece (a window's view, a lamp's shade) in ONE mesh, the sky dome in one of its own (a night tints it) and window glass
## in one per tint (the mirror wall's see-through settings). Draws matter more than triangles on the Quest (≤ 100 draws a
## frame): a room's whole dressing costs about four draws, however many pieces it has. Every piece is remembered as its box
## in the room's space (`pieces`): the rooms' keep-clear rules (never on a target, a view's line or a VR reach) read them.
## `bake` merges a room's static scenery (its LifeRoomKit boxes, cylinders and spheres, under LifeRoom.scenery()) into one
## lit mesh the same way, keeping as nodes everything the room moves, hides, glows or names.
## Only shaders the game already warms up (ShaderWarmup's census): no assets loaded, no shadows, no new material kind.

const DECOR := "decor"     ## dressing: furniture, plants, trees (keeps clear of targets and lines)
const SHELL := "shell"     ## floors, walls, ceilings, kerbs (keeps clear of lines)
const SKY := "sky"         ## the dome round the room
const BAKED := "baked"     ## a room's own static scenery, merged

## Block pictures on the atlas's page 0 (BlockLibrary.TILES): [column, row] of its 8 x 8 tiles.
const PLANKS := Vector2i(7, 0)
const BRICK := Vector2i(2, 1)
const STONE := Vector2i(3, 0)
const COBBLE := Vector2i(6, 6)
const SLABS := Vector2i(7, 6)
const ASPHALT := Vector2i(2, 2)
const SAND := Vector2i(4, 0)
const GRASS := Vector2i(0, 0)
const DIRT := Vector2i(2, 0)
const TILE := Vector2i(1, 1)       ## the glass block: a white square with a pale blue edge (a wall or floor tile)
const WATER := Vector2i(4, 1)
const BARK := Vector2i(5, 0)
const LEAVES := Vector2i(0, 1)
const HEDGE := Vector2i(0, 6)      ## the berry bush's side
const RED := Vector2i(5, 1)
const YELLOW := Vector2i(6, 1)
const GREEN := Vector2i(7, 1)
const BLUE := Vector2i(0, 2)
const PURPLE := Vector2i(1, 2)
const ATLAS := 8.0
const INSET := 0.002               ## UVs kept a hair inside a tile (no neighbour bleeds in)

## The room's camera sees 80 m: the sky's dome is well inside it.
const SKY_RADIUS := 52.0

enum { LIT, TILES, GLOW }

var pieces: Array[Dictionary] = []
var _parts: Array[Part] = [Part.new(), Part.new(), Part.new()]
var _sky: Part = null
var _glass := {}   # tint (html) -> Part

static var _lit_mat: StandardMaterial3D
static var _glow_mat: StandardMaterial3D


## One mesh's arrays as they grow.
class Part:
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var colours := PackedColorArray()
	var uvs := PackedVector2Array()
	var tangents := PackedFloat32Array()
	var index := PackedInt32Array()

	func empty() -> bool:
		return verts.is_empty()

	## A quad seen from the front (its corners bottom-left, top-left, top-right, bottom-right as the viewer sees them),
	## wound as Godot's front faces (clockwise from the front) whatever order the caller thinks in: `front` is its normal.
	func quad(bl: Vector3, tl: Vector3, tr: Vector3, br: Vector3, front: Vector3, c: Color,
			uv := PackedVector2Array(), tangent := Vector4.ZERO) -> void:
		var base := verts.size()
		verts.append_array([bl, tl, tr, br])
		for i in 4:
			normals.append(front)
			colours.append(c)
		if not uv.is_empty():
			uvs.append_array(uv)
			for i in 4:
				tangents.append_array([tangent.x, tangent.y, tangent.z, tangent.w])
		var n := (tl - bl).cross(tr - bl)
		if n.dot(front) <= 0.0:
			index.append_array([base, base + 1, base + 2, base, base + 2, base + 3])
		else:
			index.append_array([base, base + 2, base + 1, base, base + 3, base + 2])

	func tri(a: Vector3, b: Vector3, c: Vector3, front: Vector3, ca: Color, cb: Color, cc: Color) -> void:
		var base := verts.size()
		verts.append_array([a, b, c])
		normals.append_array([front, front, front])
		colours.append_array([ca, cb, cc])
		if (b - a).cross(c - a).dot(front) <= 0.0:
			index.append_array([base, base + 1, base + 2])
		else:
			index.append_array([base, base + 2, base + 1])

	func mesh() -> ArrayMesh:
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = verts
		arrays[Mesh.ARRAY_NORMAL] = normals
		arrays[Mesh.ARRAY_COLOR] = colours
		if not uvs.is_empty():
			arrays[Mesh.ARRAY_TEX_UV] = uvs
			arrays[Mesh.ARRAY_TANGENT] = tangents
		arrays[Mesh.ARRAY_INDEX] = index
		var m := ArrayMesh.new()
		m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		return m


# --- Materials (each one the game already warms up) ---------------------------------------------------------------

## The lit pieces: the Theater building's vertex-colour material (ShaderWarmup's census: vertex_color_use_as_albedo,
## vertex_color_is_srgb), matte.
static func lit_material() -> StandardMaterial3D:
	if _lit_mat == null:
		_lit_mat = StandardMaterial3D.new()
		_lit_mat.vertex_color_use_as_albedo = true
		_lit_mat.vertex_color_is_srgb = true
		_lit_mat.roughness = 0.82
	return _lit_mat


## The glowing pieces: the launch site's blinker's settings (unshaded, vertex colours).
static func glow_material() -> StandardMaterial3D:
	if _glow_mat == null:
		_glow_mat = _unshaded()
	return _glow_mat


## The sky's dome: the glowing pieces' settings, an instance of its own (a night tints its albedo).
static func sky_material() -> StandardMaterial3D:
	return _unshaded()


static func _unshaded() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.vertex_color_use_as_albedo = true
	m.vertex_color_is_srgb = true
	return m


## The block pictures: the blocks' own opaque material on page 0 (the world's style: pixel or realistic).
static func tiles_material() -> BaseMaterial3D:
	return BlockLibrary.page_material(0, &"opaque")


# --- Pieces ---------------------------------------------------------------------------------------------------------

## A lit box in its colour (`yaw` turns it about its centre).
func box(piece: String, size: Vector3, at: Vector3, colour: Color, yaw: float = 0.0, kind: String = DECOR) -> void:
	var xf := Transform3D(Basis(Vector3.UP, yaw), at)
	_box(_parts[LIT], xf, size, colour, Vector2i(-1, -1), 1.0)
	_remember(piece, kind, xf, AABB(-size * 0.5, size))


## A box turned any way (a slanted roof, a leaning board).
func box_basis(piece: String, size: Vector3, xf: Transform3D, colour: Color, kind: String = DECOR) -> void:
	_box(_parts[LIT], xf, size, colour, Vector2i(-1, -1), 1.0)
	_remember(piece, kind, xf, AABB(-size * 0.5, size))


## A glowing box (unlit: a window's bright view, a lamp's shade, a screen).
func glow_box(piece: String, size: Vector3, at: Vector3, colour: Color, yaw: float = 0.0, kind: String = DECOR) -> void:
	var xf := Transform3D(Basis(Vector3.UP, yaw), at)
	_box(_parts[GLOW], xf, size, colour, Vector2i(-1, -1), 1.0)
	_remember(piece, kind, xf, AABB(-size * 0.5, size))


## A box faced with a block picture `tile`, repeated every `per` metres on every face (tinted by `tint`).
func tiled(piece: String, tile: Vector2i, size: Vector3, at: Vector3, tint: Color = Color.WHITE, per: float = 1.0,
		yaw: float = 0.0, kind: String = SHELL) -> void:
	var xf := Transform3D(Basis(Vector3.UP, yaw), at)
	_box(_parts[TILES], xf, size, tint.srgb_to_linear(), tile, per)
	_remember(piece, kind, xf, AABB(-size * 0.5, size))


## A box faced with a block picture, turned any way (`xf`: a gate's frame, a leaning beam).
func tiled_basis(piece: String, tile: Vector2i, size: Vector3, xf: Transform3D, tint: Color = Color.WHITE, per: float = 1.0,
		kind: String = SHELL) -> void:
	_box(_parts[TILES], xf, size, tint.srgb_to_linear(), tile, per)
	_remember(piece, kind, xf, AABB(-size * 0.5, size))


## A glowing box turned any way (a picture's turned stroke on a sign).
func glow_box_basis(piece: String, size: Vector3, xf: Transform3D, colour: Color, kind: String = DECOR) -> void:
	_box(_parts[GLOW], xf, size, colour, Vector2i(-1, -1), 1.0)
	_remember(piece, kind, xf, AABB(-size * 0.5, size))


## One lit mesh of plain boxes, each [centre, size, colour] or [centre, size, colour, basis] (a model: Hoot), drawn with
## the lit material (`lit_material`), every face turned outwards.
static func boxes_mesh(boxes: Array) -> ArrayMesh:
	var p := Part.new()
	for b: Array in boxes:
		var basis: Basis = b[3] if b.size() > 3 else Basis.IDENTITY
		_box(p, Transform3D(basis, b[0]), b[1], b[2], Vector2i(-1, -1), 1.0)
	return p.mesh()


## A see-through pane (window glass): the mirror wall's settings (LifeRoomKit.material with alpha), one mesh a tint.
func glass(piece: String, size: Vector3, at: Vector3, tint: Color = Color(0.82, 0.92, 1.0, 0.22), yaw: float = 0.0) -> void:
	var key := tint.to_html(true)
	if not _glass.has(key):
		_glass[key] = Part.new()
	var xf := Transform3D(Basis(Vector3.UP, yaw), at)
	_box(_glass[key], xf, size, Color.WHITE, Vector2i(-1, -1), 1.0)
	_remember(piece, DECOR, xf, AABB(-size * 0.5, size))


## A lit cylinder (or a cone: `top` the top's radius, 0 for a point), standing on `at` minus half its height.
func cylinder(piece: String, radius: float, height: float, at: Vector3, colour: Color, top: float = -1.0,
		sides: int = 10, kind: String = DECOR, glow: bool = false) -> void:
	var r_top := radius if top < 0.0 else top
	var p := _parts[GLOW if glow else LIT]
	var y0 := at.y - height * 0.5
	var y1 := at.y + height * 0.5
	var slope := (radius - r_top) / maxf(height, 0.001)
	for i in sides:
		var a0 := TAU * i / sides
		var a1 := TAU * (i + 1) / sides
		var d0 := Vector3(cos(a0), 0, sin(a0))
		var d1 := Vector3(cos(a1), 0, sin(a1))
		var mid := (d0 + d1).normalized()
		var n := (mid + Vector3(0, slope, 0)).normalized()
		var b0 := at + Vector3(0, y0 - at.y, 0) + d0 * radius
		var b1 := at + Vector3(0, y0 - at.y, 0) + d1 * radius
		var t0 := at + Vector3(0, y1 - at.y, 0) + d0 * r_top
		var t1 := at + Vector3(0, y1 - at.y, 0) + d1 * r_top
		if r_top <= 0.001:   # a point at the top (a cone): one triangle a side, no flat sliver
			p.tri(b0, t0, b1, n, colour, colour, colour)
		elif radius <= 0.001:   # a point at the foot
			p.tri(b0, t0, t1, n, colour, colour, colour)
		else:
			p.quad(b0, t0, t1, b1, n, colour)
		if r_top > 0.001:
			p.tri(Vector3(at.x, y1, at.z), Vector3(at.x, y1, at.z) + d0 * r_top, Vector3(at.x, y1, at.z) + d1 * r_top,
				Vector3.UP, colour, colour, colour)
		if radius > 0.001:
			p.tri(Vector3(at.x, y0, at.z), Vector3(at.x, y0, at.z) + d1 * radius, Vector3(at.x, y0, at.z) + d0 * radius,
				Vector3.DOWN, colour, colour, colour)
	var r := maxf(radius, r_top)
	_remember(piece, kind, Transform3D(Basis(), at), AABB(Vector3(-r, -height * 0.5, -r), Vector3(r * 2, height, r * 2)))


## A lit ball, squashed or stretched by `scale` (a bush, a tree's crown, a cloud).
func ball(piece: String, radius: float, at: Vector3, colour: Color, scale: Vector3 = Vector3.ONE, kind: String = DECOR,
		glow: bool = false, rings: int = 5, sides: int = 9) -> void:
	var p := _parts[GLOW if glow else LIT]
	var s := scale * radius
	for ring in rings:
		var t0 := PI * ring / rings - PI * 0.5
		var t1 := PI * (ring + 1) / rings - PI * 0.5
		for i in sides:
			var a0 := TAU * i / sides
			var a1 := TAU * (i + 1) / sides
			var q := [_sphere_pt(t0, a0), _sphere_pt(t1, a0), _sphere_pt(t1, a1), _sphere_pt(t0, a1)]
			var n := ((q[0] + q[1] + q[2] + q[3]) as Vector3).normalized()
			var shade := colour.darkened(0.08 * (1.0 - (n.y * 0.5 + 0.5)))
			if ring == 0:
				p.tri(at + q[0] * s, at + q[1] * s, at + q[2] * s, n, shade, shade, shade)
			elif ring == rings - 1:
				p.tri(at + q[0] * s, at + q[1] * s, at + q[3] * s, n, shade, shade, shade)
			else:
				p.quad(at + q[0] * s, at + q[1] * s, at + q[2] * s, at + q[3] * s, n, shade)
	_remember(piece, kind, Transform3D(Basis(), at), AABB(-s, s * 2.0))


static func _sphere_pt(t: float, a: float) -> Vector3:
	return Vector3(cos(t) * cos(a), sin(t), cos(t) * sin(a))


# --- The sky -----------------------------------------------------------------------------------------------------------

## A soft sky round the room: a dome from `horizon` (light, at eye level) up to `top`, a ring of hazy far hills in
## `land`'s colour over the horizon (none when `land`'s alpha is 0), a few soft clouds, and the ground under the horizon
## in `land`. Drawn unlit with its own material (`sky_tint`: a night darkens it).
func sky(top: Color, horizon: Color, land: Color = Color("8cc56a"), clouds: int = 5, hills: float = 1.0) -> void:
	_sky = Part.new()
	var r := SKY_RADIUS
	var sides := 28
	var bands := [[0.0, horizon], [0.12, horizon.lerp(top, 0.35)], [0.35, horizon.lerp(top, 0.7)], [0.7, top],
		[1.0, top.darkened(0.06)]]
	for i in sides:
		var a0 := TAU * i / sides
		var a1 := TAU * (i + 1) / sides
		for b in bands.size() - 1:
			var e0: float = bands[b][0] * PI * 0.5
			var e1: float = bands[b + 1][0] * PI * 0.5
			var p00 := Vector3(cos(e0) * cos(a0), sin(e0), cos(e0) * sin(a0)) * r
			var p01 := Vector3(cos(e1) * cos(a0), sin(e1), cos(e1) * sin(a0)) * r
			var p10 := Vector3(cos(e0) * cos(a1), sin(e0), cos(e0) * sin(a1)) * r
			var p11 := Vector3(cos(e1) * cos(a1), sin(e1), cos(e1) * sin(a1)) * r
			var c0: Color = bands[b][1]
			var c1: Color = bands[b + 1][1]
			var inward := -((p00 + p11) * 0.5).normalized()
			_sky.tri(p00, p01, p11, inward, c0, c1, c1)
			_sky.tri(p00, p11, p10, inward, c0, c1, c0)
		# the ground under the horizon (seen past the room's own floor)
		var g0 := Vector3(cos(a0), 0, sin(a0)) * r
		var g1 := Vector3(cos(a1), 0, sin(a1)) * r
		var low := Vector3(0, -r * 0.4, 0)
		var far_land := land.lerp(horizon, 0.45)
		_sky.tri(g0, g1, g1 * 0.6 + low, Vector3(-g0.x, 0, -g0.z).normalized(), far_land, far_land, land)
		_sky.tri(g0, g1 * 0.6 + low, g0 * 0.6 + low, Vector3(-g0.x, 0, -g0.z).normalized(), far_land, land, land)
	if land.a > 0.0 and hills > 0.0:
		_hills(r * 0.94, land.lerp(horizon, 0.55), land.lerp(horizon, 0.3), hills)
	var rng := RandomNumberGenerator.new()
	rng.seed = 122
	for i in clouds:
		var a := TAU * (i + rng.randf() * 0.6) / maxf(clouds, 1)
		var e := deg_to_rad(rng.randf_range(14.0, 30.0))
		var at := Vector3(cos(e) * cos(a), sin(e), cos(e) * sin(a)) * (r * 0.9)
		_cloud(at, rng.randf_range(4.0, 7.0), horizon.lerp(Color.WHITE, 0.8), rng)
	_remember("Sky", SKY, Transform3D(), AABB(Vector3(-r, -r * 0.4, -r), Vector3(r * 2, r * 1.4, r * 2)))


func has_sky() -> bool:
	return _sky != null


func _hills(r: float, far: Color, near: Color, height: float) -> void:
	var sides := 48
	for layer in 2:
		var rr := r * (1.0 - layer * 0.08)
		var c := far if layer == 0 else near
		for i in sides:
			var a0 := TAU * i / sides
			var a1 := TAU * (i + 1) / sides
			var h0 := _hill_height(a0, layer) * height
			var h1 := _hill_height(a1, layer) * height
			var b0 := Vector3(cos(a0), -0.5, sin(a0)) * Vector3(rr, 1, rr)
			var b1 := Vector3(cos(a1), -0.5, sin(a1)) * Vector3(rr, 1, rr)
			var inward := -Vector3(cos(a0), 0, sin(a0))
			_sky.quad(b0, b0 + Vector3(0, h0 + 0.5, 0), b1 + Vector3(0, h1 + 0.5, 0), b1, inward, c)


static func _hill_height(a: float, layer: int) -> float:
	var k := 1.7 + layer * 1.3
	return maxf(0.0, 2.2 + 1.6 * sin(a * 3.0 + k) + 1.1 * sin(a * 7.0 + k * 2.0) + 0.6 * sin(a * 13.0 + k)) * (0.8 - layer * 0.25)


func _cloud(at: Vector3, size: float, colour: Color, rng: RandomNumberGenerator) -> void:
	var inward := -at.normalized()
	var side := Vector3.UP.cross(inward).normalized()
	for k in 3:
		var c := at + side * (k - 1) * size * 0.55 + Vector3(0, rng.randf_range(-0.3, 0.6) + (0.6 if k == 1 else 0.0), 0)
		var w := size * (0.55 if k != 1 else 0.75)
		var h := w * 0.42
		var segs := 10
		for i in segs:
			var a0 := TAU * i / segs
			var a1 := TAU * (i + 1) / segs
			var under := colour.darkened(0.05)
			_sky.tri(c, c + side * cos(a0) * w + Vector3(0, sin(a0) * h, 0), c + side * cos(a1) * w + Vector3(0, sin(a1) * h, 0),
				inward, colour, under if sin(a0) < 0 else colour, under if sin(a1) < 0 else colour)


# --- Composite helpers (a few pieces each) ---------------------------------------------------------------------------

## A window on a wall: a painted view (glowing: sky over a green hill and a tree), its frame, its bars and its sill.
## `at` is the middle of the window's face, `yaw` turns its face (0: facing +Z, into a room whose wall is at -Z).
func window(piece: String, at: Vector3, width: float = 1.1, height: float = 1.0, yaw: float = 0.0,
		frame: Color = Color("f6f2ea"), view_top: Color = Color("8cc8f2"), view_low: Color = Color("dff0fb"),
		land: Color = Color("8cc56a")) -> void:
	var b := Basis(Vector3.UP, yaw)
	var out := b * Vector3(0, 0, 1)
	var right := b * Vector3(1, 0, 0)
	var p := _parts[GLOW]
	var hw := width * 0.5
	var hh := height * 0.5
	var f := at + out * 0.012
	# the view: sky light at the bottom, deeper above; a hill along the bottom third; a tree
	p.quad(f - right * hw - Vector3(0, hh, 0), f - right * hw + Vector3(0, hh, 0), f + right * hw + Vector3(0, hh, 0),
		f + right * hw - Vector3(0, hh, 0), out, view_low)
	var sky_c := view_top
	var mid_l := f - right * hw + Vector3(0, hh * 0.1, 0)
	var mid_r := f + right * hw + Vector3(0, hh * 0.1, 0)
	p.quad(mid_l + out * 0.001, f - right * hw + Vector3(0, hh, 0) + out * 0.001, f + right * hw + Vector3(0, hh, 0) + out * 0.001,
		mid_r + out * 0.001, out, sky_c)
	var hill := land.lerp(view_low, 0.25)
	var hb := f - Vector3(0, hh, 0) + out * 0.002
	p.quad(hb - right * hw, hb - right * hw + Vector3(0, height * 0.32, 0), hb + right * hw * 0.2 + Vector3(0, height * 0.22, 0),
		hb + right * hw * 0.2, out, hill)
	p.quad(hb + right * hw * 0.2, hb + right * hw * 0.2 + Vector3(0, height * 0.22, 0), hb + right * hw + Vector3(0, height * 0.12, 0),
		hb + right * hw, out, hill.darkened(0.06))
	var tree := hb + right * hw * 0.45 + Vector3(0, height * 0.18, 0) + out * 0.001
	p.quad(tree - right * 0.02, tree - right * 0.02 + Vector3(0, height * 0.18, 0), tree + right * 0.02 + Vector3(0, height * 0.18, 0),
		tree + right * 0.02, out, Color("8a5a34"))
	var crown := tree + Vector3(0, height * 0.24, 0) + out * 0.001
	for i in 8:
		var a0 := TAU * i / 8
		var a1 := TAU * (i + 1) / 8
		p.tri(crown, crown + right * cos(a0) * height * 0.1 + Vector3(0, sin(a0) * height * 0.1, 0),
			crown + right * cos(a1) * height * 0.1 + Vector3(0, sin(a1) * height * 0.1, 0), out, land.darkened(0.1),
			land.darkened(0.1), land.darkened(0.1))
	# the frame, the cross bars and the sill (lit)
	var t := 0.06
	var depth := 0.05
	for side: int in [-1, 1]:
		box_basis(piece + "_FrameSide", Vector3(t, height + t * 2, depth), Transform3D(b, at + right * side * (hw + t * 0.5) + out * 0.02), frame, DECOR)
		box_basis(piece + "_FrameEnd", Vector3(width + t * 2, t, depth), Transform3D(b, at + Vector3(0, side * (hh + t * 0.5), 0) + out * 0.02), frame, DECOR)
	box_basis(piece + "_Bar", Vector3(0.03, height, 0.02), Transform3D(b, at + out * 0.022), frame, DECOR)
	box_basis(piece + "_BarAcross", Vector3(width, 0.03, 0.02), Transform3D(b, at + Vector3(0, hh * 0.1, 0) + out * 0.022), frame, DECOR)
	box_basis(piece + "_Sill", Vector3(width + 0.24, 0.05, 0.16), Transform3D(b, at - Vector3(0, hh + t, 0) + out * 0.08), frame.darkened(0.05), DECOR)
	# remembered as the wall it is part of: a thing seen in it (a kite in the lines outside) is not covered by it
	_remember(piece, SHELL, Transform3D(b, at + out * 0.02), AABB(Vector3(-hw - t, -hh - t, -0.02), Vector3(width + t * 2, height + t * 2, 0.06)))


## A potted plant: a pot, soil and a round leafy crown (`size` 1: about 0.6 m tall).
func plant(piece: String, at: Vector3, size: float = 1.0, pot: Color = Color("d9774a"), leaves: Color = Color("5aa548")) -> void:
	cylinder(piece + "_Pot", 0.13 * size, 0.24 * size, at + Vector3(0, 0.12 * size, 0), pot, 0.16 * size)
	cylinder(piece + "_Soil", 0.14 * size, 0.02 * size, at + Vector3(0, 0.235 * size, 0), Color("6b4a32"))
	ball(piece + "_Leaves", 0.2 * size, at + Vector3(0, 0.42 * size, 0), leaves, Vector3(1.0, 0.9, 1.0))
	ball(piece + "_Leaves2", 0.13 * size, at + Vector3(0.1 * size, 0.56 * size, 0.04 * size), leaves.lightened(0.12))


## A bookshelf against a wall (`yaw` 0: its back to -Z): shelves with rows of books in friendly colours.
func shelf(piece: String, at: Vector3, width: float = 1.0, height: float = 1.4, yaw: float = 0.0, wood: Color = Color("b98450"),
		rows: int = 3) -> void:
	var b := Basis(Vector3.UP, yaw)
	var depth := 0.3
	var books := [Color("e8544e"), Color("3a7be8"), Color("ffc93c"), Color("3fbf5a"), Color("b03cc0"), Color("f39a3c"),
		Color("1fa6a0")]
	for side: int in [-1, 1]:
		box_basis(piece + "_Side", Vector3(0.04, height, depth), Transform3D(b, at + b * Vector3(side * width * 0.5, height * 0.5, 0)), wood)
	box_basis(piece + "_Back", Vector3(width, height, 0.02), Transform3D(b, at + b * Vector3(0, height * 0.5, -depth * 0.5)), wood.darkened(0.15))
	for r in rows + 1:
		var y := 0.04 + r * (height - 0.06) / rows
		box_basis(piece + "_Board", Vector3(width, 0.035, depth), Transform3D(b, at + b * Vector3(0, y, 0)), wood)
		if r == rows:
			break
		var x := -width * 0.5 + 0.05
		var k := r * 3
		while x < width * 0.5 - 0.12:
			var w := 0.04 + 0.025 * ((k * 7) % 3)
			var h := minf(0.18 + 0.04 * ((k * 5) % 3), (height - 0.06) / rows - 0.05)
			box_basis(piece + "_Book", Vector3(w, h, depth * 0.75), Transform3D(b, at + b * Vector3(x + w * 0.5, y + 0.02 + h * 0.5, 0.02)),
				books[k % books.size()])
			x += w + 0.008
			k += 1
			if k % 6 == 5:
				x += 0.1   # a gap, a book lying down
	_remember(piece, DECOR, Transform3D(b, at + b * Vector3(0, height * 0.5, 0)), AABB(Vector3(-width * 0.5, -height * 0.5, -depth * 0.5),
		Vector3(width, height, depth)))


## A rug on the floor: a border and a middle (flat: never in the way).
func rug(piece: String, at: Vector3, size: Vector2, colour: Color, border: Color = Color(), yaw: float = 0.0) -> void:
	var edge := border if border.a > 0.0 else colour.darkened(0.2)
	box(piece, Vector3(size.x, 0.012, size.y), at + Vector3(0, 0.006, 0), edge, yaw, SHELL)
	box(piece + "_Middle", Vector3(size.x - 0.16, 0.014, size.y - 0.16), at + Vector3(0, 0.007, 0), colour, yaw, SHELL)


## A floor lamp: a pole and a glowing shade.
func lamp(piece: String, at: Vector3, height: float = 1.5, shade: Color = Color("fff1c8")) -> void:
	cylinder(piece + "_Base", 0.16, 0.04, at + Vector3(0, 0.02, 0), Color("6b6f7a"))
	cylinder(piece + "_Pole", 0.02, height, at + Vector3(0, height * 0.5, 0), Color("8a8f99"))
	cylinder(piece + "_Shade", 0.2, 0.24, at + Vector3(0, height + 0.06, 0), shade, 0.12, 12, DECOR, true)


## A picture on a wall (`yaw` 0: facing +Z): a frame and a few calm shapes (a sun over hills, or flowers).
func picture(piece: String, at: Vector3, size: Vector2 = Vector2(0.6, 0.45), yaw: float = 0.0, frame: Color = Color("8a5a34"),
		paper: Color = Color("fff6e0"), kind: int = 0) -> void:
	var b := Basis(Vector3.UP, yaw)
	var out := b * Vector3(0, 0, 1)
	box_basis(piece, Vector3(size.x, size.y, 0.03), Transform3D(b, at), frame)
	box_basis(piece + "_Paper", Vector3(size.x - 0.08, size.y - 0.08, 0.01), Transform3D(b, at + out * 0.016), paper)
	var c := at + out * 0.022
	var right := b * Vector3(1, 0, 0)
	match kind % 3:
		0:   # hills and a sun
			box_basis(piece + "_Hill", Vector3(size.x - 0.1, size.y * 0.25, 0.01), Transform3D(b, c - Vector3(0, size.y * 0.22, 0)), Color("8cc56a"))
			box_basis(piece + "_Sun", Vector3(size.y * 0.2, size.y * 0.2, 0.01), Transform3D(b, c + right * size.x * 0.2 + Vector3(0, size.y * 0.15, 0)),
				Color("ffc93c"))
		1:   # three flowers
			for i in 3:
				var x := (i - 1) * size.x * 0.25
				box_basis(piece + "_Stem", Vector3(0.015, size.y * 0.4, 0.01), Transform3D(b, c + right * x - Vector3(0, size.y * 0.1, 0)), Color("3fbf5a"))
				box_basis(piece + "_Bloom", Vector3(size.y * 0.16, size.y * 0.16, 0.012), Transform3D(b, c + right * x + Vector3(0, size.y * 0.12, 0)),
					[Color("e85a9a"), Color("ffc93c"), Color("3a7be8")][i])
		2:   # a boat on the sea
			box_basis(piece + "_Sea", Vector3(size.x - 0.1, size.y * 0.3, 0.01), Transform3D(b, c - Vector3(0, size.y * 0.2, 0)), Color("6fb2ec"))
			box_basis(piece + "_Boat", Vector3(size.x * 0.3, size.y * 0.1, 0.012), Transform3D(b, c - Vector3(0, size.y * 0.02, 0)), Color("e8544e"))
			box_basis(piece + "_Sail", Vector3(size.x * 0.12, size.y * 0.25, 0.012), Transform3D(b, c + Vector3(0, size.y * 0.15, 0)), Color.WHITE)


## A wooden fence from `a` to `b` on the ground: posts and two rails.
func fence(piece: String, a: Vector3, b: Vector3, colour: Color = Color("c89a62"), height: float = 0.8) -> void:
	var d := b - a
	var length := Vector2(d.x, d.z).length()
	var yaw := atan2(-d.z, d.x)
	var posts := maxi(2, ceili(length / 1.4) + 1)
	for i in posts:
		var at := a.lerp(b, float(i) / (posts - 1))
		box(piece + "_Post", Vector3(0.08, height, 0.08), at + Vector3(0, height * 0.5, 0), colour.darkened(0.1), yaw)
	var mid := (a + b) * 0.5
	for y: float in [height * 0.4, height * 0.8]:
		box(piece + "_Rail", Vector3(length, 0.07, 0.04), mid + Vector3(0, y, 0), colour, yaw)


## A tree: a trunk and a round crown (`size` 1: about 3.5 m tall).
func tree(piece: String, at: Vector3, size: float = 1.0, leaves: Color = Color("4f9a3e"), trunk: Color = Color("8a5a34")) -> void:
	cylinder(piece + "_Trunk", 0.14 * size, 1.6 * size, at + Vector3(0, 0.8 * size, 0), trunk, 0.1 * size, 7)
	ball(piece + "_Crown", 1.0 * size, at + Vector3(0, 2.3 * size, 0), leaves, Vector3(1.0, 0.85, 1.0))
	ball(piece + "_Crown2", 0.7 * size, at + Vector3(0.45 * size, 2.85 * size, 0.2 * size), leaves.lightened(0.1))


## A round bush (`size` 1: about 0.7 m tall), with a few flowers when `flowers` has alpha.
func bush(piece: String, at: Vector3, size: float = 1.0, leaves: Color = Color("5aa548"), flowers: Color = Color(0, 0, 0, 0)) -> void:
	ball(piece, 0.5 * size, at + Vector3(0, 0.32 * size, 0), leaves, Vector3(1.2, 0.75, 1.0))
	if flowers.a > 0.0:
		for i in 5:
			var a := TAU * i / 5.0 + 0.4
			ball(piece + "_Flower", 0.06 * size, at + Vector3(cos(a) * 0.42 * size, 0.42 * size + 0.08 * sin(a * 3.0) * size,
				sin(a) * 0.32 * size), flowers, Vector3.ONE, DECOR, false, 3, 5)


## A bench: a seat, a back and legs (`yaw` 0: the seat faces +Z).
func bench(piece: String, at: Vector3, yaw: float = 0.0, width: float = 1.4, wood: Color = Color("b07a46")) -> void:
	var b := Basis(Vector3.UP, yaw)
	box_basis(piece + "_Seat", Vector3(width, 0.06, 0.4), Transform3D(b, at + b * Vector3(0, 0.45, 0)), wood)
	box_basis(piece + "_Back", Vector3(width, 0.35, 0.05), Transform3D(b, at + b * Vector3(0, 0.72, -0.18)), wood)
	for side: int in [-1, 1]:
		box_basis(piece + "_Leg", Vector3(0.06, 0.45, 0.36), Transform3D(b, at + b * Vector3(side * (width * 0.5 - 0.08), 0.225, 0)),
			Color("6b6f7a"))


## A ceiling light: a round glowing disc.
func ceiling_light(piece: String, at: Vector3, radius: float = 0.25) -> void:
	cylinder(piece, radius, 0.05, at, Color("fff4d6"), radius * 0.85, 14, DECOR, true)


## A little house (`yaw` 0: its front faces +Z, `at` on the ground at its middle): walls, a pitched roof with its
## eaves, a door and two windows with their painted views (they glow softly, as lit rooms do).
func house(piece: String, at: Vector3, size: Vector3 = Vector3(4.0, 2.8, 3.0), yaw: float = 0.0, wall: Color = Color("f3e1c0"),
		roof: Color = Color("c8553d"), door: Color = Color("8a5a34"), windows: int = 2) -> void:
	var b := Basis(Vector3.UP, yaw)
	box_basis(piece, size, Transform3D(b, at + Vector3(0, size.y * 0.5, 0)), wall, SHELL)
	var pitch := 0.6
	var half := size.z * 0.5 + 0.25
	var slope := half / cos(pitch)
	for side: int in [-1, 1]:
		var rb := b * Basis(Vector3.RIGHT, side * pitch)
		var mid := at + b * Vector3(0, size.y + sin(pitch) * slope * 0.5, side * half * 0.5)
		box_basis(piece + "_Roof", Vector3(size.x + 0.3, 0.12, slope), Transform3D(rb, mid), roof, SHELL)
	# the gables: a triangle each end (two boxes stepped, small enough to read as one)
	for end: int in [-1, 1]:
		for k in 3:
			var h := (k + 0.5) * sin(pitch) * slope / 3.0
			var w := size.z * (1.0 - (k + 0.5) / 3.0)
			box_basis(piece + "_Gable", Vector3(0.04, sin(pitch) * slope / 3.0, w),
				Transform3D(b, at + b * Vector3(end * size.x * 0.5, size.y + h, 0)), wall.darkened(0.04), SHELL)
	var front := b * Vector3(0, 0, size.z * 0.5)
	box_basis(piece + "_Door", Vector3(0.9, 1.9, 0.06), Transform3D(b, at + front + Vector3(0, 0.95, 0) + b * Vector3(0, 0, 0.02)), door)
	box_basis(piece + "_Step", Vector3(1.2, 0.12, 0.4), Transform3D(b, at + front + b * Vector3(0, 0.06, 0.2)), Color("b9b2a6"), SHELL)
	for i in windows:
		var x := (i - (windows - 1) * 0.5) * (size.x * 0.55) + (size.x * 0.18 if windows == 1 else 0.0)
		if absf(x) < 0.7:
			x = 0.9 * signf(x) if x != 0.0 else 1.1
		window(piece + "_Window", at + front + b * Vector3(x, size.y * 0.55, 0.0), 0.8, 0.75, yaw, Color("fdfdf8"),
			Color("ffe9b8"), Color("fff6dc"), Color("f3c98a"))


## Strings of little flags across from `a` to `b`, sagging in the middle (pennants in friendly colours).
func bunting(piece: String, a: Vector3, b: Vector3, sag: float = 0.4, flags: int = 0) -> void:
	var colours := [Color("e8544e"), Color("ffc93c"), Color("3fbf5a"), Color("3a7be8"), Color("b03cc0"), Color("f39a3c")]
	var n := flags if flags > 0 else maxi(4, int(a.distance_to(b) / 0.45))
	var along := (b - a).normalized()
	var side := along.cross(Vector3.UP).normalized()
	var p := _parts[LIT]
	var prev := a
	for i in n + 1:
		var t := float(i) / n
		var at := a.lerp(b, t) - Vector3(0, sag * 4.0 * t * (1.0 - t), 0)
		if i > 0:
			box_basis(piece + "_String", Vector3(0.012, 0.012, prev.distance_to(at)),
				Transform3D(Basis.looking_at(at - prev, Vector3.UP), (prev + at) * 0.5), Color("f6f2ea"))
		if i < n:
			var c: Color = colours[i % colours.size()]
			var tip := at + along * 0.11 - Vector3(0, 0.24, 0)
			for s: int in [-1, 1]:   # both sides (the pennants are seen from either way)
				p.tri(at, at + along * 0.22, tip, side * s, c, c, c.darkened(0.1))
		prev = at
	var lo := Vector3(minf(a.x, b.x), minf(a.y, b.y) - sag - 0.25, minf(a.z, b.z))
	var hi := Vector3(maxf(a.x, b.x), maxf(a.y, b.y), maxf(a.z, b.z))
	pieces.append({"name": piece, "kind": DECOR, "box": AABB(lo, hi - lo).grow(0.05)})


## A street lamp: a dark pole and a softly glowing lantern.
func street_lamp(piece: String, at: Vector3, height: float = 2.8, pole: Color = Color("3d4a5c")) -> void:
	cylinder(piece + "_Foot", 0.12, 0.25, at + Vector3(0, 0.125, 0), pole, 0.08)
	cylinder(piece + "_Pole", 0.045, height, at + Vector3(0, height * 0.5, 0), pole)
	cylinder(piece + "_Cap", 0.2, 0.08, at + Vector3(0, height + 0.32, 0), pole, 0.05)
	box(piece + "_Lantern", Vector3(0.24, 0.3, 0.24), at + Vector3(0, height + 0.13, 0), Color("fff1c8"))
	glow_box(piece + "_Glow", Vector3(0.18, 0.24, 0.26), at + Vector3(0, height + 0.13, 0), Color("ffe7a6"))
	glow_box(piece + "_Glow2", Vector3(0.26, 0.24, 0.18), at + Vector3(0, height + 0.13, 0), Color("ffe7a6"))


## A wooden planter with a flowering bush.
func planter(piece: String, at: Vector3, size: Vector2 = Vector2(0.9, 0.5), flowers: Color = Color("e85a9a")) -> void:
	box(piece, Vector3(size.x, 0.42, size.y), at + Vector3(0, 0.21, 0), Color("a8642a"))
	box(piece + "_Rim", Vector3(size.x + 0.06, 0.05, size.y + 0.06), at + Vector3(0, 0.43, 0), Color("8a5a34"))
	bush(piece + "_Bush", at + Vector3(0, 0.38, 0), size.x * 0.75, Color("5aa548"), flowers)


## A sunny town square round a room's stalls: paving slabs over `rect` (x and z, the floor's top at 0), grass out to the
## sky, little houses in friendly colours along its back and both sides facing in (none over a `keep_clear` rect), street
## lamps near its corners, flags across its back and trees behind its front (behind the child).
func town_square(rect: Rect2, keep_clear: Array[Rect2] = [], flags: bool = true) -> void:
	var fronts := [Color("f3e1c0"), Color("f6c9b4"), Color("cfe9d6"), Color("d6e4f6"), Color("f6e7a8"), Color("e8d6f2")]
	var roofs := [Color("c8553d"), Color("b5583f"), Color("8f5a4a")]
	var c := rect.get_center()
	box("Grass", Vector3(70, 0.1, 70), Vector3(c.x, -0.13, c.y), Color("8cc56a"), 0.0, SHELL)
	tiled("Square", SLABS, Vector3(rect.size.x, 0.1, rect.size.y), Vector3(c.x, -0.05, c.y), Color("f2e4c9"), 1.25)
	var spots: Array[Array] = []   # [where, yaw]
	var n := maxi(2, floori(rect.size.x / 4.6))
	for i in n:
		spots.append([Vector3(rect.position.x + (i + 0.5) * rect.size.x / n, 0, rect.position.y - 1.4), 0.0])
	var rows := maxi(2, floori(rect.size.y / 5.0))
	for i in rows:
		var z := rect.position.y + (i + 0.5) * rect.size.y / rows
		spots.append([Vector3(rect.position.x - 1.4, 0, z), PI / 2])
		spots.append([Vector3(rect.end.x + 1.4, 0, z), -PI / 2])
	var k := 0
	for s: Array in spots:
		var at: Vector3 = s[0]
		var foot := Rect2(at.x - 2.3, at.z - 2.3, 4.6, 4.6)
		if keep_clear.any(func(r: Rect2) -> bool: return r.intersects(foot)):
			continue
		house("House", at, Vector3(4.2, 2.8 + 0.5 * (k % 2), 2.6), float(s[1]), fronts[k % fronts.size()], roofs[k % roofs.size()])
		k += 1
	for corner: Vector2 in [Vector2(rect.position.x + 1.0, rect.position.y + 1.0), Vector2(rect.end.x - 1.0, rect.position.y + 1.0),
			Vector2(rect.position.x + 1.0, rect.end.y - 1.5), Vector2(rect.end.x - 1.0, rect.end.y - 1.5)]:
		if not keep_clear.any(func(r: Rect2) -> bool: return r.has_point(corner)):
			street_lamp("Lamp", Vector3(corner.x, 0, corner.y))
	if flags:
		bunting("Flags", Vector3(rect.position.x + 0.7, 3.3, rect.position.y + 1.3), Vector3(rect.end.x - 0.7, 3.3, rect.position.y + 1.3), 0.5)
	tree("Tree", Vector3(rect.position.x + 1.6, 0, rect.end.y + 1.6), 1.1)
	tree("Tree", Vector3(rect.end.x - 1.6, 0, rect.end.y + 1.6), 1.0, Color("5aa548"))
	tree("Tree", Vector3(c.x + 0.8, 0, rect.end.y + 2.6), 1.2, Color("5aa548"))


## Plain ground (lit, one colour) round a place's own floor `inner` (x, z and its size), out to a square `size` across:
## four slabs, so whatever is in `inner` (a pool, a pond) stays open. `top` is the ground's top.
func ground_around(piece: String, inner: Rect2, size: float, top: float, colour: Color) -> void:
	var c := inner.get_center()
	var lo := Vector2(c.x - size * 0.5, c.y - size * 0.5)
	var hi := Vector2(c.x + size * 0.5, c.y + size * 0.5)
	var e := inner.end
	for r: Rect2 in [Rect2(lo.x, lo.y, hi.x - lo.x, inner.position.y - lo.y), Rect2(lo.x, e.y, hi.x - lo.x, hi.y - e.y),
			Rect2(lo.x, inner.position.y, inner.position.x - lo.x, inner.size.y), Rect2(e.x, inner.position.y, hi.x - e.x, inner.size.y)]:
		box(piece, Vector3(r.size.x, 0.1, r.size.y), Vector3(r.get_center().x, top - 0.05, r.get_center().y), colour, 0.0, SHELL)


## A skirting board along a wall's foot (a thin dark strip: the room's corners read).
func skirting(piece: String, from: Vector3, to: Vector3, colour: Color = Color("e6dccb"), height: float = 0.09) -> void:
	var d := to - from
	var yaw := atan2(-d.z, d.x)
	box(piece, Vector3(Vector2(d.x, d.z).length(), height, 0.025), (from + to) * 0.5 + Vector3(0, height * 0.5, 0), colour, yaw, SHELL)


# --- Making the meshes -------------------------------------------------------------------------------------------------

## Draws everything added so far under `parent` (in a Node3D named `holder`, or straight under `parent` when holder is
## ""): at most one mesh a material. Returns the node they are in.
func commit(parent: Node3D, holder: String = "Decor") -> Node3D:
	var into := parent
	if holder != "":
		into = Node3D.new()
		into.name = holder
		parent.add_child(into)
	var names := ["Decor_Lit", "Decor_Tiles", "Decor_Glow"]
	var mats: Array[Material] = [lit_material(), tiles_material(), glow_material()]
	for i in _parts.size():
		if not _parts[i].empty():
			_mesh(into, names[i], _parts[i].mesh(), mats[i])
	for key: String in _glass:
		var g: Part = _glass[key]
		if not g.empty():
			_mesh(into, "Glass", g.mesh(), LifeRoomKit.material(Color.html(key)))
	if _sky != null:
		var m := _mesh(into, "Sky", _sky.mesh(), sky_material())
		m.extra_cull_margin = 0.0
	_parts = [Part.new(), Part.new(), Part.new()]
	_glass = {}
	_sky = null
	return into


static func _mesh(parent: Node3D, node_name: String, mesh: Mesh, mat: Material) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	m.name = node_name
	m.mesh = mesh
	m.material_override = mat
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(m)
	return m


func _remember(piece: String, kind: String, xf: Transform3D, local: AABB) -> void:
	pieces.append({"name": piece, "kind": kind, "box": xf * local, "xf": xf, "local": local})


## A box's six faces into `p`: plain in colour `c`, or (tile.x >= 0) faced with the atlas's `tile`, one picture every
## `per` metres along each face.
static func _box(p: Part, xf: Transform3D, size: Vector3, c: Color, tile: Vector2i, per: float) -> void:
	var h := size * 0.5
	# [outward normal, right, up, bottom-left corner] as a viewer facing the face sees it
	var faces := [
		[Vector3.RIGHT, Vector3.FORWARD, Vector3.UP, Vector3(h.x, -h.y, h.z)],
		[Vector3.LEFT, Vector3.BACK, Vector3.UP, Vector3(-h.x, -h.y, -h.z)],
		[Vector3.BACK, Vector3.RIGHT, Vector3.UP, Vector3(-h.x, -h.y, h.z)],
		[Vector3.FORWARD, Vector3.LEFT, Vector3.UP, Vector3(h.x, -h.y, -h.z)],
		[Vector3.UP, Vector3.RIGHT, Vector3.FORWARD, Vector3(-h.x, h.y, h.z)],
		[Vector3.DOWN, Vector3.RIGHT, Vector3.BACK, Vector3(-h.x, -h.y, -h.z)]]
	for f: Array in faces:
		var n: Vector3 = f[0]
		var right: Vector3 = f[1]
		var up: Vector3 = f[2]
		var bl: Vector3 = f[3]
		var w := absf((size * right).x + (size * right).y + (size * right).z)
		var hgt := absf((size * up).x + (size * up).y + (size * up).z)
		var world_n := (xf.basis * n).normalized()
		if tile.x < 0:
			p.quad(xf * bl, xf * (bl + up * hgt), xf * (bl + right * w + up * hgt), xf * (bl + right * w), world_n, c)
			continue
		var t3 := xf.basis * right
		var tangent := Vector4(t3.x, t3.y, t3.z, -1.0)
		var nu := maxi(1, ceili(w / per - 0.001))
		var nv := maxi(1, ceili(hgt / per - 0.001))
		for i in nu:
			var u0 := i * per
			var u1 := minf((i + 1) * per, w)
			for j in nv:
				var v0 := j * per
				var v1 := minf((j + 1) * per, hgt)
				var a := bl + right * u0 + up * v0
				var uv := PackedVector2Array([
					_uv(tile, 0.0, 0.0), _uv(tile, 0.0, (v1 - v0) / per), _uv(tile, (u1 - u0) / per, (v1 - v0) / per),
					_uv(tile, (u1 - u0) / per, 0.0)])
				p.quad(xf * a, xf * (a + up * (v1 - v0)), xf * (a + right * (u1 - u0) + up * (v1 - v0)), xf * (a + right * (u1 - u0)),
					world_n, c, uv, tangent)


## The atlas UV of a point (fu across, fv up, each 0..1) of a tile.
static func _uv(tile: Vector2i, fu: float, fv: float) -> Vector2:
	var u := clampf(fu, INSET, 1.0 - INSET)
	var v := clampf(fv, INSET, 1.0 - INSET)
	return Vector2((tile.x + u) / ATLAS, (tile.y + 1.0 - v) / ATLAS)


# --- A room's static scenery, merged ----------------------------------------------------------------------------------

## Merges the plain lit meshes under `holder` (a room's LifeRoom.scenery()) into one lit mesh there, freeing them, and
## returns their pieces (kind BAKED, boxes in the room's space). Stays itself: anything a room property holds (in an
## Array or Dictionary too), every target's node with what is above and under it, anything with a script of its own (a
## buddy, a dog, a tool), anything hidden (it shows later), see-through or glowing things, and whatever is under those.
## A sign on a static box is lifted off it (the same place, under the holder) so the box can merge.
static func bake(room: Node3D, holder: Node3D) -> Array[Dictionary]:
	var keep := {}
	for p: Dictionary in room.get_property_list():
		if p.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
			_refs(room.get(p.name), keep, 0)
	var t: Variant = room.get("targets")
	if t is Dictionary:
		for k: Variant in t:
			var n: Variant = (t[k] as Dictionary).get("node")
			if n is Node:
				keep[n] = true
	# a kept node's ancestors under the holder must stay too (freeing them would free it)
	var pinned := {}
	for n: Variant in keep:
		if n is Node and is_instance_valid(n) and holder.is_ancestor_of(n):
			var up := (n as Node).get_parent()
			while up != null and up != holder:
				pinned[up] = true
				up = up.get_parent()
	var can := {}
	for c: Node in holder.get_children():
		_can_go(c, keep, pinned, can)
	var d := LifeRoomDecor.new()
	var gone: Array[Node] = []
	var lift: Array[Label3D] = []
	for c: Node in holder.get_children():
		_act(c, keep, can, d, holder, gone, lift)
	var out: Array[Dictionary] = []
	if d._parts[LIT].empty():
		return out
	for l in lift:
		var xf := _relative(l, holder)
		l.get_parent().remove_child(l)
		l.transform = xf
		holder.add_child(l)
	d.commit(holder, "")
	var to_room := _relative(holder, room)
	for p: Dictionary in d.pieces:
		out.append({"name": p.name, "kind": BAKED, "box": to_room * (p.box as AABB)})
	for g in gone:
		g.get_parent().remove_child(g)
		g.free()
	return out


static func _refs(v: Variant, into: Dictionary, depth: int) -> void:
	if depth > 3:
		return
	if v is Node:
		into[v] = true
	elif v is Array:
		for x: Variant in v:
			_refs(x, into, depth + 1)
	elif v is Dictionary:
		for k: Variant in v:
			_refs(v[k], into, depth + 1)


## Whether `n` stays put as it is, with everything under it (kept, its own script, hidden, not a plain node or mesh).
static func _fixed(n: Node, keep: Dictionary) -> bool:
	if keep.has(n) or n.get_script() != null or not n is Node3D or not (n as Node3D).visible:
		return true
	return not (n.get_class() == "Node3D" or (n is MeshInstance3D and _plain_lit(n as MeshInstance3D)))


## Whether `n` and all under it can merge and go (a sign under it is lifted off), memoised in `can`.
static func _can_go(n: Node, keep: Dictionary, pinned: Dictionary, can: Dictionary) -> bool:
	var ok := not _fixed(n, keep) and not pinned.has(n)
	for c: Node in n.get_children():
		var child_ok := _can_go(c, keep, pinned, can)
		if not child_ok and not (c is Label3D and not keep.has(c) and c.get_child_count() == 0):
			ok = false
	if ok and n.get_class() == "Node3D" and n.get_child_count() == 0:
		ok = false   # an empty marker (a spot a room may still use) stays
	can[n] = ok
	return ok


static func _act(n: Node, keep: Dictionary, can: Dictionary, d: LifeRoomDecor, holder: Node3D, gone: Array[Node],
		lift: Array[Label3D]) -> void:
	if can.get(n, false):
		_merge_all(n, holder, d, lift)
		gone.append(n)
		return
	if _fixed(n, keep):
		return
	for c: Node in n.get_children():
		_act(c, keep, can, d, holder, gone, lift)


static func _merge_all(n: Node, holder: Node3D, d: LifeRoomDecor, lift: Array[Label3D]) -> void:
	if n is Label3D:
		lift.append(n as Label3D)
		return
	if n is MeshInstance3D:
		_merge(n as MeshInstance3D, holder, d)
	for c: Node in n.get_children():
		_merge_all(c, holder, d, lift)


static func _plain_lit(m: MeshInstance3D) -> bool:
	var mat := m.material_override as StandardMaterial3D
	if mat == null or m.mesh == null or m.mesh.get_surface_count() != 1:
		return false
	return mat.shading_mode != BaseMaterial3D.SHADING_MODE_UNSHADED and mat.transparency == BaseMaterial3D.TRANSPARENCY_DISABLED \
		and mat.albedo_color.a >= 0.999 and mat.albedo_texture == null and not mat.vertex_color_use_as_albedo \
		and not mat.emission_enabled and (m.mesh is PrimitiveMesh or m.mesh is ArrayMesh)


static func _merge(m: MeshInstance3D, holder: Node3D, d: LifeRoomDecor) -> void:
	var xf := _relative(m, holder)
	var arrays := m.mesh.surface_get_arrays(0)
	var v: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var nrm: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var idx: PackedInt32Array = arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
	var c := (m.material_override as StandardMaterial3D).albedo_color
	var p := d._parts[LIT]
	var base := p.verts.size()
	var nb := xf.basis.inverse().transposed()
	for i in v.size():
		p.verts.append(xf * v[i])
		p.normals.append((nb * nrm[i]).normalized() if i < nrm.size() else Vector3.UP)
		p.colours.append(c)
	var flip := xf.basis.determinant() < 0.0
	if idx.is_empty():
		for i in range(0, v.size(), 3):
			p.index.append_array([base + i, base + i + (2 if flip else 1), base + i + (1 if flip else 2)])
	else:
		for i in range(0, idx.size(), 3):
			p.index.append_array([base + idx[i], base + idx[i + (2 if flip else 1)], base + idx[i + (1 if flip else 2)]])
	d.pieces.append({"name": str(m.name), "kind": BAKED, "box": xf * m.mesh.get_aabb()})


## `n`'s transform in `root`'s space (walking up its parents: works before either is in the tree).
static func _relative(n: Node, root: Node) -> Transform3D:
	var xf := Transform3D()
	var at := n
	while at != null and at != root:
		if at is Node3D:
			xf = (at as Node3D).transform * xf
		at = at.get_parent()
	return xf


# --- The room's light and tone -----------------------------------------------------------------------------------------

## The worlds' tone on a room's environment (the visuals brief: ACES at a little under 1; a soft sky-tinted ambient):
## the rooms match the worlds' colours and never wash out white.
static func tone(env: Environment, exposure: float = 0.92) -> void:
	if env == null:
		return
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = exposure
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.86, 0.9, 1.0)
