extends Node
## The steps of tools/bot_talk_smoke.gd (owner feedback #38), in a new Sandbox world on real terrain: a
## builder and an explorer join; the child talks to them through the HUD's chat bar and through the host's
## path (Session.request_bot_talk): they follow, build a house next to the child on real ground, the
## explorer answers where the nearest secret is from the world's own secrets and leads the child there,
## they answer the day clock, Tilly (no shop in Sandbox) and a thank-you. Prints what they said.

const TIMEOUT := 180.0

var _t := 0.0
var _step := 0
var _wait := 0.0
var _step_t := 0.0
var _fails: Array[String] = []
var _heard: Array[String] = []
var _edits := 0
var _done := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Game.mode = ModeRules.SANDBOX
	Game.start_new_world = true
	Session.chat_received.connect(func(from: String, text: String, kind: StringName) -> void:
		if kind == &"bot":
			_heard.append("%s: %s" % [from, text])
			print("BOT_TALK_SMOKE heard %s: %s" % [from, text]))
	get_tree().change_scene_to_file(Game.SANDBOX_SCENE)


func _process(delta: float) -> void:
	if _done:
		return
	_t += delta
	if _t > TIMEOUT:
		_check(false, "timeout at step %d" % _step)
		_finish()
		return
	var sandbox := get_tree().current_scene
	if sandbox == null or sandbox.get("player") == null or not (sandbox.player as Player).is_spawned():
		return
	if _wait > 0.0:
		_wait -= delta
		return
	_step_t += delta
	_run_step(sandbox, sandbox.player)


func _run_step(sandbox: Node, p: Player) -> void:
	var d := sandbox.get("_bot_director") as BotDirector
	match _step:
		0:
			_check(d != null and d.is_in_group(&"bot_director"), "the host's BotDirector hears the child")
			_check(d.add(BotRules.BUILDER) != null and d.add(BotRules.EXPLORER) != null, "a builder and an explorer joined")
			_check(Session.has_own_bots(), "the child has friends of their own")
			p.world.block_changed.connect(func(_pos: Vector3i, _old: int, id: int) -> void:
				if id != BlockIds.AIR:
					_edits += 1)
			_next(3.0)
		1:
			var chat := sandbox.find_children("*", "ChatPanel", true, false)
			_check(not chat.is_empty(), "the HUD has the chat")
			_heard.clear()
			if not chat.is_empty():
				var panel := chat[0] as ChatPanel
				panel.open()
				panel._submit("follow me")   # an under-13 profile: to the friends only
				panel.close()
			_next(0.5)
		2:
			_check(_said("right behind you"), "they answered the chat bar: %s" % [_heard])
			_heard.clear()
			_edits = 0
			Session.bot_talk_reset()
			Session.request_bot_talk("build a house")
			_next(0.0)
		3:
			var builder := _bot_of(d, BotRules.BUILDER)
			if builder.talk_building() and _step_t < 25.0:
				return
			var answered := _said("Coming right up") or _said("flat spot")
			_check(answered, "the builder answered the build: %s" % [_heard])
			if _said("Coming right up"):
				_check(_said("little house"), "it finished the house (%d blocks placed, %.1f s)" % [_edits, _step_t])
				_check(_edits >= 20, "a house of %d blocks on real ground" % _edits)
			_heard.clear()
			Session.bot_talk_reset()
			Session.request_bot_talk("where is the treasure?")
			_next(0.5)
		4:
			var explorer := _bot_of(d, BotRules.EXPLORER)
			_check(_said("I know!") or _said("secrets near here"), "the explorer answered from the world's secrets: %s" % [_heard])
			if not _said("Follow me!"):
				_next(0.0)
				_step = 6
				return
			_check(explorer.behaviour == BotRules.GUIDE or explorer.talk_order() == BotRules.GUIDE, "it leads the way")
			_next(0.0)
		5:
			var explorer := _bot_of(d, BotRules.EXPLORER)
			if not explorer.pointing and _step_t < 90.0 and explorer.talk_order() == BotRules.GUIDE:
				if fmod(_step_t, 1.0) < get_process_delta_time():
					var behind := explorer.global_position.move_toward(explorer.get("_talk_point"), -2.5)
					var x := floori(behind.x)
					var z := floori(behind.z)
					if p.world.is_area_ready(Vector3(x, behind.y, z)):
						p.global_position = Vector3(x + 0.5, p.world.find_standing_y(x, z) + 0.05, z + 0.5)
				return
			_check(explorer.pointing or _said("can't get through"), "it got there and points (or says it can't get through) after %.0f s: %s" % [
				_step_t, _heard.slice(-2)])
			_next(0.0)
		6:
			_heard.clear()
			for text in ["is it night soon?", "where is tilly?", "thank you", "banana"]:
				Session.bot_talk_reset()
				Session.request_bot_talk(text)
			_next(0.5)
		7:
			_check(_said("Night comes") or _said("The sun"), "the day clock")
			_check(_said("Survivor"), "no shop in Sandbox")
			_check(_said("welcome") or _said("Anytime"), "a thank-you gets a kind answer")
			_check(_said("You can say"), "a kind hint for words it doesn't know")
			_finish()


func _said(part: String) -> bool:
	for l in _heard:
		if l.contains(part):
			return true
	return false


func _bot_of(d: BotDirector, personality: StringName) -> BotFriend:
	for b in d.bots():
		if b.personality == personality:
			return b
	return null


func _next(wait: float) -> void:
	_step += 1
	_wait = wait
	_step_t = 0.0


func _check(ok: bool, what: String) -> void:
	print("BOT_TALK_SMOKE %s %s" % ["ok" if ok else "FAIL", what])
	if not ok:
		_fails.append(what)


func _finish() -> void:
	_done = true
	print("BOT_TALK_SMOKE done failed=%d" % _fails.size())
	Music.reset()
	await get_tree().create_timer(0.3).timeout
	get_tree().quit(0 if _fails.is_empty() else 1)
