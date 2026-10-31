extends GutTest
## Owner #110, VR round 4 (VR-WONDER, idea 1 "hold a planet"; docs/devlog/parts/vr-r4-wonder.md): in a headset the Star
## Map is a moving orrery within reach (VrOrrery, made by SpacePanel), driven with fake hands (Vr.simulate) on a real
## Player. A planet taken grows to its true size against Earth in the hand and opens its card (the Space Book); two hands
## stretch it; Jupiter and Earth held together are compared in words; let go it floats back to its orbit; dropped in the
## landing ring it flies there as LAND does (or the panel says why not); TRUE SIZE lines the planets up before the Sun;
## time holds still while a hand is on a planet; nothing of it off VR.

const OPEN: Array[int] = [16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28]
const DT := 1.0 / 72.0


class FloorWorld:
	extends WorldService

	func get_block(pos: Vector3i) -> int:
		return BlockIds.STONE if pos.y < 80 else BlockIds.AIR


## A voice that keeps what it was asked to say ("Read to me").
class HeardVoice:
	extends ReadAloud.Voice
	var said: Array[String] = []

	func has_voice(_language: String) -> bool:
		return true

	func speak(text: String, _language: String) -> void:
		said.append(text)


var p: Player
var panel: SpacePanel
var heard := {}
var _settings := {}


func before_each() -> void:
	_settings = Profile.data.settings.duplicate()
	heard = {"travel": [], "home": 0, "seen": []}
	var w := FloorWorld.new()
	autofree(w)
	p = load("res://entities/player/player.tscn").instantiate()
	p.name = str(multiplayer.get_unique_id())
	p.world = w
	add_child_autofree(p)
	p.set_physics_process(false)
	p.set_process_unhandled_input(false)
	p.get_node("BlockInteractor").set_process_unhandled_input(false)
	p.viewer.free()
	p._spawned = true
	p.visible = true
	p.global_position = Vector3(0.5, 80, 0.5)
	Vr.simulate(true)
	Vr.anchor(p, &"feet")
	_frame()
	panel = SpacePanel.new()
	panel.size = Vector2(1280, 720)
	add_child_autofree(panel)
	panel.travel_requested.connect(func(u: int) -> void: heard.travel.append(u))
	panel.home_requested.connect(func() -> void: heard.home += 1)
	panel.body_seen.connect(func(id: StringName) -> void: heard.seen.append(id))


func after_each() -> void:
	if is_instance_valid(panel):
		panel.close()
	Vr.simulate(false)
	Vr.anchor(null)
	Input.flush_buffered_events()
	get_tree().paused = false
	Profile.data.settings.clear()
	Profile.data.settings.merge(_settings)
	UniverseRegistry.reset()


func _frame(delta: float = DT) -> void:
	Vr.step_physics()
	Vr.step(delta)
	Input.flush_buffered_events()
	p.rig._process(delta)
	p._process(delta)
	if is_instance_valid(panel) and panel.vr_orrery != null and is_instance_valid(panel.vr_orrery):
		panel.vr_orrery.step(delta)


func _frames(seconds: float) -> void:
	for i in ceili(seconds / DT):
		_frame()


func _open() -> VrOrrery:
	panel.open(1, 1, OPEN, 2)
	_frame()
	return panel.vr_orrery


## A hand (the play space's pose) moved so that its grip is at world point `at`.
func _hand_to(side: StringName, at: Vector3) -> void:
	var local := Vr.rig.global_transform.affine_inverse() * at / Vr.world_scale()
	Vr.sim_hand(side, Transform3D(Basis(), local))


func _grip(side: StringName, value: float) -> void:
	Vr.sim_input(side, &"grip", value)
	_frame()


## Takes body `id` in hand `side`: the hand to it, a frame (its glow), the grip.
func _take(o: VrOrrery, id: StringName, side: StringName = VrRules.RIGHT) -> Node3D:
	var b := o.body(id)
	_hand_to(side, b.global_position + Vector3(0.0, 0.0, 0.0))
	_frame()
	_grip(side, 1.0)
	return b


func test_in_vr_the_star_map_opens_an_orrery_within_reach_under_the_panel() -> void:
	var o := _open()
	assert_not_null(o, "the orrery comes with the Star Map in a headset")
	assert_true(o.is_inside_tree())
	var head := Vr.head_transform()
	var to := o.global_position - head.origin
	assert_almost_eq(-to.y, OrreryRules.ORRERY_DROP, 0.01, "under the eyes, under the eye panel")
	assert_almost_eq(Vector2(to.x, to.z).length(), OrreryRules.ORRERY_AHEAD, 0.01, "ahead of the child")
	for b: Dictionary in StarMap.SOLAR:
		assert_not_null(o.body(b.id), "%s is on the orrery" % b.id)
	var days := o.days
	for id: StringName in [&"earth", &"jupiter", &"pluto"]:
		var want := o.global_transform * OrreryRules.place(id, days, o.moon_t, false)
		assert_almost_eq(o.body(id).global_position.distance_to(want), 0.0, 0.002, "%s where it really is today" % id)
	assert_true(panel.true_size_button.visible, "TRUE SIZE on the panel")
	assert_false(o.body_grabbable(&"sun").enabled, "the Sun stays in the middle")
	assert_false(panel.body_for(&"jupiter").visible, "on the panel the solar system is the orrery now")
	assert_true(panel.body_for(&"boing").visible, "the far worlds stay on the map")
	panel.close()
	assert_true(panel.body_for(&"jupiter").visible, "closed: the flat map as it was")


func test_off_vr_the_star_map_is_as_before() -> void:
	Vr.simulate(false)
	panel.open(1, 1, OPEN, 2)
	assert_null(panel.vr_orrery, "no orrery off VR")
	assert_false(panel.true_size_button.visible, "no TRUE SIZE off VR")
	assert_eq(panel.hint(), "", "the flat map's own words")


func test_a_planet_taken_grows_to_its_true_size_in_the_hand_and_opens_its_card() -> void:
	var o := _open()
	var jupiter := _take(o, &"jupiter")
	assert_eq(o.body_grabbable(&"jupiter").held_by(), VrRules.RIGHT, "Jupiter is in the hand")
	assert_true(panel.card_open(), "its card opens on the panel")
	assert_eq(panel.card_title(), "Jupiter")
	assert_has(heard.seen, &"jupiter", "the Space Book learns it")
	_frames(0.6)
	assert_almost_eq(jupiter.global_transform.basis.get_scale().x, OrreryRules.hand_radius(&"jupiter"), 0.002,
		"in the hand it is its true size against Earth: 45 cm across")
	assert_almost_eq(jupiter.global_position.distance_to(Vr.hand_grip(VrRules.RIGHT).origin),
		OrreryRules.hand_radius(&"jupiter") * VrOrrery.HOLD_AHEAD, 0.02, "held in front of the palm")


func test_a_planet_taken_reads_its_card_aloud_for_read_to_me() -> void:
	var old := ReadAloud.voice
	var voice := HeardVoice.new()
	ReadAloud.voice = voice
	Profile.data.settings["read_to_me"] = true
	var o := _open()
	_take(o, &"jupiter")
	ReadAloud.voice = old
	ReadAloud.queue.clear()
	assert_true(voice.said.any(func(t: String) -> bool: return t.contains("Jupiter is the biggest planet")),
		"its facts read aloud: %s" % str(voice.said))


func test_two_hands_stretch_a_planet() -> void:
	var o := _open()
	var j := _take(o, &"jupiter")
	_frames(0.6)
	var size := j.global_transform.basis.get_scale().x
	var right := Vr.hand_grip(VrRules.RIGHT).origin
	var left := j.global_position + Vector3(-0.1, 0.0, 0.0)   # the other hand on the big ball too
	_hand_to(VrRules.LEFT, left)
	_frame()
	_grip(VrRules.LEFT, 1.0)
	assert_eq(o.body_grabbable(&"jupiter").held_by(), &"both", "both hands on it")
	var mid := (left + right) * 0.5
	var half := (right - left) * 0.5
	_hand_to(VrRules.LEFT, mid - half * 2.0)
	_hand_to(VrRules.RIGHT, mid + half * 2.0)
	_frame()
	_frame()
	assert_almost_eq(j.global_transform.basis.get_scale().x, size * 2.0, size * 0.1, "twice as far apart: twice as big")
	assert_almost_eq(j.global_position.distance_to(mid), 0.0, 0.01, "between the hands")


func test_jupiter_and_earth_in_the_two_hands_are_compared() -> void:
	var o := _open()
	_take(o, &"earth", VrRules.LEFT)
	_hand_to(VrRules.LEFT, Vr.head_transform().origin + Vector3(-0.3, -0.3, -0.35))
	_frame()
	_take(o, &"jupiter", VrRules.RIGHT)
	_frames(0.6)
	assert_eq(o.compare_text(), "Jupiter is 11 times as wide as Earth!")
	var ratio := o.body(&"jupiter").global_transform.basis.get_scale().x / o.body(&"earth").global_transform.basis.get_scale().x
	assert_almost_eq(ratio, OrreryRules.ratio(&"jupiter", &"earth"), 0.05, "and they look it")
	_grip(VrRules.LEFT, 0.0)
	assert_eq(o.compare_text(), "", "one planet: no comparison")


func test_let_go_a_planet_floats_back_to_its_orbit() -> void:
	var o := _open()
	var mars := _take(o, &"mars")
	_hand_to(VrRules.RIGHT, Vr.head_transform().origin + Vector3(0.1, 0.2, -0.3))
	_frames(0.3)
	_grip(VrRules.RIGHT, 0.0)
	assert_eq(o.body_grabbable(&"mars").held_by(), &"")
	_frames(VrOrrery.GLIDE_TIME + 0.1)
	var want := o.global_transform * OrreryRules.place(&"mars", o.days, o.moon_t, false)
	assert_almost_eq(mars.global_position.distance_to(want), 0.0, 0.003, "back on its orbit")
	assert_almost_eq(mars.global_transform.basis.get_scale().x, OrreryRules.radius(&"mars", false), 0.001, "its orrery size")
	assert_eq(heard.travel, [], "no trip")


func test_dropped_in_the_landing_ring_a_planet_flies_there_as_land_does() -> void:
	var o := _open()
	_take(o, &"moon")
	_frames(0.3)
	_hand_to(VrRules.RIGHT, o.ring_position())
	_frames(0.2)
	_grip(VrRules.RIGHT, 0.0)
	assert_eq(heard.travel, [16], "the Moon's world: LAND, as the card's button")


func test_a_planet_with_no_ground_dropped_in_the_ring_says_why() -> void:
	var o := _open()
	_take(o, &"jupiter")
	_frames(0.3)
	_hand_to(VrRules.RIGHT, o.ring_position())
	_frames(0.2)
	_grip(VrRules.RIGHT, 0.0)
	assert_eq(heard.travel, [], "no trip to Jupiter")
	assert_eq(panel.hint(), StarMap.action_words(StarMap.NO_GROUND), "the panel says why")


func test_home_dropped_in_the_ring_goes_home() -> void:
	panel.open(16, 1, OPEN, 2)   # on the Moon, home is Green Meadows: its universe planet is far away; Earth lands
	_frame()
	var o := panel.vr_orrery
	_take(o, &"moon")
	_frames(0.3)
	_hand_to(VrRules.RIGHT, o.ring_position())
	_frames(0.2)
	_grip(VrRules.RIGHT, 0.0)
	assert_eq(heard.travel, [], "the Moon is here")
	assert_eq(panel.hint(), StarMap.action_words(StarMap.HERE))


func test_true_size_lines_the_planets_up_before_the_sun() -> void:
	var o := _open()
	panel.true_size_button.pressed.emit()
	assert_true(o.true_size)
	assert_eq(panel.true_size_button.text, "ORRERY", "the button goes back")
	_frames(VrOrrery.GLIDE_TIME + 0.1)
	for id: StringName in OrreryRules.ROW:
		var want := o.global_transform * OrreryRules.place(id, o.days, o.moon_t, true)
		assert_almost_eq(o.body(id).global_position.distance_to(want), 0.0, 0.003, "%s in the row" % id)
		assert_almost_eq(o.body(id).global_transform.basis.get_scale().x, OrreryRules.radius(id, true), 0.0005,
			"%s at its true size" % id)
	assert_almost_eq(o.body(&"sun").global_transform.basis.get_scale().x, OrreryRules.radius(&"sun", true), 0.001,
		"the Sun 109 Earths across")
	panel.true_size_button.pressed.emit()
	assert_false(o.true_size)
	assert_eq(panel.true_size_button.text, "TRUE SIZE")


func test_time_goes_round_but_holds_still_while_a_hand_is_on_a_planet() -> void:
	var o := _open()
	var d0 := o.days
	_frames(1.0)
	assert_almost_eq(o.days - d0, OrreryRules.days_per_second(), 0.5, "a year in 40 seconds")
	_hand_to(VrRules.RIGHT, o.body(&"saturn").global_position)
	_frame()
	var d1 := o.days
	_frames(0.5)
	assert_eq(o.days, d1, "a planet waits for the hand near it")
	_grip(VrRules.RIGHT, 1.0)
	_frames(0.5)
	assert_eq(o.days, d1, "and while it is held")


func test_the_orrery_goes_with_the_map_and_with_the_session() -> void:
	var o := _open()
	panel.close()
	assert_true(o == null or not is_instance_valid(o) or o.is_queued_for_deletion(), "closed with the map")
	assert_null(panel.vr_orrery)
	var o2 := _open()
	assert_not_null(o2)
	Vr.simulate(false)
	assert_true(not is_instance_valid(o2) or o2.is_queued_for_deletion(), "gone with the session")
