class_name ReelPack
extends RefCounted
## The Reel Studio (owner #96, spec §5.12b): where a rendered reel's video is. Every video is `assets/reels/<file>.ogv`
## (Theora: Godot's own video player), rendered by tools/reel_render.sh from the reel's 3D stage; its still (the
## picture the feed shows until the video is here) is `assets/reels/<file>.jpg`, small, always in the game.
## - Android and the desktop: the videos are in the game (the APK, while they stay under ANDROID_CAP together: the
##   ruling in docs/devlog/parts/reel-studio.md), so present() is always true.
## - The browser: the videos leave the first download for the reels pack (`reels.<hash>.pck`, packs.json's "reels",
##   fetched in the background after the music by WebContent, kept in user://packs/ by its content); until it is in,
##   present() is false and the feed shows the reel's still with "coming…". on_pack_loaded tells every video view
##   (the group VIEWS) to look again.
## Tests pretend with exists_check = func(path) -> bool (reset to Callable() after).

const DIR := "res://assets/reels/"
const PACK := "reels"
const VIEWS := &"reel_videos"
## All the videos together stay under this to ship in the APK (else the same background pack there too).
const ANDROID_CAP := 20 * 1024 * 1024
## One video at most (a phone decodes it on its CPU: 540 × 960 is plenty for the 9:16 player).
const VIDEO_CAP := 8 * 1024 * 1024

static var exists_check := Callable()
## The child opened the SHORTS (ShortsView.open): an iPhone or iPad fetches the reels pack only then
## (scenes/main.gd's WebContent.later, like the realistic pictures: every start copies user:// into the tab's memory).
static var wanted := false


static func video_path(file: String) -> String:
	return DIR + file + ".ogv"


static func still_path(file: String) -> String:
	return DIR + file + ".jpg"


## True when reel `file`'s video is here to play.
static func present(file: String) -> bool:
	var path := video_path(file)
	if exists_check.is_valid():
		return bool(exists_check.call(path))
	return FileAccess.file_exists(path)


## The reel's still (null when missing).
static func still(file: String) -> Texture2D:
	var path := still_path(file)
	if ResourceLoader.exists(path):
		return load(path)
	return null


## WebContent.pack_loaded (scenes/main.gd): the reels pack is in; every video view looks again.
static func on_pack_loaded(pack_name: String) -> void:
	if pack_name != PACK:
		return
	var tree := Engine.get_main_loop() as SceneTree
	if tree != null:
		tree.call_group(VIEWS, &"reels_arrived")
