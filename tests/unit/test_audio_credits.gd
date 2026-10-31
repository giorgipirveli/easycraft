extends GutTest
## Every sound and every piece of music in the game is credited (the audio pass; house rule: CC0 or
## public domain only, each file credited in assets/CREDITS.md with its source and licence). A file counts
## as credited when a `backticked` name or pattern in CREDITS.md matches its path under assets/ or its
## file name (* and ? work as in String.match: `audio/sfx/step_*.ogg`, `dog_*.ogg`, `music/day.ogg`).

const AUDIO := ["ogg", "wav", "mp3", "flac", "opus"]


func _audio_files(dir: String, out: Array[String]) -> void:
	var d := DirAccess.open(dir)
	if d == null:
		return
	for sub in d.get_directories():
		_audio_files(dir.path_join(sub), out)
	for f in d.get_files():
		if AUDIO.has(f.get_extension().to_lower()):
			out.append(dir.path_join(f).trim_prefix("res://assets/"))


func _patterns() -> Array[String]:
	var text := FileAccess.get_file_as_string("res://assets/CREDITS.md")
	var re := RegEx.new()
	re.compile("`([^`\\s]+\\.(?:ogg|wav|mp3|flac|opus))`")
	var out: Array[String] = []
	for m in re.search_all(text):
		out.append(m.get_string(1))
	return out


func _credited(rel: String, patterns: Array[String]) -> bool:
	for p in patterns:
		if rel.match(p) or rel.get_file().match(p) or rel.match("*/" + p):
			return true
	return false


func test_every_audio_file_under_assets_has_a_credits_line() -> void:
	var files: Array[String] = []
	_audio_files("res://assets", files)
	assert_gt(files.size(), 100, "the game's sounds are found (%d)" % files.size())
	var patterns := _patterns()
	var missing: Array[String] = []
	for f in files:
		if not _credited(f, patterns):
			missing.append(f)
	assert_eq(missing, [] as Array[String], "not in assets/CREDITS.md")


func test_the_matcher_is_not_fooled() -> void:
	var p: Array[String] = ["audio/sfx/step_*.ogg", "dog_*.ogg", "music/day.ogg"]
	assert_true(_credited("audio/sfx/step_3.ogg", p))
	assert_true(_credited("audio/sfx/dog_2.ogg", p))
	assert_true(_credited("music/day.ogg", p))
	assert_false(_credited("music/night.ogg", p))
	assert_false(_credited("audio/sfx/cat_1.ogg", p))


func test_the_audio_pass_names_its_sources_and_licences() -> void:
	var text := FileAccess.get_file_as_string("res://assets/CREDITS.md")
	for must: String in ["freesound.org", "commons.wikimedia.org", "kenney.nl", "make_audio_pass_sfx.py",
			"make_classical_music.py", "mutopiaproject.org", "CC0", "public domain"]:
		assert_string_contains(text, must)
