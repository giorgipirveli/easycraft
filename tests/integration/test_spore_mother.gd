extends GutTest
## Universe 6, the Glow Caves' boss through the BossDirector (spec §5.1; brief): with the world's boss set to the Spore
## Mother, the Totem's fight brings a SporeMother with her team-sized health; the bar names her and shows her face; her
## rhythm runs (spores, the ring, the puff, her gills open after each); spore clouds land on the rings shown at the
## children's feet (1 HP and a slow for whoever stays in one, nothing for whoever stepped out; a lingering cloud slows,
## never hurts); the ring rolls along the ground (a jump clears it); her puff hides her (no hits) and carries her; her
## open gills take double damage. The caves are the last universe: a win opens the rainbow portal to the hub with the
## grand celebration. She never changes a block.

const FLOOR := 10
const TOTEM := Vector3(20.5, FLOOR, 3.5)
const P := preload("res://core/rules/spore_mother_rules.gd").Phase
const S := preload("res://core/rules/spore_mother_rules.gd")

var _mode_before: StringName
var _universe_before := 1
var _unlocked_before := 1
var _said: Array = []
var _edits := 0


func before_each() -> void:
	_mode_before = Game.mode
	_universe_before = Game.universe
	_unlocked_before = Profile.data.universe_unlocked
	Game.mode = ModeRules.SURVIVOR
	Game.universe = 6
	Profile.data.universe_unlocked = 6
	_said.clear()
	Session.magic_feedback.connect(_on_said)


func after_each() -> void:
	Session.magic_feedback.disconnect(_on_said)
	Game.mode = _mode_before
	Game.universe = _universe_before
	Profile.data.universe_unlocked = _unlocked_before
	Session.survivor_reset()
	Music.reset()
	UniverseRegistry.reset()


func after_all() -> void:
	for n in Audio.get_children():
		if n is AudioStreamPlayer3D:
			(n as AudioStreamPlayer3D).stop()


func _on_said(text: String) -> void:
	_said.append(text)


func _flat(p: Vector3i) -> int:
	return BlockIds.CAVE_STONE if p.y < FLOOR else BlockIds.AIR


func _director() -> BossDirector:
	var d := BossDirector.new()
	d.name = "Boss"
	d.block_at = _flat
	d.boss_kind = BossRules.SPORE_MOTHER
	d.pay_gold = func(_peer: int, _amount: int) -> void: pass
	d.celebrate = func() -> void: pass
	var bar := BossBar.new()
	add_child_autofree(bar)
	d.bar = bar
	add_child_autofree(d)
	return d


func _ground() -> void:
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(120, 1, 120)
	shape.shape = box
	body.add_child(shape)
	add_child_autofree(body)
	body.global_position = Vector3(TOTEM.x, FLOOR - 0.5, TOTEM.z)


func _player(feet: Vector3, peer: int = 1) -> Player:
	var p: Player = load("res://entities/player/player.tscn").instantiate()
	p.name = str(peer)
	add_child_autofree(p)
	p.set_physics_process(false)
	p.viewer.free()
	p._spawned = true
	p.global_position = feet
	p.is_local = true
	return p


func _mother(d: BossDirector) -> SporeMother:
	return d.golem() as SporeMother


func _run(g: SporeMother, seconds: float) -> void:
	for i in int(seconds * 60.0):
		if not is_instance_valid(g):
			return
		g._physics_process(1.0 / 60.0)


func test_the_glow_totem_brings_the_spore_mother() -> void:
	_player(TOTEM + Vector3(0, 0, 6))
	await get_tree().physics_frame
	var d := _director()
	assert_eq(d.start(TOTEM), "")
	var g := _mother(d)
	assert_not_null(g, "the world's boss is a SporeMother")
	assert_eq(g.max_hp, S.max_hp(1))
	assert_eq(g.boss_kind(), BossRules.SPORE_MOTHER)
	d.tick(0.016)
	assert_eq(d.bar.title(), S.TITLE)
	assert_eq(d.bar.face(), BossRules.SPORE_MOTHER, "the bar shows her face")
	assert_eq(d.start(TOTEM), "The Spore Mother is already here!", "one at a time, by her name")


## Spores: rings at the child's feet as her cap glows; a child still in a ring when the clouds land: 1 HP and slowed;
## the clouds linger and slow (never hurt) whoever walks in.
func test_spore_clouds_land_on_the_rings() -> void:
	_ground()
	var p := _player(TOTEM + Vector3(4, 0, 0))
	await get_tree().physics_frame
	var d := _director()
	d.start(TOTEM)
	var g := _mother(d)
	g.start_phase(P.SPORE_WARN)
	assert_true(g.warning_spots().has(p.global_position), "a ring at the child's feet, on every screen")
	assert_eq(g.warning_spots().size(), S.CLOUDS)
	var hp := p.health.hp
	_run(g, S.SPORE_WINDUP + 0.1)
	assert_eq(p.health.hp, hp - S.damage(S.SPORES), "a spore cloud: one heart")
	assert_true(p.is_slowed(), "and slowed")
	assert_eq(g.phase, P.GILLS_OPEN, "her gills open after the spores")
	assert_gt(g.lingering().size(), 0, "the clouds linger")
	p.slow_down(0.0)
	assert_false(p.is_slowed())
	g._process(0.1)                     # a lingering cloud: the child still stands in it
	assert_true(p.is_slowed(), "a lingering cloud slows")
	assert_eq(p.health.hp, hp - S.damage(S.SPORES), "and never hurts")


func test_a_step_out_of_the_ring_dodges_the_cloud() -> void:
	_ground()
	var p := _player(TOTEM + Vector3(4, 0, 0))
	await get_tree().physics_frame
	var d := _director()
	d.start(TOTEM)
	var g := _mother(d)
	g.start_phase(P.SPORE_WARN)
	p.global_position = TOTEM + Vector3(4 + S.CLOUD_R + 1.0, 0, 0)
	await get_tree().physics_frame
	var hp := p.health.hp
	_run(g, S.SPORE_WINDUP + 0.1)
	assert_eq(p.health.hp, hp, "stepped out: missed")
	assert_false(p.is_slowed())


func test_the_spore_ring_rolls_along_the_ground() -> void:
	_ground()
	var p := _player(TOTEM + Vector3(0, 0, -7) + Vector3(3, 0, 0))
	await get_tree().physics_frame
	var d := _director()
	d.start(TOTEM)
	var g := _mother(d)
	g.global_position = p.global_position + Vector3(-3, 0, 0)
	g.start_phase(P.RING_WARN)
	var hp := p.health.hp
	_run(g, S.RING_WINDUP + 0.05)
	assert_eq(p.health.hp, hp - S.damage(S.RING), "on the ground within the ring")
	assert_eq(g.phase, P.GILLS_OPEN)


## Her puff hides her (no hits), carries her PUFF_MOVE, then her gills open: double damage.
func test_her_puff_hides_her_and_her_open_gills_take_double() -> void:
	_ground()
	_player(TOTEM + Vector3(0, 0, 8))
	await get_tree().physics_frame
	var d := _director()
	d.start(TOTEM)
	var g := _mother(d)
	_run(g, 0.1)
	var from := g.global_position
	g.start_phase(P.HIDDEN)
	var hp := g.hp
	g.take_hit(10, from, Vector3.ZERO)
	assert_eq(g.hp, hp, "the glitter puff: weapons go through")
	_run(g, S.HIDDEN_TIME + 0.05)
	assert_gt(Vector2(g.global_position.x - from.x, g.global_position.z - from.z).length(), S.PUFF_MOVE * 0.5,
		"she glided to a new spot")
	assert_eq(g.phase, P.GILLS_OPEN)
	assert_true(g.is_dazed(), "the bar shows her open (her weak spot)")
	g.take_hit(10, g.global_position, Vector3.ZERO)
	assert_eq(g.hp, hp - 20, "her glowing gills: double damage")
	g.start_phase(P.SWAY)
	g.take_hit(10, g.global_position, Vector3.ZERO)
	assert_eq(g.hp, hp - 30)


## The last universe: a win opens the rainbow portal to the hub, with the grand celebration.
func test_a_win_is_the_grand_one_and_opens_the_hub() -> void:
	_player(TOTEM + Vector3(0, 0, 6))
	await get_tree().physics_frame
	var d := _director()
	d.start(TOTEM)
	var g := _mother(d)
	g.start_phase(P.SWAY)
	g.take_hit(100000, TOTEM, Vector3.ZERO)
	await get_tree().process_frame
	d.tick(0.016)
	assert_eq(d.bar.title(), S.WIN_MESSAGE)
	assert_true(_said.has(CakeRules.GRAND_WIN), "the last universe: %s" % [_said])
	assert_eq(d.portals().size(), 1)
	assert_eq(d.portals()[0].target, UniverseRules.HUB)


## Through a whole rhythm she never changes a block (she only reads the world).
func test_she_never_changes_a_block() -> void:
	_ground()
	_player(TOTEM + Vector3(0, 0, 6))
	await get_tree().physics_frame
	var d := _director()
	var calls := [0]
	d.block_at = func(p: Vector3i) -> int:
		calls[0] += 1
		return _flat(p)
	d.start(TOTEM)
	var g := _mother(d)
	_run(g, 14.0)
	assert_gt(calls[0], 0, "she reads the world")
	assert_false(g.has_method(&"set_block"))
