class_name LabPlantsView
extends LabView
## A fair test: what do plants need? (LabPlants). Three pots on the bench's shelf, each a big button: its name, the sun
## or a dark cupboard, a watering can or a dry cloud, and what grows in it. A tap plants its seed. Then the day's words
## ("Day 1 of 2") and LOOK AGAIN: game days pass while the child plays anywhere (or is away), and the pots show it.

const POT := Vector2(280, 312)

var pot_buttons: Array[Button] = []
var look_button: Button
var day_label: Label
var _pictures: Array[Control] = []


func _init(m: LabModel = null) -> void:
	super(m)
	var p := model as LabPlants
	for i in p.pots.size():
		var b := place_button("", Color(), Vector2(20 + i * (POT.x + 16), 14), POT)
		b.name = "Pot%d" % i
		var pic := PotPicture.new(p, i)
		pic.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		b.add_child(pic)
		var n := LabView._label(str(p.pots[i].name), 22, Color.WHITE)
		n.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
		n.offset_top = 6
		b.add_child(n)
		b.pressed.connect(_plant.bind(i))
		pot_buttons.append(b)
		_pictures.append(pic)
	var x := 20 + p.pots.size() * (POT.x + 16)
	day_label = place_label("", 30, INK, Vector2(x, 36), SIZE.x - x - 16)
	day_label.name = "Day"
	place_label("A game day is one turn of the sun.", 20, SOFT, Vector2(x, 90), SIZE.x - x - 16)
	look_button = place_button("LOOK AGAIN", SchoolUi.TEAL, Vector2(x + 8, 236), Vector2(SIZE.x - x - 32, 80), 24)
	look_button.name = "LookAgain"
	look_button.pressed.connect(_look)
	refresh()


func _plant(i: int) -> void:
	var p := model as LabPlants
	if p.planted[i]:
		return
	p.plant(i)
	Audio.play(&"ui_tick")
	tapped()


func _look() -> void:
	var p := model as LabPlants
	if p.planted_at > 0:
		p.last = "Day %d: " % mini(p.days(), p.days_needed()) + (
			"see what grew!" if p.done() else "the seeds are still growing. Come back after another game day.")
	Audio.play(&"ui_click")
	tapped()


func refresh() -> void:
	var p := model as LabPlants
	day_label.text = p.day_words() if p.planted_at > 0 else "Plant the seeds!"
	look_button.visible = p.planted_at > 0
	for i in pot_buttons.size():
		pot_buttons[i].disabled = p.planted[i]
		_pictures[i].queue_redraw()
	super.refresh()


## One pot's picture: its light (the sun, or a dark cupboard), its water (a watering can, or a dry cloud) and the pot.
class PotPicture:
	extends Control
	var plants: LabPlants
	var index := 0

	func _init(p: LabPlants, i: int) -> void:
		plants = p
		index = i
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var pot: Dictionary = plants.pots[index]
		var w := size.x
		var h := size.y
		var light := bool(pot.get("light", true))
		if not light:   # a dark cupboard, its door open for us to look in
			draw_rect(Rect2(Vector2(w * 0.08, h * 0.16), Vector2(w * 0.84, h * 0.8)), Color("1c2230"))
			draw_rect(Rect2(Vector2(w * 0.02, h * 0.16), Vector2(w * 0.06, h * 0.8)), Color("5a3d24"))
		else:   # the sun
			var sun := Vector2(w * 0.2, h * 0.28)
			draw_circle(sun, w * 0.07, Color("ffd23f"))
			for k in 8:
				var a := TAU * k / 8.0
				draw_line(sun + Vector2(cos(a), sin(a)) * w * 0.09, sun + Vector2(cos(a), sin(a)) * w * 0.13, Color("ffb020"), 3.0)
		var water := bool(pot.get("water", true))
		var can_at := Vector2(w * 0.78, h * 0.3)
		if water:   # a watering can and its drops
			draw_rect(Rect2(can_at + Vector2(-w * 0.07, -h * 0.03), Vector2(w * 0.12, h * 0.08)), Color("3a7be8"))
			draw_line(can_at + Vector2(-w * 0.07, 0), can_at + Vector2(-w * 0.14, -h * 0.05), Color("3a7be8"), 4.0)
			for k in 3:
				draw_circle(can_at + Vector2(-w * 0.15 + k * w * 0.02, h * (0.03 + 0.04 * k)), 3.0, Color("6fb2ff"))
		else:   # a dry cloud: no rain for this one
			for k in 3:
				draw_circle(can_at + Vector2((k - 1) * w * 0.05, 0), w * 0.045, Color("c9ced6"))
			draw_line(can_at + Vector2(-w * 0.09, h * 0.06), can_at + Vector2(w * 0.09, h * 0.06), Color("c9ced6"), 3.0)
		LabArt.pot(self, Rect2(Vector2(w * 0.2, h * 0.42), Vector2(w * 0.6, h * 0.5)), plants.look(index))
		if not plants.planted[index]:
			var font := ThemeDB.fallback_font
			var t := "tap to plant"
			var tw := font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x
			draw_string(font, Vector2((w - tw) * 0.5, h * 0.97), t, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(1, 1, 1, 0.85))
