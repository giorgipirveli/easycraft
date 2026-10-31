extends Node
## The steps of tools/measure_online_chat.gd (loaded at run time: a --script main loop can't name
## the game's classes).

const ROUNDS := 5
const MESSAGES := 5

var _times := {}
var _server := {}


func _ready() -> void:
	_server = OnlineConfig.parse_server("")
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--online-server="):
			_server = OnlineConfig.parse_server(a.trim_prefix("--online-server="))
	for round in ROUNDS:
		var a := await _teen()
		var b := await _teen()
		if a == null or b == null:
			print("CHAT_MEASURE error: could not sign in or claim a name")
			get_tree().quit(1)
			return
		await a.add_friend_by_id(b.user_id())
		await b.add_friend_by_id(a.user_id())
		var t := Time.get_ticks_usec()
		var ja: Dictionary = await a.join_chat(b.user_id(), OnlineChatRules.TYPE_DM, true)
		_note("dm_join", t)
		await b.join_chat(a.user_id(), OnlineChatRules.TYPE_DM, true)
		var heard: Array = []
		b.chat_message.connect(func(m: Dictionary) -> void: heard.append(Time.get_ticks_usec()))
		for i in MESSAGES:
			t = Time.get_ticks_usec()
			var sent: Dictionary = await a.send_chat(ja.channel_id, {"text": "want to build a castle %d?" % i})
			_note("dm_send_ack", t)
			if not sent.get("ok", false):
				print("CHAT_MEASURE error %s" % sent)
			while heard.size() <= i:
				await get_tree().process_frame
			_note("dm_send_until_heard", t)
		t = Time.get_ticks_usec()
		var history: Dictionary = await b.chat_history(ja.channel_id, OnlineChatRules.HISTORY_COUNT)
		_note("dm_history_%d" % (history.get("messages", []) as Array).size(), t)
		var link: Node = a.get("_link")
		await link.call(&"create_match")
		var room := OnlineChatRules.team_room(str(link.call(&"match_id")))
		t = Time.get_ticks_usec()
		var jr: Dictionary = await a.join_chat(room, OnlineChatRules.TYPE_ROOM, false)
		_note("team_join", t)
		t = Time.get_ticks_usec()
		await a.send_chat(str(jr.get("channel_id", "")), {"text": "Follow me!"})
		_note("team_send_ack", t)
		a.sign_out()
		b.sign_out()
		await get_tree().create_timer(0.3).timeout
		a.free()
		b.free()
	var steps: Array = _times.keys()
	steps.sort()
	for step: String in steps:
		var list: Array = _times[step]
		list.sort()
		print("CHAT_MEASURE %s median_ms=%.1f max_ms=%.1f n=%d" % [step, list[list.size() / 2], list[-1], list.size()])
	get_tree().quit(0)


## A signed-in 13+ player who claimed a name (signed in again, so the session carries it).
func _teen() -> NakamaOnlineBackend:
	var device := DeviceId.generate()
	var first := NakamaOnlineBackend.new()
	add_child(first)
	if not (await first.sign_in(_server, device)).get("ok", false):
		return null
	var name := "Meas"
	for i in 5:
		name += "bdfgkmnprtvxz"[randi() % 13] + str(randi() % 10)
	var claim: Dictionary = await first.call_rpc("claim_username", {"username": name, "age_band": "13_plus"})
	first.sign_out()
	await get_tree().create_timer(0.3).timeout
	first.free()
	if not claim.get("ok", false):
		return null
	var b := NakamaOnlineBackend.new()
	add_child(b)
	if not (await b.sign_in(_server, device)).get("ok", false):
		return null
	return b


func _note(step: String, since_usec: int) -> void:
	if not _times.has(step):
		_times[step] = []
	(_times[step] as Array).append((Time.get_ticks_usec() - since_usec) / 1000.0)
