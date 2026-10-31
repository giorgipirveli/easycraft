class_name UpdateRules
extends RefCounted
## Owner #123 (2026-10-17): "make windows and phone use same version always … i mean game version but of course mobile
## should be mobile". The web game is deployed from the newest code almost every day; an installed Android app (the
## phone's APK or the Play AAB, the Quest's APK) took a new game only from a new APK. Now every deploy also puts a
## **patch pack** for each Android build in the wild on our server, under a signed manifest; the app's first autoload
## (autoloads/updater.gd) downloads the patch for its own build in the background and starts with it next time.
## These are the pure rules: the manifest and its signature, where files come from, what to download for this app, the
## Wi-Fi rule, the start (a verified pack, two tries, the fall-back to the app's own build), and the version and input map
## a pack brings in its project.binary. docs/devlog/parts/same-version.md has the spike, the rulings and the release rule.
##
## Part of the updater's own set (with update_flow.gd and update_fetch.gd): the first autoload preloads it before any
## pack is in, so a pack never changes it (a change here reaches an app only in a new APK/AAB), and it names no other
## script of the game (tests/unit/test_updater.gd).

## Our server; the updates live in the web game's folder, which Caddy already serves (server/deploy/caddy/Caddyfile).
const SERVER := "https://178-104-20-64.sslip.io"
## Each kind of app has its own folder: the phone's packs have ETC2 pictures and the `android` features, the Quest's add
## its `quest` feature and the OpenXR vendors' scripts.
const FOLDERS := {"phone": "/play/android/", "quest": "/play/quest/"}
const MANIFEST_FILE := "update.json"
## The manifest's format this app reads; a newer one is ignored (that app keeps what it has).
const FORMAT := 1
## The keys the deploy signs with (tools/android_update.py, the private half in ~/.config/easycraft/update-signing.pem on
## the lead's PC, never in git). A new key reaches apps only in a new APK/AAB: keep the old one listed until then.
const PUBLIC_KEYS := {
	"k1": """-----BEGIN PUBLIC KEY-----
MIIBojANBgkqhkiG9w0BAQEFAAOCAY8AMIIBigKCAYEAz7vsALLN4qL7BgHwCLkN
iKkys8bVts+b9rJmK/LE3oE5HaauiJvwlResdf3CdvMm+lghe230td+tHkHvCVD7
UTybDw2Liya+h0DQMH9rHRzk1BVoIo2yT9mLFRM7YCuvT+I3/aar/vcP4WfDFfBZ
AOPE3aoMzv7744CxD6sXWhNL0GvnxTgpTmv2M7Q5JErVvftT6NWBfMJBeIMyToa/
JI6zuIm1xzr0ZS7ZQdewhriFcfKoxjionWqVid/9OlDSvT5nnuySHiCdbN+KPVmJ
F6CLsfENmDeMbeIT6fySA/p9RfAnoktJ+4UyGFPj2O6NHp01IbNQc/OVTtnnOAcE
VZW5ohS/0yBEs0o+xgI4my2ZA474161TnNeedX0zXnZqaM545dCBuVf7+mbdgTeJ
D8Gdo2umBd4MqDo9UVrvCOanyNuorUeL6UUF5DX8X+zpxKMbHIlgPUZgoO3lmo7h
LasT3TotYD7hYzZqL6WizCArg6h7+CTfKYHaQQu6dCsHAgMBAAE=
-----END PUBLIC KEY-----
""",
}

## Ruling 2: a pack that started the game this many times without the menu ever showing is dropped (one start can be a
## child closing the app while it loads; two in a row is the pack).
const MAX_TRIES := 2
## The games that failed here are remembered (never downloaded again for this app), the newest this many.
const KEEP_BAD := 20
## Ruling 4: up to this size a patch downloads on any network (a day's change is 1-2.5 MB); a bigger one waits for an
## unmetered network (Wi-Fi) unless the grown-ups allowed big updates on mobile data.
const SMALL_BYTES := 32 * 1024 * 1024
## Never a file bigger than this (the whole phone game is 147 MB).
const MAX_BYTES := 400 * 1024 * 1024

## The menu's line when a newer game is downloaded and checked (ui/menus/update_note.gd).
const READY_WORDS := "A new EasyCraft is ready: it starts next time"

## Why the background check downloads nothing (Updater.status).
const UP_TO_DATE := "up_to_date"
const ALREADY_READY := "already_ready"
const FAILED_HERE := "failed_here_before"
const TOO_OLD := "too_old"           # the store has a newer app: online play's version check says so
const NO_PATCH := "no_patch"         # a build the deploy does not know (a developer's)
const OTHER_ENGINE := "other_engine"
const OTHER_APP := "other_app"
const OLDER_MANIFEST := "older_manifest"
const WAITS_FOR_WIFI := "waits_for_wifi"


## "4.7.2.stable" from Engine.get_version_info() (the deploy's `godot --version` gives the same first four parts).
static func engine_id(info: Dictionary) -> String:
	return "%d.%d.%d.%s" % [int(info.get("major", 0)), int(info.get("minor", 0)), int(info.get("patch", 0)),
		str(info.get("status", ""))]


static func kind_of(quest: bool) -> String:
	return "quest" if quest else "phone"


static func manifest_url(kind: String) -> String:
	return SERVER + FOLDERS[kind] + MANIFEST_FILE if FOLDERS.has(kind) else ""


## The address of a pack in this kind's folder, or "" when the name is not a plain pack name.
static func file_url(kind: String, file: String) -> String:
	if not FOLDERS.has(kind) or not safe_file(file):
		return ""
	return SERVER + FOLDERS[kind] + file


## Ruling 3: only HTTPS, only our server, only the update folders.
static func is_our_url(url: String) -> bool:
	for kind: String in FOLDERS:
		var start: String = SERVER + FOLDERS[kind]
		if url.begins_with(start) and safe_file(url.trim_prefix(start)) or url == start + MANIFEST_FILE:
			return true
	return false


## A plain pack name: letters, digits, dots, dashes and underscores, ending in ".pck" (no folder, no "..").
static func safe_file(name: String) -> bool:
	if not name.ends_with(".pck") or name.length() > 120 or name.begins_with("."):
		return false
	for c in name:
		if not (c >= "a" and c <= "z" or c >= "A" and c <= "Z" or c >= "0" and c <= "9" or c in ["-", "_", "."]):
			return false
	return not name.contains("..")


## The manifest in its envelope {"key", "signed", "signature"}: the signature (RSA, SHA-256, base64) must be the key's
## over `signed`'s UTF-8 bytes, and `signed` must be a whole manifest. {"ok": true, "manifest": {...}} or
## {"ok": false, "why": "..."}.
static func open_envelope(text: String, keys: Dictionary = PUBLIC_KEYS) -> Dictionary:
	var json := JSON.new()   # its parse() reports a bad file quietly (JSON.parse_string logs an engine error)
	if text.is_empty() or json.parse(text) != OK or not json.data is Dictionary:
		return {"ok": false, "why": "not an envelope"}
	var env: Dictionary = json.data
	var key_id: Variant = env.get("key")
	var signed: Variant = env.get("signed")
	var signature: Variant = env.get("signature")
	if not (key_id is String and keys.has(key_id) and signed is String and signature is String):
		return {"ok": false, "why": "no signature by a key this app has"}
	var key := CryptoKey.new()
	if key.load_from_string(keys[key_id], true) != OK:
		return {"ok": false, "why": "the app's key"}
	var sig := Marshalls.base64_to_raw(signature) if _is_base64(signature) else PackedByteArray()
	if sig.is_empty() or not Crypto.new().verify(HashingContext.HASH_SHA256, (signed as String).sha256_buffer(), sig, key):
		return {"ok": false, "why": "the signature does not match"}
	if json.parse(signed) != OK:
		return {"ok": false, "why": "the signed text is not JSON"}
	var why := check_manifest(json.data)
	if why != "":
		return {"ok": false, "why": why}
	return {"ok": true, "manifest": json.data}


## "" when `m` is a whole manifest of this format, else what is wrong:
## {"format": 1, "kind": "phone", "serial": <the deploy's time>, "engine": "4.7.2.stable",
##  "game": {"commit", "date", "version", "net"}, "min_base": "1.0.6",
##  "bases": {"<a build's commit>": {"file": "phone-<base>-<game>.pck", "size": <bytes>, "sha256": "<64 hex>"}}}
static func check_manifest(m: Variant) -> String:
	if not m is Dictionary:
		return "not a manifest"
	var d: Dictionary = m
	if not _is_int(d.get("format")) or int(d.format) != FORMAT:
		return "another format"
	if not FOLDERS.has(d.get("kind")):
		return "an unknown kind of app"
	if not _is_int(d.get("serial")) or int(d.serial) <= 0:
		return "no serial"
	if not (d.get("engine") is String and not str(d.engine).is_empty()):
		return "no engine"
	var game: Variant = d.get("game")
	if not (game is Dictionary and is_hex(game.get("commit")) and game.get("version") is String):
		return "no game"
	if not d.get("min_base") is String:
		return "no lowest base"
	if not d.get("bases") is Dictionary:
		return "no bases"
	for base: Variant in d.bases:
		var e: Variant = d.bases[base]
		if not (is_hex(base) and e is Dictionary):
			return "a base"
		if not (e.get("file") is String and safe_file(e.file)):
			return "a file's name"
		if not _is_int(e.get("size")) or int(e.size) <= 0 or int(e.size) > MAX_BYTES:
			return "a file's size"
		if not (e.get("sha256") is String and str(e.sha256).length() == 64 and is_hex(e.sha256, 64, 64)):
			return "a file's SHA-256"
	return ""


## What the background check does with a verified manifest for this app (`base`: kind, commit, version, engine) and what
## it has (`state`, user://update/state.json): {"do": "download", "entry", "game", "serial"} or {"do": "nothing", "why"}.
static func plan_download(m: Dictionary, base: Dictionary, state: Dictionary, metered: bool) -> Dictionary:
	if m.kind != base.kind:
		return _nothing(OTHER_APP)
	if m.engine != base.engine:
		return _nothing(OTHER_ENGINE)
	if int(m.serial) < int(state.get("serial", 0)):
		return _nothing(OLDER_MANIFEST)
	var target := str(m.game.commit)
	if target == running_commit(state, base):
		return _nothing(UP_TO_DATE)
	if target == str((state.get("ready", {}) as Dictionary).get("commit", "")):
		return _nothing(ALREADY_READY)
	if (state.get("bad", []) as Array).has(target):
		return _nothing(FAILED_HERE)
	if version_less(str(base.version), str(m.min_base)):
		return _nothing(TOO_OLD)
	var entry: Variant = (m.bases as Dictionary).get(base.commit)
	if not entry is Dictionary:
		return _nothing(NO_PATCH)
	if not may_download(int(entry.size), metered, bool(state.get("big_on_mobile", false))):
		return _nothing(WAITS_FOR_WIFI)
	return {"do": "download", "entry": entry, "game": m.game, "serial": int(m.serial)}


## The game this app runs now: the pack in use, or its own build.
static func running_commit(state: Dictionary, base: Dictionary) -> String:
	var active: Variant = state.get("active")
	return str(active.get("commit", "")) if active is Dictionary else str(base.get("commit", ""))


## Ruling 4: small patches on any network; a big one on an unmetered network, or when the grown-ups allowed it.
static func may_download(size: int, metered: bool, big_on_mobile: bool) -> bool:
	return size <= SMALL_BYTES or not metered or big_on_mobile


## After a download whose size and SHA-256 matched: it waits for the next start. {"state", "drop": [files]}.
static func keep_ready(state: Dictionary, plan: Dictionary) -> Dictionary:
	var s := state.duplicate(true)
	var drop: Array[String] = []
	var old: Variant = s.get("ready")
	if old is Dictionary and str(old.get("file", "")) != str(plan.entry.file):
		drop.append(str(old.file))
	s.ready = {"commit": str(plan.game.commit), "file": str(plan.entry.file), "sha256": str(plan.entry.sha256),
		"size": int(plan.entry.size), "version": str(plan.game.get("version", "")), "date": str(plan.game.get("date", ""))}
	return {"state": s, "drop": drop}


## At the start, before any pack is in: {"state" (save it before loading), "load" (the pack to load, {} for the app's own
## build), "drop" (files to delete), "fell_back" (a pack was dropped after MAX_TRIES bad starts)}.
static func start_plan(state: Dictionary, base: Dictionary) -> Dictionary:
	var s := state.duplicate(true)
	var drop: Array[String] = []
	var had: Variant = s.get("base")
	if not (had is Dictionary and had.get("kind") == base.kind and had.get("commit") == base.commit
			and had.get("engine") == base.engine):
		# A new app from the store (or a first start): the packs were made for the old one.
		for k: String in ["active", "ready"]:
			if s.get(k) is Dictionary:
				drop.append(str(s[k].get("file", "")))
		var fresh := {"base": base.duplicate()}
		for keep: String in ["serial", "big_on_mobile"]:
			if s.has(keep):
				fresh[keep] = s[keep]
		s = fresh
	if s.get("ready") is Dictionary:
		var ready: Dictionary = s.ready
		s.erase("ready")
		if s.get("active") is Dictionary and str(s.active.get("file", "")) != str(ready.get("file", "")):
			drop.append(str(s.active.get("file", "")))
		ready.tries = 0
		s.active = ready
	var to_load := {}
	var fell_back := false
	if s.get("active") is Dictionary:
		if int(s.active.get("tries", 0)) >= MAX_TRIES:
			drop.append(str(s.active.get("file", "")))
			s = drop_active(s, true)
			fell_back = true
		else:
			s.active.tries = int(s.active.get("tries", 0)) + 1
			to_load = s.active.duplicate()
	return {"state": s, "load": to_load, "drop": drop.filter(func(f: String) -> bool: return not f.is_empty()),
		"fell_back": fell_back}


## The pack in use goes (its file is the caller's to delete); `bad`: it failed to start the game, never again here.
static func drop_active(state: Dictionary, bad: bool) -> Dictionary:
	var s := state.duplicate(true)
	if bad and s.get("active") is Dictionary:
		var list: Array = s.get("bad", []).duplicate()
		list.append(str(s.active.get("commit", "")))
		s.bad = list.slice(maxi(0, list.size() - KEEP_BAD))
	s.erase("active")
	return s


## The menu showed: the pack in use started the game.
static func menu_reached(state: Dictionary) -> Dictionary:
	var s := state.duplicate(true)
	if s.get("active") is Dictionary:
		s.active.tries = 0
	return s


## "1.0.9" < "1.0.10": part by part as numbers.
static func version_less(a: String, b: String) -> bool:
	var pa := a.split(".")
	var pb := b.split(".")
	for i in maxi(pa.size(), pb.size()):
		var x := pa[i].to_int() if i < pa.size() else 0
		var y := pb[i].to_int() if i < pb.size() else 0
		if x != y:
			return x < y
	return false


## project.binary (the engine's settings file) as {key: the value's encoding}: "ECFG", a u32 count, then for each
## setting a u32 key length, the key (UTF-8), a u32 value length and encode_variant's bytes (with objects). {} for a
## missing or broken file.
static func read_project_binary(b: PackedByteArray) -> Dictionary:
	var out := {}
	if b.size() < 8 or b.slice(0, 4).get_string_from_ascii() != "ECFG":
		return out
	var count := b.decode_u32(4)
	var at := 8
	for i in count:
		if at + 4 > b.size():
			return {}
		var kl := b.decode_u32(at)
		if at + 4 + kl + 4 > b.size():
			return {}
		var key := b.slice(at + 4, at + 4 + kl).get_string_from_utf8()
		at += 4 + kl
		var vl := b.decode_u32(at)
		if at + 4 + vl > b.size():
			return {}
		out[key] = b.slice(at + 4, at + 4 + vl)
		at += 4 + vl
	return out


## What the pack's project.binary changes that the running game can take (the engine read its own at start): the version
## and the input map. {"version": "" or the pack's, "set": {key: value}, "erase": [keys]}. A built-in `ui_` action the
## pack no longer overrides keeps its current value (its default is the engine's); every other setting needs a new APK
## (the deploy refuses a patch that changes one: tools/android_update.py).
static func project_changes(base_raw: Dictionary, pack_raw: Dictionary) -> Dictionary:
	var out := {"version": "", "set": {}, "erase": []}
	if pack_raw.is_empty():
		return out
	const VERSION := "application/config/version"
	if pack_raw.has(VERSION) and pack_raw[VERSION] != base_raw.get(VERSION, PackedByteArray()):
		var v: Variant = bytes_to_var(pack_raw[VERSION])
		if v is String:
			out.version = v
	for k: String in pack_raw:
		if k.begins_with("input/") and pack_raw[k] != base_raw.get(k, PackedByteArray()):
			out.set[k] = bytes_to_var_with_objects(pack_raw[k])
	for k: String in base_raw:
		if k.begins_with("input/") and not k.begins_with("input/ui_") and not pack_raw.has(k):
			out.erase.append(k)
	return out


static func is_hex(s: Variant, shortest: int = 8, longest: int = 40) -> bool:
	if not s is String or (s as String).length() < shortest or (s as String).length() > longest:
		return false
	for c in s:
		if not "0123456789abcdef".contains(c):
			return false
	return true


## Only base64's letters, in fours (base64_to_raw logs an engine error for anything else).
static func _is_base64(s: String) -> bool:
	if s.is_empty() or s.length() % 4 != 0:
		return false
	for c in s:
		if not (c >= "a" and c <= "z" or c >= "A" and c <= "Z" or c >= "0" and c <= "9" or c in ["+", "/", "="]):
			return false
	return true


static func _is_int(v: Variant) -> bool:
	return v is int or v is float and is_equal_approx(v, roundf(v))


static func _nothing(why: String) -> Dictionary:
	return {"do": "nothing", "why": why}
