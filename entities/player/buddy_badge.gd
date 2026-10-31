class_name BuddyBadge
extends RefCounted
## Owner feedback #43 (spec §3c): the buddy badge, EasyCraft's signature on every avatar's chest in both styles: a
## little orange block buddy with googly eyes on a white pin. It is part of the body, not of the look (old looks
## wear it too); a full outfit hides it (AvatarModel._dress). One merged mesh made once and shared by every avatar,
## drawn with the avatar parts' own material (vertex colours): no new material or shader.

const NODE_NAME := "BuddyBadge"
const BUDDY := Color("ff8a34")
const INK := Color("1e2a4a")
const PIN := Color("fafafa")
## Where it sits: on the blocky torso (BODY anchor: the torso's centre, its front at z -0.16), over the heart; on the
## realistic chest (metres, its front at about z -0.12), smaller.
const BLOCKY_AT := Vector3(-0.19, 0.14, -0.172)
const REAL_AT := Vector3(-0.075, 0.1, -0.128)
const REAL_SCALE := 0.5

## [size, position, colour] in the badge's own space (it faces -Z, like the body).
const BOXES := [
	[Vector3(0.14, 0.14, 0.012), Vector3(0, 0, 0), PIN],                       # the pin
	[Vector3(0.11, 0.1, 0.008), Vector3(0, -0.005, -0.009), BUDDY],            # the buddy
	[Vector3(0.11, 0.025, 0.006), Vector3(0, 0.035, -0.014), Color("ffba6e")], # its lighter top
	[Vector3(0.034, 0.034, 0.004), Vector3(-0.024, 0.0, -0.016), PIN],         # googly eyes
	[Vector3(0.034, 0.034, 0.004), Vector3(0.024, 0.0, -0.016), PIN],
	[Vector3(0.016, 0.016, 0.004), Vector3(-0.019, 0.004, -0.019), INK],       # looking up
	[Vector3(0.016, 0.016, 0.004), Vector3(0.029, 0.004, -0.019), INK],
	[Vector3(0.03, 0.008, 0.004), Vector3(0, -0.03, -0.016), INK],             # a smile
]

static var _mesh: ArrayMesh


## The badge's mesh, made once.
static func mesh() -> ArrayMesh:
	if _mesh == null:
		var s := AvatarParts._new_surface()
		for b: Array in BOXES:
			AvatarParts._append_box(s, b[0], b[1], Vector3.ZERO, b[2])
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array(s.v)
		arrays[Mesh.ARRAY_NORMAL] = PackedVector3Array(s.n)
		arrays[Mesh.ARRAY_COLOR] = PackedColorArray(s.c)
		arrays[Mesh.ARRAY_INDEX] = PackedInt32Array(s.i)
		_mesh = ArrayMesh.new()
		_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		_mesh.surface_set_material(0, AvatarParts.part_material())
	return _mesh


## A badge for a body's chest anchor: the blocky torso's, or (realistic) the person's chest, smaller.
static func build(realistic: bool) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = NODE_NAME
	mi.mesh = mesh()
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.position = REAL_AT if realistic else BLOCKY_AT
	if realistic:
		mi.scale = Vector3.ONE * REAL_SCALE
	return mi
