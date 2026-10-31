class_name Scene3DView
extends Control
## The Reel Studio (owner #96, spec §5.12b): a 3D stage (StudioRules' format) in a Short: a SubViewport with a world of
## its own (the game's world is never in it), its sky (Scene3DSky), a studio's lights (a key light from the stage's Sun,
## a fill and a rim light that stay placed round the camera, no shadows), its models (Scene3DModels), its effects
## (Scene3DEffects) and its camera (StudioCamera), drawn as a picture filling this Control. show_at(t) poses everything
## at `t` (pure functions of the time: a seek shows the frame playing reaches) and asks for ONE render: a paused or hidden
## stage costs nothing. Its pixels follow its size on the screen (at most StudioRules.LIVE_MAX live; a rendered reel's
## window size for RENDER), so the picture stays sharp on a phone and cheap.
## Used whole-Short (a cinematic reel's picture: ShortPlayer's plate, its time the Short's) and inside a `scene3d` actor
## (Scene3DDrawer, its time the scene's).

var stage: Dictionary = {}
## LIVE: a phone's picture (2x antialiasing); RENDER: a rendered video's (more antialiasing, the glow of flames and suns).
var quality := StudioRules.LIVE
## The moment shown (-1 before the first).
var time := -1.0

var viewport := SubViewport.new()
var camera := Camera3D.new()
var sky := Scene3DSky.new()
var env := Environment.new()
var key := DirectionalLight3D.new()
var fill := DirectionalLight3D.new()
var rim := DirectionalLight3D.new()
var sun_light := OmniLight3D.new()
var models := {}                 # id -> Scene3DModels.Built
var effects: Array[Scene3DEffects] = []

var _world := Node3D.new()
var _sun := Vector3.UP
var _light := {}
var _sun_model: Scene3DModels.Built
var _pixels := Vector2i.ZERO


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	name = "Scene3DView"
	viewport.name = "Stage3D"
	viewport.own_world_3d = true
	viewport.transparent_bg = false
	viewport.handle_input_locally = false
	viewport.gui_disable_input = true
	viewport.audio_listener_enable_3d = false
	viewport.positional_shadow_atlas_size = 0
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	viewport.size = Vector2i(64, 64)
	add_child(viewport)
	var we := WorldEnvironment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color.BLACK
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	we.environment = env
	viewport.add_child(we)
	for l: DirectionalLight3D in [key, fill, rim]:
		l.shadow_enabled = false
		viewport.add_child(l)
	key.name = "Key"
	fill.name = "Fill"
	fill.light_specular = 0.0
	rim.name = "Rim"
	sun_light.name = "SunLight"
	sun_light.shadow_enabled = false
	sun_light.omni_range = 4000.0
	sun_light.omni_attenuation = 0.0
	sun_light.visible = false
	viewport.add_child(sun_light)
	camera.name = "Camera"
	camera.near = 0.1
	camera.far = StudioRules.FAR
	camera.current = true
	viewport.add_child(camera)
	viewport.add_child(sky)
	_world.name = "Models"
	viewport.add_child(_world)
	resized.connect(_fit_pixels)
	visibility_changed.connect(_fit_pixels)


## Builds `s` (models, effects, lights) and shows its first moment. Round 2: a live stage's blocks models are meshed on
## worker threads; they show the frame they are in (building(), finish_building()).
func build(s: Dictionary) -> void:
	_abandon()
	for c in _world.get_children():
		c.queue_free()
	for e in effects:
		e.queue_free()
	models.clear()
	effects.clear()
	stage = s
	_sun_model = null
	_set_light(StudioRules.light_at(s, 0.0))
	var first: Variant = s.get("light", "")
	if first is Array and not (first as Array).is_empty() and first[0] is Dictionary:
		first = (first[0] as Dictionary).get("light", "")
	sun_light.visible = str(first) == "orrery"
	_quality()
	for m: Variant in s.get("models", []):
		if m is Dictionary:
			var b := Scene3DModels.build(m, _world, self)
			models[str(m.id)] = b
			if str(m.get("model")) == "sun" and _sun_model == null:
				_sun_model = b
	for e: Variant in s.get("effects", []):
		if e is Dictionary:
			var fx := Scene3DEffects.new(e, _anchor_for(e))
			_world.add_child(fx)
			effects.append(fx)
	time = -1.0
	_fit_pixels()
	show_at(0.0)
	set_process(building())


## True while a blocks model is still being meshed on a worker thread.
func building() -> bool:
	for id: String in models:
		var b: Variant = models[id]
		if b is Scene3DModels.BlocksBuilt and (b as Scene3DModels.BlocksBuilt).building():
			return true
	return false


## Waits for every blocks model's mesh (the reel tools, tests) and shows the moment again.
func finish_building() -> void:
	for id: String in models:
		var b: Variant = models[id]
		if b is Scene3DModels.BlocksBuilt:
			(b as Scene3DModels.BlocksBuilt).finish()
	_repose()
	set_process(false)


## Polls the worker threads' meshes while any is out; the moment is shown again when one comes in.
func _process(_delta: float) -> void:
	var came := false
	for id: String in models:
		var b: Variant = models[id]
		if b is Scene3DModels.BlocksBuilt and (b as Scene3DModels.BlocksBuilt).poll():
			came = true
	if came:
		_repose()
	if not building():
		set_process(false)


func _repose() -> void:
	var t := time
	time = -1.0
	show_at(maxf(t, 0.0))


func _abandon() -> void:
	for id: String in models:
		var b: Variant = models[id]
		if b is Scene3DModels.BlocksBuilt:
			(b as Scene3DModels.BlocksBuilt).abandon()


## Where effect `e` comes from at a moment: its model's anchor (a rocket's engines) moved by its `at`, else its `at`.
func _anchor_for(e: Dictionary) -> Callable:
	var offset := StudioRules.vec(e.get("at")) if StudioRules.is_vec(e.get("at")) else Vector3.ZERO
	var on := str(e.get("on", ""))
	if models.has(on):
		var b: Scene3DModels.Built = models[on]
		return func(t: float) -> Transform3D: return b.anchor(t) * Transform3D(Basis.IDENTITY, offset)
	return func(_t: float) -> Transform3D: return Transform3D(Basis.IDENTITY, offset)


## Shows the moment `t`: the camera, the sky, the lights, every model and effect; one render follows.
func show_at(t: float) -> void:
	if t == time:
		return
	time = t
	var where := func(id: String, at: float) -> Vector3:   # round 2: a rider's place in the stage (on its model)
		return world_of(model_data(id), at).origin
	var cam := StudioCamera.pose(stage.get("camera", []), t, where)
	camera.transform = StudioCamera.transform(cam)
	camera.fov = float(cam.fov)
	sky.show_sky(StudioRules.sky_at(stage.get("sky", "space"), t), camera.position)
	if StudioRules.light_moves(stage):   # round 2: light and sun keys (a sunset)
		_set_light(StudioRules.light_at(stage, t))
	_place_lights()
	for id: String in models:
		(models[id] as Scene3DModels.Built).pose(t)
	for fx in effects:
		fx.pose(t)
	if _sun_model != null:
		sun_light.position = _sun_model.root.position
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	queue_redraw()


## The key, fill, rim and ambient lights from `l` (StudioRules.light_at) and the key light from its sun.
func _set_light(l: Dictionary) -> void:
	_light = l
	_sun = l.sun
	env.ambient_light_color = _light.ambient
	env.ambient_light_energy = float(_light.ambient_energy)
	key.light_color = _light.key
	key.light_energy = float(_light.key_energy)
	fill.light_color = _light.fill
	fill.light_energy = float(_light.fill_energy)
	rim.light_color = _light.rim
	rim.light_energy = float(_light.rim_energy)
	key.basis = Basis.looking_at(-_sun, Vector3.UP if absf(_sun.y) < 0.99 else Vector3.BACK)


## Round 2: the riders' frames, the models' places and whether they show at the pose's moment, worked out once a pose
## (ropes, riders and the camera ask about the same models: the lever reel's pose cost 2.6 ms here before).
var _memo := {}
var _memo_t := -INF


func frame_of(model: Dictionary, t: float) -> Transform3D:
	_memo_at(t)
	var key := "f" + str(model.get("id", ""))
	if not _memo.has(key):
		_memo[key] = StudioMotion.frame(stage, model, t)
	return _memo[key]


func world_of(model: Dictionary, t: float) -> Transform3D:
	_memo_at(t)
	var key := "w" + str(model.get("id", ""))
	if not _memo.has(key):
		_memo[key] = frame_of(model, t) * StudioMotion.transform(model, t)
	return _memo[key]


func shown_of(model: Dictionary, t: float) -> bool:
	_memo_at(t)
	var key := "s" + str(model.get("id", ""))
	if not _memo.has(key):
		_memo[key] = StudioMotion.shown(stage, model, t)
	return _memo[key]


## Model `id`'s data ({} for none).
func model_data(id: String) -> Dictionary:
	return (models[id] as Scene3DModels.Built).data if models.has(id) else StudioRules.model(stage, id)


func _memo_at(t: float) -> void:
	if t != _memo_t:
		_memo.clear()
		_memo_t = t


## Toward the light for a planet standing at `at`: the Sun model's middle when the stage has one, else the key light's.
func sun_toward(at: Vector3) -> Vector3:
	if _sun_model != null:
		var d := _sun_model.root.position - at
		return d.normalized() if d.length() > 0.001 else Vector3.UP
	return _sun


## The fill light comes from the camera's side away from the key, the rim light from behind what it looks at.
func _place_lights() -> void:
	var fwd := -camera.basis.z
	var right := camera.basis.x
	var key_side := signf(right.dot(_sun))
	var from_fill := (-right * (key_side if key_side != 0.0 else 1.0) - fwd * 0.6 + Vector3.UP * 0.35).normalized()
	fill.basis = Basis.looking_at(-from_fill, Vector3.UP)
	var from_rim := (fwd * 1.0 + Vector3.UP * 0.9).normalized()
	rim.basis = Basis.looking_at(-from_rim, Vector3.UP)


func _quality() -> void:
	var render := quality == StudioRules.RENDER
	viewport.msaa_3d = Viewport.MSAA_4X if render else Viewport.MSAA_2X
	viewport.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
	env.glow_enabled = render
	if render:
		env.glow_intensity = 0.7
		env.glow_bloom = 0.05
		env.glow_hdr_threshold = 0.9
		env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT


## The picture's pixels: its size on the screen (at most LIVE_MAX live). Inside a Short it is measured by the Short's
## stage (an actor's own pop and the push-in never shrink it to nothing).
func _fit_pixels() -> void:
	if not is_inside_tree():
		return
	var player := _player()
	var s := (player.stage.get_screen_transform().get_scale() if player != null else get_screen_transform().get_scale()) * size
	var px := Vector2i(maxi(roundi(absf(s.x)), 16), maxi(roundi(absf(s.y)), 16))
	if quality == StudioRules.LIVE:
		var k := minf(1.0, minf(float(StudioRules.LIVE_MAX.x) / px.x, float(StudioRules.LIVE_MAX.y) / px.y))
		px = Vector2i(roundi(px.x * k), roundi(px.y * k))
	if px != _pixels:
		_pixels = px
		viewport.size = px
		viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
		queue_redraw()


## The picture's pixels now (tests, the bench).
func pixels() -> Vector2i:
	return viewport.size


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		_abandon()
	if what == NOTIFICATION_ENTER_TREE:
		var player := _player()
		if player != null and not player.resized.is_connected(_fit_pixels):
			player.resized.connect(_fit_pixels)
		_fit_pixels.call_deferred()


## The Short this stage plays in (null outside one).
func _player() -> ShortPlayer:
	var n := get_parent()
	while n != null:
		if n is ShortPlayer:
			return n
		n = n.get_parent()
	return null


func _draw() -> void:
	draw_texture_rect(viewport.get_texture(), Rect2(Vector2.ZERO, size), false)
