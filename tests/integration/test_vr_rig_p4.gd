extends GutTest
## Owner #101 (VR on the Meta Quest), P4 with Vr.simulate's fakes on a real Player (stone under y 80): the child's own
## hands in the avatar's colours (a fist, a point), the held item on the hand (a bow in the other hand), the bow drawn
## with two hands, opt-in swings (off by default; once per swing; the weapon's cooldown), vr_pose written while in VR,
## a remote VR player's body (its head turned, its hands floating, its arms folded, the VR mark), the mirror (the
## avatar seen only in it), and the games that refuse a teleport (a race, a round).

class FloorWorld:
	extends WorldService

	func get_block(pos: Vector3i) -> int:
		return BlockIds.STONE if pos.y < 80 else BlockIds.AIR

	func surface_height(_x: int, _z: int) -> int:
		return 80


var p: Player
var _settings := {}


func before_each() -> void:
	_settings = Profile.data.settings.duplicate()
	var w := FloorWorld.new()
	autofree(w)
	p = load("res://entities/player/player.tscn").instantiate()
	p.name = str(multiplayer.get_unique_id())
	p.world = w
	add_child_autofree(p)
	p.set_physics_process(false)
	p.viewer.free()
	p._spawned = true
	p.visible = true
	p.global_position = Vector3(0.5, 80, 0.5)
	Session._last_attack.erase(p.peer_id)
	Vr.simulate(true)
	Vr.anchor(p, &"feet")
	_frame()


func after_each() -> void:
	Vr.simulate(false)
	Vr.anchor(null)
	Session._last_attack.erase(multiplayer.get_unique_id())
	Profile.data.settings.clear()
	Profile.data.settings.merge(_settings)


func _frame(delta: float = 1.0 / 72.0) -> void:
	Vr.step_physics()
	Vr.step(delta)
	p.rig._process(delta)
	p._process(delta)


func test_the_childs_own_hands_wear_the_avatars_colours_and_take_the_grip_and_trigger() -> void:
	assert_eq(Vr.hand_models.size(), 2, "two hands")
	var right := Vr.hand_models[VrRules.RIGHT] as VrHandModel
	assert_almost_eq(right.global_position.distance_to(Vr.hand_grip(VrRules.RIGHT).origin), 0.0, 0.001, "on the controller")
	var skin: Color = p.avatar.look().resolve().skin
	var palm := right.find_child("Palm", true, false) as MeshInstance3D
	assert_eq((palm.material_override as StandardMaterial3D).albedo_color, Color(skin, 1.0), "the avatar's skin")
	Vr.sim_input(VrRules.RIGHT, &"grip", 1.0)
	Vr.sim_input(VrRules.RIGHT, &"trigger", 0.0)
	_frame()
	assert_true(right.pointing(), "a grip without the trigger points")
	Vr.sim_input(VrRules.RIGHT, &"trigger", 1.0)
	_frame()
	assert_false(right.pointing(), "both: a fist")
	assert_almost_eq(right.grip, 1.0, 0.001)


func test_the_held_item_hangs_on_the_hand_and_a_bow_in_the_other() -> void:
	var interactor := p.get_node("BlockInteractor") as BlockInteractor
	p.held_item = ItemIds.SWORD
	_frame()
	assert_eq(p._held.get_parent(), (Vr.hand_models[VrRules.RIGHT] as VrHandModel).item_anchor(), "the sword in the hand")
	p.held_item = ItemIds.BOW
	_frame()
	assert_eq(p._held.get_parent(), (Vr.hand_models[VrRules.LEFT] as VrHandModel).item_anchor(), "the bow in the other")
	assert_not_null(interactor)
	Vr.simulate(false)
	p._process(0.016)
	assert_eq(p._held.get_parent(), p.avatar.hand(), "off VR: the avatar's hand again")


func test_the_bow_is_drawn_with_two_hands() -> void:
	var interactor := p.get_node("BlockInteractor") as BlockInteractor
	interactor.hotbar[0] = ItemIds.BOW
	interactor.select_slot(0)
	# the bow hand (left) held out ahead; the string hand (right) at it
	Vr.sim_hand(VrRules.LEFT, Transform3D(Basis(), Vector3(-0.05, 1.3, -0.55)))
	Vr.sim_hand(VrRules.RIGHT, Transform3D(Basis(), Vector3(0.0, 1.3, -0.45)))
	Vr.sim_input(VrRules.RIGHT, &"trigger", 1.0)
	_frame()
	assert_true(Vr.input.drawing, "the string taken at the bow")
	Vr.sim_hand(VrRules.RIGHT, Transform3D(Basis(), Vector3(0.0, 1.3, 0.1)))   # pulled back past the full draw
	_frame()
	assert_almost_eq(Vr.input.draw_power, 1.0, 0.001, "a full draw")
	Vr.sim_input(VrRules.RIGHT, &"trigger", 0.0)
	_frame()
	assert_false(Vr.input.drawing)
	assert_eq(Vr.input.shots, 1, "let go: the arrow flies")


func test_a_squeeze_away_from_the_bow_takes_no_string() -> void:
	var interactor := p.get_node("BlockInteractor") as BlockInteractor
	interactor.hotbar[0] = ItemIds.BOW
	interactor.select_slot(0)
	Vr.sim_hand(VrRules.LEFT, Transform3D(Basis(), Vector3(-0.3, 1.0, -0.2)))
	Vr.sim_hand(VrRules.RIGHT, Transform3D(Basis(), Vector3(0.4, 1.3, -0.5)))
	Vr.sim_input(VrRules.RIGHT, &"trigger", 1.0)
	_frame()
	assert_false(Vr.input.drawing, "too far from the bow: the trigger's usual tap")
	Vr.sim_input(VrRules.RIGHT, &"trigger", 0.0)


func _swing_once() -> void:
	Vr.sim_hand(VrRules.RIGHT, Transform3D(Basis(), Vector3(0.4, 1.3, -0.4)))
	_frame(0.02)
	Vr.sim_hand(VrRules.RIGHT, Transform3D(Basis(), Vector3(-0.2, 1.1, -0.5)))   # 0.6 m in 0.02 s: a hard swing
	_frame(0.02)
	Vr.sim_hand(VrRules.RIGHT, Transform3D(Basis(), Vector3(-0.2, 1.1, -0.5)))
	_frame(0.02)


func test_waving_without_a_melee_weapon_attacks_nothing() -> void:
	_swing_once()
	assert_eq(Vr.input.swings, 0, "owner #128: only a melee weapon in the hand is swung; waving never punches")


func test_a_swing_attacks_once_and_waits_for_the_weapons_cooldown() -> void:
	Profile.data.settings[VrRules.SWING] = true
	var interactor := p.get_node("BlockInteractor") as BlockInteractor
	interactor.hotbar[0] = ItemIds.SWORD
	interactor.select_slot(0)
	_swing_once()
	assert_eq(Vr.input.swings, 1, "one swing, one attack")
	_swing_once()
	assert_eq(Vr.input.swings, 1, "the sword's cooldown: the next swing too soon does nothing")


func test_vr_pose_is_written_in_vr_and_nods_with_the_head() -> void:
	Vr.sim_head(Transform3D(Basis.from_euler(Vector3(-0.5, 0.0, 0.0)), Vector3(0, 1.6, 0)))   # looking down: a nod
	_frame()
	assert_eq(p.vr_pose.size(), VrPoseRules.SIZE)
	var pose := VrPoseRules.decode(p.vr_pose, CameraRig.HEAD_HEIGHT, 1.0)
	assert_almost_eq((pose.head as Transform3D).basis.get_euler().x, -0.5, 0.03, "the nod goes out")
	Vr.simulate(false)
	p._process(0.016)
	assert_true(p.vr_pose.is_empty(), "off VR: nothing")


func test_a_remote_vr_player_turns_its_head_floats_its_hands_and_has_the_mark() -> void:
	var other: Player = load("res://entities/player/player.tscn").instantiate()
	other.name = "7"
	add_child_autofree(other)
	other.global_position = Vector3(5.5, 80, 0.5)
	var head := Transform3D(Basis.from_euler(Vector3(0.4, 0.3, 0.0)), Vector3(0, 1.6, 0))
	var wave := Transform3D(Basis(), Vector3(0.4, 1.9, -0.2))   # the right hand up: a wave
	other.vr_pose = VrPoseRules.encode(head, Transform3D(Basis(), Vector3(-0.3, 1.1, -0.3)), wave, Vector4(0, 0, 0.2, 0.0),
		CameraRig.HEAD_HEIGHT, 1.0)
	other._process(0.016)
	var body := other.get_node_or_null("VrBody") as VrBody
	assert_not_null(body, "a VR body on the other game")
	body.step(0.0)
	var right := body.hands[VrRules.RIGHT] as VrHandModel
	assert_true(right.visible)
	var want := Transform3D(Basis(Vector3.UP, other.avatar.rotation.y), other.global_position) * wave
	assert_almost_eq(right.global_position.distance_to(want.origin), 0.0, 0.02, "its hand where its controller is")
	var blocky := other.avatar as BlockyAvatar
	assert_almost_eq(blocky.head_anchor().rotation.x, 0.4, 0.03, "its head nods")
	for arm in blocky.arms():
		assert_false(arm.visible, "the arms fold away")
	assert_true(NameTag.vr_marked("Mia", true).contains("VR"), "the VR mark")
	assert_eq(NameTag.vr_marked("Mia", false), "Mia")
	other.vr_pose = PackedByteArray()   # the headset off
	other._process(0.016)
	await get_tree().process_frame
	assert_null(other.get_node_or_null("VrBody"), "no pose: the body goes")
	for arm in blocky.arms():
		assert_true(arm.visible, "the arms back")
	assert_eq(blocky.head_anchor().rotation, Vector3.ZERO)


func test_the_mirror_shows_the_avatar_and_only_in_the_mirror() -> void:
	Vr.set_mirror(true)
	_frame()
	assert_true(Vr.mirror_shown())
	var head := Vr.head_transform()
	var glass := Vr.mirror.glass.global_transform
	assert_almost_eq(Vector2(glass.origin.x, glass.origin.z).distance_to(Vector2(head.origin.x, head.origin.z)),
		VrMirror.AHEAD, 0.05, "1.6 m ahead")
	assert_gt(glass.basis.z.dot((head.origin - glass.origin).normalized()), 0.9, "facing the child")
	assert_true(p.avatar.visible, "the avatar shows")
	for m: Node in p.avatar.find_children("*", "VisualInstance3D", true, false):
		assert_eq((m as VisualInstance3D).layers, VrPhotoCamera.SELF_LAYER)
	assert_eq(Vr.camera.cull_mask & VrPhotoCamera.SELF_LAYER, 0, "never from inside the head")
	var n := glass.basis.z.normalized()
	var mirrored := head.origin - n * 2.0 * (head.origin - glass.origin).dot(n)
	assert_almost_eq(Vr.mirror.camera.global_position.distance_to(mirrored), 0.0, 0.01, "the eye through the glass")
	assert_not_null(p.get_node_or_null("VrBody"), "its head turns as the child's does")
	Vr.set_mirror(false)
	_frame()
	assert_false(p.avatar.visible, "first person again")
	for m: Node in p.avatar.find_children("*", "VisualInstance3D", true, false):
		assert_ne((m as VisualInstance3D).layers, VrPhotoCamera.SELF_LAYER)


func test_a_race_or_a_round_refuses_a_teleport() -> void:
	var at := Vector3(0.5, 80, -3.5)
	assert_false(p.vr_teleport_refused(at))
	var courses := CourseDirector.new()
	add_child_autofree(courses)
	courses.player = p
	courses.state = {"on": true}
	assert_true(p.vr_teleport_refused(at), "racing a course: checkpoints are walked")
	courses.state = {}
	assert_false(p.vr_teleport_refused(at))
	var games := GamesDirector.new()
	add_child_autofree(games)
	games.kind = GameRules.STORM_RUN
	assert_false(p.vr_teleport_refused(at), "no round on")
	games.kind = GameRules.HIDE_SEEK
	games.hide.phase = HideSeekRound.Phase.SEEKING
	assert_true(games.running())
	assert_true(p.vr_teleport_refused(at), "a round of hide and seek on: no teleport")
	games.hide.phase = HideSeekRound.Phase.COUNTING
	assert_true(p.vr_teleport_refused(at), "nor while the seeker counts")
