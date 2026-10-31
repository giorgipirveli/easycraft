# Life L2: Safe Streets, The Kitchen, Calm Corner, Life Town (owner #112, #113, #116, #117)

The owner (2026-10-16): life skills are "the future of education" (#112); "children should understand everything easily"
(#113); "they should be able to use any instrument and devices ... we must use same aproach for any skills children need
in real life" (#117). The brief: `docs/superpowers/plans/2026-10-16-life-l2-brief.md`; the designs:
`docs/design/life-skills.md` (§3, §5 #4-#6, §6, §7, §10, §11, §13) and `docs/design/success-skills.md` (the Kitchen's
budget week links to Money); the spec: §27.2 ("As built (L2)"). Built by the Life L2 agent on the branch
`worktree-agent-life-l2` (its first worktree was cleaned away unchanged by a network stop; the second one was cut from
`lead-merge` at `6f05bbba`, and `lead-merge` merged in again at `a5df827a` before the final suite: VR-HANDS' shared grab,
VR-SOUND, the owner's #118 design), on Life L1's framework (`docs/devlog/parts/life-l1.md`): nothing of it forked. The review
sheet for the experts: `docs/devlog/parts/life-l2-review.md` (written from the data by `tools/life_review_sheet.py`).

## What a child sees and does

All three Experiences are on the Life map (their units replace L1's "coming soon"): **Getting around** (Safe Streets),
**Home and everyday** (The Kitchen), **My feelings** (Calm Corner), each on the Little, Middle and Big track with LESSON,
PRACTICE (the School's format: a memory question first, "Try it" last, 11 exercises on three levels) and TRY IT, the
Passport's three stamps and the EXPERT TRY. The practice rooms work as in L1: Professor Hoot's words read aloud on
Little, "3 of 12", SHOW ME and I NEED A BREAK always, the one next thing glowing, the coach after 10 s (a ghost finger,
ghost hands in VR), the name-it card, the after-check, the stamps and Try it for real. The Passport now has pages
(L1's three Experiences, then L2's; NEXT PAGE / PREVIOUS PAGE).

### Safe Streets (the practice street)

A real-sized town street: two 3 m lanes, pavements with kerbs, houses, trees, street lamps, a lay-by, a speed sign in
the region's unit (30 km/h, or 20 mph in the UK and the US). Real-sized cars from the cars (#109: the off-roader, the
pickup, the race car and the bus, their own models and wheels) drive at 30-40 km/h on the region's side, in bunches with
a real gap every 16 s; their engines hum where they are (the cars' engine loop, positional), so a child can listen. A
child who steps out when it isn't safe sees the coming cars stop gently before the crossing ("Wait! A car is coming...")
and waits again: never a crash, and it counts as one kind miss. Waiting while cars pass is the right thing, so the coach
never nags a child who waits.
- **Little, Stop, look and listen:** Gus the grown-up buddy (a tall purple buddy) holds the child's hand (hold) → walk to
  the kerb and stop → look `{look_order}` (the region's: "left, right, left" where cars drive on the right) → listen
  (stand still) → wait for a big gap and cross with Gus (the far kerb glows only when it is safe) → walk, don't run →
  the family car in the lay-by: where children sit (the back, a booster seat) → climb into the booster → pull the belt
  across and click it → where the belt goes (over the shoulder, low on the hips; not the neck, not under the arm).
  Expert try: a car is heard round the bend before it is seen (an engine and soft rings), the gap without a glow, and a
  ball rolls into the road (stay on the pavement, ask a grown-up).
- **Middle, crossing alone, at night and on a bike:** a parked van hides the child: go to its edge and stop (never into
  the road to look) → look → cross on a big gap → a button crossing: press the button (WAIT lights), the red man means
  wait, the green man and the cars stopped: cross (pressing too early is a kind miss) → dusk (a calm deep blue, the lamps
  glowing): light clothes and something that shines, put on the shiny band, switch on the torch → Pip-pop's bike helmet:
  level on the head, two fingers above the eyebrows (hold), the straps' V under each ear, buckle it, one finger under the
  chin strap. Expert try: the green man flashes just as you get there (wait for the next one, without a glow) and a
  crossing in the dark.
- **Big, the rules of the road:** the driver's seat of a cut-away practice car "on rollers" (it never moves: no motion
  sickness, nothing can go wrong) at the stop line: belt on (pull, click), everyone's belt → the light turns red: stop at
  the line, then press and hold the brake (in VR: the trigger) → people cross on their green man → amber → green: go if
  the way is clear → the accelerator: keep the needle at the limit or under for 4 seconds (the gauge and the dashboard's
  speedometer; "Ease off" over the limit) → the phone buzzes: leave it → stopping distances (12 m at 20 mph, 23 m at
  30 mph) → a cyclist: 1.5 m → someone waiting at a zebra: give way. Expert try: a ball rolls into the road (brake: a
  child may follow).

### The Kitchen (the practice kitchen)

A bright child-sized kitchen: the worktop along the back wall with the sink (the tap, the soap pump, a towel), the kettle
on its base, the hob with its knobs and its hot light, the oven below, the fridge, a table with the healthy plate's foods,
the chopping board and a round-tipped child-safe knife, the jug and the measuring cup (marks at 1/4, 1/2, 3/4), the
scales, the bowl; on the Big track the pantry shelf with price tags in pretend coins. "TODAY: ..." names the try's recipe
(from many countries, varied by the seed: `core/life/life_kitchen.gd`). Calm: a soft orange glow under a pan, a small warm
hot light, never a flame.
- **Little, clean hands and a healthy plate:** twist the tap on → press the soap → rub for 20 seconds (the clock; the
  germs' green glow fades as the seconds go; hum Happy Birthday twice) → rinse → twist it off → dry → half the plate
  vegetables and fruit (pick two), a quarter grains, a quarter protein → water to drink → the bridge grip → cut
  `{cut_food}` with the child-safe knife (back and forth) → pour `{pour_words}` of `{pour_what}` to the line → stir →
  wipe the table. Expert try: when do you wash your hands (before food, after the toilet), three vegetables and fruit.
- **Middle, measure, cut and cook safely:** soap and 20 seconds, dry → spoon `{weigh_what}` onto the scales to
  `{weigh_g}` g (slowly near the end: too much and a little goes back) → pour a fraction of a cup → the claw grip →
  slice → whisk → the hob with a grown-up: turn the pan's handle in, the knob to low, it cooks (never left alone), the
  knob off → the hot light: still hot, don't touch → wipe. Expert try: the scales show 35 g with the empty bowl: press
  zero first.
- **Big, cook a meal and plan a week:** 20 seconds → raw meat on its own board → raw meat on the fridge's bottom shelf →
  the fridge at 5 °C or below → fill the kettle between MIN and MAX → switch on → it boils and switches itself off →
  pour slowly, away from you → weigh → slice with the claw → oven gloves on → open the oven, step back from the hot air →
  the tray out with both hands → onto the heat mat → the oven off → a week's shopping with pretend coins (23; needs
  first, one treat fits) → the better buy (3 coins a kilo, not 4). Expert try: a kettle filled above MAX (tip some out)
  and a tighter week (19 coins: needs only).

### Calm Corner (the quiet room)

Soft lilac walls, a round rug, cushions, a window with slow clouds, a lamp, a plant, books, a sleepy cat, a clock, a fish
in its bowl, the breathing balloon on a string, the worry box on a low table, the calm toolbox's picture cards and a
tablet on a stand (both shown only for their steps). Bobo, Mo and Pip-pop act the stories with their faces (happy, sad,
cross, worried, calm: never a scary face; the tablet says "a mean comment", never the words). Not therapy: kind, short,
always pointing to a trusted grown-up; **nothing a child picks is kept** (a feeling is any picture: no answer is marked,
the coach never picks one, the step log keeps no answer).
- **Little, name it, calm it:** Bobo's tower fell: how does Bobo feel (his face: sad) → how do you feel now (any
  picture, a kind reply) → balloon breathing three times (flat: hold for in, let go for out; VR: the hands rise and
  fall, or a squeeze) → Bobo is calm now → find five things you can see → a worry (school, a friend, the dark, something
  else, nothing today) into the worry box → Pip-pop is left out: ask her to play (she joins, everyone smiles) → who to
  tell (a grown-up you trust). Expert try: "you can't play with us" (say how you feel, play with someone else, tell a
  grown-up) and four breaths.
- **Middle, the calm toolbox:** Bobo and Mo both want the ball (both cross) → breathe four times → pick three calm tools
  (breathe, count to ten, a walk, talk, draw, music) → "I feel cross when you take the ball" → take turns → Mo is unkind
  to Pip-pop in the playground: stay with her and tell a grown-up → who can help → how do you feel now. Expert try: a mean
  message about Pip-pop on the tablet (don't reply, keep it, show a grown-up; BLOCK with the grown-up).
- **Big, pressure, and getting help:** friends push you to share a silly photo of Mo (say no) → how Mo might feel → a mean
  message to you (never your fault): don't reply, keep it, BLOCK, REPORT → slow breathing, in for four and out for four
  → five things you can see → when to get help (a worry that won't go away, someone hurting you: asking is brave) →
  where (a parent or carer, a teacher, a school counsellor, a doctor, a free children's helpline) → how do you feel now.
  Expert try: a whole group chat laughs at a post and asks you to add a joke.

### Flat and VR, the same steps

Flat: a finger on the thing does it, a held finger holds, pours, breathes in and presses a pedal; a finger moving on the
hands rubs; a drag across the food cuts, whisks and wipes; LOOK LEFT and LOOK RIGHT (big pictures with eyes and arrows)
or a sideways swipe look, and the view turns that way and comes back. VR: the head's turn looks (35° each way, in the
region's order); both hands moving at the sink rub; the hand at the jug, squeezing and tilted, pours (the scales: the
hand squeezing there spoons); the hands rising breathe in (a squeeze too, for a child who sits still); the knife, the
whisk and the cloth follow the hand's own path across the target; the practice car's pedals and the decision to cross are
the trigger itself (the laser to the far kerb crosses the HUD's tray: see ruling 6); LOOK LEFT / LOOK RIGHT appear on the
tray after the coach has shown a look twice.

### Life Town

A small district a short walk from the spawn of every home world (not Monster Wave's arena, not a space world), placed
like the Launch Site: the practice house with its red roof (Fire Escape), the clinic with its green cross (Little
Lifesaver), the market stall under a striped awning (My Money Stall), a short street with a crossing and a lollipop sign
(Safe Streets), the kitchen house with its chimney (The Kitchen) and a park bench under a tree (Calm Corner). Each has
its sign over the door (readable from anywhere, in VR too) and a soft green ring on the ground where to walk up. Walking
up to one opens Life over the world on that place's unit, on the child's own track (the track picked first, the very
first time), with LESSON, PRACTICE and TRY IT; TRY IT opens the practice room exactly as in the School (the world's HUD
hides while it shows; the avatar stands still and safe in the world: monsters and the night can't touch it). BACK, Esc or
Android Back closes Life (it stays closed until the child walks away and back); walking away closes it, never a room
that shows. MY MAP marks "Life Town" (a town's picture).

## How it is built

- **Rules (`core/life/`):** `LifeCheck` has 24 kinds (L2's seven: `look`, `cross`, `rub`, `pour`, `breathe`, `feel`,
  `steady`, each from the same one sample a frame; `LifeAuto` plays them; `feel` is in `LifeRun.NO_HINTS`);
  `LifeTraffic` (the street's scripted traffic: bunches, gaps, gentle stops, the button crossing, held lights, other
  crossing places, one lane only for the practice car); `LifeKitchen` (the recipes, the cup's fractions); `LifeTown`
  (the site search, the walk-up spots, the natural check, the trees to clear, the save); `LifeRegion.look_sides`,
  `speed_unit`, `speed_limit`; `LifeExperience.vars` gives every Experience the kerb drill's and the speed sign's words,
  the seed, and the kitchen's words (`"vary": "kitchen"`); `LifeCatalog.experience_unit`.
- **Rooms (`entities/life/`):** `StreetRoom`, `KitchenRoom`, `CalmRoom` (`LifeRooms.make`, every room gets `vars`);
  `LifeRoom.safe_now(step)`; `LifeBuddy.face(feeling)`; `LifeRoomHost` plays the new kinds flat and in VR (`LOOK_TURN`,
  `SWIPE_PX`, `RUB_GAP`, `RUB_SPEED`, `POUR_TILT`, `BREATHE_IN`/`OUT`, a step's `on_miss` event, reach `trigger` and
  reach `hand` sweeps), `LASER` 8 m (across the street), the group `GROUP` and `any_open(tree)`. Life Town:
  `LifeTownBuildings` (one vertex-colour mesh with WeaponModels' warmed material, a static body, LifeRoomKit's signs) and
  `LifeTownDirector` (node "LifeTown").
- **Screens (`ui/life/`):** `LifeRoomHud`'s LOOK buttons, `Gauge` (a pour's level, a pedal's needle) and `BreathGuide`, the
  rub's clock, the faces as picture answers, "Leave the practice?" (`open_leave`); `LifeIconsMore` (59 pictures: the
  street, the kitchen, the feelings; `LifeIcons` asks it for any name it doesn't draw); `LifePassportPage`'s pages;
  `LifeScreen.town_experience`; `LifeTownPanel` (Life over the world).
- **Data (`data/life/`):** `experiences/safe_streets.json`, `kitchen.json`, `calm_corner.json` (with their devices: the
  crossing, the seat belt, the helmet, the car; the tap, the scales, the hob, the oven, the till, the kettle; the
  tablet); 9 units in `units/`; `life.json`'s L2 units.
- **Hooks (marked owner #112):** `scenes/sandbox.gd` (`_setup_life_town`, `_mark_life_town`, `_life_take_over`, Back),
  `world/world_meta.gd` (`life_town`), `core/economy/earn_rules.gd` (`LIFE_SKILL_GOLD`, the `life_skill` row),
  `ui/shop/gold_shop.gd` (the How to earn list's words a size smaller past 14 rows), `ui/menus/menu.gd` (Back asks a
  practice room first).
- **Tools:** `tools/life_smoke.gd` (+ `_steps`: L2's kinds, `--only=` skills or Experiences, comma-separated, a timeout
  prints the step's state and the street's cars), `tools/life_town_smoke.gd` (+ `_steps`, new), `tools/life_review_sheet.py`
  (two sheets).

## Rulings (decided, with what each costs if wrong)

1. **The street's traffic is scripted in the room (LifeTraffic), never the world's cars**, with the cars' own models and
   engine sound. *Cost:* the world's driving physics isn't what the child sees; the models and sizes are.
2. **Real gaps:** bunches of three cars reach the crossing 2.8 s apart each 16 s cycle (jitter ±0.35 s), at 30, 35 or
   40 km/h; safe = nothing in the crossing's 4 m zone and nothing reaching it within 6 s (6 m at a child's ~1 m/s).
   Measured: the shortest safe window 3.55 s, the longest wait 12.2 s. *Cost:* constants (`LifeTraffic`).
3. **An unsafe step is a kind miss** (one hint: no By myself stamp that run) and the coming cars stop gently before the
   crossing (hard braking at most 7 m/s², stopping 4.5 m or more before its middle), wait 2.5 s and drive on. *Cost:* a
   child who steps out once loses that run's By myself stamp (they can try again at once).
4. **Waiting is progress** (the coach never shows while a car comes) and **the far kerb glows only while it is safe**
   (never on the Expert try, `"glow": false`). *Cost:* the glow helps the judgement on Little and Middle; the Expert
   try is the honest test.
5. **A look is 35° of the head's turn** (back under half of it, or the other way, is a new look); flat, a LOOK button or a
   sideways swipe of 110 px, and the view turns 66° that way for 0.9 s. The wrong way first is kind words, never a miss.
   *Cost:* constants (`LifeCheck.LOOK_YAW`, `LifeRoomHost.LOOK_*`).
6. **In VR the crossing is the trigger itself** (reach `trigger`): the smoke found the laser to the far kerb crosses the
   HUD's tray (Vr.ui_wants_pointer), and the skill is the timing, not the aim (the way is straight across). The
   trigger never counts while it is over the panel's buttons. *Cost:* the child doesn't point where they go; a VR walk
   across would be truer (the Quest check).
7. **The Big track's car never moves** ("on rollers"): the views blink between the driver's view, the pedals' and the
   belt's; the accelerator moves the needle, not the car. No motion the child didn't make (vr-research's comfort rules).
   Its traffic is the oncoming lane only. *Cost:* less like driving; a moving drive is a later round with the vignette.
8. **The speed sign is the practice street's own** (30 km/h, 20 mph in the UK and the US: a school street), never a
   claimed national limit; the stopping distances are the UK Highway Code's (20 and 30 mph, with km/h beside). *Cost:*
   a country with other numbers sees the UK's distances, said as "about".
9. **Children's car seats:** "in the back, in a booster seat" and the belt's fit (NHTSA), without ages or heights (they
   differ by country). *Cost:* the grown-up checks their country's rule (the Try it for real card).
10. **The helmet is fitted on Pip-pop** (the child is the helper, as with Bobo in L1), by the 2-V-1 fit. *Cost:* the child
    fits their own helmet only on the Try it for real card.
11. **Pouring:** held pours at the step's rate; let go within ±tol is done; under it "a little more"; over it, a little goes
    back (to want − 2 tol) and the child pours again: never a miss. VR pours only with the hand tilted 40° or more
    (`POUR_TILT`); the scales (spooning) need only the squeeze. *Cost:* no real liquid physics; the jug doesn't leave the
    table until VR-HANDS' grab lands (no grab system of our own, as the brief says).
12. **Rubbing counts only while it moves:** flat, the finger moved within 0.3 s; VR, a hand at the sink moving faster
    than 0.12 m/s. 20 s of rubbing (the CDC's "at least 20 seconds"), the germs' glow fading with it. *Cost:* constants.
13. **The knife is child-safe and round-tipped; Little cuts soft food with the bridge, Middle and Big the claw**, a
    grown-up near; the hob and the oven always "with a grown-up". *Cost:* a parent who prefers no knife for 6-year-olds
    plays the choice question only (one data change).
14. **Recipes vary by the seed** (four a track, from many countries: `LifeKitchen.RECIPES`); the steps stay the same.
    *Cost:* the recipe's own steps (a real dal) are not taught: the skills are.
15. **The week's budget is pretend coins** (23, or 19 on the Expert try; needs 18), like the stall's (L1 ruling 10).
    *Cost:* numbers in the data.
16. **Calm Corner keeps nothing a child picks:** `feel` has no right answer, is never marked, never coached, and the step log
    keeps only its seconds; the before-and-after checks ask knowledge ("what helps you calm down?"), never feelings.
    *Cost:* the grown-ups' page can't say how a child felt (by design).
17. **No helpline numbers in the game:** "a free children's helpline" (Child Helpline International lists them), and the
    Try it for real card asks the grown-up to find their country's. The careful topic "hard times" (crises) stays off
    and empty (design §6). *Cost:* a child doesn't learn the number in the game.
18. **The stories never show unkind words:** faces, a "..." and "a mean comment" on the tablet. *Cost:* less real; kinder.
19. **Balloon breathing:** in at least 3 s and out at least 3 s (4 and 4 on Big); too quick is "Slowly, like filling a
    balloon", never a miss. VR in = the hands' height 40 cm or less under the eye (out under 55 cm), or a squeeze.
    *Cost:* constants; a child with tracking trouble uses the squeeze.
20. **Life Town is models, placed like the Launch Site** (a worker's search, 30-54 blocks from the spawn, away from the
    Theater and the Launch Site and never hiding behind them), **each place on its own ground** (no common slab: the
    meadows roll), **and the host clears the trees in and right round its places once** (like the Launch Site's stamp;
    meadows are wooded: without clearing, 0 of 8 test seeds had room, with it 7 of 8; the search takes up to ~110 ms on
    a worker). A child's build in its box moves it before it stands. No blocks taken (page 45 stays free). *Cost:* a few
    of a new world's trees go; a world with no room (all sea) has no Life Town (Life is still in the School).
21. **Walking up opens the place's unit, not straight into the room** (one tap: TRY IT), so walking past a building never
    throws a child into a room. *Cost:* one tap.
22. **While a room from Life Town shows, the avatar is held** (its physics and block taps off) **and kept safe** (3 s of
    protection every second); the world goes on (friends, the day). *Cost:* a friend can't move the child's avatar
    (nobody can push it).
23. **Life's gold in the world** goes into the profile like the School's over the Theater (ShortsSchool's way). *Cost:*
    as the School's.
24. **The Gold Shop's How to earn** names Life ("A Life skill practised to the end (once per skill and track)", 100,
    `EarnRules.LIFE_SKILL_GOLD` = the unit's 100); its words are a size smaller past 14 rows so the page fits.
    *Cost:* smaller words on that page.
25. **Android Back in a room asks "Leave the practice?"** (the room's own calm card: CARRY ON or LEAVE = STOP FOR NOW; a
    second Back carries on); the menu asks `LifeRoomHost.any_open` first; Life Town's panel leaves Back to the room.
    *Cost:* Back never leaves a room by itself (LEAVE does).
26. **The Passport turns pages** (three Experiences a page) and its cells are 140 px tall (150 before) so a page fits the
    frame. *Cost:* the child turns a page to see L2's stamps.
27. **The laser reaches 8 m** (6 in L1) for the street. *Cost:* farther things can be pressed in every room.
28. **Motions named (owner #117):** the knife cuts; the whisk, the cloth, rubbing hands, drying and pulling a belt across
    stroke; taps, knobs and a pan's handle twist; the scales and two fingers on a helmet measure; a jug and a kettle pour;
    the buckle and oven gloves squeeze; soap pumps, buttons, pedals, BLOCK and REPORT press. *Cost:* one data field per
    step when the shared recogniser wants another word.

## The facts and their sources

Every step's words and its source are in `docs/devlog/parts/life-l2-review.md` (from the data), for the owner's experts:
a road safety officer, a food safety and nutrition educator, a child psychologist or school counsellor. The authorities:
- **Road safety:** the UK Highway Code, rules for pedestrians 1-35 (the Green Cross Code, Rule 7; be seen, Rule 3; parked
  vehicles, Rule 14; button crossings, Rules 21-23) (https://www.gov.uk/guidance/the-highway-code/rules-for-pedestrians-1-to-35),
  general rules 103-158 (stopping distances, Rule 126) (https://www.gov.uk/guidance/the-highway-code/general-rules-techniques-and-advice-for-all-drivers-and-riders-103-to-158),
  using the road 159-203 (lights, Rules 175-176; phones, Rule 149; cyclists, Rule 163; zebras, Rule 195)
  (https://www.gov.uk/guidance/the-highway-code/using-the-road-159-to-203); the US NHTSA's car seats and booster seats
  (https://www.nhtsa.gov/vehicle-safety/car-seats-and-booster-seats) and bicycle safety (the helmet's fit)
  (https://www.nhtsa.gov/road-safety/bicycle-safety); the WHO's road traffic injuries fact sheet (seat belts: 45-50% and
  25%) (https://www.who.int/news-room/fact-sheets/detail/road-traffic-injuries) and pedestrian safety manual
  (https://www.who.int/publications/i/item/pedestrian-safety-a-road-safety-manual-for-decision-makers-and-practitioners);
  Schwebel et al.'s VR pedestrian training trials (https://pmc.ncbi.nlm.nih.gov/articles/PMC4990383).
- **Food:** the CDC's clean hands (https://www.cdc.gov/clean-hands/about/index.html) and the NHS's hand washing
  (https://www.nhs.uk/live-well/healthy-body/best-way-to-wash-your-hands/); the WHO's healthy diet
  (https://www.who.int/news-room/fact-sheets/detail/healthy-diet) and Five Keys to Safer Food
  (https://www.who.int/publications/i/item/9789241594639); Harvard's Healthy Eating Plate
  (https://nutritionsource.hsph.harvard.edu/healthy-eating-plate/); the UK Food Standards Agency's chilling
  (https://www.food.gov.uk/safety-hygiene/chilling); the British Nutrition Foundation's Food - a fact of life (the bridge and
  claw grips) (https://www.foodafactoflife.org.uk/); RoSPA's home safety (https://www.rospa.com/home-safety); the Child
  Accident Prevention Trust's burns and scalds (https://capt.org.uk/burns-and-scalds/); the OECD/INFE youth framework
  (budgets) (https://microfinancegateway.org/paper/2015/09/core-competencies-framework-financial-literacy-youth).
- **Feelings:** CASEL's framework (https://casel.org/fundamentals-of-sel/what-is-the-casel-framework/); the NHS's breathing
  exercises for stress (https://www.nhs.uk/mental-health/self-help/guides-tools-and-activities/breathing-exercises-for-stress/);
  UNICEF's cyberbullying (https://www.unicef.org/end-violence/how-to-stop-cyberbullying) and talking about bullying
  (https://www.unicef.org/parenting/child-care/how-talk-your-children-about-bullying); StopBullying.gov
  (https://www.stopbullying.gov/); Childline (https://www.childline.org.uk/); Child Helpline International
  (https://childhelplineinternational.org/).
- **Not re-fetched in this session** (the brief: no downloads): the URLs and wordings come from the authorities' published
  guidance as known; the experts' review checks each against the current pages (most need a look: the CDC's 2024 site,
  RoSPA's and CAPT's paths, UNICEF's parenting page, NHTSA's helmet page).

## Tests and measurements

- **Unit:** `test_life_check_l2.gd` (the seven kinds, the automatic player), `test_life_traffic.gd` (speeds and sides, a safe
  gap every cycle (the shortest 3.55 s), safe means safe, the gentle stop and drive-on, no car into another, the button
  crossing, the seed), `test_life_l2_vars.gd` (the kerb drill and the sign by region, the recipes and fractions),
  `test_life_town.gd` (the six places, the site's rules, the landmarks, dry land, trees cleared, the sea, walking up,
  a child's build, the save, real meadows: 7 of 8 seeds, the world's save), and L1's files updated: the six
  Experiences (no problems in any region or seed, an automatic player finishes every track and try), L2's motions and
  devices, the catalog (every Experience's own units, no "coming soon" left for a built one), the Gold Shop's row.
- **Integration:** `test_life_rooms.gd` (now all six rooms and L2's kinds: every target and view, everything to tap on
  the 16:9 screen from its view, everything to touch in reach in VR, warmed shaders only, no shadows),
  `test_life_room_host_l2.gd` (14: the looks flat and VR, the crossing flat and VR, rubbing, pouring, breathing, feeling,
  the pedal, the cut), `test_life_icons_l2.gd`, `test_life_town_director.gd` (7), `test_life_back.gd` (3),
  `test_life_screen.gd` (the Passport's pages, "coming soon" for a later wave).
- **The flake** (the lead's full suite on a busy PC: `test_a_tap_on_something_else_waits_kindly` saw "safe"): the host
  tests' helpers now wait for the state they need (`_taken`: the host sampled the input; `_next_started`: the next step
  began; `wait_until`, 3 s at most) instead of fixed frame counts, in L1's and L2's host tests.
- **Mutation checks:** the trigger reach (the VR crossing and the pedal tests fail without it), the menu's Back hook (the
  Back test fails without it).
- **The smoke (`tools/life_smoke.gd`, 5× time):** L2's 27 runs (every track, flat, Expert and VR): its first runs found two
  real problems, both fixed: a held finger that went down while the view still glided landed on another thing (the
  smoke now presses again on the thing), and in VR the laser to the far kerb crossed the HUD's tray (ruling 6). Then
  27 of 27 passed (3.1-12.9 s each). **The whole smoke, L1 and L2, 54 runs: 54 passed** (2.4-12.8 s each; L1's 27 as
  before). After merging `lead-merge` (VR-HANDS' grab landed): the 18 VR runs again, 18 passed.
- **The town smoke (`tools/life_town_smoke.gd`), a new Green Meadows world, seed 12345:** Life Town stood after ~6 s at
  (-13, 27, -31), the save keeps it, six signs, clear of the Launch Site; walking up to each of the six places opened its
  Experience; TRY IT at the kitchen opened the room over the loaded world (the HUD hidden, the avatar held); 185 frames
  in the room, average 32.6 ms, worst 72.4 ms (headless on this shared desktop at load ~7, the world streaming and
  living below); STOP FOR NOW gave everything back; walking away closed Life: 22 checks, 0 failed. After the merge its
  first run found a real problem: a BACK at the bench still held the kitchen when the child walked straight on (fixed
  test-first: `test_back_at_one_place_never_holds_the_next`); then 22 of 22 again, twice (in the room 114 frames, 52.9 ms
  average and 136.9 ms worst while the PC's load was 33 with other agents' suites). One of those runs printed glibc's
  "corrupted double-linked list" after its result, at the engine's quit (exit status unaffected), once in four runs and
  not again: noted for the lead (the quit comes 0.3 s after the world's workers were busy; nothing of Life's runs then).

## What the lead must check (I could not: no editor, no emulator, no headset)

On the emulator (`Pixel_8_API_35`), flat:
- The street at the real screen: the cars' sizes and speeds feel real; LOOK LEFT / LOOK RIGHT and the swipe; the view's
  turn; the far kerb's glow only when safe; a car stopping gently when tapped too early; the engines' sound; dusk.
- The kitchen: the germs' glow fading over 20 s; the cup's and the scales' gauges; the cut's drag; the hob's glow.
- Calm Corner: the faces read as feelings at phone size; the balloon guide's pace.
- The Passport's two pages; the Gold Shop's How to earn page (smaller words) fits.
- **FPS ≥ 30, no frame over 100 ms** in each room, the street most (its cars, ~200 boxes, the engines); and in a room
  opened from Life Town (the world loaded below: the smoke's headless frames averaged 33 ms on this busy desktop).
- Android Back in a room ("Leave the practice?"), and from Life Town's panel.
- Life Town in a new world and an old one: the six places, their signs, the rings; walking up; MY MAP's mark; the
  trees cleared round the places; a LAN guest sees it too.

On the Quest 3:
- The street at real scale: the head's look (35°), the trigger to cross, the cars' sound from where they are, the
  practice car's views (driver, pedals, belt) and the trigger as the pedals, LOOK buttons after two coach showings.
- The kitchen: rubbing at the sink, the tilt to pour, the knife's path, the oven's tray with both hands.
- Calm Corner: the hands rising to breathe, the five things round the room (reachable with the laser), the tablet's
  buttons.
- Comfort (no motion but blinks), 72 Hz, the light at night in a room opened from Life Town (the rooms' own lights).

## Next

The lead's E0 ease audit through L2's rooms (a pad there, the street's swipe), the census through a room
(`tools/shader_probe_steps.gd --shader-census`), the experts' review of `life-l2-review.md`; L3 (Online City, Earth
Shakes, Water Safety, Find Your Way, Home Helper) on the same framework; when VR-HANDS' grab and the tool recogniser land
(round 4b), the jug, the knife, the whisk and the belt become real held tools (their motions are already named). The
owner's #118 ("dangerous things, learned safely", design §14, merged while L2 was built): L2's unsafe crossing is its
first "safe mistake" in spirit (the car stops gently, a kind word, then the right way); the step kind with time frozen,
the time scale and the intensity setting are L3's first step, as §14 plans: Safe Streets' crossings and the Kitchen's hob
are their first users.
