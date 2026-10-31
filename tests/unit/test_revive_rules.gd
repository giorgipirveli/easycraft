extends GutTest
## Helping a knocked-out teammate up, as pure rules (M4 Wave 2, Agent E; spec §17.5, §12.3): the
## knocked-out player waits a little when a teammate is near; a teammate holds HELP UP near them for
## 3 s; only a knocked-out teammate who is still down (not already getting up and protected); the
## helper must be up and within reach; the words are short and kind.

const R := preload("res://core/survival/revive_rules.gd")


func test_a_friend_near_makes_the_knocked_out_player_wait_for_help() -> void:
	assert_eq(R.down_time(0), KnockoutRules.KO_TIME, "alone: up again as before")
	assert_eq(R.down_time(1), R.WAIT_TIME)
	assert_eq(R.down_time(3), R.WAIT_TIME)
	assert_gt(R.WAIT_TIME, R.HOLD_TIME + 3.0, "time to walk over and help")
	assert_lte(R.WAIT_TIME, 12.0, "never a long wait")
	assert_true(R.calls_for_help(Vector3.ZERO, Vector3(R.CALL_DISTANCE - 0.5, 0, 0)))
	assert_false(R.calls_for_help(Vector3.ZERO, Vector3(R.CALL_DISTANCE + 0.5, 0, 0)))


func test_holding_takes_three_seconds() -> void:
	assert_eq(R.HOLD_TIME, 3.0)
	assert_false(R.done(2.9))
	assert_true(R.done(3.0))
	assert_almost_eq(R.progress(1.5), 0.5, 0.001)
	assert_eq(R.progress(-1.0), 0.0)
	assert_eq(R.progress(9.0), 1.0)


func test_reach_is_near_the_friend_and_grows_with_a_giant() -> void:
	assert_true(R.in_reach(Vector3.ZERO, Vector3(2.5, 0, 0)))
	assert_false(R.in_reach(Vector3.ZERO, Vector3(R.REACH + 0.5, 0, 0)))
	assert_true(R.in_reach(Vector3.ZERO, Vector3(R.REACH + 0.5, 0, 0), 2.0), "a giant reaches further")
	assert_true(R.in_reach(Vector3.ZERO, Vector3(2.0, 0, 0), 0.25), "a tiny helper still reaches a normal friend")
	assert_false(R.in_reach(Vector3.ZERO, Vector3.INF))


func test_who_can_help_whom() -> void:
	var ok := {"helper": 2, "friend": 7, "friend_down": true, "friend_protected": false, "helper_down": false, "near": true}
	assert_eq(_why(ok), &"")
	assert_eq(_why(_with(ok, "helper", 7)), R.SELF, "not yourself")
	assert_eq(_why(_with(ok, "friend_down", false)), R.NOT_DOWN, "only a knocked-out teammate")
	assert_eq(_why(_with(ok, "friend_protected", true)), R.PROTECTED, "not while they are getting up, protected")
	assert_eq(_why(_with(ok, "helper_down", true)), R.HELPER_DOWN, "a knocked-out helper can't")
	assert_eq(_why(_with(ok, "near", false)), R.TOO_FAR)


func test_every_word_is_short_and_kind() -> void:
	var lines: Array[String] = [R.WAITING, R.helping_you("Pip"), R.helped_you("Pip"), R.you_helped("Pip"),
		R.someone_helped("Pip", "Max"), R.refusal_message(R.TOO_FAR), R.HELP_BUTTON, R.GET_UP_BUTTON]
	for l in lines:
		assert_ne(l, "")
		assert_lte(l.split(" ").size(), 8, l)
	assert_eq(R.helped_you("Pip"), "Pip helped you up!")
	assert_eq(R.refusal_message(R.NOT_DOWN), "", "nothing to say when there is nobody to help")


func _why(d: Dictionary) -> StringName:
	return R.refusal(d.helper, d.friend, d.friend_down, d.friend_protected, d.helper_down, d.near)


func _with(d: Dictionary, key: String, value: Variant) -> Dictionary:
	var out := d.duplicate()
	out[key] = value
	return out
