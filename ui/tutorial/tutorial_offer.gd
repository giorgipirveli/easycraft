class_name TutorialOffer
extends QuestOverlay
## The tutorial's two cards (M3 Task 15, spec §14.9), a QuestOverlay page (it takes touches before the HUD):
## - the offer at the first Survivor start: Pip ("Hi! I'm Pip!") with PLAY WITH PIP and SKIP. SKIP is a real choice
##   (never asked again); a tap outside the card or the pause menu decides nothing (`later`: asked next time);
## - the end: "You did it!" with the reward the first time (500 gold, Pip's Cap, Pip as a pet), or a well done.
## Every card is read aloud with "Read to me"; the speaker beside the title reads it any time.

signal play
signal skip
## Closed without a choice: the offer comes again next time.
signal later

var play_button: Button
var skip_button: Button
var ok_button: Button

var _asking := false


func _init() -> void:
	box_width = 720.0


func _ready() -> void:
	super()
	closed.connect(func() -> void:
		if _asking:
			_asking = false
			later.emit())


## PLAY WITH PIP / SKIP; `resume`: a stopped tutorial goes on where it stopped.
func offer(resume: bool) -> void:
	clear()
	var head := row(20)
	head.add_child(AnimalPortrait.new(PetRules.PIP, 150.0))
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	col.add_child(ReadAloud.with_speaker(words(TutorialRules.line(&"tutorial_hello"), 40, 0.0, GOLD), content))
	col.add_child(words(TutorialRules.line(&"tutorial_resume" if resume else &"tutorial_offer"), 30, 420.0))
	head.add_child(col)
	content.add_child(head)
	var buttons := row(24)
	play_button = button("PLAY WITH PIP", UiKit.GREEN, Vector2(340, 100), "PlayWithPip")
	play_button.pressed.connect(_choose.bind(play))
	buttons.add_child(play_button)
	skip_button = button("SKIP", UiKit.BLUE, Vector2(220, 100), "SkipTutorial")
	skip_button.pressed.connect(_choose.bind(skip))
	buttons.add_child(skip_button)
	content.add_child(buttons)
	_asking = true
	show_overlay()
	ReadAloud.auto(TutorialRules.line(&"tutorial_hello"))
	ReadAloud.auto(TutorialRules.line(&"tutorial_resume" if resume else &"tutorial_offer"))


## The end: `rewarded` shows what the first finish gives (the host has paid it); later finishes say well done.
func reward(rewarded: bool) -> void:
	_asking = false
	clear()
	var title := TutorialRules.line(&"tutorial_done" if rewarded else &"tutorial_again_done")
	content.add_child(ReadAloud.with_speaker(words(title, 40, 0.0, GOLD), content))
	if rewarded:
		var gifts := row(30)
		gifts.add_child(_gift(ProgressPicture.new(&"coin", 90.0), &"tutorial_reward_gold"))
		gifts.add_child(_gift(ProgressPicture.new(&"gift", 90.0), &"tutorial_reward_hat"))
		gifts.add_child(_gift(AnimalPortrait.new(PetRules.PIP, 90.0), &"tutorial_reward_pip"))
		content.add_child(gifts)
	var buttons := row()
	ok_button = button("OK", UiKit.GREEN, Vector2(240, 90), "TutorialOk")
	ok_button.pressed.connect(close)
	buttons.add_child(ok_button)
	content.add_child(buttons)
	show_overlay()
	ReadAloud.auto(title)
	if rewarded:
		for line: StringName in [&"tutorial_reward_gold", &"tutorial_reward_hat", &"tutorial_reward_pip"]:
			ReadAloud.auto(TutorialRules.line(line))


func _gift(pic: Control, line: StringName) -> VBoxContainer:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	col.add_child(pic)
	col.add_child(words(TutorialRules.line(line), 24, 190.0))
	return col


func _choose(what: Signal) -> void:
	_asking = false
	close()
	what.emit()
