extends SceneTree
## The reel studio (owner #96, spec §5.12b "High quality, with real tools"): EasyCraft Shorts in a window, for making and
## reviewing them. Windowed (headless draws nothing); the steps are in tools/reel_preview_steps.gd.
##
##   godot --path . --script res://tools/reel_preview.gd -- --short=rocket_parts
##       the studio: the Short at full stage size (360 × 640), a timeline to scrub (drag it; its ticks are the scenes),
##       PLAY / PAUSE, the scene list (a click jumps there), the style checker's findings; keys: Space plays, ← / → a
##       tenth of a second (Shift: a second), PageUp / PageDown the Short before or after, Home the start, R reduce motion.
##   ... -- --sheet --short=rocket_parts,lesson:g4.science.circuits      a frame sheet each: every half second, one PNG
##   ... -- --sheet --all                                               every hand-made Short
##   ... -- --shot --short=rocket_parts --at=12.5                        a picture of the studio at that moment
## Sheets and pictures go to user://reel_studio/ (the path is printed; REEL lines). Every Short is reviewed on its sheet
## before it ships (docs/devlog/parts/shorts.md: what the review changed).


func _initialize() -> void:
	var steps: Node = load("res://tools/reel_preview_steps.gd").new()
	root.add_child.call_deferred(steps)
