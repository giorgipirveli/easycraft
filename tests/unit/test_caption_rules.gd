extends GutTest
## M5 Task 1 (spec §15.1a): which sounds get a caption (a monster nearby, the Sneaker's jingle, a hiss, a boss's roar,
## the Sand Serpent's rumble, the wave horn, night falling, someone talking), and how often: one per kind every REST
## seconds, at most MAX_SHOWN at once.

func test_the_important_sounds_have_a_caption_kind() -> void:
	var want := {&"grunt": &"monster", &"squish": &"monster", &"moan": &"monster", &"growl": &"monster",
		&"scorpion_click": &"monster", &"yeti_roar": &"monster", &"screech": &"monster", &"shadow_squeak": &"monster",
		&"wisp_charge": &"monster", &"jingle": &"sneak", &"hiss": &"hiss", &"golem_roar": &"boss",
		&"serpent_roar": &"boss", &"giant_roar": &"boss", &"cake_roar": &"boss", &"sky_dragon_roar": &"boss",
		&"serpent_rumble": &"rumble", &"horn": &"horn", &"babble": &"talk"}
	for sound: StringName in want:
		assert_eq(CaptionRules.kind_of(sound), want[sound], String(sound))


func test_everyday_sounds_have_none() -> void:
	for sound: StringName in [&"place", &"break", &"step", &"ui_click", &"coin", &"moo", &"bark", &"swing", &"&nothing"]:
		assert_eq(CaptionRules.kind_of(sound), &"", String(sound))


func test_every_captioned_sound_is_a_real_sound_and_every_kind_has_words_and_a_picture() -> void:
	for sound: StringName in CaptionRules.SOUNDS:
		assert_true(Audio.SOUNDS.has(sound), "%s is one of Audio's sounds" % sound)
	for kind: StringName in CaptionRules.KINDS:
		var k: Dictionary = CaptionRules.KINDS[kind]
		assert_ne(str(k.words), "", String(kind))
		assert_true(CaptionRules.ICONS.has(k.icon), "%s has a picture" % kind)
		assert_lte(str(k.words).length(), 18, "%s: a few words" % kind)
	assert_true(CaptionRules.KINDS.has(&"night"))


func test_one_per_kind_every_few_seconds_and_three_at_most() -> void:
	var last := {}
	assert_true(CaptionRules.may_show(&"monster", 10.0, last, 0))
	last[&"monster"] = 10.0
	assert_false(CaptionRules.may_show(&"monster", 10.0 + CaptionRules.REST - 0.1, last, 1), "rests")
	assert_true(CaptionRules.may_show(&"monster", 10.0 + CaptionRules.REST, last, 1))
	assert_true(CaptionRules.may_show(&"boss", 10.1, last, 1), "another kind may show")
	assert_false(CaptionRules.may_show(&"boss", 10.1, last, CaptionRules.MAX_SHOWN), "three at most")


func test_a_caption_sits_towards_its_sound_inside_the_screen() -> void:
	var screen := Vector2(1280, 720)
	var right := CaptionRules.place(screen, Vector2.RIGHT)
	var behind := CaptionRules.place(screen, Vector2.DOWN)
	var up := CaptionRules.place(screen, Vector2.UP)
	assert_gt(right.x, 900.0)
	assert_almost_eq(right.y, 360.0, 1.0)
	assert_gt(behind.y, 500.0, "behind the camera: the bottom")
	assert_lt(behind.y, 642.0 - CaptionRules.CHIP.y * 0.5, "above the hotbar")
	assert_lt(up.y, 360.0)
	for p: Vector2 in [right, behind, up, CaptionRules.place(screen, Vector2(-1, -1).normalized())]:
		assert_true(Rect2(Vector2.ZERO, screen).encloses(Rect2(p - CaptionRules.CHIP * 0.5, CaptionRules.CHIP)))
