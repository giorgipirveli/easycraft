class_name AvatarLook
extends RefCounted
## A player's avatar look (M3 Task 9; spec §5.9, §14.6): one AvatarCatalog name per slot plus the
## emote wheel. Saved in the profile and sent to other players as a short code (Player.look_code).
## Parsing never fails: every bad field falls back to its default on its own, so an old save or a
## tampered LAN peer can at worst wear the default. Ownership is AvatarUnlocks.wearable's job.

## M3 Task 8: 2,048 (was 1,024), so three built wearables of the busiest kind fit (WearRules.MAX_TEXT).
const MAX_CODE_LENGTH := 2048
## Field -> the catalog slot its value comes from.
const FIELDS := {
	"skin": AvatarCatalog.SKIN, "face": AvatarCatalog.FACE, "hair": AvatarCatalog.HAIR,
	"hair_color": AvatarCatalog.HAIR_COLOR, "hat": AvatarCatalog.HAT, "shirt": AvatarCatalog.SHIRT,
	"pants": AvatarCatalog.PANTS, "cape": AvatarCatalog.CAPE, "wings": AvatarCatalog.WINGS,
	"trail": AvatarCatalog.TRAIL, "outfit": AvatarCatalog.OUTFIT, "clothes": AvatarCatalog.CLOTHES,
}

# Owner 43 (spec §3c): EasyCraft's own default (new players, JUST ME): peach skin, curly brown hair, a smile with rosy
# cheeks, an orange tee, teal trousers. The old default is classic(): what every look saved before keeps.
var skin: StringName = &"peach"
var face: StringName = &"rosy"
var hair: StringName = &"curly"
var hair_color: StringName = &"brown"
var hat: StringName = &"none"
var shirt: StringName = &"orange"
var pants: StringName = &"teal"
var cape: StringName = &"none"
var wings: StringName = &"none"
var trail: StringName = &"none"
var outfit: StringName = &"none"
## Owner 48: the cut of the clothes (AvatarCatalog.CUTS), worn in the shirt and pants colours.
var clothes: StringName = &"none"
## Owner 48: the first choice (AvatarCatalog.BOY / GIRL / NEUTRAL): which starting look was picked. A
## starting point, never a lock: nothing checks it against the parts. It stays on this phone (to_code and
## the online backup leave it out; other players only need the parts).
var base: StringName = AvatarCatalog.NEUTRAL
## The emote wheel: 8 different emotes, clockwise from the top.
var emotes: Array[StringName] = AvatarCatalog.DEFAULT_WHEEL.duplicate()
## M3 Task 8 (Build-and-Wear): the child's own built wearables, WearRules slot -> its code (WearRules.from_blocks).
var builds := {}


## Owner 43: `base` fills every missing or unknown field (a saved profile passes classic(), so it looks as before).
static func from_dict(d: Variant, base: AvatarLook = null) -> AvatarLook:
	var look := base.duplicate() if base else AvatarLook.new()
	if typeof(d) != TYPE_DICTIONARY:
		return look
	for field: String in FIELDS:
		var value: Variant = (d as Dictionary).get(field)
		if AvatarCatalog.has_item(FIELDS[field], value):
			look.set(field, StringName(value))
	var b: Variant = (d as Dictionary).get("base")
	if (typeof(b) == TYPE_STRING or typeof(b) == TYPE_STRING_NAME) and AvatarCatalog.BASES.has(StringName(b)):
		look.base = StringName(b)
	look.emotes = wheel_from(d.get("emotes"))
	look.builds = builds_from(d.get("builds"))   # M3 Task 8
	return look


## Owner 43: the look every player had before EasyCraft's own default (yellow skin, a blue tee, jeans, no hair):
## a profile saved without a look, or with a field this version doesn't know, keeps it (ProfileData.from_json).
static func classic() -> AvatarLook:
	var look := AvatarLook.new()
	look.skin = &"classic"
	look.face = &"smile"
	look.hair = &"none"
	look.shirt = &"blue"
	look.pants = &"jeans"
	return look


## Owner 48: the starting look of a first choice (AvatarCatalog.STARTS), keeping `keep`'s skin tone and
## dance wheel (a child's own, whatever they pick).
static func start(start_base: StringName, keep: AvatarLook = null) -> AvatarLook:
	var look := from_dict(AvatarCatalog.STARTS.get(start_base, {}))
	look.base = start_base if AvatarCatalog.BASES.has(start_base) else AvatarCatalog.NEUTRAL
	look._keep_own(keep)
	return look


## Owner 48: a ready-made look (AvatarCatalog.PRESETS), keeping `keep`'s skin tone and dance wheel; an
## unknown preset changes nothing.
static func preset(id: StringName, keep: AvatarLook = null) -> AvatarLook:
	if not AvatarCatalog.PRESETS.has(id):
		return keep.duplicate() if keep else AvatarLook.new()
	var p: Dictionary = AvatarCatalog.PRESETS[id]
	var look := from_dict(p.look)
	look.base = p.base
	look._keep_own(keep)
	return look


func _keep_own(keep: AvatarLook) -> void:
	if keep:
		skin = keep.skin
		emotes = keep.emotes.duplicate()


## A wheel from saved data: known emotes in order, no repeats, filled up to 8 from the default wheel.
static func wheel_from(value: Variant) -> Array[StringName]:
	var wheel: Array[StringName] = []
	if typeof(value) != TYPE_ARRAY:
		return AvatarCatalog.DEFAULT_WHEEL.duplicate()
	for v: Variant in value:
		if wheel.size() >= AvatarCatalog.WHEEL_SLOTS:
			break
		if AvatarCatalog.has_item(AvatarCatalog.EMOTE, v) and not wheel.has(StringName(v)):
			wheel.append(StringName(v))
	return fill_wheel(wheel)


## Fills `wheel` up to 8 different emotes, from the default wheel first.
static func fill_wheel(wheel: Array[StringName]) -> Array[StringName]:
	for pool: Array[StringName] in [AvatarCatalog.DEFAULT_WHEEL, AvatarCatalog.items_in(AvatarCatalog.EMOTE)]:
		for e: StringName in pool:
			if wheel.size() >= AvatarCatalog.WHEEL_SLOTS:
				return wheel
			if not wheel.has(e):
				wheel.append(e)
	return wheel


func to_dict() -> Dictionary:
	var d := {}
	for field: String in FIELDS:
		d[field] = String(get(field))
	d["base"] = String(base)
	d["emotes"] = Array(emotes).map(func(e: StringName) -> String: return String(e))
	if not builds.is_empty():   # M3 Task 8 (only when worn: older codes stay the same)
		var b := {}
		for slot: StringName in builds:
			b[String(slot)] = builds[slot]
		d["builds"] = b
	return d


## The look as a short JSON code (sent with the player: Player.look_code). The first choice (base) stays
## on this phone: the parts are the look.
func to_code() -> String:
	var d := to_dict()
	d.erase("base")
	return JSON.stringify(d)


static func from_code(code: Variant) -> AvatarLook:
	if typeof(code) != TYPE_STRING or (code as String).length() > MAX_CODE_LENGTH:
		return AvatarLook.new()
	var json := JSON.new()   # JSON.parse_string would log an engine error for every bad code
	if json.parse(code) != OK:
		return AvatarLook.new()
	return from_dict(json.data)


func duplicate() -> AvatarLook:
	var copy := AvatarLook.new()
	for field: String in FIELDS:
		copy.set(field, get(field))
	copy.base = base
	copy.emotes = emotes.duplicate()
	copy.builds = builds.duplicate()   # M3 Task 8
	return copy


func equals(other: AvatarLook) -> bool:
	return other != null and to_dict() == other.to_dict()


## What to draw: colours and parts, with the clothes cut and the outfit (if any: it wins) dressing the
## body. Keys: skin, hair, hair_color, face, hat, shirt (the torso and sleeves), pants (the legs), shoes
## (alpha 0 = no shoes of their own), cape, wings, trail, pattern, pattern_color, extras (AvatarParts ids),
## hides_hair, outfit, skin_id; Owner 48: clothes (the cut worn), top and bottom (the look's own shirt and
## pants colours, for skirts and panels), sleeves (long sleeves' colour, alpha 0 = short), puff, boots,
## lashes, blush.
func resolve() -> Dictionary:
	return resolve_in(AvatarCatalog.CLOTH[shirt], AvatarCatalog.CLOTH[pants], AvatarCatalog.SKIN_TONES[skin])


## resolve() with other base colours for the top, the bottom and the skin (a bot friend's own).
func resolve_in(top: Color, bottom: Color, skin_color: Color) -> Dictionary:
	var face_style: Dictionary = AvatarCatalog.FACE_STYLES.get(face, {})
	var r := {
		"skin": skin_color, "skin_id": skin, "hair": hair,
		"hair_color": AvatarCatalog.HAIR_COLORS[hair_color], "face": face, "hat": hat,
		"shirt": top, "pants": bottom, "shoes": Color(0, 0, 0, 0),
		"cape": cape, "wings": wings, "trail": trail, "pattern": AvatarCatalog.PATTERN_NONE,
		"pattern_color": Color.WHITE, "extras": [], "hides_hair": false, "outfit": outfit,
		"clothes": &"none", "top": top, "bottom": bottom, "sleeves": Color(0, 0, 0, 0), "puff": false,
		"boots": false, "lashes": bool(face_style.get("lashes", false)), "blush": bool(face_style.get("blush", false)),
	}
	if AvatarCatalog.OUTFITS.has(outfit):
		var o: Dictionary = AvatarCatalog.OUTFITS[outfit]
		for key: String in ["shirt", "pants", "shoes", "hat", "pattern", "pattern_color", "hides_hair"]:
			r[key] = o[key]
		r.extras = (o.extras as Array).duplicate()
		if o.get("sleeves", false):
			r.sleeves = r.shirt   # Owner 36: an outfit with long sleeves (the Tin Woodman's tin arms)
	elif AvatarCatalog.CUTS.has(clothes):
		var c: Dictionary = AvatarCatalog.CUTS[clothes]
		r.clothes = clothes
		r.shirt = c.get("shirt", top)
		r.pants = c.get("legs", bottom)
		r.sleeves = r.shirt if c.get("sleeves", false) else Color(0, 0, 0, 0)
		r.puff = bool(c.get("puff", false))
		r.shoes = c.get("shoes", Color(0, 0, 0, 0))
		r.boots = bool(c.get("boots", false))
		r.extras = (c.get("extras", []) as Array).duplicate()
	r["builds"] = builds.duplicate()   # M3 Task 8: a built wearable takes its catalogue slot's place
	for slot: StringName in builds:
		r[WearRules.REPLACES[slot]] = &"none"
	return r

# --- M3 Task 8: Build-and-Wear ---------------------------------------------------------------------------

## Wears a built wearable (a WearRules code) in `slot`; a bad slot or code changes nothing.
func wear(slot: StringName, code: String) -> void:
	if WearRules.is_slot(slot) and WearRules.valid(code):
		builds[StringName(slot)] = code


func take_off(slot: StringName) -> void:
	builds.erase(StringName(slot))


## Built wearables from saved data: known slots with valid codes; anything else is dropped on its own.
static func builds_from(value: Variant) -> Dictionary:
	var out := {}
	if not value is Dictionary:
		return out
	for key: Variant in value:
		if WearRules.is_slot(key) and WearRules.valid(value[key]):
			out[StringName(key)] = value[key]
	return out
