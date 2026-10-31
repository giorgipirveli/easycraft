# Play W1: learning inside the world (owner #122, #132, #133)

The owner, watching their child play (2026-10-17 23:30-23:31, #132): "i dont understand where is educational content?
nowhere in the game … my child is playing more then 30 minutes and there is no educational content, have you hiddne it
somwhere? it should be in the game". Five minutes later (23:36, #133): "consider no one will start reading in the game,
we have to rethink all this, try to deliver education without just reading". The brief:
`docs/superpowers/plans/2026-10-17-play-w1-world-brief.md`; the design: `docs/design/learning-is-play.md` (the seven
rules); the spec: §22.0 ("As built (W1)"). Built by the Play W1 agent on the worktree branch
`worktree-agent-a44930430f542d3a8`, from `lead-merge` at `48dccc33`. No editor, no emulator, no adb, no download, no
agents. Logs: the session scratchpad's `playw1_*`.

## Report before building: the pattern picked, and the one rejected

**Picked: a DiscoveryDirector beside LifeTownDirector** (node "Discovery" of the sandbox, `entities/discovery/`), the
way Life Town, the Launch Site and the Theater already live in a world: one node per place-system, its pure rules in
`core/discovery/` (DiscoveryRules: where it plays, when Hoot comes, the word budget; later CrystalRules and the
Academy's layout), its screens in `ui/discovery/` (DiscoverPanel: the School over the world, as LifeTownPanel opens Life
and ShortsSchool opens a unit over the Theater; HootCard: Professor Hoot's invitation), Callables for everything it asks
the sandbox (the player's feet, whether a menu covers the screen, holding and keeping the avatar safe, a toast for the
headset) so its tests need no sandbox, and one marked hook block in `scenes/sandbox.gd` ("owner #132 (W1)"). Hoot's
memory (which worlds he has visited, the day he came last) is a small device-only file (`DiscoveryLog`,
`user://discovery.json`): no world key or day is personal, and nothing goes over the network.
- The **discovery crystal** (stage 2) will be a **local-only node** of the director (never a replicated entity: each
  child their own crystal and their own learning; a guest's crystal never reaches the host), its challenge spoken and
  answered by an action (#133).
- The **Discovery Academy** (stage 3) will be **a third layout for Life Town's search** (`LifeTown.pick` already takes a
  layout: the Market Square is the second), placed beside the town and saved with it, its buildings models like the
  town's.

**Rejected: putting learning into the existing systems one by one** (a DISCOVER button inside the HUD's own code, Hoot as
a quest giver in `QuestDirector`, crystals as `SecretDirector` treasures, the Academy as a Life Town row). Each of those
is somebody else's file and each would teach a different way; the quests and secrets are shared through the host (a
crystal must be each child's own), and Life Town is full (6 of 8 real meadows; another row costs meadows). A director of
its own keeps W1 in its own folders (the brief's allocation), testable alone, and one call away from Play G0's games.

**The one call the lead switches when G0 merges:** `DiscoverPanel.make_screen()` (marked "owner #132 (W1) → Play G0")
makes the School's own screen today (SchoolScreen, its existing public functions only: `show_map(subject)`,
`show_life()`); G0's DISCOVER map goes there.

**#133 (no reading):** nothing W1 adds asks a child to read. Hoot's line is spoken by itself (`ReadAloud.speak`, not
behind a button); on screen Hoot, one big picture button (a magnifying glass: DISCOVER) and at most a few words
(`DiscoveryRules.MAX_SCREEN_WORDS`); DISCOVER in MORE and in the pause menu is a picture, its word spoken when the
pointer (a mouse, the headset's laser) comes over it and when pressed. Every W1 screen has a test that it speaks its line
and stays within the word budget.

## The first five minutes of a new home world (all three stages)

**Flat (phone, tablet, PC).** 0:00 the child lands; from the spawn the Discovery Academy's tower stands over the trees
(34-42 m off in 7 of 8 meadows; Hoot on its top), and the compass in the corner points to it. 0:20 Professor Hoot glides
down out of the sky and lands a few metres away; his card pops in at the top (Hoot, one big DISCOVER picture, a cross)
and his voice says "Want to play a discovery game? Tap the magnifying glass!" (no reading needed). DISCOVER opens the
School over the world and BACK brings the child back; the cross or 30 s and he flies off to the Academy's top. Any time:
DISCOVER is MORE's first picture and sits beside RESUME in the pause menu. Walking to the Academy, each gate says its name;
each subject's door opens a whole round of that subject's unit that plays without reading (in grade 4 all eleven
do), Life opens Life, and a subject with nothing to play yet says a calm "coming soon". 2:30 of free play
(not in a fight, a race or a ride): a glowing "?" crystal rises a few metres off with a chime and "Hoo! Touch the crystal
to play!"; walking up or tapping it opens a short round (four challenges) of the child's own unit in Play G0's place (a
review due, else the next unit, when it plays without reading; else a unit of the grade that does), spoken, with
pictures and numbers; its end counts as the School's (SkillShown); it fades if ignored, and the next comes five minutes
of play later.

**VR (Quest 3).** The same Academy and crystal life size. Hoot lands beside the child and his line is spoken and floats on
the toast strip (no card in front of the eyes); DISCOVER is MORE's first picture on the raised arm's panel (pointing the
laser at it speaks "Discover!") and beside RESUME on the pause menu's eye panel; the School shows on the eye panel. The
crystal is touched with a hand (or the laser and trigger) and G0's place plays with the hands (G0's VR); a gate's "coming soon" card comes on the eye
panel while the child stands at it.

## Stage 1: DISCOVER inside the world, Professor Hoot's invitation

**What a child sees (flat).** A new home world (Green Meadows, Sandbox or Survivor): the child looks round and plays;
about 20 s after standing in the world with no menu over it, a small dark card pops in at the top middle (under the
toast's line, between the HUD's columns: never over the thumbs' buttons or the crosshair): Professor Hoot, a big teal
**DISCOVER** picture (a magnifying glass with a sparkle in its lens) and a round cross. Hoot says by himself "Hoo hoo!
I'm Professor Hoot. Want to play a discovery game? Tap the magnifying glass!" (spoken whatever "Read to me" says:
owner #133). Tapping DISCOVER opens the School over the world on the child's grade's map (today the School's own screen,
Play G0's DISCOVER map once merged) and Hoot says "Let's discover!"; the avatar stands still and is kept safe while it
shows; BACK (or Android Back, Esc, Circle / B) and the child is in the world where they stood. The cross puts Hoot away;
untouched, the card waits quietly 30 s and fades. Nothing is lost either way. DISCOVER is always there afterwards: the
**first picture in MORE** and a picture **beside RESUME** in the pause menu; pointing at it (a mouse, the headset's
laser, a controller's focus) speaks "Discover!".
- Pictures (a real window, 1280 × 720, blocky): `docs/devlog/parts/play-w1/s1-hoot-card.jpg`, `s1-more.jpg`,
  `s1-pause-menu.jpg`, `s1-school-over-the-world.jpg`.

**What a child sees (VR).** The HUD hides while playing (owner #127), so Hoot's card would be lost on the raised arm's
panel: in a headset his line goes on the **toast strip** over the gaze ("… Find the magnifying glass in MORE!") and is
spoken. DISCOVER is MORE's first picture on the raised arm's panel (pointing the laser at it speaks its word) and beside
RESUME in the pause menu (the eye panel); the School then shows on the **eye panel** (PadFocus watches the panel: "a
panel has the pad" → EYE).

**Tests and proof.** `tests/unit/test_discovery_rules.gd` (11: where, when Hoot comes, his memory, the word count),
`tests/integration/test_discovery_director.gd` (20: MORE's picture and its spoken word, the School over the world and
back, held and kept safe, Android Back, a subject's map; Hoot after 20 s and spoken, his card's few words, its DISCOVER,
its cross, the quiet fade, waiting under a menu and before the spawn, once a day to a world, a new world the same day,
not in the arena, the device's file, the headset's toast strip, DISCOVER found first counts as his visit),
`tests/integration/test_discovery_pause.gd` (6: none unless on, beside RESUME, resumes and asks, spoken when pointed or
focused, one word, still within 720 px). The smoke `tools/discovery_smoke.gd` on a real Green Meadows world (seed
12345): every check passed; Hoot came 19.8 s after the child stood in the world; 431 frames headless with his card
showing averaged 7.0 ms (worst 14.9 ms) on this desktop (a real window: 21.6 ms average, 26.5 ms worst with its pictures
being taken). The card is 2D only: a panel, a drawn owl, a drawn picture and a drawn cross (no 3D draw, no material).

**Rulings (each with its cost if wrong).**
1. **DISCOVER in every world but Monster Wave's arena** (space worlds too: the cosmos teaches). *Cost:* a child in the
   arena reaches the School from the menu; if the arena should have it, one line (`discover_here`).
2. **DISCOVER is MORE's first picture** (before EMOTE): learning was "nowhere" (#132). *Cost:* a child used to EMOTE
   first finds it one place on; one `move_child` to undo.
3. **The pause menu's DISCOVER shares RESUME's row** (150 px picture, RESUME 258 px): a row of its own would push the
   menu with MONSTERS and FRIENDS past 720 px. *Cost:* a smaller RESUME.
4. **Hoot comes on each world's first visit, and to a world seen before at most once a day** (the day he last came
   anywhere). *Cost:* a child making several new worlds a day sees him in each (one tap on the cross); a child who plays
   one world sees him once a day.
5. **He comes after 20 s standing in the world with nothing over it** (no menu, card, place's panel, tutorial card,
   Theater, MAP, KEYS): never over a menu, never at the very first second. *Cost:* a child who leaves within 20 s never
   meets him that time (DISCOVER is in MORE and the pause menu anyway).
6. **His line is spoken by itself, every time he comes** (ReadAloud.speak cuts in), not only with "Read to me" (#133).
   *Cost:* a child who dislikes the voice hears one short line a day; where the device has no voice (some desktops) the
   card still shows its picture.
7. **Opening DISCOVER before Hoot comes counts as his visit** for the day (no invitation to a child who found it).
   *Cost:* none known.
8. **Hoot's memory is a small file on this device** (`user://discovery.json`: world keys "slot:seed" and day numbers),
   not in the profile or its backup. *Cost:* a new device gets him once more per world.
9. **While the School shows over the world the avatar is held and protected** (Life Town's way: physics off, block taps
   off, `health.protect(3)` every second): the world goes on for friends (never a pause on a shared world). *Cost:* in
   Survivor a child could stand safe at night by opening DISCOVER; learning is the point, so it stays.
10. **The pause menu closes the School** (it would otherwise draw over the pause menu, as Life Town's panel would).
    *Cost:* a child pausing mid-School is back on the world after RESUME (DISCOVER opens it again).
11. **In a headset Hoot's line uses the toast strip**, not a card on the eye panel: an eye panel would cover the view
    until answered ("never blocking play"). *Cost:* no button on the strip: the child finds DISCOVER in MORE or the
    pause menu, as the line says.

**What the lead must check.** Emulator: a new Sandbox world: Hoot's card after about 20 s with his voice (the emulator
has a voice), its DISCOVER opens the School and BACK returns; MORE's first picture; the pause menu's DISCOVER; the frames
with the card up (≥ 30 FPS, nothing over 100 ms). Quest 3: Hoot's line on the toast strip and spoken; MORE's DISCOVER on
the raised arm's panel speaks when the laser is over it; the School on the eye panel and back to the world.

## Stage 2: the discovery crystals (owner #133: no reading; #134: real play only)

**What a child sees (flat).** About two and a half minutes into playing a home world (not in a fight, a wave, a race, a
round, riding, a car, flying, hiding, asleep or in Pip's tutorial; nothing over the world), a tall glowing crystal with a
big "?" over it rises out of the ground a few metres away, a little to one side of the view (so the avatar never hides
it), with a chime. The first one ever, Hoot's voice says "Hoo! Touch the crystal to play!"; later ones "A discovery
crystal! Touch it to play!". Walking up to it or tapping it starts its play: the voice says the challenge ("Make
213,402!", "Start at 8. Make minus 5!", "Smallest first!"), the number to make floats over the crystal (ORDER: "? < ? <
? < ?"), the number it holds just over it, and gems with numbers float in two rows beside it, on the side away from the
middle of the view (MAKE's place values read like a number: 100,000 10,000 1,000 on top, 100 10 1 below). A small card
at the top shows the goal again (MAKE's number, or ORDER's rising steps) with a speaker and a cross. Tapping a gem flies
it into the crystal and the number changes; a gem that would go past the number (or, with negatives, farther from it, or
in ORDER is not the smallest left) shakes and bounces off with a soft boing and a calm line ("Too far! Try another
one."); after two misses the helpful gem pulses (shown, not told). Solved: the crystal flashes and sparkles, "Yes!
213,402!", and the next of three challenges comes; after the third, confetti, "Well done, discoverer!", and it sinks
away. Each challenge solved with no miss pays the School's answer gold (5, inside the day's cap of 150). An untouched
crystal waits two minutes and fades; walking 14 m away, a fight starting, the cross, or opening DISCOVER end the play
quietly. Nothing is ever lost; the next crystal comes five minutes of play later.
- Pictures (a real window): `docs/devlog/parts/play-w1/s2-crystal-waiting.jpg`, `s2-crystal-play.jpg`.

**What a child sees (VR).** The same crystal and gems in the world, life size; the voice says each line; the goal and
the held number float over the crystal (the HUD's card is on the raised arm's panel only). The child walks up and
touches the crystal with a hand (or points the laser and pulls the trigger), and takes gems by touching them with either
hand or with the laser and trigger (the BlockInteractor's tap path: `player.aim_ray` is the hand's ray in a headset).

**What it plays (DiscoveryPlays; #134: only real play, never a written question).** Two mechanics where the number
sense is the move: **MAKE** (place value to 10,000 and to a million, coins to 99, tenths and hundredths, thousandths,
integers from zero, integers from a start) and **ORDER** (big numbers, unit fractions, decimals, negatives, rationals,
irrationals with √). The pick: a review due first, else the next unit of the grade (the School's order, written units,
no Explorer lessons); if that unit's own play is one of these (`UNIT_PLAYS`: 11 units of grades 3-8, each by its
standards: 3.NBT.1, money, 3.NF.3d, 4.NBT.1-2, 4.NBT.2, 4.NF.6-7, 5.NBT.3, 6.NS.5-7, 7.NS.1, 7.NS.2d, 8.NS.2) it plays
it; otherwise a real-play challenge from the child's grade (a review due among those units, else the first not mastered,
else one by the day) and the unit the child was on is recorded as **play debt** on the device
(`user://discovery.json`, "crystals": {"met", "played", "debt": {unit: n}, "last"}). The lead's switch as deep games and
G0's mechanics merge: `DiscoveryPlays.play_for(unit_id)`.

**The five tests, honestly.** Mute: nothing to read (numbers and signs only; every line spoken; tested). Cheat: MAKE
can't be won by mashing (a gem past the number bounces; only the exact number solves it); ORDER can be ground through by
trying every gem (a miss costs nothing but the first-try record and the gold), so its record (`first_try`) is the honest
signal, not finishing. Transfer and wow: not measured yet (the owner's child is the judge). Choice: a crystal is never
forced (it waits and fades).

**Tests and proof.** `tests/unit/test_discovery_crystal_rules.gd` (10: home worlds and the switch, the timing, the spot:
a few metres, in front, never in water, never in a wall, beside water, a step up but not a cliff, short lines),
`tests/unit/test_discovery_crystal_plays.gd` (17: every unit and set real, every grade has plays, numbers and signs
only, every MAKE target makeable by the hints in a handful of gems, ORDER values distinct, seeds repeat, the pick: a
review due, the next unit, a grade challenge plus debt, grade 0, every grade; the challenge rules: counting, bouncing
past, negatives farther, the hint after two misses, ORDER, three then finished), `tests/integration/test_discovery_crystal.gd`
(19: when and where, busy, a menu, the switch, not in the arena or space, fading and the next, walking up, a tap, a VR
hand, numbers only, taps never build, three solved pay answer gold and it goes, the day's cap, a bounce, the glow, a VR
hand takes a gem, walking away, the cross, a fight, play debt recorded), `tests/integration/test_discovery_grown_ups.gd`
(4: the grown-ups' switch on by default, off and saved at once, it survives a save, the page fits). The smoke on a real
Green Meadows world: the crystal rose 4.5 m from the child on dry ground, a tap through the real tap path started it,
three place-value challenges (Big numbers, the child's next unit) solved by taps on gems, answer gold paid, it went;
headless 6.9 ms a frame; in a real window on this desktop 21.7 ms average, 29.4 ms worst while the crystal played.
**Cost:** one crystal mesh and up to six gem meshes (one shared unshaded material, warmed), eight billboard labels
(warmed), no light, no shadow, no physics body; about 15 draws while it plays, 2 while it waits.

**Rulings (each with its cost if wrong).**
12. **The first crystal after 150 s of play, then 300 s after the last went; untouched it waits 120 s** (the brief's
    "about 5 minutes"; sooner for the first because the owner saw 30 minutes without learning). *Cost:* a crystal every
    five minutes may feel frequent to some children; the numbers are one place (`DiscoveryCrystalRules`).
13. **Play time counts only when the child is free** (busy states and menus pause the clock). *Cost:* a child who fights
    all evening sees few crystals (by design: never during a fight).
14. **MAKE and ORDER are the only crystal plays until deep games and G0 merge**, and most units (science, English…)
    get a grade's number challenge instead, recorded as play debt (#134). *Cost:* the crystal is maths-only for now; the
    debt list shows the lead where real play is most wanted.
15. **Crystals never write mastery** (no stars, no reviews moved): a crystal's three challenges are not a unit's round,
    and G0's bridge from play to MasteryRules is the place for it. They pay answer gold (within the cap) for a challenge
    solved with no miss. *Cost:* a review done through a crystal does not move the review date.
16. **The Daily Mission is not a crystal fallback** (its five questions are written). *Cost:* none for the child.
17. **A crystal's gems are taken by taps, the laser and hands, not by walking into them** (walking would take gems by
    accident and bounce them). The crystal itself starts by walking up, a tap or a hand.
18. **During a crystal's play every tap is the play's** (BlockInteractor.discovery_tap, before bags and blocks): no
    block is placed or broken behind a gem; a PC's left click counts too. *Cost:* a child who wants to build mid-play
    walks away or presses the cross first.
19. **The gems float beside the crystal on the side away from the middle of the view**, in two rows, so the camera behind
    the avatar sees them all. *Cost:* if the child turns round, the gems stay where they were shown (they face the
    child's first position).
20. **A grown-up's switch on the grown-ups' PLAY & PHOTOS page** (settings `discovery_crystals`, on by default; travels
    with the profile's settings in the backup). *Cost:* none known.
21. **The pause menu pauses the crystal** (its clocks wait while the tree is paused).

## Stage 3: the Discovery Academy, and Hoot comes in person

**What a child sees (flat).** From the spawn, a tall cream-and-teal tower (15 m, over the meadows' trees) with warm
windows, DISCOVER's magnifying glass glowing over its front door and Professor Hoot in his square cap on a pedestal on its
top, facing the spawn; round it a ring of twelve slim gates in the School's colours, each with its picture glowing on a
sign (a gear, a flask, an open book, a heart, angle brackets, columns, a map pin, a dumbbell, a note, two friends, a
palette, a hammer) and a soft ring on the ground where to walk up. At night the windows, the pictures and a band round
the top glow. The HUD's compass points to it ("25 m") until the child has been to a door; MY MAP marks it (a tower).
Walking up to a door says its name: **the Maths Workshop** starts a crystal's real play right there in the courtyard
("The Maths Workshop! Make 330,122!"); **Life** opens the School's Life tab over the world ("Life! Let's discover!");
every other door shows a calm card while the child stands there: Hoot, the door's picture on its colour, a speaker and a
cross, and the voice: "The History Museum! Hoot is still building it. Come back soon!" (never a list of lessons: #134).
Walking away puts it away. And when Hoot's invitation comes (stage 1), **Hoot himself** glides down out of the sky and
lands a few metres from the child, turned to them, bobbing; when his card goes he flies off to the Academy's top.
- Pictures (a real window): `docs/devlog/parts/play-w1/s3-academy.jpg` (21 m in front of it), `s3-academy-night.jpg`,
  `s3-door-coming-soon.jpg`, `s3-maths-door.jpg`, `s3-hoot-landed.jpg`.

**What a child sees (VR).** The tower, Hoot and the gates life size; the child walks (or teleports) up to a gate; its
name is spoken; the Maths Workshop's crystal plays as in stage 2 (hands, laser); Life opens on the eye panel; the
"coming soon" card has the pad (PadFocus), so it shows on the eye panel while the child stands at the door. Hoot lands
near the child too (his line on the toast strip) and flies off after 30 s.

**Placement, measured** (`test_real_meadows_keep_their_town_and_market_and_get_their_academy`, the eight seeds Life
Town is measured on; the search runs after Life Town's and the Market Square's and keeps off their plazas and 20 degrees
round from them, seen from the spawn): **Life Town keeps its 6 of 8, the Market Square its 6**; the Academy stands on
the ground in **7 of 8** worlds, **34-42 m from the spawn**, **51-80 m from Life Town's middle**; seed 2024 has no room:
the island over the spawn. Slowest search 91 ms (on a worker). The smoke's new Green Meadows world (seed 12345): the
Academy stood at (4, 38, 34), 34 m from the spawn and 72 m from Life Town's middle; the save kept it; MY MAP marked it;
the compass pointed to it until the History Museum's door; the Maths Workshop started its play; Life's door opened
Life. Frames with the Academy in view in a real window: 10.5 ms average, 14.8 ms worst (this desktop); headless 6.9 ms.
**Draws:** four meshes (the lit parts merged, the glowing parts merged, Hoot's body and head), no label, no light, no
shadow-casting glow; one static body (the tower; the island's rock). Hoot flying in: three draws while he is here.

**Tests and proof.** `tests/unit/test_discovery_academy.gd` (9: twelve doors one per subject family and Life, every
grade's subjects but Projects have a door, doors more than two reaches apart, Maths faces the spawn, walking up, what
each door opens, the search keeps off the town and the Market Square and beside them, the island, the save and
WorldMeta, the real meadows), `tests/integration/test_discovery_academy_world.gd` (12: a saved site stands, the host
checks, clears a tree and saves, a child's build moves it, a guest, the island, four meshes and no words or light, each
door's name spoken, coming soon shown and spoken within the word budget and closed by walking away, the Maths Workshop's
play, Life, the compass until visited and remembered, the island's no doors), `tests/integration/test_discovery_hoot_flight.gd`
(4: lands near the child out of the sky with no body, in a headset too, flies off when his card goes, to the Academy).
The smoke `tools/discovery_smoke.gd` runs it all on a real world.

**Rulings (each with its cost if wrong).**
22. **The Academy is placed after Life Town and the Market Square** (their sites from the save, else the seed's own
    search), so they keep every meadow they had. *Cost:* if a child's build moved the town after a new world's first
    search, the Academy may stand where the moved town's search avoided nothing (rare: the town moves only off a child's
    build).
23. **Its search starts at its own angle round the spawn** (the seed shifted by 7919) and keeps 20 degrees from the town
    and the Market Square: it lands on another side of the spawn, 51-80 m from the town. *Cost:* the three are not one
    district; each is its own landmark.
24. **No room: a small floating island over the spawn** (16 blocks up: the tower and Hoot on grass and rock), with no
    doors to walk up to; DISCOVER (MORE, the pause menu) and the crystals still bring the learning. *Cost:* in 1 world of
    8 the doors can't be walked to.
25. **Twelve doors: the eleven subject families and Life; Projects has none** (big builds, reached through DISCOVER's
    map). *Cost:* none known.
26. **What a door opens follows #134** (`AcademyPlaza.opens`, the lead's switch): Maths a crystal's real play at the
    door (the only subject with real play today), Life opens Life, every other door a calm "coming soon" with Hoot, its
    picture and a spoken line; never the School's list of lessons. *Cost:* ten doors say "come back soon" until their
    games come (each deep game switches its door).
27. **The door's name is spoken as the child walks up** (#133); the doors show pictures only, no sign words. *Cost:* a
    reading child sees no names (the voice and the pictures carry them).
28. **The compass points to the Academy until the child has been to any door of it in this world** (remembered on the
    device), then to the world's own guide (Gemma's quests); chained before it. *Cost:* for a new world's first minutes
    the compass shows the Academy, not Gemma's camp.
29. **The models keep the world's blocky look in both styles** (Life Town's way), colours as the School's (converted for
    the lit material). *Cost:* the realistic style has no realistic Academy yet.
30. **Hoot comes in person with his invitation** (flat and VR), landing where a crystal could stand, and flies to the
    Academy's top when his card goes (or after 30 s in a headset). He has no body. *Cost:* where there is no dry ground
    near (a swim, a cave) only his card and voice come.

**What the lead must check.** Emulator: a new Green Meadows world: the tower seen from the spawn, Hoot on top; the
compass to it; each gate's picture and spoken name; the Maths Workshop's crystal; Life; a "coming soon" card; frames
with the Academy in view (≥ 30 FPS, no frame over 100 ms); Hoot landing near the child. Quest 3: walking to a gate, the
"coming soon" card on the eye panel, the Maths crystal by hand, the draws with the Academy in view (≤ 100 on the floor
preset: it adds four).

## Play G0 merged (the lead, 2026-10-18): W1 on G0's foundation

The lead merged Play G0 into lead-merge (`670824f5`) and asked W1 to stand on it. Merged into this branch (`c88ab96b`);
then:
- **DISCOVER's panel knows G0's play place** (G0's report, §8.6): `DiscoverPanel.room_open()` is true while the School's
  `play_host` is open (Android Back and the pause key belong to the place) and `close()` stops it for now (nothing
  recorded, the answers' gold kept). The place hides the world's HUD layer it was opened under (it is opened under
  DISCOVER's panel, in the HUD's layer), and gives it back. Tests: `test_discovery_play_place.gd`.
- **A crystal opens G0's short round** (`PlayHost.setup(…, 4)`): on the child's own unit (a review due, else the next)
  when it plays without reading (`PlayHost.plays`: G0's `PlayReadless`, the same test as DISCOVER's PLAY), else on a unit
  of the grade that does (the one the child was on kept as play debt). The place opens under a holder in the HUD's
  layer (`play_holder`: the world's HUD hides under it); the avatar is held and kept safe meanwhile; the gold for an
  answer right the first time is `SkillShown.pay_first_try` (the School's cap); the end records through
  `SkillShown.record` exactly as the School's PLAY does (a review of a mastered unit counts; a unit not mastered needs a
  whole round's events: G0's ruling 37); STOP FOR NOW ends it quietly. **This replaces ruling 15** (crystals never wrote
  mastery): they now record like the School.
- **MAKE and ORDER duplicate G0's Make it and Order it** (place value with base-ten things, coins, ordering numbers), and
  G0's play the child's own unit's checked exercises with show-then-do, the coach and SkillShown: **G0's are preferred.**
  W1's own MAKE and ORDER stay only as the crystal's fallback in the world where nothing in the child's grade plays
  without reading (none today: every grade has playable units), so a crystal never comes empty.
- **The Academy's subject doors open a whole round** (count 0: it can count like the School's) of the subject's unit
  that plays without reading (`DiscoveryPlays.subject_unit`: a review due, else the first not mastered, else the first);
  **a subject with none yet shows the calm "coming soon"**; Life opens Life. On the smoke's grade 4 every subject's door
  plays. Stage 3's first build (the Maths Workshop's crystal in the courtyard) is gone: G0's place plays the door.
  `AcademyPlaza.opens(door)` (PLAY, LIFE, SOON) stays the lead's switch: a deep game registered with G0 plays through
  PLAY by itself; one with a scene of its own (the leaf game, for the Science Lab's door) is switched there.
- **The voice is G0's** (`PlayVoice.say` for every W1 line: Hoot, DISCOVER's word, the crystal's, the doors'): spoken at
  once while "Read to me" is on (on for everyone since `ff49983f`); a grown-up's off silences it as it does G0's play.
  **This changes ruling 6** (Hoot's line was spoken whatever the setting).
- The smoke on a real world: the crystal opened G0's short round on `g4.maths.big_numbers` (4 challenges), the world's HUD
  hid and came back, the avatar was held, STOP FOR NOW took the crystal quietly; the Academy's History Museum and Maths
  Workshop opened whole rounds, Life opened Life (no grade 4 door is "coming soon").

**Rulings (with their costs).**
31. **G0's place is a room above the world** (its own camera): a crystal's play takes the child out of the world for a
    minute, then back where they stood (the avatar held and kept safe). *Cost:* the crystal's play is not in the meadow
    itself (W1's own MAKE and ORDER were; they remain the fallback).
32. **Four challenges per crystal** (the brief's "about a minute: 3-5"). *Cost:* by G0's ruling 37 a crystal never gives
    a new unit its first star (a review of a mastered unit counts).
33. **A door plays a whole round** (six challenges), a crystal a short one. *Cost:* a door's round is a few minutes.
34. **No door opens while a play place is open** (the child plays; their avatar is held). *Cost:* none.

## The full suite (once, at the end)

On the branch merged with lead-merge `1c524bfb` (Play G0, the Android updater and W1's stages 1-3 with the G0
integration: merge `dc62c32c`): `tests/run_tests.sh`: **11,988 tests, 11,984 passing, 1 failing, 3 risky or pending**
(the known ones: the device-move pages and the voxel column cache don't assert, the Nakama move is off), no script
errors. The one failure, `test_flight_cockpit.gd::test_a_drag_steers` ("dragged a full reach left": 0.0 for -1.0), passes
alone (7/7) on the same tree: a drag's timing under the full suite's load on this shared PC (W1 touches nothing of the
rocket's cockpit). Two earlier full runs were stopped by me, not cut off: one waited 30 minutes for a suite slot before
G0 merged, the second was replaced when the lead merged G0 (its first 524 scripts had passed).
