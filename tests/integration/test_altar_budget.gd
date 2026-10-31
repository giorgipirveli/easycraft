extends GutTest
## Owner #133, #134 (docs/design/games/balance-altar.md §4.5; G0's test_play_budget.gd): the phones' and the Quest's
## budget (at most 100 draws a frame on the Quest, aim 70). Each place at its heaviest moment draws few things however
## many pieces it holds (a mesh or a MultiMesh is one draw a surface): the Entrance Hall at the chorus (every socket lit,
## the Great Altar risen and full, the ring's last altar showing, the door open, Hoot), the Sky Room with every pan full
## of gems and balloons, the arrival with the door open. The HUD (10-20), the flying Glimmer and the VR hands come on top
## (the design's 45-55 in the hall, about 40 in the Sky Room).

## The place's own draws.
const HALL_MAX := 40
const SKY_MAX := 34
const ARRIVAL_MAX := 20


func before_all() -> void:
	Profile.data.settings.reduce_motion = true


func after_all() -> void:
	Profile.data.settings.reduce_motion = false


static func draws(root: Node) -> int:
	var n := 0
	for g: Node in root.find_children("*", "GeometryInstance3D", true, false):
		if (g as GeometryInstance3D).is_visible_in_tree():
			var mesh: Mesh = null
			if g is MeshInstance3D:
				mesh = (g as MeshInstance3D).mesh
			elif g is MultiMeshInstance3D and (g as MultiMeshInstance3D).multimesh:
				mesh = (g as MultiMeshInstance3D).multimesh.mesh
			n += maxi(mesh.get_surface_count(), 1) if mesh else 1
	return n


func test_the_hall_at_the_chorus_stays_within_the_budget() -> void:
	var hall := TempleHall.new()
	add_child_autofree(hall)
	hall.set_freed([0, 1, 2, 3, 4, 5, 6, 7, 8, 9])
	hall.set_lit(11)
	hall.raise_great(1.0)
	hall.show_altar(AltarState.make(3, 4, 0, 16, 4), {"pan": 0, "verb": "lift", "kind": "gem", "count": 2, "twins": 1})
	hall.set_door_open(true)
	hall.show_hoot(true)
	var n := draws(hall)
	gut.p("ALTAR_DRAWS hall at the chorus: %d" % n)
	assert_lte(n, HALL_MAX, "%d draws" % n)
	var play := TempleHall.new()
	add_child_autofree(play)
	play.show_altar(AltarState.make(3, 0, 0, 12, 4), {})
	play.show_hoot(true)
	gut.p("ALTAR_DRAWS hall at an altar: %d" % draws(play))


func test_the_sky_room_full_stays_within_the_budget() -> void:
	var sky := SkyRoom.new()
	add_child_autofree(sky)
	sky.show_altar(AltarState.make(3, -4, 0, 11, 5), {"pan": 0, "verb": "place", "kind": "gem", "count": 3, "twins": 0})
	sky.show_hoot(true)
	var n := draws(sky)
	gut.p("ALTAR_DRAWS sky room full: %d" % n)
	assert_lte(n, SKY_MAX, "%d draws" % n)


func test_the_arrival_stays_within_the_budget() -> void:
	var arrival := TempleArrival.new()
	add_child_autofree(arrival)
	arrival.set_door_open(true)
	var n := draws(arrival)
	gut.p("ALTAR_DRAWS arrival: %d" % n)
	assert_lte(n, ARRIVAL_MAX, "%d draws" % n)
