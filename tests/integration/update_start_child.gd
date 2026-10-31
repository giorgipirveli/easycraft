extends SceneTree
## Owner #123, tests/integration/test_update_flow.gd's helper (not a test): one start of the updater
## (autoloads/updater.gd) in a Godot of its own, as a phone's next start is a new process; a pack it loads stays in this
## process only. Prints one line: UPDATE_START {"running", "fell_back", "probe"}.
##   godot --headless --path <game> -s res://tests/integration/update_start_child.gd -- --dir=<abs>
##     --base=<the base's JSON in base64> --probe=<res path> [--menu]

func _initialize() -> void:
	var dir := ""
	var base := {}
	var probe := ""
	var menu := false
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--dir="):
			dir = a.trim_prefix("--dir=")
		elif a.begins_with("--base="):
			var v: Variant = JSON.parse_string(Marshalls.base64_to_utf8(a.trim_prefix("--base=")))
			base = v if v is Dictionary else {}
		elif a.begins_with("--probe="):
			probe = a.trim_prefix("--probe=")
		elif a == "--menu":
			menu = true
	var u: Node = load("res://autoloads/updater.gd").new()
	u.auto_check = false
	u.start({"enabled": true, "kind": str(base.get("kind", "phone")), "dir": dir, "source": "", "base": base})
	if menu:
		u.menu_shown()
	print("UPDATE_START " + JSON.stringify({"running": u.running, "fell_back": u.fell_back,
		"probe": FileAccess.get_file_as_string(probe) if probe != "" and FileAccess.file_exists(probe) else null}))
	u.free()
	quit()
