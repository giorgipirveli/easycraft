extends GutTest
## Owner feedback #40: the chat bar's command buttons follow the mode (Survivor sees only what it allows),
## a command this child can't use says why, the buttons are English only (owner #52), /weather's buttons are
## what the universe has, and /bot's list the bot friends.

var panel: ChatPanel
var commands: Array[String] = []
var _mode_before: StringName
var _universe_before := 1


class FakeFriend:
	extends Node
	var bot_name := "Pip"


func before_each() -> void:
	_mode_before = Game.mode
	_universe_before = Game.universe
	Game.mode = ModeRules.SANDBOX
	Game.universe = 1
	commands.clear()
	panel = ChatPanel.new()
	add_child_autofree(panel)
	panel.command_entered.connect(func(t: String) -> void: commands.append(t))
	panel.setup("Hopper", AgeBand.TEEN_PLUS)


func after_each() -> void:
	Game.mode = _mode_before
	Game.universe = _universe_before


func _labels() -> Array[String]:
	var out: Array[String] = []
	for b in panel._choices.get_children():
		out.append((b as Button).text)
	return out


func test_survivor_sees_only_what_it_may_use() -> void:
	Game.mode = ModeRules.SURVIVOR
	panel.open("/")
	var shown := _labels()
	assert_eq(shown.size(), ChatCommands.suggestions("/", [], {"mode": ModeRules.SURVIVOR, "enabled": true}).size())
	assert_true(shown.has("/find"))
	assert_true(shown.has("/clearbag"))
	assert_false(shown.has("/tp"), "a cheat")
	assert_false(shown.has("/weather"), "a cheat")


func test_a_command_you_cant_use_says_why() -> void:
	Game.mode = ModeRules.SURVIVOR
	panel.open("/tp ")
	assert_eq(panel._hint.text, ChatCommands.SANDBOX_ONLY_MESSAGE)
	assert_eq(panel._choices.get_child_count(), 0)


func test_weather_buttons_are_what_the_universe_has() -> void:
	panel.open("/weather ")
	assert_eq(_labels(), ["clear"] as Array[String], "Green Meadows has clear skies only")
	Game.universe = 2
	panel._set_text("/weather ")
	assert_eq(_labels(), ["clear", "sandstorm"] as Array[String], "the Sandstorm Desert")


func test_the_command_buttons_are_english_only() -> void:
	panel.open("/\u10D0\u10DB")   # owner #52: Georgian letters name no command
	assert_eq(_labels(), [] as Array[String])


func test_switches_run_at_once_and_bot_buttons_name_the_friends() -> void:
	var friend := FakeFriend.new()
	friend.add_to_group(&"bot_friends")
	add_child_autofree(friend)
	panel.open("/")
	panel._pick("/peace")
	assert_eq(commands, ["/peace"] as Array[String], "/peace alone switches peace on or off")
	panel.open("/bot ")
	assert_true(_labels().has("remove Pip"))
	assert_true(_labels().has("add builder"))
