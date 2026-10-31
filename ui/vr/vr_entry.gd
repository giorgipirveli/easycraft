class_name VrEntry
extends RefCounted
## ENTER VR (owner #101, the WebXR route; docs/superpowers/plans/2026-10-15-vr-quest.md ruling 1): in the Web VR export
## (feature tag "webxr", served at /vr/) the main menu has a big ENTER VR button, shown only where the browser says an
## immersive session can start (WebXRInterface.is_session_supported("immersive-vr"): the Quest's browser, a PC with a
## headset), once the menu's shader warm-up is done (a first-sight compile in a headset freezes the view), and never
## while VR runs. A browser starts a session only from a tap, so the button's press starts it: Vr.start(VrRules.WEBXR)
## (the rig's body sets the session up); if it can't, its words show under the button. /play/ and the apps never show it.

const MODE := "immersive-vr"
const WORDS := "ENTER VR"

## The WebXR interface (or a test's stand-in with its session_supported signal and is_session_supported).
var iface: Object
## The browser said an immersive session can start.
var supported := false
## (kind) -> String: starts VR ("" or why not; default Vr.start).
var start := func(kind: StringName) -> String: return Vr.start(kind)
## () -> bool: the menu is ready (its warm-up done; default: yes).
var ready := func() -> bool: return true
## The words under the button (made with it).
var words: Label

var _button: Button


## Only the Web VR export (`features`: tests; {} reads this build's).
static func wanted(features: Dictionary = {}) -> bool:
	return bool(features.get("webxr", false)) if not features.is_empty() else OS.has_feature("webxr")


## A desktop preview runs (--vr-preview): VrUi prints where the panel goes (VR_PREVIEW lines).
static var previewing := false
static var _preview_world_done := false


## --vr-preview (a developer's look at VR on the desktop, no headset; docs/DEVELOPMENT.md "VR"): VR-RIG's preview (its
## fake head turned by a captured mouse), else a simulated session (Vr.simulate), from the menu on: the canvas on its
## panel in front of the head, a free mouse as the laser (VrPointer).
## --vr-preview=sandbox goes on into the Sandbox world (CONTINUE, or a new one when there is none) once.
static func preview_from_args(args: PackedStringArray) -> void:
	var world := ""
	var wanted := false
	for a: String in args:
		if a == "--vr-preview" or a.begins_with("--vr-preview="):
			wanted = true
			world = a.trim_prefix("--vr-preview").trim_prefix("=")
	if not wanted:
		return
	previewing = true
	if not Vr.active():   # VR-RIG's body starts its own preview (the fake head turned by the mouse) for --vr-preview
		if Vr.has_method(&"preview"):
			Vr.call(&"preview", true)
		else:
			Vr.simulate(true)
	if world == "sandbox" and not _preview_world_done:
		_preview_world_done = true
		var slot := ModeRules.slot(ModeRules.SANDBOX, 1)
		Game.start_world.call_deferred(ModeRules.SANDBOX, not WorldSaves.exists(slot))


## The browser's WebXR interface (null where the engine has none).
static func find() -> Object:
	return XRServer.find_interface("WebXR")


func _init(xr: Object = null) -> void:
	iface = xr


## Asks the browser once whether an immersive session can start (the answer comes as a signal).
func ask() -> void:
	if iface == null:
		return
	if not iface.is_connected(&"session_supported", _on_supported):
		iface.connect(&"session_supported", _on_supported)
	iface.call(&"is_session_supported", MODE)


## The button (hidden until it can be used) with its line of words under it.
func button() -> Button:
	if _button != null:
		return _button
	_button = UiKit.big_button(WORDS, Color("7b3fd1"), Vector2(260, 84))
	_button.name = "EnterVr"
	_button.add_theme_font_size_override("font_size", 30)
	_button.pressed.connect(_on_pressed)
	words = Label.new()
	words.name = "EnterVrWords"
	words.add_theme_font_size_override("font_size", 24)
	words.position = Vector2(0, 92)
	words.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_button.add_child(words)
	Vr.started.connect(refresh)
	Vr.ended.connect(refresh)
	refresh()
	return _button


## Shows the button exactly when it can be used.
func refresh() -> void:
	if _button == null or not is_instance_valid(_button):
		return
	_button.visible = supported and not Vr.active() and bool(ready.call())


func _on_supported(mode: String, ok: bool) -> void:
	if mode != MODE:
		return
	supported = ok
	refresh()


func _on_pressed() -> void:
	words.text = str(start.call(VrRules.WEBXR))
