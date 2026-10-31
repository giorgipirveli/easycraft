class_name PostcardPage
extends VBoxContainer
## Owner #81, #82 (brief 2026-09-30 item 2): the postcard of a proud moment (PostcardView) with what a child can do with
## it: SAVE PICTURE (where photos go here), SHARE (a browser's share sheet with the words and the link, or Android's with
## the picture, where a grown-up's switch allows), COPY (the words and the link) and CLOSE; the grown-ups' line. Fits
## SchoolUi.FRAME (the School shows it as a page; in a world PostcardOffer shows it over the game).
## Hooks (tests set them): `profile`, `copy_text`, `can_share`, `share`, `save_png`, `render`.

signal closed

const CARD_PX := Vector2i(700, 480)

var moment := {}
var photo: Texture2D
var profile: ProfileData
var copy_text := func(t: String) -> void: DisplayServer.clipboard_set(t)
var can_share := Callable()
var share := func(text: String, url: String, png: PackedByteArray) -> String: return CardPicture.share(text, url, png)
var save_png := func(png: PackedByteArray) -> Dictionary: return CardPicture.save_png(png)
var render := Callable()
var note: Label
var view: PostcardView


func _init(m: Dictionary = {}, p_photo: Texture2D = null) -> void:
	moment = m
	photo = p_photo
	name = "PostcardPage"
	add_theme_constant_override("separation", 10)
	alignment = BoxContainer.ALIGNMENT_CENTER


func _ready() -> void:
	if profile == null:
		profile = Profile.data
	if not can_share.is_valid():
		can_share = func() -> bool: return CardPicture.can_share(profile)
	if not render.is_valid():
		render = func(c: Control) -> Image: return await CardPicture.render(self, c, CARD_PX)
	add_child(ReadAloud.with_speaker(UiKit.title("Your postcard", 34), self, func() -> String: return words()))
	view = PostcardView.new(words(), profile.invite.code, photo)
	view.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	add_child(view)
	var buttons: Array[Control] = []
	var keep := OnlineUi.button(CardPicture.save_label(), OnlineUi.PURPLE, Vector2(230, 64))
	keep.name = "SavePicture"
	keep.add_theme_font_size_override("font_size", 24)
	keep.pressed.connect(_save_picture)
	buttons.append(keep)
	if can_share.call():
		var sh := OnlineUi.button("SHARE", UiKit.GREEN, Vector2(160, 64))
		sh.name = "Share"
		sh.pressed.connect(_share)
		buttons.append(sh)
	var copy := OnlineUi.button("COPY", UiKit.BLUE, Vector2(150, 64))
	copy.name = "Copy"
	copy.pressed.connect(_copy)
	buttons.append(copy)
	var close := OnlineUi.button("CLOSE", Color(0.2, 0.24, 0.36), Vector2(170, 64))
	close.name = "Close"
	close.pressed.connect(func() -> void: closed.emit())
	buttons.append(close)
	add_child(OnlineUi.row(buttons, 12))
	note = OnlineUi.words("", 20, 900)
	note.name = "Note"
	note.add_theme_color_override("font_color", SchoolUi.GOLD)
	note.visible = false
	add_child(note)
	var grown := OnlineUi.words(PostcardRules.GROWN_UPS_LINE, 16, 900)
	grown.name = "GrownUpLine"
	grown.add_theme_color_override("font_color", Color(1, 1, 1, 0.65))
	add_child(grown)
	ReadAloud.auto(words())


func words() -> String:
	return str(moment.get("words", ""))


func share_text() -> String:
	return PostcardRules.share_text(words(), profile.invite.code)


func _say(text: String) -> void:
	if text != "":
		note.text = text
		note.visible = true


func _picture() -> PackedByteArray:
	var img: Image = await render.call(PostcardView.new(words(), profile.invite.code, photo))
	return CardPicture.png_of(img)


func _save_picture() -> void:
	var png: PackedByteArray = await _picture()
	if not is_inside_tree():
		return
	if png.is_empty():
		_say(CardPicture.FAILED)
		return
	var r: Dictionary = save_png.call(png)
	_say(PostcardRules.SAVED_WORDS if str(r.get("path", "")) != "" else str(r.get("text", "")))


func _share() -> void:
	var png: PackedByteArray = await _picture()
	if not is_inside_tree():
		return
	_say(str(share.call(share_text(), DailyMission.link(profile.invite.code), png)))


func _copy() -> void:
	copy_text.call(share_text())
	_say("Copied! A grown-up can paste it in a message.")
	Audio.play(&"ui_click")
