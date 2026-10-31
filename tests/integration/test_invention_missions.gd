extends GutTest
## Owner #78 (spec §21e): in Survivor the rocket invention opens the Launch Site's missions, and only there: the
## Mission Board says so when it opens and LAUNCH refuses until the rocket is invented; the Sandbox's missions stay
## open. The board asks the sandbox's gate (InventionRules.missions_open).

var board: MissionBoard
var launched: Array = []
var data: InventionData
var free_fly := false


func before_each() -> void:
	launched = []
	data = InventionData.new()
	free_fly = false
	board = MissionBoard.new()
	board.read_rocket = func() -> Dictionary: return {}
	board.available = func() -> Array[int]: return [16] as Array[int]
	board.launch = func(r: Dictionary) -> String:
		launched.append(r)
		return ""
	board.gate = func() -> String:
		return "" if InventionRules.missions_open(free_fly, data) else InventionRules.MISSIONS_WORDS
	add_child_autofree(board)


func test_survivor_s_board_needs_the_rocket_invented() -> void:
	board.open()
	assert_eq(board.message(), InventionRules.MISSIONS_WORDS, "said when it opens")
	assert_eq(board.press_launch(), InventionRules.MISSIONS_WORDS)
	assert_eq(launched, [], "LAUNCH refuses")
	data = InventionData.invented_to(InventionLine.ROCKET)
	board.close()
	board.open()
	assert_eq(board.message(), "", "the rocket is invented: the missions are open")
	assert_string_starts_with(board.press_launch(), "Not yet: 1 line to fix.", "now it is the rocket's own check (owner #98: what to fix)")


func test_the_sandbox_s_missions_stay_open() -> void:
	free_fly = true
	board.open()
	assert_eq(board.message(), "")
	assert_ne(board.press_launch(), InventionRules.MISSIONS_WORDS)
