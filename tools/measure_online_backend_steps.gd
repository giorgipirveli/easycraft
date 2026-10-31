extends Node
## The steps of tools/measure_online_backend.gd (loaded at run time: a --script main loop can't name
## the game's classes).

const ROUNDS := 5

var _times := {}


func _ready() -> void:
	var server := OnlineConfig.parse_server("")
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--online-server="):
			server = OnlineConfig.parse_server(a.trim_prefix("--online-server="))
	for round in ROUNDS:
		var a := NakamaOnlineBackend.new()
		var b := NakamaOnlineBackend.new()
		add_child(a)
		add_child(b)
		var t := Time.get_ticks_usec()
		var ra := await a.sign_in(server, DeviceId.generate())
		_note("sign_in", t)
		if not ra.get("ok", false):
			print("ONLINE_MEASURE error %s" % ra)
			get_tree().quit(1)
			return
		var rb := await b.sign_in(server, DeviceId.generate())
		t = Time.get_ticks_usec()
		await a.call_rpc("healthcheck")
		_note("rpc_healthcheck", t)
		var heard := [false]
		b.notified.connect(func(_c: int, _x: String, _s: String) -> void: heard[0] = true)
		t = Time.get_ticks_usec()
		await a.add_friend_by_name(str(rb.username))
		_note("add_friend", t)
		while not heard[0]:
			await get_tree().process_frame
		_note("add_friend_until_notified", t)
		t = Time.get_ticks_usec()
		await b.add_friend_by_id(a.user_id())
		_note("accept", t)
		t = Time.get_ticks_usec()
		await a.list_friends()
		_note("list_friends", t)
		t = Time.get_ticks_usec()
		await a.follow([b.user_id()] as Array[String])
		_note("follow", t)
		a.sign_out()
		b.sign_out()
		await get_tree().create_timer(0.3).timeout
		a.free()
		b.free()
	for step: String in _times:
		var list: Array = _times[step]
		list.sort()
		print("ONLINE_MEASURE %s median_ms=%.1f max_ms=%.1f n=%d" % [step, list[list.size() / 2], list[-1], list.size()])
	get_tree().quit(0)


func _note(step: String, since_usec: int) -> void:
	if not _times.has(step):
		_times[step] = []
	(_times[step] as Array).append((Time.get_ticks_usec() - since_usec) / 1000.0)
