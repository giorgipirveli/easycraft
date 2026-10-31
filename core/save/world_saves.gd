class_name WorldSaves
extends RefCounted
## World save slots on disk: user://worlds/<slot>/ holds world.json (WorldMeta) and voxels.sqlite.

const ROOT := "user://worlds/"
const META_FILE := "world.json"


static func dir_for(slot: String) -> String:
	return ROOT + slot + "/"


static func exists(slot: String) -> bool:
	return FileAccess.file_exists(dir_for(slot) + META_FILE)


static func load_meta(slot: String) -> WorldMeta:
	var text := JsonStore.read_text(dir_for(slot) + META_FILE)
	return WorldMeta.from_json(text) if text != "" else WorldMeta.new_random()


static func save_meta(slot: String, meta: WorldMeta) -> Error:
	DirAccess.make_dir_recursive_absolute(dir_for(slot))
	return JsonStore.write_atomic(dir_for(slot) + META_FILE, meta.to_json())


## Deletes the slot and every file in it (meta, voxel database and its journal files).
static func delete(slot: String) -> void:
	var dir := dir_for(slot)
	if not DirAccess.dir_exists_absolute(dir):
		return
	for f in DirAccess.get_files_at(dir):
		DirAccess.remove_absolute(dir + f)
	DirAccess.remove_absolute(dir)
