extends GutTest
## Owner #84: on a PC the HUD is a PC game's: no thumb buttons or stick (the keyboard and the mouse, the KEYS card), the
## PC-sized canvas (the window's content scale 0.8: 1600 × 900 on a 1920 × 1080 screen), and the hearts, the gold, the
## name, the hotbar and the lines above them on the screen and clear of each other, in Sandbox and in Survivor.

const SCREENS: Array[Vector2i] = [Vector2i(1920, 1080), Vector2i(1366, 768)]

var _window_size: Vector2i
var _mode_before: StringName


class AirWorld:
	extends WorldService

	func get_block(_pos: Vector3i) -> int:
		return BlockIds.AIR


func before_all() -> void:
	_window_size = get_window().size
	_mode_before = Game.mode


func after_all() -> void:
	get_window().size = _window_size
	get_window().content_scale_factor = 1.0
	Game.mode = _mode_before


func _hud(mode: StringName, screen: Vector2i) -> Hud:
	get_window().size = screen
	PlatformRules.apply_ui_scale(get_window(), {PlatformRules.WEB: true, PlatformRules.WEB_WINDOWS: true})
	Game.mode = mode
	var w := AirWorld.new()
	autofree(w)
	var p: Player = load("res://entities/player/player.tscn").instantiate()
	p.name = str(multiplayer.get_unique_id())
	p.world = w
	add_child_autofree(p)
	p.set_physics_process(false)
	p.viewer.free()
	var hud := Hud.new()
	add_child_autofree(hud)
	hud.setup(p, "Kid", false, true)   # a PC: no touch controls, FPS on (the most crowded)
	hud.add_health_controls()
	hud.add_secret_controls(null)
	hud.show_difficulty_badge(DifficultyRules.BRAVE)
	hud.add_game_clock()
	hud.game_clock.show_build(DayCycle.NOON, 3, 5, ShelterRules.OPEN)
	await wait_process_frames(3)
	return hud


func test_a_pc_hud_has_no_thumb_buttons_and_everything_fits() -> void:
	for screen in SCREENS:
		for mode: StringName in [ModeRules.SANDBOX, ModeRules.SURVIVOR]:
			var hud := await _hud(mode, screen)
			var what := "%s %s" % [mode, screen]
			var view := Rect2(Vector2.ZERO, hud.get_viewport_rect().size)
			assert_almost_eq(view.size.y, 900.0, 1.0, "%s: the PC canvas" % what)
			assert_false(hud.joystick.is_visible_in_tree(), "%s: no stick" % what)
			assert_false(hud.jump_button.is_visible_in_tree(), "%s: no JUMP button (Space)" % what)
			assert_true(hud.hotbar.is_visible_in_tree(), "%s: the hotbar" % what)
			var parts := {"hotbar": hud.hotbar, "hearts": hud.hearts, "gold": hud.gold_counter,
				"name": hud.username_label, "fps": hud.fps_label, "brave": hud.brave_badge, "game_clock": hud.game_clock}
			for key: String in parts:
				var c := parts[key] as Control
				if not c.is_visible_in_tree():
					continue
				var r := c.get_global_rect()
				assert_true(view.encloses(r), "%s: the %s is on the screen (%s)" % [what, key, r])
				for other: String in parts:
					var o := parts[other] as Control
					if other > key and o.is_visible_in_tree():
						assert_false(r.intersects(o.get_global_rect()), "%s: the %s is clear of the %s" % [what, key, other])
