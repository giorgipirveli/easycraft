extends GutTest
## An inner class (`class Name:`) with the name of a global `class_name` stops its whole script from compiling
## ("Class X hides a global script class"), and the import check does not see it. Two agents' merges met this way
## on 2026-09-24 (M4 H's inner StickerPicture and M4 I's global one).

const ROOTS: Array[String] = ["res://autoloads", "res://core", "res://entities", "res://net", "res://scenes", "res://tools", "res://ui", "res://world"]


func test_no_inner_class_takes_the_name_of_a_global_class() -> void:
	var globals := {}
	for c: Dictionary in ProjectSettings.get_global_class_list():
		globals[String(c["class"])] = String(c["path"])
	var clashes: Array[String] = []
	var inner := RegEx.create_from_string("(?m)^class\\s+([A-Za-z_][A-Za-z0-9_]*)")
	for path in _scripts():
		for m in inner.search_all(FileAccess.get_file_as_string(path)):
			var name := m.get_string(1)
			if globals.has(name):
				clashes.append("%s: inner class %s hides %s" % [path, name, globals[name]])
	assert_eq(clashes, [] as Array[String])


func _scripts() -> Array[String]:
	var out: Array[String] = []
	var dirs: Array[String] = ROOTS.duplicate()
	while not dirs.is_empty():
		var dir: String = dirs.pop_back()
		for sub in DirAccess.get_directories_at(dir):
			dirs.append(dir.path_join(sub))
		for f in DirAccess.get_files_at(dir):
			if f.ends_with(".gd"):
				out.append(dir.path_join(f))
	return out
