class_name AnimLife
extends RefCounted
## Owner #94 (the animations brief §2): an animal's small idle life, on top of its wagging tail or grazing head
## (Animal._animate_part). Now and then (WAIT seconds apart, its own rhythm from its id) a standing animal hops (the
## hoppers: rabbits, frogs, squirrels, chickens, the bunnies), shakes itself (dogs, foxes, sheep, goats, horses,
## donkeys, parrots, ducks, penguins) or sniffs the ground (the rest). Every game shows its own (nothing sent), and never
## while it walks, sits, swims or is golden. One tween on the animal's visual root, which is exactly at rest after.

const WAIT := Vector2(6.0, 14.0)
const HOP := &"hop"
const SHAKE := &"shake"
const SNIFF := &"sniff"
const HOPPERS: Array[StringName] = [&"rabbit", &"frog", &"squirrel", &"chicken", &"gummy_bunny", &"moon_bunny",
	&"candy_bird"]
const SHAKERS: Array[StringName] = [&"dog", &"fox", &"arctic_fox", &"fennec", &"sheep", &"goat", &"horse", &"donkey",
	&"parrot", &"duck", &"penguin", &"polar_bear"]
## Not these: the fish swim their own sway; the bosses and the monster friend have moves of their own.
const NONE: Array[StringName] = [&"fish", &"mini_boss", &"monster_friend"]


## What `species` does when it fidgets (&"" for nothing).
static func action(species: StringName) -> StringName:
	if NONE.has(species):
		return &""
	if HOPPERS.has(species):
		return HOP
	if SHAKERS.has(species):
		return SHAKE
	return SNIFF


## Seconds to its `n`-th fidget after the last one (the first: n = 0), its own rhythm from its id.
static func wait(animal_id: String, n: int) -> float:
	var k := fposmod(float(hash(animal_id) % 1000) * 0.001 + n * 0.618034, 1.0)
	return lerpf(WAIT.x, WAIT.y, k) * (0.5 if n == 0 else 1.0)


## Plays `what` on `body` (a hop, a shake or a sniff; `size` its scale: a baby hops lower) and returns its tween.
static func play(host: Node, body: Node3D, what: StringName, size: float = 1.0) -> Tween:
	if what == &"" or not host.is_inside_tree():
		return null
	var tw := host.create_tween()
	match what:
		HOP:
			for i in 2:
				tw.tween_property(body, "position:y", 0.22 * size, 0.13).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
				tw.tween_property(body, "position:y", 0.0, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		SHAKE:
			for i in 4:
				tw.tween_property(body, "rotation:z", 0.2 if i % 2 == 0 else -0.2, 0.07)
			tw.tween_property(body, "rotation:z", 0.0, 0.08)
		SNIFF:
			for i in 2:
				tw.tween_property(body, "rotation:x", -0.22, 0.14).set_trans(Tween.TRANS_SINE)
				tw.tween_property(body, "rotation:x", -0.08, 0.1).set_trans(Tween.TRANS_SINE)
			tw.tween_property(body, "rotation:x", 0.0, 0.18).set_trans(Tween.TRANS_SINE)
	tw.tween_callback(func() -> void: rest(body))
	return tw


## The visual root exactly at rest (a cheer or a fidget cut short).
static func rest(body: Node3D) -> void:
	body.position.y = 0.0
	body.rotation.x = 0.0
	body.rotation.z = 0.0
