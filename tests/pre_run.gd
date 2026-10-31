extends GutHookScript
## Before any test: the age rules on (AgeBand.restrictions), as the tests written for them expect. The game ships with
## them off (the owner, 2026-09-29: "remove all such restrictions"); tests/unit/test_no_age_restrictions.gd tests the
## game as it ships (it switches them off and back on).


func run() -> void:
	AgeBand.restrictions = true
