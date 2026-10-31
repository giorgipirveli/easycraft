extends SceneTree
## Long frames in a child's session, headless (2026-09-28, the browser's freezes; docs/devlog/parts/m7-freezes.md).
## Plays one session through its phases and prints each frame over the threshold with what it spent its time on
## (tools/frame_blame.gd), then a summary per phase: frames, average, worst, and how many took over 16/33/50/100/200 ms.
## Phones run this logic 3-5x slower than this desktop (a browser slower still). What it cannot see: the browser's
## multi-second stalls when something is drawn the first time are shader compiles (docs/devlog/2026-09-27-m7-web.md,
## 06:00-06:35).
## Phases (in this order; --phases= picks some; each needs the ones before it where noted):
##   menu            the menu for 3 s (--menu-seconds=)
##   new             Sandbox NEW WORLD (seed 12345): the switch and the load until the child stands (new-load),
##                   then 10 s standing (new-play)
##   walk            60 s walking forward, jump held, turning (about a quarter) where a hill stops the child, after new
##   cruise          FLY: up 2.5 s, then 30 s straight ahead over new land (streaming it), then it lands, after new
##   fly             FLY, jump held until "Where shall we land?" (y 200; out from under an overhang first), after new
##   trip            the Moon: the switch until the child stands (trip-load), then 15 s standing (trip-play), after fly
##   continue        SAVE AND QUIT and 3 s of the menu (menu-2), Sandbox CONTINUE (continue-load, continue-play 10 s)
##   survivor        SAVE AND QUIT and 3 s of the menu (menu-3), Survivor NEW WORLD (survivor-load, survivor-play 10 s)
## Run with a private user folder whose path contains "smoke" (copy a profile.json into it):
##   XDG_DATA_HOME=/tmp/easycraft-freeze-smoke godot --headless --max-fps 60 --path . --script res://tools/frame_probe.gd
##   ... -- --phases=new,walk --over=30 --no-blame --voxel-threads=2
## --voxel-threads: like a phone's browser (the web build takes a quarter of the cores: 2 on an 8-core phone). With this
## PC's default (12), the main thread's calls into engine methods slow down 10-50x while the terrain generates (plain
## GDScript maths does not): the GDScript generator on 12 threads contends with it, which a phone does not see.
## Prints PROBE lines; the summary lines start with "PROBE phase".


func _initialize() -> void:
	if not OS.get_environment("XDG_DATA_HOME").contains("smoke"):
		print("PROBE refused: set XDG_DATA_HOME to a private folder (its path must contain 'smoke')")
		quit(2)
		return
	root.add_child.call_deferred(load("res://tools/frame_probe_steps.gd").new())
