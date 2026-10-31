class_name GhostRunner
extends Node3D
## A friend's ghost on a course (M4 ghost races; spec §17.5, research T2): the friend's look, see-through
## (GhostLook), that waits on the START and runs the ghost's path when this player's run starts (GhostRaces),
## at the run's own pace, blinking with a puff where the friend fell back to a checkpoint or took a teleport pad.
## Fair by construction: no collision of any kind (it never blocks and can't be touched or hit), not a player
## (no group, no network, nothing of the world changes), drawn on this game only. The blocky body in both
## styles: the look's own shape, and cheaper than a skeleton on a phone.

signal arrived

const NAME_HEIGHT := 2.35
const WAIT_AFTER := 2.0          # after the finish it stands there a moment, then waits on START again

var ghost: RaceGhost
var top := Vector3.ZERO          # START's top in the world
var turn := Vector3i.ZERO        # a stamp's facing (Blueprints); ZERO: not turned
var label := ""
var avatar: AvatarModel
var tag: Label3D
var running := false
var t := 0.0

var _rest := 0.0
var _last := Vector3.ZERO


## A ghost whose START's top is `start_top`, turned like a stamp facing `forward`, with `name_text` over it.
func setup(g: RaceGhost, start_top: Vector3, forward: Vector3i = Vector3i.ZERO, name_text: String = "") -> void:
	ghost = g
	top = start_top
	turn = forward
	label = name_text


func _ready() -> void:
	avatar = BlockyAvatar.new()
	avatar.name = "Avatar"
	if ghost != null and ghost.look != "":
		avatar.apply_look(AvatarLook.from_code(ghost.look))
	add_child(avatar)
	GhostLook.apply(avatar)
	tag = Label3D.new()
	tag.name = "Tag"
	tag.text = label
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tag.font_size = 32
	tag.outline_size = 8
	tag.pixel_size = 0.01
	tag.modulate = Color(0.85, 0.95, 1.0, 0.9)
	tag.position.y = NAME_HEIGHT
	tag.visible = label != ""
	add_child(tag)
	wait()


## Stands on START, facing the way it will go.
func wait() -> void:
	running = false
	t = 0.0
	_rest = 0.0
	_place(0.0, 0.0)


## Runs from START now (this player just stepped off it).
func go() -> void:
	running = true
	t = 0.0
	_rest = 0.0


func _process(delta: float) -> void:
	step(delta)


## One frame of the run (tests step it).
func step(delta: float) -> void:
	if ghost == null or avatar == null:
		return
	if not running:
		if _rest > 0.0:
			_rest -= delta
			if _rest <= 0.0:
				wait()
		avatar.animate(0.0, true, delta)
		return
	var before := t
	t = minf(t + delta, ghost.duration())
	if ghost.jumps_between(before, t):
		Fx.burst(get_tree().root, global_position + Vector3(0, 1.0, 0), Color(0.85, 0.95, 1.0, 0.8), 10, 2.5, 0.12, 0.45, 2.0)
	_place(t, delta)
	if t >= ghost.duration():
		running = false
		_rest = WAIT_AFTER
		arrived.emit()


func _place(time: float, delta: float) -> void:
	if ghost == null:
		return
	var at := top + RaceGhost.turned(ghost.sample_at(time), turn)
	var moved := at - _last
	_last = at
	position = at
	var f := RaceGhost.turned(ghost.facing_at(time), turn)
	if time <= 0.0:
		f = RaceGhost.turned(ghost.facing_at(0.2), turn)
	if f != Vector3.ZERO:
		rotation.y = atan2(-f.x, -f.z)
	if delta > 0.0 and avatar:
		var flat := Vector2(moved.x, moved.z).length() / delta
		avatar.animate(flat if flat < RaceGhost.MAX_SPEED else 0.0, absf(moved.y / delta) < 0.5, delta)
