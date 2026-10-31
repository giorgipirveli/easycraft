extends GutTest
## Jingles and horns (the audio pass, owner feedback #27): a level-up, a finished goal and a new badge
## (M3 Task 12's Progress) each play their own little tune on this game; a wave starts with a horn at
## the Totem (M2 Task 9).


func before_each() -> void:
	Audio.stop_all()


func after_each() -> void:
	Progress.end()
	Session.progress_reset()


func after_all() -> void:
	Audio.stop_all()


func _director() -> ProgressDirector:
	var dir := ProgressDirector.new()
	dir.data_override = ProgressData.new()
	add_child_autofree(dir)
	return dir


func test_a_level_up_plays_the_level_jingle() -> void:
	_director()
	Audio.last_sound = &""
	Progress.leveled_up.emit(2)
	assert_eq(Audio.last_sound, &"jingle_level")


func test_a_goal_done_plays_the_goal_jingle() -> void:
	_director()
	Audio.last_sound = &""
	Progress.goal_done.emit(&"no_such_goal", 0)
	assert_eq(Audio.last_sound, &"jingle_goal")


func test_a_new_badge_plays_the_badge_jingle() -> void:
	_director()
	Audio.last_sound = &""
	Progress.badge_unlocked.emit(&"no_such_badge")
	assert_eq(Audio.last_sound, &"jingle_badge")


func test_a_wave_starts_with_a_horn() -> void:
	var waves := WaveDirector.new()
	add_child_autofree(waves)
	Audio.last_sound = &""
	waves._rpc_fx(Vector3(0, 10, 0), WaveDirector.FX_START)
	assert_eq(Audio.last_sound, &"horn")
