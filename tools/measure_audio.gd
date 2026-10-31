extends SceneTree
## The audio pass's measurements (docs/devlog/parts/audio-pass.md): how long loading each classical piece
## and ambience loop takes on the main thread (Music and AmbienceSounds load them when they start), the
## size of every audio folder. (The settings panel's size: test_settings_panel.gd prints it.)
##   godot --headless --path . --script res://tools/measure_audio.gd


func _initialize() -> void:
	await process_frame
	var worst := 0.0
	for id: StringName in MusicPieces.ids():
		var t := Time.get_ticks_usec()
		var s := ResourceLoader.load(MusicPieces.path(id), "", ResourceLoader.CACHE_MODE_IGNORE) as AudioStream
		var ms := (Time.get_ticks_usec() - t) / 1000.0
		worst = maxf(worst, ms)
		print("AUDIO load %-14s %6.2f ms  %6.1f s" % [id, ms, s.get_length() if s else -1.0])
	for id: StringName in AmbienceSoundRules.LOOPS:
		var t := Time.get_ticks_usec()
		ResourceLoader.load(AmbienceSoundRules.path(id), "", ResourceLoader.CACHE_MODE_IGNORE)
		print("AUDIO load %-14s %6.2f ms" % [id, (Time.get_ticks_usec() - t) / 1000.0])
	print("AUDIO worst piece load %.2f ms" % worst)
	for dir: String in ["res://assets/audio/sfx", "res://assets/audio/ambience", "res://assets/music", "res://assets/music/classical"]:
		var total := 0
		var n := 0
		for f in DirAccess.get_files_at(dir):
			if f.get_extension() in ["ogg", "wav"]:
				total += FileAccess.get_file_as_bytes(dir.path_join(f)).size()
				n += 1
		print("AUDIO folder %-30s %3d files %8.1f KB" % [dir, n, total / 1024.0])
	quit()
