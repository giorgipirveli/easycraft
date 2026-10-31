extends SceneTree
## Owner #98: makes Mission Control's plans (RocketPlan.PLANS in core/rules/rocket_plan.gd) for every mission and crew
## of 1 to 4: the cheapest rocket the REAL RocketCheck passes, laid out like a rocket on the pad (the work is in
## tools/rocket_plans_maker.gd, the search in tools/rocket_plans_search.gd). Run it whenever RocketParts (masses, pushes,
## prices), RocketCheck or MissionRules change; tests/unit/test_rocket_plan.gd guards the table. About 20 s here.
##   godot --headless --path . --script res://tools/make_rocket_plans.gd
##   godot --headless --path . --script res://tools/make_rocket_plans.gd -- --dry                 # print, write nothing
##   godot --headless --path . --script res://tools/make_rocket_plans.gd -- --dry --prices 562=5    # try other prices
## (Its work loads at run time: a --script SceneTree cannot compile scripts that use autoloads. After the run the
## Profile autoload may print SCRIPT ERROR lines about this PC's profile: harmless, the table is written before.)


func _initialize() -> void:
	var work: Node = load("res://tools/rocket_plans_maker.gd").new()
	root.add_child.call_deferred(work)
