class_name AvatarIcon
extends RefCounted
## Pictures for avatar items and emotes (M3 Task 9), drawn from the same data as the 3D parts, so the
## editor and the emote wheel are icon-first with no image files: colour swatches, a blocky head
## wearing the hair, face or hat, a little figure in an outfit or doing an emote. Every function draws
## on `canvas` inside `rect`.

const SKIN := Color("f5cd30")
const SHIRT := Color("0d69ac")
const PANTS := Color("33406b")
const HAIR := Color("5a3a22")
const INK := Color(0.1, 0.1, 0.12)


## Owner 48: the editor's first choice (BOY / GIRL / JUST ME: AvatarCatalog.BASES) and its ready-made
## looks (AvatarCatalog.PRESETS) are drawn as little figures too.
const BASE := &"base"
const PRESET := &"preset"
## Owner 36: a whole costume (CostumeRules), drawn as a little figure wearing it.
const COSTUME := &"costume"


## The picture for `item` of `slot`. `own` (optional) is the child's look: a clothes cut, a first choice or a
## preset is drawn in its colours and skin tone.
static func draw_item(canvas: CanvasItem, rect: Rect2, slot: StringName, item: StringName, own: AvatarLook = null) -> void:
	match slot:
		BASE:
			figure(canvas, rect, AvatarLook.start(item, own).resolve(), EmotePoses.rest())
		PRESET:
			figure(canvas, rect, AvatarLook.preset(item, own).resolve(), EmotePoses.rest())
		COSTUME:   # Owner 36: the whole costume, in the child's own skin tone
			figure(canvas, rect, CostumeRules.wear(item, own).resolve(), EmotePoses.rest())
		AvatarCatalog.CLOTHES:
			var dressed := own.duplicate() if own else AvatarLook.new()
			dressed.clothes = item
			dressed.outfit = &"none"
			figure(canvas, rect, dressed.resolve(), EmotePoses.rest())
		AvatarCatalog.SKIN:
			_swatch(canvas, rect, AvatarCatalog.SKIN_TONES.get(item, SKIN))
		AvatarCatalog.HAIR_COLOR:
			_swatch(canvas, rect, AvatarCatalog.HAIR_COLORS.get(item, HAIR), true)
		AvatarCatalog.SHIRT:
			_shirt(canvas, rect, AvatarCatalog.CLOTH.get(item, SHIRT))
		AvatarCatalog.PANTS:
			_pants(canvas, rect, AvatarCatalog.CLOTH.get(item, PANTS))
		AvatarCatalog.FACE:
			_head(canvas, rect, ["face_%s" % item])
		AvatarCatalog.HAIR:
			_head(canvas, rect, ["face_smile", "hair_%s" % item] if item != &"none" else ["face_smile"])
		AvatarCatalog.HAT:
			_head(canvas, rect, ["face_smile", "hat_%s" % item] if item != &"none" else ["face_smile"])
		AvatarCatalog.CAPE, AvatarCatalog.WINGS:
			if item == &"none":
				_none(canvas, rect)
			else:
				_back(canvas, rect, "%s_%s" % [slot, item])
		AvatarCatalog.TRAIL:
			_trail(canvas, rect, item)
		AvatarCatalog.OUTFIT:
			var look := AvatarLook.new()
			look.outfit = item
			figure(canvas, rect, look.resolve(), EmotePoses.rest())
		AvatarCatalog.EMOTE:
			figure(canvas, rect, AvatarLook.new().resolve(), EmotePoses.sample(item, _pose_time(item)))


## A good moment to show an emote in a still picture.
static func _pose_time(emote: StringName) -> float:
	match emote:
		&"sit":
			return 2.0
		&"dance_star":
			return 0.3
		&"bow":
			return 0.8
	return 0.45


static func _swatch(canvas: CanvasItem, rect: Rect2, color: Color, round_shape: bool = false) -> void:
	var r := rect.grow(-rect.size.x * 0.14)
	if round_shape:
		canvas.draw_circle(r.get_center(), r.size.x * 0.5, color.darkened(0.3))
		canvas.draw_circle(r.get_center(), r.size.x * 0.44, color)
		canvas.draw_circle(r.get_center() - r.size * 0.14, r.size.x * 0.1, Color(1, 1, 1, 0.35))
	else:
		_box(canvas, r, color)


static func _box(canvas: CanvasItem, r: Rect2, color: Color) -> void:
	canvas.draw_rect(r, color.darkened(0.3))
	canvas.draw_rect(r.grow(-maxf(2.0, r.size.x * 0.06)), color)


static func _none(canvas: CanvasItem, rect: Rect2) -> void:
	var c := rect.get_center()
	var r := rect.size.x * 0.28
	canvas.draw_arc(c, r, 0.0, TAU, 32, Color(1, 1, 1, 0.6), 5.0, true)
	canvas.draw_line(c + Vector2(-r, r) * 0.7, c + Vector2(r, -r) * 0.7, Color(1, 1, 1, 0.6), 5.0, true)


static func _shirt(canvas: CanvasItem, rect: Rect2, color: Color) -> void:
	var u := rect.size.x / 10.0
	var o := rect.position
	var body := PackedVector2Array([o + Vector2(3, 2) * u, o + Vector2(7, 2) * u, o + Vector2(9, 4) * u,
		o + Vector2(8, 5) * u, o + Vector2(7, 4) * u, o + Vector2(7, 8.5) * u, o + Vector2(3, 8.5) * u,
		o + Vector2(3, 4) * u, o + Vector2(2, 5) * u, o + Vector2(1, 4) * u])
	canvas.draw_colored_polygon(body, color)
	body.append(body[0])
	canvas.draw_polyline(body, color.darkened(0.35), 3.0, true)


static func _pants(canvas: CanvasItem, rect: Rect2, color: Color) -> void:
	var u := rect.size.x / 10.0
	var o := rect.position
	var legs := PackedVector2Array([o + Vector2(2.5, 1.5) * u, o + Vector2(7.5, 1.5) * u, o + Vector2(7.8, 8.5) * u,
		o + Vector2(5.5, 8.5) * u, o + Vector2(5, 4) * u, o + Vector2(4.5, 8.5) * u, o + Vector2(2.2, 8.5) * u])
	canvas.draw_colored_polygon(legs, color)
	legs.append(legs[0])
	canvas.draw_polyline(legs, color.darkened(0.35), 3.0, true)


## A blocky head seen from the front, wearing parts (AvatarParts ids).
static func _head(canvas: CanvasItem, rect: Rect2, parts: Array, colors: Dictionary = {}) -> void:
	var s := rect.size.x * 0.8          # pixels per block: the 0.5 head is 40% of the picture
	var centre := rect.get_center() + Vector2(0, rect.size.y * 0.16)   # low: tall hats fit above
	var cols := {"hair": HAIR, "skin": SKIN, "shirt": SHIRT, "pants": PANTS}
	cols.merge(colors, true)
	var boxes: Array = []
	for id: String in parts:
		boxes.append_array(_boxes(id))
	boxes.sort_custom(func(a: Array, b: Array) -> bool: return (a[1] as Vector3).z > (b[1] as Vector3).z)   # far first
	var head_drawn := false
	for box: Array in boxes:
		if not head_drawn and (box[1] as Vector3).z <= 0.0:
			_box(canvas, Rect2(centre - Vector2(0.25, 0.25) * s, Vector2(0.5, 0.5) * s), cols.skin)
			head_drawn = true
		_part_box(canvas, box, centre, s, cols)
	if not head_drawn:
		_box(canvas, Rect2(centre - Vector2(0.25, 0.25) * s, Vector2(0.5, 0.5) * s), cols.skin)


## A back part (cape, wings) seen from behind, on a small torso.
static func _back(canvas: CanvasItem, rect: Rect2, id: String) -> void:
	var body := rect.size.x * 0.42      # a small torso and head...
	var part := rect.size.x * 0.78      # ...and the part bigger, so it reads at tile size
	var top := rect.get_center() + Vector2(0, -rect.size.y * 0.04)
	canvas.draw_rect(Rect2(top + Vector2(-0.31, 0.0) * body, Vector2(0.62, 0.72) * body), SHIRT.darkened(0.2))
	canvas.draw_rect(Rect2(top + Vector2(-0.25, -0.5) * body, Vector2(0.5, 0.5) * body), HAIR)
	var spec: Dictionary = AvatarParts.PARTS.get(id, {})
	for box: Array in spec.get("boxes", []):
		_part_box(canvas, box, top, part, {}, false)
		if spec.get("mirror", false):
			_part_box(canvas, box, top, part, {}, true)


static func _trail(canvas: CanvasItem, rect: Rect2, trail: StringName) -> void:
	if trail == &"none":
		_none(canvas, rect)
		return
	var colors: Array = AvatarTrail.STYLES[trail].colors
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(trail)
	for i in 14:
		var t := float(i) / 14.0
		var p := rect.position + Vector2(rect.size.x * (0.15 + 0.7 * t), rect.size.y * (0.75 - 0.45 * t + rng.randf_range(-0.12, 0.12)))
		var sz := rect.size.x * lerpf(0.05, 0.11, t)
		canvas.draw_rect(Rect2(p - Vector2(sz, sz) * 0.5, Vector2(sz, sz)), colors[i % colors.size()])


## A little blocky figure wearing a resolved look (AvatarLook.resolve) in an emote pose
## (EmotePoses), seen from the front and a little from the side, so arms held forward still show.
static func figure(canvas: CanvasItem, rect: Rect2, r: Dictionary, pose: Dictionary) -> void:
	var s := rect.size.y * 0.42                       # pixels per block (the body is 1.8 tall)
	var feet := rect.position + Vector2(rect.size.x * 0.5, rect.size.y * 0.94)
	var lift := (float(pose.get("hop", 0.0)) - float(pose.get("sit", 0.0)) * AvatarModel.SIT_DROP) * s
	var to_px := func(p: Vector3) -> Vector2: return feet + Vector2(p.x + 0.35 * p.z, -p.y - 0.2 * p.z) * s - Vector2(0, lift)
	var skin: Color = r.skin
	var cols := {"hair": r.hair_color, "skin": skin, "shirt": r.shirt, "pants": r.pants, "shoes": r.shoes,
		"top": r.get("top", r.shirt), "bottom": r.get("bottom", r.pants)}
	var shoes: Color = r.shoes
	# legs, then the torso, then the arms and the head in front
	for side: float in [-1.0, 1.0]:
		var pitch := float(pose.get("l_leg" if side < 0 else "r_leg", 0.0))
		var hip := Vector3(0.15 * side, 0.64, 0.0)
		var foot := hip + Vector3(0, -cos(pitch), -sin(pitch)) * 0.6
		_limb(canvas, to_px.call(hip), to_px.call(foot), 0.28 * s, r.pants)
		if shoes.a > 0.0:   # Owner 48: shoes and boots show
			var ankle := hip + Vector3(0, -cos(pitch), -sin(pitch)) * (0.36 if r.get("boots", false) else 0.48)
			_limb(canvas, to_px.call(ankle), to_px.call(foot), 0.3 * s, Color(shoes, 1.0))
	var torso_top: Vector2 = to_px.call(Vector3(-0.31, 1.36, 0.0))
	canvas.draw_rect(Rect2(torso_top, Vector2(0.62, 0.72) * s), r.shirt)
	for box: Array in _outfit_body_boxes(r):
		_part_box(canvas, box, to_px.call(Vector3(0, 1.0, 0.0)), s, cols)
	var sleeves: Color = r.get("sleeves", Color(0, 0, 0, 0))
	for side: float in [-1.0, 1.0]:
		var arm: Vector2 = pose.get("l_arm" if side < 0 else "r_arm", Vector2.ZERO)
		var shoulder := Vector3(0.42 * side, 1.32, 0.0)
		var dir := Basis(Vector3.RIGHT, arm.x) * Basis(Vector3.BACK, side * arm.y) * Vector3.DOWN
		_limb(canvas, to_px.call(shoulder), to_px.call(shoulder + dir * 0.6), 0.22 * s, skin)
		if sleeves.a > 0.0:   # Owner 48: long sleeves down to the hand
			_limb(canvas, to_px.call(shoulder), to_px.call(shoulder + dir * 0.46), 0.24 * s, Color(sleeves, 1.0))
	var parts: Array = ["face_%s" % r.face]
	if r.hair != &"none" and not r.hides_hair:
		parts.append("hair_%s" % r.hair)
	if r.hat != &"none":
		parts.append("hat_%s" % r.hat)
	var head_rect := Rect2(Vector2.ZERO, Vector2.ONE * s / 0.8)   # _head draws 0.8 * width pixels per block
	head_rect.position = to_px.call(Vector3(0, 1.55, 0.0)) - head_rect.size * 0.5 - Vector2(0, head_rect.size.y * 0.16)
	_head(canvas, head_rect, parts, cols)


static func _outfit_body_boxes(r: Dictionary) -> Array:
	var out: Array = []
	for e: StringName in r.extras:
		var id := "extra_%s" % e
		if AvatarParts.anchor_of(id) == AvatarParts.BODY:
			out.append_array(_boxes(id))
	return out


static func _limb(canvas: CanvasItem, from: Vector2, to: Vector2, width: float, color: Color) -> void:
	canvas.draw_line(from, to, color.darkened(0.25), width + 3.0, true)
	canvas.draw_line(from, to, color, width, true)


static func _boxes(id: String) -> Array:
	var spec: Dictionary = AvatarParts.PARTS.get(id, {})
	var out: Array = []
	if spec.has("base"):
		out.append_array(AvatarParts.PARTS[spec.base].boxes)
	out.append_array(spec.get("boxes", []))
	return out


## One part box seen from the front (or the back): its x/y rectangle around `origin` (pixels), `s`
## pixels per block.
static func _part_box(canvas: CanvasItem, box: Array, origin: Vector2, s: float, cols: Dictionary, mirrored: bool = false) -> void:
	var size: Vector3 = box[0]
	var pos: Vector3 = box[1]
	if mirrored:
		pos.x = -pos.x
	var c: Variant = box[2]
	var color: Color = cols.get(c, Color.MAGENTA) if typeof(c) == TYPE_STRING else c
	var r := Rect2(origin + Vector2(pos.x - size.x * 0.5, -pos.y - size.y * 0.5) * s, Vector2(size.x, size.y) * s)
	canvas.draw_rect(r, color)
