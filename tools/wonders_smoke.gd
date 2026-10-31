extends SceneTree
## Headless smoke run of world 41, Wonders of the World (owner #78, spec §24), in the real sandbox; the steps are in
## tools/wonders_smoke_steps.gd (loaded at run time: a --script SceneTree cannot compile scripts that use autoloads).
## Sandbox: fly up from a new Green Meadows world, the Star Map opens, tap Earth (its card: three facts, "Wonders of the
## World: LAND"), land on the landing square (its own world, sandbox_41: Earth's gravity and sky, animals, peace, the
## explorer's card, MY MAP's landing spot and seven wonders, the signs, the compass, the portal home), walk up to the
## Great Pyramid (its fact, the passport's stamp), into the King's Chamber, knock open the hidden room over the Grand
## Gallery (its fact), tap the pyramid's plaque and answer its quiz (gold, once), reach the New Seven Wonders at the end
## of the Wonders Road and the six other ancient ones (each one's fact and stamp), open the golden chest by the
## Lighthouse's fire, tap the New Seven's square's plaque, knock open the pyramid inside El Castillo (its jaguar throne),
## see Earth as "You are here" with HOME on the Star Map, and walk home through the portal (back on the take-off column;
## the stamps kept). It replaces the Sandbox worlds
## of Green Meadows and world 41 in that folder, so run it with a private user folder whose path contains "smoke" (copy a
## profile.json into it):
##   XDG_DATA_HOME=/tmp/easycraft-wonders-smoke godot --headless --path . --script res://tools/wonders_smoke.gd
## Prints WONDERS_SMOKE lines; exits 0 when every check passed.


func _initialize() -> void:
	if not OS.get_environment("XDG_DATA_HOME").contains("smoke"):
		print("WONDERS_SMOKE refused: set XDG_DATA_HOME to a private folder (its path must contain 'smoke')")
		quit(2)
		return
	var steps: Node = load("res://tools/wonders_smoke_steps.gd").new()
	root.add_child.call_deferred(steps)
