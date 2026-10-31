extends GutTest
## Spec §23.1: Survivor "finds one in some villages' houses": in some of the wild meadows' villages and towns one house
## has a lab bench against its back wall, under the window, on the house's floor, with room beside it to stand. Never in
## every house.

const SEED := 12345
const R := 8


func test_some_village_houses_have_a_lab_bench() -> void:
	var shape := MeadowsBiomeShape.new(SEED)
	var places := MeadowsPlaces.new(SEED, shape, SecretRules.new(SEED, shape))
	var villages := 0
	var with_bench := 0
	var houses := 0
	var benches := 0
	for rz in range(-R, R):
		for rx in range(-R, R):
			for p: Dictionary in places.places_in_region(Vector2i(rx, rz)):
				if p.kind != MeadowsPlaces.VILLAGE and p.kind != MeadowsPlaces.TOWN:
					continue
				villages += 1
				houses += (p.houses as Array).size()
				var here := 0
				for b: Array in p.boxes:
					if int(b[2]) != BlockIds.LAB_BENCH:
						continue
					here += 1
					var cell: Vector3i = b[0]
					assert_eq((b[1] as Vector3i) - cell, Vector3i.ONE, "%s: one bench" % p.id)
					assert_eq(places.block_at(cell), BlockIds.LAB_BENCH, "%s: nothing is built over it" % p.id)
					var inside := false
					for h: Array in p.houses:
						var lo: Vector3i = h[0]
						var hi: Vector3i = h[1]
						inside = inside or (cell.x >= lo.x and cell.x < hi.x and cell.z >= lo.z and cell.z < hi.z
							and cell.y == int(h[2]))
					assert_true(inside, "%s: inside a house, on its floor" % p.id)
					var room := 0
					for d: Vector3i in [Vector3i(1, 0, 0), Vector3i(-1, 0, 0), Vector3i(0, 0, 1), Vector3i(0, 0, -1)]:
						room += 1 if places.block_at(cell + d) == BlockIds.AIR else 0
					assert_gt(room, 0, "%s: room beside it to stand" % p.id)
				benches += here
				with_bench += 1 if here > 0 else 0
	gut.p("%d villages and towns, %d with a lab bench (%d benches in %d houses)" % [villages, with_bench, benches, houses])
	assert_gt(villages, 2)
	assert_gt(with_bench, 0, "some villages have one")
	assert_lt(benches * 3, houses, "never in every house")
