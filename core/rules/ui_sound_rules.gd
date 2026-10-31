class_name UiSoundRules
extends RefCounted
## Which sound a button makes (the audio pass, owner feedback #27; spec §15.2 "sound for every button").
## Buttons click; toggles (switches, check buttons, mode buttons) click softer. The HUD's touch buttons
## that a child presses all the time while playing stay quiet: JUMP and UP have their jump sound, ATTACK
## its swing, CROUCH and DOWN are movement, UNDO has its own sound, and a button holding an Input action
## is a control, not a menu. The hotbar's slots (no picture of their own) tick.

const CLICK := &"ui_click"
const TOGGLE := &"ui_toggle"
const TICK := &"ui_tick"
const QUIET: Array[StringName] = [&"jump", &"up", &"down", &"crouch", &"attack", &"undo"]
const SWITCHES: Array[StringName] = [&"walk", &"fly", &"ghost", &"moon", &"zero_g", &"slow", &"size", &"camera",
	&"mirror"]


## A BaseButton's sound. own: the button's meta "ui_sound" when it has one (&"" = silent).
static func button_sound(toggle: bool, own: Variant = null) -> StringName:
	if own is StringName or own is String:
		return StringName(own)
	return TOGGLE if toggle else CLICK


## A TouchButton's sound from its picture (HudIcons symbol) and its Input action.
static func touch_sound(symbol: StringName, action: StringName) -> StringName:
	if action != &"" or QUIET.has(symbol):
		return &""
	if symbol == &"":
		return TICK
	return TOGGLE if SWITCHES.has(symbol) else CLICK
