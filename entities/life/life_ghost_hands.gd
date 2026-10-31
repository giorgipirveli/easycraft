class_name LifeGhostHands
extends Node3D
## Owner #113 (docs/design/life-skills.md §10: "the coach does the step once with see-through ghost hands"): two
## see-through hands (the child's own hand model, VrHandModel, in a soft glowing white) that glide from in front of the
## child to the one next thing and do the step once: press it (squeeze), hold it, push on the chest to the beat, point
## at it, sweep across it; then they fade. They take nothing and block nothing.

const COLOUR := Color(0.85, 0.95, 1.0, 0.42)
const GLIDE := 0.7
const ACT := 2.2

var hands: Array[VrHandModel] = []
var t := -1.0
var kind := "touch"
var target := Vector3.ZERO
var start := Vector3.ZERO
var right := Vector3.RIGHT


func _init() -> void:
	name = "LifeGhostHands"
	for side: StringName in [VrRules.LEFT, VrRules.RIGHT]:
		var h := VrHandModel.new(side, VrHandModel.BLOCKY)
		for m: Node in h.find_children("*", "MeshInstance3D", true, false):
			(m as MeshInstance3D).material_override = LifeRoomKit.material(COLOUR, true)
		h.visible = false
		add_child(h)
		hands.append(h)


## Shows a step of `step_kind` at `at` (world), starting from in front of the head.
func demonstrate(step_kind: String, at: Vector3, head: Transform3D) -> void:
	kind = step_kind
	target = at
	right = head.basis.x
	start = head.origin + head.basis * Vector3(0, -0.3, -0.35)
	t = 0.0
	for h in hands:
		h.visible = true


func showing() -> bool:
	return t >= 0.0


func _process(delta: float) -> void:
	if t < 0.0:
		return
	t += delta
	if t > GLIDE + ACT:
		t = -1.0
		for h in hands:
			h.visible = false
		return
	var k := clampf(t / GLIDE, 0.0, 1.0)
	k = k * k * (3.0 - 2.0 * k)
	var act := maxf(t - GLIDE, 0.0)
	var two := kind == "rhythm" or kind == "hands"
	var at := start.lerp(target, k)
	var squeeze := 0.0
	var point := false
	match kind:
		"rhythm":
			at.y -= 0.04 * absf(sin(act * PI / LifeBeat.BEAT_SECONDS))
		"sweep":
			at += right * sin(act * TAU / 1.2) * 0.25
			squeeze = 1.0
		"point", "go":
			at = start.lerp(target, k * 0.5)
			point = true
		"hold", "hands":
			squeeze = 1.0 if act > 0.2 else 0.0
		_:
			squeeze = 1.0 if fmod(act, 1.1) < 0.4 and act > 0.0 else 0.0
	var dir := (target - at)
	var facing := Basis.looking_at(dir.normalized() if dir.length() > 0.01 else Vector3.FORWARD, Vector3.UP) \
		if absf(dir.normalized().dot(Vector3.UP)) < 0.98 else Basis(Vector3.RIGHT, -PI / 2)
	var fade := clampf((GLIDE + ACT - t) / 0.4, 0.0, 1.0)
	for i in hands.size():
		var h := hands[i]
		h.visible = two or i == 1
		var offset := right * (-0.07 if i == 0 else 0.07) if two else Vector3.ZERO
		h.global_transform = Transform3D(facing, at + offset + (Vector3(0, 0.02, 0) if two and i == 1 else Vector3.ZERO))
		h.set_pose(1.0 if point else squeeze, 0.0 if point else squeeze)
		h.scale = Vector3.ONE * (0.6 + 0.4 * fade)
