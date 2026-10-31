class_name PostcardOffer
extends Control
## Owner #81, #82 (brief 2026-09-30 item 2): the offer of a postcard at a proud moment in a world, once (PostcardRules:
## never nagging). A small card in the top right corner, "What a moment! Make a postcard?" with POSTCARD and NO THANKS;
## the game goes on behind it. POSTCARD hides the card for a frame, takes the picture of the world (photo mode's
## capture; `before_photo` / `after_photo` can hide the HUD for it) and shows the postcard over the game (PostcardPage,
## the mouse freed on a PC); CLOSE goes back to the game. The moment is told to friends to cheer either way
## (SocialSender.moment).
##
## The hook for the lead (the flight is merged after this brief): at a first landing (RocketFlight.landed or the
## sandbox's mission_arrive), `PostcardOffer.offer(_layer, PostcardRules.landed("moon"))`; a wonder's stamp and a deposit
## found use PostcardRules.stamp / deposit the same way.

signal done

var moment := {}
var profile: ProfileData
var save_profile := Callable()
## () -> Image: the world's picture (tests pretend); default PhotoMode.capture of the viewport.
var capture := Callable()
var before_photo := Callable()
var after_photo := Callable()
## A PC frees its captured mouse for the card (M7: a phone browser has none to free); tests switch it off.
var frees_mouse := PlatformRules.captures_mouse(PlatformRules.current()) and DisplayServer.get_name() != "headless"

var card: PanelContainer
var page: PostcardPage
var _shade: ColorRect


## Offers the postcard of `m` under `parent` (a CanvasLayer or the HUD's Control), once per moment: null when it was
## offered before. Tells friends either way the first time. The profile is saved.
static func offer(parent: Node, m: Dictionary, p: ProfileData = null) -> PostcardOffer:
	var prof := p if p != null else Profile.data
	if parent == null or m.is_empty() or not PostcardRules.due(prof, m):
		return null
	PostcardRules.note_offered(prof, m)
	SocialSender.moment(m, prof)
	var o := PostcardOffer.new()
	o.moment = m
	o.profile = prof
	parent.add_child(o)
	if p == null:
		Profile.save()
	return o


func _ready() -> void:
	name = "PostcardOffer"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS
	theme = UiKit.theme()
	if profile == null:
		profile = Profile.data
	if not capture.is_valid():
		capture = func() -> Image: return PhotoMode.capture(get_viewport())
	card = PanelContainer.new()
	card.name = "Card"
	card.add_theme_stylebox_override("panel", UiKit.box(UiKit.DARK, 18, 14))
	card.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	card.offset_left = -470
	card.offset_right = -20
	card.offset_top = 120
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	var v := OnlineUi.column(8)
	v.add_child(OnlineUi.words(str(moment.get("words", "")), 26, 420))
	v.add_child(OnlineUi.words(PostcardRules.OFFER_WORDS, 22, 420))
	var make := OnlineUi.button("POSTCARD", UiKit.GREEN, Vector2(200, 64))
	make.name = "MakePostcard"
	make.pressed.connect(make_postcard)
	var no := OnlineUi.button("NO THANKS", UiKit.BLUE, Vector2(200, 64))
	no.name = "NoThanks"
	no.add_theme_font_size_override("font_size", 24)
	no.pressed.connect(close)
	v.add_child(OnlineUi.row([make, no], 12))
	card.add_child(v)
	add_child(card)
	if frees_mouse:   # a PC: the card's buttons are clicked (no new key: the notes' ruling); the next click plays on
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	Audio.play(&"jingle_goal")


func make_postcard() -> void:
	card.visible = false
	if before_photo.is_valid():
		before_photo.call()
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
	var img: Image = capture.call()
	if after_photo.is_valid():
		after_photo.call()
	if not is_inside_tree():
		return
	var tex: Texture2D = ImageTexture.create_from_image(img) if img != null and not img.is_empty() else null
	_shade = ColorRect.new()
	_shade.name = "Shade"
	_shade.color = Color(0, 0, 0, 0.6)
	_shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_shade.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_shade.add_child(center)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiKit.box(UiKit.DARK, 22, 20))
	center.add_child(panel)
	page = PostcardPage.new(moment, tex)
	page.profile = profile
	page.closed.connect(close)
	panel.add_child(page)
	if frees_mouse:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func close() -> void:
	done.emit()
	queue_free()


## Android Back: true when the offer or its postcard was showing (now gone).
func close_if_open() -> bool:
	if not is_inside_tree():
		return false
	close()
	return true
