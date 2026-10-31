extends SceneTree
## Adds the rocket flight's draws to the shader warm-up's census (data/shader_warmup.json, phase "flight"); the steps
## are tools/flight_census_steps.gd. Run it again after the census is written by playing:
##   godot --headless --path . --script res://tools/flight_census.gd


func _initialize() -> void:
	root.add_child.call_deferred(load("res://tools/flight_census_steps.gd").new())
