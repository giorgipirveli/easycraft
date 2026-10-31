class_name VideoKind
extends RefCounted
## The Reel Studio (owner #96, spec §5.12b): the check of a `video` actor ({kind: video, at, file, start?, w?, h?}: a clip
## of a rendered reel in a scene, its time the scene's plus `start`) and of a Short's own `video` (a cinematic reel's
## whole picture: `"video": "<file>"`, the Short's time). A file is a plain name: the reels pack's
## `assets/reels/<file>.ogv` (ReelPack). Whether the file is here and good is ReelCheck's (a quality check: on the web it
## comes later, in the background).

const MAX_START := 600.0

static var _name := RegEx.create_from_string("^[a-z][a-z0-9_]{1,39}$")


## "" when `actor` is right.
static func problem(actor: Dictionary) -> String:
	var why := name_problem(actor.get("file"))
	if why != "":
		return why
	if actor.has("start") and (typeof(actor.start) not in [TYPE_INT, TYPE_FLOAT] or float(actor.start) < 0.0
			or float(actor.start) > MAX_START):
		return "a video's start is 0-%d seconds into its file" % int(MAX_START)
	for key: String in ["w", "h"]:
		if actor.has(key):
			var most := ShortRules.STAGE.x if key == "w" else ShortRules.STAGE.y
			if typeof(actor[key]) not in [TYPE_INT, TYPE_FLOAT] or float(actor[key]) < 60.0 or float(actor[key]) > most:
				return "a video's %s is 60-%d" % [key, int(most)]
	return ""


## "" when `file` is a reel's plain name (small letters, digits and _; no folder, no extension).
static func name_problem(file: Variant) -> String:
	if not file is String or _name.search(file) == null:
		return "a video's file is its reel's plain name (2-40 small letters, digits and _), not %s" % [file]
	return ""
