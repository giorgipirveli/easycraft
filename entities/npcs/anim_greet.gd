class_name AnimGreet
extends RefCounted
## Owner #94 (the animations brief §1): the helpers greet the child who walks up to them, a hop with a squash and a
## stretch on top of their turn and wave (Tilly and the quest givers, Gemma, the helper robots, the aliens), and jump
## for joy (three hops) when the child's quest step, story or board goal is done near them (cheers_for). Tweens on the
## helper's own model root (its position.y and scale), which is exactly at rest again after; nothing per frame when
## nobody hops, nothing sent (every game shows its own helpers).

const HOP_HEIGHT := 0.22
const HOP_TIME := 0.34
const CHEER_HOPS := 3
const CROUCH := Vector3(1.08, 0.88, 1.08)
const STRETCH := Vector3(0.94, 1.1, 0.94)
const _TWEEN := &"anim_greet_tween"


## `times` hops of `body` (its rest: position.y 0, scale 1).
static func hop(body: Node3D, times: int = 1, height: float = HOP_HEIGHT) -> Tween:
	if body == null or not body.is_inside_tree():
		return null
	if body.has_meta(_TWEEN):
		var old := body.get_meta(_TWEEN) as Tween
		if old and old.is_valid():
			old.kill()
	body.position.y = 0.0
	body.scale = Vector3.ONE
	var tw := body.create_tween()
	for i in times:
		tw.tween_property(body, "scale", CROUCH, 0.06)
		tw.tween_property(body, "scale", STRETCH, 0.08)
		tw.parallel().tween_property(body, "position:y", height, HOP_TIME * 0.5).set_trans(Tween.TRANS_QUAD) \
			.set_ease(Tween.EASE_OUT)
		tw.tween_property(body, "position:y", 0.0, HOP_TIME * 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.parallel().tween_property(body, "scale", Vector3.ONE, HOP_TIME * 0.5)
	tw.tween_callback(func() -> void:
		body.position.y = 0.0
		body.scale = Vector3.ONE)
	body.set_meta(_TWEEN, tw)
	return tw


## Three higher hops: a quest step or story done near the helper.
static func cheer(body: Node3D) -> Tween:
	return hop(body, CHEER_HOPS, HOP_HEIGHT * 1.6)


## True when `body` is hopping now.
static func hopping(body: Node3D) -> bool:
	if body == null or not body.has_meta(_TWEEN):
		return false
	var tw := body.get_meta(_TWEEN) as Tween
	return tw != null and tw.is_valid() and tw.is_running()


## A Progress kind a helper near the child cheers for: a quest step, a story or a board goal.
static func cheers_for(kind: StringName) -> bool:
	return StringName(String(kind).get_slice("/", 0)) in [LevelRules.QUEST_STEP, LevelRules.QUEST_DONE, LevelRules.GOAL]
