extends GutTest
## P5 (the research's P5 row): in a headset session a label drawn over everything (no_depth_test: a trader's sign, a quest
## bubble, seen over the hills) ends at WorldService.VR_LABEL_FAR: farther, the two eyes' depth fights the hill in front
## of it. Labels that hills hide anyway, and nearer ranges, stay as they are; off VR every label is as before.

var world: WorldService


func after_each() -> void:
	GraphicsPreset.vr_session = false


func _world() -> void:
	world = load("res://world/world.tscn").instantiate()
	world.setup("", 3)
	add_child_autofree(world)


func _label(over_everything: bool, range_end: float = 0.0) -> Label3D:
	var l := Label3D.new()
	l.no_depth_test = over_everything
	l.visibility_range_end = range_end
	add_child_autofree(l)
	return l


func test_in_vr_labels_over_everything_end_at_32_m() -> void:
	GraphicsPreset.vr_session = true
	_world()
	var sign := _label(true)
	var far := _label(true, 200.0)
	var near := _label(true, 12.0)
	var hidden_by_hills := _label(false)
	await wait_process_frames(2)
	assert_eq(sign.visibility_range_end, WorldService.VR_LABEL_FAR)
	assert_eq(far.visibility_range_end, WorldService.VR_LABEL_FAR)
	assert_eq(near.visibility_range_end, 12.0, "a nearer range stays")
	assert_eq(hidden_by_hills.visibility_range_end, 0.0, "a label the hills hide keeps its own")


func test_a_label_made_before_the_world_is_clamped_too() -> void:
	GraphicsPreset.vr_session = true
	var early := _label(true)
	_world()
	await wait_process_frames(2)
	assert_eq(early.visibility_range_end, WorldService.VR_LABEL_FAR)


func test_off_vr_labels_are_as_before() -> void:
	_world()
	var sign := _label(true)
	await wait_process_frames(2)
	assert_eq(sign.visibility_range_end, 0.0)
