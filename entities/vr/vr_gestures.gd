class_name VrGestures
extends Node3D
## Owner #110, VR round 4 idea 3 (VR-HANDS; docs/devlog/parts/vr-r4-hands.md, the research §5.3 "Wave and high-five",
## R8): buddies, pets and friends answer the child's hands. Made by Vr for a session, stepped every frame.
## - **A wave** (VrGestureRules.wave_step, either hand raised): buddies near wave back (Buddy.wave), the nearest animals
##   look up (Animal.cheer), bot friends wave (their avatar's wave); the nearest buddy within PAW_RANGE holds up a paw.
## - **A high-five:** a hand slapping the paw, or meeting a VR friend's drawn hand (their VrBody) fast: a clap, sparkles,
##   both controllers buzz. A clap with a friend counts in `claps`, sent on this child's VR pose (VrGestureRules'
##   spare byte, Vr.pose_bytes): the friend's game claps too (once, CLAP_ONCE). No new sync, no voice: only gestures.
## - **Eyes:** buddies within LOOK_RANGE look at the child (Buddy.look_target).
## The personal bubble (R8) is VrBody's (other players' hands) and the Player's (another player's body, vr_bubbled).

## This child's high-fives with friends (on its VR pose), waves heard, answers to them, claps played (tests).
var claps := 0
var waves := 0
var answered := 0
var clapped := 0
## The paw a buddy holds up after a wave (shown while one does).
var paw := MeshInstance3D.new()

const PAW_SIZE := Vector3(0.14, 0.035, 0.12)
const PAW_COLOR := Color(1.0, 0.82, 0.45)
const CLAP_BUZZ := [0.6, 0.08]
const NEAREST_ANIMALS := 3

var _clock := 0.0
var _wave := {}       # side -> VrGestureRules.wave_step's state
var _last := {}       # side -> the hand's world place last frame
var _vel := {}        # side -> its velocity (the child's m/s)
var _paw_buddy: WeakRef = null
var _paw_left := 0.0
var _last_clap := -10.0
var _remote_claps := {}   # a player's instance id -> its claps last seen
var _looking: Array[WeakRef] = []


func _init() -> void:
	name = "VrGestures"
	var box := BoxMesh.new()
	box.size = PAW_SIZE
	var m := StandardMaterial3D.new()
	m.albedo_color = PAW_COLOR
	m.emission_enabled = true
	m.emission = PAW_COLOR * 0.35
	box.material = m
	paw.mesh = box
	paw.name = "Paw"
	paw.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	paw.top_level = true
	paw.visible = false
	add_child(paw)


func _exit_tree() -> void:
	for w: WeakRef in _looking:
		var b := w.get_ref() as Buddy
		if b != null and is_instance_valid(b):
			b.look_target = Vector3.INF   # off VR the eyes jiggle as before
	_looking.clear()


## One frame (Vr.step): the hands' motion, waves and their answers, the paw, high-fives with friends, the eyes.
func step(delta: float) -> void:
	if Vr.rig == null or not is_inside_tree():
		return
	_clock += delta
	var head := Vr.head_transform()
	var s := maxf(Vr.world_scale(), 0.001)
	for side: StringName in [VrRules.LEFT, VrRules.RIGHT]:
		var at := Vr.hand_grip(side).origin
		var was: Vector3 = _last.get(side, Vector3.INF)
		_vel[side] = (at - was) / s / delta if was.is_finite() and delta > 0.0 else Vector3.ZERO
		_last[side] = at
		if _wave_heard(side, at, head, s):
			waves += 1
			_answer_wave(head, s)
	_step_paw(delta, s)
	_with_friends(head, s)
	_eyes(head, s)


## The hand's sideways sweep across the head's facing, raised (the play space: walking never counts).
func _wave_heard(side: StringName, at: Vector3, head: Transform3D, s: float) -> bool:
	var right := head.basis.x
	right.y = 0.0
	if right.length_squared() < 0.000001:
		return false
	var to := (at - head.origin) / s
	var high := to.y >= -VrGestureRules.WAVE_LOW
	if not _wave.has(side):
		_wave[side] = {}
	var local_x := (Vr.rig.global_transform.affine_inverse() * at).dot(Vr.rig.global_basis.inverse() * right.normalized())
	return VrGestureRules.wave_step(_wave[side], _clock, local_x / s, high)


## Buddies near wave back (the nearest within PAW_RANGE holds up a paw), the nearest animals look up, bot friends wave.
func _answer_wave(head: Transform3D, s: float) -> void:
	var reach := VrGestureRules.LOOK_RANGE * s
	var nearest: Buddy = null
	var nearest_d := VrGestureRules.PAW_RANGE * s
	for n: Node in get_tree().get_nodes_in_group(&"buddies"):
		var b := n as Buddy
		if b == null or not b.is_inside_tree():
			continue
		var d := b.global_position.distance_to(head.origin)
		if d > reach:
			continue
		b.wave()
		answered += 1
		if d < nearest_d:
			nearest_d = d
			nearest = b
	var animals: Array = []
	for n: Node in get_tree().get_nodes_in_group(&"animals"):
		var a := n as Animal
		if a != null and a.is_inside_tree() and a.global_position.distance_to(head.origin) <= reach:
			animals.append(a)
	animals.sort_custom(func(x: Animal, y: Animal) -> bool:
		return x.global_position.distance_squared_to(head.origin) < y.global_position.distance_squared_to(head.origin))
	for a: Animal in animals.slice(0, NEAREST_ANIMALS):
		a.cheer()
		answered += 1
	for n: Node in get_tree().get_nodes_in_group(&"bot_friends"):
		var bot := n as Node3D
		if bot == null or bot.global_position.distance_to(head.origin) > reach:
			continue
		var avatar: Variant = bot.get(&"avatar")
		if avatar is AvatarModel and (avatar as AvatarModel).play_emote(&"wave"):
			answered += 1
	if nearest != null:
		_offer_paw(nearest)


func _offer_paw(b: Buddy) -> void:
	_paw_buddy = weakref(b)
	_paw_left = VrGestureRules.PAW_SECONDS
	paw.visible = true
	_place_paw(Vr.world_scale())


## The paw between the buddy and the child, at the child's hand height, facing the child.
func _place_paw(s: float) -> void:
	var b := _paw_buddy.get_ref() as Buddy if _paw_buddy != null else null
	if b == null or not is_instance_valid(b) or not b.is_inside_tree():
		paw.visible = false
		return
	var head := Vr.head_transform()
	var to := head.origin - b.global_position
	to.y = 0.0
	var dir := to.normalized() if to.length() > 0.001 else Vector3.FORWARD
	var half := maxf(float(b.size_blocks.x), float(b.size_blocks.z)) * 0.5
	var at := b.global_position + dir * (half + 0.25)
	at.y = head.origin.y - 0.35 * s
	paw.global_transform = Transform3D(Basis.looking_at(dir, Vector3.UP) * Basis(Vector3.RIGHT, PI * 0.5) \
		* Basis.from_scale(Vector3.ONE * s), at)


func _step_paw(delta: float, s: float) -> void:
	if not paw.visible:
		return
	_paw_left -= delta
	if _paw_left <= 0.0:
		paw.visible = false
		return
	_place_paw(s)
	if not paw.visible:
		return
	for side: StringName in [VrRules.LEFT, VrRules.RIGHT]:
		if VrGestureRules.meets(_last[side] / s, _vel[side], paw.global_position / s, Vector3.ZERO):
			paw.visible = false
			_clap(paw.global_position)
			var b := _paw_buddy.get_ref() as Buddy
			if b != null and is_instance_valid(b):
				b.cheer()
			return


## High-fives with VR friends (their drawn hands, VrBody), their claps heard on their pose.
func _with_friends(_head: Transform3D, s: float) -> void:
	for n: Node in get_tree().get_nodes_in_group(&"players"):
		var p := n as Player
		if p == null or p.is_local:
			continue
		var body := p.vr_body()
		if body != null and body.showing() and body.hands_shown:
			for side: StringName in [VrRules.LEFT, VrRules.RIGHT]:
				for theirs: VrHandModel in body.hands.values():
					if theirs.visible and VrGestureRules.meets(_last[side] / s, _vel[side], theirs.global_position / s,
							Vector3.ZERO) and _clock - _last_clap > VrGestureRules.CLAP_ONCE:
						claps += 1
						_clap((_last[side] + theirs.global_position) * 0.5)
		var id := p.get_instance_id()
		var theirs_now := VrGestureRules.claps_of(p.vr_pose)
		var seen := int(_remote_claps.get(id, theirs_now))
		_remote_claps[id] = theirs_now
		if theirs_now != seen and _clock - _last_clap > VrGestureRules.CLAP_ONCE:
			_clap(p.eye_position() - Vector3(0.0, 0.3, 0.0))   # their game heard a high-five with this child


## A clap: the sound, sparkles, both controllers buzz.
func _clap(at: Vector3) -> void:
	_last_clap = _clock
	clapped += 1
	Audio.play(&"pop", at)
	Audio.play(&"sparkle", at, -6.0)
	Fx.burst(get_tree().root, at, Color("ffd23f"), 14, 2.5, 0.08, 0.6, 3.0)
	for side: StringName in [VrRules.LEFT, VrRules.RIGHT]:
		Vr.haptic(side, float(CLAP_BUZZ[0]), float(CLAP_BUZZ[1]))


## Buddies within LOOK_RANGE look at the child's eyes (their pupils: Buddy.look_target).
func _eyes(head: Transform3D, s: float) -> void:
	var reach := VrGestureRules.LOOK_RANGE * s
	var now: Array[WeakRef] = []
	for n: Node in get_tree().get_nodes_in_group(&"buddies"):
		var b := n as Buddy
		if b == null:
			continue
		var near := b.is_inside_tree() and b.global_position.distance_to(head.origin) <= reach
		b.look_target = head.origin if near else Vector3.INF
		if near:
			now.append(weakref(b))
	_looking = now
