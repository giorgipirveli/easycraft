extends GutTest
## M3 Task 2 (spec §14.1, §5.3): the Sandstorm Desert's boss through the BossDirector. With the world's
## boss set to the Sand Serpent, the Totem's fight brings a SandSerpent with its team-sized health; the HUD
## bar names it and shows its face; a tired one says so; a win says "You beat the Sand Serpent!" and pays,
## opens the portal and resets the help like the Golem's (the same director code); /summon serpent works in
## Sandbox; the Totem's words name the serpent. The Golem is unchanged.

const FLOOR := 10
const TOTEM := Vector3(20.5, FLOOR, 3.5)

var _mode_before: StringName
var _gold_before := 0
var _universe_before := 1
var _toasts: Array = []


func before_each() -> void:
	_mode_before = Game.mode
	_gold_before = Profile.data.survivor_gold
	_universe_before = Profile.data.universe_unlocked
	Game.mode = ModeRules.SURVIVOR
	Profile.data.survivor_gold = 0
	_toasts.clear()
	Session.magic_feedback.connect(_on_toast)


func after_each() -> void:
	Session.magic_feedback.disconnect(_on_toast)
	Game.mode = _mode_before
	Profile.data.survivor_gold = _gold_before
	Profile.data.universe_unlocked = _universe_before
	Session.survivor_reset()
	Music.reset()


func after_all() -> void:
	for n in Audio.get_children():
		if n is AudioStreamPlayer3D:
			(n as AudioStreamPlayer3D).stop()


func _on_toast(text: String) -> void:
	_toasts.append(text)


func _flat(p: Vector3i) -> int:
	return BlockIds.SAND if p.y < FLOOR else BlockIds.AIR


func _director(kind: StringName = BossRules.SERPENT) -> BossDirector:
	var d := BossDirector.new()
	d.name = "Boss"
	d.block_at = _flat
	d.boss_kind = kind
	d.pay_gold = func(_peer: int, _amount: int) -> void: pass
	var bar := BossBar.new()
	add_child_autofree(bar)
	d.bar = bar
	add_child_autofree(d)
	return d


func _player(feet: Vector3, peer: int = 1) -> Player:
	var p: Player = load("res://entities/player/player.tscn").instantiate()
	p.name = str(peer)
	add_child_autofree(p)
	p.set_physics_process(false)
	p.viewer.free()
	p._spawned = true
	p.global_position = feet
	return p


func test_the_desert_totem_brings_the_sand_serpent() -> void:
	_player(TOTEM)
	await get_tree().physics_frame
	var d := _director()
	assert_eq(d.start(TOTEM), "")
	var g := d.golem()
	assert_true(g is SandSerpent, "the world's boss")
	assert_eq(g.max_hp, SerpentRules.max_hp(1))
	assert_eq(g.boss_kind(), BossRules.SERPENT)
	d.tick(0.016)
	assert_eq(d.bar.title(), SerpentRules.TITLE)
	assert_eq(d.start(TOTEM), "The Sand Serpent is already here!", "one at a time, by its name")


func test_a_tired_serpent_says_so_and_a_win_names_it() -> void:
	_player(TOTEM)
	await get_tree().physics_frame
	var d := _director()
	d.restore({"losses": 3, "best": 40, "wins": 0}, Vector3.INF)
	d.start(TOTEM)
	var g := d.golem()
	assert_true(g.tired)
	assert_eq(g.max_hp, SerpentRules.max_hp(1, true))
	assert_has(_toasts, SerpentRules.TIRED_MESSAGE, "honest help, announced")
	assert_eq(d.bar.title(), SerpentRules.TIRED_TITLE)
	g.start_phase(SerpentRules.Phase.UP)
	g.take_hit(10000, TOTEM, Vector3.ZERO)
	await get_tree().process_frame
	d.tick(0.016)
	assert_eq(d.bar.title(), SerpentRules.WIN_MESSAGE)
	assert_eq(d.help.losses, 0, "the help resets after a win")
	assert_eq(d.portals().size(), 1, "the portal opens by the Totem")


func test_the_golem_is_still_the_meadows_boss() -> void:
	_player(TOTEM)
	await get_tree().physics_frame
	var d := _director(BossRules.GOLEM)
	d.start(TOTEM)
	assert_false(d.golem() is SandSerpent)
	assert_eq(d.golem().boss_kind(), BossRules.GOLEM)
	d.tick(0.016)
	assert_eq(d.bar.title(), BossBar.TITLE)


func test_a_meadows_world_can_summon_the_serpent_by_name() -> void:
	_player(TOTEM)
	await get_tree().physics_frame
	var d := _director(BossRules.GOLEM)
	d.start(TOTEM + Vector3(4, 0, 0), BossRules.SERPENT)
	assert_true(d.golem() is SandSerpent, "/summon serpent")


func test_summon_serpent_is_a_sandbox_command() -> void:
	var cmd := ChatCommands.parse("/summon serpent")
	assert_eq(cmd.get("boss"), &"serpent")
	assert_true(ChatCommands.suggestions("/summon se").has("/summon serpent"))


func test_the_totems_words_name_the_worlds_boss() -> void:
	assert_eq(WaveRules.boss_word(BossRules.words(BossRules.SERPENT).name), "The Sand Serpent!")
	assert_eq(WaveRules.refusal_message(&"boss", "Sand Serpent"), "The Sand Serpent is here!")
