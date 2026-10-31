extends GutTest
## Owner #133, #134 (docs/design/games/leaf-voyage.md §4.5; G0's test_play_budget.gd): the phones' and the Quest's
## budget (at most 100 draws a frame on the Quest, aim 70). Each place at its heaviest moment draws few things however
## many pieces it holds (a mesh, a MultiMesh or a particle system is one draw): the leaf's inside with every door open,
## the mist pouring, a sugar at every spot, the puffs and the drops on their way (both dressings, day and night), the
## garden in bloom with its bee, every stage of the dive. The HUD, Hoot and the avatar come on top (the design's 45-55
## inside, 35 in the garden).

## The place's own draws (the HUD's 10-20, Hoot's 2 and the avatar's 8 come on top).
const INSIDE_MAX := 34
const GARDEN_MAX := 26
const DIVE_MAX := 24


func before_all() -> void:
	Profile.data.settings.reduce_motion = true


func after_all() -> void:
	Profile.data.settings.reduce_motion = false


func _draws(root: Node) -> int:
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


func test_the_leaf_s_inside_at_its_heaviest_stays_within_the_budget() -> void:
	for dressing: String in ["sunflower", "cactus"]:
		for night: bool in [false, true]:
			var place := LeafPlace.new(dressing)
			add_child_autofree(place)
			place.show_all(night)
			var n := _draws(place)
			gut.p("LEAF_DRAWS inside %s %s: %d" % [dressing, "night" if night else "day", n])
			assert_lte(n, INSIDE_MAX, "%s (%s): %d draws" % [dressing, "night" if night else "day", n])
			assert_lte(place.find_children("*", "Light3D", true, false).size(), 1)


func test_the_garden_in_bloom_stays_within_the_budget() -> void:
	for stage: String in [LeafProgress.DROOP, LeafProgress.BLOOM]:
		var garden := LeafGarden.new()
		add_child_autofree(garden)
		garden.show_stage(stage, true)
		var n := _draws(garden)
		gut.p("LEAF_DRAWS garden %s: %d" % [stage, n])
		assert_lte(n, GARDEN_MAX, "%s: %d draws" % [stage, n])


func test_every_stage_of_the_dive_stays_within_the_budget() -> void:
	var dive := LeafDive.new()
	add_child_autofree(dive)
	for i in LeafDive.STAGES.size():
		dive.pose(float(i) / (LeafDive.STAGES.size() - 1))
		var n := _draws(dive)
		gut.p("LEAF_DRAWS dive %s: %d" % [LeafDive.STAGES[i], n])
		assert_lte(n, DIVE_MAX, "%s: %d draws" % [LeafDive.STAGES[i], n])


## B2: the whole voyage at its heaviest moment, inside the leaf with everything the host adds: the avatar carrying its
## sugar, Hoot at its shoulder, and the HUD's canvas (each drawn Control counted as one draw, no batching: a ceiling).
const HOST_MAX := 100


func _hud_draws(hud: CanvasLayer) -> int:
	var n := 0
	for c: Node in hud.find_children("*", "Control", true, false):
		var ctl := c as Control
		if not ctl.is_visible_in_tree():
			continue
		if ctl is Label and (ctl as Label).text.strip_edges() == "":
			continue
		if ctl is Button or ctl is Label or ctl is PanelContainer or ctl is Panel or ctl is TextureRect \
				or ctl is ColorRect or ctl.get_script() != null:
			n += 1
	return n


func test_a_voyage_at_its_heaviest_moment_stays_within_the_quests_budget() -> void:
	var layer := CanvasLayer.new()
	add_child_autofree(layer)
	var screen := Control.new()
	layer.add_child(screen)
	var path := "user://test_leaf_budget_%d.json" % OS.get_process_id()
	for voyage: String in ["5.1", "5.T1"]:
		var host := LeafVoyageHost.new()
		host.progress_path = path
		host.setup("g5.science.plants_air_water", {"id": "g5.science.plants_air_water", "exercises": [],
			"play": {"game": "leaf_voyage", "params": {"voyage": voyage}}}, 7, 0, {})
		host.open(screen)
		host.set_process(false)
		host.water_now()
		host.tap_target("leaf")
		for i in 70:
			host.step(0.1)
		assert_eq(host.journey.stage, LeafJourney.INSIDE)
		host.place.show_all(voyage == "5.T1")
		host.avatar.set_carried(LeafAvatar.MAX_CARRY)
		var three := _draws(host)
		var two := _hud_draws(host.hud)
		gut.p("LEAF_DRAWS voyage %s inside, the host's whole frame: %d (3D %d, HUD %d)" % [voyage, three + two, three,
			two])
		assert_lte(three + two, HOST_MAX, "%s: %d draws" % [voyage, three + two])
		host.close()
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
