class_name CombatDirector
extends Node
## Weapons in a world (M1b Task 11). The sandbox adds one on every peer, always named "Combat",
## so its spawners and RPCs line up across the network.
## Host: resolves the attacks Session has checked (weapon, cooldown) with the host's own positions:
## melee hits within the weapon's reach, and the arrows and boomerangs it flies and checks. It also
## places, removes and saves the practice targets.
## Every peer: plays other players' attack animations and the hit effects.
## Practice dummies (floating numbers) and monsters (M2 Task 4: take_hit) take damage. Players are
## pushed by their own game (Session.send_knockback) and buddies cheer; neither is ever hurt by a weapon.
## Owner feedback #26 (it overrules M1b's "animals are only pushed"): animals take damage too (their
## take_hit; pets and golden ones are only pushed), and a defeated one puffs away in the monsters'
## cartoon cloud and leaves its defeater a little in Survivor (AnimalRules.drops; animal_defeated).
## M2 Task 6: tier weapons (the tier's damage; a tier bow's arrows too), the spear's thrust and its
## throw (a ThrownSpear the thrower walks up to take back), and the mace's ground shake.

## Host: an animal was defeated (owner feedback #26); by_peer: who did it (0: nobody known). The sandbox
## tells the AnimalDirector, whose herd then refills slowly.
signal animal_defeated(animal_id: String, species: StringName, pos: Vector3, by_peer: int)

const MAX_PROJECTILES := 24
const ANIMAL_RADIUS := 0.5
const ANIMAL_CENTER := 0.4
const PLAYER_RADIUS := 0.4
const MONSTER_RADIUS := 0.5       # a monster without hit_radius()
const MONSTER_CENTER := 0.5
const SUPPORT_CHECK := 1.0     # seconds between checks that the targets still stand on something

## block_at(pos: Vector3i) -> int: the host's world (tests replace it).
var block_at: Callable = _world_block

var _targets := Node3D.new()
var _target_spawner := MultiplayerSpawner.new()
var _projectiles := Node3D.new()
var _projectile_spawner := MultiplayerSpawner.new()
var _next_id := 1
var _combos := {}              # peer id -> [sword combo step, msec of that swing]
var _support_timer := 0.0


func _ready() -> void:
	_targets.name = "Targets"
	add_child(_targets)
	_target_spawner.name = "TargetSpawner"
	add_child(_target_spawner)
	_target_spawner.spawn_path = _target_spawner.get_path_to(_targets)
	_target_spawner.spawn_function = _make_target
	_projectiles.name = "Projectiles"
	add_child(_projectiles)
	_projectile_spawner.name = "ProjectileSpawner"
	add_child(_projectile_spawner)
	_projectile_spawner.spawn_path = _projectile_spawner.get_path_to(_projectiles)
	_projectile_spawner.spawn_function = _make_projectile
	Session.attack_requested.connect(_on_attack)
	Session.target_requested.connect(_on_target_requested)
	Session.target_removal_requested.connect(_on_target_removal)
	Session.knocked_back.connect(_on_knocked_back)
	Session.spear_throw_requested.connect(_on_spear_throw)   # M2 Task 6


func _world_block(pos: Vector3i) -> int:
	return Session.world.get_block(pos) if Session.world else BlockIds.AIR


func _is_solid(cell: Vector3i) -> bool:
	return BlockIds.is_solid(block_at.call(cell))


## The middle of a player's body, where swings start and hits land.
static func chest(p: Player) -> Vector3:
	return p.global_position + Vector3(0, 1.0 * p.size_scale(), 0)


## Everything a weapon can hit: [{node, pos, radius, kind}] (targets, animals, buddies, players,
## monsters), without `exclude` (the attacker).
static func hittables(tree: SceneTree, exclude: Node = null) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for n in tree.get_nodes_in_group(&"targets"):
		var t := n as PracticeTarget
		if t and not t.is_queued_for_deletion():
			out.append({"node": t, "pos": t.center(), "radius": t.radius(), "kind": t.kind()})
	for n in tree.get_nodes_in_group(&"animals"):
		var a := n as Node3D
		if a and a != exclude and not a.is_queued_for_deletion():
			out.append({"node": a, "pos": a.global_position + Vector3(0, ANIMAL_CENTER, 0), "radius": ANIMAL_RADIUS, "kind": WeaponRules.ANIMAL})
	for n in tree.get_nodes_in_group(&"buddies"):
		var b := n as Buddy
		if b and not b.is_queued_for_deletion():
			var s := Vector3(b.size_blocks)
			out.append({"node": b, "pos": b.global_position + Vector3(0, s.y * 0.5, 0),
				"radius": clampf(maxf(s.x, s.z) * 0.5, 0.4, 1.2), "kind": WeaponRules.BUDDY})
	for n in tree.get_nodes_in_group(&"players"):
		var p := n as Player
		if p and p != exclude and p.is_spawned():
			out.append({"node": p, "pos": chest(p), "radius": PLAYER_RADIUS * p.size_scale(), "kind": WeaponRules.PLAYER})
	_add_monsters(tree, out)
	return out


## M2 Task 4: anything in the group "monsters" with take_hit(damage, from, knockback); where it is hit
## and how big it is come from its hit_center() / hit_radius() when it has them.
static func _add_monsters(tree: SceneTree, out: Array[Dictionary]) -> void:
	for n in tree.get_nodes_in_group(&"monsters"):
		var m := n as Node3D
		if m == null or m.is_queued_for_deletion() or not m.has_method(&"take_hit"):
			continue
		var pos: Vector3 = m.call(&"hit_center") if m.has_method(&"hit_center") else m.global_position + Vector3(0, MONSTER_CENTER, 0)
		var radius: float = m.call(&"hit_radius") if m.has_method(&"hit_radius") else MONSTER_RADIUS
		out.append({"node": m, "pos": pos, "radius": radius, "kind": WeaponRules.MONSTER})


# --- Attacks (host) ---------------------------------------------------------------------------

func _on_attack(peer_id: int, weapon_id: int, dir: Vector3, power: float) -> void:
	var attacker := Session._player_for_peer(peer_id)
	if attacker == null or not attacker.is_spawned():
		return
	var w := WeaponRules.stats(weapon_id)
	var base := WeaponRules.base_of(weapon_id)
	if base == ItemIds.SPEAR and spear_of(peer_id) != null:
		return                                        # its spear is out there: the hand is empty
	var combo := _next_combo(peer_id, weapon_id)
	match w.kind:
		WeaponRules.MELEE:
			resolve_melee(chest(attacker), dir, weapon_id, combo, attacker)
			if base == ItemIds.MACE:
				_rpc_ground_shake.rpc(WeaponRules.mace_impact(chest(attacker), dir))
		WeaponRules.BOW:
			var from := Session.shot_origin(attacker)   # owner #124: a VR player's bow, else the eye
			var start := from + dir * (0.5 if from == attacker.eye_position() else 0.1)
			spawn_arrow(start, WeaponRules.arrow_velocity(dir, power), peer_id, power, weapon_id)
		WeaponRules.BOOMERANG:
			if boomerang_of(peer_id) != null:
				return
			var from := Session.shot_origin(attacker)   # owner #124: a VR player's hand, else below the eye
			var start := (from + Vector3(0, -0.3, 0) + dir * 0.6) if from == attacker.eye_position() else from + dir * 0.15
			spawn_boomerang(start, dir, peer_id)
	_rpc_attack_fx.rpc(peer_id, weapon_id, combo)


func _next_combo(peer_id: int, weapon_id: int) -> int:
	var now := Time.get_ticks_msec()
	var last: Array = _combos.get(peer_id, [0, -100000])
	var combo := WeaponRules.combo_next(weapon_id, int(last[0]), (now - int(last[1])) / 1000.0)
	_combos[peer_id] = [combo, now]
	return combo


## Host: one swing from `origin` along `dir`; returns what it hit ([{node, pos, radius, kind}]).
## Every hit is within the weapon's reach of the host's own position of the attacker and in sight
## of it. Things behind a wall are left out before the swing picks its targets, so they neither
## take a hit nor pull the aim away from a target in the open (review M10).
func resolve_melee(origin: Vector3, dir: Vector3, weapon_id: int, combo: int = 0, attacker: Node = null) -> Array:
	var things: Array[Dictionary] = []
	for thing in hittables(get_tree(), attacker):
		if WeaponRules.hit_in_reach(origin, thing.pos, weapon_id, thing.radius) and in_sight(origin, thing.pos):
			things.append(thing)
	var hits: Array = []
	for i: int in WeaponRules.melee_hits(origin, dir, things, weapon_id, combo):
		var thing: Dictionary = things[i]
		apply_hit(thing, origin, weapon_id, combo, 1.0, thing.pos, _peer_of(attacker))
		hits.append(thing)
	return hits


static func _peer_of(attacker: Node) -> int:
	return (attacker as Player).peer_id if attacker is Player else 0


## Host: can a swing from `from` reach `to`? Not through a solid block; water and air never block,
## and neither do the cells the swing starts and ends in (review M10).
func in_sight(from: Vector3, to: Vector3) -> bool:
	var dist := from.distance_to(to)
	if dist < 0.001:
		return true
	var hit := GridRay.cast(from, to - from, dist, _is_solid)
	return hit == null or hit.position == Vector3i(to.floor())


## Host: what one hit does. Dummies show the damage and monsters take it (with the push); animals take
## it too (owner feedback #26), players are pushed back and buddies cheer. by_peer: the attacker's
## peer (for an animal's drops), 0 when unknown.
func apply_hit(thing: Dictionary, from: Vector3, weapon_id: int, combo: int, power: float, point: Vector3,
		by_peer: int = 0) -> void:
	var node: Node = thing.node
	var kind: StringName = thing.kind
	if node is PracticeTarget:
		(node as PracticeTarget).show_hit.rpc(WeaponRules.damage_to(kind, weapon_id, combo, power), from)
		return
	var push := WeaponRules.knockback(from, thing.pos, weapon_id, combo)
	if kind == WeaponRules.ANIMAL and node.has_method(&"take_hit"):
		if node.call(&"take_hit", WeaponRules.damage_to(kind, weapon_id, combo, power), from, push):
			_animal_defeated(node, thing.pos, by_peer)
	elif kind == WeaponRules.ANIMAL and node.has_method(&"knockback"):
		node.call(&"knockback", push)
	elif kind == WeaponRules.MONSTER:
		node.call(&"take_hit", WeaponRules.damage_to(kind, weapon_id, combo, power), from, push)
	elif kind == WeaponRules.PLAYER:
		Session.send_knockback((node as Player).peer_id, push)
	_rpc_hit_fx.rpc(point, weapon_id, node.get_path() if kind == WeaponRules.BUDDY else NodePath())


## Host -> everyone: a player attacked (the attacker's own game has already animated it).
@rpc("authority", "call_local", "unreliable")
func _rpc_attack_fx(peer_id: int, weapon_id: int, combo: int) -> void:
	if peer_id == multiplayer.get_unique_id():
		return
	var p := Session._player_for_peer(peer_id)
	if p:
		p.play_attack(weapon_id, combo)
		Audio.play(WeaponRules.stats(weapon_id).get("sound", &""), p.global_position)


@rpc("authority", "call_local", "unreliable")
func _rpc_hit_fx(point: Vector3, weapon_id: int, buddy_path: NodePath) -> void:
	Fx.burst(get_tree().root, point, _hit_color(weapon_id), 10, 3.5, 0.1, 0.45, 6.0)
	Audio.play(&"hit", point, -3.0)
	if not buddy_path.is_empty():
		var b := get_node_or_null(buddy_path) as Buddy
		if b:
			b.cheer()


## Host: an animal was defeated: a cartoon cloud for everyone (the monsters' puff; never blood), the
## herd's refill (animal_defeated), and in Survivor a little for its defeater's bag (AnimalRules.drops).
func _animal_defeated(animal: Node, at: Vector3, by_peer: int) -> void:
	var species := StringName(str(animal.get(&"species")))
	_rpc_animal_puff.rpc(at)
	animal_defeated.emit(str(animal.get(&"animal_id")), species, at, by_peer)
	if Game.mode != ModeRules.SURVIVOR or by_peer == 0:
		return
	var items := AnimalRules.drops(species, str(animal.get(&"animal_id")))
	if items.is_empty():
		return
	var inv := Session.inventory_of(by_peer)
	for e: Array in items:
		inv.add(int(e[0]), int(e[1]))
	Session.send_feedback(by_peer, AnimalRules.drop_text(items))


## Host -> everyone: an animal puffs away (the monsters' shared cloud, MonsterDirector's BURST_PUFF).
@rpc("authority", "call_local", "unreliable")
func _rpc_animal_puff(pos: Vector3) -> void:
	Fx.burst(get_tree().root, pos, MonsterDirector.PUFF_COLOR, 18, 2.2, 0.22, 0.8, -1.5)
	Audio.play(&"poof", pos, -4.0)


static func _hit_color(weapon_id: int) -> Color:
	match WeaponRules.base_of(weapon_id):
		ItemIds.HAMMER:
			return Color("b89a7c")
		ItemIds.BOOMERANG:
			return Color("f08a1c")
		ItemIds.BOW:
			return Color("f3efe6")
	return Color("fff7c2")


func _on_knocked_back(impulse: Vector3) -> void:
	var me := Session._player_for_peer(multiplayer.get_unique_id())
	if me:
		me.knockback(impulse)


# --- Arrows and boomerangs --------------------------------------------------------------------

func projectiles() -> Array[Node]:
	var list: Array[Node] = []
	for n in _projectiles.get_children():
		if not n.is_queued_for_deletion():
			list.append(n)
	return list


## Host: shoots an arrow for everyone (weapon_id: the bow, for a tier's damage).
func spawn_arrow(origin: Vector3, velocity: Vector3, shooter: int, power: float, weapon_id: int = ItemIds.BOW) -> Arrow:
	_make_room()
	var data := {"kind": "arrow", "id": "Arrow%d" % _next_id, "origin": origin, "velocity": velocity,
		"shooter": shooter, "power": power, "weapon": weapon_id}
	_next_id += 1
	return _projectile_spawner.spawn(data) as Arrow


## Host: throws a boomerang for everyone.
func spawn_boomerang(origin: Vector3, dir: Vector3, shooter: int) -> Boomerang:
	_make_room()
	var data := {"kind": "boomerang", "id": "Boomerang%d" % _next_id, "origin": origin, "dir": dir, "shooter": shooter}
	_next_id += 1
	return _projectile_spawner.spawn(data) as Boomerang


func boomerang_of(peer_id: int) -> Boomerang:
	for n in projectiles():
		if n is Boomerang and (n as Boomerang).shooter == peer_id:
			return n
	return null


## At most MAX_PROJECTILES: the oldest arrows go first.
func _make_room() -> void:
	var list := projectiles()
	if list.size() >= MAX_PROJECTILES:
		for n in list:
			if n is Arrow:
				n.queue_free()
				return


func _make_projectile(data: Variant) -> Node:
	var d: Dictionary = data
	if d.kind == "spear":
		return _make_spear(d)
	if d.kind == "boomerang":
		var b := Boomerang.new()
		b.setup(d)
		b.is_solid = _is_solid
		if multiplayer.is_server():
			b.hit_check = _boomerang_hits
		return b
	var a := Arrow.new()
	a.setup(d)
	a.is_solid = _is_solid
	if multiplayer.is_server():
		a.hit_check = _arrow_hits
	return a


## Host: did the arrow hit something between p0 and p1? The bullseye scores its rings, a dummy
## takes the damage (the arrow sticks in both); monsters and animals take it too, buddies and players
## only get a bonk.
func _arrow_hits(arrow: Arrow, p0: Vector3, p1: Vector3) -> bool:
	var seg := p1 - p0
	var length := maxf(seg.length(), 0.0001)
	var best := {}
	var best_t := INF
	var best_point := Vector3.ZERO
	for thing in hittables(get_tree(), Session._player_for_peer(arrow.shooter)):
		var t := -1.0
		var point := Vector3.ZERO
		if thing.node is Bullseye:
			var b := thing.node as Bullseye
			point = WeaponRules.segment_hits_disc(p0, p1, b.center(), b.face_normal(), WeaponRules.BULLSEYE_RADIUS)
			t = (point - p0).length() / length if point.is_finite() else -1.0
		else:
			t = WeaponRules.segment_hits_sphere(p0, p1, thing.pos, thing.radius)
			point = p0 + seg * t
		if t >= 0.0 and t < best_t:
			best_t = t
			best = thing
			best_point = point
	if best.is_empty():
		return false
	var dir := seg / length
	if best.node is PracticeTarget:
		arrow.stick(best_point, dir)
		arrow.stick_at.rpc(best_point, dir)
		if best.node is Bullseye:
			var b := best.node as Bullseye
			b.show_score.rpc(WeaponRules.bullseye_score(best_point.distance_to(b.center()), WeaponRules.BULLSEYE_RADIUS), best_point)
		else:
			apply_hit(best, p0, arrow.weapon, 0, arrow.power, best_point, arrow.shooter)
	else:
		apply_hit(best, p0, arrow.weapon, 0, arrow.power, best_point, arrow.shooter)
		arrow.queue_free()
	return true


## Host: the boomerang hits each thing once per throw, up to its max_hits.
func _boomerang_hits(b: Boomerang, p0: Vector3, p1: Vector3) -> void:
	var max_hits := int(WeaponRules.stats(ItemIds.BOOMERANG).max_hits)
	for thing in hittables(get_tree(), Session._player_for_peer(b.shooter)):
		var id := (thing.node as Node).get_instance_id()
		if b.hit.size() >= max_hits or b.hit.has(id):
			continue
		var t := WeaponRules.segment_hits_sphere(p0, p1, thing.pos, float(thing.radius) + 0.3)
		if t >= 0.0:
			b.hit[id] = true
			apply_hit(thing, p0, ItemIds.BOOMERANG, 0, 1.0, p0.lerp(p1, t), b.shooter)


# --- Practice targets (host) ------------------------------------------------------------------

func targets() -> Array[PracticeTarget]:
	var list: Array[PracticeTarget] = []
	for n in _targets.get_children():
		if n is PracticeTarget and not n.is_queued_for_deletion():
			list.append(n)
	return list


## Host: puts a practice dummy or bullseye (item) down for everyone, its feet at pos.
func spawn_target(item_id: int, pos: Vector3, yaw: float) -> PracticeTarget:
	if not is_finite(yaw):
		yaw = 0.0   # the yaw arrives over LAN; a NaN would reach the save
	var data := {"item": item_id, "pos": pos, "yaw": yaw, "id": "Target%d" % _next_id}
	_next_id += 1
	return _target_spawner.spawn(data) as PracticeTarget


func _make_target(data: Variant) -> Node:
	var t: PracticeTarget = Bullseye.new() if int(data.item) == ItemIds.BULLSEYE else PracticeDummy.new()
	t.setup(data)
	return t


## The targets for WorldMeta.targets.
func to_save() -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	for t in targets():
		list.append(t.to_save())
	return list


## Host: brings back the saved targets (WorldMeta.targets, already validated).
func restore(saved: Array[Dictionary]) -> void:
	for e in saved:
		spawn_target(int(e.item), Vector3(e.pos[0], e.pos[1], e.pos[2]), float(e.yaw))


## Host: may `peer_id` put a target (item) in `cell`? Returns "" or a friendly reason.
func check_target_spot(peer_id: int, item_id: int, cell: Vector3i) -> String:
	var requester := Session._player_for_peer(peer_id)
	if requester == null or not ItemIds.is_target(item_id):
		return "?"
	if not PlacementRules.in_reach(requester.eye_position(), cell, PlacementRules.REACH + PlacementRules.REACH_TOLERANCE):
		return "Too far away!"
	if targets().size() >= WeaponRules.MAX_TARGETS:
		return tr("That's %d targets! Hold one to take it away.") % WeaponRules.MAX_TARGETS
	if not WeaponRules.target_spot_ok(cell, block_at) or _target_near(cell):
		return "Targets need flat ground and room above."
	return ""


func _on_target_requested(peer_id: int, item_id: int, cell: Vector3i, yaw: float) -> void:
	var problem := check_target_spot(peer_id, item_id, cell)
	if problem == "":
		spawn_target(item_id, Vector3(cell) + Vector3(0.5, 0.0, 0.5), yaw)
		_rpc_poof.rpc(Vector3(cell) + Vector3(0.5, 0.2, 0.5), false)
	elif problem != "?":
		Session.send_feedback(peer_id, problem)


func _target_near(cell: Vector3i) -> bool:
	for t in targets():
		var c := t.cell()
		if c.x == cell.x and c.z == cell.z and absi(c.y - cell.y) <= 1:
			return true
	return false


func _on_target_removal(peer_id: int, target_name: String) -> void:
	var t := _targets.get_node_or_null(NodePath(target_name)) as PracticeTarget
	var requester := Session._player_for_peer(peer_id)
	if t == null or requester == null or t.is_queued_for_deletion():
		return
	if PlacementRules.in_reach(requester.eye_position(), t.cell(), PlacementRules.REACH + PlacementRules.REACH_TOLERANCE):
		_rpc_poof.rpc(t.center(), true)
		t.queue_free()


@rpc("authority", "call_local", "unreliable")
func _rpc_poof(pos: Vector3, removed: bool) -> void:
	Fx.burst(get_tree().root, pos, Color("e0c38c"), 16, 3.5, 0.12, 0.6, 8.0)
	Audio.play(&"break" if removed else &"place", pos)


## Host: a target whose ground was dug away pops (only where the terrain is loaded).
func _physics_process(delta: float) -> void:
	if not multiplayer.is_server() or Session.world == null:
		return
	_support_timer += delta
	if _support_timer < SUPPORT_CHECK:
		return
	_support_timer = 0.0
	for t in targets():
		var below := t.cell() + Vector3i.DOWN
		if Session.world.is_editable(below) and not _is_solid(below):
			_rpc_poof.rpc(t.center(), true)
			t.queue_free()


# --- M2 Task 6: the thrown spear and the mace's ground shake ------------------------------------

## The shake felt here most recently (tests and tuning read it).
var last_shake := 0.0
var _last_shake_ms := -100000


## Host: throws a spear (weapon: its tier) for everyone.
func spawn_spear(origin: Vector3, velocity: Vector3, shooter: int, weapon_id: int) -> ThrownSpear:
	_make_room()
	var data := {"kind": "spear", "id": "Spear%d" % _next_id, "origin": origin, "velocity": velocity,
		"shooter": shooter, "weapon": weapon_id}
	_next_id += 1
	return _projectile_spawner.spawn(data) as ThrownSpear


## The spear this player threw that is still out there, or null.
func spear_of(peer_id: int) -> ThrownSpear:
	for n in projectiles():
		if n is ThrownSpear and (n as ThrownSpear).shooter == peer_id:
			return n
	return null


## Host: a throw Session checked (a spear, a sane aim, the cooldown). One spear out per player.
func _on_spear_throw(peer_id: int, weapon_id: int, dir: Vector3) -> void:
	var attacker := Session._player_for_peer(peer_id)
	if attacker == null or not attacker.is_spawned() or spear_of(peer_id) != null:
		return
	spawn_spear(attacker.eye_position() + dir * 0.6, WeaponRules.spear_throw_velocity(dir), peer_id, weapon_id)
	_rpc_attack_fx.rpc(peer_id, weapon_id, WeaponRules.THROW)


func _make_spear(d: Dictionary) -> ThrownSpear:
	var spear := ThrownSpear.new()
	spear.setup(d)
	spear.is_solid = _is_solid
	if multiplayer.is_server():
		spear.hit_check = _spear_hits
		spear.returned.connect(_on_spear_returned.bind(spear.shooter))
	return spear


## Host: the first thing a flying spear meets takes the throw's hit, and the spear drops there.
func _spear_hits(spear: ThrownSpear, p0: Vector3, p1: Vector3) -> bool:
	var best := {}
	var best_t := INF
	for thing in hittables(get_tree(), Session._player_for_peer(spear.shooter)):
		var t := WeaponRules.segment_hits_sphere(p0, p1, thing.pos, float(thing.radius) + 0.1)
		if t >= 0.0 and t < best_t:
			best_t = t
			best = thing
	if best.is_empty():
		return false
	var point := p0.lerp(p1, best_t)
	apply_hit(best, p0, spear.weapon, WeaponRules.THROW, 1.0, point, spear.shooter)
	spear.drop_at(point)
	spear.drop_at.rpc(point)
	return true


func _on_spear_returned(pos: Vector3, picked_up: bool, shooter: int) -> void:
	_rpc_poof.rpc(pos, true)
	var here := shooter == multiplayer.get_unique_id() or multiplayer.get_peers().has(shooter)
	if not picked_up and here:
		Session.send_feedback(shooter, "Your spear flew back to you!")


## Host -> everyone: a mace struck the ground at `at`.
@rpc("authority", "call_local", "unreliable")
func _rpc_ground_shake(at: Vector3) -> void:
	Fx.burst(get_tree().root, at + Vector3(0, 0.15, 0), Color("b89a7c"), 14, 4.0, 0.12, 0.5, 12.0)
	Audio.play(&"thud", at)
	ground_shake(at)


## This game's player feels a ground shake at `at` (less further away, nothing beyond
## WeaponRules.MACE_SHAKE_RADIUS), at most three times a second (no flashing screen, lead's ruling).
func ground_shake(at: Vector3) -> void:
	var me := Session._player_for_peer(multiplayer.get_unique_id())
	if me == null or not me.is_spawned():
		return
	var strength := WeaponRules.shake_strength(me.global_position.distance_to(at))
	var now := Time.get_ticks_msec()
	if strength <= 0.0 or now - _last_shake_ms < SHAKE_GAP_MS:
		return
	_last_shake_ms = now
	last_shake = strength
	shake(me, strength)


const SHAKE_GAP_MS := 340


const SHAKE_METRES := 0.25   # view wobble per unit of mace shake strength (at most ~0.09 m, like a hard hit)
const SHAKE_TIME := 0.25


## The one place a mace's ground shake reaches the camera: Feel (M2 Task 11) wobbles this device's
## view, and stays still with Reduce motion or vibration off.
static func shake(_p: Player, strength: float) -> void:
	Feel.shake(strength * SHAKE_METRES, SHAKE_TIME)


# --- M2 Task 15: bot friends fight monsters -----------------------------------------------------
# A monster without hit_center() / hit_radius() is aimed at by MONSTER_CENTER / MONSTER_RADIUS (top).


## Host: one swing of a bot friend's weapon from `origin` along `dir`, by the rules of a player's
## swing (the weapon table's reach, arc, max hits and damage; nothing behind a wall), but a friend
## only ever hits monsters: players, animals, buddies and targets are left out. Each monster hit
## gets take_hit(damage, from, knockback) (the M2 monster contract). Returns what it hit.
func bot_melee(origin: Vector3, dir: Vector3, weapon_id: int, combo: int = 0) -> Array:
	var things: Array[Dictionary] = []
	for thing in monster_hittables(get_tree()):
		if WeaponRules.hit_in_reach(origin, thing.pos, weapon_id, thing.radius) and in_sight(origin, thing.pos):
			things.append(thing)
	var hits: Array = []
	for i: int in WeaponRules.melee_hits(origin, dir, things, weapon_id, combo):
		var thing: Dictionary = things[i]
		(thing.node as Node).call(&"take_hit", WeaponRules.damage_to(WeaponRules.MONSTER, weapon_id, combo), origin,
			WeaponRules.knockback(origin, thing.pos, weapon_id, combo))
		_rpc_hit_fx.rpc(thing.pos, weapon_id, NodePath())
		hits.append(thing)
	return hits


## Every monster that can take a hit: [{node, pos, radius, kind}]. A monster may give its own
## hit_center() and hit_radius(); otherwise a small body is assumed.
static func monster_hittables(tree: SceneTree) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for n in tree.get_nodes_in_group(&"monsters"):
		var m := n as Node3D
		if m == null or m.is_queued_for_deletion() or not m.has_method(&"take_hit"):
			continue
		var pos: Vector3 = m.call(&"hit_center") if m.has_method(&"hit_center") else m.global_position + Vector3(0, MONSTER_CENTER, 0)
		var radius: float = float(m.call(&"hit_radius")) if m.has_method(&"hit_radius") else MONSTER_RADIUS
		out.append({"node": m, "pos": pos, "radius": radius, "kind": WeaponRules.MONSTER})
	return out
