class_name GadgetLooks
extends Node3D
## What a player's gadget looks like, in every game (M3 Task 14a): the open glider over its head (turned
## with the avatar, in its look), the hook's rope from the hand to where it holds, and the handle a zipline
## rider hangs from. A child of the Player (its feet at the origin), made the first time a gadget is used;
## the meshes are GadgetModels' cached ones and every change is written only when it happens.

var _canopy := MeshInstance3D.new()
var _handle := MeshInstance3D.new()
var _rope := MeshInstance3D.new()
var _head := MeshInstance3D.new()
var _shown_move := -1
var _shown_look := -1


func _ready() -> void:
	for m: MeshInstance3D in [_canopy, _handle, _rope, _head]:
		m.visible = false
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(m)
	_canopy.name = "Canopy"
	_handle.name = "Handle"
	_handle.mesh = GadgetModels.handle()
	_rope.name = "Rope"
	_rope.top_level = true
	_rope.mesh = GadgetModels.rope()
	_head.name = "HookHead"
	_head.top_level = true
	_head.mesh = GadgetModels.hook_head()


func show_for(p: Player) -> void:
	var move := p.gadget_move
	if move != _shown_move or p.glider_look != _shown_look:
		_shown_move = move
		_shown_look = p.glider_look
		_canopy.visible = move == GadgetRules.Move.GLIDE
		_handle.visible = move == GadgetRules.Move.ZIP
		if _canopy.visible:
			_canopy.mesh = GadgetModels.canopy(p.glider_look)
	var s := Vector3.ONE * p.size_scale()
	if scale != s:
		scale = s
	if _canopy.visible and _canopy.rotation.y != p.avatar.rotation.y:
		_canopy.rotation.y = p.avatar.rotation.y
	var hooked := move == GadgetRules.Move.HOOK and p.hook_point.is_finite()
	_rope.visible = hooked
	_head.visible = hooked
	if hooked:
		var hand: Node3D = p.avatar.hand() if p.avatar.has_method(&"hand") else null
		var from := hand.global_position if hand else p.eye_position()
		stretch(_rope, from, p.hook_point)
		_head.global_position = p.hook_point


## Stretches a 1 m piece along -Z from `a` to `b`.
static func stretch(piece: Node3D, a: Vector3, b: Vector3) -> void:
	var d := b - a
	var length := d.length()
	if length < 0.01:
		return
	var up := Vector3.RIGHT if absf(d.normalized().y) > 0.99 else Vector3.UP
	piece.global_transform = Transform3D(Basis.looking_at(d, up) * Basis.from_scale(Vector3(1, 1, length)), a)


## Which looks show (tests): &"canopy", &"handle", &"rope".
func showing() -> Array[StringName]:
	var out: Array[StringName] = []
	for pair: Array in [[&"canopy", _canopy], [&"handle", _handle], [&"rope", _rope]]:
		if (pair[1] as Node3D).visible:
			out.append(pair[0])
	return out
