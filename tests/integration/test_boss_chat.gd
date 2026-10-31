extends GutTest
## M2 Task 10: /summon golem (Sandbox, for testing and fun) reaches the sandbox's summon_boss hook on
## the host; in Survivor the Golem comes only from the Totem (a cheat there, like every /summon).

var lines: Array = []


class FakeSandbox:
	extends Node
	var summoned: Array = []
	var reply := ""

	func summon_boss(near: Vector3) -> String:
		summoned.append(near)
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


func test_summon_golem_parses_in_sandbox_and_is_a_cheat_in_survivor() -> void:
	var r := ChatCommands.parse("/summon Golem")
	assert_eq(r.get("boss"), &"golem")
	assert_false(r.has("species") or r.has("monster"), "the boss is neither an animal nor a monster kind")
	assert_eq(ChatCommands.host_check("/summon golem", true, ModeRules.SANDBOX).get("boss"), &"golem")
	assert_eq(ChatCommands.host_check("/summon golem", true, ModeRules.SURVIVOR).get("error"),
		ChatCommands.SANDBOX_ONLY_MESSAGE, "in Survivor the Golem comes from the Totem")
	assert_true(ChatCommands.suggestions("/summon ").has("/summon golem"))
	assert_string_contains(ChatCommands.usage(&"summon"), "golem")


func test_summon_golem_calls_the_sandbox_hook_on_the_host() -> void:
	_me_in_the_world()
	var runner := ChatCommandRunner.new()
	var fake := FakeSandbox.new()
	runner.sandbox = fake
	var me := multiplayer.get_unique_id()
	runner.run_host(me, ChatCommands.parse("/summon golem"))
	assert_eq(fake.summoned, [Vector3(3, 20, -4)])
	assert_string_contains(lines[-1].text, "Golem")
	fake.reply = "The Stone Golem is already here!"
	runner.run_host(me, ChatCommands.parse("/summon golem"))
	assert_eq(lines[-1].text, "The Stone Golem is already here!", "the hook's answer is shown")
	fake.free()
	runner.free()


func test_summon_golem_answers_soon_without_the_hook() -> void:
	_me_in_the_world()
	var runner := ChatCommandRunner.new()
	runner.sandbox = Node.new()
	runner.run_host(multiplayer.get_unique_id(), ChatCommands.parse("/summon golem"))
	assert_eq(lines[-1].text, ChatCommandRunner.SOON)
	runner.sandbox.free()
	runner.free()
