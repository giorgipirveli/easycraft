extends GutTest
## HELP UP and GET UP on the screen (M4 Wave 2, Agent E; spec §17.5): HELP UP shows near a teammate
## who waits for help and holding it asks the host (a ring fills); the waiting player sees kind words
## and GET UP; both are big, clear of the other buttons, and never build behind them.

const SCREEN := Vector2(1280, 720)
const SPOT := Vector3(3.5, 10.0, -4.5)

var world: WorldService
var me: Player
var pip: Player
var hud: Hud
var director: KnockoutDirector
var _mode_before: StringName


static func _rect(c: Control) -> Rect2:
	var anchor := Vector2(c.anchor_left, c.anchor_top) * SCREEN
	return Rect2(anchor + Vector2(c.offset_left, c.offset_top), Vector2(c.offset_right - c.offset_left, c.offset_bottom - c.offset_top))


func before_each() -> void:
	_mode_before = Game.mode
	Game.mode = ModeRules.SURVIVOR
	world = load("res://world/world.tscn").instantiate()
	world.setup("", 42)
	add_child_autofree(world)
	me = _player(str(multiplayer.get_unique_id()), SPOT + Vector3(2, 0, 0))
	pip = _player("7", SPOT)
	hud = Hud.new()
	add_child_autofree(hud)
	hud.player = me
	director = KnockoutDirector.new()
	director.name = "Knockout"
	director.block_at = func(c: Vector3i) -> int: return BlockIds.STONE if c.y <= 9 else BlockIds.AIR
	add_child_autofree(director)
	director.setup_local(me, hud)
	await get_tree().physics_frame


func after_each() -> void:
	Game.mode = _mode_before
	Session.survivor_reset()


func _player(node_name: String, at: Vector3) -> Player:
	var p: Player = load("res://entities/player/player.tscn").instantiate()
	p.name = node_name
	p.world = world
	add_child_autofree(p)
	p.viewer.free()
	p.set_physics_process(false)
	p.global_position = at
	return p


func _frame() -> void:
	director._scan = 0.0
	director._process(0.05)


func test_the_buttons_are_big_and_clear_of_the_others() -> void:
	for b: TouchButton in [hud.help_button, hud.get_up_button]:
		var r := _rect(b)
		assert_gte(r.size.x, 135.0)
		assert_gte(r.size.y, 64.0)
		assert_true(Rect2(Vector2.ZERO, SCREEN).encloses(r), "on the screen")
		for other: Control in [hud.jump_button, hud.hotbar, hud.attack_button, hud.fly_down_button]:
			assert_false(r.intersects(_rect(other)), "clear of %s" % other.name)
		assert_has(hud.look_area.blockers, b, "a hold never builds behind it")
	assert_false(hud.help_button.visible)
	assert_false(hud.get_up_button.visible)


func test_help_up_shows_near_a_teammate_who_waits_and_holding_it_fills_the_ring() -> void:
	_frame()
	assert_false(hud.help_button.visible, "nobody needs help")
	Session.hurt_player(pip.peer_id, Health.MAX_HP + 5, Vector3.ZERO)
	_frame()
	assert_true(hud.help_button.visible, "Pip waits for help")
	assert_eq(hud.help_button.text, ReviveRules.HELP_BUTTON)
	hud.help_button.pressed.emit()
	assert_eq(director.helper_of(pip.peer_id), me.peer_id, "asked the host (this game is the host here)")
	director.helping[pip.peer_id].since = Time.get_ticks_msec() - 1500
	_frame()
	assert_almost_eq(hud.help_ring.progress, 0.5, 0.1, "half full after 1.5 s")
	assert_true(hud.help_ring.visible)
	hud.help_button.released.emit()
	_frame()
	assert_eq(director.helper_of(pip.peer_id), 0, "let go")
	assert_false(hud.help_ring.visible)


func test_walking_away_hides_help_up_and_lets_go() -> void:
	Session.hurt_player(pip.peer_id, Health.MAX_HP + 5, Vector3.ZERO)
	_frame()
	hud.help_button.pressed.emit()
	me.global_position = SPOT + Vector3(ReviveRules.REACH + 2, 0, 0)
	_frame()
	assert_false(hud.help_button.visible)
	assert_eq(director.helper_of(pip.peer_id), 0)


func test_the_waiting_player_sees_kind_words_and_get_up() -> void:
	Session.hurt_player(me.peer_id, Health.MAX_HP + 5, Vector3.ZERO)
	_frame()
	assert_true(director.is_waiting(me.peer_id), "Pip is near")
	assert_true(hud.get_up_button.visible)
	assert_eq(hud.knockout_overlay.tip_text(), ReviveRules.WAITING, "in the fade, where the tip was")
	assert_false(hud.help_button.visible, "no helping while down")
	hud.get_up_button.pressed.emit()
	director.advance(0.1)
	assert_eq(me.health.hp, Health.MAX_HP, "up now, the usual way")
	_frame()
	assert_false(hud.get_up_button.visible)


func test_while_a_friend_helps_the_words_say_so_and_get_up_waits() -> void:
	Session.chat_names[pip.peer_id] = "Pip"
	Session.hurt_player(me.peer_id, Health.MAX_HP + 5, Vector3.ZERO)
	director.request_revive(pip.peer_id, me.peer_id, true)
	_frame()
	assert_eq(hud.knockout_overlay.tip_text(), ReviveRules.helping_you("Pip"))
	assert_true(hud.help_ring.visible, "the ring fills for the one being helped too")
	assert_false(hud.get_up_button.visible, "no GET UP while a friend helps")
	Session.chat_names.erase(pip.peer_id)
