extends GutTest
## Chat through the Session autoload in solo play (the local game is the host, peer 1). Lines for
## this player arrive on Session.chat_received; no network is involved.

var lines: Array = []


class FakeSandbox:
	extends Node
	var time_set := -1.0
	var home_peer := -1

	func set_time_of_day(t: float) -> void:
		time_set = t

	func go_home(peer_id: int) -> void:
		home_peer = peer_id


func before_each() -> void:
	lines.clear()
	Session.chat_reset()
	Session.commands_enabled = true
	Session.chat_received.connect(_on_line)


func after_each() -> void:
	Session.chat_received.disconnect(_on_line)
	Session.chat_reset()
	Session.commands_enabled = true


func _on_line(from: String, text: String, kind: StringName) -> void:
	lines.append({"from": from, "text": text, "kind": kind})


func test_join_registers_name() -> void:
	Session.chat_join("Hopper", AgeBand.TEEN_PLUS)
	assert_eq(Session.chat_names.get(multiplayer.get_unique_id()), "Hopper")


func test_teen_message_is_delivered_with_the_name() -> void:
	Session.chat_join("Hopper", AgeBand.TEEN_PLUS)
	Session.request_chat("  Want to build a castle?  ")
	assert_eq(lines.size(), 1)
	assert_eq(lines[0].from, "Hopper")
	assert_eq(lines[0].text, "Want to build a castle?")
	assert_eq(lines[0].kind, &"chat")


func test_under_13_free_text_is_refused_by_the_host() -> void:
	Session.chat_join("Kiddo", AgeBand.UNDER_13)
	Session.request_chat("my house is blue")
	assert_eq(lines.size(), 1)
	assert_eq(lines[0].kind, &"error")
	assert_eq(lines[0].text, ChatRules.message("quick_chat_only"))
	Session.request_chat("Hi!")
	assert_eq(lines[1].text, "Hi!")
	assert_eq(lines[1].kind, &"chat")


func test_a_player_who_never_joined_counts_as_under_13() -> void:
	Session.request_chat("hello there")
	assert_eq(lines[0].kind, &"error")


func test_filtered_message_is_refused() -> void:
	Session.chat_join("Hopper", AgeBand.TEEN_PLUS)
	Session.request_chat("call 555 123 4567")
	assert_eq(lines[0].text, ChatRules.message("personal_info"))


## Review M14: who receives a message was only tested alone (no peers in solo play). With fake
## peers registered on the host: a teen's free text never reaches an under-13 player, quick-chat
## does, a peer who never registered counts as under 13, and the sender always sees their line.
func test_host_delivers_by_the_receivers_age_band() -> void:
	var me := multiplayer.get_unique_id()
	Session._chat_bands[me] = AgeBand.TEEN_PLUS
	Session._chat_bands[2] = AgeBand.UNDER_13
	Session._chat_bands[3] = AgeBand.TEEN_PLUS
	var peers: Array[int] = [me, 2, 3, 4]      # 4 never registered
	assert_eq(Session.chat_recipients(me, "my house is blue", peers), [me, 3] as Array[int])
	assert_eq(Session.chat_recipients(me, "Hi!", peers), peers, "quick-chat reaches everybody")
	assert_eq(Session.chat_recipients(2, "Hi!", peers), peers)


## Review M14: a remote peer registers once; a second chat_join claiming 13+ changes nothing.
func test_a_remote_peer_cannot_upgrade_its_age_band() -> void:
	Session._host_chat_join(5, "Kiddo", String(AgeBand.UNDER_13))
	Session._host_chat_join(5, "Kiddo", String(AgeBand.TEEN_PLUS))
	assert_eq(Session._chat_bands[5], AgeBand.UNDER_13)
	var peers: Array[int] = [multiplayer.get_unique_id(), 5]
	Session._chat_bands[multiplayer.get_unique_id()] = AgeBand.TEEN_PLUS
	assert_false(Session.chat_recipients(multiplayer.get_unique_id(), "my house is blue", peers).has(5))


func test_host_rate_limits_messages() -> void:
	Session.chat_join("Hopper", AgeBand.TEEN_PLUS)
	for i in 6:
		Session.request_chat("Hi!")
	assert_eq(lines.size(), 6)
	assert_eq(lines[4].kind, &"chat")
	assert_eq(lines[5].kind, &"error")
	assert_eq(lines[5].text, ChatRules.message("too_fast"))


func test_world_changing_command_reaches_the_sandbox_on_the_host() -> void:
	watch_signals(Session)
	Session.request_command("/time night")
	assert_signal_emitted(Session, "command_requested")
	var params: Array = get_signal_parameters(Session, "command_requested")
	assert_eq(params[0], multiplayer.get_unique_id())
	assert_eq((params[1] as Dictionary).get("time"), ChatCommands.TIME_NIGHT)


func test_host_refuses_a_local_command_sent_to_it() -> void:
	watch_signals(Session)
	Session.request_command("/give diamond")
	assert_signal_not_emitted(Session, "command_requested")
	assert_eq(lines[0].kind, &"error")


func test_commands_off_outside_sandbox() -> void:
	watch_signals(Session)
	Session.commands_enabled = false
	Session.request_command("/time night")
	assert_signal_not_emitted(Session, "command_requested")
	assert_eq(lines[0].kind, &"error")


func test_every_command_has_a_handler() -> void:
	var runner := ChatCommandRunner.new()
	for name: StringName in ChatCommands.COMMANDS:
		assert_true(runner.has_method(ChatCommandRunner.handler_name(name)), String(name))
	runner.free()


func test_hooks_not_built_yet_answer_soon() -> void:
	var runner := ChatCommandRunner.new()
	runner.sandbox = Node.new()
	var me := multiplayer.get_unique_id()
	runner.run_host(me, ChatCommands.parse("/time night"))
	runner.run_host(me, ChatCommands.parse("/home"))
	runner.run_host(me, ChatCommands.parse("/summon dog"))
	assert_eq(lines.size(), 3)
	for line: Dictionary in lines:
		assert_eq(line.text, ChatCommandRunner.SOON)
	runner.sandbox.free()
	runner.free()


func test_time_and_home_call_the_sandbox_hooks() -> void:
	var runner := ChatCommandRunner.new()
	var fake := FakeSandbox.new()
	runner.sandbox = fake
	var me := multiplayer.get_unique_id()
	runner.run_host(me, ChatCommands.parse("/time noon"))
	runner.run_host(me, ChatCommands.parse("/home"))
	assert_eq(fake.time_set, ChatCommands.TIME_NOON)
	assert_eq(fake.home_peer, me)
	fake.free()
	runner.free()


func _keys(action: StringName) -> Array:
	var keys := []
	for e in InputMap.action_get_events(action):
		if e is InputEventKey:
			keys.append((e as InputEventKey).physical_keycode)
	return keys


func test_chat_keys_are_in_the_input_map() -> void:
	assert_true(InputMap.has_action(&"chat"))
	assert_true(InputMap.has_action(&"chat_command"))
	assert_true(_keys(&"chat").has(KEY_T))
	assert_true(_keys(&"chat").has(KEY_ENTER))
	assert_true(_keys(&"chat_command").has(KEY_SLASH))
