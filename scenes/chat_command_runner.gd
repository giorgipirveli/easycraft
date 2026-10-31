class_name ChatCommandRunner
extends Node
## Runs chat commands (ChatCommands parses them; spec §3b). Local commands act on this device's
## own player, hotbar and settings: each player simulates their own body, so /tp, /fly or /size
## need no host, and /give only fills a hotbar slot (placing still goes through the host's edit
## checks). World-changing commands (/time, /home, /summon) go to the host through
## Session.request_command; the host re-checks the text and runs them here through hooks on the
## sandbox. A hook that doesn't exist yet answers SOON.
##
## Sandbox hooks (host side, found with has_method):
##   set_time_of_day(t: float)                           t in 0..1, 0 = midnight (ChatCommands.TIME_*)
##   go_home(peer_id: int)                               that player back to their bed (or the spawn)
##   summon_animal(species: StringName, near: Vector3)   near = the asking player's feet
##   summon_monster(kind: StringName, level: int, near: Vector3)   /summon slime 3 (M2 Task 4)
##   find_secret(kind: StringName, near: Vector3)        the nearest unfound secret (M2 Task 16)
##   summon_boss(near: Vector3)                          /summon golem (M2 Task 10)
## A hook may return a non-empty String; it is then shown to the asking player instead of the
## default reply (for example "There are too many animals here!").
##
## Owner feedback #40 (spec §3b "More commands") reads the sandbox's parts by name instead of new hooks
## (the lead kept this task out of sandbox.gd): `player`, `hud`, `sky` (its `running`), `photo` (open()),
## `pause_menu` (the MONSTERS switch), `meta` (monsters_on), save_world(), travel_to(u), is_client(), and
## the children "Sandstorm"/"Snowstorm" (SandstormDirector), "Animals", "Traders", "Boss" (its portals),
## "PortalFrames" (their swirls), "Secrets" and `universe_hub` (its stone circle); the bot friends'
## director is the node in the group &"bot_director".

const SOON := "That command arrives soon!"
const TP_BESIDE := Vector3(1, 0, 0)   # /tp name lands next to that player
const SIZE_REPLIES := {
	SizeMagic.Mode.GIANT: "You are a GIANT!", SizeMagic.Mode.TINY: "You are tiny!",
	SizeMagic.Mode.NORMAL: "Back to your normal size.",
}

var sandbox: Node   # scenes/sandbox.gd: world, player and the hooks above
var chat: ChatPanel


func _ready() -> void:
	Session.command_requested.connect(run_host)
	Session.clock_frozen_changed.connect(_on_clock_frozen)   # owner feedback #40
	Session.client_ready.connect(_on_client_ready)


static func handler_name(command: StringName) -> String:
	return "_cmd_" + String(command)


## A command typed by the local player (the text starts with "/").
func run(text: String) -> void:
	var me := multiplayer.get_unique_id()
	var p := _player()
	var cmd := ChatCommands.parse(text, p.global_position if p else Vector3.ZERO)
	if cmd.has("error"):
		_reply(me, cmd.error, &"error")
	elif ChatCommands.refusal(cmd.name, Session.commands_enabled, Game.mode) != "":
		_reply(me, ChatCommands.refusal(cmd.name, Session.commands_enabled, Game.mode), &"error")
	elif ChatCommands.runs_on_host(cmd.name):
		Session.request_command(text)
	elif ChatCommands.LIMITED.has(cmd.name) and not _limiter.allow(me, clock.call()):
		_reply(me, ChatRules.message("too_fast"), &"error")   # owner feedback #40: heavy local ones
	else:
		call(handler_name(cmd.name), cmd, me)


## Host: a world-changing command from a player, already checked by Session (ChatCommands.host_check).
func run_host(peer_id: int, cmd: Dictionary) -> void:
	if ChatCommands.runs_on_host(cmd.get("name", &"")):
		call(handler_name(cmd.name), cmd, peer_id)


# --- Local commands ---------------------------------------------------------------------------

func _cmd_help(cmd: Dictionary, peer_id: int) -> void:
	var ctx := {"mode": Game.mode, "enabled": Session.commands_enabled}   # owner feedback #40: what this child may use
	for line in ChatCommands.help_lines(cmd.get("topic", &""), ctx):
		_reply(peer_id, line)


func _cmd_tp(cmd: Dictionary, peer_id: int) -> void:
	var p := _player()
	if p == null:
		return
	_wake_first(p)
	if cmd.has("pos"):
		var pos: Vector3 = cmd.pos
		p.spawn_at(pos)
		_reply(peer_id, tr("Whoosh! Off to %d %d %d.") % [floori(pos.x), floori(pos.y), floori(pos.z)])
		return
	var target_id := ChatCommands.find_player(cmd.player, Session.chat_names)
	if target_id == peer_id:
		_reply(peer_id, "That's you!")
		return
	var target: Player = Session._player_for_peer(target_id) if target_id != -1 else null
	if target == null or not target.is_spawned():
		_reply(peer_id, tr("Nobody called %s is here.") % cmd.player, &"error")
		return
	p.spawn_at(target.global_position + TP_BESIDE)
	_reply(peer_id, tr("Whoosh! You jumped to %s.") % Session.chat_names.get(target_id, cmd.player))


func _cmd_spawn(_cmd: Dictionary, peer_id: int) -> void:
	var p := _player()
	var w := _world()
	if p == null or w == null:
		return
	_wake_first(p)
	var column := w.spawn_column()
	p.spawn_on_surface(column.x, column.y)
	_reply(peer_id, "Back to the start!")


func _cmd_fly(_cmd: Dictionary, peer_id: int) -> void:
	_set_physics_mode(peer_id, PhysicsMode.Mode.FLY, "Fly mode! Up and down to fly.")


func _cmd_ghost(_cmd: Dictionary, peer_id: int) -> void:
	_set_physics_mode(peer_id, PhysicsMode.Mode.GHOST, "Ghost mode! Fly through anything.")


func _cmd_walk(_cmd: Dictionary, peer_id: int) -> void:
	_set_physics_mode(peer_id, PhysicsMode.Mode.NORMAL, "Walking again.")


func _cmd_size(cmd: Dictionary, peer_id: int) -> void:
	var p := _player()
	if p == null:
		return
	_wake_first(p)
	p.set_size_mode(cmd.mode)
	_reply(peer_id, SIZE_REPLIES.get(cmd.mode, "Size Magic!"))


func _cmd_jumps(cmd: Dictionary, peer_id: int) -> void:
	store_setting.call("max_jumps", cmd.count)
	_reply(peer_id, "Double jump is on!" if cmd.count == 2 else "Triple jump is on!")


func _cmd_style(cmd: Dictionary, peer_id: int) -> void:
	store_setting.call("style", cmd.style)
	if cmd.style == "realistic" and not RealisticPack.present():   # M7: a browser before the realistic pack
		_reply(peer_id, STYLE_COMING)
		return
	_reply(peer_id, tr("The world looks %s now.") % cmd.style)


func _cmd_seed(_cmd: Dictionary, peer_id: int) -> void:
	var w := _world()
	if w == null:
		return
	var generator := w.terrain().generator as MeadowsGenerator
	if generator:
		_reply(peer_id, tr("World seed: %d") % generator.world_seed)


func _cmd_clear(_cmd: Dictionary, _peer_id: int) -> void:
	if chat:
		chat.clear_history()


func _cmd_give(cmd: Dictionary, peer_id: int) -> void:
	var p := _player()
	if p == null:
		return
	var interactor := p.get_node("BlockInteractor") as BlockInteractor
	interactor.set_slot_block(interactor.selected_slot, cmd.id)
	# Owner feedback #40: the count is what the child asked for; in Sandbox (where /give works) every block
	# is endless, so the slot simply holds it.
	_reply(peer_id, ChatCommands.give_words(cmd.id, int(cmd.get("count", 1))))


# --- Host commands (hooks on the sandbox) -----------------------------------------------------

func _cmd_time(cmd: Dictionary, peer_id: int) -> void:
	if not _has_hook("set_time_of_day"):
		_reply(peer_id, SOON)
		return
	var said: Variant = sandbox.call("set_time_of_day", cmd.time)
	if not _hook_replied(peer_id, said):
		Session.broadcast_chat_line(tr("%s made it %s.") % [_name(peer_id), cmd.choice])


func _cmd_home(_cmd: Dictionary, peer_id: int) -> void:
	if not _has_hook("go_home"):
		_reply(peer_id, SOON)
		return
	var said: Variant = sandbox.call("go_home", peer_id)
	if not _hook_replied(peer_id, said):
		_reply(peer_id, "Going home!")


## /secret (M2 Task 16): where the nearest secret nobody found yet is, for the asking player only.
func _cmd_secret(cmd: Dictionary, peer_id: int) -> void:
	var body := Session._player_for_peer(peer_id)
	if not _has_hook("find_secret") or body == null or not body.is_spawned():
		_reply(peer_id, SOON)
		return
	_reply(peer_id, str(sandbox.call("find_secret", cmd.kind, body.global_position)))


func _cmd_summon(cmd: Dictionary, peer_id: int) -> void:
	if cmd.has("boss"):
		_summon_boss(peer_id, StringName(cmd.boss))
		return
	var monster := cmd.has("monster")
	if not _has_hook("summon_monster" if monster else "summon_animal"):
		_reply(peer_id, SOON)
		return
	var body := Session._player_for_peer(peer_id)
	if body == null or not body.is_spawned():
		_reply(peer_id, "Wait until you are in the world.", &"error")
		return
	if monster:
		var said_m: Variant = sandbox.call("summon_monster", cmd.monster, cmd.level, body.global_position)
		if not _hook_replied(peer_id, said_m):
			Session.broadcast_chat_line(tr("%s called a level %d %s! Watch out!") % [_name(peer_id), cmd.level,
				String(cmd.monster).replace("_", " ")])   # owner #39: "a shadow bat", not "shadow_bat"
		return
	var said: Variant = sandbox.call("summon_animal", cmd.species, body.global_position)
	if not _hook_replied(peer_id, said):
		var animal := String(cmd.species).replace("_", " ")   # M3 Task 19: "an arctic fox", not "a arctic_fox"
		var a := "an" if "aeiou".contains(animal.left(1)) else "a"
		Session.broadcast_chat_line(tr("%s called %s %s!") % [_name(peer_id), a, animal])


## /summon golem (M2 Task 10): the Stone Golem a few steps from the asking player.
func _summon_boss(peer_id: int, kind: StringName = BossRules.GOLEM) -> void:
	if not _has_hook("summon_boss"):
		_reply(peer_id, SOON)
		return
	var body := Session._player_for_peer(peer_id)
	if body == null or not body.is_spawned():
		_reply(peer_id, "Wait until you are in the world.", &"error")
		return
	var said: Variant = sandbox.call("summon_boss", body.global_position) if kind == BossRules.GOLEM \
		else sandbox.call("summon_boss", body.global_position, kind)   # M3 Task 2: /summon serpent
	if not _hook_replied(peer_id, said):
		Session.broadcast_chat_line(str(BossRules.words(kind).summon) % _name(peer_id))


# --- Helpers ----------------------------------------------------------------------------------

func _has_hook(method: String) -> bool:
	return sandbox != null and sandbox.has_method(method)


func _hook_replied(peer_id: int, said: Variant) -> bool:
	if said is String and said != "":
		_reply(peer_id, said)
		return true
	return false


func _set_physics_mode(peer_id: int, mode: int, text: String) -> void:
	var p := _player()
	if p == null:
		return
	_wake_first(p)
	p.set_physics_mode(mode)
	_reply(peer_id, text)


## Same as the settings panel: saved in the profile and applied right away.
func _store_setting(key: String, value: Variant) -> void:
	Profile.data.settings[key] = value
	Profile.save()
	Game.apply_settings()


## A command that moves or changes the body gets the sleeper out of bed first (the host then stops
## counting them as asleep; the wake never pulls them back, see Player.set_sleeping).
func _wake_first(p: Player) -> void:
	if p.sleeping:
		Session.request_bed_wake()


func _reply(peer_id: int, text: String, kind: StringName = &"system") -> void:
	Session.send_chat_line(peer_id, text, kind)


func _name(peer_id: int) -> String:
	return str(Session.chat_names.get(peer_id, "Someone"))


func _player() -> Player:
	return sandbox.get("player") as Player if sandbox else null


func _world() -> WorldService:
	return sandbox.get("world") as WorldService if sandbox else null


# --- Owner 40: more commands ------------------------------------------------------------------------

## /pet: a pet farther than this pops up next to its owner (nearer ones walk over).
const PET_CALL_NEAR := 8.0
const PET_BESIDE: Array[Vector3] = [Vector3(1.5, 0.3, 1.5), Vector3(-1.5, 0.3, 1.5), Vector3(1.5, 0.3, -1.5),
	Vector3(-1.5, 0.3, -1.5)]
## /music on after /music off: the settings' default music volume.
const MUSIC_ON_VOLUME := 0.6
const NEXT_NONE := "The game's own music plays here. Try /music classical!"
## M7: a browser before its music pack is in (Music.more_music_coming).
const NEXT_COMING := "More music is on its way…"
## M7: /style realistic in a browser before its realistic pack is in (RealisticPack.present).
const STYLE_COMING := SettingsPanel.REALISTIC_COMING

## (key, value) -> void: a setting saved and applied (tests catch it instead of writing the profile).
var store_setting: Callable = _store_setting
## () -> float seconds: the rate limit's and /clearbag's clock (tests move it).
var clock: Callable = func() -> float: return Time.get_ticks_msec() / 1000.0
## () -> Array: the avatar items this child owns (AvatarUnlocks ids), for /dance and /emote.
var owned: Callable = func() -> Array: return Profile.data.cosmetics
## (edits: Array) -> bool: /build's one batch of edits, through the interactor to the host (one undo step).
var place_edits: Callable = _place_edits
## /find's arrow on this game's HUD (made the first time).
var find_arrow: FindArrow

var _limiter := ChatRules.RateLimiter.new()
var _clearbag_asked := {}   # host: peer id -> when /clearbag first asked (clock seconds)


## Everyone: the host stopped or started the day clock (Session, /freeze).
func _on_clock_frozen(frozen: bool) -> void:
	var sky: Object = sandbox.get("sky") if sandbox else null
	if sky:
		sky.set("running", not frozen)


## Host: a guest who joins hears the clock and whether commands are on.
func _on_client_ready(peer_id: int) -> void:
	Session.send_command_state(peer_id)


func _exit_tree() -> void:
	Session.command_state_reset()   # the game is over: the next one's clock runs


# Host commands

func _cmd_weather(cmd: Dictionary, peer_id: int) -> void:
	var storm := _storm()
	var universe_weather: StringName = (&"snowstorm" if storm.snow else &"sandstorm") if storm else &""
	var why := ChatCommands.weather_refusal(cmd.weather, universe_weather)
	if why != "":
		_reply(peer_id, why, &"error")
		return
	if storm == null:
		_reply(peer_id, "The sky is clear here!")
		return
	storm.force(cmd.weather != &"clear")
	Session.broadcast_chat_line(ChatCommands.weather_words(cmd.weather, _name(peer_id)))


func _storm() -> SandstormDirector:
	if sandbox == null:
		return null
	for n in ["Sandstorm", "Snowstorm"]:
		var s := sandbox.get_node_or_null(n) as SandstormDirector
		if s:
			return s
	return null


func _cmd_heal(_cmd: Dictionary, peer_id: int) -> void:
	var p := Session._player_for_peer(peer_id)
	if p == null:
		_reply(peer_id, "Wait until you are in the world.", &"error")
		return
	if p.health.is_knocked_out():
		_reply(peer_id, "Wait until you are back on your feet!", &"error")
		return
	if p.health.hp >= Health.MAX_HP:
		_reply(peer_id, "Your hearts are full already!")
		return
	p.health.heal(Health.MAX_HP)
	Session.broadcast_health(peer_id, p.health.hp)   # like the hearts' own regrowth (Player.tick_health)
	Session.player_hurt.emit(peer_id, p.health.hp, Vector3.INF)
	_reply(peer_id, "All better! Your hearts are full.")


## /peace: the pause menu's MONSTERS switch (Sandbox), so monsters puff away, waves stop and the menu agrees.
func _cmd_peace(cmd: Dictionary, peer_id: int) -> void:
	var menu: PauseMenu = sandbox.get("pause_menu") as PauseMenu if sandbox else null
	var meta: WorldMeta = sandbox.get("meta") as WorldMeta if sandbox else null
	if menu == null or meta == null:
		_reply(peer_id, SOON)
		return
	var peace := ChatCommands.switch_value(cmd.switch, not meta.monsters_on)
	if peace == not meta.monsters_on:
		_reply(peer_id, "Peace is on already." if peace else "Monsters come at night already.")
		return
	menu.show_monsters_setting(not peace)
	menu.monsters_toggled.emit(not peace)
	Session.broadcast_chat_line((tr("%s made peace: the monsters went home.") if peace
		else tr("%s let the monsters come back at night.")) % _name(peer_id))


func _cmd_freeze(cmd: Dictionary, peer_id: int) -> void:
	var frozen := ChatCommands.switch_value(cmd.switch, Session.clock_frozen)
	Session.set_clock_frozen(frozen)
	Session.broadcast_chat_line((tr("%s stopped the clock. /freeze starts it again.") if frozen
		else tr("%s started the clock again.")) % _name(peer_id))


## /pet: your pets stand up and come; far ones pop up next to you.
func _cmd_pet(_cmd: Dictionary, peer_id: int) -> void:
	var body := Session._player_for_peer(peer_id)
	var animals: Node = sandbox.get_node_or_null("Animals") if sandbox else null
	var names: Array = []
	if body and body.is_spawned() and animals:
		for a in animals.get_children():
			var pet := a as Animal
			if pet == null or pet.owner_peer != peer_id or pet.is_queued_for_deletion():
				continue
			pet.sitting = false
			if pet.global_position.distance_to(body.global_position) > PET_CALL_NEAR:
				pet.global_position = body.global_position + PET_BESIDE[names.size() % PET_BESIDE.size()]
				pet.velocity = Vector3.ZERO
			names.append(pet.pet_name)
	_reply(peer_id, ChatCommands.pets_words(names))


## /boss (Sandbox): this universe's boss (the Golem, the Sand Serpent, the Frost Giant …).
func _cmd_boss(_cmd: Dictionary, peer_id: int) -> void:
	var kind := UniverseRegistry.boss_kind(Game.universe)
	_summon_boss(peer_id, kind if kind != &"" else BossRules.GOLEM)


## /clearbag (Survivor): the first one asks, a second one within CLEARBAG_SECONDS empties the bag.
func _cmd_clearbag(_cmd: Dictionary, peer_id: int) -> void:
	var now: float = clock.call()
	if not ChatCommands.confirmed(float(_clearbag_asked.get(peer_id, -INF)), now):
		_clearbag_asked[peer_id] = now
		_reply(peer_id, "This empties your whole bag! Type /clearbag again to do it.")
		return
	_clearbag_asked.erase(peer_id)
	var inv := Session.inventory_of(peer_id)
	for id in inv.ids():
		inv.take(id, inv.count(id))
	_reply(peer_id, "Your bag is empty now.")


# Local commands

func _cmd_kit(_cmd: Dictionary, peer_id: int) -> void:
	var interactor := _interactor()
	if interactor == null:
		return
	for i in mini(ChatCommands.KIT.size(), interactor.hotbar.size()):
		interactor.hotbar[i] = ChatCommands.KIT[i]
	interactor.select_slot(0)
	_reply(peer_id, "Here is a builder's kit!")


## /speed 1: the Lab's slow motion; 2: normal; 3: the Speed potion's 1.5× (the host lets it work, 60 s).
func _cmd_speed(cmd: Dictionary, peer_id: int) -> void:
	var p := _player()
	if p == null:
		return
	_wake_first(p)
	var speed: int = cmd.speed
	if speed == 1:
		p.set_lab_mode(LabRules.Mode.SLOW)
		_reply(peer_id, LabRules.toast(LabRules.Mode.SLOW))
		return
	if p.lab_mode == LabRules.Mode.SLOW:
		p.set_lab_mode(LabRules.Mode.NORMAL)
	if speed == 3:
		Session.request_drink(ItemIds.POTION_SPEED)
		_reply(peer_id, "Zoom! Super fast for a minute.")
	else:
		_reply(peer_id, "Normal speed.")


func _cmd_gravity(cmd: Dictionary, peer_id: int) -> void:
	var p := _player()
	if p == null:
		return
	_wake_first(p)
	p.set_lab_mode(cmd.gravity)
	_reply(peer_id, LabRules.toast(cmd.gravity))


## /universe (Survivor): the stone circle's travel, alone, to an unlocked universe.
func _cmd_universe(cmd: Dictionary, peer_id: int) -> void:
	if not _has_hook("travel_to"):
		_reply(peer_id, SOON)
		return
	var said := str(sandbox.call("travel_to", cmd.universe))
	_reply(peer_id, said if said != "" else tr("Off to %s!") % Lang.t(UniverseRegistry.display_name(cmd.universe)))


## /build: the stamp two blocks ahead, facing the way you look; one batch, so UNDO takes it all back.
func _cmd_build(cmd: Dictionary, peer_id: int) -> void:
	var p := _player()
	if p == null or not p.is_spawned():
		return
	var forward := Blueprints.facing_for_yaw(p.rig.yaw)
	var anchor := ChatCommands.build_anchor(p.global_position, forward)
	if not place_edits.call(Blueprints.place(cmd.stamp, anchor, forward)):
		_reply(peer_id, "No room to build here.", &"error")
		return
	if p.world:
		Audio.play(&"place", Vector3(anchor))
		Fx.burst(p.world, Vector3(anchor) + Vector3(0.5, 2.0, 0.5), Color("ffd23f"), 28, 6.0, 0.16, 0.9, 6.0)
	_reply(peer_id, tr("Ta-da! A %s! UNDO takes it back.") % String(cmd.choice))


func _place_edits(edits: Array) -> bool:
	var interactor := _interactor()
	return interactor != null and interactor.apply_edits(edits, false)


func _cmd_dance(cmd: Dictionary, peer_id: int) -> void:
	var e: StringName = cmd.emote
	if e == &"":
		var mine := ChatCommands.owned_dances(owned.call())
		e = mine[randi() % mine.size()] if not mine.is_empty() else &"dance_hop"
	_play_emote(e, peer_id)


func _cmd_emote(cmd: Dictionary, peer_id: int) -> void:
	_play_emote(cmd.emote, peer_id)


func _play_emote(e: StringName, peer_id: int) -> void:
	var p := _player()
	if p == null:
		return
	if not ChatCommands.owns_emote(e, owned.call()):
		_reply(peer_id, ChatCommands.emote_locked_words(e), &"error")
	elif not p.play_emote(e):
		_reply(peer_id, "Not now! Stand in the world first.", &"error")


## /bot (host and solo, like the pause menu's FRIENDS row): add a friend, or send one home.
func _cmd_bot(cmd: Dictionary, peer_id: int) -> void:
	var director: Node = null
	if is_inside_tree() and not (sandbox and sandbox.has_method("is_client") and sandbox.call("is_client")):
		director = get_tree().get_first_node_in_group(&"bot_director")
	if director == null:
		_reply(peer_id, "Only the host can bring bot friends.", &"error")
		return
	if cmd.action == &"add":
		var personality: StringName = cmd.personality
		if personality == &"":
			personality = BotRules.PERSONALITIES[randi() % BotRules.PERSONALITIES.size()]
		if director.call(&"add", personality) == null:
			_reply(peer_id, tr("You have %d bot friends already!") % BotRules.MAX_BOTS, &"error")
		return
	var names := {}
	var i := 0
	for b: Variant in director.call(&"bots"):
		names[i] = str((b as Object).get("bot_name"))
		i += 1
	if names.is_empty():
		_reply(peer_id, "You have no bot friends yet. Try /bot add", &"error")
		return
	var wanted: String = cmd.bot
	var found := ChatCommands.find_player(wanted, names) if wanted != "" else (0 if names.size() == 1 else -1)
	if found == -1:
		var list := PackedStringArray()
		for n: String in names.values():
			list.append(n)
		_reply(peer_id, tr("Say which friend: /bot remove %s") % " or ".join(list), &"error")
		return
	director.call(&"remove", names[found])


func _cmd_xp(_cmd: Dictionary, peer_id: int) -> void:
	_reply(peer_id, ChatCommands.xp_words(Progress.data()))


func _cmd_level(_cmd: Dictionary, peer_id: int) -> void:
	_reply(peer_id, ChatCommands.level_words(Progress.data()))


## /music off and on are the settings' music volume; classical and game are the audio pass's MUSIC setting
## (settings.music_style, MusicPlan); next skips to another piece where pieces play (Music.next_piece).
func _cmd_music(cmd: Dictionary, peer_id: int) -> void:
	var wanted: StringName = cmd.music
	if wanted == &"off":
		store_setting.call("music_volume", 0.0)
		_reply(peer_id, "Music off. /music on brings it back.")
		return
	if wanted == &"next":
		if Music.next_piece():
			_reply(peer_id, "Next song!")
		else:
			_reply(peer_id, NEXT_COMING if Music.more_music_coming() else NEXT_NONE)
		return
	if float(Profile.data.settings.get("music_volume", MUSIC_ON_VOLUME)) <= 0.0:
		store_setting.call("music_volume", MUSIC_ON_VOLUME)
	if wanted == &"on":
		_reply(peer_id, "Music on!")
		return
	var style := MusicPlan.CLASSICAL if wanted == &"classical" else MusicPlan.GAME
	store_setting.call("music_style", String(style))
	_reply(peer_id, "Classical music!" if style == MusicPlan.CLASSICAL else "Game music!")


func _cmd_photo(_cmd: Dictionary, peer_id: int) -> void:
	var photo: Object = sandbox.get("photo") if sandbox else null
	if photo and photo.has_method(&"open"):
		photo.call(&"open")
	else:
		_reply(peer_id, SOON)


func _cmd_save(_cmd: Dictionary, peer_id: int) -> void:
	if sandbox and sandbox.has_method("is_client") and sandbox.call("is_client"):
		_reply(peer_id, "The host saves this world.")
		return
	if not _has_hook("save_world"):
		_reply(peer_id, SOON)
		return
	sandbox.call("save_world")
	_reply(peer_id, "Saved!")


## /find: an arrow on the HUD and words with the distance and the way.
func _cmd_find(cmd: Dictionary, peer_id: int) -> void:
	var p := _player()
	if p == null or not p.is_spawned():
		return
	var why := ChatCommands.find_refusal(cmd.target, Game.mode, _has_map())
	if why != "":
		_reply(peer_id, why, &"error")
		return
	var t := _find_target(cmd.target, p)
	if t.is_empty():
		_reply(peer_id, ChatCommands.find_missing(cmd.target, Game.mode), &"error")
		return
	_point(str(t.what), t.pos, p)
	_reply(peer_id, ChatCommands.find_words(str(t.what), p.global_position, t.pos, p.rig.yaw))


## {pos, what} of the nearest `target` this game knows, or {} when there is none here.
func _find_target(target: StringName, p: Player) -> Dictionary:
	var here := p.global_position
	match target:
		&"tilly":
			var traders: Node = sandbox.get_node_or_null("Traders") if sandbox else null
			return _nearest(traders.get_children() if traders else [], here, "Tilly")
		&"home":
			if p.has_home:
				return {"pos": Vector3(p.home_bed) + Vector3(0.5, 0.0, 0.5), "what": "your bed"}
			var w := _world()
			if w == null:
				return {}
			var c := w.spawn_column()
			return {"pos": Vector3(c.x + 0.5, w.surface_height(c.x, c.y) + 1, c.y + 0.5), "what": "the world's start"}
		&"portal":
			var nodes: Array = []
			var boss: BossDirector = sandbox.get_node_or_null("Boss") as BossDirector if sandbox else null
			if boss:
				nodes.append_array(boss.portals())
			var frames: PortalDirector = sandbox.get_node_or_null("PortalFrames") as PortalDirector if sandbox else null
			if frames:
				for s in frames.swirls():
					if s.visible:
						nodes.append(s)
			var hub: Object = sandbox.get("universe_hub") if sandbox else null
			if hub and hub.get("circle"):
				nodes.append(hub.get("circle"))
			return _nearest(nodes, here, "the portal")
		&"treasure":
			var secrets: SecretDirector = sandbox.get_node_or_null("Secrets") as SecretDirector if sandbox else null
			var s: Dictionary = secrets.map_target(here) if secrets and secrets.rules else {}
			if s.is_empty():
				return {}
			return {"pos": Vector3(s.chest) + Vector3(0.5, 0.5, 0.5), "what": "the treasure"}
		&"launch":   # owner #98: the Mission Board of this home world's Launch Site
			var launch: Object = sandbox.get("launch_site") if sandbox else null
			var site: Variant = launch.get("site") if launch != null else null
			if not site is Dictionary or (site as Dictionary).is_empty():
				return {}
			return {"pos": LaunchSite.board_position(site), "what": "the Launch Site"}
	return {}


func _nearest(nodes: Array, here: Vector3, what: String) -> Dictionary:
	var best := {}
	var best_d := INF
	for n: Variant in nodes:
		var n3 := n as Node3D
		if n3 == null or not n3.is_inside_tree() or n3.is_queued_for_deletion():
			continue
		var d := n3.global_position.distance_to(here)
		if d < best_d:
			best_d = d
			best = {"pos": n3.global_position, "what": what}
	return best


## A Treasure Map in the hotbar or the bag (Survivor's /find treasure needs one).
func _has_map() -> bool:
	var interactor := _interactor()
	return (interactor != null and interactor.hotbar.has(ItemIds.TREASURE_MAP)) \
		or Session.my_inventory.count(ItemIds.TREASURE_MAP) > 0


## Owner #45b: the world map points the same arrow at a place the child tapped.
func point_at(what: String, pos: Vector3) -> void:
	var p := _player()
	if p:
		_point(what, pos, p)


## The arrow on this game's HUD, pointing at `pos`.
func _point(what: String, pos: Vector3, p: Player) -> void:
	var hud: Control = sandbox.get("hud") as Control if sandbox else null
	if hud == null:
		return
	if find_arrow == null or not is_instance_valid(find_arrow):
		find_arrow = FindArrow.new()
		find_arrow.name = "FindArrow"
		var compass: Variant = hud.get("compass")
		if compass is Control:
			find_arrow.covered = func() -> bool: return is_instance_valid(compass) and (compass as Control).visible
		find_arrow.arrived.connect(_on_found)
		hud.add_child(find_arrow)
	find_arrow.player = p
	find_arrow.point_to(what, pos)


func _on_found(what: String) -> void:
	var hud: Object = sandbox.get("hud") if sandbox else null
	var text := tr("You found %s!") % what
	if hud and hud.has_method(&"toast"):
		hud.call(&"toast", text, 3.0)
	else:
		_reply(multiplayer.get_unique_id(), text)


func _interactor() -> BlockInteractor:
	var p := _player()
	return p.get_node_or_null("BlockInteractor") as BlockInteractor if p else null

# --- M3 Task 8: /fill and /copy -------------------------------------------------------------------------

const COPY_LOOK := "Look at a build, then /copy it!"

## () -> Vector3i: the block /copy looks at (the middle of the screen), or BuildToolUser.NO_CELL (tests set it).
var copy_target: Callable = _copy_target


## /fill: a box of the block two blocks ahead (like /build: centred, reaching away), only into empty cells, as one
## FILL request (the host checks it like the FILL tool's: one undo step).
func _cmd_fill(cmd: Dictionary, peer_id: int) -> void:
	var p := _player()
	if p == null or not p.is_spawned():
		return
	var forward := Blueprints.facing_for_yaw(p.rig.yaw)
	var anchor := ChatCommands.build_anchor(p.global_position, forward)
	var size: Vector3i = cmd.size
	var id: int = cmd.id
	var cells: Array = []
	for y in size.y:
		for z in size.z:
			for x in size.x:
				cells.append(Blueprints.to_world(Vector3i(x - size.x / 2, y, z), anchor, forward))
	var edits: Array = cells.map(func(c: Vector3i) -> Array: return [c, id])   # the host builds into the empty cells
	if not Session.request_build_tool(Session.TOOL_FILL, edits):
		_reply(peer_id, "No room to build here.", &"error")
		return
	Audio.play(&"place", Vector3(anchor))
	_reply(peer_id, tr("A box of %s! UNDO takes it back.") % Lang.t(BlockIds.display_name(id)))


## /copy: the build you look at (its connected blocks, at most 16 on a side) goes into the COPY tool, in your hand.
func _cmd_copy(_cmd: Dictionary, peer_id: int) -> void:
	var p := _player()
	var interactor := _interactor()
	if p == null or interactor == null or not p.is_spawned():
		return
	var cell: Vector3i = copy_target.call()
	var picked := {"error": "not_a_build"}
	if cell != BuildToolUser.NO_CELL:
		picked = BuildPicker.pick(cell, p.world.get_block, PowerTools.COPY_MAX_SIDE, PowerTools.FILL_MAX)
	if picked.has("error"):
		_reply(peer_id, PowerTools.message(PowerTools.TOO_BIG_COPY) if picked.error == "too_big" else COPY_LOOK, &"error")
		return
	var blocks := BuildPicker.local(picked)
	interactor.tools.clipboard = PowerTools.to_stamp(blocks, Blueprints.facing_for_yaw(p.rig.yaw))
	interactor.tools.turns = 0
	interactor.set_slot_block(interactor.selected_slot, ItemIds.COPY_TOOL)
	_reply(peer_id, BuildToolUser.copied_words(blocks.size()))


func _copy_target() -> Vector3i:
	var interactor := _interactor()
	if interactor == null:
		return BuildToolUser.NO_CELL
	var hit := interactor.ray_at(interactor.get_viewport().get_visible_rect().size * 0.5)
	return hit.position if hit else BuildToolUser.NO_CELL
