class_name PlayStation
extends Node3D
## Owner #122 (G0; docs/design/learning-is-play.md §5.1): one mechanic's station in the play arena, built from one
## exercise (a component: PlayStations.make picks the subclass by the exercise's type). It owns its things and the
## arena's targets for them, and turns what the child does into ExerciseCheck's response:
## - `tap(target)`: one act (a finger on the flat screen; in VR a hand squeezing at a thing, or the laser's trigger): a
##   thing that can be carried is lifted (a second tap on it puts it back home), a place it can go takes it, anything else
##   is pressed (a piece's source, a drum, a key, a gate); GO (the world's test) asks the host to check.
## - VR carrying: the host keeps `carried_node()` in the hand and, on release, taps `spot_near` the hand (or puts it home).
## - `is_ready`, `response`; `answers_by_acting` (Choose by doing, Test it: the act itself is the answer: `acted`).
## - `react(outcome)`: the world answers (PlayLoop's RIGHT, NOT_YET, GHOST, SHOWN); a miss sends things home where the
##   School's own answer widgets cleared (sort, order, match, label) and keeps a build otherwise.
## - `ghost()`: the coach's next step as the taps a child would make (the ghost finger or hands show them, then they are
##   done); repeated, they always lead to a right answer. `show_answer`: the worked answer, in the place.
## Units are metres in the arena's frame (its floor y = 0; the child stands at PlayArena.FEET, facing -Z).

signal changed
signal acted
signal go_pressed

const GO := "go"
## Owner #133 ("Show"): how a new unit's first challenge of a kind is shown before the child acts (demo_kind): the
## coach's ghost does one step for real and the child does the rest (DEMO_DO), only shows it over the right things
## (DEMO_SHOW: the child does it), or nothing, where one act answers it (DEMO_NONE).
const DEMO_DO := "do"
const DEMO_SHOW := "show"
const DEMO_NONE := "none"
const LIFT := 0.1
const MOVE_TIME := 0.25
## The table in front of the child: its top, its middle, its size.
const TABLE_TOP := 0.72
const TABLE_AT := Vector3(0, 0, 0.42)
const TABLE_SIZE := Vector2(2.1, 0.6)
## The things on the table (front, up to PER_ROW a row; a second row stands a step higher behind, like a shelf) and the
## places on a shelf behind the table (back): from the flat view the places show above the things, the board above both.
const FRONT_Z := 0.6
const BACK_Z := 0.02
const SHELF_TOP := 0.86
const ON_TABLE := TABLE_TOP + 0.14
const CARD := Vector3(0.56, 0.15, 0.05)
const PER_ROW := 3
const CARD_GAP := 0.62
const ROW_GAP := 0.2
const ROW_RISE := 0.2
const GO_AT := Vector3(0.98, TABLE_TOP + 0.16, 0.6)
## A small card for a station's own button (TAKE ONE BACK, CLEAR, EMPTY): at the table's front left corner.
const UTILITY := Vector3(0.26, 0.09, 0.04)
const UTILITY_AT := Vector3(-0.98, ON_TABLE - 0.04, 0.62)

var mechanic := ""
var ex: Dictionary = {}
var seed := 0
var params := {}
var arena: PlayArena
var locked := false
var carried := ""
## Each carryable thing's home (local position), and its node.
var homes := {}
var things := {}

var _owned: Array[String] = []
var _tweens := {}


func setup(exercise: Dictionary, run_seed: int, run_params: Dictionary, in_arena: PlayArena) -> void:
	ex = exercise
	seed = run_seed
	params = run_params
	arena = in_arena
	mechanic = PlayMechanics.of_exercise(ex)
	name = "Station_" + mechanic


## Subclasses build their props and targets here.
func build() -> void:
	pass


func add(target_name: String, node: Node3D, radius: float, width: float = 0.0) -> void:
	arena.add_target(target_name, node, radius, width)
	if not _owned.has(target_name):
		_owned.append(target_name)


func owned() -> Array[String]:
	return _owned.duplicate()


## A thing a child can carry: registered as a target, with its home.
func add_thing(target_name: String, node: Node3D, radius: float = 0.12) -> void:
	things[target_name] = node
	homes[target_name] = node.position
	add(target_name, node, radius)


# --- The view and the board ----------------------------------------------------------------------------------------

## The flat view: over the child's shoulder, looking down at the table (its things and places), the board behind.
func view_cam() -> Vector3:
	return Vector3(0, 1.9, 1.32)


func view_look() -> Vector3:
	return Vector3(0, 0.93, 0.12)


## The picture's board: behind the places at a child's eye height (it turns to face whoever looks: PlayArena).
func board_at() -> Vector3:
	return Vector3(0, 1.17, -0.5)


func board_size() -> Vector2:
	return Vector2(1.6, 0.69)


## The picture shown on the board ({} for none).
func board_picture() -> Dictionary:
	var p: Variant = ex.get("picture")
	return p if p is Dictionary else {}


# --- Acting --------------------------------------------------------------------------------------------------------

func tap(t: String) -> void:
	if locked or t == "":
		return
	if t == GO:
		go_pressed.emit()
		return
	if carried != "":
		if t == carried:
			put_home()
			return
		if spots_for(carried).has(t):
			var thing := carried
			carried = ""
			arena.glow([] as Array[String])
			put(thing, t)
			changed.emit()
			return
	if carryable(t):
		if carried != "":
			put_home()
		lift(t)
		return
	press(t)


func carryable(t: String) -> bool:
	return things.has(t)


## Every place a carried thing can go.
func spot_names() -> Array[String]:
	return [] as Array[String]


func spots_for(_thing: String) -> Array[String]:
	return spot_names()


## A press on something that is not carried (subclasses).
func press(_t: String) -> void:
	pass


## Lifts a thing (out of its place, if it was in one): it rises a little and glows.
func lift(t: String) -> void:
	carried = t
	take(t)
	var n: Node3D = things[t]
	n.scale = Vector3.ONE
	move(n, n.position + Vector3(0, LIFT, 0))
	arena.glow([t] as Array[String])


## The carried thing back home.
func put_home() -> void:
	if carried == "":
		return
	var t := carried
	carried = ""
	arena.glow([] as Array[String])
	take(t)
	move(things[t], homes[t])
	changed.emit()


## Subclasses: `thing` now goes into `spot` (and moves there), or comes out of its place.
func put(_thing: String, _spot: String) -> void:
	pass


func take(_thing: String) -> void:
	pass


func carried_node() -> Node3D:
	return things.get(carried) as Node3D


## The place nearest `at` (global) a carried thing can go, within `reach` of its radius ("" for none).
func spot_near(at: Vector3, reach: float = 0.12) -> String:
	if carried == "":
		return ""
	var best := ""
	var best_d := INF
	for s in spots_for(carried):
		if not arena.has_target(s):
			continue
		var d := at.distance_to(arena.target_position(s)) - arena.target_radius(s)
		if d <= reach and d < best_d:
			best_d = d
			best = s
	return best


# --- Answering -----------------------------------------------------------------------------------------------------

func is_ready() -> bool:
	return true


func response() -> Variant:
	return null


func answers_by_acting() -> bool:
	return false


## The world's test's words (GO).
func go_words() -> String:
	return PlayMechanics.go_words(mechanic)


## The world answers the check (PlayLoop's RIGHT, NOT_YET, GHOST, SHOWN).
func react(_outcome: String) -> void:
	pass


## Owner #133: how this challenge is shown first to a child new to the unit (DEMO_DO, DEMO_SHOW, DEMO_NONE).
func demo_kind() -> String:
	return DEMO_NONE if answers_by_acting() else DEMO_SHOW


## Owner #133 ("choices as pictures or objects, spoken when touched"): what a thing or a place says when the child
## touches it ("" for nothing: a source of pieces, a drum, a key).
func spoken_name(_t: String) -> String:
	return ""


## The coach's next step: the taps a child would make ([] when the answer is right).
func ghost() -> Array[String]:
	return [] as Array[String]


## The worked answer, in the place.
func show_answer() -> void:
	pass


func lock() -> void:
	if carried != "":
		put_home()
	locked = true


## What a child who waits may touch (the idle cue glows them for a moment: never the answer): the things to carry, else
## the station's own pressables but its test and its helpers, at most HINTS of them.
const HINTS := 6
const HELPERS: Array[String] = ["back", "clear", "empty", "listen", "mine", "board"]


func hint_targets() -> Array[String]:
	var out: Array[String] = []
	var pool: Array = things.keys() if not things.is_empty() else _owned
	for t: Variant in pool:
		var name := str(t)
		if name == GO or HELPERS.has(name) or spot_names().has(name):
			continue
		out.append(name)
		if out.size() >= HINTS:
			break
	return out


## The station's own words for the HUD ("Made: 347"); "" for none.
func readout() -> String:
	return ""


## What the world says after a miss ("Not enough yet."), before the hint; "" for nothing more than its reaction.
func world_words() -> String:
	return ""


# --- Helpers -------------------------------------------------------------------------------------------------------

## Moves a node to a local position: a short glide, or at once with Reduce motion (and in tests).
func move(n: Node3D, to: Vector3) -> void:
	if not is_instance_valid(n):
		return
	if _tweens.has(n) and (_tweens[n] as Tween).is_valid():
		(_tweens[n] as Tween).kill()
	if UiMotion.calm() or not is_inside_tree():
		n.position = to
		return
	var tw := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(n, "position", to, MOVE_TIME)
	_tweens[n] = tw


## A happy hop of a node (a right answer), or a little shake (not yet).
func hop(n: Node3D) -> void:
	if not is_instance_valid(n) or UiMotion.calm() or not is_inside_tree():
		return
	var at := n.position
	var tw := create_tween().set_trans(Tween.TRANS_SINE)
	tw.tween_property(n, "position", at + Vector3(0, 0.08, 0), 0.15)
	tw.tween_property(n, "position", at, 0.2)


func shake(n: Node3D) -> void:
	if not is_instance_valid(n) or UiMotion.calm() or not is_inside_tree():
		return
	var at := n.position
	var tw := create_tween()
	for k in 3:
		tw.tween_property(n, "position", at + Vector3(0.025, 0, 0), 0.05)
		tw.tween_property(n, "position", at - Vector3(0.025, 0, 0), 0.05)
	tw.tween_property(n, "position", at, 0.05)


## The things' places on the table (PER_ROW a row, a shelf step for a second row).
static func things_at(count: int, y: float = ON_TABLE) -> Array[Vector3]:
	return rows_of(count, PER_ROW, CARD_GAP, FRONT_Z, ROW_GAP, y, ROW_RISE)


## The shelf behind the table the places stand on (its top at SHELF_TOP).
func shelf(width: float = 1.7) -> void:
	LifeRoomKit.box(self, "Shelf", Vector3(width, SHELF_TOP, 0.4), Vector3(0, SHELF_TOP * 0.5, BACK_Z), PlayKit.WOOD_DARK)


## `count` places spread across the table's width (x), centred.
static func spread(count: int, gap: float) -> Array[float]:
	var out: Array[float] = []
	for i in count:
		out.append((i - (count - 1) * 0.5) * gap)
	return out


## Up to `per_row` things a row (one row for up to `per_row`, then rows going back and up a step, like a shelf, so their
## words never overlap from the flat view): local positions, the first things in the back row.
static func rows_of(count: int, per_row: int, gap: float, front_z: float, row_gap: float, y: float,
		rise: float = 0.17) -> Array[Vector3]:
	var out: Array[Vector3] = []
	var rows := ceili(float(count) / per_row)
	for i in count:
		var r := i / per_row
		var in_row := mini(per_row, count - r * per_row)
		var xs := spread(in_row, gap)
		var back := rows - 1 - r
		out.append(Vector3(xs[i - r * per_row], y + back * rise, front_z - back * row_gap))
	return out
