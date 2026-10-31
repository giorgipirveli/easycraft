# Life L3a: safe mistakes, then Water Safety, The Poisons Cupboard, Earth and Weather (owner #112, #117, #118)

The owner (2026-10-16 19:51, #118): "consider somethimes in real life teaching some staff is dangerous, we can use this
online environment to teach them safely, so think what such things we can implement into game". The brief:
`docs/superpowers/plans/2026-10-16-life-l3a-brief.md`; the design: `docs/design/life-skills.md` §14 ("Dangerous things,
learned safely": safe mistakes, time frozen, the coach's calm why; prevention first; calm, never scary) with §3, §6, §10,
§11, §13; the spec: §27.5 ("As built (L3a)"). Built by the Life L3a agent in the worktree branch
`worktree-agent-a28f46edfdb6cb15d`, on `lead-merge` at `979caa1d` (Life L1 and L2, the tool engine and Real Builder, VR
round 4), on Life's own framework (nothing of it forked). No editor, no emulator, no adb, no download, no agents. Logs:
the session scratchpad's `life3a_*`. The experts' review sheet, written from the data:
`docs/devlog/parts/life-l3a-review.md` (`tools/life_review_sheet.py`).

## The framework additions (Life's own, test-first)

**(a) The safe mistake.** A step may carry `safe_mistake` {wrong, try, event, icon, why, right}: the child may do the
wrong thing. `try` names a target in the room (pressed, tapped or pointed at), a body action ("action:stand": the head
coming up after being low in this step in VR, the STAND UP picture flat), or, on a picture step, the picture marked
`"mistake": true`. When the child tries it (LifeCheck says `mistake`, never a miss):
- **time freezes**: the room's own simulation and every tween in it stop (`LifeRoom.freeze`: its process disabled), the
  glow goes out, a soft chime;
- **the scene softens and stills, never sudden**: flat, a pale see-through veil fades in over the room in 0.8 s; in VR the
  view dims to 35% over 0.8 s (`Vr.set_dim`, the comfort sphere, drawn under the panel), never black;
- **the room shows calmly what would happen** (`LifeRoom.show_mistake`, a still picture, never an injury): a second figure
  in the water beside the friend ("NOW TWO NEED HELP"), a tired swimmer held in the rip's arrows ("THE RIP IS FASTER THAN
  YOU"), cracks spreading round a figure standing on the ice, a soft grey-green cloud over the bucket ("A HARMFUL GAS"),
  roof tiles and a little glass frozen in the air by the doorway a figure ran to ("THINGS FALL BY DOORS");
- **the coach's card** (HUD): "Time stands still. Let's see why.", the picture (`icon`), the calm why, the right way in
  green, GOT IT (the A button too) and a speaker; read aloud by Read to me or the speaker (no mistakes on Little);
- **then the step goes on**: GOT IT takes the picture and the veil away, the room moves again, the right thing glows, the
  coach says the right way and shows it (a ghost finger, or ghost hands in VR) and the child does it right.
On the **Little track** no mistake is ever shown: the coach says the rule first ("Never jump in", "never run outside while
it shakes") and the data validation refuses a safe mistake there (`LifeExperience.problems`). A safe mistake is **never a
hint on a normal try** (the By myself stamp stays: trying the wrong way and seeing why is learning) and **one hint on the
Expert try** (the honest test). The device's measurement counts it (`LifeMeasure`'s `m` and `fm`: how many runs, and
whether the very first, tried the wrong way). Also: `not` {target: words} on a touch or go step (a harmless wrong tap: a
playing buddy when the quiet one needs help) is a kind miss with its words, and `within` / `late`: a danger moment's action
wanted within its seconds of the room's time (too late is a kind miss, its clock starts again).

**(b) The time scale.** A step with `danger: true` is a danger moment: the room's own time there (`LifeRoom.time_scale`;
rooms move by `sim_delta`) is `LifeRun.time_scale(runs, expert, more_real)`: 0.5 on a skill's first two tries, 0.75 after
that, real time (1.0) on the Expert try and when a grown-up chose "more real". The HUD shows SLOW PRACTICE (a clock) while
it is slowed. What slows: the rip's arrows, the shaking (the lamp, the books, the picture), the storm's rain and thunder,
the flood's water, and the `within` clock of the earthquake's drop and cover (5 and 10 s of the room's time on Middle: 10
and 20 real seconds on a first try, 5 and 10 on the Expert try). Danger moments: Water (the throw on Little, the rip on
Middle, the cold-water steps on Big), Earth (drop, cover, hold, the aftershock, the lightning). The Poisons Cupboard has
none: nothing in it moves fast.

**(c) The intensity.** `LifeData.intensity` (GENTLE by default, or REAL), on the grown-ups' page's new **SAFETY** tab:
GENTLE / MORE REAL, what it changes ("danger moments at real speed from the first try, and the storm, the shaking and the
alarms a little stronger. Never injuries, never scares: the freeze, the coach and the way out stay.") and what a safe
mistake is. It only ever reaches the **Big track** (`LifeData.intensity_for`). What "more real" changes, kept modest
(`LifeRoom.more_real`): real time from the first try; the shaking's sway ×1.6 and its rumble louder (-6 dB instead of
-14); the thunder nearer (-8 instead of -16); the CO alarm's beep at -2 dB instead of -8; the rip's arrows ×1.4; the
pond's cold water a little darker; ten cracks instead of seven in the ice's picture. Never anything new to see or read
(a test holds it).

**(d) The debrief and the way out.** Little Lifesaver, Fire Escape and L3a's three are `emergency: true`: after the
practice room the **DEBRIEF** page comes first: Professor Hoot, a heart, "You did it. In real life, grown-ups help too.",
"It was practice, and everyone is safe. If something worries you, talk to a grown-up you trust. In a real emergency, the
number is 112." (the region's), read aloud, NEXT to the name-it card. STOP FOR NOW in one of them says it too ("... In real
life, grown-ups help too."). I NEED A BREAK, STOP FOR NOW and Android Back work at any moment, also while frozen (the break
card lies over the freeze's card), and closing while frozen leaves the VR view clear.

Also grown in the framework: `glow: false` now hides the glow on any kind of step (an Expert try; SHOW ME still shows the
way); an action step's `button` (its big button's words: KEEP STILL, COVER HEAD); a basket's `label`, `unit` and `pay`
("In the bag: 6 of 10 spaces", ZIP IT UP); an area page with more than five units shows them in two rows (Staying safe now
has 7-8 per track); the region's `{quake_where}` sentence (`LifeRegion.quake_words`).

## What a child does in each Experience

Every Experience: flat (a finger, the mouse) and in VR (hands, the laser, the head; the views blink between spots, the
child is never moved by anything), on all three tracks, each with its Expert try, the before-and-after picture check, the
name-it card in the authorities' words with its source, Try it for real, the Passport's stamps, gold once, the debrief.
Every hands-on step names its motion, tool and device (owner #117; the Tool Book's seven new entries: life jacket, float
(lifebuoy), reaching pole, whistle, emergency bag, child lock, carbon monoxide alarm).

### Water Safety (the practice pool, the practice beach, the practice pond in winter)

- **Little, Water rules and help from the side (11 steps; Expert 12):** who must be with you near water (a grown-up
  watching) → walk, don't run → help Bobo into his life jacket and click its buckle → Pip-pop slips in at the deep end:
  "Never jump in to help: even grown-ups help from the side with a float" → shout for help (touch Gus the lifeguard) →
  **throw the float** (aim at her: a danger moment, slow on the first tries) → hold the rope and pull her gently to the
  side, staying back from the edge → she is out and smiling. Expert: your ball floats into the deep water (ask a grown-up;
  never lean over, never jump in) and the throw doesn't glow. VR: the float is aimed with the laser and held still for a
  second; the rope is held with a hand (0.46 m from the eye).
- **Middle, Spot trouble, rips and life jackets (16 steps):** four friends in the pool: one needs help: **spot the quiet
  one** (Mo: upright, head back, mouth at the water, not waving); tapping Pip-pop (waving, laughing), Bobo (splashing) or
  Kiki (floating on her back) is a kind miss with why; their places vary with the seed → shout for the lifeguard first →
  Mo is near the side: "Help her!" (the pole on its rack, or the water: **safe mistake: jumping in after someone**) →
  lie or kneel at the edge → hold the pole out still → pull her in slowly → the beach: touch where it's safest to swim
  (between the red and yellow flags; the calm gap in the waves is a rip: a kind miss) → in the sea with a body board, a
  rip gently pulls out (its arrows drift out to sea) → which way do you swim? (**safe mistake: swimming straight back
  against the rip**; right: along the beach) → back in to the shore → can't swim out? float, raise a hand and shout → a
  life jacket on Pip-pop: on and buckled, then lift at the shoulders: it stays down (the fit). Expert: the quiet friend
  without a glow, the rip pulls the other way (its own view), nothing glows. VR: the child's eye is just above the water
  (the feet under it), the swim is the laser and the trigger at the buoy, then a blink.
- **Big, Thin ice and cold water (18 steps):** the frozen pond: can you walk on it? (stay off: you can't see how thick it
  is) → practice: in the cold water at the edge of the hole → keep still while the breathing calms (KEEP STILL; the first
  shock passes in about a minute) → turn back the way you came → both arms out flat on the ice → kick and slide out (four
  pushes) → lie flat → **roll away from the hole** (**safe mistake: standing up on the ice**: in VR the head coming up;
  flat, STAND UP beside ROLL) → crawl back to the bank, low → stand, the blanket, dry clothes, a grown-up calls 112 → Mo
  falls through near the bank → shout and call 112 first → "Help Mo!" (a long branch on the bank, or the ice: **safe
  mistake: walking onto the ice to help**) → lie down on the bank → hold the branch out still → pull her slowly out → wrap
  her in a blanket. Expert: you choose the way out (back the way you came), and the crawl doesn't glow. VR: in the hole
  the eye is 0.5 m over the ice and the ice edge at chest height (0.65 m from the eye); on the ice the child crouches.

### The Poisons Cupboard (the practice kitchen, the garage, the hall at night and the front garden)

- **Little, Danger bottles and safe hands (7 steps):** find the 4 things with a warning sign (the red diamond: bleach,
  oven cleaner, washing tablets, drain cleaner; each says why) → never touch: tell Gus, who puts them up high, locked →
  medicine looks like sweets: only from your own grown-up → a tiny round battery: give it to a grown-up → red berries in
  the garden: never eat them. Expert: 5 to find, one a cleaner poured into a juice bottle.
- **Middle, The cupboard, the lock, never mix (13 steps; Expert 14):** find the 4 warning signs themselves (corrosive,
  toxic, flammable, harmful: each says what it means) → Gus puts the cleaners in the high cupboard → **click the child
  lock** (press) → pull the door gently: it holds → Mo: "Let's pour the bleach and the toilet cleaner into the bucket
  together, for a super cleaner!" (Gus, or the bucket: **safe mistake: two cleaners poured together**) → the garage: the
  3 things to lock away (antifreeze, weed killer, paint thinner) → a friend's headache tablet: no → the remote's button
  battery: pick it up, give it to Gus → a swallowed one is an emergency: call 112 at once → wild mushrooms: never.
  Expert: a bottle with no label (never sniff or taste: tell a grown-up) and the lock without a glow.
- **Big, Carbon monoxide and emergencies (15 steps):** the CO alarm: a gas you can't see, smell or taste → **test it**
  (press and hold until it beeps; the device co_alarm) → night: the alarm sounds → wake everyone and get out (not back to
  bed, not just a window) → wake Gus on the sofa → out of the front door → call 112 from outside (the play phone) → when
  can you go back in? (when the fire service or a gas engineer says so) → a stain and two cleaners: help the grown-up the
  safe way (one bottle, or the bucket: **safe mistake: pouring two cleaners together**; the why names chlorine and
  chloramine) → a little cousin may have swallowed a button battery: call 112 at once (never make her sick; keep the
  packet) → medicine: the label's amount from a grown-up → a friend wants to pick wild mushrooms: no. Expert: Gus says
  "it's probably just the battery" (get out anyway; never take the battery out), and the door doesn't glow.

### Earth and Weather (the practice room, the garden's open ground, the park, the flooded path, the woods, the bag shelf, the playground)

- **Little, Shake and storm drills (12 steps):** "Sometimes the ground shakes... In Georgia the Caucasus mountains are
  still growing, so the ground can shake here. The rule: never run outside while it shakes. Drop, cover, hold on." (each
  region its own sentence) → it shakes (the lamp and the books sway; the view never does): **drop** (within 8 s of the
  room's time) → **cover** under the strong table → **hold on** to its leg until it stops → wait for your grown-up → walk
  out with Gus to the open grass → a storm in the park: thunder! go inside (never under the big tree) → lost in the woods:
  **hug a tree** (both hands on the trunk) → you hear your name: shout back. Expert: it starts by the window, and the
  table doesn't glow.
- **Middle, Earthquake, flood, lightning and heat (11 steps):** drop (within 5 s) → cover under something strong (the
  table, or the door: **safe mistake: running outside during the shaking**) → hold on → walk out (don't run) → to open
  ground, away from buildings, trees and power lines → an aftershock: cover your head and neck (COVER HEAD) → fast water
  across the path: turn around (15 cm can knock you over) → thunder on the football field: inside a building or a car
  (not the lone tree, not lying flat) → a hot day: shade, water and rest. Expert: no table today: get down by an inside
  wall and cover your head (the door is still the safe mistake), nothing glows.
- **Big, Ready for anything (18 steps; Expert 15):** pack the family's emergency bag first (water, a torch, a whistle,
  first aid, warm layers, food that keeps: 9 of its 10 spaces; the games and the big teddy don't fit) → days later it
  shakes by the window: drop (within 4 s) → away from the glass, under the table (**safe mistake: running outside during
  the shaking**) → hold on → shoes on before you walk (broken glass) → out with the family and the bag → open ground → a
  thunderstorm in the hills: go down, away from peaks, lone trees and water, and get inside → lost in the woods: stop and
  stay put → by a big tree → put on the bright jacket → blow the whistle again and again → cold and wet: layers, a hat,
  keep dry → a heatwave: shade, water, rest, never anyone in a parked car. Expert: the shaking starts outside by the
  school: to the clear space if you safely can (the school's door: **safe mistake: running into a building during the
  shaking**), then drop and cover your head.

## Life Town

Three new places on the plaza's free cells, each with its sign and green ring, every door more than two reaches (3.6 m)
from every other (walking up to one never opens another): the **practice pool** (front row between the street and the
bench: a white rim, blue water, a float on its post, the red and yellow flags; Water Safety), **the poisons cupboard's
little house** at the back row's end (white, a big red-diamond sign, a door with a green child lock; The Poisons
Cupboard) and the **weather hut** between the building site and the street (an open front with a strong table inside, a
wind vane and a little cloud on its roof; Earth and Weather). The plaza is full after these: the next wave needs a second
row. Measured: 7 of 8 real meadows still get their town (as before), the slowest search 109 ms.

## How it is built

- **Rules (`core/life/`):** `LifeCheck` (`safe_mistake`, `tries_mistake`, `not`, `within` / `late`, `WRONG_ACTIONS`,
  `SAFE_MISTAKE_KEYS`; its `feed` says `mistake`), `LifeRun` (mistakes per step, a hint only on the Expert try,
  `time_scale`, `SLOW_FIRST` 0.5 / `SLOW_LATER` 0.75 / `SLOW_TRIES` 2), `LifeData` (`intensity`, `intensity_for`,
  GENTLE / REAL), `LifeExperience` (the three ids, `emergency`, `vars(..., intensity)` with `{intensity}` and
  `{quake_where}`, no safe mistake on Little), `LifeRegion.quake_words`, `LifeMeasure` (`m`, `fm`), `LifeTown` (three spots).
- **Rooms (`entities/life/`):** `LifeRoom` (`time_scale`, `sim_delta`, `freeze`, `show_mistake` / `on_mistake` /
  `mistake_holder`, `more_real`), `WaterRoom` ("water"), `PoisonsRoom` ("home_hazards"), `EarthRoom` ("earth")
  (`LifeRooms.make`), `LifeRoomHost` (`setup(..., intensity, runs_before)`, `danger_scale`, `freeze_for`, `unfreeze`,
  `FREEZE_FADE` 0.8 s, `MISTAKE_DIM` 0.35, the glow rule), `LifeTownBuildings` (`_pool`, `_cupboard`, `_hut`).
- **Screens (`ui/life/`):** `LifeRoomHud` (the veil, the mistake card and `mistake_ok`, SLOW PRACTICE, the wrong action's
  button, an action's `button`, a basket's `pay`), `LifeScreen` (DEBRIEF, the host's intensity and runs, two-row areas),
  `LifeGrownUpsPage` (SAFETY, L3a's authorities), `LifeIconsDanger` (45 pictures; `LifeIcons` asks it last).
- **Data:** `data/life/experiences/water_safety.json`, `poisons_cupboard.json`, `earth_weather.json`; nine units in
  `data/life/units/` (water_rules, spot_trouble_and_rips, thin_ice, danger_bottles, poisons_cupboard, carbon_monoxide,
  shake_and_storm, earthquake_and_weather, ready_for_anything: the School's bar, 11 exercises on three levels each) and
  in `life.json` (Staying safe); `emergency: true` on Little Lifesaver and Fire Escape; `data/tools/tools.json`: seven new
  entries (owner #118).
- **Tools:** `tools/life_smoke_steps.gd` (the DEBRIEF page, GOT IT, the `mistake` and `mistake_vr` modes),
  `tools/life_review_sheet.py` (the third sheet).

## Rulings (decided, with what each costs if wrong)

1. **The safe mistake is a step's `safe_mistake` with a `try`, not a new LifeCheck kind**, so any kind can carry it (a
   touch, a go, a picture, a body action) and its own rules stay. *Cost:* "a safe mistake step kind" (the brief) is a step
   property; one validation path (`LifeCheck.problem`).
2. **Never a hint on a normal try, one on the Expert try** (error-management training, design §14 [L18]: making the
   mistake is the lesson; the Expert stamp is the honest test). *Cost:* a child who tries the wrong way on Expert waits
   for the stamp (and can try again at once).
3. **The freeze waits for GOT IT** (no timer): the child hears or reads the why. *Cost:* one tap more; the A button and
   the panel's laser do it in VR.
4. **"Softens" is a veil flat and a 35% dim in VR** (the comfort sphere's dim, under the panel): no blur, so no new shader
   (the web build and the Quest compile nothing new). *Cost:* VR's softening is a gentle darkening, not a blur.
5. **The room's picture of what would happen is still** (set at once, frozen with the room): figures with worried faces,
   never hurt; words on calm yellow signs. *Cost:* nothing moves in the picture (it is a frozen moment by design).
6. **Little never shows a mistake**; its coach says the rule before the risky step, and the data validation enforces it.
   *Cost:* Little learns by being told and doing it right, not by trying the wrong way.
7. **Time scale 0.5 (tries 1-2), 0.75 (later), 1.0 (Expert and "more real")**, only on `danger` steps, only the room's own
   motion and the `within` clocks (the child's own holds and the coach's 10 s stay real time). *Cost:* constants in
   `LifeRun`.
8. **"More real" is the Big track's only, a grown-up's choice, and modest** (real time from the first try; the effects
   ×1.4-1.6; the sounds 6-8 dB louder): never an injury, a scream, a sudden scare or anything new to see. It merges as the
   newer copy's (like the careful switches). *Cost:* a grown-up hoping for "more real" sees a small change.
9. **The SAFETY tab** holds the intensity and what a safe mistake is (SETTINGS was full to the frame's last 6 px).
   *Cost:* one more tab on the grown-ups' page.
10. **The debrief comes before the name-it card** for the five emergency Experiences (and is said on the calm page after
    STOP FOR NOW); it says the region's number. *Cost:* one tap more after Little Lifesaver and Fire Escape too (L1's
    screen tests follow).
11. **Standing up on the ice in VR is the head rising above the low line after being low in this step** (so standing
    before lying down is never a mistake); flat, a STAND UP picture button beside ROLL (its side varies with the step).
    *Cost:* a seated VR child can't make that mistake (their buttons appear after two coach showings, as everywhere).
12. **Swimming is the laser and the trigger, then a blink; the rip never moves the child** (no motion the child didn't
    make: the VR comfort rules); its pull is shown by arrows drifting out to sea. *Cost:* no swimming motion; a later
    round could add arm strokes (the stroke motion).
13. **In the water the VR eye is just over the surface** (the sea: 0.3 m; the ice hole: 0.5 m, the ice edge at chest
    height). *Cost:* the Quest check must confirm comfort (it may feel low).
14. **The life jacket is fitted on a buddy** (Bobo on Little, Pip-pop on Middle), like L2's helmet; the child's own fit is
    the Try it for real card. *Cost:* no fitting on yourself in the game.
15. **Spotting trouble: the playing buddies are `not` taps (a kind miss, so a hint)**: spotting is the skill. *Cost:* a
    child who taps around loses that run's By myself stamp.
16. **The view never shakes in an earthquake** (comfort); the room's things sway; the rumble is soft (-14 dB), the thunder
    distant (-16 dB), no lightning flash (sudden). *Cost:* less real; the shaking is seen, not felt.
17. **No poison centre numbers in the game** (they differ by country and change); emergencies say the region's number and
    the Try it for real card asks the grown-up to find their country's poison centre. *Cost:* a child doesn't learn it in
    the game.
18. **The words never say "drown", "die" or "dead"** ("can't get out", "in trouble", "can hurt inside"); the Royal Life
    Saving Society's "Reach or throw, don't go" is said "never go in after them" (the words test also refuses "don't go").
    *Cost:* the slogans are paraphrased.
19. **The bottles are generic products with the GHS's real red diamonds**; Little finds the bottles, Middle the signs
    themselves (one target per thing: a tap goes to the nearest); the skull is on a pest killer (washing tablets wear the
    exclamation mark). The Big track names chlorine and chloramine. *Cost:* the product-to-sign pairs are typical, not
    every brand's; the poison centre expert checks them.
20. **Carbon monoxide is practised at night in the practice house** (the room's own sky darkens), the call from the front
    garden on the play phone. *Cost:* none known.
21. **Georgia's own guidance** is the `{quake_where}` sentence (the Caucasus still growing) and the Emergency Management
    Service of Georgia as a source beside ShakeOut's Drop, Cover, Hold On (not re-fetched: see the sources). *Cost:* if
    Georgia's service teaches something else, the expert's review changes the data.
22. **Life Town's three places fill the plaza's free cells** (the cupboard house and the weather hut are 2 m wide). *Cost:*
    narrow models; the next wave needs a second row.
23. **The Tool Book's new entries use ToolIcons' "safety" and "device" pictures** (ui/tools is not mine). *Cost:* plain
    pictures until the tools' owner draws a life jacket, a float, a whistle, a CO alarm.
24. **Real Builder's shaped safe mistakes stay valid without a `try`** (`LifeCheck.tries_mistake` false: they play as
    before, the coach's why and the room's event). *Cost:* the saw without goggles still doesn't freeze time: for the lead,
    one line in `ToolRoomHost._safe_mistake` (`freeze_for(step)` with a `try` added to the data) gives it the freeze.
25. **Safe Streets' unsafe crossing stays L2's kind miss** (a car stops gently): its wrong press is the same target as the
    right one at another moment, which `try` cannot express. *Cost:* the street's own safe mistake waits for a cross-step
    form (`try: "unsafe"`, a later small rule).
26. **The Poisons Cupboard has no danger moments** (nothing moves fast there). *Cost:* its time never slows.
27. **The new places' targets avoid overlaps** (the smoke found one: in VR a hand on Bobo's buckle also touched the
    jacket's bigger target; once the jacket is on, its target goes). *Cost:* none.

## The facts and their sources

Every step's words and source are in `docs/devlog/parts/life-l3a-review.md` (written from the data), for the owner's
experts: a lifesaving and water safety instructor, a poison centre's specialist with a child accident prevention officer
(and a gas engineer or the fire service for CO), a civil protection officer with a meteorologist and a mountain rescue
volunteer. The authorities:
- **Water:** the WHO's drowning fact sheet (https://www.who.int/news-room/fact-sheets/detail/drowning); the Royal Life
  Saving Society UK (water safety, ice safety, pool safety: https://www.rlss.org.uk/water-safety ,
  https://www.rlss.org.uk/ice-safety , https://www.rlss.org.uk/pool-safety); the RNLI (rip currents, beach flags, Float to
  Live: https://rnli.org/safety/know-the-risks/rip-currents , https://rnli.org/safety/beach-safety ,
  https://rnli.org/safety/float); the US National Weather Service's rip current safety (https://www.weather.gov/safety/ripcurrent);
  the US Coast Guard's life jacket fit (https://www.uscgboating.org/); Pia (1974) and the US Coast Guard's On Scene (2006)
  for the instinctive drowning response (https://www.uscg.mil/); the Minnesota Department of Natural Resources' ice
  self-rescue (https://www.dnr.state.mn.us/safety/ice/index.html).
- **Poisons:** the WHO's poisoning prevention and management fact sheet
  (https://www.who.int/news-room/fact-sheets/detail/poisoning-prevention-and-management) and World report on child injury
  prevention (https://www.who.int/publications/i/item/9789241563574); UNECE's GHS pictograms
  (https://unece.org/transport/dangerous-goods/ghs-pictograms); the Child Accident Prevention Trust (button batteries,
  poisoning: https://capt.org.uk/button-batteries/ , https://capt.org.uk/poisoning/); the US CDC (Up and Away:
  https://www.upandaway.org/ ; cleaning safely: https://www.cdc.gov/hygiene/about/cleaning-and-disinfecting-at-home.html ;
  carbon monoxide: https://www.cdc.gov/carbon-monoxide/prevention/index.html); the NHS (poisoning, carbon monoxide:
  https://www.nhs.uk/conditions/poisoning/ , https://www.nhs.uk/conditions/carbon-monoxide-poisoning/); the US Consumer
  Product Safety Commission's CO centre (https://www.cpsc.gov/Safety-Education/Safety-Education-Centers/Carbon-Monoxide-Information-Center).
- **Earth and weather:** the Earthquake Country Alliance's ShakeOut, Drop, Cover, Hold On
  (https://www.shakeout.org/dropcoverholdon/); the Emergency Management Service of Georgia (https://ema.gov.ge/) and its
  112; FEMA's Ready.gov (earthquakes, build a kit: https://www.ready.gov/earthquakes , https://www.ready.gov/kit); the US
  National Weather Service (lightning, floods: https://www.weather.gov/safety/lightning ,
  https://www.weather.gov/safety/flood-turn-around-dont-drown); the UK Environment Agency (https://www.gov.uk/help-during-flood);
  the WHO's heat and health (https://www.who.int/news-room/fact-sheets/detail/climate-change-heat-and-health); Mountain
  Rescue England and Wales (https://www.mountain.rescue.org.uk/); Hug-a-Tree and Survive (a US programme, 1981; via
  https://www.nasar.org/).
- **Not re-fetched in this session** (the brief: no downloads): the URLs and wordings come from the authorities' published
  guidance as known; the experts' review checks every one. Most need a look: the RLSS UK and RNLI page paths, the US
  Coast Guard's and USCG Boating's pages (Pia's paper and the On Scene article have no stable link), the CDC's 2024
  reorganised paths, CAPT's paths, **Georgia's Emergency Management Service's address and its own earthquake advice**
  (ema.gov.ge as known), and Hug-a-Tree's (its founders' site is gone; NASAR is a stand-in).

## Tests and measurements

- **Unit:** `test_life_safe_mistake.gd` (11: a target, a picture and standing up tried; the harmless taps; `within` in the
  room's time; the problems; never a hint on a normal try, one on Expert; the time scale), `test_life_intensity.gd` (5:
  gentle by default, more real only on Big, the backup, the merge, the measurement), `test_life_l3a_data.gd` (9: the three
  are known and emergencies, Little guides first, the brief's safe mistakes on Middle and Big each with its picture, the
  authorities' right ways, "never" said plainly, danger moments, the region's number and Georgia, devices and the Tool
  Book, the intensity in the words). L1's `test_life_experience.gd` now knows the ten Experiences (every one valid in every
  region and seed, an automatic player finishes every track, the words kind, calm and British).
- **Integration:** `test_life_room_host_l3a.gd` (11: the freeze flat (the room still, the picture, the card, the veil,
  nothing moves on, GOT IT, the right way glows and is said, no hint), the rip's arrows still while frozen and again
  after, STAND UP flat, the head coming up in VR with the dim (over 0.1, under 0.6, clear after), a hint on Expert,
  closing while frozen leaves VR clear, the time scale by try and intensity with SLOW PRACTICE, the drop's `within` at
  half speed, `glow: false` with SHOW ME, an action's and a basket's words, a VR hand on the buckle),
  `test_life_screen_l3a.gd` (7: the debrief, none for the kitchen, the calm page, the host's intensity and runs, SAFETY,
  Staying safe's units within the frame, L3a's authorities), `test_life_rooms_l3a.gd` (6: every mistake's picture comes and
  goes, the freeze and slow time reach the room's motion, "more real" modest, the swimmers vary, the mesh budget),
  `test_life_icons_l3a.gd` (2); and L1's and L2's own room, host, screen, town tests on the new data: every target and view
  in its room, everything to tap on the 16:9 screen from its view, everything to touch within a child's reach in VR, only
  warmed shaders, no shadows, every page within the frame, the town's spots apart.
- **Meshes per room** (Little / Middle / Big): water 147 / 180 / 37, poisons 112 / 136 / 135, earth 88 / 97 / 109 (L1's
  and L2's rooms are about 150-200).
- **The smoke** (`tools/life_smoke.gd`, 5× time): L3a's 39 runs (every track flat, Expert and VR, and the mistake modes
  flat and VR on Middle and Big): its first run found a real problem (the buckle, ruling 27), fixed test-first; then 39 of
  39 passed (1.6-5.9 s each). **The whole smoke, every Experience (L1, L2 and L3a; Real Builder has its own), 93 runs: 93
  passed** (L1's two emergency Experiences now meet the debrief).
- **The Life Town smoke** (`tools/life_town_smoke.gd`, a new Green Meadows world): Life Town stood after 5 s at
  (-13, 27, -31); walking up to each of the ten places opened its Experience (the pool Water Safety, the cupboard house The
  Poisons Cupboard, the hut Earth and Weather); TRY IT opened the room over the loaded world; 133 frames in the room,
  average 45.2 ms, worst 138.5 ms (headless on this shared desktop, other agents' suites running; L2 measured 32.6 / 72.4
  ms at a lighter load); STOP FOR NOW gave everything back: 0 failed.
- **The full suite before the merge** (2026-10-17, one run in a PC-wide slot): 1,207 scripts, 11,091 tests: **11,088
  passed, 0 failed**, 3 risky or pending (the two old "did not assert" and the device move's pending by design), 4,238 s.
- **Merged `lead-merge` (Success S2, `5bf98802`)** at the lead's word: six files joined (the Experience ids: L3a's three
  and S2's four, 14 in all; LifeData's emptiness and dict; LifeIcons asks SuccessIcons, LifeIconsMore and
  LifeIconsDanger; the area page's two rows with S2's places under them; the exact-ids test; the spec: §27.4 is S2's,
  §27.5 L3a's). After it: Life's, Success's and the tools' 50 test scripts, 580 tests, all passed; the smoke of L3a's,
  S2's and Fire Escape's runs: 84 of 84 passed; the full suite: 1,216 scripts, 11,184 tests, 11,181 passed, 0 failed.
- **Merged `lead-merge` again** (the School's grade 7 D&T, Health and Projects, then `b585e78b`: the lead's fix to
  `test_school_content_g7_life.gd`, which now reads the Experiences through `LifeExperience.data`): no conflicts; that
  test, Life's data and catalogue tests: 43 passed.
- **The final full suite** (2026-10-17, on everything merged, one run in a PC-wide slot): 1,219 scripts, 11,213 tests:
  **11,210 passed, 0 failed**, 3 risky or pending (the same three: `test_the_column_cache_changes_nothing` and
  `test_chunks_meet_without_seams` "did not assert", and the device move's pending by design), 4,028 s.

## What the lead must check (I could not: no editor, no emulator, no headset)

On the emulator (`Pixel_8_API_35`), flat:
- The freeze: the veil's softening (0.8 s), the card's words and picture at the real screen, GOT IT, the glow and ghost
  finger after; STAND UP beside ROLL on the ice; SLOW PRACTICE under the coach's bar.
- The pool's four swimmers readable at phone size (who is quiet, who waves); the rip's arrows and the gap in the waves;
  the GHS diamonds on the bottles (7.5 cm: small at phone size); the CO alarm's night; the earthquake's sway; the storm's
  rain; the flood's flow.
- The DEBRIEF page; the grown-ups' SAFETY tab; Staying safe's two rows of units.
- **FPS ≥ 30, no frame over 100 ms** in each new room (the beach and the pool are Middle's biggest, 180 meshes) and in one
  opened from Life Town; the three new Life Town models, their signs and rings.

On the Quest 3:
- The dim (35%) and the card on the panel; GOT IT by the laser and by A; the soft chime.
- In the water: the eye just above the sea (0.3 m) and at the ice hole (0.5 m): comfort; the ice edge at chest height for
  both hands; the four kicks; crouching on the ice and the head coming up as the mistake (30 cm); the roll.
- Under the strong table (its top at 1 m; the crouched head about 0.85 m), the table leg in reach, the shaking seen but the
  view still; the tree trunk for both hands; the branch's end (1.06 m from the eye, near the reach limit) and the pole's;
  the CO alarm's test button at 1.42 m; the high cupboard's lock (0.8 m away, above the eye).
- The laser to the swimming buoys (5 m), to the lifeguard (5.3 m) and to the beach's rip water (7.35 m, near the 8 m reach).

## Next

The lead's hooks: Real Builder's saw without goggles frozen in time (ruling 24); Safe Streets' crossing as a safe mistake
(ruling 25); Tool Book pictures for the seven new entries (ruling 23); the experts' review of `life-l3a-review.md`; the
census through a new room (`tools/shader_probe_steps.gd --shader-census`). Then L3b (Online City, Find Your Way, Home
Helper, and the catalogue's next rows: electricity, animals, medical emergencies, people and places) on this framework,
and a second row for Life Town.
