extends Node
## M7 (owner 2026-09-28: "after refresh i dont need to redownload the data, this is important"): in a browser the game's
## media (the sounds and ambience, the three core music loops, the characters' models and skins) are not in index.pck
## but in their own pack, assets.<hash>.pck, which the page (web/shell.html) downloads next to index.pck before the
## engine starts and writes to PATH. The service worker keeps it by its content, so an update that changes only code
## downloads only index.pck (tools/export_web.sh, docs/devlog/parts/m7-assets-pack.md).
## The FIRST autoload: the engine loads and makes the autoloads one by one, so this _init runs before any other
## autoload script is loaded, and their preloads (Music's loops) find their files. For that it names nothing of the
## game itself (tests/unit/test_assets_pack.gd). Android and the desktop have everything in their one pack: nothing to do.

## Where the page puts the pack in the engine's file system (web/shell.html: engine.preloadFile(assets, PATH)).
const PATH := "/assets.pck"


func _init() -> void:
	if not OS.has_feature("web"):
		return
	var started := Time.get_ticks_msec()
	if load_pack(PATH, true):
		print("EasyCraft: the assets pack is in (%d ms)" % (Time.get_ticks_msec() - started))
	else:
		printerr("EasyCraft: no assets pack at %s: the sounds and the characters are missing" % PATH)


## Loads the pack at `path` into res:// in a browser (`web`); a file the game already has stays as it is. False off the
## web, or when there is no pack there.
static func load_pack(path: String, web: bool) -> bool:
	if not web or not FileAccess.file_exists(path):
		return false
	return ProjectSettings.load_resource_pack(path, false)
