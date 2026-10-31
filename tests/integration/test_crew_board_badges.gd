extends GutTest
## Crew flights (spec §21d.6 phase 2, the brief's item 4): a crew badge ("Crew of the Moon mission with Anna and Sam")
## shows on its mission's card on the Mission Board's MISSIONS page (the board's `badges` hook reads the profile's
## CrewBadges); a mission flown alone has none.

var board: MissionBoard


func before_each() -> void:
	board = MissionBoard.new()
	board.available = func() -> Array[int]: return [SpaceRules.MOON, SpaceRules.MARS] as Array[int]
	board.route = func() -> Array[int]: return [SpaceRules.MOON] as Array[int]
	board.badges = func(w: int) -> Array:
		return ["Crew of the Moon mission with Anna and Sam"] if w == SpaceRules.MOON else []
	add_child_autofree(board)


func _texts(n: Node) -> Array[String]:
	var out: Array[String] = []
	if n is Label:
		out.append((n as Label).text)
	for c in n.get_children():
		out.append_array(_texts(c))
	return out


func test_the_missions_page_shows_the_crew_badge_on_its_mission() -> void:
	board.open()
	board.show_page(MissionBoard.MISSIONS_PAGE)
	var texts := _texts(board)
	assert_has(texts, "★ Crew of the Moon mission with Anna and Sam")
	assert_eq(texts.filter(func(t: String) -> bool: return t.begins_with("★")).size(), 1, "Mars was flown alone: none")
