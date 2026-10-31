extends GutTest
## M5 Task 1 (spec §15.1a): Sound captions on the HUD. An important sound (Audio.sound_played) shows a small chip with
## a picture and a word, placed towards the sound (a grunt behind the camera: at the bottom; to the right: on the
## right). The same kind rests a few seconds; the setting turns them off; night falling shows one; with Reduce motion
## a chip never pulses. A 1280 × 720 view with a camera looking down -Z.

var _saved := {}


class Clock:
	extends Node
	var time := DayCycle.NOON


func before_each() -> void:
	_saved = {"captions": Profile.data.settings.captions, "reduce_motion": Profile.data.settings.reduce_motion}
	Profile.data.settings.captions = true
	Profile.data.settings.reduce_motion = false


func after_each() -> void:
	for key: String in _saved:
		Profile.data.settings[key] = _saved[key]


func _captions() -> SoundCaptions:
	var view := SubViewport.new()
	view.size = Vector2i(1280, 720)
	add_child_autofree(view)
	var cam := Camera3D.new()
	view.add_child(cam)
	cam.current = true
	var c := SoundCaptions.new()
	c.sky = Clock.new()
	autofree(c.sky)
	view.add_child(c)
	await wait_process_frames(2)
	return c


func test_a_monster_behind_shows_a_caption_at_the_bottom() -> void:
	var c := await _captions()
	Audio.sound_played.emit(&"grunt", Vector3(0, 0, 6), -6.0)   # behind the camera (it looks down -Z)
	assert_eq(c.count(), 1)
	assert_eq(c.kind(0), &"monster")
	assert_gt(c.chip_rect(0).get_center().y, 480.0, "behind: at the bottom")
	Audio.sound_played.emit(&"golem_roar", Vector3(8, 0, -2), 0.0)   # to the right
	assert_eq(c.count(), 2)
	assert_gt(c.chip_rect(1).get_center().x, 900.0, "to the right: on the right")
	assert_false(c.chip_rect(0).intersects(c.chip_rect(1)), "two chips never cover each other")


func test_the_same_kind_rests_and_everyday_sounds_show_nothing() -> void:
	var c := await _captions()
	c.hear(&"grunt", Vector3(0, 0, -6))
	c.hear(&"moan", Vector3(0, 0, -6))
	assert_eq(c.count(), 1, "one monster caption at a time")
	c.hear(&"place", Vector3(0, 0, -2))
	c.hear(&"moo", Vector3(0, 0, -2))
	assert_eq(c.count(), 1)
	c.tick(CaptionRules.SHOW_TIME + 0.1)
	assert_eq(c.count(), 0, "it goes after a moment")
	c.tick(CaptionRules.REST)
	c.hear(&"grunt", Vector3(0, 0, -6))
	assert_eq(c.count(), 1, "and may come again")


func test_the_setting_turns_them_off() -> void:
	var c := await _captions()
	Profile.data.settings.captions = false
	c.hear(&"horn")
	assert_eq(c.count(), 0)
	Profile.data.settings.captions = true
	c.hear(&"horn")
	assert_eq(c.count(), 1, "a flat sound shows too")


func test_night_falling_shows_a_caption_once() -> void:
	var c := await _captions()
	c.tick(1.0)
	assert_eq(c.count(), 0, "noon")
	(c.sky as Clock).time = DayCycle.NIGHT_START + 0.01
	c.tick(1.0)
	assert_eq(c.count(), 1)
	assert_eq(c.kind(0), &"night")
	c.tick(1.0)
	assert_eq(c.count(), 1, "once")


func test_reduce_motion_never_pulses_a_caption() -> void:
	var c := await _captions()
	c.hear(&"hiss", Vector3(3, 0, -3))
	assert_gt(c.chip_scale(0), 1.0, "a new chip pops a little")
	Profile.data.settings.reduce_motion = true
	c.hear(&"horn", Vector3(-3, 0, -3))
	assert_eq(c.chip_scale(1), 1.0, "with Reduce motion it just shows")


func test_the_hud_has_captions_under_its_messages() -> void:
	var hud := Hud.new()
	add_child_autofree(hud)
	await wait_process_frames(1)
	assert_not_null(hud.captions)
	assert_eq(hud.captions.get_parent(), hud)
	assert_lt(hud.captions.get_index(), hud._toast_panel.get_index(), "under the toasts")
	assert_eq(hud.captions.mouse_filter, Control.MOUSE_FILTER_IGNORE, "never in the way of a tap")
