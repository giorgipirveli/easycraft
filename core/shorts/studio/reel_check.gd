class_name ReelCheck
extends RefCounted
## The Reel Studio's quality checker (owner #96, spec §5.12b), on top of ShortCheck's: what a 3D stage and a rendered
## video need. problems(short) lists everything wrong ([] when it can ship):
## - a stage's camera starts with the Short (a key at 0) and its moves and keys fit the Short (Scene3DKind);
## - a video reel's video is here (ReelPack), plays (Godot reads it), weighs at most ReelPack.VIDEO_CAP, is as long as
##   its Short (within LENGTH_SLACK), is 9:16, and never shows a black or blank frame (its brightness at a quarter, half
##   and three quarters, measured by tools/reel_render.sh into assets/reels/reels.json, between LUMA); its still is here.
## The studio (tools/reel_preview.gd) shows them with ShortCheck's; test_reel_studio_library.gd runs them on every reel.

const MANIFEST := "res://assets/reels/reels.json"
const LENGTH_SLACK := 0.2
const LUMA := Vector2(12.0, 240.0)
const ASPECT := 9.0 / 16.0


static func problems(short: Dictionary) -> Array[String]:
	var out: Array[String] = []
	var id := str(short.get("id", ""))
	var length := ShortTimeline.length(short)
	if short.get("stage") is Dictionary:
		var keys := StudioCamera.sorted(short.stage.get("camera", []))
		if keys.is_empty() or float(keys[0].at) > 0.0:
			out.append("%s: the stage's camera has a key at 0 (the first frame)" % id)
	if short.has("video"):
		out.append_array(video_problems(str(short.video), length))
	return out


## Everything wrong with reel `file`'s video for a Short of `length` seconds.
static func video_problems(file: String, length: float) -> Array[String]:
	var out: Array[String] = []
	var path := ReelPack.video_path(file)
	if not FileAccess.file_exists(path):
		return ["%s: no video (tools/reel_render.sh %s)" % [file, file]]
	if not ResourceLoader.exists(ReelPack.still_path(file)):
		out.append("%s: no still (%s)" % [file, ReelPack.still_path(file)])
	var bytes := FileAccess.get_file_as_bytes(path).size()
	if bytes > ReelPack.VIDEO_CAP:
		out.append("%s: %d KiB, more than %d KiB (a phone downloads it)" % [file, bytes / 1024, ReelPack.VIDEO_CAP / 1024])
	var plays := seconds_of(path)
	if absf(plays - length) > LENGTH_SLACK:
		out.append("%s: the video plays %.2f s, its Short %.2f s" % [file, plays, length])
	var m: Dictionary = manifest().get(file, {})
	if m.is_empty():
		out.append("%s: not in %s (render it again)" % [file, MANIFEST])
		return out
	if int(m.get("bytes", -1)) != bytes:
		out.append("%s: %s is not this file's (render it again)" % [file, MANIFEST])
	var px: Variant = m.get("size", [])
	if not px is Array or (px as Array).size() != 2 or absf(float(px[0]) / float(px[1]) - ASPECT) > 0.01:
		out.append("%s: a video is 9:16, not %s" % [file, px])
	var luma: Variant = m.get("luma", [])
	if not luma is Array or (luma as Array).size() != 3:
		out.append("%s: three frames' brightness measured" % file)
	else:
		for y: Variant in luma:
			if float(y) < LUMA.x or float(y) > LUMA.y:
				out.append("%s: a frame is %s (black or blank: %.0f)" % [file, "black" if float(y) < LUMA.x else "blank",
					float(y)])
	return out


## Seconds a video plays, as Godot reads it (0 when it cannot).
static func seconds_of(path: String) -> float:
	var s := VideoStreamTheora.new()
	s.file = path
	var v := VideoStreamPlayer.new()
	v.stream = s
	var secs := v.get_stream_length()
	v.free()
	return secs


static func manifest() -> Dictionary:
	if not FileAccess.file_exists(MANIFEST):
		return {}
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
	return d if d is Dictionary else {}
