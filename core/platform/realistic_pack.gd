class_name RealisticPack
extends RefCounted
## M7 (owner 2026-09-28: "make sure it loads fast, load any unnessesary data later"): the REALISTIC style's pictures,
## every block page's realistic twin (albedo and normal map) and the HDRI sky, are about 30 MB of the browser's 44 MB
## main pack, and a child who plays BLOCKY (the default) never needs them. The web export leaves them out of index.pck
## and puts them in the "realistic" pack (one per texture format, tools/export_web.sh) that WebContent fetches after
## the start. Until it is in, BlockLibrary.set_style keeps the pixel pictures for a child who chose REALISTIC (the
## choice stays saved), the settings say the pictures are on their way, and when the pack lands every world that
## wants REALISTIC turns realistic by itself (on_pack_loaded). The phone and desktop builds have every file from the
## start, so present() is always true there.

## packs.json's name for the pack (WebContent.pack_loaded).
const PACK := "realistic"
## Nodes told when the pictures arrive: they have realistic_pictures_arrived() (a world that wants REALISTIC, the
## settings' "on their way" line).
const GROUP := &"realistic_pictures"

## (path) -> bool in place of ResourceLoader.exists (tests pretend files are missing; reset to Callable()).
static var exists_check := Callable()


## Every file of the realistic style that is not also needed by BLOCKY: the pages' realistic twins and the sky.
static func files() -> Array[String]:
	var out := BlockLibrary.realistic_files()
	out.append(WorldService.REALISTIC_SKY)
	return out


static func file_present(path: String) -> bool:
	if exists_check.is_valid():
		return bool(exists_check.call(path))
	return ResourceLoader.exists(path)


## Every realistic picture is in the game now (false in a browser until the realistic pack has come).
static func present() -> bool:
	for f: String in files():
		if not file_present(f):
			return false
	return true


## WebContent.pack_loaded (scenes/main.gd): the realistic pack is in; the worlds and panels waiting for it are told.
static func on_pack_loaded(pack_name: String) -> void:
	if pack_name != PACK:
		return
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	var start := Time.get_ticks_msec()
	tree.call_group(GROUP, &"realistic_pictures_arrived")
	print("EasyCraft: the realistic pictures are here (the blocks show %s; %d ms)" % [BlockLibrary.style,
		Time.get_ticks_msec() - start])
