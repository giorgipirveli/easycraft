extends Node
## The steps of tools/store_shots.gd (docs/store/screenshots.md): each picture in a NEW Sandbox world of its own
## (nothing from one picture wanders into the next), set up through the game's own paths: the chat commands'
## runner (/time, /freeze, /give, /summon, /size, /build, /find), the wand's spark request, Session's block, pet,
## hide and spark requests, the portal frames, the bot friends' RACE ME!, the Secret Book. The camera is the game's
## third-person camera (its yaw and pitch, as a finger drag sets them); the feature graphic's photo uses photo mode's
## own orbit camera with the HUD hidden. Candidates go to $XDG_DATA_HOME/store_shots/<shot>_<n>.jpg (1920 x 1080,
## RGB, quality 0.92); the picked ones are copied to docs/store/graphics/next/ by hand after a look.

const SIZE := Vector2i(1920, 1080)
const QUALITY := 0.92
const USERNAME := "SwiftDragon54"
## Seeds of the worlds the pictures are taken in (Green Meadows, the Candy Kingdom, the Dragon Realm).
const MEADOWS_SEED := 12345
const CANDY_SEED := 424242
const DRAGON_SEED := 515151
const ORDER: Array[String] = ["wake", "size", "portal", "dragon", "dog", "hide", "race", "book", "feature"]
const TIMEOUT := 2400.0
## What the made-up player did before (counted once into the profile's progress before the first world): the
## adventure board's first goals are done, so no "Goal done" banner covers a picture's moment.
const PLAYED := {&"buddy_woken": 6, &"animal_tamed/dog": 2, &"animal_tamed/cat": 1, &"animal_tamed/fox": 1,
	&"animal_tamed/parrot": 1, &"animal_tamed/horse": 1, &"pet_fed/dog": 4, &"secret_found/treasure": 1,
	&"secret_found/room": 1, &"secret_found/geode": 1, &"secret_found/temple": 1, &"secret_found/island": 1,
	&"block_placed": 400, &"photo_taken": 6, &"friend_played/bot": 1, &"race_finished": 2, &"area_explored": 8,
	&"monster_defeated/slime": 6, &"monster_defeated/goblin": 4}

## Trees and plants of every universe (_clear_plants takes them away where they would stand in a picture's way).
const PLANTS: Array[int] = [BlockIds.LOG, BlockIds.LEAVES, BlockIds.BIRCH_LOG, BlockIds.BIRCH_LEAVES, BlockIds.DARK_LOG,
	BlockIds.DARK_LEAVES, BlockIds.FLOWERS, BlockIds.CRYSTAL_SPIRE, BlockIds.MUSHROOM_STEM, BlockIds.GLOW_CAP,
	BlockIds.CANDY_CANE, BlockIds.LOLLIPOP, BlockIds.COTTON_CANDY, BlockIds.PINE_LOG, BlockIds.PINE_NEEDLES]

var _out := ""
var _only: PackedStringArray = []
var _t := 0.0
var sb: Node
var p: Player
var w: WorldService
var runner: ChatCommandRunner
var hud: Hud


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_out = OS.get_environment("XDG_DATA_HOME").path_join("store_shots")
	DirAccess.make_dir_recursive_absolute(_out)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--only="):
			_only = arg.trim_prefix("--only=").split(",", false)
	_profile()
	Session.chat_received.connect(func(from: String, text: String, _kind: StringName) -> void:
		print("STORE_SHOT chat %s: %s" % [from, text]))
	get_window().size = SIZE
	_run.call_deferred()


func _process(delta: float) -> void:
	_t += delta
	if _t > TIMEOUT:
		print("STORE_SHOT timeout")
		get_tree().quit(1)


## A made-up player's profile in the private folder: the new default look, blocky, no FPS counter, every universe
## reached, EasyCraft Plus (so nothing about the shop shows), no first-launch cards, some play behind it.
func _profile() -> void:
	var d := Profile.data
	d.username = USERNAME
	d.age_band = AgeBand.UNDER_13
	d.universe_unlocked = 5
	d.purchases = ["plus"] as Array[String]
	d.settings.show_fps = false
	d.settings.style = "blocky"
	d.settings.graphics = "high"
	d.settings.view_distance = 160
	d.settings.song_names = false
	d.settings.simple_asked = true
	d.settings.read_to_me = false
	d.settings.captions = false
	d.avatar = AvatarLook.new()
	if not d.hints_seen.has(ShopGuide.TIP):
		d.hints_seen.append(ShopGuide.TIP)
	d.progress = ProgressData.new()
	Progress.begin()
	for kind: StringName in PLAYED:
		Progress.event(kind, int(PLAYED[kind]))
	Progress.end()
	print("STORE_SHOT profile level %d" % d.progress.level())
	Profile.save()
	Game.apply_settings()


func _run() -> void:
	print("STORE_SHOT window %s" % DisplayServer.window_get_size())
	var list: Array[String] = ORDER.duplicate()
	for extra in _only:
		if not list.has(extra):
			list.append(extra)   # the probes (probe_candy, probe_dragon) only when asked for
	for shot in list:
		if _only.is_empty() or _only.has(shot):
			print("STORE_SHOT begin %s" % shot)
			await call("_shot_" + shot)
	print("STORE_SHOT done")
	get_tree().quit(0)

# --- 1: a build wakes up --------------------------------------------------------------------------------------

## A small buddy in bright blocks wakes (its eyes open, the wand's gold stars, the toast), the child beside it with
## the wand. Its name tag pops up 1.1 s after the spark, half hidden behind its head from this low camera: the pick is
## a frame before that (eyes open at 0.92-1.12 s).
func _shot_wake() -> void:
	await _start(1, MEADOWS_SEED)
	var o := await _stage(60, 9)
	_build(o, _small_buddy())
	# its middle is o + (0.5, 0, 1); the child 3.3 blocks from it (a buddy follows from 3.5), front right; the camera
	# looks past the child so the buddy stands 15 degrees right of the middle, under the toast
	await _stand(Vector3(o) + Vector3(1.62, 0.0, -2.1))
	_cmd("/give wand")
	await _secs(1.0)
	_shoo_animals(Vector3(o), 40.0)
	_clear()
	_view(PI + 0.26, 0.15)
	_face(0.76)
	await _secs(0.5)
	Session.request_spark(o + Vector3i(0, 2, 0))
	await _secs(0.6)
	for i in 9:
		await _secs(0.1)
		_shoo_animals(Vector3(o), 80.0)   # animals come to look at the magic (their "?" bubbles)
		await _save("wake_%d" % i)

# --- 2: Size Magic --------------------------------------------------------------------------------------------

## A tiny child at the feet of a giant buddy, looking up at its face. The tiny child's camera is only 1.8 blocks
## behind the head and looking up pushes it into the ground (it then squeezes onto the child's face), so the buddy
## and the child stand on a grass terrace 2 blocks high, the child 0.2 from its edge: the camera looks up from below
## the edge (which hides the child's feet).
func _shot_size() -> void:
	await _start(1, MEADOWS_SEED)
	var ground := await _stage(60, 9)
	var o := ground + Vector3i(0, 2, 0)
	for x in range(-9, 10):
		for z in range(-3, 10):
			w.set_block(ground + Vector3i(x, -1, z), BlockIds.DIRT)
			w.set_block(ground + Vector3i(x, 0, z), BlockIds.DIRT)
			w.set_block(ground + Vector3i(x, 1, z), BlockIds.GRASS)
	_build(o, _giant_buddy())
	await _secs(0.5)
	await _stand(Vector3(o) + Vector3(0.5, 0.0, -2.0))
	_cmd("/give wand")
	await _secs(0.5)
	Session.request_spark(o + Vector3i(0, 3, 0))
	await _secs(3.0)
	# a buddy walks after its owner once they are 3.5 blocks away (a verification run had it land on the tiny child):
	# it stays on its own spot, the way a playdate's spot holds it (Buddy.playdate_target)
	for bd: Buddy in sb.call(&"_buddy_nodes"):
		bd.playdate_target = bd.global_position
	_cmd("/size tiny")
	await _secs(1.0)
	# the buddy's middle is o + (0.5, 0, 0.5): the tiny child 3.3 blocks in front of it
	await _stand(Vector3(o) + Vector3(0.5, 0.0, -2.8))
	await _secs(1.5)
	_shoo_animals(Vector3(o), 40.0)
	await _secs(0.3)
	_clear()
	for pitch: float in [0.42, 0.44, 0.46]:   # from 0.5 the spring arm touches the terrace and squeezes onto the child
		for facing: float in [0.0, PI]:
			_view(PI, pitch)
			_face(facing)
			_shoo_animals(Vector3(o), 80.0)   # animals come to look at the magic (their "?" bubbles)
			await _secs(0.6)
			# the arm is 1.8 blocks for a tiny child; shorter: it touched something and the camera sits on the child
			print("STORE_SHOT size pitch %.2f child %s arm %.2f" % [pitch, p.global_position, p.rig.arm.get_hit_length()])
			await _save("size_%d_%d" % [roundi(pitch * 100), roundi(facing)])

# --- 3: a golden portal in the Candy Kingdom -----------------------------------------------------------------

## The Candy Kingdom's own Sandbox world (the world a Candy Crystal's portal opens), away from the Theater: a 2 x 3
## portal frame whose Portal Core the child places, linked with a second one far behind the camera (the child places
## that core too), so it swirls gold with rainbow arms.
func _shot_portal() -> void:
	await _start(4, CANDY_SEED)
	var c := _flat_any(w.generator_shape(), w.spawn_column(), 45, 6)
	await _go(c)
	var feet := Vector3i(c.x, w.generator_shape().height_at(c.x, c.y), c.y)
	print("STORE_SHOT portal spot %s, theater %s" % [feet, _theater()])
	_level(feet, 5, BlockIds.FROSTING, BlockIds.CAKE)
	_shoo_animals(Vector3(feet), 30.0)
	var lo := feet + Vector3i(-4, 0, -3)
	_portal_frame(lo, 2, 3)
	var far := Vector2i(feet.x, feet.z + 30)
	await _go(far)
	var far_lo := Vector3i(far.x, w.find_standing_y(far.x, far.y), far.y) + Vector3i(0, 0, -2)
	_level(far_lo + Vector3i(0, 0, 2), 3, BlockIds.FROSTING, BlockIds.CAKE)
	_portal_frame(far_lo, 1, 2)
	await _secs(0.5)
	print("STORE_SHOT far core %s" % Session.request_set_block(far_lo + Vector3i.DOWN, BlockIds.PORTAL_CORE))
	await _go(Vector2i(feet.x, feet.z))
	await _stand(Vector3(feet) + Vector3(-1.5, 0.0, -1.0))
	print("STORE_SHOT core %s" % Session.request_set_block(lo + Vector3i.DOWN, BlockIds.PORTAL_CORE))
	await _stand(Vector3(feet) + Vector3(0.5, 0.0, 0.5))
	await _secs(2.5)
	_shoo_animals(Vector3(feet), 40.0)
	await _secs(0.3)
	_clear()
	var i := 0
	for yaw: float in [0.15, 0.2]:
		_view(yaw, -0.1)
		_face(yaw + PI - 0.8)
		await _secs(0.6)
		await _save("portal_%d" % i)
		i += 1

# --- 4: the Dragon Realm at sunrise with the Sky Dragon -------------------------------------------------------

## The home island's rim away from the Theater: the Sky Dragon is called there at sunrise, then the child walks 7
## blocks inwards and looks out over the rim (the sea of clouds and the other islands) while it arrives and circles
## the rim and its sun lanterns rise.
func _shot_dragon() -> void:
	await _start(5, DRAGON_SEED)
	var shape := w.generator_shape()
	var home := w.spawn_column()
	var theater := _theater()
	var best := Vector2i.MAX
	var out_dir := Vector2.ZERO
	for a in 16:
		var d := Vector2(cos(TAU * a / 16.0), sin(TAU * a / 16.0))
		var edge := Vector2i.MAX
		for r in range(10, 200):
			var q := home + Vector2i(roundi(d.x * r), roundi(d.y * r))
			if shape.height_at(q.x, q.y) <= MeadowsShape.SEA_LEVEL + 1:
				edge = home + Vector2i(roundi(d.x * (r - 4)), roundi(d.y * (r - 4)))
				break
		if edge == Vector2i.MAX:
			continue
		var far := Vector2(edge).distance_to(Vector2(theater.x, theater.z)) if theater.is_finite() else 999.0
		if far > 60.0 and best == Vector2i.MAX:
			best = edge
			out_dir = d
	if best == Vector2i.MAX:
		print("STORE_SHOT no island edge")
		return
	print("STORE_SHOT dragon rim %s out %s theater %s" % [best, out_dir, theater])
	await _go(best)
	_cmd("/time sunrise")
	await _secs(1.0)
	_clear()
	_cmd("/summon skydragon")
	var inward := best - Vector2i(roundi(out_dir.x * 7), roundi(out_dir.y * 7))
	# the realm's trees (crystal spires, giant mushrooms) between the camera and the rim go; the ground stays
	var mid := best - Vector2i(roundi(out_dir.x * 8), roundi(out_dir.y * 8))
	_clear_plants(shape, mid, 12)
	await _secs(0.5)
	await _stand(Vector3(inward.x + 0.5, shape.height_at(inward.x, inward.y), inward.y + 0.5))
	var out_yaw := atan2(-out_dir.x, -out_dir.y)   # the camera's yaw looking out over the rim
	for i in 22:
		_clear()
		_view(out_yaw + (0.35 if i % 2 == 0 else -0.35), -0.04)
		_face(out_yaw + (0.35 if i % 2 == 0 else -0.35) + (PI - 0.6 if i % 4 < 2 else 0.0))
		await _secs(0.25)
		await _save("dragon_%02d" % i)

# --- 5: the pet dog digs up treasure --------------------------------------------------------------------------

## The nearest buried treasure (its sand X) on flat meadow: a dog tamed by three pets sniffs it out and paws the
## ground over it (a dirt puff every 0.8 s) right beside the child, who stands 1.5 blocks from the X facing the
## camera; /find treasure says "You found the treasure!" there (its arrow only shows from farther away, where the dog
## would be too small to see).
func _shot_dog() -> void:
	await _start(1, MEADOWS_SEED)
	var secrets: SecretDirector = sb.get_node("Secrets")
	var shape := w.generator_shape() as MeadowsBiomeShape
	var theater := _theater()
	var home := Vector3(w.spawn_column().x, 40, w.spawn_column().y)
	var pick := {}
	var best_d := INF
	for s: Dictionary in secrets.rules.secrets_near(home, 900.0):
		if s.kind != SecretRules.TREASURE:
			continue
		var ch: Vector3i = s.chest
		var d := Vector2(ch.x - home.x, ch.z - home.z).length()
		if d < best_d and _flat_at(shape, Vector2i(ch.x, ch.z), 6) \
				and (not theater.is_finite() or Vector2(ch.x, ch.z).distance_to(Vector2(theater.x, theater.z)) > 50.0):
			best_d = d
			pick = s
	if pick.is_empty():
		print("STORE_SHOT no treasure in a meadow")
		return
	var chest: Vector3i = pick.chest
	var h := shape.height_at(chest.x, chest.z)
	var x_top := Vector3(chest.x + 0.5, h, chest.z + 0.5)   # over the sand X
	print("STORE_SHOT treasure chest %s, X at %s" % [chest, x_top])
	await _go(Vector2i(chest.x - 1, chest.z - 5))
	_clear_plants(shape, Vector2i(chest.x, chest.z), 14)   # the flowers and trees round it
	# the ground round it made level at the X's height (only its top two layers: the chest lies deeper), the X
	# put back
	for x in range(-8, 9):
		for z in range(-8, 9):
			var c := Vector3i(chest.x + x, h, chest.z + z)
			w.set_block(c + Vector3i(0, -2, 0), BlockIds.DIRT)
			w.set_block(c + Vector3i(0, -1, 0), BlockIds.GRASS)
			for y in 6:
				w.set_block(c + Vector3i(0, y, 0), BlockIds.AIR)
	for bx: Array in pick.boxes:
		if int(bx[2]) == BlockIds.SAND:
			var cell: Vector3i = bx[0]
			w.set_block(Vector3i(cell.x, h - 1, cell.z), BlockIds.SAND)
	_shoo_animals(x_top, 60.0)
	await _secs(0.5)
	# the camera looks +Z (yaw PI; -X is screen-right): the child 1.5 blocks +X of the X, the dog on the X 18 degrees
	# right of the middle
	await _stand(x_top + Vector3(1.5, 0.0, 0.0))
	var dog := _summon_animal(&"dog")
	if dog == null:
		return
	for k in 3:
		Session.request_pet(dog.name)
	Session.pet_request_name(dog.name, "Biscuit")
	Session.pet_request_collar(dog.name, 2)
	await _secs(1.0)
	dog.set("_sniff_t", 0.0)
	for i in 28:
		if i == 6:
			_cmd("/find treasure")
		_shoo_animals(x_top, 60.0)
		_clear()
		_view(PI + (0.12 if i % 2 == 0 else -0.05), -0.22)
		_face(0.35)   # towards the camera, a little towards the dog
		await _secs(0.2)
		await _save("dog_%02d" % i)
		if i % 4 == 0:
			print("STORE_SHOT dog %.1f from the X, sniffing %s" % [Vector2(dog.global_position.x - x_top.x,
				dog.global_position.z - x_top.z).length(), dog.get("sniffing")])

# --- 6: hiding in a barrel at night ---------------------------------------------------------------------------

## A small house (/build house) with lanterns at its door; 7 blocks in front of it the child hides in a barrel at
## night and looks out (the view from inside the barrel turns like the camera): a goblin summoned between the barrel
## and the house walks about; the view follows it with the house behind.
func _shot_hide() -> void:
	await _start(1, MEADOWS_SEED)
	var o := await _stage(60, 11)
	await _stand(Vector3(o) + Vector3(0.5, 0.0, 0.5))
	_view(0.0, -0.1)
	await _secs(0.3)
	_cmd("/build house")
	await _secs(1.0)
	# the house stands at z -2 .. -8, its door at o + (0, 0, -2); lanterns either side of the door
	Session.request_set_block(o + Vector3i(-2, 0, -1), BlockIds.LANTERN)
	Session.request_set_block(o + Vector3i(2, 0, -1), BlockIds.LANTERN)
	var barrel := o + Vector3i(1, 0, 5)
	await _stand(Vector3(o) + Vector3(1.5, 0.0, 3.5))
	Session.request_set_block(barrel, BlockIds.BARREL)
	_cmd("/time night")
	await _secs(1.0)
	Session.stealth_request_hide(barrel)
	await _secs(0.5)
	_shoo_animals(Vector3(o), 60.0)
	# /peace on first (the night's wild monsters go home and stay away), then a goblin summoned the way /summon does;
	# the summon picks one of four spots 4 blocks round `near` (one of them inside the house), so it is then set down
	# once between the barrel and the house, facing the barrel; from there it walks about by itself
	_cmd("/peace on")
	await _secs(0.5)
	var monsters: MonsterDirector = sb.get("_monsters")
	var before := monsters.monsters()
	print("STORE_SHOT goblin %s" % monsters.summon(MonsterRules.GOBLIN, 3, Vector3(o) + Vector3(1.5, 0.0, 1.0)))
	var goblin: Monster = null
	for m: Monster in monsters.monsters():
		if not before.has(m):
			goblin = m
	if goblin == null:
		print("STORE_SHOT no goblin came")
		return
	goblin.global_position = Vector3(o) + Vector3(0.5, 0.0, 1.5)
	goblin.velocity = Vector3.ZERO
	goblin.rotation.y = PI   # facing +Z: the barrel
	var peek := Vector3(barrel) + Vector3(0.5, 0.9, 0.5)
	for i in 28:
		_shoo_animals(Vector3(o), 60.0)
		_clear()
		var d: Vector3 = goblin.global_position - peek if is_instance_valid(goblin) else Vector3(0, 0, -4)
		var yaw := clampf(atan2(-d.x, -d.z), -0.6, 0.6) * 0.7   # towards it, the house staying in the picture
		if i % 4 == 0:
			print("STORE_SHOT goblin at %s from the barrel" % [d])
		_view(yaw, -0.06)
		await _secs(0.12 if i < 12 else 0.3)
		await _save("hide_%02d" % i)

# --- 7: racing a bot friend on a built course -----------------------------------------------------------------

## A lane of Game Blocks runs along -Z from START (o + (0, -1, 12)) to a FINISH line (z -13); the child runs it
## once (the course's best run, which a bot friend races), a bot friend joins and is asked to race (the FRIENDS
## page's RACE ME!), and the child runs again from START, veering off the recorded line at first, so the two run side
## by side over the hurdle, the race clock counting.
func _shot_race() -> void:
	await _start(1, MEADOWS_SEED)
	var o := await _stage(60, 15)   # none this big and flat within 1200 blocks: the spawn's own meadow, levelled
	_course(o)
	await _secs(1.0)
	var start := Vector3(o) + Vector3(0.5, 0.0, 12.5)
	await _stand(start)
	_view(PI, -0.25)
	await _secs(0.8)
	await _run_course(PI, 9.0)
	await _secs(1.5)
	var friends: BotDirector = sb.get("_bot_director")
	var bot := friends.add(BotRules.EXPLORER)
	await _secs(1.0)
	print("STORE_SHOT race %s" % friends.race(bot.bot_name))
	await _secs(3.0)
	await _stand(start)
	var yaw := PI + 0.45
	_view(yaw, -0.2)
	await _secs(0.8)
	_clear()
	var dir := _run_input(yaw, Vector3(-0.35, 0.0, -1.0).normalized())
	_press(dir)
	await _secs(1.2)
	_press(_run_input(yaw, Vector3(0.0, 0.0, -1.0)))
	for i in 20:
		_clear()
		await _secs(0.15)
		await _save("race_%02d" % i)
	_press(Vector2.ZERO)


## Runs the course (towards -Z) for `seconds`, the camera turned to `yaw`.
func _run_course(yaw: float, seconds: float) -> void:
	_view(yaw, -0.25)
	_press(_run_input(yaw, Vector3(0.0, 0.0, -1.0)))
	await _secs(seconds)
	_press(Vector2.ZERO)


## The stick's (x, y) that moves the body along `world_dir` for a camera turned to `yaw` (Player: the body moves along
## Basis(UP, yaw) * (x, 0, y)).
func _run_input(yaw: float, world_dir: Vector3) -> Vector2:
	var local := Basis(Vector3.UP, -yaw) * world_dir
	return Vector2(local.x, local.z)


func _press(v: Vector2) -> void:
	for a: StringName in [&"move_left", &"move_right", &"move_forward", &"move_back"]:
		Input.action_release(a)
	if v.x < 0.0:
		Input.action_press(&"move_left", -v.x)
	elif v.x > 0.0:
		Input.action_press(&"move_right", v.x)
	if v.y < 0.0:
		Input.action_press(&"move_forward", -v.y)
	elif v.y > 0.0:
		Input.action_press(&"move_back", v.y)


func _course(o: Vector3i) -> void:
	w.set_block(o + Vector3i(0, -1, 12), BlockIds.START)
	for x in range(-2, 3):
		w.set_block(o + Vector3i(x, 0, 6), BlockIds.PAINTED_YELLOW if x % 2 == 0 else BlockIds.PAINTED_RED)
		w.set_block(o + Vector3i(x, -1, 2), BlockIds.BOUNCE)
		w.set_block(o + Vector3i(x, -1, -6), BlockIds.CHECKPOINT)
		w.set_block(o + Vector3i(x, -1, -13), BlockIds.FINISH)
	for z: int in [9, 8, -9, -10]:
		for x: int in [-1, 0]:
			w.set_block(o + Vector3i(x, 0, z), BlockIds.COIN)
	for z in range(-14, 14):
		for x: int in [-4, 4]:
			w.set_block(o + Vector3i(x, 0, z), BlockIds.PAINTED_TEAL if posmod(z, 4) < 2 else BlockIds.PAINTED_ORANGE)

# --- 8: the Secret Book ---------------------------------------------------------------------------------------

## A few secrets found (the host's own "found" path) and animals met (summoned next to the child: met within a
## second); the book opens on SECRETS, then on ANIMALS.
func _shot_book() -> void:
	await _start(1, MEADOWS_SEED)
	var o := await _stage(60, 7)
	await _stand(Vector3(o) + Vector3(0.5, 0.0, 0.5))
	var secrets: SecretDirector = sb.get_node("Secrets")
	var seen := {}
	for s: Dictionary in secrets.rules.secrets_near(p.global_position, 900.0):
		if seen.size() >= 4 or seen.has(s.kind) or not [SecretRules.TREASURE, SecretRules.ROOM, SecretRules.TEMPLE,
				SecretRules.GEODE, SecretRules.ISLAND].has(s.kind):
			continue
		seen[s.kind] = true
		secrets._mark_found(s, p.peer_id)
		await _secs(0.3)
	print("STORE_SHOT book found %s" % [seen.keys()])
	for species: StringName in [&"horse", &"duck", &"owl", &"sheep", &"pig", &"cow", &"rabbit", &"cat", &"fox", &"dog",
			&"frog", &"turtle", &"squirrel", &"hedgehog", &"deer"]:
		_summon_animal(species)
		await _secs(0.3)
	await _secs(6.0)
	_clear()
	hud.secret_book.open()
	await _secs(1.0)
	await _save("book_0")
	hud.secret_book.show_tab(SecretBook.ANIMALS_TAB)
	await _secs(1.0)
	await _save("book_1")

# --- The feature graphic's photo ------------------------------------------------------------------------------

## A buddy waking in front of a castle (two /build towers and a battlemented stone wall between them) at sunset;
## photo mode (the world pauses and the HUD hides), its orbit camera turned, pulled back and panned as its gestures
## allow. The camera looks +Z: the castle, the buddy and the child on the right half (-X), the trees on the left (+X)
## side cleared far out, so the wordmark lies on open sunset sky.
func _shot_feature() -> void:
	await _start(1, MEADOWS_SEED)
	var o := await _stage(60, 16, 2)   # 2 steps: no flatter meadow this big within 1200 blocks
	for k in 2:
		await _stand(Vector3(o) + Vector3(-2.5 - k * 9, 0.0, 2.5))
		_view(PI, -0.1)   # looking +Z: the tower rises 2 blocks ahead (z +4 .. +8), 5 wide
		await _secs(0.3)
		_cmd("/build tower")
		await _secs(3.0)
	# the wall between the towers (x -9 .. -6), 8 high, 2 thick, with battlements
	for x in range(-9, -5):
		for z in range(5, 7):
			for y in 8:
				w.set_block(o + Vector3i(x, y, z), BlockIds.STONE)
		if x % 2 == 0:
			w.set_block(o + Vector3i(x, 8, 5), BlockIds.STONE)
	_clear_plants(w.generator_shape(), Vector2i(o.x + 30, o.z + 20), 30)
	var b := o + Vector3i(-4, 0, -1)   # its middle o + (-3.5, 0, 0), 4 blocks in front of the wall, facing -Z
	_build(b, _small_buddy())
	await _stand(Vector3(b) + Vector3(-1.9, 0.0, -1.1))   # on its right (-X), 3.2 from its middle
	_cmd("/give wand")
	_cmd("/peace on")   # the dusk's wild slimes go home and stay away
	_cmd("/time sunset")
	await _secs(2.0)
	var wanderer := (sb.get_node("Secrets") as SecretDirector).wanderer()
	if wanderer:
		wanderer.queue_free()   # the Wanderer walks up at dusk: not in this picture
	_shoo_animals(Vector3(o), 60.0)
	_clear()
	_face(-0.52)
	await _secs(0.3)
	Session.request_spark(b + Vector3i(0, 2, 0))
	await _secs(1.25)   # after its first blink (0.92-1.12 s): eyes open, the stars still round it
	var photo: PhotoMode = sb.get("photo")
	photo.open()
	photo.controls.visible = false   # the shutter hides them the same way for the picture it takes
	var i := 0
	# [yaw, pitch, distance, pan]: the pan (at most PhotoOrbit.MAX_PAN = 6 blocks, as two fingers allow) moves the look
	# point towards +X, so the buddy stands right of the middle (a play button may lie over the feature graphic's middle)
	for v: Array in [[PI + 0.5, 0.26, 9.5, Vector3(4.6, 3.0, 0.0)], [PI + 0.5, 0.3, 9.5, Vector3(5.6, 2.1, 0.0)],
			[PI + 0.5, 0.36, 9.5, Vector3(5.6, 2.1, 0.0)], [PI + 0.55, 0.33, 9.0, Vector3(5.7, 1.8, 0.0)]]:
		photo.orbit.yaw = v[0]
		photo.orbit.pitch = v[1]
		photo.orbit.distance = v[2]
		photo.orbit.pan = v[3]
		photo._place_camera()
		await _secs(0.3)
		await _save("feature_%d" % i)
		i += 1
	photo.close()

# --- Probes: the other universes' spawns, to pick the spots ---------------------------------------------------

func _shot_probe_candy() -> void:
	await _start(4, CANDY_SEED)
	await _probe("probe_candy")


func _shot_probe_dragon() -> void:
	await _start(5, DRAGON_SEED)
	await _probe("probe_dragon")


func _probe(tag: String) -> void:
	for i in 4:
		_view(i * PI * 0.5, -0.15)
		await _secs(1.0)
		await _save("%s_%d" % [tag, i])

# --- Worlds, places and the camera ----------------------------------------------------------------------------

## A new Sandbox world of universe u; returns once the child stands in it, the terrain is meshed and the start's
## tip has gone. The day clock is stopped at a bright morning.
func _start(u: int, seed: int) -> void:
	if get_tree().current_scene and get_tree().current_scene.get("player") != null:
		Session.close()
	Game.new_world_seed = seed
	Game.start_world(ModeRules.SANDBOX, true, DifficultyRules.NORMAL, u)
	await get_tree().process_frame
	while true:
		sb = get_tree().current_scene
		if sb != null and sb.get("player") != null and (sb.player as Player).is_spawned():
			break
		await get_tree().process_frame
	p = sb.player
	w = p.world
	hud = sb.hud
	runner = sb.get_node("ChatCommands") as ChatCommandRunner
	w.apply_style("blocky")
	await _ready_at(p.global_position)
	_cmd("/time day")
	_cmd("/freeze on")
	await _secs(5.5)
	print("STORE_SHOT world u=%d seed=%d spawn %s" % [u, seed, p.global_position])


## Waits until the terrain round `at` is meshed (at most 20 s), then a little more.
func _ready_at(at: Vector3) -> void:
	var t := 0.0
	while t < 20.0 and not (w.is_area_ready(at) and w.is_editable(Vector3i(at.floor()))):
		t += await _frame()
	await _secs(1.0)


## A flat meadow at least `min_r` blocks from the spawn, levelled `half` blocks round its middle, with the child
## on it: returns the middle's feet cell (the ground is one lower).
func _stage(min_r: int, half: int, steps := 1) -> Vector3i:
	var shape := w.generator_shape() as MeadowsBiomeShape
	var c := _flat_meadow(shape, w.spawn_column(), min_r, half + 2, steps)
	p.spawn_on_surface(c.x, c.y)
	while not p.is_spawned():
		await get_tree().process_frame
	await _ready_at(p.global_position)
	var o := Vector3i(c.x, shape.height_at(c.x, c.y), c.y)   # height_at: the first free cell over the ground
	_level(o, half, BlockIds.GRASS, BlockIds.DIRT)
	_shoo_animals(Vector3(o), half + 12.0)
	await _secs(0.8)
	await _stand(Vector3(o) + Vector3(0.5, 0.0, 0.5))
	print("STORE_SHOT stage %s (%s)" % [o, MeadowsBiomeShape.BIOME_NAMES[shape.column(c.x, c.y).y]])
	return o


## The nearest column (rings round `home`) whose square of `r` is one meadow or flower field within `steps` blocks
## of its middle's height, far from the Theater.
func _flat_meadow(shape: MeadowsBiomeShape, home: Vector2i, min_r: int, r: int, steps := 1) -> Vector2i:
	var theater := _theater()
	for ring in range(min_r, 1200, 8):
		for a in 24:
			var q := home + Vector2i(roundi(cos(TAU * a / 24.0) * ring), roundi(sin(TAU * a / 24.0) * ring))
			if theater.is_finite() and Vector2(q).distance_to(Vector2(theater.x, theater.z)) < 70.0:
				continue
			if _flat_at(shape, q, r, steps):
				return q
	print("STORE_SHOT no flat meadow")
	return home


## Any universe: the nearest dry column (rings round `home`, at least `min_r` out, far from the Theater) whose square
## of `r` lies within one block of its height.
func _flat_any(shape: MeadowsShape, home: Vector2i, min_r: int, r: int) -> Vector2i:
	var theater := _theater()
	for ring in range(min_r, 1200, 6):
		for a in 24:
			var q := home + Vector2i(roundi(cos(TAU * a / 24.0) * ring), roundi(sin(TAU * a / 24.0) * ring))
			if theater.is_finite() and Vector2(q).distance_to(Vector2(theater.x, theater.z)) < 70.0:
				continue
			var h := shape.height_at(q.x, q.y)
			if h <= MeadowsShape.SEA_LEVEL + 1:
				continue
			var ok := true
			for dx in range(-r, r + 1, 2):
				for dz in range(-r, r + 1, 2):
					if absi(shape.height_at(q.x + dx, q.y + dz) - h) > 1 or shape.is_river(q.x + dx, q.y + dz):
						ok = false
			if ok:
				return q
	print("STORE_SHOT no flat ground")
	return home


## Where the Shorts Theater's building stands in this world (INF when it has none): never in a picture.
func _theater() -> Vector3:
	var t := sb.get_node_or_null("Theater")
	var b: Variant = t.get("building") if t else null
	return (b as Node3D).global_position if b is Node3D and is_instance_valid(b) else Vector3.INF


## Whether the square of `r` round `q` is dry meadow or flower field, within `steps` blocks of its middle's height.
func _flat_at(shape: MeadowsBiomeShape, q: Vector2i, r: int, steps := 1) -> bool:
	var h := shape.height_at(q.x, q.y)
	if h <= MeadowsShape.SEA_LEVEL + 1:
		return false
	for dx in range(-r, r + 1, 2):
		for dz in range(-r, r + 1, 2):
			var col := shape.column(q.x + dx, q.y + dz)
			if col.y != MeadowsBiomeShape.MEADOW and col.y != MeadowsBiomeShape.FLOWERS:
				return false
			if absi(col.x - h) > steps or shape.is_river(q.x + dx, q.y + dz):
				return false
	return true


## `top` at the feet's level - 1 over `below`, and air above (14 high), in a square of `half` round `o` (trees and
## flowers there go).
func _level(o: Vector3i, half: int, top: int, below: int) -> void:
	for x in range(-half, half + 1):
		for z in range(-half, half + 1):
			var c := o + Vector3i(x, 0, z)
			w.set_block(c + Vector3i(0, -3, 0), below)
			w.set_block(c + Vector3i(0, -2, 0), below)
			w.set_block(c + Vector3i(0, -1, 0), top)
			for y in 14:
				w.set_block(c + Vector3i(0, y, 0), BlockIds.AIR)


## The trees and plants (PLANTS) over the generated ground go, in a square of `half` round column `c`; the ground,
## builds and void columns stay.
func _clear_plants(shape: MeadowsShape, c: Vector2i, half: int) -> void:
	for x in range(-half, half + 1):
		for z in range(-half, half + 1):
			var h := shape.height_at(c.x + x, c.y + z)
			if h <= MeadowsShape.SEA_LEVEL + 1:
				continue
			for y in range(h - 1, h + 22):
				var cell := Vector3i(c.x + x, y, c.y + z)
				if PLANTS.has(w.get_block(cell)):
					w.set_block(cell, BlockIds.AIR)


## Puts blocks [[x, y, z, id], ...] relative to `o` (the host's edits, as a child's placing ends up).
func _build(o: Vector3i, blocks: Array) -> void:
	for b: Array in blocks:
		w.set_block(o + Vector3i(b[0], b[1], b[2]), b[3])


## A portal frame round a doorway `width` wide (along X) and `height` high whose lowest left cell is `lo`: frames
## all round (corners too), the doorway and the cells in front of and behind it open, the core's cell left open.
func _portal_frame(lo: Vector3i, width: int, height: int) -> void:
	for dx in range(-1, width + 1):
		for dy in range(-1, height + 1):
			var c := lo + Vector3i(dx, dy, 0)
			var inside := dx >= 0 and dx < width and dy >= 0 and dy < height
			var core := dx == 0 and dy == -1
			w.set_block(c, BlockIds.AIR if inside or core else BlockIds.PORTAL_FRAME)
	for dx in width:
		for dz: int in [-1, 1]:
			for dy in height:
				w.set_block(lo + Vector3i(dx, dy, dz), BlockIds.AIR)


## The child goes to column `col` (standing on its surface) and waits for the terrain there.
func _go(col: Vector2i) -> void:
	p.spawn_on_surface(col.x, col.y)
	while not p.is_spawned():
		await get_tree().process_frame
	await _ready_at(p.global_position)


## The wild animals within `radius` of `at` go (a picture's own animals are summoned after): none wanders into it.
func _shoo_animals(at: Vector3, radius: float) -> void:
	for a: Animal in sb.call(&"_animal_nodes"):
		if a.owner_peer == 0 and Vector2(a.global_position.x - at.x, a.global_position.z - at.z).length() < radius:
			a.queue_free()


## An animal summoned next to the child through the sandbox's /summon hook; null when none came.
func _summon_animal(species: StringName) -> Animal:
	var before := {}
	for a: Animal in sb.call(&"_animal_nodes"):
		before[a] = true
	var said: String = sb.call(&"summon_animal", species, p.global_position)
	for a: Animal in sb.call(&"_animal_nodes"):
		if not before.has(a) and a.species == species:
			return a
	print("STORE_SHOT no %s came (%s)" % [species, said])
	return null


## The child stands at `at` (feet), still.
func _stand(at: Vector3) -> void:
	p.global_position = at
	p.velocity = Vector3.ZERO
	await _secs(0.4)
	p.global_position = Vector3(at.x, p.global_position.y, at.z)
	p.velocity = Vector3.ZERO


## The game camera: yaw 0 looks towards -Z, PI towards +Z; pitch below 0 looks down.
func _view(yaw: float, pitch: float) -> void:
	p.rig.yaw = yaw
	p.rig.pitch = clampf(pitch, CameraRig.PITCH_MIN, CameraRig.PITCH_MAX)


## The child's body turned to `yaw` (0 faces -Z).
func _face(yaw: float) -> void:
	p.avatar.rotation.y = yaw


func _cmd(text: String) -> void:
	runner.run(text)


## The chat's lines (the commands' answers) off the screen.
func _clear() -> void:
	hud.chat.clear_history()

# --- Builds ---------------------------------------------------------------------------------------------------

## A small buddy, 4 tall and 5 wide with its arms, 2 deep: teal legs and arms, an orange body, a yellow head with a
## pink nose (its eyes come on the head's front, -Z).
func _small_buddy() -> Array:
	var out: Array = []
	for z in 2:
		for x: int in [-1, 1]:
			out.append([x, 0, z, BlockIds.PAINTED_TEAL])
		for y: int in [1, 2]:
			for x in range(-1, 2):
				out.append([x, y, z, BlockIds.PAINTED_ORANGE])
		for x in range(-1, 2):
			out.append([x, 3, z, BlockIds.PAINTED_PINK if x == 0 and z == 0 else BlockIds.PAINTED_YELLOW])
	for x: int in [-2, 2]:
		out.append([x, 2, 0, BlockIds.PAINTED_TEAL])
	return out


## A giant buddy, 6 tall and 7 wide, 1 deep: teal legs and arms, an orange body, a yellow head 5 wide with a pink
## nose.
func _giant_buddy() -> Array:
	var out: Array = []
	for y in 2:
		for x: int in [-2, -1, 1, 2]:
			out.append([x, y, 0, BlockIds.PAINTED_TEAL])
	for y in range(2, 4):
		for x in range(-2, 3):
			out.append([x, y, 0, BlockIds.PAINTED_ORANGE])
		for x: int in [-3, 3]:
			out.append([x, y, 0, BlockIds.PAINTED_TEAL])
	for y in range(4, 6):
		for x in range(-2, 3):
			out.append([x, y, 0, BlockIds.PAINTED_PINK if x == 0 and y == 4 else BlockIds.PAINTED_YELLOW])
	return out

# --- Time and pictures ----------------------------------------------------------------------------------------

func _frame() -> float:
	await get_tree().process_frame
	return get_process_delta_time()


func _secs(s: float) -> void:
	await get_tree().create_timer(s, true, false, true).timeout


## The screen as it is drawn now: 1920 x 1080 RGB, quality 0.92.
func _save(shot: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.convert(Image.FORMAT_RGB8)
	if img.get_size() != SIZE:
		print("STORE_SHOT resized from %s" % img.get_size())
		img.resize(SIZE.x, SIZE.y, Image.INTERPOLATE_LANCZOS)
	var path := _out.path_join(shot + ".jpg")
	img.save_jpg(path, QUALITY)
	print("STORE_SHOT %s %s" % [shot, path])
