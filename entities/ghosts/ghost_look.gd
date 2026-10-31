class_name GhostLook
extends RefCounted
## A friend's look, see-through (M4 ghost races): every mesh of a body keeps its own colours at ALPHA, a little
## towards a pale blue, and casts no shadow. Each material gets a see-through twin (alpha blending on the
## material works on every renderer, the emulator's Compatibility fallback too, unlike a per-instance fade):
## one per source material, kept for the whole game (the avatar's materials are shared per colour already), so
## a ghost never compiles a new shader after the first.

const ALPHA := 0.45
const TINT := Color(0.72, 0.88, 1.0)
const _MAX_CACHE := 256

static var _twins := {}          # source material -> its see-through twin
static var _plain: StandardMaterial3D


## Every mesh under `node` see-through (name tags, Label3D, are left as they are).
static func apply(node: Node) -> void:
	for g in node.find_children("*", "GeometryInstance3D", true, false):
		if g is Label3D:
			continue
		var gi := g as GeometryInstance3D
		gi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if gi is MeshInstance3D and (gi as MeshInstance3D).mesh != null:
			var mi := gi as MeshInstance3D
			for i in mi.mesh.get_surface_count():
				mi.set_surface_override_material(i, twin(mi.get_active_material(i)))
			mi.material_override = null
		else:
			gi.material_override = twin(gi.material_override)


## The see-through twin of `source` (a plain pale one for a shader or no material).
static func twin(source: Material) -> Material:
	if not source is BaseMaterial3D:
		return plain()
	if _twins.has(source):
		return _twins[source]
	if _twins.size() >= _MAX_CACHE:
		_twins.clear()
	var m := (source as BaseMaterial3D).duplicate() as BaseMaterial3D
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var c := m.albedo_color.lerp(TINT, 0.25)
	m.albedo_color = Color(c.r, c.g, c.b, m.albedo_color.a * ALPHA)
	_twins[source] = m
	return m


static func plain() -> StandardMaterial3D:
	if _plain == null:
		_plain = StandardMaterial3D.new()
		_plain.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_plain.albedo_color = Color(TINT.r, TINT.g, TINT.b, ALPHA)
	return _plain


## Whether `m` is see-through (tests).
static func is_see_through(m: Material) -> bool:
	return m is BaseMaterial3D and (m as BaseMaterial3D).transparency == BaseMaterial3D.TRANSPARENCY_ALPHA \
		and (m as BaseMaterial3D).albedo_color.a < 1.0
