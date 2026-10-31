extends Node
## The steps of tools/flight_census.gd (a node, so the game's autoloads are there when it compiles). Adds the rocket flight's draws (owner #79, #86, #87; entities/flight/) to the shader warm-up's census
## (data/shader_warmup.json) under the phase "flight": a flight is built here (every look it can show: the planets,
## the tunnels, the asteroids, the nebula, the ground and the pad, the flame and the smoke, the legs and the parachute),
## ShaderWarmup.draws_and_nodes describes them, and the ones the census does not have yet are added (`shown` empty:
## tier LATER, so a browser or the OpenGL renderer compiles them while the menu idles, never mid-flight).
## The census is written by playing (tools/shader_probe_steps.gd --shader-census); run this again after that:
##   godot --headless --path . --script res://tools/flight_census.gd
## Prints FLIGHT_CENSUS added=<n> total=<n>.


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var flight: Node3D = load("res://entities/flight/rocket_flight.gd").new()
	flight.set("auto_tick", false)
	add_child(flight)
	flight.call("start", RocketStages.test_rocket(SpaceRules.TITAN, 2), 1)
	# The set and the moments are built over the boarding's frames (RocketFlight._later, drained by its tick): all now
	# (the frame spikes, 2026-09-30: without this the census lost the wormhole's tunnel).
	var later: Array = flight.get("_later")
	while not later.is_empty():
		(later.pop_front() as Callable).call()
	var draws: Array[Array] = ShaderWarmup.draws_and_nodes(flight)
	var path := ProjectSettings.globalize_path(ShaderWarmup.CENSUS_PATH)
	var census: Dictionary = ShaderWarmup._whole_numbers(JSON.parse_string(FileAccess.get_file_as_string(path)))
	var list: Array = census.get("draws", [])
	var have := {}
	for d: Dictionary in list:
		var k := d.duplicate()
		for extra: String in ["at", "phases", "shown", "styles", "scene"]:
			k.erase(extra)
		have[ShaderWarmup.key(k)] = d
	var added := 0
	for pair: Array in draws:
		var d: Dictionary = pair[0]
		var node: Node = pair[1]
		if node.name.begins_with("Stage") or flight.get_node("FlightCamera").is_ancestor_of(node):
			continue   # the rocket's blocks are the block pages' own warm-up (BlockLibrary.warmup_materials)
		var k := ShaderWarmup.key(d)
		if have.has(k):
			var old: Dictionary = have[k]
			if not (old.get("phases", []) as Array).has("flight"):
				(old.phases as Array).append("flight")
			continue
		var entry := d.duplicate()
		var script: Script = node.get_script()
		entry.at = "%s (%s)" % [flight.get_path_to(node), script.resource_path.get_file() if script else node.get_class()]
		entry.phases = ["flight"]
		entry.shown = []
		entry.styles = ["blocky", "realistic"]
		list.append(entry)
		have[k] = entry
		added += 1
	census.draws = list
	var phases: Array = census.get("phases", [])
	if not phases.has("flight"):
		phases.append("flight")
		census.phases = phases
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(JSON.stringify(census, "\t", false) + "\n")
	f.close()
	print("FLIGHT_CENSUS added=%d total=%d" % [added, list.size()])
	flight.call("abort")
	get_tree().quit()
