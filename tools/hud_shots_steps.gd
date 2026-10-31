extends Node
## The steps of tools/hud_shots.gd (a Node, so it may use the autoloads and the HUD's classes).

## The emulator's 20:9 canvas (2400 × 1080 shows 1600 × 720; a window that big may not fit the monitor)
## and a small 16:9 phone.
const SCREENS: Array[Vector2i] = [Vector2i(1600, 720), Vector2i(1334, 750)]


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var out := ProjectSettings.globalize_path("user://hud_shots")
	DirAccess.make_dir_recursive_absolute(out)
	var back := ColorRect.new()
	back.color = Color(0.36, 0.55, 0.42)   # a grassy stand-in for the world
	back.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(back)
	for screen in SCREENS:
		get_window().size = screen
		var p := _player()
		var hud := Hud.new()
		add_child(hud)
		hud.setup(p, "Kid", true, true)   # a phone's HUD, FPS on
		hud.interactor.set_slot_block(0, ItemIds.SWORD)
		hud.add_health_controls()
		hud.add_revive_controls()
		hud.add_sleep_controls()
		hud.add_secret_controls(null)
		hud.show_difficulty_badge(DifficultyRules.BRAVE)
		hud.show_sleep_button(true)
		hud.show_help(true, 0.0)
		hud.add_game_clock()   # M3 Task 22: Build to Survive's clock, a minute before the night, in a hut
		hud.game_clock.show_build(DayCycle.SUNSET - 50.0 * BuildRules.DAY_SPEED / DayCycle.LENGTH, 3, 5, ShelterRules.SAFE)
		await _shot(hud, out, "%dx%d_awake" % [screen.x, screen.y])
		hud.show_help(false, 0.0)
		hud.show_sleep_button(false)
		hud.more.open()
		await _shot(hud, out, "%dx%d_more" % [screen.x, screen.y])
		hud.more.close()
		_craft_page(hud)   # M3 Task 22: the palette's CRAFT tab (a crafting table nearby)
		await _shot(hud, out, "%dx%d_craft" % [screen.x, screen.y])
		hud.palette.visible = false
		hud._on_physics_mode_changed(PhysicsMode.Mode.FLY)
		await _shot(hud, out, "%dx%d_flying" % [screen.x, screen.y])
		hud._on_physics_mode_changed(PhysicsMode.Mode.NORMAL)
		hud.show_sleep_button(true, "WAKE UP")
		hud.set_sleeping(true)
		await get_tree().create_timer(1.2).timeout   # the sleep dim fades in
		await _shot(hud, out, "%dx%d_asleep" % [screen.x, screen.y])
		hud.free()
		p.free()
	var sheet := _Sheet.new()   # every picture a button can show, with its name
	sheet.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(sheet)
	await _shot(null, out, "icons")
	print("HUD_SHOT done: %s" % out)
	get_tree().quit()


## A player standing in empty air (the HUD's buttons need one), kept still.
func _player() -> Player:
	var w := _AirWorld.new()
	var p: Player = load("res://entities/player/player.tscn").instantiate()
	p.name = str(multiplayer.get_unique_id())
	p.world = w
	add_child(p)
	p.set_physics_process(false)
	p.viewer.free()
	p.visible = false
	return p


class _AirWorld:
	extends WorldService

	func get_block(_pos: Vector3i) -> int:
		return BlockIds.AIR


class _Sheet:
	extends Control

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.08, 0.1, 0.16))
		var font := get_theme_default_font()
		for i in HudIcons.SYMBOLS.size():
			var at := Vector2(24 + (i % 8) * 150, 24 + floori(i / 8.0) * 180)
			HudIcons.draw(self, HudIcons.SYMBOLS[i], Rect2(at, Vector2(120, 120)))
			draw_string(font, at + Vector2(0, 150), String(HudIcons.SYMBOLS[i]), HORIZONTAL_ALIGNMENT_CENTER, 120, 20)


func _shot(hud: Hud, dir: String, shot_name: String) -> void:
	for i in 4:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var path := "%s/%s.png" % [dir, shot_name]
	image.save_png(path)
	var buttons := hud.find_children("*", "TouchButton", true, false).size() if hud else 0
	print("HUD_SHOT %s %s buttons=%d" % [shot_name, image.get_size(), buttons])


## M3 Task 22: the Survivor palette's CRAFT page, with a few things in the bag and a crafting table nearby.
func _craft_page(hud: Hud) -> void:
	var inv := Inventory.new()
	for pair: Array in [[BlockIds.LOG, 2], [BlockIds.PLANKS, 5], [ItemIds.STICK, 1], [BlockIds.STONE, 3],
			[BlockIds.COAL, 1]]:
		inv.add(pair[0], pair[1])
	Session.my_inventory = inv
	hud.palette.counted = true
	hud.palette.craft_book.stations_provider = func() -> Dictionary:
		return {Recipes.HAND: true, Recipes.TABLE: true, Recipes.FURNACE: false}
	hud.palette.open()
	hud.palette.show_page(BlockPalette.CRAFT_PAGE)
