class_name KeysRules
extends RefCounted
## Owner #84: what the KEYS card says on a PC. Each line names the input actions it explains; the keys shown are read
## from the game's own input map (key_text), so the card never lies when a binding changes. "mouse:" lines are the
## mouse's looking and F1, which have no action.

const LINES: Array = [
	[["move_forward", "move_left", "move_back", "move_right"], "Walk"],
	[["mouse:look"], "Look around (click the game first)"],
	[["jump"], "Jump (tap it quickly: fly up)"],
	[["fly_up", "fly_down"], "Fly up / down"],
	[["break"], "Break a block"],
	[["place"], "Place a block"],
	[["hotbar_1", "hotbar_9"], "Pick a block"],
	[["physics_mode"], "Walk, fly or ghost"],
	[["camera_toggle"], "Camera"],
	[["undo"], "Undo"],
	[["crouch"], "Crouch"],
	[["attack"], "Attack"],
	[["chat"], "Chat"],
	[["photo"], "Photo"],
	[["size_mode"], "Size magic"],
	[["mirror"], "Mirror"],
	[["prospect"], "Gemma's prospecting quests"],   # spec §26
	[["inventions"], "Inventions: how people learned to fly"],   # owner #78
	[["pause"], "Menu"],
	# Owner #79: the rocket flight (FlightCockpit)
	[["rocket_steer_up", "rocket_steer_left", "rocket_steer_down", "rocket_steer_right"], "Rocket: steer (or the arrows)"],
	[["rocket_throttle"], "Rocket: throttle (hold it)"],
	[["rocket_action"], "Rocket: lift-off, stage, legs"],
	[["rocket_view"], "Rocket: inside or outside"],
	[["mouse:f1"], "These keys"],
]
const _NAMES := {"Escape": "Esc", "Up": "Up arrow", "Down": "Down arrow", "Left": "Left arrow", "Right": "Right arrow"}


## The first key or mouse button bound to `action` ("Space", "W", "Esc", "Left click"), "" when none.
static func key_text(action: String) -> String:
	if not InputMap.has_action(action):
		return ""
	for e: InputEvent in InputMap.action_get_events(action):
		if e is InputEventKey:
			var k := e as InputEventKey
			var code := k.physical_keycode if k.physical_keycode != KEY_NONE else k.keycode
			var name := OS.get_keycode_string(code)
			return str(_NAMES.get(name, name))
		if e is InputEventMouseButton:
			match (e as InputEventMouseButton).button_index:
				MOUSE_BUTTON_LEFT:
					return "Left click"
				MOUSE_BUTTON_RIGHT:
					return "Right click"
				MOUSE_BUTTON_MIDDLE:
					return "Middle click"
	return ""


## A line's keys as the card shows them ("W A S D", "1 … 9", "Mouse", "F1").
static func line_keys(actions: Array) -> String:
	if actions == ["mouse:look"]:
		return "Mouse"
	if actions == ["mouse:f1"]:
		return "F1"
	if actions.size() == 2 and str(actions[0]).begins_with("hotbar_"):
		return "%s … %s" % [key_text(actions[0]), key_text(actions[1])]
	var keys: Array[String] = []
	for a: String in actions:
		keys.append(key_text(a))
	return (" / " if actions.size() == 2 else " ").join(keys)


## The card comes once, at the first world on a PC.
static func due(settings: Dictionary, f: Dictionary) -> bool:
	return PlatformRules.keyboard_first(f) and not bool(settings.get("keys_seen", false))
