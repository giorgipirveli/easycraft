class_name QuestCard
extends QuestOverlay
## A quest giver's card (owner #45a, spec §14.17), opened by a tap on the giver (QuestDirector.open_card): the
## giver's picture and hello, then what this child can do with them — a new story told in pictures and short
## read-aloud words (LET'S GO / NOT NOW), the story going on (its step), a waiting story (GO ON), or a thank
## you when every story is told. Tilly's card in Survivor also has SHOP (a tap on her stall opens her card
## only when she has something to say). Nothing here counts down or nags.

var director: QuestDirector
var giver_id: StringName = &""
## What the read-aloud button says (the hello and the story).
var spoken := ""


func _init() -> void:
	box_width = 780.0


func open_for(id: StringName) -> void:
	giver_id = id
	show_page()
	show_overlay()


## Fills the card from the child's progress now.
func show_page() -> void:
	clear()
	var d := director.data()
	var g := QuestRules.giver(giver_id)
	var head := row(18)
	head.add_child(ProgressPicture.new(g.get("picture", &"question"), 110))
	var who := VBoxContainer.new()
	who.add_child(words("%s %s" % [str(g.get("name", "")), str(g.get("what", ""))], 34, 0.0, GOLD))
	who.add_child(words(str(g.get("hello", "")), 26, 420.0))
	head.add_child(who)
	spoken = str(g.get("hello", ""))
	head.add_child(ReadAloud.button(func() -> String: return spoken))
	content.add_child(head)
	var active := d.quests.active
	var waiting := _waiting(d)
	var offered := QuestRules.offered(d, giver_id, director.mode)
	var buttons := row()
	if active != &"" and QuestRules.chain(active).giver == giver_id:
		_story(d, active, false)
		buttons.add_child(button("OK!", UiKit.GREEN, Vector2(260, 86), "Ok"))
		(buttons.get_child(-1) as Button).pressed.connect(close)
	elif waiting != &"":
		_story(d, waiting, false)
		content.add_child(words("This story waits for you.", 24, 0.0, HINT))
		var go := button("GO ON", UiKit.GREEN, Vector2(260, 86), "GoOn")
		go.pressed.connect(func() -> void:
			director.resume_chain(waiting)
			close())
		buttons.add_child(go)
		buttons.add_child(_not_now())
	elif offered != &"":
		_story(d, offered, true)
		var go := button("LET'S GO!", UiKit.GREEN, Vector2(300, 86), "LetsGo")
		go.pressed.connect(func() -> void:
			director.start_chain(offered)
			close())
		buttons.add_child(go)
		buttons.add_child(_not_now())
	else:
		_all_told(d)
		buttons.add_child(button("OK!", UiKit.GREEN, Vector2(260, 86), "Ok"))
		(buttons.get_child(-1) as Button).pressed.connect(close)
	if giver_id == &"tilly" and director.mode == ModeRules.SURVIVOR:
		var shop := button("SHOP", UiKit.ORANGE, Vector2(220, 86), "Shop")
		shop.pressed.connect(_shop)
		buttons.add_child(shop)
	content.add_child(buttons)


## A story: its picture and title, its words (a new one), its steps as pictures and the step being done.
func _story(d: ProgressData, id: StringName, new: bool) -> void:
	var c := QuestRules.chain(id)
	var title := row(14)
	title.add_child(ProgressPicture.new(c.picture, 64))
	title.add_child(words(str(c.title), 32))
	content.add_child(title)
	if new:
		content.add_child(words(str(c.story), 26, box_width - 60.0))
		spoken += " " + str(c.story)
	var steps := QuestRules.steps_of(id)
	var at := QuestRules.step_index(d, id)
	var tiles := row(10)
	for i in steps.size():
		tiles.add_child(step_tile(steps[i], at > i, at == i or (new and i == 0), 70.0))
	content.add_child(tiles)
	var s: Dictionary = steps[at] if at >= 0 and at < steps.size() else steps[0]
	content.add_child(words(str(s.words), 26, box_width - 60.0, GOLD if not new else Color.WHITE))
	if not new:
		spoken += " " + str(s.words)
	var rewards := tr("You get: %s") % str(QuestRules.keepsake(id).get("words", "")).to_lower()
	if director.survivor.call():
		rewards += tr(" and %d gold") % QuestRules.gold_for(id)
	content.add_child(words(rewards, 22, 0.0, HINT))


## Every story of this giver is told: a thank you and the keepsakes.
func _all_told(d: ProgressData) -> void:
	var done := 0
	var shelf := row(10)
	for id in QuestRules.chains_of(giver_id):
		if QuestRules.is_done(d, id):
			done += 1
			shelf.add_child(ProgressPicture.new(QuestRules.keepsake(id).picture, 72))
	var line := "Thank you! You helped me with every story." if done == QuestRules.chains_of(giver_id).size() \
		else "My next story is for a Survivor world."
	content.add_child(words(line, 28, box_width - 60.0))
	spoken += " " + line
	if shelf.get_child_count() > 0:
		content.add_child(shelf)


## A story of this giver started and waiting (not the one being followed).
func _waiting(d: ProgressData) -> StringName:
	for id in QuestRules.chains_of(giver_id):
		if QuestRules.is_started(d, id) and d.quests.active != id and QuestRules.allowed_in(id, director.mode):
			return id
	return &""


func _not_now() -> Button:
	var b := button("NOT NOW", Color(), Vector2(240, 86), "NotNow")
	b.pressed.connect(close)
	return b


func _shop() -> void:
	close()
	var stall := director._giver_node(&"tilly") as Trader
	if stall and is_instance_valid(director.hud):
		director.hud.open_shop(stall)
