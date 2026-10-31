extends GutTest
## M2 Task 4: /summon slime 3 and /summon goblin 2 reach the sandbox's summon_monster hook on the host,
## and the pause menu's Sandbox world setting "Monsters: ON / OFF" (§12.15).

var lines: Array = []


class FakeSandbox:
	extends Node
	var summoned: Array = []
	var reply := ""

	func summon_monster(kind: StringName, level: int, near: Vector3) -> String:
		summoned.append([kind, level, near])
		return reply


func before_each() -> void:
	lines.clear()
	Session.chat_reset()
	Session.commands_enabled = true
	Session.chat_received.connect(_on_line)


func after_each() -> void:
	Session.chat_received.disconnect(_on_line)
	Session.chat_reset()


func _on_line(from: String, text: String, kind: StringName) -> void:
	lines.append({"from": from, "text": text, "kind": kind})


func _me_in_the_world() -> Player:
	var p: Player = load("res://entities/player/player.tscn").instantiate()
	p.name = str(multiplayer.get_unique_id())
	add_child_autofree(p)
	p.set_physics_process(false)
	p.viewer.free()
	p._spawned = true
	p.global_position = Vector3(3, 20, -4)
	return p


func test_summon_goblin_3_calls_the_sandbox_hook_on_the_host() -> void:
	_me_in_the_world()
	var runner := ChatCommandRunner.new()
	var fake := FakeSandbox.new()
	runner.sandbox = fake
	var me := multiplayer.get_unique_id()
	runner.run_host(me, ChatCommands.parse("/summon goblin 3"))
	assert_eq(fake.summoned, [[MonsterRules.GOBLIN, 3, Vector3(3, 20, -4)]])
	assert_string_contains(lines[-1].text, "goblin")
	fake.reply = "Lots of monsters here already!"
	runner.run_host(me, ChatCommands.parse("/summon slime"))
	assert_eq(fake.summoned[1][1], 1)
	assert_eq(lines[-1].text, "Lots of monsters here already!", "the hook's answer is shown")
	fake.free()
	runner.free()


func test_summon_monster_answers_soon_without_the_hook() -> void:
	_me_in_the_world()
	var runner := ChatCommandRunner.new()
	runner.sandbox = Node.new()
	runner.run_host(multiplayer.get_unique_id(), ChatCommands.parse("/summon slime 2"))
	assert_eq(lines[-1].text, ChatCommandRunner.SOON)
	runner.sandbox.free()
	runner.free()


# --- The pause menu's world setting ---

func _menu() -> PauseMenu:
	var m := PauseMenu.new()
	add_child_autofree(m)
	return m


func _button(m: PauseMenu, prefix: String) -> Button:
	for b in m.find_children("*", "Button", true, false):
		if (b as Button).text.begins_with(prefix):
			return b
	return null


func test_sandbox_worlds_have_a_monsters_on_off_button() -> void:
	var m := _menu()
	m.show_monsters_setting(true)
	m.open()
	await get_tree().process_frame
	var b := _button(m, "MONSTERS")
	assert_not_null(b)
	assert_eq(b.text, "MONSTERS: ON")
	watch_signals(m)
	b.pressed.emit()
	assert_eq(b.text, "MONSTERS: OFF")
	assert_signal_emitted_with_parameters(m, "monsters_toggled", [false])
	b.pressed.emit()
	assert_eq(b.text, "MONSTERS: ON")
	assert_signal_emitted_with_parameters(m, "monsters_toggled", [true])
	m.close()


func test_the_button_remembers_off_and_other_worlds_have_none() -> void:
	var m := _menu()
	m.show_monsters_setting(false)
	m.open()
	await get_tree().process_frame
	assert_eq(_button(m, "MONSTERS").text, "MONSTERS: OFF")
	m.close()
	var plain := _menu()
	plain.open()
	await get_tree().process_frame
	assert_null(_button(plain, "MONSTERS"), "Survivor worlds and LAN guests: no setting")
	plain.close()


## Merge of Tasks 4 and 15: a Sandbox host's menu has both MONSTERS and FRIENDS; all of it fits the
## 720 px design height, in this order.
func test_the_menu_with_monsters_and_friends_fits_the_screen() -> void:
	var m := _menu()
	m.show_monsters_setting(true)
	var director := BotDirector.new()
	add_child_autofree(director)
	m.friends = director
	m.open()
	await get_tree().process_frame
	var panel := m.find_children("*", "PanelContainer", true, false)[0] as PanelContainer
	assert_lte(panel.size.y, 720.0 - 40.0, "the whole menu fits the 720 px design height, with a margin")
	assert_lte(panel.size.x, 1280.0)
	var order: Array[String] = []
	for prefix in ["RESUME", "SETTINGS", "MONSTERS", "FRIENDS", "SAVE"]:
		assert_not_null(_button(m, prefix), prefix)
		order.append(prefix)
	var ys: Array[float] = []
	for prefix in order:
		ys.append(_button(m, prefix).get_global_rect().position.y)
	var sorted := ys.duplicate()
	sorted.sort()
	assert_eq(ys, sorted, "RESUME, SETTINGS, MONSTERS, FRIENDS, SAVE & QUIT from top to bottom")
	m.close()

