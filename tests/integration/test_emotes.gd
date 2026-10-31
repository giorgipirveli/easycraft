extends GutTest
## M3 Task 9: emotes and dances on both avatar styles, the player's emote (played here, sent through
## the host), other players' emotes arriving over LAN, and the victory celebration after a won wave
## or boss (Player.celebrate / Session.celebrate_all, called by M2 Tasks 9-10).

var _mode_before: StringName
var _owned_before: Array[String]


func before_each() -> void:
	_mode_before = Game.mode
	_owned_before = Profile.data.cosmetics.duplicate()
	Session._last_emote.clear()


func after_each() -> void:
	Game.mode = _mode_before
	Profile.data.cosmetics = _owned_before


func _make(kind: GDScript) -> AvatarModel:
	var a: AvatarModel = kind.new()
	add_child_autofree(a)
	return a


func _name(a: AvatarModel) -> String:
	return a.get_script().get_global_name()


## Runs `a` for `seconds` at 30 fps standing still (on the ground), letting the skeleton follow.
func _stand(a: AvatarModel, seconds: float) -> void:
	for i in int(seconds * 30.0):
		a.animate(0.0, true, 1.0 / 30.0)
		await wait_process_frames(1)


func _player(peer: int) -> Player:
	var p: Player = load("res://entities/player/player.tscn").instantiate()
	p.name = str(peer)
	add_child_autofree(p)
	return p


func test_wave_raises_the_right_hand_in_both_styles() -> void:
	for a in [_make(BlockyAvatar), _make(RealisticAvatar)]:
		await _stand(a, 0.2)
		var rest: Vector3 = a.to_local(a.hand().global_position)
		assert_true(a.play_emote(&"wave"))
		assert_eq(a.emote(), &"wave")
		await _stand(a, 0.6)
		var up: Vector3 = a.to_local(a.hand().global_position)
		assert_gt(up.y, rest.y + 0.5, "%s: the hand goes up to wave (%.2f -> %.2f)" % [_name(a), rest.y, up.y])
		assert_gt(up.y, 1.5, "%s: above the shoulder" % _name(a))


func test_an_unknown_emote_does_nothing() -> void:
	var a := _make(BlockyAvatar)
	assert_false(a.play_emote(&"moonwalk"))
	assert_eq(a.emote(), &"")


func test_walking_away_ends_an_emote_and_the_body_comes_back() -> void:
	for a in [_make(BlockyAvatar), _make(RealisticAvatar)]:
		a.play_emote(&"sit")
		await _stand(a, 0.8)
		assert_lt(a.body_pivot().position.y, 0.6, "%s sits down" % _name(a))
		for i in 20:
			a.animate(4.0, true, 1.0 / 30.0)
		assert_eq(a.emote(), &"", "%s: running ends it" % _name(a))
		assert_almost_eq(a.body_pivot().position.y, 0.9, 0.001, "%s: standing again" % _name(a))
		assert_almost_eq(a.body_pivot().rotation.y, 0.0, 0.001)


func test_a_jump_or_sleep_ends_an_emote_at_once() -> void:
	for a in [_make(BlockyAvatar), _make(RealisticAvatar)]:
		a.play_emote(&"dance_star")
		await _stand(a, 0.5)
		a.play_jump(1)
		assert_eq(a.emote(), &"")
		assert_almost_eq(a.body_pivot().rotation.y, 0.0, 0.001, "%s: no spin left over" % _name(a))
		a.play_emote(&"dance_hop")
		await _stand(a, 0.3)
		a.set_pose(AvatarModel.POSE_SLEEP)
		assert_eq(a.emote(), &"", "sleeping ends it")
		assert_false(a.play_emote(&"wave"), "no emotes in bed")
		a.set_pose(AvatarModel.POSE_STAND)


func test_a_one_shot_emote_ends_by_itself_and_a_dance_keeps_going() -> void:
	var a := _make(BlockyAvatar)
	a.play_emote(&"thumbs_up")
	for i in int((EmotePoses.duration(&"thumbs_up") + 0.5) * 30.0):
		a.animate(0.0, true, 1.0 / 30.0)
	assert_eq(a.emote(), &"", "the thumbs up is over")
	a.play_emote(&"dance_robot")
	for i in 300:
		a.animate(0.0, true, 1.0 / 30.0)
	assert_eq(a.emote(), &"dance_robot", "still dancing after 10 s")


func test_the_realistic_emote_uses_a_skeleton_modifier_only_while_emoting() -> void:
	var a := _make(RealisticAvatar) as RealisticAvatar
	await _stand(a, 0.1)
	assert_false(a.emote_poser().active)
	a.play_emote(&"cheer")
	await _stand(a, 0.4)
	assert_true(a.emote_poser().active)
	assert_almost_eq(a.emote_poser().influence, 1.0, 0.01)
	for i in 30:
		a.animate(5.0, true, 1.0 / 30.0)
	assert_false(a.emote_poser().active, "off again")


func test_the_player_plays_its_own_emote_and_the_host_hears_it() -> void:
	var p := _player(multiplayer.get_unique_id())
	p._spawned = true
	watch_signals(Session)
	assert_true(p.play_emote(&"wave"))
	assert_eq(p.avatar.emote(), &"wave")
	assert_signal_emitted_with_parameters(Session, "emote_played", [p.peer_id, &"wave"])
	assert_true(p.play_emote(&"cheer"), "a second emote plays here at once")
	assert_eq(p.avatar.emote(), &"cheer")
	assert_signal_emit_count(Session, "emote_played", 1, "but the host doesn't send emotes faster than its cooldown")


func test_a_player_that_is_not_spawned_or_asleep_cannot_emote() -> void:
	var p := _player(multiplayer.get_unique_id())
	assert_false(p.play_emote(&"wave"), "not spawned yet")
	p._spawned = true
	p.sleeping = true
	assert_false(p.play_emote(&"wave"), "asleep")


func test_another_players_emote_arrives_and_plays_on_its_body() -> void:
	var remote := _player(4321)
	watch_signals(Session)
	Session._rpc_emote(4321, "dance_hop")
	assert_eq(remote.avatar.emote(), &"dance_hop")
	assert_signal_emitted_with_parameters(Session, "emote_played", [4321, &"dance_hop"])
	Session._rpc_emote(4321, "self_destruct")
	assert_eq(remote.avatar.emote(), &"dance_hop", "unknown emotes from the network are ignored")


func test_the_host_checks_emotes_and_limits_spam() -> void:
	assert_true(Session.accept_emote(77, &"wave", 10_000))
	assert_false(Session.accept_emote(77, &"wave", 10_100), "too soon")
	assert_true(Session.accept_emote(78, &"wave", 10_100), "another player is fine")
	assert_true(Session.accept_emote(77, &"cheer", 10_000 + Session.EMOTE_COOLDOWN_MS))
	assert_false(Session.accept_emote(79, &"ban_everyone", 20_000), "unknown")


func test_the_host_plays_a_guests_emote_on_the_guests_body() -> void:
	var guest := _player(555)
	watch_signals(Session)
	Session._host_emote(555, &"laugh")
	assert_eq(guest.avatar.emote(), &"laugh")
	assert_signal_emitted_with_parameters(Session, "emote_played", [555, &"laugh"])


func test_a_bot_body_can_emote_too() -> void:
	## The hook for bots (M2 §12.14): any body shows an emote with show_emote, and emote_played tells
	## followers (bots, buddies) what to copy.
	var bot := _player(9001)
	bot.show_emote(&"dance_star")
	assert_eq(bot.avatar.emote(), &"dance_star")


func test_celebrate_dances_and_throws_confetti() -> void:
	var p := _player(4242)
	p.celebrate()
	assert_eq(p.avatar.emote(), &"victory")
	var confetti := p.get_parent().find_children("*", "CPUParticles3D", false, false)
	assert_gt(confetti.size(), 0, "a confetti burst")
	var burst := confetti[0] as CPUParticles3D
	assert_same(burst.mesh.surface_get_material(0), Fx.material(), "the shared particle material")
	assert_not_null(burst.color_initial_ramp, "many colours")
	assert_same(burst.color_initial_ramp, Celebration.confetti_colors(), "one shared gradient")


func test_celebrate_all_makes_every_player_celebrate() -> void:
	var a := _player(multiplayer.get_unique_id())
	var b := _player(3131)
	watch_signals(Session)
	Session.celebrate_all()
	assert_eq(a.avatar.emote(), &"victory")
	assert_eq(b.avatar.emote(), &"victory")
	assert_signal_emitted(Session, "celebrated")


func test_the_first_survivor_win_earns_the_victory_dance() -> void:
	Game.mode = ModeRules.SURVIVOR
	Profile.data.cosmetics = [] as Array[String]
	var p := _player(multiplayer.get_unique_id())
	watch_signals(Session)
	p.celebrate()
	assert_true(AvatarUnlocks.is_owned("emote.victory", Profile.data.cosmetics))
	assert_signal_emitted(Session, "magic_feedback", "a 'New dance' message")


func test_sandbox_celebrations_earn_nothing() -> void:
	Game.mode = ModeRules.SANDBOX
	Profile.data.cosmetics = [] as Array[String]
	var p := _player(multiplayer.get_unique_id())
	p.celebrate()
	assert_false(AvatarUnlocks.is_owned("emote.victory", Profile.data.cosmetics), "Sandbox doesn't unlock items (§5.9)")
