class_name LeafVrHands
extends RefCounted
## Owner #133, #134 (docs/design/games/leaf-voyage.md §3.7 VR, §4.4 VR; the lead's review 5; the B2 brief): a voyage in a
## headset, for LeafVoyageHost. The child stands at each place's stand (the rig follows `host.stand`); the HUD is the
## raised forearm's panel (owner #127, PlayHud in VR); snap turns are Vr's own.
## - The garden: a squeeze at the can lifts it (it follows the hand), tilted over the soil it pours (POUR_HOLD s); a hand
##   on the leaf (the cactus's stem) starts the dive (the host grows the garden round the feet).
## - Inside: swimming (a grip squeezed away from anything and pulled: the body moves the other way, LeafSwimRules; thick
##   air stops it when no hand pulls), the laser grapple (the pointing hand's trigger on a door, a pipe or a sugar: a
##   GRAPPLE s glide to its stand; a blink instead for a child whose comfort choice is the strong vignette), doors (both
##   hands on its two guard cells: squeezed together it shuts, pulled apart it opens; one hand's trigger on a door toggles
##   it), sugar (a hand takes a waiting hexagon, it follows the hand, let go at the gold pipe's mouth it whooshes away;
##   at the blue pipe it bobs back); Professor Hoot flies at the child's shoulder.

const GRAB_REACH := 0.3
const PIPE_REACH := 0.3
const POUR_HOLD := 0.6
const GRAPPLE := PlayHost.GLIDE
## A door's two guard cells held: closer by this (m) shuts it, further apart by this opens it.
const SQUEEZE_SHUT := 0.06
const PULL_OPEN := 0.15
const BODY_RADIUS := 0.35
## The can held by its handle: its spout along the hand's forward (tilt the hand down to pour).
const CAN_IN_HAND := Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(0.1, -0.2, 0.0))

var host: LeafVoyageHost
var velocity := Vector3.ZERO
var hoot: Node3D
## What the hands show (a sugar held, Hoot at the shoulder), under the host.
var holder: Node3D

var _grip := {}
var _trig := {}
var _rel := {}
var _held := {}
var _gaps := {}
var _pour := 0.0
var _grapple_from := Vector3.ZERO
var _grapple_to := Vector3.ZERO
var _grapple_t := -1.0
var _sugars := {}


func _init(voyage_host: LeafVoyageHost) -> void:
	host = voyage_host
	holder = Node3D.new()
	holder.name = "VrHands"
	host.add_child(holder)


func step(dt: float) -> void:
	match host.journey.stage:
		LeafJourney.HOOK:
			_garden(dt)
		LeafJourney.INSIDE:
			_leaf(dt)
	_laser()
	_follow_hoot()
	for side: StringName in [VrRules.LEFT, VrRules.RIGHT]:
		_grip[side] = _grip_on(side)
		_trig[side] = Vr.trigger(side) >= PlayHost.SQUEEZE_ON
		_rel[side] = _hand_local(side)


func release() -> void:
	for side: Variant in _sugars:
		if is_instance_valid(_sugars[side]):
			(_sugars[side] as Node).queue_free()
	_sugars.clear()


## The swim's speed now (m/s), for the tests and the vignette.
func speed() -> float:
	return velocity.length()


# --- The garden ----------------------------------------------------------------------------------------------------

func _garden(dt: float) -> void:
	var g := host.garden
	for side: StringName in [VrRules.LEFT, VrRules.RIGHT]:
		var hand := Vr.hand_grip(side)
		var on := _grip_on(side)
		var was := bool(_grip.get(side, false))
		if on and not was and g.has_target("can") and not host.journey.watered \
				and hand.origin.distance_to(g.target_position("can")) <= g.target_radius("can") + GRAB_REACH:
			_held[side] = "can"
			host._buzz(0.35, 0.05)
		elif not on and was and str(_held.get(side, "")) == "can":
			_held.erase(side)
			g.can_home()
			_pour = 0.0
		if str(_held.get(side, "")) == "can":
			g.can_node().global_transform = hand * CAN_IN_HAND
			_pour = _pour + dt if g.can_pours_on_soil() else 0.0
			if _pour >= POUR_HOLD and not host.journey.watered:
				host.water_now()
				host._buzz(0.5, 0.1)
		if g.has_target("leaf") and hand.origin.distance_to(g.target_position("leaf")) <= g.target_radius("leaf") + 0.08:
			host.tap_target("leaf")


# --- Inside the leaf -----------------------------------------------------------------------------------------------

func _leaf(dt: float) -> void:
	var place := host.place
	var run := host.journey.run
	var pulls: Array[Vector3] = []
	var on_beans := {}
	for side: StringName in [VrRules.LEFT, VrRules.RIGHT]:
		var hand := Vr.hand_grip(side).origin
		var rel := _hand_local(side)
		var on := _grip_on(side)
		var was := bool(_grip.get(side, false))
		var trig := Vr.trigger(side) >= PlayHost.SQUEEZE_ON
		if on and not was:
			var spot := _sugar_near(hand)
			var bean := _near(hand, true)
			if spot >= 0 and run.carried() < LeafAvatar.MAX_CARRY and run.take():
				place.take_sugar(spot)
				_held[side] = "sugar"
				host._buzz(0.35, 0.05)
			elif bean != "":
				_held[side] = bean
			elif run.carried() > 0 and _at_pipe(hand) != "":
				_held[side] = "sugar"   # a carried sugar back in the hand, at the pipe
			else:
				_held[side] = "swim"
		elif not on and was:
			if str(_held.get(side, "")) == "sugar":
				_let_go(side, hand)
			_held.erase(side)
		var held := str(_held.get(side, ""))
		if on and held == "swim" and _rel.has(side) and dt > 0.0:
			pulls.append(_body_basis() * (rel - (_rel[side] as Vector3)) / dt)
		if on and held.begins_with("door_"):
			var d := int(held.get_slice("_", 1))
			var sides: Array = on_beans.get(d, [])
			sides.append(side)
			on_beans[d] = sides
		if trig and not bool(_trig.get(side, false)) and not on:
			var door := _near(hand, false)
			if door != "":
				run.toggle(int(door.get_slice("_", 1)))
				host._buzz(0.4, 0.06)
		_show_sugar(side, held == "sugar", hand)
	_doors(on_beans)
	_swim(pulls, dt)
	if _grapple_t >= 0.0:
		_grapple_t += dt
		var k := smoothstep(0.0, 1.0, clampf(_grapple_t / GRAPPLE, 0.0, 1.0))
		host.stand.global_position = _grapple_from.lerp(_grapple_to, k)
		if _grapple_t >= GRAPPLE:
			_grapple_t = -1.0


func _doors(on_beans: Dictionary) -> void:
	var run := host.journey.run
	for d: Variant in _gaps.keys():
		if not on_beans.has(d) or (on_beans[d] as Array).size() < 2:
			_gaps.erase(d)
	for d: Variant in on_beans:
		if (on_beans[d] as Array).size() < 2:
			continue
		var gap := Vr.hand_grip(VrRules.LEFT).origin.distance_to(Vr.hand_grip(VrRules.RIGHT).origin)
		if not _gaps.has(d):
			_gaps[d] = gap
		var start := float(_gaps[d])
		var i := int(d)
		if run.sim.doors[i] and gap <= start - SQUEEZE_SHUT:
			run.toggle(i)
			_gaps[d] = gap
			host._buzz(0.5, 0.08)
		elif not run.sim.doors[i] and gap >= start + PULL_OPEN:
			run.toggle(i)
			_gaps[d] = gap
			host._buzz(0.5, 0.08)


func _swim(pulls: Array[Vector3], dt: float) -> void:
	velocity = LeafSwimRules.step(velocity, pulls, dt)
	if velocity.length() < 0.001 or _grapple_t >= 0.0:
		return
	var place := host.place
	var p := host.stand.global_position + velocity * dt
	var free := place.space.push_out(place.to_local(p), BODY_RADIUS)
	host.stand.global_position = place.to_global(free)


func _let_go(side: StringName, hand: Vector3) -> void:
	var pipe := _at_pipe(hand)
	if pipe != "" and host.journey.run.deliver(pipe):
		host._buzz(0.6, 0.12)
	elif pipe == "blue":
		host.journey.run.deliver("blue")   # it bobs back: still carried
	_held.erase(side)


## The pipe whose mouth the hand is at ("gold", "blue" or "").
func _at_pipe(hand: Vector3) -> String:
	var place := host.place
	for pipe: Array in [["gold_pipe", "gold"], ["blue_pipe", "blue"]]:
		if hand.distance_to(place.target_position(str(pipe[0]))) <= PIPE_REACH + 0.25:
			return str(pipe[1])
	return ""


## The waiting sugar's spot a hand is at (-1 none).
func _sugar_near(hand: Vector3) -> int:
	for k: int in host.place.waiting_spots():
		var t := "sugar_%d" % k
		if hand.distance_to(host.place.target_position(t)) <= host.place.target_radius(t):
			return k
	return -1


## The guard cell (`beans`: "door_i_a"/"_b") or the door ("door_i") a hand touches ("" none).
func _near(hand: Vector3, beans: bool) -> String:
	var place := host.place
	var best := ""
	var best_d := INF
	for t: String in place.target_names():
		if not t.begins_with("door_"):
			continue
		var is_bean := t.ends_with("_a") or t.ends_with("_b")
		if is_bean != beans:
			continue
		var d := hand.distance_to(place.target_position(t))
		if d <= place.target_radius(t) and d < best_d:
			best_d = d
			best = t
	return best


# --- The laser: the garden's taps, the grapple inside ----------------------------------------------------------------

func _laser() -> void:
	var ray := Vr.pointer_ray()
	var side := Vr.pointing_hand()
	var pressed := Vr.trigger_pressed(side)
	var was := bool(_trig.get(&"laser", false))
	_trig[&"laser"] = pressed
	var r := host.room()
	if ray.is_empty() or Vr.ui_wants_pointer() or r == null or str(_held.get(side, "")) != "":
		if host.beam:
			host.beam.visible = false
		return
	var pointed := ""
	var best := INF
	for t: String in _laser_targets():
		if not r.has_target(t):
			continue
		var d := LifeReach.ray_hit(ray[0], ray[1], r.target_position(t), r.target_radius(t))
		if d >= 0.0 and d < best and d <= PlayHost.LASER:
			best = d
			pointed = t
	host._show_beam(ray, best if pointed != "" else PlayHost.LASER)
	if pointed == "" or not pressed or was:
		return
	if host.journey.stage == LeafJourney.INSIDE:
		grapple_to(pointed)
	else:
		host.tap_target(pointed)
	host._buzz(0.35, 0.05)


func _laser_targets() -> Array[String]:
	var out: Array[String] = []
	match host.journey.stage:
		LeafJourney.HOOK:
			out = host.garden.flat_targets(LeafGarden.GARDEN)
		LeafJourney.INSIDE:
			for t: String in host.place.flat_targets(LeafPlace.WORK):
				if not t.begins_with("sugar_"):
					out.append(t)
			for k: int in host.place.waiting_spots():
				out.append("sugar_%d" % k)
	return out


## The laser grapple: a GRAPPLE s glide to the thing's stand (a blink for the strong-vignette comfort choice).
func grapple_to(t: String) -> void:
	var place := host.place
	var view := LeafVoyageHost._view_of(t)
	if not place.views.has(view):
		return
	var to := place.vr_stand(view).origin
	if str(Vr.setting(VrRules.VIGNETTE)) == "strong":
		host.stand.global_position = to
		Vr.blink()
		return
	velocity = Vector3.ZERO
	_grapple_from = host.stand.global_position
	_grapple_to = to
	_grapple_t = 0.0


func grappling() -> bool:
	return _grapple_t >= 0.0


# --- Showing -------------------------------------------------------------------------------------------------------

## A hand in the body's own space (the rig's): it moves only when the hand moves, whatever the body does.
func _hand_local(side: StringName) -> Vector3:
	if Vr.rig != null:
		return Vr.rig.global_transform.affine_inverse() * Vr.hand_grip(side).origin
	return Vr.hand_grip(side).origin - host.stand.global_position


func _body_basis() -> Basis:
	return Vr.rig.global_basis if Vr.rig != null else Basis()


func _grip_on(side: StringName) -> bool:
	var g := Vr.grip(side)
	return g >= PlayHost.SQUEEZE_ON or (bool(_grip.get(side, false)) and g > PlayHost.SQUEEZE_OFF)


func _show_sugar(side: StringName, on: bool, hand: Vector3) -> void:
	if not on:
		if _sugars.has(side) and is_instance_valid(_sugars[side]):
			(_sugars[side] as Node3D).visible = false
		return
	if not _sugars.has(side) or not is_instance_valid(_sugars[side]):
		var m := LeafKit.Mesher.new()
		m.hexagon(Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3.ZERO), 0.11, 0.05, Color("ffe47a"), Color("f0b830"))
		_sugars[side] = LeafKit.mesh(holder, "HeldSugar", m.commit(), LeafKit.glow())
	var s: Node3D = _sugars[side]
	s.visible = true
	s.global_position = hand


## Professor Hoot flies at the child's shoulder while they are tiny (inside the leaf).
func _follow_hoot() -> void:
	var inside := host.journey.stage == LeafJourney.INSIDE
	if hoot == null and inside:
		hoot = LeafKit.hoot(holder, Vector3.ZERO, 0.0, 0.32)
	if hoot == null:
		return
	hoot.visible = inside
	if inside:
		var head := Vr.head_transform()
		hoot.global_position = head * Vector3(0.38, -0.12, -0.35)
		var to_eye := head.origin - hoot.global_position
		hoot.rotation.y = atan2(to_eye.x, to_eye.z) + PI
