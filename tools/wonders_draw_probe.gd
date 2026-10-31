extends SceneTree
## World 41's spawn view on this desktop (owner #78, the wonders' second tour; the lead's ask, 2026-09-30: "don't make
## the spawn view heavier"): a NEW Sandbox world in universe 41 (seed 12345, the default settings: MEDIUM, view 128),
## standing on the landing spot at noon, the HUD and cards hidden; for each of the four directions it waits for the
## terrain there, settles, then averages 120 frames of the renderer's draw calls, objects and primitives and the frame
## time. Windowed (headless draws nothing). The steps are in tools/wonders_draw_probe_steps.gd. It writes a new world in
## that universe's Sandbox slot, so give it a private folder whose path contains "smoke":
##   XDG_DATA_HOME=/tmp/easycraft-draw-smoke godot --path . --disable-vsync --resolution 1280x720 \
##     --script res://tools/wonders_draw_probe.gd
## Prints DRAW_PROBE lines: one per direction and "DRAW_PROBE all …" (the four together).
## Owner #78's third tour: `-- --at=nature` stands on the nature square instead, `-- --at=<wonder id>` at a wonder's
## gate (e.g. everest, victoria_falls); `-- --night` measures at midnight (the northern lights).


func _initialize() -> void:
	if not OS.get_environment("XDG_DATA_HOME").contains("smoke"):
		print("DRAW_PROBE refused: set XDG_DATA_HOME to a private folder (its path must contain 'smoke')")
		quit(2)
		return
	var steps: Node = load("res://tools/wonders_draw_probe_steps.gd").new()
	root.add_child.call_deferred(steps)
