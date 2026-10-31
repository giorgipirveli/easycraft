extends GutTest
## Inside a Leaf's B2 (finding 1, 2026-10-18): Vr eased its comfort vignette by the rig's motion only while a world's
## player was spawned, so a voyage opened from the menu's School (no world: no player) swam with no vignette at all. A
## place that moves the child's stand (a voyage's swim and grapple, any `&"life"` stand) gets the vignette as the world
## does; a still stand gets none.

var _settings := {}
var stand: Node3D


func before_each() -> void:
	_settings = Profile.data.settings.duplicate()
	stand = Node3D.new()
	add_child_autofree(stand)
	Vr.simulate(true)
	Vr.anchor(stand, &"life")
	Vr.step_physics()
	Vr.step(1.0 / 72.0)


func after_each() -> void:
	Vr.simulate(false)
	Vr.anchor(null)
	Profile.data.settings.clear()
	Profile.data.settings.merge(_settings)


func test_no_world_player_here() -> void:
	assert_null(Vr.local_player(), "the menu's School: no world")


func test_a_moving_stand_gets_the_vignette_without_a_world() -> void:
	for i in 30:
		Vr.rig.velocity = Vector3(2.5, 0, 0)   # swimming at a voyage's top speed
		Vr.step(1.0 / 72.0)
	assert_gt(Vr.vignette_amount(), 0.0, "a swim is never without the comfort vignette")


func test_a_still_stand_gets_none() -> void:
	for i in 30:
		Vr.rig.velocity = Vector3.ZERO
		Vr.step(1.0 / 72.0)
	assert_eq(Vr.vignette_amount(), 0.0)
