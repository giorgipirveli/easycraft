class_name TreasureState
extends RefCounted
## What the treasure pack keeps in a world (owner feedback #42), saved inside SecretState ("more"): the dawns
## seen (a world's days: the rainbows' schedule and the wishing well's once-a-day), the rainbows so far, who
## took the pot of gold of which rainbow ("<rainbow>:<player>") and the day each player last wished. The
## vault's levers and the ghosts' riddles are SecretState.solved; chests are SecretState.opened.
## from_save never fails: anything broken is dropped. The oldest entries go first past MAX_ENTRIES.

const MAX_ENTRIES := 512

var dawns := 0
var rainbows := 0
var pots := {}                    # "<rainbow>:<player>" -> true
var wishes := {}                  # player -> the day (dawns) of their last wish


## Player `who` takes the pot of rainbow `n`; true the first time.
func take_pot(n: int, who: String) -> bool:
	var key := "%d:%s" % [n, who]
	if pots.has(key):
		return false
	pots[key] = true
	_trim(pots)
	return true


func took_pot(n: int, who: String) -> bool:
	return pots.has("%d:%s" % [n, who])


func to_save() -> Dictionary:
	_trim(wishes)
	return {"dawns": dawns, "rainbows": rainbows, "pots": pots.keys(), "wishes": wishes.duplicate()}


static func from_save(data: Variant) -> TreasureState:
	var t := TreasureState.new()
	if not data is Dictionary:
		return t
	var d: Dictionary = data
	t.dawns = _count(d.get("dawns"))
	t.rainbows = _count(d.get("rainbows"))
	var p: Variant = d.get("pots")
	if p is Array:
		for e: Variant in p:
			if e is String and e != "":
				t.pots[e] = true
	var w: Variant = d.get("wishes")
	if w is Dictionary:
		for who: Variant in w:
			var day: Variant = w[who]
			if who is String and typeof(day) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(day)) and absf(float(day)) < 1.0e9:
				t.wishes[who] = int(day)
	_trim(t.pots)
	_trim(t.wishes)
	return t


static func _trim(d: Dictionary) -> void:
	while d.size() > MAX_ENTRIES:
		d.erase(d.keys()[0])


static func _count(v: Variant) -> int:
	return maxi(int(v), 0) if typeof(v) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(v)) and absf(float(v)) < 1.0e9 else 0
