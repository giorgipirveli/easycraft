extends GutTest
## The quick-chat wheel (M4 Wave 2, Agent E; spec §5.13, §17.4): eight picture phrases around the
## middle, big enough for small fingers, tapped to send; extra pills for commands and emotes.

var wheel: QuickChatWheel
var chosen: Array[String] = []
var events: Array[String] = []


func before_each() -> void:
	chosen.clear()
	events.clear()
	wheel = QuickChatWheel.new()
	add_child_autofree(wheel)
	wheel.size = Vector2(1280, 720)
	wheel.chosen.connect(func(p: String) -> void: chosen.append(p))
	wheel.closed.connect(func() -> void: events.append("closed"))
	wheel.commands_requested.connect(func() -> void: events.append("commands"))
	wheel.emotes_requested.connect(func() -> void: events.append("emotes"))
	wheel.tapped_outside.connect(func(_at: Vector2) -> void: events.append("outside"))


func _tap(at: Vector2) -> void:
	for pressed in [true, false]:
		var t := InputEventScreenTouch.new()
		t.position = at
		t.pressed = pressed
		wheel._input(t)


func test_the_wheel_holds_the_eight_phrases_with_pictures() -> void:
	wheel.open()
	assert_true(wheel.visible)
	assert_eq(wheel.phrases(), OnlineChatRules.WHEEL)
	var rects := wheel.slot_rects()
	assert_eq(rects.size(), 8)
	var screen := Rect2(Vector2.ZERO, Vector2(1280, 720))
	for i in rects.size():
		assert_gte(rects[i].size.x, OnlineUi.MIN_WIDTH, "a big slot for small fingers")
		assert_true(screen.encloses(rects[i]), "slot %d on the screen" % i)
		for j in range(i + 1, rects.size()):
			assert_false(rects[i].grow(-4).intersects(rects[j].grow(-4)), "slots %d and %d apart" % [i, j])
	for phrase in OnlineChatRules.WHEEL:
		assert_true(ChatPictures.KINDS.has(OnlineChatRules.PICTURES[phrase]), phrase)


func test_a_tap_on_a_slot_sends_its_phrase_and_closes() -> void:
	wheel.open()
	_tap(wheel.slot_rects()[3].get_center())
	assert_eq(chosen, [OnlineChatRules.WHEEL[3]] as Array[String])
	assert_false(wheel.visible)
	assert_true(events.has("closed"))


func test_the_middle_closes_without_sending() -> void:
	wheel.open()
	_tap(Vector2(640, 360))
	assert_eq(chosen, [] as Array[String])
	assert_false(wheel.visible)
	assert_false(events.has("outside"), "the middle is the close button")


func test_a_tap_outside_closes_and_says_where() -> void:
	wheel.open()
	_tap(Vector2(60, 60))
	assert_false(wheel.visible)
	assert_true(events.has("outside"), "the chat panel looks for a message there (mute / report)")


func test_the_pills_for_commands_and_emotes_show_only_when_asked() -> void:
	wheel.open()
	assert_eq(wheel.pill_rects().size(), 0)
	wheel.open(true, true)
	var pills := wheel.pill_rects()
	assert_eq(pills.size(), 2)
	for p in pills:
		assert_gte(p.size.x, OnlineUi.MIN_WIDTH)
		assert_gte(p.size.y, OnlineUi.MIN_HEIGHT)
		assert_true(Rect2(Vector2.ZERO, Vector2(1280, 720)).encloses(p))
		for s in wheel.slot_rects():
			assert_false(p.intersects(s), "pills clear of the slots")
	_tap(pills[0].get_center())
	assert_eq(events, ["closed", "commands"] as Array[String], "it closes, then the commands open")
	wheel.open(true, true)
	_tap(wheel.pill_rects()[1].get_center())
	assert_true(events.has("emotes"))


func test_a_finger_that_slides_off_sends_nothing() -> void:
	wheel.open()
	var down := InputEventScreenTouch.new()
	down.position = wheel.slot_rects()[0].get_center()
	down.pressed = true
	wheel._input(down)
	var up := InputEventScreenTouch.new()
	up.position = wheel.slot_rects()[1].get_center()
	wheel._input(up)
	assert_eq(chosen, [] as Array[String])


func test_pausing_closes_it() -> void:
	wheel.open()
	wheel._notification(Node.NOTIFICATION_PAUSED)
	assert_false(wheel.visible)
