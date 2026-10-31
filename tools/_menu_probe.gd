extends SceneTree
func _init() -> void:
	await process_frame
	var m := PauseMenu.new()
	root.add_child(m)
	m.show_monsters_setting(true)
	var d := BotDirector.new()
	root.add_child(d)
	m.friends = d
	m.open()
	await process_frame
	await process_frame
	print("viewport ", root.get_visible_rect())
	for b in m.find_children("*", "Control", true, false):
		if b is Button or b is Label or b is PanelContainer:
			print(b.get_class(), " ", (b as Control).get_global_rect(), " ", b.get("text") if b is Button or b is Label else "")
	quit()
