extends SceneTree
## Times MeadowsGenerator per 16³ chunk, split into surface, underground and sky chunks.
## Run: godot --headless --path . --script res://tools/bench_generator.gd
## Prints one "BENCH" line per chunk kind: count, average and worst milliseconds (the real generator,
## secrets included). Each chunk is also generated with the secrets off (M2 Task 16), in alternating
## order so a busy machine slows both alike; "BENCH_SECRETS" lines give that comparison, and
## "BENCH_SECRET_AREAS" the one-time cost of placing a new 128 × 128 area's secrets (paid by the first
## chunk generated there, then cached).
## With `-- --desert` (M3 Task 2) it compares DesertGenerator with MeadowsGenerator instead: the same
## chunks, the two generators alternating chunk by chunk (a busy PC slows both alike), one
## "BENCH_DESERT <kind> meadows_avg_ms=… desert_avg_ms=…" line per chunk kind, and the desert's secret areas.
## With `-- --frost` (M3 Task 3) the same for FrostGenerator: "BENCH_FROST <kind> meadows_avg_ms=… frost_avg_ms=…".
## With `-- --candy` (M3 Task 4) the same for CandyGenerator: "BENCH_CANDY <kind> meadows_avg_ms=… candy_avg_ms=…".
## With `-- --dragon` (owner 39) the same for DragonGenerator: "BENCH_DRAGON <kind> meadows_avg_ms=… dragon_avg_ms=…".
## With `-- --glow` (universe 6) the Glow Caves' GlowGenerator against the Dragon Realm's and the meadows' on the same
## chunks: "BENCH_GLOW <kind> meadows_avg_ms=… dragon_avg_ms=… glow_avg_ms=…" (warm: the second round, stacks cached) and
## "BENCH_GLOW_COLD …" (fresh generators streaming whole stacks y -64..111, the two universes alternating stack by stack).
## With `-- --space` (owner #55) the same for every planet's SpaceGenerator: "BENCH_SPACE_MOON <kind> meadows_avg_ms=… moon_avg_ms=…";
## `-- --space moon mars` only for those planets (cosmos: Mars is BENCH_SPACE_MARS, Europa BENCH_SPACE_EUROPA, Io
## BENCH_SPACE_IO, Titan BENCH_SPACE_TITAN, Mercury BENCH_SPACE_MERCURY, Venus BENCH_SPACE_VENUS, Saturn's rings
## BENCH_SPACE_RINGS, Pluto BENCH_SPACE_PLUTO, Triton BENCH_SPACE_TRITON, Ganymede BENCH_SPACE_GANYMEDE; their regions
## BENCH_MARS_<REGION>, BENCH_EUROPA_<REGION>, BENCH_IO_<REGION>, BENCH_TITAN_<REGION>, BENCH_MERCURY_<REGION>,
## BENCH_VENUS_<REGION>, BENCH_RINGS_<REGION>, BENCH_PLUTO_<REGION>, BENCH_TRITON_<REGION> and BENCH_GANYMEDE_<REGION>, with
## BENCH_PLUTO_SHAPE, BENCH_TRITON_SHAPE and BENCH_GANYMEDE_SHAPE, the cost of building such a shape and a column).
## With `-- --biomes` (owner #45b) the wild meadows (MeadowsBiomeGenerator, terrain version 2) against the old
## meadows: "BENCH_BIOMES <kind> meadows_avg_ms=… biomes_avg_ms=… biomes_cold_avg_ms=…" (see _bench_biomes).
## With `-- --deposits` (spec §26, prospecting) the chunks round each terrain's nearest deposits, deposits on and off
## alternating: "BENCH_DEPOSITS <terrain> off_avg_ms=… on_avg_ms=…", and "BENCH_DEPOSIT_REGIONS <terrain> …" the one-time
## cost of placing a new 512 × 512 region's deposits (its secrets already placed, and cold with them); spec §26.5: the
## Moon and Mars too (terrains moon, mars: SpaceGenerator).
## With `-- --wonders` (owner #78) world 41's WondersGenerator against the meadows round the landing square
## ("BENCH_WONDERS <kind> meadows_avg_ms=… wonders_avg_ms=…"), then over each wonder: "BENCH_WONDERS_<ID> …" (fresh
## generators over 4 × 4 whole chunk stacks, against the old meadows and the wild meadows on the same chunks).

const SEED := 12345
const SIZE := 16


func _init() -> void:
	if OS.get_cmdline_user_args().has("--deposits"):   # spec §26: prospecting's deposits
		_bench_deposits()
		quit()
		return
	if OS.get_cmdline_user_args().has("--desert"):
		_bench_desert()
		quit()
		return
	if OS.get_cmdline_user_args().has("--frost"):
		var frost := FrostGenerator.new()
		frost.world_seed = SEED
		_bench_universe("FROST", "frost", frost, FrostSecretRules.new(SEED))
		quit()
		return
	if OS.get_cmdline_user_args().has("--biomes"):   # owner #45b: the wild meadows (terrain version 2)
		_bench_biomes()
		quit()
		return
	if OS.get_cmdline_user_args().has("--candy"):   # M3 Task 4
		var candy := CandyGenerator.new()
		candy.world_seed = SEED
		_bench_universe("CANDY", "candy", candy, CandySecretRules.new(SEED))
		quit()
		return
	if OS.get_cmdline_user_args().has("--space"):   # owner #55: the Moon and the planets (SpaceGenerator)
		var only := OS.get_cmdline_user_args()   # cosmos: `-- --space moon mars` benches only those planets
		for planet: StringName in SpaceShape.PLANETS:
			if only.size() > 1 and not only.has(String(planet)):
				continue
			var space := SpaceGenerator.new()
			space.planet = planet
			space.world_seed = SEED
			_bench_universe("SPACE_" + String(planet).to_upper(), String(planet), space,
				SpaceSecretRules.new(SEED, SpaceShape.new(SEED, planet)))
			_bench_space_cold(planet)
			if ColonyRules.has_colony(planet):   # spec §21c: the colony under domes
				_bench_colony(planet)
			if planet == SpaceShape.MARS:
				_bench_mars_regions()
			if planet == SpaceShape.EUROPA:
				_bench_europa_regions()
			if planet == SpaceShape.IO:
				_bench_io_regions()
			if planet == SpaceShape.TITAN:
				_bench_titan_regions()
			if planet == SpaceShape.MERCURY:
				_bench_mercury_regions()
			if planet == SpaceShape.VENUS:
				_bench_venus_regions()
			if planet == SpaceShape.RINGS:
				_bench_rings_regions()
			if planet == SpaceShape.PLUTO:
				_bench_pluto_regions()
			if planet == SpaceShape.TRITON:
				_bench_triton_regions()
			if planet == SpaceShape.GANYMEDE:
				_bench_ganymede_regions()
		quit()
		return
	if OS.get_cmdline_user_args().has("--wonders"):   # owner #78: world 41, Wonders of the World
		var wonders := WondersGenerator.new()
		wonders.world_seed = SEED
		_bench_universe("WONDERS", "wonders", wonders, WondersSecretRules.new(SEED))
		_bench_wonders_regions()
		quit()
		return
	if OS.get_cmdline_user_args().has("--glow"):   # universe 6: the Glow Caves against the Dragon Realm (the brief's bar)
		_bench_glow()
		quit()
		return
	if OS.get_cmdline_user_args().has("--dragon"):   # owner 39: the Dragon Realm's floating islands
		var dragon := DragonGenerator.new()
		dragon.world_seed = SEED
		_bench_universe("DRAGON", "dragon", dragon, DragonSecretRules.new(SEED))
		quit()
		return
	var gen := MeadowsGenerator.new()
	gen.world_seed = SEED
	var shape := MeadowsShape.new(SEED)
	var times := {"surface": [], "underground": [], "sky": []}
	var off := {"surface": [], "underground": [], "sky": []}
	var n := 0
	for cx in range(-4, 4):
		for cz in range(-4, 4):
			var ground := shape.height_at(cx * SIZE + 8, cz * SIZE + 8)
			for cy in range(-4, 5):
				var origin := Vector3i(cx, cy, cz) * SIZE
				var kind := "sky" if origin.y > ground + 16 else ("underground" if origin.y + SIZE <= 0 else "surface")
				var first_on := n % 2 == 0
				n += 1
				for pass_on in ([true, false] if first_on else [false, true]):
					gen.secrets_enabled = pass_on
					var ms := _time(gen, origin)
					((times if pass_on else off)[kind] as Array).append(ms)
	gen.secrets_enabled = true
	_bench_areas()
	for kind: String in times:
		var on_list: Array = times[kind]
		if on_list.is_empty():
			continue
		print("BENCH %s chunks=%d avg_ms=%.2f worst_ms=%.2f" % [kind, on_list.size(), _avg(on_list), _worst(on_list)])
	for kind: String in times:
		var on_list: Array = times[kind]
		if on_list.is_empty():
			continue
		var off_list: Array = off[kind]
		print("BENCH_SECRETS %s off_avg_ms=%.2f on_avg_ms=%.2f off_worst_ms=%.2f on_worst_ms=%.2f" % [kind,
			_avg(off_list), _avg(on_list), _worst(off_list), _worst(on_list)])
	quit()


func _bench_areas() -> void:
	var rules := SecretRules.new(SEED)
	var list: Array = []
	for az in range(-4, 4):
		for ax in range(-4, 4):
			var t := Time.get_ticks_usec()
			rules.secrets_in_area(Vector2i(ax, az))
			list.append((Time.get_ticks_usec() - t) / 1000.0)
	print("BENCH_SECRET_AREAS areas=%d avg_ms=%.2f worst_ms=%.2f" % [list.size(), _avg(list), _worst(list)])


func _time(gen: MeadowsGenerator, origin: Vector3i) -> float:
	var buf := VoxelBuffer.new()
	buf.create(SIZE, SIZE, SIZE)
	var t := Time.get_ticks_usec()
	gen._generate_block(buf, origin, 0)
	return (Time.get_ticks_usec() - t) / 1000.0


func _avg(list: Array) -> float:
	var total := 0.0
	for ms: float in list:
		total += ms
	return total / list.size()


func _worst(list: Array) -> float:
	var worst := 0.0
	for ms: float in list:
		worst = maxf(worst, ms)
	return worst


# --- Owner #55: a new space world, cold (nothing cached yet) ---------------------------------------------

## Fresh generators (a planet's and Green Meadows') over the same chunks the way a world streams them (a stack's chunks
## one after another: its first chunk pays for the stack's columns), alternating stack by stack: BENCH_SPACE_<P>_COLD.
func _bench_space_cold(planet: StringName) -> void:
	var space := SpaceGenerator.new()
	space.planet = planet
	space.world_seed = SEED + 1
	var meadows := MeadowsGenerator.new()
	meadows.world_seed = SEED + 1
	var s := {"surface": [], "underground": [], "sky": []}
	var m := {"surface": [], "underground": [], "sky": []}
	var n := 0
	for cx in range(-4, 4):
		for cz in range(-4, 4):
			var space_first := n % 2 == 0
			n += 1
			for which in ([space, meadows] if space_first else [meadows, space]):
				for cy in range(-4, 6):
					var origin := Vector3i(cx, cy, cz) * SIZE
					var kind := "underground" if origin.y + SIZE <= 0 else ("surface" if origin.y < 80 else "sky")
					((s if which == space else m)[kind] as Array).append(_time(which, origin))
	for kind: String in ["surface", "underground", "sky"]:
		print("BENCH_SPACE_%s_COLD %s chunks=%d meadows_avg_ms=%.2f %s_avg_ms=%.2f meadows_worst_ms=%.2f %s_worst_ms=%.2f" % [
			String(planet).to_upper(), kind, (s[kind] as Array).size(), _avg(m[kind]), planet, _avg(s[kind]),
			_worst(m[kind]), planet, _worst(s[kind])])
	var all_s: Array = s.surface + s.underground + s.sky
	var all_m: Array = m.surface + m.underground + m.sky
	print("BENCH_SPACE_%s_COLD all meadows_avg_ms=%.2f %s_avg_ms=%.2f" % [String(planet).to_upper(), _avg(all_m), planet, _avg(all_s)])


# --- Spec §21c: the colony under domes (the Moon's, Mars's) --------------------------------------------------------

## Fresh generators over the colony's 6 × 6 chunk stacks (y -64..159, as a world streams them), the planet's with the
## colony, the planet's with the colony off (SpaceGenerator.colony_enabled: the same flat ground, no boxes) and Green
## Meadows', alternating stack by stack: BENCH_COLONY_<P> surface, underground, sky (…_avg_ms, …_worst_ms), and the cost of
## building a shape with its colony (BENCH_COLONY_<P>_SHAPE: every world load builds a few).
func _bench_colony(planet: StringName) -> void:
	var probe := SpaceShape.new(SEED + 3, planet)
	var at := probe.colony.centre
	var on := SpaceGenerator.new()
	on.planet = planet
	on.world_seed = SEED + 3
	var off := SpaceGenerator.new()
	off.planet = planet
	off.world_seed = SEED + 3
	off.colony_enabled = false
	var meadows := MeadowsGenerator.new()
	meadows.world_seed = SEED + 3
	var times := {}
	for g in ["colony", "plain", "meadows"]:
		times[g] = {"surface": [], "underground": [], "sky": []}
	var n := 0
	for cx in range(-3, 3):
		for cz in range(-3, 3):
			var order: Array = [[on, "colony"], [off, "plain"], [meadows, "meadows"]]
			for i in n % 3:
				order.push_back(order.pop_front())
			n += 1
			for which: Array in order:
				for cy in range(-4, 10):
					var origin := Vector3i(floori(at.x / 16.0) + cx, cy, floori(at.y / 16.0) + cz) * SIZE
					var kind := "underground" if origin.y + SIZE <= 0 else ("surface" if origin.y < 80 else "sky")
					((times[which[1]] as Dictionary)[kind] as Array).append(_time(which[0], origin))
	for kind: String in ["surface", "underground", "sky"]:
		print("BENCH_COLONY_%s %s chunks=%d meadows_avg_ms=%.2f plain_avg_ms=%.2f colony_avg_ms=%.2f meadows_worst_ms=%.2f plain_worst_ms=%.2f colony_worst_ms=%.2f" % [
			String(planet).to_upper(), kind, (times.colony[kind] as Array).size(), _avg(times.meadows[kind]),
			_avg(times.plain[kind]), _avg(times.colony[kind]), _worst(times.meadows[kind]), _worst(times.plain[kind]),
			_worst(times.colony[kind])])
	var shapes: Array = []
	for i in 5:
		var t := Time.get_ticks_usec()
		SpaceShape.new(SEED + 10 + i, planet)
		shapes.append((Time.get_ticks_usec() - t) / 1000.0)
	print("BENCH_COLONY_%s_SHAPE builds=%d avg_ms=%.2f worst_ms=%.2f boxes=%d" % [String(planet).to_upper(), shapes.size(),
		_avg(shapes), _worst(shapes), probe.colony.box_count()])


# --- Cosmos: Mars's regions (spec §21b.2) --------------------------------------------------------------------

## Fresh generators over 4 × 4 chunk stacks (y -64..159, as a world streams them) on the giant volcano's flank and its
## summit, across the canyon and on the north cap, against Green Meadows' on the same chunks (the plains are the
## BENCH_SPACE_MARS lines): BENCH_MARS_<REGION> surface (y 0..159, the volcano's chunks go up to its top), underground.
func _bench_mars_regions() -> void:
	var probe := SpaceShape.new(SEED + 2, SpaceShape.MARS)
	var vc := probe.mars.volcano_centre()
	var regions := {"VOLCANO_FLANK": vc + Vector2i(90, 0), "VOLCANO_TOP": vc, "CANYON": Vector2i(0, roundi(probe.mars.canyon_z(0))),
		"NORTH_CAP": Vector2i(0, probe.mars.north_edge() - 80)}
	for region: String in regions:
		var at: Vector2i = regions[region]
		var mars := SpaceGenerator.new()
		mars.planet = SpaceShape.MARS
		mars.world_seed = SEED + 2
		var meadows := MeadowsGenerator.new()
		meadows.world_seed = SEED + 2
		var s := {"surface": [], "underground": []}
		var m := {"surface": [], "underground": []}
		var n := 0
		for cx in range(-2, 2):
			for cz in range(-2, 2):
				var mars_first := n % 2 == 0
				n += 1
				for which in ([mars, meadows] if mars_first else [meadows, mars]):
					for cy in range(-4, 10):
						var origin := Vector3i(floori(at.x / 16.0) + cx, cy, floori(at.y / 16.0) + cz) * SIZE
						var kind := "underground" if origin.y + SIZE <= 0 else "surface"
						((s if which == mars else m)[kind] as Array).append(_time(which, origin))
		for kind: String in ["surface", "underground"]:
			print("BENCH_MARS_%s %s chunks=%d meadows_avg_ms=%.2f mars_avg_ms=%.2f meadows_worst_ms=%.2f mars_worst_ms=%.2f" % [
				region, kind, (s[kind] as Array).size(), _avg(m[kind]), _avg(s[kind]), _worst(m[kind]), _worst(s[kind])])


# --- Owner #78: the wonders of world 41 (spec §24) ------------------------------------------------------------

## Fresh generators over 4 × 4 chunk stacks (y -64..159, as a world streams them) round each wonder, against Green
## Meadows' (the old meadows and the wild meadows, terrain version 2, fresh too) on the same chunks, the three
## alternating stack by stack: BENCH_WONDERS_<ID> surface (y 0..159: the wonders' chunks), underground.
func _bench_wonders_regions() -> void:
	for id: StringName in WonderTour.ids():
		var at: Vector2i = WonderTour.WONDERS[id].centre
		var wonders := WondersGenerator.new()
		wonders.world_seed = SEED + 3
		var meadows := MeadowsGenerator.new()
		meadows.world_seed = SEED + 3
		var wild := MeadowsBiomeGenerator.new()
		wild.world_seed = SEED + 3
		var gens: Array[MeadowsGenerator] = [wonders, meadows, wild]
		var t := {}
		for g in gens:
			t[g] = {"surface": [], "underground": []}
		var n := 0
		for cx in range(-2, 2):
			for cz in range(-2, 2):
				n += 1
				for k in gens.size():
					var one: MeadowsGenerator = gens[(k + n) % gens.size()]
					for cy in range(-4, 10):
						var origin := Vector3i(floori(at.x / 16.0) + cx, cy, floori(at.y / 16.0) + cz) * SIZE
						var kind := "underground" if origin.y + SIZE <= 0 else "surface"
						(t[one][kind] as Array).append(_time(one, origin))
		for kind: String in ["surface", "underground"]:
			print("BENCH_WONDERS_%s %s chunks=%d meadows_avg_ms=%.2f wild_avg_ms=%.2f wonders_avg_ms=%.2f meadows_worst_ms=%.2f wonders_worst_ms=%.2f" % [
				String(id).to_upper(), kind, (t[wonders][kind] as Array).size(), _avg(t[meadows][kind]), _avg(t[wild][kind]),
				_avg(t[wonders][kind]), _worst(t[meadows][kind]), _worst(t[wonders][kind])])


# --- Cosmos: Europa's regions (spec §21b.2) ------------------------------------------------------------------

## Fresh generators over 4 × 4 chunk stacks (y -64..159, as a world streams them) round the ocean well (its water,
## ramp and rings cut chunk by chunk), across the ice cliffs' edge and round a plume's vent, against Green Meadows' on
## the same chunks (the plains and cracks are the BENCH_SPACE_EUROPA lines): BENCH_EUROPA_<REGION> surface, underground.
func _bench_europa_regions() -> void:
	var probe := SpaceShape.new(SEED + 2, SpaceShape.EUROPA)
	var e := probe.europa
	var mc := e.mesa_centre()
	var regions := {"WELL": e.well_centre(), "CLIFFS": mc + Vector2i(roundi(EuropaTerrain.MESA_RADIUS), 0),
		"VENT": e.nearest_vent(probe.spawn_column())}
	for region: String in regions:
		var at: Vector2i = regions[region]
		var europa := SpaceGenerator.new()
		europa.planet = SpaceShape.EUROPA
		europa.world_seed = SEED + 2
		var meadows := MeadowsGenerator.new()
		meadows.world_seed = SEED + 2
		var s := {"surface": [], "underground": []}
		var m := {"surface": [], "underground": []}
		var n := 0
		for cx in range(-2, 2):
			for cz in range(-2, 2):
				var europa_first := n % 2 == 0
				n += 1
				for which in ([europa, meadows] if europa_first else [meadows, europa]):
					for cy in range(-4, 10):
						var origin := Vector3i(floori(at.x / 16.0) + cx, cy, floori(at.y / 16.0) + cz) * SIZE
						var kind := "underground" if origin.y + SIZE <= 0 else "surface"
						((s if which == europa else m)[kind] as Array).append(_time(which, origin))
		for kind: String in ["surface", "underground"]:
			print("BENCH_EUROPA_%s %s chunks=%d meadows_avg_ms=%.2f europa_avg_ms=%.2f meadows_worst_ms=%.2f europa_worst_ms=%.2f" % [
				region, kind, (s[kind] as Array).size(), _avg(m[kind]), _avg(s[kind]), _worst(m[kind]), _worst(s[kind])])


# --- Cosmos: Io's regions (spec §21b.2) ----------------------------------------------------------------------

## Fresh generators over 4 × 4 chunk stacks (y -64..159, as a world streams them) round the big lava lake (its crust,
## moat, rim and causeways), across the mountain's steep side and round a volcano, against Green Meadows' on the same
## chunks (the plains are the BENCH_SPACE_IO lines): BENCH_IO_<REGION> surface, underground.
func _bench_io_regions() -> void:
	var probe := SpaceShape.new(SEED + 2, SpaceShape.IO)
	var io := probe.io
	var pk := io.peak_centre()
	var regions := {"LAKE": io.lake_centre(), "MOUNTAIN": pk + Vector2i(roundi(io.mountain_up().x * 16), roundi(io.mountain_up().y * 16)),
		"VOLCANO": io.nearest_vent(probe.spawn_column())}
	for region: String in regions:
		var at: Vector2i = regions[region]
		var gen := SpaceGenerator.new()
		gen.planet = SpaceShape.IO
		gen.world_seed = SEED + 2
		var meadows := MeadowsGenerator.new()
		meadows.world_seed = SEED + 2
		var s := {"surface": [], "underground": []}
		var m := {"surface": [], "underground": []}
		var n := 0
		for cx in range(-2, 2):
			for cz in range(-2, 2):
				var io_first := n % 2 == 0
				n += 1
				for which in ([gen, meadows] if io_first else [meadows, gen]):
					for cy in range(-4, 10):
						var origin := Vector3i(floori(at.x / 16.0) + cx, cy, floori(at.y / 16.0) + cz) * SIZE
						var kind := "underground" if origin.y + SIZE <= 0 else "surface"
						((s if which == gen else m)[kind] as Array).append(_time(which, origin))
		for kind: String in ["surface", "underground"]:
			print("BENCH_IO_%s %s chunks=%d meadows_avg_ms=%.2f io_avg_ms=%.2f meadows_worst_ms=%.2f io_worst_ms=%.2f" % [
				region, kind, (s[kind] as Array).size(), _avg(m[kind]), _avg(s[kind]), _worst(m[kind]), _worst(s[kind])])


# --- Cosmos: Titan's regions (spec §21b.2) -------------------------------------------------------------------

## Fresh generators over 4 × 4 chunk stacks (y -64..159, as a world streams them) on the methane sea's shore (its beach,
## coast and liquid), among the dunes and across the icy mountains' flank, against Green Meadows' on the same chunks (the
## plains are the BENCH_SPACE_TITAN lines): BENCH_TITAN_<REGION> surface, underground.
func _bench_titan_regions() -> void:
	var probe := SpaceShape.new(SEED + 2, SpaceShape.TITAN)
	var t := probe.titan
	var sp := probe.spawn_column()
	var dune := t.first_dune_south_of(sp)
	var regions := {"SEA": t.sea_beach_toward(sp), "DUNES": dune + Vector2i(0, 60),
		"MOUNTAIN": t.peak_centre() + Vector2i(roundi(TitanTerrain.HALF_W * 0.6), 0)}
	for region: String in regions:
		var at: Vector2i = regions[region]
		var gen := SpaceGenerator.new()
		gen.planet = SpaceShape.TITAN
		gen.world_seed = SEED + 2
		var meadows := MeadowsGenerator.new()
		meadows.world_seed = SEED + 2
		var s := {"surface": [], "underground": []}
		var m := {"surface": [], "underground": []}
		var n := 0
		for cx in range(-2, 2):
			for cz in range(-2, 2):
				var titan_first := n % 2 == 0
				n += 1
				for which in ([gen, meadows] if titan_first else [meadows, gen]):
					for cy in range(-4, 10):
						var origin := Vector3i(floori(at.x / 16.0) + cx, cy, floori(at.y / 16.0) + cz) * SIZE
						var kind := "underground" if origin.y + SIZE <= 0 else "surface"
						((s if which == gen else m)[kind] as Array).append(_time(which, origin))
		for kind: String in ["surface", "underground"]:
			print("BENCH_TITAN_%s %s chunks=%d meadows_avg_ms=%.2f titan_avg_ms=%.2f meadows_worst_ms=%.2f titan_worst_ms=%.2f" % [
				region, kind, (s[kind] as Array).size(), _avg(m[kind]), _avg(s[kind]), _worst(m[kind]), _worst(s[kind])])


# --- Cosmos: Mercury's regions (spec §21b.2) -----------------------------------------------------------------

## Fresh generators over 4 × 4 chunk stacks (y -64..159, as a world streams them) across the great long cliff's face,
## over a big crater (its peak, floor and terraced walls) and the ice crater, against Green Meadows' on the same chunks
## (the plains are the BENCH_SPACE_MERCURY lines): BENCH_MERCURY_<REGION> surface, underground.
func _bench_mercury_regions() -> void:
	var probe := SpaceShape.new(SEED + 2, SpaceShape.MERCURY)
	var m := probe.mercury
	var sp := probe.spawn_column()
	var regions := {"CLIFF": m.great_face_toward(sp), "CRATER": m.nearest_crater(sp), "ICE": m.ice_centre()}
	for region: String in regions:
		var at: Vector2i = regions[region]
		var gen := SpaceGenerator.new()
		gen.planet = SpaceShape.MERCURY
		gen.world_seed = SEED + 2
		var meadows := MeadowsGenerator.new()
		meadows.world_seed = SEED + 2
		var s := {"surface": [], "underground": []}
		var m2 := {"surface": [], "underground": []}
		var n := 0
		for cx in range(-2, 2):
			for cz in range(-2, 2):
				var mercury_first := n % 2 == 0
				n += 1
				for which in ([gen, meadows] if mercury_first else [meadows, gen]):
					for cy in range(-4, 10):
						var origin := Vector3i(floori(at.x / 16.0) + cx, cy, floori(at.y / 16.0) + cz) * SIZE
						var kind := "underground" if origin.y + SIZE <= 0 else "surface"
						((s if which == gen else m2)[kind] as Array).append(_time(which, origin))
		for kind: String in ["surface", "underground"]:
			print("BENCH_MERCURY_%s %s chunks=%d meadows_avg_ms=%.2f mercury_avg_ms=%.2f meadows_worst_ms=%.2f mercury_worst_ms=%.2f" % [
				region, kind, (s[kind] as Array).size(), _avg(m2[kind]), _avg(s[kind]), _worst(m2[kind]), _worst(s[kind])])


# --- Cosmos: Venus's cloud city's parts (spec §21b.2) -----------------------------------------------------

## Fresh generators over 4 × 4 chunk stacks (y -64..159, as a world streams them) round the landing deck, the cloud
## homes, the sky garden, an isle far out and the open clouds between the rings, against Green Meadows' on the same
## chunks: BENCH_VENUS_<REGION> surface (y 0..79: the clouds, the hulls, the decks), sky (y 80 up: the features and the
## built parts), underground.
func _bench_venus_regions() -> void:
	var probe := SpaceShape.new(SEED + 2, SpaceShape.VENUS)
	var v := probe.venus
	var isle := Vector2i.ZERO
	for cx in range(2, 9):
		var i := v.isle(Vector2i(cx, 1))
		if not i.is_empty():
			isle = Vector2i(i[1], i[2])
			break
	var regions := {"LANDING": v.spawn(), "HOMES": v.centre(VenusTerrain.HOMES),
		"GARDEN": v.centre(VenusTerrain.GARDEN_DECK), "ISLE": isle, "OPEN": v.spawn() - v.north() * 60}
	for region: String in regions:
		var at: Vector2i = regions[region]
		var gen := SpaceGenerator.new()
		gen.planet = SpaceShape.VENUS
		gen.world_seed = SEED + 2
		var meadows := MeadowsGenerator.new()
		meadows.world_seed = SEED + 2
		var s := {"surface": [], "sky": [], "underground": []}
		var m2 := {"surface": [], "sky": [], "underground": []}
		var n := 0
		for cx in range(-2, 2):
			for cz in range(-2, 2):
				var venus_first := n % 2 == 0
				n += 1
				for which in ([gen, meadows] if venus_first else [meadows, gen]):
					for cy in range(-4, 10):
						var origin := Vector3i(floori(at.x / 16.0) + cx, cy, floori(at.y / 16.0) + cz) * SIZE
						var kind := "underground" if origin.y + SIZE <= 0 else ("surface" if origin.y < 80 else "sky")
						((s if which == gen else m2)[kind] as Array).append(_time(which, origin))
		for kind: String in ["surface", "sky", "underground"]:
			print("BENCH_VENUS_%s %s chunks=%d meadows_avg_ms=%.2f venus_avg_ms=%.2f meadows_worst_ms=%.2f venus_worst_ms=%.2f" % [
				region, kind, (s[kind] as Array).size(), _avg(m2[kind]), _avg(s[kind]), _worst(m2[kind]), _worst(s[kind])])


# --- Cosmos: Saturn's rings' parts (spec §21b.2) -----------------------------------------------------------

## Fresh generators over 4 × 4 chunk stacks (y -64..159, as a world streams them) round the landing chunk, the dense B
## ring, the C ring, the Cassini Division, Pan, the F ring and open space beyond, against Green Meadows' on the same
## chunks: BENCH_RINGS_<REGION> surface (y 0..79: the chunks), sky (y 80 up: the built parts' tops), underground.
func _bench_rings_regions() -> void:
	var probe := SpaceShape.new(SEED + 2, SpaceShape.RINGS)
	var r := probe.rings
	var sp := r.spawn()
	var regions := {"LANDING": sp, "B_RING": sp + Vector2i(130, -90), "C_RING": sp + Vector2i(90, -230),
		"CASSINI": sp + Vector2i(60, 120), "PAN": r.centre(&"pan"), "F_RING": sp + Vector2i(70, RingsTerrain.F_MID),
		"OPEN": sp + Vector2i(0, 600)}
	for region: String in regions:
		var at: Vector2i = regions[region]
		var gen := SpaceGenerator.new()
		gen.planet = SpaceShape.RINGS
		gen.world_seed = SEED + 2
		var meadows := MeadowsGenerator.new()
		meadows.world_seed = SEED + 2
		var s := {"surface": [], "sky": [], "underground": []}
		var m2 := {"surface": [], "sky": [], "underground": []}
		var n := 0
		for cx in range(-2, 2):
			for cz in range(-2, 2):
				var rings_first := n % 2 == 0
				n += 1
				for which in ([gen, meadows] if rings_first else [meadows, gen]):
					for cy in range(-4, 10):
						var origin := Vector3i(floori(at.x / 16.0) + cx, cy, floori(at.y / 16.0) + cz) * SIZE
						var kind := "underground" if origin.y + SIZE <= 0 else ("surface" if origin.y < 80 else "sky")
						((s if which == gen else m2)[kind] as Array).append(_time(which, origin))
		for kind: String in ["surface", "sky", "underground"]:
			print("BENCH_RINGS_%s %s chunks=%d meadows_avg_ms=%.2f rings_avg_ms=%.2f meadows_worst_ms=%.2f rings_worst_ms=%.2f" % [
				region, kind, (s[kind] as Array).size(), _avg(m2[kind]), _avg(s[kind]), _worst(m2[kind]), _worst(s[kind])])


# --- Cosmos: Pluto's regions (spec §21b.2) -------------------------------------------------------------------

## Fresh generators over 4 × 4 chunk stacks (y -64..159, as a world streams them) round the landing pad and the Charon
## Lookout, on the heart's plain (its cells), among the floating hills, over the ice mountains' peak, in the red-brown
## lands (their craters) and on the heart's bright side, against Green Meadows' on the same chunks: BENCH_PLUTO_<REGION>
## surface, underground. BENCH_PLUTO_SHAPE: building a Pluto shape (its terrain's cells, hills and mountain blocks, the
## pad and the lookout: once per world load, a few times) and one column.
func _bench_pluto_regions() -> void:
	var shapes: Array = []
	var t0 := Time.get_ticks_usec()
	for i in 5:
		shapes.append(SpaceShape.new(SEED + 10 + i, SpaceShape.PLUTO))
	var build_ms := (Time.get_ticks_usec() - t0) / 5000.0
	var probe := SpaceShape.new(SEED + 2, SpaceShape.PLUTO)
	var p := probe.pluto
	var t1 := Time.get_ticks_usec()
	var n_cols := 0
	for z in range(-300, 300, 7):
		for x in range(-300, 500, 7):
			p.column(x, z)
			n_cols += 1
	var col_us := float(Time.get_ticks_usec() - t1) / n_cols
	print("BENCH_PLUTO_SHAPE builds=5 avg_ms=%.2f column_us=%.2f hills=%d" % [build_ms, col_us, p.hills().size()])
	var sp := probe.spawn_column()
	var regions := {"LANDING": sp, "PLAIN": p.plain_shore_toward(sp) + Vector2i(60, 0), "HILLS": p.nearest_hill(sp),
		"MOUNTAINS": p.peak_centre(), "DARK": p.first_dark_west_of(sp) + Vector2i(-60, 0), "BRIGHT": p.bright_centre()}
	for region: String in regions:
		var at: Vector2i = regions[region]
		var gen := SpaceGenerator.new()
		gen.planet = SpaceShape.PLUTO
		gen.world_seed = SEED + 2
		var meadows := MeadowsGenerator.new()
		meadows.world_seed = SEED + 2
		var s := {"surface": [], "underground": []}
		var m := {"surface": [], "underground": []}
		var n := 0
		for cx in range(-2, 2):
			for cz in range(-2, 2):
				var pluto_first := n % 2 == 0
				n += 1
				for which in ([gen, meadows] if pluto_first else [meadows, gen]):
					for cy in range(-4, 10):
						var origin := Vector3i(floori(at.x / 16.0) + cx, cy, floori(at.y / 16.0) + cz) * SIZE
						var kind := "underground" if origin.y + SIZE <= 0 else "surface"
						((s if which == gen else m)[kind] as Array).append(_time(which, origin))
		for kind: String in ["surface", "underground"]:
			print("BENCH_PLUTO_%s %s chunks=%d meadows_avg_ms=%.2f pluto_avg_ms=%.2f meadows_worst_ms=%.2f pluto_worst_ms=%.2f" % [
				region, kind, (s[kind] as Array).size(), _avg(m[kind]), _avg(s[kind]), _worst(m[kind]), _worst(s[kind])])


# --- Cosmos: Triton's regions (spec §21b.2) ------------------------------------------------------------------

## Fresh generators over 4 × 4 chunk stacks (y -64..159, as a world streams them) round the landing pad and the Neptune
## Lookout, on the pink cap by the first geyser (its vent, ring and streak), on the cap's plain ice, in the cantaloupe
## terrain, over the frozen lake's walls and in the crater, against Green Meadows' on the same chunks:
## BENCH_TRITON_<REGION> surface, underground. BENCH_TRITON_SHAPE: building a Triton shape (the pad and the lookout: once
## per world load, a few times) and one column.
func _bench_triton_regions() -> void:
	var t0 := Time.get_ticks_usec()
	for i in 5:
		SpaceShape.new(SEED + 10 + i, SpaceShape.TRITON)
	var build_ms := (Time.get_ticks_usec() - t0) / 5000.0
	var probe := SpaceShape.new(SEED + 2, SpaceShape.TRITON)
	var t := probe.triton
	var t1 := Time.get_ticks_usec()
	var n_cols := 0
	for z in range(-300, 300, 7):
		for x in range(-300, 300, 7):
			t.column(x, z)
			n_cols += 1
	var col_us := float(Time.get_ticks_usec() - t1) / n_cols
	print("BENCH_TRITON_SHAPE builds=5 avg_ms=%.2f column_us=%.2f" % [build_ms, col_us])
	var sp := probe.spawn_column()
	var regions := {"LANDING": sp, "GEYSER": t.first_geyser(), "CAP": t.cap_point_south_of(sp) + Vector2i(40, 60),
		"MELON": t.first_melon_toward(sp) + Vector2i(-60, -60), "LAKE": t.lake_centre() + Vector2i(TritonTerrain.LAKE_R, 0),
		"CRATER": t.crater_centre()}
	for region: String in regions:
		var at: Vector2i = regions[region]
		var gen := SpaceGenerator.new()
		gen.planet = SpaceShape.TRITON
		gen.world_seed = SEED + 2
		var meadows := MeadowsGenerator.new()
		meadows.world_seed = SEED + 2
		var s := {"surface": [], "underground": []}
		var m := {"surface": [], "underground": []}
		var n := 0
		for cx in range(-2, 2):
			for cz in range(-2, 2):
				var triton_first := n % 2 == 0
				n += 1
				for which in ([gen, meadows] if triton_first else [meadows, gen]):
					for cy in range(-4, 10):
						var origin := Vector3i(floori(at.x / 16.0) + cx, cy, floori(at.y / 16.0) + cz) * SIZE
						var kind := "underground" if origin.y + SIZE <= 0 else "surface"
						((s if which == gen else m)[kind] as Array).append(_time(which, origin))
		for kind: String in ["surface", "underground"]:
			print("BENCH_TRITON_%s %s chunks=%d meadows_avg_ms=%.2f triton_avg_ms=%.2f meadows_worst_ms=%.2f triton_worst_ms=%.2f" % [
				region, kind, (s[kind] as Array).size(), _avg(m[kind]), _avg(s[kind]), _worst(m[kind]), _worst(s[kind])])


# --- Cosmos: Ganymede's regions (spec §21b.2) ----------------------------------------------------------------

## Fresh generators over 4 × 4 chunk stacks (y -64..159, as a world streams them) round the landing pad and the Jupiter
## Lookout, in the grooved terrain, on the dark terrain (furrows, old craters), at the ray crater (its pit and rays), on
## the north frost by the Aurora Watch and at the ocean drill, against Green Meadows' on the same chunks:
## BENCH_GANYMEDE_<REGION> surface, underground. BENCH_GANYMEDE_SHAPE: building a Ganymede shape (the pad and the built
## parts: once per world load, a few times) and one column.
func _bench_ganymede_regions() -> void:
	var t0 := Time.get_ticks_usec()
	for i in 5:
		SpaceShape.new(SEED + 10 + i, SpaceShape.GANYMEDE)
	var build_ms := (Time.get_ticks_usec() - t0) / 5000.0
	var probe := SpaceShape.new(SEED + 2, SpaceShape.GANYMEDE)
	var g := probe.ganymede
	var t1 := Time.get_ticks_usec()
	var n_cols := 0
	for z in range(-300, 300, 7):
		for x in range(-300, 300, 7):
			g.column(x, z)
			n_cols += 1
	var col_us := float(Time.get_ticks_usec() - t1) / n_cols
	print("BENCH_GANYMEDE_SHAPE builds=5 avg_ms=%.2f column_us=%.2f" % [build_ms, col_us])
	var sp := probe.spawn_column()
	var regions := {"LANDING": sp, "GROOVES": g.first_groove_toward(sp) + Vector2i(0, 40),
		"DARK": g.first_dark_west_of(sp) + Vector2i(-80, 0), "CRATER": g.crater_centre(), "FROST": g.watch,
		"DRILL": g.drill}
	for region: String in regions:
		var at: Vector2i = regions[region]
		var gen := SpaceGenerator.new()
		gen.planet = SpaceShape.GANYMEDE
		gen.world_seed = SEED + 2
		var meadows := MeadowsGenerator.new()
		meadows.world_seed = SEED + 2
		var s := {"surface": [], "underground": []}
		var m := {"surface": [], "underground": []}
		var n := 0
		for cx in range(-2, 2):
			for cz in range(-2, 2):
				var ganymede_first := n % 2 == 0
				n += 1
				for which in ([gen, meadows] if ganymede_first else [meadows, gen]):
					for cy in range(-4, 10):
						var origin := Vector3i(floori(at.x / 16.0) + cx, cy, floori(at.y / 16.0) + cz) * SIZE
						var kind := "underground" if origin.y + SIZE <= 0 else "surface"
						((s if which == gen else m)[kind] as Array).append(_time(which, origin))
		for kind: String in ["surface", "underground"]:
			print("BENCH_GANYMEDE_%s %s chunks=%d meadows_avg_ms=%.2f ganymede_avg_ms=%.2f meadows_worst_ms=%.2f ganymede_worst_ms=%.2f" % [
				region, kind, (s[kind] as Array).size(), _avg(m[kind]), _avg(s[kind]), _worst(m[kind]), _worst(s[kind])])


# --- M3 Task 2: the Sandstorm Desert against Green Meadows ---------------------------------------------

func _bench_desert() -> void:
	var desert := DesertGenerator.new()
	desert.world_seed = SEED
	_bench_universe("DESERT", "desert", desert, DesertSecretRules.new(SEED))


## A universe's generator against Green Meadows' on the same chunks (M3 Task 3: shared by the desert and
## Frostpeak): BENCH_<label> lines, `name` in their field names.
func _bench_universe(label: String, name: String, desert: MeadowsGenerator, rules: SecretRules) -> void:
	var meadows := MeadowsGenerator.new()
	meadows.world_seed = SEED
	var kinds := ["surface", "underground", "sky"]
	var m := {"surface": [], "underground": [], "sky": []}
	var d := {"surface": [], "underground": [], "sky": []}
	var n := 0
	for rep in 2:                       # the second round has every secret area cached, like a real world
		for cx in range(-4, 4):
			for cz in range(-4, 4):
				for cy in range(-4, 6):
					var origin := Vector3i(cx, cy, cz) * SIZE
					var kind: String = kinds[1] if origin.y + SIZE <= 0 else (kinds[0] if origin.y < 80 else kinds[2])
					var desert_first := n % 2 == 0
					n += 1
					for which in ([desert, meadows] if desert_first else [meadows, desert]):
						var ms := _time(which, origin)
						if rep == 1:
							((d if which == desert else m)[kind] as Array).append(ms)
	for kind: String in kinds:
		print("BENCH_%s %s chunks=%d meadows_avg_ms=%.2f %s_avg_ms=%.2f meadows_worst_ms=%.2f %s_worst_ms=%.2f" % [
			label, kind, (d[kind] as Array).size(), _avg(m[kind]), name, _avg(d[kind]), _worst(m[kind]), name, _worst(d[kind])])
	var all_m: Array = m.surface + m.underground + m.sky
	var all_d: Array = d.surface + d.underground + d.sky
	print("BENCH_%s all meadows_avg_ms=%.2f %s_avg_ms=%.2f" % [label, _avg(all_m), name, _avg(all_d)])
	var list: Array = []
	for az in range(-4, 4):
		for ax in range(-4, 4):
			var t := Time.get_ticks_usec()
			rules.secrets_in_area(Vector2i(ax, az))
			list.append((Time.get_ticks_usec() - t) / 1000.0)
	print("BENCH_%s_SECRET_AREAS areas=%d avg_ms=%.2f worst_ms=%.2f" % [label, list.size(), _avg(list), _worst(list)])


# --- Owner #45b: the wild meadows against the old meadows ------------------------------------------------

## The old meadows, the wild meadows and the wild meadows without their column cache ("cold": every chunk works
## out its own columns) on the same chunks, generated the way a world streams them: a whole stack of chunks per
## chunk column (y -64..159), the three generators alternating chunk by chunk (a busy PC slows all alike). The
## secret areas are placed before the clock starts (placed once per area in a real world, then cached; their cost
## is BENCH_BIOMES_SECRET_AREAS) and the column cache starts empty, so each column's heights and biomes are paid
## once per stack, as in the game. Kinds: underground (y < 0), surface (0..79), sky (80+).
func _bench_biomes() -> void:
	var old := MeadowsGenerator.new()
	old.world_seed = SEED
	var wild := MeadowsBiomeGenerator.new()
	wild.world_seed = SEED
	var cold := MeadowsBiomeGenerator.new()
	cold.world_seed = SEED
	cold.columns_cached = false
	var t_areas := []
	for az in range(-3, 3):
		for ax in range(-3, 3):
			for g: MeadowsGenerator in [old, wild, cold]:
				var t := Time.get_ticks_usec()
				g._secrets.secrets_in_area(Vector2i(ax, az))
				if g == wild:
					t_areas.append((Time.get_ticks_usec() - t) / 1000.0)
	var gens: Array[MeadowsGenerator] = [old, wild, cold]
	var names := ["meadows", "biomes", "biomes_cold"]
	var kinds := ["surface", "underground", "sky"]
	var times := {}
	for name: String in names:
		times[name] = {"surface": [], "underground": [], "sky": []}
	var n := 0
	for cx in range(-6, 6):
		for cz in range(-6, 6):
			for cy in range(-4, 10):
				var origin := Vector3i(cx, cy, cz) * SIZE
				var kind: String = kinds[1] if origin.y + SIZE <= 0 else (kinds[0] if origin.y < 80 else kinds[2])
				for k in 3:
					var i := (n + k) % 3
					((times[names[i]] as Dictionary)[kind] as Array).append(_time(gens[i], origin))
				n += 1
	for kind: String in kinds:
		print("BENCH_BIOMES %s chunks=%d meadows_avg_ms=%.2f biomes_avg_ms=%.2f biomes_cold_avg_ms=%.2f meadows_worst_ms=%.2f biomes_worst_ms=%.2f" % [
			kind, (times.meadows[kind] as Array).size(), _avg(times.meadows[kind]), _avg(times.biomes[kind]),
			_avg(times.biomes_cold[kind]), _worst(times.meadows[kind]), _worst(times.biomes[kind])])
	var all := {}
	for name: String in names:
		all[name] = (times[name].surface as Array) + (times[name].underground as Array) + (times[name].sky as Array)
	print("BENCH_BIOMES all meadows_avg_ms=%.2f biomes_avg_ms=%.2f biomes_cold_avg_ms=%.2f" % [_avg(all.meadows),
		_avg(all.biomes), _avg(all.biomes_cold)])
	print("BENCH_BIOMES_SECRET_AREAS areas=%d avg_ms=%.2f worst_ms=%.2f" % [t_areas.size(), _avg(t_areas), _worst(t_areas)])
	# the places of a new 256 x 256 region (worked out once, then cached; the secrets of its areas already placed)
	var fresh := MeadowsPlaces.new(SEED, wild.wild_shape(), wild._secrets)
	var t_regions := []
	var built := 0
	for rz in range(-4, 4):
		for rx in range(-4, 4):
			for az in range(rz * 2 - 1, rz * 2 + 3):
				for ax in range(rx * 2 - 1, rx * 2 + 3):
					wild._secrets.secrets_in_area(Vector2i(ax, az))
			var t := Time.get_ticks_usec()
			built += fresh.places_in_region(Vector2i(rx, rz)).size()
			t_regions.append((Time.get_ticks_usec() - t) / 1000.0)
	print("BENCH_BIOMES_PLACE_REGIONS regions=%d places=%d avg_ms=%.2f worst_ms=%.2f" % [t_regions.size(), built,
		_avg(t_regions), _worst(t_regions)])


# --- Spec §26: prospecting's deposits ---

## Whole chunk stacks (y -64 … 95) over each of a terrain's three nearest deposits, deposits on and off alternating
## chunk by chunk (the regions' deposits placed first and every chunk made once before it is timed, so this is the
## per-chunk cost of writing them); then the one-time cost of placing a region's deposits.
func _bench_deposits() -> void:
	for which: String in ["meadows", "wild", "desert", "moon", "mars"]:
		var gen: MeadowsGenerator = DesertGenerator.new() if which == "desert" else (
			MeadowsBiomeGenerator.new() if which == "wild" else MeadowsGenerator.new())
		if which in ["moon", "mars"]:   # spec §26.5
			var space := SpaceGenerator.new()
			space.planet = StringName(which)
			gen = space
		gen.world_seed = SEED
		var rules := gen.deposits()
		var on: Array = []
		var off: Array = []
		var n := 0
		for kind in rules.kinds:
			var d := rules.nearest(kind, Vector3(rules.spawn.x, 0, rules.spawn.y), [], 3)
			var key := DepositRules.chunk_key(d.anchor)
			for cz in range(key.z - 1, key.z + 2):
				for cx in range(key.x - 1, key.x + 2):
					for cy in range(-4, 6):
						var origin := Vector3i(cx, cy, cz) * SIZE
						_time(gen, origin)   # warm: a stack's first chunk works out its columns (the wild meadows' cache)
						for pass_on in ([true, false] if n % 2 == 0 else [false, true]):
							gen.deposits_enabled = pass_on
							(on if pass_on else off).append(_time(gen, origin))
						n += 1
		gen.deposits_enabled = true
		print("BENCH_DEPOSITS %s chunks=%d off_avg_ms=%.2f on_avg_ms=%.2f off_worst_ms=%.2f on_worst_ms=%.2f" % [which,
			on.size(), _avg(off), _avg(on), _worst(off), _worst(on)])
		var warm: Array = []
		var cold: Array = []
		for i in 6:
			var shape := gen._shape
			var region := Vector2i(i - 3, 2 + i % 2)
			var secrets: SecretRules = gen._secrets
			var fresh := DepositRules.for_world(SEED, shape, secrets, gen.get(&"places"))
			var t := Time.get_ticks_usec()
			fresh.deposits_in_region(region)
			warm.append((Time.get_ticks_usec() - t) / 1000.0)
			var fresh_secrets: SecretRules = DesertSecretRules.new(SEED, shape) if which == "desert" else SecretRules.new(SEED, shape)
			if shape is SpaceShape:
				fresh_secrets = SpaceSecretRules.new(SEED, shape)
			var fresh_cold := DepositRules.for_world(SEED, shape, fresh_secrets)
			t = Time.get_ticks_usec()
			fresh_cold.deposits_in_region(region + Vector2i(0, 3))
			cold.append((Time.get_ticks_usec() - t) / 1000.0)
		print("BENCH_DEPOSIT_REGIONS %s regions=%d avg_ms=%.2f worst_ms=%.2f cold_avg_ms=%.2f cold_worst_ms=%.2f" % [which,
			warm.size(), _avg(warm), _worst(warm), _avg(cold), _worst(cold)])


# --- Universe 6: the Glow Caves against the Dragon Realm (the brief: "no slower than the Dragon Realm's") -----------

func _bench_glow() -> void:
	var meadows := MeadowsGenerator.new()
	meadows.world_seed = SEED
	var dragon := DragonGenerator.new()
	dragon.world_seed = SEED
	var glow := GlowGenerator.new()
	glow.world_seed = SEED
	var gens := [meadows, dragon, glow]
	var names := ["meadows", "dragon", "glow"]
	var kinds := ["underground", "caves", "sky"]
	var t := {}
	for g in names:
		t[g] = {"underground": [], "caves": [], "sky": []}
	var n := 0
	for rep in 2:                       # the second round: stacks and secret areas cached, like a playing world
		for cx in range(-4, 4):
			for cz in range(-4, 4):
				for cy in range(-4, 6):
					var origin := Vector3i(cx, cy, cz) * SIZE
					var kind: String = kinds[0] if origin.y + SIZE <= 0 else (kinds[1] if origin.y < 80 else kinds[2])
					var order := [0, 1, 2]
					for k in n % 3:
						order.push_back(order.pop_front())
					n += 1
					for i: int in order:
						var ms := _time(gens[i], origin)
						if rep == 1:
							(t[names[i]][kind] as Array).append(ms)
	for kind: String in kinds:
		print("BENCH_GLOW %s chunks=%d meadows_avg_ms=%.2f dragon_avg_ms=%.2f glow_avg_ms=%.2f dragon_worst_ms=%.2f glow_worst_ms=%.2f" % [
			kind, (t.glow[kind] as Array).size(), _avg(t.meadows[kind]), _avg(t.dragon[kind]), _avg(t.glow[kind]),
			_worst(t.dragon[kind]), _worst(t.glow[kind])])
	var all := {}
	for g in names:
		all[g] = (t[g].underground as Array) + (t[g].caves as Array) + (t[g].sky as Array)
	print("BENCH_GLOW all meadows_avg_ms=%.2f dragon_avg_ms=%.2f glow_avg_ms=%.2f" % [_avg(all.meadows), _avg(all.dragon), _avg(all.glow)])
	# cold: fresh generators, whole stacks as a world streams them, the two universes alternating stack by stack
	var cold := {"dragon": [], "glow": []}
	var cold_d := DragonGenerator.new()
	cold_d.world_seed = SEED + 1
	var cold_g := GlowGenerator.new()
	cold_g.world_seed = SEED + 1
	var m := 0
	for cx in range(6, 10):
		for cz in range(-2, 2):
			var pair := [["dragon", cold_d], ["glow", cold_g]] if m % 2 == 0 else [["glow", cold_g], ["dragon", cold_d]]
			m += 1
			for p: Array in pair:
				var total := 0.0
				for cy in range(-4, 7):
					total += _time(p[1], Vector3i(cx, cy, cz) * SIZE)
				(cold[p[0]] as Array).append(total / 11.0)
	print("BENCH_GLOW_COLD stacks=%d dragon_avg_ms=%.2f glow_avg_ms=%.2f dragon_worst_ms=%.2f glow_worst_ms=%.2f" % [
		(cold.glow as Array).size(), _avg(cold.dragon), _avg(cold.glow), _worst(cold.dragon), _worst(cold.glow)])
	var areas := {"dragon": [], "glow": []}
	var rules := {"dragon": DragonSecretRules.new(SEED), "glow": GlowSecretRules.new(SEED)}
	for az in range(-4, 4):
		for ax in range(-4, 4):
			for g: String in ["dragon", "glow"]:
				var t0 := Time.get_ticks_usec()
				(rules[g] as SecretRules).secrets_in_area(Vector2i(ax, az))
				(areas[g] as Array).append((Time.get_ticks_usec() - t0) / 1000.0)
	print("BENCH_GLOW_SECRET_AREAS areas=%d dragon_avg_ms=%.2f glow_avg_ms=%.2f dragon_worst_ms=%.2f glow_worst_ms=%.2f" % [
		(areas.glow as Array).size(), _avg(areas.dragon), _avg(areas.glow), _worst(areas.dragon), _worst(areas.glow)])
