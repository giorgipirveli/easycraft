extends SceneTree
## Owner #41: how many herds of each kind a universe grows (AnimalRules.spawns_for_cell with the universe's own
## animals), over a square of 32-block areas round the origin. Writes nothing.
##   godot --headless --path . --script res://tools/animal_census.gd -- [--seed=12345] [--cells=32]
## Prints `CENSUS u=<u> <species>=<herds>/<animals> ...` per universe.


func _initialize() -> void:
	var seed := 12345
	var cells := 32
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--seed="):
			seed = int(a.trim_prefix("--seed="))
		elif a.begins_with("--cells="):
			cells = int(a.trim_prefix("--cells="))
	for u in range(1, UniverseRegistry.size() + 1):
		var shape := UniverseRegistry.shape_for(u, seed)
		var kinds := UniverseRegistry.animals(u)
		var herds := {}
		var animals := {}
		for cx in range(-cells / 2, cells / 2):
			for cz in range(-cells / 2, cells / 2):
				var list := AnimalRules.spawns_for_cell(shape, Vector2i(cx, cz), kinds)
				if list.is_empty():
					continue
				var sp: StringName = list[0].species
				herds[sp] = int(herds.get(sp, 0)) + 1
				animals[sp] = int(animals.get(sp, 0)) + list.size()
		var parts: Array[String] = []
		for sp: StringName in kinds:
			parts.append("%s=%d/%d" % [sp, int(herds.get(sp, 0)), int(animals.get(sp, 0))])
		print("CENSUS u=%d seed=%d areas=%d %s" % [u, seed, cells * cells, " ".join(parts)])
	quit(0)
