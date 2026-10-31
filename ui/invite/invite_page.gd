class_name InvitePage
extends VBoxContainer
## Owner #79, #81, #82, #85 (spec §25.2; the world game plan §2, §2b): INVITE A FRIEND, from the main menu. "Bring a
## friend to school!" It signs in (a code lives on the server), claims the child's own name when the account has none
## (the friend is told their guide's name; a taken name asks for another, UsernameClaim), then shows:
## - MAIN: the code, big, to read out; the link; COPY LINK, SHARE (a browser's own share sheet), QR CODE; what both
##   friends get and why; the explorers the child brought (their in-game names, learned or not), the Explorer Tree's
##   count, the rank and the next one, the month's friend gold; the grown-ups' line; I HAVE A CODE (a new account that
##   has not used one) and GROWN-UPS (class and family codes, behind the parent gate).
## - QR: the link as a QR code another phone's camera reads.
## - CODE: InviteCodeBox (a friend's, class or family code).
## - GATE, GROWN_UPS: GrownUpGate, then the class and family codes (make, show, remove).
## Nothing pushes: no timers, no "invite or lose", no ranking of children; a child with no one to invite is told the
## game is all theirs. Every page fits the menu's frame (SchoolUi.FRAME).

signal closed

const SOON := &"soon"
const CONNECTING := &"connecting"
const FAILED := &"failed"
const CLAIM := &"claim"
const MAIN := &"main"
const QR := &"qr"
const CODE := &"code"
const GATE := &"gate"
const GROWN_UPS := &"grown_ups"
const FRIENDS_SHOWN := 3

var service: OnlineService
## Copies text for the child (tests record it); SHARE opens the browser's sheet (tests pretend).
var copy_text := func(t: String) -> void: DisplayServer.clipboard_set(t)
var can_share := func() -> bool: return WebGlue.can_share()
var share := func(text: String, url: String) -> bool: return WebGlue.share(text, url)
var view: StringName = &""
var info := {}
var note: Label


func _ready() -> void:
	name = "InvitePage"
	add_theme_constant_override("separation", 14)
	custom_minimum_size.x = SchoolUi.FRAME.x
	open()


## Signs in (once), makes sure the account has its name, reads the page from the server.
func open() -> void:
	if not service.has_server():
		var v := _page(SOON, "Invite a friend")
		v.add_child(OnlineUi.words("Invite codes need the internet. Ask a grown-up to try again later.", 28, 900))
		_back_row(v, [])
		return
	var c := _page(CONNECTING, "Invite a friend")
	c.add_child(OnlineUi.words("Connecting...", 30))
	_back_row(c, [])
	var err := await service.sign_in()
	if not is_inside_tree():
		return
	if err == "" and not service.claimed() and UsernameRules.validate(service.profile.username) == "":
		await service.claim_username(service.profile.username)   # the name the child picked: one friend-facing name
	if err != "":
		_show_failed(err)
	elif not service.claimed():
		_show_claim()
	else:
		await refresh()


func refresh() -> void:
	var r := await service.invite_info()
	if not is_inside_tree():
		return
	if r.text != "":
		_show_failed(r.text)
		return
	info = r
	show_main()


# --- Pages --------------------------------------------------------------------------------------------------------

func _show_failed(text: String) -> void:
	var v := _page(FAILED, "Invite a friend")
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
	claim.done.connect(refresh)
	claim.have_account.connect(func() -> void: closed.emit())   # PLAY ONLINE signs another device in (behind its gate)
	add_child(claim)
	var back := OnlineUi.button("BACK", UiKit.BLUE, Vector2(220, 72))
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back.pressed.connect(func() -> void: closed.emit())
	add_child(back)


func show_main() -> void:
	var v := _page(MAIN, "Invite a friend")
	v.add_theme_constant_override("separation", 8)
	v.add_child(_line(InviteRules.WHY, 24, Color.WHITE, 1160))
	var code := str(info.get("code", ""))
	var body := HBoxContainer.new()
	body.alignment = BoxContainer.ALIGNMENT_CENTER
	body.add_theme_constant_override("separation", 36)
	v.add_child(body)
	# The code, the link and the ways to pass them on.
	var left := OnlineUi.column(6)
	left.custom_minimum_size.x = 560
	left.add_child(_line("Your invite code", 22, Color(1, 1, 1, 0.8)))
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UiKit.box(SchoolUi.PAPER, 18, 12))
	var big := OnlineUi.words(code, 46, 520)
	big.name = "Code"
	big.add_theme_color_override("font_color", SchoolUi.INK)
	card.add_child(big)
	left.add_child(card)
	var link := _line(InviteRules.link(code), 18, Color(1, 1, 1, 0.75))
	link.name = "Link"
	left.add_child(link)
	var buttons: Array[Control] = []
	var copy := OnlineUi.button("COPY LINK", UiKit.BLUE, Vector2(200, 64))
	copy.pressed.connect(_copy)
	buttons.append(copy)
	if can_share.call():
		var sh := OnlineUi.button("SHARE", UiKit.GREEN, Vector2(160, 64))
		sh.pressed.connect(func() -> void: share.call(InviteRules.share_text(code), InviteRules.link(code)))
		buttons.append(sh)
	var qr := OnlineUi.button("QR CODE", OnlineUi.PURPLE, Vector2(180, 64))
	qr.pressed.connect(show_qr)
	buttons.append(qr)
	left.add_child(OnlineUi.row(buttons, 14))
	note = _line("", 20, SchoolUi.GOLD)
	note.name = "Note"
	note.visible = false
	left.add_child(note)
	var rewards: Dictionary = info.get("rewards", {})
	left.add_child(_line("Your friend gets %d gold at once. When they learn a whole unit: you +%d gold, them +%d." % [
		int(rewards.get("welcome", InviteRules.WELCOME_GOLD)), int(rewards.get("inviter", InviteRules.INVITER_GOLD)),
		int(rewards.get("learner", InviteRules.LEARNER_GOLD))], 20, SchoolUi.GOLD))
	body.add_child(left)
	body.add_child(_explorers())
	v.add_child(_line(InviteRules.NO_ONE_LINE, 20, Color(1, 1, 1, 0.8), 1160))
	var grown := _line(InviteRules.GROWN_UP_LINE, 16, Color(1, 1, 1, 0.65), 1160)
	grown.name = "GrownUpLine"
	v.add_child(grown)
	var extra: Array[Control] = []
	if info.get("can_use_code", false) == true:
		var have := OnlineUi.button("I HAVE A CODE", UiKit.ORANGE, Vector2(280, 64))
		have.pressed.connect(show_code_box)
		extra.append(have)
	var grownups := OnlineUi.button("GROWN-UPS", Color(0.2, 0.24, 0.36), Vector2(250, 64), &"grownup")
	grownups.pressed.connect(_show_gate)
	extra.append(grownups)
	_back_row(v, extra)


## The explorers this child brought, the tree, the rank, the month.
func _explorers() -> VBoxContainer:
	var right := OnlineUi.column(4)
	right.name = "Explorers"
	right.custom_minimum_size.x = 540
	var counts: Dictionary = info.get("counts", {})
	var friends_n := int(counts.get("friends", 0))
	var learned := int(counts.get("learned", 0))
	right.add_child(_line("Your explorers", 24, Color.WHITE))
	if friends_n == 0:
		right.add_child(_line("No friends yet. When a friend joins with your code, they show here.", 20,
			Color(1, 1, 1, 0.8)))
	else:
		right.add_child(_line("%d joined, %d learned a whole unit" % [friends_n, learned], 20, Color.WHITE))
		var list: Array = info.get("friends", [])
		for i in mini(list.size(), FRIENDS_SHOWN):
			var f: Dictionary = list[i]
			var who := str(f.get("name", "")) if str(f.get("name", "")) != "" else "A new explorer"
			var theirs := int(f.get("friends", 0))   # the tree's second level: a count, never names
			var line := _line("%s  %s%s" % [who, "- learned!" if f.get("learned", false) == true else "- joined",
				"  (brought %d)" % theirs if theirs > 0 else ""], 20,
				SchoolUi.GOLD if f.get("learned", false) == true else Color.WHITE)
			line.name = "Friend%d" % i
			right.add_child(line)
		if list.size() > FRIENDS_SHOWN:
			right.add_child(_line("and %d more" % (list.size() - FRIENDS_SHOWN), 18, Color(1, 1, 1, 0.8)))
	var tree := _line(InviteRules.tree_words(int(counts.get("children_learning", 0))), 22, SchoolUi.GOLD)
	tree.name = "Tree"
	right.add_child(tree)
	var rank := InviteRules.rank_for(learned)
	var next := InviteRules.next_rank(learned)
	if not rank.is_empty():
		right.add_child(_line("%s: %s" % [rank.title, rank.reward], 20, SchoolUi.GOLD))
	if not next.is_empty():
		var more := int(next.at) - learned
		right.add_child(_line("Next: %s, %d more friend%s who learn%s" % [next.title, more, "" if more == 1 else "s",
			"s" if more == 1 else ""], 18, Color(1, 1, 1, 0.8)))
	var month: Dictionary = info.get("month", {})
	var caps: Dictionary = info.get("caps", {})
	if friends_n > 0:
		var earned := _line("Gold from friends so far: %d  (this month %d of %d friends)" % [int(info.get("earned", 0)),
			int(month.get("learned", 0)), int(caps.get("learned", 10))], 18, Color(1, 1, 1, 0.75))
		earned.name = "Earned"
		right.add_child(earned)
	var groups: Dictionary = info.get("groups", {})
	for kind: String in ["class", "family"]:
		if groups.get(kind) is Dictionary:
			var g: Dictionary = groups[kind]
			right.add_child(_line("Your %s: %d explorers, %d learned" % [kind, int(g.get("members", 0)), int(g.get("learned", 0))],
				18, Color.WHITE))
	return right


func show_qr() -> void:
	var v := _page(QR, "Scan to join")
	var code := str(info.get("code", ""))
	var qr := QrView.new(InviteRules.link(code), 360.0)
	qr.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(qr)
	v.add_child(OnlineUi.words(code, 40, 900))
	v.add_child(OnlineUi.words("A grown-up points another phone's camera here.", 22, 900))
	var back := OnlineUi.button("BACK", UiKit.BLUE, Vector2(220, 72))
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back.pressed.connect(show_main)
	v.add_child(back)


func show_code_box() -> void:
	_clear(CODE)
	var box := InviteCodeBox.new()
	box.service = service
	box.at_start = false
	box.done.connect(func(_r: Dictionary) -> void: refresh())
	add_child(box)


func _show_gate() -> void:
	_clear(GATE)
	var gate := GrownUpGate.new()
	gate.passed.connect(show_grown_ups)
	gate.cancelled.connect(show_main)
	add_child(gate)


## Class and family codes (a grown-up, behind the gate): one code a whole class or family joins with.
func show_grown_ups() -> void:
	var v := _page(GROWN_UPS, "Class and family codes")
	v.add_child(OnlineUi.words("One code for a whole class or family. Everyone who joins is counted together; names are " \
		+ "never shown to other families. A new player who joins also gets the welcome gift.", 22, 1000))
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 40)
	var made: Dictionary = info.get("made", {})
	var groups: Dictionary = info.get("groups", {})
	for kind: String in ["class", "family"]:
		var col := OnlineUi.column(10)
		col.custom_minimum_size.x = 480
		col.add_child(_line(kind.to_upper(), 30, Color.WHITE))
		var code := str(made.get(kind, ""))
		if code == "":
			var make := OnlineUi.button("MAKE A %s CODE" % kind.to_upper(), UiKit.GREEN, Vector2(400, 76))
			make.name = "Make_" + kind
			make.pressed.connect(_group.bind("make", kind))
			col.add_child(make)
		else:
			col.add_child(_line(code, 34, SchoolUi.GOLD))
			var g: Dictionary = groups.get(kind, {}) if groups.get(kind) is Dictionary else {}
			col.add_child(_line("%d explorers, %d learned" % [int(g.get("members", 0)), int(g.get("learned", 0))], 22, Color.WHITE))
			var remove := OnlineUi.button("STOP THIS CODE", UiKit.RED, Vector2(320, 68))
			remove.name = "Remove_" + kind
			remove.pressed.connect(_group.bind("remove", kind))
			col.add_child(remove)
		row.add_child(col)
	v.add_child(row)
	var back := OnlineUi.button("BACK", UiKit.BLUE, Vector2(220, 72))
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back.pressed.connect(show_main)
	v.add_child(back)


func _group(action: String, kind: String) -> void:
	var r := await service.invite_group(action, kind)
	if not is_inside_tree():
		return
	if r.text != "":
		_show_failed(r.text)
		return
	var fresh := await service.invite_info()
	if fresh.text == "":
		info = fresh
	show_grown_ups()


# --- Pieces -------------------------------------------------------------------------------------------------------

func _copy() -> void:
	copy_text.call(InviteRules.share_text(str(info.get("code", ""))))
	if note:
		note.text = "Copied! A grown-up can paste it in a message."
		note.visible = true
	Audio.play(&"ui_click")


func _page(v: StringName, title: String) -> VBoxContainer:
	_clear(v)
	var box := OnlineUi.column(14)
	box.add_child(ReadAloud.with_speaker(UiKit.title(title, 36), box))
	add_child(box)
	return box


func _back_row(box: VBoxContainer, extra: Array[Control]) -> void:
	var back := OnlineUi.button("BACK", UiKit.BLUE, Vector2(200, 68))
	back.pressed.connect(func() -> void: closed.emit())
	var all: Array[Control] = [back]
	all.append_array(extra)
	box.add_child(OnlineUi.row(all, 18))


func _line(text: String, font_size: int, color: Color, width: float = 540.0) -> Label:
	var l := OnlineUi.words(text, font_size, width)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT if width < 1000.0 else HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_color_override("font_color", color)
	return l


func _clear(v: StringName) -> void:
	view = v
	note = null
	OnlineUi.clear(self)
