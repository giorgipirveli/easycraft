class_name CarCard
extends VBoxContainer
## Owner #109 (the learning, the game's heart): a car's card in the garage: DID YOU KNOW? and its checked facts (how an
## engine turns the wheels, four-wheel drive, downforce, buses and electric buses, why big wheels climb, how a hovercraft
## floats, real flying cars; sources in docs/devlog/parts/cars.md). A speaker reads it with its numbers in the game.

const WIDTH := 630.0

var kind: StringName = CarKinds.GO_KART
var heading := Label.new()
var facts := Label.new()
var numbers := Label.new()


func _init(k: StringName = CarKinds.GO_KART) -> void:
	name = "CarCard"
	add_theme_constant_override("separation", 4)
	heading.text = "DID YOU KNOW?"
	heading.add_theme_font_size_override("font_size", 24)
	heading.add_theme_color_override("font_color", Color("ffe14d"))
	add_child(ReadAloud.with_speaker(heading, self, words))
	for l: Label in [facts, numbers]:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size.x = WIDTH
		l.add_theme_font_size_override("font_size", 18)
		add_child(l)
	numbers.add_theme_color_override("font_color", Color("9ad7ff"))
	numbers.visible = false   # the garage shows the numbers beside the picture; the speaker still reads them
	set_kind(k)


func set_kind(k: StringName) -> void:
	kind = k
	var lines: Array[String] = []
	for f: String in CarKinds.facts(k):
		lines.append("•  " + f)
	facts.text = "\n".join(lines)
	numbers.text = "In the game: " + CarKinds.numbers_words(k) + "."


## What the speaker reads: the car's name, then its card and its numbers.
func words() -> String:
	return "%s. %s %s" % [CarKinds.display_name(kind), ReadAloud.words_of(self), numbers.text]
