extends SceneTree
## The rocket flight in the real sandbox (owner #79, #87; spec §25.3), headless: the missions' `fly` (the sandbox's
## fly_rocket) with a rocket at a pad, the pause menu holding it, QUIT putting everything back, a whole flight to the
## Moon (a child who presses what is asked at once), the Moon world with the lander by the pad, then the Star Map's
## landing on its own (land_on_space) to Mercury. Needs a private folder whose path contains "smoke":
##   XDG_DATA_HOME=/tmp/easycraft-flight-smoke godot --headless --path . --script res://tools/flight_smoke.gd
## (tools/smoke_all.sh runs it with the others.) Prints FLIGHT_SMOKE ok/FAIL lines and "FLIGHT_SMOKE result fails=<n>".


func _initialize() -> void:
	if not OS.get_environment("XDG_DATA_HOME").contains("smoke"):
		push_error("flight_smoke: give XDG_DATA_HOME a private folder whose path contains \"smoke\"")
		quit(2)
		return
	root.add_child.call_deferred(load("res://tools/flight_smoke_steps.gd").new())
