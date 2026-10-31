extends SceneTree
## Writes the game's Input Map into project.godot (keyboard/mouse bindings for desktop testing;
## touch controls drive the same actions) and the game controller's (owner #90: GamepadRules.BINDINGS, beside the keys;
## the pad-only actions; Cross / A added to ui_accept, which keeps its keys).
## Run: godot --headless --path . --script res://tools/setup_input_map.gd

const KEYS := {
	"move_forward": [KEY_W, KEY_UP],
	"move_back": [KEY_S, KEY_DOWN],
	"move_left": [KEY_A, KEY_LEFT],
	"move_right": [KEY_D, KEY_RIGHT],
	"jump": [KEY_SPACE],
	"fly_up": [KEY_E],
	"fly_down": [KEY_Q, KEY_SHIFT],
	"undo": [KEY_Z],
	"physics_mode": [KEY_F],
	"camera_toggle": [KEY_V],
	"size_mode": [KEY_G],
	"mirror": [KEY_M],
	"attack": [KEY_R],
	"pause": [KEY_ESCAPE],
	"hotbar_1": [KEY_1], "hotbar_2": [KEY_2], "hotbar_3": [KEY_3],
	"hotbar_4": [KEY_4], "hotbar_5": [KEY_5], "hotbar_6": [KEY_6],
	"hotbar_7": [KEY_7], "hotbar_8": [KEY_8], "hotbar_9": [KEY_9],
	"chat": [KEY_T, KEY_ENTER],
	"chat_command": [KEY_SLASH],   # opens the chat with "/" typed
	"prospect": [KEY_J],           # Gemma's prospecting journal: the quest's step, or her quests (spec §26)
	"inventions": [KEY_I],         # the Inventions book: how people learned to fly (owner #78, spec §21e)
	"photo": [KEY_P],              # photo mode on and off (M3 Task 16)
	"lab_mode": [KEY_L],           # the Physics Lab's LAB button (M3 Task 6, Sandbox)
	"crouch": [KEY_C],             # crouch on and off (M2 Task 5); held while swimming it dives
	# Owner #79, #84: the rocket flight's keys (RocketFlight's cockpit; the KEYS card shows them): the same WASD and
	# arrows as walking steer, Shift the throttle (held), Space or Enter the ACTION button, V inside or outside.
	"rocket_steer_up": [KEY_W, KEY_UP],
	"rocket_steer_down": [KEY_S, KEY_DOWN],
	"rocket_steer_left": [KEY_A, KEY_LEFT],
	"rocket_steer_right": [KEY_D, KEY_RIGHT],
	"rocket_throttle": [KEY_SHIFT],
	"rocket_action": [KEY_SPACE, KEY_ENTER],
	"rocket_view": [KEY_V],
}
const MOUSE := {
	"break": MOUSE_BUTTON_LEFT,
	"place": MOUSE_BUTTON_RIGHT,
}
const DEADZONE := 0.2


func _init() -> void:
	var events := {}   # action -> Array[InputEvent]
	for action: String in KEYS:
		var list: Array = []
		for key: Key in KEYS[action]:
			var e := InputEventKey.new()
			e.physical_keycode = key
			list.append(e)
		events[action] = list
	for action: String in MOUSE:
		var e := InputEventMouseButton.new()
		e.button_index = MOUSE[action]
		events[action] = [e]
	# Owner #90: the pad's events after the keys (the KEYS card reads the first key), ui_accept with its own keys.
	var accept: Array = []
	for e: InputEvent in InputMap.action_get_events(&"ui_accept"):
		if not GamepadRules.is_pad_event(e):
			accept.append(e)
	events["ui_accept"] = accept
	for b: Dictionary in GamepadRules.BINDINGS:
		var action := String(b.action)
		if not events.has(action):
			events[action] = []
		(events[action] as Array).append(GamepadRules.make_event(b.spec))
	for action: String in events:
		var dz := GamepadRules.TRIGGER_DEADZONE if action in ["break", "place"] else DEADZONE
		if action == "ui_accept":
			dz = InputMap.action_get_deadzone(&"ui_accept")
		ProjectSettings.set_setting("input/" + action, {"deadzone": dz, "events": events[action]})
	print("INPUT saved err=", ProjectSettings.save())
	quit()
