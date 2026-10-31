class_name SharePanel
extends Control
## SHARE, from the HUD's MORE panel (M4 Wave 3, agent I; spec §17.5, research T3): the child picks a
## build in their own world and sends it to a friend (GIFT A BUILD: tap the build, the connected blocks
## glow (BuildPicker, BuildOutline), SEND, pick the friend), or puts the area around them up as their
## showcase (MY SHOWCASE: a golden frame shows what friends will see; SHOW IT). Only on the host's or a
## solo game (the world is the child's own); only when the child may play online with friends.
## While picking, the world takes taps (BlockInteractor.tap_override); a small bar stays at the top.

signal closed

const CHOOSE := &"choose"
const PICK := &"pick"
const PICKED := &"picked"
const FRIENDS := &"friends"
const AREA := &"area"
const BAR_TOP := 130.0            # the picking bar's top (the toasts sit above it)
const BAR_WORDS := 560.0          # the bar's width: clear of WALK and MORE (top right) and BOOK (top left)

var service: OnlineService
var interactor: BlockInteractor
var world: WorldService
var player: Node3D                 # where the child stands (the showcase's area is around it)
var outline: BuildOutline
## The player's buddies' blocks and feet ([{"blocks", "pos"}]) for the showcase (the sandbox gives them).
var own_buddies := func() -> Array: return []

var step: StringName = &""
var picked: Dictionary = {}       # BuildPicker.pick's answer
var area: Dictionary = {}         # ShowcaseArea.box_around
var message: Label

var _box := PanelContainer.new()
var _content := VBoxContainer.new()
var _busy := false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	_box.add_theme_stylebox_override("panel", UiKit.box(Color(0.08, 0.1, 0.17, 0.96), 22, 18))
	_box.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_box)
	_content.add_theme_constant_override("separation", 12)
	_box.add_child(_content)
	message = OnlineUi.words("", 24, BAR_WORDS)
	message.add_theme_color_override("font_color", OnlineUi.HINT_COLOR)


func is_open() -> bool:
	return visible


## Whether SHARE is offered: signed in with friends allowed, in the child's own world (not a guest's).
static func offered(service: OnlineService, is_guest: bool) -> bool:
	return service != null and service.social_allowed() and not is_guest


func open() -> void:
	visible = true
	_choose()


func close() -> void:
	visible = false
	step = &""
	picked = {}
	area = {}
	if interactor:
		interactor.tap_override = Callable()
	if outline:
		outline.clear()
	closed.emit()


## The panel's box, for the HUD's look area (its taps never build).
func blockers() -> Array[Control]:
	return [_box]


func _choose() -> void:
	step = CHOOSE
	_page(false)
	_content.add_child(OnlineUi.words("Share with your friends", 32, 700))
	var gift := OnlineUi.button("GIFT A\nBUILD", UiKit.GREEN, Vector2(260, 140), &"gift")
	gift.name = "GiftABuild"
	gift.pressed.connect(start_pick)
	var mine := OnlineUi.button("MY\nSHOWCASE", OnlineUi.PURPLE, Vector2(260, 140), &"house")
	mine.name = "MyShowcase"
	mine.pressed.connect(start_area)
	var shut := OnlineUi.button("CLOSE", UiKit.BLUE, Vector2(180, 140))
	shut.name = "Close"
	shut.pressed.connect(close)
	_content.add_child(OnlineUi.row([gift, mine, shut], 16))
	_content.add_child(message)


## GIFT A BUILD: the next tap on the world picks a build.
func start_pick() -> void:
	step = PICK
	picked = {}
	outline.clear()
	interactor.tap_override = pick_at_screen
	_page(true)
	_content.add_child(OnlineUi.words("Tap your build!", 30, BAR_WORDS))
	_content.add_child(OnlineUi.row([_cancel()]))
	_content.add_child(message)


## A tap on the world while picking: the build under it glows. True (the tap is used).
func pick_at_screen(screen_pos: Vector2) -> bool:
	var hit := interactor.ray_at(screen_pos)
	if hit == null:
		message.text = BuildPicker.message("not_a_build")
		return true
	return pick_cell(hit.position)


func pick_cell(cell: Vector3i) -> bool:
	var r := BuildPicker.pick(cell, world.get_block)
	if r.has("error"):
		message.text = BuildPicker.message(r.error)
		return true
	picked = r
	picked_ghost = _gh_gift_ghost(r.blocks)   # M4 ghost races: a whole course in it takes the child's race along
	outline.show_blocks(r.blocks)
	Fx.burst(world, Vector3(cell) + Vector3(0.5, 0.5, 0.5), Color("ffd23f"), 18, 4.0, 0.12, 0.7, 3.0)
	Audio.play(&"chime", Vector3(cell))
	step = PICKED
	_page(true)
	_content.add_child(OnlineUi.words(tr("This one? %s") % Lang.blocks((r.blocks as Dictionary).size()), 30, BAR_WORDS))
	_gh_race_words()   # M4 ghost races
	var send := OnlineUi.button("SEND TO\nA FRIEND", UiKit.GREEN, Vector2(240, 110), &"gift")
	send.name = "SendToAFriend"
	send.pressed.connect(show_friends)
	_content.add_child(OnlineUi.row([send, _cancel()]))
	message.text = "Or tap another build."
	_content.add_child(message)
	return true


func show_friends() -> void:
	step = FRIENDS
	interactor.tap_override = Callable()
	_page(false)
	_content.add_child(OnlineUi.words("Who gets it?", 32, 700))
	var buttons: Array = []
	for f in service.friends:
		if f.state == OnlineRules.FRIEND:
			var b := OnlineUi.button(str(f.username), UiKit.GREEN, Vector2(230, 90))
			b.name = "Friend_" + str(f.username)
			b.add_theme_font_size_override("font_size", 26)
			b.pressed.connect(_send.bind(f))
			buttons.append(b)
	if buttons.is_empty():
		_content.add_child(OnlineUi.words("Add a friend first in PLAY ONLINE.", 28, 700))
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	for b: Button in buttons.slice(0, 12):
		grid.add_child(b)
	var centre := CenterContainer.new()
	centre.add_child(grid)
	_content.add_child(centre)
	_content.add_child(OnlineUi.row([_cancel()]))
	_content.add_child(message)


func _send(f: Dictionary) -> void:
	if _busy or picked.is_empty():
		return
	_busy = true
	message.text = "One moment..."
	var err: String = await service.send_gift(str(f.id), BuildCodec.encode(picked.blocks), picked_ghost)
	_busy = false
	if not is_inside_tree():
		return
	if err != "":
		message.text = err
		return
	var who := str(f.username)
	close()
	player_toast.call("Your present is on its way to %s!" % who)


## MY SHOWCASE: the area around the child, framed in gold.
func start_area() -> void:
	step = AREA
	interactor.tap_override = Callable()
	area = ShowcaseArea.box_around(player.global_position)
	outline.show_box(area.origin, area.size)
	_page(true)
	_content.add_child(OnlineUi.words("Everything in the golden frame is your showcase. Friends can visit it!", 26, BAR_WORDS))
	var show_it := OnlineUi.button("SHOW IT", OnlineUi.PURPLE, Vector2(240, 100))
	show_it.name = "ShowIt"
	show_it.pressed.connect(publish)
	_content.add_child(OnlineUi.row([show_it, _cancel()]))
	_content.add_child(message)


func publish() -> void:
	if _busy or area.is_empty():
		return
	_busy = true
	message.text = "One moment..."
	var text: String = await ShowcaseArea.snapshot_async(get_tree(), world.copy_box(area.origin, area.size))
	if not is_inside_tree() or step != AREA or area.is_empty() or not is_instance_valid(player):
		_busy = false   # M4 Task 10 review: CANCEL (or leaving) while the area was read shares nothing
		return
	var buddy := ShowcaseArea.nearest_buddy(own_buddies.call(), player.global_position, area)
	var err: String = await service.publish_showcase(text, buddy)
	_busy = false
	if not is_inside_tree():
		return
	if err != "":
		message.text = err
		return
	var raced: int = await _gh_share_area()   # M4 ghost races: the child's courses in the frame, as ghosts
	if not is_inside_tree():
		return
	close()
	player_toast.call(tr("Your showcase is up! Friends can visit it now.") if raced == 0 else
		tr("Your showcase is up! Friends can visit it and race your course.") if raced == 1 else
		tr("Your showcase is up! Friends can visit it and race your courses."))   # M3 Task 21a: whole lines translate


## A toast on the HUD (the sandbox gives it).
var player_toast := func(_text: String) -> void: pass


func _cancel() -> Button:
	var b := OnlineUi.button("CANCEL", UiKit.BLUE, Vector2(200, 100))
	b.name = "Cancel"
	b.pressed.connect(close)
	return b


## The box in the middle (choosing) or as a bar at the top (the world stays visible and tappable).
func _page(bar: bool) -> void:
	if message.get_parent():
		message.get_parent().remove_child(message)
	message.text = ""
	OnlineUi.clear(_content)
	if bar:   # under the toasts, between the top corners' buttons: never over a HUD button
		_box.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
		_box.offset_top = BAR_TOP
		_box.grow_vertical = Control.GROW_DIRECTION_END
	else:
		_box.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		_box.grow_vertical = Control.GROW_DIRECTION_BOTH
	_box.grow_horizontal = Control.GROW_DIRECTION_BOTH


func _exit_tree() -> void:
	if message and message.get_parent() == null:
		message.free()

# --- M4 ghost races (spec §17.5, research T2) ---
# SHOW IT takes the child's best runs on the courses inside the golden frame along as ghosts (friends race them
# when they visit); GIFT A BUILD of a whole course (its START and FINISH in the picked build) sends the child's
# race with it. Only the world owner's own runs (CourseBook's own best), only what the server will take
# (GhostShare). The sandbox gives the world's courses, its key and the child's look.

## () -> CourseBook: this world's courses (the sandbox's CourseDirector.book); none: no races travel.
var course_book := Callable()
## This world's key (its save slot and seed), for the showcase's record on the device (GhostBook.mine).
var world_key := ""
## () -> String: the child's look code (AvatarLook.to_code): the ghost wears it.
var look_code := func() -> String: return Profile.data.avatar.to_code()
## The child's race that goes with the picked build (null: none).
var picked_ghost: RaceGhost


func _gh_gift_ghost(blocks: Dictionary) -> RaceGhost:
	if not course_book.is_valid():
		return null
	return GhostShare.gift_ghost(course_book.call(), blocks, str(look_code.call()))


func _gh_race_words() -> void:
	if picked_ghost == null:
		return
	var words := OnlineUi.words(tr("Your race comes too! (%s)") % CourseRules.format_time(picked_ghost.ms), 24, BAR_WORDS)
	words.name = "RaceComes"
	_content.add_child(words)


## After SHOW IT: the child's courses inside the area go on the showcase as ghosts. How many did.
func _gh_share_area() -> int:
	if area.is_empty() or not course_book.is_valid():
		return 0
	var list := GhostShare.showcase_ghosts(course_book.call(), area.origin, area.size, world.get_block, str(look_code.call()))
	if list.is_empty():
		service.ghost_book_note_showcase(world_key, area.origin, area.size)
		return 0
	var r: Dictionary = await service.share_showcase_ghosts(list, world_key, area.origin, area.size)
	return int(r.shared)
