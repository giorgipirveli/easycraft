extends GutTest
## Owner #132 (W1), stage 3: Professor Hoot comes to the child. When his invitation comes (flat and in a headset), Hoot
## himself flies in out of the sky and lands near the child (a few metres off, on dry ground), stays while his line is
## said, then flies off towards the Discovery Academy (or up and away where there is none). Only a picture in the world:
## he never blocks the way (no body), and he is this device's own.

class Meadow:
	func block(p: Vector3i) -> int:
		return BlockIds.GRASS if p.y < 70 else BlockIds.AIR


const DAY := 20380

var ui: Control
var world: Node3D
var meadow := Meadow.new()
var feet := Vector3(0.5, 70.0, 0.5)
var vr := false


func before_each() -> void:
	ui = Control.new()
	add_child_autofree(ui)
	world = Node3D.new()
	add_child_autofree(world)
	feet = Vector3(0.5, 70.0, 0.5)
	vr = false


func after_each() -> void:
	await wait_process_frames(2)


func after_all() -> void:
	Audio.stop_all()


func _director() -> DiscoveryDirector:
	var d := DiscoveryDirector.new()
	d.profile = ProfileData.new()
	d.save_profile = func() -> void: pass
	d.today = func() -> int: return DAY
	d.player_ready = func() -> bool: return true
	d.overlay_open = func() -> bool: return false
	d.in_vr = func() -> bool: return vr
	d.toast = func(_t: String, _s: float) -> void: pass
	d.log = DiscoveryLog.new("")
	d.world_parent = world
	d.block_at = meadow.block
	d.player_feet = func() -> Vector3: return feet
	d.player_yaw = func() -> float: return 0.0
	d.busy = func() -> bool: return false
	add_child_autofree(d)
	d.setup(ui, "sandbox_1:7", true)
	return d


func _run(d: DiscoveryDirector, seconds: float) -> void:
	var t := 0.0
	while t < seconds:
		d.step(0.5)
		t += 0.5


func test_hoot_flies_in_and_lands_near_the_child() -> void:
	var d := _director()
	_run(d, DiscoveryRules.HOOT_AFTER + 1.0)
	assert_not_null(d.hoot_flyer, "Hoot himself comes")
	assert_eq(d.hoot_flyer.get_parent(), world)
	var land := d.hoot_flyer.landing
	assert_between(Vector2(land.x - feet.x, land.z - feet.z).length(), DiscoveryCrystalRules.NEAR - 0.5,
		DiscoveryCrystalRules.FAR + 1.0)
	assert_eq(land.y, 70.0, "on the ground")
	assert_gt(d.hoot_flyer.global_position.y, land.y + 5.0, "out of the sky first")
	assert_eq(d.hoot_flyer.find_children("*", "CollisionShape3D", true, false).size(), 0, "never in the way")


func test_in_a_headset_he_comes_too() -> void:
	vr = true
	var d := _director()
	_run(d, DiscoveryRules.HOOT_AFTER + 1.0)
	assert_not_null(d.hoot_flyer, "the headset's child sees him land (his line on the toast strip)")


func test_he_flies_off_when_his_card_goes() -> void:
	var d := _director()
	_run(d, DiscoveryRules.HOOT_AFTER + 1.0)
	var flyer := d.hoot_flyer
	d.hoot.not_now.pressed.emit()
	assert_true(flyer.leaving, "off he goes")
	assert_null(d.hoot_flyer)


func test_he_flies_towards_the_academy() -> void:
	var d := _director()
	var p := AcademyPlacer.new()
	p.search_later = false
	world.add_child(p)
	p.setup(null, {"pos": Vector3i(0, 70, -40), "facing": 0}, func(_x: int, _z: int) -> int: return 70)
	d.academy = p
	_run(d, DiscoveryRules.HOOT_AFTER + 1.0)
	var flyer := d.hoot_flyer
	d.open_discover()
	assert_true(flyer.leaving)
	assert_lt(flyer.away.distance_to(Vector3(0.5, 70.0 + AcademyBuildings.TOWER_TOP, -39.5)), 6.0, "to the tower's top")
