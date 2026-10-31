class_name LifeRooms
extends RefCounted
## Owner #112: the practice room for an Experience's "room" (LifeExperience): FirstAidRoom (Little Lifesaver),
## PracticeHouse (Fire Escape), MarketRoom (My Money Stall); Life L2: StreetRoom (Safe Streets), KitchenRoom (The
## Kitchen), CalmRoom (Calm Corner). Every room gets the run's `vars` before it is built. Life L3c: OnlineRoom (Online
## City), FindWayRoom (Find Your Way), HomeHelperRoom (Home Helper).

const KINDS: Array[String] = ["first_aid", "practice_house", "market", "street", "kitchen", "calm", "building_site", "water",
	"home_hazards", "earth", "electric", "animals", "medical", "online", "find_way", "home_helper"]


static func make(kind: String, track: String, vars: Dictionary = {}) -> LifeRoom:
	var room: LifeRoom
	match kind:
		"first_aid":
			room = FirstAidRoom.new(track)
		"practice_house":
			room = PracticeHouse.new(track)
		"market":
			room = MarketRoom.new(track)
		"street":
			room = StreetRoom.new(track)
		"kitchen":
			room = KitchenRoom.new(track)
		"calm":
			room = CalmRoom.new(track)
		"building_site":   # owner #116: Real Builder (round 4b)
			room = RealBuilderSite.new(track)
		"water":   # owner #118, Life L3a: Water Safety
			room = WaterRoom.new(track)
		"home_hazards":   # owner #118, Life L3a: The Poisons Cupboard
			room = PoisonsRoom.new(track)
		"earth":   # owner #118, Life L3a: Earth and Weather
			room = EarthRoom.new(track)
		"electric":   # owner #118, Life L3b: Electricity Safety
			room = ElectricRoom.new(track)
		"animals":   # owner #118, Life L3b: Safe with Animals
			room = AnimalsRoom.new(track)
		"medical":   # owner #118, Life L3b: Medical Emergencies
			room = MedicalRoom.new(track)
		"online":   # owner #112, Life L3c: Online City
			room = OnlineRoom.new(track)
		"find_way":   # owner #112, #118, Life L3c: Find Your Way
			room = FindWayRoom.new(track)
		"home_helper":   # owner #112, Life L3c: Home Helper
			room = HomeHelperRoom.new(track)
		_:
			room = SuccessExperiences.room(kind, track)   # owner #115: Success S2's rooms (entities/success)
			if room == null:
				room = LifeRoom.new(track)
	room.vars = vars
	return room
