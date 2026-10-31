class_name AvatarModel
extends Node3D
## A player's body model (M1b Task 13): BlockyAvatar in the BLOCKY style, RealisticAvatar in the
## REALISTIC style. Player swaps them with set_avatar_style(). Every model faces -Z (the player's
## forward), stands with its feet at y = 0, is 1.8 blocks tall at scale 1, and is scaled as a whole
## by Size Magic.

const POSE_STAND := &"stand"
const POSE_SLEEP := &"sleep"
const POSE_SWIM := &"swim"     # M2 Task 14: swimming; swim() animates it

var pose: StringName = POSE_STAND
## Swimming: how far the body is tipped forward from upright (rad), see _tip().
var swim_tilt := 0.0


## Called every physics frame with the horizontal speed in m/s. `on_floor` is also true while flying.
func animate(_horizontal_speed: float, _on_floor: bool, _delta: float) -> void:
	pass


## 1 = the jump from the ground; 2 and 3 = air jumps (these flip).
func play_jump(_index: int) -> void:
	pass


## Held items attach here, at the right hand. Its -Y runs along the arm to the fingertips and its -Z
## points forward (where the body faces when the arm hangs down). It has the body's scale, so items
## grow with Size Magic.
func hand() -> Node3D:
	return self


## The node that flips on air jumps and lies down to sleep (the whole visible body).
func body_pivot() -> Node3D:
	return self


## POSE_STAND, POSE_SLEEP (lying on the back, face up, head towards +Z) or POSE_SWIM.
func set_pose(new_pose: StringName) -> void:
	if new_pose != POSE_STAND:
		stop_emote(true)   # no dancing in bed or in the water (M3 Task 9)
	pose = new_pose
	swim_tilt = 0.0


## Called every physics frame while swimming (POSE_SWIM), instead of animate(), with the body's speed
## through the water (m/s; vertical > 0 rises). The body tips with the swim direction
## (SwimRules.body_tilt): upright treading water with the arms sculling out to the sides, flat along
## the surface with crawl strokes and kicking legs, head first when diving (M2 Task 14).
func swim(_horizontal_speed: float, _vertical_speed: float, _delta: float) -> void:
	pass


const SWIM_PIVOT_Y := 1.2       # swimming flat: the body along the surface (SwimRules.FLOAT_DEPTH), the head out
const SWIM_TILT_RATE := 6.0
const SWIM_CRAWL_FROM := 2.0    # m/s at which the strokes are a full crawl (slower blends into treading water)


## Both styles: tips `pivot` (the body, standing at standing_y) towards the swim direction; lying flat
## it rises to the surface.
func _tip(pivot: Node3D, standing_y: float, horizontal_speed: float, vertical_speed: float, delta: float) -> void:
	var w := clampf(SWIM_TILT_RATE * delta, 0.0, 1.0)
	swim_tilt = lerpf(swim_tilt, SwimRules.body_tilt(horizontal_speed, vertical_speed), w)
	pivot.rotation.x = -swim_tilt
	pivot.position.y = lerpf(standing_y, SWIM_PIVOT_Y, sin(swim_tilt))

# --- Looks, emotes and celebrations (M3 Task 9) ---------------------------------------------------

## The realistic person's head and back are smaller than the blocky body's: box parts built for the
## blocky body are worn at these scales there.
const REALISTIC_HEAD_SCALE := 0.85
const REALISTIC_BACK_SCALE := 0.7
## Sitting lowers the body this far (both bodies' legs are about 0.64 long).
const SIT_DROP := 0.5
const EMOTE_BLEND := 0.18      # s to blend an emote in or out

var _look := AvatarLook.new()
var _look_applied := false
var _parts: Array[Node3D] = []
var _cape: Node3D
var _wings: Node3D
var _trail: AvatarTrail
var _part_t := 0.0
var _emote := &""
var _emote_shown := &""        # the emote being blended (in, or out after it ended)
var _emote_t := 0.0
var _emote_w := 0.0


## Wears `new_look` (a copy is kept): colours and parts in this body's style.
func apply_look(new_look: AvatarLook) -> void:
	_look = new_look.duplicate()
	_look_applied = true
	if is_node_ready():
		_dress(_resolved())


func look() -> AvatarLook:
	return _look


## Where head parts go (the head's centre), back parts (between the shoulders), hip parts (the tail)
## and body parts (the blocky torso's centre; none on the realistic person).
func head_anchor() -> Node3D:
	return self


## Face pieces (the blocky face, sunglasses, an eyepatch, the ninja mask): at the eyes.
func face_anchor() -> Node3D:
	return head_anchor()


func back_anchor() -> Node3D:
	return self


func hip_anchor() -> Node3D:
	return self


func body_anchor() -> Node3D:
	return null


## Owner 48: where skirts hang (the blocky torso's centre; the realistic person's hips).
func waist_anchor() -> Node3D:
	return body_anchor()


## The look as this body draws it (AvatarLook.resolve); a bot friend wears it in its own colours.
func _resolved() -> Dictionary:
	return _look.resolve()


func trail() -> AvatarTrail:
	return _trail


## Colours the body itself (skin, shirt, pants, shoes) for a resolved look.
func _color_body(_r: Dictionary) -> void:
	pass


## Sizes a part that wraps the whole head (a helmet) to this body's head.
func _fit_cover(_part: Node3D) -> void:
	pass


## True for the blocky body, which builds hair, faces and torso pieces from boxes.
func _builds_everything() -> bool:
	return false


func _dress(r: Dictionary) -> void:
	_color_body(r)
	for p in _parts:
		if is_instance_valid(p):
			p.free()   # at once: plain meshes nothing refers to (no orphans waiting for the frame's end)
	_parts.clear()
	_cape = null
	_wings = null
	var colors := {"hair": r.hair_color, "skin": r.skin, "shirt": r.shirt, "pants": r.pants, "shoes": r.shoes,
		"top": r.get("top", r.shirt), "bottom": r.get("bottom", r.pants)}
	var boxy := _builds_everything()
	if r.hair != &"none" and not r.hides_hair:
		_attach(_part_id("hair_%s" % r.hair, boxy), colors)   # the realistic person: only its "_real" hair shapes
	if boxy:
		_attach("face_%s" % r.face, colors)
	elif r.face == &"cool":
		_attach("extra_sunglasses", colors)
	elif AvatarParts.has_part("face_%s_real" % r.face):
		_attach("face_%s_real" % r.face, colors)   # Owner 36: a painted face's add-ons (Pinocchio's nose, a beard)
	if r.hat != &"none":
		_attach(_part_id("hat_%s" % r.hat, boxy), colors)
	if r.cape != &"none":
		_attach(_part_id("cape_%s" % r.cape, boxy), colors)   # Owner 36: a back piece may have its "_real" recipe
	if r.wings != &"none":
		_attach("wings_%s" % r.wings, colors)
	_dress_builds(r)   # M3 Task 8: the child's own built hat, backpack and wings
	if r.outfit == &"none" and body_anchor():   # Owner 43: the buddy badge on the chest (a full outfit hides it)
		var badge := BuddyBadge.build(not boxy)
		body_anchor().add_child(badge)
		_parts.append(badge)
	for e: StringName in r.extras:
		var id := _part_id("extra_%s" % e, boxy)
		if id != "" and not (AvatarParts.sway_of(id) == &"cape" and _cape):
			_attach(id, colors)
	if r.trail == &"none":
		if _trail:
			_trail.free()
			_trail = null
	else:
		if _trail == null:
			_trail = AvatarTrail.new()
			add_child(_trail)
		_trail.setup(r.trail)


## Owner 48: the part this body wears for `id`: the realistic person wears "<id>_real" where there is one
## and never a blocky-only part ("" = none).
func _part_id(id: String, boxy: bool) -> String:
	if boxy:
		return id
	if AvatarParts.has_part(id + "_real"):
		return id + "_real"
	return "" if AvatarParts.blocky_only(id) else id


func _attach(id: String, colors: Dictionary) -> Node3D:
	if id == "":
		return null
	var anchor: Node3D
	match AvatarParts.anchor_of(id):
		AvatarParts.BACK:
			anchor = back_anchor()
		AvatarParts.HIP:
			anchor = hip_anchor()
		AvatarParts.BODY:
			anchor = body_anchor()
		AvatarParts.WAIST:
			anchor = waist_anchor()
		AvatarParts.FACE:
			anchor = face_anchor()
		_:
			anchor = head_anchor()
	if anchor == null:
		return null
	var part := AvatarParts.build(id, colors)
	if part == null:
		return null
	if AvatarParts.covers(id):
		_fit_cover(part)
	if not _builds_everything():
		part.position += AvatarParts.real_offset(id)   # Owner 36: hats sit lower on the realistic head
	anchor.add_child(part)
	_parts.append(part)
	match AvatarParts.sway_of(id):
		&"cape":
			_cape = part
		&"wings":
			_wings = part
	return part


## Every frame: the cape flutters back as the body runs, wings flap (faster in the air), the trail
## follows the ground speed.
func _dress_tick(speed: float, on_floor: bool, delta: float) -> void:
	_part_t += delta
	if _cape:
		var lift := -(0.08 + 0.55 * clampf(speed / 6.0, 0.0, 1.0)) + 0.04 * sin(_part_t * 3.0)
		_cape.rotation.x = lerpf(_cape.rotation.x, lift, clampf(8.0 * delta, 0.0, 1.0))
	if _wings:
		var flap := (0.12 if on_floor else 0.4) * sin(_part_t * (3.0 if on_floor else 10.0))
		(_wings.get_node("R") as Node3D).rotation.y = -0.35 + flap
		(_wings.get_node("L") as Node3D).rotation.y = 0.35 - flap
	if _trail:
		_trail.update(speed, on_floor)


## Starts an emote or dance (EmotePoses); false for an unknown one. Moving, jumping, sleeping or
## swimming ends it (in every game: remote bodies stop when their synced speed does).
func play_emote(emote_name: StringName) -> bool:
	if not EmotePoses.has(emote_name) or pose != POSE_STAND:
		return false
	_emote = emote_name
	_emote_shown = emote_name
	_emote_t = 0.0
	return true


## Ends the emote; `snap` drops it at once (a jump or an attack takes over the body).
func stop_emote(snap: bool = false) -> void:
	_emote = &""
	if snap and _emote_w > 0.0:
		_emote_w = 0.0
		_emote_shown = &""
		_show_emote({}, 0.0)


## The emote playing now (&"" when none).
func emote() -> StringName:
	return _emote


## Advances the emote clock and blend (once per frame, from animate()); returns the pose to show, or
## {} when no emote shows, and the blend weight in `_emote_w`.
func _emote_step(horizontal_speed: float, delta: float, on_floor: bool = true) -> Dictionary:
	if _emote != &"":
		if EmotePoses.stops_at(horizontal_speed) or not on_floor:
			_emote = &""
		else:
			_emote_t += delta
			if EmotePoses.finished(_emote, _emote_t):
				_emote = &""
	var was := _emote_w
	_emote_w = move_toward(_emote_w, 1.0 if _emote != &"" else 0.0, delta / EMOTE_BLEND)
	if _emote_w <= 0.0:
		_emote_shown = &""
		if was > 0.0:
			_show_emote({}, 0.0)   # back to exactly the normal pose
		return {}
	return EmotePoses.sample(_emote_shown, _emote_t)


## Shows emote pose `p` with weight w (0 = back to normal); each body turns its own limbs.
func _show_emote(_p: Dictionary, _w: float) -> void:
	pass


## The whole body's part of a pose (both styles): hop, sit, spin and lean on `pivot`, which stands at
## `standing_y`. Weight 0 puts it back exactly.
func _pose_pivot(pivot: Node3D, standing_y: float, p: Dictionary, w: float) -> void:
	pivot.position.y = standing_y + w * (float(p.get("hop", 0.0)) - float(p.get("sit", 0.0)) * SIT_DROP)
	pivot.rotation.y = lerp_angle(0.0, float(p.get("spin", 0.0)), w)
	pivot.rotation.x = w * float(p.get("lean", 0.0))

# --- M3 Task 8: Build-and-Wear ----------------------------------------------------------------------------------

## The child's built wearables (AvatarLook.builds): each one small cached mesh (WearMesh), a hat on the head and a
## backpack and wings on the back (built wings flap like the catalogue's).
func _dress_builds(r: Dictionary) -> void:
	var builds: Dictionary = r.get("builds", {})
	for slot: StringName in builds:
		var anchor := head_anchor() if slot == WearRules.HAT else back_anchor()
		var part := WearMesh.build(slot, builds[slot]) if anchor else null
		if part == null:
			continue
		anchor.add_child(part)
		_parts.append(part)
		if slot == WearRules.WINGS:
			_wings = part
