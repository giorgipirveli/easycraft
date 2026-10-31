class_name DeviceId
extends RefCounted
## This install's id for signing in to the game server (Nakama device authentication, spec §5.13:
## no password, the account is bound to the device). A random UUID made on first use and kept in
## its own file, never in profile.json: a profile backup restored on another phone (M4, §7.4) must
## not carry this phone's id. It is not a hardware id (no Android ID), so nothing identifies the
## child's device; reinstalling makes a new account until account linking arrives (§5.13, later).

const PATH := "user://device_id.json"
const MIN_LENGTH := 10    # Nakama refuses device ids outside 10-128 bytes
const MAX_LENGTH := 128

const _ALLOWED := "^[A-Za-z0-9_-]+$"


## A new random UUID (version 4).
static func generate() -> String:
	var bytes := Crypto.new().generate_random_bytes(16)
	bytes[6] = (bytes[6] & 0x0f) | 0x40   # version 4
	bytes[8] = (bytes[8] & 0x3f) | 0x80   # RFC 4122 variant
	var hex := bytes.hex_encode()
	return "%s-%s-%s-%s-%s" % [hex.substr(0, 8), hex.substr(8, 4), hex.substr(12, 4), hex.substr(16, 4), hex.substr(20, 12)]


## Whether Nakama accepts `id` as a device id (and nothing odd was stored).
static func is_valid(id: String) -> bool:
	return id.length() >= MIN_LENGTH and id.length() <= MAX_LENGTH and RegEx.create_from_string(_ALLOWED).search(id) != null


## The id kept at `path`; a missing, broken or refused one is replaced by a new id, which is kept
## (crash-safe, JsonStore). If it can't be written, the new id is still used for this session.
static func load_or_create(path: String = PATH) -> String:
	var text := JsonStore.read_text(path)
	if text != "":
		var json := JSON.new()
		if json.parse(text) == OK and typeof(json.data) == TYPE_DICTIONARY:
			var stored := str((json.data as Dictionary).get("device_id", ""))
			if is_valid(stored):
				return stored
	var id := generate()
	var err := JsonStore.write_atomic(path, JSON.stringify({"device_id": id}))
	if err != OK:
		push_warning("DeviceId: could not keep the device id at %s (%s); the next start signs in as a new player" % [path, error_string(err)])
	return id
