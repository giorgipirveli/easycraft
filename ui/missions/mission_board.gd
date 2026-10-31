class_name MissionBoard
extends Control
## The Mission Board (spec §21d.1, §21d.3, §21d.5, §25.3): walking up to the board at a Launch Site opens it
## (LaunchDirector). One panel, big buttons, read aloud like the School, three pages:
## - MISSIONS: the missions in the real order people did or plan them (MissionRules, the worlds built here), each card
##   with its planet, where it is, the real trip, one real fact, what its rocket needs, Mission Control's plan (owner
##   #98: its parts and gold) and whether it is on the child's route; CHOOSE picks the mission the rocket is checked
##   for. OPEN THE STAR MAP when a planet is on the route (its LAND works from there, §21d.5).
## - MY ROCKET, the rocket science panel: Mission Control's plan with BUILD IT FOR ME (owner #98: the host builds it on
##   the pad, layer by layer: LaunchDirector.build); RocketCheck of the parts on the pad for the chosen mission: the bar
##   from the ground to the planet, each stage's numbers, green ticks and kind "not yet" lines (each with what real
##   rockets do); buying in one place (owner #98): BUY THE PARTS FOR THIS ROCKET under the Sandbox's paid line,
##   Survivor's BUY THE MISSING PARTS for the plan (into the bag), each asking first on a card ("Buy 33 parts for 470
##   gold?"), too little gold saying exactly how much more; CHECK AGAIN and LAUNCH (grey until every line passes: then it
##   says how many lines to fix and the first one).
## - PARTS, the Launch Site's shop: every part (RocketParts) with its picture, what it does, its numbers, its price and
##   how many the child has; BUY one (the page keeps its place).
## It opens on MY ROCKET when the pad holds rocket parts, else on MISSIONS. Mouse and keys (Esc closes; the buttons
## click) and touch alike. The game goes on behind it (friends build on the pad meanwhile). Per device: its hooks come
## from the sandbox.

signal opened
signal closed

const MISSIONS_PAGE := 0
const ROCKET_PAGE := 1
const PARTS_PAGE := 2
const PANEL_SIZE := Vector2(1180, 650)
const OK_COLOR := Color("5be37a")
const MISS_COLOR := Color("ffb347")
const WHY_COLOR := Color(1, 1, 1, 0.65)
const GOLD_COLOR := Color("ffd23f")

## Owner #98: what the buy buttons buy (ask_buy).
const BUY_ROCKET := &"rocket"   # the Sandbox: the parts of the rocket on the pad not bought yet
const BUY_PLAN := &"plan"       # Survivor: the parts of Mission Control's plan the bag still lacks
const GUEST_BUY_WORDS := "This rocket is your friend's: they buy its parts. Parts you buy on PARTS are for your own rockets."
const CHANGED_WORDS := "Your rocket changed while you looked: "
const ALL_PAID_WORDS := "Every part is paid for!"

## () -> Dictionary: the cells on the pad ({Vector3i relative to its corner, y up: block id}).
var read_rocket: Callable = func() -> Dictionary: return {}
## () -> Variant: the parts this child bought ({id: count}: the Sandbox checks them), or null (Survivor: the bag paid).
var owned: Callable = func() -> Variant: return null
## (id) -> int: how many of a part the child has (the shop's "You have"; Survivor: the bag).
var have: Callable = func(_id: int) -> int: return 0
## () -> int: the child's gold (earned by learning; spent here in every mode).
var gold: Callable = func() -> int: return 0
## (id, n) -> String: buys n of a part ("" = bought, else why not).
var buy: Callable = func(_id: int, _n: int) -> String: return ""
## (rocket: Dictionary) -> String: LAUNCH with the rocket's description (RocketCheck.description; "" = on the way).
var launch: Callable = func(_rocket: Dictionary) -> String: return ""
## () -> Array[int]: the worlds on this child's route (MissionRules.route).
var route: Callable = func() -> Array[int]: return [] as Array[int]
## () -> Array[int]: the space worlds built (UniverseRegistry.space_available).
var available: Callable = func() -> Array[int]: return UniverseRegistry.space_available()
## () -> void: opens the Star Map (invalid: no button).
var star_map := Callable()
## () -> String: why the missions are shut here ("" = open). Owner #78 (spec §21e): in Survivor the rocket must be
## invented first; the board says so when it opens and LAUNCH refuses.
var gate: Callable = func() -> String: return ""
## Astronauts who fly (phase 1: the one who launches).
var crew := 1
## (world) -> Array: this child's crew badges for that mission's world (spec §21d.6 phase 2: CrewBadges' words).
var badges: Callable = func(_world: int) -> Array: return []
## Owner #98: (world, crew) -> String: BUILD IT FOR ME ("" = Mission Control builds the plan on the pad now, else why
## not). Invalid: no button.
var build := Callable()
## Owner #98: () -> int: the astronauts here (1 + friends, up to RocketPlan.MAX_CREW): the plan seats them all.
var crew_here: Callable = func() -> int: return 1
## Owner #98: () -> bool: this pad is a friend's (a guest's game): its rocket's parts are theirs to buy.
var is_guest: Callable = func() -> bool: return false

var page := MISSIONS_PAGE
## The mission the rocket is checked for (MissionRules).
var mission: Dictionary = {}
## The last check (RocketCheck.check).
var result: Dictionary = {}

var close_button: Button
var launch_button: Button
var buy_all_button: Button     # owner #98: MY ROCKET's "BUY THE PARTS FOR THIS ROCKET" (the Sandbox)
var buy_plan_button: Button    # owner #98: MY ROCKET's "BUY THE MISSING PARTS" (Survivor, for the plan)
var build_button: Button       # owner #98: BUILD IT FOR ME
var star_map_button: Button
var gold_label: Label
var bar: RocketBar
## Owner #98: the card that asks before buying ("Buy 33 parts for 470 gold?").
var confirm_card: PanelContainer
var confirm_label: Label
var confirm_yes: Button
var confirm_no: Button

var _panel: PanelContainer
var _tabs: Array[Button] = []
var _message: Label
var _content: VBoxContainer
var _scroll: ScrollContainer
var _keep := Control.new()   # holds the buttons kept across pages while their page is not shown
var _built := false
var _cards := 0
var _stage_labels := 0
var _misses := 0
var _parts := 0
var _pending := {}           # owner #98: what the card asks about: {kind, parts, gold}


func _ready() -> void:
	name = "MissionBoard"
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme = UiKit.theme()


## Opens on the missions (the first one not reached yet is chosen), or on MY ROCKET when the pad holds rocket parts
## (owner #98: a child coming back to check sees their rocket at once).
func open() -> void:
	_build()
	var missions := _missions()
	if mission.is_empty() or not _has(missions, int(mission.world)):
		mission = missions[0] if not missions.is_empty() else MissionRules.MISSIONS[0]
		for m in missions:
			if not on_route(int(m.world)):
				mission = m
				break
	_hide_card()
	_say(str(gate.call()))
	visible = true
	UiMotion.pop_in(self)   # owner #94: every panel pops in the same way
	if PlatformRules.captures_mouse(PlatformRules.current()) and is_inside_tree():
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	show_page(ROCKET_PAGE if pad_has_parts() else MISSIONS_PAGE)
	_fit()
	Audio.play(&"ui_click")
	ReadAloud.auto(words())
	opened.emit()


## Owner #98: opens on MY ROCKET with `text` on the message line (Mission Control built the rocket).
func open_on_rocket(text: String) -> void:
	open()
	if page != ROCKET_PAGE:
		show_page(ROCKET_PAGE)
	_say(text)


func close() -> void:
	if not visible:
		return
	_hide_card()
	visible = false
	closed.emit()


func is_open() -> bool:
	return visible


## Android Back: true when the board was open (now closed; an open card closes first).
func close_if_open() -> bool:
	if not visible:
		return false
	if confirm_card and confirm_card.visible:
		_hide_card()
		return true
	close()
	return true


## The pad holds rocket parts (owner #98: the board opens on MY ROCKET then).
func pad_has_parts() -> bool:
	for id: Variant in (read_rocket.call() as Dictionary).values():
		if RocketParts.is_part(int(id)):
			return true
	return false


func show_page(i: int, keep_place := false) -> void:
	_build()
	var at := _scroll.scroll_vertical
	page = clampi(i, MISSIONS_PAGE, PARTS_PAGE)
	for k in _tabs.size():
		_tabs[k].add_theme_stylebox_override("normal", UiKit.box(UiKit.BLUE if k == page else Color(0.2, 0.26, 0.4)))
	for k: Control in _kept():   # kept across pages
		if k.get_parent() != _keep:
			if k.get_parent():
				k.get_parent().remove_child(k)
			_keep.add_child(k)
	for c in _content.get_children():
		_content.remove_child(c)
		c.queue_free()
	_cards = 0
	_parts = 0
	if page == ROCKET_PAGE or page == PARTS_PAGE:
		check()
	match page:
		MISSIONS_PAGE:
			_missions_page()
		ROCKET_PAGE:
			_rocket_page()
		PARTS_PAGE:
			_parts_page()
	_scroll.scroll_vertical = 0
	if keep_place:   # owner #98 (bug 5): a BUY keeps the page where it was
		_scroll.set_deferred("scroll_vertical", at)
		_restore_scroll.call_deferred(at)
	_update_gold()


## Picks the mission the rocket is checked for, and shows the check.
func choose(world: int) -> void:
	var m := MissionRules.for_world(world)
	if m.is_empty():
		return
	mission = m
	show_page(ROCKET_PAGE)


## Reads the pad and checks the rocket for the chosen mission.
func check() -> Dictionary:
	if mission.is_empty():
		mission = MissionRules.MISSIONS[0]
	result = RocketCheck.check(read_rocket.call(), mission, crew, owned.call())
	return result


func on_route(world: int) -> bool:
	return (route.call() as Array).has(world)


## Buys one part; "" when bought (the message line says why not). The page keeps its place.
func buy_part(id: int) -> String:
	var why: String = buy.call(id, 1)
	_after_buying(why, "+1 %s" % BlockIds.display_name(id))
	return why


## Gold for the parts the rocket on the pad still needs (Sandbox; 0 when none or in Survivor).
func missing_cost() -> int:
	return RocketParts.cost(result.get("missing", {}))


# --- Owner #98: Mission Control's plan, BUILD IT FOR ME, buying in one place ----------------------------------------

## The astronauts the plan is for (1 + the friends here, at most RocketPlan.MAX_CREW).
func plan_crew() -> int:
	return clampi(int(crew_here.call()), 1, RocketPlan.MAX_CREW)


## Mission Control's plan for the chosen mission and the crew here ({} when there is none).
func plan() -> Dictionary:
	return RocketPlan.cells(mission, plan_crew())


## Survivor: the plan's parts the bag still lacks ({id: count}; {} in the Sandbox, where building is free).
func plan_short() -> Dictionary:
	if owned.call() != null:
		return {}
	var p := plan()
	if p.is_empty():
		return {}
	return RocketPlan.bag_short(p, read_rocket.call(), have)


## BUILD IT FOR ME: Mission Control builds its plan on the pad (the board closes so the child watches), or the message
## line says why not ("" when it started).
func press_build() -> String:
	var why := str(gate.call())
	if why == "":
		why = RocketPlan.no_plan_words(mission, plan_crew())
	if why == "" and is_guest.call():
		why = MissionRules.message(MissionRules.GUEST)
	if why == "":
		var short := plan_short()
		if not short.is_empty():
			why = "Your bag needs %s first: BUY THE MISSING PARTS." % RocketParts.list_words(short)
	if why == "" and build.is_valid():
		why = str(build.call(int(mission.world), plan_crew()))
	if why != "":
		_say(why)
		return why
	close()
	return ""


## What a buy button buys now ({id: count}).
func to_buy(kind: StringName) -> Dictionary:
	if kind == BUY_PLAN:
		return plan_short()
	check()
	return (result.get("missing", {}) as Dictionary).duplicate()


## A buy button: too little gold says how much more and where it is earned; enough asks first on the card ("" when the
## card asks, else the words said).
func ask_buy(kind: StringName, said := "") -> String:
	var parts := to_buy(kind)
	if parts.is_empty():
		_hide_card()
		_say(ALL_PAID_WORDS)
		return ALL_PAID_WORDS
	if is_guest.call():   # owner #98 (bug 4): a friend's bulk buy never paid for the pad
		_say(GUEST_BUY_WORDS)
		return GUEST_BUY_WORDS
	var cost := RocketParts.cost(parts)
	var g := int(gold.call())
	if cost > g:
		var w := said + short_words(g, cost)
		_hide_card()
		_say(w)
		return w
	_pending = {"kind": kind, "parts": parts, "gold": cost}
	confirm_label.text = said + buy_question(parts)
	confirm_card.visible = true
	if is_inside_tree():
		confirm_yes.grab_focus.call_deferred()
	ReadAloud.auto(confirm_label.text)
	return ""


## YES on the card: buys the parts it named. Owner #98 (bug 6): if the rocket changed meanwhile, the card asks again
## with the new parts and price instead of charging a price it never showed.
func confirm_buy() -> String:
	if _pending.is_empty():
		return ""
	var kind: StringName = _pending.kind
	var parts := to_buy(kind)
	if parts != _pending.parts:
		return ask_buy(kind, CHANGED_WORDS)
	_hide_card()
	var why := ""
	for id in RocketParts.ORDER:
		if parts.has(id) and why == "":
			why = buy.call(id, int(parts[id]))
	var done := ALL_PAID_WORDS + " LAUNCH when every line is green." if kind == BUY_ROCKET \
		else "Into your bag! Now press BUILD IT FOR ME."
	_after_buying(why, done)
	return why


## NO on the card.
func cancel_buy() -> void:
	_hide_card()


## "Buy 33 parts for 470 gold? 8 rocket engines, 10 fuel tanks …"
static func buy_question(parts: Dictionary) -> String:
	var n := RocketParts.total(parts)
	return "Buy %s for %d gold? %s." % ["1 part" if n == 1 else "%d parts" % n, RocketParts.cost(parts),
		_capital(RocketParts.list_words(parts))]


## "You have 120 gold: 350 more to go. A School unit mastered gives 100 gold."
static func short_words(have_gold: int, cost: int) -> String:
	return "You have %d gold: %d more to go. A School unit mastered gives %d gold." % [have_gold, cost - have_gold,
		EarnRules.UNIT_GOLD]


## LAUNCH would fly now (every line passes).
func launch_ready() -> bool:
	return bool(result.get("ok", false))


## LAUNCH: the rocket flies (the board closes) or the line says why not (owner #98: how many lines and the first one).
func press_launch() -> String:
	var shut := str(gate.call())
	if shut != "":
		_say(shut)
		return shut
	check()
	if not launch_ready():
		var why := not_yet_words()
		_say(why)
		return why
	var why: String = launch.call(RocketCheck.description(result, int(mission.world)))
	if why != "":
		_say(why)
		return why
	close()
	return ""


## "Not yet: 2 lines to fix. First: Fins: put 3 on the first stage (you have 0)."
func not_yet_words() -> String:
	var lines: Array = result.get("lines", [])
	var misses: Array = lines.filter(func(l: Dictionary) -> bool: return not bool(l.ok))
	if misses.is_empty():
		return MissionRules.message(MissionRules.NOT_READY)
	var head := "Not yet: 1 line to fix." if misses.size() == 1 else "Not yet: %d lines to fix." % misses.size()
	return "%s First: %s" % [head, str(misses[0].text)]


func message() -> String:
	return _message.text if _message else ""


func card_names() -> Array[String]:
	var out: Array[String] = []
	for m in _missions():
		out.append(str(m.name))
	return out


func stage_count() -> int:
	return (result.get("stages", []) as Array).size()


func miss_count() -> int:
	return _misses


func part_cards() -> int:
	return _parts


## What the speaker reads: the page's words.
func words() -> String:
	var parts: Array[String] = ["Mission Control."]
	match page:
		MISSIONS_PAGE:
			for m in _missions():
				parts.append("%s: %s, %s." % [m.name, m.distance, m.trip])
		ROCKET_PAGE:
			parts.append("Your rocket for %s." % mission.get("place", "space"))
			parts.append(RocketPlan.card_words(mission, plan_crew()))
			for l: Dictionary in result.get("lines", []):
				parts.append(str(l.text))
		PARTS_PAGE:
			parts.append("Rocket parts. You have %d gold." % int(gold.call()))
	return " ".join(parts)


## What must not build or break under the board (LookBuildArea reads touches first).
func blockers() -> Array[Control]:
	return [self]


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed(&"pause"):
		if confirm_card and confirm_card.visible:
			_hide_card()
		else:
			close()
		if is_inside_tree():
			get_viewport().set_input_as_handled()


# --- building the panel ---

func _kept() -> Array[Control]:
	return [launch_button, buy_all_button, buy_plan_button, build_button, star_map_button, bar]


func _build() -> void:
	if _built:
		return
	_built = true
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.5)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	_panel = PanelContainer.new()
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.05, 0.08, 0.17, 0.97)
	box.border_color = GOLD_COLOR
	box.set_border_width_all(3)
	box.set_corner_radius_all(22)
	box.set_content_margin_all(18)
	_panel.add_theme_stylebox_override("panel", box)
	_panel.custom_minimum_size = PANEL_SIZE
	center.add_child(_panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	_panel.add_child(column)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 16)
	column.add_child(head)
	var title := UiKit.title("MISSION CONTROL", 40)
	title.add_theme_color_override("font_color", GOLD_COLOR)
	head.add_child(ReadAloud.with_speaker(title, self, words))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(spacer)
	gold_label = Label.new()
	gold_label.add_theme_font_size_override("font_size", 26)
	gold_label.add_theme_color_override("font_color", GOLD_COLOR)
	head.add_child(gold_label)
	close_button = UiKit.big_button("X", UiKit.RED, Vector2(72, 64))
	close_button.tooltip_text = "Close (Esc)"
	close_button.pressed.connect(close)
	head.add_child(close_button)
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 14)
	column.add_child(tabs)
	for i in 3:
		var b := UiKit.big_button(["MISSIONS", "MY ROCKET", "PARTS"][i], UiKit.BLUE, Vector2(250, 64))
		b.pressed.connect(show_page.bind(i))
		tabs.add_child(b)
		_tabs.append(b)
	_message = Label.new()
	_message.add_theme_font_size_override("font_size", 22)
	_message.add_theme_color_override("font_color", GOLD_COLOR)
	_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_message.custom_minimum_size.x = PANEL_SIZE.x - 60
	column.add_child(_message)
	_scroll = ScrollContainer.new()
	_scroll.custom_minimum_size = Vector2(PANEL_SIZE.x - 40, PANEL_SIZE.y - 190)
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(_scroll)
	_content = VBoxContainer.new()
	_content.add_theme_constant_override("separation", 12)
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(_content)
	launch_button = UiKit.big_button("LAUNCH!", UiKit.GREEN, Vector2(300, 80))
	launch_button.pressed.connect(func() -> void: press_launch())
	buy_all_button = UiKit.big_button("", UiKit.ORANGE, Vector2(560, 72))
	buy_all_button.pressed.connect(func() -> void: ask_buy(BUY_ROCKET))
	buy_all_button.visible = false
	buy_plan_button = UiKit.big_button("", UiKit.ORANGE, Vector2(560, 72))
	buy_plan_button.pressed.connect(func() -> void: ask_buy(BUY_PLAN))
	buy_plan_button.visible = false
	build_button = UiKit.big_button("BUILD IT FOR ME", UiKit.GREEN, Vector2(360, 72))
	build_button.pressed.connect(func() -> void: press_build())
	build_button.visible = false
	star_map_button = UiKit.big_button("OPEN THE STAR MAP", UiKit.BLUE, Vector2(420, 72))
	star_map_button.pressed.connect(_on_star_map)
	bar = RocketBar.new()
	_keep.name = "Kept"
	_keep.visible = false
	add_child(_keep)
	for k: Control in _kept():
		_keep.add_child(k)
	_build_card()


## Owner #98: the card that asks before a big buy, over the panel.
func _build_card() -> void:
	var holder := CenterContainer.new()
	holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(holder)
	confirm_card = PanelContainer.new()
	confirm_card.name = "BuyCard"
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.09, 0.13, 0.26, 0.99)
	box.border_color = GOLD_COLOR
	box.set_border_width_all(4)
	box.set_corner_radius_all(20)
	box.set_content_margin_all(24)
	confirm_card.add_theme_stylebox_override("panel", box)
	confirm_card.custom_minimum_size = Vector2(720, 0)
	confirm_card.visible = false
	holder.add_child(confirm_card)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 18)
	confirm_card.add_child(column)
	confirm_label = _words("", 26, Color.WHITE, 660)
	column.add_child(confirm_label)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 30)
	column.add_child(row)
	confirm_yes = UiKit.big_button("YES", UiKit.GREEN, Vector2(220, 80))
	confirm_yes.pressed.connect(func() -> void: confirm_buy())
	row.add_child(confirm_yes)
	confirm_no = UiKit.big_button("NO", UiKit.RED, Vector2(220, 80))
	confirm_no.pressed.connect(cancel_buy)
	row.add_child(confirm_no)


func _hide_card() -> void:
	_pending = {}
	if confirm_card:
		confirm_card.visible = false


## A screen lower than the panel draws it smaller.
func _fit() -> void:
	var room := get_viewport_rect().size if is_inside_tree() else Vector2(1280, 720)
	var need := _panel.get_combined_minimum_size()
	var s := minf(1.0, minf((room.y - 16.0) / maxf(need.y, 1.0), (room.x - 16.0) / maxf(need.x, 1.0)))
	_panel.scale = Vector2(s, s)
	_panel.pivot_offset = need * 0.5


func _missions() -> Array[Dictionary]:
	return MissionRules.open_missions(available.call())


func _has(missions: Array[Dictionary], world: int) -> bool:
	for m in missions:
		if int(m.world) == world:
			return true
	return false


func _missions_page() -> void:
	var reached := false
	for m in _missions():
		_content.add_child(_mission_card(m))
		_cards += 1
		reached = reached or on_route(int(m.world))
	star_map_button.visible = reached and star_map.is_valid()
	_adopt(star_map_button)
	_content.add_child(_words("Rockets can't be flown to our own planets (Planet Boing, Rainbow Planet): fly up to reach them.",
		18, WHY_COLOR))


func _mission_card(m: Dictionary) -> Control:
	var card := PanelContainer.new()
	var chosen := int(m.world) == int(mission.get("world", 0))
	card.add_theme_stylebox_override("panel", UiKit.box(Color(0.12, 0.2, 0.34) if chosen else Color(0.09, 0.13, 0.24), 16, 14))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	card.add_child(row)
	var body := StarMap.body(m.body).duplicate()
	body.size = 34.0
	body.name = ""
	var pic := StarBody.new(body)
	pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pic.set_state(StarMap.LAND if on_route(int(m.world)) else StarMap.LOOK)
	row.add_child(pic)
	var text := VBoxContainer.new()
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text)
	var title := _words(str(m.name), 28, GOLD_COLOR if chosen else Color.WHITE)
	text.add_child(title)
	text.add_child(_words("%s · the real trip: %s" % [_capital(str(m.distance)), m.trip], 19, Color.WHITE))
	text.add_child(_words(str(m.fact), 18, WHY_COLOR))
	text.add_child(_words("The rocket needs: " + "; ".join(MissionRules.needs_words(m)) + ".", 18, Color("bfe3ff")))
	text.add_child(_words(RocketPlan.card_words(m, plan_crew()), 19, GOLD_COLOR))   # owner #98: its size and price
	text.add_child(_words("On your route: LAND on the Star Map." if on_route(int(m.world)) else "Not reached yet.", 18,
		OK_COLOR if on_route(int(m.world)) else MISS_COLOR))
	for b: Variant in badges.call(int(m.world)):   # spec §21d.6 phase 2: flown with friends
		text.add_child(_words("★ " + str(b), 18, GOLD_COLOR))
	var pick := UiKit.big_button("CHOSEN" if chosen else "CHOOSE", UiKit.GREEN if chosen else UiKit.BLUE, Vector2(190, 72))
	pick.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	pick.pressed.connect(choose.bind(int(m.world)))
	row.add_child(pick)
	return card


func _rocket_page() -> void:
	_misses = 0
	_content.add_child(_words("Your rocket for %s (%s)" % [mission.get("place", "space"), mission.get("name", "")], 28, GOLD_COLOR))
	var empty := bool(result.get("empty", true))
	if empty:
		for l: Dictionary in result.get("lines", []):
			_content.add_child(_line(l))
			_misses += 1
	_plan_rows()   # owner #98: under the empty-pad line, or above the check
	if not empty:
		bar.show_trip(mission.get("legs", []), float(result.dv))
		_adopt(bar)
		var stages: Array = result.stages
		for i in stages.size():
			_content.add_child(_words(_stage_words(i, stages[i]), 19, Color("bfe3ff")))
		for l: Dictionary in result.get("lines", []):
			_content.add_child(_line(l))
			if not bool(l.ok):
				_misses += 1
			if l.key == &"paid":
				_buy_rocket_row(l)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 20)
	var again := UiKit.big_button("CHECK AGAIN", UiKit.BLUE, Vector2(280, 72))
	again.pressed.connect(show_page.bind(ROCKET_PAGE))
	row.add_child(again)
	_adopt(launch_button, row)
	var ready := launch_ready()
	launch_button.disabled = false   # owner #98: a grey LAUNCH still says why
	launch_button.modulate = Color.WHITE if ready else Color(1, 1, 1, 0.5)
	var fix := _misses
	launch_button.text = "LAUNCH TO %s!" % str(mission.get("place", "space")).to_upper() if ready \
		else ("NOT YET: 1 LINE TO FIX" if fix == 1 else "NOT YET: %d LINES TO FIX" % fix)
	_content.add_child(row)
	_content.add_child(_words("Rocket science: each stage's speed change is its engines' efficiency (seconds) × 9.8 × the "
		+ "natural log of its weight full ÷ empty. Dropping an empty stage makes the rest lighter, so it goes faster.", 17,
		WHY_COLOR))


## Owner #98: Mission Control's plan, BUILD IT FOR ME and (Survivor) BUY THE MISSING PARTS for it.
func _plan_rows() -> void:
	var crew_n := plan_crew()
	var has_plan := RocketPlan.has_plan(mission, crew_n)
	var who := "" if crew_n == 1 else " (for a crew of %d)" % crew_n
	_content.add_child(_words(RocketPlan.card_words(mission, crew_n).trim_suffix(".") + who + "." if has_plan
		else RocketPlan.no_plan_words(mission, crew_n), 21, GOLD_COLOR))
	build_button.visible = has_plan and build.is_valid()
	if build_button.visible:
		_adopt(build_button)
	var short := plan_short() if has_plan and not is_guest.call() else {}   # a friend's pad: nothing to buy for it
	buy_plan_button.visible = not short.is_empty()
	if buy_plan_button.visible:
		_content.add_child(_words("Your bag needs %s for it." % RocketParts.list_words(short), 19, MISS_COLOR))
		buy_plan_button.text = "BUY THE MISSING PARTS: %d gold" % RocketParts.cost(short)
		_adopt(buy_plan_button)


## Owner #98: the Sandbox's paid line gets its own button, right under it.
func _buy_rocket_row(paid: Dictionary) -> void:
	var cost := missing_cost()
	buy_all_button.visible = not bool(paid.ok) and cost > 0
	if buy_all_button.visible:
		buy_all_button.text = "BUY THE PARTS FOR THIS ROCKET: %d gold" % cost
		_adopt(buy_all_button)


func _stage_words(i: int, st: Dictionary) -> String:
	return "Stage %d: %s. Push %s t, %s t full, %s t empty: +%.1f km/s." % [i + 1, RocketParts.list_words(st.parts),
		RocketCheck._t(float(st.push)), RocketCheck._t(float(st.full)), RocketCheck._t(float(st.empty)), float(st.dv)]


func _line(l: Dictionary) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var mark := _words("✓" if bool(l.ok) else "•", 28, OK_COLOR if bool(l.ok) else MISS_COLOR)
	mark.custom_minimum_size.x = 36
	mark.autowrap_mode = TextServer.AUTOWRAP_OFF
	row.add_child(mark)
	var text := VBoxContainer.new()
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.add_child(_words(str(l.text), 21, Color.WHITE if bool(l.ok) else MISS_COLOR))
	if not bool(l.ok) and str(l.why) != "":
		text.add_child(_words(str(l.why), 17, WHY_COLOR))
	row.add_child(text)
	return row


func _parts_page() -> void:
	buy_all_button.visible = false
	_content.add_child(_words("To buy every part your rocket needs at once: MY ROCKET.", 18, WHY_COLOR))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 12)
	_content.add_child(grid)
	var on_pad := RocketParts.count(result.get("cells", {}))
	for id in RocketParts.ORDER:
		grid.add_child(_part_card(id, int(on_pad.get(id, 0))))
		_parts += 1


func _part_card(id: int, on_pad: int) -> Control:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UiKit.box(Color(0.09, 0.13, 0.24), 14, 10))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	card.add_child(row)
	var icon := TextureRect.new()
	icon.texture = BlockIcons.icon(id)
	icon.custom_minimum_size = Vector2(64, 64)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	row.add_child(icon)
	var text := VBoxContainer.new()
	text.custom_minimum_size.x = 330
	text.add_child(_words(BlockIds.display_name(id), 22, Color.WHITE, 330))
	text.add_child(_words(RocketParts.words(id), 15, WHY_COLOR, 330))
	text.add_child(_words(_numbers(id), 15, Color("bfe3ff"), 330))
	text.add_child(_words(RocketParts.made_of(id), 14, WHY_COLOR, 330))
	var survivor: bool = owned.call() == null
	if survivor and RocketParts.craft_words(id) != "":   # Survivor: the simple ones are made too
		text.add_child(_words(RocketParts.craft_words(id), 14, OK_COLOR, 330))
	var count := ("in your bag %d" % int(have.call(id))) if survivor \
		else ("bought %d · on your rocket %d" % [int(have.call(id)), on_pad])   # owner #98: what "you have" means
	text.add_child(_words("%d gold · %s" % [RocketParts.price(id), count], 17, GOLD_COLOR, 330))
	row.add_child(text)
	var b := UiKit.big_button("BUY", UiKit.GREEN, Vector2(110, 64))
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	b.pressed.connect(func() -> void: buy_part(id))
	row.add_child(b)
	return card


func _numbers(id: int) -> String:
	var out := "%s t" % RocketCheck._t(RocketParts.mass_full(id))
	if RocketParts.fuel(id) > 0.0:
		out = "%s t full, %s t empty" % [RocketCheck._t(RocketParts.mass_full(id)), RocketCheck._t(RocketParts.mass_empty(id))]
	if RocketParts.is_engine(id):
		out += " · pushes %s t · %d s" % [RocketCheck._t(RocketParts.push(id)), int(RocketParts.isp(id))]
	if RocketParts.seats(id) > 0:
		out += " · %d seat" % RocketParts.seats(id)
	if RocketParts.keeps(id) > 0:
		out += " · air and water for one astronaut, the whole trip"   # owner #98
	return out


func _after_buying(why: String, done: String) -> void:
	if why == "":
		Audio.play(&"ui_click")
	show_page(page, true)
	_say(done if why == "" else why)


func _restore_scroll(at: int) -> void:
	if is_instance_valid(_scroll):
		_scroll.scroll_vertical = at


func _on_star_map() -> void:
	close()
	if star_map.is_valid():
		star_map.call()


func _update_gold() -> void:
	gold_label.text = "Your gold: %d" % int(gold.call())


func _say(text: String) -> void:
	if _message:
		_message.text = text
		_message.visible = text != ""


## Puts a long-lived control (a button kept across pages) on the page (or into `parent`).
func _adopt(c: Control, parent: Control = null) -> void:
	if c.get_parent():
		c.get_parent().remove_child(c)
	(parent if parent else _content).add_child(c)
	c.visible = c.visible or c == launch_button or c == bar


func _words(text: String, size: int, color: Color, width := 0) -> Label:
	var l := Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.custom_minimum_size.x = width if width > 0 else PANEL_SIZE.x - 300
	return l


static func _capital(s: String) -> String:
	return s.substr(0, 1).to_upper() + s.substr(1) if s != "" else s
