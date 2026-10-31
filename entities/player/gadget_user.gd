class_name GadgetUser
extends Node
## The local player's gadgets (M3 Task 14a), a child of the BlockInteractor. With a gadget in the hand a tap
## uses it where it points: the grappling hook holds onto the tapped block and pulls, an orb is thrown at the
## tapped spot, a quick build goes up in front, the glider opens (in the air). ATTACK (owner feedback #29:
## ATTACK always attacks) uses the hook or an orb in the hand at the middle of the screen; with anything
## else in the hand ATTACK attacks as before. Every use is a request the host checks (Session section
## "M3 Task 14a"); the local pace here only saves requests the host would refuse anyway.

const JUMP_FIRST := "Jump off something high, then glide!"

var interactor: BlockInteractor
var _ready_ms := {}   # use -> msec it may be used again (the host checks the pace again)


func player() -> Player:
	return interactor.player


func handles(id: int) -> bool:
	return GadgetRules.is_gadget(id)


## A tap (or a click with a captured mouse) with a gadget in the hand; true when it was used.
func use_at_screen(screen_pos: Vector2) -> bool:
	var item := interactor.selected_block()
	var p := player()
	if not p.is_spawned() or p.sleeping or p.knocked_out:
		return false
	if item == ItemIds.GLIDER:
		if p.gadget_move == GadgetRules.Move.GLIDE or p.can_glide():
			return p.toggle_glider()
		_say(JUMP_FIRST)
		return true
	if item == ItemIds.GRAPPLE:
		return hook_at_screen(screen_pos)
	if GadgetRules.is_orb(item):
		return throw_orb(item, interactor.weapons.aim_point(screen_pos))
	if GadgetRules.is_build(item):
		return build(item)
	return false


## ATTACK with the hook or an orb in the hand: used at the middle of the screen (true). Anything else in the
## hand: false, and ATTACK attacks as always.
func attack() -> bool:
	var item := interactor.selected_block()
	if item != ItemIds.GRAPPLE and not GadgetRules.is_orb(item):
		return false
	var p := player()
	if not p.is_spawned() or p.sleeping or p.knocked_out:
		return true
	var center := get_viewport().get_visible_rect().size * 0.5
	if item == ItemIds.GRAPPLE:
		return hook_at_screen(center)
	return throw_orb(item, interactor.weapons.aim_point(center))


## Throws the hook at the block under a screen point (up to its reach): the host checks it and says go.
func hook_at_screen(screen_pos: Vector2) -> bool:
	var p := player()
	var ray := p.aim_ray(screen_pos)   # owner #101: the camera's ray through the point, or the VR hand's
	var from: Vector3 = ray[0]
	var reach := from.distance_to(p.eye_position()) + GadgetRules.HOOK_RANGE + 1.0
	var hit := GridRay.cast(from, ray[1], reach, p._is_solid)
	if hit == null:
		_say(GadgetRules.hook_message("far"))
		return true
	var r := GadgetRules.hook_check(p.eye_position(), hit.position, p._is_solid)
	if not r.ok:
		_say(GadgetRules.hook_message(r.error))
		return true
	if not _pace(&"hook", GadgetRules.HOOK_COOLDOWN):
		return true
	_face(r.point - p.eye_position())
	p.play_attack(ItemIds.BOOMERANG)   # the throw
	Audio.play(&"swing", p.global_position)
	Session.request_hook(hit.position)
	return true


## Throws an orb towards `point` (it flies in an arc and bursts where it lands).
func throw_orb(item: int, point: Vector3) -> bool:
	var p := player()
	var dir := point - p.eye_position()
	if dir.length() < 0.01:
		dir = -p.camera().global_basis.z
	if not _pace(&"orb", GadgetRules.ORB_COOLDOWN):
		return true
	_face(dir)
	p.play_attack(ItemIds.BOOMERANG)
	Audio.play(&"swing", p.global_position)
	Session.request_orb(item, dir.normalized())
	return true


## A quick build in front of the player, the way the camera looks.
func build(item: int) -> bool:
	if not _pace(&"build", GadgetRules.BUILD_COOLDOWN):
		return true
	Session.request_instant_build(item, player().rig.yaw)
	return true


func _pace(use: StringName, seconds: float) -> bool:
	var now := Time.get_ticks_msec()
	if now < int(_ready_ms.get(use, 0)):
		return false
	_ready_ms[use] = now + int(seconds * 1000.0)
	return true


func _face(dir: Vector3) -> void:
	var p := player()
	if Vector2(dir.x, dir.z).length() > 0.01 and not p.rig.first_person:
		p.avatar.rotation.y = atan2(-dir.x, -dir.z)


func _say(text: String) -> void:
	if text != "":
		Session.magic_feedback.emit(text)
