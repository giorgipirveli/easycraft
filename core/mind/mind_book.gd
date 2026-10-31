class_name MindBook
extends RefCounted
## The learned tables of a world's species (M2 Task 18, spec §12.17): every wild creature of a species
## shares one TinyNet per world, so what one sheep learns every sheep of that world knows, and the
## goblins of a world slowly change their tactics over many nights. Saved in WorldMeta.minds as
## {species id: TinyNet.to_save()} — only tables that learned something, at most MAX_TOTAL characters
## for the whole world. The host's sandbox loads `current` with its world and saves it back.

const MAX_TOTAL := 2048
const MAX_KEY := 32

## The book of the world being played (the host's; tests make their own).
static var current := MindBook.new()

var _nets := {}                   # species id (String) -> TinyNet
var _saved := {}                  # species id -> saved text not yet given to a net


## The shared net of `species` in this world (made on first use, with its saved learning).
func net_for(species: MindSpecies) -> TinyNet:
	var key := String(species.id)
	if not _nets.has(key):
		var net := species.make_net(hash(key))
		if _saved.has(key):
			net.load_save(str(_saved[key]))
			_saved.erase(key)
		_nets[key] = net
	return _nets[key]


## For WorldMeta.minds: the tables that learned something (and saved ones no creature used yet). Owner #41: a world
## can hold more kinds than MAX_TOTAL fits (about 13 tables), so the monsters' tables come first (their tactics are
## play), then the tables that learned the most; the rest start again from their hand-made defaults.
func to_save() -> Dictionary:
	var entries: Array = []   # [monster first (0/1), -learned, key, text]
	for key: String in _nets:
		var net: TinyNet = _nets[key]
		if not net.is_fresh():
			entries.append([0 if key.begins_with("monster:") else 1, -net.learned(), key, net.to_save()])
	for key: String in _saved:
		if not _nets.has(key):
			var text := str(_saved[key])
			entries.append([0 if key.begins_with("monster:") else 1, -TinyNet.learned_in(text), key, text])
	entries.sort()
	var out := {}
	var total := 2
	for e: Array in entries:
		total = _put(out, e[2], e[3], total)
	return out


func load_save(d: Variant) -> void:
	_nets.clear()
	_saved = clean(d)


## Only well-formed entries (a short species id, a base64 table), at most MAX_TOTAL in all.
static func clean(d: Variant) -> Dictionary:
	var out := {}
	if not d is Dictionary:
		return out
	var total := 2
	for k: Variant in d:
		var key := str(k)
		var v: Variant = d[k]
		if not _valid_key(key) or not v is String or not TinyNet.is_base64(v) or (v as String).length() > 400:
			continue
		total = _put(out, key, v, total)
	return out


static func _put(out: Dictionary, key: String, text: String, total: int) -> int:
	var size := key.length() + text.length() + 6
	if total + size > MAX_TOTAL:
		return total
	out[key] = text
	return total + size


static func _valid_key(key: String) -> bool:
	if key == "" or key.length() > MAX_KEY:
		return false
	for i in key.length():
		var c := key.unicode_at(i)
		if not (c >= 97 and c <= 122 or c >= 48 and c <= 57 or c == 95 or c == 58):   # a-z 0-9 _ :
			return false
	return true
