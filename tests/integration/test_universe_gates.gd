extends GutTest
## Owner feedback #39 (spec §14.2a): universe portals through the host's PortalDirector — a frame with a crystal's
## core in its core slot swirls in that universe's colours with no partner; walking in asks the sandbox to travel
## there (solo), and says kindly why not ("You are here!", friends in the game, what the travel said); breaking its
## core or frame stops it; the portals are saved and work after loading; guests see the colours.

const F := BlockIds.PORTAL_FRAME
const FLOOR := 20
const LO := Vector3i(0, FLOOR, 0)

var cells := {}
var _told: Array = []
var _asked: Array[int] = []
var _refuse := ""


func before_each() -> void:
	cells = {}
	_told = []
	_asked = []
	_refuse = ""


func after_all() -> void:
	for n in Audio.get_children():
		if n is AudioStreamPlayer3D:
			(n as AudioStreamPlayer3D).stop()


func _at(p: Vector3i) -> int:
	if cells.has(p):
		return cells[p]
	return BlockIds.STONE if p.y < FLOOR else BlockIds.AIR


func _put(d: PortalDirector, p: Vector3i, id: int) -> void:
	var old := _at(p)
	cells[p] = id
	d.note_block(p, old, id)
	d.flush()


## A 1 x 2 doorway along X at `lo`, the frames first and the crystal's core last (as a child builds it).
func _build(d: PortalDirector, lo: Vector3i, core_id: int) -> Vector3i:
	for c in [lo + Vector3i(-1, -1, 0), lo + Vector3i(1, -1, 0), lo + Vector3i(-1, 0, 0), lo + Vector3i(1, 0, 0),
			lo + Vector3i(-1, 1, 0), lo + Vector3i(1, 1, 0), lo + Vector3i(-1, 2, 0), lo + Vector3i(0, 2, 0),
			lo + Vector3i(1, 2, 0)]:
		_put(d, c, F)
	_put(d, lo + Vector3i.DOWN, core_id)
	return lo + Vector3i.DOWN


func _director(here: int = 1) -> PortalDirector:
	var d := PortalDirector.new()
	d.name = "PortalFrames"
	d.block_at = _at
	d.here = here
	d.tell = func(peer: int, text: String) -> void: _told.append([peer, text])
	d.travel = func(u: int) -> String:
		_asked.append(u)
		return _refuse
	add_child_autofree(d)
	d.set_process(false)
	d.start({})
	return d


func _player(feet: Vector3) -> Player:
	var p: Player = load("res://entities/player/player.tscn").instantiate()
	p.name = str(multiplayer.get_unique_id())
	add_child_autofree(p)
	p.set_physics_process(false)
	p.viewer.free()
	p._spawned = true
	p.global_position = feet
	return p


func _walk_in(d: PortalDirector, me: Player) -> void:
	me.global_position = Vector3(LO) + Vector3(0.5, 0.0, 3.5)
	await get_tree().physics_frame
	d.tick(PortalDirector.CHECK_EVERY + 0.01)
	me.global_position = Vector3(LO) + Vector3(0.5, 0.0, 0.5)
	await get_tree().physics_frame
	d.tick(PortalDirector.CHECK_EVERY + 0.01)


func test_a_frame_with_a_crystal_core_swirls_in_its_universes_colours_alone() -> void:
	var d := _director()
	var core := _build(d, LO, BlockIds.CORE_FROST)
	assert_true(d.gates.works(core), "no partner needed")
	assert_eq(d.gates.universe_of(core), 3)
	assert_eq(d.swirls().size(), 1)
	var m := d.swirls()[0].material_override as ShaderMaterial
	assert_same(m, PortalSwirl.material_for(3), "one shared material for Frostpeak's portals")
	assert_same(m.shader, PortalSwirl.material().shader, "the same shader: no new compile")
	assert_eq(m.get_shader_parameter(&"bright"), CrystalRules.swirl_colors(3)[1], "Frostpeak's colours")
	assert_same(d.swirls()[0].mesh, PortalSwirl.quad())


func test_walking_in_asks_to_travel_to_its_universe_once() -> void:
	var d := _director(1)
	_build(d, LO, BlockIds.CORE_DESERT)
	var me := _player(Vector3(LO) + Vector3(0.5, 0, 3.5))
	var went: Array[int] = []
	d.gate_entered.connect(func(u: int) -> void: went.append(u))
	await _walk_in(d, me)
	assert_eq(_asked, [2] as Array[int], "to the Sandstorm Desert")
	assert_eq(went, [2] as Array[int])
	d.tick(PortalDirector.CHECK_EVERY + 0.01)
	d.tick(PortalRules.COOLDOWN + 0.1)
	assert_eq(_asked.size(), 1, "standing in it asks once")


func test_a_refusal_is_said_to_the_child() -> void:
	var d := _director(1)
	_build(d, LO, BlockIds.CORE_CANDY)
	_refuse = UniverseRules.travel_message("locked")
	var me := _player(Vector3.ZERO)
	await _walk_in(d, me)
	assert_eq(_told, [[me.peer_id, "Beat the boss to open this universe!"]])


func test_a_portal_to_the_universe_you_are_in_says_so() -> void:
	var d := _director(3)
	_build(d, LO, BlockIds.CORE_FROST)
	var me := _player(Vector3.ZERO)
	await _walk_in(d, me)
	assert_eq(_asked, [] as Array[int], "no trip")
	assert_eq(_told, [[me.peer_id, "You are here!"]])


func test_breaking_the_core_or_the_frame_stops_it() -> void:
	var d := _director()
	var core := _build(d, LO, BlockIds.CORE_MEADOWS)
	_put(d, LO + Vector3i(0, 2, 0), BlockIds.AIR)
	assert_false(d.gates.works(core), "the frame is broken")
	assert_eq(d.swirls().size(), 0)
	_put(d, LO + Vector3i(0, 2, 0), F)
	assert_eq(d.swirls().size(), 1, "whole again")
	_put(d, core, BlockIds.AIR)
	assert_false(d.gates.has(core), "the crystal was taken out")
	assert_eq(d.swirls().size(), 0)


func test_swapping_the_crystal_leads_somewhere_else() -> void:
	var d := _director()
	var core := _build(d, LO, BlockIds.CORE_DESERT)
	_put(d, core, BlockIds.CORE_FROST)
	assert_eq(d.gates.universe_of(core), 3)
	assert_true(d.gates.works(core))
	_put(d, core, BlockIds.PORTAL_CORE)
	assert_false(d.gates.has(core), "a linking core is not a universe portal")
	assert_true(d.links.has(core), "it waits for a partner like any linking core")


func test_universe_portals_are_saved_and_work_after_loading_unseen() -> void:
	var d := _director()
	var core := _build(d, LO, BlockIds.CORE_CANDY)
	var saved := d.gates_to_save()
	var e := _director()
	e.start_gates(JSON.parse_string(JSON.stringify(saved)))
	assert_true(e.gates.works(core), "trusted as saved while its blocks aren't read")
	assert_eq(e.swirls().size(), 1)
	assert_same(e.swirls()[0].material_override, PortalSwirl.material_for(4))


func test_the_swirls_come_from_the_hosts_list_with_colours() -> void:
	var d := _director()
	d._rpc_active([[LO, Vector2i(1, 2), PortalRules.AXIS_X, 5], [LO + Vector3i(9, 0, 0), Vector2i(1, 2), PortalRules.AXIS_X]])
	assert_eq(d.swirls().size(), 2)
	assert_same(d.swirls()[0].material_override, PortalSwirl.material_for(5), "the Dragon Realm's colours")
	assert_same(d.swirls()[1].material_override, PortalSwirl.material(), "a linking portal's purple")
	d._rpc_active([[LO, Vector2i(1, 2), PortalRules.AXIS_X, "x"], "bad", [LO]])
	assert_eq(d.swirls().size(), 1, "broken entries are dropped")
