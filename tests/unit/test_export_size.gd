extends GutTest
## M5 Task 3 (spec §15.3, the APK size pass): what goes into the APK. The dev log's and the store's pictures were
## imported (a picture outside a .gdignore folder is a resource) and so went into every APK: 16 MB of JPEGs.


## Every .import file under `dir` (recursively).
func _imports(dir: String) -> Array[String]:
	var out: Array[String] = []
	for f in DirAccess.get_files_at(dir):
		if f.ends_with(".import"):
			out.append(dir.path_join(f))
	for d in DirAccess.get_directories_at(dir):
		out.append_array(_imports(dir.path_join(d)))
	return out


func test_the_docs_pictures_are_never_imported_so_never_exported() -> void:
	assert_true(FileAccess.file_exists("res://docs/.gdignore"), "docs/ is a .gdignore folder")
	assert_eq(_imports("res://docs"), [] as Array[String], "no picture under docs/ is imported")
