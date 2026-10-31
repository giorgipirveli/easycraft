extends Node
## The steps of tools/survivor_games_smoke.gd (spec §12.18–§12.20), in the real sandbox on real terrain:
## Build to Survive — a new world starts in the morning with the quick-start kit and the night clock; it has no
## Monster Totem (owner feedback #44); a plank hut built round the player through the host's edits is a shelter (a
## door opened is a gap), a monster at night can't see the player inside, the sunrise counts a night; crafting —
## planks and a crafting table by hand, a furnace at the table, glass at the furnace, the CRAFT page; a knock-out at
## night brings the morning and ends the run, and world.json keeps the game and the score. Monster Wave — a new
## arena: flat, the kit, the Totem in the middle, wave 1 by itself; each defeat pays the kill bonus with the combo
## (no coins); a cleared wave, then a breather; no building, no flying; a knock-out ends the run with gold for the
## time and the wave, the result panel and a best saved; PLAY AGAIN starts a new run.

const TIMEOUT := 240.0

var _t := 0.0
var _step := 0
var _wait := 0.0
var _fails: Array[String] = []
var _door := Vector3i.ZERO
var _gold := 0
var _to_arena := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Session.magic_feedback.connect(func(text: String) -> void: print("GAMES_SMOKE feedback: %s" % text))
	Game.start_world(ModeRules.SURVIVOR, true, DifficultyRules.NORMAL, 1, SurvivorGames.BUILD)


func _process(delta: float) -> void:
	_t += delta
	if _t > TIMEOUT:
		_check(false, "timeout at step %d" % _step)
		_finish()
		return
	var sandbox := get_tree().current_scene
	if sandbox == null or sandbox.get("player") == null or not (sandbox.player as Player).is_spawned():
		return
	if _to_arena and (sandbox.get("meta") as WorldMeta).mode != ModeRules.WAVE:
		return   # the arena is on its way
	if _wait > 0.0:
		_wait -= delta
		return
	_run_step(sandbox)


func _run_step(sandbox: Node) -> void:
	var p: Player = sandbox.player
	var hud: Hud = sandbox.hud
	var sky: SkyCycle = sandbox.sky
	var inv := Session.inventory_of(p.peer_id)
	var feet := ShelterRules.feet_cell(p.global_position)
	if _to_arena:
		_arena_step(sandbox, p, hud, inv)
		return
	var games: SurvivorGameDirector = sandbox.get_node("SurvivorGame")
	match _step:
		0:
			_check(Game.survivor_game == SurvivorGames.BUILD and (sandbox.meta as WorldMeta).game == SurvivorGames.BUILD, "a Build to Survive world")
			_check(inv.count(BlockIds.PLANKS) == 48 and inv.count(BlockIds.DOOR) == 2 and inv.count(BlockIds.LANTERN) == 1,
				"the quick-start kit: %s" % [inv.to_save()])
			var bar: Array[int] = (p.get_node("BlockInteractor") as BlockInteractor).hotbar
			_check(bar[7] == BlockIds.DOOR and bar[8] == BlockIds.LANTERN, "the doorway and the lantern on the hotbar: %s" % [bar])
			var left := BuildRules.seconds_to_night(sky.time)
			_check(left > 170.0 and left <= 180.0, "the first night in about 3:00 (%.1f s)" % left)
			_check(sky.game == SurvivorGames.BUILD, "the sky runs Build to Survive's clock")
			_check(hud.game_clock.visible and hud.game_clock.line().begins_with("Night in "), "the night clock: %s" % hud.game_clock.line())
			_check((sandbox.call("waves") as WaveDirector).totem() == null, "no Monster Totem in Survivor (#44)")
			_next(0.1)
		1:
			var cells: Array = []
			for dx in range(-1, 2):
				for dz in range(-1, 2):
					if dx != 0 or dz != 0:
						for dy in 2:
							cells.append([feet + Vector3i(dx, dy, dz), BlockIds.PLANKS])
					cells.append([feet + Vector3i(dx, 2, dz), BlockIds.PLANKS])
			_door = feet + Vector3i(1, 0, 0)
			for c: Array in cells:
				if c[0] == _door or c[0] == _door + Vector3i.UP:
					c[1] = BlockIds.DOOR
			_check(Session.request_set_blocks(cells), "a plank hut with a doorway, built through the host")
			_next(1.2)
		2:
			_check(games.shelter_of(p.peer_id) == ShelterRules.SAFE and p.sheltered, "inside the hut: sheltered (%s)" % games.shelter_of(p.peer_id))
			_check(Monster.visibility_of(p) == 0.0, "monsters can't see a sheltered player")
			Session.request_door(_door)
			_next(1.2)
		3:
			_check(games.shelter_of(p.peer_id) == ShelterRules.GAP and not p.sheltered, "the door open: a gap (%s)" % games.shelter_of(p.peer_id))
			Session.request_door(_door)
			sandbox.set_time_of_day(DayCycle.SUNSET + 0.005)
			_next(1.2)
		4:
			_check(games.shelter_of(p.peer_id) == ShelterRules.SAFE, "the door shut again: safe")
			_check(hud.game_clock.small_line() == "Safe inside!" and hud.game_clock.symbol() == &"home", "the clock says so at night: %s" % hud.game_clock.small_line())
			sandbox.summon_monster(MonsterRules.GOBLIN, 3, p.global_position + Vector3(4, 0, 0))
			_next(1.0)
		5:
			var seen := false
			for m: Monster in sandbox.get_node("Monsters").monsters():
				seen = seen or m.perceive() == p
			_check(not seen, "no monster sees the player in the hut")
			sandbox.set_time_of_day(DayCycle.SUNRISE + 0.001)
			_next(1.2)
		6:
			_check(int(games.record_of(p.peer_id).nights) == 1, "the sunrise counts a night: %s" % [games.record_of(p.peer_id)])
			inv.add(BlockIds.LOG, 2)
			Session.request_craft(&"planks")
			_check(inv.count(BlockIds.LOG) == 1, "planks by hand")
			Session.request_craft(&"crafting_table")
			_check(inv.count(BlockIds.CRAFTING_TABLE) == 1, "a crafting table by hand")
			var table := _free_cell(p, feet + Vector3i(2, 0, 0))
			Session.request_set_block(table, BlockIds.CRAFTING_TABLE)
			_check(p.world.get_block(table) == BlockIds.CRAFTING_TABLE, "the table stands next to the hut")
			inv.add(BlockIds.STONE, 8)
			var stone_before := inv.count(BlockIds.STONE)
			Session.request_craft(&"furnace")
			_check(inv.count(BlockIds.FURNACE) == 1 and inv.count(BlockIds.STONE) == stone_before - 8, "a furnace at the table")
			var furnace := _free_cell(p, feet + Vector3i(-2, 0, 0))
			Session.request_set_block(furnace, BlockIds.FURNACE)
			inv.add(BlockIds.SAND, 4)
			inv.add(BlockIds.COAL, 1)
			var glass_before := inv.count(BlockIds.GLASS)
			Session.request_craft(&"glass")
			_check(inv.count(BlockIds.GLASS) == glass_before + 4 and inv.count(BlockIds.COAL) == 0, "glass at the furnace, coal burnt")
			hud.palette.open()
			hud.palette.show_page(BlockPalette.CRAFT_PAGE)
			_next(0.3)
		7:
			var cards := hud.palette.craft_book.cards()
			_check(cards.size() == Recipes.LIST.size(), "the CRAFT page: %d cards" % cards.size())
			_check(not cards.is_empty() and cards[0].shines(), "what can be made shines first")
			hud.palette.visible = false
			sandbox.set_time_of_day(DayCycle.MIDNIGHT)
			_next(1.2)
		8:
			Session.hurt_player(p.peer_id, Health.MAX_HP * 3, p.global_position + Vector3(0, 0, 3))
			_check(p.knocked_out, "knocked out at night")
			_check(int(games.record_of(p.peer_id).nights) == 0 and int(games.record_of(p.peer_id).best_nights) == 1, "the run starts again, the best stays")
			_next(KnockoutRules.KO_TIME + 1.5)
		9:
			_check(not DayCycle.is_night(sky.time), "woke at home in the morning (t %.3f)" % sky.time)
			sandbox.save_world()
			var meta := WorldSaves.load_meta(Game.slot())
			_check(meta.game == SurvivorGames.BUILD and not meta.game_scores.is_empty(), "world.json keeps the game and the scores: %s" % [meta.game_scores])
			_to_arena = true
			_step = 0
			Game.start_world(ModeRules.WAVE, true, DifficultyRules.NORMAL, 1)


## Monster Wave (spec §12.20).
func _arena_step(sandbox: Node, p: Player, hud: Hud, inv: Inventory) -> void:
	var arena: ArenaDirector = sandbox.get_node("Arena")
	var waves: WaveDirector = sandbox.call("waves")
	match _step:
		0:
			_check(Game.mode == ModeRules.WAVE and (sandbox.meta as WorldMeta).mode == ModeRules.WAVE, "a Monster Wave arena")
			_check(p.world.generator_shape() is ArenaShape, "a flat arena world")
			_check(absf(p.global_position.y - ArenaShape.FLOOR) < 0.6, "standing on the arena floor (y %.2f)" % p.global_position.y)
			_check(inv.count(WeaponRules.TIERS[ItemIds.SWORD][1]) == 1 and inv.count(ItemIds.POTION_SPEED) == 2, "the arena kit: %s" % [inv.to_save()])
			_check(waves.totem() != null and waves.totem().global_position.distance_to(Vector3(0.5, ArenaShape.FLOOR, 0.5)) < 1.0,
				"the Totem in the middle")
			_check(arena.phase == ArenaDirector.Phase.READY and hud.game_clock.visible, "the run gets ready; the clock shows it: %s" % hud.game_clock.line())
			_check(not hud.physics_button.visible, "no WALK/FLY button in the arena")
			_next(ArenaRules.FIRST_DELAY + WaveRules.COUNTDOWN + 4.0)
		1:
			_check(arena.phase == ArenaDirector.Phase.WAVE and waves.wave == 1 and not waves.wave_monsters().is_empty(),
				"wave 1 came by itself (%d monsters)" % waves.wave_monsters().size())
			_gold = Profile.data.survivor_gold
			for i in 12:
				for m in waves.wave_monsters():
					m.take_hit(100000, p.global_position, Vector3.ZERO)
			_check(Profile.data.survivor_gold > _gold, "the kill bonus paid at once (+%d)" % (Profile.data.survivor_gold - _gold))
			_check((sandbox.get_node("Monsters") as MonsterDirector).coins().is_empty(), "no coins in the arena")
			_next(1.0)
		2:
			_check(arena.cleared == 1 and arena.phase == ArenaDirector.Phase.BREATHER, "wave 1 cleared, a breather")
			var cell := ShelterRules.feet_cell(p.global_position) + Vector3i(2, 0, 0)
			var before := p.world.get_block(cell)
			Session.request_set_block(cell, BlockIds.STONE)
			_check(p.world.get_block(cell) == before, "no building in the arena")
			p.set_physics_mode(PhysicsMode.Mode.FLY)
			_check(p.physics_mode == PhysicsMode.Mode.NORMAL, "no flying in the arena")
			_gold = Profile.data.survivor_gold
			Session.hurt_player(p.peer_id, Health.MAX_HP * 3, p.global_position + Vector3(0, 0, 3))
			_next(0.5)
		3:
			_check(arena.phase == ArenaDirector.Phase.OVER, "a knock-out ends the run")
			var paid := Profile.data.survivor_gold - _gold
			_check(paid == ArenaRules.run_gold(arena.run_time, 1, 1), "gold for the time and the wave: +%d (%.1f s)" % [paid, arena.run_time])
			_check(hud.arena_panel.visible and hud.arena_panel.title_text() == ArenaPanel.RUN_TITLE, "the result panel: %s" % hud.arena_panel.line_text())
			sandbox.save_world()
			var meta := WorldSaves.load_meta(Game.slot())
			_check(not meta.arena.is_empty(), "the best is saved: %s" % [meta.arena])
			hud.arena_panel.buttons()[0].pressed.emit()   # PLAY AGAIN
			_next(KnockoutRules.KO_TIME + 1.0)
		4:
			_check(arena.phase == ArenaDirector.Phase.READY and arena.cleared == 0, "PLAY AGAIN: a new run")
			_finish()


## `want`, or the first free cell beside it on the same level (air, not the player's).
func _free_cell(p: Player, want: Vector3i) -> Vector3i:
	for c: Vector3i in [want, want + Vector3i(0, 0, 1), want + Vector3i(0, 0, -1), want + Vector3i.UP]:
		if p.world.get_block(c) == BlockIds.AIR:
			return c
	return want


func _next(wait: float) -> void:
	_step += 1
	_wait = wait


func _check(ok: bool, what: String) -> void:
	print("GAMES_SMOKE %s %s" % ["ok" if ok else "FAIL", what])
	if not ok:
		_fails.append(what)


func _finish() -> void:
	print("GAMES_SMOKE result fails=%d" % _fails.size())
	set_process(false)
	get_tree().quit(1 if not _fails.is_empty() else 0)
