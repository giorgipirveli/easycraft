class_name Hud
extends Control
## In-game HUD: touch controls (joystick, look/build area, buttons), hotbar, block palette,
## username (top right), crosshair and FPS counter. Every spot comes from one table (HudLayout, for a
## 1280x720 landscape canvas with corner anchors, so it adapts to wider phones). M2 Task 17: every
## button is a picture with its word under it, big enough for a child's thumb; the ones used now and
## then wait in the MORE panel.

signal pause_requested

const MODE_LABELS := {PhysicsMode.Mode.NORMAL: "WALK", PhysicsMode.Mode.FLY: "FLY", PhysicsMode.Mode.GHOST: "GHOST"}
## The WALK button's picture for each word it shows (the physics switch and the Physics Lab).
const MODE_SYMBOLS := {"WALK": &"walk", "FLY": &"fly", "GHOST": &"ghost", "MOON": &"moon", "ZERO-G": &"zero_g",
	"SLOW": &"slow"}

var player: Player
var interactor: BlockInteractor

var look_area := LookBuildArea.new()
var joystick := VirtualJoystick.new()
var jump_button := TouchButton.new()
var fly_down_button := TouchButton.new()
var physics_button := TouchButton.new()
var camera_button := TouchButton.new()
var size_button := TouchButton.new()
var mirror_button := TouchButton.new()
var undo_button := TouchButton.new()
var pause_button := TouchButton.new()
var more_button := TouchButton.new()
## The MORE panel: emotes, photos, CAM, SIZE, MIRROR, UNDO and LAB (M2 Task 17).
var more := MorePanel.new()
var hotbar := Hotbar.new()
var palette := BlockPalette.new()
var chat := ChatPanel.new()
var username_label := Label.new()
var fps_label := Label.new()
var crosshair := Label.new()
var _toast_panel := PanelContainer.new()
var _toast_label := Label.new()
var _toast_tween: Tween

var _touch_only: Array[Control] = []


## Owner #101: the HUD in this group (VrUi finds it for the wrist and the toast strip: vr_rects).
const GROUP := &"hud"


func _ready() -> void:
	add_to_group(GROUP)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_configure_layout()   # M5 Task 1: the button size, the hand and the moves, before anything is placed
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(look_area)

	joystick.joystick_mode = VirtualJoystick.JOYSTICK_DYNAMIC
	joystick.joystick_size = 190.0
	joystick.tip_size = 80.0
	joystick.deadzone_ratio = 0.12
	joystick.action_left = &"move_left"
	joystick.action_right = &"move_right"
	joystick.action_up = &"move_forward"
	joystick.action_down = &"move_back"
	HudLayout.place(joystick, &"joystick")
	add_child(joystick)

	_button(jump_button, "JUMP", &"jump", &"jump", &"jump")
	_button(fly_down_button, "DOWN", &"crouch", &"down", &"fly_down")   # CROUCH's spot (M2 Task 5)
	_button(physics_button, "WALK", &"physics", &"walk")
	_button(pause_button, "PAUSE", &"pause", &"pause")
	pause_button.pressed.connect(func() -> void: pause_requested.emit())   # owner feedback #32: lost in the HUD pass
	_button(more_button, "MORE", &"more", &"more")
	_rare(size_button, "SIZE", &"size")
	_rare(camera_button, "CAM", &"camera")
	_rare(undo_button, "UNDO", &"undo")
	_rare(mirror_button, "MIRROR", &"mirror")
	_touch_only = [look_area, joystick, jump_button, fly_down_button, physics_button, size_button, camera_button, undo_button, mirror_button]

	add_child(hotbar)
	HudLayout.place(hotbar, &"hotbar")

	_label(username_label, &"username", 28, HORIZONTAL_ALIGNMENT_RIGHT)
	_label(fps_label, &"fps", 22, HORIZONTAL_ALIGNMENT_RIGHT)   # top right, left of the gold (JUMP has the corner)
	_label(crosshair, &"crosshair", 40, HORIZONTAL_ALIGNMENT_CENTER)
	crosshair.text = "+"
	crosshair.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_build_toast()
	_add_picture_hint()  # M2 Task 3: below the toasts
	add_child(chat)      # CHAT button, chat bar and history
	palette.build_later = true   # M7: its pages are built when it first opens (not in the world switch's frame)
	add_child(palette)   # last: the full-screen overlay sits above everything
	_add_attack_button()
	_add_photo_button()
	_add_economy()
	_add_potion_timers()   # M2 Task 6
	_add_lab_button()
	_add_emote_controls()
	_add_waves()           # M2 Task 9
	_add_stealth_controls()   # M2 Task 5
	_add_boss_bar()        # M2 Task 10
	_add_online_dot()   # M4 C
	_add_races()        # M3 Task 7: the race clock and a course's goals panel
	_add_games()   # M4 H
	_add_glide_button()   # M3 Task 14a
	_add_more_panel()   # M2 Task 17
	_add_access()   # M5 Task 1: last (it lays out what the others placed)


func setup(p: Player, username: String, show_touch: bool, show_fps: bool) -> void:
	player = p
	interactor = p.get_node("BlockInteractor")
	look_area.player = p
	look_area.interactor = interactor
	look_area.blockers = [joystick, jump_button, fly_down_button, physics_button, size_button, camera_button, undo_button,
		pause_button, mirror_button, more_button, more.box, hotbar, palette]
	hotbar.counted = not Game.allows(ModeRules.UNLIMITED_BLOCKS)   # Survivor shows counts (M2 Task 3)
	palette.counted = hotbar.counted
	hotbar.setup(interactor)
	hotbar.palette_requested.connect(palette.open)
	palette.picked.connect(func(id: int) -> void: interactor.set_slot_block(interactor.selected_slot, id))
	physics_button.pressed.connect(p.cycle_physics_mode)
	size_button.pressed.connect(p.cycle_size_mode)
	p.size_mode_changed.connect(func(mode: int) -> void:
		size_button.text = SizeMagic.label(mode)
		size_button.queue_redraw())
	camera_button.pressed.connect(p.toggle_camera)
	undo_button.pressed.connect(interactor.undo)
	mirror_button.pressed.connect(interactor.toggle_mirror)
	interactor.mirror_changed.connect(func(on: bool) -> void:
		mirror_button.selected = on
		toast("Mirror ON: everything you build is copied" if on else "Mirror OFF"))
	p.physics_mode_changed.connect(_on_physics_mode_changed)
	p.swimming_changed.connect(set_swimming)
	Session.magic_feedback.connect(toast)
	username_label.text = username
	username_label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED   # M3 Task 21a: a name stays a name
	fps_label.visible = show_fps
	_touch_base = show_touch   # owner #90: set_pad hides them while a game controller plays
	for c in _touch_only:
		c.visible = show_touch
	_on_physics_mode_changed(p.physics_mode)
	chat.setup(username, Profile.data.age_band)
	look_area.blockers.append_array(chat.blockers())
	_setup_attack_button(show_touch)
	look_area.blockers.append(photo_button)
	_setup_economy()
	potion_timers.player = p   # M2 Task 6
	_setup_lab_button(p, show_touch)
	_setup_emotes(p)
	_setup_waves()             # M2 Task 9


## Short message at the top of the screen (tips and feedback), fades out by itself.
func toast(text: String, seconds: float = 2.5) -> void:
	if not _toast_panel.visible:
		UiMotion.pop_in(_toast_panel)   # owner #94: a new message pops in (one already showing just changes)
	_toast_label.text = text
	ReadAloud.auto(text)   # M3 Task 21a: "Read to me"
	_toast_panel.visible = true
	_toast_panel.modulate.a = 1.0
	if _toast_tween and _toast_tween.is_valid():
		_toast_tween.kill()
	_toast_tween = create_tween()
	_toast_tween.tween_interval(seconds)
	_toast_tween.tween_property(_toast_panel, "modulate:a", 0.0, 0.4)
	_toast_tween.tween_callback(func() -> void: _toast_panel.visible = false)


func _build_toast() -> void:
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.08, 0.1, 0.17, 0.88)
	box.set_corner_radius_all(18)
	box.set_content_margin_all(14)
	box.content_margin_left = 26
	box.content_margin_right = 26
	_toast_panel.add_theme_stylebox_override("panel", box)
	_toast_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast_label.add_theme_font_size_override("font_size", 26)
	_toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast_panel.add_child(_toast_label)
	add_child(_toast_panel)
	HudLayout.place(_toast_panel, &"toast")
	_toast_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_toast_panel.visible = false


## Pausing lets go of every touch: a finger lifted during the pause menu never reaches the paused
## HUD. The buttons and the look area let go by themselves. VirtualJoystick has no reset method;
## its resize handler forgets the finger and releases the move actions.
func _notification(what: int) -> void:
	if what == NOTIFICATION_PAUSED:
		joystick.notification(NOTIFICATION_RESIZED)


func _process(delta: float) -> void:
	if fps_label.visible:
		fps_label.text = "%d FPS" % Engine.get_frames_per_second()
	# aim help while the bow is drawn; set once a frame (it was hidden and shown again every frame of a draw, M5 Task 3)
	var aim := is_instance_valid(interactor) and shows_crosshair(interactor.crosshair_mode, interactor.weapons.drawing)
	if crosshair.visible != aim:
		crosshair.visible = aim
	_update_attack_button()
	_update_stealth()   # M2 Task 5
	_update_glide_button()   # M3 Task 14a
	_theater_tick(delta)   # M5 Task 1


## Owner #101 (VR, P2): where the parts the wrist and the toast strip show are on the canvas now (an empty rect: not
## showing): the hotbar, the hearts, the gold, a toast, the boss bar, the wave line.
func vr_rects() -> Dictionary:
	var out := {}
	for pair: Array in [[&"hotbar", hotbar], [&"hearts", hearts], [&"gold", gold_counter], [&"toast", _toast_panel],
			[&"boss", boss_bar], [&"wave", wave_line]]:
		var c := pair[1] as Control
		var shows := c != null and c.is_inside_tree() and c.is_visible_in_tree() and c.modulate.a > 0.05
		out[pair[0]] = c.get_global_rect() if shows else Rect2()
	return out


## The "+" in the middle: aiming at the screen's middle (a captured mouse, a pad, first person) or a bow drawn; never in a
## headset (owner #101: the hand's laser aims, and the canvas's middle is only the tray's).
static func shows_crosshair(crosshair_mode: bool, drawing: bool) -> bool:
	return (crosshair_mode or drawing) and not Vr.active()


func _on_physics_mode_changed(mode: int) -> void:
	_set_word(physics_button, MODE_LABELS.get(mode, "WALK"))
	_flying = mode != PhysicsMode.Mode.NORMAL
	_show_up_down()


## A button on its own spot of the screen (HudLayout), with its picture and word.
func _button(b: TouchButton, text: String, spot: StringName, symbol: StringName, action: StringName = &"") -> void:
	b.text = text
	b.symbol = symbol
	b.action = action
	HudLayout.place(b, spot)
	add_child(b)


## A button for the MORE panel (added to it, in order, by _add_more_panel).
func _rare(b: TouchButton, text: String, symbol: StringName) -> void:
	b.text = text
	b.symbol = symbol


## The WALK button's word and its picture (WALK, FLY, GHOST and the lab modes).
func _set_word(b: TouchButton, text: String) -> void:
	b.text = text
	b.symbol = MODE_SYMBOLS.get(text, &"walk")
	b.queue_redraw()


func _label(l: Label, spot: StringName, font_size: int, align: HorizontalAlignment) -> void:
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	l.add_theme_constant_override("outline_size", 6)
	l.horizontal_alignment = align
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	HudLayout.place(l, spot)
	add_child(l)


## Overlays that hear touches before the buttons stay above them, in this order, with the palette on
## top: the MORE panel, the emote wheel, the palette. Called whenever a section adds buttons.
func _raise_overlays() -> void:
	for c: Control in [more, emote_wheel, palette]:
		if c.get_parent() == self:
			move_child(c, -1)


# --- Beds and sleeping (M1b Task 10) ----------------------------------------------------------

## The SLEEP context button (WAKE UP while sleeping), centred just above the hotbar.
var sleep_button := TouchButton.new()
var sleep_overlay := SleepOverlay.new()


## Called once by SleepDirector after setup().
## Asleep: save the world and go back to the menu (the sandbox's SAVE & QUIT).
signal stop_for_today

var stop_button := TouchButton.new()


func add_sleep_controls() -> void:
	add_child(sleep_overlay)
	move_child(sleep_overlay, _toast_panel.get_index())   # dims the game, never the messages
	sleep_button.round_shape = false
	_button(sleep_button, "SLEEP", &"sleep", &"sleep")
	sleep_button.visible = false
	# M2 Task 17: asleep, STOP FOR TODAY sits beside WAKE UP, the same size (a natural place to stop).
	stop_button.round_shape = false
	_button(stop_button, "STOP FOR TODAY", &"stop", &"home")
	stop_button.visible = false
	stop_button.pressed.connect(func() -> void: stop_for_today.emit())
	_raise_overlays()
	look_area.blockers.append(sleep_button)
	look_area.blockers.append(stop_button)


func show_sleep_button(on: bool, text: String = "SLEEP") -> void:
	sleep_button.visible = on
	sleep_button.text = text
	sleep_button.symbol = &"wake" if text == "WAKE UP" else &"sleep"


func set_sleeping(asleep: bool) -> void:
	if asleep:
		sleep_overlay.fall_asleep()
	else:
		sleep_overlay.wake_up()
	stop_button.visible = asleep
	# asleep: WAKE UP moves left of STOP FOR TODAY; awake: SLEEP is back in the middle
	HudLayout.place(sleep_button, &"wake" if asleep else &"sleep")

# --- Weapons (M1b Task 11) ---

## Shown on touch screens whatever the hand holds (owner feedback #29: ATTACK always attacks, with the
## best weapon in the hotbar or fists): tap to attack, hold to draw the bow or throw the spear.
## Above JUMP (M2 Task 17: nearly as big), clear of CROUCH and the hotbar.
var attack_button := TouchButton.new()
var _show_touch := false


func _add_attack_button() -> void:
	_button(attack_button, "ATTACK", &"attack", &"attack")
	attack_button.visible = false
	move_child(attack_button, palette.get_index())   # under the palette overlay


func _setup_attack_button(show_touch: bool) -> void:
	_show_touch = show_touch
	attack_button.pressed.connect(interactor.weapons.attack_pressed)
	attack_button.released.connect(interactor.weapons.attack_released)
	look_area.blockers.append(attack_button)
	_update_attack_button()


func _update_attack_button() -> void:
	if not is_instance_valid(interactor):   # the player's; freed with it when a LAN host quits
		return
	var show := _show_touch and _simple_shows_attack() and not _under_theater(attack_button)   # M3 Task 21a; M5 Task 1
	if attack_button.visible != show:
		attack_button.visible = show

# --- Owner #90: a game controller plays ---

var _touch_base := false   # the touch HUD on this device (setup's show_touch)
var _pad_on := false


## While a game controller plays the touch buttons hide (the stick, the look area, JUMP, DOWN and CROUCH, WALK, ATTACK,
## GLIDE: the pad has them; a finger on the screen brings them back), and MORE's picture buttons (SIZE, CAM, UNDO,
## MIRROR, LAB) show on a PC too, where the pad reaches them through MORE (D-pad right).
func set_pad(on: bool) -> void:
	_pad_on = on
	var touch := _touch_base and not on
	for c: Control in [look_area, joystick, jump_button, fly_down_button, physics_button]:
		c.visible = touch
	for c: Control in [size_button, camera_button, undo_button, mirror_button]:
		c.visible = _touch_base or on
	lab_button.visible = (_touch_base or on) and Game.allows(ModeRules.PHYSICS_LAB)
	_show_touch = touch
	if touch:
		_tuck_under_theater()
	_show_up_down()
	_update_attack_button()

# --- Swimming (M2 Task 14) ---

var _flying := false
var _swimming := false


## While swimming JUMP swims up (UP) and DOWN dives, the same buttons as flying.
func set_swimming(on: bool) -> void:
	_swimming = on
	_show_up_down()


func _show_up_down() -> void:
	var up_down := _flying or _swimming or _ride_fly   # M3 Task 20a: riding a flyer
	fly_down_button.visible = up_down and jump_button.visible and not _under_theater(fly_down_button)   # M5 Task 1
	crouch_button.visible = not up_down and jump_button.visible and _simple_shows_crouch() \
		and not _under_theater(crouch_button)   # M2 Task 5; M3 Task 21a; M5 Task 1
	jump_button.text = "UP" if up_down else "JUMP"
	jump_button.symbol = &"up" if up_down else &"jump"

# --- Photo mode (M3 Task 16) ---

## Asks the sandbox's PhotoMode to open.
signal photo_requested

## The camera button: in the MORE panel (M2 Task 17; top right before). Shown on phones and desktop
## (P also opens photo mode there).
var photo_button := PhotoChip.new()


func _add_photo_button() -> void:
	_rare(photo_button, "PHOTO", &"photo")
	photo_button.pressed.connect(func() -> void: photo_requested.emit())

# --- First-time picture hints (M2 Task 3, the lead's child-friendly feedback) ---

const IRON_HINT := "iron_pickaxe"
const IRON_COLOR := Color("4da3ff")   # iron is "rare" blue (spec §13.2)
const IRON_HINT_TEXT := "Shiny ores need an IRON pickaxe!\nTilly the trader sells one."

var picture_hint := PictureHint.new()


func _add_picture_hint() -> void:
	add_child(picture_hint)
	Session.magic_feedback.connect(show_first_time_hint)


## The first time this player meets an ore that needs an iron pickaxe (the host's refusal), a
## picture of an iron pickaxe; once per profile.
func show_first_time_hint(feedback: String) -> void:
	if feedback != GatherRules.NEED_IRON_MESSAGE or Profile.data.hints_seen.has(IRON_HINT):
		return
	Profile.data.hints_seen.append(IRON_HINT)
	picture_hint.show_hint(BlockIcons.icon(ItemIds.PICKAXE), IRON_COLOR, IRON_HINT_TEXT)

# --- Hearts and knock-outs (M2 Task 2) ---

## The hearts row, top left right of pause (above CHAT and BOOK since M2 Task 17): both modes have
## hearts (spec §12.3, §12.15).
const HEARTS_POS := HudLayout.HEARTS_POS

var hearts := HeartsBar.new()
var knockout_overlay := KnockoutOverlay.new()


## Called once by KnockoutDirector after setup() (tests may set `player` directly).
func add_health_controls() -> void:
	HudLayout.place(hearts, &"hearts", hearts.bar_size())
	add_child(hearts)
	move_child(hearts, chat.get_index())   # the open chat bar covers them
	add_child(knockout_overlay)
	move_child(knockout_overlay, _toast_panel.get_index())   # dims the game, never the messages
	if player:
		hearts.set_hp(player.health.hp)
	Session.player_hurt.connect(_on_player_hurt)


func _on_player_hurt(peer_id: int, hp: int, _from: Vector3) -> void:
	if is_instance_valid(player) and peer_id == player.peer_id:
		hearts.set_hp(hp)

# --- M2 Task 7: the gold counter and Tilly's shop -------------------------------------------------

## Top-right under the username, above WALK and MORE: a coin and the gold (∞ in Sandbox).
var gold_counter := GoldCounter.new()
## Tilly's shop: a centred overlay, under the block palette's.
var shop := ShopPanel.new()


func _add_economy() -> void:
	HudLayout.place(gold_counter, &"gold")
	add_child(gold_counter)
	move_child(gold_counter, palette.get_index())   # under the palette overlay
	add_child(shop)
	move_child(shop, palette.get_index())


func _setup_economy() -> void:
	gold_counter.refresh()
	shop.player = player
	look_area.blockers.append(shop)
	interactor.trader_tapped.connect(open_shop)


## The player tapped Tilly: her shop, and no other overlay.
func open_shop(trader: Trader) -> void:
	palette.visible = false
	chat.close()
	more.close()
	move_child(shop, -1)   # over every button later tasks added (CROUCH sat over BUY on the emulator)
	shop.open(trader)
	BabbleVoices.say(trader, &"tilly", BabbleRules.NORMAL_SIZE, "Hello! What would you like?", true, "Tilly")   # M3 Task 21a

# --- M2 Task 6: potion timers ---

## A chip per working potion with the seconds left: top-centre-left, below the hearts (Task 2) and
## stealth (Task 5) rows, left of the wave line and boss bar (Tasks 9 and 10).
var potion_timers := PotionTimers.new()


func _add_potion_timers() -> void:
	HudLayout.place(potion_timers, &"potions")
	add_child(potion_timers)
	move_child(potion_timers, palette.get_index())   # under the palette overlay

# --- Secrets and treasures (M2 Task 16) ---

## The Secret Book's button (beside CHAT, under the hearts since M2 Task 17; shown on every device,
## there is no key), the book, surprise banners, the treasure map's compass (left of WALK) and the
## riddle panel (notes and the Wanderer).
var book_button := TouchButton.new()
var secret_book := SecretBook.new()
var banner := SurpriseBanner.new()
var compass := TreasureCompass.new()
var riddle_panel := RiddlePanel.new()


## Called once by the sandbox after setup() (secrets may be null in tests).
func add_secret_controls(secrets: SecretDirector) -> void:
	add_child(banner)
	move_child(banner, _toast_panel.get_index())
	add_child(compass)
	_button(book_button, "BOOK", &"book", &"book")
	# Open on release: the touch-down's emulated mouse press would hit the new overlay (like the palette).
	book_button.released.connect(secret_book.open)
	secret_book.build_later = true   # M7: its pages and tabs are built when it first opens
	add_child(secret_book)
	add_child(riddle_panel)
	_raise_overlays()
	look_area.blockers.append(book_button)
	look_area.blockers.append_array([secret_book, riddle_panel])   # owner 42: a tap on them never builds behind
	secret_book.director = secrets
	if is_instance_valid(interactor):
		compass.setup(secrets, interactor, player)
		secret_book.treasure_picked.connect(func(id: int) -> void: interactor.set_slot_block(interactor.selected_slot, id))


func show_banner(text: String, picture: int = -1) -> void:
	banner.show_banner(text, picture)


func show_note(text: String, pictures: Array) -> void:
	riddle_panel.show_note(text, pictures)


func show_riddle(question: String, choices: Array, on_pick: Callable) -> void:
	riddle_panel.show_riddle(question, choices, on_pick)


## Android Back: closes the Secret Book or a riddle first. True when something was closed.
func close_secret_panels() -> bool:
	for panel: Control in [riddle_panel, secret_book]:
		if panel.visible:
			panel.visible = false
			return true
	return false

# --- Physics Lab (M3 Task 6) ---

## The LAB button (Sandbox, touch screens): Normal, Moon gravity, Zero-G, Fly, Ghost, Slow motion. In
## the MORE panel (M2 Task 17); lit while Moon, Zero-G or Slow motion is on, whose names show on the
## WALK button. Survivor has none (Normal and paid Fly only). Desktop: the L key (lab_pressed).
var lab_button := TouchButton.new()
var _lab_player: Player


func _add_lab_button() -> void:
	_rare(lab_button, "LAB", &"lab")


func _setup_lab_button(p: Player, show_touch: bool) -> void:
	_lab_player = p
	lab_button.visible = show_touch and Game.allows(ModeRules.PHYSICS_LAB)
	lab_button.pressed.connect(lab_pressed)
	p.lab_mode_changed.connect(_on_lab_mode_changed)
	look_area.blockers.append(lab_button)
	_on_lab_mode_changed(p.lab_mode)


## The LAB button or the L key: the next lab mode, and a few words about it.
func lab_pressed() -> void:
	if not is_instance_valid(_lab_player) or not Game.allows(ModeRules.PHYSICS_LAB):
		return
	_lab_player.cycle_lab_mode()
	toast(LabRules.toast(_lab_player.lab_mode))


func _on_lab_mode_changed(mode: int) -> void:
	lab_button.selected = LabRules.is_lab_only(mode)
	if LabRules.is_lab_only(mode):
		_set_word(physics_button, LabRules.label(mode))

# --- Emote wheel (M3 Task 9) ---

## The emote button: in the MORE panel (M2 Task 17; the left column before); shown on phones and
## desktop. It opens the wheel of the player's 8 emotes (chosen in the avatar editor).
var emote_button := EmoteButton.new()
var emote_wheel := EmoteWheel.new()


func _add_emote_controls() -> void:
	_rare(emote_button, "EMOTE", &"emote")
	add_child(emote_wheel)                          # above the buttons: it hears touches before them
	emote_button.pressed.connect(func() -> void: emote_wheel.open(Profile.data.avatar.emotes))


func _setup_emotes(p: Player) -> void:
	emote_wheel.chosen.connect(func(emote_name: StringName) -> void: p.play_emote(emote_name))
	look_area.blockers.append_array([emote_button, emote_wheel])


# --- Brave badge (M2 Task 17) ---

## A star and BRAVE under the hearts, right of the eye, in a Brave Survivor world (DifficultyRules);
## nothing otherwise. (Right of the hearts it ran into the wave line on a 16:9 phone.)
var brave_badge := Label.new()


func show_difficulty_badge(difficulty: StringName) -> void:
	if brave_badge.get_parent() == null:
		brave_badge.name = "BraveBadge"
		brave_badge.text = "★ BRAVE"
		brave_badge.add_theme_font_size_override("font_size", 22)
		brave_badge.add_theme_color_override("font_color", Color("ffb347"))
		brave_badge.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
		brave_badge.add_theme_constant_override("outline_size", 6)
		brave_badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		brave_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		HudLayout.place(brave_badge, &"brave")
		add_child(brave_badge)
		move_child(brave_badge, palette.get_index())   # under the palette overlay
	brave_badge.visible = DifficultyRules.has_badge(difficulty)

# --- M2 Task 9: Monster Totem waves ---

## The wave line: top-centre above the toasts, right of the hearts (the boss bar's spot too, Task 10:
## the Totem starts no wave while the boss fights). The Totem's panel: a centred overlay under the
## block palette's.
var wave_line := WaveLine.new()
var totem_panel := TotemPanel.new()
var _wave_state: Dictionary = {}


func _add_waves() -> void:
	HudLayout.place(wave_line, &"wave")
	add_child(wave_line)
	move_child(wave_line, palette.get_index())
	add_child(totem_panel)
	move_child(totem_panel, palette.get_index())


func _setup_waves() -> void:
	totem_panel.player = player
	look_area.blockers.append(totem_panel)
	interactor.totem_tapped.connect(open_totem)


## The host's wave state reached this game (the sandbox follows its WaveDirector).
func show_wave_state(state: Dictionary) -> void:
	_wave_state = state
	wave_line.show_state(state)
	totem_panel.show_state(state)


## The player tapped the Monster Totem: its panel, and no other overlay.
func open_totem(totem: Totem) -> void:
	palette.visible = false
	chat.close()
	shop.close()
	more.close()
	move_child(totem_panel, -1)   # over every HUD button, like the shop
	totem_panel.open(totem, _wave_state)

# --- M2 Task 5: stealth — CROUCH, the eye and noise bars, the view from a hiding spot, danger arrows ---

## Under the hearts row (the plan's HUD allocation), lined up with it.
const STEALTH_POS := HudLayout.STEALTH_POS

## Where DOWN sits, shown while walking on touch screens; it presses the C key's action (a toggle).
var crouch_button := TouchButton.new()
var stealth_meter := StealthMeter.new()
var hide_overlay := HideOverlay.new()
var danger_arrows := DangerArrows.new()


func _add_stealth_controls() -> void:
	_button(crouch_button, "CROUCH", &"crouch", &"crouch", &"crouch")
	crouch_button.visible = false
	move_child(crouch_button, palette.get_index())   # under the palette overlay
	HudLayout.place(stealth_meter, &"stealth", stealth_meter.meter_size())
	add_child(stealth_meter)
	move_child(stealth_meter, chat.get_index())      # the open chat bar covers it, like the hearts
	add_child(hide_overlay)
	move_child(hide_overlay, _toast_panel.get_index())   # dims the game, never the messages
	add_child(danger_arrows)
	move_child(danger_arrows, _toast_panel.get_index())


## Called by the sandbox once its StealthDirector exists (this game's player's light and noise).
func setup_stealth(director: StealthDirector) -> void:
	stealth_meter.player = player
	stealth_meter.director = director
	danger_arrows.player = player
	look_area.blockers.append(crouch_button)
	player.hidden_changed.connect(hide_overlay.set_hidden)


## The CROUCH button lights up while crouching.
func _update_stealth() -> void:
	if is_instance_valid(player) and crouch_button.selected != player.crouching:
		crouch_button.selected = player.crouching

# --- M2 Task 10: the boss bar ---

## The Stone Golem's health: top-centre, above the toasts (y 96), between the hearts and the username.
## The sandbox's BossDirector drives it on every peer; hidden until a Golem fights.
var boss_bar := BossBar.new()


func _add_boss_bar() -> void:
	HudLayout.place(boss_bar, &"boss")
	add_child(boss_bar)
	move_child(boss_bar, palette.get_index())   # under the palette overlay

# --- M4 C: the online dot ---

## A small green dot right of the username while this game is online (an online match, or signed in
## for friends' invites); the username moves left to make room. Asked once a second.
var online_dot := OnlineDot.new()
const USERNAME_RIGHT := -20.0
const USERNAME_RIGHT_ONLINE := -56.0


func _add_online_dot() -> void:
	online_dot.name = "OnlineDot"
	online_dot.source = Session.online_dot_on
	online_dot.changed.connect(_on_online_dot)
	HudLayout.place(online_dot, &"online_dot")   # beside the username (16..60)
	add_child(online_dot)
	move_child(online_dot, palette.get_index())   # under the palette overlay


func _on_online_dot(on: bool) -> void:
	if HudLayout.left_handed:   # M5 Task 1: the mirror's dot is left of the name
		username_label.offset_left = -(USERNAME_RIGHT_ONLINE if on else USERNAME_RIGHT)
	else:
		username_label.offset_right = USERNAME_RIGHT_ONLINE if on else USERNAME_RIGHT


# --- M4 E: helping a knocked-out teammate up (§17.5) ---

## HELP UP (hold it near a teammate who waits for help) and GET UP (while waiting yourself) share a
## spot above SLEEP, clear of JUMP and under the knock-out fade's words; the ring that fills sits left
## of them. KnockoutDirector drives them (show_help, show_get_up).
var help_button := TouchButton.new()
var get_up_button := TouchButton.new()
var help_ring := ReviveRing.new()


## Called once by KnockoutDirector after add_health_controls.
func add_revive_controls() -> void:
	for b: TouchButton in [help_button, get_up_button]:
		b.round_shape = false
		b.visible = false
		look_area.blockers.append(b)
	_button(help_button, ReviveRules.HELP_BUTTON, &"help", &"heart")
	_button(get_up_button, ReviveRules.GET_UP_BUTTON, &"help", &"up")
	HudLayout.place(help_ring, &"help_ring")
	help_ring.visible = false
	add_child(help_ring)
	_raise_overlays()


## The helper's side: HELP UP near a teammate who waits; the ring while the host counts the hold.
func show_help(on: bool, progress: float) -> void:
	if help_button.visible != on:
		help_button.visible = on
	help_ring.visible = on and progress > 0.0
	help_ring.progress = progress


## The waiting player's side: kind words in the fade (the tip's place), GET UP while nobody is
## helping, and the ring while someone is.
func show_get_up(on: bool, with_button: bool, text: String, progress: float) -> void:
	var button := on and with_button
	if get_up_button.visible != button:
		get_up_button.visible = button
	if not on:
		return
	knockout_overlay.set_help_text(text)
	help_ring.visible = not with_button   # a friend is helping: their ring fills here too
	help_ring.progress = progress

# --- M2 Task 17: the MORE panel, and the Theater's middle ---

## MORE (top right) opens a box of the buttons used now and then, in this order; emotes and photos
## open something else, so they close it. It sits above every HUD button (it hears touches first).
func _add_more_panel() -> void:
	add_child(more)
	for b: TouchButton in [emote_button, photo_button, camera_button, size_button, mirror_button, undo_button, lab_button]:
		more.add(b, b == emote_button or b == photo_button)
	more_button.pressed.connect(more.toggle)
	more.opened.connect(func() -> void: more_button.selected = true)
	more.closed.connect(func() -> void: more_button.selected = false)
	_raise_overlays()


## Android Back: closes the MORE panel first. True when it was open.
func close_more() -> bool:
	if not more.is_open():
		return false
	more.close()
	return true


var _tucked: Array[Control] = []


## While the Shorts Theater's panel shows, the buttons its side columns reach on a 16:9 phone step
## aside (BOOK, WALK, MORE); JUMP, CROUCH, pause, CHAT and the joystick stay. The sandbox calls it. M5 Task 1: with
## `panel`, the thumb buttons its buttons reach (BIG, BIGGER, the left hand) step aside too.
func set_theater_open(on: bool, panel: Control = null) -> void:
	_theater = panel if on else null
	if on:
		more.close()
		for c: Control in [book_button, physics_button, more_button]:
			if c.visible:
				c.visible = false
				_tucked.append(c)
		_tuck_under_theater()
	else:
		for c in _tucked:
			c.visible = not (_pad_on and c in [jump_button, physics_button])   # owner #90: not while a pad plays
		_tucked.clear()
		_show_up_down()   # M5 Task 1: CROUCH or DOWN come back with JUMP

# --- Survivor games and crafting (owner feedback #33, #34; spec §12.18, §12.19) --------------------------

## The game clock (GameClock): Build to Survive's night clock, shelter and score, or Monster Hunter's pack,
## hunt and gold pops. A label, never a button; the SurvivorGameDirector fills it and shows it in those games.
var game_clock := GameClock.new()


func add_game_clock() -> void:
	if game_clock.get_parent() == null:
		game_clock.name = "GameClock"
		HudLayout.place(game_clock, &"game_clock")
		add_child(game_clock)
		# Under the chat, like the hearts: a friend's line stays readable over it (owner 49); under the
		# palette overlay (if the chat is open now, it is the last child: the palette's place).
		move_child(game_clock, mini(chat.get_index(), palette.get_index()))


## Crafting (spec §12.19): the recipe book knows where this player can craft now; its words and the host's
## answers are toasts; something new goes into a hotbar slot that holds nothing (and is picked).
func setup_crafting() -> void:
	palette.craft_book.stations_provider = func() -> Dictionary:
		if not is_instance_valid(player):
			return {Recipes.HAND: true, Recipes.TABLE: false, Recipes.FURNACE: false}
		return Session.craft_stations_near(player.eye_position(), CraftRules.REACH)
	palette.craft_book.said.connect(toast)
	Session.craft_done.connect(_on_craft_done)


func _on_craft_done(ok: bool, text: String, id: int, _count: int) -> void:
	toast(text)
	if ok:
		put_on_hotbar(id)


## A new thing goes into the first hotbar slot whose thing this player has none of (unless it is there).
func put_on_hotbar(id: int) -> void:
	if not is_instance_valid(interactor) or interactor.hotbar.has(id):
		return
	for i in interactor.hotbar.size():
		if Session.my_inventory.count(interactor.hotbar[i]) == 0 and not ItemIds.is_free_tool(interactor.hotbar[i]):
			interactor.set_slot_block(i, id)   # (M3 Task 8: a paint or REWIND is never "none left")
			return


# --- M3 Task 7: races ---

## The race clock: top-centre under the wave line and the boss bar (never over them), a label, not a button;
## while it shows, the toasts step down under it. A course's goals panel: a centred overlay under the palette's,
## opened by a tap on its FINISH or START while not racing (the host sends the course: Session.course_info_*).
const RACE_IT_FIRST := "Race it first: step on START, then run to FINISH!"

var race_clock := RaceClock.new()
var course_panel := CoursePanel.new()
var _racing := false
var _asked_course := false


func _add_races() -> void:
	HudLayout.place(race_clock, &"race")
	add_child(race_clock)
	move_child(race_clock, palette.get_index())   # under the palette overlay
	race_clock.visibility_changed.connect(_place_toast)
	add_child(course_panel)
	move_child(course_panel, palette.get_index())
	course_panel.opened.connect(func() -> void: more.close())


## Called by the sandbox once its CourseDirector follows this game's player.
func setup_races(courses: CourseDirector) -> void:
	race_clock.clock_ms = courses.clock_ms
	courses.state_changed.connect(show_race_state)
	courses.toast = func(text: String) -> void: toast(text, 2.5)
	look_area.blockers.append(course_panel)
	if is_instance_valid(interactor):
		interactor.course_tapped.connect(course_tapped)
	if not Session.course_info_received.is_connected(_on_course_info):
		Session.course_info_received.connect(_on_course_info)


## This player's run (from the host): the clock, and the toasts step aside while it shows.
func show_race_state(state: Dictionary) -> void:
	_racing = bool(state.get("on", false))
	race_clock.show_state(state)
	if _racing:
		course_panel.close()
	if str(state.get("event", "")) == "finish":
		var medal := str(state.get("medal", ""))
		toast(tr("FINISH!  %s%s") % [CourseRules.format_time(int(state.get("ms", 0))),
			("  " + tr(medal.to_upper()) + "!") if medal != "" else ""], 4.0)   # M3 Task 21a: the medal in Georgian too
		if str(state.get("ghost_line", "")) != "":   # M4 ghost races: against a friend's ghost
			toast(str(state.ghost_line), 4.0)


## A tap on a START or FINISH block: its course's panel (not while racing).
func course_tapped(cell: Vector3i) -> void:
	if _racing:
		return
	_asked_course = true
	Session.request_course_info(cell)


func _on_course_info(course: Dictionary) -> void:
	if course_panel.visible:
		course_panel.show_info(course)
		return
	if not _asked_course:
		return
	_asked_course = false
	if bool(course.get("none", true)):
		toast(RACE_IT_FIRST, 4.0)
		return
	open_course(course)


## A course's goals panel, and no other overlay.
func open_course(course: Dictionary) -> void:
	palette.visible = false
	chat.close()
	more.close()
	move_child(course_panel, -1)   # over every HUD button, like the shop
	course_panel.open(course)


func _place_toast() -> void:
	var y: float = HudLayout.TOAST_RACING_Y if race_clock.visible else (HudLayout.SPOTS[&"toast"][1] as Vector2).y
	y += _top_inset   # M4 ghost races: under a visit's bar
	_toast_panel.offset_top = y
	_toast_panel.offset_bottom = y

# --- M4 H: co-op games — the round's line and TEAM PHOTO ---

## The round's line (hide-and-seek, Storm Run: GameLine) where the wave line sits (a round never runs with
## a wave or the boss); TEAM PHOTO, a context button that shows only for the 20 s after a boss is beaten.
var game_line := GameLine.new()
var team_photo_button := TouchButton.new()


func _add_games() -> void:
	HudLayout.place(game_line, &"game_line")
	add_child(game_line)
	move_child(game_line, palette.get_index())   # under the palette overlay
	team_photo_button.round_shape = false
	team_photo_button.visible = false
	_button(team_photo_button, GameWords.PHOTO_BUTTON, &"team_photo", &"photo")
	move_child(team_photo_button, palette.get_index())


## Called by the sandbox once its GamesDirector exists: the line follows the round, TEAM PHOTO the offer.
func setup_games(director: GamesDirector) -> void:
	director.line_changed.connect(game_line.show_line)
	director.photo_offer_changed.connect(func(on: bool) -> void: team_photo_button.visible = on)
	team_photo_button.pressed.connect(Session.games_request_photo)
	if not look_area.blockers.has(team_photo_button):
		look_area.blockers.append(team_photo_button)
	game_line.show_line(director.line())


## Monster Wave's result panel (spec §12.20), centred over everything but the palette.
var arena_panel := ArenaPanel.new()


func add_arena_panel() -> void:
	if arena_panel.get_parent() == null:
		arena_panel.name = "ArenaPanel"
		add_child(arena_panel)
		look_area.blockers.append(arena_panel)   # a tap on the panel never reaches the world

# --- M3 Task 14a: the GLIDE button ---

## A context button left of ATTACK and above CROUCH, on touch screens: it shows while this player is in the air
## with room below and a glider (GLIDE opens it), and while gliding (DROP folds it). JUMP in the air after the
## last air jump opens the glider too (and Space on desktop).
var glide_button := TouchButton.new()
var _glide_player: Player


func _add_glide_button() -> void:
	_button(glide_button, "GLIDE", &"glide", &"glide")
	glide_button.visible = false
	move_child(glide_button, palette.get_index())   # under the palette overlay


## Called by the sandbox once this game's player exists.
func setup_gadgets(p: Player) -> void:
	_glide_player = p
	glide_button.pressed.connect(func() -> void:
		if is_instance_valid(_glide_player):
			_glide_player.toggle_glider())
	look_area.blockers.append(glide_button)


func _update_glide_button() -> void:
	var p := _glide_player
	var gliding := is_instance_valid(p) and p.gadget_move == GadgetRules.Move.GLIDE
	var show := _show_touch and is_instance_valid(p) and (gliding or (not p.is_on_floor() and p.can_glide())) \
		and not _under_theater(glide_button)   # M5 Task 1
	if glide_button.visible != show:
		glide_button.visible = show
	var word := "DROP" if gliding else "GLIDE"
	if show and glide_button.text != word:
		glide_button.text = word
		glide_button.symbol = &"down" if gliding else &"glide"
		glide_button.queue_redraw()

# --- M3 Task 20a: RIDE ---

## The RIDE context button (spot `ride`, right of BOOK): only next to a saddled buddy nobody rides, and as
## HOP OFF (lit) while riding. RideDirector shows it and hears its taps.
var ride_button := TouchButton.new()
var _ride_fly := false


## Called once by the sandbox's RideDirector.
func add_ride_controls() -> void:
	if ride_button.get_parent() == self:
		return
	_button(ride_button, "RIDE", &"ride", &"ride")
	ride_button.visible = false
	move_child(ride_button, palette.get_index())   # under the palette overlay
	_raise_overlays()
	if not look_area.blockers.has(ride_button):
		look_area.blockers.append(ride_button)


## Owner #109: next to a car the word is DRIVE (or GET IN) with the car's picture (`word`, `symbol`).
func show_ride_button(on: bool, riding: bool = false, word: String = "", symbol: StringName = &"ride") -> void:
	ride_button.visible = on
	ride_button.selected = riding
	if word == "":
		word = "HOP OFF" if riding else "RIDE"
	if riding:
		symbol = &"ride"
	if ride_button.text != word or ride_button.symbol != symbol:
		ride_button.text = word
		ride_button.symbol = symbol
		ride_button.queue_redraw()


## Riding a flyer: JUMP climbs (UP) and DOWN dives, the same buttons as flying.
func set_ride_up_down(on: bool) -> void:
	_ride_fly = on
	_show_up_down()

# --- Owner #109: the cars' HORN and FLY / LAND ---

## HORN (spot `horn`) in a car and FLY / LAND (spot `car_fly`) for a flying car's driver: context buttons the sandbox's
## VehicleDirector shows and hears (it adds them once).
var horn_button := TouchButton.new()
var car_fly_button := TouchButton.new()


func add_car_controls() -> void:
	if horn_button.get_parent() == self:
		return
	_button(horn_button, "HORN", &"horn", &"horn")
	_button(car_fly_button, "FLY", &"car_fly", &"fly")
	for b: TouchButton in [horn_button, car_fly_button]:
		b.visible = false
		move_child(b, palette.get_index())   # under the palette overlay
		if not look_area.blockers.has(b):
			look_area.blockers.append(b)
	_raise_overlays()

# --- M3 Task 10: the Gold Farm — its panel (a tap on the barn) and the welcome-back ---

## A centred overlay under the palette's, like the Totem's panel; made in Survivor worlds only (null in Sandbox).
var farm_panel: FarmPanel


## Called by the sandbox once its FarmDirector exists (Survivor worlds).
func add_farm_controls(director: FarmDirector) -> void:
	farm_panel = FarmPanel.new()
	add_child(farm_panel)
	move_child(farm_panel, palette.get_index())
	farm_panel.player_feet = func() -> Vector3:
		return player.global_position if is_instance_valid(player) and player.is_spawned() else Vector3.INF
	look_area.blockers.append(farm_panel)
	if is_instance_valid(interactor):
		interactor.farm_tapped.connect(func(b: FarmBuilding) -> void: open_farm(b, b.farm))
	director.state_received.connect(func(f: Dictionary) -> void:
		if farm_panel.visible:
			farm_panel.show_farm(f))
	Session.gold_changed.connect(func(_g: int) -> void:
		if farm_panel.visible:
			farm_panel.show_farm(director.shown()))


## The player tapped the barn: its panel, and no other overlay.
func open_farm(building: FarmBuilding, farm: Dictionary) -> void:
	if farm_panel == null:
		return
	palette.visible = false
	chat.close()
	shop.close()
	more.close()
	totem_panel.close()
	move_child(farm_panel, -1)   # over every HUD button, like the shop
	farm_panel.open(building, farm)


## The welcome-back: "Your farm made 240 gold!" (the exact amount) and a coin shower around the player.
func farm_welcome(gold: int) -> void:
	if gold <= 0:
		return
	show_banner(FarmRules.welcome_text(gold))
	if is_instance_valid(player) and player.is_inside_tree():
		Fx.coin_shower(get_tree().root, player.global_position, gold)
		Audio.play(&"coin")
		Audio.play(&"fanfare")

# --- M3 Task 21b: books and memories ---
# The saving list's bar under the gold (research R3: "a small bar on my screen shows my gold filling up"): the first
# thing on the list, in Survivor only, inside the gold counter's own spot (a label, never a button). SAVE UP at
# Tilly's shop (ShopPanel's section) and in the avatar editor put things on the list; the book's SAVING tab shows it.

var saving_bar := SavingBar.new(Vector2(150, 9))


## Called once by the sandbox after setup(): the bar, and a refresh whenever gold or the list changes.
func setup_books() -> void:
	saving_bar.name = "SavingBar"
	saving_bar.show_words = false
	gold_counter.add_child(saving_bar)
	saving_bar.anchor_left = 1.0
	saving_bar.anchor_right = 1.0
	saving_bar.anchor_top = 1.0
	saving_bar.anchor_bottom = 1.0
	saving_bar.offset_left = -150.0
	saving_bar.offset_right = 0.0
	saving_bar.offset_top = -9.0
	saving_bar.offset_bottom = 0.0
	Session.gold_changed.connect(func(_g: int) -> void: refresh_saving())
	shop.saving_changed.connect(refresh_saving)
	secret_book.visibility_changed.connect(refresh_saving)
	refresh_saving()


## Shows the first thing on the saving list's bar (Survivor, Tilly's price where the child is), or nothing.
func refresh_saving() -> void:
	SavingRules.tidy(Profile.data.wonder, Profile.data)   # a look bought meanwhile came true
	var list := Profile.data.wonder.saving
	saving_bar.visible = not Game.allows(ModeRules.INFINITE_GOLD) and not list.is_empty()
	if saving_bar.visible:
		saving_bar.set_have_need(SavingRules.have_need(list[0], Profile.data.survivor_gold, Game.universe, Game.survivor_game))

# --- M4 ghost races ---

var _top_inset := 0.0


## A screen with a bar of its own across the top (a showcase visit): the race clock and the toasts go `inset`
## further down, under it.
func push_top(inset: float) -> void:
	_top_inset = inset
	HudLayout.place(race_clock, &"race")
	race_clock.offset_top += inset
	race_clock.offset_bottom += inset
	_place_toast()


# --- M3 Task 21a: Simple controls — only the buttons that apply now ---

var _monster_near := false
var _simple_look_at := 0
var _simple_state := []   # [simple, monster near, crouching] when CROUCH was last shown or hidden


func _simple_shows_attack() -> bool:
	_simple_tick()
	var item := interactor.selected_block() if is_instance_valid(interactor) else 0
	return SimpleControls.show_attack(Player.simple_controls(), WeaponRules.is_weapon(item) or BlasterRules.is_blaster(item),
		_monster_near, attack_button.is_down())


func _simple_shows_crouch() -> bool:
	return SimpleControls.show_crouch(Player.simple_controls(), _monster_near,
		is_instance_valid(player) and player.crouching)


## Four times a second: is a monster within SimpleControls.MONSTER_NEAR of this game's player (Simple only)?
## CROUCH is shown or hidden again when that, the setting or crouching changed.
func _simple_tick() -> void:
	var now := Time.get_ticks_msec()
	if now - _simple_look_at < 250 or not is_instance_valid(player) or not player.is_inside_tree():
		return
	_simple_look_at = now
	var simple := Player.simple_controls()
	var near := false
	if simple:
		for m in get_tree().get_nodes_in_group(&"monsters"):
			var n := m as Node3D
			if n and n.global_position.distance_squared_to(player.global_position) <= SimpleControls.MONSTER_NEAR ** 2:
				near = true
				break
	_monster_near = near
	var state := [simple, near, player.crouching]
	if state != _simple_state:
		_simple_state = state
		_show_up_down()

# --- M5 Task 1: button sizes, the left hand, moved controls, text size (spec §15.1a) ------------------------------

var _layout_key := []   # what the layout was made from: the settings it reads, the moves, the screen
## Sound captions (SoundCaptions): a picture and a word towards an important sound; under the messages.
var captions := SoundCaptions.new()


## The table for this profile on this screen (HudLayout.configure_from); the display's safe area on a phone.
func _configure_layout() -> void:
	if PlatformRules.reads_safe_area(PlatformRules.current()) and is_inside_tree():   # M7: not a browser page
		var safe := Rect2(DisplayServer.get_display_safe_area())
		HudLayout.safe_area = get_viewport().get_final_transform().affine_inverse() * safe
	HudLayout.configure_from(Profile.data, get_viewport_rect().size)
	_layout_key = _layout_now()


func _layout_now() -> Array:
	var s := Profile.data.settings
	return [s.get("button_size"), s.get("left_handed"), Profile.data.hud_moves.duplicate(true), s.get("text_size"),
		get_viewport_rect().size]


func _add_access() -> void:
	captions.name = "SoundCaptions"
	add_child(captions)
	move_child(captions, _toast_panel.get_index())   # like the danger arrows: under the toasts
	TextSize.mark(_toast_label, 26)
	TextSize.mark(username_label, 28)
	_after_placing()
	Game.settings_applied.connect(_on_settings_applied)
	get_viewport().size_changed.connect(relayout)


func _on_settings_applied(_settings: Dictionary) -> void:
	if _layout_now() != _layout_key:   # a volume slider changes nothing here
		relayout()


## Places every control again: the button size, the hand, a move or the screen changed (each placed control knows
## its spot, HudLayout.PLACED).
func relayout() -> void:
	if not is_inside_tree():
		return
	_configure_layout()
	for n in find_children("*", "Control", true, false):
		var c := n as Control
		if c.has_meta(HudLayout.PLACED):
			var m: Array = c.get_meta(HudLayout.PLACED)
			HudLayout.place(c, m[0], m[1])
	_after_placing()


## What follows the table: the stick's size, the name's side, the online dot, the race clock and the toasts under a
## visit's bar, the MORE panel's side, the chat's bar and lines, the text size.
func _after_placing() -> void:
	var f := HudLayout.factor()
	joystick.joystick_size = HudLayout.STICK * f
	joystick.tip_size = HudLayout.STICK_TIP * f
	joystick.notification(NOTIFICATION_RESIZED)   # the stick rests in its new area
	var edge := HORIZONTAL_ALIGNMENT_LEFT if HudLayout.left_handed else HORIZONTAL_ALIGNMENT_RIGHT
	username_label.horizontal_alignment = edge
	fps_label.horizontal_alignment = edge
	_on_online_dot(online_dot.on)
	push_top(_top_inset)
	more.relayout()
	TextSize.refresh(get_tree())   # before the chat measures its lines again
	chat.relayout()


## The Theater's panel while it shows (set_theater_open): the thumb buttons under its buttons step aside, looked at
## again four times a second (its pages change, and it lays its buttons out a frame after opening).
var _theater: Control
var _theater_look := 0.0


func _theater_tick(delta: float) -> void:
	if not is_instance_valid(_theater):
		return
	_theater_look -= delta
	if _theater_look <= 0.0:
		_theater_look = 0.25
		_tuck_under_theater()


## True when one of the Theater's buttons covers `b` (ATTACK, GLIDE, CROUCH and DOWN ask it every frame).
func _under_theater(b: Control) -> bool:
	if not is_instance_valid(_theater) or not _theater.visible:
		return false
	var r := b.get_global_rect()
	for n in _theater.find_children("*", "BaseButton", true, false):
		var t := n as Control
		if t.is_visible_in_tree() and r.intersects(t.get_global_rect()):
			return true
	return false


## JUMP steps aside like BOOK (its visibility is not set every frame); CROUCH and DOWN follow it.
func _tuck_under_theater() -> void:
	if jump_button.visible and _under_theater(jump_button):
		jump_button.visible = false
		_tucked.append(jump_button)
	_show_up_down()
