extends GutTest
## M2 Task 9: the HUD for Totem waves. The wave line (top-centre above the toasts: a monster picture,
## "Wave 3 starts in 5…", then "Wave 3 — 5 left" and a bar for the time left) and the Totem's small
## picture panel ("Wave N" with START; after a wave that was not won, TRY AGAIN and TRY AN EASIER WAVE;
## the Stone Golem once wave 5 is won). Every choice goes to the host (Session.wave_request_start).

const SCREEN := Vector2(1280, 720)
const TOTEM := Vector3(0.5, 30, 0.5)

var _mode_before: StringName
var _player: Player
var _totem: Totem
var _asked: Array = []
var _boss_asked: Array = []


func before_each() -> void:
	_mode_before = Game.mode
	Game.mode = ModeRules.SURVIVOR
	_asked = []
	_boss_asked = []
	Session.wave_start_requested.connect(_on_start)
	Session.wave_boss_requested.connect(_on_boss)
	var world: WorldService = load("res://world/world.tscn").instantiate()
	world.setup("", 42)
	add_child_autofree(world)
	_player = load("res://entities/player/player.tscn").instantiate()
	_player.name = str(multiplayer.get_unique_id())
	_player.world = world
	add_child_autofree(_player)
	_player.viewer.free()
	_player.set_physics_process(false)
	_player.global_position = TOTEM + Vector3(0, 0, -3)
	_totem = Totem.new()
	_totem.setup({"pos": TOTEM, "yaw": 0.0})
	add_child_autofree(_totem)


func after_each() -> void:
	Session.wave_start_requested.disconnect(_on_start)
	Session.wave_boss_requested.disconnect(_on_boss)
	Game.mode = _mode_before


func after_all() -> void:
	for n in Audio.get_children():
		if n is AudioStreamPlayer:
			(n as AudioStreamPlayer).stop()


func _on_start(peer: int, wave: int) -> void:
	_asked.append([peer, wave])


func _on_boss(peer: int) -> void:
	_boss_asked.append(peer)


static func _state(phase: int, next: int = 1, wave: int = 0, left: int = 0, count: int = 0, lost: int = 0,
		boss: bool = false, time_left: float = 0.0, gentle: bool = false) -> Dictionary:
	return {"phase": phase, "next": next, "wave": wave, "left": left, "total": left, "count": count,
		"time_left": time_left, "lost": lost, "boss": boss, "gentle": gentle}


static func _rect(c: Control) -> Rect2:
	var anchor := Vector2(c.anchor_left, c.anchor_top) * SCREEN
	return Rect2(anchor + Vector2(c.offset_left, c.offset_top), Vector2(c.offset_right - c.offset_left, c.offset_bottom - c.offset_top))


func _hud() -> Hud:
	var hud := Hud.new()
	add_child_autofree(hud)
	hud.setup(_player, "Kid", false, false)
	return hud


# --- The wave line ---

func test_the_wave_line_shows_only_while_a_wave_counts_down_or_runs() -> void:
	var line := WaveLine.new()
	add_child_autofree(line)
	line.show_state(_state(WaveDirector.Phase.IDLE, 3))
	assert_false(line.visible)
	line.show_state(_state(WaveDirector.Phase.COUNTDOWN, 3, 3, 0, 5))
	assert_true(line.visible)
	assert_eq(line.text(), "Wave 3 starts in 5…")
	line.show_state(_state(WaveDirector.Phase.RUNNING, 3, 3, 9, 0, 0, false, 180.0))
	assert_eq(line.text(), "Wave 3 — 9 left")
	assert_almost_eq(line.time_share(), 1.0, 0.01, "a full time bar")
	line.show_state(_state(WaveDirector.Phase.RUNNING, 3, 3, 4, 0, 0, false, 45.0))
	assert_eq(line.text(), "Wave 3 — 4 left")
	assert_almost_eq(line.time_share(), 0.25, 0.01)
	line.show_state(_state(WaveDirector.Phase.IDLE, 4))
	assert_false(line.visible)


func test_the_time_bar_runs_down_between_messages() -> void:
	var line := WaveLine.new()
	add_child_autofree(line)
	line.show_state(_state(WaveDirector.Phase.RUNNING, 3, 3, 9, 0, 0, false, 90.0))
	line._process(9.0)
	assert_almost_eq(line.time_share(), 0.45, 0.01, "the host sends changes only; the bar keeps going")


func test_the_longest_lines_fit() -> void:
	var line := WaveLine.new()
	add_child_autofree(line)
	for s: Dictionary in [_state(WaveDirector.Phase.COUNTDOWN, 99, 99, 0, 5), _state(WaveDirector.Phase.RUNNING, 99, 99, 20)]:
		line.show_state(s)
		assert_lte(line.text_width(), line.text_room(), "\"%s\" fits" % line.text())


func test_the_wave_line_sits_top_centre_above_the_toasts_clear_of_the_hearts() -> void:
	var hud := _hud()
	var r := _rect(hud.wave_line)
	assert_almost_eq(r.get_center().x, SCREEN.x * 0.5, 1.0, "top-centre")
	assert_lte(r.end.y, 96.0, "above the toasts")
	assert_false(r.intersects(Rect2(Hud.HEARTS_POS, hud.hearts.bar_size())), "clear of the hearts")
	for other: Control in [hud.gold_counter, hud.pause_button, hud.potion_timers, hud.more_button, hud.fps_label]:
		assert_false(r.intersects(_rect(other)), "clear of %s" % other.get_class())
	assert_eq(hud.wave_line.mouse_filter, Control.MOUSE_FILTER_IGNORE, "never takes a tap")


# --- The Totem's panel ---

func test_a_tap_on_the_totem_opens_its_panel_with_the_wave_and_start() -> void:
	var hud := _hud()
	hud.show_wave_state(_state(WaveDirector.Phase.IDLE, 3))
	hud.palette.open()
	_player.get_node("BlockInteractor").totem_tapped.emit(_totem)
	var panel := hud.totem_panel
	assert_true(panel.visible)
	assert_false(hud.palette.visible, "one overlay at a time")
	assert_has(hud.look_area.blockers, panel, "touches on the panel never build behind it")
	assert_eq(panel.wave_text(), "Wave 3")
	assert_eq(panel.monster_count(), WaveRules.size(3, false))
	assert_eq(panel.reward_text(), "30")
	assert_true(panel.start_button.visible)
	assert_false(panel.again_button.visible)
	assert_false(panel.easier_button.visible)
	assert_false(panel.boss_button.visible)
	panel.start_button.pressed.emit()
	assert_eq(_asked, [[_player.peer_id, 3]], "the host decides")
	assert_false(panel.visible, "the countdown takes over")


func test_after_a_wave_not_won_it_offers_try_again_or_an_easier_wave() -> void:
	var panel := TotemPanel.new()
	add_child_autofree(panel)
	panel.player = _player
	panel.open(_totem, _state(WaveDirector.Phase.IDLE, 4, 0, 0, 0, 4))
	assert_false(panel.start_button.visible)
	assert_true(panel.again_button.visible)
	assert_true(panel.easier_button.visible)
	assert_eq(panel.again_button.text, WaveRules.TRY_AGAIN)
	assert_eq(panel.easier_button.text, WaveRules.TRY_EASIER)
	panel.easier_button.pressed.emit()
	assert_eq(_asked, [[_player.peer_id, 3]], "an easier wave is wave 3")
	panel.open(_totem, _state(WaveDirector.Phase.IDLE, 4, 0, 0, 0, 4))
	panel.again_button.pressed.emit()
	assert_eq(_asked.back(), [_player.peer_id, 4])


func test_wave_1_has_no_easier_wave() -> void:
	var panel := TotemPanel.new()
	add_child_autofree(panel)
	panel.player = _player
	panel.open(_totem, _state(WaveDirector.Phase.IDLE, 1, 0, 0, 0, 1))
	assert_true(panel.again_button.visible)
	assert_false(panel.easier_button.visible)


func test_the_same_buttons_look_the_same_size_so_easier_is_never_the_small_choice() -> void:
	var panel := TotemPanel.new()
	add_child_autofree(panel)
	panel.player = _player
	panel.open(_totem, _state(WaveDirector.Phase.IDLE, 4, 0, 0, 0, 4))
	assert_eq(panel.again_button.custom_minimum_size, panel.easier_button.custom_minimum_size, "equal buttons (G6)")
	assert_ne(panel.again_button.icon, null)
	assert_ne(panel.easier_button.icon, null)


func test_after_wave_5_the_totem_offers_the_stone_golem() -> void:
	var panel := TotemPanel.new()
	add_child_autofree(panel)
	panel.player = _player
	panel.open(_totem, _state(WaveDirector.Phase.IDLE, 6, 0, 0, 0, 0, true))
	assert_true(panel.start_button.visible, "wave 6 is still there")
	assert_true(panel.boss_button.visible)
	panel.boss_button.pressed.emit()
	assert_eq(_boss_asked, [_player.peer_id])
	assert_false(panel.visible)


func test_sandbox_waves_show_their_gentle_size_and_no_gold() -> void:
	Game.mode = ModeRules.SANDBOX
	var panel := TotemPanel.new()
	add_child_autofree(panel)
	panel.player = _player
	panel.open(_totem, _state(WaveDirector.Phase.IDLE, 9, 0, 0, 0, 0, false, 0.0, true))
	assert_eq(panel.monster_count(), 8)
	assert_eq(panel.reward_text(), "", "no gold in Sandbox")


func test_the_panel_closes_when_a_wave_starts_or_the_player_walks_away() -> void:
	var panel := TotemPanel.new()
	add_child_autofree(panel)
	panel.player = _player
	panel.open(_totem, _state(WaveDirector.Phase.IDLE, 2))
	panel.show_state(_state(WaveDirector.Phase.COUNTDOWN, 2, 2, 0, 5))
	assert_false(panel.visible, "someone else started it")
	panel.open(_totem, _state(WaveDirector.Phase.IDLE, 2))
	panel.check_reach()
	assert_true(panel.visible)
	_player.global_position = TOTEM + Vector3(0, 0, -20)
	panel.check_reach()
	assert_false(panel.visible)


func test_the_panel_is_centred_on_the_screen_and_closes_with_its_x() -> void:
	var panel := TotemPanel.new()
	add_child_autofree(panel)
	panel.player = _player
	panel.open(_totem, _state(WaveDirector.Phase.IDLE, 2))
	var r := panel.panel_rect(SCREEN)
	assert_true(Rect2(Vector2.ZERO, SCREEN).encloses(r))
	assert_almost_eq(r.get_center(), SCREEN * 0.5, Vector2(1, 1))
	panel.close_button.pressed.emit()
	assert_false(panel.visible)
