extends GutTest
## Owner #117 (docs/design/life-skills.md §13, "The Tool Book"; §11): the book of every tool and device by area, each with
## its picture and three stamps; "you can use N tools"; a tool's page says what it is for, how to hold it, its motion in
## VR and on a phone, its safety rule (a grown-up's job says so) and a device's right order. The flat tray and pictures.


func _page(p: ProfileData = null) -> ToolBookPage:
	var page := ToolBookPage.new(p if p != null else ProfileData.new())
	add_child_autofree(page)
	return page


func test_every_area_and_every_tool_is_in_the_book() -> void:
	var page := _page()
	for area in ToolBook.AREAS:
		assert_not_null(page.find_child("Area_" + area, true, false), area)
	for id in ToolBook.ids():
		assert_not_null(page.find_child("Tool_" + id, true, false), id)


func test_you_can_use_counts_what_the_child_did_alone() -> void:
	var p := ProfileData.new()
	assert_eq(_page(p).headline(), "My Tool Book: you can use 0 tools")
	p.tools.record([{"tool": "trowel", "hinted": false}, {"tool": "saw", "hinted": true}], false)
	assert_eq(_page(p).headline(), "My Tool Book: you can use 1 tool")


func test_a_tools_card_shows_its_stamps() -> void:
	var p := ProfileData.new()
	p.tools.record([{"tool": "hammer", "hinted": false}], true)
	var page := _page(p)
	var card := page.find_child("Tool_hammer", true, false) as Button
	var stamps: Array = card.find_children("*", "", true, false)
	assert_gt(stamps.size(), 3)
	assert_eq(p.tools.stamps_of("hammer"), LifeData.DONE | LifeData.SELF | LifeData.EXPERT)


func test_a_tools_page_says_everything_a_child_needs() -> void:
	var lines := ToolBookPage.lines("saw")
	var text := "\n".join(PackedStringArray(lines))
	assert_string_contains(text, "cutting wood to length")
	assert_string_contains(text, "long, slow strokes")
	assert_string_contains(text, "Stroke: in VR, back and forth along a line; on a phone, drag back and forth.")
	assert_string_contains(text, "Goggles on")


func test_a_devices_page_says_its_right_order() -> void:
	var text := "\n".join(PackedStringArray(ToolBookPage.lines("mixer")))
	assert_string_contains(text, "The right order: gloves on, then goggles on, then switch it on")


func test_a_grown_ups_job_says_so() -> void:
	var page := _page()
	page.show_tool("mixer")
	assert_not_null(page.find_child("GrownUpsJob", true, false))
	page.show_tool("trowel")
	assert_null(page.find_child("GrownUpsJob", true, false))


func test_back_goes_back_and_closes() -> void:
	var page := _page()
	var closed := []
	page.closed.connect(func() -> void: closed.append(true))
	page.show_tool("tape")
	assert_eq(page.showing, "tape")
	(page.find_child("Back", true, false) as Button).pressed.emit()
	assert_eq(page.showing, "")
	(page.find_child("Back", true, false) as Button).pressed.emit()
	assert_eq(closed.size(), 1)


func test_every_motion_has_its_words_for_vr_and_a_phone() -> void:
	for m in ToolMotion.ALL:
		var how: Dictionary = ToolMotion.HOW[m]
		for key: String in ["name", "vr", "phone"]:
			assert_ne(str(how.get(key, "")), "", "%s %s" % [m, key])


func test_every_tool_has_a_picture() -> void:
	for id in ToolBook.ids():
		assert_true(ToolIcons.has(ToolBook.icon(id)) or ToolIcons.NAMES.has(ToolBook.icon(id)), "%s: %s" % [id,
			ToolBook.icon(id)])
		assert_ne(ToolIcons.resolve(ToolBook.icon(id)), "tool", id + " has its own drawing")
	for name in ToolIcons.NAMES:
		var pic := ToolIcons.new(name, 64.0)
		add_child_autofree(pic)
		pic.queue_redraw()
	await wait_process_frames(2)


func test_the_tray_picks_one_tool_at_a_time_and_glows_the_right_one() -> void:
	var tray := ToolTray.new()
	add_child_autofree(tray)
	tray.set_tools(["trowel", "spirit_level", "tape"] as Array[String])
	var heard := []
	tray.picked.connect(func(id: String) -> void: heard.append(id))
	(tray.buttons.trowel as Button).pressed.emit()
	assert_eq(tray.selected, "trowel")
	assert_eq(heard, ["trowel"])
	assert_true((tray.buttons.trowel as Button).button_pressed)
	tray.select("tape")
	assert_false((tray.buttons.trowel as Button).button_pressed, "one tool in the hand")
	tray.glow("spirit_level")
	await wait_process_frames(10)
	assert_ne((tray.buttons.spirit_level as Button).modulate, Color.WHITE, "the right one glows")
