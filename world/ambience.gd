class_name Ambience
extends Node
## Applies AmbienceRules to the world's light and fog for the local player: caves get dark with a
## warm lantern around the player, and the view turns blue and foggy underwater. Its child AmbienceSounds
## (the audio pass) plays the place's ambience loop. The open-air look
## comes from WorldService.ambience_base (graphics settings, later the time of day).

const CEILING_SCAN := 32          # blocks above the head searched for a ceiling
const SCAN_INTERVAL := 0.2
const WATER_SPEED := 4.0          # the underwater view switches faster than the cave mood
const EPSILON := 0.001            # smaller changes of light, fog or tint are not written (yet)

var world: WorldService
var player: Player
var underground := 0.0
var underwater := 0.0
## M3 Task 2: a sandstorm's strength 0..1 (SandstormDirector): sandy fog at half the view, a sandy tint.
var storm := 0.0
## M3 Task 3: the storm is a Frostpeak snowstorm (white fog, a whiter screen).
var storm_snow := false
## M3 Task 4: the Candy Kingdom's water is chocolate: under it the view is brown (CandyRules.chocolate_mood).
var chocolate := false
## Cosmos: Titan's lakes are liquid methane: under it the view is amber (TitanRules.methane_mood).
var methane := false
var writes := 0                   # light, fog and tint values written so far (tests count them)

var _target_underground := 0.0
var _scan_t := 0.0
var _lantern := OmniLight3D.new()
var _layer := CanvasLayer.new()
var _tint := ColorRect.new()


func _ready() -> void:
	_lantern.name = "Lantern"
	_lantern.light_color = Color(1.0, 0.78, 0.5)
	_lantern.omni_range = 12.0
	_lantern.omni_attenuation = 1.2
	_lantern.shadow_enabled = false
	_lantern.visible = false
	_lantern.position = Vector3(0, CameraRig.HEAD_HEIGHT, 0)
	player.add_child(_lantern)
	_layer.layer = 0                 # above the 3D view, below the HUD (layer 1)
	add_child(_layer)
	_tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tint.visible = false
	_layer.add_child(_tint)
	_tint.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var sounds := AmbienceSounds.new()   # the audio pass: birds, crickets, drips, waves, wind
	sounds.name = "AmbienceSounds"
	add_child(sounds)


func _process(delta: float) -> void:
	if not is_instance_valid(player) or not player.is_spawned():   # a LAN host's spawner can free it
		return
	_scan_t -= delta
	if _scan_t <= 0.0:
		_scan_t = SCAN_INTERVAL
		_target_underground = _measure_underground()
	var cam := get_viewport().get_camera_3d()
	var cam_block := world.get_block(Vector3i(cam.global_position.floor())) if cam else BlockIds.AIR
	underwater = AmbienceRules.approach(underwater, AmbienceRules.underwater_target(cam_block), delta * WATER_SPEED)
	underground = AmbienceRules.approach(underground, _target_underground, delta)
	var m := AmbienceRules.mood(underground, underwater, world.ambience_base)
	if not world.cave_mood.is_empty():
		m = GlowRules.mood(m, world.ambience_base, underground, underwater, world.cave_mood)   # universe 6: the Glow Caves
	if chocolate:
		m = CandyRules.chocolate_mood(m, underwater)   # M3 Task 4
	elif methane:
		m = TitanRules.methane_mood(m, underwater)   # cosmos: Titan
	_apply(SandstormRules.mood(m, storm * (1.0 - underground), storm_snow))
	_set_muffled(AmbienceRules.muffled(underwater))


## The screen's colour tint shows (underwater blue, a sandstorm's sand); owner #101: never in a headset, where the
## root's 2D canvas is not shown and a tint on the panel would only colour the HUD (the fog and the light carry the mood).
static func shows_tint(tint: Color) -> bool:
	return tint.a > 0.001 and not Vr.active()


func _measure_underground() -> float:
	var head := player.eye_position()
	var cell := Vector3i(head.floor())
	var ceiling := false
	for dy in range(1, CEILING_SCAN + 1):
		if BlockIds.is_solid(world.get_block(cell + Vector3i(0, dy, 0))):
			ceiling = true
			break
	return AmbienceRules.underground_target(head.y, world.sky_height(cell.x, cell.z), ceiling)   # the Glow Caves: the roof


func _apply(m: Dictionary) -> void:
	var env := world.environment()
	_put(world.sun(), &"light_energy", m.sun)
	_put(env, &"ambient_light_energy", m.ambient)
	_put(env, &"fog_light_color", m.fog_color)
	_put(env, &"fog_depth_begin", m.fog_begin)
	_put(env, &"fog_depth_end", m.fog_end)
	_put(_lantern, &"light_energy", m.lantern)
	_put(_lantern, &"omni_range", 12.0 * player.size_scale())
	_lantern.visible = m.lantern > 0.01
	_put(_tint, &"color", m.tint)
	_tint.visible = shows_tint(m.tint)
	if m.has("ambient_color"):   # universe 6, the Glow Caves (GlowRules.mood): the blue-violet dark, the cool lantern
		_put(env, &"ambient_light_color", m.ambient_color)
		_put(env, &"ambient_light_sky_contribution", m.sky_share)
		_put(_lantern, &"light_color", m.lantern_color)


## Writes a light, fog or tint value only when it changed by EPSILON or more (review M8): each
## write is a call into the RenderingServer, and in the open air nothing changes between
## SkyCycle's updates. It compares with the value the object holds now, so a write from
## elsewhere (apply_graphics sets the open-air fog distances) is put right on the next frame.
func _put(target: Object, property: StringName, value: Variant) -> void:
	var now: Variant = target.get(property)
	if value is Color:
		var a: Color = now
		var b: Color = value
		if maxf(maxf(absf(a.r - b.r), absf(a.g - b.g)), maxf(absf(a.b - b.b), absf(a.a - b.a))) < EPSILON:
			return
	elif absf(float(now) - float(value)) < EPSILON:
		return
	target.set(property, value)
	writes += 1


# --- Real water (M2 Task 14) ---

var _muffled := false


## Under water every sound is muffled (Audio's low-pass), switched only on a change.
func _set_muffled(on: bool) -> void:
	if on != _muffled:
		_muffled = on
		Audio.set_muffled(on)


## Back to the menu (or a LAN client's world gone): never leave the game muffled.
func _exit_tree() -> void:
	_set_muffled(false)
