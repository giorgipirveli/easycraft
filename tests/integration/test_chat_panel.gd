extends GutTest
## The chat bar's logic, headless: which buttons show, what submitting does, and that typing
## switches the keyboard's game keys off. (Looks and touch are checked on the emulator.)

var panel: ChatPanel
var commands: Array[String] = []


func before_each() -> void:
	commands.clear()
	panel = ChatPanel.new()
	add_child_autofree(panel)
	panel.command_entered.connect(func(t: String) -> void: commands.append(t))


func _action(action: StringName) -> InputEventAction:
	var e := InputEventAction.new()
	e.action = action
	e.pressed = true
	return e


func test_opens_closed_with_the_button_and_blockers() -> void:
	panel.setup("Hopper", AgeBand.TEEN_PLUS)
	assert_false(panel.is_open())
	assert_true(panel.blockers().has(panel.button))
	panel.open()
	assert_true(panel.is_open())
	panel.close()
	assert_false(panel.is_open())


func test_typing_switches_game_keys_off_and_back_on() -> void:
	panel.setup("Hopper", AgeBand.TEEN_PLUS)
	var walk := InputMap.action_get_events(&"move_forward").size()
	var accept := InputMap.action_get_events(&"ui_accept").size()
	assert_gt(walk, 0)
	panel.open()
	assert_eq(InputMap.action_get_events(&"move_forward").size(), 0, "W must not walk while typing")
	assert_eq(InputMap.action_get_events(&"jump").size(), 0)
	assert_eq(InputMap.action_get_events(&"ui_accept").size(), accept, "ui actions stay for typing")
	panel.close()
	assert_eq(InputMap.action_get_events(&"move_forward").size(), walk)
	assert_eq(InputMap.action_get_events(&"chat").size(), 2)


func test_leaving_the_game_while_typing_gives_the_keys_back() -> void:
	panel.setup("Hopper", AgeBand.TEEN_PLUS)
	var walk := InputMap.action_get_events(&"move_forward").size()
	panel.open()
	remove_child(panel)
	assert_eq(InputMap.action_get_events(&"move_forward").size(), walk)
	add_child(panel)


func test_empty_bar_shows_quick_phrases_and_commands() -> void:
	panel.setup("Hopper", AgeBand.TEEN_PLUS)   # under-13 gets the quick-chat wheel (M4 E: test_chat_panel_online.gd)
	panel.open()
	assert_eq(panel._choices.get_child_count(), ChatRules.QUICK_PHRASES.size() + 1)
	assert_true(panel._choices_panel.visible)


func test_slash_shows_every_command_as_a_button() -> void:
	var mode_before := Game.mode
	Game.mode = ModeRules.SANDBOX
	panel.setup("Hopper", AgeBand.TEEN_PLUS)
	panel.open("/")
	# Owner feedback #40: every command this child may use (Sandbox: all but Survivor's /clearbag and /universe)
	assert_eq(panel._choices.get_child_count(), ChatCommands.COMMANDS.size() - 2)
	Game.mode = mode_before
	panel._set_text("/time ")
	assert_eq(panel._choices.get_child_count(), ChatCommands.TIMES.size())
	assert_string_contains(panel._hint.text, ChatCommands.usage(&"time"))


func test_tapping_a_command_that_needs_a_choice_shows_the_choices() -> void:
	panel.setup("Hopper", AgeBand.TEEN_PLUS)
	panel.open("/")
	panel._pick("/size")
	assert_eq(panel._field.text, "/size ")
	assert_eq(panel._choices.get_child_count(), ChatCommands.SIZES.size())
	panel._pick("/size giant")
	assert_eq(commands, ["/size giant"] as Array[String])
	assert_false(panel.is_open())


func test_submitting_a_command_closes_and_emits_it() -> void:
	panel.setup("Hopper", AgeBand.TEEN_PLUS)
	panel.open()
	panel._submit("  /fly ")
	assert_eq(commands, ["/fly"] as Array[String])
	assert_false(panel.is_open())


func test_under_13_free_text_stays_local_with_a_hint() -> void:
	panel.setup("Kiddo", AgeBand.UNDER_13)
	panel.open("/")   # the wheel's COMMANDS (M4 E): the bar, where free text still stays local
	panel._field.text = "hello friends"
	panel._submit(panel._field.text)
	assert_true(panel.is_open(), "stays open to pick a phrase")
	assert_eq(panel._field.text, "")
	assert_eq(panel._lines.back().text, ChatRules.message("quick_chat_only"))


func test_keyboard_shortcuts() -> void:
	panel.setup("Hopper", AgeBand.TEEN_PLUS)
	panel._unhandled_input(_action(&"chat_command"))
	assert_true(panel.is_open())
	assert_eq(panel._field.text, "/")
	panel._input(_action(&"ui_cancel"))
	assert_false(panel.is_open())
	panel._unhandled_input(_action(&"chat"))
	assert_true(panel.is_open())
	assert_eq(panel._field.text, "")


func test_history_keeps_recent_lines_and_clears() -> void:
	panel.setup("Hopper", AgeBand.TEEN_PLUS)
	for i in 12:
		panel.add_line("line %d" % i, &"chat", "Bob")
	var shown := 0
	for l in panel._labels:
		if l.visible:
			shown += 1
	assert_eq(shown, ChatPanel.HISTORY_CLOSED)
	assert_eq(panel._labels[ChatPanel.HISTORY_CLOSED - 1].text, "Bob: line 11")
	panel.clear_history()
	for l in panel._labels:
		assert_false(l.visible)


## Found in the editor: the closed history (top left) ran into the tip/feedback toast, which sits
## centred at the top from y = 96 and is about 60 px tall.
func test_closed_history_stays_below_the_toast() -> void:
	assert_gte(ChatPanel.HISTORY_CLOSED_POS.y, 170.0)


## 2026-09-28: in a browser Godot reports a virtual keyboard (it is switched on for typing) but its web display server
## has no height to give: every ask printed a warning, about 60 a second into the browser's console while playing. The
## page shrinks above the keyboard there instead (interactive-widget=resizes-content), so the height is 0, never asked.
func test_in_a_browser_the_keyboard_height_is_never_asked() -> void:
	var asked := [0]
	var measure := func() -> int:
		asked[0] += 1
		return 300
	assert_eq(ChatPanel.keyboard_px(true, true, measure), 0, "the page shrinks above the keyboard instead")
	assert_eq(asked[0], 0, "Godot's web display server warns at every ask")
	assert_eq(ChatPanel.keyboard_px(false, true, measure), 300, "a phone app asks")
	assert_eq(ChatPanel.keyboard_px(false, false, measure), 0, "a computer has none")
