extends Node
## The steps of tools/launch_shots.gd: a new Sandbox world, its Launch Site stamped, a rocket on the pad, then views of
## the site and the Mission Board in both styles.

const SEED := 12345
const SETTLE := 2.0
const MAX_WAIT := 15.0
const SHOT_SIZE := Vector2i(960, 540)

var _views: Array[Dictionary] = []
var _i := 0
var _phase := 0
var _wait := 0.0
var _waited := 0.0
var _out := ""
var _t := 0.0
var _built := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	WorldSaves.delete("sandbox_1")
	Profile.data.survivor_gold = 5000
	Profile.data.settings.keys_seen = true   # owner #84: no KEYS card over the pictures
	Game.mode = ModeRules.SANDBOX
	Game.universe = 1
	Game.start_new_world = true
	Game.new_world_seed = SEED
	_out = OS.get_environment("XDG_DATA_HOME").path_join("launch_shots")
	DirAccess.make_dir_recursive_absolute(_out)
	get_tree().change_scene_to_file(Game.SANDBOX_SCENE)


func _process(delta: float) -> void:
	_t += delta
	if _t > 600.0:
		print("LAUNCH_SHOT timeout")
		get_tree().quit(1)
		return
	var sandbox := get_tree().current_scene
	if sandbox == null or sandbox.get("player") == null or not (sandbox.player as Player).is_spawned():
		return
	var p: Player = sandbox.player
	var launch: LaunchDirector = sandbox.get("launch_site")
	if launch == null or not launch.stamped:
		return
	if not _built:
		_built = true
		var corner := LaunchSite.corner(launch.site)
		var rocket: Dictionary = load("res://tools/mission_smoke_steps.gd").moon_rocket()
		var changes: Array = []
		for c: Vector3i in rocket:
			changes.append([corner + c, rocket[c]])
		p.world.set_blocks(changes)
		Profile.data.missions.parts = RocketParts.count(rocket)   # the parts bought: every line green
		_plan(launch)
		if not p.rig.first_person:
			p.toggle_camera()
		p.set_physics_mode(PhysicsMode.Mode.FLY)
	if _wait > 0.0:
		_wait -= delta
		return
	if _i >= _views.size():
		print("LAUNCH_SHOT done views=%d" % _views.size())
		get_tree().quit(0)
		return
	var v := _views[_i]
	var hud := sandbox.get("hud") as Control
	match _phase:
		0:
			p.world.apply_style(v.style)
			(sandbox.get("sky") as SkyCycle).set_time(0.4)
			launch.board.close()
			hud.visible = v.has("page")
			p.spawn_at(v.stand)
			p.velocity = Vector3.ZERO
			_waited = 0.0
			_phase = 1
			_wait = 0.3
		1:
			p.global_position = v.stand
			p.velocity = Vector3.ZERO
			_aim(p, v.look)
			_waited += delta
			if p.world.is_area_ready(v.look) or _waited > MAX_WAIT:
				if v.has("page"):
					launch.board.open()
					if int(v.page) == MissionBoard.ROCKET_PAGE:
						launch.board.choose(SpaceRules.MOON)
					else:
						launch.board.show_page(int(v.page))
				_phase = 2
				_wait = SETTLE
		2:
			p.global_position = v.stand
			_aim(p, v.look)
			var img := get_viewport().get_texture().get_image()
			img.resize(SHOT_SIZE.x, SHOT_SIZE.y, Image.INTERPOLATE_LANCZOS)
			var path := _out.path_join("%02d_%s_%s.jpg" % [_i, v.name, v.style])
			img.save_jpg(path, 0.85)
			print("LAUNCH_SHOT %s %s %s" % [v.name, v.style, path])
			_i += 1
			_phase = 0


func _plan(launch: LaunchDirector) -> void:
	var site := launch.site
	var y := float((site.pos as Vector3i).y)
	var pad := LaunchSite.to_world_point(site, Vector2.ZERO, y + 6.0)
	for style: StringName in [&"blocky", &"realistic"]:
		_views.append({"name": "site", "style": style, "stand": LaunchSite.to_world_point(site, Vector2(-4, 30), y + 12.0),
			"look": pad})
		_views.append({"name": "rocket", "style": style, "stand": LaunchSite.to_world_point(site, Vector2(7, 12), y + 5.0),
			"look": pad + Vector3(0, 1, 0)})
		_views.append({"name": "tower", "style": style, "stand": LaunchSite.to_world_point(site, Vector2(14, 8), y + 14.0),
			"look": LaunchSite.to_world_point(site, Vector2(4, -4), y + 10.0)})
		for page in [MissionBoard.MISSIONS_PAGE, MissionBoard.ROCKET_PAGE, MissionBoard.PARTS_PAGE]:
			_views.append({"name": "board_%d" % page, "style": style, "page": page,
				"stand": LaunchSite.to_world_point(site, LaunchSite.BOARD_AT + Vector2(0, 1.6), y + 1.05),
				"look": LaunchSite.board_position(site) + Vector3(0, 1.2, 0)})


func _aim(p: Player, target: Vector3) -> void:
	var eye := p.eye_position()
	var d := target - eye
	p.rig.yaw = atan2(-d.x, -d.z)
	p.rig.pitch = clampf(atan2(d.y, Vector2(d.x, d.z).length()), CameraRig.PITCH_MIN, CameraRig.PITCH_MAX)
