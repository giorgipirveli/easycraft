class_name TheaterChannels
extends RefCounted
## The Shorts Theater's curated channel list (spec §5.12, §14.12; M3 Task 17; owner #89). The game plays the list
## the server keeps (module 0.2.17, TheaterFeed keeps the last one on the device), else the one bundled with it,
## `data/theater/channels.json`. parse never fails and fails closed: a list it can't read, or one without
## `"enabled": true`, hides the Theater (the kill-switch). Every id is checked per platform, so no text from the
## list can reach the player's page as code.
##
## Result: {enabled: bool, source: "sample" | "bundled" | "server", channels: [{id, title, platform, color, icon,
## videos: [{id, title, made_for_kids, from}]}]}. EasyCraft TV always comes first.

const YOUTUBE := &"youtube"
const TIKTOK := &"tiktok"
const PLATFORMS: Array[StringName] = [YOUTUBE, TIKTOK]
const EASYCRAFT_TV := "easycraft_tv"
## "sample": placeholder ids (the rules' tests; phones never play it). "bundled": the real list shipped with the
## game. "server": the real list the server keeps.
const SOURCE_SAMPLE := "sample"
const SOURCE_BUNDLED := "bundled"
const SOURCE_SERVER := "server"
const BUNDLED_PATH := "res://data/theater/channels.json"
const SAMPLE_PATH := "res://data/theater/sample_channels.json"
const MAX_CHANNELS := 12
const MAX_VIDEOS := 50
const MAX_TITLE := 40
const MAX_FROM := 30
const DEFAULT_COLOR := Color("3a7be8")
## The pictures a channel's tab can show (TheaterIcons draws them); the server takes the same names.
const ICONS: Array[StringName] = [&"tv", &"planet", &"flask", &"paw", &"gear", &"note", &"palette", &"pyramid", &"star"]
const DEFAULT_ICON := &"tv"

static var _channel_id := RegEx.create_from_string("^[a-z0-9_]{1,32}$")
static var _youtube_id := RegEx.create_from_string("^[A-Za-z0-9_-]{11}$")
static var _tiktok_id := RegEx.create_from_string("^[0-9]{6,25}$")


## The list that shows nothing: the Theater stays hidden.
static func closed() -> Dictionary:
	return {"enabled": false, "source": SOURCE_SAMPLE, "channels": []}


static func load_path(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return closed()
	return parse(FileAccess.get_file_as_string(path))


static func parse(text: String) -> Dictionary:
	var json := JSON.new()
	if text == "" or json.parse(text) != OK or not json.data is Dictionary:
		return closed()
	var d: Dictionary = json.data
	var out := closed()
	var flag: Variant = d.get("enabled")
	out.enabled = typeof(flag) == TYPE_BOOL and flag == true
	var source: Variant = d.get("source")
	if typeof(source) == TYPE_STRING and source in [SOURCE_SERVER, SOURCE_BUNDLED]:
		out.source = source
	var list: Variant = d.get("channels")
	if not list is Array:
		out.enabled = false
		return out
	var channels: Array[Dictionary] = []
	var seen := {}
	for entry: Variant in list:
		var c := _parse_channel(entry)
		if c.is_empty() or seen.has(c.id):
			continue
		seen[c.id] = true
		if c.id == EASYCRAFT_TV:
			channels.push_front(c)
		else:
			channels.append(c)
		if channels.size() >= MAX_CHANNELS:
			break
	out.channels = channels
	return out


## Real videos (the bundled list or the server's), not the sample's placeholders.
static func is_real(list: Dictionary) -> bool:
	return list.get("source") in [SOURCE_BUNDLED, SOURCE_SERVER]


static func is_video_id(platform: StringName, id: String) -> bool:
	match platform:
		YOUTUBE:
			return _youtube_id.search(id) != null
		TIKTOK:
			return _tiktok_id.search(id) != null
	return false


static func _parse_channel(entry: Variant) -> Dictionary:
	if not entry is Dictionary:
		return {}
	var e: Dictionary = entry
	var id := str(e.get("id", "")) if typeof(e.get("id")) == TYPE_STRING else ""
	var platform := StringName(str(e.get("platform", "")))
	if _channel_id.search(id) == null or not PLATFORMS.has(platform) or not e.get("videos") is Array:
		return {}
	var videos: Array[Dictionary] = []
	var seen := {}
	for v: Variant in e.videos:
		if not v is Dictionary:
			continue
		var vid := str(v.get("id", "")) if typeof(v.get("id")) == TYPE_STRING else ""
		if not is_video_id(platform, vid) or seen.has(vid):
			continue
		seen[vid] = true
		var kids: Variant = v.get("made_for_kids")
		var from: Variant = v.get("from")
		videos.append({"id": vid, "title": _title(v.get("title"), "Video"),
			"made_for_kids": typeof(kids) == TYPE_BOOL and kids == true,
			"from": _capped(from, MAX_FROM) if typeof(from) == TYPE_STRING else ""})
		if videos.size() >= MAX_VIDEOS:
			break
	if videos.is_empty():
		return {}
	var color := DEFAULT_COLOR
	var hex: Variant = e.get("color")
	if typeof(hex) == TYPE_STRING and Color.html_is_valid(hex):
		color = Color.html(hex)
	var icon := DEFAULT_ICON
	var named: Variant = e.get("icon")
	if typeof(named) == TYPE_STRING and ICONS.has(StringName(named)):
		icon = StringName(named)
	return {"id": id, "title": _title(e.get("title"), "Channel"), "platform": platform, "color": color, "icon": icon,
		"videos": videos}


## A trimmed, capped title; `fallback` when there is nothing to show.
static func _title(value: Variant, fallback: String) -> String:
	var t := ""
	if typeof(value) == TYPE_STRING:
		t = value
	elif typeof(value) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(value)):
		var f := float(value)
		t = str(int(f)) if f == floorf(f) and absf(f) < 1e15 else str(f)   # JSON numbers are floats: 7, not 7.0
	t = _capped(t, MAX_TITLE)
	return t if t != "" else fallback


static func _capped(text: String, most: int) -> String:
	return text.strip_edges().left(most).strip_edges()
