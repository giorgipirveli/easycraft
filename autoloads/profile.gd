extends Node
## The player's profile, loaded at start and saved atomically (a kill mid-write keeps the old file).

const PATH := "user://profile.json"

## The avatar look changed (the avatar editor saved it): this game's player wears it (M3 Task 9).
signal avatar_changed
## The profile was saved (M4 Wave 2, agent F: ProfileSync backs it up to the server, debounced).
signal saved

var data := ProfileData.new()
var path := PATH   # tests use their own file
## Owner #67: each group of the child's choices as last loaded or saved (ProfileBackup.group_texts): a save
## stamps the groups that changed since, so the newest choice wins per group when the account's copies merge.
var _choices := {}


func _ready() -> void:
	load_profile()


func load_profile() -> void:
	data = _read()
	_choices = ProfileBackup.group_texts(data)


## Owner #99, #105 (LOG OUT, LOG IN as another account, DELETE: OnlineService.forget_player): the profile file was
## replaced or removed; it is read into the same object the game holds on to (every screen and service keeps Profile.data). A new player (no file yet) starts fresh but keeps this
## device's own settings (ProfileBackup.DEVICE_ONLY_SETTINGS: the graphics, the view distance, the install card's answers).
func reload() -> void:
	var device := {}
	for key: String in ProfileBackup.DEVICE_ONLY_SETTINGS:
		if data.settings.has(key):
			device[key] = data.settings[key]
	var fresh := JsonStore.read_text(path) == ""
	var loaded := _read()
	if fresh:
		loaded.settings.merge(device, true)
	ProfileBackup.copy_into(data, loaded)
	_choices = ProfileBackup.group_texts(data)
	avatar_changed.emit()


func _read() -> ProfileData:
	var text := JsonStore.read_text(path)
	# M5 Task 3: the first start picks the graphics preset for this phone (LOW on weak ones)
	var p := ProfileData.from_json(text) if text != "" else ProfileData.first_start(
		int(OS.get_memory_info().get("physical", -1)), OS.get_processor_count(),
		PlatformRules.starts_low_graphics(PlatformRules.current()))   # M7: phones and tablets in a browser
	if text == "":   # P5 (owner #108): the Quest APK's first start: vr_plus on a Quest 3 / 3S, vr on a Quest 2
		p.settings.graphics = GraphicsPreset.first_preset(p.settings.graphics, PlatformRules.current(), GraphicsPreset.model())
	if not AgeBand.restrictions and p.age_band == AgeBand.UNDER_13:
		p.age_band = AgeBand.TEEN_PLUS   # the owner, 2026-09-29: no age limits for now (AgeBand.restrictions)
	return p


func save() -> void:
	var now := int(Time.get_unix_time_from_system())
	_choices = ProfileBackup.stamp_changes(data, _choices, now)   # owner #67
	data.updated_at = now   # the newer of phone and backup wins (ProfileBackup)
	var err := JsonStore.write_atomic(path, data.to_json())
	if err != OK:
		push_warning("Profile save failed: %s" % error_string(err))
	saved.emit()
