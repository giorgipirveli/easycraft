class_name NameSuggester
extends RefCounted
## Friendly random usernames ("BraveFox42") for kids who don't want to type one.

const ADJECTIVES: Array[String] = [
	"Brave", "Happy", "Sunny", "Swift", "Lucky", "Cosmic", "Mighty", "Jolly", "Clever", "Rapid",
	"Bouncy", "Sparky", "Frosty", "Golden", "Silver", "Turbo", "Pixel", "Magic", "Rocket", "Ninja",
]
const NOUNS: Array[String] = [
	"Fox", "Panda", "Tiger", "Dragon", "Otter", "Falcon", "Koala", "Wolf", "Bunny", "Owl",
	"Shark", "Comet", "Robot", "Hopper", "Builder", "Knight", "Wizard", "Penguin", "Dino", "Star",
]


static func suggest(rng: RandomNumberGenerator) -> String:
	for i in 10:
		var name := "%s%s%d" % [ADJECTIVES[rng.randi() % ADJECTIVES.size()], NOUNS[rng.randi() % NOUNS.size()], rng.randi_range(1, 99)]
		if UsernameRules.validate(name) == "":
			return name
	return "Hopper%d" % rng.randi_range(1, 99)
