class_name SpaceSights
extends Node
## A space world's sights (cosmos, spec §21b.2: "its facts to discover"): the places a child learns a real fact at by
## walking there. Mars's are the giant volcano's summit, the canyon's floor, the two ice caps and any dry river bed
## (where they are: SpaceShape.sight_at, sights(); their names and words: the descriptor's `sights`,
## UniverseRegistry.sights). The sandbox adds one ("Sights") in a space world whose shape has sights, for this game's
## own player. A few times a second (never every frame) it looks at the column under the player's feet: standing on a
## sight (not flying high over it) the first time in this world says its fact with a sparkle and puts it on MY MAP.
## The big sights are on MY MAP from the landing (their names), a river bed where one was found. Found sights are kept
## in the world's secrets (SecretState.found, ids "sight:<id>": saved with the world, never counted as the Secret
## Book's secrets, whose ids are "<kind>_<ax>_<az>_<n>"). Spec §21c: the Moon's and Mars's colony is a big sight (its Great
## Dome); its other parts (the greenhouse, the airlock, the smaller domes, the outside parts) say their facts as they are
## walked into and are never marked by themselves (SpaceShape.is_part_sight).

## A sight was found here (its id).
signal sight_found(id: StringName)

const TICK := 0.5
const NEAR_GROUND := 10.0         # feet this far above the ground (flying over) find nothing
const PREFIX := "sight:"

var shape: SpaceShape
## {id: {"name", "words"}} (UniverseRegistry.sights).
var sights := {}
## The world's found secrets (SecretState.found): the found sights go in as "sight:<id>".
var found := {}
## () -> Vector3: this game's player's feet (INF when there is none).
var player_position: Callable
## (text) -> void: this game's words for the player (the HUD's toast).
var toast: Callable
## (entry {id, kind, name, pos}) -> void: a place on MY MAP (PlacesDirector.mark).
var mark: Callable
## Off in tests (they call tick()).
var auto_tick := true

var _t := 0.0


## Puts the big sights on MY MAP (a river bed found in an earlier visit is not: only its fact was kept).
func setup() -> void:
	if shape == null:
		return
	for s: Dictionary in shape.sights():
		_mark(s.id, s.pos)


func _process(delta: float) -> void:
	if not auto_tick:
		return
	_t += delta
	if _t >= TICK:
		_t = 0.0
		tick()


## One look under the player's feet.
func tick() -> void:
	if shape == null or not player_position.is_valid():
		return
	var at: Vector3 = player_position.call()
	if not at.is_finite():
		return
	var x := floori(at.x)
	var z := floori(at.z)
	var id := shape.sight_at(x, z)
	if id == &"" or not sights.has(id) or found.has(PREFIX + String(id)):
		return
	if absf(at.y - shape.height_at(x, z)) > NEAR_GROUND:
		return
	found[PREFIX + String(id)] = true
	if toast.is_valid():
		toast.call(tr(str(sights[id].words)))
	Audio.play(&"sparkle")
	if is_inside_tree():
		Fx.burst(get_tree().root, at + Vector3(0, 1.0, 0), Color("ffd23f"), 24, 3.0)
	if not shape.is_part_sight(id) and not shape.sights().any(func(s: Dictionary) -> bool: return s.id == id):
		_mark(id, Vector3(x + 0.5, shape.height_at(x, z), z + 0.5))   # a river bed: on the map where it was found
	sight_found.emit(id)


func _mark(id: StringName, pos: Vector3) -> void:
	if mark.is_valid() and sights.has(id):
		mark.call({"id": "sight_" + String(id), "kind": &"sight", "name": tr(str(sights[id].name)), "pos": pos})
