extends SceneTree
## Headless smoke run of Io (cosmos, spec §21b.2) in the real sandbox; the steps are in tools/io_smoke_steps.gd (loaded
## at run time: a --script SceneTree cannot compile scripts that use autoloads).
## Sandbox: fly up from a new Green Meadows world, the Star Map opens, tap Io (its card: three facts, LAND), land on Io's
## landing pad (its own world, sandbox_21: gravity 0.18, space's black sky with Jupiter and two of its moons, peace, no
## animals, MY MAP's pad and sights, the Space Book's mark, the volcanoes and the portal home), fall slowly, find the
## Volcano Lander (stand on its deck), stand on a volcano's cone (its fact), ride its plume up from the vent, reach the
## lava lake's rim (its fact), step into the hot lava of its moat (a warm bounce throws the child up and out, no harm),
## climb the mountain (its fact), and walk home through the portal by the pad (back on the take-off column). It replaces
## the Sandbox worlds of Green Meadows and Io in that folder, so run it with a private user folder whose path contains
## "smoke" (copy a profile.json into it):
##   XDG_DATA_HOME=/tmp/easycraft-io-smoke godot --headless --path . --script res://tools/io_smoke.gd
## Prints IO_SMOKE lines; exits 0 when every check passed.


func _initialize() -> void:
	if not OS.get_environment("XDG_DATA_HOME").contains("smoke"):
		print("IO_SMOKE refused: set XDG_DATA_HOME to a private folder (its path must contain 'smoke')")
		quit(2)
		return
	var steps: Node = load("res://tools/io_smoke_steps.gd").new()
	root.add_child.call_deferred(steps)
