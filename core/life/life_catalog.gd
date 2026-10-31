class_name LifeCatalog
extends RefCounted
## Owner #112, #115 (docs/design/life-skills.md §2, §7; docs/design/success-skills.md; spec §27): the Life tab's map,
## data/life/life.json: {areas: [{id, title, icon (LifeIcons), strand ("living": Living well; "success": Success),
## colour}], units: [{id, area, track, ...}]}. A unit is one of:
## - Life's own: {title, goals, file (under data/life/: the School's lesson format, Curriculum.parse_content),
##   experience (its "Try it" opens that Experience on the unit's track)}; its id "life.<area>.<name>"; its progress in
##   ProfileData.life (LifeData.units);
## - one of the School's real lessons: {school: true} with the School's id; its title, goals and progress are the
##   School's (one unit, one reward);
## - "coming soon": {title, goals, soon: the Experience it waits for (not built yet)}.
## Words may hold the region's {number} (filled by content and goals with the region given). Read once and kept.

const PATH := "res://data/life/life.json"
const DIR := "res://data/life"
const STRANDS: Array[String] = ["living", "success"]
const STRAND_TITLES := {"living": "LIVING WELL", "success": "SUCCESS"}
const TRACK_TITLES := {"little": "LITTLE", "middle": "MIDDLE", "big": "BIG"}
const TRACK_AGES := {"little": "about 6 to 8", "middle": "about 9 to 11", "big": "12 and up"}
const MAX_TITLE := 40

static var _data := {}
static var _content := {}


static func data() -> Dictionary:
	if _data.is_empty():
		var json := JSON.new()
		var text := FileAccess.get_file_as_string(PATH) if FileAccess.file_exists(PATH) else ""
		_data = json.data if text != "" and json.parse(text) == OK and json.data is Dictionary else {"areas": [], "units": []}
	return _data


static func clear_cache() -> void:
	_data = {}
	_content.clear()


static func areas() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for a: Variant in data().get("areas", []):
		if a is Dictionary:
			out.append(a)
	return out


static func area(id: String) -> Dictionary:
	for a in areas():
		if str(a.id) == id:
			return a
	return {}


static func areas_of(strand: String) -> Array[Dictionary]:
	return areas().filter(func(a: Dictionary) -> bool: return str(a.get("strand", "")) == strand)


static func all_units() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for u: Variant in data().get("units", []):
		if u is Dictionary:
			out.append(u)
	return out


static func units(area_id: String, track: String) -> Array[Dictionary]:
	return all_units().filter(func(u: Dictionary) -> bool:
		return str(u.get("area", "")) == area_id and str(u.get("track", "")) == track)


static func unit(id: String) -> Dictionary:
	for u in all_units():
		if str(u.id) == id:
			return u
	return {}


static func is_school(id: String) -> bool:
	return bool(unit(id).get("school", false))


static func is_soon(id: String) -> bool:
	return unit(id).has("soon")


static func experience_of(id: String) -> String:
	return str(unit(id).get("experience", ""))


## Life L2, Life Town: the Life unit that tries Experience `exp_id` on `track` ("" for none).
static func experience_unit(exp_id: String, track: String) -> String:
	for u in all_units():
		if str(u.get("experience", "")) == exp_id and str(u.get("track", "")) == track:
			return str(u.id)
	return ""


static func title(id: String) -> String:
	if is_school(id):
		return str(Curriculum.unit(id).get("title", ""))
	return str(unit(id).get("title", ""))


static func goals(id: String, region: String) -> Array[String]:
	var src: Array = Curriculum.unit(id).get("goals", []) if is_school(id) else unit(id).get("goals", [])
	var v := {"number": LifeRegion.number(region)}
	var out: Array[String] = []
	for g: Variant in src:
		out.append(LifeExperience.fill(str(g), v))
	return out


## A unit's lesson and exercises (the School's content format), its {number} filled; {} for "coming soon".
static func content(id: String, region: String = LifeRegion.DEFAULT) -> Dictionary:
	if is_school(id):
		return Curriculum.content(id)
	var key := "%s|%s" % [id, region]
	if not _content.has(key):
		var file := str(unit(id).get("file", ""))
		var text := FileAccess.get_file_as_string(DIR.path_join(file)) if file != "" and FileAccess.file_exists(
			DIR.path_join(file)) else ""
		var parsed := Curriculum.parse_content(id, text)
		_content[key] = LifeExperience.resolve(parsed, {"number": LifeRegion.number(region)}) if not parsed.is_empty() else {}
	return _content[key]


static func has_content(id: String) -> bool:
	return not content(id).is_empty()


static func track_words(track: String) -> String:
	return str(TRACK_TITLES.get(track, track.to_upper()))


static func track_ages(track: String) -> String:
	return str(TRACK_AGES.get(track, ""))


## What is wrong with the catalog ([] when nothing).
static func problems() -> Array[String]:
	var out: Array[String] = []
	var ids := {}
	for a in areas():
		if str(a.get("title", "")) == "" or not STRANDS.has(str(a.get("strand", ""))) or not LifeIcons.has(str(a.get("icon", ""))):
			out.append("area %s needs a title, a strand and a known icon" % a.get("id"))
	if areas_of("living").size() != 8 or areas_of("success").size() < 2:   # owner #115: the Success strand grows (S2: 6)
		out.append("the Life map has %d areas: Living well's 8 and Success's (2 or more)" % areas().size())
	for u in all_units():
		var id := str(u.get("id", ""))
		if ids.has(id):
			out.append("%s twice" % id)
		ids[id] = true
		if area(str(u.get("area", ""))).is_empty() or not LifeData.valid_track(str(u.get("track", ""))):
			out.append("%s: a bad area or track" % id)
		if bool(u.get("school", false)):
			if not SchoolData.valid_id(id) or Curriculum.unit(id).is_empty() or not Curriculum.has_content(id):
				out.append("%s is not a written School unit" % id)
			continue
		if not LifeData.valid_unit_id(id):
			out.append("%s: a bad Life unit id" % id)
		if title(id) == "" or title(id).length() > MAX_TITLE or (u.get("goals", []) as Array).is_empty():
			out.append("%s needs a short title and its goals" % id)
		if u.has("soon"):
			if u.has("file") or LifeExperience.IDS.has(str(u.soon)):
				out.append("%s: coming soon only waits for an Experience not built yet" % id)
			continue
		if not LifeExperience.IDS.has(str(u.get("experience", ""))):
			out.append("%s: its Experience %s is not known" % [id, u.get("experience")])
		if content(id).is_empty():
			out.append("%s: its file %s is missing or not its content" % [id, u.get("file")])
	for a in areas():
		for track in LifeData.TRACKS:
			if units(str(a.id), track).is_empty():
				out.append("%s has nothing on the %s track" % [a.id, track])
	return out
