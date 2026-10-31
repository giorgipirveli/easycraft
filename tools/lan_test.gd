extends Node
## Automated two-instance LAN check (developer tool, enabled with the --lan-test user arg).
## Host places a purple block at A, the client places a red block at B; both log what they see:
##   LANTEST <role> t=<s> players=<n> A=<id> B=<id> remote=<position> undo=<steps>
## undo counts this player's undo steps, which the host sends back after it applies each edit.
## The host also walks its player along +X so the client can see it move. Quits after 30 s.

const DURATION := 30.0

var sandbox: Node
var _t := 0.0
var _next_log := 2.0
var _placed := false


func _process(delta: float) -> void:
	_t += delta
	if _t > (GAMES_DURATION if OS.get_cmdline_user_args().has("--games") else WAVE_DURATION if OS.get_cmdline_user_args().has("--wave") else DURATION):
		get_tree().quit()
		return
	if not is_instance_valid(sandbox) or not is_instance_valid(sandbox.world) or not is_instance_valid(sandbox.player):
		return
	var world: WorldService = sandbox.world
	var player: Player = sandbox.player
	if not player.is_spawned():
		return
	var spawn := world.spawn_column()   # both players start here, so A and B are within reach
	var base := Vector3i(spawn.x, maxi(world.surface_height(spawn.x, spawn.y), MeadowsShape.SEA_LEVEL) + 3, spawn.y)
	var a := base + Vector3i(3, 0, 0)
	var b := base + Vector3i(-2, 0, 2)
	var host := Session.is_host()
	if not _placed and _t > 8.0:
		_placed = true
		var ok := Session.request_set_block(a if host else b, BlockIds.PURPLE if host else BlockIds.RED)
		print("LANTEST %s placed ok=%s" % ["host" if host else "client", ok])
	if host and _t > 10.0 and _t < 14.0:
		player.global_position.x += delta * 1.5
	if _t >= _next_log:
		_next_log = _t + 2.0
		var remote := "none"
		for p: Player in get_tree().get_nodes_in_group(&"players"):
			if p != player:
				remote = "%.1f,%.1f,%.1f" % [p.global_position.x, p.global_position.y, p.global_position.z]
		var undo: int = (player.get_node("BlockInteractor") as BlockInteractor).undo_size()
		print("LANTEST %s t=%d players=%d A=%d B=%d remote=%s undo=%d" % [
			"host" if host else "client", int(_t), get_tree().get_nodes_in_group(&"players").size(),
			world.get_block(a), world.get_block(b), remote, undo])
	if OS.get_cmdline_user_args().has("--ko"):
		_knockout_phase(player, host)
	if OS.get_cmdline_user_args().has("--wave"):
		_wave_phase(player, host)
	if OS.get_cmdline_user_args().has("--boss"):
		_boss_phase(player, host)   # M2 Task 10
	if OS.get_cmdline_user_args().has("--games"):
		_games_phase(player, host)   # M4 H
	if OS.get_cmdline_user_args().has("--trade"):
		_trade_phase(player, host)   # owner #37


# --- Knock-out over LAN (M2 Task 2; user arg --ko, best with --survivor on the host) -------------
# Host t 16: gives the guest 5 dirt and knocks them out. The guest logs the fade and getting up; it
# taps for its bag once while still down (refused) and again 2 s after getting up (taken). Both log
# `LANTEST <role> ko ...` lines; the host logs the end once the bag is gone (or at t 29).

var _ko_step := 0
var _ko_up_at := -1.0


func _knockout_phase(player: Player, host: bool) -> void:
	var ko := sandbox.get_node("Knockout") as KnockoutDirector
	if _ko_step == 0:
		_ko_step = 1
		Session.knockout_received.connect(func(id: int, at_home: bool) -> void:
			print("LANTEST %s ko received peer=%d me=%s at_home=%s overlay_down=%s" % [_role(host), id,
				id == player.peer_id, at_home, sandbox.hud.knockout_overlay.is_down()])
			if not host and id == player.peer_id and not ko.bags().is_empty():
				Session.request_take_bag(ko.bags()[0].name))   # while down: the host must refuse it
		Session.knockout_respawned.connect(func(id: int, _at_home: bool) -> void:
			print("LANTEST %s ko respawned peer=%d me=%s" % [_role(host), id, id == player.peer_id])
			if id == player.peer_id:
				_ko_up_at = _t)
		Session.magic_feedback.connect(func(text: String) -> void: print("LANTEST %s ko feedback: %s" % [_role(host), text]))
	if host and _ko_step == 1 and _t > 16.0:
		for p: Player in get_tree().get_nodes_in_group(&"players"):
			if p != player:
				_ko_step = 2
				Session.inventory_of(p.peer_id).add(BlockIds.DIRT, 5)
				Session.hurt_player(p.peer_id, Health.MAX_HP, player.global_position)
				print("LANTEST host ko sent peer=%d hp=%d bags=%d guest_dirt=%d" % [p.peer_id, p.health.hp,
					ko.bags().size(), Session.inventory_of(p.peer_id).count(BlockIds.DIRT)])
	if host and _ko_step == 2 and (ko.bags().is_empty() or _t > 29.0):
		_ko_step = 3
		for p: Player in get_tree().get_nodes_in_group(&"players"):
			if p != player:
				print("LANTEST host ko end guest_hp=%d bags=%d guest_dirt=%d" % [p.health.hp, ko.bags().size(),
					Session.inventory_of(p.peer_id).count(BlockIds.DIRT)])
	if not host and _ko_step == 1 and _ko_up_at >= 0.0 and _t > _ko_up_at + 2.0:
		_ko_step = 2
		print("LANTEST client ko before_take hp=%d knocked_out=%s overlay_down=%s bags=%d" % [player.health.hp,
			player.knocked_out, sandbox.hud.knockout_overlay.is_down(), ko.bags().size()])
		if not ko.bags().is_empty():
			Session.request_take_bag(ko.bags()[0].name)
	if not host and _ko_step == 2 and _t > _ko_up_at + 3.5:
		_ko_step = 3
		print("LANTEST client ko end hp=%d bags=%d" % [player.health.hp, ko.bags().size()])


static func _role(host: bool) -> String:
	return "host" if host else "client"


# --- Totem waves over LAN (M2 Task 9; user arg --wave on both, best with --survivor on the host) ------
# Both log every wave state they hear, with their Totem's glow and line and their HUD's wave line. The
# guest walks to the Totem and asks for wave 1 at t 15 (the request goes to the host); at t 27 both log
# the wave monsters they see; then the host defeats them all and both log the end (the guest's gold).

const WAVE_DURATION := 40.0

var _wave_step := 0
var _wave_seen := 0


func _wave_phase(player: Player, host: bool) -> void:
	var waves := sandbox.get_node("Waves") as WaveDirector
	var totem := waves.totem()
	if _wave_step == 0:
		_wave_step = 1
		waves.state_changed.connect(func(s: Dictionary) -> void:
			var t := waves.totem()
			print("LANTEST %s wave state phase=%d wave=%d next=%d left=%d count=%d lost=%d glow=%s totem=%s line=%s" % [
				_role(host), int(s.phase), int(s.wave), int(s.next), int(s.left), int(s.count), int(s.lost),
				t != null and t.glowing(), t.label_text() if t else "none", sandbox.hud.wave_line.text() if sandbox.hud.wave_line.visible else "-"]))
		Session.magic_feedback.connect(func(text: String) -> void: print("LANTEST %s wave feedback: %s" % [_role(host), text]))
	var here := waves.wave_monsters().size()
	if here > _wave_seen:
		_wave_seen = here
		print("LANTEST %s wave monsters here=%d" % [_role(host), here])   # replicated with their wave
	if not host and _wave_step == 1 and _t > 12.0 and totem:
		_wave_step = 2
		var front := totem.global_position + Vector3(0, 0, -3.0).rotated(Vector3.UP, totem.rotation.y)
		player.spawn_on_surface(floori(front.x), floori(front.z))
		print("LANTEST client wave totem=%s gold=%d" % [totem.global_position, Profile.data.survivor_gold])
	if not host and _wave_step == 2 and _t > 15.0:
		_wave_step = 3
		Session.wave_request_start(1)
		print("LANTEST client wave asked for wave 1")
	if _wave_step in [1, 3] and _t > 27.0:
		_wave_step = 4
		print("LANTEST %s wave monsters seen=%d" % [_role(host), waves.wave_monsters().size()])
		if host:
			for m in waves.wave_monsters():
				m.take_hit(1000, m.global_position, Vector3.ZERO)
	if _wave_step == 4 and _t > 30.0:
		_wave_step = 5
		print("LANTEST %s wave end phase=%d next=%d monsters=%d gold=%d" % [_role(host), int(waves.current.get("phase", -1)),
			int(waves.current.get("next", -1)), waves.wave_monsters().size(), Profile.data.survivor_gold])

# --- The Stone Golem over LAN (M2 Task 10; user arg --boss on both, best with --survivor on the host) ---
# Host t 12: the Golem rises 4 blocks from the host (start_boss, the Totem's hook); t 18: the host
# defeats it. Both log `LANTEST <role> boss ...` every 2 s from t 12: the Golem (phase, health), the
# HUD bar, the music, then the portal, the gold and the profile's universe.

var _boss_step := 0
var _boss_log := 12.0


func _boss_phase(player: Player, host: bool) -> void:
	var boss := sandbox.get_node("Boss") as BossDirector
	if host and _boss_step == 0 and _t > 12.0:
		_boss_step = 1
		var said: String = sandbox.call("start_boss", player.global_position + Vector3(4, 0, 0))
		print("LANTEST host boss start said='%s' golem=%s" % [said, boss.golem() != null])
	if host and _boss_step == 1 and _t > 18.0:
		_boss_step = 2
		var g := boss.golem()
		if g:
			g.take_hit(100000, player.global_position, Vector3.ZERO)
		print("LANTEST host boss defeated")
	if _t >= _boss_log:
		_boss_log = _t + 2.0
		var g := boss.golem()
		var bar: BossBar = sandbox.hud.boss_bar
		print("LANTEST %s boss t=%d golem=%s phase=%s hp=%s bar=%s fraction=%.2f title='%s' music=%s portals=%d gold=%d universe=%d" % [
			_role(host), int(_t), g != null, g.phase if g else -1, "%d/%d" % [g.hp, g.max_hp] if g else "-",
			bar.visible, bar.fraction(), bar.title(), Music.current(), boss.portals().size(),
			Profile.data.survivor_gold, Profile.data.universe_unlocked])

# --- Co-op games over LAN (M4 Wave 3 H; user arg --games on both; both run 60 s) -------------------------
# Host t 18: hide-and-seek with the GUEST seeking (the guest sees the counting screen); 4 s later the
# counting ends at once. The guest, once it sees the seeking, stands 2 blocks from the host's player and a
# second later asks to find it (the host checks it). When the round is over, the host starts Storm Run; the
# guest, 3 s after seeing the circle, stands at a star (its own game asks for it); 8 s into the run the host
# ends it (END GAME), then offers TEAM PHOTO, which the guest taps. Both log `LANTEST <role> games ...` every
# 2 s from t 12 (round, phase, counting screen, line, stars, score, best, stickers, photo, ring).

const GAMES_DURATION := 60.0

var _games_step := 0
var _games_log := 12.0
var _games_at := 0.0


func _games_phase(player: Player, host: bool) -> void:
	var games := sandbox.get("games") as GamesDirector
	if games == null:
		return
	if host:
		_games_host(games, player)
	else:
		_games_guest(games, player)
	if _t >= _games_log:
		_games_log = _t + 2.0
		print("LANTEST %s games t=%d kind=%s phase=%d counting=%s line='%s' seekers=%s stars=%d score=%d best=%d stickers=%s photo='%s' ring=%s" % [
			_role(host), int(_t), games.kind, games.hide.phase, games.counting_here(), games.line(), games.hide.seekers,
			games.stars.count(), games.storm.score, games.storm.best, Profile.data.stickers,
			(sandbox.photo as PhotoMode).last_path, games.ring.visible])
		var other := _other_player(player)
		if host and other and games.kind == GameRules.HIDE_SEEK:
			var eye := other.eye_position()
			var target := player.stealth_eye()
			var to := target - eye
			var hit := GridRay.cast(eye, to, to.length(), func(c: Vector3i) -> bool: return StealthRules.blocks_sight(sandbox.world.get_block(c)))
			print("LANTEST host games sight guest_eye=%s my_eye=%s dist=%.2f vis=%.2f blocked=%s" % [eye, target, to.length(),
				player.stealth_visibility(), hit.position if hit else "no"])


func _games_host(games: GamesDirector, player: Player) -> void:
	match _games_step:
		0:
			var other := _other_player(player)
			if _t > 18.0 and other:
				_games_step = 1
				_games_at = _t
				Session.games_request_start(GameRules.HIDE_SEEK, GameRules.player_key(other.peer_id))
				print("LANTEST host games hide start seeker=p%d running=%s" % [other.peer_id, games.running()])
		1:
			if _t > _games_at + 4.0:
				_games_step = 2
				games._process(HideSeekRound.COUNT_TIME)   # the counting ends at once
		2:
			if games.kind == &"":
				_games_step = 3
				_games_at = _t
				Session.games_request_start(GameRules.STORM_RUN, "")
				print("LANTEST host games storm start running=%s" % games.running())
		3:
			if _t > _games_at + 8.0:
				_games_step = 4
				Session.games_request_stop()
				print("LANTEST host games storm stopped score=%d best=%d" % [games.storm.score, games.storm.best])
		4:
			if games.kind == &"":
				_games_step = 5
				games.offer_photo()


func _games_guest(games: GamesDirector, player: Player) -> void:
	match _games_step:
		0:
			if games.kind == GameRules.HIDE_SEEK and games.hide.phase == HideSeekRound.Phase.SEEKING:
				_games_step = 1
				var other := _other_player(player)
				if other:   # on the ground 2 blocks from the host (never inside a slope); the host sees it a moment later
					var x := floori(other.global_position.x)
					var z := floori(other.global_position.z) + 2
					player.global_position = Vector3(x + 0.5, sandbox.world.find_standing_y(x, z) + 0.05, z + 0.5)
				_games_at = _t
		1:
			if _t > _games_at + 1.0:
				_games_step = 2
				var other := _other_player(player)
				if other:
					Session.games_request_find(GameRules.player_key(other.peer_id))
					print("LANTEST client games asked to find p%d" % other.peer_id)
		2:
			if games.kind == GameRules.STORM_RUN and games.running():
				_games_step = 3
				_games_at = _t
		3:
			if _t > _games_at + 3.0:
				_games_step = 4
				for id: int in games.storm.stars:
					player.global_position = games.storm.stars[id] - Vector3(0, 1.0, 0)
					print("LANTEST client games at star %d" % id)
					break
		4:
			if sandbox.hud.team_photo_button.visible:
				_games_step = 5
				print("LANTEST client games photo button=true")
				Session.games_request_photo()


func _other_player(me: Player) -> Player:
	for p: Player in get_tree().get_nodes_in_group(&"players"):
		if p != me:
			return p
	return null


# --- Trading between players over LAN (owner #37; user arg --trade on both, and --survivor on the host) ---------
# t 12: the host gives itself 10 Stone and the guest 3 Diamonds, then asks the guest to trade. The guest says YES
# when asked and offers 2 Diamonds; the host offers 5 Stone; each presses READY once both offers show. Both log
# the ask, every state they hear, the end and their chat line, and at t 16 what their bag holds:
#   LANTEST host trade bag stone=5 diamond=2   /   LANTEST client trade bag stone=5 diamond=1

var _trade_step := 0
var _trade_linked := false
var _trade_offered := false
var _trade_readies := 0


func _trade_phase(player: Player, host: bool) -> void:
	if not _trade_linked:
		_trade_linked = true
		Session.player_trade_asked.connect(func(peer: int, from_name: String) -> void:
			print("LANTEST %s trade asked by=%d name=%s" % [_role(host), peer, from_name])
			Session.player_trade_answer(peer, true))
		Session.player_trade_changed.connect(func(state: Dictionary) -> void: _trade_state(state, host))
		Session.player_trade_ended.connect(func(done: bool, text: String) -> void:
			print("LANTEST %s trade ended done=%s text='%s'" % [_role(host), done, text]))
		Session.player_trade_note.connect(func(text: String) -> void: print("LANTEST %s trade note '%s'" % [_role(host), text]))
		Session.chat_received.connect(func(_from: String, text: String, _kind: StringName) -> void:
			if text.begins_with("You traded"):
				print("LANTEST %s trade line '%s'" % [_role(host), text]))
	if host and _trade_step == 0 and _t > 12.0 and not multiplayer.get_peers().is_empty():
		_trade_step = 1
		var guest := multiplayer.get_peers()[0]
		Session.inventory_of(player.peer_id).add(BlockIds.STONE, 10)
		Session.inventory_of(guest).add(BlockIds.DIAMOND, 3)
		Session.player_trade_ask(guest)
	if _trade_step < 2 and _t > 16.0:
		_trade_step = 2
		var inv := Session.my_inventory
		print("LANTEST %s trade bag stone=%d diamond=%d" % [_role(host), inv.count(BlockIds.STONE), inv.count(BlockIds.DIAMOND)])


func _trade_state(state: Dictionary, host: bool) -> void:
	print("LANTEST %s trade state mine=%s theirs=%s my_ready=%s their_ready=%s" % [_role(host), state.mine, state.theirs,
		state.my_ready, state.their_ready])
	if not _trade_offered:
		_trade_offered = true
		Session.player_trade_offer([[BlockIds.STONE, 5]] if host else [[BlockIds.DIAMOND, 2]], 0)
		return
	var both := not (state.mine.items as Array).is_empty() and not (state.theirs.items as Array).is_empty()
	if both and not bool(state.my_ready) and _trade_readies < 3:   # a change made us not ready: ready again
		_trade_readies += 1
		Session.player_trade_ready(true)
