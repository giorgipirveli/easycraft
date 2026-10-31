class_name SpaceCreature
extends Node3D
## A robot or an alien on a space world (owner #86, spec §21f): the parts every one shares. It is tapped like Tilly (a
## ray from the tap, near its middle, within reach, never through a block: SpaceCreature.find, BlockInteractor asks
## it first after the quest givers), it talks in babble at its own pitch (BabbleVoices) with a short line in a bubble
## over its head, it hops for joy, and it wears its graphics style's material (CreatureLook). Every game places its own
## (SpaceCreatures, from the seed and the landing), so nothing is sent over the network. Its thinking is throttled
## (LOOK_EVERY); each frame only eases what already moves.

const GROUP := &"space_creatures"
const TAP_REACH := 6.5
const LOOK_EVERY := 0.25
const BUBBLE_TIME := 5.0
## Farther than this from the child it sleeps (no thinking, no easing: SpaceCreatures wakes it).
const WAKE_R := 64.0

## Who it is (CreatureWords' id: an alien's, or &"robot", &"rover", &"drone").
var creature_id: StringName = &""
var display_name := ""
## Taps aim here (above its feet) and hit within this radius; from this far away at most.
var tap_height := 1.0
var tap_radius := 0.8
var reach := TAP_REACH
## A robot shines in the realistic style; an alien has a softer sheen.
var robot := true
## Its babble voice (BabbleRules.KINDS) and size.
var voice: StringName = &"bot"
var voice_size := 1.6
## (creature) -> void: the director hears a tap (its card, a dig, a hop...).
var on_tap: Callable
## () -> Array[Vector3]: the players' feet (tests set their own; else the "players" group).
var players: Callable

var body := Node3D.new()           # the model's root: hops, tilts, turns
var bubble := Label3D.new()
var _style := "?"
var _look_t := 0.0
var _bubble_t := 0.0
var _hop: Tween
var _turn_target := 0.0


func _init() -> void:
	body.name = "Body"
	add_child(body)
	bubble.name = "Bubble"
	bubble.font_size = 44
	bubble.outline_size = 12
	bubble.pixel_size = 0.005
	bubble.width = 520.0
	bubble.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bubble.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	bubble.visible = false
	add_child(bubble)


func _ready() -> void:
	add_to_group(GROUP)
	check_style()


## Where taps aim.
func tap_center() -> Vector3:
	return global_position + Vector3(0, tap_height, 0)


## A tap reached it: the director's answer (true: the tap was used).
func tapped() -> bool:
	if on_tap.is_valid():
		on_tap.call(self)
		return true
	return false


## The creature a tap ray (from, unit dir) hits, near its middle and within its reach of `eye`, never through a block
## (blocked(from, dir, distance) -> bool); the nearest along the ray.
static func find(tree: SceneTree, from: Vector3, dir: Vector3, eye: Vector3, blocked: Callable = Callable()) -> SpaceCreature:
	var best: SpaceCreature = null
	var best_t := INF
	for n in tree.get_nodes_in_group(GROUP):
		var c := n as SpaceCreature
		if c == null or c.is_queued_for_deletion() or not c.is_visible_in_tree():
			continue
		var center := c.tap_center()
		if not eye.is_finite() or eye.distance_to(center) > c.reach:
			continue
		var t := (center - from).dot(dir)
		if t <= 0.0 or t >= best_t or (from + dir * t).distance_to(center) > c.tap_radius:
			continue
		if blocked.is_valid() and blocked.call(from, dir, t):
			continue
		best = c
		best_t = t
	return best


## It says `text`: babble at its pitch and the words in its bubble for a while (the HUD's toast says them too: the
## director's).
func say(text: String) -> void:
	bubble.text = tr(text)
	bubble.visible = text != ""
	_bubble_t = BUBBLE_TIME
	if is_inside_tree():
		BabbleVoices.say(self, voice, voice_size, text, true, display_name)


## A happy hop and a puff of sparkles.
func cheer() -> void:
	if _hop and _hop.is_valid():
		_hop.kill()
	body.position.y = 0.0
	_hop = create_tween()
	_hop.tween_property(body, "position:y", 0.45, 0.16).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	_hop.tween_property(body, "position:y", 0.0, 0.22).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	if is_inside_tree():
		Fx.burst(get_tree().root, tap_center() + Vector3(0, 0.6, 0), Color("ffd23f"), 12, 2.5)


## The nearest player's feet within `radius`, or INF.
func nearest_player(radius: float) -> Vector3:
	var best := Vector3.INF
	var best_d := radius
	for p: Vector3 in _player_spots():
		var d := p.distance_to(global_position)
		if d < best_d:
			best_d = d
			best = p
	return best


func _player_spots() -> Array[Vector3]:
	if players.is_valid():
		var got: Array[Vector3] = []
		got.assign(players.call())
		return got
	var out: Array[Vector3] = []
	if not is_inside_tree():
		return out
	for p in get_tree().get_nodes_in_group(&"players"):
		var b := p as Node3D
		if b != null and b.visible:
			out.append(b.global_position)
	return out


## Wears the graphics style's material (checked a few times a second: the settings can change it any time).
func check_style() -> void:
	if BlockLibrary.style != _style:
		_style = BlockLibrary.style
		CreatureLook.dress(self, _style, robot)


## Every LOOK_EVERY: what it thinks (subclasses), then its style.
func think() -> void:
	pass


## Every frame: what it eases (subclasses).
func ease_frame(_delta: float) -> void:
	pass


func _process(delta: float) -> void:
	_look_t -= delta
	if _look_t <= 0.0:
		_look_t = LOOK_EVERY
		think()
		check_style()
	if _bubble_t > 0.0:
		_bubble_t -= delta
		if _bubble_t <= 0.0:
			bubble.visible = false
	if absf(angle_difference(body.rotation.y, _turn_target)) > 0.002:   # a transform set only when it moves
		body.rotation.y = lerp_angle(body.rotation.y, _turn_target, clampf(5.0 * delta, 0.0, 1.0))
	ease_frame(delta)


## Eases `node`'s `property` towards `to` (a set only when it moves: every set tells its meshes).
static func ease_to(node: Node3D, property: NodePath, to: float, rate: float) -> void:
	var now: float = node.get_indexed(property)
	if absf(now - to) > 0.001:
		node.set_indexed(property, lerpf(now, to, clampf(rate, 0.0, 1.0)))


## Turns (eased) so its front (-Z) faces `at` (a world position), or back to its own front with INF.
func face(at: Vector3) -> void:
	if not at.is_finite() or not is_inside_tree():
		_turn_target = 0.0
		return
	_turn_target = RobotRules.yaw_to(global_position, at) - global_rotation.y
