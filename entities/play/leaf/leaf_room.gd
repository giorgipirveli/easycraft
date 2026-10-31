class_name LeafRoom
extends LifeRoom
## Owner #133, #134 (docs/design/games/leaf-voyage.md §4.4): Inside a Leaf's places (LeafPlace, LeafGarden) are Life rooms
## (targets with forgiving radii, flat views, VR stands, the glow: G0's PlayArena's way) that also say, for B2's host and
## the tests, which targets each flat view shows (a tap there glides the child to it and acts), which targets the hands
## take or squeeze in VR, and the stand (a view's VR spot) from which the hands reach each.

var _flat := {}
var _hands := {}


func _init() -> void:
	super("middle")


## The rooms' look (2026-10-17) dresses every Life room once it is built: a default sky dome, the room's own sun and a
## daylight tone. A leaf place lights itself with that sun (LeafKit.sun) but draws its own sky, tinted by its weather,
## in its own tone: the default dome is put away (hidden: the room still knows it) and the tone given back.
func _ready() -> void:
	super()
	var dome := get_node_or_null("Decor/Sky") as Node3D
	if dome != null:
		dome.visible = false
	LeafKit.own_tone(env)


## The flat views a voyage uses, in order.
func flat_views() -> Array[String]:
	var out: Array[String] = []
	for v: String in _flat:
		out.append(v)
	return out


## The targets a flat view shows (each tappable from there).
func flat_targets(view_name: String) -> Array[String]:
	var out: Array[String] = []
	for t: Variant in _flat.get(view_name, []):
		out.append(str(t))
	return out


## The targets the hands take, squeeze or let go at in VR.
func hand_targets() -> Array[String]:
	var out: Array[String] = []
	for t: String in _hands:
		out.append(t)
	return out


## The view whose VR stand reaches a hand target (the start view for the rest: the laser reaches them).
func stand_for(target_name: String) -> String:
	return str(_hands.get(target_name, start_view))


func add_flat(view_name: String, targets: Array) -> void:
	_flat[view_name] = targets.duplicate()


func add_hand(target_name: String, stand_view: String) -> void:
	_hands[target_name] = stand_view
