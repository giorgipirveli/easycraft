extends GutTest
## Spec §23.1: the rules of each experiment's small scene, as pure models the Lab's views draw (LabModels). Every step
## is a tap; nothing can be failed; each says in a few words what just happened; each is done once the child has seen
## the thing the experiment shows (and never before).

const TANK := {"kind": "tank", "things": [{"thing": "wood", "name": "Wood", "floats": true},
	{"thing": "stone", "name": "Stone", "floats": false}, {"thing": "ice", "name": "Ice", "floats": true}]}
const MAGNET := {"kind": "magnet", "things": [{"thing": "iron", "name": "Iron nail", "magnetic": true},
	{"thing": "wood", "name": "Wood", "magnetic": false}]}
const HEAT := {"kind": "heat", "start": -20, "low": -20, "step": 20, "melt": 0, "boil": 100}
const COLOURS := {"kind": "colours", "paints": ["red", "yellow", "blue"], "lights": ["red", "green", "blue"],
	"paint_goals": ["orange", "green", "brown"], "light_goals": ["yellow", "white"]}
const PLANTS := {"kind": "plants", "days": 2, "pots": [{"name": "Light and water", "light": true, "water": true},
	{"name": "In the dark", "light": false, "water": true}, {"name": "No water", "light": true, "water": false}]}
const CIRCUIT := {"kind": "circuit", "wires": 3, "bulbs": 2}


func test_the_factory_makes_each_kind_and_refuses_the_rest() -> void:
	assert_true(LabModels.make(TANK) is LabTank)
	assert_true(LabModels.make(MAGNET) is LabMagnet)
	assert_true(LabModels.make(HEAT) is LabHeat)
	assert_true(LabModels.make(COLOURS) is LabColours)
	assert_true(LabModels.make(PLANTS) is LabPlants)
	assert_true(LabModels.make(CIRCUIT) is LabCircuit)
	assert_null(LabModels.make({"kind": "volcano"}))
	for s: Dictionary in [TANK, MAGNET, HEAT, COLOURS, PLANTS, CIRCUIT]:
		assert_eq(LabModels.problem(s), "", str(s.kind))
		assert_eq(LabModels.make(s).kind, str(s.kind))
	assert_ne(LabModels.problem({"kind": "tank", "things": [{"thing": "wood", "name": "Wood", "floats": true}]}), "",
		"one thing is no test")
	assert_ne(LabModels.problem({"kind": "tank", "things": [{"thing": "cake", "name": "Cake", "floats": true},
		{"thing": "stone", "name": "Stone", "floats": false}]}), "", "a thing the Lab can't draw")
	assert_ne(LabModels.problem({"kind": "heat", "start": -20, "low": -20, "step": 30, "melt": 0, "boil": 100}), "",
		"the thermometer must land on 0 and 100")
	assert_ne(LabModels.problem({"kind": "colours", "paints": ["red", "blue"], "lights": ["red"],
		"paint_goals": ["orange"], "light_goals": []}), "", "orange needs yellow paint")


func test_the_tank_drops_each_thing_once() -> void:
	var m := LabModels.make(TANK) as LabTank
	assert_false(m.done())
	assert_eq(m.sorted(), [-1, -1, -1] as Array[int])
	m.drop(1)
	assert_true(m.is_dropped(1))
	assert_eq(m.last, "The stone sinks!")
	m.drop(1)
	m.drop(9)
	m.drop(0)
	assert_eq(m.last, "The wood floats!")
	assert_false(m.done())
	m.drop(2)
	assert_true(m.done())
	assert_eq(m.sorted(), [0, 1, 0] as Array[int], "floats is group 0, sinks group 1")


func test_the_magnet_pulls_only_magnetic_things() -> void:
	var m := LabModels.make(MAGNET) as LabMagnet
	m.test(1)
	assert_eq(m.last, "The wood does not stick.")
	assert_false(m.sticks(1))
	m.test(0)
	assert_eq(m.last, "The iron nail jumps and sticks!")
	assert_true(m.sticks(0))
	assert_true(m.done())
	assert_eq(m.sorted(), [0, 1] as Array[int])


func test_heat_melts_boils_and_freezes_with_the_thermometer_still_while_it_changes() -> void:
	var m := LabModels.make(HEAT) as LabHeat
	assert_eq([m.temp, m.ice], [-20, LabHeat.ICE_PARTS])
	m.cool()
	assert_eq(m.temp, -20, "the ice bath is as cold as it goes")
	m.warm()
	assert_eq([m.temp, m.ice], [0, 2], "warmed to 0 °C, still ice")
	m.warm()
	assert_eq([m.temp, m.ice], [0, 1], "melting: 0 °C while it melts")
	assert_string_contains(m.last, "melting")
	m.warm()
	assert_eq([m.temp, m.ice], [0, 0], "all water now, still 0 °C")
	assert_true(m.saw_melt)
	for i in 5:
		m.warm()
	assert_eq(m.temp, 100)
	assert_false(m.boiling)
	m.warm()
	assert_true(m.boiling, "at 100 °C more heat boils it")
	assert_eq(m.temp, 100, "boiling water stays at 100 °C")
	assert_true(m.saw_boil)
	m.warm()
	assert_eq(m.temp, 100)
	assert_false(m.done(), "not cooled again yet")
	m.cool()
	assert_false(m.boiling)
	assert_eq(m.temp, 80)
	for i in 4:
		m.cool()
	assert_eq([m.temp, m.ice], [0, 0])
	m.cool()
	assert_eq([m.temp, m.ice], [0, 1], "freezing at 0 °C")
	m.cool()
	assert_eq([m.temp, m.ice], [0, 2])
	assert_true(m.saw_freeze)
	assert_true(m.done())
	m.cool()
	assert_eq(m.temp, -20)
	assert_eq(LabHeat.degrees(-20), "−20 °C", "the font's minus sign")
	assert_eq(LabHeat.degrees(100), "100 °C")


func test_paint_mixes_by_recipe_and_light_adds() -> void:
	var m := LabModels.make(COLOURS) as LabColours
	m.add_paint("red")
	assert_eq(m.paint_name(), "red")
	assert_true(m.found_paint.is_empty(), "one paint is not a mix")
	m.add_paint("yellow")
	assert_eq(m.paint_name(), "orange")
	assert_true(m.found_paint.has("orange"))
	assert_eq(m.last, "Red and yellow make orange!")
	m.add_paint("red")
	assert_eq(m.paint_name(), "red-orange", "2 red and 1 yellow: red-orange, a tertiary colour (grade 4 art)")
	assert_eq(m.last, "Red and yellow make red-orange!")
	m.add_paint("red")
	assert_eq(m.paint_name(), "", "3 red and 1 yellow: a colour with no name here")
	m.clean()
	assert_eq(m.drops, {})
	for p: String in ["yellow", "blue"]:
		m.add_paint(p)
	assert_true(m.found_paint.has("green"))
	m.add_paint("red")
	assert_true(m.found_paint.has("brown"))
	for i in 20:
		m.add_paint("blue")
	var drops := 0
	for k: String in m.drops:
		drops += int(m.drops[k])
	assert_eq(drops, ColourMix.MAX_DROPS, "the bowl holds so much")
	assert_false(m.done(), "no light yet")
	m.toggle_light(0)
	m.toggle_light(1)
	assert_eq(m.lit_names(), ["red", "green"])
	assert_true(m.found_light.has("yellow"))
	assert_eq(m.last, "Red and green light make yellow!")
	m.toggle_light(2)
	assert_true(m.found_light.has("white"))
	assert_true(m.done())
	m.toggle_light(0)
	assert_eq(m.lit_names(), ["green", "blue"])
	assert_true(m.found_light.has("cyan"))


func test_plants_grow_over_two_game_days() -> void:
	var clock := [5000]
	var m := LabModels.make(PLANTS, func() -> int: return clock[0]) as LabPlants
	assert_eq(m.look(0), LabPlants.EMPTY)
	m.plant(0)
	m.plant(1)
	assert_eq(m.planted_at, 0, "the test starts when every seed is in")
	m.plant(2)
	assert_eq(m.planted_at, 5000)
	assert_eq(m.days(), 0)
	assert_eq([m.look(0), m.look(1), m.look(2)], [LabPlants.SEED, LabPlants.SEED, LabPlants.SEED])
	clock[0] += int(LabPlants.DAY)
	assert_eq(m.days(), 1)
	assert_eq([m.look(0), m.look(1), m.look(2)], [LabPlants.SPROUT, LabPlants.PALE_SPROUT, LabPlants.SEED])
	assert_false(m.done())
	clock[0] += int(LabPlants.DAY)
	assert_eq([m.look(0), m.look(1), m.look(2)], [LabPlants.PLANT, LabPlants.PALE_SHOOT, LabPlants.SEED])
	assert_true(m.done())
	clock[0] += int(10 * LabPlants.DAY)
	assert_eq(m.look(0), LabPlants.PLANT, "no more stages")
	var again := LabModels.make(PLANTS, func() -> int: return clock[0]) as LabPlants
	again.restore(5000)
	assert_true(again.done(), "planted before: the pots come back as they grew")
	assert_eq(LabPlants.DAY, DayCycle.LENGTH, "a game day is one turn of the sun")


func test_the_circuit_lights_in_a_closed_loop_and_two_bulbs_share_it() -> void:
	var m := LabModels.make(CIRCUIT) as LabCircuit
	assert_eq(m.wires, [true, true, true] as Array[bool])
	assert_false(m.lit())
	assert_eq(m.brightness(), 0.0)
	m.toggle_switch()
	assert_true(m.lit())
	assert_eq(m.brightness(), 1.0)
	assert_true(m.saw_lit)
	m.toggle_wire(2)
	assert_false(m.lit())
	assert_true(m.saw_gap)
	assert_string_contains(m.last, "gap")
	m.toggle_wire(2)
	assert_true(m.lit())
	m.add_bulb()
	assert_eq(m.bulbs, 2)
	assert_eq(m.brightness(), 0.25, "two bulbs in series: a quarter of the power each")
	assert_true(m.saw_two)
	assert_true(m.done())
	m.add_bulb()
	assert_eq(m.bulbs, 2, "the board holds two")
	m.remove_bulb()
	assert_eq(m.bulbs, 1)
	m.remove_bulb()
	assert_eq(m.bulbs, 1, "always one bulb")


func test_nothing_is_done_before_it_is_seen() -> void:
	var c := LabModels.make(CIRCUIT) as LabCircuit
	c.add_bulb()
	c.toggle_switch()
	assert_false(c.done(), "lit with two, but no gap seen yet")
	c.toggle_switch()
	assert_true(c.done())
	var h := LabModels.make(HEAT) as LabHeat
	for i in 3:
		h.cool()
	assert_false(h.done())
