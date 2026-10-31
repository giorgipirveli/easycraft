class_name GhostRaces
extends Node
## Friends' ghosts on the courses of this game (M4 ghost races; spec §17.5, research T2): a friend's showcase
## ghosts in a visit, a gift's ghost where its stamp was stamped in this player's own world. One node on this
## game only (never over the network): each ghost is a GhostRunner waiting on its START while this player is
## near; when this player's run on that START starts (CourseDirector: START as in M3 Task 7) the ghost runs too,
## and at FINISH the race clock shows the medal against the ghost's time (CourseDirector.state_filter), with a
## line for the toast; the child's best against each ghost is kept (`result_noted`). Works offline: the ghosts
## are this device's (GhostBook).

const SHOW_RADIUS := 64.0        # a ghost waits on its START while this player is this near
const LOOK_EVERY := 0.5

## () -> bool: whether friends' names show (GhostRaceRules.shows_names; else "A friend's ghost").
var names_shown := func() -> bool: return false
## (key: String, ms: int) -> bool: a finished race against the ghost `key` (GhostBook.note_result).
var result_noted := func(_key: String, _ms: int) -> bool: return false
## (cell: Vector3i) -> bool: whether the START is still there (a broken START's ghost waits nowhere).
var start_ok := func(_cell: Vector3i) -> bool: return true

var courses: CourseDirector
var player: Node3D
## START cell -> {"ghost": RaceGhost, "forward": Vector3i, "key": String}
var links := {}
## START cell -> GhostRunner (only near this player, and the one being raced)
var runners := {}
## The START this player races from against its ghost (CourseBook.NONE when none).
var racing := CourseBook.NONE

var _look_t := 0.0


## Follows this game's course director (its local player's runs) and player.
func setup(director: CourseDirector, local_player: Node3D) -> void:
	courses = director
	player = local_player
	director.state_filter = filter
	if not director.state_changed.is_connected(_on_state):
		director.state_changed.connect(_on_state)


## The ghost `g` races from the START at `start` (a world cell), turned like a stamp facing `forward` (ZERO: as
## it came, a showcase); `key`: its GhostBook entry.
func link(start: Vector3i, g: RaceGhost, forward: Vector3i = Vector3i.ZERO, key: String = "") -> void:
	unlink(start)
	links[start] = {"ghost": g, "forward": forward, "key": key}
	look_around()


func unlink(start: Vector3i) -> void:
	links.erase(start)
	if runners.has(start):
		(runners[start] as GhostRunner).queue_free()
		runners.erase(start)


func runner_at(start: Vector3i) -> GhostRunner:
	return runners.get(start)


func _process(delta: float) -> void:
	_look_t -= delta
	if _look_t <= 0.0:
		_look_t = LOOK_EVERY
		look_around()


## A runner waits on every linked START near this player; far ones go (never the one being raced).
func look_around() -> void:
	if not is_instance_valid(player) or not is_inside_tree():
		return
	for start: Vector3i in links:
		var near := CourseRules.top_of(start).distance_to(player.global_position) <= SHOW_RADIUS \
			and bool(start_ok.call(start))
		if near and not runners.has(start):
			_add_runner(start)
		elif not near and runners.has(start) and start != racing:
			(runners[start] as GhostRunner).queue_free()
			runners.erase(start)


func _add_runner(start: Vector3i) -> GhostRunner:
	var l: Dictionary = links[start]
	var g: RaceGhost = l.ghost
	var r := GhostRunner.new()
	r.name = "Ghost_%d_%d_%d" % [start.x, start.y, start.z]
	r.setup(g, CourseRules.top_of(start), l.forward, GhostRaceRules.ghost_name(g.owner, bool(names_shown.call())))
	add_child(r)
	runners[start] = r
	return r


## This player's run as the host sent it: the ghost of that START waits with them, runs with them, stops with them.
func _on_state(s: Dictionary) -> void:
	var event := str(s.get("event", ""))
	var start: Variant = s.get("start")
	match event:
		"armed":
			_reset_racing()
			if start is Vector3i and links.has(start):
				racing = start
				var r: GhostRunner = runners.get(start) if runners.has(start) else _add_runner(start)
				r.wait()
		"go":
			if start is Vector3i and start == racing and runners.has(start):
				(runners[start] as GhostRunner).go()
		"stop":
			_reset_racing()
		"finish":
			racing = CourseBook.NONE


func _reset_racing() -> void:
	if racing != CourseBook.NONE and runners.has(racing):
		(runners[racing] as GhostRunner).wait()
	racing = CourseBook.NONE


## CourseDirector.state_filter: a finish against a ghost shows the medal against the ghost's time, and its words.
func filter(s: Dictionary) -> Dictionary:
	if str(s.get("event", "")) != "finish" or not s.get("start") is Vector3i or not links.has(s.start) \
			or s.start != racing:
		return s
	var l: Dictionary = links[s.start]
	var g: RaceGhost = l.ghost
	var ms := int(s.get("ms", 0))
	var out := s.duplicate()
	var m := GhostRaceRules.medal(ms, g.ms)
	out.medal = String(m)
	out.ghost_best = bool(result_noted.call(str(l.key), ms))   # the child's best against this ghost
	out.best = GhostRaceRules.beat(ms, g.ms)                    # sparkles: the ghost is beaten
	out.ghost_line = GhostRaceRules.result_line(ms, g.ms, g.owner, bool(names_shown.call()))
	out.ghost_ms = g.ms
	return out
