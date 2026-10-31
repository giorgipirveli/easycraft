class_name WondersDirector
extends Node3D
## The tours in world 41, Wonders of the World (owner #78, spec §24), for this game's own player (the sandbox's node
## "Wonders", section "Owner #78: the world's wonders"): every tour's wonders as sights (WonderSights: reaching one says
## its real fact), the Wonders Passport's stamp for each (WonderData.stamp, then how many of its tour are visited and
## which is next, or where the next tour waits), the explorer's guide (the landing card, PlanetGuideCard with the tours
## side by side; the HUD's compass to the nearest wonder not reached: compass_target), MY MAP's landing spot, the New
## Seven's and the nature squares and every wonder, the names over the squares' signposts (the Wonders Road's and the
## Nature Trail's too) and the wonders' and tours' plaques (Label3D, the traders' look, hidden far away), a plaque's tap:
## the wonder's card and its fact quiz (WonderCard: each question pays once, right the first time, through `pay`) or its
## tour's card, and the nature region's sky (NatureSky: the northern lights at night, the rainbow in the falls' spray).

## A wonder was reached here for the first time in this world (after its fact's words).
signal wonder_reached(id: StringName)
## Owner #94: a wonder's Passport stamp won just now (the first time it is reached).
signal stamp_won(id: StringName)
## A card opened from a plaque (tests, the smoke run).
signal card_opened(card: WonderCard)

const STAMP_DELAY := 6.5          # the stamp's words come after the fact's
const LANDING_ID := "wonders_landing"
const NEW_SQUARE_ID := "wonders_new_square"
const NATURE_SQUARE_ID := "wonders_nature_square"
## The floating names show from this far (metres): a square's signposts from across it, a wonder's plaque from near it
## (none of the wonders' plaques shows from the landing spot: the spawn view stays light).
const LABEL_RANGE := 140.0
const PLAQUE_LABEL_RANGE := 60.0
const SIGN_Y := 3.4               # a name floats this far over a signpost's foot
const PLAQUE_NAME_Y := 2.2

## The world's found secrets (SecretState.found): the reached wonders go in as "sight:<id>".
var found := {}
## () -> Vector3: this game's player's feet (INF when there is none).
var player_position: Callable = func() -> Vector3: return Vector3.INF
## (text, seconds) -> void: this game's words for the player (the HUD's toast).
var toast: Callable = func(_t: String, _s: float) -> void: pass
## (entry {id, kind, name, pos}) -> void: a place on MY MAP (PlacesDirector.mark).
var mark: Callable
## (gold) -> void: a quiz's gold for this child (the sandbox's: Survivor's wallet or the profile).
var pay: Callable = func(gold: int) -> void: EarnRules.credit(Profile.data, gold)
var data: Callable = func() -> WonderData: return Profile.data.wonder
var save: Callable = func() -> void: Profile.save()
## Where cards open (the sandbox's UI layer; tests leave it null and read card_opened).
var ui_parent: Node
## Off in tests (they call sights.tick()).
var auto_tick := true
## () -> float: the sky's time of day (DayCycle; the sandbox's SkyCycle): the northern lights shine at night.
var sky_time: Callable = func() -> float: return DayCycle.NOON

var sights: WonderSights
var nature_sky: NatureSky
var card: WonderCard
var labels: Array[Label3D] = []
var _spots: Array[Vector3] = []     # each wonder's place, in WonderTour.ids() order (the compass asks every frame)
var _spot_ids: Array[String] = []


## The sights, the map's places and the signs' names (after the node is in the tree).
func setup() -> void:
	sights = WonderSights.new()
	sights.name = "Sights"
	sights.sights = UniverseRegistry.sights(EarthRules.WONDERS)
	sights.found = found
	sights.player_position = player_position
	sights.auto_tick = auto_tick
	sights.toast = func(text: String) -> void: toast.call(text, 7.0)
	sights.mark = mark
	add_child(sights)
	sights.setup()
	sights.sight_found.connect(_on_reached)
	if mark.is_valid():
		mark.call({"id": LANDING_ID, "kind": &"pad", "name": tr("Landing Spot"),
			"pos": Vector3(0.5, WonderTour.BASE_Y, 0.5)})
		var c := WonderTour.NEW_SQUARE
		mark.call({"id": NEW_SQUARE_ID, "kind": &"pad", "name": tr(WonderFacts.NEW_TOUR_TITLE),
			"pos": Vector3(c.x + 0.5, WonderTour.BASE_Y, c.y + 0.5)})
		var n := WonderTour.NATURE_SQUARE
		mark.call({"id": NATURE_SQUARE_ID, "kind": &"pad", "name": tr(WonderFacts.NATURE_TOUR_TITLE),
			"pos": Vector3(n.x + 0.5, WonderTour.BASE_Y, n.y + 0.5)})
	_signs()
	nature_sky = NatureSky.new()
	nature_sky.name = "NatureSky"
	nature_sky.player_position = player_position
	nature_sky.sky_time = sky_time
	nature_sky.auto_tick = auto_tick
	add_child(nature_sky)


## The guide's checklist: [{id, name, pos, found}], nearest to `from` first.
func checklist(from: Vector3 = Vector3.ZERO) -> Array[Dictionary]:
	return PlanetGuideRules.checklist(WonderSights.spots(), sights.sights if sights else UniverseRegistry.sights(41),
		found, from)


## The HUD compass's target from `from`: the nearest wonder not reached yet ({} when all are).
## The HUD asks it every frame (TreasureCompass.guided): a plain loop over the places, nothing built or sorted.
func compass_target(from: Vector3) -> Dictionary:
	if _spots.is_empty():
		for s: Dictionary in WonderSights.spots():
			_spots.append(s.pos)
			_spot_ids.append(SpaceSights.PREFIX + String(s.id))
	var best := -1
	var best_d := INF
	for i in _spots.size():
		if found.has(_spot_ids[i]):
			continue
		var d := Vector2(_spots[i].x - from.x, _spots[i].z - from.z).length_squared()
		if d < best_d:
			best_d = d
			best = i
	return {} if best < 0 else {"chest": Vector3i(_spots[best])}


## The explorer's card for the landing: the tours side by side (each nearest first, by their short names so three
## columns fit a phone), the world's own words.
func guide_card() -> PlanetGuideCard:
	var all := checklist()
	var groups: Array = []
	for tour: StringName in WonderFacts.TOUR_IDS:
		var mine: Array = []
		for e: Dictionary in all:
			if WonderFacts.tour_of(e.id) == tour:
				var short := e.duplicate()
				short.name = str(WonderFacts.of(e.id).get("short", e.name))
				mine.append(short)
		groups.append({"title": WonderFacts.tour_info(tour).heading, "list": mine})
	return PlanetGuideCard.new(WonderFacts.WORLD_TITLE, all, WonderFacts.TOUR_INTRO, groups)


func _on_reached(id: StringName) -> void:
	var first := (data.call() as WonderData).stamp(id)
	if first:
		save.call()
		stamp_won.emit(id)
	wonder_reached.emit(id)
	if not is_inside_tree():
		return
	get_tree().create_timer(STAMP_DELAY).timeout.connect(_say_progress.bind(first, id))   # gone with the world: never said


## The stamp's words (the first time) and how many of its tour are visited, which is next.
func _say_progress(first: bool, id: StringName = &"") -> void:
	toast.call(progress_words(first, id), 7.0)


## What is said after wonder `id` is reached (tests).
func progress_words(first: bool, id: StringName) -> String:
	var here: Vector3 = player_position.call()
	var at := here if here.is_finite() else Vector3.ZERO
	var tour := WonderFacts.tour_of(id)
	var words := WondersPassportRules.tour_progress_words(checklist(at), at, tour) if tour != &"" \
		else WondersPassportRules.progress_words(checklist(at), at)
	if first:
		words = WondersPassportRules.stamp_words(data.call(), id) + " " + words
	return words


## A tap on a plaque at `cell`: its wonder's card (or the tour's). False when no plaque is there.
func open_plaque(cell: Vector3i) -> bool:
	var id := WonderTour.plaque_at(cell)
	if id == &"":
		return false
	open_card(id)
	return true


func open_card(id: StringName) -> WonderCard:
	if card != null and is_instance_valid(card):
		card.queue_free()
	card = WonderCard.new(id, data, pay, save)
	card.closed.connect(card.queue_free)
	if ui_parent != null and is_instance_valid(ui_parent):
		ui_parent.add_child(card)
		if PlatformRules.captures_mouse(PlatformRules.current()):
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE   # a PC clicks the card (the next click looks around again)
	Audio.play(&"ui_click")
	card_opened.emit(card)
	return card


## The names over the squares' signposts (the Wonders Road's to the other tour) and over the wonders' and tours' plaques.
func _signs() -> void:
	for id: StringName in WonderTour.ids():
		var s := WonderTour.signpost(id)
		_label(WonderFacts.display_name(id), Vector3(s.x + 0.5, WonderTour.BASE_Y + SIGN_Y, s.y + 0.5), Color("fff3c4"))
		var p := WonderTour.plaque(id)
		_label(WonderFacts.display_name(id), Vector3(p) + Vector3(0.5, PLAQUE_NAME_Y, 0.5), Color("ffe14d"),
			PLAQUE_LABEL_RANGE)
	for tour: StringName in WonderFacts.TOUR_IDS:
		var t := WonderTour.tour_plaque(tour)
		_label(str(WonderFacts.tour_info(tour).title), Vector3(t) + Vector3(0.5, PLAQUE_NAME_Y, 0.5), Color("ffe14d"))
	for road: Array in [[&"ancient", &"new", "Wonders Road"], [&"ancient", &"nature", "Nature Trail"]]:
		for i in 2:   # the sign at each end names the tour at the other end
			var here: StringName = road[i]
			var there: StringName = road[1 - i]
			var r := WonderTour.road_signpost(here) if road[2] == "Wonders Road" else WonderTour.trail_signpost(here)
			_label("%s (%s)" % [WonderFacts.tour_info(there).heading, road[2]],
				Vector3(r.x + 0.5, WonderTour.BASE_Y + SIGN_Y, r.y + 0.5),
				Color("9be7ff") if road[2] == "Wonders Road" else Color("b7f5a6"))


func _label(text: String, at: Vector3, color: Color, range_end: float = LABEL_RANGE) -> void:
	var l := Label3D.new()
	l.text = text
	l.font_size = 48
	l.outline_size = 12
	l.pixel_size = 0.005
	l.modulate = color
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.visibility_range_end = range_end
	l.position = at
	add_child(l)
	labels.append(l)
