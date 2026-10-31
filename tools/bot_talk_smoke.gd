extends SceneTree
## Headless smoke run of talking to bot friends in the real sandbox (owner feedback #38); the steps are in
## tools/bot_talk_smoke_steps.gd (loaded at run time: a --script SceneTree cannot compile scripts that use
## autoloads). It starts a NEW Sandbox world, so run it with a private user folder:
##   XDG_DATA_HOME=/tmp/easycraft-talksmoke godot --headless --path . --script res://tools/bot_talk_smoke.gd
## Prints BOT_TALK_SMOKE lines; exits 0 when every check passed.


func _initialize() -> void:
	if not OS.get_environment("XDG_DATA_HOME").contains("smoke"):
		print("BOT_TALK_SMOKE refused: set XDG_DATA_HOME to a private folder (its path must contain 'smoke')")
		quit(2)
		return
	var steps: Node = load("res://tools/bot_talk_smoke_steps.gd").new()
	root.add_child.call_deferred(steps)
