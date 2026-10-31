class_name QuestBook
extends QuestOverlay
## The quest book (owner #45a, spec §14.17), MORE → QUESTS: a picture page with the story being followed (its
## steps as pictures, the one being done with its words and "1/3", ARROW to show the way, STOP FOR NOW), the
## stories waiting (GO ON), the shared story in co-op (PLAY TOGETHER, for the host), the quest givers and how
## many of their stories are done, and the pages of keepsakes and places. Nothing expires, nothing counts
## down, nothing nags: a story waits as long as it likes.

const MAIN := &"main"
const KEEPSAKES := &"keepsakes"
const PLACES := &"places"
const KEEPSAKE_TILE := Vector2(176, 140)
## Keepsakes a row, and rows shown before the page scrolls (Nell's two made 11: a third row of five was too tall).
const KEEPSAKE_COLUMNS := 6
const KEEPSAKE_ROWS := 2

var director: QuestDirector
var page: StringName = MAIN
## What the read-aloud button says on this page.
var spoken := ""


func open() -> void:
	show_page(MAIN)
	show_overlay()


func show_page(which: StringName) -> void:
	page = which
	clear()
	spoken = ""
	match which:
		KEEPSAKES:
			_keepsakes()
		PLACES:
			_places()
		_:
			_main()


func _title(text: String) -> void:
	var r := row(16)
	r.add_child(ProgressPicture.new(&"scroll", 56))
	r.add_child(words(text, 38, 0.0, GOLD))
	r.add_child(ReadAloud.button(func() -> String: return spoken, 60.0))
	content.add_child(r)


func _main() -> void:
	var d := director.data()
	_title("Quest book")
	if not director.team_view.is_empty() and not director.is_host.call():
		_shared_story()
	var id := d.quests.active
	if id != &"":
		_story(d, id)
	elif director.team_view.is_empty():
		var hint := "No story yet! Look for a friend with a ! over their head."
		content.add_child(words(hint, 26, box_width - 60.0))
		spoken = hint
	_waiting_list(d)
	_givers(d)
	var bottom := row()
	var ks := button("KEEPSAKES", UiKit.ORANGE, Vector2(270, 80), "Keepsakes")
	ks.pressed.connect(show_page.bind(KEEPSAKES))
	bottom.add_child(ks)
	var pl := button("PLACES", UiKit.BLUE, Vector2(240, 80), "Places")
	pl.pressed.connect(show_page.bind(PLACES))
	bottom.add_child(pl)
	var back := button("CLOSE", Color(), Vector2(220, 80), "Close")
	back.pressed.connect(close)
	bottom.add_child(back)
	content.add_child(bottom)


## The story being followed: the giver, the title, the steps, the step being done and its buttons.
func _story(d: ProgressData, id: StringName) -> void:
	var c := QuestRules.chain(id)
	var g := QuestRules.giver(c.giver)
	var head := row(14)
	head.add_child(ProgressPicture.new(g.picture, 64))
	head.add_child(words("%s: %s" % [str(g.name), str(c.title)], 30))
	content.add_child(head)
	var steps := QuestRules.steps_of(id)
	var at := QuestRules.step_index(d, id)
	var tiles := row(10)
	for i in steps.size():
		var t := step_tile(steps[i], at > i, at == i, 72.0)
		t.name = "Step%d" % i
		tiles.add_child(t)
	content.add_child(tiles)
	var s := QuestRules.current_step(d, id)
	var here := QuestRules.universe_of(id) == director.universe
	var line := str(s.get("words", ""))
	if s.get("type", &"") == QuestRules.DO:
		var p := QuestRules.step_progress(d, id)
		line += "  %d/%d" % [p.x, p.y]
	if not here:
		line += "  (%s)" % QuestRules.in_universe(QuestRules.universe_of(id))
	var now := words(line, 28, box_width - 60.0, GOLD)
	now.name = "StepWords"
	content.add_child(now)
	spoken = "%s. %s" % [str(c.title), str(s.get("words", ""))]
	var buttons := row()
	if here:
		var arrow := button("ARROW: ON" if director.arrow_on else "ARROW: OFF", UiKit.GREEN if director.arrow_on else Color(),
			Vector2(270, 76), "Arrow")
		arrow.pressed.connect(func() -> void:
			director.set_arrow(not director.arrow_on)
			show_page(MAIN))
		buttons.add_child(arrow)
	var stop := button("STOP FOR NOW", Color(), Vector2(300, 76), "Stop")
	stop.pressed.connect(func() -> void:
		director.stop_chain()
		show_page(MAIN))
	buttons.add_child(stop)
	if director.is_host.call() and not director.others.call().is_empty() and here:
		var together := button("PLAY ALONE" if director.is_sharing() else "PLAY TOGETHER", UiKit.BLUE, Vector2(320, 76), "Together")
		together.pressed.connect(func() -> void:
			director.share(not director.is_sharing())
			show_page(MAIN))
		buttons.add_child(together)
	content.add_child(buttons)


## A guest's view of the host's shared story.
func _shared_story() -> void:
	var v := director.team_view
	var id: StringName = v.chain
	var c := QuestRules.chain(id)
	var steps := QuestRules.steps_of(id)
	var i := int(v.step)
	var line := tr("Playing together: %s") % str(c.title)
	if i >= 0 and i < steps.size():
		line += " — %s" % str(steps[i].words)
		if steps[i].type == QuestRules.DO:
			line += "  %d/%d" % [int(v.have), int(v.need)]
	var l := words(line, 26, box_width - 60.0, Color("b3e5fc"))
	l.name = "Shared"
	content.add_child(l)
	spoken = line


## Stories started and waiting where they were.
func _waiting_list(d: ProgressData) -> void:
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 6)
	for id: String in d.quests.chains:
		if StringName(id) == d.quests.active:
			continue
		var cid := StringName(id)
		var c := QuestRules.chain(cid)
		var r := row(14)
		r.name = "Waiting_%s" % id
		r.add_child(ProgressPicture.new(c.picture, 52))
		r.add_child(words(tr("%s (step %d of %d)") % [str(c.title), QuestRules.step_index(d, cid) + 1,
			QuestRules.steps_of(cid).size()], 24))
		if QuestRules.universe_of(cid) == director.universe and QuestRules.allowed_in(cid, director.mode):
			var go := button("GO ON", UiKit.GREEN, Vector2(200, 64), "GoOn")
			go.pressed.connect(func() -> void:
				director.resume_chain(cid)
				show_page(MAIN))
			r.add_child(go)
		else:
			r.add_child(words(QuestRules.in_universe(QuestRules.universe_of(cid)), 22, 0.0, HINT))
		list.add_child(r)
	if list.get_child_count() > 0:
		content.add_child(words("Stories waiting for you:", 24, 0.0, HINT))
		var scroll := ScrollContainer.new()
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		scroll.custom_minimum_size = Vector2(box_width - 40.0, mini(list.get_child_count(), 2) * 70)
		scroll.add_child(list)
		content.add_child(scroll)
	else:
		list.free()


## The givers, each with how many of its stories are done.
func _givers(d: ProgressData) -> void:
	var r := row(26)
	for gid: StringName in QuestRules.GIVERS:
		var g := QuestRules.giver(gid)
		var all := QuestRules.chains_of(gid)
		var done := all.filter(func(id: StringName) -> bool: return QuestRules.is_done(d, id)).size()
		var v := VBoxContainer.new()
		v.name = "Giver_%s" % gid
		v.add_theme_constant_override("separation", 0)
		v.add_child(ProgressPicture.new(g.picture, 64))
		v.add_child(words("%s %d/%d" % [str(g.name), done, all.size()], 20))
		r.add_child(v)
	content.add_child(r)


func _keepsakes() -> void:
	var d := director.data()
	_title("Keepsakes")
	var have := QuestRules.keepsakes(d)
	var grid := GridContainer.new()
	grid.columns = KEEPSAKE_COLUMNS
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	for c: Dictionary in QuestRules.CHAINS:
		var k: Dictionary = c.keepsake
		var got := have.has(k.id)
		var tile := PanelContainer.new()
		tile.name = "Keepsake_%s" % k.id
		tile.custom_minimum_size = KEEPSAKE_TILE
		tile.add_theme_stylebox_override("panel", UiKit.box(Color(0.35, 0.27, 0.14, 0.95) if got else Color(0.2, 0.16, 0.12, 0.9), 16, 6))
		var v := VBoxContainer.new()
		v.alignment = BoxContainer.ALIGNMENT_CENTER
		var pic := ProgressPicture.new(k.picture, 70)
		pic.dim = not got
		v.add_child(pic)
		v.add_child(words(str(k.words) if got else tr("Ask %s") % str(QuestRules.giver(c.giver).name), 18, KEEPSAKE_TILE.x - 16))
		tile.add_child(v)
		grid.add_child(tile)
	var count := words(tr("%d of %d keepsakes") % [have.size(), QuestRules.CHAINS.size()], 24)
	count.name = "Count"
	content.add_child(count)
	spoken = count.text
	# Two rows show; more keepsakes (more stories to come) scroll with a finger, the page never grows off the screen.
	var shelf := ScrollContainer.new()
	shelf.name = "KeepsakeShelf"
	shelf.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var rows := ceili(QuestRules.CHAINS.size() / float(KEEPSAKE_COLUMNS))
	shelf.custom_minimum_size = Vector2(KEEPSAKE_COLUMNS * (KEEPSAKE_TILE.x + 8), mini(rows, KEEPSAKE_ROWS) * (KEEPSAKE_TILE.y + 8))
	shelf.add_child(grid)
	content.add_child(shelf)
	var bottom := row()
	var back := button("BACK", Color(), Vector2(260, 80), "Back")
	back.pressed.connect(show_page.bind(MAIN))
	bottom.add_child(back)
	content.add_child(bottom)


## The places the stories led to: in this world the arrow can show the way back.
func _places() -> void:
	var d := director.data()
	_title("Places you found")
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 6)
	for p: Dictionary in d.quests.places:
		var c := QuestRules.chain(StringName(str(p.chain)))
		var r := row(14)
		r.name = "Place_%s" % p.chain
		r.add_child(ProgressPicture.new(c.picture, 52))
		r.add_child(words(str(c.title), 24))
		if int(p.seed) == director.world_seed and int(p.u) == director.universe:
			var show := button("SHOW THE WAY", UiKit.GREEN, Vector2(300, 64), "Show")
			show.pressed.connect(func() -> void:
				director.point_to_place(p)
				close())
			r.add_child(show)
		else:
			r.add_child(words(tr("in another world (%s)") % Lang.t(UniverseRegistry.display_name(int(p.u))), 22, 0.0, HINT))
		list.add_child(r)
	if list.get_child_count() == 0:
		list.free()
		var none := words("No places yet. Stories lead to new places!", 26, box_width - 60.0)
		content.add_child(none)
		spoken = none.text
	else:
		var scroll := ScrollContainer.new()
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		scroll.custom_minimum_size = Vector2(box_width - 40.0, mini(list.get_child_count(), 6) * 70)
		scroll.add_child(list)
		content.add_child(scroll)
	var bottom := row()
	var back := button("BACK", Color(), Vector2(260, 80), "Back")
	back.pressed.connect(show_page.bind(MAIN))
	bottom.add_child(back)
	content.add_child(bottom)
