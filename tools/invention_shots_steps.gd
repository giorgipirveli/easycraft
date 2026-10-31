extends Node
## The steps of tools/invention_shots.gd (owner #78): each view sets the child up (a machine, the kite, the book),
## waits for the ground to stream in and a moment to settle, then saves the screen as a small JPEG.

const SEED := 12345
const SHOT_SIZE := Vector2i(640, 360)
const SETTLE := 0.8

var _out := ""
var _t := 0.0
var _wait := 0.0
var _i := 0
var _phase := 0
var _cam: Camera3D
var _views: Array[Dictionary] = []
var _home := Vector3.INF


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Game.mode = ModeRules.SANDBOX
	Game.universe = 1
	Game.start_new_world = true
	Game.new_world_seed = SEED
	_out = OS.get_environment("XDG_DATA_HOME").path_join("invention_shots")
	DirAccess.make_dir_recursive_absolute(_out)
	get_tree().change_scene_to_file(Game.SANDBOX_SCENE)
	for style: String in ["blocky", "realistic"]:
		for craft: int in [FlightCrafts.Craft.BALLOON, FlightCrafts.Craft.PLANE, FlightCrafts.Craft.JET, FlightCrafts.Craft.KITE]:
			_views.append({"name": String(FlightCrafts.invention_of(craft)), "style": style, "craft": craft})
	_views.append({"name": "book_balloon", "style": "blocky", "book": InventionLine.BALLOON})
	_views.append({"name": "book_kite", "style": "blocky", "book": InventionLine.KITE, "survivor": true})
	_views.append({"name": "book_bottle", "style": "blocky", "book": InventionLine.ROCKET, "bottle": true})
	_views.append({"name": "banner", "style": "blocky", "try": InventionLine.KITE})


func _process(delta: float) -> void:
	_t += delta
	if _t > 400.0:
		print("INVENTION_SHOT timeout")
		get_tree().quit(1)
		return
	var sandbox := get_tree().current_scene
	if sandbox == null or sandbox.get("player") == null or not (sandbox.player as Player).is_spawned():
		return
	var p: Player = sandbox.player
	var inventions: InventionsDirector = sandbox.get("inventions")
	if _cam == null:
		_cam = Camera3D.new()
		_cam.name = "ShotCamera"
		sandbox.add_child(_cam)
		_home = p.global_position + Vector3(0, 12, 0)
		_wait = 2.0
	if _wait > 0.0:
		_wait -= delta
		return
	if _i >= _views.size():
		print("INVENTION_SHOT done views=%d" % _views.size())
		get_tree().quit(0)
		return
	var v := _views[_i]
	var hud := sandbox.get("hud") as Control
	var layer := sandbox.get("_layer") as CanvasLayer
	match _phase:
		0:
			p.world.apply_style(v.style)
			(sandbox.get("sky") as SkyCycle).set_time(0.4)
			inventions.panel.close()
			inventions.stop_try()
			p.hold_kite(false)
			p.set_physics_mode(PhysicsMode.Mode.NORMAL)
			p.global_position = _home
			p.velocity = Vector3.ZERO
			p.avatar.rotation.y = 0.0
			p.photo_mode = true   # the avatar shows to the tool's camera
			var book := v.has("book")
			hud.visible = v.has("try")
			var keys := sandbox.get("keys_card") as Control
			if keys:
				keys.visible = false   # the PC's KEYS card comes at the first world: not in the pictures
			layer.visible = book or v.has("try")
			inventions.survivor = bool(v.get("survivor", false))
			if v.has("craft"):
				var craft: int = v.craft
				if craft == FlightCrafts.Craft.KITE:
					p.chosen_craft = FlightCrafts.Craft.NONE
					p.hold_kite(true)   # walking, held still in the air for the picture
				else:
					p.chosen_craft = craft
					p.set_physics_mode(PhysicsMode.Mode.FLY)
				_cam.current = true
			else:
				_cam.current = false
			if book:
				inventions.panel.open(v.book)
				if v.has("bottle"):
					inventions.panel.open_bottle()
					for k in 5:
						inventions.panel.bottle.pump()
			if v.has("try"):
				p.set_physics_mode(PhysicsMode.Mode.NORMAL)
				inventions.try_it(v.try)
			_phase = 1
			_wait = 0.5
		1:
			p.global_position = _home
			p.velocity = Vector3.ZERO
			if v.has("craft"):
				_frame(p, int(v.craft))
			if p.world.is_area_ready(_home) or _t > 300.0:
				_phase = 2
				_wait = SETTLE
		2:
			p.global_position = _home
			p.velocity = Vector3.ZERO
			if v.has("craft"):
				_frame(p, int(v.craft))
			var img := get_viewport().get_texture().get_image()
			img.resize(SHOT_SIZE.x, SHOT_SIZE.y, Image.INTERPOLATE_LANCZOS)
			var path := _out.path_join("%02d_%s_%s.jpg" % [_i, v.name, v.style])
			img.save_jpg(path, 0.85)
			print("INVENTION_SHOT %s %s %s" % [v.name, v.style, path])
			_i += 1
			_phase = 0


## The tool's camera a little way off, front-left and above, looking at the machine.
func _frame(p: Player, craft: int) -> void:
	var at := p.global_position + Vector3(0, 1.2, 0)
	var off := Vector3(-5.5, 2.5, -7.5)
	match craft:
		FlightCrafts.Craft.BALLOON:
			at = p.global_position + Vector3(0, 4.5, 0)
			off = Vector3(-9.0, 1.0, -12.0)
		FlightCrafts.Craft.PLANE:
			off = Vector3(-7.0, 3.0, -8.0)
		FlightCrafts.Craft.KITE:
			var w := Vector3(p.wind.x, 0, p.wind.z).normalized()
			at = p.global_position + w * 3.5 + Vector3(0, 4.0, 0)
			off = -w * 7.0 + w.cross(Vector3.UP) * 5.0 + Vector3(0, 1.0, 0)
	_cam.global_position = at + off
	_cam.look_at(at, Vector3.UP)
