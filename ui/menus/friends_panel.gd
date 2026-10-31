class_name FriendsPanel
extends VBoxContainer
## The pause menu's FRIENDS page (M2 Task 15, owner feedback #18): the bot friends playing in this
## world, each with its colour, name and personality and a BYE button, and three big buttons to add
## a builder, an explorer or a fighter (up to BotRules.MAX_BOTS). Host and solo only: a LAN guest's
## pause menu has no FRIENDS row (the host's game simulates the friends).

signal closed
## M3 Task 7: a friend will race a course (the pause menu closes, so the child can step on START).
signal raced

const ADD_BUTTONS := {BotRules.BUILDER: ["AddBuilder", "+ BUILDER", UiKit.BLUE],
	BotRules.EXPLORER: ["AddExplorer", "+ EXPLORER", UiKit.GREEN],
	BotRules.FIGHTER: ["AddFighter", "+ FIGHTER", UiKit.RED]}

var director: BotDirector

var _rows := VBoxContainer.new()
var _adds := {}                   # personality -> Button


func _ready() -> void:
	add_theme_constant_override("separation", 16)
	add_child(UiKit.title("Bot friends"))
	var hint := Label.new()
	hint.text = tr("Bots play with you. Up to %d.") % BotRules.MAX_BOTS
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 26)
	add_child(hint)
	_hint = hint
	_rows.add_theme_constant_override("separation", 10)
	add_child(_rows)
	var add_row := HBoxContainer.new()
	add_row.add_theme_constant_override("separation", 14)
	add_row.alignment = BoxContainer.ALIGNMENT_CENTER
	for p: StringName in BotRules.PERSONALITIES:
		var spec: Array = ADD_BUTTONS[p]
		var b := UiKit.big_button(spec[1], spec[2], Vector2(250, 84))
		b.name = spec[0]
		b.pressed.connect(_add.bind(p))
		add_row.add_child(b)
		_adds[p] = b
	add_child(add_row)
	var back := UiKit.big_button("BACK", Color(), Vector2(250, 80))
	back.name = "Back"
	back.pressed.connect(func() -> void: closed.emit())
	add_child(_games_row(back))   # M4 H: GAMES beside BACK
	if director:
		# Deferred: a BYE tap must not free its own row while the button is still handling the tap.
		director.changed.connect(_refresh, CONNECT_DEFERRED)
	_refresh()


func _add(personality: StringName) -> void:
	if director:
		director.add(personality)
	_refresh()


func _refresh() -> void:
	for c in _rows.get_children():
		_rows.remove_child(c)
		c.queue_free()
	var bots: Array[BotFriend] = director.bots() if director else [] as Array[BotFriend]
	if bots.is_empty():
		var none := Label.new()
		none.text = "No friends yet. Add one!"
		none.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_rows.add_child(none)
	for bot in bots:
		_rows.add_child(_row(bot))
	var full := director == null or not director.can_add()
	for b: Button in _adds.values():
		b.disabled = full


func _row(bot: BotFriend) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	var swatch := ColorRect.new()
	swatch.color = BotRules.LOOKS[bot.look].torso
	swatch.custom_minimum_size = Vector2(48, 48)
	swatch.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(swatch)
	var label := Label.new()
	label.text = tr("%s  (%s bot)") % [bot.bot_name, tr(bot.personality)]
	label.custom_minimum_size = Vector2(420, 0)
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(label)
	row.add_child(_race_button(bot))   # M3 Task 7
	var bye := UiKit.big_button("BYE", UiKit.ORANGE, Vector2(150, 72))
	var bot_name := bot.bot_name
	bye.name = "Bye%s" % bot_name
	bye.pressed.connect(func() -> void:
		if director:
			director.remove(bot_name))   # the rows are redrawn on the director's `changed`
	row.add_child(bye)
	return row

# --- M3 Task 7: RACE ME! ---------------------------------------------------------------------------------

var _hint: Label


## A friend's RACE ME!: it races the best run of the course nearest the player (BotDirector.race); the menu
## closes so the child can step on START. When there is no course yet, the hint line says why.
func _race_button(bot: BotFriend) -> Button:
	var b := UiKit.big_button("RACE ME!", UiKit.GREEN, Vector2(190, 72))
	var bot_name := bot.bot_name
	b.name = "Race%s" % bot_name
	b.pressed.connect(func() -> void:
		var why := director.race(bot_name) if director else CourseDirector.NO_COURSE
		if why == "":
			raced.emit()
		elif _hint:
			_hint.text = why)
	return b

# --- M4 H: the GAMES section (hide-and-seek, Storm Run) ---

var _games_page: GamesPanel


## GAMES and BACK side by side (the panel keeps its height on the 720 px screen).
func _games_row(back: Button) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	var games := UiKit.big_button("GAMES", UiKit.GREEN, Vector2(250, 80))
	games.name = "Games"
	games.pressed.connect(show_games)
	row.add_child(games)
	row.add_child(back)
	return row


## The GAMES page in this panel's place; its BACK comes back to the friends.
func show_games() -> void:
	if _games_page:
		return
	for c in get_children():
		(c as Control).visible = false
	_games_page = GamesPanel.new()
	_games_page.name = "GamesPage"
	_games_page.closed.connect(_hide_games, CONNECT_DEFERRED)
	add_child(_games_page)


func _hide_games() -> void:
	if _games_page == null:
		return
	remove_child(_games_page)
	_games_page.queue_free()
	_games_page = null
	for c in get_children():
		(c as Control).visible = true
