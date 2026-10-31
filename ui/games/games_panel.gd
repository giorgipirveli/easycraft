class_name GamesPanel
extends VBoxContainer
## The GAMES page (M4 Wave 3, agent H; spec §17.5), opened from the pause menu's FRIENDS panel: two game
## cards — HIDE & SEEK (who seeks first: RANDOM, or anyone playing here, bots marked as bots) and STORM
## RUN (the world's best) — each with PLAY; the child's stickers; END GAME while a round is on; BACK.
## PLAY asks the host (Session.games_request_start: it checks everything) and closes the pause menu so
## the round can begin.

signal closed
signal started(kind: StringName)

const CARD := Vector2(380, 0)
const WORD := 22

var director: GamesDirector

var seeker_button := UiKit.big_button("SEEKER: RANDOM", Color(), Vector2(340, 72))
var hide_play := UiKit.big_button("PLAY", UiKit.GREEN, Vector2(340, 84))
var storm_play := UiKit.big_button("PLAY", UiKit.GREEN, Vector2(340, 84))
var end_button := UiKit.big_button("END GAME", UiKit.ORANGE, Vector2(300, 80))
var back_button := UiKit.big_button("BACK", Color(), Vector2(300, 80))
var best_label := Label.new()
var stickers_label := Label.new()
var on_label := Label.new()

var _seekers: Array[String] = [""]   # "" = random, then participants' keys
var _names := {}
var _pick := 0


func _ready() -> void:
	if director == null and is_inside_tree():
		director = get_tree().get_first_node_in_group(&"games_director") as GamesDirector
	add_theme_constant_override("separation", 14)
	add_child(UiKit.title("Games"))
	var cards := HBoxContainer.new()
	cards.add_theme_constant_override("separation", 16)
	cards.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(cards)
	seeker_button.name = "Seeker"
	seeker_button.add_theme_font_size_override("font_size", WORD)
	seeker_button.pressed.connect(_next_seeker)
	hide_play.name = "PlayHideSeek"
	hide_play.pressed.connect(_play.bind(GameRules.HIDE_SEEK))
	cards.add_child(_card("Hide & Seek", "One seeks, everyone else hides!", [seeker_button, hide_play]))
	best_label.name = "Best"
	storm_play.name = "PlayStorm"
	storm_play.pressed.connect(_play.bind(GameRules.STORM_RUN))
	cards.add_child(_card("Storm Run", "Grab stars together in the shrinking circle!", [best_label, storm_play]))
	for l: Label in [stickers_label, on_label]:
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.add_theme_font_size_override("font_size", WORD)
		add_child(l)
	stickers_label.name = "Stickers"
	on_label.name = "GameOn"
	on_label.text = "A game is on!"
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	end_button.name = "EndGame"
	end_button.pressed.connect(_end)
	back_button.name = "GamesBack"
	back_button.pressed.connect(func() -> void: closed.emit())
	row.add_child(end_button)
	row.add_child(back_button)
	add_child(row)
	refresh()


func _card(title: String, hint: String, rows: Array) -> PanelContainer:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UiKit.box(Color(0.14, 0.17, 0.27, 0.95), 18, 16))
	card.custom_minimum_size = CARD
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	card.add_child(v)
	var t := Label.new()
	t.text = title
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_theme_font_size_override("font_size", 30)
	v.add_child(t)
	var h := Label.new()
	h.text = hint
	h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	h.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	h.custom_minimum_size = Vector2(CARD.x - 32, 0)
	h.add_theme_font_size_override("font_size", WORD)
	v.add_child(h)
	for r: Control in rows:
		r.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		if r is Label:
			(r as Label).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			r.add_theme_font_size_override("font_size", WORD)
		v.add_child(r)
	return card


## The world's Storm Run best (M3 Task 19: "1 star", never "1 stars").
static func best_words(best: int) -> String:
	if best <= 0:
		return "No best yet"
	return Lang.t("Best: 1 star") if best == 1 else Lang.t("Best: %d stars") % best


## Who can seek, the world's best, the child's stickers, and whether a round is on.
func refresh() -> void:
	_names = director.participant_names() if director else {}
	_seekers = [""]
	for k: String in _names:
		_seekers.append(k)
	_pick = clampi(_pick, 0, _seekers.size() - 1)
	_show_seeker()
	var best := director.storm_best if director else 0
	best_label.text = best_words(best)
	var mine: Array[String] = []
	for id: String in GameRules.STICKERS:
		var n := int(Profile.data.stickers.get(id, 0))
		if n > 0:
			mine.append("%s %d" % [GameRules.STICKERS[id], n])
	stickers_label.text = "Your stickers: " + (" · ".join(PackedStringArray(mine)) if not mine.is_empty() else "none yet")
	var on := director != null and director.running()
	on_label.visible = on
	end_button.visible = on
	hide_play.disabled = on or director == null
	storm_play.disabled = on or director == null


func seeker_choice() -> String:
	return _seekers[_pick]


func _next_seeker() -> void:
	_pick = (_pick + 1) % _seekers.size()
	_show_seeker()


func _show_seeker() -> void:
	var k := _seekers[_pick]
	seeker_button.text = "SEEKER: RANDOM" if k == "" else tr("SEEKER: %s") % str(_names.get(k, "?"))


func _play(kind: StringName) -> void:
	Session.games_request_start(kind, seeker_choice() if kind == GameRules.HIDE_SEEK else "")
	started.emit(kind)
	var menu := _pause_menu()
	if menu:
		menu.close()   # the round begins in the world


func _end() -> void:
	Session.games_request_stop()
	refresh()


func _pause_menu() -> PauseMenu:
	var n := get_parent()
	while n:
		if n is PauseMenu:
			return n
		n = n.get_parent()
	return null
