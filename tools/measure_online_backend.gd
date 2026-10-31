extends SceneTree
## Times NakamaOnlineBackend's calls against a running Nakama (M4 Wave 1, Agent C): sign-in, an RPC,
## a friend request with its notification, accept, the friends list, follow. Prints
## "ONLINE_MEASURE <step> median_ms=.. max_ms=.." lines. Needs the server (server/dev.sh up); makes two throwaway
## accounts. Usage: godot --headless --path . --script res://tools/measure_online_backend.gd [-- --online-server=<address>]


func _initialize() -> void:
	var driver: Node = Node.new()
	driver.set_script(load("res://tools/measure_online_backend_steps.gd"))
	root.add_child.call_deferred(driver)
