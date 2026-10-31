extends RefCounted
## The cheat test's players (docs/design/games/leaf-voyage.md §3.9, §4.6, ruling 23; the phase A models' `Child`):
## each stands in for a child working the leaf's doors, one door at a time (a reach and a squeeze take TOGGLE s).
## They play the production rules (LeafSim, LeafWeather, LeafBeats) step by step, as the models did, and `play` says
## how a voyage went. A test helper (tests/unit/test_leaf_cheat_bots.gd; tools may load it), not a test itself.

## Knows the rule: sets the doors the weather asks for (the voyage's own: open in the cloud; in the desert, at night).
const RULE := "rule"
## Knows the rule but reacts slowly (4 s) and a door takes a little longer.
const SLOW := "slow"
## Taps a door at random, about one every 1.5 s.
const RANDOM := "random"
const ALWAYS_OPEN := "always_open"
const ALWAYS_CLOSED := "always_closed"
## "More air, more sugar" (the design's greedy player, §3.9): opens every door while there is light to build with,
## shuts one only once the leaf visibly droops.
const GREEDY := "greedy"
## Watches the cells: keeps the doors open while the leaf is well above drooping (over 0.7), shuts one as soon as the
## cells start to drain (under 0.6). The plant's own feedback; it reads the leaf, not the weather.
const WATCH := "watch"
## Opens whenever there is light, shuts in the dark (light mistaken for the need).
const BRIGHT := "bright"
## The desert: the sunflower's habit of opening in daylight (the desert model's "habit").
const HABIT := "habit"
## The desert: the sunflower's own rule carried over unchanged (open only when a cloud comes: none ever does).
const CLOUD_HABIT := "cloud_habit"
const TOGGLE := {"flat": 0.8, "vr": 0.6}
const DT := 0.1
## Bots that never use their random stream: every seed plays the same run.
const SAME_EVERY_SEED: Array[String] = [ALWAYS_OPEN, ALWAYS_CLOSED, GREEDY, WATCH]

static var _weather_cache := {}

var policy := RULE
var toggle_s := 0.8
var reaction := 1.5
var busy := 0.0
var dt := DT
var rng := RandomNumberGenerator.new()


func _init(bot_policy: String, mode: String, seed: int, step: float = DT) -> void:
	policy = bot_policy
	toggle_s = float(TOGGLE.get(mode, 0.8))
	dt = step
	rng.seed = seed
	reaction = (4.0 if policy == SLOW else 1.5) + rng.randf_range(-0.5, 0.8)


## One step: maybe toggles a door; the door toggled, or -1.
func act(sim: LeafSim, w: Dictionary) -> int:
	if busy > 0.0:
		busy -= dt
		return -1
	var want := _want(sim, w)
	if want >= 0:
		sim.toggle(want)
		busy = toggle_s
	return want


## The same choices acted through a whole run (LeafRun: the host's way in, with its help, longer windows and extra
## turns); the rule's players also carry each waiting sugar to the gold pipe when the doors are right.
func act_run(run: LeafRun) -> void:
	if busy > 0.0:
		busy -= dt
		return
	var want := _want(run.sim, run.weather_now())
	if want >= 0:
		run.toggle(want)
		busy = toggle_s
	elif (policy == RULE or policy == SLOW) and run.take():
		run.deliver("gold")
		busy = toggle_s * 2.0


func _want(sim: LeafSim, w: Dictionary) -> int:
	var want := -1
	var since := float(w.since)
	match policy:
		RULE, SLOW:
			if since >= reaction:
				want = _first_not(sim, bool(w.open))
		RANDOM:
			if rng.randf() < dt / 1.5:
				want = rng.randi_range(0, sim.doors.size() - 1)
		ALWAYS_OPEN:
			want = _first_not(sim, true)
		GREEDY:
			if not sim.standing():
				want = _first_not(sim, false)
			elif float(w.light) > 0.0:
				want = _first_not(sim, true)
		WATCH:
			if sim.water > 0.7:
				want = _first_not(sim, true)
			elif sim.water < 0.6:
				want = _first_not(sim, false)
		BRIGHT:
			if since >= reaction:
				want = _first_not(sim, float(w.light) > 0.0)
		HABIT:
			if since >= reaction:
				want = _first_not(sim, not bool(w.night))
		CLOUD_HABIT:
			if since >= reaction:
				want = _first_not(sim, str(w.kind) == "cloud")
	return want


static func _first_not(sim: LeafSim, open: bool) -> int:
	for i in sim.doors.size():
		if sim.doors[i] != open:
			return i
	return -1


## The voyage's judged part played by a bot (5.1: Act 2 from the full leaf with its doors shut, as the model starts;
## 5.T1: the whole desert script): {results (LeafBeats'), passed (judged beats passed), judged, sugar, min_w, dry}.
static func play(voyage: String, bot_policy: String, mode: String, seed: int, step: float = DT) -> Dictionary:
	var v := LeafVoyages.voyage(voyage)
	var sim := LeafSim.make(v.sim)
	if voyage == "5.1":
		sim.water = 0.95
		for i in sim.doors.size():
			sim.set_door(i, false)
	var weather := LeafWeather.for_voyage(voyage)
	var beats := LeafBeats.for_voyage(voyage, weather)
	var bot: RefCounted = (load("res://tests/unit/leaf_bots.gd") as GDScript).new(bot_policy, mode, seed, step)
	var min_w := 1.0
	var dry := 0
	var was_dry := false
	for w: Dictionary in _steps(voyage, weather, step):
		bot.act(sim, w)
		sim.step(step, w)
		beats.observe(w, sim, step)
		min_w = minf(min_w, sim.water)
		var now_dry := sim.too_dry()
		if now_dry and not was_dry:
			dry += 1
		was_dry = now_dry
	beats.finish()
	var passed := beats.results.filter(func(r: Dictionary) -> bool: return bool(r.passed)).size()
	return {"results": beats.results, "passed": passed, "judged": beats.results.size(), "sugar": sim.made,
		"min_w": min_w, "dry": dry, "bud": float(v.sim.get("bud", 12))}


## Masters the voyage's beats as MasteryRules counts them (5 of 6), the act 1 beat counted solved for the sunflower
## (the most a guesser could hope for).
static func masters(voyage: String, r: Dictionary) -> bool:
	var extra := 1 if voyage == "5.1" else 0
	var silent_ok := int(r.passed) >= 5
	return silent_ok and MasteryRules.is_mastery(int(r.passed) + extra, int(r.judged) + extra)


## The desert's own win (the model's): at least the bud's sugar built and the stem never drooping.
static func wins_desert(r: Dictionary) -> bool:
	return float(r.sugar) >= float(r.bud) and float(r.min_w) >= 0.55


## The weather at every step of a voyage's script (computed once per voyage and step: the script is fixed here).
static func _steps(voyage: String, weather: LeafWeather, step: float) -> Array:
	var key := "%s@%f" % [voyage, step]
	if not _weather_cache.has(key):
		var out := []
		for i in int(round(weather.total() / step)):
			out.append(weather.at(i * step))
		_weather_cache[key] = out
	return _weather_cache[key]
