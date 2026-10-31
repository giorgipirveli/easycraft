class_name VrGrabber
extends Node3D
## Owner #110 (VR round 4, VR-HANDS; docs/devlog/parts/vr-r4-hands.md, the research's task 0 and rulings R1-R4): both
## hands take what holds a VrGrabbable (the frozen contract: entities/vr/vr_grabbable.gd), on VrGrabRules' numbers.
## Made by Vr for a session (Vr.grabber), stepped every frame after the controllers (VrInput asks claim / let_go when a
## grip goes down or up: the grip's two jobs, R1). Off VR it does not exist.
##
## - **Near:** a hand within NEAR_REACH of a thing's surface glows it (hovered, a soft tick); the grip takes it (grabbed;
##   the mitten closes by itself). A thing held by the other hand passes over, unless it is &"two_hand": then both hold
##   it, and their distance stretches it (VrGrabbable.stretch, the thing's scale).
## - **Far (R4, Alyx's three stages):** the pointing hand's laser glows a far_pull thing within FAR_RANGE; the grip locks
##   it (moving the hand keeps it); a flick of the wrist (towards the head or up, VrGrabRules.flick), or the grip held
##   PULL_HOLD, flies it to the hand (PULL_TIME, an arc: catchable). Let go before the pull: it stays.
## - **Held:** it follows the hand (hold_offset from the grip pose), kinematic (a RigidBody3D frozen); the trigger is its
##   `used` (0..1) and never the world's. **Let go (R3):** it flies at VrGrabRules.throw_velocity of the hand's last
##   samples (a RigidBody3D gets it), or drops (not throwable). **Over the shoulder:** no throw, and a thing whose node
##   has `vr_into_bag(side) -> bool` goes into the bag.
## - **Other grips** (the bricks of owner #116, the Build Table's edge, the model's turn): objects in `claimers`
##   (`grip_claim(side) -> bool`, `grip_release(side)`) are asked in order when no grabbable is near or under the laser.
## Distances are the child's metres (a world distance over Vr.world_scale(): a giant's hands reach as far as a child's).

enum { IDLE, HOLD, LOCK, PULL, CLAIMED }

const TICK := [0.12, 0.02]
const TAKE := [0.4, 0.05]
const LOCK_BUZZ := [0.25, 0.03]
const GLOW := Color(1.0, 0.9, 0.45, 0.28)
const GLOW_LOCKED := Color(0.55, 0.9, 1.0, 0.45)
const GLOW_MIN := 0.05

## Objects asked for a grip no grabbable takes (see above), in order.
var claimers: Array[Object] = []
## VrRules.LEFT / RIGHT -> Hand.
var hands := {}


class Hand:
	var side: StringName
	var state := IDLE
	var hover: VrGrabbable = null
	var hover_far := false
	var thing: VrGrabbable = null
	var claimer: Object = null
	var lock_t := 0.0
	var pull_t := 0.0
	var pull_from := Vector3.ZERO
	var keep_on_arrival := true
	var samples: Array = []
	var last_local := Vector3.INF
	var clock := 0.0
	var used := 0.0
	var glow: MeshInstance3D

	func _init(s: StringName) -> void:
		side = s


func _init() -> void:
	name = "VrGrabber"
	for side: StringName in [VrRules.LEFT, VrRules.RIGHT]:
		var h := Hand.new(side)
		h.glow = _glow_mesh()
		add_child(h.glow)
		hands[side] = h


static func _glow_mesh() -> MeshInstance3D:
	var m := MeshInstance3D.new()
	m.name = "Glow"
	var s := SphereMesh.new()
	s.radius = 1.0
	s.height = 2.0
	s.radial_segments = 16
	s.rings = 8
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.disable_receive_shadows = true
	mat.albedo_color = GLOW
	s.material = mat
	m.mesh = s
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	m.top_level = true
	m.visible = false
	return m


## The hand's state now (IDLE, HOLD, LOCK, PULL, CLAIMED).
func state(side: StringName) -> int:
	var h := hands.get(side) as Hand
	return h.state if h else IDLE


## What the hand holds (or has locked or is pulling), or null.
func held(side: StringName) -> VrGrabbable:
	var h := hands.get(side) as Hand
	return h.thing if h and h.state != IDLE and h.state != CLAIMED else null


## The hand holds, locks or pulls something, or a claimer has its grip: its trigger and laser are not the world's.
func busy(side: StringName) -> bool:
	var h := hands.get(side) as Hand
	return h != null and h.state != IDLE


## The child's metres in one world metre (1 / Vr.world_scale()).
static func _per_metre() -> float:
	return 1.0 / maxf(Vr.world_scale(), 0.001)


# --- The grip's press and release (VrInput) ---

## The grip went down: true when the grabber (or a claimer) takes it; false lets it step the hotbar as before (R1).
func claim(side: StringName) -> bool:
	var h := hands.get(side) as Hand
	if h == null or h.state != IDLE:
		return h != null and h.state != IDLE
	if h.hover != null and is_instance_valid(h.hover) and h.hover.takeable():
		if h.hover_far:
			_lock(h, h.hover)
		else:
			_take(h, h.hover)
		return true
	for c: Object in claimers:
		if is_instance_valid(c) and bool(c.call(&"grip_claim", side)):
			h.state = CLAIMED
			h.claimer = c
			_set_hover(h, null, false)
			return true
	return false


## The grip went up (only after claim said true).
func let_go(side: StringName) -> void:
	var h := hands.get(side) as Hand
	if h == null:
		return
	match h.state:
		HOLD:
			_release(h)
		LOCK:
			_unlock(h)
		PULL:
			h.keep_on_arrival = false
		CLAIMED:
			var c := h.claimer
			h.state = IDLE
			h.claimer = null
			if is_instance_valid(c):
				c.call(&"grip_release", side)


# --- VR-WONDER's two additions (owner #110, round 4 idea 2; docs/devlog/parts/vr-r4-wonder.md): a thing that comes
# into a hand without a grip (the hotbar's lens, VrLens) and goes out of it the same way ---

## Puts `g` in hand `side` as a grip would (grabbed, held: it follows the hand, its trigger is `used`, the hand's laser
## is off); false when that hand is busy or `g` can't be taken now.
func give(side: StringName, g: VrGrabbable) -> bool:
	var h := hands.get(side) as Hand
	if h == null or h.state != IDLE or g == null or not g.takeable():
		return false
	_take(h, g)
	return true


## Lets go of `g` from the hand that holds, locks or pulls it, quietly (no throw, no bag); the hand is free at once.
func take_back(g: VrGrabbable) -> void:
	for h: Hand in hands.values():
		if h.thing == g and h.state != IDLE and h.state != CLAIMED:
			if h.state == HOLD:
				_release(h, true)
			else:
				h.state = IDLE
				h.thing = null


## Lets go of everything at once (the session ends): no throws.
func drop_all() -> void:
	for h: Hand in hands.values():
		if h.state == HOLD or h.state == PULL or h.state == LOCK:
			_set_holder(h.thing, h.side, false)
			if is_instance_valid(h.thing):
				_thaw(h.thing, Vector3.ZERO)
				h.thing.released.emit(h.side, Vector3.ZERO)
		elif h.state == CLAIMED and is_instance_valid(h.claimer):
			h.claimer.call(&"grip_cancel" if h.claimer.has_method(&"grip_cancel") else &"grip_release", h.side)
		h.state = IDLE
		h.thing = null
		h.claimer = null
		_set_hover(h, null, false)

# --- Every frame ---

## One frame (Vr.step, after VrInput): the samples, the hovers, the locks and pulls, the held things and their glow.
func step(delta: float) -> void:
	if Vr.rig == null:
		return
	_attach_world_things(delta)
	for h: Hand in hands.values():
		_sample(h, delta)
		if h.thing != null and not is_instance_valid(h.thing):
			h.thing = null
			h.state = IDLE
		match h.state:
			IDLE:
				_hover(h)
			LOCK:
				_step_lock(h, delta)
			PULL:
				_step_pull(h, delta)
			HOLD:
				_step_hold(h)
		_show_glow(h)
	VrLens.keep_in_hand(self, delta)   # VR-WONDER (owner #110, idea 2): the hotbar's telescope or magnifier is in the hand


## The hand's velocity in the play space (the child's metres a second: walking never counts), kept for the throw and
## the flick.
func _sample(h: Hand, delta: float) -> void:
	h.clock += delta
	var local := Vr.rig.global_transform.affine_inverse() * Vr.hand_grip(h.side).origin * _per_metre()
	if h.last_local.is_finite() and delta > 0.0:
		VrGrabRules.add_sample(h.samples, h.clock, (local - h.last_local) / delta)
	h.last_local = local


func _hover(h: Hand) -> void:
	var grip := Vr.hand_grip(h.side)
	var s := _per_metre()
	var near: Array = []
	var list: Array[VrGrabbable] = []
	for n: Node in get_tree().get_nodes_in_group(VrGrabbable.GROUP):
		var g := n as VrGrabbable
		if g == null or not g.takeable() or not _free_for(g, h.side):
			continue
		list.append(g)
		near.append({"pos": g.global_position * s, "radius": g.radius * s})
	var i := VrGrabRules.near_pick(Transform3D(grip.basis, grip.origin * s), near)
	if i >= 0:
		_set_hover(h, list[i], false)
		return
	if h.side == Vr.pointing_hand() and not Vr.ui_wants_pointer():
		var ray := Vr.hand_ray(h.side)
		if ray.size() == 2:
			var far: Array = []
			var far_list: Array[VrGrabbable] = []
			for g: VrGrabbable in list:
				if g.far_pull and g.held_by() == &"" and _in_sight(ray[0], g.global_position):
					far_list.append(g)
					far.append({"pos": g.global_position * s, "radius": g.radius * s})
			var j := VrGrabRules.far_pick((ray[0] as Vector3) * s, ray[1], far)
			if j >= 0:
				_set_hover(h, far_list[j], true)
				return
	_set_hover(h, null, false)


## Another hand's thing passes over to this one (a &"two_hand" one is shared).
func _free_for(g: VrGrabbable, side: StringName) -> bool:
	var who := g.held_by()
	return who == &"" or (who != side and who != &"both")


## No block between the laser's hand and the thing (the world's voxels: no physics query).
func _in_sight(from: Vector3, to: Vector3) -> bool:
	var player := Vr.local_player()
	if player == null or player.world == null:
		return true
	var d := to - from
	return player.world.raycast(from, d.normalized(), maxf(d.length() - 0.3 * Vr.world_scale(), 0.0)) == null


func _set_hover(h: Hand, g: VrGrabbable, far: bool) -> void:
	if g == h.hover and far == h.hover_far:
		return
	if h.hover != null and is_instance_valid(h.hover):
		h.hover.hovered.emit(h.side, false)
	h.hover = g
	h.hover_far = far
	if g != null:
		g.hovered.emit(h.side, true)
		Vr.haptic(h.side, float(TICK[0]), float(TICK[1]))


func _take(h: Hand, g: VrGrabbable) -> void:
	var other := hands[VrRules.LEFT if h.side == VrRules.RIGHT else VrRules.RIGHT] as Hand
	var shared := other.thing == g and (other.state == HOLD) and g.kind == &"two_hand"
	if other.thing == g and not shared:
		_release(other, true)   # passed from hand to hand: the other lets go without a throw
	_set_hover(h, null, false)
	h.thing = g
	h.state = HOLD
	h.used = 0.0
	if shared:
		g.holder = &"both"
		g.set_meta(&"_vr_apart", _apart())
		g.set_meta(&"_vr_base", g.thing().scale / maxf(g.stretch, 0.001))
	else:
		g.holder = h.side
		g.stretch = 1.0
	_freeze(g)
	g.grabbed.emit(h.side)
	Vr.haptic(h.side, float(TAKE[0]), float(TAKE[1]))


func _lock(h: Hand, g: VrGrabbable) -> void:
	h.thing = g
	h.state = LOCK
	h.lock_t = 0.0
	h.keep_on_arrival = true
	Vr.haptic(h.side, float(LOCK_BUZZ[0]), float(LOCK_BUZZ[1]))


func _unlock(h: Hand) -> void:
	h.state = IDLE
	h.thing = null


func _step_lock(h: Hand, delta: float) -> void:
	if not is_instance_valid(h.thing) or not h.thing.takeable() or h.thing.held_by() != &"":
		_unlock(h)
		return
	h.lock_t += delta
	var to_head := Vr.rig.global_transform.affine_inverse() * Vr.head_transform().origin * _per_metre() - h.last_local
	if h.lock_t >= VrGrabRules.PULL_HOLD or VrGrabRules.flick(h.samples, to_head):
		h.state = PULL
		h.pull_t = 0.0
		var t := h.thing.thing()
		h.pull_from = t.global_position if t else h.thing.global_position
		Vr.haptic(h.side, float(LOCK_BUZZ[0]), float(LOCK_BUZZ[1]))


func _step_pull(h: Hand, delta: float) -> void:
	if not is_instance_valid(h.thing):
		h.state = IDLE
		h.thing = null
		return
	h.pull_t += delta / VrGrabRules.PULL_TIME
	var at := Vr.hand_grip(h.side) * h.thing.hold_offset.origin
	var t := h.thing.thing()
	if h.thing.follows_hand and t != null:
		t.global_position = VrGrabRules.pull_point(h.pull_from, at, h.pull_t)
	if h.pull_t < 1.0:
		return
	var g := h.thing
	_take(h, g)
	if not h.keep_on_arrival:
		_release(h)


func _step_hold(h: Hand) -> void:
	var g := h.thing
	var t := g.thing()
	var amount := Vr.trigger(h.side)
	if absf(amount - h.used) > 0.01 or (amount == 0.0 and h.used != 0.0):
		h.used = amount
		g.used.emit(h.side, amount)
	if not g.follows_hand or t == null:
		return
	if g.held_by() == &"both":
		if h.side != VrRules.RIGHT:
			return   # one hand places a shared thing
		var apart := _apart()
		g.stretch = VrGrabRules.stretch(float(g.get_meta(&"_vr_apart", apart)), apart)
		var mid := (Vr.hand_grip(VrRules.LEFT).origin + Vr.hand_grip(VrRules.RIGHT).origin) * 0.5
		t.global_position = mid
		t.scale = (g.get_meta(&"_vr_base", t.scale) as Vector3) * g.stretch
		return
	var x := Vr.hand_grip(h.side) * g.hold_offset
	t.global_transform = Transform3D(x.basis.orthonormalized() * Basis.from_scale(t.scale), x.origin)   # its own size kept


func _apart() -> float:
	return Vr.hand_grip(VrRules.LEFT).origin.distance_to(Vr.hand_grip(VrRules.RIGHT).origin) * _per_metre()


## Lets go of what the hand holds: a throw (R3), a drop, or into the bag over the shoulder. `quiet`: passed to the other
## hand (no throw, no bag).
func _release(h: Hand, quiet: bool = false) -> void:
	var g := h.thing
	h.state = IDLE
	h.thing = null
	if g == null or not is_instance_valid(g):
		return
	var other := hands[VrRules.LEFT if h.side == VrRules.RIGHT else VrRules.RIGHT] as Hand
	var still := other.thing == g and other.state == HOLD and not quiet
	_set_holder(g, h.side, still)
	if still:
		g.released.emit(h.side, Vector3.ZERO)
		return
	var bag := not quiet and _over_shoulder(h)
	var v := Vector3.ZERO
	if not quiet and not bag and g.throwable:
		v = Vr.rig.global_basis * VrGrabRules.throw_velocity(h.samples) * Vr.world_scale()
	_thaw(g, v)
	g.released.emit(h.side, v)
	var t := g.thing()
	if bag and is_instance_valid(t) and t.has_method(&"vr_into_bag"):
		t.call(&"vr_into_bag", h.side)


func _set_holder(g: VrGrabbable, side: StringName, other_keeps: bool) -> void:
	if not is_instance_valid(g):
		return
	if other_keeps:
		g.holder = VrRules.LEFT if side == VrRules.RIGHT else VrRules.RIGHT   # the shape stays as stretched
	else:
		g.holder = &""


func _over_shoulder(h: Hand) -> bool:
	var inv := Vr.rig.global_transform.affine_inverse()
	var s := _per_metre()
	var head := inv * Vr.head_transform()
	return VrGrabRules.over_shoulder(Transform3D(head.basis, head.origin * s), (inv * Vr.hand_grip(h.side).origin) * s)


## A held RigidBody3D is kinematic.
static func _freeze(g: VrGrabbable) -> void:
	var b := g.thing() as RigidBody3D
	if b != null:
		b.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
		b.freeze = true


## Let go: a RigidBody3D is physics again, flying at `v`.
static func _thaw(g: VrGrabbable, v: Vector3) -> void:
	var b := g.thing() as RigidBody3D
	if b != null:
		b.freeze = false
		b.linear_velocity = v
		b.sleeping = false


# --- The world's own things a hand takes (owner #110): pickup bags ---

const ATTACH_EVERY := 0.5
const BAG_RADIUS := 0.35
var _attach_t := 0.0
var _attached: Array[WeakRef] = []


## Every half second: a pickup bag (M2 Task 2) gets a grabbable while VR runs. Grabbed (near, or pulled in by the
## laser) it asks the host for it, as a tap does (Session.request_take_bag: whose it is, its reach); it never moves on
## this game alone (the host keeps where it lies).
func _attach_world_things(delta: float) -> void:
	_attach_t -= delta
	if _attach_t > 0.0:
		return
	_attach_t = ATTACH_EVERY
	for n: Node in get_tree().get_nodes_in_group(&"bags"):
		var bag := n as PickupBag
		if bag == null or bag.is_queued_for_deletion() or bag.has_node(^"VrGrabbable"):
			continue
		var g := VrGrabbable.new()
		g.name = "VrGrabbable"
		g.position = Vector3(0.0, 0.3, 0.0)
		g.radius = BAG_RADIUS
		g.throwable = false
		g.follows_hand = false
		var bag_name := String(bag.name)
		g.grabbed.connect(func(_side: StringName) -> void: Session.request_take_bag(bag_name))
		bag.add_child(g)
		_attached.append(weakref(g))


func _exit_tree() -> void:
	for w: WeakRef in _attached:
		var g := w.get_ref() as VrGrabbable
		if g != null and is_instance_valid(g):
			g.queue_free()   # off VR a bag is a tap's again, nothing more
	_attached.clear()


func _show_glow(h: Hand) -> void:
	var g: VrGrabbable = h.hover if h.state == IDLE else (h.thing if h.state == LOCK else null)
	var on := g != null and is_instance_valid(g) and g.is_inside_tree()
	h.glow.visible = on
	if not on:
		return
	var r := maxf(g.radius, GLOW_MIN * Vr.world_scale()) * 1.25
	h.glow.global_transform = Transform3D(Basis.from_scale(Vector3.ONE * r), g.global_position)
	((h.glow.mesh as SphereMesh).material as StandardMaterial3D).albedo_color = \
		GLOW_LOCKED if h.state == LOCK else GLOW
