class_name AccountsOverlay
extends CanvasLayer
## Owner #99, #104, #105 (spec §5.13 "As built"): the account buttons and the overlay AccountsFlow opens on (its own layer
## over the menu). LOG OUT in SETTINGS (beside GROWN-UPS) and the main menu's own LOG IN / LOG OUT (marked lines in
## settings_panel.gd and menu.gd), and LOG IN on the start screen (a marked line in menu.gd). LOG OUT shows only on the
## main menu (in a world its files are open) and only for a player with an online account. After a LOG OUT or a LOG IN
## the main menu opens again (to_menu).

const LAYER := 85

var flow: AccountsFlow
var panel: PanelContainer


## LOG OUT for the SETTINGS panel: hidden outside the main menu. Never a grown-up's step (the owner, 2026-10-15).
static func log_out_button(service: OnlineService = null) -> Button:
	var b := UiKit.big_button(DeviceMoveRules.LOG_OUT, Color(), Vector2(200, 84))
	b.name = "LogOut"
	b.tree_entered.connect(func() -> void: b.visible = on_main_menu(b) and _has_account(service))
	b.pressed.connect(func() -> void: open(b, service))
	return b


## The start screen's LOG IN (beside PLAY, a new player: one marked line in menu.gd): the name and the password, or a
## grown-up's key; the account's profile comes down and the main menu opens for it.
static func start_log_in_button(service: OnlineService = null) -> Button:
	var b := UiKit.big_button(DeviceMoveRules.LOG_IN, OnlineUi.PURPLE, Vector2(420, 90))
	b.name = "StartLogIn"
	b.add_theme_font_size_override("font_size", 34)
	b.pressed.connect(func() -> void: open(b, service, AccountsFlow.VIEW_LOG_IN))
	return b


## The main menu again, for whoever plays now (after a LOG OUT, a LOG IN or a DELETE).
static func to_menu() -> void:
	Game.apply_settings()
	Game.change_scene.call(Game.MENU_SCENE)


static func _has_account(service: OnlineService) -> bool:
	var s := service if service != null else Session.online_service()
	return s != null and s.prefs.account_name != ""


## SETTINGS' account buttons (one marked line in settings_panel.gd): LOG OUT and PASSWORD (owner #105: make or change
## it), on the main menu only.
static func settings_buttons(service: OnlineService = null) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.name = "AccountButtons"
	row.add_theme_constant_override("separation", 10)
	var out := log_out_button(service)
	out.custom_minimum_size.x = 170   # the settings' last row is full (1280 wide)
	row.add_child(out)
	var pw := UiKit.big_button(PasswordRules.PASSWORD, Color(), Vector2(190, 84))
	pw.name = "Password"
	pw.tree_entered.connect(func() -> void: pw.visible = on_main_menu(pw))
	pw.pressed.connect(func() -> void: open_password(pw, service))
	row.add_child(pw)
	return row


## The main menu's own LOG IN / LOG OUT, under the child's name at the top right (one marked line in menu.gd): LOG OUT
## for a player with an online name here (one tap and YES / NO: never a grown-up's step), else LOG IN (the name and the
## password: a new device, or one logged out by another device). Hidden before the first-launch screens gave a name, and
## while `follow` is hidden (the menu's logo: a panel as tall as SETTINGS takes the whole screen, and this button would
## sit on its top row and take its taps).
static func menu_button(service: OnlineService = null, follow: CanvasItem = null) -> Button:
	var b := UiKit.big_button(DeviceMoveRules.LOG_OUT, Color(0.14, 0.12, 0.3), Vector2(200, 60))
	b.name = "MenuAccount"
	b.add_theme_font_size_override("font_size", 22)
	b.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	b.offset_left = -220
	b.offset_right = -20
	b.offset_top = 58
	b.offset_bottom = 118
	var refresh := func() -> void:
		var s := service if service != null else Session.online_service()
		b.visible = Profile.data.is_onboarded() and (follow == null or follow.visible)
		b.text = DeviceMoveRules.LOG_OUT if s.prefs.account_name != "" and not s.logged_out else DeviceMoveRules.LOG_IN
	b.tree_entered.connect(func() -> void:
		refresh.call()
		var s := service if service != null else Session.online_service()
		var sigs: Array[Signal] = [Profile.saved, s.account_changed, s.logged_out_elsewhere]
		if follow != null:
			sigs.append(follow.visibility_changed)
		for sig: Signal in sigs:
			if not sig.is_connected(refresh):
				sig.connect(refresh))
	b.tree_exiting.connect(func() -> void:
		var s := service if service != null else Session.online_service()
		var sigs: Array[Signal] = [Profile.saved, s.account_changed, s.logged_out_elsewhere]
		if follow != null and is_instance_valid(follow):
			sigs.append(follow.visibility_changed)
		for sig: Signal in sigs:
			if sig.is_connected(refresh):
				sig.disconnect(refresh))
	b.pressed.connect(func() -> void:
		var log_out := b.text == DeviceMoveRules.LOG_OUT
		open(b, service, AccountsFlow.VIEW_LOG_OUT if log_out else AccountsFlow.VIEW_LOG_IN))
	return b


## SETTINGS' PASSWORD: make one (an account that has none) or change it; signed in first (the server keeps it).
static func open_password(from: Node, service: OnlineService = null) -> AccountsOverlay:
	var o := _frame(from)
	var s := service if service != null else Session.online_service()
	var waiting := OnlineUi.words(DeviceMoveRules.SWITCHING, 30)
	o.panel.add_child(waiting)
	o._password(s, waiting)
	return o


func _password(s: OnlineService, waiting: Label) -> void:
	var err: String = await s.sign_in()
	if not is_inside_tree():
		return
	if err == "" and s.has_password < 0:
		await s._pw_read_state()
	if not is_inside_tree():
		return
	panel.remove_child(waiting)
	waiting.queue_free()
	if err != "" or not s.claimed():
		var v := OnlineUi.column(18)
		v.add_child(OnlineUi.words(err if err != "" else OnlineRules.message("not_claimed"), 28, 900))
		var back := OnlineUi.button("BACK", UiKit.BLUE, Vector2(220, 84))
		back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		back.pressed.connect(queue_free)
		v.add_child(back)
		panel.add_child(v)
		return
	var pp := PasswordPage.new()
	pp.service = s
	pp.mode = PasswordPage.Mode.MAKE if s.has_password == 0 else PasswordPage.Mode.CHANGE
	pp.done.connect(queue_free)
	pp.closed.connect(queue_free)
	panel.add_child(pp)


## Whether `node` is in the main menu (no world open).
static func on_main_menu(node: Node) -> bool:
	var scene := node.get_tree().current_scene if node.is_inside_tree() else null
	return scene != null and scene.scene_file_path == Game.MENU_SCENE


static func open(from: Node, service: OnlineService = null, start_at: StringName = AccountsFlow.VIEW_LOG_OUT) -> AccountsOverlay:
	var o := _frame(from)
	o.flow = AccountsFlow.new()
	o.flow.service = service if service != null else Session.online_service()
	o.flow.start_at = start_at
	o.flow.closed.connect(o.queue_free)
	o.panel.add_child(o.flow)
	return o


static func _frame(from: Node) -> AccountsOverlay:
	var o := AccountsOverlay.new()
	o.layer = LAYER
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.72)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	o.add_child(dim)
	var centre := CenterContainer.new()
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	o.add_child(centre)
	o.panel = PanelContainer.new()
	o.panel.theme = UiKit.theme()
	o.panel.add_theme_stylebox_override("panel", UiKit.box(Color(0.12, 0.1, 0.24, 0.98), 24, 28))
	centre.add_child(o.panel)
	var host: Node = from.get_tree().current_scene if from.get_tree().current_scene != null else from.get_tree().root
	UiLayers.route(o, host)   # owner #101: in VR on the eye panel (the VR canvas)
	PadFocus.watch(o.panel)   # owner #90: a game controller reaches it too
	return o
