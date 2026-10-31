extends GutTest
## M3 Task 19 (the whole-branch review): /summon's chat line put the animal's id into "%s called a %s!", so owner
## #41's animals read "Pip called a arctic_fox!", "… a owl!", "… a polar_bear!". It says "an owl" and "an arctic fox"
## now, like the monsters' line ("a level 3 shadow bat").


class SummonSandbox:
	extends Node3D
	var player: Player

	func summon_animal(_species: StringName, _near: Vector3) -> String:
		return ""

	func summon_monster(_kind: StringName, _level: int, _near: Vector3) -> String:
		return ""


var _chat: Array[String] = []
var _mode_before: StringName


func before_each() -> void:
	_chat.clear()
	_mode_before = Game.mode
	Game.mode = ModeRules.SANDBOX
	Session.chat_reset()
	Session.commands_enabled = true
	Session.chat_received.connect(_on_chat)


func after_each() -> void:
	Session.chat_received.disconnect(_on_chat)
	Session.chat_reset()
	Game.mode = _mode_before


func _on_chat(_from: String, text: String, _kind: StringName) -> void:
	_chat.append(text)


func _runner() -> ChatCommandRunner:
	var fake := SummonSandbox.new()
	add_child_autofree(fake)
	var p: Player = load("res://entities/player/player.tscn").instantiate()
	p.name = str(multiplayer.get_unique_id())
	fake.add_child(p)
	p.set_physics_process(false)
	p.viewer.free()
	p._spawned = true
	fake.player = p
	var runner := ChatCommandRunner.new()
	runner.sandbox = fake
	add_child_autofree(runner)
	return runner


func _summon(runner: ChatCommandRunner, text: String) -> String:
	_chat.clear()
	runner.run_host(multiplayer.get_unique_id(), ChatCommands.parse(text))
	return _chat.back() if not _chat.is_empty() else ""


func test_an_animal_is_named_in_plain_english() -> void:
	var runner := _runner()
	assert_string_ends_with(_summon(runner, "/summon horse"), " called a horse!")
	assert_string_ends_with(_summon(runner, "/summon owl"), " called an owl!")
	assert_string_ends_with(_summon(runner, "/summon arctic_fox"), " called an arctic fox!")
	assert_string_ends_with(_summon(runner, "/summon polar_bear"), " called a polar bear!")


func test_a_monster_line_is_unchanged() -> void:
	var runner := _runner()
	assert_string_ends_with(_summon(runner, "/summon shadowbat 3"), " called a level 3 shadow bat! Watch out!")
