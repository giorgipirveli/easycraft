extends SceneTree
## Times online chat against a running Nakama with the game's module (M4 Wave 2, Agent E): joining
## a friend's DM, a message from sending until the friend hears it, reading back a 13+ DM's history,
## joining a match's team room and a quick phrase there. Prints "CHAT_MEASURE <step> median_ms=..
## max_ms=.." lines. Needs the server (server/dev.sh up); makes throwaway 13+ accounts.
## Usage: godot --headless --path . --script res://tools/measure_online_chat.gd [-- --online-server=<address>]


func _initialize() -> void:
	var driver: Node = Node.new()
	driver.set_script(load("res://tools/measure_online_chat_steps.gd"))
	root.add_child.call_deferred(driver)
