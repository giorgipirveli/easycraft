extends Node
## Vr (autoload; owner #101, docs/superpowers/plans/2026-10-15-vr-quest.md): the one door to VR. **This is the lead's frozen
## contract**: both VR agents build against these names; the VR-RIG agent writes the body (the XR rig, the interfaces, the
## anchors and fades), the VR-UI agent the canvas (ui_viewport, ui_wants_pointer). Off VR every call is a cheap no-op and
## nothing here makes a node, so phones, the web and the desktop suite behave exactly as before.
##
## - active(): a headset session is running (or simulated by a test).
## - camera: the XRCamera3D while active, else null.
## - hand_ray(side): [origin, direction] of that controller's aim in world space (the right hand by default; the
##   left-handed setting swaps: VrRules.pointing_hand); [] when not active.
## - anchor(node, kind): the XR origin follows `node` (kind &"feet": the player's feet; &"seat": a seat, the rocket's
##   capsule; &"menu": a fixed menu spot); null lets it stay where it is.
## - fade_out(seconds) / fade_in(seconds): a black fade (awaitable); instant off VR.
## - ui_viewport(): the SubViewport the 2D UI is drawn into in VR (UiLayers.route puts the CanvasLayers there); null off VR.
## - ui_wants_pointer(): the laser is over a panel (a world action waits).
## - start(kind): starts VrRules.OPENXR or VrRules.WEBXR; "" or plain words why not.
## - simulate(on): tests fake a session (a head and two hands) without an XR server.
##
## The VR-RIG body (docs/devlog/parts/vr-rig.md; added names, noted for the lead): `rig` (the VrRig: origin, head, hands,
## comfort sphere; made at the start, freed at the end, kept across scene changes), pointing_hand() / pointer_ray() (the
## hand that points and acts), head_transform(), turn(radians) / face(yaw) (round the head), recenter(), blink() (black at
## once, then the fade in: a jump that already happened), fade_amount(), tint(color) (Feel's flash), vignette(amount),
## haptic(side, amplitude, seconds, frequency := 0.0), setting(key) (the VR COMFORT values), local_player(), preview(on) (the desktop's
## flat look through the fake head: the --vr-preview argument), sim_head / sim_hand / sim_input (tests drive the fakes).
## A real session (OpenXR in the Quest APK, WebXR in the Quest's browser) sets GraphicsPreset.vr_session (the `vr`
## preset), turns V-Sync off, asks for 72 Hz, sustained-high CPU and GPU levels and foveation; losing the focus (the
## Quest's menu, the headset taken off) says focus_changed(false).

signal started
signal ended
signal recentered
signal focus_changed(focused: bool)

var camera: XRCamera3D = null

var _active := false
var _simulated := false
var _anchor: Node3D = null
var _anchor_kind := &""

## What runs the session: VrRules.OPENXR / VrRules.WEBXR, SIM (a test), PREVIEW (the desktop's flat look).
const SIM := &"sim"
const PREVIEW := &"preview"
## The argument that starts the desktop preview (`godot --path . -- --vr-preview`).
const PREVIEW_ARG := "--vr-preview"
## The refresh rate asked for (the plan's ruling 2: Quest 2 is the floor; 90 on a Quest 3 only after measuring).
## P5: the VR preset's own (GraphicsPreset.refresh_rate: vr 72, vr_plus 90); this stays the floor's.
const REFRESH_RATE := 72.0
## OpenXRInterface.PERF_SETTINGS_LEVEL_SUSTAINED_HIGH (by number: the web build has no OpenXR classes).
const PERF_SUSTAINED_HIGH := 2
## The fake head's standing height in the preview (m), and how far the mouse turns it.
const PREVIEW_EYE := 1.6
const PREVIEW_MOUSE := 0.003

## The rig while a session runs, else null.
var rig: VrRig = null
## The controllers as a pad, and the laser.
var input: VrInput = null
var hand: VrHand = null
## A real session's (and the preview's) VR_BENCH lines.
var bench: VrBench = null
## P3: the teleport's arc and its jump.
var teleport: VrTeleport = null
## Owner #110 (round 4, VR-HANDS): both hands take things (VrGrabber); owner #116: bricks laid by hand (VrBricks).
var grabber: VrGrabber = null
var bricks: VrBricks = null
## Owner #110 idea 3: waves, high-fives, the buddies' eyes (VrGestures).
var gestures: VrGestures = null
## Owner #110 idea 5: the Build Table while it is open (MORE → BUILD TABLE, or a School board), else null.
var build_table: VrBuildTable = null
## Owner #110 idea 6: MODEL VIEW while it is open (MORE → MODEL VIEW, the Sandbox only), else null.
var model_view: VrModelView = null
var _frozen := false
## P4: the child's own hands (VrRules.LEFT / RIGHT -> VrHandModel), the mirror (null while closed), who shows the
## child's own avatar (the photo's selfie, the mirror) and the avatar's layers meanwhile.
var hand_models := {}
var mirror: VrMirror = null
var _self_seen := {}
var _self_layers := {}
var _hands_look := ""
## P5 (VR performance, docs/devlog/parts/vr-perf.md): the refresh rate asked for (0 off a real session), the rates the
## headset offers, the interface asked, the VR preset the rate came from and the step-down's state
## (GraphicsPreset.watch_refresh: 90 Hz only while there is headroom).
var refresh_rate := 0.0
var _rates: Array = []
var _refresh_xr: XRInterface = null
var _refresh_preset := ""
var _refresh_watch := {}

var _kind := &""
## The anchors before this one ([WeakRef, kind]), newest last.
var _before: Array = []
var _interface: XRInterface = null
var _was_camera: Camera3D = null
var _fakes: Array[XRPositionalTracker] = []
var _fade := 0.0
var _fade_target := 0.0
var _fade_seconds := 0.0
var _tint := Color(1.0, 0.16, 0.1, 0.0)
var _vignette := 0.0
var _focused := true
var _preview_yaw := 0.0
var _preview_pitch := 0.0
## Haptic pulses asked for (tests: a simulated session has no controllers to buzz).
var haptics := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS   # a paused tree must never freeze the head
	process_physics_priority = 100   # after the player's tick: the origin follows where the body went this tick
	if OS.get_cmdline_user_args().has(PREVIEW_ARG):
		preview.call_deferred(true)
	elif PlatformRules.starts_vr(PlatformRules.current()):
		_start_at_launch.call_deferred()


func active() -> bool:
	return _active


## True while a test simulates a session (no XR server, no headset).
func simulated() -> bool:
	return _simulated


func hand_ray(_side: StringName = VrRules.RIGHT) -> Array:
	if not _active or rig == null:
		return []
	var t := _hand_transform(_side)
	return [t.origin, -t.basis.z.normalized()]


func anchor(node: Node3D, kind: StringName = &"feet") -> void:
	if node == null:
		_before.clear()
	elif is_instance_valid(_anchor) and _anchor != node:
		_before.append([weakref(_anchor), _anchor_kind])   # a visit's player: back to this one when it goes
	_anchor = node
	_anchor_kind = kind
	if _active and rig != null and is_instance_valid(node):
		_recenter_on_anchor()


## The anchor is there to follow (freed or out of the tree: a scene change's frame, its transform unreadable).
func _anchor_ok() -> bool:
	return is_instance_valid(_anchor) and _anchor.is_inside_tree()


## The node the origin follows and how (&"" when none).
func anchor_kind() -> StringName:
	return _anchor_kind if is_instance_valid(_anchor) else &""


func fade_out(_seconds: float = VrRules.FADE_OUT) -> void:
	if not _active:
		return
	_fade_to(1.0, _seconds)
	while _active and _fade_target == 1.0 and _fade < 1.0:
		await get_tree().process_frame


func fade_in(_seconds: float = VrRules.FADE_IN) -> void:
	if not _active:
		return
	_fade_to(0.0, _seconds)
	while _active and _fade_target == 0.0 and _fade > 0.0:
		await get_tree().process_frame


func ui_viewport() -> SubViewport:
	return VrUi.ensure(self).viewport if _active else null   # VR-UI: the canvas, made at the session's first ask


func ui_wants_pointer() -> bool:
	return _active and VrUi.wants_pointer()   # VR-UI: the laser over the panel (VrPointer)


func start(kind: StringName) -> String:
	if kind != VrRules.OPENXR and kind != VrRules.WEBXR:
		return "That is not a VR kind."
	if _active:
		return "" if kind == _kind else "VR is already on."
	var xr := XRServer.find_interface("OpenXR" if kind == VrRules.OPENXR else "WebXR")
	if xr == null:
		return "This device can't show VR." if kind == VrRules.OPENXR else "This browser can't show VR."
	_interface = xr
	return _start_openxr(xr) if kind == VrRules.OPENXR else _start_webxr(xr)


func simulate(on: bool) -> void:
	if on == _active and on == _simulated:
		return
	if on:
		_end()
		_simulated = true
		_kind = SIM
		_add_fakes()
		_begin()
	else:
		_end()

# --- The VR-RIG body: the session ---

func _start_at_launch() -> void:
	var why := start(VrRules.OPENXR)
	if why != "":
		push_warning("VR did not start: %s" % why)


func _start_openxr(xr: XRInterface) -> String:
	if not xr.is_initialized() and not xr.initialize():
		_interface = null
		return "VR could not start (no headset runtime)."
	for s: Array in [["session_visible", _on_focus_lost], ["session_focussed", _on_focus_back],
			["session_stopping", _on_focus_lost], ["pose_recentered", _on_pose_recentered],
			["user_presence_changed", _on_presence]]:
		if xr.has_signal(s[0]) and not xr.is_connected(s[0], s[1]):
			xr.connect(s[0], s[1])
	_kind = VrRules.OPENXR
	get_viewport().use_xr = true
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)   # the headset paces the frames
	_tune(xr)
	_begin()
	return ""


## The Quest's browser: the session starts a moment after initialize() (session_started), which a tap must call
## (VR-UI's ENTER VR button: a browser starts immersive VR only from a tap).
func _start_webxr(xr: XRInterface) -> String:
	xr.set("session_mode", "immersive-vr")
	xr.set("requested_reference_space_types", "local-floor, local")
	xr.set("required_features", "local-floor")
	xr.set("optional_features", "bounded-floor, high-fixed-foveation-level")
	for s: Array in [["session_started", _on_webxr_started], ["session_ended", _on_webxr_ended],
			["session_failed", _on_webxr_failed], ["visibility_state_changed", _on_webxr_visibility],
			["reference_space_reset", _on_pose_recentered]]:
		if xr.has_signal(s[0]) and not xr.is_connected(s[0], s[1]):
			xr.connect(s[0], s[1])
	if not xr.initialize():
		_interface = null
		return "This browser can't show VR."
	return ""


func _on_webxr_started() -> void:
	_kind = VrRules.WEBXR
	get_viewport().use_xr = true
	_tune(_interface)
	_begin()


func _on_webxr_ended() -> void:
	get_viewport().use_xr = false
	_end()


func _on_webxr_failed(message: String) -> void:
	push_warning("VR did not start in this browser: %s" % message)
	_interface = null


func _on_webxr_visibility() -> void:
	_set_focus(str(_interface.get("visibility_state")) == "visible" if _interface else true)


## 72 Hz (the nearest the headset offers), sustained-high CPU and GPU (OpenXR), and foveation: VRS_XR on the Mobile
## renderer, OpenXR's own level on Compatibility (the "Quest GL" build; the project settings ask for it too).
func _tune(xr: XRInterface) -> void:
	if xr == null:
		return
	# P5: the VR preset's rate, the nearest the headset offers; again when the child picks the other VR preset
	_rates = xr.call("get_available_display_refresh_rates") \
		if xr.has_method("get_available_display_refresh_rates") else []
	_refresh_xr = xr
	_refresh_preset = ""
	_on_settings_refresh(Profile.data.settings)
	if not Game.settings_applied.is_connected(_on_settings_refresh):
		Game.settings_applied.connect(_on_settings_refresh)
	if xr.has_method("set_cpu_level"):
		xr.call("set_cpu_level", PERF_SUSTAINED_HIGH)
		xr.call("set_gpu_level", PERF_SUSTAINED_HIGH)
	if RenderingServer.get_current_rendering_method() == "gl_compatibility":
		if "foveation_level" in xr:
			xr.set("foveation_level", 3)
			xr.set("foveation_dynamic", true)
	else:
		get_viewport().vrs_mode = Viewport.VRS_XR


## P5: the child's VR preset changed (or the session starts): ask for its rate and watch for headroom anew.
func _on_settings_refresh(settings: Dictionary) -> void:
	var preset := GraphicsPreset.vr_preset(str(settings.get("graphics", "")))
	if _refresh_xr == null or preset == _refresh_preset:
		return
	_refresh_preset = preset
	_refresh_watch = {}
	_ask_refresh(GraphicsPreset.nearest_rate(GraphicsPreset.refresh_rate(preset), _rates))


func _ask_refresh(rate: float) -> void:
	refresh_rate = rate
	if _refresh_xr.has_method("set_display_refresh_rate"):
		_refresh_xr.call("set_display_refresh_rate", rate)   # WebXR ("not supported on all browsers")
	elif "display_refresh_rate" in _refresh_xr:
		_refresh_xr.set("display_refresh_rate", rate)
	# the lead reads which headset, preset and rate from logcat (adb logcat -s godot:V | grep VR_BENCH)
	print(GraphicsPreset.device_line(GraphicsPreset.model(), _refresh_preset, rate, _rates,
		RenderingServer.get_current_rendering_method()))


## P5: every drawn frame of a real session: a step down once the frames keep missing the rate.
func _watch_refresh(delta: float) -> void:
	if _refresh_xr == null or refresh_rate <= 0.0:
		return
	if not _focused:
		_refresh_watch.hitch = true   # the Quest's menu, the headset off: frames the child never saw count neither way
	var r := GraphicsPreset.watch_refresh(_refresh_watch, delta, refresh_rate, _rates)
	if r != refresh_rate:
		_ask_refresh(r)


func _end_refresh() -> void:
	refresh_rate = 0.0
	_rates = []
	_refresh_xr = null
	_refresh_preset = ""
	_refresh_watch = {}
	if Game.settings_applied.is_connected(_on_settings_refresh):
		Game.settings_applied.disconnect(_on_settings_refresh)


func _on_focus_lost() -> void:
	_set_focus(false)


func _on_focus_back() -> void:
	_set_focus(true)


func _on_presence(present: bool) -> void:
	_set_focus(present)


func _set_focus(focused: bool) -> void:
	if focused == _focused:
		return
	_focused = focused
	focus_changed.emit(focused)


func _on_pose_recentered() -> void:
	recenter()


## Makes the rig, its hands and the laser; the head is the view from now on.
func _begin() -> void:
	_active = true
	_focused = true
	_was_camera = get_viewport().get_camera_3d()
	rig = VrRig.new()
	rig.real_height = str(setting(VrRules.HEIGHT)) == "real"
	add_child(rig)
	camera = rig.head
	camera.make_current()
	rig.current = true
	input = VrInput.new()
	add_child(input)
	hand = VrHand.new()
	add_child(hand)
	teleport = VrTeleport.new()
	add_child(teleport)
	grabber = VrGrabber.new()   # owner #110
	add_child(grabber)
	bricks = VrBricks.new()   # owner #116: its grips after the grabbables'
	add_child(bricks)
	grabber.claimers.append(bricks)
	gestures = VrGestures.new()   # owner #110 idea 3
	add_child(gestures)
	if not get_tree().node_added.is_connected(_on_node_added):
		get_tree().node_added.connect(_on_node_added)   # owner #110 idea 5: a School board opens the table
	_frozen = false
	_fade = 0.0
	_fade_target = 0.0
	if _anchor_ok():
		_recenter_on_anchor()
	if _kind != SIM:
		GraphicsPreset.vr_session = true   # the `vr` preset: re-applied everywhere (Game.settings_applied)
		Game.apply_settings()
		bench = VrBench.new()   # a VR_BENCH line every 10 s (logcat on the Quest)
		bench.name = "VrBench"
		add_child(bench)
	started.emit()


func _end() -> void:
	_end_refresh()   # P5
	if not _active:
		_simulated = false
		_remove_fakes()
		return
	if input:
		input.release_all()
	if grabber:
		grabber.drop_all()   # owner #110: nothing stays in a hand
	close_build_table()
	if is_instance_valid(model_view):
		model_view.close()
	model_view = null
	_remove_more_buttons()
	if get_tree().node_added.is_connected(_on_node_added):
		get_tree().node_added.disconnect(_on_node_added)
	set_mirror(false)
	for who: StringName in _self_seen.keys():
		show_self(false, who)
	for n: Node in [input, hand, rig, bench, teleport, grabber, bricks, gestures] + hand_models.values():
		if is_instance_valid(n):
			remove_child(n)
			n.queue_free()
	hand_models.clear()
	_hands_look = ""
	input = null
	hand = null
	bench = null
	teleport = null
	grabber = null
	bricks = null
	gestures = null
	_frozen = false
	XRServer.world_scale = 1.0   # Size Magic's scale goes with the rig
	rig = null
	camera = null
	_active = false
	_simulated = false
	_remove_fakes()
	var real := _kind != SIM
	_kind = &""
	_fade = 0.0
	_fade_target = 0.0
	if is_instance_valid(_was_camera) and _was_camera.is_inside_tree():
		_was_camera.make_current()
	elif local_player() != null:
		local_player().camera().make_current()
	_was_camera = null
	if real and GraphicsPreset.vr_session:
		GraphicsPreset.vr_session = false
		Game.apply_settings()
	ended.emit()


## The headset's session ends (the browser's EXIT VR; tests; the preview off).
func stop() -> void:
	if _interface != null and _interface.is_initialized() and _kind == VrRules.WEBXR:
		_interface.uninitialize()   # session_ended follows
		return
	_end()

# --- Every frame ---

func _physics_process(_delta: float) -> void:
	step_physics()


## One physics tick: the origin's place after where the anchor went this tick; a jump further than a child moves is
## the safety net's blink (a teleport nobody faded for).
func step_physics() -> void:
	if not _active or rig == null:
		return
	if not _anchor_ok() and not _back_to_before():
		return
	if _anchor_kind == VrRig.SEAT or _frozen:
		return   # a seat is followed every frame (follow_now); a frozen origin waits behind its fade (sleep)
	var player := local_player()
	rig.predict = player != null and player.is_riding() and not player.multiplayer.is_server()   # a guest's own mount
	var dt := 1.0 / maxf(float(Engine.physics_ticks_per_second), 1.0)
	if rig.record(rig.target(_anchor, _anchor_kind), dt):
		blink()


func _process(delta: float) -> void:
	step(delta)
	_watch_refresh(delta)   # P5


## One drawn frame: the rig between the ticks, the fade, the comfort sphere, the controllers, the laser.
func step(delta: float) -> void:
	if not _active or rig == null:
		return
	if camera != null and get_viewport().get_camera_3d() != camera:
		camera.make_current()   # a menu's, a photo's or a rocket's camera: the head is always the view in VR
	if _kind == PREVIEW:
		_preview_step()
	if _anchor_ok():
		if _anchor_kind == VrRig.SEAT:
			rig.place_seat(_anchor.global_transform)
		elif not _frozen:
			rig.follow(Engine.get_physics_interpolation_fraction(), delta)
	_fade = VrRules.fade_step(_fade, _fade_target, _fade_seconds, delta)
	var player := local_player()
	input.step(delta, player)
	grabber.step(delta)   # owner #110: after the grips' presses, before the hands' pictures
	_step_hands(player)
	bricks.step(delta)   # owner #116: after the hands (the fingertip on the wrist)
	gestures.step(delta)   # owner #110 idea 3
	if is_instance_valid(build_table):
		build_table.step(delta)   # owner #110 idea 5
	if is_instance_valid(model_view):
		model_view.step(delta)   # owner #110 idea 6
	_step_more_buttons(delta)
	hand.step(player)
	if mirror:
		mirror.reflect(head_transform().origin)
	teleport.step(player, input.teleport_y if not seated() else 0.0)
	var passive := false
	var moving := Vector3.ZERO
	if player != null and _anchor_kind != VrRig.SEAT:
		rig.ease_steps = player.physics_mode == PhysicsMode.Mode.NORMAL
		passive = player.vr_passive_motion()
		moving = rig.velocity if player.is_spawned() else Vector3.ZERO
	if moving == Vector3.ZERO and _anchor_kind == &"life" and _anchor_ok():
		moving = rig.velocity   # a place moves the child's stand (a voyage's swim), with or without a world behind it
	var smooth := input.turned != 0.0 and VrRules.snap_degrees(str(setting(VrRules.TURN))) <= 0.0
	var want := VrRules.vignette_motion(str(setting(VrRules.VIGNETTE)), moving, rig.accel if passive else 0.0, passive,
		smooth)
	_vignette = VrRules.ease_vignette(_vignette, want, delta)
	_apply_comfort()


func _apply_comfort() -> void:
	if rig == null:
		return
	rig.comfort.fade = _fade
	rig.comfort.vignette = _vignette
	rig.comfort.tint = _tint
	rig.comfort.apply()

# --- Fades and the comfort sphere ---

func _fade_to(target: float, seconds: float) -> void:
	_fade_target = target
	_fade_seconds = maxf(seconds, 0.0)
	if seconds <= 0.0:
		_fade = target
	_apply_comfort()


## A jump that already happened (a spawn, a portal, the safety net): black at once, then the fade in; the rig never
## glides across it.
func blink() -> void:
	if not _active or rig == null:
		return
	_fade = 1.0
	_fade_to(0.0, VrRules.FADE_IN)
	if _anchor_ok() and _anchor_kind == VrRig.SEAT:
		rig.place_seat(_anchor.global_transform)
	elif _anchor_ok():
		rig.reset_history(rig.target(_anchor, _anchor_kind))
	_apply_comfort()


## How black the view is (0..1: a fade or the head in a wall).
func fade_amount() -> float:
	return rig.comfort.black() if rig != null else 0.0


## Feel's red tint over the view (its alpha capped at VrRules.TINT_MAX).
func tint(color: Color) -> void:
	_tint = Color(color, minf(color.a, VrRules.TINT_MAX))
	_apply_comfort()


func vignette_amount() -> float:
	return _vignette


## The head in a wall (Player._vr_room_scale: VrRules.head_fade).
func set_head_blocked(amount: float) -> void:
	if rig != null:
		rig.comfort.head_block = amount
		_apply_comfort()

# --- P3 (owner #101): seats, the sleep's fade, the knock-out's dim, Size Magic, the trigger ---

## A knock-out's dim over the view (0 clear; VrRules.KNOCKOUT_DIM).
func set_dim(amount: float) -> void:
	if rig != null:
		rig.comfort.dim = clampf(amount, 0.0, 1.0)
		_apply_comfort()


## The origin stays where it is (a sleep fading out while the body goes onto the bed); unfrozen, it starts again at
## the anchor at once (behind the black).
func freeze(on: bool) -> void:
	if on == _frozen:
		return
	_frozen = on
	if not on and rig != null and _anchor_ok() and _anchor_kind != VrRig.SEAT:
		rig.reset_history(rig.target(_anchor, _anchor_kind))


func frozen() -> bool:
	return _frozen


## The origin at the anchor now, no glide and no fade of its own (a wake behind the sleep's black).
func snap_origin() -> void:
	if rig != null and _anchor_ok():
		if _anchor_kind == VrRig.SEAT:
			rig.place_seat(_anchor.global_transform)
		else:
			rig.reset_history(rig.target(_anchor, _anchor_kind))


## The child sits in `seat` (the rocket's capsule: VrRig.place_seat every frame), behind a blink; the anchor before it
## comes back with release().
func sit(seat: Node3D) -> void:
	anchor(seat, VrRig.SEAT)
	blink()
	if camera != null:
		camera.make_current()   # the flight made its own camera current: the head is the view at once


## The black held at `amount` (0..1) with no fade of its own (the flight's last step darkens as its screen did).
func hold_fade(amount: float) -> void:
	if _active:
		_fade_to(clampf(amount, 0.0, 1.0), 0.0)


## Seated (the rocket): the pointing trigger is the throttle then, the turning stick no teleport.
func seated() -> bool:
	return _active and is_instance_valid(_anchor) and _anchor_kind == VrRig.SEAT


## `node` is no anchor any more (a flight ended): the one before it again, behind a blink.
func release(node: Node3D) -> void:
	if node == null or _anchor != node:
		return
	_anchor = null
	_anchor_kind = &""
	if _active and rig != null:
		_back_to_before()


## A seat moved this frame after Vr's own frame (RocketFlight ticks later): the origin follows it now.
func follow_now() -> void:
	if _active and rig != null and _anchor_ok() and _anchor_kind == VrRig.SEAT:
		rig.place_seat(_anchor.global_transform)


## Size Magic in VR (owner #101, the research's P3): the play space's scale is the child's size (a giant's head moves 3
## m for a real one and its eyes are 3× apart: the world looks small), behind a blink; the head back over the anchor.
func set_world_scale(s: float) -> void:
	if rig == null or is_equal_approx(rig.world_scale, s):
		return
	rig.world_scale = s
	XRServer.world_scale = s
	_refresh_fakes()   # a headset sends new poses every frame; the fakes say theirs again with the new scale
	if _anchor_ok():
		rig.recenter(_anchor, _anchor_kind, VrRules.yaw_of(head_transform().basis) if _anchor_kind != VrRig.SEAT else NAN)
	blink()


func world_scale() -> float:
	return rig.world_scale if rig != null else 1.0


## A hand's trigger, 0..1 (VR-UI's pointer, the photo's shutter).
func trigger(side: StringName) -> float:
	var v: Variant = VrInput.read(side, "trigger")
	if v is bool:
		return 1.0 if v else 0.0
	return float(v) if v is float else 0.0


# --- P4 (owner #101): the hands, the pose for the others, the mirror, the child's own avatar seen ---

## The child's own hands: on the controllers' grips, in the avatar's colours and style, posed by grip and trigger.
func _step_hands(player: Player) -> void:
	var style := VrHandModel.REALISTIC if player != null and player.avatar is RealisticAvatar else VrHandModel.BLOCKY
	var look := "%s:%s" % [style, player.look_code if player != null else ""]
	if look != _hands_look or hand_models.size() != 2:
		_hands_look = look
		for h: Node in hand_models.values():
			h.queue_free()
		hand_models.clear()
		for side: StringName in [VrRules.LEFT, VrRules.RIGHT]:
			var h := VrHandModel.new(side, style)
			add_child(h)
			hand_models[side] = h
			if player != null:
				h.set_look(player.avatar.look().resolve())
	# owner #110 (R2): the pictures stop at a block's face (the world's voxels, never a physics query)
	var w: WorldService = player.world if player != null else null
	var solid := Callable() if w == null else func(c: Vector3i) -> bool: return BlockIds.is_solid(w.get_block(c))
	for side: StringName in [VrRules.LEFT, VrRules.RIGHT]:
		var h := hand_models[side] as VrHandModel
		h.follow(hand_grip(side), solid, world_scale(), head_transform().origin)
		h.set_pose(_value(side, "grip"), trigger(side))
		h.item_anchor().visible = not hand_busy(side)   # owner #110: a held thing (a brick) takes the item's place
		h.item_anchor().basis = aim_in_grip(side)   # owner #124: the held item points where the laser points


## Owner #110: the hand holds, pulls or locks something, its grip builds (VrGrabber), or it builds at the Build Table:
## its laser is off then (no panel, no world; the table or the held thing has its trigger).
func hand_busy(side: StringName) -> bool:
	if not _active:
		return false
	if grabber != null and grabber.busy(side):
		return true
	return side == pointing_hand() and is_instance_valid(build_table) and build_table.wants_trigger(side)

# --- Owner #110 idea 5: the Build Table, and the MORE menu's VR entries ---

## MORE → BUILD TABLE: the table in front of the child (open already: it comes in front again); `board`: a School round's.
func open_build_table(board: BuildBoard = null) -> void:
	if not _active or rig == null:
		return
	close_build_table()
	build_table = VrBuildTable.new()
	add_child(build_table)
	build_table.open_before(head_transform(), world_scale(), board)
	build_table.closed.connect(_on_table_closed.bind(build_table))
	grabber.claimers.insert(0, build_table)   # its rim before a brick's grip


func close_build_table() -> void:
	if is_instance_valid(build_table):
		build_table.close()
	build_table = null


func _on_table_closed(table: VrBuildTable) -> void:
	if grabber != null:
		grabber.claimers.erase(table)
	if build_table == table:
		build_table = null


## A School "build the answer" board came into the VR canvas: the table becomes it (once it shows).
func _on_node_added(n: Node) -> void:
	if n is BuildBoard and _active:
		_board_shown.call_deferred(weakref(n))


func _board_shown(w: WeakRef) -> void:
	var b := w.get_ref() as BuildBoard
	if b != null and is_instance_valid(b) and b.is_inside_tree() and _active:
		open_build_table(b)


const MORE_TABLE := &"VrBuildTable"
const MORE_MODEL := &"VrModelView"
var _more_t := 0.0
var _more_hud: WeakRef = null
var _more_buttons: Array[TouchButton] = []


## In a headset, the HUD's MORE panel gets BUILD TABLE and MODEL VIEW (the Sandbox's only; owner #110); off VR never.
func _step_more_buttons(delta: float) -> void:
	_more_t -= delta
	if _more_t > 0.0:
		return
	_more_t = 0.5
	var hud := get_tree().get_first_node_in_group(Hud.GROUP) as Hud
	if hud == null or (_more_hud != null and _more_hud.get_ref() == hud):
		if hud != null:
			for b: TouchButton in _more_buttons:
				if is_instance_valid(b) and b.name == MORE_MODEL:
					b.visible = Game.mode == ModeRules.SANDBOX
		return
	_remove_more_buttons()
	_more_hud = weakref(hud)
	for spec: Array in [[MORE_TABLE, "BUILD TABLE", &"table"], [MORE_MODEL, "MODEL VIEW", &"model"]]:
		var b := TouchButton.new()
		b.name = spec[0]
		b.text = spec[1]
		b.symbol = spec[2]
		hud.more.add(b, true)
		b.pressed.connect(_on_more_button.bind(spec[0]))
		b.visible = spec[0] != MORE_MODEL or Game.mode == ModeRules.SANDBOX
		_more_buttons.append(b)


func _on_more_button(which: StringName) -> void:
	if which == MORE_TABLE:
		open_build_table()
	else:
		toggle_model_view()


func _remove_more_buttons() -> void:
	for b: TouchButton in _more_buttons:
		if is_instance_valid(b):
			b.queue_free()
	_more_buttons.clear()
	_more_hud = null


## The MORE panel's VR buttons now (tests).
func more_buttons() -> Array[TouchButton]:
	return _more_buttons


## MORE → MODEL VIEW: the child a giant over their world as a model (the Sandbox only), or back. False when it can't
## open (not the Sandbox, riding, hiding, seated, no world).
func toggle_model_view() -> bool:
	if is_instance_valid(model_view) and model_view.is_open():
		model_view.close()
		model_view = null
		return true
	var p := local_player()
	if not _active or rig == null or p == null or not ModelViewRules.allowed(Game.mode):
		return false
	grabber.drop_all()   # nothing held across the giant's scale: a brick back to the bag, a thing let go
	for side: StringName in [VrRules.LEFT, VrRules.RIGHT]:
		bricks.grip_cancel(side)
	close_build_table()   # the table is the child's own size: closed (BUILD TABLE again after)
	model_view = VrModelView.new()
	add_child(model_view)
	if not model_view.open(p):
		model_view.queue_free()
		model_view = null
		return false
	model_view.ended.connect(func() -> void: model_view = null)
	return true


func model_view_open() -> bool:
	return is_instance_valid(model_view) and model_view.is_open()


## The child's body waits where it stood (MODEL VIEW): the controllers move nothing of it, room scale walks nothing.
func body_waits() -> bool:
	return _active and model_view_open()


## A hand's grip pose in the world (the tracker's "grip" when the runtime gives it, else its aim pose).
func hand_grip(side: StringName) -> Transform3D:
	var t := XRServer.get_tracker(VrRig.tracker_name(side)) as XRPositionalTracker
	if t != null and t.has_pose(&"grip") and rig != null:
		var p := t.get_pose(&"grip")
		if p != null and p.has_tracking_data:
			return rig.global_transform * p.get_adjusted_transform()
	return _hand_transform(side) if rig != null else Transform3D.IDENTITY


## Owner #112 (Life L1): a hand's grip, 0..1 (read-only; 0 off VR). The practice rooms read "the hand is here and
## squeezing" from it and the trigger (LifeRoomHost), never a particular button.
func grip(side: StringName) -> float:
	return _value(side, "grip") if _active else 0.0


func _value(side: StringName, control: String) -> float:
	var v: Variant = VrInput.read(side, control)
	if v is bool:
		return 1.0 if v else 0.0
	return float(v) if v is float else 0.0


## Owner #124: the aim pose seen from the grip pose (Basis() when the runtime gives only one of them): how a held item
## turns in the hand so its barrel or blade points along the laser (the Quest's aim is tilted ~40 degrees from its grip;
## an item along the grip pointed one way while the laser and the shots went another).
func aim_in_grip(side: StringName) -> Basis:
	var t := XRServer.get_tracker(VrRig.tracker_name(side)) as XRPositionalTracker
	if t == null or not t.has_pose(&"grip") or not t.has_pose(&"aim"):
		return Basis()
	var g := t.get_pose(&"grip")
	var a := t.get_pose(&"aim")
	if g == null or a == null or not g.has_tracking_data or not a.has_tracking_data:
		return Basis()
	return (g.get_adjusted_transform().basis.orthonormalized().inverse() * a.get_adjusted_transform().basis.orthonormalized())


## Owner #124: how far along a held weapon its shots leave it (a blaster's barrel; a bow's arrow leaves the bow hand).
const MUZZLE := 0.18


## Owner #124: where a shot of the held `item_id` leaves the hand in the world (INF off VR or with no hand).
func muzzle(item_id: int) -> Vector3:
	if not _active:
		return Vector3.INF
	var a := item_anchor(item_id)
	if a == null:
		return Vector3.INF
	if WeaponRules.base_of(item_id) == ItemIds.BOW:
		return a.global_position
	return a.global_transform * Vector3(0.0, 0.0, -MUZZLE)


## Where an item hangs in VR (Player._held_item_hand): the pointing hand's, a bow the other hand's (drawn with two).
func item_anchor(item_id: int) -> Node3D:
	var side := pointing_hand()
	if WeaponRules.base_of(item_id) == ItemIds.BOW:
		side = VrRules.LEFT if side == VrRules.RIGHT else VrRules.RIGHT
	var h := hand_models.get(side) as VrHandModel
	return h.item_anchor() if h else null


## The pose the others see (Player.vr_pose; VrPoseRules): the head and the hands in `player`'s body space.
func pose_bytes(player: Player) -> PackedByteArray:
	if not _active or rig == null or player == null:
		return PackedByteArray()
	var s := player.size_scale()
	var body := Transform3D(Basis(Vector3.UP, player.avatar.rotation.y), player.global_position).affine_inverse()
	var grips := Vector4(_value(VrRules.LEFT, "grip"), trigger(VrRules.LEFT), _value(VrRules.RIGHT, "grip"),
		trigger(VrRules.RIGHT))
	var pose := VrPoseRules.encode(body * head_transform(), body * hand_grip(VrRules.LEFT),
		body * hand_grip(VrRules.RIGHT), grips, CameraRig.HEAD_HEIGHT * s, s)
	# owner #110 idea 3: a high-five's count on the pose's spare byte (once there was one; older builds skip it)
	return VrGestureRules.with_claps(pose, gestures.claps if gestures != null else 0)


## The mirror (optional, P4): open, it stands 1.6 m ahead of the eyes and the child's avatar shows in it.
func set_mirror(on: bool) -> void:
	if on == (mirror != null):
		return
	if not on:
		mirror.queue_free()
		mirror = null
		show_self(false, &"mirror")
		return
	if not _active or rig == null:
		return
	mirror = VrMirror.new()
	add_child(mirror)
	mirror.use_world(get_viewport().find_world_3d())
	mirror.stand_before(head_transform())
	show_self(true, &"mirror")
	mirror.reflect(head_transform().origin)


func toggle_mirror() -> void:
	set_mirror(mirror == null)


func mirror_shown() -> bool:
	return mirror != null


## The child's own avatar shows (`on`) for `who` (&"photo": the selfie; &"mirror"): its meshes on
## VrPhotoCamera.SELF_LAYER, which the head never draws; back as they were when nobody wants it any more.
func show_self(on: bool, who: StringName) -> void:
	var was := not _self_seen.is_empty()
	if on:
		_self_seen[who] = true
	else:
		_self_seen.erase(who)
	var now := not _self_seen.is_empty()
	if now == was:
		return
	var player := local_player()
	if now and player != null:
		for n: Node in player.avatar.find_children("*", "VisualInstance3D", true, false):
			var v := n as VisualInstance3D
			_self_layers[v] = v.layers
			v.layers = VrPhotoCamera.SELF_LAYER
		if camera:
			camera.cull_mask &= ~VrPhotoCamera.SELF_LAYER
	elif not now:
		for v: VisualInstance3D in _self_layers:
			if is_instance_valid(v):
				v.layers = int(_self_layers[v])
		_self_layers.clear()
		if camera:
			camera.cull_mask |= VrPhotoCamera.SELF_LAYER


## Something shows the child its own avatar (Player._process keeps the avatar visible then).
func self_seen() -> bool:
	return _active and not _self_seen.is_empty()


## A hand's trigger as a press (the lead's frozen name, round 3): VrRules.trigger_down's hysteresis per hand (on at 0.6,
## off under 0.35), the same reading VrInput acts on; false off VR.
func trigger_pressed(side: StringName) -> bool:
	return _active and input != null and input.pressed(side)


## The head draws what `cam` would (the rocket's: its layers, its space environment, its far plane).
func view_like(cam: Camera3D) -> void:
	if camera != null and cam != null:
		camera.cull_mask = cam.cull_mask | VrRules.HANDS_LAYER   # owner #126: the child's own hands, in space too
		camera.environment = cam.environment
		camera.far = maxf(cam.far, VrRig.FAR)


## The head draws the world again as it does by itself.
func view_default() -> void:
	if camera != null:
		camera.cull_mask = (1 << 20) - 1
		camera.environment = null
		camera.far = VrRig.FAR

# --- The head and the hands ---

## The VR COMFORT setting `key` (VrRules' keys and defaults over the profile's).
func setting(key: String) -> Variant:
	return VrRules.setting(Profile.data.settings, key)


## The hand that points and acts (the left for a left-handed child).
func pointing_hand() -> StringName:
	return VrRules.pointing_hand(bool(Profile.data.settings.get("left_handed", false)))


## The pointing hand's ray ([] off VR).
func pointer_ray() -> Array:
	return hand_ray(pointing_hand())


func head_transform() -> Transform3D:
	return camera.global_transform if camera != null else Transform3D.IDENTITY


## A hand's aim in world space: its tracker's aim pose (OpenXR's aim_pose, WebXR's target ray), else its default pose,
## else a hand held in front of the chest (no controller tracked yet).
func _hand_transform(side: StringName) -> Transform3D:
	var t := XRServer.get_tracker(VrRig.tracker_name(side)) as XRPositionalTracker
	if t != null:
		for pose: StringName in [&"aim", &"default"]:
			if t.has_pose(pose):
				var p := t.get_pose(pose)
				if p != null and p.has_tracking_data:
					return rig.global_transform * p.get_adjusted_transform()
	var h := head_transform()
	var x := 0.2 if side == VrRules.RIGHT else -0.2
	return Transform3D(h.basis, h.origin + h.basis * Vector3(x, -0.35, -0.2))


## The player this game plays (the anchor while it is one), or null.
func local_player() -> Player:
	return _anchor as Player if is_instance_valid(_anchor) and _anchor is Player else null


## The node the origin follows (null when none).
func anchor_node() -> Node3D:
	return _anchor if is_instance_valid(_anchor) else null


## Turns the child on the spot by `radians` (snap turn; a yaw the game sets: a portal, a saved facing).
func turn(radians: float) -> void:
	if rig == null or radians == 0.0:
		return
	if _anchor_ok() and _anchor_kind == VrRig.SEAT:
		rig.turn_in_seat(radians, _anchor.global_transform)
	else:
		rig.turn(radians)


## Turns the head to look along `yaw` (CameraRig.yaw's meaning).
func face(yaw: float) -> void:
	if rig != null:
		turn(angle_difference(VrRules.yaw_of(head_transform().basis), yaw))


## The head back over the anchor, facing where it faces now (the Quest's recenter; the VR COMFORT page's RECENTER).
func recenter() -> void:
	if rig != null and _anchor_ok():
		rig.recenter(_anchor, _anchor_kind, VrRules.yaw_of(head_transform().basis))
	recentered.emit()


## The anchor went (a friend's showcase visit ended: its player was freed): the one before it again, behind a blink.
## False when none is left.
func _back_to_before() -> bool:
	while not _before.is_empty():
		var b: Array = _before.pop_back()
		var node := (b[0] as WeakRef).get_ref() as Node3D
		if is_instance_valid(node) and node.is_inside_tree():
			_anchor = node
			_anchor_kind = b[1]
			_recenter_on_anchor()
			blink()
			return true
	return false


## A seat or a menu spot faces its node's way; a player's feet keep the turn (CameraRig faces the player's yaw).
func _recenter_on_anchor() -> void:
	var face_yaw := NAN if _anchor_kind == VrRig.FEET else VrRules.yaw_of(_anchor.global_basis)
	rig.recenter(_anchor, _anchor_kind, face_yaw)


## A buzz in one hand (a place, a break, a hit). Owner #110 (VR round 4's frozen contract): `frequency` in Hz, 0 = the
## runtime's own (every caller before round 4 passes none).
func haptic(side: StringName, amplitude: float, seconds: float, frequency := 0.0) -> void:
	if rig == null:
		return
	haptics += 1
	var c := rig.hands.get(side) as XRController3D
	if c != null and _kind != SIM and _kind != PREVIEW:
		c.trigger_haptic_pulse("haptic", maxf(frequency, 0.0), clampf(amplitude, 0.0, 1.0), seconds, 0.0)

# --- Fakes: the tests' session and the desktop preview ---

func _add_fakes() -> void:
	if not _fakes.is_empty():
		return
	var head := XRPositionalTracker.new()
	head.name = &"head"
	head.type = XRServer.TRACKER_HEAD
	_fakes.append(head)
	for side: StringName in [VrRules.LEFT, VrRules.RIGHT]:
		var c := XRControllerTracker.new()
		c.name = VrRig.tracker_name(side)
		c.hand = XRPositionalTracker.TRACKER_HAND_LEFT if side == VrRules.LEFT else XRPositionalTracker.TRACKER_HAND_RIGHT
		_fakes.append(c)
	for t in _fakes:
		XRServer.add_tracker(t)
	sim_head(Transform3D(Basis(), Vector3(0.0, PREVIEW_EYE, 0.0)))
	sim_hand(VrRules.LEFT, Transform3D(Basis(), Vector3(-0.2, PREVIEW_EYE - 0.4, -0.3)))
	sim_hand(VrRules.RIGHT, Transform3D(Basis(), Vector3(0.2, PREVIEW_EYE - 0.4, -0.3)))


func _remove_fakes() -> void:
	for t in _fakes:
		XRServer.remove_tracker(t)
	_fakes.clear()


## Tests and the preview: the fake head's pose in the play space (origin space).
func sim_head(t: Transform3D) -> void:
	_sim_pose(&"head", &"default", t)


## Tests and the preview: a fake hand's aim pose in the play space.
func sim_hand(side: StringName, t: Transform3D) -> void:
	_sim_pose(VrRig.tracker_name(side), &"aim", t)


## Tests: a fake hand's grip pose (the Quest gives one tilted from its aim pose: owner #124); none: the grip is the aim.
func sim_grip(side: StringName, t: Transform3D) -> void:
	_sim_pose(VrRig.tracker_name(side), &"grip", t)


## Tests: a fake controller's input (&"trigger": 0..1, &"ax_button": true, &"primary": Vector2...).
func sim_input(side: StringName, input_name: StringName, value: Variant) -> void:
	for t in _fakes:
		if t.name == VrRig.tracker_name(side):
			t.set_input(input_name, value)


func _refresh_fakes() -> void:
	for f in _fakes:
		for pose: StringName in [&"default", &"aim", &"grip"]:
			if f.has_pose(pose):
				var p := f.get_pose(pose)
				f.set_pose(pose, p.transform, Vector3.ZERO, Vector3.ZERO, XRPose.XR_TRACKING_CONFIDENCE_HIGH)


func _sim_pose(tracker: StringName, pose: StringName, t: Transform3D) -> void:
	for f in _fakes:
		if f.name == tracker:
			f.set_pose(pose, t, Vector3.ZERO, Vector3.ZERO, XRPose.XR_TRACKING_CONFIDENCE_HIGH)

# --- The desktop preview (no headset: the fake head through the window, flat) ---

## The desktop's VR preview: the rig and the comfort rules as in a headset, seen flat through the fake head; the mouse
## (captured: click the world) turns the head, Q and E snap-turn, the game's own keys walk and the mouse buttons place
## and break along the fake right hand (it points where the head looks).
func preview(on: bool) -> void:
	if on == (_kind == PREVIEW):
		return
	if not on:
		_end()
		return
	_end()
	_kind = PREVIEW
	_add_fakes()
	_preview_yaw = 0.0
	_preview_pitch = 0.0
	_begin()


func _input(event: InputEvent) -> void:
	if _kind != PREVIEW:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var m := event as InputEventMouseMotion
		_preview_yaw -= m.relative.x * PREVIEW_MOUSE
		_preview_pitch = clampf(_preview_pitch - m.relative.y * PREVIEW_MOUSE, -1.3, 1.3)
	elif event is InputEventKey and event.pressed and not event.echo:
		var k := (event as InputEventKey).physical_keycode
		if k == KEY_Q or k == KEY_E:
			turn(deg_to_rad(VrRules.snap_degrees(str(setting(VrRules.TURN))) * (1.0 if k == KEY_Q else -1.0)))


## The fake head turns with the mouse; the fake right hand points at what the head looks at, 3 m out.
func _preview_step() -> void:
	if OS.get_cmdline_user_args().has(WAVE_ARG):
		_wave_step()
		return
	var b := Basis.from_euler(Vector3(_preview_pitch, _preview_yaw, 0.0))
	var eye := Vector3(0.0, PREVIEW_EYE, 0.0)
	sim_head(Transform3D(b, eye))
	var hand_at := eye + b * Vector3(0.2, -0.3, -0.1)
	var look_at := eye + b * Vector3(0.0, 0.0, -3.0)
	sim_hand(VrRules.RIGHT, Transform3D(Basis.looking_at(look_at - hand_at, Vector3.UP), hand_at))
	sim_hand(VrRules.LEFT, Transform3D(b, eye + b * Vector3(-0.2, -0.4, -0.2)))


## P4: the preview with --vr-wave (tools/net_test.sh --vr=...): a simulated child who nods, looks round and waves its
## right hand, for the other game to see (no mouse).
const WAVE_ARG := "--vr-wave"
var _wave_t := 0.0


func _wave_step() -> void:
	_wave_t += get_process_delta_time()
	var b := Basis.from_euler(Vector3(0.45 * sin(TAU * _wave_t / 2.0), 0.7 * sin(TAU * _wave_t / 5.0), 0.0))
	var eye := Vector3(0.0, PREVIEW_EYE, 0.0)
	sim_head(Transform3D(b, eye))
	var wave := Vector3(0.35, 0.25 + 0.2 * sin(TAU * _wave_t * 1.5), -0.2)
	sim_hand(VrRules.RIGHT, Transform3D(Basis(Vector3.FORWARD, 0.4 * sin(TAU * _wave_t * 1.5)), eye + wave))
	sim_hand(VrRules.LEFT, Transform3D(Basis(), eye + Vector3(-0.25, -0.45, -0.25)))
