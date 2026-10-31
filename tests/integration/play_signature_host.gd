extends PlayHost
## The registry's tests (owner #133, #134; docs/devlog/parts/game-leaf-b.md B2.1): a stand-in deep game with its own host,
## registered in a test's own "signature" table as {"host": this script}. It keeps what it was opened with, opens like a
## PlayHost (in PlayHost.GROUP, the screen it came from hidden) and ends when a test says so, as a real game's round does.

## Each setup's `count` (a crystal's short round, or 0).
var counts: Array[int] = []
## The unit's play params when it was set up (the leaf's voyage, a bakery's room...).
var params := {}


func setup(id: String, unit_content: Dictionary, run_seed: int, unit_stars: int, outline: Dictionary = {},
		count: int = 0) -> void:
	unit_id = id
	content = unit_content
	seed = run_seed
	stars = unit_stars
	unit = outline
	params = PlayBlock.params(unit_content)
	shown = SkillShown.begin()
	counts.append(count)


func open(parent: Node) -> void:
	name = "StandInHost"
	add_to_group(PlayHost.GROUP)
	parent.add_child(self)
	_hide_screen(parent)


## The game's round ends: `right` of `total` challenges solved with no help (the rest helped); `then` asks the caller to
## open the unit again with these params ({} for none).
func finish_now(right: int, total: int, then: Dictionary = {}) -> void:
	for i in total:
		shown.add(unit_id, SkillShown.SOLVED if i < right else SkillShown.HELPED)
	closed = true
	finished.emit({"right_first": shown.right_first(unit_id), "total": shown.total(unit_id), "world_task": "",
		"shown": shown, "then": then})
	close()


func stop_for_now() -> void:
	if closed:
		return
	closed = true
	stopped.emit({"right_first": 0, "answered": 0})
	close()
