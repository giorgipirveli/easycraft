class_name GiftSendPage
extends VBoxContainer
## GIFT on a friend's row (M4 Wave 3, agent I; spec §17.5, research T3, D5): send the friend A BUILD
## (one of the child's own picked builds, the shelf GiftStampBook.mine; picking happens in a world:
## MORE, SHARE, then a tap on the build) or A BOTTLE (a quick phrase and maybe a tiny build). Big
## buttons, short words; the server checks everything again.

const SHELF_COLUMNS := 4

var service: OnlineService
var friend: Dictionary = {}       # {id, username}
var message: Label
var page := &"choose"

var _body := VBoxContainer.new()
var _title: Label
var _busy := false


func _ready() -> void:
	add_theme_constant_override("separation", 10)
	_title = OnlineUi.words(tr("A present for %s") % friend.get("username", ""), 30, 900)
	add_child(_title)
	_body.add_theme_constant_override("separation", 10)
	add_child(_body)
	message = OnlineUi.words("", 24, 900)
	message.add_theme_color_override("font_color", OnlineUi.HINT_COLOR)
	add_child(message)
	show_choice()


func show_choice() -> void:
	page = &"choose"
	_title.visible = true
	OnlineUi.clear(_body)
	var build := OnlineUi.button("A BUILD", UiKit.GREEN, Vector2(360, 150), &"house")
	build.name = "ABuild"
	build.pressed.connect(show_shelf)
	var bottle := OnlineUi.button("A BOTTLE", OnlineUi.PURPLE, Vector2(360, 150), &"globe")
	bottle.name = "ABottle"
	bottle.pressed.connect(show_bottle)
	_body.add_child(OnlineUi.row([build, bottle], 28))


## The child's own picked builds, newest first; a tap sends one.
func show_shelf() -> void:
	page = &"shelf"
	OnlineUi.clear(_body)
	var shelf := service._i_book().mine.duplicate()
	shelf.reverse()
	if shelf.is_empty():
		_body.add_child(OnlineUi.words("Pick a build first: in your world tap MORE, then SHARE, then tap your build.", 28, 900))
		return
	_body.add_child(OnlineUi.words("Which build?", 30, 900))
	var grid := GridContainer.new()
	grid.columns = SHELF_COLUMNS
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	for i in shelf.size():
		var b := OnlineUi.button(tr("BUILD %d\n%s") % [i + 1, Lang.blocks(BuildCodec.count_of(shelf[i]))], UiKit.GREEN, Vector2(210, 110))
		b.name = "Build%d" % (i + 1)
		b.add_theme_font_size_override("font_size", 24)
		b.pressed.connect(_send_build.bind(shelf[i]))
		grid.add_child(b)
	var centre := CenterContainer.new()
	centre.add_child(grid)
	_body.add_child(centre)


func show_bottle() -> void:
	page = &"bottle"
	_title.visible = false   # the bottle says whom it is for
	OnlineUi.clear(_body)
	var b := BottlePage.new()
	b.name = "Bottle"
	b.friend_name = str(friend.get("username", ""))
	b.shelf = service._i_book().mine.filter(func(t: String) -> bool: return not BuildCodec.decode(t, BuildCodec.BOTTLE).is_empty())
	b.send_requested.connect(_send_bottle)
	_body.add_child(b)


func _send_build(build: String) -> void:
	await _act(service.send_gift.bind(str(friend.id), build), tr("Sent! %s will find it next time they play.") % friend.get("username", ""))


func _send_bottle(phrase: String, build: String) -> void:
	await _act(service.send_bottle.bind(str(friend.id), phrase, build), tr("Your bottle is floating to %s!") % friend.get("username", ""))


func _act(action: Callable, thanks: String) -> void:
	if _busy:
		return
	_busy = true
	message.text = "One moment..."
	var err: String = await action.call()
	_busy = false
	if not is_inside_tree():
		return
	message.text = err if err != "" else thanks
	if err == "":
		show_choice()


## The friends page's BACK: from a shelf or a bottle back to the choice (true), else the page closes.
func back() -> bool:
	if page == &"choose":
		return false
	message.text = ""
	show_choice()
	return true
