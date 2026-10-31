extends GutTest
## M7, the browser's freezes (docs/devlog/parts/m7-freezes.md): the menu's backdrop world built collision for every
## chunk its orbiting camera streams (96 blocks), on the main thread (frames of 10-20 ms here while it streams, several
## times that in a phone's browser), though nothing on the menu stands on the ground.


func test_the_menus_backdrop_streams_pictures_but_no_collision() -> void:
	var menu: Node = load("res://ui/menus/menu.tscn").instantiate()
	add_child_autofree(menu)
	await wait_process_frames(2)
	var viewers := menu.find_children("*", "VoxelViewer", true, false)
	assert_gt(viewers.size(), 0, "the backdrop streams")
	for v in viewers:
		assert_true((v as VoxelViewer).requires_visuals)
		assert_false((v as VoxelViewer).requires_collisions, "nothing on the menu stands on the ground")
