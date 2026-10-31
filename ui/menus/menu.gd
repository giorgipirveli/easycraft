extends Node3D
## Main menu over a live, slowly orbiting view of the Meadows. On first launch it walks through
## the neutral age question, the username and (owner feedback #48) BOY / GIRL / JUST ME before showing the
## mode choice.

const WORLD_SCENE := preload("res://world/world.tscn")
const BACKDROP_SEED := 20260923
const ORBIT_RADIUS := 34.0
const ORBIT_SPEED := 0.05

var _world: WorldService
var _cam := Camera3D.new()
var _orbit_center := Vector3.ZERO
var _angle := 0.0
var _diorama: TitleDiorama

var _ui := Control.new()
var _center := CenterContainer.new()
## Owner 43: the title is our own wordmark (bubble-block letters, tools/make_brand_art.py), drawn at LOGO_SIZE.
const WORDMARK := preload("res://assets/brand/wordmark.png")
const LOGO_SIZE := Vector2(492, 120)
## Where the panels' room starts, under the name and the credit.
const CENTER_TOP := 130.0
## Kept free around a panel that takes the whole screen.
const EDGE := 4.0
var _logo := TextureRect.new()
var _credit := Label.new()   # owner 2026-09-28: "Made by Alexander Pirveli" under the name
var _username := Label.new()
var _version := Label.new()
var _admin := CodePanel.admin_link()   # small black "admin panel" text, main screen only (M3 Task 13)


func _ready() -> void:
	VrEntry.preview_from_args(OS.get_cmdline_user_args())   # owner #101: --vr-preview, the desktop's look at VR
	add_to_group(ShaderWarmup.AT_MENU)   # M7: the shader warm-up's rest draws here while nobody touches the menu
	Music.play_menu()   # the gentle day track (M2 Task 11)
	_build_backdrop()
	_build_ui()
	_route()
	_setup_vr()   # owner #101: in a headset the menu holds still, the child standing on its hill; ENTER VR (Web VR)
	Session.online_autostart()   # M4 C: friends' invites reach a device that has been online before
	Session.back_online.connect(_on_back_online)   # owner #95: signed in again by itself after an offline spell
	_warm_then_announce()   # M7: in a browser, MENU ready (the loading page leaves) after the shader warm-up


const BACK_ONLINE_SECONDS := 5.0


## Owner #95: the game signed in again by itself (ReconnectWatch): a note across the top for a few seconds, over
## everything, never taking a tap.
func _on_back_online() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 50
	UiLayers.route(layer, self)   # owner #101: in VR on the panel
	var box := PanelContainer.new()
	box.add_theme_stylebox_override("panel", UiKit.box(Color(0.1, 0.45, 0.25, 0.92), 16, 14))
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var words := Label.new()
	words.text = ReconnectRules.BACK_WORDS
	words.add_theme_font_size_override("font_size", 26)
	words.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(words)
	layer.add_child(box)
	box.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	box.position.y = 16.0
	var t := create_tween()
	t.tween_interval(BACK_ONLINE_SECONDS)
	t.tween_property(box, "modulate:a", 0.0, 0.6)
	t.tween_callback(layer.queue_free)


## M7 (docs/devlog/parts/m7-shader-warmup.md): where the renderer compiles shaders on first sight (a browser), what the
## menu and a first world show is drawn once, hidden, before `MENU ready` (the loading page shows its progress); the
## rest goes on after (ShaderWarmup). Elsewhere the menu announces at once.
var warmup: ShaderWarmup
var announced := false


func _warm_then_announce() -> void:
	warmup = ShaderWarmup.start(self, _world)
	if warmup:
		await warmup.first_done
		warmup = null
	announced = true
	_startup_probe()   # M5 Task 3


# --- M5 Task 3: startup time ---------------------------------------------------------------------------------------

## The menu is ready: prints the milliseconds since the engine started (logcat on a phone: `MENU ready_ms`) and the
## main thread's own CPU time so far (Linux and Android /proc; -1 elsewhere: unlike the wall time it hardly changes
## with what else the device runs), once per run. The developer arg --startup-probe also prints the first frame and
## quits (the headless measurement in docs/devlog/parts/m5-task-3.md).
static var _startup_printed := false


func _startup_probe() -> void:
	if _startup_printed:
		return
	_startup_printed = true
	print("MENU ready_ms=%d main_cpu_ms=%d" % [Time.get_ticks_msec(), _main_cpu_ms()])
	if not OS.get_cmdline_user_args().has("--startup-probe"):
		return
	await get_tree().process_frame
	print("MENU first_frame_ms=%d" % Time.get_ticks_msec())
	get_tree().quit()


## This thread's user + system CPU time in ms (/proc/thread-self/stat, 100 Hz ticks), or -1.
static func _main_cpu_ms() -> int:
	var f := FileAccess.open("/proc/thread-self/stat", FileAccess.READ)
	if f == null:
		return -1
	var fields := f.get_line().get_slice(")", 1).split(" ", false)
	return (int(fields[11]) + int(fields[12])) * 10 if fields.size() > 12 else -1


func _build_backdrop() -> void:
	_world = WORLD_SCENE.instantiate()
	_world.setup("", BACKDROP_SEED)
	add_child(_world)
	_world.apply_graphics(Profile.data.settings)
	_world.apply_style(str(Profile.data.settings.style))
	Game.settings_applied.connect(_restyle_backdrop)   # M7: a style picked in SETTINGS shows at once
	_orbit_center = _find_backdrop_spot()
	var viewer := VoxelViewer.new()
	viewer.view_distance = 96
	viewer.view_distance_vertical_ratio = 0.5   # the orbiting camera never needs the deep underground
	viewer.requires_collisions = false   # M7: nothing here stands on the ground (collision was built on the main thread)
	_cam.add_child(viewer)
	_cam.fov = 60.0
	add_child(_cam)
	_cam.current = true
	_place_camera()
	_diorama = TitleDiorama.new()   # M5 Task 2: the living title diorama, behind the wordmark (hidden with Reduce motion)
	_cam.add_child(_diorama)


## The style picked in SETTINGS, at once (it kept its first style until the next menu). M7: REALISTIC in a browser
## before its pictures shows when they land (WorldService.realistic_pictures_arrived).
func _restyle_backdrop(settings: Dictionary) -> void:
	_world.apply_style(str(settings.style))


## The closest hilly spot to the origin (land a bit above the sea), so the orbit shows land and trees.
func _find_backdrop_spot() -> Vector3:
	var best := Vector3(0, MeadowsShape.SEA_LEVEL + 8, 0)
	var best_dist := INF
	for gx in range(-16, 17):
		for gz in range(-16, 17):
			var x := gx * 16
			var z := gz * 16
			var h := _world.surface_height(x, z)
			var d := Vector2(x, z).length()
			if h >= MeadowsShape.SEA_LEVEL + 5 and h <= MeadowsShape.SEA_LEVEL + 22 and d < best_dist:
				best_dist = d
				best = Vector3(x, h + 6, z)
	return best


func _process(delta: float) -> void:
	if not Feel.motion_allowed() or Vr.active():
		return                        # M5 Task 2: Reduce motion: the camera holds still; owner #101: and in a headset
	_angle += delta * ORBIT_SPEED
	_place_camera()


func _place_camera() -> void:
	_cam.position = _orbit_center + Vector3(cos(_angle) * ORBIT_RADIUS, 14.0, sin(_angle) * ORBIT_RADIUS)
	_cam.look_at(_orbit_center, Vector3.UP)

# --- Owner #101: VR on the Meta Quest ---------------------------------------------------------------------------------

## Where the child's eyes are in a headset: over the backdrop's hill (the orbit's middle), at the avatar's eye height
## above the ground (a menu spot is the eye's place: Vr.anchor's &"menu"; null until VR).
var vr_stand: Node3D
var _vr_entry: VrEntry


func _setup_vr() -> void:
	Vr.started.connect(_on_vr_started)
	Vr.ended.connect(_on_vr_ended)
	if Vr.active():
		_on_vr_started()
	if VrEntry.wanted():   # the Web VR export (/vr/): ENTER VR where the browser can
		_vr_entry = VrEntry.new(VrEntry.find())
		_vr_entry.ready = func() -> bool: return announced
		var b := _vr_entry.button()
		_ui.add_child(b)
		b.position = Vector2(16, 16)
		_vr_entry.ask()


## In a headset the camera never orbits (a camera move the child did not make): it holds still where the child stands,
## on the hill, level, looking the way the window's view looked; the XR origin puts the eyes there (Vr.anchor, &"menu":
## the eye on the spot, facing its way) and the screens are on the eye panel (UiLayers). The title diorama rides on the
## camera, so it stays in front.
func _on_vr_started() -> void:
	if vr_stand == null:
		vr_stand = Node3D.new()
		vr_stand.name = "VrStand"
		add_child(vr_stand)
	var x := floori(_orbit_center.x)
	var z := floori(_orbit_center.z)
	vr_stand.global_position = Vector3(x + 0.5, _world.surface_height(x, z) + CameraRig.HEAD_HEIGHT, z + 0.5)
	vr_stand.global_rotation = Vector3(0.0, atan2(cos(_angle), sin(_angle)), 0.0)   # from the orbit's spot over the hill
	_cam.global_transform = vr_stand.global_transform
	Vr.anchor(vr_stand, &"menu")


## The menu goes (a world starts): the headset never follows a spot that has left the tree.
func _exit_tree() -> void:
	if Vr.anchor_kind() == &"menu" and is_instance_valid(vr_stand):
		Vr.anchor(null)


func _on_vr_ended() -> void:
	if Vr.anchor_kind() == &"menu":
		Vr.anchor(null)
	if is_inside_tree():
		_place_camera()   # orbiting again


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	UiLayers.route(layer, self)   # owner #101: in VR the menu's screens are on the eye panel
	_ui.theme = UiKit.theme()
	layer.add_child(_ui)
	_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE

	_ui.add_child(_logo)
	_logo.texture = WORDMARK
	_logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_logo.custom_minimum_size = LOGO_SIZE
	_logo.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_logo.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_logo.offset_top = 8
	_logo.pivot_offset = LOGO_SIZE * 0.5
	_ui.add_child(_credit)
	_credit.text = "Made by Alexander Pirveli"
	_credit.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_credit.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_credit.add_theme_font_size_override("font_size", 20)
	_credit.add_theme_color_override("font_color", Color.WHITE)
	_credit.add_theme_color_override("font_outline_color", Color(0.12, 0.16, 0.29))   # the brand ink
	_credit.add_theme_constant_override("outline_size", 6)
	_credit.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_credit.offset_left = -220
	_credit.offset_right = 220
	_credit.offset_top = _logo.offset_top + LOGO_SIZE.y - 4
	_credit.offset_bottom = _credit.offset_top + 28
	var bob := create_tween().set_loops()
	bob.tween_property(_logo, "rotation", deg_to_rad(2.0), 1.2).set_trans(Tween.TRANS_SINE)
	bob.tween_property(_logo, "rotation", deg_to_rad(-2.0), 1.2).set_trans(Tween.TRANS_SINE)

	_ui.add_child(_center)
	_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_center.offset_top = CENTER_TOP
	_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	PadFocus.watch(_center)   # owner #90: every screen of the menu (and the School in it) with a game controller

	_ui.add_child(_username)
	_username.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED   # M3 Task 21a: a name stays a name
	_username.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_username.offset_left = -440
	_username.offset_right = -20
	_username.offset_top = 16
	_username.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_username.add_theme_font_size_override("font_size", 28)
	_ui.add_child(AccountsOverlay.menu_button(null, _logo))   # owner #99, #105: LOG IN / LOG OUT under the name, hidden with the logo (ui/online/accounts_overlay.gd)

	_ui.add_child(_version)
	_version.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	_version.offset_left = 16
	_version.offset_top = -44
	# owner #123: the build beside the version ("v1.0.6 (17 Oct, 90e976cc)"), so a phone and the web can be compared
	_version.text = BuildInfo.label(str(ProjectSettings.get_setting("application/config/version", "0.1.0")),
		BuildInfo.current())
	_version.add_theme_font_size_override("font_size", 20)
	_version.mouse_filter = Control.MOUSE_FILTER_STOP
	_version.gui_input.connect(_on_version_input)
	var update_note := UpdateNote.new(Updater.has_ready, Callable()) if Updater.menu_shown() else UpdateNote.new()   # owner #123: "A new EasyCraft is ready!" when one has downloaded; an installed app's from its updater (which learns the menu showed)
	_ui.add_child(update_note)
	update_note.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	update_note.offset_top = -88
	update_note.offset_bottom = -16
	update_note.grow_horizontal = Control.GROW_DIRECTION_BOTH

	_ui.add_child(_admin)
	_admin.visible = false
	_admin.pressed.connect(_show_codes)


func _route() -> void:
	_username.text = Profile.data.username
	var web_code: String = web_invite_code.call()   # owner #79: a child who already plays opened an invite link
	if web_code != "" and Profile.data.is_onboarded() and not Profile.data.invite.used \
			and Profile.data.invite.pending_code == "":
		Profile.data.invite.pending_code = web_code   # the next sign-in asks the server (a code is for new explorers)
		Profile.save()
	if Profile.data.is_onboarded():
		_welcome(_show_home)   # M3 Task 21a: the language and Simple controls cards, once; M7: then maybe the install card
	elif AgeBand.is_valid(Profile.data.age_band):
		_show_name()
	else:
		_show_start()


var _at_root := false
## Quits the app (tests record it instead).
var quit_game := func() -> void: get_tree().quit()


## Android Back: step back to the main panel (or the start of onboarding); quit only from there (M7: never in a
## browser, whose tab the browser closes).
func _notification(what: int) -> void:
	if what != NOTIFICATION_WM_GO_BACK_REQUEST or not is_node_ready():
		return
	if HudEditor.close_open():
		return   # M5 Task 6 review: Back over MOVE BUTTONS closes only it (the menu went to its first screen under it)
	if LifeRoomHost.any_open(get_tree()) or PlayHost.any_open(get_tree()):
		return   # owner #112: Back inside a Life practice room asks "Leave the practice?" (the room's own card); #122: a game too
	if _at_root:
		if PlatformRules.can_quit(PlatformRules.current()) and not PadFocus.back_from_pad:   # owner #90: a pad's B never quits
			quit_game.call()
	else:
		_route()


## `universe` > 0: one universe's screen: its scene behind the buttons (M5 Task 2, UniverseBackdrop).
func _show(content: Control, universe: int = 0) -> void:
	_at_root = false
	_admin.visible = false
	for c in _center.get_children():
		c.queue_free()
	var panel := PanelContainer.new()
	var backdrop: UniverseBackdrop = null
	if universe > 0:
		backdrop = UniverseBackdrop.new(universe)
		panel.add_child(backdrop, false, Node.INTERNAL_MODE_FRONT)   # behind the content, outside its layout
	panel.add_child(content)
	_center.add_child(panel)
	if backdrop:
		backdrop.fit_inside(panel)
	ReadAloud.auto(ReadAloud.title_of(content))   # M3 Task 21a: "Read to me" reads each screen's title
	var fit := _make_room(panel.get_combined_minimum_size().y)
	panel.scale = Vector2(0.92, 0.92) * fit
	panel.pivot_offset = panel.get_combined_minimum_size() * 0.5
	create_tween().tween_property(panel, "scale", Vector2.ONE * fit, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## A panel taller than the room under the name (SETTINGS: 711 px of 720) takes the whole screen while it shows, the
## name and the credit hidden, so BACK is never below the screen (2026-09-28, a 20:9 phone's browser); one still taller
## is drawn smaller. Returns the scale the panel is drawn at.
func _make_room(height: float) -> float:
	var screen_h := get_viewport().get_visible_rect().size.y if is_inside_tree() else 720.0
	var tall := height > screen_h - CENTER_TOP - EDGE
	_center.offset_top = 0.0 if tall else CENTER_TOP
	_logo.visible = not tall
	_credit.visible = not tall
	return minf(1.0, (screen_h - 2.0 * EDGE) / height) if tall else 1.0


func _vbox(title: String) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 20)
	if title != "":
		v.add_child(ReadAloud.with_speaker(UiKit.title(title), v))   # M3 Task 21a: the speaker reads the screen
	return v


# --- First launch -------------------------------------------------------------------------

func _show_start() -> void:
	var v := _vbox("")
	var play := UiKit.big_button("PLAY", UiKit.GREEN, Vector2(420, 120))
	play.add_theme_font_size_override("font_size", 52)
	play.pressed.connect(_after_play)
	v.add_child(play)
	v.add_child(AccountsOverlay.start_log_in_button())   # owner #105: LOG IN with the name and the password (ui/online/accounts_overlay.gd)
	_show(v)


## The first PLAY: the age question while age rules are on; else straight to the name, as 13+ (the owner, 2026-09-29:
## "remove all such restrictions"; AgeBand.restrictions).
func _after_play() -> void:
	if AgeBand.restrictions:
		_show_age()
		return
	Profile.data.age_band = AgeBand.TEEN_PLUS
	Profile.save()
	_show_name()


## Owner #57: "there should be just window to type age, not years". A box for the age and the game's own number
## pad (AgePad); OK keeps only the band (AgeBand.from_age), then the name.
func _show_age() -> void:
	var v := _vbox("How old are you?")
	var shown := Label.new()
	shown.text = "?"
	shown.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	shown.add_theme_font_size_override("font_size", 56)
	var box := PanelContainer.new()
	box.custom_minimum_size = Vector2(220, 84)
	box.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var look := StyleBoxFlat.new()
	look.bg_color = Color.WHITE
	look.set_corner_radius_all(16)
	look.set_border_width_all(4)
	look.border_color = Color(0.12, 0.16, 0.29)
	box.add_theme_stylebox_override("panel", look)
	shown.add_theme_color_override("font_color", Color(0.12, 0.16, 0.29))
	box.add_child(shown)
	v.add_child(box)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 10)
	var typed := [""]
	var ok := UiKit.big_button("OK", UiKit.GREEN, Vector2(150, 72))
	ok.disabled = true
	var refresh := func() -> void:
		shown.text = typed[0] if typed[0] != "" else "?"
		ok.disabled = not AgePad.is_complete(typed[0])
	for key: String in ["1", "2", "3", "4", "5", "6", "7", "8", "9", AgePad.DELETE, "0"]:
		var b := UiKit.big_button(key, UiKit.BLUE if key == AgePad.DELETE else Color(), Vector2(150, 72))
		if key == AgePad.DELETE:
			b.add_theme_font_size_override("font_size", 24)
		b.pressed.connect(func() -> void:
			typed[0] = AgePad.press(typed[0], key)
			refresh.call())
		grid.add_child(b)
	ok.pressed.connect(func() -> void: _on_age(AgePad.value(typed[0])))
	grid.add_child(ok)
	v.add_child(grid)
	_show(v)


func _on_age(age: int) -> void:
	Profile.data.age_band = AgeBand.from_age(age)
	Profile.save()
	_show_name()   # owner #52: English only, no language card after the age screen


func _show_name() -> void:
	var v := _vbox("Pick your name")
	var edit := LineEdit.new()
	edit.max_length = UsernameRules.MAX_LEN
	edit.placeholder_text = "Your name"
	edit.custom_minimum_size = Vector2(520, 84)
	edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	edit.text = Profile.data.username
	v.add_child(edit)
	var hint := Label.new()
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 24)
	v.add_child(hint)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 16)
	var random := UiKit.big_button("RANDOM", UiKit.BLUE, Vector2(240, 88))
	var ok := UiKit.big_button("OK", UiKit.GREEN, Vector2(240, 88))
	row.add_child(random)
	row.add_child(ok)
	v.add_child(row)
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var validate := func(text: String) -> void:
		var code := UsernameRules.validate(text)
		ok.disabled = code != ""
		hint.text = UsernameRules.message(code) if code != "" and text != "" else ""
		hint.add_theme_color_override("font_color", Color("ff8a80"))
	edit.text_changed.connect(validate)
	edit.text_submitted.connect(func(_t: String) -> void: if not ok.disabled: ok.pressed.emit())
	random.pressed.connect(func() -> void:
		edit.text = NameSuggester.suggest(rng)
		validate.call(edit.text))
	ok.pressed.connect(func() -> void:
		Profile.data.username = UsernameRules.normalize(edit.text)
		Profile.save()
		_username.text = Profile.data.username
		_show_code_step())
	validate.call(edit.text)
	_show(v)
	if PlatformRules.keyboard_first(PlatformRules.current()):   # owner #84: a PC types at once (a phone taps the box)
		edit.grab_focus.call_deferred()


## Owner #79 (spec §25.2): after the name, "Did a friend give you an invite code?" (the web page's ?invite= fills it in);
## NO CODE or a used code goes on to BOY / GIRL / JUST ME. Nothing waits for the network: without it the code is kept.
func _show_code_step() -> void:
	if Profile.data.invite.used:
		_show_look_step()
		return
	var box := InviteCodeBox.new()
	box.service = Session.online_service()
	box.prefill = web_invite_code.call() if Profile.data.invite.pending_code == "" else Profile.data.invite.pending_code
	box.done.connect(func(_r: Dictionary) -> void: _show_look_step(), CONNECT_ONE_SHOT)
	_show(box)


## The web page's ?invite= (WebGlue; tests pretend).
var web_invite_code := func() -> String: return WebGlue.invite_code()


## INVITE A FRIEND (owner #79): the code, the link, the QR code, the friends and the tree.
func _show_invite() -> void:
	var page := InvitePage.new()
	page.service = Session.online_service()
	page.closed.connect(_show_main)
	_show(page)


## FRIENDS (owner #81, #82, #85): friendship levels, cheers, presents, study buddies and the crew (FriendsPage).
func _show_friends() -> void:
	var page := FriendsPage.new()
	page.service = Session.online_service()
	page.closed.connect(_show_main)
	page.invite_requested.connect(_show_invite)
	_show(page)


## The GOLD SHOP (owner #83): Explorer lessons, rocket parts, weapons and tools, avatar things (SpendRules).
func _show_gold_shop() -> void:
	var shop := GoldShop.new()
	shop.closed.connect(_show_main)
	_show(shop)


## Good news from friends (owner #79), on a card over the main menu once: now, or when it arrives while it shows. A code
## kept on this device that the server has now answered says its words the same way.
func _invite_news_soon() -> void:
	var service := Session.online_service_or_null()
	if service == null:
		return
	if not service.invite_news_arrived.is_connected(_on_invite_news):
		service.invite_news_arrived.connect(_on_invite_news)
		service.invite_code_result.connect(_on_invite_code_result)
	if not service.invite_news.is_empty():
		_on_invite_news.call_deferred()


func _on_invite_news() -> void:
	var service := Session.online_service_or_null()
	if service == null or not _at_root or service.invite_news.is_empty() or not is_inside_tree():
		return
	var card := InviteNewsCard.new(service.take_invite_news())
	card.closed.connect(_show_main, CONNECT_ONE_SHOT)
	_show(card)


func _on_invite_code_result(r: Dictionary) -> void:
	var service := Session.online_service_or_null()
	if service == null or str(r.get("text", "")) == "":
		return
	service.invite_news.append({"what": "code", "text": str(r.text), "gold": int(r.get("welcome", 0))})
	_on_invite_news()


## Owner 48 (spec §14.6a): the last first-launch step: BOY / GIRL / JUST ME (LookChoice saves it).
func _show_look_step() -> void:
	var step := LookChoice.new()
	step.chosen.connect(func(_b: StringName) -> void: _welcome(_show_main))   # M3 Task 21a: then Simple controls?
	_show(step)


# --- Mode choice ----------------------------------------------------------------------------

func _show_main() -> void:
	var v := _vbox("Choose your game")
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	var sandbox := UiKit.big_button("SANDBOX\nBuild anything!", UiKit.GREEN, MAIN_BUTTON)
	sandbox.pressed.connect(_on_sandbox)
	var survivor := UiKit.big_button("SURVIVOR\nSurvive the night!", UiKit.RED, MAIN_BUTTON)
	survivor.pressed.connect(_on_survivor)
	var wave := UiKit.big_button("MONSTER WAVE\nStay alive!", UiKit.ORANGE, MAIN_BUTTON)   # owner feedback #44, §12.20
	wave.pressed.connect(_show_wave)
	var online := UiKit.big_button("PLAY ONLINE\nWith friends!", OnlineUi.PURPLE, MAIN_BUTTON)   # M4 C
	online.pressed.connect(_show_online)
	row.add_child(sandbox)
	row.add_child(survivor)
	row.add_child(wave)
	row.add_child(online)
	v.add_child(row)
	var settings := UiKit.big_button("SETTINGS", Color(), EXTRA_BUTTON)
	settings.pressed.connect(_show_settings)
	var avatar := UiKit.big_button("AVATAR", UiKit.BLUE, EXTRA_BUTTON)   # M3 Task 9
	avatar.pressed.connect(_show_avatar)
	var invite := UiKit.big_button("INVITE", OnlineUi.PURPLE, EXTRA_BUTTON)   # owner #79: invite a friend
	invite.pressed.connect(_show_invite)
	var shop := UiKit.big_button("GOLD SHOP", Color("c9901a"), EXTRA_BUTTON)   # owner #83
	shop.pressed.connect(_show_gold_shop)
	var friends := UiKit.big_button("FRIENDS", Color("d9437a"), EXTRA_BUTTON)   # owner #81, #85: friends and the crew
	friends.pressed.connect(_show_friends)
	var extras := HBoxContainer.new()
	extras.alignment = BoxContainer.ALIGNMENT_CENTER
	extras.add_theme_constant_override("separation", EXTRA_GAP)
	extras.add_child(_school_button())   # owner #68
	extras.add_child(invite)
	extras.add_child(friends)
	extras.add_child(shop)
	extras.add_child(avatar)
	extras.add_child(settings)
	for b: Button in extras.get_children():
		b.add_theme_font_size_override("font_size", EXTRA_FONT)
	v.add_child(extras)
	_show(v)
	_at_root = true
	_admin.visible = true
	_invite_news_soon()   # owner #79: good news from friends, on a card


## PLAY ONLINE (M4 Wave 1, Agent C; spec §17): sign in, then the card, the name, friends and hosting.
func _show_online() -> void:
	var screen := PlayOnlineScreen.new()
	screen.service = Session.online_service()
	screen.closed.connect(_show_main)
	screen.host_requested.connect(OnlineFlow.host)
	screen.join_requested.connect(func(match_id: String) -> void: OnlineFlow.join(match_id))
	_show(screen)


## The avatar editor (M3 Task 9): outside a world it spends the profile's Survivor gold itself.
func _show_avatar() -> void:
	var editor := AvatarEditor.new()
	editor.closed.connect(_show_main)
	_show(editor)


func _on_sandbox() -> void:
	if sandbox_worlds().size() > 1:
		_show_sandbox_hub()   # owner 39: a Sandbox world per universe a portal led to
	else:
		_show_mode(ModeRules.SANDBOX)


func _on_survivor() -> void:
	if UniverseRules.shows_hub(Profile.data.universe_unlocked):
		_show_hub()   # M3 Task 5: more than one universe to choose
	else:
		_show_mode(ModeRules.SURVIVOR)


## CONTINUE / NEW WORLD / BACK for a mode's own world (a new world right away when there is none);
## Survivor: the world of `universe` (M3 Task 5).
func _show_mode(world_mode: StringName, universe: int = 1) -> void:
	if not WorldSaves.exists(ModeRules.slot(world_mode, universe)):
		_new_world(world_mode, universe)
		return
	var v := _vbox(_world_title(world_mode, universe))
	var cont := UiKit.big_button("CONTINUE", UiKit.GREEN, Vector2(420, 100))
	cont.pressed.connect(Game.start_world.bind(world_mode, false, DifficultyRules.NORMAL, universe))
	var fresh := UiKit.big_button("NEW WORLD", UiKit.ORANGE, Vector2(420, 100))
	fresh.pressed.connect(_confirm_new_world.bind(world_mode, universe))
	var back := UiKit.big_button("BACK", UiKit.BLUE, Vector2(420, 84))
	back.pressed.connect(_back_from_mode.bind(world_mode))
	for b in [cont, fresh, back]:
		v.add_child(b)
	_show(v, universe)


func _confirm_new_world(world_mode: StringName = ModeRules.SANDBOX, universe: int = 1) -> void:
	var v := _vbox("Start a new world?")
	var warn := Label.new()
	warn.text = tr("Your old %s world will be gone.") % _world_title(world_mode, universe)
	warn.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(warn)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 16)
	var yes := UiKit.big_button("YES, NEW WORLD", UiKit.ORANGE, Vector2(320, 90))
	yes.pressed.connect(_new_world.bind(world_mode, universe))
	var no := UiKit.big_button("NO", UiKit.BLUE, Vector2(200, 90))
	no.pressed.connect(_show_mode.bind(world_mode, universe))
	row.add_child(yes)
	row.add_child(no)
	v.add_child(row)
	_show(v, universe)


## A new world: Survivor first asks how brave to be (M2 Task 17); Sandbox starts at once.
func _new_world(world_mode: StringName, universe: int = 1) -> void:
	if world_mode == ModeRules.SURVIVOR:
		_choose_difficulty(universe)
	else:
		Game.start_world(world_mode, true, DifficultyRules.NORMAL, universe)   # owner 39: that universe's Sandbox world


## COZY / NORMAL / BRAVE side by side, a short line under each (DifficultyRules), then BACK; for a new
## world of `universe` (M3 Task 5).
func _choose_difficulty(universe: int = 1) -> void:
	var v := _vbox("How brave are you?")
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 18)
	var colors := {DifficultyRules.COZY: UiKit.GREEN, DifficultyRules.NORMAL: UiKit.BLUE, DifficultyRules.BRAVE: UiKit.ORANGE}
	for d: StringName in DifficultyRules.CHOICES:
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 8)
		var b := UiKit.big_button(DifficultyRules.label(d), colors[d], Vector2(260, 110))
		b.pressed.connect(_choose_game.bind(d, universe))   # then which game (spec §12.18)
		col.add_child(b)
		var about := Label.new()
		about.text = DifficultyRules.about(d)
		about.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		about.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		about.custom_minimum_size.x = 260
		col.add_child(about)
		row.add_child(col)
	v.add_child(row)
	var back := UiKit.big_button("BACK", UiKit.BLUE, Vector2(260, 84))
	back.pressed.connect(_back_from_mode.bind(ModeRules.SURVIVOR))
	var back_row := CenterContainer.new()
	back_row.add_child(back)
	v.add_child(back_row)
	_show(v, universe)


## Survivor games (owner feedback #33, spec §12.18): after how brave, which game — CLASSIC or BUILD TO SURVIVE
## as big picture cards with a short line under each, then BACK (to how brave).
const _GAME_COLORS := {SurvivorGames.CLASSIC: UiKit.GREEN, SurvivorGames.BUILD: UiKit.BLUE}
const _GAME_PICTURES := {SurvivorGames.CLASSIC: ItemIds.PICKAXE, SurvivorGames.BUILD: ItemIds.STAMP_HOUSE}


func _choose_game(difficulty: StringName, universe: int = 1) -> void:
	var v := _vbox("Which game?")
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 18)
	for g: StringName in SurvivorGames.CHOICES:
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 8)
		var b := UiKit.big_button(SurvivorGames.label(g), _GAME_COLORS[g], Vector2(330, 140))
		b.icon = BlockIcons.icon(_GAME_PICTURES[g])
		b.expand_icon = true   # the 16-32 px pictures, scaled up above the word
		b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		b.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		b.add_theme_constant_override("icon_max_width", 64)
		b.pressed.connect(Game.start_world.bind(ModeRules.SURVIVOR, true, difficulty, universe, g))
		col.add_child(b)
		var about := Label.new()
		about.text = SurvivorGames.about(g)
		about.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		about.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		about.custom_minimum_size.x = 330
		col.add_child(about)
		row.add_child(col)
	v.add_child(row)
	var back := UiKit.big_button("BACK", UiKit.BLUE, Vector2(260, 84))
	back.pressed.connect(_choose_difficulty.bind(universe))
	var back_row := CenterContainer.new()
	back_row.add_child(back)
	v.add_child(back_row)
	_show(v, universe)


# --- Monster Wave (owner feedback #44, spec §12.20) ---------------------------------------------------------

## The four main buttons share one row (SANDBOX / SURVIVOR / MONSTER WAVE / PLAY ONLINE).
const MAIN_BUTTON := Vector2(282, 200)
## SCHOOL, INVITE, FRIENDS, GOLD SHOP, AVATAR and SETTINGS in one row under the games (owner #79, #83; owner #81, #85:
## FRIENDS makes six), as wide together as the games' row.
const EXTRA_BUTTON := Vector2(182, 76)
const EXTRA_GAP := 16
const EXTRA_FONT := 26

## Game.start_world (tests put a stand-in here).
var start_world: Callable = Game.start_world


## MONSTER WAVE: a card for every universe unlocked (a missing one says "Coming soon!"), its best under it; a card
## starts that universe's arena.
func _show_wave() -> void:
	var v := _vbox("Monster Wave")
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 18)
	var available := UniverseRegistry.available()
	for u in range(1, UniverseRules.valid(Profile.data.universe_unlocked) + 1):
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 6)
		var card := UniverseCard.new(u, available.has(u))
		card.pressed.connect(_start_arena.bind(u))
		col.add_child(card)
		var best := Label.new()
		best.text = ArenaRules.best_line(_arena_best(u))
		best.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		best.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART   # universe 6: as narrow as its card (six fit the screen)
		best.custom_minimum_size = Vector2(UniverseCard.width_for(UniverseRegistry.size()), 0)
		col.add_child(best)
		row.add_child(col)
	v.add_child(row)
	var back := UiKit.big_button("BACK", UiKit.BLUE, Vector2(260, 84))
	back.pressed.connect(_show_main)
	var back_row := CenterContainer.new()
	back_row.add_child(back)
	v.add_child(back_row)
	_show(v)


## This profile's best in universe u's arena (none before the first run there).
func _arena_best(u: int) -> Dictionary:
	var slot := ModeRules.slot(ModeRules.WAVE, u)
	if not WorldSaves.exists(slot):
		return ArenaRules.new_record()
	var arena: Dictionary = WorldSaves.load_meta(slot).arena
	return arena.get(str(Profile.data.username), arena.get("player", ArenaRules.new_record()))


## Universe u's arena (made the first time; a run always starts fresh).
func _start_arena(u: int) -> void:
	if not UniverseRegistry.available().has(u):
		return   # "Coming soon!" (the card says so)
	start_world.call(ModeRules.WAVE, not WorldSaves.exists(ModeRules.slot(ModeRules.WAVE, u)), DifficultyRules.NORMAL, u)


# --- Owner #68: School (spec §22) ---------------------------------------------------------------------------------

## Loaded only when SCHOOL is pressed: the menu's start stays as fast as before (spec §22.6 ruling 11).
const SCHOOL_SCREEN := "res://ui/school/school_screen.gd"


func _school_button() -> Button:
	var b := UiKit.big_button("DISCOVER", Color("139e9b"), EXTRA_BUTTON)   # owner #122 (G0): "we are not school"
	b.pressed.connect(_show_school)
	return b


func _show_school() -> void:
	var screen: Control = load(SCHOOL_SCREEN).new()
	screen.connect(&"closed", _show_main)
	_show(screen)


func _show_settings() -> void:
	var panel := SettingsPanel.new()
	panel.closed.connect(_show_main)
	_show(panel)


## The secret-code field (M3 Task 13), from the small "admin panel" text.
func _show_codes() -> void:
	var panel := CodePanel.new()
	panel.closed.connect(_show_main)
	_show(panel)


var _version_taps: Array[int] = []


## Triple-tap the version label (within one second) to open the developer menu.
func _on_version_input(event: InputEvent) -> void:
	if not OS.is_debug_build():   # the developer menu (LAN, autopilot) never ships to players
		return
	if not (event is InputEventMouseButton and (event as InputEventMouseButton).pressed):
		return
	var now := Time.get_ticks_msec()
	_version_taps.append(now)
	_version_taps = _version_taps.filter(func(t: int) -> bool: return now - t < 1000)
	if _version_taps.size() >= 3:
		_version_taps.clear()
		_show_dev()


func _show_dev() -> void:
	var v := _vbox("Developer")
	var lan := PlatformRules.lan_available(PlatformRules.current())   # M7: no home Wi-Fi play in a browser
	var info := Label.new()
	info.text = "LAN test: host on one device, join from another on the same Wi-Fi." if lan \
		else "No home Wi-Fi play in the browser: use PLAY ONLINE."
	info.add_theme_font_size_override("font_size", 22)
	v.add_child(info)
	var ip := LineEdit.new()
	ip.text = Game.join_address
	ip.custom_minimum_size = Vector2(420, 72)
	ip.alignment = HORIZONTAL_ALIGNMENT_CENTER
	ip.visible = lan
	# M3 acceptance: the autopilot's universe, beside the address (no row the lead taps moves).
	var world := UiKit.big_button("WORLD: " + UniverseRegistry.display_name(Game.autopilot_universe).to_upper(), UiKit.ORANGE, Vector2(360, 72))
	world.pressed.connect(func() -> void:
		Game.autopilot_universe = UniverseRegistry.next_autopilot(Game.autopilot_universe)   # the space worlds too
		world.text = "WORLD: " + UniverseRegistry.display_name(Game.autopilot_universe).to_upper())
	# Owner #79: FLY flies a test rocket (FlightTicket) from the Sandbox world to WORLD's space world, else the Moon; at
	# the end of the row, so no button the lead taps by position moves.
	var fly := UiKit.big_button("FLY ROCKET", UiKit.GREEN, Vector2(260, 72))
	fly.name = "FlyRocket"
	fly.pressed.connect(func() -> void:
		var to := Game.autopilot_universe
		FlightTicket.test_pending = to if SpaceRules.is_space(to) else SpaceRules.MOON
		FlightTicket.test_landing = false
		Game.start_sandbox(false))
	var ip_row := HBoxContainer.new()
	ip_row.alignment = BoxContainer.ALIGNMENT_CENTER
	ip_row.add_theme_constant_override("separation", 16)
	ip_row.add_child(ip)
	ip_row.add_child(world)
	ip_row.add_child(fly)
	v.add_child(ip_row)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 16)
	var host := UiKit.big_button("HOST LAN", UiKit.GREEN, Vector2(240, 84))
	host.pressed.connect(Game.host_lan_game)
	var join := UiKit.big_button("JOIN", UiKit.BLUE, Vector2(240, 84))
	join.pressed.connect(func() -> void: Game.join_lan_game(ip.text.strip_edges()))
	host.visible = lan   # never a dead button
	join.visible = lan
	var back := UiKit.big_button("BACK", Color(), Vector2(200, 84))
	back.pressed.connect(_show_main)
	# M2 Task 12: the next autopilot at night with monsters. At the end of this row, so no button the
	# lead taps by position moves.
	var night := UiKit.big_button("NIGHT RUN: ON" if Game.autopilot_night else "NIGHT RUN: OFF", UiKit.ORANGE, Vector2(260, 84))
	night.pressed.connect(func() -> void:
		Game.autopilot_night = not Game.autopilot_night
		night.text = "NIGHT RUN: ON" if Game.autopilot_night else "NIGHT RUN: OFF")
	for b in [host, join, back, night]:
		row.add_child(b)
	v.add_child(row)
	var pilots := HBoxContainer.new()
	pilots.alignment = BoxContainer.ALIGNMENT_CENTER
	pilots.add_theme_constant_override("separation", 16)
	for st: String in GraphicsPreset.STYLES:
		var pilot := UiKit.big_button("AUTOPILOT " + st.to_upper(), UiKit.ORANGE, Vector2(360, 80))
		pilot.pressed.connect(func() -> void:
			Profile.data.settings.style = st   # acceptance runs both graphics styles
			Profile.save()
			if Game.autopilot_universe > 1:   # a new Survivor world in that universe (WORLD)
				Game.start_world(ModeRules.SURVIVOR, true, DifficultyRules.NORMAL, Game.autopilot_universe)
			else:
				Game.start_sandbox(false)
			Game.autopilot = true)
		pilots.add_child(pilot)
	v.add_child(pilots)
	var buddies := UiKit.big_button("AUTOPILOT 10 BUDDIES", UiKit.ORANGE, Vector2(420, 80))
	buddies.pressed.connect(func() -> void:
		Profile.data.settings.style = "blocky"
		Profile.save()
		Game.start_sandbox(false)
		Game.autopilot = true
		Game.autopilot_buddies = true)
	# The acceptance tour (tools/tour.gd) in a new world, in the current style. The lead taps these
	# buttons by screen position and the panel has no room for another row, so it sits right of
	# 10 BUDDIES, with the Survivor tour on the left that keeps 10 BUDDIES (and every row) centred.
	var tour := UiKit.big_button("AUTOPILOT TOUR", UiKit.ORANGE, Vector2(360, 80))
	tour.pressed.connect(func() -> void:
		Game.start_sandbox(true)
		Game.autopilot_tour = true)
	# M2 Task 12: the Survivor tour (tools/tour_survivor.gd) in a new Survivor world, left of 10 BUDDIES.
	var balance := UiKit.big_button("SURVIVOR TOUR", UiKit.ORANGE, tour.custom_minimum_size)
	balance.name = "SurvivorTour"
	balance.pressed.connect(func() -> void:
		Game.start_world(ModeRules.SURVIVOR, true)
		Game.autopilot_tour = true)
	var last_row := HBoxContainer.new()
	last_row.alignment = BoxContainer.ALIGNMENT_CENTER
	last_row.add_theme_constant_override("separation", 16)
	for c: Control in [balance, buddies, tour]:
		last_row.add_child(c)
	v.add_child(last_row)
	_show(v)


func _current_year() -> int:
	return int(Time.get_date_dict_from_system().year)

# --- M3 Task 5: the portal hub (Survivor's universes) ---------------------------------------------------

## SURVIVOR once a second universe is unlocked: a picture card for every unlocked universe (UniverseCard);
## one whose file isn't there yet says "Coming soon!". A card opens that universe's CONTINUE / NEW WORLD.
func _show_hub() -> void:
	var v := _vbox("Choose a universe")
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 18)
	var plus_card := 0   # Owner 35: a universe that comes with EasyCraft Plus
	for e: Dictionary in UniverseRegistry.hub_entries(Profile.data.universe_unlocked):
		var card := UniverseCard.new(int(e.universe), bool(e.open))
		card.pressed.connect(_show_mode.bind(ModeRules.SURVIVOR, int(e.universe)))
		row.add_child(card)
		if card.plus_locked and plus_card == 0:
			plus_card = card.universe
	v.add_child(row)
	if plus_card > 0 and ShopWords.plus_once_due(Profile.data):   # Owner 35: said once, calmly, never again
		var once := Label.new()
		once.text = Session.shop_travel_refusal(plus_card)
		once.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		once.add_theme_font_size_override("font_size", 26)
		once.add_theme_color_override("font_color", Color("ffe14d"))
		v.add_child(once)
	var back := UiKit.big_button("BACK", UiKit.BLUE, Vector2(260, 84))
	back.pressed.connect(_show_main)
	var back_row := CenterContainer.new()
	back_row.add_child(back)
	v.add_child(back_row)
	_show(v)


## "Sandbox", "Survivor" (Green Meadows, as in M2) or the universe's name (owner 39: "Frostpeak Sandbox").
func _world_title(world_mode: StringName, universe: int) -> String:
	if world_mode != ModeRules.SURVIVOR:
		return "Sandbox" if universe <= 1 else tr("%s Sandbox") % Lang.t(UniverseRegistry.display_name(universe))
	return "Survivor" if universe <= 1 else UniverseRegistry.display_name(universe)


## BACK from a world's choices: the hub when there is one, else the main panel.
func _back_from_mode(world_mode: StringName) -> void:
	if world_mode == ModeRules.SURVIVOR and UniverseRules.shows_hub(Profile.data.universe_unlocked):
		_show_hub()
	elif world_mode == ModeRules.SANDBOX and sandbox_worlds().size() > 1:
		_show_sandbox_hub()   # owner 39
	else:
		_show_main()

# --- Owner feedback #39: a Sandbox world per universe ---------------------------------------------------------

## The universes that have a Sandbox world (Green Meadows always: M1's world, or the new one it makes);
## exists(slot) -> bool (tests pass their own; WorldSaves.exists by default).
static func sandbox_worlds(exists: Callable = Callable()) -> Array[int]:
	var out: Array[int] = [1]
	for u in range(2, UniverseRegistry.size() + 1):
		var slot := ModeRules.slot(ModeRules.SANDBOX, u)
		if bool(exists.call(slot)) if exists.is_valid() else WorldSaves.exists(slot):
			out.append(u)
	return out


## SANDBOX once a universe portal made a second Sandbox world: a picture card per world (CONTINUE / NEW WORLD
## for it), then BACK.
func _show_sandbox_hub() -> void:
	var v := _vbox("Choose a Sandbox world")
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	var worlds := sandbox_worlds()
	row.add_theme_constant_override("separation", 18 if worlds.size() <= 4 else 8)
	for u in worlds:
		var card := UniverseCard.new(u, UniverseRegistry.exists(u))
		card.pressed.connect(_show_mode.bind(ModeRules.SANDBOX, u))
		row.add_child(card)
	v.add_child(row)
	var back := UiKit.big_button("BACK", UiKit.BLUE, Vector2(260, 84))
	back.pressed.connect(_show_main)
	var back_row := CenterContainer.new()
	back_row.add_child(back)
	v.add_child(back_row)
	_show(v)

# --- M3 Task 21a: the welcome cards (the language, Simple controls), each once ---

## Shows the next card this child has not seen (only those of `kinds`, when given), then calls `then`.
func _welcome(then: Callable, kinds: Array = []) -> void:
	for kind: StringName in WelcomeCards.due(Profile.data.settings):
		if kinds.is_empty() or kinds.has(kind):
			var card := WelcomeCards.card(kind)
			card.connect(&"chosen", func() -> void: _welcome(then, kinds), CONNECT_ONE_SHOT)
			_show(card)
			return
	then.call()

# --- M7 (owner 2026-09-28): "Add EasyCraft to this device" (InstallOffer, InstallCard) ---

## The page's install state (WebGlue; tests pretend), asking the page for the browser's install prompt or Safari's
## picture guide, and saving the profile (tests never write the shared file).
var install_state := func() -> Dictionary: return WebGlue.install_state()
var request_install := func() -> void: WebGlue.request_install()
var save_profile := func() -> void: Profile.save()


## The games, or first (in a browser that can add the game, after some play, once a run) the card that offers it.
func _show_home() -> void:
	var state: Dictionary = install_state.call()
	var played := Game.worlds_left > 0 or not Profile.data.progress.is_empty()
	if not InstallOffer.card_due(PlatformRules.current(), state, played, Profile.data.settings,
			int(Time.get_unix_time_from_system()), InstallOffer.shown_this_run):
		_show_main()
		return
	InstallOffer.shown_this_run = true
	var card := InstallCard.new()
	card.guide = state.get("needs_guide", false) == true
	card.add_pressed.connect(_on_install_add)
	card.not_now_pressed.connect(_on_install_not_now)
	_show(card)


## ADD: the page's prompt right away (browsers allow it only just after a tap), then the games; Safari's guide shows
## over them.
func _on_install_add() -> void:
	request_install.call()
	InstallOffer.note_add(Profile.data.settings, int(Time.get_unix_time_from_system()))
	save_profile.call()
	_show_main()


func _on_install_not_now() -> void:
	InstallOffer.note_not_now(Profile.data.settings, int(Time.get_unix_time_from_system()))
	save_profile.call()
	_show_main()
