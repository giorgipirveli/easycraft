class_name InviteNewsCard
extends VBoxContainer
## Owner #79 (spec §25.2): good news from friends, on the main menu once ("Your friend Sam_22 joined and learned! +250
## gold"), read aloud when Read to me is on; OK goes on to the games. A friend is named by their in-game name only; a
## friend's friend is never named.

signal closed

var news: Array[Dictionary] = []


func _init(items: Array[Dictionary] = []) -> void:
	news = items


func _ready() -> void:
	name = "InviteNews"
	add_theme_constant_override("separation", 16)
	add_child(ReadAloud.with_speaker(UiKit.title("Good news from your friends!", 40), self, _spoken))
	var shown := 0
	for n in news:
		var line := InviteRules.news_words(n)
		if line == "" or shown >= 5:
			continue
		var l := OnlineUi.words(line, 28, 900)
		l.add_theme_color_override("font_color", SchoolUi.GOLD if int(n.get("gold", 0)) > 0 else Color.WHITE)
		add_child(l)
		shown += 1
	if news.size() > shown:
		add_child(OnlineUi.words("More on your INVITE and FRIENDS pages.", 22, 900))
	var ok := OnlineUi.button("OK", UiKit.GREEN, Vector2(240, 84))
	ok.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	ok.pressed.connect(func() -> void: closed.emit())
	add_child(ok)
	Audio.play(&"jingle_badge")


func _spoken() -> String:
	var lines: Array[String] = []
	for n in news:
		lines.append(InviteRules.news_words(n))
	return " ".join(lines)
