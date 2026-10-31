class_name FriendsPage
extends VBoxContainer
## Owner #81, #82, #85 (brief 2026-09-30 items 3-5; the world game plan §1-§2b): FRIENDS, from the main menu. Learning is
## better together. It signs in (friends live on the server), claims the child's own name when the account has none,
## reads social_info and shows three tabs:
## - FRIENDS: "Cheer your friends" (their proud moments: AMAZING! or WELL DONE! at one tap, MORE for the other kind
##   words; never typed) and each friend with their
##   friendship level (days together: Good, Great, Best friends, each opening a shared reward), GIFT, and study buddies
##   (ask, yes, the days learning together and this week's row; a rest day is fine).
## - PRESENTS: presents to open (a rocket part, seeds, a buddy egg, a map piece: the game gives the thing) and THANK YOU
##   (a small gift back); a present for a new friend waits on the invite code.
## - CREW: invitations (JOIN, NO THANKS), MAKE A CREW (a name from two kid-safe word lists and a badge), and the crew
##   page: each member's avatar and what each learned this week (never a ranking), the crew's weekly goal, INVITE A
## FRIEND TO THE CREW, LEAVE.
## Nothing pushes: no timers, no ranking of children, nothing lost by resting. Every page fits the menu's frame
## (SchoolUi.FRAME).

signal closed
## INVITE A FRIEND (no friends yet): the menu opens the invite page.
signal invite_requested

const SOON := &"soon"
const CONNECTING := &"connecting"
const FAILED := &"failed"
const CLAIM := &"claim"
const NOT_ALLOWED := &"not_allowed"
const FRIENDS := &"friends"
const PRESENTS := &"presents"
const CREW := &"crew"
const CHEER := &"cheer"
const PICK_PRESENT := &"pick_present"
const MAKE_CREW := &"make_crew"
const PICK_CREWMATE := &"pick_crewmate"
const FRIENDS_SHOWN := 4
const FEED_SHOWN := 3
## A friend's moment: these cheer at one tap (MORE shows all six).
const QUICK_CHEERS: Array[String] = ["amazing", "well_done"]
const PRESENTS_SHOWN := 4

var service: OnlineService
var view: StringName = &""
var info := {}
var note: Label
## Words to show on the next page (what the last action did).
var told := ""
## The crew maker's picks.
var pick_adjective := 0
var pick_noun := 0
var pick_badge := 0


func _ready() -> void:
	name = "FriendsPage"
	add_theme_constant_override("separation", 12)
	custom_minimum_size.x = SchoolUi.FRAME.x
	open()


func open() -> void:
	if not service.has_server():
		var v := _page(SOON, "Friends")
		v.add_child(OnlineUi.words("Friends need the internet. Ask a grown-up to try again later.", 28, 900))
		_back_row(v, [])
		return
	var c := _page(CONNECTING, "Friends")
	c.add_child(OnlineUi.words("Connecting...", 30))
	_back_row(c, [])
	var err := await service.sign_in()
	if not is_inside_tree():
		return
	if err == "" and not service.claimed() and UsernameRules.validate(service.profile.username) == "":
		await service.claim_username(service.profile.username)
	if err != "":
		_show_failed(err)
	elif not service.claimed():
		_show_claim()
	else:
		await refresh(FRIENDS)


## Reads the server again and shows `tab`.
func refresh(tab: StringName = FRIENDS) -> void:
	var r := await service.social_info()
	if not is_inside_tree():
		return
	if str(r.get("text", "")) != "":
		_show_failed(str(r.text))
		return
	info = r
	if r.get("allowed", true) == false:
		var v := _page(NOT_ALLOWED, "Friends")
		v.add_child(OnlineUi.words("Friends play online. A grown-up can turn it on in PLAY ONLINE.", 28, 900))
		_back_row(v, [])
		return
	match tab:
		PRESENTS:
			show_presents()
		CREW:
			show_crew()
		_:
			show_friends()


func _show_failed(text: String) -> void:
	var v := _page(FAILED, "Friends")
	v.add_child(OnlineUi.words(text, 28, 900))
	var alone := OnlineUi.play_alone(text)   # owner #93: what works without the internet
	if alone != null:
		v.add_child(alone)
	var again := OnlineUi.button("TRY AGAIN", UiKit.GREEN, Vector2(300, 84))
	again.pressed.connect(open)
	_back_row(v, [again])


func _show_claim() -> void:
	_clear(CLAIM)
	var claim := UsernameClaim.new()
	claim.service = service
	claim.done.connect(func() -> void: refresh(FRIENDS))
	claim.have_account.connect(func() -> void: closed.emit())
	add_child(claim)
	var back := OnlineUi.button("BACK", UiKit.BLUE, Vector2(220, 72))
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back.pressed.connect(func() -> void: closed.emit())
	add_child(back)


# --- FRIENDS -----------------------------------------------------------------------------------------------------

func show_friends() -> void:
	var v := _tabbed(FRIENDS)
	var body := HBoxContainer.new()
	body.alignment = BoxContainer.ALIGNMENT_CENTER
	body.add_theme_constant_override("separation", 24)
	v.add_child(body)
	var feed := OnlineUi.column(8)
	feed.name = "Feed"
	feed.custom_minimum_size.x = 440
	feed.add_child(_line(FriendshipRules.CHEER_LINE, 26, Color.WHITE))
	var moments: Array = info.get("feed", [])
	if moments.is_empty():
		feed.add_child(_line("When a friend lands on the Moon or masters a unit, you can cheer them here.", 20,
			Color(1, 1, 1, 0.75)))
	for i in mini(moments.size(), FEED_SHOWN):
		var m: Dictionary = moments[i]
		var row := OnlineUi.column(4)
		row.add_child(_line(FriendshipRules.moment_words(str(m.get("name", "")), str(m.get("kind", "")),
			str(m.get("place", ""))), 20, SchoolUi.GOLD))
		var quick: Array[Control] = []
		for id: String in QUICK_CHEERS:
			var one := OnlineUi.button(FriendshipRules.cheer_words(id).to_upper(), UiKit.ORANGE, Vector2(150, 64))
			one.name = "Cheer%d_%s" % [i, id]
			one.add_theme_font_size_override("font_size", 20)
			one.pressed.connect(_cheer.bind(str(m.get("id", "")), id))
			quick.append(one)
		var more := OnlineUi.button("MORE", Color(0.2, 0.24, 0.36), Vector2(135, 64))
		more.name = "Cheer%d" % i
		more.add_theme_font_size_override("font_size", 20)
		more.pressed.connect(show_cheer.bind(m))
		quick.append(more)
		row.add_child(OnlineUi.row(quick, 6))
		feed.add_child(row)
	body.add_child(feed)
	var list := OnlineUi.column(8)
	list.name = "Friends"
	list.custom_minimum_size.x = 680
	var friends: Array = info.get("friends", [])
	if friends.is_empty():
		list.add_child(_line(FriendshipRules.NO_FRIENDS, 22, Color.WHITE, 680))
		var invite := OnlineUi.button("INVITE A FRIEND", OnlineUi.PURPLE, Vector2(320, 72))
		invite.name = "InviteAFriend"
		invite.pressed.connect(func() -> void: invite_requested.emit())
		list.add_child(invite)
	for i in mini(friends.size(), FRIENDS_SHOWN):
		list.add_child(_friend_row(friends[i], i))
	if friends.size() > FRIENDS_SHOWN:
		list.add_child(_line("and %d more friends" % (friends.size() - FRIENDS_SHOWN), 18, Color(1, 1, 1, 0.75)))
	body.add_child(list)


## One friend: the name, the friendship level and the next one, GIFT, and study buddies.
func _friend_row(f: Dictionary, i: int) -> PanelContainer:
	var box := PanelContainer.new()
	box.name = "Friend%d" % i
	box.add_theme_stylebox_override("panel", UiKit.box(Color(1, 1, 1, 0.08), 14, 8))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	box.add_child(row)
	var words := OnlineUi.column(2)
	words.custom_minimum_size.x = 400
	var days := int(f.get("days", 0))
	var level := int(f.get("level", 0))
	words.add_child(_line("%s  -  %s" % [str(f.get("name", "")), FriendshipRules.title(level)], 22,
		SchoolUi.GOLD if level > 0 else Color.WHITE, 400))
	words.add_child(_line(FriendshipRules.days_words(days) + ". " + FriendshipRules.next_words(days), 16,
		Color(1, 1, 1, 0.75), 400))
	var b: Dictionary = f.get("buddy", {})
	var state := str(b.get("state", ""))
	if state == "yes":
		words.add_child(_line("%s. %s" % [FriendshipRules.buddy_words(int(b.get("days", 0))),
			FriendshipRules.buddy_row_words(b.get("row", []))], 16, SchoolUi.GOOD, 400))
	elif state == "asked":
		words.add_child(_line("You asked: study buddies?", 16, Color(1, 1, 1, 0.75), 400))
	row.add_child(words)
	var gift := OnlineUi.button("GIFT", UiKit.GREEN, Vector2(135, 64))
	gift.name = "Gift"
	gift.pressed.connect(show_pick_present.bind(f))
	row.add_child(gift)
	var id := str(f.get("id", ""))
	match state:
		"asking":
			var yes := OnlineUi.button("BUDDY: YES", UiKit.ORANGE, Vector2(135, 64))
			yes.name = "BuddyYes"
			yes.add_theme_font_size_override("font_size", 20)
			yes.pressed.connect(_buddy.bind("yes", id))
			row.add_child(yes)
		"", "asked":
			var ask := OnlineUi.button("BUDDY?", OnlineUi.PURPLE, Vector2(135, 64))
			ask.name = "BuddyAsk"
			ask.add_theme_font_size_override("font_size", 22)
			ask.disabled = state == "asked"
			ask.pressed.connect(_buddy.bind("ask", id))
			row.add_child(ask)
		"yes":
			var stop := OnlineUi.button("STOP BUDDY", Color(0.2, 0.24, 0.36), Vector2(135, 64))
			stop.name = "BuddyStop"
			stop.add_theme_font_size_override("font_size", 18)
			stop.pressed.connect(_buddy.bind("stop", id))
			row.add_child(stop)
	return box


func show_cheer(m: Dictionary) -> void:
	var v := _page(CHEER, "Send a cheer")
	v.add_child(OnlineUi.words(FriendshipRules.moment_words(str(m.get("name", "")), str(m.get("kind", "")),
		str(m.get("place", ""))).trim_suffix(" Send a cheer?"), 28, 1000))
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 12)
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	for id: String in FriendshipRules.CHEER_IDS:
		var b := OnlineUi.button(FriendshipRules.cheer_words(id), UiKit.ORANGE, Vector2(330, 84))
		b.name = "Cheer_" + id
		b.pressed.connect(_cheer.bind(str(m.get("id", "")), id))
		grid.add_child(b)
	v.add_child(grid)
	v.add_child(OnlineUi.words("Cheers are kind words only. Your friend sees your name and the cheer.", 20, 1000))
	var back := OnlineUi.button("BACK", UiKit.BLUE, Vector2(220, 72))
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back.pressed.connect(show_friends)
	v.add_child(back)


func _cheer(moment_id: String, cheer: String) -> void:
	var err := await service.send_cheer(moment_id, cheer)
	told = err if err != "" else "Your cheer is on its way!"
	await refresh(FRIENDS)


func _buddy(action: String, friend_id: String) -> void:
	var r := await service.study_buddy(action, friend_id)
	if str(r.get("text", "")) != "":
		told = str(r.text)
	else:
		match str(r.get("state", "")):
			"asked":
				told = "Asked! When your friend says yes, you're study buddies."
			"yes":
				told = "Study buddies! " + FriendshipRules.BUDDY_GOAL
			_:
				told = "Done. You're still friends."
	await refresh(FRIENDS)


# --- PRESENTS ----------------------------------------------------------------------------------------------------

func show_presents() -> void:
	var v := _tabbed(PRESENTS)
	var body := HBoxContainer.new()
	body.alignment = BoxContainer.ALIGNMENT_CENTER
	body.add_theme_constant_override("separation", 30)
	v.add_child(body)
	var inbox := OnlineUi.column(8)
	inbox.name = "Inbox"
	inbox.custom_minimum_size.x = 620
	inbox.add_child(_line("Presents for you", 26, Color.WHITE))
	var presents: Array = info.get("presents", [])
	var waiting := presents.filter(func(p: Dictionary) -> bool: return not p.get("opened", false) or not p.get("thanked", false))
	if waiting.is_empty():
		inbox.add_child(_line("No presents waiting. Friends can send you one a day.", 20, Color(1, 1, 1, 0.75)))
	for i in mini(waiting.size(), PRESENTS_SHOWN):
		inbox.add_child(_present_row(waiting[i], i))
	body.add_child(inbox)
	var give := OnlineUi.column(8)
	give.name = "Give"
	give.custom_minimum_size.x = 460
	give.add_child(_line("Give a present", 26, Color.WHITE))
	give.add_child(_line("One present a day to each friend: %d left today. Tap GIFT beside a friend." % int(
		info.get("sends_left", FriendPresents.SENDS_PER_DAY)), 20, Color(1, 1, 1, 0.85), 460))
	var links: Array = info.get("link_gifts", [])
	give.add_child(_line("A present for a new friend waits on your invite code: the next friend who joins with it opens " \
		+ "it. %d of %d waiting." % [links.size(), FriendPresents.LINK_GIFTS_MAX], 20, Color(1, 1, 1, 0.85), 460))
	var link := OnlineUi.button("GIFT FOR A NEW FRIEND", OnlineUi.PURPLE, Vector2(420, 72))
	link.name = "GiftNewFriend"
	link.add_theme_font_size_override("font_size", 24)
	link.disabled = links.size() >= FriendPresents.LINK_GIFTS_MAX
	link.pressed.connect(show_pick_present.bind({}))
	give.add_child(link)
	body.add_child(give)


func _present_row(p: Dictionary, i: int) -> PanelContainer:
	var box := PanelContainer.new()
	box.name = "Present%d" % i
	box.add_theme_stylebox_override("panel", UiKit.box(Color(1, 1, 1, 0.08), 14, 8))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	box.add_child(row)
	var kind := str(p.get("kind", ""))
	var name_ := str(p.get("name", ""))
	var words := "%s sent you %s!" % [name_, FriendPresents.name_of(kind)] if not p.get("opened", false) \
		else "%s from %s" % [FriendPresents.name_of(kind).capitalize(), name_]
	if p.get("link", false) == true and not p.get("opened", false):
		words = "Your guide %s left you %s!" % [name_, FriendPresents.name_of(kind)]
	row.add_child(PresentIcon.new(kind, 56.0))
	row.add_child(_line(words, 20, FriendPresents.color_of(kind).lightened(0.4), 340))
	var id := str(p.get("id", ""))
	if not p.get("opened", false):
		var open_it := OnlineUi.button("OPEN", UiKit.GREEN, Vector2(160, 64))
		open_it.name = "Open"
		open_it.pressed.connect(_open.bind(id))
		row.add_child(open_it)
	elif not p.get("thanked", false):
		var thanks := OnlineUi.button("THANK YOU", UiKit.ORANGE, Vector2(190, 64))
		thanks.name = "ThankYou"
		thanks.add_theme_font_size_override("font_size", 24)
		thanks.pressed.connect(_thank.bind(id))
		row.add_child(thanks)
	return box


func _open(present_id: String) -> void:
	var r := await service.open_present(present_id)
	told = str(r.text) if str(r.get("text", "")) != "" else str(r.get("gave", ""))
	await refresh(PRESENTS)


func _thank(present_id: String) -> void:
	var err := await service.thank_present(present_id)
	told = err if err != "" else "Thank you sent! Your friend gets a small gift back."
	await refresh(PRESENTS)


## Which present: for `friend` ({id, name}), or for a new friend when it is {} (it waits on the invite code).
func show_pick_present(friend: Dictionary) -> void:
	var for_new := friend.is_empty()
	var v := _page(PICK_PRESENT, "A present for a new friend" if for_new else "A present for %s" % str(friend.get("name", "")))
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 16)
	for kind: String in FriendPresents.KINDS:
		var col := OnlineUi.column(6)
		var pic := PresentIcon.new(kind, 96.0)
		pic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		col.add_child(pic)
		var b := OnlineUi.button(FriendPresents.title_of(kind), FriendPresents.color_of(kind), Vector2(260, 90))
		b.name = "Kind_" + kind
		b.add_theme_font_size_override("font_size", 26)
		b.pressed.connect(_send.bind(str(friend.get("id", "")), kind))
		col.add_child(b)
		col.add_child(_line(FriendPresents.what_it_is(kind), 18, Color(1, 1, 1, 0.8), 260))
		row.add_child(col)
	v.add_child(row)
	v.add_child(OnlineUi.words("Presents are free: one a day to each friend. Only the kind of present is sent.", 20, 1000))
	var back := OnlineUi.button("BACK", UiKit.BLUE, Vector2(220, 72))
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back.pressed.connect(show_presents if for_new else show_friends)
	v.add_child(back)


func _send(friend_id: String, kind: String) -> void:
	var r: Dictionary
	if friend_id == "":
		r = await service.send_link_present(kind)
	else:
		r = await service.send_present(friend_id, kind)
	if str(r.get("text", "")) != "":
		told = str(r.text)
	elif friend_id == "":
		told = "Your present waits on your invite code for a new friend!"
	else:
		told = "Your present is on its way!"
	await refresh(PRESENTS if friend_id == "" else FRIENDS)


# --- CREW --------------------------------------------------------------------------------------------------------

func show_crew() -> void:
	var v := _tabbed(CREW)
	var crew: Variant = info.get("crew")
	if crew is Dictionary:
		_crew_page(v, crew)
		return
	v.add_child(OnlineUi.words(CrewRules.ABOUT, 26, 1000))
	var invites: Array = info.get("crew_invites", [])
	for i in mini(invites.size(), 3):
		var inv: Dictionary = invites[i]
		var row := HBoxContainer.new()
		row.name = "Invite%d" % i
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 12)
		row.add_child(BadgeIcon.new(str(inv.get("badge", "")), 56.0))
		row.add_child(_line("%s asks you to join the %s (%d of %d)" % [str(inv.get("from", "")), str(inv.get("name", "")),
			int(inv.get("members", 0)), CrewRules.MAX], 20, SchoolUi.GOLD, 560))
		var join := OnlineUi.button("JOIN", UiKit.GREEN, Vector2(150, 64))
		join.name = "Join"
		join.disabled = inv.get("full", false) == true
		join.pressed.connect(_crew.bind("join", {"crew": str(inv.get("crew", ""))}))
		row.add_child(join)
		var no := OnlineUi.button("NO THANKS", UiKit.BLUE, Vector2(190, 64))
		no.name = "Decline"
		no.add_theme_font_size_override("font_size", 22)
		no.pressed.connect(_crew.bind("decline", {"crew": str(inv.get("crew", ""))}))
		row.add_child(no)
		v.add_child(row)
	var make := OnlineUi.button("MAKE A CREW", UiKit.GREEN, Vector2(340, 84))
	make.name = "MakeCrew"
	make.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	make.pressed.connect(show_make_crew)
	v.add_child(make)
	v.add_child(OnlineUi.words(CrewRules.ROCKET_LATER, 20, 1000))


func _crew_page(v: VBoxContainer, crew: Dictionary) -> void:
	var top := HBoxContainer.new()
	top.alignment = BoxContainer.ALIGNMENT_CENTER
	top.add_theme_constant_override("separation", 16)
	top.add_child(BadgeIcon.new(str(crew.get("badge", "")), 64.0))
	var name_ := UiKit.title(str(crew.get("name", "")), 36)
	name_.name = "CrewName"
	top.add_child(name_)
	v.add_child(top)
	var members: Array = crew.get("members", [])
	v.add_child(_line(CrewRules.size_words(members.size()), 20, Color(1, 1, 1, 0.85), 1000))
	var row := HBoxContainer.new()
	row.name = "Members"
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)
	for i in members.size():
		var m: Dictionary = members[i]
		var col := OnlineUi.column(2)
		col.name = "Member%d" % i
		var fig := MemberFigure.new(m.get("look", {}) if m.get("look") is Dictionary else {})
		fig.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		col.add_child(fig)
		for l: Label in [_line(str(m.get("name", "")) + (" (you)" if m.get("me", false) == true else ""), 18, Color.WHITE, 180),
				_line(CrewRules.week_words(m.get("week", {}) if m.get("week") is Dictionary else {}), 14, Color(1, 1, 1, 0.75), 180)]:
			l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			col.add_child(l)
		row.add_child(col)
	v.add_child(row)
	var goal: Dictionary = crew.get("goal", {})
	var bar := GoalBar.new(int(goal.get("done", 0)), int(goal.get("target", 1)))
	bar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(bar)
	var words := _line(CrewRules.goal_words(int(goal.get("done", 0)), int(goal.get("target", 1))), 20, SchoolUi.GOLD, 1000)
	words.name = "Goal"
	v.add_child(words)
	var buttons: Array[Control] = []
	if members.size() < CrewRules.MAX:
		var invite := OnlineUi.button("INVITE A FRIEND TO THE CREW", OnlineUi.PURPLE, Vector2(440, 64))
		invite.name = "CrewInvite"
		invite.add_theme_font_size_override("font_size", 22)
		invite.pressed.connect(show_pick_crewmate)
		buttons.append(invite)
	var leave := OnlineUi.button("LEAVE THE CREW", Color(0.2, 0.24, 0.36), Vector2(260, 64))
	leave.name = "LeaveCrew"
	leave.add_theme_font_size_override("font_size", 22)
	leave.pressed.connect(_crew.bind("leave", {}))
	buttons.append(leave)
	v.add_child(OnlineUi.row(buttons, 14))


func show_make_crew() -> void:
	var v := _page(MAKE_CREW, "Make a crew")
	v.add_child(OnlineUi.words("Pick your crew's name and badge. Your friends see them.", 24, 1000))
	var name_ := UiKit.title(CrewRules.name_of(CrewRules.ADJECTIVES[pick_adjective], CrewRules.NOUNS[pick_noun]), 44)
	name_.name = "CrewName"
	var pickers := HBoxContainer.new()
	pickers.alignment = BoxContainer.ALIGNMENT_CENTER
	pickers.add_theme_constant_override("separation", 40)
	pickers.add_child(_stepper("Adjective", "FIRST WORD", func(d: int) -> void:
		pick_adjective = posmod(pick_adjective + d, CrewRules.ADJECTIVES.size())
		show_make_crew()))
	pickers.add_child(_stepper("Noun", "SECOND WORD", func(d: int) -> void:
		pick_noun = posmod(pick_noun + d, CrewRules.NOUNS.size())
		show_make_crew()))
	v.add_child(name_)
	v.add_child(pickers)
	var badges := HBoxContainer.new()
	badges.name = "Badges"
	badges.alignment = BoxContainer.ALIGNMENT_CENTER
	badges.add_theme_constant_override("separation", 10)
	for i in CrewRules.BADGES.size():
		var b := Button.new()
		b.name = "Badge_" + CrewRules.BADGES[i]
		b.custom_minimum_size = Vector2(96, 96)
		b.toggle_mode = true
		b.button_pressed = i == pick_badge
		var icon := BadgeIcon.new(CrewRules.BADGES[i], 72.0)
		icon.position = Vector2(12, 12)
		icon.size = Vector2(72, 72)
		b.add_child(icon)
		b.pressed.connect(func() -> void:
			pick_badge = i
			show_make_crew())
		badges.add_child(b)
	v.add_child(badges)
	var make := OnlineUi.button("MAKE THE CREW", UiKit.GREEN, Vector2(340, 80))
	make.name = "MakeTheCrew"
	make.pressed.connect(func() -> void: _crew("make", {"adjective": CrewRules.ADJECTIVES[pick_adjective],
		"noun": CrewRules.NOUNS[pick_noun], "badge": CrewRules.BADGES[pick_badge]}))
	var back := OnlineUi.button("BACK", UiKit.BLUE, Vector2(200, 80))
	back.pressed.connect(show_crew)
	v.add_child(OnlineUi.row([back, make], 18))


## "<  >" over "FIRST WORD": steps through a word list.
func _stepper(what: String, label: String, step: Callable) -> VBoxContainer:
	var prev := OnlineUi.button("<", UiKit.BLUE, Vector2(135, 64))
	prev.name = "Prev" + what
	prev.pressed.connect(step.bind(-1))
	var next := OnlineUi.button(">", UiKit.BLUE, Vector2(135, 64))
	next.name = "Next" + what
	next.pressed.connect(step.bind(1))
	var v := OnlineUi.column(2)
	v.add_child(OnlineUi.row([prev, next], 10))
	v.add_child(OnlineUi.words(label, 18, 280))
	return v


func show_pick_crewmate() -> void:
	var v := _page(PICK_CREWMATE, "Invite a friend to the crew")
	var crew: Dictionary = info.get("crew", {}) if info.get("crew") is Dictionary else {}
	var in_crew: Array[String] = []
	for m: Dictionary in crew.get("members", []):
		in_crew.append(str(m.get("name", "")))
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 12)
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var n := 0
	for f: Dictionary in info.get("friends", []):
		if in_crew.has(str(f.get("name", ""))) or n >= 9:
			continue
		var b := OnlineUi.button(str(f.get("name", "")), OnlineUi.PURPLE, Vector2(320, 72))
		b.name = "Mate%d" % n
		b.pressed.connect(_crew.bind("invite", {"user_id": str(f.get("id", ""))}))
		grid.add_child(b)
		n += 1
	if n == 0:
		v.add_child(OnlineUi.words("Every friend is in your crew, or you have no friends here yet. Add friends in PLAY ONLINE!",
			24, 1000))
	v.add_child(grid)
	var back := OnlineUi.button("BACK", UiKit.BLUE, Vector2(220, 72))
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back.pressed.connect(show_crew)
	v.add_child(back)


func _crew(action: String, payload: Dictionary) -> void:
	var r := await service.crew_action(action, payload)
	if str(r.get("text", "")) != "":
		told = str(r.text)
	else:
		match action:
			"make":
				told = "Your crew is ready! Invite friends to fill its seats."
			"invite":
				told = "Invitation sent!"
			"join":
				told = "Welcome to the crew!"
			"leave":
				told = "You left the crew. You can make or join another any time."
			_:
				told = ""
	await refresh(CREW)


# --- Pieces -------------------------------------------------------------------------------------------------------

## A page with the FRIENDS / PRESENTS / CREW tabs (the one showing lit) and the last action's words.
func _tabbed(tab: StringName) -> VBoxContainer:
	var v := _page(tab, "Friends")
	var tabs := HBoxContainer.new()
	tabs.name = "Tabs"
	tabs.alignment = BoxContainer.ALIGNMENT_CENTER
	tabs.add_theme_constant_override("separation", 14)
	var presents: Array = info.get("presents", [])
	var unopened := presents.filter(func(p: Dictionary) -> bool: return not p.get("opened", false)).size()
	var invites: Array = info.get("crew_invites", [])
	for t: Array in [[FRIENDS, "FRIENDS"], [PRESENTS, "PRESENTS" + (" (%d)" % unopened if unopened > 0 else "")],
			[CREW, "CREW" + (" (%d)" % invites.size() if invites.size() > 0 and not (info.get("crew") is Dictionary) else "")]]:
		var b := OnlineUi.button(t[1], OnlineUi.PURPLE if t[0] == tab else Color(0.2, 0.24, 0.36), Vector2(250, 60))
		b.name = "Tab_" + String(t[0])
		b.add_theme_font_size_override("font_size", 24)
		b.pressed.connect(_show_tab.bind(t[0]))
		tabs.add_child(b)
	var back := OnlineUi.button("BACK", UiKit.BLUE, Vector2(160, 60))
	back.name = "Back"
	back.pressed.connect(func() -> void: closed.emit())
	tabs.add_child(back)
	v.add_child(tabs)
	note = _line(told, 20, SchoolUi.GOLD, 1000)
	note.name = "Note"
	note.visible = told != ""
	v.add_child(note)
	told = ""
	return v


func _show_tab(tab: StringName) -> void:
	match tab:
		PRESENTS:
			show_presents()
		CREW:
			show_crew()
		_:
			show_friends()


func _page(v: StringName, title: String) -> VBoxContainer:
	_clear(v)
	var box := OnlineUi.column(10)
	box.add_child(ReadAloud.with_speaker(UiKit.title(title, 34), box))
	add_child(box)
	return box


func _back_row(box: VBoxContainer, extra: Array[Control]) -> void:
	var back := OnlineUi.button("BACK", UiKit.BLUE, Vector2(200, 68))
	back.pressed.connect(func() -> void: closed.emit())
	var all: Array[Control] = [back]
	all.append_array(extra)
	box.add_child(OnlineUi.row(all, 18))


func _line(text: String, font_size: int, color: Color, width: float = 440.0) -> Label:
	var l := OnlineUi.words(text, font_size, width)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT if width < 1000.0 else HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_color_override("font_color", color)
	return l


func _clear(v: StringName) -> void:
	view = v
	note = null
	OnlineUi.clear(self)


## A crew's badge, drawn (the font has no pictures): a coloured round badge with its picture.
class BadgeIcon:
	extends Control
	var badge := ""

	func _init(p_badge: String = "", side: float = 64.0) -> void:
		badge = p_badge
		custom_minimum_size = Vector2(side, side)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var r := minf(size.x, size.y) * 0.5
		var c := size * 0.5
		draw_circle(c, r, CrewRules.badge_color(badge))
		draw_arc(c, r - 2.0, 0.0, TAU, 40, Color(1, 1, 1, 0.8), 3.0, true)
		var ink := Color(1, 1, 1, 0.95)
		match badge:
			"rocket":
				draw_colored_polygon(PackedVector2Array([c + Vector2(0, -r * 0.6), c + Vector2(r * 0.22, -r * 0.15),
					c + Vector2(r * 0.22, r * 0.4), c + Vector2(-r * 0.22, r * 0.4), c + Vector2(-r * 0.22, -r * 0.15)]), ink)
				draw_colored_polygon(PackedVector2Array([c + Vector2(-r * 0.22, r * 0.1), c + Vector2(-r * 0.45, r * 0.5),
					c + Vector2(-r * 0.22, r * 0.4)]), ink)
				draw_colored_polygon(PackedVector2Array([c + Vector2(r * 0.22, r * 0.1), c + Vector2(r * 0.45, r * 0.5),
					c + Vector2(r * 0.22, r * 0.4)]), ink)
			"star":
				draw_colored_polygon(SchoolUi.star_points(c, r * 0.62), ink)
			"moon":
				draw_circle(c, r * 0.55, ink)
				draw_circle(c + Vector2(r * 0.28, -r * 0.18), r * 0.48, CrewRules.badge_color(badge))
			"planet":
				draw_circle(c, r * 0.4, ink)
				draw_arc(c, r * 0.62, deg_to_rad(200.0), deg_to_rad(340.0), 20, ink, 3.0, true)
			"comet":
				draw_circle(c + Vector2(r * 0.25, -r * 0.25), r * 0.25, ink)
				draw_line(c + Vector2(r * 0.1, -r * 0.1), c + Vector2(-r * 0.5, r * 0.5), ink, 5.0)
			"owl":   # big round eyes, ear tufts, a beak
				draw_colored_polygon(PackedVector2Array([c + Vector2(-r * 0.45, -r * 0.1), c + Vector2(-r * 0.4, -r * 0.55),
					c + Vector2(-r * 0.15, -r * 0.3)]), ink)
				draw_colored_polygon(PackedVector2Array([c + Vector2(r * 0.45, -r * 0.1), c + Vector2(r * 0.4, -r * 0.55),
					c + Vector2(r * 0.15, -r * 0.3)]), ink)
				for side: float in [-1.0, 1.0]:
					draw_circle(c + Vector2(side * r * 0.22, 0), r * 0.2, ink)
					draw_circle(c + Vector2(side * r * 0.22, 0), r * 0.09, CrewRules.badge_color(badge).darkened(0.4))
				draw_colored_polygon(PackedVector2Array([c + Vector2(-r * 0.08, r * 0.2), c + Vector2(r * 0.08, r * 0.2),
					c + Vector2(0, r * 0.38)]), Color("f2b61d"))
			"fox":   # a pointed face with tall ears
				draw_colored_polygon(PackedVector2Array([c + Vector2(-r * 0.5, -r * 0.2), c + Vector2(r * 0.5, -r * 0.2),
					c + Vector2(0, r * 0.5)]), ink)
				draw_colored_polygon(PackedVector2Array([c + Vector2(-r * 0.5, -r * 0.2), c + Vector2(-r * 0.4, -r * 0.6),
					c + Vector2(-r * 0.15, -r * 0.2)]), ink)
				draw_colored_polygon(PackedVector2Array([c + Vector2(r * 0.5, -r * 0.2), c + Vector2(r * 0.4, -r * 0.6),
					c + Vector2(r * 0.15, -r * 0.2)]), ink)
				draw_circle(c + Vector2(0, r * 0.42), r * 0.07, Color("1f2a4a"))
			_:   # the whale: a round body, a tail and a spout
				draw_circle(c + Vector2(-r * 0.1, r * 0.1), r * 0.36, ink)
				draw_colored_polygon(PackedVector2Array([c + Vector2(r * 0.2, r * 0.1), c + Vector2(r * 0.6, -r * 0.15),
					c + Vector2(r * 0.55, r * 0.35)]), ink)
				draw_line(c + Vector2(-r * 0.15, -r * 0.3), c + Vector2(-r * 0.15, -r * 0.55), ink, 3.0)
				draw_line(c + Vector2(-r * 0.15, -r * 0.45), c + Vector2(-r * 0.3, -r * 0.6), ink, 3.0)
				draw_line(c + Vector2(-r * 0.15, -r * 0.45), c + Vector2(0, -r * 0.6), ink, 3.0)


## A crew member's avatar, drawn from the look the server keeps (AvatarIcon.figure).
class MemberFigure:
	extends Control
	var look: AvatarLook

	func _init(d: Dictionary = {}) -> void:
		look = AvatarLook.from_dict(d)
		custom_minimum_size = Vector2(80, 96)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		AvatarIcon.figure(self, Rect2(Vector2.ZERO, size), look.resolve(), EmotePoses.rest())


## The crew's week: learning days together against the goal (a bar that fills; never who brought more).
class GoalBar:
	extends Control
	var done := 0
	var target := 1

	func _init(p_done: int = 0, p_target: int = 1) -> void:
		done = p_done
		target = maxi(p_target, 1)
		name = "GoalBar"
		custom_minimum_size = Vector2(620, 26)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		draw_rect(r, Color(1, 1, 1, 0.15))
		draw_rect(Rect2(Vector2.ZERO, Vector2(size.x * clampf(float(done) / target, 0.0, 1.0), size.y)), SchoolUi.GOLD)
		draw_rect(r, Color(1, 1, 1, 0.6), false, 2.0)
