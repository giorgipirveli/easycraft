extends GutTest
## When a body's water effects happen (M2 Task 14, owner feedback #17: "add water effects, like
## swimming, splashing"). SwimEffects is fed the body's (synced) water state and velocity each frame,
## on every peer, and says which effects are due.

const DT := 1.0 / 60.0
const DRY := SwimRules.State.DRY
const WADING := SwimRules.State.WADING
const SWIMMING := SwimRules.State.SWIMMING
const DIVING := SwimRules.State.DIVING


## Runs `fx` for `seconds` in `state` at `velocity`; returns how many of each event happened.
static func _run(fx: SwimEffects, seconds: float, state: int, velocity: Vector3) -> Dictionary:
	var counts := {}
	for i in maxi(int(round(seconds / DT)), 1):
		for e: StringName in fx.update(DT, state, velocity):
			counts[e] = int(counts.get(e, 0)) + 1
	return counts


func test_jumping_in_splashes_once_and_its_size_follows_the_speed() -> void:
	var fx := SwimEffects.new()
	_run(fx, 0.5, DRY, Vector3.ZERO)
	var events := fx.update(DT, SWIMMING, Vector3(0, -9, 0))
	assert_has(events, &"splash")
	var jump := fx.splash
	assert_gt(jump, 0.4)
	var fall := SwimEffects.new()
	fall.update(DT, DRY, Vector3.ZERO)
	fall.update(DT, WADING, Vector3(0, -18, 0))
	assert_gt(fall.splash, jump, "a higher fall makes a bigger splash")
	assert_false(_run(fx, 1.0, SWIMMING, Vector3.ZERO).has(&"splash"), "only on the way in")


func test_wading_in_slowly_does_not_splash() -> void:
	var fx := SwimEffects.new()
	fx.update(DT, DRY, Vector3.ZERO)
	assert_false(fx.update(DT, WADING, Vector3(1, 0, 0)).has(&"splash"))


func test_hopping_in_and_out_quickly_splashes_once() -> void:
	var fx := SwimEffects.new()
	fx.update(DT, DRY, Vector3.ZERO)
	var splashes := 0
	for i in 3:
		splashes += _run(fx, 0.05, WADING, Vector3(6, 0, 0)).get(&"splash", 0)
		_run(fx, 0.05, DRY, Vector3(6, 0, 0))
	assert_eq(splashes, 1)
	_run(fx, SwimEffects.SPLASH_COOLDOWN, DRY, Vector3.ZERO)
	assert_eq(_run(fx, 0.05, WADING, Vector3(6, 0, 0)).get(&"splash", 0), 1, "after a moment it splashes again")


func test_ripples_spread_around_a_swimmer_faster_when_it_moves() -> void:
	var fx := SwimEffects.new()
	var moving := int(_run(fx, 3.0, SWIMMING, Vector3(3, 0, 0)).get(&"ripple", 0))
	var idle := int(_run(fx, 3.0, SWIMMING, Vector3.ZERO).get(&"ripple", 0))
	assert_between(moving, int(3.0 / SwimEffects.RIPPLE_MOVING) - 1, int(3.0 / SwimEffects.RIPPLE_MOVING) + 1)
	assert_between(idle, 1, int(3.0 / SwimEffects.RIPPLE_IDLE) + 1, "a floating swimmer still rocks the water")
	assert_eq(int(_run(fx, 3.0, DIVING, Vector3(3, 0, 0)).get(&"ripple", 0)), 0, "no ripples from under water")
	assert_gt(int(_run(fx, 3.0, WADING, Vector3(3, 0, 0)).get(&"ripple", 0)), 0, "wading makes ripples too")
	assert_eq(int(_run(fx, 3.0, WADING, Vector3.ZERO).get(&"ripple", 0)), 0, "standing in a puddle: calm")


func test_bubbles_rise_only_from_a_diver() -> void:
	var fx := SwimEffects.new()
	assert_eq(int(_run(fx, 3.0, SWIMMING, Vector3(3, 0, 0)).get(&"bubbles", 0)), 0, "head above the water")
	var diving := int(_run(fx, 3.0, DIVING, Vector3(0, -3, 0)).get(&"bubbles", 0))
	assert_between(diving, int(3.0 / SwimEffects.BUBBLE_EVERY) - 1, int(3.0 / SwimEffects.BUBBLE_EVERY) + 1)
	assert_eq(int(_run(fx, 3.0, DRY, Vector3.ZERO).get(&"bubbles", 0)), 0)


func test_climbing_out_after_a_swim_drips_once() -> void:
	var fx := SwimEffects.new()
	_run(fx, 1.0, SWIMMING, Vector3(2, 0, 0))
	_run(fx, 0.1, WADING, Vector3(2, 3, 0))
	var out := _run(fx, 1.0, DRY, Vector3(2, 0, 0))
	assert_eq(int(out.get(&"drips", 0)), 1)
	var wader := SwimEffects.new()
	_run(wader, 1.0, WADING, Vector3(2, 0, 0))
	assert_eq(int(_run(wader, 1.0, DRY, Vector3.ZERO).get(&"drips", 0)), 0, "wet feet only: no drips")


func test_footsteps_are_wet_in_and_for_a_while_after_the_water() -> void:
	var fx := SwimEffects.new()
	_run(fx, 1.0, DRY, Vector3.ZERO)
	assert_false(fx.wet_feet(), "never in the water")
	_run(fx, 0.5, WADING, Vector3(2, 0, 0))
	assert_true(fx.wet_feet(), "wading")
	_run(fx, SwimEffects.WET_TIME - 0.5, DRY, Vector3(2, 0, 0))
	assert_true(fx.wet_feet(), "still wet after walking out")
	_run(fx, 1.0, DRY, Vector3(2, 0, 0))
	assert_false(fx.wet_feet(), "dry again")


func test_swim_strokes_sound_while_swimming_along() -> void:
	var fx := SwimEffects.new()
	var along := int(_run(fx, 3.0, SWIMMING, Vector3(3, 0, 0)).get(&"stroke", 0))
	assert_between(along, int(3.0 / SwimEffects.STROKE_EVERY) - 1, int(3.0 / SwimEffects.STROKE_EVERY) + 1)
	assert_eq(int(_run(fx, 3.0, SWIMMING, Vector3.ZERO).get(&"stroke", 0)), 0, "floating: quiet")
	assert_eq(int(_run(fx, 3.0, WADING, Vector3(3, 0, 0)).get(&"stroke", 0)), 0, "wading is walking")
