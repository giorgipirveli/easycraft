# Life L3c: Online City, Find Your Way, Home Helper, Life Town's third row (owner #112, #113, #117, #118)

The owner (2026-10-16, #112): life skills school doesn't teach; (#117) every skill with its real tools and devices; (#118)
dangerous things taught safely. The brief: `docs/superpowers/plans/2026-10-17-life-l3c-brief.md`; the design:
`docs/design/life-skills.md` §5 rows 7 (Online City), 10 (Find Your Way), 11 (Home Helper), §14 row 14 (people and
places) and its rules, with §3, §6, §10, §11, §13; owner #105's log-in rules (Online City's password lesson); the spec:
§27.7 ("As built (L3c)"). Built by the Life L3c agent in the worktree branch `worktree-agent-a78788effe83fe752`, on
`lead-merge` at `a3a4e75d`, with `lead-merge` merged again at `802d299b` (the School's grade 8 health and PE, D&T and
projects: no conflicts). On Life's framework as L3b left it (the safe mistake, the wrong moment, the time scale, the
intensity, the debrief), one small rule added (a device held in the hand). No editor, no emulator, no adb, no download
(a few web searches to check facts, nothing saved), no agents. Logs: the session scratchpad's `life3c_*`. The experts'
review sheet, written from the data: `docs/devlog/parts/life-l3c-review.md` (`tools/life_review_sheet.py`, the fifth
sheet; every source a checkbox).

## The framework's one small rule (test-first): a device held in the hand

The brief: "Online City ... on a play tablet (flat: the screen; VR: the tablet held in the hand, the device model; the
catalogue said 'flat first': both, a ruling)". `LifeRoom.held` is a device the child picks up (`holding` once its pick-up
step is done); `held_rest` is where it sits flat (in front of the view; also when the headset comes off:
`rest_held`). In VR `LifeRoomHost._hold_device` keeps it in the **off hand** every frame (the hand that doesn't point:
the left for a right-handed child), a little above the hand and towards the middle of the view, its face turned to the
eyes (`hold_pose`); the pointing hand (a finger on the button, squeezing) or the laser presses its buttons, and **the
holding hand never presses its own device's buttons** (`is_held_target`). Rooms without a held device play exactly as
before. Tests: `test_vr_the_tablet_is_held_in_the_off_hand_and_the_other_hand_presses`,
`test_the_tablet_is_picked_up_and_held`; the smoke checks the tablet stays within 0.3 m of the off hand on every VR frame
it is held.

## What a child does in each Experience

Every Experience: flat (a finger, the mouse) and in VR (hands, the laser, the head; the views blink between spots), on all
three tracks, each with its Expert try, the before-and-after picture check, the name-it card with its source, Try it for
real, the Passport's stamps, gold once. Online City and Find Your Way are `emergency` (the calm debrief after them); Home
Helper is not. Every hands-on step names its motion, tool and device (owner #117). No safe mistake on any Little track
(the coach says the rule first) and none in Home Helper's chores (a wrong bin, a spotty sock, a knife pointing up are kind
misses with their why).

### Online City (Life online; the practice living room and the play tablet)

Everything in it is pretend: no real sites, apps, brands or people; nothing the child types or says is kept or sent;
nothing personal is ever typed (every answer is a button or a picture); no microphone. A stranger online is only a grey
"?" on the screen, never a face. The tablet shows one page at a time (a step's `page`): Online City's map (the GAME PARK,
CHAT SQUARE, the NEWS STAND, the PHOTO WALL, the SHOP), chats with BLOCK and REPORT, pop-ups with an X.

- **Little, Online: ask, keep it private, tell (10 steps; Expert 11):** "Everything is pretend, and nothing you do is kept
  or sent" → pick up the play tablet → a new game: ask Gus first (touch him) → "Your name, your school and where you live
  stay private" (the rule first), then someone you don't know asks your name and where you live: don't answer, tell a
  grown-up → touch Gus (he blocks them) → a sad, worried screen: tell a grown-up (touch Gus; he closes it and gives a
  hug) → a pop-up's flashing button: close it with the X (the button is a kind miss: "ask a grown-up first") → Mo's
  rocket on the Photo Wall: a kind comment → TAKE A BREAK, stretch, look out of the window. Expert: a stranger asks for a
  photo too, nothing glows.
- **Middle, Strangers, mean posts, passwords and pop-ups (18 steps):** pick up → the GAME PARK → a player you don't know
  writes "You're good! Send me a photo of you. Where do you live?": **safe mistake: answering (SEND PHOTO)**: time
  freezes, a photo card frozen on its way to a grey "?" far off, "ONCE IT'S SENT, YOU CAN'T TAKE IT BACK"; the coach: "You
  can't know who someone online really is. Once a photo or where you live is sent, you can't take it back."; the right
  way: "Don't answer. Block them, then tell a grown-up." → BLOCK → tell Gus (he reports them) → an online friend asks to
  meet at the park: never (online friends you've never met are still strangers) → "you're bad at this game": don't reply,
  keep it to show a grown-up, BLOCK then REPORT → **the game's own password rules** (#105) for Bobo: the right picture is
  the game's own idea ("two words and a number that only Bobo would think of"), never a password to copy; the weak ones
  (bobo123, 123456, cat) are each refused by the game's `PasswordRules` too → Mo asks for your password: "Never tell anyone
  your password. Not even a friend." (`PasswordRules.NEVER_TELL`) → "FREE GOLD! Send your password": a trick → a pop-up
  "YOUR TABLET IS SLOW! DOWNLOAD THIS NOW!": the X (DOWNLOAD is a kind miss) → the News Stand's "Cats can talk on
  Tuesdays!": WHO MADE IT?, WHEN?, ANYONE ELSE? (nobody knows, no date, no one else) → a kind comment → a break (never
  guilt: "the game waits for you"). Expert: the stranger's BLOCK and the pop-up's X don't glow.
- **Big, Scams, fake news, privacy and passwords (16 steps):** pick up → a pretend profile: touch what stays private (MY
  SCHOOL, MY ADDRESS, PHOTO OF ME, MY PASSWORD; a picture name FOX and a favourite colour are fine) → think before you post
  → a friend request "I'm 12 too, from your school!": check with a grown-up → "let's meet, just the two of us": never, tell
  → **"FREE GOLD! Send your password": safe mistake: clicking GET GOLD**: time freezes, a little fishing hook frozen over
  the password card, "IT'S A TRICK TO TAKE YOUR ACCOUNT"; the coach: "It's a scam: a trick to take your account and
  everything in it. Real games never ask for your password."; the right way: "Close it, never give your password, and tell
  a grown-up. Report it if you can." → the X → phishing ("Your account will close today! Log in at this link"): open the
  game yourself → Kiki's password by the game's rules (kiki2024, qwerty, abc refused) → never shared, not even with a friend
  → the game's own brake (5 wrong tries in 15 minutes makes a guesser wait; a new device logs the old one out) → "Ice
  cream will be banned next week!": the three checks → a cat as big as a bus: a picture can be changed → a group chat
  laughing at Bobo's dance: don't join in, stand by him, report, tell → screens away an hour before bed. Expert: a new
  story ("Schools will open at midnight"), the profile and the X without glows.
- **VR:** the tablet lies on the low table; touching it (or the laser) picks it up, and from then on it is in the off
  hand, its face to the eyes; the pointing hand's finger (squeeze) or the laser presses its buttons; Gus is touched by
  laser or by hand (1.1 m).

### Find Your Way (Getting around; the practice market, school, metro and park)

The address and a grown-up's number are said aloud to a grown-up at home, never typed or kept: every track says "the
game never asks for them"; Try it for real on every track: "Say your address to your grown-up now". The school's
emergency is a **fire drill, never a lockdown** (§14's ruling). The man who says "come with me" is an ordinary figure who
only ever stands where he is (never shown grabbing or following; his words shown on a sign while he says them).

- **Little, Lost? Stay, and ask a safe grown-up (14 steps; Expert the same with no glows):** the practice market with Gus
  → your address and number: learned at home, said aloud; if lost, only to a police officer or a shop worker who is
  helping you (never online) → you can't see Gus → **STAY HERE** (be still 2 s; VR: the head still) → find two safe
  grown-ups (a shop worker with a name badge, a mum with her children, a police officer; each says who) → touch the shop
  worker: "I'm lost" ("Let's wait here together, and I'll call for your grown-up") → "Never go anywhere with anyone, even
  someone who says they'll help" (the rule first), then a man says "Come with me!": stay here and say no → Gus is back
  ("found you because you stayed put") → the practice school's fire drill bell: stand in the line behind the teacher →
  follow the teacher calmly to the meeting point (walk, don't run) → your pencil is inside: stay with your class (never go
  back in) → a landmark (the red bridge, not a cloud) → "In danger, 112 gets help." Expert: all three safe grown-ups and
  the line without glows.
- **Middle, Lost, the fire drill, the metro and the compass (20 steps):** your address and number by heart, aloud at home
  → lost again → STAY HERE → a man says "Come with me, I'll find your mum!": **safe mistake: walking off with him** (touch
  him): time freezes, a see-through figure of the child a few steps off towards the market's WAY OUT, soft footprints
  behind it, the man still where he stood, "WALKING AWAY MAKES YOU HARDER TO FIND"; the coach: "A safe grown-up helps you
  right where you are, where your grown-up can find you. Never go off with anyone, even if they say they'll help."; the
  right way: "Stay here, say no, and ask a shop worker with a name badge, a parent with children or a police officer." →
  the shop worker (Expert: she is busy: the police officer) → she may hear your grown-up's number aloud (never online) →
  Gus is back → the fire drill: leave your bag and drawing, the line, the meeting point, answer your name → the practice
  metro: the green line and the red line; `{metro_where}` (Georgia: "Tbilisi's metro has two lines too, and they meet at
  Station Square, where you change.") → from PARK (green) to ZOO (red): touch CENTRAL, where they meet (MARKET and HILL are
  kind misses: each on one line only) → tap the ticket on the gate's reader (the green light) → wait behind the yellow
  line (the edge is a kind miss) → the compass held flat: N, then E, S, W (Never Eat Soggy Waffles) → north-east → a
  landmark (the red bridge, not a parked car) → "in danger, call 112". Expert: CENTRAL and the platform without glows.
- **Big, A metro journey, a map and a bearing (17 steps):** the number by heart, the address aloud, "the game never asks"
  → `{metro_where}` → plan it on the map: PARK, CENTRAL, ZOO (in order) → the red line towards RIVER (trains are signed by
  their last station; HILL is the other way) → the ticket → a train coming in (a danger moment: it comes in slowly on the
  first tries): **safe mistake: waiting at the platform's edge**: time freezes, the train still, soft wind arrows along the
  edge and a see-through figure at it, "TRAINS COME IN FAST AND CLOSE"; the coach: "Trains come in fast and close to the
  edge, and the wind they push can make you wobble."; the right way: "Stand behind the yellow line until the train has
  stopped and the doors open." → behind the yellow line → people off first, mind the gap → practice time: your group went
  on without you → stay put and ask the staff (not riding round) → the help point's button ("the staff help you phone your
  grown-up") → the park map's key (M for the metro, first aid's cross, a wood's trees) → grid square C2 (along, then up;
  B3 is a kind miss) → the compass's dial set to 90 (Expert: 45) → turn to the needle, walk the arrow: the yellow flag in
  the east (Expert: the blue flag in the north-east; the others kind misses) → south-west. Expert: the new bearing, the
  platform without its glow.
- **VR:** the market's people and the metro's map by laser; STAY HERE is standing still (the button after two showings for
  a seated child); the reader and the compass within the hand's reach (0.8 m, 0.5 m); the platform's places and the
  flags by laser (the north flag 7.2 m off); the views blink between the market, the school, the metro and the park.

### Home Helper (Home and everyday; the practice house)

No safe mistakes: chores. The practice bins are the game's own: PAPER (blue), PLASTIC AND CANS (yellow), GLASS (green),
FOOD WASTE (brown), each with its picture and words; `{bins_where}` says the region's own differ.

- **Little, A little helper at home (14 steps):** touch the white things (a T-shirt, socks, a towel) into WHITES →
  Bobo's red striped sock's partner (the spotty ones are kind misses) → fold the T-shirt (one sleeve, the other, in half)
  → tidy: each thing back in its home (the car in the toy box, the book on the shelf, Teddy on the bed) → water the plant
  until the soil is damp, not soaking (the gauge: "the soil is still dry", "damp: just right", "too wet") → when the soil
  feels dry → Biscuit's food → fresh water poured into his bowl → a walk and a clean bed (not sweets) → the newspaper into
  PAPER, the bottle into PLASTIC AND CANS (the other bins kind misses with words) → with Gus, the smoke alarm's test
  button held until it beeps ("Gus tests it with you once a month"). Expert: four whites, and shoes to tidy too, no glows.
- **Middle, Washing, folding, recycling, plants and a pet (16 steps; Expert 17):** the coloured things into COLOURS → a
  red sock hiding in the whites (it could turn them pink) → folding → `{bins_where}` (Georgia: "more and more places have
  their own bins for plastic bottles or for paper") → a flattened cereal box, a can, a jam jar (empty and rinse first), an
  apple core (compost) → the plant → his lead off the hook, a daily walk → fresh water → a poorly Biscuit: tell a grown-up,
  the vet → the table: the plate, the fork on the left, the knife on the right with its blade to the plate, the cup → the
  smoke alarm once a month. Expert: the bins without glows, and a used battery: none of these bins, a battery box.
- **Big, Labels, the washing machine, the dishwasher, the smoke alarm (15 steps):** the care label's symbols (a tub
  washing, a triangle bleach, a square drying, an iron ironing, a circle dry cleaning; a cross means no) → a tub with 30:
  30 degrees at most (Expert: a towel's 40) → a hand in the tub: hand wash only → a crossed-out square with a circle: no
  tumble dryer → the washing machine: the door, the dial to 30 with Gus watching, START → fold and put away in the drawer
  → the dishwasher: plates below, a cup upside down on top → the sharp knife: point down (point up is a kind miss: "Sharp
  points up could hurt a hand reaching in") → an old battery: a battery box → plants while away: a neighbour or a tray of
  water → the smoke alarm's test → its chirp: a grown-up changes the battery (never take it out) → once a month. Expert:
  the 40 label and the knives without a glow.
- **VR:** folding is the hand on each part, squeezing; the watering can and the jug pour when the hand holding them is
  tilted over the plant or the bowl; the bins by hand or laser; the smoke alarm's button held by hand (0.76 m); the
  dishwasher's basket by hand.

## Life Town's third row

In front of the second row (`THIRD_ROW_Z` 15, footprints z 15..16, `PLAZA_MAX` (12, 18)), its doors facing the spawn 5 m
apart (walking up to one never opens another): the **web café** (a white kiosk with a big play tablet on its front and
four pretend app squares; Online City), the **metro entrance** (a low wall round stairs going down, a red M on its post,
the two-line map; Find Your Way) and the **helper's house** (yellow walls, a red roof, a washing line with four clothes
and four little bins: blue, yellow, green, brown; Home Helper). Every Experience has its place. The search also checks the
plaza's whole edge against the Theater now (its empty corners: a flat world's seed 99 put a corner 5.8 blocks from the
Theater without it). Measured (`test_real_meadows_get_their_town`): **6 of 8 real meadows get their town** (L3b: 7; seed 3
loses it: its plaza fitted only at radius 34, which the deeper plaza can't use), the slowest search 108 ms (L3b: 127).
Also measured and not taken: a side wing (x 14..16: 6 of 8, 143 ms, and a near corner too close to the spawn), a row one
cell deep (6 of 8), finer radii 36 and 40 (6 of 8, 141-173 ms). The Life Town smoke in a real Green Meadows world: the town
stood after 5.9 s; walking up to each of the twenty places opened its Experience (the third row's three too).

## How it is built

- **Rules (`core/life/`):** `LifeRegion` (`METRO_WORDS` / `metro_words`, `BINS_WORDS` / `bins_words`), `LifeExperience`
  (the three ids, `{metro_where}`, `{bins_where}`), `LifeTown` (three spots, `THIRD_ROW_Z`, the bigger plaza, the edge's
  Theater check).
- **Rooms (`entities/life/`):** `OnlineRoom` ("online": the living room, Gus, the play tablet and its twenty pretend pages;
  a step's `page`, the news step's `headline`), `FindWayRoom` ("find_way": the market, the school, the metro, the park;
  the train moves by the room's time), `HomeHelperRoom` ("home_helper") (`LifeRooms.make`); `LifeRoom` (`held`, `holding`,
  `held_rest`, `hold_pose`, `is_held_target`, `rest_held`), `LifeRoomHost` (`_hold_device`; the holding hand skips its own
  device; `rest_held` when the headset comes off), `LifeTownBuildings` (`_third_row`).
- **Screens (`ui/life/`):** `LifeIconsEveryday` (59 pictures; `LifeIcons` asks it after `LifeIconsHazards`), `LifeRoomHud`
  (`amount_words`' "soil"), `LifeGrownUpsPage` (`SOURCES_L3C`: L3c's authorities, and "the game never asks for an address
  or a phone number").
- **Data:** `data/life/experiences/online_city.json`, `find_way.json`, `home_helper.json`; nine units in `data/life/units/`
  (ask_private_tell, strangers_and_passwords, scams_and_news, stay_and_ask, metro_and_compass, journeys_and_bearings,
  little_helper, washing_and_recycling, labels_and_machines: the School's bar, 11 exercises on three levels each) and in
  `life.json` (Life online 4 / 4 / 5 units, Getting around 2 / 4 / 4, Home and everyday 6 / 5 / 5);
  `data/tools/tools.json`: five new entries (metro_ticket, washing_label, gates, help_point, dishwasher), owner "#112
  (L3c)".
- **The hooks outside Life** (each marked "owner #118 (L3c)", none of Success's or the School's code touched):
  - `data/success/experiences/goal_board.json` lines 70, 162, 175: the Little and Middle `jar` steps name `"device": "jar"`,
    the Middle `week` step `"device": "calendar"`, each with `"owner": "#118 (L3c)"` (their Tool Book stamps can be earned
    now; `LifeExperience.problems("goal_board")` stays empty: the devices were already in its data).
  - `data/school/g8/computing/cyber_security.json` line 41: the last card names Online City ("In LIFE, Online City's big
    track practises spotting scams and phishing and keeping passwords secret.") instead of the Connections Book, with an
    `"owner"` key on the card; and `tests/unit/test_school_content_g8_arts.gd` line 30: its `LIFE_LINKS` entry moved with
    it (`["Online City"]`, marked), or the School's test would fail.
  - `data/life/life.json`: the School link `g8.computing.cyber_security` on Life online's Big track, beside the grade 6-7
    online-safety links and Online City's Big unit (marked `"owner": "#118 (L3c): ..."`). (life.json is Life's own file;
    the map had such links, so the hook was done, not skipped.)
- **Tools:** `tools/life_smoke_steps.gd` (VR: the held tablet stays in the off hand; no freeze without a wrong way tried;
  Online City's VR run must hold the tablet), `tools/life_review_sheet.py` (the fifth sheet; its tokens and reviewers).

## Rulings (decided, with what each costs if wrong)

1. **Online City is flat and VR** (the catalogue said "flat first"), and in VR the tablet is held in the off hand (one small
   framework rule: `LifeRoom.held`). *Cost:* a child holding the controller oddly sees the tablet tilt; a later VR-HANDS
   grab may want to own held things (the rule is three functions).
2. **The play tablet is the Tool Book's `tablet`** (Calm Corner's, with its BLOCK and REPORT), not a second entry; the new
   entries are the metro ticket, the washing label, the ticket gates, the help point and the dishwasher (every step's
   device must be in the Tool Book). *Cost:* the tablet's page is shared with Calm Corner's.
3. **Online City and Find Your Way are emergency Experiences** (the calm debrief: strangers, scams and getting lost can
   worry a child), Home Helper is not. *Cost:* one more page after Online City.
4. **Nothing personal is typed:** every answer is a button or a picture; pretend passwords appear only as weak examples
   that the game's own `PasswordRules` refuses, and the strong one only as the game's own idea ("two words and a number
   that only Bobo would think of", the #105 review's shape), never a password a child could copy. *Cost:* no practice
   making one (the game's own MAKE A PASSWORD page does that, for real).
5. **A stranger online is a grey "?"**, never a face; the market's man is an ordinary figure who only stands where he is;
   the safe mistake's picture is the child's see-through figure walking off, never him following. *Cost:* less vivid, by
   design (§6, §14: calm, never scary).
6. **The mean comment is "you're bad at this game"**, the brief's bound; the group chat "laughs at Bobo's dance".
   *Cost:* milder than real bullying (Calm Corner's tracks carry more).
7. **Online City's safe mistakes:** Middle answering the stranger (SEND PHOTO), Big clicking the free gold (GET GOLD), as
   the brief says; Middle's free gold is a picture choice. *Cost:* Middle never clicks the scam.
8. **Find Your Way's safe mistakes:** Middle walking off with "come with me" (the brief), and Big's platform edge while a
   train comes in (my addition: a real danger, a danger moment slowed on first tries). *Cost:* one more freeze on Big; a
   reviewer may want it a kind miss (one data change).
9. **No lockdown anywhere:** the school's emergency is a fire drill on Little and Middle; Big's "people and places" is being
   separated from the group at a station (stay put, the help point). *Cost:* Big practises no school drill.
10. **The game's metro is its own** (the green line and the red line meeting at CENTRAL; PARK, MARKET, SCHOOL, HILL, ZOO,
    RIVER) and the region's own metro is one sentence (`{metro_where}`): Georgia's says Tbilisi's two lines meet at
    Station Square (checked: 23 stations, two lines, Station Square the one interchange). *Cost:* a region without a
    metro hears "many big cities"; Tbilisi's line names aren't taught.
11. **The bins:** the game's four practice bins, each with a picture and words, coloured paper blue, plastic and cans
    yellow, glass green, food waste brown (a common European pattern; the EU has no colour standard), and the region's
    sentence (`{bins_where}`) says the child's own bins differ (Georgia's: separate bins for plastic bottles or paper in
    more and more places: UNDP's 2021 pilot in Tbilisi and Batumi, paper bins in Zugdidi and Telavi; Tbilisi's own colour
    scheme could not be confirmed). *Cost:* a child's bins may have other colours (Try it for real sends them to check).
12. **Home Helper has no safe mistakes;** its wrong bins, spotty socks and the knife pointing up are `not` kind misses
    with their why. *Cost:* like any kind miss they cost that run's By myself stamp.
13. **Folding is presses** (sleeve, sleeve, half; Big: and the drawer), named "press": the ten motions have no fold.
    *Cost:* no true folding gesture until the tool engine gets one.
14. **The smoke alarm is a practice one low on the hall's wall**, its button held 2 s with Gus ("a grown-up reaches the
    ones on the ceiling"). *Cost:* none known.
15. **The washing label is a Tool Book "tool" with the motion "measure"** (reading the tub's hottest wash). *Cost:* a
    stretch of "measure"; the tools' owner may give labels a kind of their own.
16. **The address:** every track says the game never asks; Little's and Middle's say a safe grown-up who is helping (a
    shop worker, a police officer) may hear the grown-up's number aloud, never online. *Cost:* a police adviser may want
    only the police named.
17. **Life Town's third row is in front of the second, two cells deep, its three in the middle;** the plaza's edge is
    checked against the Theater. *Cost:* 6 of 8 real meadows get their town (7 before); a next wave needs a second
    plaza. Worlds that already have their town keep its site and the third row stands there on its plinths like the
    second row did (models, never stamped): it may stand among trees or by a child's build (the lead checks one old
    world).
18. **The tablet's words are billboards** (the only label shader the warm-up holds), so in VR its text turns to the head
    over a tilted tablet. *Cost:* the text floats a little in front of the screen.
19. **The news is calm and silly** ("Cats can talk on Tuesdays!", "Ice cream will be banned next week!", "Schools will open
    at midnight"), never frightening news; the phishing sender is "ONLINE CITY TEAM?" (a pretend name with a question
    mark, never a real brand). *Cost:* real fake news is subtler (the three checks are the lesson).
20. **The compass's north is the room's forward;** Big walks a bearing of 90 (the yellow flag), Expert 45 (the blue); the
    north flag is 7.2 m off (the laser's 8 m). *Cost:* no real magnetic north in the game.
21. **STAY HERE is the body action "still"** (2 s; VR: the head still), its own button words. *Cost:* a fidgety child in
    VR waits longer (the button comes after two showings).
22. **The cyber security card's hook moved its test's line too** (`test_school_content_g8_arts.gd`'s `LIFE_LINKS`).
    *Cost:* the School's owner merges a one-line test edit with the card.
23. **Time online is a break, never guilt:** "Breaks help your eyes, your body and your sleep. The game waits for you."
    *Cost:* no screen-time numbers (the grown-ups decide them).

## The facts and their sources

Every step's words and source are in `docs/devlog/parts/life-l3c-review.md` (written from the data, each source a checkbox
for the expert's review before it ships, design §14), for the owner's experts: an online safety educator (the UK Safer
Internet Centre, Childnet) with a child protection adviser (the NSPCC or UNICEF's national office); a police community
officer or a child-safety charity's educator, the fire and rescue service (school drills), Tbilisi's metro and an Ordnance
Survey or orienteering trainer; a home safety educator (RoSPA or the fire service), a vet or the RSPCA, the local
recycling service and GINETEX. The authorities:
- **Online:** Childnet's SMART rules (Safe, Meeting, Accepting, Reliable, Tell; https://www.childnet.com/), the UK Safer
  Internet Centre (https://saferinternet.org.uk/: ask before downloading, don't reply, keep evidence, block, report,
  tell; scams and phishing), the NSPCC's online safety and Share Aware
  (https://www.nspcc.org.uk/keeping-children-safe/online-safety/ ; bullying and cyberbullying), UNICEF
  (https://www.unicef.org/end-violence/how-to-stop-cyberbullying), the UK's National Cyber Security Centre (three random
  words: https://www.ncsc.gov.uk/collection/top-tips-for-staying-secure-online), and the game's own rules
  (`core/net/password_rules.gd`, owner #105).
- **Getting around:** NCMEC (stay in one place; ask uniformed police or security, or shop staff with name tags:
  https://www.missingkids.org/), Kidpower (a mother with children; never go anywhere with anyone:
  https://www.kidpower.org/library/article/getting-lost/), the fire and rescue services (the London Fire Brigade: school
  drills), the Tbilisi metro and the Georgian encyclopedia (two lines, Station Square:
  https://georgianencyclopedia.ge/en/form_eng/832), Transport for London (the yellow line, help points: https://tfl.gov.uk/),
  Ordnance Survey (grid references, the compass, a bearing: https://www.ordnancesurvey.co.uk/).
- **Home:** the RSPCA's five welfare needs (https://www.rspca.org.uk/adviceandwelfare/pets/general/fiveneeds) and caring
  for dogs, the London Fire Brigade and NFPA (smoke alarms tested monthly; a chirp is a low battery), the RHS (watering),
  Recycle Now (WRAP; empty and rinse; batteries to a battery box), the European Commission's Waste Framework Directive
  (separate collection), UNDP Georgia (Tbilisi's and Batumi's 2021 recycling pilot), Recycle Your Electricals (batteries
  and bin-lorry fires), GINETEX's care symbols (ISO 3758: https://www.ginetex.net/), dishwasher makers' instructions
  (knives point down), Debrett's (the table).
- **Checked in this session** (web searches, nothing saved): Tbilisi's metro (two lines, 23 stations, Station Square the
  one interchange), Childnet's SMART rules, Tbilisi's recycling (a 2021 UNDP pilot with clear PET bins; no city colour
  scheme found), lost-child advice (NCMEC's safe adults; Kidpower's mother with children; insist on staying in the same
  place), dishwasher knives point down (makers' manuals; no RoSPA or CAPT page found), GINETEX's symbols (the tub's number
  is the highest temperature; a bar a milder wash; the square's circle tumble drying; dots the heat).
- **Not re-fetched** (the brief: no downloads): the other URLs and wordings come from the authorities' published guidance
  as known; most need a look: the UK Safer Internet Centre's and the NSPCC's page paths, UNICEF's misinformation page (the
  URL given is its cyberbullying page), the London Fire Brigade's smoke alarm path, the RHS's watering page, Recycle Now's
  and Material Focus's battery advice, Debrett's, the hand-wash symbol's temperature (left out on purpose).

## Tests and measurements

- **Unit:** `test_life_l3c_data.gd` (12: the three known, their areas and emergencies; the safe mistakes only on Online
  City's and Find Your Way's Middle and Big, never on Little or in Home Helper, each tryable with its picture; the game's
  own password rules (every weak example refused by `PasswordRules`, `NEVER_TELL`, the brake); nothing personal typed,
  kept or sent and nothing scary (no lockdown, grabbing, following, hate, microphone); the address said aloud, "Say your
  address to your grown-up now"; the authorities' right ways on every track; a fire drill, never a lockdown; the region's
  metro (Tbilisi) and bins (Georgia) and number; the devices and the Tool Book; every unit on the map; every fact's
  authority and source; the three hooks), `test_life_l3c_rules.gd` (4: the metro and bins words, the soil gauge, the third
  row). L1's `test_life_experience.gd` knows the twenty; `test_life_town.gd` counts the second row without the third.
- **Integration:** `test_life_rooms_l3c.gd` (11: every safe mistake's picture comes and goes; one tablet page at a time,
  chat buttons only on chats; nothing to type or personal on the tablet; picked up and held, its face to the eyes, back
  flat when the headset comes off; the man only stands where he is; a fire drill, never a lockdown; the metro's lines meet
  at CENTRAL; the train comes in by the room's time, still while frozen; recycling, washing and toys go home; the soil
  darkens; the mesh budget), `test_life_room_host_l3c.gd` (9: SEND PHOTO freezes then BLOCK; GET GOLD freezes then the X;
  VR: the tablet in the off hand, the holding hand never presses, the other hand does; STAY HERE, then walking off freezes
  (he stays put) then the shop worker; Little's rule first; the platform edge freezes the train; a knife pointing up is a
  kind miss; VR: the can tilted pours; VR: the smoke alarm held by hand), `test_life_screen_l3c.gd` (4: the three areas fit
  the frame on every track; L3c's authorities on the grown-ups' page; a third-row place opens its unit; the debrief after
  Online City and Find Your Way, the card after Home Helper), `test_life_icons_l3c.gd` (4: every new picture known, drawn
  once, at three sizes, never a ToolIcons name; every L3c choice's and mistake's picture; the Tool Book's new entries
  drawn by Life's pictures). L1's, L2's, L3a's and L3b's room, host, screen and town tests on the new data: every target and
  view in its room, everything to tap in the screen's free band from its view, everything to touch within a child's reach
  in VR (the smoke found nothing; the room test found the north flag at 8.2 m, moved to 7.2), only warmed shaders, no
  shadows.
- **Meshes per room** (Little / Middle / Big): Online City 87 / 87 / 87, Find Your Way 145 / 210 / 98, Home Helper 83 / 80 /
  65 (the budget: 320).
- **Life's, Success's and the tools' test scripts** (62 scripts, before the merge): 666 of 666 passed. After merging
  `lead-merge` (`802d299b`): the grade 8 School tests, Life's data, catalogue and experience tests: 84 of 84.
- **The smoke** (`tools/life_smoke.gd`, 5× time): L3c's three, every mode: **35 of 35** (2.4-5.5 s each); with the smoke's
  new checks also Little Lifesaver's and Water Safety's runs: **57 of 57**.
- **The Life Town smoke** (`tools/life_town_smoke.gd`, a new Green Meadows world): stood after 5.9 s at (0, 29, -38); the
  twenty places each opened their Experience; TRY IT opened the room; 171 frames in the room, average 35.3 ms, worst
  109.9 ms (headless on this shared desktop); STOP FOR NOW gave everything back: 0 failed.
- **The full suite** (2026-10-17, on everything merged with `lead-merge` at `802d299b`, one run in a PC-wide slot; the
  session's limit paused the agent while it ran, and it finished): 1,241 scripts, 11,505 tests: **11,502 passed, 0
  failed**, 3 risky or pending (the same three as before: `test_the_column_cache_changes_nothing` and
  `test_chunks_meet_without_seams` "did not assert", and the device move's pending by design), 4,415 s. `lead-merge` then
  gained only docs (`16392111`, `d4c74bfb`), merged at `7dd684f8` with no conflicts.

## What the lead must check (I could not: no editor, no emulator, no headset)

On the emulator (`Pixel_8_API_35`), flat:
- Online City's tablet at phone size: the pages' words (billboards at 0.45-0.8 mm a pixel), its buttons (5-7 cm at reading
  distance), the profile's six cards, the News Stand's three checks; the freezes' pictures (the photo card and the grey
  "?", the hook over the password card) and their cards.
- Find Your Way: the market's people (the worker's badge, the mum and children, the police officer's hat), the man's
  "COME WITH ME!" sign, the see-through walking figure; the school's line and meeting point; the metro map's seven
  stations and labels, the gates' reader, the yellow line, the train coming in; the compass's N/E/S/W (small: 4 cm
  targets), the park map's key and grid.
- Home Helper: the washing on the floor, the socks on the bed, the four bins' words, the care label board, the dishwasher's
  POINT DOWN / POINT UP, the smoke alarm's button.
- **FPS ≥ 30, no frame over 100 ms** in each new room (Find Your Way's Middle is the biggest, 210 meshes) and in one opened
  from Life Town; the third row's three models, signs and rings (and in one world saved before L3c: the third row on its
  plinths).

On the Quest 3:
- The tablet in the off hand (0.1 m right of and 0.12 m above the grip, its face to the eyes): comfort, readability, the
  finger on its buttons (a squeeze at 5-7 cm buttons), the laser as well; that holding it never presses it.
- STAY HERE standing still (0.8 s still, 2 s); the market's people by laser; the metro map by laser; the reader by hand
  (0.76 m); the platform's spots and the flags by laser (the north flag 7.2 m); the compass's letters and dial by hand (0.5
  m); the bearing's walk (a blink to the flag).
- Home Helper's folding by hand (the bed at 1.05 m: a lean), the socks, the watering can's and the jug's tilt over the plant
  (0.73 m) and the water bowl (low on the floor: a crouch), the bins, the dishwasher's basket, the smoke alarm (0.76 m).

## Next

The experts' review of `life-l3c-review.md` (the checkboxes); a second plaza for Life Town when the next wave comes (a
fourth row would cost more meadows); a fold gesture for the tool engine; the catalogue's remaining rows (falls and heights,
power tools and the workshop, dangerous science, dangerous jobs) in L4.
