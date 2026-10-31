extends Node
## The steps of tools/leaf_voyage.gd (a Node, so it may use the autoloads and the game's classes).

const UNIT := "g5.science.plants_air_water"


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	get_window().size = Vector2i(1280, 720)
	if OS.get_cmdline_user_args().has(Vr.PREVIEW_ARG):
		Vr.preview(true)
		await get_tree().process_frame
	var layer := CanvasLayer.new()
	add_child(layer)
	var screen := Control.new()
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(screen)
	var content := Curriculum.content(UNIT)
	var host := LeafVoyageHost.new()
	host.setup(UNIT, content, randi(), 0, Curriculum.unit(UNIT))
	host.first_try_gold = func() -> int: return 0
	host.finished.connect(func(o: Dictionary) -> void:
		print("LEAF_VOYAGE finished: %d of %d right the first time, then %s" % [int(o.right_first), int(o.total), o.then]))
	host.stopped.connect(func(_o: Dictionary) -> void: print("LEAF_VOYAGE stopped for now"))
	host.tree_exited.connect(func() -> void: get_tree().quit())
	host.open(screen)
	print("LEAF_VOYAGE %s (%s)" % [host.voyage_id, "VR preview" if host.vr else "flat"])
