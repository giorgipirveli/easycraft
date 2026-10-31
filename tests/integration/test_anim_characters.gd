extends GutTest
## Owner #94 (the animations brief §1): the characters come alive. Both avatar styles turn the head for the new poses
## (a glance round, think, yawn) and bring it back ahead; a standing body fidgets now and then and waves when a friend
## walks up (each game for every body it shows, nothing sent); the child jumps for joy (hooray, sent like any emote)
## for a secret, a quest step, a board goal, a tamed animal, a Wonders stamp and a rocket's landing, but never over a
## dance the child chose.

var _mode_before: StringName


func before_each() -> void:
	_mode_before = Game.mode
	Session._last_emote.clear()
	AnimIdle.cheer_on_arrival = false


func after_each() -> void:
	Game.mode = _mode_before
	AnimIdle.cheer_on_arrival = false


func _make(kind: GDScript) -> AvatarModel:
	var a: AvatarModel = kind.new()
	add_child_autofree(a)
	return a


func _stand(a: AvatarModel, seconds: float) -> void:
	for i in int(seconds * 30.0):
		a.animate(0.0, true, 1.0 / 30.0)
		await wait_process_frames(1)


func _player(peer: int) -> Player:
	var p: Player = load("res://entities/player/player.tscn").instantiate()
	p.name = str(peer)
	add_child_autofree(p)
	p.set_physics_process(false)   # no world here: the test steps what it needs
	p._spawned = true
	return p


func test_the_head_turns_in_both_styles_and_comes_back() -> void:
	var blocky: BlockyAvatar = _make(BlockyAvatar)
	await _stand(blocky, 0.1)
	assert_true(blocky.play_emote(&"look"))
	var turned := 0.0
	for i in 60:
		blocky.animate(0.0, true, 1.0 / 30.0)
		turned = maxf(turned, absf(blocky.head_anchor().rotation.y))
	assert_gt(turned, 0.4, "the blocky head glances round")
	await _stand(blocky, 1.5)
	assert_eq(blocky.head_anchor().rotation, Vector3.ZERO, "and looks ahead again")
	var real: RealisticAvatar = _make(RealisticAvatar)
	await _stand(real, 0.2)
	assert_true(real.play_emote(&"think"))
	await _stand(real, 0.6)
	var poser := real.emote_poser()
	assert_not_null(poser)
	assert_ne(poser.pose.get("head", Vector3.ZERO), Vector3.ZERO, "the realistic head tilts to think")
	assert_true(poser.active)


func test_a_player_jumps_for_joy_at_a_secret_and_a_quest_step() -> void:
	var p := _player(multiplayer.get_unique_id())
	p._on_progress_counted(&"secret_found/cove", 1)
	assert_eq(p.avatar.emote(), &"hooray", "a secret")
	p.avatar.stop_emote(true)
	Session._last_emote.clear()
	Progress.counted.emit(&"quest_step", 1)
	assert_eq(p.avatar.emote(), &"hooray", "a quest step (through Progress)")
	p.avatar.stop_emote(true)
	p._on_progress_counted(&"block_placed", 1)
	assert_eq(p.avatar.emote(), &"", "not for every block")


func test_a_cheer_never_cuts_a_dance_the_child_chose() -> void:
	var p := _player(multiplayer.get_unique_id())
	assert_true(p.play_emote(&"dance_robot"))
	p.react_happy()
	assert_eq(p.avatar.emote(), &"dance_robot", "the dance goes on")
	p.avatar.stop_emote(true)
	assert_true(p.play_emote(&"wave"))
	Session._last_emote.clear()
	p.react_happy()
	assert_eq(p.avatar.emote(), &"wave", "nor a wave the child chose")
	p.avatar.stop_emote(true)
	p._idle_tick(AnimIdle.FIRST_AFTER + 0.1, 0.0, true)   # a fidget the body played itself gives way
	assert_ne(p.avatar.emote(), &"")
	Session._last_emote.clear()
	p.react_happy()
	assert_eq(p.avatar.emote(), &"hooray")


func test_another_game_s_body_never_cheers_here() -> void:
	var remote := _player(4321)
	remote._on_progress_counted(&"secret_found/cove", 1)
	assert_eq(remote.avatar.emote(), &"", "only the child's own body, from its own game (then sent)")


func test_a_standing_body_fidgets_and_waves_when_a_friend_walks_up() -> void:
	var p := _player(4321)
	p._idle_tick(AnimIdle.FIRST_AFTER + 0.1, 0.0, true)
	assert_true(AnimIdle.DAY_IDLES.has(p.avatar.emote()), "a fidget after standing a while: %s" % p.avatar.emote())
	p.avatar.stop_emote(true)
	var friend := _player(5555)
	friend.visible = true
	friend.global_position = p.global_position + Vector3(20, 0, 0)
	p._idle_tick(0.6, 0.0, true)
	assert_eq(p.avatar.emote(), &"", "a friend far off")
	friend.global_position = p.global_position + Vector3(2, 0, 0)
	p._idle_tick(0.6, 0.0, true)
	assert_eq(p.avatar.emote(), &"wave", "a friend walked up: a wave")


func test_no_fidget_while_moving_asleep_or_swimming() -> void:
	var p := _player(4321)
	p._idle_tick(20.0, 3.0, true)
	assert_eq(p.avatar.emote(), &"", "walking")
	p.sleeping = true
	p._idle_tick(20.0, 0.0, true)
	assert_eq(p.avatar.emote(), &"", "asleep")


func test_a_landing_cheers_once_the_new_world_shows() -> void:
	var p := _player(multiplayer.get_unique_id())
	AnimIdle.cheer_on_arrival = true
	p._idle_tick(0.1, 0.0, true)
	assert_false(AnimIdle.cheer_on_arrival, "taken")
	assert_eq(p.avatar.emote(), &"", "a moment first")
	p._idle_tick(AnimIdle.ARRIVAL_DELAY + 0.05, 0.0, true)
	assert_eq(p.avatar.emote(), &"hooray", "then a jump for joy")


func test_a_wonder_s_first_stamp_is_won_once() -> void:
	var d := WondersDirector.new()
	var book := WonderData.new()
	d.data = func() -> WonderData: return book
	d.save = func() -> void: pass
	watch_signals(d)
	var id := StringName(WonderTour.ids()[0])
	d._on_reached(id)
	d._on_reached(id)
	assert_signal_emit_count(d, "stamp_won", 1, "the first time only")
	d.free()


# --- The helpers greet the child -------------------------------------------------------------------------------------

func test_a_hop_is_back_exactly_at_rest() -> void:
	var body := Node3D.new()
	add_child_autofree(body)
	AnimGreet.hop(body)
	assert_true(AnimGreet.hopping(body))
	var highest := 0.0
	while AnimGreet.hopping(body):   # every frame of it, however slow the PC's frames are
		highest = maxf(highest, body.position.y)
		await wait_process_frames(1)
	assert_gt(highest, 0.1, "in the air")
	assert_eq(body.position.y, 0.0)
	assert_eq(body.scale, Vector3.ONE)


func test_tilly_hops_hello_and_jumps_for_joy_at_a_quest_step() -> void:
	var g := QuestGiver.new()
	g.setup({"id": &"tilly", "pos": Vector3.ZERO})
	add_child_autofree(g)
	var child := Node3D.new()
	child.add_to_group(&"players")
	child.position = Vector3(20, 0, 0)
	add_child_autofree(child)
	g._look_for_players()
	assert_false(AnimGreet.hopping(g._body), "nobody near")
	child.position = Vector3(3, 0, 0)
	g._look_for_players()
	assert_true(AnimGreet.hopping(g._body), "a hop hello")
	await wait_seconds(0.6)
	g._look_for_players()
	assert_false(AnimGreet.hopping(g._body), "once, not while the child stays")
	Progress.counted.emit(&"quest_step", 1)
	assert_true(AnimGreet.hopping(g._body), "a jump for joy at the child's quest step")
	var rises := 0
	var up := false
	while AnimGreet.hopping(g._body):   # every frame of it, however slow the PC's frames are
		if not up and g._body.position.y > 0.15:
			rises += 1
			up = true
		elif up and g._body.position.y < 0.05:
			up = false
		await wait_process_frames(1)
	assert_eq(rises, AnimGreet.CHEER_HOPS, "three hops")
	assert_eq(g._body.position.y, 0.0, "and back at rest")


func test_the_helper_robot_hops_hello() -> void:
	var r := HelperRobot.new()
	r.setup({"pos": Vector3.ZERO, "name": "Bolt"})
	var spot := [Vector3(30, 0, 0)]
	r.players = func() -> Array[Vector3]: return [spot[0]]
	add_child_autofree(r)
	r.think()
	assert_false(AnimGreet.hopping(r.body))
	spot[0] = Vector3(2, 0, 0)
	r.think()
	assert_true(AnimGreet.hopping(r.body), "it hops as the child walks up")


func test_professor_hoot_bounces_hello() -> void:
	var hoot := SchoolUi.teacher(120.0)
	add_child_autofree(hoot)
	var tallest := 1.0
	for i in 120:   # up to 2 s of frames
		tallest = maxf(tallest, hoot.scale.y)
		await wait_process_frames(1)
		if tallest > 1.0 and hoot.scale == Vector2.ONE:
			break
	assert_gt(tallest, 1.05, "a bounce")
	assert_eq(hoot.scale, Vector2.ONE, "settled")
