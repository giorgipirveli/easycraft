# Success S2: the Goal Board and the habit garden, Talk & Deal, the Connections Book, Success Stories (owner #115)

The owner (2026-10-16 11:49, #115): "in life skills we need more, we need skills school dont deliver, skills releted to
real life, how to be successfull, business, trading, money, comunications, connections, everything to be sucsessfull".
The brief: `docs/superpowers/plans/2026-10-16-success-s2-brief.md`; the design: `docs/design/success-skills.md` (§2
systems 3, 4, 6, 7; §3 the guardrails; §4 parents); the spec: §27.4 ("As built (S2)"). Built by the Success S2 agent on
the worktree branch `worktree-agent-a80874e5d73cf3f40` from `lead-merge` at `979caa1d` (2026-10-16/17), on Life's
framework (`docs/devlog/parts/life-l1.md`, `life-l2.md`): nothing of it forked. The experts' review sheet, written from
the data: `docs/devlog/parts/success-s2-review.md` (`tools/success_review_sheet.py`).

## What a child sees and does

**The Life map's Success strand** now has six areas in one row: Money and business, Thinking and the future, and S2's
four: **Goals and habits**, **Talk and deal**, **Connections**, **Success stories**. Each new area shows its units on the
child's track (LESSON, PRACTICE, TRY IT, the Passport's stamps, EXPERT TRY once done alone), the School's own lessons that
fit, and, for three of them, its place under the units: **MY GOAL BOARD**, **MY CONNECTIONS BOOK**, **THE STORY SHELF**.
TRY IT works as everywhere in Life: the before-check the first time, the practice room (Professor Hoot's words read aloud
on Little, SHOW ME and I NEED A BREAK always, the one next thing glowing, the coach after 10 s), the name-it card, the
after-check, the stamps, the honest before-and-after, Try it for real.

### The Goal Board (Experience `goal_board`, the Goal Room)

A bright playroom: the Goal Board on the back wall (the dream's rocket, the GOAL and PLAN spaces, step cards in a mixed
order), Bobo's blocks on a mat, the saving jar on a little table, the habit plant by the window with its watering can,
the week's calendar on the wall, and on Big the time jar.
- **Little, one step at a time:** Bobo dreams of a tower as tall as the window → which is a goal for today (3 blocks high,
  not "the best builder ever", not "sometime") → stack big, middle, small → a wobble, it falls softly → what now (try again
  carefully; not give up, not kick the blocks) → build again → saving for a kite: keep the 2 coins (not sweets) → tap the
  jar twice → a habit: water the plant (hold the can over it) → 5 days pass, one forgotten → what now (water it the next
  day: it waited). Expert: the tower falls twice (look why: the wobbly floor) and Pip-pop's sweets are half price.
- **Middle, goals in steps, if-then plans:** the dream: your own rocket to the Moon → a goal you can check ("Save N gold for
  Mission Control's Moon rocket in 3 weeks": N is the game's real plan, `RocketPlan.gold`) → pin it → the steps in order
  (LEARN A LESSON, SAVE GOLD, BUY THE PARTS, BUILD THE ROCKET, shown mixed) → the best plan ("When I finish a lesson, I put
  10 gold aside for my rocket.") → pin it → a friend asks you to play: "After my lesson!" → pick a practice habit (any
  picture is right) → a week: touch every day kept (Wednesday has a cloud) → is the habit ruined? (no: one day off hardly
  matters) → three lessons: tap the rocket jar 3 times. Expert: a second obstacle (tired: a tiny part).
- **Big, plans that stick:** a clear, measurable, dated goal (3 By myself stamps by the end of the month) → WOOP in order
  (wish, outcome, obstacle, plan) → the WHEN (a moment you notice) → the THEN (a small clear action) → the obstacle's
  if-then (tired: just 5 minutes) → big rocks first in the week's jar, then pebbles, then sand → bouncing back (change the
  plan, try again) → habit stacking (after I brush my teeth, I read one page) → a month passes → honest progress ("2 of 3:
  close! Next month's plan."). Expert: a trickier goal and a second obstacle (a game: play after your 10 minutes).

**MY GOAL BOARD** (the place): the child's own goal, made from pictures (never typed): a dream (the Moon, Mars, a new
universe, something big to build, school, real-life skills, my own dream), a goal you can check (the game measures it
where it can: the child's Survivor gold against Mission Control's rocket for one astronaut, a flight there, the next
universe opened, 3 lessons mastered since the goal, 2 By myself stamps since the goal; a build or a dream of their own is
the child's ticks), the steps (Little: the first three, ready-made; Middle and Big: three picked in the child's order),
the plan (Little: one of three ready plans; Middle and Big: WHEN and I WILL from parts), on Big the obstacle plan (IF and
THEN), then the plan read back and Try it for real ("Tell a grown-up your goal, and plan its first step together"). The
board shows the goal, how far the game sees it (a bar and words: "Your gold: 120. Mission Control's rocket to the Moon:
470 gold."), the steps to tick, the plans; reaching it is celebrated once ("Goal reached! You did it, step by step.").
**The habit garden** beside it: pick one small good habit (water, teeth, reading, tidying, helping at home, playing
outside, bedtime, a thank-you, a lesson); "Did you do it today?" YES, I DID IT or NOT TODAY ("That's OK. Thank you for
being honest. Tomorrow is a new day."), once a day, CHANGE for today's answer; the plant grows on every kept day (a seed,
a sprout, leaves, a bud, a flower, more flowers after weeks) and never shrinks; "Kept on 12 days in all"; after days away
"Welcome back! Your plant waited for you."; another habit starts its own plant and the first one stays in the garden.

### Talk & Deal (Experience `talk_deal`, the market square)

- **Little, listen, sorry, clear words:** Mo comes to the stall, cross → first: look at him and listen (not talk over,
  not walk away) → Mo: "My bread got squashed in my bag!" (or a hard loaf, or the wrong bread: each try differs) → say it
  back → say sorry (no "but") → fix it: give him a fresh loaf → "Thank you for telling me!" → Robo the robot, who does
  EXACTLY what you say: the red box in the basket, the blue box on the table (a muddled order puts a box on his head for a
  moment and he looks puzzled: harmless) → Pip-pop's ball: "Can I have a turn, please?" Expert: Mo's jam lid too, and two
  steps in one go for Robo.
- **Middle, win-win deals, clear instructions:** Ana the farmer has apples → ask what she needs most → she needs bread for
  her helpers and help with heavy crates → a win-win offer (4 loaves for a crate, and help carrying) → shake hands (VR:
  squeeze her hand) → busy on Friday: bring it anyway or tell her early → keep the promise: bread in her basket → Robo:
  the apples in the blue crate under the table → his steps in order (FORWARD, TURN LEFT, PICK UP) → a customer's complaint
  about the cake (dry, too sweet or squashed): listen, sorry, a fresh slice, thanks. Expert: Ana can spare only half a
  crate.
- **Big, pitch, feedback, fair deals:** a bread cart for the Launch Site; three friendly investors in the meeting tent (in
  VR the child stands in front of their table) → the pitch board's four parts in order (THE PROBLEM, MY IDEA, WHY ME,
  WHAT I NEED) → each part said well (builders walk 20 minutes for lunch; a cart that comes at lunchtime; "I ran my stall
  for two weeks and customers came back"; 50 coins for 1 coin of every 10 for a year) → look at each investor → "What if
  it rains?": an honest answer with a plan → feedback taken ("What price would feel fair?") → Mrs Kowalski's 9-in-10 for
  ever: a polite no → Ms Ade's fair offer: yes → she comes round the table to shake hands → kind, useful feedback for
  Pip-pop's lemonade pitch (one thing liked, one to try). Expert: the numbers (25 loaves pay back 50 coins at 2 each) and
  "Sign now, or the offer is gone for ever!" (think it over, talk to a grown-up first).

### The Connections Book (Experience `connections`, the village square)

The practice village: Amara's bakery, Tomas's mill, Ana's farm stall, Ivan's tool shop, Mr Okafor's library, Omar's clock
shop (with a ramp), Sam's workshop, Grandpa Kenji's beehives, Rosa's pottery, Gemma's rock table, Mei's Launch Site
workshop, the fountain and Lina on the bench. People wave when met, look worried when they need something, smile when
helped, and turn to each other when introduced.
- **Little, friends and helping first:** say hello to Amara and Tomas → who is the baker? → Amara has no flour → help
  first: the flour from the mill to Amara → "You're welcome!" → Lina is new and alone → say hello, ask her to play → a
  promise: your crayons (or paints, or coloured pencils) tomorrow → the night passes → keep it. Expert: Ana's apples
  have spilt and Tomas has a heavy sack: help one, then the other.
- **Middle, trust, introductions, mentors:** meet four people and their needs → what does Ana need (a spade) → introduce
  Ana to Ivan, and Amara to Tomas (both win) → "flour by tomorrow morning?": promise what you can ("by lunchtime") → keep
  it on time → ask Omar politely to teach you, saying when you could come → his tip: "Check twice, fix once." → Sam is
  deaf: face him, smile, point and show (he signs thank you) → thank your mentor a week later. Expert: Mr Okafor needs
  shelves: find who can build them (Sam) by yourself.
- **Big, networks, trust, online safety:** meet Mei, Grandpa Kenji (80, bees for 60 years), Rosa and Gemma → who could use
  Mei's pump (Ana's dry fields) → introduce them → a chain: Rosa to Gemma (clay), Rosa to Kenji (jars) → why Kenji is great
  to know → the clay pit is closed: tell Rosa early, sorry, a new day → keep in touch: a thank-you postcard → a stranger's
  message asks for your address: don't reply, tell a grown-up → advice for a honey stall: ask Kenji politely, questions
  ready → his tip → a new chance (Amara: the builders would love fresh bread). Expert: a message pretending to be from Mei
  asks for your password.

**MY CONNECTIONS BOOK** (the place): the sixteen people (the village's twelve and the market's Mo and three investors),
eight a page; the ones met with their faces (their own clothes and skin tones), name and job on a card that glows warmer
as they trust the child more (no number anywhere); the others "Not met yet" (closed). A person's page: where they are and
their hello, what they wish for, need and offer, who could help them, how they differ from many children, their warmth
in words ("Amara smiles when you come by"), the help, promises and introductions, a mentor's tip, the new chance they
told the child about. CHANCES AND TIPS lists them all. A finished try fills the book.

### Success Stories (Experience `success_stories`, the Story Theatre)

A little stage with red curtains and a backdrop naming each scene's place and year; buddies act the stories (symbols and
actors, never portraits). Little: Louis Braille's dots (make the letter B: dots 1 and 2), Wangari Maathai's tree holes
(five), the Wright brothers' glider (it comes down: they try again; the first flight's 12 seconds); Expert: Mary Seacole.
Middle: the Wrights (the glider, three wings in the wind tunnel, the flight), George Washington Carver's two fields
(peanuts, then cotton), Florence Nightingale's ward (the window, the basin, the sheets; her charts); Expert: Alexander
Fleming's dish. Big: Henry Dunant's town helpers (both sides), Katherine Johnson's check (3 × 90 minutes), Yuan
Longping's field (find the special plant), what the stories show (people often fail, learn and try again); Expert:
Savitribai Phule. Each scene asks "Which skill did they use?".

**THE STORY SHELF** (the place): the twenty stories, ten a page, a tick on the ones read; each read one line at a time
(aloud on Little; a speaker on every page), with its symbol, the person's years, country and job; then "Which skill did
they use?" with three picture answers in a mixed order: the right one is praised for the skill ("Yes! Louis Braille made
an idea better."), any other gets its kind why and the child tries again; "Facts checked with: nfb.org, britannica.com".

### Flat and VR

Flat: a finger on a thing does it (the investors, the people, the blocks, the cards, the dots), a held finger holds (the
watering can, a handshake), the picture answers on the bottom bar. VR: the child stands at each step's spot (a blink when
it moves): at the stall, at Ana's cart, at Robo's mat, in front of the investors' table, at Bobo's mat, at the board, by
the plant, at the calendar, in the village square and beside each person, before the stage; the hand squeezing on Ana's
or Ms Ade's hand shakes it; the laser presses farther things (the board's cards, the people, the stage); the picture
answers on the tray. Every thing to touch is within a child's reach of the spot (Life's room tests).

### The grown-ups' Life page

"Goals and habits": the goal and its plan (and obstacle plan), the steps done, what the game measured, "Reached on ...";
"Habit: Drink a glass of water. Kept on 12 days since 3 Oct (in all, not in a row: a missed day takes nothing away)";
goals reached so far. "People and stories": "The Connections Book: met 6 people, helped 4 times, kept 2 promises, made 3
introductions, learned 1 mentor's tip"; "Success Stories: read 4 of 20 true stories; answered 3 'Which skill did they
use?' questions." "About Success": nothing typed, nothing sent but the backup; habits in all, never in a row; the people
are the practice village's; the stories are true and checked. The Passport has the four new skills' pages (its fourth and
fifth pages).

## How it is built

- **Rules (`core/success/`):** `SuccessData` (`ProfileData.life.success`: the goal, goals reached, the habit and its kept
  days, the garden, the people, the stories; field-by-field parsing, limits, a merge that loses nothing), `SuccessGoals`
  (`data/success/goals.json`; the goal's measures over the profile; the plan's words; reaching once), `SuccessHabits`
  (answers, days kept, the plant's stages; no streak anywhere), `SuccessPeople` (`data/success/people.json`; the book's
  record from a try's steps; warmth in words; chances; tips), `SuccessStories` (`data/success/stories.json`; the question
  as a choose step; the problems check), `SuccessExperiences` (the four Experiences' registry: data path, rooms, `vars`).
- **Rooms (`entities/success/`):** `GoalRoom`, `TalkSquare`, `VillageSquare`, `StoryStage`, `SuccessCast` (people as
  LifeBuddies in their clothes, skin tones and names; Robo). Only LifeRoomKit's warmed shaders; no shadows of their own.
- **Places (`ui/success/`):** `SuccessPage` (the frame), `GoalBoardPage`, `HabitPlant`, `ConnectionsBookPage`,
  `StoryShelfPage`, `SuccessPlaces` (the map's row, the areas' place buttons, the pages, a try's record, the grown-ups'
  lines), `SuccessIcons` (100 pictures drawn in code).
- **Data (`data/success/`):** `experiences/` (four, Life's format), `units/` (twelve Life units, the School's format),
  `goals.json`, `people.json`, `stories.json`; `data/life/life.json`'s four Success areas and their units (new entries
  only, `"owner": "#115"`).
- **Hooks (each marked owner #115):** `core/life/life_experience.gd` (IDS, the data path, `"vary": "success"`),
  `core/life/life_catalog.gd` (the area rule: Living well's 8 and Success's 2 or more), `core/life/life_data.gd`
  (`success`), `entities/life/life_rooms.gd` (the default: Success's rooms), `ui/life/life_icons.gd` (SuccessIcons),
  `ui/life/life_screen.gd` (`SUCCESS`, `show_success_place`, the map's row, the area's place, a finished try's record),
  `ui/life/life_grown_ups_page.gd` (the Success lines). Tests updated for the new counts: `test_life_experience.gd` (the
  IDS), `test_life_catalog.gd` and `test_life_screen.gd` (14 areas), `test_life_town.gd` (Success has no Life Town place).
- **Tools:** `tools/success_review_sheet.py` (+ `--check`), and Life's smoke runs the four (it follows LifeExperience.IDS).

## Rulings (decided, with what each costs if wrong)

1. **Success S2 is four Life Experiences** in Life's framework (LifeExperience.IDS), their data in `data/success` and
   their rooms in `entities/success`, Life reached only through owner #115's small hooks. *Cost:* Life L3a also edits the
   IDS line and three test lines: the lead's merge joins the lists (a minute).
2. **Four new Success areas** on the map, the strand's six cards in one row (`SuccessPlaces.fit_grid`: narrower cards,
   18 px words). *Cost:* a seventh Success area needs a second row and a smaller living strand, or a scroll.
3. **The catalogue's area rule** is Living well's eight and Success's two or more (it was exactly ten). *Cost:* none for
   Living well.
4. **No Life Town places for Success yet** (L3a edits the plaza now); `test_life_town.gd` leaves Success out. *Cost:* the
   four are reached only through the Life tab until the lead adds their buildings.
5. **Success's progress lives inside Life's** (`ProfileData.life.success`), so the backup and its merge carry it;
   nothing goes to the friends' server. `ProfileBackup.is_new` still looks only at Life's units and skills. *Cost:* a new
   device with only a goal or a habit counts as new when choosing the backup (the backup holds the same goal).
6. **The Goal Board measures what the game can see:** the child's Survivor gold against Mission Control's plan for one
   astronaut (Moon or Mars), a flight there (MissionData.flown), the next universe (universe_unlocked + 1), lessons
   mastered (two stars, the School's and Life's) and By myself stamps counted from the day the goal was set; a build or a
   dream of their own is the child's ticks. *Cost:* gold already spent on parts doesn't count as "have" (the board shows
   the gold in hand); a bigger crew's rocket costs more than the line says.
7. **No gold for goals, habits, the book or stories:** Life's Experiences still pay their 100 once per skill and track.
   Self-reported things are never paid (honesty is the lesson; engagement research §1.8: informational, not paid).
   *Cost:* less pull for the habit; the plant and the goal are the reward.
8. **A habit is the child's honest answer, once a day** (YES or NOT TODAY, thanked; today's answer can change), counted
   in all, never in a row; nothing anywhere counts a streak; the plant never shrinks; "Welcome back" after two days away.
   *Cost:* a child can tap YES without doing it (honesty is taught, not policed).
9. **The plant's stages** at 0, 1, 3, 5, 8, 12, 18 and 25 days kept, then a flower more each 7 days (up to 8). *Cost:*
   constants (`SuccessHabits.STAGES`).
10. **Another habit keeps the first plant** in the garden at its size; coming back to that habit grows it on. *Cost:*
    one plant per habit (12 kept).
11. **Promises in the practice rooms are kept within the try** (a gentle night or morning passes on a clock), never a
    real-time deadline. *Cost:* less real than a promise across days; no pressure and no guilt.
12. **Warmth** rises by 1 for each help, kept promise, introduction or mentor's tip (meeting gives the first), at most 2
    a person each try; a new chance opens at 3; it shows only as words about the person and a warmer card. *Cost:*
    constants; several tries are needed for a good friend.
13. **The book's people are the practice village's and the market's** (sixteen), not the voxel worlds' characters
    (Gemma is in the village by name). *Cost:* meeting someone in a world doesn't add them yet (a hook later).
14. **Talk & Deal's conversations are Life's choose steps** (the child picks what to say from pictures or phrases; each
    other answer has its own kind "why"; the character's face and Robo answer through the room's events), not a separate
    dialogue system (the dialogue skill's data-driven lines, choices and conditions fit Life's step data). *Cost:* one
    best answer a line: another good phrasing isn't offered.
15. **Robo does exactly what was said** through the step's `on_miss` event: a box on his head for 1.5 s, a puzzled face,
    a spin unless Reduce motion is on. *Cost:* the same silly action for every muddled order (each order's why says what
    Robo did).
16. **Eye contact in VR is the laser or a tap on each investor** (a find step), not the head's gaze. *Cost:* a child can
    look away and still "look at" them: a gaze sample later (the Quest check).
17. **A handshake is a hold with the hand** (reach `hand`, motion squeeze) on the hand's spot. *Cost:* no real grab of a
    hand (VR-HANDS' grab could carry it later).
18. **Stories: people of the past only** (no living people, so no living-people politics), no brands (Abed's employer
    unnamed), symbols and actors, never portraits; the Red Cross is named but its emblem never drawn (it is protected).
    *Cost:* no living role models in S2.
19. **Facts checked with web searches this session (reading only)**: the brief's "no downloads" read as no files saved or
    assets fetched; nothing was downloaded or kept. Details were changed to what the sources support (below). *Cost:* if
    the lead meant no network at all, the searches went beyond it (nothing was saved).
20. **Reading a story pays no gold**; a right answer is praised for the skill and marks it answered; another answer shows
    its why and the child tries again; the shelf mixes the answers by the day. *Cost:* none.
21. **The Story Theatre's acted stories tick the shelf** (a step's `story`). *Cost:* a child who only watched the
    theatre sees the stories as read.
22. **Devices** (Life's device model): the calendar and the jar (the Goal Board), the tablet (the pitch), the phone
    (keeping in touch, online safety), the stopwatch (the first flight). Steps name only the Tool Book's (tablet, phone,
    stopwatch; tools: coins, watering can), since `data/tools/tools.json` is L3a's now. *Cost:* the calendar and the jar
    are not in the Tool Book yet (two entries for the lead).
23. **The coins in Talk & Deal are pretend market coins** (the investors' 50), never the child's gold, never real money;
    the pressure trick appears once (Big's Expert try) to be spotted, with "talk to a grown-up first". *Cost:* none.
24. **The units:** twelve Life units (one per Experience and track) and twelve School lessons; two left out (`g7.english
    .speeches_media` is not written yet; `g5.citizenship.big_questions_owe`'s title is longer than a card's 40 letters).
    *Cost:* data.
25. **The Little track's Goal Board** takes the dream's first three steps ready-made and one of three ready plans; Middle
    and Big pick three steps in order and the plan from parts; Big adds the obstacle plan. *Cost:* Little can't reorder.
26. **The village's night** changes the flat camera's sky; in VR the head keeps the room's day (Vr.view_like at open).
    *Cost:* in VR the night is the clock's label and the words only.
27. **The review sheet is its own tool** reusing Life's step writer (`tools/success_review_sheet.py`), so Life's sheets
    stay Life's. *Cost:* two tools to run after editing data.

## The stories' facts and their sources (checked 2026-10-17)

Each story's facts against its sources (searched this session; every URL is in `data/success/stories.json` and the
review sheet). Changes made to fit the sources are in brackets.
- **Florence Nightingale** (UK, 1820-1910): the Scutari hospital 1854, night rounds with a lamp (National Army Museum,
  nam.ac.uk/explore/florence-nightingale-lady-lamp); her statistics showed most deaths were from preventable disease; the
  Nightingale Training School at St Thomas', 1860 (MacTutor, St Andrews).
- **Mary Seacole** (Jamaica, 1805-1881): turned down by the War Office, she went at her own expense; the British Hotel near
  Balaclava with Thomas Day; bankrupt after the war, a fund raised (British Red Cross museum, object 46895); her book, 1857
  (London Museum).
- **Louis Braille** (France, 1809-1852): blind after an accident at three; six dots from Barbier's twelve by 1824, aged 15;
  taught at the school (National Federation of the Blind, nfb.org/node/9796); Britannica.
- **Wangari Maathai** (Kenya, 1940-2011): the first woman in East and Central Africa with a doctorate; the Green Belt
  Movement 1977; the first African woman to win the Nobel Peace Prize, 2004 (nobelprize.org); the first event planted seven
  trees, women paid for trees that survived (Wikipedia's Green Belt Movement article; University of Pittsburgh); over 51
  million trees (the movement's own figure) [the story says "more than 50 million"; the Nobel page of 2004 says 30 million].
- **George Washington Carver** (USA, about 1864-1943): born into slavery; Tuskegee from 1896; crop rotation with peanuts and
  sweet potatoes (Science History Institute); the Jesup Wagon, 1906 (National Park Service) [no count of his peanut
  products].
- **The Wright brothers** (USA): the 1901 glider's poor lift, their wind tunnel (NASA's Beginner's Guide); 17 December 1903,
  120 feet in 12 seconds, the best 852 feet in 59 seconds (Smithsonian, the stopwatch) ["lots of wing shapes", not a count].
- **Katherine Johnson** (USA, 1918-2020): Langley 1953; Shepard's path 1961; Glenn's 1962 check; the Presidential Medal of
  Freedom 2015 (NASA's biography; Space.com).
- **Maria Montessori** (Italy, 1870-1952): a doctor in 1896 ("one of the first women"); the Casa dei Bambini, 6 January
  1907, San Lorenzo, about 60 children aged 3-6 (AMI's timeline; Montessori Australia).
- **Alexander Fleming** (Scotland, 1881-1955): 1928, the mould on a dish after a holiday; Florey and Chain made the medicine;
  the 1945 Nobel Prize shared (Science History Institute; nobelprize.org).
- **Garrett Morgan** (USA, about 1877-1963): sewing-machine repairs, businesses; the safety hood patent 1914; the 1916 Lake
  Erie tunnel rescue; the three-position traffic signal patent 1923 (Lemelson-MIT; ITE) [no number of lives saved: the
  sources differ].
- **Henry Dunant** (Switzerland, 1828-1910): Solferino 1859; A Memory of Solferino 1862; the ICRC 1863; bankrupt 1867; the
  first Nobel Peace Prize 1901, shared (Britannica; nobelprize.org) [no "tutti fratelli" quotation: not confirmed].
- **Yuan Longping** (China, 1930-2021): the wild male-sterile rice found by a railway in Hainan, 1970; hybrids of the 1970s
  with 20-30% more rice (Heroes of Progress; Nature's obituary) [no "dream" quotation].
- **Savitribai Phule** (India, 1831-1897): the girls' school at Bhide Wada, Pune, 1848; teacher training; three schools and
  about 150 pupils by 1851 (The Leaflet; Wikipedia) [stones and dirt, not "mud"; the spare sari "it is said"].
- **Alberto Santos-Dumont** (Brazil, 1873-1932): around the Eiffel Tower in airship No. 6, 1901; the prize given to his
  workers and the poor of Paris; the 14-bis 220 m in 1906 (Smithsonian Education; the Brazilian Air Force museum) [no
  amounts: the sources differ].
- **Fazle Hasan Abed** (Bangladesh, 1936-2019): the 1970 cyclone; the London flat sold to start work in Sulla; BRAC 1972
  (BRAC University; Prothom Alo).
- **Fred Hollows** (New Zealand and Australia, 1929-1993): the trachoma and eye health programme (460+ Aboriginal
  communities); lens laboratories in Eritrea and Nepal, opened after he died; the Foundation 1992 (hollows.org; the
  Medical Journal of Australia).
- **Umeko Tsuda** (Japan, 1864-1929): to the USA in 1871, aged about six, the youngest girl; back in 1882; Joshi Eigaku
  Juku 1900, later Tsuda (National Diet Library; nippon.com) [no first-year pupil count].
- **Hassan Fathy** (Egypt, 1900-1989): New Gourna near Luxor in mud brick, the Nubian vaults, villagers taught to build,
  never finished; the book 1969/1973 (University of Chicago Press; the CCA's library record).
- **Carlos Finlay** (Cuba, 1833-1915): the mosquito idea, 14 August 1881, met with ridicule; Reed's commission confirmed it
  in 1900 and credited Finlay (PBS American Experience; Britannica's Walter Reed).
- **Marie Curie** (Poland and France, 1867-1934): the 1903 Physics Prize (the first woman) and the 1911 Chemistry Prize;
  the only person with Nobel Prizes in two sciences; X-ray vehicles in the First World War (nobelprize.org; LSHTM).
- The Experiences' science (each track's sources, in the sheet): Gollwitzer and Sheeran 2006 (if-then plans, d = 0.65);
  Lally et al. 2010 (habits 18-254 days, one missed day no material effect; doi 10.1002/ejsp.674); Duckworth, Kirby,
  Gollwitzer and Oettingen 2013 (WOOP-style plans with fifth graders; PMC4106484); Moffitt et al. 2011 (self-control);
  Jones, Greenberg and Crowley 2015 (social skills at five); Chetty et al. 2022 (economic connectedness); CASEL's
  relationship skills; the Harvard Program on Negotiation (BATNA, interests); EntreComp 2016; the WEF Future of Jobs 2025;
  CEOP's Thinkuknow (online safety).

## Tests and measurements

- **Unit:** `test_success_data.gd` (10: round trip, bad fields, limits, the newest 400 days, the merge never losing a day,
  a person or a story, another habit's plant kept, the newer goal, Life carries it in the profile and the backup),
  `test_success_habits.gd` (11: once a day, honest no, a missed day takes nothing, only grows, welcome back with no guilt
  words, no streak anywhere in the code, the garden, the week, the grown-ups' line), `test_success_goals.gd` (12: every
  dream's parts, the plan's words, unknown parts refused, ticks, the rocket's real gold, a flight, the next universe,
  lessons and stamps since the goal, reached once), `test_success_people.gd` (12), `test_success_stories.gd` (6: twenty,
  short, kind, British, plain letters, no brands, sources, people of the past, 17 countries, 8 women, every job, the
  question), `test_success_experiences.gd` (14: Life's Experiences with Success's data and rooms, the try's variety, the
  real Moon plan, never gambling, the only pressure trick the one taught, listen-sorry-fix, Robo, the deal, the pitch,
  the Goal Board, the book's people, the brief's connections, the theatre's stories, the units).
- **Integration:** `test_success_places.gd` (15: the map's row, the areas' places, a goal from pictures on all three
  tracks, the reached goal's celebration, the habit garden, the book and its pages, a story read and its question, the
  shelf, a finished try fills the book and ticks the stories, the grown-ups' page; every page fits the frame and has a
  speaker), `test_success_rooms.gd` (11), `test_success_icons.gd` (2). Life's own tests now cover the four too: every step's
  targets and views, everything to tap in the screen's free band from its view, everything to touch within a child's
  reach in VR, warmed shaders only, no shadows, an automatic player finishing every track and try with no hint, every
  choice's picture, every device's model, kind British words, nothing typed.
- **Mutation check:** without `_on_room_finished`'s record hook, the book's and the theatre's try tests fail (2 of 15).
- **The smoke** (`tools/life_smoke.gd --only=goal_board,talk_deal,connections,success_stories`, 5x time, the real screen,
  room and host, a child who always does the right thing): **36 of 36 passed** (every track flat, Expert and VR;
  2.3-4.7 s each).
- **The full suite** (2026-10-17, after merging `lead-merge` at `de8ec9a4`, one run in a PC-wide slot): 1,209 scripts, 11,133 tests: **11,130 passed, 0 failed**, 3 risky or pending (the two old "did not assert" in `test_meadows_biome_generator.gd` and the device move's pending by design), 4,194 s.

## What the lead must check (I could not: no editor, no emulator, no headset)

On the emulator (`Pixel_8_API_35`), flat:
- The Life map's Success row of six at the real font (18 px words on narrower cards); the four areas' unit cards and the
  place buttons under them.
- MY GOAL BOARD's two panels (the goal and the habit garden) at phone size; the wizard's pages (the dreams, the steps, the
  WHEN and I WILL rows of six); the plant's drawing at each stage; the celebration.
- The Connections Book's cards (faces, names, the warmer glow), a person's page; the story shelf's cards and a story's
  reader; the question's three answers.
- Each room: the stall and Robo's mat, Ana's cart, the meeting tent (the pitch board's cards readable), the Goal Room's
  board and calendar, the village (people's names over their heads), the Story Theatre's scenes; FPS ≥ 30, no frame over
  100 ms (each room is under ~250 boxes; the village has 13 buddies).
On the Quest 3:
- The handshakes with Ana and Ms Ade (the hand squeezing at the spot); standing in front of the investors; the laser on
  each investor, the people and the stage's things; the blink between the spots; the board's cards readable at 1.8 m;
  72 Hz in the village.
- The night in the village (the head keeps the day: ruling 26).

## Next

S3 (the shop, the Market Square) grows from the stall and Talk & Deal's customers; the Connections Book's people can
become the Market's merchants and the shop's suppliers (their needs and offers are already data). Life Town's four
places; the calendar and the jar into the Tool Book; a gaze sample for eye contact in VR; the experts' review of the
sheet (a child psychologist, a speaking-and-listening teacher, a financial educator, an online-safety educator, a history
teacher).
