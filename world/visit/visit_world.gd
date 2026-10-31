class_name VisitWorld
extends Node3D
## A friend's showcase to walk around in (M4 Wave 3, agent I; spec §17.5, research T3), even while the
## friend is away: a small island of its own (VisitGenerator: flat grass in a calm sea, the showcase in
## the middle), the friend's name on a sign, the friend's buddy waving if one waits there, and the
## visitor's own player. Read-only by construction: the world never registers with Session (so no edit
## request of any kind reaches it) and it has no monsters, animals or saves. The visit's bar
## (VisitPanel): a sticker for the guestbook, REPORT, LEAVE.

const WORLD_SCENE := preload("res://world/world.tscn")
const PLAYER_SCENE := preload("res://entities/player/player.tscn")
## The island's terrain stops this far from the middle (a small world: little to generate).
const HALF := 96
const SIGN_OFFSET := Vector3(-3.0, 0.0, 4.0)   # from the spawn column, towards the showcase's corner

## GiftRules.showcase of the friend (Session.visit_showcase when the scene starts).
var showcase: Dictionary = {}
var service: OnlineService
var world: WorldService
var player: Player
var hud: Hud
var panel: VisitPanel
var buddy: Buddy
var sign_label: Label3D
var generator := VisitGenerator.new()

## Where LEAVE goes (default Session.leave_visit: the menu; tests give their own).
var leave_to := Callable()

var _layer := CanvasLayer.new()
var _leaving := false


func _ready() -> void:
	if showcase.is_empty():
		showcase = Session.visit_showcase
	if service == null:
		service = Session.online_service_or_null()
	Game.mode = ModeRules.SANDBOX   # a visit has no economy, hearts or monsters
	generator.setup(str(showcase.get("build", "")))
	world = WORLD_SCENE.instantiate()
	world.setup_visit(generator, VisitShape.new(), HALF)
	add_child(world)
	world.apply_graphics(Profile.data.settings)
	world.apply_style(str(Profile.data.settings.style))
	var players := Node3D.new()
	players.name = "Players"
	add_child(players)
	player = PLAYER_SCENE.instantiate()
	player.name = str(multiplayer.get_unique_id())
	player.world = world
	players.add_child(player)
	var spawn := world.spawn_column()
	player.spawn_on_surface(spawn.x, spawn.y)
	player.rig.yaw = 0.0   # looking at the showcase (-Z)
	player.set_view_distance(GraphicsPreset.view_distance(Profile.data.settings))
	_add_sign(Vector3(spawn.x, VisitGenerator.GROUND_TOP + 1, spawn.y) + SIGN_OFFSET)
	_add_buddy()
	UiLayers.route(_layer, self)   # owner #101: in VR the visit's HUD is on the panel
	_setup_hud()
	_add_races()   # M4 ghost races: the friend's courses work here, and their ghosts wait on them


## The friend's name on a wooden sign by where the visitor arrives.
func _add_sign(at: Vector3) -> void:
	var post := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.18, 1.6, 0.18)
	var wood := StandardMaterial3D.new()
	wood.albedo_color = Color("8a5a2b")
	box.material = wood
	post.mesh = box
	post.position = at + Vector3(0, 0.8, 0)
	add_child(post)
	var board := MeshInstance3D.new()
	var plank := BoxMesh.new()
	plank.size = Vector3(2.6, 0.9, 0.12)
	plank.material = wood
	board.mesh = plank
	board.position = at + Vector3(0, 1.9, 0)
	add_child(board)
	sign_label = Label3D.new()
	sign_label.name = "Sign"
	sign_label.text = tr("%s's\nshowcase") % showcase.get("owner", "")
	sign_label.font_size = 64
	sign_label.outline_size = 10
	sign_label.pixel_size = 0.008
	sign_label.position = at + Vector3(0, 1.9, 0.08)
	add_child(sign_label)


## The friend's buddy, if one waits in the showcase: it stands there and waves for visitors.
func _add_buddy() -> void:
	var b: Dictionary = showcase.get("buddy", {})
	if b.is_empty():
		return
	var blocks := BuildCodec.decode(str(b.build), BuildCodec.BUDDY)
	if blocks.is_empty():
		return
	var size := BuildCodec.size_of(str(b.build))
	var at: Vector3i = b.at
	var feet := Vector3(generator.origin + at) + Vector3(0.5, 0.0, 0.5)
	buddy = Buddy.new()
	buddy.visiting = true
	buddy.setup({"flat": Buddy.pack(blocks), "name": BuddyNames.name_for(blocks), "owner": -1,
		"pos": feet + Vector3(0, 0.05, 0), "yaw": 0.0, "id": "VisitingBuddy"})
	add_child(buddy)
	buddy.face(Vector3(0, feet.y, VisitGenerator.ISLAND))   # towards where visitors arrive
	if size.y > 0:
		buddy.wave()


func _setup_hud() -> void:
	hud = Hud.new()
	_layer.add_child(hud)
	var show_touch := PlatformRules.touch_ui(PlatformRules.current())   # M7: phones and tablets in a browser too
	var interactor: BlockInteractor = player.get_node("BlockInteractor")
	interactor.hotbar = [ItemIds.WAND] as Array[int]   # a tap only sparkles: nothing here can change
	interactor.selected_slot = 0
	hud.setup(player, Profile.data.username, show_touch, bool(Profile.data.settings.show_fps))
	for c: Control in [hud.hotbar, hud.chat, hud.book_button, hud.username_label, hud.online_dot, hud.undo_button,
			hud.mirror_button, hud.lab_button, hud.photo_button, hud.gold_counter]:
		c.visible = false
	hud.chat.process_mode = Node.PROCESS_MODE_DISABLED
	panel = VisitPanel.new()
	panel.name = "VisitPanel"
	panel.service = service
	panel.showcase = showcase
	_layer.add_child(panel)
	panel.set_toast(hud.toast)
	panel.leave_requested.connect(leave)
	hud.look_area.blockers.append_array(panel.blockers())
	hud.pause_requested.connect(leave)
	player.spawned.connect(func() -> void:
		hud.toast(tr("Welcome to %s's showcase! Look around.") % showcase.get("owner", ""), 4.0), CONNECT_ONE_SHOT)


## Back to the menu (LEAVE, PAUSE, Android Back).
func leave() -> void:
	if _leaving:
		return
	_leaving = true
	if leave_to.is_valid():
		leave_to.call()
	else:
		Session.leave_visit()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST and is_node_ready():
		if panel and panel.sheet_open():
			panel.close_sheet()
		else:
			leave()


func _unhandled_input(event: InputEvent) -> void:
	if player == null:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		player.look_delta((event as InputEventMouseMotion).relative, CameraRig.MOUSE_SENSITIVITY)
	elif event.is_action_pressed("pause"):
		leave()
	elif event.is_action_pressed("physics_mode"):
		player.cycle_physics_mode()
	elif event.is_action_pressed("camera_toggle"):
		player.toggle_camera()

# --- M4 ghost races (spec §17.5, research T2) ---
# The friend's courses in the showcase work in the visit: START, CHECKPOINT, FINISH and coins as in M3 Task 7,
# timed by this game (a visit is a world of its own: CourseDirector.setup_own_world; nothing is saved), with
# the race clock under the visit's bar. The friend's best run on each course waits on its START as a
# see-through ghost in the friend's look (GhostRaces), from the showcase's ghosts (online, or this device's
# copy offline). A finish against a ghost shows the medal against its time; the child's best is kept.

## The HUD's race clock and toasts go this far down: under the visit's bar (VisitPanel: 12 + 120 high).
const HUD_TOP_INSET := 60.0

var courses: CourseDirector
var races: GhostRaces


func _add_races() -> void:
	courses = CourseDirector.new()
	courses.name = "Courses"
	add_child(courses)
	courses.toast = func(text: String) -> void: hud.toast(text, 2.5)
	courses.setup_own_world(player, generator.block_at)
	hud.setup_races(courses)
	hud.push_top(HUD_TOP_INSET)
	races = GhostRaces.new()
	races.name = "GhostRaces"
	add_child(races)
	races.names_shown = func() -> bool: return service.ghost_names_shown() if service else GhostBook.current().names_ok
	races.result_noted = func(key: String, ms: int) -> bool:
		if service:
			return service.note_ghost_result(key, ms)
		var best := GhostBook.current().note_result(key, ms, int(Time.get_unix_time_from_system()))
		GhostBook.save_current()
		return best
	races.start_ok = func(cell: Vector3i) -> bool: return generator.block_at(cell) == BlockIds.START
	races.setup(courses, player)
	for g: Variant in showcase.get("ghosts", []):
		if g is RaceGhost:
			races.link(generator.origin + (g as RaceGhost).start, g, Vector3i.ZERO, GhostBook.showcase_key((g as RaceGhost).id))
