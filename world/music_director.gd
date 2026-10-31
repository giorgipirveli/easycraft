class_name MusicDirector
extends Node
## Owner #110 (VR round 4, idea 7; the research docs/devlog/parts/vr-ideas-research.md §5.3, the notes
## docs/devlog/parts/vr-r4-sound.md): the music blocks played. Node "Music" in the sandbox, on every peer.
## - A tap (a phone, the web, a PC; the laser in VR) on a xylophone plays the bar under it, on the bongos the skin under
##   it or the shell, whatever is in the hand, as a good medium hit (MusicBlockRules.TAP_SPEED); a hold still breaks it.
##   The bar's letter shows over it for a moment (the School's note names).
## - In VR, near a music block two mallets float over it (VrGrabbable, kind &"tool": VR-HANDS' grabber takes them). A
##   held mallet's tip coming into a block plays what it hits, louder the faster it came, with a short buzz in that hand
##   at the note's own frequency; the trigger plays the bar under the tip too (no big arm motion needed). Let go, a
##   mallet floats back; far from every music block, or out of VR, they go.
## - LOOP (a context button over the hotbar, in the cars' HORN spot: never in a car) records four bars after a bar's
##   count-in, then plays them again and again; LOOP again adds a layer from the next bar (three at most); STOP clears
##   it. The metronome ticks while a take counts in and records. A loop stops when its player walks off.
## - Friends hear the notes as events, never audio: a guest's note goes to the host, who checks it (a music block there,
##   the friend near it, a budget a second) and plays it and passes it on to every game that has this node (a game
##   says so once: older builds never get a call they lack).
## The tones are our own (tools/make_instrument_tones.gd), played at their exact pitch from a small pool of positional
## players on the Effects bus (Audio's pools are never taken).

signal note_played(voice: int, cell: Vector3i, volume_db: float, from_peer: int)

const SOUND := &"music_note"
const POOL := 8
const LETTER_SECONDS := 0.8
const SCAN_EVERY := 0.4
## The scan looks this many cells each way round the feet (MALLET_NEAR, LOOP_NEAR) and this many up and down.
const SCAN_REACH := 4
const SCAN_UP := 2
## Farther than this from every music block (m) the mallets go, even held (within the scan's SCAN_REACH cells).
const MALLETS_GO := 4.5
## The trigger strikes at this squeeze (and again after it falls under TRIGGER_UP), the bar under the tip within
## STRIKE_REACH (m).
const TRIGGER_STRIKE := 0.6
const TRIGGER_UP := 0.35
const STRIKE_REACH := 0.15
const METRONOME_DB := -18.0
const ACCENT_DB := -12.0

var world: WorldService
var player: Player
var hud: Hud
## () -> Vector3: the local child's feet (INF while none stands in the world); setup_local sets the player's.
var local_feet: Callable = func() -> Vector3: return Vector3.INF
## (peer) -> Vector3: a player's feet on the host (INF: unknown).
var peer_feet: Callable = func(peer: int) -> Vector3:
	var p := Session._player_for_peer(peer)
	return p.global_position if p != null else Vector3.INF
## The game clock (s): it moves with step(), so a paused game's loop waits.
var time := 0.0
var loop := MusicBlockRules.Loop.new()
var mallets: Array[Mallet] = []
var letter := Label3D.new()
var loop_button: TouchButton
var stop_button: TouchButton
## Notes played here (taps, mallets, the loop, friends'), and the last one's voice, loudness, block, peer and buzz.
var played := 0
var last_voice := -1
var last_db := 0.0
var last_cell := Vector3i.ZERO
var last_from := 0
var last_haptic: Array = []
## The metronome's ticks so far (a take's count-in and its beats).
var metronome_ticks := 0
## A music block within LOOP_NEAR of the child (the nearest), and within MALLET_NEAR.
var near := false
var near_cell := Vector3i.ZERO

var _players: Array[AudioStreamPlayer3D] = []
var _next := 0
var _streams := {}
var _scan_t := 0.0
var _letter_t := 0.0
var _nearest_d := INF
var _loop_cells := {}
var _budget := {}
var _listeners := {}
var _host_listens := false


func _ready() -> void:
	for i in POOL:
		var p := AudioStreamPlayer3D.new()
		p.unit_size = 6.0
		p.max_distance = Audio.HEARING
		p.bus = Audio.BUS
		add_child(p)
		_players.append(p)
	letter.name = "Letter"
	letter.top_level = true
	letter.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	letter.pixel_size = 0.004
	letter.font_size = 72
	letter.outline_size = 18
	letter.visible = false
	add_child(letter)
	Vr.ended.connect(_drop_mallets)


func _process(delta: float) -> void:
	step(delta)


## This game's player and HUD: the taps on music blocks, LOOP and STOP; a guest tells the host it hears notes.
func setup_local(p: Player, h: Hud) -> void:
	player = p
	hud = h
	local_feet = func() -> Vector3: return Player.position_or_none(player)
	if player:
		var tap := player.get_node_or_null("BlockInteractor") as BlockInteractor
		if tap:
			tap.music_tap = tap_at_screen   # its own hook, before the cars' (the lead, VR-SOUND's ruling S1)
	if hud:
		make_buttons(hud)
		for b: TouchButton in [loop_button, stop_button]:
			hud.move_child(b, hud.palette.get_index())   # under the palette overlay
			if not hud.look_area.blockers.has(b):
				hud.look_area.blockers.append(b)
	if not Session.is_host() and multiplayer.has_multiplayer_peer():
		_rpc_listen.rpc_id(1)


## LOOP (the cars' HORN spot) and STOP (FLY's), hidden until a music block is near.
func make_buttons(parent: Control) -> void:
	loop_button = TouchButton.new()
	loop_button.name = "MusicLoop"
	loop_button.text = "LOOP"
	HudLayout.place(loop_button, &"horn")
	parent.add_child(loop_button)
	loop_button.pressed.connect(press_loop)
	stop_button = TouchButton.new()
	stop_button.name = "MusicStop"
	stop_button.text = "STOP"
	HudLayout.place(stop_button, &"car_fly")
	parent.add_child(stop_button)
	stop_button.pressed.connect(press_stop)
	_show_buttons()

# --- Playing ---------------------------------------------------------------------------------------------------------

## A tap at `screen_pos` on a music block plays it (true); anything else is the next tap's.
func tap_at_screen(screen_pos: Vector2) -> bool:
	if player == null or world == null:
		return false
	var tap := player.get_node_or_null("BlockInteractor") as BlockInteractor
	if tap == null:
		return false
	var hit := tap.ray_at(screen_pos)
	if hit == null or not MusicBlockRules.is_instrument(world.get_block(hit.position)):
		return false
	if tap.hittable_at(screen_pos, PlacementRules.REACH) != null:
		return false   # a friend, an animal or a buddy in front of it is the tap's
	var ray := player.aim_ray(screen_pos)
	var e := MusicBlockRules.entry(Vector3(ray[0]) - Vector3(hit.position), ray[1], PlacementRules.REACH * 2.0)
	if e.is_empty():
		e = {"face": Vector3i.UP, "point": Vector3(0.5, 1.0, 0.5)}
	return strike(hit.position, e.face, e.point, MusicBlockRules.TAP_SPEED) >= 0


## A strike on `face` at `point` (block space) of the block at `cell`, `speed` m/s fast; `side` the hand that buzzes
## (&"": none). The voice it played, -1 for none.
func strike(cell: Vector3i, face: Vector3i, point: Vector3, speed: float, side: StringName = &"") -> int:
	var voice := MusicBlockRules.voice_at(world.get_block(cell), face, point) if world else -1
	if voice < 0:
		return -1
	var db := MusicBlockRules.volume_db(voice, speed)
	_sound(voice, cell, db, multiplayer.get_unique_id())
	if loop.note(time, voice, cell, db):
		_loop_cells[cell] = true
	_send(voice, cell, db)
	_show_letter(voice, cell, point)
	if side != &"":
		last_haptic = MusicBlockRules.haptic(voice, speed)
		Vr.haptic(side, float(last_haptic[0]), float(last_haptic[1]), float(last_haptic[2]))
	return voice


func _sound(voice: int, cell: Vector3i, db: float, from: int) -> void:
	var at := Vector3(cell) + Vector3(0.5, 1.0, 0.5)
	var p := _players[_next]
	_next = (_next + 1) % _players.size()
	p.stream = _tone(voice)
	p.volume_db = db
	p.pitch_scale = 1.0
	if p.is_inside_tree():
		p.global_position = at
		p.play()
	played += 1
	last_voice = voice
	last_db = db
	last_cell = cell
	last_from = from
	Audio.sound_played.emit(SOUND, at, db)
	note_played.emit(voice, cell, db, from)


func _tone(voice: int) -> AudioStream:
	if not _streams.has(voice):
		_streams[voice] = load(MusicBlockRules.tone_file(voice))
	return _streams[voice]


## A bar's letter over it for LETTER_SECONDS (the drums have none).
func _show_letter(voice: int, cell: Vector3i, point: Vector3) -> void:
	var l := MusicBlockRules.letter(voice)
	if l == "":
		return
	letter.text = l
	letter.modulate = Color(MusicBlockRules.BAR_COLORS[voice].lightened(0.25), 1.0)
	letter.outline_modulate = Color(0.08, 0.06, 0.05, 1.0)
	letter.visible = true
	if letter.is_inside_tree():
		letter.global_position = Vector3(cell) + Vector3(clampf(point.x, 0.0, 1.0), 1.35, 0.5)
	_letter_t = LETTER_SECONDS

# --- Every frame -----------------------------------------------------------------------------------------------------

## A frame (`delta` s): the loop's notes due and the metronome, the letter's fade, the scan for music blocks near (the
## buttons, the mallets), the mallets following their hands and striking.
func step(delta: float) -> void:
	time += delta
	for e: Dictionary in loop.tick(time):
		if world and MusicBlockRules.is_instrument(world.get_block(e.c)):   # a broken block's notes are silent
			_sound(int(e.v), e.c, float(e.db), multiplayer.get_unique_id())
			_send(int(e.v), e.c, float(e.db))
	var beat := loop.beat_tick(time)
	if beat != MusicBlockRules.Loop.NO_TICK:
		var accent := MusicBlockRules.Loop.accented(beat)
		metronome_ticks += 1
		Audio.play(&"beep", Vector3.INF, ACCENT_DB if accent else METRONOME_DB, 1.5 if accent else 1.2)
	if _letter_t > 0.0:
		_letter_t -= delta
		letter.modulate.a = clampf(_letter_t / (LETTER_SECONDS * 0.4), 0.0, 1.0)
		if _letter_t <= 0.0:
			letter.visible = false
	_scan_t -= delta
	if _scan_t <= 0.0:
		_scan_t = SCAN_EVERY
		_scan()
	_show_buttons()
	_step_mallets(delta)


## The nearest music block round the feet; the loop stops when the child is far from it; the mallets come and go.
func _scan() -> void:
	var feet: Vector3 = local_feet.call()
	near = false
	_nearest_d = INF
	if world != null and feet.is_finite():
		var base := Vector3i(feet.floor())
		for dy in range(-SCAN_UP, SCAN_UP + 1):
			for dz in range(-SCAN_REACH, SCAN_REACH + 1):
				for dx in range(-SCAN_REACH, SCAN_REACH + 1):
					var c := base + Vector3i(dx, dy, dz)
					if not MusicBlockRules.is_instrument(world.get_block(c)):
						continue
					var d := _distance(feet, c)
					if d < _nearest_d:
						_nearest_d = d
						near_cell = c
		near = _nearest_d <= MusicBlockRules.LOOP_NEAR
	if loop.state != MusicBlockRules.Loop.IDLE and _far_from_loop(feet):
		press_stop()
	if not Vr.active() or _nearest_d > MALLETS_GO:
		_drop_mallets()
	elif _nearest_d <= MusicBlockRules.MALLET_NEAR:
		_bring_mallets()


## From the feet to the nearest point of the block at `c` (m).
static func _distance(feet: Vector3, c: Vector3i) -> float:
	return feet.distance_to(feet.clamp(Vector3(c), Vector3(c) + Vector3.ONE))


func _far_from_loop(feet: Vector3) -> bool:
	if not feet.is_finite():
		return false
	for c: Vector3i in _loop_cells:
		if _distance(feet, c) <= MusicBlockRules.LOOP_RANGE:
			return false
	return not _loop_cells.is_empty() or _nearest_d > MusicBlockRules.LOOP_RANGE

# --- LOOP and STOP ---------------------------------------------------------------------------------------------------

## LOOP: the first take after a bar's count-in, or one more layer from the next bar.
func press_loop() -> bool:
	if not loop.record(time):
		return false
	if near:
		_loop_cells[near_cell] = true
	_show_buttons()
	return true


## STOP: the loop and its layers gone.
func press_stop() -> void:
	loop.stop()
	_loop_cells.clear()
	_show_buttons()


## The buttons' words and who shows: LOOP near a music block (never in a car, nor over SLEEP), STOP while a loop runs.
func _show_buttons() -> void:
	if loop_button == null:
		return
	var free := not (player != null and player.in_car()) and not (hud != null and hud.sleep_button.visible)
	var running := loop.state != MusicBlockRules.Loop.IDLE
	loop_button.visible = free and (near or running)
	stop_button.visible = free and running
	var words := "LOOP"
	match loop.state:
		MusicBlockRules.Loop.COUNT_IN:
			var b := loop.beat_at(time) - loop.rec_from
			words = str(clampi(-floori(b), 1, MusicBlockRules.COUNT_IN_BEATS)) if b >= -MusicBlockRules.COUNT_IN_BEATS \
				else "WAIT"
		MusicBlockRules.Loop.RECORDING:
			words = "REC %d/%d" % [clampi(floori((loop.beat_at(time) - loop.rec_from) / MusicBlockRules.BEATS_PER_BAR) + 1,
				1, MusicBlockRules.LOOP_BARS), MusicBlockRules.LOOP_BARS]
		MusicBlockRules.Loop.PLAYING:
			words = "LOOP +" if loop.layers.size() < MusicBlockRules.MAX_LAYERS else "%d LOOPS" % loop.layers.size()
	if loop_button.text != words:
		loop_button.text = words
		loop_button.queue_redraw()
	var lit := loop.state == MusicBlockRules.Loop.RECORDING
	if loop_button.selected != lit:
		loop_button.selected = lit
		loop_button.queue_redraw()

# --- The mallets (VR) ------------------------------------------------------------------------------------------------

func _bring_mallets() -> void:
	if mallets.is_empty():
		for i in 2:
			var m := Mallet.new()
			m.name = "Mallet%d" % i
			add_child(m)
			mallets.append(m)
			m.grabbable.used.connect(_on_used.bind(m))
	var top := Vector3(near_cell) + Vector3(0.5, 1.0, 0.5)
	var feet: Vector3 = local_feet.call()
	var to_child := Vector3(feet.x - top.x, 0.0, feet.z - top.z)
	to_child = to_child.normalized() if to_child.length() > 0.01 else Vector3.BACK
	var across := to_child.cross(Vector3.UP)
	for i in mallets.size():
		var at := top + to_child * 0.45 + Vector3.UP * 0.25 + across * (0.12 if i == 0 else -0.12)
		mallets[i].rest = Transform3D(Basis.looking_at(-to_child, Vector3.UP), at)


func _drop_mallets() -> void:
	for m in mallets:
		if is_instance_valid(m):
			m.queue_free()
	mallets.clear()


## The mallets follow their hands (or float at rest); a held one's tip coming into a music block strikes it.
func _step_mallets(delta: float) -> void:
	for m in mallets:
		m.follow()
		var tip := m.tip()
		var side := m.grabbable.held_by()
		if side == &"" or side == &"both" or delta <= 0.0 or not m.has_prev:
			m.prev_tip = tip
			m.has_prev = side != &""
			continue
		var speed := tip.distance_to(m.prev_tip) / delta
		if not m.armed and _rearmed(m, tip):
			m.armed = true
		if m.armed and MusicBlockRules.is_hit(speed):
			for c in _cells_round(tip):
				if not MusicBlockRules.is_instrument(world.get_block(c)):
					continue
				var e := MusicBlockRules.entry(m.prev_tip - Vector3(c), tip - m.prev_tip, 1.0, MusicBlockRules.TIP_RADIUS)
				if e.is_empty():
					continue
				if strike(c, e.face, e.point, speed, side) >= 0:
					m.armed = false
					m.hit_cell = c
					m.hit_at = time
				break
		m.prev_tip = tip


## Re-armed: out of the block it hit by REARM, and MIN_GAP after the hit.
func _rearmed(m: Mallet, tip: Vector3) -> bool:
	if time - m.hit_at < MusicBlockRules.MIN_GAP:
		return false
	var grow := MusicBlockRules.TIP_RADIUS + MusicBlockRules.REARM
	var lo := Vector3(m.hit_cell) - Vector3.ONE * grow
	var hi := Vector3(m.hit_cell) + Vector3.ONE * (1.0 + grow)
	return not (tip.x > lo.x and tip.y > lo.y and tip.z > lo.z and tip.x < hi.x and tip.y < hi.y and tip.z < hi.z)


## The cells a tip of TIP_RADIUS at `p` touches.
static func _cells_round(p: Vector3) -> Array[Vector3i]:
	var out: Array[Vector3i] = []
	var r := MusicBlockRules.TIP_RADIUS
	for dx: float in [-r, r]:
		for dy: float in [-r, r]:
			for dz: float in [-r, r]:
				var c := Vector3i((p + Vector3(dx, dy, dz)).floor())
				if not out.has(c):
					out.append(c)
	return out


## The trigger on a held mallet: the bar (or skin) under its tip plays, as a tap does.
func _on_used(side: StringName, amount: float, m: Mallet) -> void:
	if amount < TRIGGER_UP:
		m.trigger_down = false
		return
	if amount < TRIGGER_STRIKE or m.trigger_down:
		return
	m.trigger_down = true
	var tip := m.tip()
	for c: Vector3i in [Vector3i(tip.floor()), Vector3i((tip - Vector3(0.0, STRIKE_REACH, 0.0)).floor())]:
		if world == null or not MusicBlockRules.is_instrument(world.get_block(c)):
			continue
		var e := MusicBlockRules.entry(tip - Vector3(c), Vector3.DOWN, STRIKE_REACH + MusicBlockRules.TIP_RADIUS)
		if e.is_empty() and tip.y - float(c.y) <= 1.0:
			e = {"face": Vector3i.UP, "point": (tip - Vector3(c)).clamp(Vector3.ZERO, Vector3.ONE)}   # in it already
		if not e.is_empty():
			strike(c, e.face, e.point, MusicBlockRules.TAP_SPEED, side)
			return


## A mallet (VR): a stick with a round head along its -Z from the grip (its origin), a VrGrabbable of kind &"tool" at
## the grip. Held, it sits in its hand (Vr.hand_grip * hold_offset); let go, it floats at `rest`.
class Mallet:
	extends Node3D
	## The head's middle from the grip.
	const TIP := Vector3(0.0, 0.0, -0.3)
	const HEAD := Color("f2c94c")
	const STICK := Color("c99a64")

	var grabbable := VrGrabbable.new()
	var rest := Transform3D.IDENTITY
	var prev_tip := Vector3.ZERO
	var has_prev := false
	var armed := true
	var hit_cell := Vector3i.ZERO
	var hit_at := -INF
	var trigger_down := false

	func _init() -> void:
		grabbable.name = "Grabbable"
		grabbable.kind = &"tool"
		grabbable.throwable = false
		grabbable.far_pull = true
		grabbable.hold_offset = Transform3D(Basis(Vector3.RIGHT, deg_to_rad(-20.0)), Vector3.ZERO)
		add_child(grabbable)
		var stick := MeshInstance3D.new()
		stick.name = "Stick"
		var c := CylinderMesh.new()
		c.top_radius = 0.011
		c.bottom_radius = 0.011
		c.height = 0.34
		c.radial_segments = 8
		c.rings = 1
		stick.mesh = c
		stick.rotation = Vector3(PI * 0.5, 0.0, 0.0)   # its length along z
		stick.position = Vector3(0.0, 0.0, -0.12)
		stick.material_override = _material(STICK)
		stick.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(stick)
		var head := MeshInstance3D.new()
		head.name = "Head"
		var s := SphereMesh.new()
		s.radius = 0.028
		s.height = 0.056
		s.radial_segments = 10
		s.rings = 5
		head.mesh = s
		head.position = TIP
		head.material_override = _material(HEAD)
		head.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(head)
		grabbable.released.connect(func(_side: StringName, _v: Vector3) -> void: trigger_down = false)

	## The blocky avatar's own material settings (warmed with the avatar: no new shader to compile in a headset).
	static func _material(color: Color) -> StandardMaterial3D:
		return AvatarParts.material(color)

	## Held: in its hand; else at rest.
	func follow() -> void:
		var side := grabbable.held_by()
		if side == &"left" or side == &"right":
			global_transform = Vr.hand_grip(side) * grabbable.hold_offset
		elif side == &"":
			global_transform = rest

	## The head's middle in the world.
	func tip() -> Vector3:
		return global_transform * TIP

# --- Friends (events, never audio) ----------------------------------------------------------------------------------

func _send(voice: int, cell: Vector3i, db: float) -> void:
	if not multiplayer.has_multiplayer_peer() or multiplayer.get_peers().is_empty():
		return
	if Session.is_host():
		_relay(multiplayer.get_unique_id(), voice, cell, db)
	elif _host_listens:
		_rpc_note.rpc_id(1, cell, voice, roundi(db * 10.0))


## Host: player `peer`'s note (a music block at `cell`, the friend near it, within the budget): played here and passed
## on. "" when it played, else why not.
func host_note(peer: int, cell: Vector3i, voice: int, db: float) -> String:
	if voice < 0 or voice >= MusicBlockRules.VOICES or world == null:
		return "unknown"
	if not MusicBlockRules.is_instrument(world.get_block(cell)):
		return "no_instrument"
	var feet: Vector3 = peer_feet.call(peer)
	if not feet.is_finite() or _distance(feet, cell) > MusicBlockRules.REACH:
		return "too_far"
	if not _budget.has(peer):
		_budget[peer] = []
	if not MusicBlockRules.may_play(_budget[peer], time):
		return "too_many"
	var level := clampf(db, -40.0, MusicBlockRules.MAX_DB)
	_sound(voice, cell, level, peer)
	_relay(peer, voice, cell, level)
	return ""


func _relay(from: int, voice: int, cell: Vector3i, db: float) -> void:
	for p: int in _listeners:
		if p != from and multiplayer.get_peers().has(p):
			_rpc_heard.rpc_id(p, from, cell, voice, roundi(db * 10.0))


## Host: the games that hear notes (a guest says so once).
func host_listen(peer: int) -> void:
	_listeners[peer] = true


@rpc("any_peer", "call_remote", "reliable")
func _rpc_listen() -> void:
	if Session.is_host():
		host_listen(multiplayer.get_remote_sender_id())
		_rpc_welcome.rpc_id(multiplayer.get_remote_sender_id())


@rpc("authority", "call_remote", "reliable")
func _rpc_welcome() -> void:
	_host_listens = true


@rpc("any_peer", "call_remote", "unreliable")
func _rpc_note(cell: Vector3i, voice: int, db10: int) -> void:
	if Session.is_host():
		host_note(multiplayer.get_remote_sender_id(), cell, voice, db10 / 10.0)


@rpc("authority", "call_remote", "unreliable")
func _rpc_heard(from: int, cell: Vector3i, voice: int, db10: int) -> void:
	if voice >= 0 and voice < MusicBlockRules.VOICES:
		_sound(voice, cell, minf(db10 / 10.0, MusicBlockRules.MAX_DB), from)
