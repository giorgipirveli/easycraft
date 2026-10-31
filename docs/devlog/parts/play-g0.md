# Play G0: the foundation every game stands on (owner #122, re-scoped by #133, #134)

The owner (2026-10-17 18:49, #122): "all lessons should be game, part of game, mini games and etc but games, not
lectures and slides and classical lessons, this is why we are not school, we are something more … this must be future
of education". The brief: `docs/superpowers/plans/2026-10-17-play-g0-brief.md`; the authority:
`docs/design/learning-is-play.md` (spec §22.0). Built by the Play G0 agent in the worktree branch
`worktree-agent-af1233244fecc639d`, cut from `lead-merge` at `c078d217`. Re-scoped the same night by the owner's #133
and #134 (section 0: what holds now).

## 0. Re-scoped: the foundation, not the games (owner #133, #134)

The owner, 2026-10-17 23:36 (#133): "consider no one will start reading in the game, we have to rethink all this, try to
deliver education without just reading"; 23:40 (#134): "noone will start reading and learning the lessons when playing
game, so each game needs a lot time power and thinking … we need future lessons, not just texts with visuals like
slides". The lead's answer, `docs/design/future-lessons.md` (`db3cd502`), is the authority now over learning-is-play.md
§5 and §8: depth before breadth, one deep game at a time, each passing five tests (choice, mute, cheat, transfer, wow).
G0's goal changed from "every unit is a game at once" to **the foundation every deep game stands on**. Where §§1-7 below
describe the first build, this section and the rulings from 28 say what holds now.

**What the foundation is (DEVELOPMENT.md, "The foundation's API, for the game agents"):**
1. **The loop engine** (`PlayLoop`, `PlayHost`): the hook, the try, see why, play, the world task, come back; a short
   round (`setup(…, count)`) for Play W1's crystals.
2. **The automatic voice** (`PlayVoice`, the HUD's rule 0): every line spoken at once by itself, the big ear repeats,
   a thing says its name when touched, at most 7 words on the screen while a challenge plays, the buttons and the
   count as pictures (`PlayGlyph`), the world answers without a written "Correct!". Read to me is on for everyone
   (`ff49983f`); without a voice the words show.
3. **Show, then do** (the ghost's demonstration): a new unit's first challenge of each mechanic is shown one step
   first (`PlayStation.demo_kind`: do one step, show it, or nothing where one act answers it), then "Your turn!".
4. **The place, flat and VR** (`PlayArena`, `PlayStation`, `PlayHost`): as first built (§1, §3).
5. **The bridge to the record: `SkillShown`.** A game says what the child showed (SOLVED, NEW_SETTING, HELPED,
   SHOWN), and `record` turns each unit's events into a round as `MasteryRules` counts one: stars, the gold once,
   reviews, the grown-ups' page, a friend's reward, postcards, learning together. No quiz screens. The School's own
   rounds and the arena record through it too.
6. **DISCOVER and its map:** a game picture only on units that play; PLAY where a unit plays; the School as it was
   elsewhere. Play W1 opens DISCOVER from the world and starts crystals with `PlayHost.plays` + `setup(…, count)` +
   `SkillShown` (DEVELOPMENT.md shows the call).
7. **The audit's play levels and the reading debt** (`PlayReadless`, `tools/play_audit.py`, `tools/play_debt.gd`):
   §6.

**Kept, shelved, dropped (and why), against future-lessons.md §2's five tests:**

| What | Now | Why |
|---|---|---|
| Make it, Order it, Sort it, Connect it, Fix it, Build it, Code it, Beat it, Mix it, Find it | **kept**, for challenges that play without reading (things: pictures, numbers, names of at most 3 words, spoken when touched; a question of at most 16 words, spoken) | the action is the answer (mute: passes with the voice; cheat: a quantity, an order, a sort or a wiring is not guessed in one go) |
| Choose by doing (choice), Test it (truefalse) | **shelved**: the loop never plays them; their stations and tests stay in the code for a deep game with a real use for a picture choice | a written question in costume: the child still reads it (mute: fails), and a guess wins a third or half of the time (cheat: fails) |
| Sorting, ordering or matching sentences; long word problems | **dropped from play** (they stay in the School's PRACTICE) | reading is the move (mute: fails) |
| "Every unit playable" (818 of 818) | **dropped**: 404 units play; 414 stay in the School as they were (LESSON, then PRACTICE), P0 with their reading debt | quality, not breadth (#134) |
| PLAY first on every unit page, the old round reached by no button | **replaced**: PLAY only where a unit plays; LESSON and PRACTICE back for the rest | a reading unit is not dressed as a game |
| Words on the play screen (the question, the coach's card, the world's line, the break card, the buttons) | **replaced by the voice** (and pictures); kept only without a voice | rule 0 |
| The twelve example play blocks (grade 4) | **kept** as the format's examples; six of their units play, six stay in the School | the format is the units' (hook spoken, `game` names a deep game) |

**Honestly, against the five tests:** what G0 plays today passes *mute* (every line spoken, at most 7 words on the
screen: `test_play_voice.gd`) and mostly *cheat* (the kept acts), but not *wow* (one plain meadow, a table and a
shelf for every subject) and has no *transfer* levels; *choice* is unknown until the owner's child plays. The generic
mechanics are the foundation's verbs and the fallback, not future lessons: those are the deep games (wave 1: Size Magic
Voyages: Inside a Leaf, Balance Altar, Fraction Bakery), which bring the first P1s and report through `SkillShown`.

## 1. Reported before building: the pattern for the places

**Picked: both, in one way: Life's room is the base, the host is new.** Every unit plays in one small place, the
**play arena** (`PlayArena`, a `LifeRoom` subclass in `entities/play/`): Life's targets with forgiving radii, its flat
views and VR spots, its glow, its kit (`LifeRoomKit`: only shaders the warm-up already holds), its buddies
(`LifeBuddy`), placed far above the menu's world like Life's rooms with its own calm sky. A new host, `PlayHost`, runs
a unit's loop there: Life's way of turning a finger (flat) or the hands, the laser and the head (VR) into one input a
frame (`LifeReach.screen_pick`, `touching`, `ray_hit`), Life's coach (`LifeGhostFinger` flat, `LifeGhostHands` in VR,
extended to carry a thing from one place to another), the VR anchor and blink, the HUD routed onto the panel in a
headset (`UiLayers.route`). In the arena each challenge builds its mechanic's **station** (a component: one
`PlayStation` subclass per mechanic: Make it, Sort it, Order it, Connect it, Fix it, Build it, Code it, Beat it, Mix
it, Find it, Choose by doing, Test it), so a round of six mixed exercises (a number, a sort, a choice…) plays in one
place without loading another room. The station turns what the child did into a response in `ExerciseCheck`'s own
form, and **`ExerciseCheck.is_right` is the referee**; the round's result goes to **`MasteryRules.after_round`**
exactly as the old round's did.

**Rejected: each unit as a Life Experience in `LifeRoomHost` / `ToolRoomHost`** (the exercises translated into
`LifeCheck` steps: a sequence step for an order, touch steps for a sort, a choose step for a choice).

**Why:**
1. *The referee.* `LifeCheck` judges every touch as it happens (a wrong press is a miss at once, the right one moves the
   step on); `ExerciseCheck` judges a whole answer (six planks in order, every item in its bin, a number made). Steps
   would either change what "right the first time" means (and so the stars, the reviews and the gold) or need a second
   referee beside `ExerciseCheck`. The brief keeps `ExerciseCheck` the referee and `MasteryRules` the record.
2. *The shape.* Life's host is shaped for Experiences (tracks, Passport stamps, safe mistakes, danger time, the Expert
   try, 24 step kinds), and each Life room is built by hand for its Experience. G0 needs twelve parametric mechanics
   fed by 13,100 hand-written exercises and 1,091 generators that make new ones every round: a place has to be built
   from the exercise, not from a script of steps.
3. *The record.* The School's progress (stars, reviews, the gold once, the daily mission, the grown-ups' page) is
   `SchoolData`'s; Life's is the Passport's. One host per record keeps both honest.

*Cost if wrong:* two hosts share their input code by copying (about 250 lines of sampling); joining them later is a
refactor of that sampling into one shared component, with no change to either's rules or data.

*As built, one difference from this report:* the ghost hands were not extended: they show each of the coach's taps in
turn (a carry is two: the thing, then its place), and `LifeGhostHands` and `LifeGhostFinger` are used as they are.

## 2. What a child sees and does (as it stands after the re-scope)

**DISCOVER.** The main menu's School button says **DISCOVER** (ruling 12). The first visit: Professor Hoot says
"Welcome to DISCOVER: play, explore and learn!" (read aloud) and asks the grade. The map ("Grade 4: places to play";
"Pick a stop. A picture on it means a game!") shows each subject's units; a stop carries its game's little picture
(`PlayIcon`) only when the unit plays without reading. A unit that plays: its goals and standards (for grown-ups),
**You play:** its games with their pictures, Hoot's line ("Play first! …"), the big **PLAY** (**PLAY: REVIEW**), and two
small buttons, **THE BOOK** (the cards, read aloud, ending in LET'S PLAY!) and **MY QUESTS**. A unit that doesn't play
yet: the School's page as it was before G0, **LESSON** then **PRACTICE** (REVIEW), its Book ending in LET'S PRACTISE!

**The place** (PLAY; the School hides): a little meadow, a wooden table in front of the child and a shelf behind,
Professor Hoot's bar at the top with a big ear, the eye (SHOW ME) and two bars (I NEED A BREAK) at the top right, the
world's test (a green triangle) at the bottom right and, after an answer, an arrow (NEXT). With the voice on (every
device with English text-to-speech, Read to me on: the default):
- **The hook** is spoken ("The bakery's pie tins are cut into eighths…"); the bar shows nothing but Hoot; the try's
  things are already on the table, and the first act (or 4 s) starts the try.
- **Each challenge's question is spoken** at once; the bar shows only its numbers ("300 + 40 + 7 = ?") or the
  mechanic's few words ("Sort them!", "Put them in order!", "Make it!"), and the count as dots. The ear says it again.
- **Show, then do:** in a unit the child has not played yet, the first challenge of each kind is shown first: once the
  question has been heard, the ghost finger (flat) or the ghost hands (VR) do one step (a card carried into its bin) or
  show it (the source to tap glows), then Hoot says "Your turn!". It still counts.
- **A thing says its name** when lifted ("three hundred forty-seven"), a bin its name when touched or when a thing
  lands in it.
- **The world answers:** right, the bins light, the buddy walks the bridge, the lamps light… and Hoot's praise is
  heard ("+5 gold" shows); a miss, the world reacts and the hint is heard, never written; the second miss, the ghost
  does a step; the third, the worked answer in the place, its words spoken.
- **See why:** after the try, Hoot's card with a triangle (LET'S PLAY!); its line is spoken.
- **I NEED A BREAK:** the calm card with a triangle (carry on) and a door (stop for now), its words spoken.
- **The end:** the round's stars and gold exactly as before (the School's page, read aloud), the world task as a quest
  card (TAKE IT WITH ME).
Without a voice (a device with no English voice, or Read to me turned off by a grown-up) every word shows, as first
built (§1-§3): the question in the bar, "2 of 6", the buttons' words, the world's line and the hint under the bar.

## 3. The twelve mechanics, flat and in VR (each with a unit the smoke plays)

Flat, a finger taps a thing (a fingertip's reach at least: `LifeReach.screen_pick`): a thing that can be carried lifts
(it rises and glows), a tap on its place puts it there, and a drag from the thing to its place does both; a second tap
on a lifted thing puts it back. In VR the child stands at the table: a hand squeezing (grip or trigger) at a thing picks
it up and it follows the hand; letting go over its place puts it there (elsewhere it goes home); squeezing at anything
else presses it; the laser's trigger taps what is far (the gates, the paths' signs). The world's test is a big green
button on a post at the table's right end, and the HUD's button.

| Type (hand-written) | Mechanic | What the child does | Smoke's unit |
|---|---|---|---|
| number (2,057) | **Make it** | makes the answer with things from the sources along the table's front: unit cubes into towers of ten (to 20: 864 exercises), base-ten blocks with tenths, hundredths and thousandths (881), gold coins (153), weights on the scale's pan (56: the scale tips only when tested), cups poured into the jug (30), fraction bars of three sizes filling up to three wholes (51), a frog's jumps along a line over the water (17 negatives); the counting machine's keys only when nothing else can make it within 40 pieces (5). The machine's sign reads what was made, never the answer. TEST IT. | g3.maths.numbers_to_10000 |
| sort (1,121) | **Sort it** | carries each card from the belt into its bin on the shelf; RUN THE MACHINE | g3.science.living_things |
| order (881) | **Order it** | lays each plank into the bridge's numbered gaps; WALK ACROSS: the buddy walks it | g3.maths.numbers_to_10000 |
| match (881) | **Connect it** | takes each plug (its wire follows) to its partner's socket; SWITCH ON: the lamps light | g3.science.living_things |
| label (57) | **Fix it** | puts each tag on its numbered pin on the picture's board (leaning back towards the child); START IT | g4.science.digestion_teeth |
| build (49) | **Build it** | taps squares of the wall (leaning back) or the farm (on the table) to place or take blocks; the game's Mirror shows as a line; CHECK THE BUILD | g3.maths.multiply_meaning |
| robot (24) | **Code it** | taps FORWARD, TURN LEFT, TURN RIGHT cards (TAKE ONE BACK); the program reads on the board; RUN THE ROBOT: it really runs | g3.computing.algorithms |
| rhythm (62) | **Beat it** | LISTEN, then taps each drum to a clap or a rest; MY RHYTHM plays them; PLAY IT | g3.english.poems_plays |
| mix (22) | **Mix it** | taps paint pots to add drops (EMPTY to start again); the bowl takes the colour; PAINT WITH IT | g3.art.colour_mixing |
| point (4) | **Find it** | taps a crossing of the treasure map (the spade goes there); DIG HERE: the chest comes up | g5.maths.coordinates |
| choice (5,854) | **Choose by doing** | GIVE: carries the right crate (its words or its picture) into the buddy's paws; PATH: sends the buddy down the path whose signpost is right (the gate at its end opens) | g3.maths.numbers_to_10000 |
| truefalse (2,322) | **Test it** | opens the TRUE gate or the FALSE gate in the hedge; right: the buddy runs through | g3.maths.numbers_to_10000 |

**Shelved by the re-scope (owner #134, section 0):** Choose by doing and Test it are no longer played; the paragraph
below is why. A kept mechanic plays a challenge only when it needs no reading (PlayReadless).

**The honest limit (the brief; design §5.1).** Choose by doing and Test it are the weakest bridge: 8,284 of the 13,559
hand-written challenges (61%). Giving a crate to a buddy or opening a gate makes the answer an act in a place, with the
world's reaction and a buddy who needs it, but the concept is still not the move that wins: take the knowledge away and
a child can still guess. They are a choice and a claim in costume. The play level (P0) on the audit and the grown-ups'
page keeps that visible until the signature games (G1-G5) replace them family by family; new units should keep choice
and true or false for what no act can show. The other ten mechanics are acts where the knowledge is the move: the
number is made, the things sorted, ordered, wired, labelled, built, coded, played, mixed or found.

## 4. How it is built

- `core/play/`: `PlayMechanics` (`data/play/mechanics.json`), `PlayBlock`, `PlayLoop`, `PlayMake`, `PlayPlacing`,
  `PlayChoose`, `PlayQuests` (pure; `tests/unit/test_play_*.gd`).
- `entities/play/`: `PlayArena` (a `LifeRoom`), `PlayStation` (the component: `tap`, `ghost`, `response`, `react`,
  `show_answer`), `PlacingStation`, `MakeStation`, `SortStation`, `OrderStation`, `ConnectStation`, `FixStation`,
  `BuildStation`, `CodeStation`, `BeatStation`, `MixStation`, `FindStation`, `ChooseStation`, `TestStation`,
  `PlayStations` (the factory), `PlayBoard`, `PlayKit`, `PlayHost`.
- `ui/play/`: `PlayHud` (the coach's bar, the world's line, the test, NEXT, SHOW ME, the break, the see-why card, the
  picture big, the tap area, the ghost finger), `PlayIcon`.
- Hooks (marked owner #122): `ui/school/school_screen.gd` (DISCOVER's words, the map's pictures, the unit page,
  `show_play`, `_record_round`, the quest card, MY QUESTS, the Book's end), `ui/school/school_grown_ups.gd` (play
  levels), `ui/menus/menu.gd` (DISCOVER; Back belongs to the place), `core/school/curriculum.gd` (keeps and checks
  `play`). No hook was needed in `core/life`, `entities/life` or `entities/tools`: G0 uses Life's classes as they are
  (`LifeRoom`, `LifeRoomKit`, `LifeBuddy`, `LifeReach`, `LifeGhostHands`, `LifeGhostFinger`).
- **The contract for G1-G5** (the G1 brief: "G0's play layer is your contract"): a signature game is a `PlayStation`
  subclass with `static func expresses(ex) -> bool`, registered by one entry in `data/play/mechanics.json`'s
  `"signature"` ({name, script}); a unit whose `play.game` names it is P1 and plays every exercise the game expresses in
  its station (`PlayStations.make(ex, game)`), the rest in G0's; the loop, the coach, the referee and the record are
  G0's (`tests/integration/test_play_games.gd`, with a stand-in game).
- Tools: `tools/play_audit.py`, `tools/play_debt.gd`, `tools/play_smoke.gd` (+ `_steps`), `tools/play_shots.gd` (+ `_steps`).
- **Added by the re-scope:** `PlayReadless` (what plays without reading; the debt), `SkillShown` (the bridge to the
  record; `SchoolScreen._record_round` calls `SkillShown.record_round`), `PlayVoice` and `PlayGlyph` (rule 0 in
  `PlayHud`: `set_voice`, the ear, the caption, the dots, the pictures, `screen_words`), `PlayStation.demo_kind` /
  `spoken_name` (and `PlacingStation`'s, `FindStation`'s), `PlayArena.label_words`, `PlayHost`'s demonstration
  (`DEMO_WAIT`, "Your turn!"), names on touch, `shown`, `setup(…, count)`, `plays`; `PlayLoop.make(…, count)` over
  `PlayReadless.content`; `PlayMechanics.say_of`, `kept`, `game_expresses`; the School's unit page and map
  (`PlayHost.plays`), the grown-ups' tooltip.
- Data: `data/play/mechanics.json`; twelve example play blocks in grade 4 (DEVELOPMENT.md, "The play block").
- School tests fixed to the new flow (they protect the same things): `test_school_screen.gd` (the hello, the goals with
  PLAY and the Book, the review, the Book read to the end then PLAY), `test_school_earn.gd` (an Explorer lesson's PLAY
  and no play before it is bought), `test_school_menu.gd`, `test_invite_menu.gd`, `test_friendship_page.gd` (DISCOVER).

## 5. Rulings (decided, with what each costs if wrong)

1. **One arena, a station per challenge** (not a place per mechanic): a round of six mixed exercises plays in one place
   with no loading. *Cost:* the places look alike (a meadow, a table, a shelf); G1's signature games bring their own.
2. **The try is the round's first challenge** (level 1 for a new unit; a review starts at its own level), so a round
   stays 6 and MasteryRules is unchanged. *Cost:* the try counts towards the stars like any challenge.
3. **Three tries:** not yet (the world and the hint) → the ghost's step → the worked answer (the panel showed the
   worked answer after two misses). *Cost:* one more try before the answer; right-the-first-time is unchanged.
4. **SHOW ME is help:** that challenge no longer counts (Life's way). *Cost:* a child who peeks loses that one's credit.
5. **The ghost does one step where the answer takes several; for a choice or a claim it only shows** (else the coach
   would answer). *Cost:* none.
6. **A miss clears the placed things where the School's answer widgets cleared** (sort, order, match, label) and keeps
   a build, a number made, a mix, a rhythm, a program, a point: the difficulty is the School's. *Cost:* none.
7. **Make it's world answers "Not enough yet." / "A little too much." after a test** (the scale tips then, never while
   building; the sign reads only what was made). *Cost:* a second try is a little easier than after the pad's plain
   "not yet"; the first try, which counts, is not.
8. **The maker comes from the answer and the prompt's words** (gold → coins, ml or litres → the jug, g or kg → the
   scale, a fraction to twelfths → bars, a negative → the frog, a whole to 20 → a tower, else base-ten blocks with up to
   three decimal places, else the machine's keys); a unit's play block may prefer one that can make the answer. *Cost:*
   5 of 2,057 number exercises play on the keys (the pad in costume).
9. **Base-ten offers one place more than the answer needs; fraction bars offer three sizes** (the answer's and two near
   it): the answer's size is not given away. *Cost:* a little more to choose from.
10. *(Superseded by ruling 31: shelved.)* **Choose by doing: GIVE or PATH by the round's seed** (a unit may choose); Test it: two gates. *Cost:* the weakest
    bridge, as above.
11. **The picture is on a board in the place**, facing whoever looks, drawn once into its own small canvas; a tap shows
    it big. The board's face is a copy of the kit's see-through material with the picture as its texture (the census key
    is the same: `test_play_stations.gd` checks it). *Cost:* if a browser compiles it at first sight anyway, a census run
    through a play place fixes it (the lead's).
12. **DISCOVER for children, the programme's words for grown-ups** (design ruling 3): "Welcome to DISCOVER: play,
    explore and learn!" (first "here every lesson is a game!": no longer true after the re-scope) *Cost:* the Gold Shop's lines still say "Find it in the SCHOOL" (not G0's files: the lead's).
13. *(The map's line now says "Pick a stop. A picture on it means a game!": only units that play carry one.)* **The
    map's title says "Grade N: places to play"** on screens and "Grade N" in a headset (its header is narrower).
    *Cost:* two titles; the spoken title says the same in both.
14. **The Book is the old lesson page** (the cards as they are, read aloud), ending in LET'S PLAY!; reading it to the
    end still marks the lesson read for grown-ups. *Cost:* none.
15. **Quest cards stay on the device** (`user://play_quests.json`: the unit's id, the task's words, done), never in the
    profile or the backup: nothing personal kept or sent. *Cost:* a new device starts with none; showing them in the
    world's HUD is a hook for the lead.
16. **MY QUESTS is on the unit page and, on a one-row map, the map's footer** (most grades have two rows of tabs: no
    room). *Cost:* one step further away.
17. **The grown-ups' page shows each unit's play level** (a small "P0" beside its title; the stats column 210 → 186 px,
    the two lists 24 → 10 px apart, the line about it shorter). *Cost:* a stats line of 12 rounds may clip a little.
18. *(Superseded by ruling 32: the round is the PRACTICE of every unit that doesn't play.)* **The old quiz round stays
    in the code, reached by no button** (`SchoolScreen.show_round`: its rules' tests and the
    VR audit's School round). *Cost:* code children never reach; it goes when those tests move to play.
19. **Back in the place asks "Leave the game?"** (`PlayHost.any_open` beside Life's in `menu.gd`). *Cost:* one line.
20. **In VR the child stands 0.9 m from the arena's middle**, every carried thing and its place within 1.1 m of the
    eyes (Life's rule), the rest within the laser's 8 m. *Cost:* a seated child may lean for the far bin.
21. **The budget: at most 100 draws at a station's heaviest** (a board's squares are its lines: a 12 x 10 build 170 →
    75; an 8 x 8 robot board 108 → 60), one light, no shadows, still pictures drawn once. *Cost:* plain squares.
22. **Life's tab and TODAY'S MISSION are untouched** (not G0's allocation): Life's units (its own and the 60 School
    units it lists) keep Life's own page (the lead's #122 change on lead-merge: TRY IT first, PRACTICE next, the BOOK
    last), whose PRACTICE is still the panel's round, and the Daily Mission is five questions on a panel. *Cost:* until
    the lead's hooks, a child can still meet a quiz there (`PlayHost` takes any unit's content: one call).
23. **The hook lasts until the first act, or 4 s** (rule 2: play first; the brief's 15 s is its longest). *Cost:* a
    slow reader taps the speaker.
24. **The example play blocks are grade 4's** (grades 7 and 8 belong to the content agents). *Cost:* none.
25. **A game controller can't act on the place's things yet** (Life's ruling 24); its buttons reach the HUD. *Cost:*
    pad players on a TV or PC play with the mouse or touch (the ease audit E0).
27. **The idle cue** (10 s without an act: every thing to act with glows for 3 s) is no help (the challenge still
    counts): it shows what can be touched, never which. *Cost:* none.
26. **Numbers from the School's files are JSON's floats** (an order's answer is [3.0, 2.0…]): the play rules read every
    answer number as an int (the smoke's first run found `Array.find` missing them). *Cost:* none.

**Rulings of the re-scope (owner #133, #134; they win over the ones above where they differ: 10, 12, 13 and 18 are
superseded as noted in them):**

28. **The voice decides the screen:** with a voice and Read to me on, every line is spoken and the screen keeps at most
    7 words; without (no English voice on the device, or Read to me turned off by a grown-up) every word shows.
    *Cost:* a child who can't read, on a device without text-to-speech (some Linux desktops, a browser without speech),
    can't play by ear; the lead checks the phones, the web and the Quest have a voice.
29. **Every line cuts in** (`ReadAloud.speak`): the newest is heard. *Cost:* a fast child cuts Hoot's praise short by
    pressing NEXT.
30. **What plays without reading:** a kept mechanic, things of at most 3 words, a question of at most 16 words; a unit
    plays with at least 3 such hand-written challenges or one such generator (all its sampled exercises at every
    level). *Cost:* some 17-20-word word problems and 4-word names stay in the School; a unit with 3 challenges repeats
    them in a round of 6 (each in a new layout).
31. **Written choices and claims are never played** (Choose by doing and Test it shelved: their stations and tests kept,
    never routed). *Cost:* 8,284 hand-written challenges are reached only by reading (the School's PRACTICE), until
    deep games replace them; code no child reaches until a game wants a picture choice.
32. **A unit that doesn't play stays in the School as it was before G0** (LESSON, then PRACTICE or REVIEW; its Book
    ends in LET'S PRACTISE!; no game picture on its stop). *Cost:* 414 of 818 units are still read-then-quizzed: the
    honest P0 of future-lessons.md §6.
33. **A unit that plays offers PLAY and the Book, not PRACTICE:** its written questions are not reached by a child.
    *Cost:* a reader can't practise them; a small PRACTICE button is one line if the lead wants it back.
34. **Show, then do, for a new unit only** (no stars): the first challenge of each mechanic in the round, once the
    question has been heard (0.6 s after the voice stops): the ghost does one step where several remain (placing),
    shows it otherwise (a quantity, a build, a program, a beat, a mix), and never where one act answers it (Find it). It
    still counts; any act of the child's first skips it. *Cost:* a novice's first challenge of a kind is one step
    easier (the worked-example effect is the point).
35. **The question's caption:** the prompt itself when it has at most 3 words and 40 letters (mostly its numbers), else
    the mechanic's `say`. *Cost:* a child who can read a little sees "Sort them!" instead of the question (the ear
    repeats it).
36. **The buttons are pictures while the voice speaks** (eye, two bars, triangle, arrow, door, cross; their words in the
    tooltip; the 3D test button has none); the count is dots; the gold says "+5 gold". *Cost:* a picture has to be
    learnt once (Hoot's demonstration shows the triangle).
37. **`SkillShown` needs ROUND_SIZE events to change a unit not mastered yet**; fewer count only as a review of a
    mastered unit. *Cost:* a crystal's minute (3-5 challenges) never gives a new unit its first star (its answers'
    gold is still paid).
38. **A deep game keeps whatever it expresses** (a P1 unit's exercises the game plays count as playable, whatever their
    type). *Cost:* a game could express a written choice; its own five tests (phase B's gate) are the guard.
39. **P0 means the School's own** on the grown-ups' page (its tooltip: "N of M questions play without reading").
    *Cost:* a tooltip shows only under a pointer (not on a phone).
40. **The twelve example play blocks stay** (format examples; six of their units play). *Cost:* their Choose by doing
    costumes are unused.
41. **The 818 units' words are untouched:** the Book is the cards as they are (future-lessons.md §6). *Cost:* none.

## 6. The count: play levels and the reading debt (2026-10-18, on the branch merged with lead-merge `e00b3752`)

`tools/play_debt.gd` (PlayReadless itself, generators run) and `tools/play_audit.py` (the hand-written part; the test
keeps the two equal). Every unit is P0 (no deep game yet: P1 0). "Plays" is a unit whose page offers PLAY.

| Grade | Units | Plays | Challenges that play | Reading debt | written choices | claims | long questions | words on things | Book cards | Book words |
|---|---|---|---|---|---|---|---|---|---|---|
| 3 | 137 | 65 | 464 | 2,005 | 1,100 | 445 | 88 | 372 | 1,037 | 27,667 |
| 4 | 137 | 62 | 349 | 1,880 | 1,017 | 384 | 126 | 353 | 1,040 | 31,261 |
| 5 | 136 | 61 | 349 | 1,912 | 1,014 | 414 | 115 | 369 | 1,023 | 30,984 |
| 6 | 136 | 73 | 431 | 1,891 | 1,057 | 379 | 136 | 319 | 1,015 | 30,058 |
| 7 | 136 | 73 | 442 | 1,832 | 971 | 359 | 165 | 337 | 1,003 | 31,987 |
| 8 | 136 | 70 | 367 | 1,637 | 763 | 381 | 163 | 330 | 932 | 28,835 |
| **All** | **818** | **404** | **2,402 (17.7%)** | **11,157 (82.3%)** | **5,922** | **2,362** | **793** | **2,080** | **6,050** | **180,792** |

Generators: 777 of the units' 3,387 generator entries play (every sampled exercise at every level plays). By subject
the games are where the acts are: maths (18 of 18 units in grades 3-5, 17 in 6, 15 in 7, 12 in 8), computing (6-11 a
grade), music (5-9); the fewest where everything is words: citizenship (0-3 a grade), English (0-10; grade 8: none),
health and PE (2-5). Two subjects of a grade have no unit that plays at all: grade 3 citizenship and grade 8 English
(the smoke says so). Of what plays, Make it is the most (68% in grade 8), then Sort it, Order it, Fix it, Connect it.

*Before the re-scope* (§§1-7's build): 818 of 818 units "playable", 61% of hand-written challenges through Choose by doing
or Test it; that was the slide in costume future-lessons.md §1 names.

## 7. Tests and measurements

- **Unit** (`tests/unit/test_play_*.gd`, 8 files): the mechanics' table (every ExerciseCheck type has one; no written
  unit has a type without one), the play block (format, defaults from the cards, the twelve examples), the loop (hook,
  try, see why, play, world, end; tries; help), Make it (every number of the School can be made, right, within 40
  pieces; exact sums; the ghost's step; too much or too little), placing (sort, order, match, label, JSON's floats),
  choose, quests, the audit (runs `tools/play_audit.py --check`).
- **Integration:** `test_play_stations.gd` (every type's station: the coach's steps always reach a right answer, the
  worked answer is right, a miss clears where the School cleared, every target in the free band of a 16:9 screen, carried
  things within a hand's reach in VR, only warmed shaders, no shadows, the board), `test_play_host.gd` (the loop flat and
  in a simulated headset: the hook, the try, see why, the round counted like a round, the misses, SHOW ME, the break, the
  hands carrying a thing to its bin), `test_play_screen.gd` (DISCOVER: PLAY first and the Book, the end recorded with
  the gold once, a weaker round, stopping, the quest card and MY QUESTS, the review, the map's pictures, every page fits,
  the grown-ups' play levels), `test_play_budget.gd` (every station at its heaviest: 26-78 draws, at most 100),
  `test_play_vr_hud.gd` (every word 24 px or more on the VR panel, inside it; the board faces the eyes).
- **The smoke** (`tools/play_smoke.gd`): 108 runs (12 types flat and VR; 72 units of every subject of every grade, flat;
  12 of grade 5 in VR), all pass. Its first run found the JSON floats (ruling 26) and a bin 1.10 m from the eyes.
- **Pictures** (`tools/play_shots.gd`, windowed): every station as it opens and with its worked answer; the stage was
  tuned from them (the flat view, the shelf, cards leaning back and fitting their words, boards leaning back).

**Added by the re-scope:** `test_play_readless.gd` (9: words and numbers, what plays, the shelved, a long question or
sentence cards, the limits are the file's, a unit's playable part, too little to play, generators, the debt),
`test_play_skill_shown.gd` (8: a round as MasteryRules counts it, help and shown answers don't count, transfer kept,
unknown kinds refused, a few events never master a new unit, a review of a mastered one, units on their own, the
answers' gold capped), `test_play_voice.gd` (10: every challenge's question spoken by itself, the ear, at most 7 words
on the screen for every kept station and every word on a thing a short name, the numbers shown when they are the
question, the world answers without words, a thing says its name, no voice shows the words, show then do, a one-act
answer never shown, a kind shown once and a known unit not shown), `test_play_loop.gd` (+3: written choices and claims
never come into play, a short round, nothing to play), `test_play_screen.gd` (+1: a reading unit stays in the School:
LESSON, PRACTICE, its Book ends in practice, no game picture), `test_play_mechanics.gd` (+1: the shelved say why),
`test_play_audit.gd` (the reading debt counted as the game plays). The smoke: **102 runs, all pass** (the 10 kept types
flat and VR; the first unit that plays of every subject of every grade, flat, and grade 5's in VR; it names the two
subjects with none, and the shelved types).

**The full suite** (`tests/run_tests.sh`, once, on the branch merged with lead-merge `95c3c900`, W1 stage 1 in: merge
`b18f6e7c`): **11,860 tests, 11,857 passing, 0 failing, 3 risky/pending, no script errors, exit 0** (5,507 s). The
three are not G0's: two world tests that don't assert (the column cache, the chunk seams) and the Nakama device move,
off on that server. Earlier runs, for the record: the first one on the pre-re-scope tree, right after a merge, had 96
failures, all from a stale class cache (`UpdateNote` from lead-merge not imported yet: "Identifier not declared");
the second, after `--import`, had 0 failures through 6,829 tests when it was stopped for the re-scope.

## 8. What the lead must check on the emulator and the Quest 3

1. **The voice** (the heart of rule 0): on the emulator (`Pixel_8_API_35`, Android's text-to-speech) and the Quest 3,
   PLAY a unit (`g4.maths.add_fractions`): the hook is spoken, then the question, at once and by themselves; the ear
   repeats; a card lifted says its words; Hoot's praise and the hint are heard and not written. If the Quest has no
   English voice, the play falls back to words (ruling 28): say so, it decides whether the Quest needs a voice pack.
2. **The screen while a challenge plays:** at most a few words (the numbers, or "Sort them!"), the dots, the pictures
   on the buttons (the eye, the two bars, the triangle, the arrow; the break card's triangle and door) drawn clearly on
   the phone and on the VR panel.
3. **Show, then do:** a unit never played (a fresh profile): after the first question is heard, the ghost finger (or
   the ghost hands in VR) carries one card into its bin, then "Your turn!"; a second sort in the round is not shown.
4. **A unit that doesn't play** (`g4.history.ancient_egypt`): LESSON and PRACTICE as before G0, no game picture on its
   stop; its Book ends in LET'S PRACTISE!
5. **The budget** (unchanged stations: at most 78 draws; the HUD's pictures are a few canvas shapes): ≥ 30 FPS and no
   frame over 100 ms in the arena on the emulator, and the Quest's frame rate there.
6. **Play W1** (stage 1 merged into this branch at `b18f6e7c`): its `DiscoverPanel.make_screen` ("the one call the lead
   switches") needs no switch: `SchoolScreen` *is* G0's DISCOVER and its map. Two hooks in W1's files (not G0's): its
   `room_open()` and `close()` know Life's room host but not the School's play place: they should also treat
   `(screen as SchoolScreen).play_host` (open: `not play_host.closed`; close: `play_host.stop_for_now()`), or ask
   `PlayHost.any_open(get_tree())`, so Back and the pause key belong to the place while a child plays from the world;
   and check the world's HUD layers don't show over the play place (PlayHost hides only the layer it was opened from).
   W1's crystals (stage 2) go through `PlayHost.plays` + `setup(…, count)` and the outcome's `shown.record(…)`
   (DEVELOPMENT.md, "The foundation's API").

## 9. Next (the foundation's open ends, for the lead and the game agents)
- **The deep games** (future-lessons.md §5, wave 1) build on this: their stations or scenes, `PlayVoice` for every line,
  the ghost's first step, `SkillShown` for what the child showed (with NEW_SETTING for transfer levels), a registry
  entry under `signature` to make their units P1.
- **The reading debt shrinks** as games replace families of units (the audit counts it each time), never by dressing
  questions.
- **Life's PRACTICE and TODAY'S MISSION** are still questions on a panel (not G0's files): `PlayHost` and `SkillShown`
  take them in one call each.
- **A game controller** can't act on the place's things yet (ruling 25).
