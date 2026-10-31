class_name ProgressDirector
extends Node
## Progress in a world (M3 Task 12, spec §5.8): one per game (node `Progress` in the sandbox), for this
## game's own player. While it is in the tree the Progress autoload counts. Once a second it looks at the
## player: the pet's present clock (active play with a pet near only), new places explored (128 × 128
## areas, the one the world started in excepted), friends played with (other players once each; bot
## friends that join later). It shows level-ups (confetti and a banner, here only), finished goals, new
## badges and presents on the HUD, and keeps the player's synced name tag code. On the host it also
## turns the monster, wave and boss directors' signals into events for the players they belong to.
## Pausing stops it (the tree pauses it), so paused time never counts.

const TICK := 1.0
## Explored places are squares this wide (SecretRules' areas).
const AREA := 128
const MAX_AREAS := 4096

var player: Player
var hud: Hud
## The name of this game's player's pet within PresentRules.PET_NEAR ("" = none there).
var pet_near: Callable = func() -> String: return ""
## A LAN guest's game never saves the world, so it saves the profile itself (tests replace it).
var saves_profile := false
var save_profile: Callable = func() -> void: Profile.save()
## A test's own progress (null: the profile's).
var data_override: ProgressData

var _t := 0.0
var _idle := 0.0
var _last_pos := Vector3.INF
var _last_yaw := 0.0
var _areas := {}
var _friends := {}
var _bots := {}
var _bots_known := false
var _bot_counted := false
var _save_t := 0.0


func _ready() -> void:
	Progress.begin(data_override)
	Progress.leveled_up.connect(_on_level)
	Progress.goal_done.connect(_on_goal)
	Progress.badge_unlocked.connect(_on_badge)
	Progress.present_ready.connect(_on_present)
	Progress.changed.connect(_update_tag)
	_update_tag()


func _exit_tree() -> void:
	if saves_profile:
		save_profile.call()
	Progress.end()
	for s: Signal in [Progress.leveled_up, Progress.goal_done, Progress.badge_unlocked, Progress.present_ready,
			Progress.changed]:
		for c: Dictionary in s.get_connections():
			if c.callable.get_object() == self:
				s.disconnect(c.callable)


func _process(delta: float) -> void:
	_t += delta
	if _t >= TICK:
		_t = 0.0
		tick(TICK)


## One look at the player (TICK seconds of play have passed).
func tick(dt: float) -> void:
	if not is_instance_valid(player) or not player.is_spawned():
		return
	var pos := player.global_position
	var yaw := player.rig.yaw if player.rig else 0.0
	var moved := _last_pos.is_finite() and pos.distance_to(_last_pos) > 0.2
	if moved or absf(yaw - _last_yaw) > 0.05 or Input.is_anything_pressed():
		_idle = 0.0
	else:
		_idle += dt
	_last_pos = pos
	_last_yaw = yaw
	var playing := _idle < PresentRules.IDLE_S and not player.sleeping and not player.knocked_out
	var pet: String = pet_near.call()
	Progress.present_tick(dt, playing, pet != "")
	_explore(pos)
	_meet_friends()
	if saves_profile:
		_save_t += dt
		if _save_t >= 60.0:
			_save_t = 0.0
			save_profile.call()


func _explore(pos: Vector3) -> void:
	var area := Vector2i(floori(pos.x / AREA), floori(pos.z / AREA))
	if _areas.has(area):
		return
	var first := _areas.is_empty()
	if _areas.size() < MAX_AREAS:
		_areas[area] = true
	if not first:
		Progress.event(LevelRules.EXPLORED)


## Other players count once each; bot friends once, when one joins after the world loaded (the saved
## ones were friends already).
func _meet_friends() -> void:
	for n in get_tree().get_nodes_in_group(&"players"):
		var p := n as Player
		if is_instance_valid(p) and p != player and p.peer_id != player.peer_id and not _friends.has(p.peer_id):
			_friends[p.peer_id] = true
			Progress.event(&"friend_played/player")
	for n in get_tree().get_nodes_in_group(&"bot_friends"):
		var id := n.get_instance_id()
		if not _bots.has(id):
			_bots[id] = true
			if _bots_known and not _bot_counted:
				_bot_counted = true   # once a session: BYE and add again is no XP farm
				Progress.event(&"friend_played/bot")
	_bots_known = true


func _update_tag() -> void:
	if is_instance_valid(player):
		player.progress_tag = Progress.tag()


func _banner(text: String, picture: int) -> void:
	if is_instance_valid(hud):
		hud.show_banner(text, picture)


func _on_level(level: int) -> void:
	_banner(tr("Level %d!") % level, Riddles.STAR)
	Audio.play(&"jingle_level")   # the audio pass: a little tune, on this game
	if is_instance_valid(player) and player.is_inside_tree():
		var s := player.size_scale()
		Celebration.confetti(player.get_parent(), player.eye_position() + Vector3.UP * 0.6 * s, s)
		Fx.level_up(player.get_parent(), player.global_position, s)   # M5 Task 2: gold stars rise round the child
	_saved()


func _on_goal(goal_id: StringName, gold: int) -> void:
	var words := str(BoardRules.goal(goal_id).get("words", ""))
	_banner(tr("Goal done: %s!") % words + (tr(" +%d gold") % gold if gold > 0 else ""), Riddles.STAR)
	Audio.play(&"jingle_goal")
	_saved()


func _on_badge(badge_id: StringName) -> void:
	_banner(tr("New badge: %s") % str(AchievementRules.badge(badge_id).get("words", "")), Riddles.STAR)
	Audio.play(&"jingle_badge")
	_saved()


func _on_present() -> void:
	var pet: String = pet_near.call()
	_banner(tr("%s brought you a present! Open it on your BOARD.") % (pet if pet != "" else "Your pet"), Riddles.HEART)
	_saved()


func _saved() -> void:
	if saves_profile:
		save_profile.call()


## Host: events the host decides, told to the players they belong to. `arena`: Monster Wave's arena, whose
## waves count as "wave_won/arena" (owner #45a); a boss counts as the world's own boss (BossDirector.boss_kind).
func watch_host(monsters: Node, waves: Node, boss: Node, arena := false) -> void:
	if monsters:
		monsters.connect(&"monster_defeated", func(kind: StringName, _level: int, pos: Vector3) -> void:
			Session.progress_near(pos, StringName("%s/%s" % [LevelRules.MONSTER, kind])))
	if waves:
		var wave_kind := StringName("%s/arena" % LevelRules.WAVE) if arena else LevelRules.WAVE
		waves.connect(&"wave_ended", func(_wave: int, result: StringName) -> void:
			if WaveRules.is_win(result):
				Session.progress_everyone(wave_kind))
	if boss:
		boss.connect(&"fight_ended", func(won: bool, _percent: int) -> void:
			if won:
				var kind: Variant = boss.get(&"boss_kind")
				Session.progress_everyone(StringName("%s/%s" % [LevelRules.BOSS, kind if kind is StringName and kind != &"" else &"golem"])))
