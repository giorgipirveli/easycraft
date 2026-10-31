class_name RobotRules
extends RefCounted
## The planets' robots as pure rules (owner #86, spec §21f: "true to how people really explore space: with robots").
## - The helper robot stands by the landing pad, to the front and right of the child who lands, clear of the portal
##   home (in front), the lander (to the left), Tilly's stall and Mercury's thermometer (helper_spot); its arm points
##   the way the HUD's compass points (the planet guide's next place, PlanetGuideRules.next), else to the aliens.
## - Its science quest: dig a sample (a tap on the rover buddy), explore a place (the guide's next place when the quest
##   starts, else the aliens' camp or village), come back and answer a question about the planet. Kept in the world's
##   secrets (SecretState.found, ids "creature:…": saved with the world, never counted by the Secret Book).
## - Its questions: each one right the first time pays EarnRules.FACT_QUIZ_GOLD once (CreatureData.quiz); a wrong
##   answer says "Not yet!" with a hint, a second miss shows the answer (the School's way: never a failure).
## - The rover buddy follows the child a little behind and to the right; the scout drone flies ahead of the child
##   towards the next place, or circles over them when there is none.

## Helper robot: this far from the pad's middle, clear of every obstacle by CLEAR.
const HELPER_RING := 5.0
const CLEAR := 1.5
## Where it may stand, in degrees from the landing child's forward (right is positive): the front-right first.
const ANGLES: Array[float] = [55.0, 90.0, 125.0, 180.0, 20.0, -125.0, -160.0]
## The obstacles every landing has: the portal home 3 blocks in front, the lander 7 to the left.
const PORTAL_AHEAD := 3.0
const PORTAL_R := 2.5
const LANDER_LEFT := 7.0
const LANDER_R := 3.5

## The quest's steps.
const OFFER := &"offer"
const DIG := &"dig"
const FIND := &"find"
const BACK := &"back"
const FINISHED := &"done"
## Its marks in the world's secrets.
const STARTED := "creature:quest"
const SAMPLE := "creature:sample"
const PLACE := "creature:place:"
const DONE := "creature:quest_done"
const CAMP := "creature:camp"
const CAMP_PLACE := "camp"

## Rover buddy: it keeps this far behind the child, drives at this speed, and jumps to them when left this far behind.
const ROVER_FOLLOW := 2.6
const ROVER_SPEED := 6.5
const ROVER_TELEPORT := 28.0
const ROVER_SIDE := 1.4
## Scout drone: this far ahead of the child and this high over the ground; it circles at CIRCLE_R over a child with no
## place to go.
const DRONE_AHEAD := 7.0
const DRONE_HEIGHT := 4.5
const DRONE_SPEED := 9.0
const CIRCLE_R := 3.0
const CIRCLE_SPEED := 0.6
const DRONE_TELEPORT := 40.0


## Where the helper robot stands (x, z) round the pad's middle `pad`, for a child landing there facing `forward` (x, z,
## any length): the first spot of ANGLES that keeps CLEAR from every obstacle [{at: Vector2, r: float}] (the portal and
## the lander always count), else the first one.
static func helper_spot(pad: Vector2, forward: Vector2, avoid: Array = []) -> Vector2:
	var fwd := forward.normalized() if forward.length() > 0.001 else Vector2(0, -1)
	var right := Vector2(-fwd.y, fwd.x)
	var all: Array = avoid.duplicate()
	all.append({"at": pad + fwd * PORTAL_AHEAD, "r": PORTAL_R})
	all.append({"at": pad - right * LANDER_LEFT, "r": LANDER_R})
	var first := Vector2.INF
	for deg in ANGLES:
		var a := deg_to_rad(deg)
		var spot := pad + (fwd * cos(a) + right * sin(a)) * HELPER_RING
		if first == Vector2.INF:
			first = spot
		if _clear(spot, all):
			return spot
	return first


static func _clear(spot: Vector2, avoid: Array) -> bool:
	for o: Dictionary in avoid:
		var at: Vector2 = o.get("at", Vector2.INF)
		if at.is_finite() and spot.distance_to(at) < float(o.get("r", 0.0)) + CLEAR:
			return false
	return true


## The yaw that turns a node's front (-Z) from `from` towards `to` (flat).
static func yaw_to(from: Vector3, to: Vector3) -> float:
	return atan2(-(to.x - from.x), -(to.z - from.z))


# --- The science quest --------------------------------------------------------------------------------------------

## The quest's step in a world whose secrets hold `found`.
static func quest_step(found: Dictionary) -> StringName:
	if found.has(DONE):
		return FINISHED
	if not found.has(STARTED):
		return OFFER
	if not found.has(SAMPLE):
		return DIG
	return BACK if place_found(found) else FIND


## Starts the quest: its place is the guide's next place `next_sight` (&"" for none: the aliens' camp or village).
static func start_quest(found: Dictionary, next_sight: StringName) -> void:
	if found.has(STARTED):
		return
	found[STARTED] = true
	found[PLACE + (("sight:" + String(next_sight)) if next_sight != &"" else CAMP_PLACE)] = true


## The quest's place: "sight:<id>" or CAMP_PLACE ("" before it starts).
static func quest_place(found: Dictionary) -> String:
	for k: Variant in found:
		if k is String and (k as String).begins_with(PLACE):
			return (k as String).trim_prefix(PLACE)
	return ""


## The quest's place was explored: its sight found (SpaceSights: "sight:<id>"), or the aliens visited.
static func place_found(found: Dictionary) -> bool:
	var place := quest_place(found)
	if place == "":
		return false
	return found.has(CAMP) if place == CAMP_PLACE else found.has(place)


## The rover dug its sample (true the first time in this world).
static func dig(found: Dictionary) -> bool:
	if found.has(SAMPLE):
		return false
	found[SAMPLE] = true
	return true


## The quest's question answered: the quest is done.
static func finish(found: Dictionary) -> bool:
	if found.has(DONE) or not found.has(STARTED):
		return false
	found[DONE] = true
	return true


# --- Questions ------------------------------------------------------------------------------------------------------

## The robot of world u asks this next: its first question whose gold is not paid yet, else the first again (practice,
## no gold); {} for a world without a robot.
static func next_question(u: int, data: CreatureData) -> Dictionary:
	var list: Array = CreatureWords.robot(u).get("questions", [])
	for q: Dictionary in list:
		if not data.paid(str(q.id)):
			return q
	return list[0] if not list.is_empty() else {}


## World u's robot has questions whose gold is not paid yet.
static func has_unpaid(u: int, data: CreatureData) -> bool:
	for q: Dictionary in CreatureWords.robot(u).get("questions", []):
		if not data.paid(str(q.id)):
			return true
	return false


## An answer: right or not.
static func is_right(q: Dictionary, choice: int) -> bool:
	return not q.is_empty() and choice == int(q.get("answer", -1))


## The gold for question `id` answered right: EarnRules.FACT_QUIZ_GOLD the first time it is right the first try (the
## question is marked paid in `data`); 0 otherwise.
static func quiz_gold(data: CreatureData, id: String, first_try: bool) -> int:
	if not first_try or data.paid(id) or not data.pay_question(id):
		return 0
	return EarnRules.FACT_QUIZ_GOLD


# --- The rover and the drone -------------------------------------------------------------------------------------

## Where the rover wants to be: ROVER_FOLLOW behind the child and ROVER_SIDE to their right.
static func rover_goal(child: Vector3, child_forward: Vector3) -> Vector3:
	var f := Vector3(child_forward.x, 0.0, child_forward.z)
	f = f.normalized() if f.length() > 0.001 else Vector3.FORWARD
	var right := Vector3(-f.z, 0.0, f.x)
	return child - f * ROVER_FOLLOW + right * ROVER_SIDE


## One step of the rover from `at` to `goal` in `delta` seconds (flat; it stops within 0.4 of it).
static func rover_step(at: Vector3, goal: Vector3, delta: float) -> Vector3:
	var d := Vector3(goal.x - at.x, 0.0, goal.z - at.z)
	var dist := d.length()
	if dist < 0.4:
		return at
	var step := minf(ROVER_SPEED * delta, dist - 0.3)
	return at + d / dist * step


## The rover was left behind (a jump, a fall, a flight): it comes to the child at once.
static func rover_teleports(at: Vector3, child: Vector3) -> bool:
	return Vector2(at.x - child.x, at.z - child.z).length() > ROVER_TELEPORT or absf(at.y - child.y) > 12.0


## Where the drone wants to be at time `t` (seconds): DRONE_AHEAD from the child towards `target` (INF: no place: it
## circles over the child), DRONE_HEIGHT over `ground` (its ground there).
static func drone_goal(child: Vector3, target: Vector3, t: float) -> Vector3:
	var flat := Vector3.ZERO
	if target.is_finite():
		var d := Vector3(target.x - child.x, 0.0, target.z - child.z)
		var dist := d.length()
		if dist > 0.5:
			flat = d / dist * minf(DRONE_AHEAD, maxf(dist - 1.0, 0.0))
	else:
		flat = Vector3(cos(t * CIRCLE_SPEED), 0.0, sin(t * CIRCLE_SPEED)) * CIRCLE_R
	return child + flat + Vector3(0, DRONE_HEIGHT, 0)


## One step of the drone towards `goal` (it eases in).
static func drone_step(at: Vector3, goal: Vector3, delta: float) -> Vector3:
	var d := goal - at
	var dist := d.length()
	if dist < 0.05:
		return goal
	return at + d / dist * minf(DRONE_SPEED * delta, dist * clampf(delta * 3.0, 0.0, 1.0) + 0.02)


## What the drone says when tapped: where the next place is, from the child.
static func drone_words(child: Vector3, target: Vector3, place_name: String, camp: bool) -> String:
	if not target.is_finite():
		return tr_words(CreatureWords.DRONE_NOTHING)
	var blocks := int(round(Vector2(target.x - child.x, target.z - child.z).length()))
	var way := CreatureWords.direction(child, target)
	if camp:
		return tr_words(CreatureWords.DRONE_CAMP) % [blocks, way]
	return tr_words(CreatureWords.DRONE_SCOUTS) % [place_name, blocks, way]


static func tr_words(text: String) -> String:
	return Lang.t(text)
