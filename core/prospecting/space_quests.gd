class_name SpaceQuests
extends RefCounted
## Prospecting quests on the Moon and Mars (spec §26.5, owner #80): Gemma's space camp by each landing tells one per
## resource, 7 steps each like Earth's (ProspectQuests builds the map and MARK IT, and these the middle): a walk the
## compass points along, the sign found up close (a real fact), a problem (sums of real numbers), a clue from real
## geology, and a quiz of School exercises. The lesson is living off the land (in-situ resource use): ice becomes water,
## air and rocket fuel for the trip; dust becomes bricks for the domes; the finds become metal. Every fact is checked
## (sources: docs/devlog/parts/prospecting-space.md) and names no real mission, agency or person (spec §21b.2): "a
## lander", "a rover", "a spacecraft". Friendly: nothing is dangerous or scary; the honest lines stay honest (helium-3
## power is a dream not built yet).

## kind -> {title, story (Gemma's words on the card), map_ask ("direction", "distance", "square")}.
const QUESTS := {
	DepositKinds.MOON_ICE: {"title": "Ice in the dark craters", "map_ask": "direction",
		"story": "Near the Moon's south pole, some craters are so deep that sunlight never reaches their floors. It's icy cold down there. Let's find ice!"},
	DepositKinds.ILMENITE: {"title": "The Moon's dark seas", "map_ask": "square",
		"story": "The Moon's dark patches are seas of old lava, not water! Their rock hides ilmenite: iron, titanium and oxygen. Let's find some."},
	DepositKinds.HELIUM_3: {"title": "The Sun's wind in the dust", "map_ask": "distance",
		"story": "The Sun blows a wind of tiny bits into space. On the Moon it lands in the dust and leaves a rare gas there: helium-3!"},
	DepositKinds.KREEP: {"title": "The rock that clicks", "map_ask": "direction",
		"story": "Giant impacts dug deep into the Moon and threw out a rare rock called KREEP. It holds rare earths: metals for super-strong magnets!"},
	DepositKinds.MOON_METEORITE: {"title": "The falling star's crater", "map_ask": "square",
		"story": "A shooting star that reaches the ground is a meteorite. The Moon has no air to slow them, so they hit hard. Some are made of iron!"},
	DepositKinds.MARS_ICE: {"title": "The ice under the red dust", "map_ask": "direction",
		"story": "Mars looks dry, but ice hides just under its dust! It means drinks, air and rocket fuel for the trip home. Let's find it."},
	DepositKinds.HEMATITE: {"title": "The blueberries of Mars", "map_ask": "square",
		"story": "A rover on Mars found thousands of little grey balls. Scientists called them blueberries! They are hematite, grown in water long ago."},
	DepositKinds.DARK_SAND: {"title": "The magnet and the dark dunes", "map_ask": "distance",
		"story": "Rovers on Mars carried magnets, and Mars dust stuck to them! Some of its dark sand is full of iron grains. Let's find a dune."},
	DepositKinds.MARS_SALT: {"title": "The salt of the old lakes", "map_ask": "square",
		"story": "Long ago, Mars had lakes. When they dried up, they left salt behind. One Mars salt even holds oxygen to breathe!"},
	DepositKinds.MARS_METEORITE: {"title": "The rock that fell from the sky", "map_ask": "distance",
		"story": "In 2005 a rover on Mars bumped into a shiny rock as big as a basketball: an iron meteorite, the first found on another planet!"},
}


static func quest(kind: StringName) -> Dictionary:
	return QUESTS.get(kind, {})


## The quest's steps between the map and MARK IT for `deposit` (roll: the seed's pick of the choices' order).
static func middle(kind: StringName, deposit: Dictionary, roll: int) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	match kind:
		DepositKinds.MOON_ICE:
			out.append(ProspectQuests._reach(0, "Walk to the crater's rim at the X"))
			out.append(ProspectQuests._sign(1, "Climb down and find the frosty dust",
				"In 2009 a spacecraft crashed into a dark crater near the Moon's south pole on purpose. It saw water in the dust it threw up!"))
			out.append(ProspectQuests._problem(ProspectQuests._number("In sunshine the Moon's ground gets as hot as 120 °C. The dark craters' floors stay 230 °C below zero. How many degrees apart is that?",
				"350", "Count up from 230 below zero to zero, then on up to 120.",
				"230 + 120 = 350 degrees! Down there it is so cold that the ice never melts.")))
			out.append(ProspectQuests._clue(ProspectQuests._choice("Why can ice stay on the Moon, where the sunshine is so hot?",
				["It hides where sunlight never reaches", "The Moon is made of ice", "Ice can't melt in space", "The Moon has no Sun"],
				0, roll, "Look at the crater: can sunlight reach its floor?",
				"The Moon is hardly tilted, so near its poles the Sun stays low. Deep craters' floors are always in shadow, and ice stays frozen there.")))
			out.append(ProspectQuests._quiz([
				_order("Put in order: how the Moon's ice becomes rocket fuel.",
					["Dig the icy dust", "Melt it into water", "Split the water with electricity", "Fill the rocket's tanks"],
					"What do you need before you can melt it?",
					"Dig the icy dust, melt it into water, split the water into hydrogen and oxygen, and fill the tanks for the trip home. That's living off the land!"),
				ProspectQuests._number("9 kg of water splits into 1 kg of hydrogen, and the rest is oxygen. How many kg of oxygen is that?", "8",
					"Take the hydrogen away from the water.",
					"9 − 1 = 8 kg of oxygen. Rockets burn the hydrogen with the oxygen: water becomes rocket fuel!"),
				ProspectQuests._truefalse("Water is made of hydrogen and oxygen.", true, "Its name in science letters is H2O.",
					"H2O: two hydrogen atoms and one oxygen atom. That is why water can give air to breathe and rocket fuel."),
			]))
		DepositKinds.ILMENITE:
			out.append(ProspectQuests._reach(0, "Walk to the dark plain at the X"))
			out.append(ProspectQuests._sign(0, "Find the dark dust and its black crystals",
				"The dark seas are lava that flooded giant craters more than 3 billion years ago. Long ago, people thought they were real seas."))
			out.append(ProspectQuests._problem(ProspectQuests._number("Moon rock is about 40% oxygen: 4 kg in every 10 kg. How many kg of oxygen are in 500 kg of Moon rock?",
				"200", "How many lots of 10 kg are in 500 kg? Each lot gives 4 kg.",
				"500 ÷ 10 = 50 lots, and 50 × 4 = 200 kg. Astronauts could breathe oxygen made from Moon rock!")))
			out.append(ProspectQuests._clue(ProspectQuests._choice("Why are the Moon's seas darker than its bright hills?",
				["They are dark lava rock", "They are full of water", "They are always in shadow", "They were burnt"], 0, roll,
				"The seas are old lava plains.",
				"The seas are basalt, dark lava rock rich in iron and titanium. The bright hills are older, paler rock.")))
			out.append(ProspectQuests._quiz([
				ProspectQuests._choice("What is ilmenite made of?",
					["Iron, titanium and oxygen", "Gold, silver and water", "Salt, sugar and sand", "Ice, air and dust"], 0, roll + 1,
					"Two metals and the gas we breathe.",
					"Ilmenite is iron, titanium and oxygen. Heat it with hydrogen and its oxygen comes out as water."),
				ProspectQuests._truefalse("Titanium is strong and light, so planes and rockets are built with it.", true,
					"Strong and light is just what a rocket needs.",
					"Titanium is as strong as steel but much lighter. Planes, rockets and even bicycles use it."),
			]))
		DepositKinds.HELIUM_3:
			out.append(ProspectQuests._reach(0, "Walk to the wide, dark plain at the X"))
			out.append(ProspectQuests._sign(0, "Find the old, dark dust with no craters",
				"Helium-3 sticks best in dark dust full of titanium. The longer the Sun shines on the dust, the more it holds."))
			out.append(ProspectQuests._problem(ProspectQuests._number("The best Moon dust holds about 20 milligrams of helium-3 in every tonne. How many milligrams are in 50 tonnes?",
				"1000", "50 lots of 20.", "50 × 20 = 1,000 mg: just 1 gram from 50 tonnes of dust! That is why helium-3 is so rare.")))
			out.append(ProspectQuests._clue(ProspectQuests._choice("Why does the Moon's dust have helium-3, when Earth's ground has almost none?",
				["Earth's air and magnetism stop the Sun's wind", "The Moon is nearer the Sun", "Helium-3 grows in dust", "Earth is too wet"],
				0, roll, "What wraps round the Earth but not the Moon?",
				"The Sun's wind hits the Moon's bare dust. Earth's magnetic field and air turn it away, so almost none reaches our ground.")))
			out.append(ProspectQuests._quiz([
				ProspectQuests._truefalse("Heating the Moon's dust lets its helium-3 out.", true, "Gases escape from warm dust.",
					"Heated to about 600 °C, the dust gives off most of the gases the Sun's wind left in it, helium-3 too."),
				ProspectQuests._choice("What do scientists dream of using helium-3 for one day?",
					["Clean power from fusion", "Growing plants", "Making bricks", "Painting rockets"], 0, roll + 1,
					"A new kind of power plant.",
					"Scientists dream of fusion power plants that burn helium-3. None works yet, but helium-3 already helps super-cold fridges."),
			]))
		DepositKinds.KREEP:
			out.append(ProspectQuests._reach(0, "Walk to the crater's rim at the X"))
			out.append(ProspectQuests._sign(0, "Find the pale, speckled rock on the rim",
				"KREEP is named for what it holds: K for potassium, REE for rare earth elements and P for phosphorus."))
			out.append(ProspectQuests._problem(ProspectQuests._number("A space probe's counter clicks 3 times a minute over plain Moon rock, and 8 times as often over KREEP rock. How many clicks a minute is that?",
				"24", "8 lots of 3.",
				"3 × 8 = 24 clicks. KREEP gives off a faint glow of invisible rays, far too weak to hurt anyone. A probe mapped them from orbit!")))
			out.append(ProspectQuests._clue(ProspectQuests._choice("How did KREEP rock from deep inside the Moon get up to the top?",
				["A giant impact dug it up and threw it out", "It floated up like a boat", "Astronauts carried it up", "Rain washed it up"],
				0, roll, "Look where it lies: on a crater's rim.",
				"Big impacts dig deep holes and throw the rock from inside out onto their rims and far beyond.")))
			out.append(ProspectQuests._quiz([
				_match("Match KREEP's letters to what they stand for.",
					[["K", "Potassium"], ["REE", "Rare earth elements"], ["P", "Phosphorus"]], roll,
					"K is the chemists' letter for potassium, the one in bananas.",
					"K is potassium, REE the rare earth elements and P phosphorus: KREEP!"),
				ProspectQuests._choice("What do rare earths help make?",
					["Strong magnets for motors", "Bread and cheese", "Window glass", "Rubber boots"], 0, roll + 1,
					"They are in electric motors and headphones.",
					"Rare earths make the strongest magnets, for electric cars' motors, wind turbines and headphones."),
			]))
		DepositKinds.MOON_METEORITE:
			out.append(ProspectQuests._reach(0, "Walk to the small crater at the X"))
			out.append(ProspectQuests._sign(1, "Find the lump of shiny dark iron",
				"Iron meteorites come from the metal hearts of old, broken asteroids. They are mostly iron, with some nickel."))
			out.append(ProspectQuests._problem(ProspectQuests._number("A space rock flies at about 20 km every second. How many km does it fly in one minute?",
				"1200", "A minute is 60 seconds: 60 lots of 20.",
				"60 × 20 = 1,200 km in one minute! Nothing slows it down, because the Moon has no air.")))
			out.append(ProspectQuests._clue(ProspectQuests._choice("Why does the Moon have many more craters than the Earth?",
				["No air to stop rocks, no rain to wear craters", "The Moon is softer", "Space rocks like the Moon", "The Moon is older than the Sun"],
				0, roll, "What happens to shooting stars in Earth's air?",
				"Most space rocks burn up in Earth's air, and wind and rain wear old craters away. The Moon has neither, so its craters last.")))
			out.append(ProspectQuests._quiz([
				ProspectQuests._truefalse("Most shooting stars burn up in Earth's air before they reach the ground.", true,
					"A shooting star is a bright line of light high in the sky.",
					"Rushing into Earth's air squeezes and heats a space rock until it glows and burns away. Only a few big ones land as meteorites."),
				ProspectQuests._number("In the Solar Oven, 1 Iron Meteorite makes 3 Iron. How much Iron do 5 meteorites make?", "15",
					"5 lots of 3.", "5 × 3 = 15 Iron: an iron meteorite is almost pure metal."),
			]))
		DepositKinds.MARS_ICE:
			out.append(ProspectQuests._reach(0, "Walk to the small crater at the X"))
			out.append(ProspectQuests._sign(1, "Find the bright ice in the crater's floor",
				"In 2008 a lander on Mars dug a trench and found white ice just under the soil. The bits it dug up slowly vanished into the air."))
			out.append(ProspectQuests._problem(ProspectQuests._number("An astronaut drinks about 3 litres of water a day. How many litres do 4 astronauts drink in 10 days?",
				"120", "First find one day for all four, then times it by 10.",
				"3 × 4 = 12 litres a day, and 12 × 10 = 120 litres. Carrying that from Earth is heavy: better to melt Mars's ice!")))
			out.append(ProspectQuests._clue(ProspectQuests._choice("Why is the ice on Mars hidden under the dust?",
				["The dust shades it from the Sun", "Mars has no ice at all", "The ice hides from robots", "The dust makes the ice"],
				0, roll, "What happened to the ice the lander dug up?",
				"In Mars's thin air, ice in the sunshine slowly turns straight into gas. Under a blanket of dust it stays frozen.")))
			out.append(ProspectQuests._quiz([
				_order("Put in order: how Mars's ice gives air and rocket fuel.",
					["Dig the ice", "Melt it into water", "Split the water with electricity", "Breathe the oxygen, fly on the hydrogen"],
					"What must you do before you can melt it?",
					"Dig the ice, melt it, split the water into oxygen and hydrogen, then breathe and fly! Making what you need where you are is living off the land."),
				ProspectQuests._choice("Which part of Mars holds the most ice?", ["Its poles", "Its giant volcano", "Its middle", "Its red sky"],
					0, roll + 1, "Think of Earth's coldest places.",
					"Mars's poles have caps of ice. Melted, they would cover all of Mars in water about 20 m deep."),
				ProspectQuests._truefalse("On Mars, rocket builders plan to make rocket fuel from Mars's air and ice.", true,
					"Mars's air is mostly carbon dioxide.",
					"The plan: mix carbon dioxide from the air with hydrogen from the ice to make methane fuel, and keep the oxygen."),
			]))
		DepositKinds.HEMATITE:
			out.append(ProspectQuests._reach(0, "Walk to the plain at the X"))
			out.append(ProspectQuests._sign(0, "Find the little grey balls in the dust",
				"The blueberries grew slowly inside wet rock long ago, a bit like pearls. Wind wore the rock away and left them lying on top."))
			out.append(ProspectQuests._problem(ProspectQuests._number("12 blueberries lie in a row, touching. The row is 48 mm long. How many mm wide is one blueberry?",
				"4", "Share the 48 mm out between the 12 blueberries.", "48 ÷ 12 = 4 mm: about as big as a peppercorn.")))
			out.append(ProspectQuests._clue(ProspectQuests._choice("The blueberries are hematite. What did they tell scientists about Mars long ago?",
				["Water once soaked through its rocks", "It was covered in fruit", "It was always dry", "It had lots of trees"],
				0, roll, "How did the blueberries grow?",
				"Hematite balls like these grow in wet rock. Finding them told scientists that Mars had water long ago.")))
			out.append(ProspectQuests._quiz([
				ProspectQuests._choice("Why is Mars red?", ["Its dust has rust in it", "It is very hot", "It is painted red", "It is on fire"],
					0, roll + 1, "What colour does iron go when it rusts?",
					"Mars's dust holds iron oxide, which is rust! That makes the whole planet look red."),
				ProspectQuests._number("3 Blueberry Soil make 1 Hematite, and 2 Hematite make 1 Iron. How much Blueberry Soil makes 1 Iron?", "6",
					"First find the soil for 2 Hematite.", "2 × 3 = 6 Blueberry Soil for 1 Iron."),
				ProspectQuests._truefalse("Hematite is an iron ore: people mine it on Earth to make iron.", true,
					"Most of the iron ore mined on Earth is hematite or magnetite.",
					"Hematite is iron and oxygen. On Earth it is one of the most mined iron ores."),
			]))
		DepositKinds.DARK_SAND:
			out.append(ProspectQuests._reach(0, "Walk to the crater's rim at the X"))
			out.append(ProspectQuests._sign(1, "Find the dark sand on the crater's floor",
				"Dark sand dunes gather in many of Mars's craters. In 2015 a rover drove right up to moving dunes on Mars!"))
			out.append(ProspectQuests._problem(ProspectQuests._number("In this sand, a magnet picks up 3 of every 4 grains. How many grains does it pick up from 20 grains?",
				"15", "How many lots of 4 are in 20? From each lot it picks 3.",
				"20 ÷ 4 = 5 lots, and 5 × 3 = 15 grains. Those are the grains full of iron!")))
			out.append(ProspectQuests._clue(ProspectQuests._choice("Mars dust stuck to the rovers' magnets. What does that tell us?",
				["The dust has iron in it", "The dust is wet", "The magnets were sticky", "The dust is made of glue"],
				0, roll, "What do magnets pull?",
				"Magnets pull iron. Mars's dust and sand hold iron minerals, like magnetite: that's where the iron comes from!")))
			out.append(ProspectQuests._quiz([
				ProspectQuests._truefalse("Some dust storms on Mars cover the whole planet.", true, "Mars's dust is very fine.",
					"Some storms grow until they wrap all of Mars for weeks. The fine dust even settles on solar panels."),
				ProspectQuests._number("4 Dark Sand make 1 Iron. How much Dark Sand makes 5 Iron?", "20", "5 lots of 4.",
					"5 × 4 = 20 Dark Sand for 5 Iron."),
			]))
		DepositKinds.MARS_SALT:
			out.append(ProspectQuests._reach(0, "Walk to the low, flat ground at the X"))
			out.append(ProspectQuests._sign(0, "Find the pale, cracked salt crust",
				"In 2008 a lander found perchlorate salt in Mars's soil. It isn't good for us, so astronauts would wash the soil before growing food in it."))
			out.append(ProspectQuests._problem(ProspectQuests._number("Perchlorate has 4 oxygen atoms for every 1 chlorine atom. How many oxygen atoms go with 6 chlorine atoms?",
				"24", "6 lots of 4.", "6 × 4 = 24 oxygen atoms. That is why this salt is full of oxygen to breathe!")))
			out.append(ProspectQuests._clue(ProspectQuests._choice("How did a salt crust get onto the flat, low ground here?",
				["A lake dried up and left its salt", "It snowed salt", "A rover spilled it", "Salt grows like grass"],
				0, roll, "What is left when salty water dries up?",
				"Water flowed into the low ground and made a lake. When the water dried up, its salt stayed behind as a crust.")))
			out.append(ProspectQuests._quiz([
				ProspectQuests._truefalse("Salty water stays liquid at colder temperatures than fresh water.", true,
					"Why do people put salt on icy roads?",
					"Salt makes water freeze colder. On Mars, very salty water could stay liquid far below 0 °C."),
				ProspectQuests._choice("What does perchlorate salt give off when it is heated?",
					["Oxygen to breathe", "Chocolate", "Electricity", "Rain"], 0, roll + 1, "Remember its 4 oxygen atoms.",
					"Heated, perchlorate gives off oxygen. Spacecraft carry oxygen candles made with a salt like it, just in case."),
			]))
		DepositKinds.MARS_METEORITE:
			out.append(ProspectQuests._reach(0, "Walk to the plain at the X"))
			out.append(ProspectQuests._sign(0, "Find the dark, shiny iron rock",
				"Mars is dry and cold, so an iron meteorite can lie there for millions of years and rust only a little."))
			out.append(ProspectQuests._problem(ProspectQuests._number("An iron meteorite is about 90% iron and 10% nickel. How many kg of nickel are in a 50 kg meteorite?",
				"5", "10% is 1 kg in every 10 kg.", "50 ÷ 10 = 5 kg of nickel, and the other 45 kg is iron.")))
			out.append(ProspectQuests._clue(ProspectQuests._choice("Where do iron meteorites come from?",
				["The metal hearts of broken asteroids", "Volcanoes on Mars", "Old rockets", "Clouds of iron"],
				0, roll, "Big asteroids once melted, and their heavy metal sank to the middle.",
				"Some big asteroids melted long ago and their iron sank to the middle. When they broke apart, pieces of that metal heart flew off.")))
			out.append(ProspectQuests._quiz([
				ProspectQuests._truefalse("Mars's thin air slows small space rocks a little, so some land in one piece.", true,
					"Mars has air, but much less than Earth.",
					"Mars's thin air slows them a little, and iron is tough, so iron meteorites often land whole."),
				ProspectQuests._number("In the Solar Oven, 1 Iron Meteorite makes 3 Iron. How much Iron do 4 meteorites make?", "12",
					"4 lots of 3.", "4 × 3 = 12 Iron to build with, made on Mars."),
			]))
	return out


## An "order" exercise (the School's) from its steps in the right order: shown mixed up (never in order), `answer` the
## shown steps' indexes in the right order.
static func _order(prompt: String, in_order: Array, hint: String, explain: String) -> Dictionary:
	var n := in_order.size()
	var mix: Array[int] = []
	if n == 4:
		mix.assign([2, 0, 3, 1])
	else:
		for i in n:
			mix.append(n - 1 - i)   # reversed
	var items: Array = []
	for i in n:
		items.append(in_order[mix[i]])
	var answer: Array = []
	for k in n:
		answer.append(mix.find(k))
	return {"type": "order", "prompt": prompt, "items": items, "answer": answer, "hint": hint, "explain": explain}


## A "match" exercise from [left, right] pairs: the right sides shown turned round by the roll (never side by side).
static func _match(prompt: String, pairs: Array, roll: int, hint: String, explain: String) -> Dictionary:
	var n := pairs.size()
	var turn := 1 + absi(roll) % maxi(n - 1, 1)
	var items: Array = []
	var matches: Array = []
	matches.resize(n)
	var answer: Array = []
	for i in n:
		items.append(pairs[i][0])
		var at := (i + turn) % n
		matches[at] = pairs[i][1]
		answer.append(at)
	return {"type": "match", "prompt": prompt, "items": items, "matches": matches, "answer": answer, "hint": hint,
		"explain": explain}
