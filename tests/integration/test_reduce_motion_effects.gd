extends GutTest
## M5 Task 1 (spec §15.1a): Reduce motion also calms the newer effects: the bursts of gadgets, piñatas and blasters, the
## rocket's confetti, the farm's coin shower and the menus' coin rain: half the pieces, slower, no spin. Off, they are
## as before.

var _reduce := false


func before_each() -> void:
	_reduce = bool(Profile.data.settings.reduce_motion)


func after_each() -> void:
	Profile.data.settings.reduce_motion = _reduce


func test_the_rules() -> void:
	assert_eq(FeelRules.burst_amount(12, false), 12)
	assert_eq(FeelRules.burst_amount(12, true), 6)
	assert_eq(FeelRules.burst_amount(1, true), 1, "never none")
	assert_eq(FeelRules.burst_speed_scale(false), 1.0)
	assert_lt(FeelRules.burst_speed_scale(true), 1.0)


func test_a_burst_is_calmer_with_reduce_motion() -> void:
	var root := Node3D.new()
	add_child_autofree(root)
	Profile.data.settings.reduce_motion = false
	var p := Fx.burst(root, Vector3.ZERO, Color.RED, 20)
	assert_eq(p.amount, 20)
	assert_eq(p.speed_scale, 1.0)
	assert_gt(p.angular_velocity_max, 0.0)
	Profile.data.settings.reduce_motion = true
	var q := Fx.burst(root, Vector3.ZERO, Color.RED, 20)
	assert_eq(q.amount, 10)
	assert_lt(q.speed_scale, 1.0)
	assert_eq(q.angular_velocity_max, 0.0, "no spin")
	assert_eq(q.angular_velocity_min, 0.0)
	var coins := Fx.coin_shower(root, Vector3.ZERO, 240)
	assert_lt(coins.speed_scale, 1.0, "the farm's coin shower too")
	assert_eq(coins.angular_velocity_max, 0.0)


func test_the_blasters_pooled_bursts_and_confetti_follow_the_setting_each_time() -> void:
	var d := BlasterDirector.new()
	add_child_autofree(d)
	await wait_process_frames(1)
	Profile.data.settings.reduce_motion = true
	d.burst(Vector3.ZERO, Color.BLUE)
	d.confetti(Vector3.ZERO)
	assert_eq(d._bursts[0].amount, 6)
	assert_eq(d._confetti[0].amount, 20)
	assert_lt(d._confetti[0].speed_scale, 1.0)
	Profile.data.settings.reduce_motion = false
	for i in d._bursts.size():
		d.burst(Vector3.ZERO, Color.BLUE)
	for i in d._confetti.size():
		d.confetti(Vector3.ZERO)
	assert_eq(d._bursts[0].amount, 12, "back as it was")
	assert_eq(d._confetti[0].amount, 40)
	assert_eq(d._confetti[0].speed_scale, 1.0)


func test_the_menus_coin_rain_is_gentler() -> void:
	Profile.data.settings.reduce_motion = false
	var loud := CoinShower.new(48)
	assert_eq(loud.coin_count(), 48)
	loud.free()
	Profile.data.settings.reduce_motion = true
	var calm := CoinShower.new(48)
	assert_lte(calm.coin_count(), 16, "a third of the coins")
	assert_true(calm.calm, "no spin, no sway")
	calm.free()
