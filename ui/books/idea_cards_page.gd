class_name IdeaCardsPage
extends VBoxContainer
## Idea cards in the book (M3 Task 21b; research X5): one big picture card at a time with a build idea ("A house
## for your dog"); ◀ ▶ flip through them, round and round. Just for ideas: nothing to win, nothing timed.

const CARD := Vector2(760, 330)
const PICTURE := 150.0

var index := 0
var title := BookKit.label("Build ideas", 34, BookKit.TITLE_INK)
var count_label := BookKit.label("", 24, BookKit.SOFT_INK)
var prev_button := BookKit.button("", BookKit.PAGE_BUTTON)
var next_button := BookKit.button("", BookKit.PAGE_BUTTON)
var words := BookKit.label("", 38, BookKit.TITLE_INK)

var _pictures := HBoxContainer.new()


func _ready() -> void:
	add_theme_constant_override("separation", 12)
	add_child(BookKit.page_row(title, prev_button, next_button, count_label,
		ReadAloud.button(func() -> String: return ReadAloud.words_of(self), 60.0)))   # M3 Task 21a's speaker
	prev_button.pressed.connect(flip.bind(-1))
	next_button.pressed.connect(flip.bind(1))
	var card := PanelContainer.new()
	card.custom_minimum_size = CARD
	card.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var paper := BookKit.card_box(Color("fffaf0"), 18)
	paper.border_color = Color("e0b85a")
	paper.set_border_width_all(6)
	card.add_theme_stylebox_override("panel", paper)
	add_child(card)
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 18)
	card.add_child(v)
	_pictures.alignment = BoxContainer.ALIGNMENT_CENTER
	_pictures.add_theme_constant_override("separation", 30)
	v.add_child(_pictures)
	words.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	words.custom_minimum_size.x = CARD.x - 60
	v.add_child(words)
	show_card(index)


func flip(step: int) -> void:
	Audio.play(&"ui_click")
	show_card(IdeaCards.flip(index, step))


func show_card(i: int) -> void:
	index = posmod(i, IdeaCards.count())
	var c := IdeaCards.card(index)
	for p in _pictures.get_children():
		_pictures.remove_child(p)
		p.queue_free()
	for p: Variant in c.pictures:
		_pictures.add_child(BookKit.picture(p, PICTURE))
	words.text = str(c.words)
	count_label.text = "%d / %d" % [index + 1, IdeaCards.count()]


## Nothing to fill: the cards are the same for everyone (the book calls it like the other pages).
func refresh() -> void:
	show_card(index)
