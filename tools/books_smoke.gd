extends SceneTree
## Headless smoke run of books and memories in the real sandbox (M3 Task 21b); the steps are in
## tools/books_smoke_steps.gd (loaded at run time: a --script SceneTree cannot compile scripts that use autoloads).
## It starts a NEW Survivor world and writes the profile and the Memory Book, so run it with a private, fresh user
## folder holding a copy of profile.json:
##   XDG_DATA_HOME=/tmp/easycraft-books-smoke godot --headless --path . --script res://tools/books_smoke.gd
## Prints BOOKS_SMOKE lines; exits 0 when every check passed.


func _initialize() -> void:
	if not OS.get_environment("XDG_DATA_HOME").contains("smoke"):
		print("BOOKS_SMOKE refused: set XDG_DATA_HOME to a private folder (its path must contain 'smoke')")
		quit(2)
		return
	var steps: Node = load("res://tools/books_smoke_steps.gd").new()
	root.add_child.call_deferred(steps)
