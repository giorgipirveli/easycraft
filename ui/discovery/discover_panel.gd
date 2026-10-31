class_name DiscoverPanel
extends Control
## Owner #132 (W1): DISCOVER inside the world. The School over the world (as LifeTownPanel opens Life over Life Town and
## ShortsSchool a unit over the Theater): the screen dimmed, the School's frame in the middle (drawn smaller on a low
## screen), on the child's grade's map (or a subject's, or Life). Its own BACK, Esc or Android Back closes it and the
## child is in the world again where they stood; while a practice room from its Life tab shows, Android Back belongs to
## the room ("Leave the practice?") and the panel stays. The screen is made only when DISCOVER is pressed.

signal closed

## The life subject: the door of Life (opens the School's LIFE tab).
const LIFE := "life"

var screen: Control
var subject := ""
var profile: ProfileData = null   # tests give theirs; the game's own otherwise
var save_profile := Callable()
var _panel: PanelContainer


func _ready() -> void:
	name = "DiscoverPanel"
	visible = false
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme = UiKit.theme()


## Opens the School over the world: the grade's map, `on_subject`'s map, or Life (LIFE); `said`: the line spoken as it
## opens (an Academy door's says its name first).
func open(on_subject: String = "", said: String = DiscoveryRules.OPEN_LINE) -> void:
	if _panel == null:
		var dim := ColorRect.new()
		dim.color = Color(0, 0, 0, 0.55)
		dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
		dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(dim)
		var center := CenterContainer.new()
		center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		center.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(center)
		_panel = PanelContainer.new()
		center.add_child(_panel)
	if screen:
		_panel.remove_child(screen)
		screen.queue_free()
	subject = on_subject
	screen = make_screen(on_subject)
	screen.connect(&"closed", close)
	_panel.add_child(screen)
	_after_open(on_subject)
	visible = true
	_fit.call_deferred()
	Audio.play(&"ui_click")
	PlayVoice.say(said)


## Owner #132 (W1) → Play G0: THE ONE CALL THE LEAD SWITCHES WHEN G0 MERGES (G0's DISCOVER map in place of the School's
## screen; `on_subject` is the map's subject, or LIFE). Today: the School's own screen through its public functions.
func make_screen(on_subject: String) -> Control:
	var s := SchoolScreen.new()
	if profile != null:
		s.profile = profile
	if save_profile.is_valid():
		s.save_profile = save_profile
	if on_subject != "" and on_subject != LIFE:
		s.subject = on_subject   # its first map is this subject's
	return s


## After the screen is in the tree (its first page is up): Life's door goes on to the LIFE tab.
func _after_open(on_subject: String) -> void:
	if on_subject == LIFE and screen is SchoolScreen and (screen as SchoolScreen).profile.school.grade != 0:
		(screen as SchoolScreen).show_life()


func is_open() -> bool:
	return visible


## A practice room from the School's Life tab is showing now (the room has the screen; the avatar stays held).
func room_open() -> bool:
	if not visible or screen == null:
		return false
	var place: Variant = screen.get("play_host")   # Play G0's play place, opened from the School's PLAY
	if place is PlayHost and is_instance_valid(place) and not (place as PlayHost).closed:
		return true
	var life: Variant = screen.get("life")
	if not (life is LifeScreen):
		return false
	var host: LifeRoomHost = (life as LifeScreen).host
	return is_instance_valid(host) and not host.closed


func close() -> void:
	if not visible:
		return
	var place: Variant = screen.get("play_host") if screen else null
	if place is PlayHost and is_instance_valid(place) and not (place as PlayHost).closed:
		(place as PlayHost).stop_for_now()   # Play G0's place: the calm way out, nothing recorded, the gold kept
	var life: Variant = screen.get("life") if screen else null
	if life is LifeScreen and is_instance_valid((life as LifeScreen).host) and not (life as LifeScreen).host.closed:
		(life as LifeScreen).host.stop_for_now()   # the calm way out: nothing lost
	visible = false
	closed.emit()


## Android Back: true when it was handled here (the panel closed, or a practice room's own card takes it).
func close_if_open() -> bool:
	if room_open():
		return true
	if not visible:
		return false
	close()
	return true


## Circle / B on a game controller when nothing nearer takes it (PadFocus): back to the world.
func pad_back() -> bool:
	return close_if_open()


## What covers the world's look area while it shows.
func blockers() -> Array[Control]:
	return [self] as Array[Control]


func _fit() -> void:
	if _panel == null or not is_inside_tree():
		return
	var room := get_viewport_rect().size
	var need := _panel.get_combined_minimum_size()
	var s := minf(1.0, minf((room.y - 16.0) / maxf(need.y, 1.0), (room.x - 16.0) / maxf(need.x, 1.0)))
	_panel.scale = Vector2(s, s)
	_panel.pivot_offset = need * 0.5


func _unhandled_input(event: InputEvent) -> void:
	if visible and not room_open() and event.is_action_pressed(&"pause"):
		close()
		get_viewport().set_input_as_handled()
