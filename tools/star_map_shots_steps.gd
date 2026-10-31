extends Node
## The steps of tools/star_map_shots.gd (loaded once the game's autoloads are there).

var _panel: SpacePanel
var _dir := "user://star_map_shots"


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_dir))
	_run.call_deferred()


func _run() -> void:
	var layer := CanvasLayer.new()   # as in the game: the panel in the UI layer, the stretched canvas's size
	get_tree().root.add_child(layer)
	_panel = SpacePanel.new()
	layer.add_child(_panel)
	_panel.open(1, 1, [16, 17, 18] as Array[int], 2)
	await _shot("map_from_meadows")
	for id: StringName in [&"moon", &"mars", &"jupiter", &"saturn", &"frostpeak"]:
		_panel.select(id)
		await _shot("card_" + str(id))
	_panel.close()
	_panel.open(16, 3, [16, 17, 18] as Array[int], 3)
	await _shot("map_from_the_moon")
	get_tree().quit()


func _shot(label: String) -> void:
	for i in 4:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var img := get_tree().root.get_texture().get_image()
	var path := ProjectSettings.globalize_path("%s/%s.png" % [_dir, label])
	img.save_png(path)
	print("STAR_SHOT ", path)
