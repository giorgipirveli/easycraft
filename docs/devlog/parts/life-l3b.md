# Life L3b: Electricity Safety, Safe with Animals, Medical Emergencies, fire and heat, Life Town's second row (owner #112, #115, #117, #118)

The owner (2026-10-16 19:51, #118): "consider somethimes in real life teaching some staff is dangerous, we can use this
online environment to teach them safely, so think what such things we can implement into game". The brief:
`docs/superpowers/plans/2026-10-16-life-l3b-brief.md`; the design: `docs/design/life-skills.md` §14 (the catalogue's rows
3, 6, 7, 8 and 10) with §3, §6, §10, §11, §13; the spec: §27.6 ("As built (L3b)"). Built by the Life L3b agent in the
worktree branch `worktree-agent-afbf4eda543e91f78`, on `lead-merge` at `92e766a7` (L3a merged), with `lead-merge` merged
again at `3a9c7347` (the School's grade 8 humanities: no conflicts). On Life's own framework: L3a's safe mistakes, time
scale, intensity and debrief used as they are, two small rules added. No editor, no emulator, no adb, no download, no
agents. Logs: the session scratchpad's `life3b_*`. The experts' review sheet, written from the data:
`docs/devlog/parts/life-l3b-review.md` (`tools/life_review_sheet.py`; every source a checkbox).

## The framework's two small rules (test-first)

**(a) The wrong moment.** A safe mistake's `try` may be `"unsafe"` (`LifeCheck.UNSAFE`): the step's own target pressed
while the sample says it is not safe is the mistake (time freezes as for any safe mistake); pressed while safe, the step
goes on as ever. Only where a moment can be wrong: a cross step (the room's `safe_now`: a car coming, the red man) or a
tool step with `safety` (the gear not on yet: ToolRoomHost says so). It closed L3a's two hooks:
- **Safe Streets' crossing** (Middle; L3a ruling 25): the van's edge, the green man (normal and Expert) and the night
  crossing are safe mistakes. Pressing (flat) or pulling the trigger (VR) while a car comes freezes the street (the cars
  stand still), its still picture is a figure at the road's edge and a soft amber strip on the near lane ("A CAR NEEDS THIS
  MUCH ROAD TO STOP", "THE DRIVER CAN'T SEE YOU BEHIND THE VAN", "THE CARS STILL HAVE GREEN"), the coach's card says why;
  GOT IT, then the child waits for the gap. No car has to stop: the child never left the kerb. Little keeps L2's kind miss
  (the car stops gently).
- **Real Builder's saw before the goggles** (L3a ruling 24): its data has `try: "unsafe"` and an `icon`;
  `ToolRoomHost._safe_mistake` marks the frame's sample unsafe with the target pressed the first time, so Life's run counts
  the mistake and the host freezes time (`RealBuilderSite.on_mistake`: chips of sawdust frozen over the work, "SAWDUST
  FLIES UP: GOGGLES FIRST"). Once explained, a later try is the old shaped way (the why, the goggles glow): a saw held on
  the work tries it every frame, and a child who forgot twice needn't freeze twice.

**(b) Be a tree.** `"tree"` is one of `LifeCheck.ACTIONS`: flat the HUD's BE A TREE button (its own picture); in VR
`LifeRoomHost._tree_pose`: the view looking down at the feet (past `TREE_LOOK_DOWN`), both hands at least
`TREE_HANDS_LOW` under the head and within `TREE_HANDS_IN` of it across (the arms folded in), held still. Running from the
dog is a place in the room (the path home, `run_away`), so L3a's `try` tries it (flat a tap, VR the laser or a hand).

Also: the region's `{wild_where}` (`LifeRegion.wild_words`: Georgia's bears, wolves, wild boar and shepherd dogs; each
region its own sentence); ToolIcons draws any LifeIcons name (L3a's seven Tool Book entries now have their own pictures:
the life jacket, the float, the reaching pole, the whistle, the emergency bag, the child lock, the CO alarm).

## What a child does in each Experience

Every Experience: flat (a finger, the mouse) and in VR (hands, the laser, the head; the views blink between spots), on all
three tracks, each with its Expert try, the before-and-after picture check, the name-it card in the authorities' words
with its source, Try it for real, the Passport's stamps, gold once, and the calm debrief (all three are `emergency`).
Every hands-on step names its motion, tool and device (owner #117).

### Electricity Safety (Staying safe; the practice house, the practice park, the park's path after a storm)

- **Little, Spot the electricity dangers (7 steps; the hazard hunt only, as the brief says):** "Electricity makes lights and
  toasters work. It can hurt, so it stays inside wires and machines." → find 5 of 7 dangers (a hair dryer by the bath, a
  drink by a socket, a cable with its wires showing, an adaptor in an adaptor, a fork in the toaster, a toy key by a socket,
  a kite in the power lines outside the window; each says why) → never touch: tell Gus → wet hands: dry them first → only
  plugs in sockets → a kite in the lines: leave it, tell a grown-up. Expert: all 7, nothing glows.
- **Middle, Water, plugs, cables and power lines (12 steps):** wet hands after a bath (the towel first; **safe mistake:
  the hair dryer with wet hands**: drops and a small yellow zigzag frozen on the dryer, "WATER LETS ELECTRICITY THROUGH")
  → the dryer far from the bath (the bath's edge is a kind miss) → unplug by the plug (the cable is a kind miss) → the
  lamp's frayed cable: tell Gus (touching it is a kind miss) → an adaptor in an adaptor and a heater: no → the practice
  park: fly the kite in the open field (under the lines is a kind miss) → the kite caught: let go, tell a grown-up → no
  climbing the tree under the lines → the ball in the substation: tell Gus (the gate is a kind miss). Expert: the dryer's
  place, the kite's field and the substation without glows.
- **Big, The fuse box, someone stuck and a fallen line (16 steps):** the fuse box's cover (the device model's order) →
  press the RCD's test button (it switches itself off) → switch it back on ("often every three months") → a cracked plug:
  stop using it → practice time: Gus mending a lamp still plugged in is stuck to the electricity (a soft yellow glow, a
  worried face) → **safe mistake: grabbing him** (a helper frozen holding his arm, both softly glowing, "NOW TWO ARE
  STUCK"; the why: "The electricity would go through you too, and then two people would be stuck."; right: "Never touch
  them. Switch the power off at the fuse box if you can reach it safely; if not, shout for a grown-up and call 112.") →
  the main switch (a danger moment) → call 112 on the play phone → stay with him, cool water on a burn → after a storm a
  line on the path → **safe mistake: going closer to look** (soft yellow rings on the ground round it, "THE GROUND NEAR IT
  CAN BE LIVE") → the safe place at least 10 metres away (a danger moment) → call out to Mo to stop → tell a grown-up who
  calls 112 and the power company → "Not for a child to do: touching or moving a power line, even with a stick." Expert:
  the main switch and the safe place without glows. VR: the switches by laser (the hall is 3 m off), the RCD by hand.

### Safe with Animals (Our world; the practice park, the dog park, the farm, the picnic, the practice hills)

- **Little, Hello dog, bees and farm animals (11 steps):** ask the owner first (a hug is the kind miss's why) → let
  Biscuit sniff the back of your hand, low and still (VR: the hand held there 2 s) → stroke his side (the head is a kind
  miss) → let sleeping dogs sleep → "If a dog ever runs at you: be a tree. Stand still, fold your arms in, and look at your
  feet. Never run." (the rule first) → a loose dog comes running (a danger moment: slow on the first tries; it stops short,
  sniffs, gets bored, trots back) → **be a tree** (3 s) → a bee at the picnic: walk away slowly → a sting: tell a grown-up →
  the farm: past the horse at its side (behind it is a kind miss). Expert: the hello and the horse without glows.
- **Middle, Dog signs, be a tree, farm and wild (14 steps):** three dogs, one saying "leave me alone" (the relaxed one and
  the play bow are kind misses with why; their places vary with the seed) → find its four signs (a stiff body, a hard
  stare, lips pulled back as a thin white line, the tail high) → a dog you don't know: **safe mistake: hugging him** (a
  figure frozen hugging Biscuit round the neck while he turns his head away, ears flat, "A HUG CAN FEEL LIKE A TRAP"; the
  why: "Most dogs don't like hugs: arms round the neck feel like being trapped, and a worried dog may snap.") → ask the
  owner, sniff, stroke → a loose dog runs at you: **safe mistake: running** (the path home: a figure frozen running, the
  dog frozen bounding after it, "RUNNING MAKES IT CHASE") → be a tree → the horse → cows with calves: calmly round the edge
  → a wasp: no swatting → a sting and swelling lips: call 112 → a snake on the hill path: step back and go round (touching
  it is a kind miss). Expert: the dogs elsewhere, nothing glows on the reading.
- **Big, The hills, guard dogs and stings (15 steps):** "The practice hills: a walk with your group. In Georgia's mountains
  live brown bears, wolves and wild boar, and big shepherd dogs guard the flocks of sheep." → stay with the group on the
  path → clap three times (noise: the strike motion) → a bear far across the valley: back slowly, together (running or
  going closer for a photo are kind misses with why) → a fox at the picnic: never feed it → a flock and its guard dogs:
  go far round (close is a kind miss) → one runs at you: **safe mistake: running** (the same frozen picture) → be a tree →
  back away slowly → a snake: step back → Mo stung, her face swelling: call 112 on the play phone, say "anaphylaxis" → her
  own pen: a grown-up or Mo herself uses it. Expert: the guard dog from the other side, the way past without a glow.

### Medical Emergencies (Staying safe; the practice room, the playground, the picnic)

- **Little, Tell a grown-up, call for help (12 steps; Expert 13):** Lulu bumps her head: tell Gus → Bobo's nosebleed: sit
  and lean forward, tell a grown-up → Pip-pop hot and dizzy: into the shade, sips of water → Mo's lips swell: tell a
  grown-up at once → no grown-up near: the play phone, 112, what happened (Expert: and where) → stay with your friend.
- **Middle, Nosebleeds, bumps, asthma and heat (17 steps):** "This is practice. A real first aid course teaches more." →
  Bobo's nosebleed (a small soft red dot): **safe mistake: tipping his head back** (a ghost of Bobo frozen with his head
  back and a soft arrow down his throat, "IT RUNS DOWN THE THROAT"; the why: "...it run down the throat, which can make you
  cough and feel sick.") → lean forward → pinch the soft part (VR: the hand at his nose 2 s) → 10 minutes (a time-lapse) →
  longer than 10 to 15 minutes: a grown-up gets help → Lulu's bump: tell a grown-up → Kiki's asthma: help her sit up → the
  trainer inhaler ("no medicine in it"): shake, into the spacer, press once, five slow breaths (the breathe kind) → a hot
  day: shade, water → muddled and no better: call 112 (heatstroke). Expert: no glows on the nosebleed and the press.
- **Big, Allergy pens and seizures (19 steps):** Mo ate nuts: find the three signs (swelling lips, a raised rash, noisy
  breathing) → a grown-up and 112 ("anaphylaxis") → "A real pen is only ever the person's own, prescribed for them: a
  grown-up, or Mo herself, uses it. Now practise with a trainer: no needle, no medicine." → blue to the sky (the cap) →
  orange to the thigh of the practice pad, until it clicks, held (VR: the hand at the pad 3 s) → lie her down, legs
  raised (sitting up if breathing is hard) → practice time: Bobo pretends to have a seizure (eyes shut, a small slow
  jerking) → start the stopwatch → move the hard things away (the chair, the toy box, the lamp) → **safe mistake: the spoon
  to his mouth** (a spoon frozen near his mouth with a soft grey "no", "NOTHING IN THE MOUTH"; the why: "it can hurt their
  teeth or block the air, and nobody can swallow their tongue.") → the cushion under his head → never hold him down → it
  stops: the recovery position (arm, hand, knee, roll) → call 112 over 5 minutes, a first seizure, or hurt. Expert: no
  glows on the signs and the cushion.

### Fire and heat, what L1 left (in The Kitchen and Fire Escape, through their data; no new room)

- **The Kitchen, Little (22 steps; Expert 23):** after the hands: the red tap is the hot one: cold first, a grown-up
  checks; at the end, a baby cousin, Nia, is coming: tidy the small things off the floor into the box up high (a marble, a
  coin, a toy wheel, beads; Expert: and a button battery) → grapes for Nia: cut into quarters (choking, the catalogue's
  row 6: an older sibling's tidy-up).
- **The Kitchen, Middle (21 steps; Expert 22):** after the hob's hot light: "Practice time: on another day, the oil in a pan
  catches fire. In real life you get out and tell a grown-up: they do this. Here you practise, so you know why." → heat off
  (a danger moment: the flame flickers slowly on a first try) → **safe mistake: water on the pan** (the jug labelled
  WATER: frozen before the flare, the splash hanging over the pan, "WATER MAKES BURNING OIL JUMP UP"; the why: "Water makes
  burning oil jump up in a big flare of flame. That's why we put a lid on it.") → the lid on (the flame goes out) → leave
  it covered until it's cold (lifting it or carrying the pan are kind misses with why) → a fire that grows: get out, stay
  out, call 112.
- **The Kitchen, Big (24 steps; Expert 25):** after the oven: a splash of hot water on Bobo's paw (a soft "ouch" spot):
  his paw under cool running water (VR: the hand at the tap 2 s), 20 minutes (a time-lapse), then cling film loosely and a
  grown-up (butter or ice is a kind miss with why).
- **Fire Escape, Little (11 steps; Expert 12):** after the hunt: "Matches, lighters and candles are a grown-up's job.
  Never touch them: tell a grown-up." (touch Gus, who now stands in the doll's house).
- **Fire Escape, Middle (24 steps; Expert 25):** after stop, drop and roll: a campfire in the practice garden with a
  grown-up: in the ring of stones (under the tree or by the tent are kind misses) → a bucket of water ready → small, a few
  sticks at a time → drown it (the pour kind: the bucket over the ashes) → stir (the little spade) → feel for heat with
  the back of your hand near the ashes, not on them: "too hot to touch is too hot to leave".

## Life Town's second row

The plaza grows a second row nearest the spawn (`PLAZA_MAX` (12, 14), `SECOND_ROW_Z` 9), its fronts and doors facing the
spawn, the doors 3.7 m apart (walking up to one never opens another): the **power hut** (grey, its fuse box and a small
yellow sign by the door, a little pole and line; Electricity Safety), the **animal corner** (a red kennel and a friendly
dog with a low, relaxed tail; Safe with Animals), the **first aid hut** (white, a green cross; Medical Emergencies), and
Success S2's four (owner #115): the **goal board** on its posts (the week's calendar ticked, the goal's picture, the saving
jar on a stand; The Goal Board), the **striped talk tent** with two stools (Talk & Deal), the **village board** with
picture cards of its people and a bench (The Connections Book), the **story stage** with its curtains and a star (Success
Stories). Every Experience now has its place. Walking up to a Success place opens its unit on the child's track (TRY IT),
like every other place. Measured (`test_real_meadows_get_their_town`): 7 of 8 real meadows still get their town (as
before), the slowest search 127 ms (L3a: 109 ms).

## How it is built

- **Rules (`core/life/`):** `LifeCheck` (`UNSAFE` and its rule, `"tree"` in `ACTIONS`, `targets_of` leaves the unsafe moment
  out), `LifeRegion` (`WILD_WORDS`, `wild_words`), `LifeExperience` (the three ids, `{wild_where}`), `LifeTown` (seven
  spots, the bigger plaza).
- **Rooms (`entities/life/`):** `ElectricRoom` ("electric"), `AnimalsRoom` ("animals"), `LifeDog`, `MedicalRoom` ("medical")
  (`LifeRooms.make`); `KitchenRoom` (the pan fire, the lid and the water jug, the play mat's small things, Nia, Bobo at the
  sink, `on_mistake` "flare"), `PracticeHouse` (Gus for Little, the campfire), `StreetRoom` (`on_mistake`: the three
  crossings' pictures), `LifeRoomHost` (`_tree_pose`), `LifeTownBuildings` (`_second_row`).
- **The hooks outside Life:** `entities/tools/tool_room_host.gd` (`_safe_mistake`: the first unsafe try freezes),
  `entities/tools/real_builder/real_builder_site.gd` (`on_mistake` "sawdust"), `data/tools/real_builder.json` (the saw's
  `try` and `icon`), `ui/tools/tool_icons.gd` (LifeIcons' names), `data/tools/tools.json` (eight new entries; L3a's seven
  entries' `icon`), `tools/real_builder_review_sheet.py` (one line: tried for real). Success's own code untouched.
- **Screens (`ui/life/`):** `LifeIconsHazards` (43 pictures; `LifeIcons` asks it after `LifeIconsDanger`), `LifeRoomHud`
  (BE A TREE), `LifeGrownUpsPage` (L3b's authorities).
- **Data:** `data/life/experiences/electricity.json`, `animals.json`, `medical.json`; `kitchen.json`, `fire_escape.json`,
  `safe_streets.json` (their new steps marked `"owner": "#118"` where they start); nine units in `data/life/units/`
  (electric_hunt, plugs_and_lines, fuse_box_and_lines, hello_dog, dog_signs, hills_and_guard_dogs, tell_and_call,
  nosebleeds_asthma, allergy_and_seizures: the School's bar, 11 exercises on three levels each) and in `life.json`
  (Staying safe: 9 / 10 / 9 units; Our world: 2 / 3 / 3).
- **Tools:** `tools/life_smoke_steps.gd` (the unsafe moment: waits for a car or the red man; be a tree in VR),
  `tools/life_review_sheet.py` (the fourth sheet, every source a checkbox).

## Rulings (decided, with what each costs if wrong)

1. **Fire and heat extend The Kitchen and Fire Escape** (the brief: "through their data where you can; a new room only
   where needed"): no new Experience; their rooms grew corners. *Cost:* longer tracks (Fire Escape Middle 24 steps, The
   Kitchen Big 24); a child with the old stamps keeps them and meets the new steps on the next try.
2. **The pan fire is on The Kitchen's Middle track, the scald on Big, the hot tap and the choking tidy-up on Little; the
   campfire on Fire Escape's Middle track, the matches on Little.** *Cost:* Big practises no pan fire, Little no campfire
   (a grown-up's job), Big Fire Escape keeps the extinguisher only.
3. **The pan fire is framed as a grown-up's job in real life** ("you get out and tell a grown-up: they do this. Here you
   practise, so you know why"): the child does heat off and lid on in practice. *Cost:* a reviewer may want the child's
   own action limited to "get out, tell" (the data's words change; the steps stay).
4. **Safe with Animals lives in Our world** (the design's area 10: "care for animals"), not Staying safe (which has 9-10
   units per track now). *Cost:* a grown-up looking for dog safety under Staying safe finds it under Our world.
5. **All three are emergency Experiences** (the calm debrief), Animals too (a frightened child may need it). *Cost:* one
   more page after Animals.
6. **Be a tree is a body action; running from the dog is a place (the path home).** VR can't see running without the
   child moving. *Cost:* running is a press, not a run; be a tree in VR wants the head down and the arms in (the button
   after two showings for a child who sits).
7. **Never a bite, a snarl or its sound:** the warning dog's lips back are a thin white line; the hug's picture is the dog
   turning away with its ears flat; the running dog stops short, sniffs and trots back. *Cost:* the warning signs are
   simplified; a dog expert may want a growl (left out: calm, never scary).
8. **The unsafe moment is one more `try` form, only on cross steps and safety-gear steps.** *Cost:* LifeCheck knows a
   sample's `safe`; other wrong moments (a hot pan touched too early) would need their room to say `safe`.
9. **All four of Safe Streets' Middle crossings are safe mistakes** (the van's edge, the green man normal and Expert, the
   night). *Cost:* a child who steps out often meets the freeze often (each time is counted, never a hint).
10. **Real Builder's saw freezes on its first try only**, then the shaped way. *Cost:* a second try shows the why and the
    glow, not the card.
11. **Hooks in the tools' files** (`ToolRoomHost._safe_mistake`, `RealBuilderSite.on_mistake`, `ToolIcons`, the review
    sheet's line), each marked Life L3b, as the brief asked. *Cost:* the tools' owner merges small edits.
12. **ToolIcons draws LifeIcons' names** (one picture per thing, not two). *Cost:* the Tool Book mixes the tools' and
    Life's drawing (both flat and plain).
13. **A fallen line: at least 10 metres** (UK Power Networks and BC Hydro; the Energy Networks Association says 5): the
    more careful figure. *Cost:* stricter than the ENA (harmless).
14. **The auto-injector is practised on a trainer and a practice pad, never on a buddy**; "a real pen is only ever the
    person's own" is said plainly; Mo's pen is used by a grown-up or Mo herself; no hold time in seconds (brands differ: "a
    real pen's instructions say how long to hold it"). *Cost:* no hold time learned.
15. **No medicine doses anywhere** (the brief): the inhaler's "her asthma plan says what's next", "one press" of a trainer.
    *Cost:* the number of puffs in an attack is a grown-up's (the plan's).
16. **The seizure is on the Big track** (Middle has asthma), a buddy clearly pretending (eyes shut, a small slow jerking,
    then sleepy). *Cost:* less real; the epilepsy nurse reviews the words.
17. **No "blood"** (Life's words test): a nosebleed is "a nosebleed" and "it runs down the throat"; a small soft red dot.
    *Cost:* a reviewer may want the plain word.
18. **Electricity's Big child practises the main switch** ("Grown-ups do just this, when they can reach it safely").
    *Cost:* a 12-year-old practises a grown-up's action; the right way's words say "shout for a grown-up" first if not.
19. **The heat is in Medical Emergencies too** (L3a's Earth and Weather has a heatwave): here as first aid (heatstroke:
    call). *Cost:* some overlap.
20. **The calendar and the jar are in the Tool Book** (owner #115's), but Success's steps don't name them yet
    (`data/success` is read-only for Life): their stamps start when the Success owner adds `device: "calendar"` / `"jar"`.
    *Cost:* no stamps for them yet.
21. **Life Town's second row is in front, nearest the spawn**, not behind. *Cost:* from the spawn the new row stands
    before the old; the search loses its 30 m radius (still 7 of 8 meadows).
22. **Each region's wild animals in one sentence** (`{wild_where}`). *Cost:* generalisations; the experts check them.
23. **The fuse box's cover target goes once touched** (the smoke found a VR hand at the RCD's button touching the bigger
    cover first, as L3a's buckle). *Cost:* none.
24. **The guard dogs are "big shepherd dogs"** (Georgia's Caucasian shepherd dogs, the livestock guardian advice: go
    round, don't stare, don't run). *Cost:* the advice is general; a mountain rescue volunteer checks it.

## The facts and their sources

Every step's words and source are in `docs/devlog/parts/life-l3b-review.md` (written from the data, each source a
checkbox for the expert's review before it ships, design §14), for the owner's experts: an electrical safety specialist
with the network's safety officer, a vet or a kennel club's dog safety educator with a farm safety officer and a mountain
rescue volunteer, and a first aid trainer with an allergy nurse, an asthma nurse and an epilepsy nurse. L1's and L2's
sheets carry the Kitchen's and Fire Escape's new steps and Safe Streets' safe mistakes. The authorities:
- **Electricity:** Electrical Safety First and its Switched On Kids (https://www.electricalsafetyfirst.org.uk/ ,
  https://www.switchedonkids.org.uk/ ; overloading sockets; RCDs), St John Ambulance (electric shock:
  https://www.sja.org.uk/get-advice/first-aid-advice/), the British Red Cross (https://www.redcross.org.uk/first-aid/learn-first-aid),
  the Energy Networks Association (https://www.energynetworks.org/), UK Power Networks (https://www.ukpowernetworks.co.uk/),
  BC Hydro (safe distance).
- **Animals:** the Dogs Trust's Be Dog Smart (https://www.dogstrust.org.uk/dog-advice/life-with-your-dog/family/be-dog-smart),
  Doggone Safe's Be a Tree and the Kennel Club
  (https://thekennelclub.org.uk/dog-training/getting-started-in-dog-training/dog-training-and-games/how-to-train-my-dog-and-child-to-behave-safely-around-each-other),
  the Blue Dog programme's guidance as text (https://www.thebluedog.org/), the RSPCA (https://www.rspca.org.uk/), the
  Countryside Code (https://www.gov.uk/government/publications/the-countryside-code), the NHS (stings, snake bites,
  anaphylaxis), the US National Park Service's bear safety (https://www.nps.gov/subjects/bears/safety.htm), Mountain
  Rescue, the WWF Caucasus programme (https://wwf.panda.org/) for Georgia's wildlife.
- **Medical:** the NHS (nosebleed, head injury, heat exhaustion and heatstroke, anaphylaxis:
  https://www.nhs.uk/conditions/nosebleed/ , https://www.nhs.uk/conditions/head-injury-and-concussion/ ,
  https://www.nhs.uk/conditions/heat-exhaustion-heatstroke/ , https://www.nhs.uk/conditions/anaphylaxis/), Asthma + Lung UK
  (https://www.asthmaandlung.org.uk/living-with/inhaler-videos/spacer-tidal , asthma attacks), Anaphylaxis UK
  (https://www.anaphylaxis.org.uk/) and the EpiPen maker's "blue to the sky, orange to the thigh", Epilepsy Action
  (https://www.epilepsy.org.uk/info/firstaid) and the Epilepsy Foundation
  (https://www.epilepsy.com/recognition/first-aid-resources), the Resuscitation Council UK, the British Red Cross.
- **Fire and heat** (in The Kitchen's and Fire Escape's own `sources`, with a new line on three name-it cards): NFPA's
  cooking fire safety (a lid, heat off, leave it covered; never water:
  https://www.nfpa.org/education-and-research/home-fire-safety/cooking), the London Fire Brigade (a fire that won't go out:
  get out, stay out, call: https://www.london-fire.gov.uk/safety/the-home/cooking/), the US Forest Service's Smokey Bear
  (drown, stir, feel: https://smokeybear.com/en/prevention-how-tos/campfire-safety), the NHS (burns and scalds: cool running
  water 20 minutes, cling film: https://www.nhs.uk/conditions/burns-and-scalds/), the Child Accident Prevention Trust
  (choking: small things away from babies, grapes cut into quarters; hot taps: https://capt.org.uk/), NFPA on children and
  matches.
- **Checked in this session** (web searches, nothing saved): the fallen-line distance (UK Power Networks and BC Hydro 10 m;
  the Energy Networks Association 5 m: the game says "at least 10 metres" and the source line says so), "be a tree"
  (Doggone Safe's programme; the Kennel Club's steps: still, arms folded, chin tucked, no running, screaming or staring,
  walk away slowly once it goes, tell an adult), Asthma + Lung UK's tidal breathing through a spacer (five breaths).
- **Not re-fetched** (the brief: no downloads): the other URLs and wordings come from the authorities' published guidance as
  known; most need a look: the ESF and ENA page paths, St John's and the Red Cross's electric shock pages, the Dogs Trust's
  Be Dog Smart path, Anaphylaxis UK's auto-injector page, Epilepsy Action's first aid path, WWF Caucasus's page on
  Georgia's bears and wolves, and every hold time and minute (the 10 to 15 minutes of a nosebleed, the 5 minutes of a
  seizure, the 20 minutes of a burn).

## Tests and measurements

- **Unit:** `test_life_l3b_rules.gd` (7: the unsafe press is the mistake, never a miss; waiting is progress; the wrong
  moment is never a room target; it needs a moment that can be wrong; Little keeps the kind miss; be a tree, flat and the
  automatic player; running from the dog is a place; the region's wild animals), `test_life_l3b_data.gd` (11: the three
  known and emergencies; the brief's safe mistakes on Middle and Big only, each with its picture; Real Builder's saw
  tryable; Little guides first; the authorities' right ways; "not for a child" and "the person's own" said plainly, no
  bite or dose words; danger moments; the region's number and Georgia; fire and heat's words; the devices and the Tool
  Book; every unit on the map), `test_life_town.gd` (every Experience has its place; the second row faces the spawn and
  nothing overlaps). L1's `test_life_experience.gd` knows the seventeen.
- **Integration:** `test_life_room_host_l3b.gd` (9: stepping out from behind the van freezes time, the cars stand still,
  no car stops, then the gap; Little's kind miss; the VR trigger before the green man freezes; running from the dog freezes,
  then BE A TREE; VR be a tree (the head down, the arms in, still; looking ahead is not); the RCD by hand in VR; grabbing
  Gus freezes, the main switch glows; the head back for a nosebleed; water on the pan fire frozen before the flare, the
  flame still), `test_life_rooms_l3b.gd` (6: every safe mistake's picture comes and goes, the hooks' too; the freeze stills
  the running dog, the flame and the seizure; a slow danger moment slows the dog; the warning dog's signs; the dogs vary
  with the seed; the mesh budget), `test_life_screen_l3b.gd` (4: Staying safe and Our world fit the frame on every track;
  L3b's authorities on the grown-ups' page; a Success place in Life Town opens its unit; the debrief), `test_life_icons_l3b.gd`
  (4: every new picture known, drawn once, drawing at three sizes; every L3b choice's picture; the Tool Book's own pictures),
  `test_real_builder_host.gd`'s saw (the freeze, GOT IT, then the shaped way). L1's, L2's and L3a's room, host, screen and
  town tests on the new data: every target and view in its room, everything to tap in the screen's free band from its
  view, everything to touch within a child's reach in VR, only warmed shaders, no shadows.
- **Meshes per room** (Little / Middle / Big): electricity 57 / 86 / 98, animals 135 / 194 / 138, medical 94 / 90 / 48, the
  kitchen 109 / 88 / 111, the practice house 97 / 80 / 69 (the budget: 320).
- **The smoke** (`tools/life_smoke.gd`, 5× time): L3b's three, every mode: 39 runs; the first found a real problem (a VR
  hand at the RCD touched the fuse box's cover: ruling 23), fixed, then 39 of 39 (1.6-10.1 s each). The extended
  Experiences (The Kitchen, Fire Escape, Safe Streets, with its new mistake modes): 31 of 31. L1's, L2's, L3a's and Success's own runs were not smoked again as a whole (172 runs, about 15 minutes: the PC's memory guard had just stopped a long run); their tests ran in the full suite.
- **The Life Town smoke** (`tools/life_town_smoke.gd`, a new Green Meadows world): Life Town stood after 6.5 s at
  (-4, 29, -34); walking up to each of the seventeen places opened its Experience (the second row's seven too); TRY IT
  opened the room; 157 frames in the room, average 38.3 ms, worst 132.5 ms (headless on this shared desktop); STOP FOR NOW
  gave everything back: 0 failed.
- **Life's, the tools' and Success's 59 test scripts** (before the second row): 660 of 661 (the one: test_life_town's count
  before the second row, then fixed).
- **Merged `lead-merge` twice:** at `3a9c7347` (the School's grade 8 history, geography and citizenship) and at
  `d3ffa6ca` (grade 8 humanities merged at `8ce66716`, the docs after it): no conflicts.
- **The full suite** (2026-10-17, on everything merged, one run in a PC-wide slot): 1,228 scripts, 11,346 tests:
  **11,343 passed, 0 failed**, 3 risky or pending (the same three as before: `test_the_column_cache_changes_nothing` and
  `test_chunks_meet_without_seams` "did not assert", and the device move's pending by design), 4,548 s. (A first run was
  stopped by the PC's memory guard at script 757 while the session was idle, with 756 scripts passed and no failure; the
  run above is the full one.)

## What the lead must check (I could not: no editor, no emulator, no headset)

On the emulator (`Pixel_8_API_35`), flat:
- The three rooms at phone size: the hazard hunt's small things (the toy key, the drink, the fork; the kite on the window),
  the fuse box's switches (small: the RCD's T button is 3.5 cm), the dogs' signs (the lips' white line, the tail), the
  trainer pen and pad, the inhaler and spacer, Mo's soft allergy signs; the freezes' pictures and cards (the street's amber
  strip, the frozen dog, the two stuck, the rings round the line, the spoon, the head back, the splash over the pan).
- The Kitchen's play mat and its five small things (2-3 cm at the floor), the pan's flame and lid; Fire Escape's campfire.
- **FPS ≥ 30, no frame over 100 ms** in each new room (the animals' Middle is the biggest, 194 meshes) and in one opened
  from Life Town; the second row's seven models, their signs and rings; Staying safe's ten units in two rows.

On the Quest 3:
- Be a tree: the head looking down and the arms folded in (the thresholds: 20 degrees down, the hands 30 cm under the head
  and within 38 cm across), held still; the BE A TREE button for a child who sits.
- The dog's sniff (the hand held out low, 2 s), the stroke by laser; the running dog stopping 1.3 m short (comfort: never
  at the child); the guard dog (1.5× size) coming at the child in the hills.
- The fuse box by hand (the RCD at 1 m), the main switch by laser (3 m); the storm's safe place (6-7 m, the laser) and Mo.
- The nose's pinch by hand, the inhaler's shake and the spacer's breathing (the hands rising), the pen on the pad (3 s).
- The campfire's pour (the bucket tilted) and stir (the hand's own path), the ashes' feel (the back of the hand).
- The street's crossing by the trigger while a car comes: the freeze and the dim.

## Next

The experts' review of `life-l3b-review.md` (the checkboxes); Success's own steps naming the calendar and the jar (their
Tool Book stamps); the catalogue's remaining rows (falls and heights, power tools and the workshop, dangerous science,
dangerous jobs, people and places: lost in a crowd, Online City); Life Town's third row or a second plaza when the next
wave comes.
