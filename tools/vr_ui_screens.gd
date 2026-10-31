extends RefCounted
## Owner #101 (VR on the Meta Quest, P2): the screens the readability audit looks at in the VR canvas, made as their own
## tests make them (stand-in services, a private profile, nothing saved): the School (map, unit, round), the Mission
## Board (MISSIONS, MY ROCKET with BUILD IT FOR ME, PARTS, the buy card), the Gold Shop, Gemma's board, the inventions
## book, the Star Map, the Secret Book, MY MAP, the Shorts feed and maker, the chat and SETTINGS' VR COMFORT.
## Used by tests/integration/test_vr_ui_audit.gd (no word under 24 px, every screen fits) and tools/vr_ui_shots.gd (the
## pictures). build(name, holder) adds the screen to `holder` (a 1280 × 720 control in the canvas); open(name, screen)
## opens it a frame later.

const NAMES: Array[String] = ["school_map", "school_unit", "school_round", "board_missions", "board_rocket",
	"board_parts", "board_buy", "gold_shop", "gemma", "inventions", "star_map", "secret_book", "my_map", "shorts_feed",
	"shorts_maker", "chat", "settings_vr", "log_in", "password_make", "logged_out", "cockpit_descent"]

const UNIT := "g4.maths.big_numbers"
const CONTENT := {"id": UNIT, "lesson": [{"text": "A digit's place tells what it is worth."}],
	"exercises": [
		{"type": "choice", "prompt": "Which is 3,000 + 20 + 5?", "choices": ["3,025", "3,205", "325"], "answer": 0,
			"hint": "No hundreds.", "level": 3}],
	"generators": []}


static func build(screen_name: String, holder: Control) -> Control:
	match screen_name:
		"school_map", "school_unit", "school_round":
			Curriculum.clear_cache()
			Curriculum.put_content(UNIT, CONTENT)
			var profile := ProfileData.new()
			profile.school.grade = 4
			var school := SchoolScreen.new()
			school.profile = profile
			school.save_profile = func() -> void: pass
			school.today = func() -> int: return 20_000
			school.next_seed = func() -> int: return 7
			return _centred(school, holder)
		"board_missions", "board_rocket", "board_parts", "board_buy":
			var board := MissionBoard.new()
			board.read_rocket = func() -> Dictionary: return {}
			board.owned = func() -> Variant: return null if screen_name == "board_buy" else {}
			board.have = func(_id: int) -> int: return 0
			board.gold = func() -> int: return 5000
			board.buy = func(_id: int, _n: int) -> String: return ""
			board.launch = func(_r: Dictionary) -> String: return ""
			board.route = func() -> Array[int]: return [] as Array[int]
			board.available = func() -> Array[int]: return [16, 17, 18] as Array[int]
			board.build = func(_w: int, _c: int) -> String: return ""
			holder.add_child(board)
			return board
		"gold_shop":
			SpendRules.clear_extra()
			var profile := ProfileData.new()
			profile.survivor_gold = 500
			var shop := GoldShop.new()
			shop.profile = profile
			shop.save_profile = func() -> void: pass
			return _centred(shop, holder)
		"gemma":
			var gemma := ProspectBoard.new()
			gemma.quests = func() -> Array:
				var out: Array = []
				for k in DepositKinds.told_in(1):
					out.append({"kind": k, "title": ProspectQuests.quest(k).title, "here": DepositKinds.universe_of(k) == 1,
						"where": "the Sandstorm Desert", "status": "going" if k == DepositKinds.IRON else "new", "step": 2,
						"steps": 7, "found": 1 if k == DepositKinds.COAL else 0})
				return out
			gemma.step_view = func(_k: StringName) -> Dictionary: return {}
			gemma.distance_to = func(_k: StringName) -> int: return 240
			holder.add_child(gemma)
			return gemma
		"inventions":
			var data := InventionData.new()
			var book := InventionsPanel.new()
			book.data = func() -> InventionData: return data
			book.survivor = func() -> bool: return true
			book.have = func(_m: StringName) -> int: return 0
			book.gold = func() -> int: return 100
			book.mastered = func(_id: StringName) -> bool: return false
			book.near_workbench = func() -> bool: return true
			book.chosen = func() -> int: return FlightCrafts.Craft.NONE
			holder.add_child(book)
			return book
		"star_map":
			var map := SpacePanel.new()
			map.size = Vector2(VrPanelRules.CANVAS)
			holder.add_child(map)
			return map
		"secret_book":
			var secrets := SecretBook.new()
			holder.add_child(secrets)
			return secrets
		"my_map":
			var mine := WorldMapPanel.new()
			mine.entries_source = func() -> Array:
				return [{"id": "village_1_0", "kind": MeadowsPlaces.VILLAGE, "name": "Maplebrook", "pos": Vector3(300, 40, 20)},
					{"id": "windmill_0_1", "kind": MeadowsPlaces.WINDMILL, "name": "Honeyfield Mill", "pos": Vector3(-90, 35, 180)}]
			mine.player_position = func() -> Vector3: return Vector3(0, 30, 0)
			mine.home_position = func() -> Vector3: return Vector3(12, 30, -20)
			mine.point_to = func(_l: String, _p: Vector3) -> void: pass
			holder.add_child(mine)
			return mine
		"shorts_feed", "shorts_maker":
			var profile := ProfileData.new()
			profile.username = "BlueFox42"
			profile.school.grade = 4
			var shorts := ShortsView.new()
			shorts.profile = profile
			shorts.save_profile = func() -> void: pass
			holder.add_child(shorts)
			return shorts
		"chat":
			var chat := ChatPanel.new()
			holder.add_child(chat)
			chat.setup("Hopper", AgeBand.TEEN_PLUS)
			return chat
		"settings_vr":
			var s := SettingsPanel.new()
			s.saver = func() -> void: pass
			return _centred(s, holder)
		"log_in":   # owner #104 / #105, as AccountsOverlay shows it (no service: nothing is sent)
			var page := LogInPage.new()
			page.username = "Anna_7"
			return _centred(page, holder)
		"password_make":
			var pp := PasswordPage.new()
			pp.mode = PasswordPage.Mode.MAKE
			pp.asked = true
			return _centred(pp, holder)
		"logged_out":
			var card := LoggedOutCard.new()
			card.on_menu = func() -> bool: return true
			holder.add_child(card)
			return card
		"cockpit_descent":   # owner #106's landing on the dashboard (VR: its dashboard mode)
			var cockpit := FlightCockpit.new()
			holder.add_child(cockpit)
			return cockpit
	return null


## Opens `screen` (a frame after build).
static func open(screen_name: String, screen: Control) -> void:
	match screen_name:
		"school_map":
			(screen as SchoolScreen).show_map("maths")
		"school_unit":
			(screen as SchoolScreen).show_unit(UNIT)
		"school_round":
			(screen as SchoolScreen).show_round(UNIT)
		"board_missions":
			(screen as MissionBoard).open()
			(screen as MissionBoard).show_page(MissionBoard.MISSIONS_PAGE)
		"board_rocket":
			(screen as MissionBoard).open()
			(screen as MissionBoard).show_page(MissionBoard.ROCKET_PAGE)
		"board_parts":
			(screen as MissionBoard).open()
			(screen as MissionBoard).show_page(MissionBoard.PARTS_PAGE)
		"board_buy":
			(screen as MissionBoard).open()
			(screen as MissionBoard).show_page(MissionBoard.ROCKET_PAGE)
			(screen as MissionBoard).ask_buy(MissionBoard.BUY_PLAN)
		"gemma":
			(screen as ProspectBoard).open_quests()
		"inventions":
			(screen as InventionsPanel).open()
		"star_map":
			(screen as SpacePanel).open(1, 1, [16, 17, 18] as Array[int], 2)
		"secret_book":
			(screen as SecretBook).open()
		"my_map":
			(screen as WorldMapPanel).open()
		"shorts_feed", "shorts_maker":
			(screen as ShortsView).open()
		"chat":
			(screen as ChatPanel).open()
		"logged_out":
			(screen as LoggedOutCard).show_text(PasswordRules.LOGGED_OUT)
		"cockpit_descent":
			(screen as FlightCockpit).show_state({"descent": {"h": 42.0, "v": 2.5, "zone": FlightDescent.GREEN,
				"fuel": 0.6, "safe": 3.0}, "descent_held": true, "time": 1.0, "hint": FlightDescent.HINT.left(40)})
		"settings_vr":
			var s := screen.get_child(0) as SettingsPanel if screen.get_child_count() > 0 else null
			if s and s.find_child("Page_vr", true, false):
				(s.find_child("Page_vr", true, false) as Button).pressed.emit()


## A screen the menus show in a panel, centred on the canvas (themed, as the menu does).
static func _centred(c: Control, holder: Control) -> Control:
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel := PanelContainer.new()
	panel.theme = UiKit.theme()
	panel.add_child(c)
	center.add_child(panel)
	holder.add_child(center)
	return panel if c is SettingsPanel else c


## The whole of what a screen draws (its panel when the menus put it in one).
static func root_of(screen: Control) -> Control:
	var p := screen.get_parent() as Control
	return p if p is PanelContainer else screen
