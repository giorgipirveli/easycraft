extends GutTest
## Missions (spec §21d.1): every home world has a Launch Site a short walk from the spawn, placed like the Theater (the
## seed finds flat, dry ground with no tree; never in the Theater's direction from the spawn, never on it; the save
## keeps it): a concrete plaza with the launch pad (the 9 × 9 build square in a ring of stripes), the service tower
## beside it and Mission Control with the Mission Board facing the spawn.

const SPAWN := Vector2i(0, 0)
const GROUND := 70


func _flat(_x: int, _z: int) -> int:
	return GROUND


func _dry(_x: int, _z: int) -> bool:
	return true


func _no_tree(_x: int, _z: int) -> bool:
	return false


func _plaza_cells(site: Dictionary) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for lx in range(LaunchSite.PLAZA_MIN.x, LaunchSite.PLAZA_MAX.x + 1):
		for lz in range(LaunchSite.PLAZA_MIN.y, LaunchSite.PLAZA_MAX.y + 1):
			out.append(LaunchSite.to_world(site, Vector2i(lx, lz)))
	return out


func test_a_flat_world_gets_a_site_a_short_walk_from_the_spawn() -> void:
	var site := LaunchSite.pick(SPAWN, 12345, _flat, _dry, _no_tree)
	assert_false(site.is_empty())
	assert_eq((site.pos as Vector3i).y, GROUND, "the pad's concrete lies on the highest ground under it")
	var near := INF
	var far := 0.0
	for c in _plaza_cells(site):
		var d := Vector2(c - SPAWN).length()
		near = minf(near, d)
		far = maxf(far, d)
	assert_gte(near, float(LaunchSite.MIN_EDGE_FROM_SPAWN), "past the spawn, Tilly and the Totem")
	assert_lte(far, LaunchSite.MAX_FROM_SPAWN, "inside the ring no generated place uses (60)")
	assert_eq(site.facing, TheaterSite.facing_towards(Vector2i(site.pos.x, site.pos.z), SPAWN), "the board faces the spawn")
	assert_eq(LaunchSite.pick(SPAWN, 12345, _flat, _dry, _no_tree), site, "the same seed, the same place")


func test_never_in_the_theaters_direction_or_on_it() -> void:
	var theater := TheaterSite.pick(SPAWN, 777, _flat, _dry, _no_tree)
	assert_false(theater.is_empty())
	for seed_ in [1, 2, 3, 777, 4242]:
		var site := LaunchSite.pick(SPAWN, seed_, _flat, _dry, _no_tree, theater)
		assert_false(site.is_empty(), "seed %d" % seed_)
		var t := Vector2i(theater.pos.x, theater.pos.z)
		var s := Vector2i(site.pos.x, site.pos.z)
		var angle := rad_to_deg(absf(Vector2(s - SPAWN).angle_to(Vector2(t - SPAWN))))
		assert_gte(angle, LaunchSite.SIGHT_GAP, "seed %d: not in front of the Theater, nor behind it" % seed_)
		for c in _plaza_cells(site):
			assert_gte(TheaterSite.edge_distance(t, c), float(LaunchSite.THEATER_CLEAR), "seed %d: clear of its walls" % seed_)


func test_it_stays_on_dry_land_without_trees() -> void:
	var dry := func(x: int, _z: int) -> bool: return x > 10   # a lake west of x 10
	var trees := func(x: int, z: int) -> bool: return x > 10 and z > 0 and z < 60 and (x + z) % 7 == 0   # a wood
	var site := LaunchSite.pick(SPAWN, 99, _flat, dry, trees)
	assert_false(site.is_empty())
	for c in _plaza_cells(site):
		assert_true(dry.call(c.x, c.y), "dry at %s" % c)
		for dx in range(-LaunchSite.TREE_MARGIN, LaunchSite.TREE_MARGIN + 1):
			for dz in range(-LaunchSite.TREE_MARGIN, LaunchSite.TREE_MARGIN + 1):
				assert_false(trees.call(c.x + dx, c.y + dz), "no tree near %s" % c)


## Real meadows are hilly and wooded: a site on flat open ground first, else a steeper one (the plinth fills down to
## PLINTH_DEPTH) where the stamp clears the trees and plants off the plaza.
func test_a_wooded_hilly_world_still_gets_a_site_and_its_trees_are_cleared() -> void:
	var hills := func(x: int, z: int) -> int: return GROUND + (x + z) % 5   # never flat for long
	var wood := func(x: int, z: int) -> bool: return posmod(x * 3 + z * 5, 11) == 0   # trees everywhere
	var site := LaunchSite.pick(SPAWN, 4242, hills, _dry, wood)
	assert_false(site.is_empty(), "a steeper spot, its trees cleared")
	var at := {}
	var trunk := Vector3i(1 << 20, 0, 0)
	for c in _plaza_cells(site):
		if wood.call(c.x, c.y):
			trunk = Vector3i(c.x, hills.call(c.x, c.y), c.y)
			break
	assert_ne(trunk.x, 1 << 20, "a tree stands on the plaza")
	var read := func(p: Vector3i) -> int:
		if p.x == trunk.x and p.z == trunk.z and p.y >= trunk.y and p.y < trunk.y + 5:
			return BlockIds.LOG
		if p.y == trunk.y + 5 and absi(p.x - trunk.x) <= 2 and absi(p.z - trunk.z) <= 2:
			return BlockIds.LEAVES
		return BlockIds.GRASS if p.y < hills.call(p.x, p.z) else BlockIds.AIR
	assert_true(LaunchSite.natural(site, read), "trees are the world's own")
	for c: Array in LaunchSite.clear_changes(site, read):
		at[c[0]] = c[1]
	assert_eq(at.get(trunk + Vector3i(0, 1, 0)), BlockIds.AIR, "the trunk goes")
	assert_eq(at.get(trunk + Vector3i(0, 5, 0)), BlockIds.AIR, "and its leaves")
	assert_false(at.has(trunk + Vector3i(0, -1, 0)), "never the ground")


func test_a_world_of_sea_has_no_site() -> void:
	var sea := func(_x: int, _z: int) -> bool: return false
	assert_true(LaunchSite.pick(SPAWN, 5, _flat, sea, _no_tree).is_empty())


func test_the_pad_is_stamped_in_concrete_with_a_ring_of_stripes() -> void:
	var site := {"pos": Vector3i(40, GROUND, 0), "facing": 3}
	var dip := func(x: int, z: int) -> int: return GROUND - 2 if x == 40 and z == 0 else GROUND
	var changes := LaunchSite.pad_changes(site, dip)
	var at := {}
	for c: Array in changes:
		at[c[0]] = c[1]
	var plaza := (LaunchSite.PLAZA_MAX.x - LaunchSite.PLAZA_MIN.x + 1) * (LaunchSite.PLAZA_MAX.y - LaunchSite.PLAZA_MIN.y + 1)
	assert_eq(changes.size(), plaza + 2, "the plaza's floor, and the plinth under the dip")
	assert_eq(at[Vector3i(40, GROUND, 0)], BlockIds.PAD_CONCRETE, "the pad's middle")
	assert_eq(at[Vector3i(40, GROUND - 1, 0)], BlockIds.PAD_CONCRETE, "the plinth fills the dip")
	assert_eq(at[Vector3i(40, GROUND - 2, 0)], BlockIds.PAD_CONCRETE)
	assert_eq(at[Vector3i(44, GROUND, 4)], BlockIds.PAD_CONCRETE, "the build square's corner")
	assert_eq(at[Vector3i(45, GROUND, 0)], BlockIds.PAD_STRIPE, "the ring")
	assert_eq(at[Vector3i(35, GROUND, -5)], BlockIds.PAD_STRIPE)
	var stripes := 0
	for p: Vector3i in at:
		if at[p] == BlockIds.PAD_STRIPE:
			stripes += 1
	assert_eq(stripes, 40, "11 × 11 around the 9 × 9 square")
	assert_eq(LaunchSite.corner(site), Vector3i(36, GROUND + 1, -4), "the rocket's cells start on the pad, at its corner")
	assert_eq(RocketCheck.PAD, 2 * LaunchSite.SQUARE_HALF + 1)


## A world from before missions may have a child's build where the site would go: the pad is stamped only on the
## world's own ground (a half-stamped pad of its own counts as ground, so a stamp cut short goes on next time).
func test_the_pad_never_covers_a_childs_build() -> void:
	var site := {"pos": Vector3i(40, GROUND, 0), "facing": 3}
	var ground := func(p: Vector3i) -> int:
		if p.y < GROUND - 1:
			return BlockIds.STONE
		if p.y == GROUND - 1:
			return BlockIds.GRASS
		return BlockIds.FLOWERS if p == Vector3i(41, GROUND, 2) else BlockIds.AIR
	assert_true(LaunchSite.natural(site, ground))
	var box := LaunchSite.natural_box(site)
	assert_lte((box[0] as Vector3i).y, GROUND - LaunchSite.PLINTH_DEPTH)
	assert_gte((box[0] as Vector3i).y + (box[1] as Vector3i).y, GROUND + LaunchSite.CLEAR_UP)
	assert_lte((box[0] as Vector3i).x, 40 - LaunchSite.PLAZA_MAX.y - LaunchSite.CLEAR_MARGIN, "round the plaza too")
	var house := func(p: Vector3i) -> int:
		return BlockIds.PLANKS if p == Vector3i(38, GROUND + 2, -3) else ground.call(p)
	assert_false(LaunchSite.natural(site, house), "a wall of planks: another place")
	var half := func(p: Vector3i) -> int:
		return BlockIds.PAD_CONCRETE if p.y == GROUND and p.x > 40 else ground.call(p)
	assert_true(LaunchSite.natural(site, half), "its own concrete from a stamp cut short")


func test_the_board_is_in_front_of_mission_control_facing_the_spawn() -> void:
	var site := {"pos": Vector3i(0, GROUND, -40), "facing": 0}   # its front looks down +Z, at the spawn
	var board := LaunchSite.board_position(site)
	assert_gt(board.z, float(site.pos.z), "on the spawn's side of the pad")
	assert_true(LaunchSite.near_board(site, board + Vector3(0, 1, 1.5)), "walking up to it")
	assert_false(LaunchSite.near_board(site, Vector3(0.5, GROUND + 1, -39.5)), "on the pad")
	assert_false(LaunchSite.near_board(site, board + Vector3(0, 12, 1.5)), "flying far over it")
	assert_false(LaunchSite.near_board({}, board), "no site, no board")
	assert_false(LaunchSite.near_board(site, Vector3.INF))
	var turned := {"pos": Vector3i(40, GROUND, 0), "facing": 3}   # its front looks down -X
	assert_lt(LaunchSite.board_position(turned).x, 40.0)


func test_the_save_keeps_the_site_and_whether_it_is_stamped() -> void:
	var site := {"pos": Vector3i(40, GROUND, -7), "facing": 3}
	var saved := LaunchSite.to_save(site, true)
	assert_eq(saved, [40, GROUND, -7, 3, 1])
	var back := LaunchSite.from_save(saved)
	assert_eq(back.pos, site.pos)
	assert_eq(back.facing, 3)
	assert_true(back.stamped)
	assert_false(LaunchSite.from_save(LaunchSite.to_save(site, false)).stamped)
	for bad: Variant in [null, [], [1, 2, 3], [1, 2, 3, 9, 0], [1, 2, "x", 0, 0], [1.5, 2, 3, 0, 0], {"pos": 1}]:
		assert_true(LaunchSite.from_save(bad).is_empty(), str(bad))
	assert_eq(LaunchSite.to_save({}, false), [])
